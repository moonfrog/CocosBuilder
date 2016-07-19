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

#import "CCBPLabelTTF.h"
#import "CocosBuilderAppDelegate.h"
#import "ProjectSettings.h"

@implementation CCBPLabelTTF
//
@synthesize outlineColor;
@synthesize shadowColor;
@synthesize outlineWidth;
@synthesize shadowBlurRadius;
@synthesize shadowOffsetInPoints;
@synthesize localeString;

- (void) setAlignment:(int)alignment
{
    self.horizontalAlignment = alignment;
}

- (void) setColor:(ccColor3B)fontColor
{
    bool update = YES;
    if (!super.string) {
        update = NO;
    }
    [self setFontFillColor:fontColor updateImage:update];
    super.color = fontColor;
}

-(id)init {
    if (self = [super init])  {
        self->currentLocale = -1;
        self->stringMap = [[NSMutableDictionary alloc] init];
        [self changeLocale];
    }
    return self;
}

-(void) setLanguageSelection:(Locale)selectedLocale
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
            NSLog(@"Language now is %@", fileName);
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

-(NSString*) string
{
    return localeString;
}

- (void) setString:(NSString *)str
{
    [self setLocaleString:str];
}

- (void) setLocaleString:(NSString*)str
{
    self->localeString = str;
    if (![str isEqualToString:@""] && [self->stringMap valueForKey:str] != nil) {
        [super setString:[self->stringMap valueForKey:str]];
    } else {
        [super setString:str];
    }
}

- (void) setOutlineColor:(ccColor3B)outlineClr
{
    outlineColor = outlineClr;
    if (self.outlineWidth == 0.0) {
        [self disableStrokeAndUpdateImage:YES];
    } else {
        [self enableStrokeWithColor:outlineClr size:self.outlineWidth updateImage:YES];
    }
}

- (void) setOutlineWidth:(CGFloat)outlineWid
{
    outlineWidth = outlineWid;
    [self setOutlineColor:outlineColor];
}

- (void) setShadowColor:(ccColor3B)shadowClr
{
    shadowColor = shadowClr;
    [self enableShadowWithOffset:CGSizeMake(shadowOffsetInPoints.x, shadowOffsetInPoints.y) opacity:255 blur:shadowBlurRadius updateImage:YES];
}

-(void) setShadowBlurRadius:(CGFloat)shadowBlurRad
{
    if (shadowBlurRad == 0) {
        [self disableShadowAndUpdateImage:YES];
        return;
    }
    shadowBlurRadius = shadowBlurRad;
    [self enableShadowWithOffset:CGSizeMake(shadowOffsetInPoints.x, shadowOffsetInPoints.y) opacity:255 blur:shadowBlurRadius updateImage:YES];
}

-(void) setShadowOffsetInPoints:(CGPoint)shadowOffsetInPoint
{
    shadowOffsetInPoints = shadowOffsetInPoint;
    if (shadowBlurRadius > 0) {
        [self enableShadowWithOffset:CGSizeMake(shadowOffsetInPoints.x, shadowOffsetInPoints.y) opacity:255 blur:shadowBlurRadius updateImage:YES];
    }
}

- (int) alignment
{
    return self.horizontalAlignment;
}

@end
