//
//  GLDoubleBuffer.h
//  producer
//
//  Created by Akshay Loke on 9/27/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum GLDoubleBufferState {
    GLDoubleBufferStateOne, GLDoubleBufferStateTwo
} GLDoubleBufferState;

@interface GLDoubleBuffer : NSObject

-(id)initWithSize:(CGSize)_size pixelBufferAdaptor:(AVAssetWriterInputPixelBufferAdaptor *)_pixelBufferAdaptor textureCache:(CVOpenGLESTextureCacheRef)_textureCache useMultisample:(BOOL)useMultisample;
-(id)initWithTextureCache:(CVOpenGLESTextureCacheRef)_textureCache;

-(void)createWithPixelBuffer:(CVPixelBufferRef)_pixelBuffer size:(CGSize)_size;

-(void)lock;
-(void)unlock;
-(void)bindFBO;
-(void)resolveAndUnbindFBO;
-(void)switchState;
-(void)cleanupTextures;

-(int)getState;
-(CVOpenGLESTextureRef)getTexture;
-(CVPixelBufferRef)getPixelBuffer;

@end
