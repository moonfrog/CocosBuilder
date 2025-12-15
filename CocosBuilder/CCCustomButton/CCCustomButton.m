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

#import "CCCustomButton.h"
#import "CCShaderCache.h"
#import "CCGLProgram.h"
#import "ccGLStateCache.h"

@implementation CCCustomButton

@synthesize radius;
@synthesize startColor;
@synthesize startOpacity;
@synthesize endColor;
@synthesize endOpacity;
@synthesize gradientVector;
@synthesize outlineWidth;
@synthesize outlineColor;
@synthesize outlineStartColor;
@synthesize outlineStartOpacity;
@synthesize outlineEndColor;
@synthesize outlineEndOpacity;
@synthesize shadowColor;
@synthesize shadowOffset;
@synthesize shadowBlur;
@synthesize autoDarkenOnPress;
@synthesize pressedScale;
@synthesize pressedStartColor;
@synthesize pressedEndColor;
@synthesize shape;
@synthesize titleLabel;
@synthesize fontColor;
@synthesize shadowOpacity;
@synthesize shadowBlurRadius;

+ (void)load
{
    NSLog(@"CCCustomButton +load called");
}

- (id)init
{
    self = [super init];
    if (!self) return NULL;
    
    // Default values matching CustomShape
    radius = 10.0f;
    startColor = ccc3(255, 255, 255);
    startOpacity = 255;
    endColor = ccc3(200, 200, 200);
    endOpacity = 255;
    gradientVector = ccp(0, 1);
    outlineWidth = 0.0f;
    outlineColor = ccc3(0, 0, 0);
    outlineStartColor = ccc3(0, 0, 0);
    outlineStartOpacity = 255;
    outlineEndColor = ccc3(0, 0, 0);
    outlineEndOpacity = 255;
    shadowColor = ccc3(0, 0, 0);
    shadowOffset = CGPointZero;
    shadowBlur = 0.0f;
    autoDarkenOnPress = YES;
    pressedScale = 0.95f;
    pressedStartColor = ccc3(200, 200, 200);
    pressedEndColor = ccc3(150, 150, 150);
    shape = 0; // ROUNDED_RECT
    
    isPressed = NO;
    
    // Create title label with default text
    titleLabel = [CCLabelTTF labelWithString:@"Button" fontName:@"Helvetica" fontSize:17];
    [(CCLabelTTF*)titleLabel setFontFillColor:ccc3(255, 255, 255) updateImage:YES];
    [self addChild:titleLabel];
    
    // Label text defaults
    fontColor = ccc3(255, 255, 255);
    shadowOpacity = 0.0f;
    shadowBlurRadius = 0.0f;
    
    self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];
    
    // Set default size
    [self setContentSize:CGSizeMake(100, 40)];
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    isPressed = highlighted;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    isPressed = selected;
}

- (void)draw
{
    [super draw];
    
    CGSize size = self.contentSize;
    if (size.width == 0 || size.height == 0) {
        size = CGSizeMake(100, 40);
    }
    
    // Draw shadow first
    if (self.shadowBlur > 0 && self.shadowColor.r + self.shadowColor.g + self.shadowColor.b > 0) {
        [self drawShadow:size];
    }
    
    // Draw the button shape with gradient and outline
    [self drawButtonShape:size];
}

- (void)drawShadow:(CGSize)size
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    CGPoint offset = self.shadowOffset;
    float blur = self.shadowBlur;
    
    int layers = MIN(5, (int)blur);
    if (layers < 1) layers = 1;
    
    for (int i = 0; i < layers; i++) {
        float t = (float)i / (float)layers;
        float alpha = 0.5f * (1.0f - t);
        
        ccColor4F shadowCol = ccc4f(self.shadowColor.r/255.0f, self.shadowColor.g/255.0f, self.shadowColor.b/255.0f, alpha);
        CGPoint layerOffset = ccp(offset.x * (1.0f + t), offset.y * (1.0f + t));
        
        switch (shape) {
            case 0: // ROUNDED_RECT
                [self drawFilledRoundedRect:layerOffset size:size radius:radius color:shadowCol];
                break;
            case 1: // CIRCLE
                [self drawFilledCircle:ccp(size.width/2 + layerOffset.x, size.height/2 + layerOffset.y) 
                                radius:MIN(size.width, size.height)/2 
                                 color:shadowCol];
                break;
            case 2: // HEXAGON
                [self drawFilledHexagon:ccp(size.width/2 + layerOffset.x, size.height/2 + layerOffset.y) 
                                 radius:MIN(size.width, size.height)/2 - radius 
                                  color:shadowCol];
                break;
            case 3: // DIAMOND
                [self drawFilledDiamond:ccp(size.width/2 + layerOffset.x, size.height/2 + layerOffset.y) 
                                   size:MIN(size.width, size.height) * 0.7f 
                                  color:shadowCol];
                break;
            case 4: // STAR
                [self drawFilledStar:ccp(size.width/2 + layerOffset.x, size.height/2 + layerOffset.y) 
                              radius:MIN(size.width, size.height) * 0.4f 
                               color:shadowCol];
                break;
            case 5: // PILL
                [self drawFilledPill:layerOffset size:size color:shadowCol];
                break;
            case 6: // TRIANGLE
                [self drawFilledTriangle:ccp(size.width/2 + layerOffset.x, size.height/2 + layerOffset.y) 
                                  radius:MIN(size.width, size.height)/2 
                                   color:shadowCol];
                break;
            default:
                [self drawFilledRoundedRect:layerOffset size:size radius:radius color:shadowCol];
                break;
        }
    }
}

- (void)drawButtonShape:(CGSize)size
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Use pressed colors if button is pressed and autoDarkenOnPress is enabled
    ccColor3B useStartColor = startColor;
    ccColor3B useEndColor = endColor;
    GLubyte useStartOpacity = startOpacity;
    GLubyte useEndOpacity = endOpacity;
    
    if (isPressed && autoDarkenOnPress) {
        useStartColor = pressedStartColor;
        useEndColor = pressedEndColor;
    }
    
    // Temporarily set the colors for drawing
    ccColor3B originalStart = startColor;
    ccColor3B originalEnd = endColor;
    GLubyte originalStartOpacity = startOpacity;
    GLubyte originalEndOpacity = endOpacity;
    
    startColor = useStartColor;
    endColor = useEndColor;
    startOpacity = useStartOpacity;
    endOpacity = useEndOpacity;
    
    // Draw filled shape with gradient
    switch (shape) {
        case 0: // ROUNDED_RECT
            [self drawFilledRoundedRectGradient:CGPointZero size:size radius:radius];
            break;
        case 1: // CIRCLE
            [self drawFilledCircleGradient:ccp(size.width/2, size.height/2) 
                                    radius:MIN(size.width, size.height)/2];
            break;
        case 2: // HEXAGON
            [self drawFilledHexagon:ccp(size.width/2, size.height/2) 
                             radius:MIN(size.width, size.height)/2 - radius];
            break;
        case 3: // DIAMOND
            [self drawFilledDiamond:ccp(size.width/2, size.height/2) 
                               size:MIN(size.width, size.height) * 0.7f];
            break;
        case 4: // STAR
            [self drawFilledStar:ccp(size.width/2, size.height/2) 
                          radius:MIN(size.width, size.height) * 0.4f];
            break;
        case 5: // PILL
            [self drawFilledPillGradient:CGPointZero size:size];
            break;
        case 6: // TRIANGLE
            [self drawFilledTriangleGradient:ccp(size.width/2, size.height/2) 
                                      radius:MIN(size.width, size.height)/2];
            break;
    }
    
    // Restore original colors
    startColor = originalStart;
    endColor = originalEnd;
    startOpacity = originalStartOpacity;
    endOpacity = originalEndOpacity;
    
    // Draw outline if width > 0
    if (self.outlineWidth > 0) {
        glLineWidth(self.outlineWidth);
        
        switch (shape) {
            case 0: // ROUNDED_RECT
                [self drawRoundedRectOutlineGradient:CGPointZero size:size radius:radius];
                break;
            case 1: // CIRCLE
                [self drawCircleOutlineGradient:ccp(size.width/2, size.height/2) 
                                          radius:MIN(size.width, size.height)/2];
                break;
            case 2: // HEXAGON
                [self drawHexagonOutlineGradient:ccp(size.width/2, size.height/2) 
                                           radius:MIN(size.width, size.height)/2 - radius];
                break;
            case 3: // DIAMOND
                [self drawDiamondOutlineGradient:ccp(size.width/2, size.height/2) 
                                             size:MIN(size.width, size.height) * 0.7f];
                break;
            case 4: // STAR
                [self drawStarOutlineGradient:ccp(size.width/2, size.height/2) 
                                       radius:MIN(size.width, size.height) * 0.4f];
                break;
            case 5: // PILL
                [self drawPillOutlineGradient:CGPointZero size:size];
                break;
            case 6: // TRIANGLE
                [self drawTriangleOutlineGradient:ccp(size.width/2, size.height/2) 
                                            radius:MIN(size.width, size.height)/2];
                break;
        }
        glLineWidth(1.0f);
    }
}

// Include all the drawing helper methods from CCCustomShape
#pragma mark - Drawing Helper Methods

- (void)drawPolyOutlineGradient:(CGPoint*)vertices count:(int)count
{
    if (count <= 0) return;
    
    ccColor4F *colors = malloc(sizeof(ccColor4F) * count);
    ccVertex2F *glVertices = malloc(sizeof(ccVertex2F) * count);
    
    float h = ccpLength(gradientVector);
    
    float c = sqrtf(2);
    CGPoint u = CGPointZero;
    if (h > 0) {
        u = ccp(gradientVector.x / h, gradientVector.y / h);
        float h2 = 1 / ( fabsf(u.x) + fabsf(u.y) );
        u = ccpMult(u, h2 * c);
    }
    
    CGSize size = self.contentSize;
    if (size.width == 0) size = CGSizeMake(100, 40);
    CGPoint center = ccp(size.width/2, size.height/2);
    
    for (int i = 0; i < count; i++) {
        glVertices[i] = (ccVertex2F){ (GLfloat)vertices[i].x, (GLfloat)vertices[i].y };
        
        if (h == 0) {
            colors[i] = ccc4f(outlineStartColor.r/255.0f, outlineStartColor.g/255.0f, outlineStartColor.b/255.0f, outlineStartOpacity/255.0f);
        } else {
            float nx = (vertices[i].x - center.x) / (size.width/2);
            float ny = (vertices[i].y - center.y) / (size.height/2);
            
            float t = 0.5f + (nx * -u.x + ny * -u.y) / (2.0f * c);
            t = clampf(t, 0.0f, 1.0f);
            
            colors[i].r = (outlineEndColor.r + (outlineStartColor.r - outlineEndColor.r) * t) / 255.0f;
            colors[i].g = (outlineEndColor.g + (outlineStartColor.g - outlineEndColor.g) * t) / 255.0f;
            colors[i].b = (outlineEndColor.b + (outlineStartColor.b - outlineEndColor.b) * t) / 255.0f;
            colors[i].a = (outlineEndOpacity + (outlineStartOpacity - outlineEndOpacity) * t) / 255.0f;
        }
    }
    
    CC_NODE_DRAW_SETUP();
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, glVertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0, colors);
    glDrawArrays(GL_LINE_LOOP, 0, count);
    
    free(colors);
    free(glVertices);
}

- (void)drawPolyGradient:(CGPoint*)vertices count:(int)count
{
    ccColor4F *colors = malloc(sizeof(ccColor4F) * count);
    ccVertex2F *glVertices = malloc(sizeof(ccVertex2F) * count);
    
    float h = ccpLength(gradientVector);
    
    float c = sqrtf(2);
    CGPoint u = CGPointZero;
    if (h > 0) {
        u = ccp(gradientVector.x / h, gradientVector.y / h);
        float h2 = 1 / ( fabsf(u.x) + fabsf(u.y) );
        u = ccpMult(u, h2 * c);
    }
    
    CGSize size = self.contentSize;
    if (size.width == 0) size = CGSizeMake(100, 40);
    CGPoint center = ccp(size.width/2, size.height/2);
    
    for (int i = 0; i < count; i++) {
        glVertices[i] = (ccVertex2F){ (GLfloat)vertices[i].x, (GLfloat)vertices[i].y };
        
        if (h == 0) {
            colors[i] = ccc4f(startColor.r/255.0f, startColor.g/255.0f, startColor.b/255.0f, startOpacity/255.0f);
        } else {
            float nx = (vertices[i].x - center.x) / (size.width/2);
            float ny = (vertices[i].y - center.y) / (size.height/2);
            
            float t = 0.5f + (nx * -u.x + ny * -u.y) / (2.0f * c);
            t = clampf(t, 0.0f, 1.0f);
            
            colors[i].r = (endColor.r + (startColor.r - endColor.r) * t) / 255.0f;
            colors[i].g = (endColor.g + (startColor.g - endColor.g) * t) / 255.0f;
            colors[i].b = (endColor.b + (startColor.b - endColor.b) * t) / 255.0f;
            colors[i].a = (endOpacity + (startOpacity - endOpacity) * t) / 255.0f;
        }
    }
    
    CC_NODE_DRAW_SETUP();
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, glVertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0, colors);
    glDrawArrays(GL_TRIANGLE_FAN, 0, count);
    
    free(colors);
    free(glVertices);
}

// Import all shape drawing methods from CCCustomShape.m
- (void)drawFilledRoundedRectGradient:(CGPoint)origin size:(CGSize)size radius:(float)r
{
    int segments = 30;
    int totalVerts = 4 * segments + 2;
    CGPoint *vertices = malloc(sizeof(CGPoint) * totalVerts);
    
    vertices[0] = ccp(origin.x + size.width/2, origin.y + size.height/2);
    
    int vIndex = 1;
    CGPoint corners[4] = {
        ccp(origin.x + size.width - r, origin.y + size.height - r),
        ccp(origin.x + r, origin.y + size.height - r),
        ccp(origin.x + r, origin.y + r),
        ccp(origin.x + size.width - r, origin.y + r)
    };
    
    for (int c = 0; c < 4; c++) {
        float startAngle = c * M_PI / 2.0f;
        for (int i = 0; i < segments; i++) {
            float angle = startAngle + (float)i / (segments - 1) * (M_PI / 2.0f);
            vertices[vIndex++] = ccp(corners[c].x + cos(angle) * r, corners[c].y + sin(angle) * r);
        }
    }
    vertices[vIndex] = vertices[1];
    
    [self drawPolyGradient:vertices count:totalVerts];
    free(vertices);
}

- (void)drawFilledRoundedRect:(CGPoint)origin size:(CGSize)size radius:(float)r color:(ccColor4F)color
{
    int segments = 30;
    int totalVerts = 4 * segments + 2;
    CGPoint *vertices = malloc(sizeof(CGPoint) * totalVerts);
    
    vertices[0] = ccp(origin.x + size.width/2, origin.y + size.height/2);
    
    int vIndex = 1;
    CGPoint corners[4] = {
        ccp(origin.x + size.width - r, origin.y + size.height - r),
        ccp(origin.x + r, origin.y + size.height - r),
        ccp(origin.x + r, origin.y + r),
        ccp(origin.x + size.width - r, origin.y + r)
    };
    
    for (int c = 0; c < 4; c++) {
        float startAngle = c * M_PI / 2.0f;
        for (int i = 0; i < segments; i++) {
            float angle = startAngle + (float)i / (segments - 1) * (M_PI / 2.0f);
            vertices[vIndex++] = ccp(corners[c].x + cos(angle) * r, corners[c].y + sin(angle) * r);
        }
    }
    vertices[vIndex] = vertices[1];
    
    ccDrawSolidPoly(vertices, totalVerts, color);
    free(vertices);
}

// Circle drawing methods
- (void)drawFilledCircleGradient:(CGPoint)center radius:(float)r
{
    int segments = 60;
    CGPoint *vertices = malloc(sizeof(CGPoint) * (segments + 2));
    vertices[0] = center;
    
    for (int i = 0; i <= segments; i++) {
        float angle = (float)i / (float)segments * M_PI * 2.0f;
        vertices[i+1] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    [self drawPolyGradient:vertices count:segments+2];
    free(vertices);
}

- (void)drawFilledCircle:(CGPoint)center radius:(float)r color:(ccColor4F)color
{
    int segments = 30;
    CGPoint *vertices = malloc(sizeof(CGPoint) * segments);
    
    for (int i = 0; i < segments; i++) {
        float angle = (float)i / (float)segments * M_PI * 2.0f;
        vertices[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    ccDrawSolidPoly(vertices, segments, color);
    free(vertices);
}

// Hexagon drawing methods
- (void)drawFilledHexagon:(CGPoint)center radius:(float)r
{
    CGPoint vertices[8];
    vertices[0] = center;
    for (int i = 0; i < 7; i++) {
        float angle = M_PI / 3.0f * i - M_PI / 2.0f;
        vertices[i+1] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    [self drawPolyGradient:vertices count:8];
}

- (void)drawFilledHexagon:(CGPoint)center radius:(float)r color:(ccColor4F)color
{
    CGPoint vertices[7];
    for (int i = 0; i < 7; i++) {
        float angle = M_PI / 3.0f * i - M_PI / 2.0f;
        vertices[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    ccDrawSolidPoly(vertices, 7, color);
}

// Diamond drawing methods
- (void)drawFilledDiamond:(CGPoint)center size:(float)s
{
    CGPoint vertices[6];
    vertices[0] = center;
    vertices[1] = ccp(center.x, center.y + s/2);
    vertices[2] = ccp(center.x + s/2, center.y);
    vertices[3] = ccp(center.x, center.y - s/2);
    vertices[4] = ccp(center.x - s/2, center.y);
    vertices[5] = vertices[1];
    
    [self drawPolyGradient:vertices count:6];
}

- (void)drawFilledDiamond:(CGPoint)center size:(float)s color:(ccColor4F)color
{
    CGPoint vertices[5] = {
        ccp(center.x, center.y + s/2),
        ccp(center.x + s/2, center.y),
        ccp(center.x, center.y - s/2),
        ccp(center.x - s/2, center.y),
        ccp(center.x, center.y + s/2)
    };
    ccDrawSolidPoly(vertices, 5, color);
}

// Star drawing methods
- (void)drawFilledStar:(CGPoint)center radius:(float)r
{
    int points = 5;
    CGPoint vertices[12];
    vertices[0] = center;
    for (int i = 0; i < points * 2; i++) {
        float angle = M_PI * i / points - M_PI / 2.0f;
        float currentR = (i % 2 == 0) ? r : r * 0.4f;
        vertices[i+1] = ccp(center.x + cos(angle) * currentR, center.y + sin(angle) * currentR);
    }
    vertices[11] = vertices[1];
    
    [self drawPolyGradient:vertices count:12];
}

- (void)drawFilledStar:(CGPoint)center radius:(float)r color:(ccColor4F)color
{
    int points = 5;
    CGPoint vertices[11];
    for (int i = 0; i < points * 2; i++) {
        float angle = M_PI * i / points - M_PI / 2.0f;
        float currentR = (i % 2 == 0) ? r : r * 0.4f;
        vertices[i] = ccp(center.x + cos(angle) * currentR, center.y + sin(angle) * currentR);
    }
    vertices[10] = vertices[0];
    ccDrawSolidPoly(vertices, 11, color);
}

// Pill drawing methods
- (void)drawFilledPillGradient:(CGPoint)origin size:(CGSize)size
{
    float r;
    if (size.width > size.height) {
        r = size.height / 2.0f;
    } else {
        r = size.width / 2.0f;
    }
    
    [self drawFilledRoundedRectGradient:origin size:size radius:r];
}

- (void)drawFilledPill:(CGPoint)origin size:(CGSize)size color:(ccColor4F)color
{
    float r;
    if (size.width > size.height) {
        r = size.height / 2.0f;
    } else {
        r = size.width / 2.0f;
    }
    [self drawFilledRoundedRect:origin size:size radius:r color:color];
}

// Triangle drawing methods
- (void)drawFilledTriangleGradient:(CGPoint)center radius:(float)r
{
    CGPoint corners[3];
    for (int i = 0; i < 3; i++) {
        float angle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
        corners[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    float cornerRadius = self.radius;
    if (cornerRadius > r / 2.0f) cornerRadius = r / 2.0f;
    if (cornerRadius < 0) cornerRadius = 0;
    
    if (cornerRadius < 1.0f) {
        [self drawPolyGradient:corners count:3];
        return;
    }
    
    int segmentsPerCorner = 15;
    int totalVerts = 3 * segmentsPerCorner + 2;
    CGPoint *vertices = malloc(sizeof(CGPoint) * totalVerts);
    vertices[0] = center;
    int vIndex = 1;
    
    for (int i = 0; i < 3; i++) {
        CGPoint p = corners[i];
        CGPoint v = ccpSub(p, center);
        float len = ccpLength(v);
        CGPoint dir = ccpMult(v, 1.0f/len);
        CGPoint arcCenter = ccpSub(p, ccpMult(dir, 2.0f * cornerRadius));
        
        float cornerAngle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
        float startAngle = cornerAngle + M_PI - M_PI/3.0f;
        float endAngle = cornerAngle + M_PI + M_PI/3.0f;
        
        for (int j = 0; j < segmentsPerCorner; j++) {
            float t = (float)j / (segmentsPerCorner - 1);
            float a = startAngle + t * (endAngle - startAngle);
            vertices[vIndex++] = ccp(arcCenter.x + cos(a) * cornerRadius, arcCenter.y + sin(a) * cornerRadius);
        }
    }
    vertices[vIndex] = vertices[1];
    
    [self drawPolyGradient:vertices count:vIndex+1];
    free(vertices);
}

- (void)drawFilledTriangle:(CGPoint)center radius:(float)r color:(ccColor4F)color
{
    CGPoint corners[3];
    for (int i = 0; i < 3; i++) {
        float angle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
        corners[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    float cornerRadius = self.radius;
    if (cornerRadius > r / 2.0f) cornerRadius = r / 2.0f;
    if (cornerRadius < 0) cornerRadius = 0;
    
    if (cornerRadius < 1.0f) {
        ccDrawSolidPoly(corners, 3, color);
        return;
    }
    
    int segmentsPerCorner = 15;
    int totalVerts = 3 * segmentsPerCorner;
    CGPoint *vertices = malloc(sizeof(CGPoint) * totalVerts);
    int vIndex = 0;
    
    for (int i = 0; i < 3; i++) {
        CGPoint p = corners[i];
        CGPoint v = ccpSub(p, center);
        float len = ccpLength(v);
        CGPoint dir = ccpMult(v, 1.0f/len);
        CGPoint arcCenter = ccpSub(p, ccpMult(dir, 2.0f * cornerRadius));
        
        float cornerAngle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
        float startAngle = cornerAngle + M_PI - M_PI/3.0f;
        float endAngle = cornerAngle + M_PI + M_PI/3.0f;
        
        for (int j = 0; j < segmentsPerCorner; j++) {
            float aT = (float)j / (segmentsPerCorner - 1);
            float a = startAngle + aT * (endAngle - startAngle);
            vertices[vIndex++] = ccp(arcCenter.x + cos(a) * cornerRadius, arcCenter.y + sin(a) * cornerRadius);
        }
    }
    
    ccDrawSolidPoly(vertices, totalVerts, color);
    free(vertices);
}

// Outline drawing methods
- (void)drawRoundedRectOutlineGradient:(CGPoint)origin size:(CGSize)size radius:(float)r
{
    int segments = 30;
    int totalVerts = 4 * segments;
    CGPoint *vertices = malloc(sizeof(CGPoint) * totalVerts);
    
    int vIndex = 0;
    CGPoint corners[4] = {
        ccp(origin.x + size.width - r, origin.y + size.height - r),
        ccp(origin.x + r, origin.y + size.height - r),
        ccp(origin.x + r, origin.y + r),
        ccp(origin.x + size.width - r, origin.y + r)
    };
    
    for (int c = 0; c < 4; c++) {
        float startAngle = c * M_PI / 2.0f;
        for (int i = 0; i < segments; i++) {
            float angle = startAngle + (float)i / (segments - 1) * (M_PI / 2.0f);
            vertices[vIndex++] = ccp(corners[c].x + cos(angle) * r, corners[c].y + sin(angle) * r);
        }
    }
    
    [self drawPolyOutlineGradient:vertices count:totalVerts];
    free(vertices);
}

- (void)drawCircleOutlineGradient:(CGPoint)center radius:(float)r
{
    int segments = 60;
    CGPoint *vertices = malloc(sizeof(CGPoint) * segments);
    
    for (int i = 0; i < segments; i++) {
        float angle = (float)i / (float)segments * M_PI * 2.0f;
        vertices[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    [self drawPolyOutlineGradient:vertices count:segments];
    free(vertices);
}

- (void)drawHexagonOutlineGradient:(CGPoint)center radius:(float)r
{
    CGPoint vertices[6];
    for (int i = 0; i < 6; i++) {
        float angle = M_PI / 3.0f * i - M_PI / 2.0f;
        vertices[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    [self drawPolyOutlineGradient:vertices count:6];
}

- (void)drawDiamondOutlineGradient:(CGPoint)center size:(float)s
{
    CGPoint vertices[4] = {
        ccp(center.x, center.y + s/2),
        ccp(center.x + s/2, center.y),
        ccp(center.x, center.y - s/2),
        ccp(center.x - s/2, center.y)
    };
    [self drawPolyOutlineGradient:vertices count:4];
}

- (void)drawStarOutlineGradient:(CGPoint)center radius:(float)r
{
    int points = 5;
    CGPoint vertices[10];
    for (int i = 0; i < points * 2; i++) {
        float angle = M_PI * i / points - M_PI / 2.0f;
        float currentR = (i % 2 == 0) ? r : r * 0.4f;
        vertices[i] = ccp(center.x + cos(angle) * currentR, center.y + sin(angle) * currentR);
    }
    [self drawPolyOutlineGradient:vertices count:10];
}

- (void)drawPillOutlineGradient:(CGPoint)origin size:(CGSize)size
{
    float r;
    if (size.width > size.height) {
        r = size.height / 2.0f;
    } else {
        r = size.width / 2.0f;
    }
    [self drawRoundedRectOutlineGradient:origin size:size radius:r];
}

- (void)drawTriangleOutlineGradient:(CGPoint)center radius:(float)r
{
    CGPoint corners[3];
    for (int i = 0; i < 3; i++) {
        float angle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
        corners[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    float cornerRadius = self.radius;
    if (cornerRadius > r / 2.0f) cornerRadius = r / 2.0f;
    if (cornerRadius < 0) cornerRadius = 0;
    
    if (cornerRadius < 1.0f) {
        [self drawPolyOutlineGradient:corners count:3];
        return;
    }
    
    int segmentsPerCorner = 15;
    int totalVerts = 3 * segmentsPerCorner;
    CGPoint *vertices = malloc(sizeof(CGPoint) * totalVerts);
    int vIndex = 0;
    
    for (int i = 0; i < 3; i++) {
        CGPoint p = corners[i];
        CGPoint v = ccpSub(p, center);
        float len = ccpLength(v);
        CGPoint dir = ccpMult(v, 1.0f/len);
        CGPoint arcCenter = ccpSub(p, ccpMult(dir, 2.0f * cornerRadius));
        
        float cornerAngle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
        float startAngle = cornerAngle + M_PI - M_PI/3.0f;
        float endAngle = cornerAngle + M_PI + M_PI/3.0f;
        
        for (int j = 0; j < segmentsPerCorner; j++) {
            float t = (float)j / (segmentsPerCorner - 1);
            float a = startAngle + t * (endAngle - startAngle);
            vertices[vIndex++] = ccp(arcCenter.x + cos(a) * cornerRadius, arcCenter.y + sin(a) * cornerRadius);
        }
    }
    
    [self drawPolyOutlineGradient:vertices count:totalVerts];
    free(vertices);
}

#pragma mark - KVC Compliance

- (id)valueForKey:(NSString *)key
{
    if ([key isEqualToString:@"startColor"]) return [NSValue value:&startColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"endColor"]) return [NSValue value:&endColor withObjCType:@encode(ccColor3B)];
    // outlineColor and shadowColor are handled by parent class
    if ([key isEqualToString:@"outlineStartColor"]) return [NSValue value:&outlineStartColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"outlineEndColor"]) return [NSValue value:&outlineEndColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"pressedStartColor"]) return [NSValue value:&pressedStartColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"pressedEndColor"]) return [NSValue value:&pressedEndColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"Text"]) return @""; // Separator property, return empty string
    if ([key isEqualToString:@"title|1"]) return [(CCLabelTTF*)self.titleLabel string];
    
    return [super valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    NSLog(@"CCCustomButton setValue:%@ forKey:%@", value, key);
    if ([key isEqualToString:@"startColor"]) { ccColor3B c; [value getValue:&c]; self.startColor = c; return; }
    if ([key isEqualToString:@"endColor"]) { ccColor3B c; [value getValue:&c]; self.endColor = c; return; }
    if ([key isEqualToString:@"outlineColor"]) { ccColor3B c; [value getValue:&c]; self.outlineColor = c; return; }
    if ([key isEqualToString:@"outlineStartColor"]) { ccColor3B c; [value getValue:&c]; self.outlineStartColor = c; return; }
    if ([key isEqualToString:@"outlineEndColor"]) { ccColor3B c; [value getValue:&c]; self.outlineEndColor = c; return; }
    if ([key isEqualToString:@"shadowColor"]) { ccColor3B c; [value getValue:&c]; self.shadowColor = c; return; }
    if ([key isEqualToString:@"pressedStartColor"]) { ccColor3B c; [value getValue:&c]; self.pressedStartColor = c; return; }
    if ([key isEqualToString:@"pressedEndColor"]) { ccColor3B c; [value getValue:&c]; self.pressedEndColor = c; return; }
    if ([key isEqualToString:@"fontColor"]) { ccColor3B c; [value getValue:&c]; self.fontColor = c; return; }

    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"title|1"])
    {
        NSString* str = value;
        if (str && [str length] > 0)
        {
            [(CCLabelTTF*)self.titleLabel setString:str];
        }
        return;
    }
    else if ([key isEqualToString:@"titleTTF|1"])
    {
        NSString* fontName = value;
        if (fontName && [fontName length] > 0)
        {
            [(CCLabelTTF*)self.titleLabel setFontName:fontName];
        }
        return;
    }
    else if ([key isEqualToString:@"titleTTFSize|1"])
    {
        CGFloat fontSize = [value floatValue];
        if (fontSize > 0)
        {
            [(CCLabelTTF*)self.titleLabel setFontSize:fontSize];
        }
        return;
    }
    
    [super setValue:value forUndefinedKey:key];
}

- (id) getLabel
{
    id label = self.titleLabel;
    if (label) {
        [label setFontFillColor:self.fontColor updateImage:NO];
    }
    return label;
}

- (void) setOutlineColor:(ccColor3B)outlineClr
{
    outlineColor = outlineClr;
    id label = [self getLabel];
    if (!label) return;
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
    if (!label) return;
    [label enableShadowWithOffset:CGSizeMake(shadowOffset.x, shadowOffset.y) opacity:shadowOpacity blur:shadowBlurRadius updateImage:YES];
}

- (void) setShadowColor:(ccColor3B)shadowClr
{
    shadowColor = shadowClr;
    id label = self.titleLabel;
    if (!label) return;
    [label enableShadowWithOffset:CGSizeMake(shadowOffset.x, shadowOffset.y) opacity:shadowOpacity blur:shadowBlurRadius updateImage:YES];
}

-(void) setShadowBlurRadius:(CGFloat)shadowBlurRad
{
    id label = self.titleLabel;
    if (!label) return;
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
    if (!label) return;
    if (shadowBlurRadius > 0) {
        [label enableShadowWithOffset:CGSizeMake(shadowOffset.x, shadowOffset.y) opacity:shadowOpacity blur:shadowBlurRadius updateImage:YES];
    }
}

@end
