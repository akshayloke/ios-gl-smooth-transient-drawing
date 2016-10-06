//
//  GLRendererPrivate.h
//  producer
//
//  Created by Akshay Loke on 6/21/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//
#import "GLBuffer.h"
#import "GLDoubleBuffer.h"

typedef enum GLBufferType {
    GLBufferTypeNone, GLBufferTypeSingle, GLBufferTypeDouble
} GLBufferType;

@interface GLRenderer() {
@protected
    dispatch_queue_t rendererQueue;
    
    CGSize size;
    
    GLuint program;
    NSString *vertexShaderName, *fragmentShaderName;
    
    BOOL useStaticVAO;
    GLuint vao, vbo, ibo;
    
    GLBufferType glBufferType;
    GLBuffer *singleBuffer;
    GLDoubleBuffer *doubleBuffer;
    
    CVOpenGLESTextureCacheRef textureCache;
    
    uint32_t totalIndicesCount;
    GLKVector2 lastPoint;
    
    BOOL isTouching;
    BOOL useMultisampling;
    BOOL hasContent;
    
    UIColor *color;
}

@end
