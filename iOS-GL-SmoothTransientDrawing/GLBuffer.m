//
//  GLBuffer.m
//  producer
//
//  Created by Akshay Loke on 9/27/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import "GLBuffer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@interface GLBuffer() {
    CGSize size;
    BOOL useMultisampling;
    
    GLuint fbo;
    GLuint msFbo;
    CVPixelBufferRef pixelBuffer;
    CVOpenGLESTextureRef texture;
    
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
    CVOpenGLESTextureCacheRef textureCache;
}

@end

@implementation GLBuffer

-(id)initWithSize:(CGSize)_size pixelBufferAdaptor:(AVAssetWriterInputPixelBufferAdaptor *)_pixelBufferAdaptor textureCache:(CVOpenGLESTextureCacheRef)_textureCache useMultisample:(BOOL)useMultisample {
    if (self = [super init]) {
        size = _size;
        pixelBufferAdaptor = _pixelBufferAdaptor;
        textureCache = _textureCache;
        useMultisampling = useMultisample;
        
        [self generatePixelBuffer:&pixelBuffer texture:&texture framebuffer:&fbo multisampleFramebuffer:&msFbo];
    }
    return self;
}

-(id)initWithTextureCache:(CVOpenGLESTextureCacheRef)_textureCache {
    if (self = [super init]) {
        textureCache = _textureCache;
    }
    return self;
}

-(void)generatePixelBuffer:(CVPixelBufferRef*)_pixelBuffer
                   texture:(CVOpenGLESTextureRef*)_texture
               framebuffer:(GLuint*)_framebuffer
    multisampleFramebuffer:(GLuint*)_msFramebuffer{
    
    CVReturn error;
    if (pixelBufferAdaptor) {
        error = CVPixelBufferPoolCreatePixelBuffer(NULL,
                                                   pixelBufferAdaptor.pixelBufferPool,
                                                   _pixelBuffer);
        if (error) {
            NSLog(@"Error creating PixelBuffer from AdaptorPool %d", error);
        }
    }
    else {
        NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSDictionary dictionary], (id)kCVPixelBufferIOSurfacePropertiesKey,
                                               nil];
        error = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes), _pixelBuffer);
        if (error) {
            NSLog(@"Error creating PixelBuffer %d", error);
        }
    }
    
    //2.
    glActiveTexture(GL_TEXTURE0);
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                         textureCache,
                                                         *_pixelBuffer,
                                                         NULL,
                                                         GL_TEXTURE_2D,
                                                         GL_RGBA,
                                                         size.width,
                                                         size.height,
                                                         GL_BGRA,
                                                         GL_UNSIGNED_BYTE,
                                                         0,
                                                         _texture);
    if (error) {
        NSLog(@"Error creating Texture %d", error);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(*_texture), CVOpenGLESTextureGetName(*_texture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    //3.
    glGenFramebuffers(1, _framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, *_framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(*_texture), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Custom Framebuffer not complete: %d", status);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if (useMultisampling) {
        glGenFramebuffers(1, _msFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, *_msFramebuffer);
        
        GLuint sampleColorRenderbuffer;
        glGenRenderbuffers(1, &sampleColorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, sampleColorRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, size.width, size.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, sampleColorRenderbuffer);
        
        GLuint sampleDepthRenderbuffer;
        glGenRenderbuffers(1, &sampleDepthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, sampleDepthRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT16, size.width, size.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, sampleDepthRenderbuffer);
        
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
    
    NSLog(@"FBO: %d, MSFBO: %d, Texture: %d", *_framebuffer, *_msFramebuffer, CVOpenGLESTextureGetName(*_texture));
}

-(void)createWithPixelBuffer:(CVPixelBufferRef)_pixelBuffer size:(CGSize)_size {
    CVReturn error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                         textureCache,
                                                         _pixelBuffer,
                                                         NULL,
                                                         GL_TEXTURE_2D,
                                                         GL_RGBA,
                                                         _size.width,
                                                         _size.height,
                                                         GL_BGRA,
                                                         GL_UNSIGNED_BYTE,
                                                         0,
                                                         &texture);
    if (error) {
        NSLog(@"Error creating Texture %d", error);
    }
}

-(void)lock {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
}

-(void)unlock {
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

-(void)bindFBO {
    if (useMultisampling)
        glBindFramebuffer(GL_FRAMEBUFFER, msFbo);
    else
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
}

-(void)resolveAndUnbindFBO {
    if (useMultisampling) {
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, fbo);
        glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, msFbo);
        glResolveMultisampleFramebufferAPPLE();
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

-(void)cleanupTexture {
    if (texture) {
        CFRelease(texture);
        texture = NULL;
    }
}

-(CVOpenGLESTextureRef)getTexture {
    return texture;
}

-(CVPixelBufferRef)getPixelBuffer {
    return pixelBuffer;
}

@end
