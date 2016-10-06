//
//  GLDrawingTool.m
//  producer
//
//  Created by Akshay Loke on 6/6/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import "GLDrawingRenderer.h"
#import "GLRendererPrivate.h"
#import "GLPrimitives.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

static const NSUInteger VertexLimit = USHRT_MAX;
static const NSUInteger IndexLimit = (VertexLimit - 4)/2 * 6 + 6;
static const float LineDecayTimeInSeconds = 2.25f;
static const float LineGlow = 2.0f;
static const float LastPointDistanceThreshold = 0.02f;
static const int CircleSubdivisions = 8;
static const float SplineSegmentSubdivisions = 4;
static const float SplineSegmentDelta = 1.0f / SplineSegmentSubdivisions;
static BOOL DEBUG_MODE = NO;

@interface GLDrawingRenderer() {
    GLKVector3 glColor;
    GLuint uniform_currLineDrawTimeDelta, uniform_aspectRatio, uniform_color;
    
    GLKVector2 lastPoint;
    BOOL isNewLine;
    
    BOOL isFirstPointOfLine;
    BOOL isLastPointOfLine;
    
    int linePointIndex;
    GLKVector2 crPoints[3];
    GLKVector2 lastMinus1TouchPoint, lastTouchPoint, currentTouchPoint;
    NSDate *appStartDate;
    
    GLKVector2 angleVectors[CircleSubdivisions];
    uint32_t totalVerticesCount;
    
    float keyboardHeight;
}

@property (nonatomic) NSMutableArray *linePoints;
@property (nonatomic) NSMutableArray *linePointsToAdd;

@end

@implementation GLDrawingRenderer

#pragma mark SETUP
-(void)setupWithSize:(CGSize)_size textureCache:(CVOpenGLESTextureCacheRef)_textureCache queue:(dispatch_queue_t)queue context:(EAGLContext *)context {
    NSLog(@"Setting up GLDrawingRenderer");
    [super setupWithSize:_size textureCache:_textureCache queue:queue context:context];
    
    self.renderType = GLRenderTypeRenderToTexture;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.linePoints = [NSMutableArray array];
    self.linePointsToAdd = [NSMutableArray array];
    
    isNewLine = YES;
    linePointIndex = 0;
    lastMinus1TouchPoint = GLKVector2Make(-2, -2);
    lastTouchPoint = GLKVector2Make(-2, -2);
    currentTouchPoint = GLKVector2Make(-2, -2);
    appStartDate = [NSDate date];
    
    float angleDelta = 2.0f * M_PI / CircleSubdivisions;
    for (int i = 0; i < CircleSubdivisions; i++) {
        float angle = i * angleDelta;
        angleVectors[i] = GLKVector2Make(cos(angle), sin(angle));
    }
    
    vertexShaderName = @"DrawingShader";
    fragmentShaderName = @"DrawingShader";
    useMultisampling = YES;
    glBufferType = GLBufferTypeSingle;
    useStaticVAO = NO;
    
    [self setupGL];
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    float aspectRatio = bounds.size.height / bounds.size.width;
    glUseProgram(program);
    glUniform1f(uniform_aspectRatio, aspectRatio);
    glUseProgram(0);
}

-(void)setupDynamicVAO {
    glGenVertexArraysOES(1, &vao);
    glBindVertexArrayOES(vao);
    
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, VertexLimit * sizeof(GLLineVertex), NULL, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 4, GL_FLOAT, GL_FALSE, sizeof(GLLineVertex), (void*)offsetof(GLLineVertex, position));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLLineVertex), (void*)offsetof(GLLineVertex, uv));
    
    glGenBuffers(1, &ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, IndexLimit * sizeof(GLushort), NULL, GL_DYNAMIC_DRAW);
    
    glBindVertexArrayOES(0);
}

-(void)setColor:(UIColor *)_color {
    [super setColor:_color];
    const CGFloat* colors = CGColorGetComponents( color.CGColor );
    glColor = GLKVector3Make(colors[0], colors[1], colors[2]);
    
    glUseProgram(program);
    glUniform3f(uniform_color, colors[0], colors[1], colors[2]);
    glUseProgram(0);
}

#pragma mark ADD TOUCHES
-(void)addLinePoint:(GLKVector2)point position:(GLLinePointPosition)position {
    @synchronized (self.linePointsToAdd) {
        if (GLKVector2AllEqualToScalar(lastMinus1TouchPoint, -2)) {
            lastMinus1TouchPoint = point;
        }
        else if (GLKVector2AllEqualToScalar(lastTouchPoint, -2)) {
            lastTouchPoint = point; //p1
            if (isLastPointOfLine) {
                isLastPointOfLine = NO;
                GLLinePoint *duo = [[GLLinePoint alloc] initWithPoint:point normal:point position:GLLinePointPositionDot drawTimeDelta:[[NSDate date] timeIntervalSinceDate:appStartDate]];
                [self.linePointsToAdd addObject:duo];
            }
        }
        else {
            currentTouchPoint = point;
            GLKVector2 midpoint1 = GLKVector2MultiplyScalar(GLKVector2Add(lastMinus1TouchPoint, lastTouchPoint), 0.5); //p0
            GLKVector2 midpoint2 = GLKVector2MultiplyScalar(GLKVector2Add(lastTouchPoint, currentTouchPoint), 0.5); //p2
            
            for (float t = 0; t < 1.0f; t += SplineSegmentDelta) {
                float oneMinusT_Squared = (1 - t) * (1 - t);
                float two_times_OneMinusT_times_T = 2 * (1 - t) * t;
                float t_Squared = t * t;
                GLKVector2 cPoint = GLKVector2Add(GLKVector2MultiplyScalar(midpoint1, oneMinusT_Squared),
                                                  GLKVector2Add(GLKVector2MultiplyScalar(lastTouchPoint, two_times_OneMinusT_times_T),
                                                                GLKVector2MultiplyScalar(midpoint2, t_Squared)
                                                                )
                                                  );
                
                float two_times_OneMinusT = 2 * (1 - t);
                float two_times_T = 2 * t;
                GLKVector2 cTangent = GLKVector2Normalize(GLKVector2Add(GLKVector2MultiplyScalar(GLKVector2Subtract(lastTouchPoint, midpoint1),
                                                                                                 two_times_OneMinusT),
                                                                        GLKVector2MultiplyScalar(GLKVector2Subtract(midpoint2, lastTouchPoint),
                                                                                                 two_times_T)
                                                                        )
                                                          );
                
                GLKVector2 cNormal = GLKVector2Normalize(GLKVector2Make(-cTangent.y, cTangent.x));
                
                GLLinePointPosition linePointPosition = GLLinePointPositionMiddle;
                if (isFirstPointOfLine) {
                    isFirstPointOfLine = NO;
                    linePointPosition = GLLinePointPositionStart;
                }
                GLLinePoint *duo = [[GLLinePoint alloc] initWithPoint:cPoint normal:cNormal position:linePointPosition drawTimeDelta:[[NSDate date] timeIntervalSinceDate:appStartDate]];
                [self.linePointsToAdd addObject:duo];
            }
            
            if (isLastPointOfLine) {
                isLastPointOfLine = NO;
                ((GLLinePoint*)[self.linePointsToAdd lastObject]).linePointPosition = GLLinePointPositionEnd;
            }
            
            lastMinus1TouchPoint = lastTouchPoint;
            lastTouchPoint = currentTouchPoint;
        }
    }
    
    //[self updateBuffers];
    lastPoint = point;
}

#pragma mark UPDATE
-(void)updateBuffers {
    @synchronized (self.linePointsToAdd) {
        if (self.linePointsToAdd.count > 0) {
            [self.linePoints addObjectsFromArray:self.linePointsToAdd];
            [self.linePointsToAdd removeAllObjects];
        }
    }
    
    if (self.linePoints.count == 0)
        return;
    
    totalIndicesCount = 0;
    totalVerticesCount = 0;
    
    NSMutableIndexSet *linePointDuoIndicesToDiscard = [NSMutableIndexSet indexSet];
    for (int i=0; i<self.linePoints.count; i++) {
        GLLinePoint *currLinePoint = [self.linePoints objectAtIndex:i];
        
        double currDrawTimeDelta = [[NSDate date] timeIntervalSinceDate:appStartDate];
        float opacityT = 1.0 - ((currDrawTimeDelta - currLinePoint.drawTimeDelta) / LineDecayTimeInSeconds);
        
        if (opacityT < 0.0f) opacityT = 0.0f; else if (opacityT > 1.0f) opacityT = 1.0f;
        float opacity = DEBUG_MODE? 1.0f: opacityT * LineGlow;
        if (opacity < 0.001f) {
            [linePointDuoIndicesToDiscard addIndex:i];
        }
    }
    
    [self.linePoints removeObjectsAtIndexes:linePointDuoIndicesToDiscard];
    
    if (self.linePoints.count == 0)
        return;
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    GLLineVertex *vertexData = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    GLushort *indexData = glMapBufferOES(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    
    GLushort verticesCount = 0;
    for (int i=0; i<self.linePoints.count; i++) {
        GLLinePoint *currLinePoint = [self.linePoints objectAtIndex:i];
        if (currLinePoint.linePointPosition == GLLinePointPositionDot) {
            for (int j = 0; j < CircleSubdivisions; j++) {
                GLKVector2 point = currLinePoint.point;
                float drawTimeDelta = currLinePoint.drawTimeDelta;
                
                GLKVector2 polarPoint1 = angleVectors[j];
                GLKVector2 polarPoint2 = (j == CircleSubdivisions-1)? angleVectors[0]: angleVectors[j+1];
                
                GLLineVertex vertices[3];
                GLushort indices[3];
                
                vertices[0].position = GLKVector4Make(point.x, point.y, 0, 0); vertices[0].uv = GLKVector2Make(drawTimeDelta, 0);
                vertices[1].position = GLKVector4Make(point.x, point.y, polarPoint1.x, polarPoint1.y); vertices[1].uv = GLKVector2Make(drawTimeDelta, 0);
                vertices[2].position = GLKVector4Make(point.x, point.y, polarPoint2.x, polarPoint2.y); vertices[2].uv = GLKVector2Make(drawTimeDelta, 0);
                
                memcpy(vertexData, vertices, sizeof(vertices));
                vertexData += 3;
                
                indices[0] = verticesCount + 0;
                indices[1] = verticesCount + 1;
                indices[2] = verticesCount + 2;
                
                memcpy(indexData, indices, sizeof(indices));
                indexData += 3;
                
                verticesCount += 3;
                totalIndicesCount += 3;
            }
        }
    }
    
    
    for (int i=0; i<self.linePoints.count-1; i++) {
        GLLinePoint *currLinePoint = [self.linePoints objectAtIndex:i];
        GLLinePoint *nextLinePoint = [self.linePoints objectAtIndex:i+1];
        
        if (currLinePoint.linePointPosition == GLLinePointPositionStart || nextLinePoint.linePointPosition == GLLinePointPositionEnd) {
            for (int j = 0; j < CircleSubdivisions; j++) {
                float drawTimeDelta = 0;
                GLKVector2 point;
                if (currLinePoint.linePointPosition == GLLinePointPositionStart) {
                    point = currLinePoint.point;
                    drawTimeDelta = currLinePoint.drawTimeDelta;
                }
                else {
                    point = nextLinePoint.point;
                    drawTimeDelta = nextLinePoint.drawTimeDelta;
                }
                
                GLKVector2 polarPoint1 = angleVectors[j];
                GLKVector2 polarPoint2 = (j == CircleSubdivisions-1)? angleVectors[0]: angleVectors[j+1];
                
                GLLineVertex vertices[3];
                GLushort indices[3];
                
                vertices[0].position = GLKVector4Make(point.x, point.y, 0, 0); vertices[0].uv = GLKVector2Make(drawTimeDelta, 0);
                vertices[1].position = GLKVector4Make(point.x, point.y, polarPoint1.x, polarPoint1.y); vertices[1].uv = GLKVector2Make(drawTimeDelta, 0);
                vertices[2].position = GLKVector4Make(point.x, point.y, polarPoint2.x, polarPoint2.y); vertices[2].uv = GLKVector2Make(drawTimeDelta, 0);
                
                memcpy(vertexData, vertices, sizeof(vertices));
                vertexData += 3;
                
                indices[0] = verticesCount + 0;
                indices[1] = verticesCount + 1;
                indices[2] = verticesCount + 2;
                
                memcpy(indexData, indices, sizeof(indices));
                indexData += 3;
                
                verticesCount += 3;
                totalIndicesCount += 3;
            }
        }
        
        if (currLinePoint.linePointPosition != GLLinePointPositionEnd && currLinePoint.linePointPosition != GLLinePointPositionDot) {
            GLLineVertex vertices[4];
            GLushort indices[6];
            
            vertices[0].position = GLKVector4Make(currLinePoint.point.x, currLinePoint.point.y, currLinePoint.normal.x, currLinePoint.normal.y); vertices[0].uv = GLKVector2Make(currLinePoint.drawTimeDelta, 0);
            vertices[1].position = GLKVector4Make(currLinePoint.point.x, currLinePoint.point.y, -currLinePoint.normal.x, -currLinePoint.normal.y); vertices[1].uv = GLKVector2Make(currLinePoint.drawTimeDelta, 0);
            vertices[2].position = GLKVector4Make(nextLinePoint.point.x, nextLinePoint.point.y, -nextLinePoint.normal.x, -nextLinePoint.normal.y); vertices[2].uv = GLKVector2Make(nextLinePoint.drawTimeDelta, 0);
            vertices[3].position = GLKVector4Make(nextLinePoint.point.x, nextLinePoint.point.y, nextLinePoint.normal.x, nextLinePoint.normal.y); vertices[3].uv = GLKVector2Make(nextLinePoint.drawTimeDelta, 0);
            
            memcpy(vertexData, vertices, sizeof(vertices));
            vertexData += 4;
            
            indices[0] = verticesCount + 0;
            indices[1] = verticesCount + 1;
            indices[2] = verticesCount + 2;
            indices[3] = verticesCount + 0;
            indices[4] = verticesCount + 2;
            indices[5] = verticesCount + 3;
            
            memcpy(indexData, indices, sizeof(indices));
            indexData += 6;
            
            verticesCount += 4;
            totalIndicesCount += 6;
        }
    }
    
    glUnmapBufferOES(GL_ELEMENT_ARRAY_BUFFER);
    glUnmapBufferOES(GL_ARRAY_BUFFER);
    
}

#pragma mark RENDER
-(void)renderIntoTexture {
    hasContent = NO;
    
    // return early if there's nothing to draw
    if (!isTouching)
        [self updateBuffers];

    if (totalIndicesCount == 0) {
        return;
    }
    hasContent = YES;
    
    //glPushGroupMarkerEXT(0, "DrawingTool START");
    [singleBuffer bindFBO];
    
    glClearColor(0, 0, 0, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendEquation(GL_FUNC_ADD);
    
    glViewport(0, 0, size.width, size.height);
    
    glUseProgram(program);
    glUniform1f(uniform_currLineDrawTimeDelta, [[NSDate date] timeIntervalSinceDate:appStartDate]);
    
    glBindVertexArrayOES(vao);
    glDrawElements(GL_TRIANGLES, totalIndicesCount, GL_UNSIGNED_SHORT, 0);
    glBindVertexArrayOES(0);
    
    glDisable(GL_BLEND);
    [singleBuffer resolveAndUnbindFBO];
    
    //glPopGroupMarkerEXT();
}

-(void)keyboardWillShow:(NSNotification*)notification {
    keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height/size.height;
}

-(void)keyboardWillHide:(NSNotification*)notification {
    keyboardHeight = 0;
}

#pragma mark TOUCHES
-(void)didTouchAtPoint:(CGPoint)point withType:(TouchType)type {
    GLKVector2 convertedPoint = GLKVector2Make(((point.x/size.width) - 0.5f) * 2.0f, ((1.0 - point.y/size.height - keyboardHeight) - 0.5f) * 2.0f);
    if (DEBUG_MODE) {
        if (type == BEGAN) {
            [self addLinePoint:convertedPoint position:isNewLine? GLLinePointPositionStart: GLLinePointPositionMiddle];
            isNewLine = NO;
        }
    }
    else {
        if (type == BEGAN) {
            linePointIndex = 0;
            lastMinus1TouchPoint = GLKVector2Make(-2, -2);
            lastTouchPoint = GLKVector2Make(-2, -2);
            currentTouchPoint = GLKVector2Make(-2, -2);
            isFirstPointOfLine = YES;
            
            [self addLinePoint:convertedPoint position:GLLinePointPositionStart];
            isNewLine = NO;
        }
        else if (type == MOVED) {
            float distance = GLKVector2Distance(lastPoint, convertedPoint);
            if (distance < LastPointDistanceThreshold)
                return;
            [self addLinePoint:convertedPoint position:GLLinePointPositionMiddle];
        }
        else if (type == ENDED){
            isLastPointOfLine = YES;
            [self addLinePoint:convertedPoint position:GLLinePointPositionEnd];
            isNewLine = YES;
        }
    }
    
    linePointIndex++;
}

#pragma mark SHADER
-(void)bindAttributeLocations {
    glBindAttribLocation(program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(program, GLKVertexAttribTexCoord0, "uv");
}

-(void)getUniformLocations {
    uniform_currLineDrawTimeDelta = glGetUniformLocation(program, "uCurrLineDrawTimeDelta");
    uniform_aspectRatio = glGetUniformLocation(program, "uAspectRatio");
}

@end
