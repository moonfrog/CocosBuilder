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

#import "CCCustomShape.h"
#import "CCShaderCache.h"
#import "CCGLProgram.h"
#import "ccGLStateCache.h"

@implementation CCCustomShape

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

// This method is called when the class is loaded - before any instances are created
+ (void)load
{
    // Force the Objective-C runtime to register this class
    NSLog(@"CCCustomShape +load called");
}

- (id)init
{
    self = [super init];
    if (!self) return NULL;
    
    // Default values to match the plist defaults
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
    shadowOffset = ccp(2, -2);
    shadowBlur = 0.0f;
    autoDarkenOnPress = YES;
    pressedScale = 0.95f;
    pressedStartColor = ccc3(200, 200, 200);
    pressedEndColor = ccc3(150, 150, 150);
    shape = 0; // ROUNDED_RECT
    
    // Initialize shader program for drawing
    self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];
    
    return self;
}

- (void) draw
{
    [super draw];
    
    CGSize size = self.contentSize;
    if (size.width == 0 || size.height == 0) {
        size = CGSizeMake(100, 40); // Default size
    }
    
    // Draw shadow first (behind button)
    if (self.shadowBlur > 0 && self.shadowColor.r + self.shadowColor.g + self.shadowColor.b > 0) {
        [self drawShadow:size];
    }
    
    // Draw the button shape with gradient and outline
    [self drawButtonShape:size];
}

- (void)drawShadow:(CGSize)size
{
    // Approximate shadow with semi-transparent shapes
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    CGPoint offset = self.shadowOffset;
    float blur = self.shadowBlur;
    
    // Draw multiple layers for blur effect
    int layers = MIN(5, (int)blur);
    if (layers < 1) layers = 1; // At least one layer if blur is 0 but shadow is enabled
    
    for (int i = 0; i < layers; i++) {
        float t = (float)i / (float)layers;
        // Alpha fades out for outer layers
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
    
    // glDisable(GL_BLEND);
}

- (void)drawButtonShape:(CGSize)size
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
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
    
    // glDisable(GL_BLEND);
}

- (void)drawPolyOutlineGradient:(CGPoint*)vertices count:(int)count
{
    if (count <= 0) return;
    
    // Calculate colors for each vertex based on gradient vector
    ccColor4F *colors = malloc(sizeof(ccColor4F) * count);
    ccVertex2F *glVertices = malloc(sizeof(ccVertex2F) * count);
    
    float h = ccpLength(gradientVector);
    
    // Gradient math setup (same as fill gradient)
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
        // Convert to GL float format
        glVertices[i] = (ccVertex2F){ (GLfloat)vertices[i].x, (GLfloat)vertices[i].y };
        
        if (h == 0) {
            // No gradient vector, use start color
            colors[i] = ccc4f(outlineStartColor.r/255.0f, outlineStartColor.g/255.0f, outlineStartColor.b/255.0f, outlineStartOpacity/255.0f);
        } else {
            // Normalize position to [-1, 1]
            float nx = (vertices[i].x - center.x) / (size.width/2);
            float ny = (vertices[i].y - center.y) / (size.height/2);
            
            // Calculate interpolation factor t (0..1)
            float t = 0.5f + (nx * -u.x + ny * -u.y) / (2.0f * c);
            t = clampf(t, 0.0f, 1.0f);
            
            // Interpolate between end and start colors
            colors[i].r = (outlineEndColor.r + (outlineStartColor.r - outlineEndColor.r) * t) / 255.0f;
            colors[i].g = (outlineEndColor.g + (outlineStartColor.g - outlineEndColor.g) * t) / 255.0f;
            colors[i].b = (outlineEndColor.b + (outlineStartColor.b - outlineEndColor.b) * t) / 255.0f;
            colors[i].a = (outlineEndOpacity + (outlineStartOpacity - outlineEndOpacity) * t) / 255.0f;
        }
    }
    
    // Draw using OpenGL
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
    // Calculate colors for each vertex based on gradient vector
    ccColor4F *colors = malloc(sizeof(ccColor4F) * count);
    ccVertex2F *glVertices = malloc(sizeof(ccVertex2F) * count);
    
    float h = ccpLength(gradientVector);
    
    // Gradient math setup
    float c = sqrtf(2);
    CGPoint u = CGPointZero;
    if (h > 0) {
        u = ccp(gradientVector.x / h, gradientVector.y / h);
        // Compressed interpolation
        float h2 = 1 / ( fabsf(u.x) + fabsf(u.y) );
        u = ccpMult(u, h2 * c);
    }
    
    CGSize size = self.contentSize;
    if (size.width == 0) size = CGSizeMake(100, 40);
    CGPoint center = ccp(size.width/2, size.height/2);
    
    for (int i = 0; i < count; i++) {
        // Convert to GL float format
        glVertices[i] = (ccVertex2F){ (GLfloat)vertices[i].x, (GLfloat)vertices[i].y };
        
        if (h == 0) {
            colors[i] = ccc4f(startColor.r/255.0f, startColor.g/255.0f, startColor.b/255.0f, startOpacity/255.0f);
        } else {
            // Normalize position to [-1, 1]
            float nx = (vertices[i].x - center.x) / (size.width/2);
            float ny = (vertices[i].y - center.y) / (size.height/2);
            
            // Calculate interpolation factor t (0..1)
            float t = 0.5f + (nx * -u.x + ny * -u.y) / (2.0f * c);
            t = clampf(t, 0.0f, 1.0f);
            
            colors[i].r = (endColor.r + (startColor.r - endColor.r) * t) / 255.0f;
            colors[i].g = (endColor.g + (startColor.g - endColor.g) * t) / 255.0f;
            colors[i].b = (endColor.b + (startColor.b - endColor.b) * t) / 255.0f;
            colors[i].a = (endOpacity + (startOpacity - endOpacity) * t) / 255.0f;
        }
    }
    
    // Draw using OpenGL
    CC_NODE_DRAW_SETUP();
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, glVertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0, colors);
    glDrawArrays(GL_TRIANGLE_FAN, 0, count);
    
    free(colors);
    free(glVertices);
}

- (void)drawFilledRoundedRectGradient:(CGPoint)origin size:(CGSize)size radius:(float)r
{
    // Generate vertices for rounded rect
    int segments = 30; // Segments per corner
    int totalVerts = 4 * segments + 2; // +2 for center and close
    CGPoint *vertices = malloc(sizeof(CGPoint) * totalVerts);
    
    // Center
    vertices[0] = ccp(origin.x + size.width/2, origin.y + size.height/2);
    
    int vIndex = 1;
    // Corners: TR, TL, BL, BR
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
    vertices[vIndex] = vertices[1]; // Close loop
    
    [self drawPolyGradient:vertices count:totalVerts];
    free(vertices);
}

- (void)drawFilledRoundedRect:(CGPoint)origin size:(CGSize)size radius:(float)r color:(ccColor4F)color
{
    // Generate vertices for rounded rect
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

- (void)drawRoundedRectOutline:(CGPoint)origin size:(CGSize)size radius:(float)r
{
    // Generate vertices for rounded rect outline
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
    
    ccDrawPoly(vertices, totalVerts, YES);
    free(vertices);
}

- (void)drawFilledCircleGradient:(CGPoint)center radius:(float)r
{
    float gradMag = sqrt(gradientVector.x * gradientVector.x + gradientVector.y * gradientVector.y);
    BOOL isRadial = (gradMag < 0.01f);
    
    if (isRadial) {
        // Keep existing radial implementation
        int layers = 15;
        for (int layer = 0; layer < layers; layer++) {
            float t = (float)layer / (float)layers;
            ccColor4F color;
            color.r = (startColor.r + t * (endColor.r - startColor.r)) / 255.0f;
            color.g = (startColor.g + t * (endColor.g - startColor.g)) / 255.0f;
            color.b = (startColor.b + t * (endColor.b - startColor.b)) / 255.0f;
            color.a = (startOpacity + t * (endOpacity - startOpacity)) / 255.0f;
            
            float layerRadius = r * (1.0f - t);
            int segments = 30;
            CGPoint *vertices = malloc(sizeof(CGPoint) * segments);
            for (int i = 0; i < segments; i++) {
                float angle = (float)i / (float)segments * M_PI * 2.0f;
                vertices[i] = ccp(center.x + cos(angle) * layerRadius, center.y + sin(angle) * layerRadius);
            }
            ccDrawSolidPoly(vertices, segments, color);
            free(vertices);
        }
    } else {
        // Linear gradient using drawPolyGradient
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

- (void)drawFilledHexagon:(CGPoint)center radius:(float)r color:(ccColor4F)color
{
    CGPoint vertices[7];
    for (int i = 0; i < 7; i++) {
        float angle = M_PI / 3.0f * i - M_PI / 2.0f;
        vertices[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    ccDrawSolidPoly(vertices, 7, color);
}

- (void)drawFilledHexagon:(CGPoint)center radius:(float)r
{
    float gradMag = sqrt(gradientVector.x * gradientVector.x + gradientVector.y * gradientVector.y);
    BOOL isRadial = (gradMag < 0.01f);
    
    if (isRadial) {
        // Keep radial implementation
        int layers = 10;
        for (int layer = 0; layer < layers; layer++) {
            float t = (float)layer / (float)layers;
            ccColor4F color;
            color.r = (startColor.r + t * (endColor.r - startColor.r)) / 255.0f;
            color.g = (startColor.g + t * (endColor.g - startColor.g)) / 255.0f;
            color.b = (startColor.b + t * (endColor.b - startColor.b)) / 255.0f;
            color.a = (startOpacity + t * (endOpacity - startOpacity)) / 255.0f;
            
            float layerRadius = r * (1.0f - t);
            CGPoint layerVerts[7];
            for (int i = 0; i < 7; i++) {
                float angle = M_PI / 3.0f * i - M_PI / 2.0f;
                layerVerts[i] = ccp(center.x + cos(angle) * layerRadius, center.y + sin(angle) * layerRadius);
            }
            ccDrawSolidPoly(layerVerts, 7, color);
        }
    } else {
        // Linear gradient using drawPolyGradient
        CGPoint vertices[8];
        vertices[0] = center;
        for (int i = 0; i < 7; i++) {
            float angle = M_PI / 3.0f * i - M_PI / 2.0f;
            vertices[i+1] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
        }
        [self drawPolyGradient:vertices count:8];
    }
}

- (void)drawHexagonOutline:(CGPoint)center radius:(float)r
{
    CGPoint vertices[7];
    for (int i = 0; i < 7; i++) {
        float angle = M_PI / 3.0f * i - M_PI / 2.0f;
        vertices[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    ccDrawPoly(vertices, 7, YES);
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

- (void)drawFilledDiamond:(CGPoint)center size:(float)s
{
    float gradMag = sqrt(gradientVector.x * gradientVector.x + gradientVector.y * gradientVector.y);
    BOOL isRadial = (gradMag < 0.01f);
    
    if (isRadial) {
        // Keep radial implementation
        int layers = 10;
        for (int layer = 0; layer < layers; layer++) {
            float t = (float)layer / (float)layers;
            ccColor4F color;
            color.r = (startColor.r + t * (endColor.r - startColor.r)) / 255.0f;
            color.g = (startColor.g + t * (endColor.g - startColor.g)) / 255.0f;
            color.b = (startColor.b + t * (endColor.b - startColor.b)) / 255.0f;
            color.a = (startOpacity + t * (endOpacity - startOpacity)) / 255.0f;
            
            float layerSize = s * (1.0f - t);
            CGPoint vertices[5] = {
                ccp(center.x, center.y + layerSize/2),
                ccp(center.x + layerSize/2, center.y),
                ccp(center.x, center.y - layerSize/2),
                ccp(center.x - layerSize/2, center.y),
                ccp(center.x, center.y + layerSize/2)
            };
            ccDrawSolidPoly(vertices, 5, color);
        }
    } else {
        // Linear gradient using drawPolyGradient
        CGPoint vertices[6];
        vertices[0] = center;
        vertices[1] = ccp(center.x, center.y + s/2);
        vertices[2] = ccp(center.x + s/2, center.y);
        vertices[3] = ccp(center.x, center.y - s/2);
        vertices[4] = ccp(center.x - s/2, center.y);
        vertices[5] = vertices[1];
        
        [self drawPolyGradient:vertices count:6];
    }
}

- (void)drawDiamondOutline:(CGPoint)center size:(float)s
{
    CGPoint vertices[5] = {
        ccp(center.x, center.y + s/2),
        ccp(center.x + s/2, center.y),
        ccp(center.x, center.y - s/2),
        ccp(center.x - s/2, center.y),
        ccp(center.x, center.y + s/2)
    };
    ccDrawPoly(vertices, 5, NO);
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

- (void)drawFilledStar:(CGPoint)center radius:(float)r
{
    float gradMag = sqrt(gradientVector.x * gradientVector.x + gradientVector.y * gradientVector.y);
    BOOL isRadial = (gradMag < 0.01f);
    int points = 5;
    
    if (isRadial) {
        // Keep radial implementation
        int layers = 10;
        for (int layer = 0; layer < layers; layer++) {
            float t = (float)layer / (float)layers;
            ccColor4F color;
            color.r = (startColor.r + t * (endColor.r - startColor.r)) / 255.0f;
            color.g = (startColor.g + t * (endColor.g - startColor.g)) / 255.0f;
            color.b = (startColor.b + t * (endColor.b - startColor.b)) / 255.0f;
            color.a = (startOpacity + t * (endOpacity - startOpacity)) / 255.0f;
            
            float layerRadius = r * (1.0f - t);
            CGPoint vertices[11];
            for (int i = 0; i < points * 2; i++) {
                float angle = M_PI * i / points - M_PI / 2.0f;
                float currentR = (i % 2 == 0) ? layerRadius : layerRadius * 0.4f;
                vertices[i] = ccp(center.x + cos(angle) * currentR, center.y + sin(angle) * currentR);
            }
            vertices[10] = vertices[0];
            ccDrawSolidPoly(vertices, 11, color);
        }
    } else {
        // Linear gradient using drawPolyGradient
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
}

- (void)drawStarOutline:(CGPoint)center radius:(float)r
{
    int points = 5;
    CGPoint vertices[11];
    for (int i = 0; i < points * 2; i++) {
        float angle = M_PI * i / points - M_PI / 2.0f;
        float currentR = (i % 2 == 0) ? r : r * 0.4f;
        vertices[i] = ccp(center.x + cos(angle) * currentR, center.y + sin(angle) * currentR);
    }
    vertices[10] = vertices[0]; // Close the shape
    ccDrawPoly(vertices, 11, NO);
}

- (void)drawFilledPillGradient:(CGPoint)origin size:(CGSize)size
{
    // Pill is just a rounded rect with maximum radius
    float r;
    if (size.width > size.height) {
        r = size.height / 2.0f;
    } else {
        r = size.width / 2.0f;
    }
    
    [self drawFilledRoundedRectGradient:origin size:size radius:r];
}

- (void)drawFilledTriangle:(CGPoint)center radius:(float)r color:(ccColor4F)color
{
    // Triangle vertices (equilateral pointing up)
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

- (void)drawFilledTriangleGradient:(CGPoint)center radius:(float)r
{
    float gradMag = sqrt(gradientVector.x * gradientVector.x + gradientVector.y * gradientVector.y);
    BOOL isRadial = (gradMag < 0.01f);
    
    if (isRadial) {
        // Radial gradient: concentric rounded triangles
        int layers = 15;
        for (int layer = 0; layer < layers; layer++) {
            float t = (float)layer / (float)layers;
            ccColor4F color;
            color.r = (startColor.r + t * (endColor.r - startColor.r)) / 255.0f;
            color.g = (startColor.g + t * (endColor.g - startColor.g)) / 255.0f;
            color.b = (startColor.b + t * (endColor.b - startColor.b)) / 255.0f;
            color.a = (startOpacity + t * (endOpacity - startOpacity)) / 255.0f;
            
            float layerRadius = r * (1.0f - t);
            float layerCornerRadius = self.radius * (1.0f - t);
            if (layerCornerRadius > layerRadius / 2.0f) layerCornerRadius = layerRadius / 2.0f;
            
            // Generate vertices for this layer
            CGPoint corners[3];
            for (int i = 0; i < 3; i++) {
                float angle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
                corners[i] = ccp(center.x + cos(angle) * layerRadius, center.y + sin(angle) * layerRadius);
            }
            
            if (layerCornerRadius < 0.5f) {
                ccDrawSolidPoly(corners, 3, color);
                continue;
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
                CGPoint arcCenter = ccpSub(p, ccpMult(dir, 2.0f * layerCornerRadius));
                
                float cornerAngle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
                float startAngle = cornerAngle + M_PI - M_PI/3.0f;
                float endAngle = cornerAngle + M_PI + M_PI/3.0f;
                
                for (int j = 0; j < segmentsPerCorner; j++) {
                    float aT = (float)j / (segmentsPerCorner - 1);
                    float a = startAngle + aT * (endAngle - startAngle);
                    vertices[vIndex++] = ccp(arcCenter.x + cos(a) * layerCornerRadius, arcCenter.y + sin(a) * layerCornerRadius);
                }
            }
            ccDrawSolidPoly(vertices, totalVerts, color);
            free(vertices);
        }
        return;
    }

    // Linear Gradient Logic (existing)
    // Triangle vertices (equilateral pointing up)
    CGPoint corners[3];
    for (int i = 0; i < 3; i++) {
        // Angles: 90, 210, 330
        float angle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
        corners[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    // Rounded corners logic
    float cornerRadius = self.radius;
    if (cornerRadius > r / 2.0f) cornerRadius = r / 2.0f;
    if (cornerRadius < 0) cornerRadius = 0;
    
    if (cornerRadius < 1.0f) {
        // Sharp triangle
        [self drawPolyGradient:corners count:3];
        return;
    }
    
    // Generate rounded vertices
    int segmentsPerCorner = 15;
    int totalVerts = 3 * segmentsPerCorner + 2; // +2 for center/close
    CGPoint *vertices = malloc(sizeof(CGPoint) * totalVerts);
    vertices[0] = center;
    int vIndex = 1;
    
    for (int i = 0; i < 3; i++) {
        CGPoint p = corners[i];
        // Vector from center to corner
        CGPoint v = ccpSub(p, center);
        float len = ccpLength(v);
        CGPoint dir = ccpMult(v, 1.0f/len); // Normalized direction to corner
        
        // Center of the arc is inward along the angle bisector (which is just -dir)
        // Distance from corner to arc center is 2 * cornerRadius
        // So ArcCenter = Corner - Dir * (2 * cornerRadius)
        CGPoint arcCenter = ccpSub(p, ccpMult(dir, 2.0f * cornerRadius));
        
        float cornerAngle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f); // 90, 210, 330
        float startAngle = cornerAngle + M_PI - M_PI/3.0f; // +180 - 60 = +120
        float endAngle = cornerAngle + M_PI + M_PI/3.0f;   // +180 + 60 = +240
        
        for (int j = 0; j < segmentsPerCorner; j++) {
            float t = (float)j / (segmentsPerCorner - 1);
            float a = startAngle + t * (endAngle - startAngle);
            vertices[vIndex++] = ccp(arcCenter.x + cos(a) * cornerRadius, arcCenter.y + sin(a) * cornerRadius);
        }
    }
    vertices[vIndex] = vertices[1]; // Close
    
    [self drawPolyGradient:vertices count:vIndex+1];
    free(vertices);
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

- (void)drawPillOutline:(CGPoint)origin size:(CGSize)size
{
    float r;
    if (size.width > size.height) {
        r = size.height / 2.0f;
    } else {
        r = size.width / 2.0f;
    }
    [self drawRoundedRectOutline:origin size:size radius:r];
}

- (void)drawTriangleOutline:(CGPoint)center radius:(float)r
{
    // Same logic as filled triangle but using ccDrawPoly
    CGPoint corners[3];
    for (int i = 0; i < 3; i++) {
        float angle = M_PI / 2.0f + i * (2.0f * M_PI / 3.0f);
        corners[i] = ccp(center.x + cos(angle) * r, center.y + sin(angle) * r);
    }
    
    float cornerRadius = self.radius;
    if (cornerRadius > r / 2.0f) cornerRadius = r / 2.0f;
    if (cornerRadius < 0) cornerRadius = 0;
    
    if (cornerRadius < 1.0f) {
        ccDrawPoly(corners, 3, YES);
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
    
    ccDrawPoly(vertices, totalVerts, YES);
    free(vertices);
}

// Gradient outline methods
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


#pragma mark - KVC Compliance for Custom Structs

- (id) valueForKey:(NSString *)key
{
    if ([key isEqualToString:@"startColor"]) return [NSValue value:&startColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"endColor"]) return [NSValue value:&endColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"outlineColor"]) return [NSValue value:&outlineColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"outlineStartColor"]) return [NSValue value:&outlineStartColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"outlineEndColor"]) return [NSValue value:&outlineEndColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"shadowColor"]) return [NSValue value:&shadowColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"pressedStartColor"]) return [NSValue value:&pressedStartColor withObjCType:@encode(ccColor3B)];
    if ([key isEqualToString:@"pressedEndColor"]) return [NSValue value:&pressedEndColor withObjCType:@encode(ccColor3B)];
    
    return [super valueForKey:key];
}

- (void) setValue:(id)value forKey:(NSString *)key
{
    NSLog(@"CCCustomShape setValue:%@ forKey:%@", value, key);
    if ([key isEqualToString:@"startColor"]) { ccColor3B c; [value getValue:&c]; self.startColor = c; return; }
    if ([key isEqualToString:@"endColor"]) { ccColor3B c; [value getValue:&c]; self.endColor = c; return; }
    if ([key isEqualToString:@"outlineColor"]) { ccColor3B c; [value getValue:&c]; self.outlineColor = c; return; }
    if ([key isEqualToString:@"outlineStartColor"]) { ccColor3B c; [value getValue:&c]; self.outlineStartColor = c; return; }
    if ([key isEqualToString:@"outlineEndColor"]) { ccColor3B c; [value getValue:&c]; self.outlineEndColor = c; return; }
    if ([key isEqualToString:@"shadowColor"]) { ccColor3B c; [value getValue:&c]; self.shadowColor = c; return; }
    if ([key isEqualToString:@"pressedStartColor"]) { ccColor3B c; [value getValue:&c]; self.pressedStartColor = c; return; }
    if ([key isEqualToString:@"pressedEndColor"]) { ccColor3B c; [value getValue:&c]; self.pressedEndColor = c; return; }

    [super setValue:value forKey:key];
}

@end
