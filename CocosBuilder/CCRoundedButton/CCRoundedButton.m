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
@synthesize outlineWidth;
@synthesize outlineColor;
@synthesize shadowColor;
@synthesize shadowOffset;
@synthesize shadowBlur;
@synthesize autoDarkenOnPress;
@synthesize pressedScale;
@synthesize pressedStartColor;
@synthesize pressedEndColor;
@synthesize shape;

// This method is called when the class is loaded - before any instances are created
+ (void)load
{
    // Force the Objective-C runtime to register this class
    NSLog(@"CCRoundedButton +load called");
}

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
    [super draw];
    
    CGSize size = self.contentSize;
    if (size.width == 0 || size.height == 0) {
        size = CGSizeMake(100, 40); // Default size
    }
    
    // Draw rounded rectangle with gradient
    [self drawRoundedRectWithSize:size];
}

- (void)drawRoundedRectWithSize:(CGSize)size
{
    float r = MIN(radius, MIN(size.width, size.height) / 2.0f);
    
    // Enable blending for colors
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Draw filled rounded rectangle with gradient
    if (shape == 0) { // ROUNDED_RECT
        [self drawFilledRoundedRect:CGPointZero size:size radius:r];
    } else if (shape == 1) { // CIRCLE
        [self drawFilledCircle:CGPointMake(size.width/2, size.height/2) radius:MIN(size.width, size.height)/2];
    } else {
        // For other shapes, draw simple rounded rect for now
        [self drawFilledRoundedRect:CGPointZero size:size radius:r];
    }
    
    // Draw outline if width > 0
    if (self.outlineWidth > 0) {
        glLineWidth(self.outlineWidth);
        ccDrawColor4B(self.outlineColor.r, self.outlineColor.g, self.outlineColor.b, 255);
        
        if (shape == 0) {
            [self drawRoundedRectOutline:CGPointZero size:size radius:r];
        } else if (shape == 1) {
            [self drawCircleOutline:CGPointMake(size.width/2, size.height/2) radius:MIN(size.width, size.height)/2];
        }
    }
    
    glDisable(GL_BLEND);
}

- (void)drawFilledRoundedRect:(CGPoint)origin size:(CGSize)size radius:(float)r
{
    // Simple gradient approximation - draw multiple horizontal strips
    int segments = 20;
    float stripHeight = size.height / segments;
    
    for (int i = 0; i < segments; i++) {
        float t = (float)i / (float)segments; // 0.0 to 1.0
        
        // Interpolate color based on gradient vector
        ccColor3B color;
        color.r = startColor.r + t * (endColor.r - startColor.r);
        color.g = startColor.g + t * (endColor.g - startColor.g);
        color.b = startColor.b + t * (endColor.b - startColor.b);
        
        float y = origin.y + i * stripHeight;
        
        // Draw a filled rectangle for this strip
        ccDrawSolidRect(ccp(origin.x, y), 
                       ccp(origin.x + size.width, y + stripHeight),
                       ccc4f(color.r/255.0f, color.g/255.0f, color.b/255.0f, 1.0f));
    }
}

- (void)drawRoundedRectOutline:(CGPoint)origin size:(CGSize)size radius:(float)r
{
    // Draw simple rectangle outline for now
    // (Proper rounded corners would require bezier curves or segment drawing)
    ccDrawRect(origin, ccp(origin.x + size.width, origin.y + size.height));
}

- (void)drawFilledCircle:(CGPoint)center radius:(float)r
{
    int segments = 30;
    CGPoint *vertices = malloc(sizeof(CGPoint) * segments);
    
    for (int i = 0; i < segments; i++) {
        float angle = (float)i / (float)segments * M_PI * 2.0f;
        vertices[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    // Draw gradient filled circle using triangle fan
    ccColor3B avgColor;
    avgColor.r = (startColor.r + endColor.r) / 2;
    avgColor.g = (startColor.g + endColor.g) / 2;
    avgColor.b = (startColor.b + endColor.b) / 2;
    
    ccDrawSolidPoly(vertices, segments, ccc4f(avgColor.r/255.0f, avgColor.g/255.0f, avgColor.b/255.0f, 1.0f));
    
    free(vertices);
}

- (void)drawCircleOutline:(CGPoint)center radius:(float)r
{
    ccDrawCircle(center, r, 0, 30, NO);
}

@end

