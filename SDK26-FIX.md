# SDK 26 Label Rasterization Fix

## TL;DR

Building CocosBuilder against macOS SDK 26 (Xcode 26+) produced an
`.app` that could not render label text — glyphs appeared as faint
ghost outlines, or were missing entirely. Building against SDK 15
(Xcode 16) on the same source rendered text correctly.

The cause was an SDK-gated behavior change in AppKit. The fix is in
`cocos2d/CCTexture2D.m` and replaces two implicit-format bitmap
rasterization paths with explicit 8-bit RGBA bitmaps. Result: text
renders correctly on both SDK 15 and SDK 26, on Intel and Apple
Silicon.

If you just want a working build, grab the universal `.app` zip from
the team (built from this commit). If you want to build locally, see
"Building from source" below.

## Symptom

In a freshly-built CocosBuilder from `UXIssues` on Xcode 26.1.1 / macOS
Tahoe (Darwin 25.x), all `CCLabelTTF` instances in the canvas rendered
as faint, transparent ghost shapes. The glyph outlines were vaguely
recognizable but most pixels were near-zero alpha. Labels with stroke
or shadow effects went through a different code path inside cocos2d and
sometimes rendered correctly, sometimes did not, depending on which
rasterizer they triggered.

The exact same source tree, built against SDK 15.5 (Xcode 16), rendered
all labels correctly. This was verifiable by inspecting an older
`/Applications/CocosBuilder.app` binary on the same machine: it still
worked at runtime, and `otool -l` showed `LC_BUILD_VERSION sdk 15.5`
while the fresh build showed `sdk 26.1`.

## Root cause

### Bitmap layout assumption in cocos2d

The cocos2d rasterizer takes an `NSAttributedString`, draws it into an
offscreen bitmap, and uploads the bitmap's bytes as a GL texture. The
upload path assumes the bitmap is 8-bit RGBA — four bytes per pixel,
with alpha at byte offset 3:

```c
unsigned char *data = (unsigned char*) [bitmap bitmapData];
// ...
data[i*4+3]  // alpha of pixel i
```

For most rendering paths in cocos2d, the texture is alpha-only or
luminance+alpha. The downstream conversion reads `data[i*4+3]` and
either packs it into an LA88 pixel or copies it to an A8 buffer:

```c
// LA88 path
for (int i = 0; i < textureSize; i++)
    dst[i] = (data[i*4+3] << 8) | 0xff;
```

This entire chain only works if every pixel is exactly 4 bytes with
alpha at the 4th byte.

### What SDK 26 changed

Two rasterization functions in `cocos2d/CCTexture2D.m` produced the
bitmap differently:

1. **`initWithString:fontDef:`** (used when shadow or stroke is
   enabled) called `[image lockFocus]` on an `NSImage` and then
   `[[NSBitmapImageRep alloc] initWithFocusedViewRect:...]`. This
   relied on the system to pick the bitmap format.

2. **`initWithString:dimensions:hAlignment:vAlignment:attributedString:`**
   (used for plain text) allocated an `NSBitmapImageRep` explicitly
   but with `bitsPerSample:16, bitsPerPixel:64` — a 16-bit-per-channel
   bitmap, with a downstream conversion that called `half_to_float()`
   on what it assumed were IEEE half-precision samples. This second
   path was an earlier attempt to address the same SDK incompatibility,
   but its math was wrong: `bitsPerSample:16` produces *integer*
   16-bit samples, not half-floats, so `half_to_float()` corrupted the
   data.

For path 1, on SDK 15 the system handed back an 8-bit RGBA bitmap and
everything worked. On SDK 26, on a Mac with a wide-color-capable
display, the system handed back a 16-bit-per-channel bitmap
(`bps=16, spp=4, bpp=64, bitmapFormat=0x4`). The downstream code,
unaware of the layout change, read `data[i*4+3]` — which in 16bpc
layout is the *high byte of red of the wrong pixel*, not alpha. Glyph
coverage was effectively discarded; only ghost outlines made it
through.

For path 2, the 16bpc bitmap was correctly produced but the wrong
formula was applied. Same end result: invisible or near-invisible
text.

### Diagnostic confirmation

A single `NSLog` line right after the bitmap was created printed:

```
[CCB-DIAG] bps=16 spp=4 bpp=64 bytesPerRow=1024 hasAlpha=1
            alphaFirst=0 planar=0 bitmapFormat=0x4 colorSpace=Color LCD
```

`bpp=64` is the smoking gun. The cocos2d code assumes 32. Every alpha
read was off by stride and offset.

### Why SDK-gating happens silently

Apple changes Cocoa defaults between SDKs but gates the new behavior
on what SDK the binary was *compiled against*, not what OS it runs on.
This keeps old apps working while letting newer apps opt into newer
behavior — the right call for Apple, but it means code written against
an older SDK can break the moment someone updates Xcode, with no API
deprecation warning, no compile error, and no runtime crash. Only the
rendered output looks wrong.

## Fix

Replace both rasterization paths with an explicit, fully-specified 8-bit
RGBA `NSBitmapImageRep` driven by an explicit `NSGraphicsContext`:

```objc
NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes:NULL
                  pixelsWide:POTSize.width
                  pixelsHigh:POTSize.height
               bitsPerSample:8
             samplesPerPixel:4
                    hasAlpha:YES
                    isPlanar:NO
              colorSpaceName:NSDeviceRGBColorSpace
                 bytesPerRow:POTSize.width * 4
                bitsPerPixel:32];

memset([bitmap bitmapData], 0, POTSize.width * POTSize.height * 4);

NSGraphicsContext *ctx =
    [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
[NSGraphicsContext saveGraphicsState];
[NSGraphicsContext setCurrentContext:ctx];
[ctx setShouldAntialias:YES];

[stringWithAttributes drawWithRect:NSRectFromCGRect(drawArea)
                           options:NSStringDrawingUsesLineFragmentOrigin];

[NSGraphicsContext restoreGraphicsState];

unsigned char *data = (unsigned char*) [bitmap bitmapData];
```

Key properties:

- **`bitsPerSample:8, bitsPerPixel:32`** — explicit byte layout. No
  SDK-dependent surprises. `data[i*4+3]` is always alpha.
- **`NSDeviceRGBColorSpace`** — pragmatic choice for offscreen text
  rasterization on macOS. Works on SDK 15 and SDK 26.
- **`memset(... 0 ...)`** — zero the buffer before drawing.
  `initWithBitmapDataPlanes:NULL` does not guarantee initialized
  memory; uninitialized data composited with text produces garbage
  even when the format is correct.
- **`setShouldAntialias:YES`** — was `NO` in the original. Antialiasing
  on matches iOS runtime behavior more closely and produces smoother
  glyph edges in the editor canvas.

Both `initWithString:fontDef:` and
`initWithString:dimensions:hAlignment:vAlignment:attributedString:` now
use this pattern.

## Affected versions

- **Broken**: builds compiled against macOS SDK 26.0 or later (Xcode
  26+).
- **Working as before**: builds compiled against macOS SDK 15.x or
  earlier (Xcode 16 and below).
- **After this fix**: builds work correctly against any SDK from 15
  through 26+.

The runtime OS does not matter — the fault is in *how the binary was
built*, not what it runs on. A Dec 2025 Intel binary built on Xcode 16
still renders text correctly today on macOS 26.

## For teammates: which path do you need?

### "I just want a working CocosBuilder"

Use the prebuilt universal `.app` zip from `~/Documents` (or wherever
the binary was shared). It runs on both Intel and Apple Silicon
natively. First launch will be Gatekeeper-blocked since the build
isn't notarized:

```
xattr -d com.apple.quarantine /path/to/CocosBuilder.app
```

…or right-click → Open and confirm the dialog once.

### "I need to build from source"

Pull `UXIssues` plus the submodule update. The cocos2d submodule is on
branch `fix/color_hex_colorspace_mismatch` with the rasterization fix
on top. Then follow "Building from source" below.

## Building from source

The CocosBuilder Xcode project doesn't declare its two framework
dependencies as build dependencies, so a first-time build fails at the
link step with missing `MMMarkdown.framework` and `MGSFragaria.framework`.
Build them first:

```bash
cd /path/to/CocosBuilderWorkspace

# 1. MMMarkdown
xcodebuild \
    -project CocosBuilder/MMMarkdown-master/MMMarkdown.xcodeproj \
    -target "MMMarkdown (OS X)" \
    -configuration Debug build
# (use -configuration Release if you want a release build)

# 2. Fragaria
xcodebuild \
    -project CocosBuilder/libs/Fragaria/Fragaria.xcodeproj \
    -target MGSFragaria \
    -configuration Debug build

# 3. CocosBuilder itself
cd CocosBuilder
xcodebuild -target CocosBuilder -configuration Debug build
```

Built `.app` lands at:

- Debug: `CocosBuilder/build/Debug/CocosBuilder.app`
- Release: `CocosBuilder/build/Release/CocosBuilder.app`

If you prefer Xcode:

1. Open `CocosBuilder/CocosBuilder.xcodeproj`.
2. Build the MMMarkdown (OS X) target (top-left scheme selector).
3. Build the MGSFragaria target.
4. Build the CocosBuilder target.

### Submodules

If submodules aren't initialized:

```bash
git submodule update --init --recursive
```

The cocos2d-iphone submodule must be at commit `289115d6` or later for
the SDK 26 fix to be present. Verify with:

```bash
cd CocosBuilder/libs/cocos2d-iphone
git log -1 --oneline
# should show: 289115d6 fix CCTexture2D label rasterization on macOS SDK 26
```

### Universal binary

Builds are universal (x86_64 + arm64) thanks to commit `3970d282
universal build support for Intel + Apple Silicon`. No separate Intel
build is required; the same `.app` runs natively on both architectures.

## Producing a shareable zip

After a Release build:

```bash
cd CocosBuilder/build/Release
ditto -c -k --sequesterRsrc --keepParent \
    CocosBuilder.app \
    ~/Documents/CocosBuilder-sdk26-fix.zip
```

`ditto` preserves macOS-specific bundle attributes (extended attributes,
resource forks) that plain `zip` can strip. Resulting zip is ~17 MB.

## Future work

- The fix uses `NSDeviceRGBColorSpace`, the pragmatic choice for
  offscreen rendering. A future cleanup could move to a fully
  modern path (e.g., `CGBitmapContextCreate` with an explicit
  `CGColorSpace` and `CGBitmapInfo`) for tighter control, but that
  would change the editor's text appearance and should be evaluated
  separately.
- `setShouldAntialias:YES` was a deliberate change from the original
  `NO`. If any teammate prefers the older crisp-pixel look, this is a
  one-line revert in `cocos2d/CCTexture2D.m` (both rasterizers).
- The cocos2d submodule branch (`fix/color_hex_colorspace_mismatch`)
  has accumulated several fixes beyond its name suggests; consider
  consolidating onto a clearer branch when there's appetite.
