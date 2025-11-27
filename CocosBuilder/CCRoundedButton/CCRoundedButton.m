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

#import "CCRoundedButton.h"

@implementation CCRoundedButton

@synthesize radius;
@synthesize startColor;
@synthesize endColor;
@synthesize gradientVector;
//@synthesize outlineWidth;
//@synthesize outlineColor;
//@synthesize shadowColor;
//@synthesize shadowOffset;
@synthesize shadowBlur;
@synthesize autoDarkenOnPress;
@synthesize pressedScale;
@synthesize pressedStartColor;
@synthesize pressedEndColor;
@synthesize shape;

- (id)init
{
    self = [super init];
    if (!self) return NULL;
    
    // Default values to match the plist defaults
    radius = 10.0f;
    startColor = ccc3(255, 255, 255);
    endColor = ccc3(200, 200, 200);
    gradientVector = ccp(0, 1);
    outlineWidth = 0.0f;
    outlineColor = ccc3(0, 0, 0);
    shadowColor = ccc3(0, 0, 0);
    shadowOffset = ccp(2, -2);
    shadowBlur = 0.0f;
    autoDarkenOnPress = YES;
    pressedScale = 0.95f;
    pressedStartColor = ccc3(200, 200, 200);
    pressedEndColor = ccc3(150, 150, 150);
    shape = 0; // ROUNDED_RECT
    
    return self;
}

- (void) draw
{
    // Simple debug drawing to verify it's working
    // In a real plugin, you'd use OpenGL or other Cocos2D drawing commands here
    // to match the appearance of your custom button
    [super draw];
}

@end
