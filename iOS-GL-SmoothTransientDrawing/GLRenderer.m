//
//  GLRenderer.m
//  producer
//
//  Created by Akshay Loke on 6/20/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import "GLRenderer.h"
#import "GLRendererPrivate.h"
#import "GLPrimitives.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation GLRenderer

#pragma mark SETUP
-(void)setupWithSize:(CGSize)_size queue:(dispatch_queue_t)queue {
    rendererQueue = queue;
    size = _size;
    
    totalIndicesCount = 0;
    isTouching = NO;
    
    glBufferType = GLBufferTypeNone;
    useMultisampling = YES;
    useStaticVAO = YES;
    hasContent = NO;
}

-(void)setupWithSize:(CGSize)_size queue:(dispatch_queue_t)queue context:(EAGLContext *)context {
    [self setupWithSize:_size queue:queue];
    self.context = context;
}

-(void)setupWithSize:(CGSize)_size textureCache:(CVOpenGLESTextureCacheRef)_textureCache queue:(dispatch_queue_t)queue {
    [self setupWithSize:_size queue:queue];
    textureCache = _textureCache;
}

-(void)setupWithSize:(CGSize)_size textureCache:(CVOpenGLESTextureCacheRef)_textureCache queue:(dispatch_queue_t)queue context:(EAGLContext *)context {
    [self setupWithSize:_size queue:queue context:context];
    textureCache = _textureCache;
}

-(void)setupGL {
    [self loadShaders];
    if (useStaticVAO) {
        [self setupStaticVAO];
    }
    else {
        [self setupDynamicVAO];
    }
    [self setupFBO];
}

-(void)setupStaticVAO {
    GLVertex vertices[4];
    vertices[0].position = GLKVector4Make(-1, -1, 0, 1); vertices[0].uv = GLKVector2Make(0, 0);
    vertices[1].position = GLKVector4Make(1, -1, 0, 1); vertices[1].uv = GLKVector2Make(1, 0);
    vertices[2].position = GLKVector4Make(1, 1, 0, 1); vertices[2].uv = GLKVector2Make(1, 1);
    vertices[3].position = GLKVector4Make(-1, 1, 0, 1); vertices[3].uv = GLKVector2Make(0, 1);
    
    GLuint indices[6];
    indices[0] = 0;
    indices[1] = 1;
    indices[2] = 2;
    indices[3] = 0;
    indices[4] = 2;
    indices[5] = 3;
    
    //vertex array
    glGenVertexArraysOES(1, &vao);
    glBindVertexArrayOES(vao);
    
    //vertex buffer
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 4, GL_FLOAT, GL_FALSE, sizeof(GLVertex), (void*)offsetof(GLVertex, position));
    
    //texcoord buffer
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLVertex), (void*)offsetof(GLVertex, uv));
    
    //index buffer
    glGenBuffers(1, &ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);
}

-(void)setupFBO {
    switch (glBufferType) {
        case GLBufferTypeNone:
            break;
        case GLBufferTypeSingle:
            singleBuffer = [[GLBuffer alloc] initWithSize:size pixelBufferAdaptor:nil textureCache:textureCache useMultisample:useMultisampling];
            break;
        case GLBufferTypeDouble:
            doubleBuffer = [[GLDoubleBuffer alloc] initWithSize:size pixelBufferAdaptor:nil textureCache:textureCache useMultisample:useMultisampling];
            break;
    }
}

-(BOOL)hasContent {
    return hasContent;
}

-(CVOpenGLESTextureRef)getTexture {
    switch (glBufferType) {
        case GLBufferTypeNone:
            return nil;
        case GLBufferTypeSingle:
            return [singleBuffer getTexture];
        case GLBufferTypeDouble:
            return [doubleBuffer getTexture];
    }
}

-(CVPixelBufferRef)getPixelBuffer {
    switch (glBufferType) {
        case GLBufferTypeNone:
            return nil;
        case GLBufferTypeSingle:
            return [singleBuffer getPixelBuffer];
        case GLBufferTypeDouble:
            return [doubleBuffer getPixelBuffer];
    }
}

-(void)setColor:(UIColor*)_color {
    color = _color;
}

#pragma mark TEARDOWN
-(void)teardownGL {
    glDeleteBuffers(1, &vbo);
    glDeleteBuffers(1, &ibo);
    glDeleteVertexArraysOES(1, &vao);
    glDeleteProgram(program);
}


#pragma mark SHADER
- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertexShaderName ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile vertex shader.
    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderName ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    [self bindAttributeLocations];
    
    // Link program.
    if (![self linkProgram]) {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    [self getUniformLocations];
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram
{
    GLint status;
    glLinkProgram(program);
    
    GLint logLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
