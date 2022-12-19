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

#import "CCBScale9Sprite.h"
#import "CocosBuilderAppDelegate.h"
#import "CCBDocument.h"
#import "ResolutionSetting.h"

@implementation CCBScale9Sprite

- (float) resolutionScale
{
    CCBDocument* currentDocument = [CocosBuilderAppDelegate appDelegate].currentDocument;
    
    ResolutionSetting* resolution = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    
    return resolution.scale;
}

- (void) setInsetBottom:(float)insetBottom
{
    [super setInsetBottom:insetBottom * [self resolutionScale]];
    iBot = insetBottom;
}

- (float) insetBottom
{
    return iBot;
}

- (void) setInsetTop:(float)insetTop
{
    [super setInsetTop:insetTop * [self resolutionScale]];
    iTop = insetTop;
}

- (float) insetTop
{
    return iTop;
}

- (void) setInsetLeft:(float)insetLeft
{
    [super setInsetLeft:insetLeft * [self resolutionScale]];
    iLeft = insetLeft;
}

- (float) insetLeft
{
    return iLeft;
}

- (void) setInsetRight:(float)insetRight
{
    [super setInsetRight:insetRight * [self resolutionScale]];
    iRight = insetRight;
}

- (float) insetRight
{
    return iRight;
}

- (GLubyte) opacity
{
    if(_opacity == 0)
        return 255;
    return _opacity;
}

- (void)setOpacity:(GLubyte)opacity
{
    NSLog(@"Anjali CCScale9Sprite original opcaity is %i", opacity);
    if(opacity == 0 && _opacity == 0)
    {
        _opacity = 255;
        opacity = 255;
    }
    if(opacity != 0)
    _opacity = opacity;
//    else
//    {
//        if(opacity < 255)
//            _opacity = opacity;
//        else{
//            NSLog(@"Anjali CCScale9Sprite original (2) opcaity is %i", _opacity);
//        }
//    }
//    NSLog(@"Anjali CCScale9Sprite new opcaity is %i", _opacity);
//    if(_opacity < 255)
    {
        for (CCNode<CCRGBAProtocol> *child in _scale9Image.children)
        {
            [child setOpacity:_opacity];
        }
    }
}

- (GLubyte) displayedOpacity
{
    if(_displayedOpacity == 0)
        return 255;
    return _displayedOpacity;
}

- (void)updateDisplayedOpacity:(GLubyte)parentOpacity
{
    _displayedOpacity = _realOpacity * parentOpacity/255.0;

    if (_cascadeOpacityEnabled)
    {
        id<CCRGBAProtocol> item;
        CCARRAY_FOREACH(self.children, item)
        {
            if ([item conformsToProtocol:@protocol(CCRGBAProtocol)])
            {
                [item updateDisplayedOpacity:_displayedOpacity];
            }
        }
    }
    NSLog(@"Anjali CCScale9Sprite original displayed opcaity is %i", _displayedOpacity);
}

- (void)updateDisplayedColor:(ccColor3B)parentColor
{
    _displayedColor.r = _realColor.r * parentColor.r/255.0;
    _displayedColor.g = _realColor.g * parentColor.g/255.0;
    _displayedColor.b = _realColor.b * parentColor.b/255.0;

    if (_cascadeColorEnabled) {
        id<CCRGBAProtocol> item;
        CCARRAY_FOREACH(self.children, item)
        {
            if ([item conformsToProtocol:@protocol(CCRGBAProtocol)])
            {
                [item updateDisplayedColor:_displayedColor];
            }
        }
    }
}



@end
