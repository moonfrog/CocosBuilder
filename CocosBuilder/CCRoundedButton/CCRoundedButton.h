/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2024.
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

#import "cocos2d.h"

@interface CCRoundedButton : CCNode
{
    float radius;
    ccColor3B startColor;
    GLubyte startOpacity;
    ccColor3B endColor;
    GLubyte endOpacity;
    CGPoint gradientVector;
    float outlineWidth;
    ccColor3B outlineColor;
    ccColor3B shadowColor;
    CGPoint shadowOffset;
    float shadowBlur;
    
    // Pressed state
    BOOL autoDarkenOnPress;
    float pressedScale;
    ccColor3B pressedStartColor;
    ccColor3B pressedEndColor;
    
    int shape;
}

@property (nonatomic, assign) float radius;
@property (nonatomic, assign) ccColor3B startColor;
@property (nonatomic, assign) GLubyte startOpacity;
@property (nonatomic, assign) ccColor3B endColor;
@property (nonatomic, assign) GLubyte endOpacity;
@property (nonatomic, assign) CGPoint gradientVector;
@property (nonatomic, assign) float outlineWidth;
@property (nonatomic, assign) ccColor3B outlineColor;
@property (nonatomic, assign) ccColor3B shadowColor;
@property (nonatomic, assign) CGPoint shadowOffset;
@property (nonatomic, assign) float shadowBlur;
@property (nonatomic, assign) BOOL autoDarkenOnPress;
@property (nonatomic, assign) float pressedScale;
@property (nonatomic, assign) ccColor3B pressedStartColor;
@property (nonatomic, assign) ccColor3B pressedEndColor;
@property (nonatomic, assign) int shape;

- (id)init;

@end
