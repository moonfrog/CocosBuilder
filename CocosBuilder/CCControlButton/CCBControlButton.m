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

@end
