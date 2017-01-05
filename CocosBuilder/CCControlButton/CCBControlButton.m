/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "CCBControlButton.h"
#import "CocosBuilderAppDelegate.h"
#import "CCBDocument.h"
#import "ResolutionSetting.h"
#import "CCScale9Sprite.h"
#import "ProjectSettings.h"
#import "TexturePropertySetter.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"

@implementation CCBControlButton

@synthesize outlineColor;
@synthesize shadowColor;
@synthesize outlineWidth;
@synthesize shadowOpacity;
@synthesize shadowBlurRadius;
@synthesize shadowOffset;
@synthesize fontColor;

- (float) resolutionScale
{
    CCBDocument* currentDocument = [CocosBuilderAppDelegate appDelegate].currentDocument;
    
    ResolutionSetting* resolution = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    
    return resolution.scale;
}

- (void) setInsetBottom:(float)insetBottom
{
//    [super setInsetBottom:insetBottom * [self resolutionScale]];
    CCScale9Sprite* sprite = [self backgroundSpriteForState:CCControlStateNormal];
    [sprite setInsetBottom:insetBottom];
    iBot = insetBottom;
}

- (float) insetBottom
{
    return iBot;
}

- (void) setInsetTop:(float)insetTop
{
//    [super setInsetTop:insetTop * [self resolutionScale]];
    CCScale9Sprite* sprite = [self backgroundSpriteForState:CCControlStateNormal];
    [sprite setInsetTop:insetTop];
    [self setBackgroundSprite:sprite forState:CCControlStateNormal];
    iTop = insetTop;
}

- (float) insetTop
{
    return iTop;
}

- (void) setInsetLeft:(float)insetLeft
{
//    [super setInsetLeft:insetLeft * [self resolutionScale]];
    CCScale9Sprite* sprite = [self backgroundSpriteForState:CCControlStateNormal];
    [sprite setInsetLeft:insetLeft];
    iLeft = insetLeft;
}

- (float) insetLeft
{
    return iLeft;
}

- (void) setInsetRight:(float)insetRight
{
//    [super setInsetRight:insetRight * [self resolutionScale]];
    CCScale9Sprite* sprite = [self backgroundSpriteForState:CCControlStateNormal];
    [sprite setInsetRight:insetRight];
    [self setBackgroundSprite:sprite forState:CCControlStateNormal];
    iRight = insetRight;
}

- (float) insetRight
{
    return iRight;
}

-(void)onSetSelectedTexture:(id)propertyName
{
    RMSpriteFrame* frame = [[CocosBuilderAppDelegate appDelegate] getSelectedResource];
    if (frame == nil) return;
    [[CocosBuilderAppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    CCNode* selection = [CocosBuilderAppDelegate appDelegate].selectedNode;

    // Fetch info about the sprite name
    NSString* ssf = [ResourceManagerUtil relativePathFromAbsolutePath:frame.spriteSheetFile];
    NSString* sf = frame.spriteFrameName;

    // Set the properties and sprite frames
    if (sf && ssf)
    {
        [selection setExtraProp:sf forKey:propertyName];
        [selection setExtraProp:ssf forKey:[NSString stringWithFormat:@"%@Sheet", propertyName]];

        [TexturePropertySetter setSpriteFrameForNode:selection andProperty:propertyName withFile:sf andSheetFile:ssf];
    }
    [self onSetSizeFromTexture];
    [[CocosBuilderAppDelegate appDelegate] updateInspectorFromSelection];
}

-(void)onSetSelectedTexture1
{
    NSString* propertyName = @"backgroundSpriteFrame|1";
    [self onSetSelectedTexture:propertyName];
}

-(void)onSetSelectedTexture2
{
    NSString* propertyName = @"backgroundSpriteFrame|2";
    [self onSetSelectedTexture:propertyName];
}

-(void)onSetSelectedTexture3
{
    NSString* propertyName = @"backgroundSpriteFrame|3";
    [self onSetSelectedTexture:propertyName];
}

-(void)onSetSizeFromTexture
{
    CCScale9Sprite * spriteFrame = [self backgroundSpriteForState:CCControlStateNormal];
    if(spriteFrame == nil)
        return;
    
    [self setPreferedSize:spriteFrame.originalSize];
    
    [self willChangeValueForKey:@"preferredSize"];
    [self didChangeValueForKey:@"preferredSize"];
    [[CocosBuilderAppDelegate appDelegate] refreshProperty:@"preferedSize"];
}

-(void) changeLanguageSelection:(Locale)selectedLocale
{
    if (selectedLocale != currentLocale) {
        currentLocale = selectedLocale;
        [self changeLocale];
    }
}

- (Locale) languageSelection
{
    return currentLocale;
}

- (void) changeLocale
{
    if (self->currentLocale == LOCALE_COUNT) {
        self->currentLocale = 0;
    }
    NSString* fileName = @"";
    switch (self->currentLocale) {
        case ENGLISH:
            fileName = @"Localized_en";
            break;
        case HINDI:
            fileName = @"Localized_hi";
            break;
        case GUJARATI:
            fileName = @"Localized_gj";
            break;
        case MARATHI:
            fileName = @"Localized_ma";
            break;
        case TELUGU:
            fileName = @"Localized_tl";
            break;
        case TAMIL:
            fileName = @"Localized_tm";
            break;
        default:
            fileName = @"Localized_en";
            break;
    }
    
    ProjectSettings* projectSettings = [CocosBuilderAppDelegate appDelegate].projectSettings;
    for (NSString* dir in projectSettings.absoluteResourcePaths)
    {
        NSString* fullName = [dir stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullName])
        {
            [stringMap removeAllObjects];
//            NSLog(@"Language now is %@", fileName);
            NSString *fileContents = [NSString stringWithContentsOfFile:fullName encoding:NSUTF8StringEncoding error:NULL];
            for (NSString *line in [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
                // Do something
                if (![line isEqualToString:@""]) {
                    NSArray *items = [line componentsSeparatedByString:@"="];
                    if ([items count] == 2) {
                        NSString* key = [[items objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        NSString* value = [[items objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        value = [value stringByReplacingOccurrencesOfString:@";" withString:@""];
                        [stringMap setObject:value forKey:key];
                    }
                }
            }
        }
    }
    [self setLocaleString:localeString];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"languageSelection"]) {
        [self changeLanguageSelection:[value intValue]];
        return;
    }
    if ([key isEqualToString:@"titleColor|1"]) {
        ccColor3B c;
        [value getValue:&c];
        CCLabelTTF* label = (CCLabelTTF*)self.titleLabel;
        [label setFontFillColor:fontColor updateImage:NO];
        self.titleLabel.color = c;
    }
    NSArray* chunks = [key componentsSeparatedByString:@"|"];
    if ([chunks count] == 2)
    {
        NSString* keyChunk = [chunks objectAtIndex:0];
        if ([keyChunk isEqualToString:@"title"])
        {
            [self setLocaleString:value];
            return;
        }
    }
    [super setValue:value forUndefinedKey:key];
}

- (id)valueForKey:(NSString*)key {
    if ([key isEqualToString:@"title|1"]) {
        return self->localeString;
    }
    return [super valueForKey:key];
}

-(id)init {
    if (self = [super init])  {
        self->currentLocale = -1;
        self->stringMap = [[NSMutableDictionary alloc] init];
        self->fontColor = ccWHITE;
        [self changeLocale];
    }
    return self;
}

- (void) setLocaleString:(NSString*)str
{
    self->localeString = str;
    if (![str isEqualToString:@""] && [self->stringMap valueForKey:str] != nil) {
        [super setValue:[self->stringMap valueForKey:str] forUndefinedKey:@"title|1"];
    } else {
        [super setValue:str forUndefinedKey:@"title|1"];
    }
}

- (id) getLabel
{
    id label = self.titleLabel;
    [label setFontFillColor:self.fontColor updateImage:NO];
    return label;
}

- (void) setOutlineColor:(ccColor3B)outlineClr
{
    outlineColor = outlineClr;
    id label = [self getLabel];
    if (self.outlineWidth == 0.0) {
        [label disableStrokeAndUpdateImage:YES];
    } else {
        [label enableStrokeWithColor:outlineClr size:self.outlineWidth updateImage:YES];
    }
}

- (void) setOutlineWidth:(CGFloat)outlineWid
{
    outlineWidth = outlineWid;
    [self setOutlineColor:outlineColor];
}

- (void) setShadowOpacity:(CGFloat)shadowOty
{
    shadowOpacity = shadowOty;
    id label = self.titleLabel;
    [label enableShadowWithOffset:CGSizeMake(shadowOffset.x, shadowOffset.y) opacity:shadowOpacity blur:shadowBlurRadius updateImage:YES];
}

- (void) setShadowColor:(ccColor3B)shadowClr
{
    shadowColor = shadowClr;
    id label = self.titleLabel;
    [label enableShadowWithOffset:CGSizeMake(shadowOffset.x, shadowOffset.y) opacity:shadowOpacity blur:shadowBlurRadius updateImage:YES];
}

-(void) setShadowBlurRadius:(CGFloat)shadowBlurRad
{
    id label = self.titleLabel;
    if (shadowBlurRad == 0) {
        [label disableShadowAndUpdateImage:YES];
        return;
    }
    shadowBlurRadius = shadowBlurRad;
    [label enableShadowWithOffset:CGSizeMake(shadowOffset.x, shadowOffset.y) opacity:shadowOpacity blur:shadowBlurRadius updateImage:YES];
}

-(void) setShadowOffset:(CGPoint)shadowOffsetInPoint
{
    shadowOffset = shadowOffsetInPoint;
    id label = self.titleLabel;
    if (shadowBlurRadius > 0) {
        [label enableShadowWithOffset:CGSizeMake(shadowOffset.x, shadowOffset.y) opacity:shadowOpacity blur:shadowBlurRadius updateImage:YES];
    }
}

@end
