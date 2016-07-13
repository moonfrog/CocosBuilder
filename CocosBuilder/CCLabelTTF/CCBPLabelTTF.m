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

@implementation CCBPLabelTTF
//
@synthesize outlineColor;
@synthesize shadowColor;
@synthesize outlineWidth;
@synthesize shadowBlurRadius;
@synthesize shadowOffsetInPoints;

- (void) setAlignment:(int)alignment
{
    self.horizontalAlignment = alignment;
}

- (void) setColor:(ccColor3B)fontColor
{
    bool update = YES;
    if (!self.string) {
        update = NO;
    }
    [self setFontFillColor:fontColor updateImage:update];
    super.color = fontColor;
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
