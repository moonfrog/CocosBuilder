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

@implementation CCBControlButton

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

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"languageSelection"]) {
        [self changeLanguageSelection:[value intValue]];
        return;
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

-(id)init {
    if (self = [super init])  {
        self->currentLocale = -1;
        self->stringMap = [[NSMutableDictionary alloc] init];
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

@end
