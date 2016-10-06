//
//  GLRenderToScreen.m
//  producer
//
//  Created by Akshay Loke on 9/29/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import "GLRenderToScreen.h"
#import "GLRendererPrivate.h"
#import "GLDoubleBuffer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GLRenderToScreen() {
    GLuint uniform_compositeTexture;
    
    CVOpenGLESTextureRef compositeTexture;
}

@end

@implementation GLRenderToScreen

-(void)setupWithSize:(CGSize)_size queue:(dispatch_queue_t)queue context:(EAGLContext *)context {
    
    [super setupWithSize:_size queue:queue context:context];
    
    vertexShaderName = @"Shader";
    fragmentShaderName = @"RenderToScreenShader";
    useMultisampling = NO;
    glBufferType = GLBufferTypeNone;
    useStaticVAO = YES;
    
    [self setupGL];
}

-(void)renderDirect {
    [EAGLContext setCurrentContext:self.context];
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(program);
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(CVOpenGLESTextureGetTarget(compositeTexture), CVOpenGLESTextureGetName(compositeTexture));
    glUniform1i(uniform_compositeTexture, 3);
    
    glBindVertexArrayOES(vao);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArrayOES(0);
}

-(void)setInputCompositeTexture:(CVOpenGLESTextureRef)_compositeTexture {
    compositeTexture = _compositeTexture;
}

#pragma mark SHADER
-(void)bindAttributeLocations {
    glBindAttribLocation(program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(program, GLKVertexAttribTexCoord0, "uv");
}

-(void)getUniformLocations {
    uniform_compositeTexture = glGetUniformLocation(program, "renderToScreenTexture");
}

@end
