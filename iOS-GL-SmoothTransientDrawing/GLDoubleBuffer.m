//
//  GLDoubleBuffer.m
//  producer
//
//  Created by Akshay Loke on 9/27/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import "GLDoubleBuffer.h"
#import "GLBuffer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@interface GLDoubleBuffer() {
    GLDoubleBufferState doubleBufferState;
    GLBuffer *buffer1, *buffer2;
}

@end

@implementation GLDoubleBuffer

-(id)initWithSize:(CGSize)_size pixelBufferAdaptor:(AVAssetWriterInputPixelBufferAdaptor *)_pixelBufferAdaptor textureCache:(CVOpenGLESTextureCacheRef)_textureCache useMultisample:(BOOL)useMultisample {
    if (self = [super init]) {
        doubleBufferState = GLDoubleBufferStateOne;
        
        buffer1 = [[GLBuffer alloc] initWithSize:_size pixelBufferAdaptor:_pixelBufferAdaptor textureCache:_textureCache useMultisample:useMultisample];
        buffer2 = [[GLBuffer alloc] initWithSize:_size pixelBufferAdaptor:_pixelBufferAdaptor textureCache:_textureCache useMultisample:useMultisample];
    }
    return self;
}

-(id)initWithTextureCache:(CVOpenGLESTextureCacheRef)_textureCache {
    if (self = [super init]) {
        doubleBufferState = GLDoubleBufferStateOne;
        
        buffer1 = [[GLBuffer alloc] initWithTextureCache:_textureCache];
        buffer2 = [[GLBuffer alloc] initWithTextureCache:_textureCache];
    }
    return self;
}

-(void)createWithPixelBuffer:(CVPixelBufferRef)_pixelBuffer size:(CGSize)_size {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            [buffer2 createWithPixelBuffer:_pixelBuffer size:_size];
            break;
        case GLDoubleBufferStateTwo:
            [buffer1 createWithPixelBuffer:_pixelBuffer size:_size];
            break;
    }
}

-(void)lock {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            [buffer2 lock];
            break;
        case GLDoubleBufferStateTwo:
            [buffer1 lock];
            break;
    }
}

-(void)unlock {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            [buffer2 unlock];
            break;
        case GLDoubleBufferStateTwo:
            [buffer1 unlock];
            break;
    }
}

-(void)bindFBO {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            [buffer2 bindFBO];
            break;
        case GLDoubleBufferStateTwo:
            [buffer1 bindFBO];
            break;
    }
}

-(void)resolveAndUnbindFBO {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            [buffer2 resolveAndUnbindFBO];
            break;
        case GLDoubleBufferStateTwo:
            [buffer1 resolveAndUnbindFBO];
            break;
    }
}

-(void)switchState {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            doubleBufferState = GLDoubleBufferStateTwo;
            break;
        case GLDoubleBufferStateTwo:
            doubleBufferState = GLDoubleBufferStateOne;
            break;
    }
}

-(void)cleanupTextures {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            [buffer2 cleanupTexture];
            break;
        case GLDoubleBufferStateTwo:
            [buffer1 cleanupTexture];
            break;
    }
}

-(int)getState {
    return doubleBufferState;
}

-(CVOpenGLESTextureRef)getTexture {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            return [buffer1 getTexture];
        case GLDoubleBufferStateTwo:
            return [buffer2 getTexture];
    }
}

-(CVPixelBufferRef)getPixelBuffer {
    switch (doubleBufferState) {
        case GLDoubleBufferStateOne:
            return [buffer1 getPixelBuffer];
        case GLDoubleBufferStateTwo:
            return [buffer2 getPixelBuffer];
    }
}
@end
