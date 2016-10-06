//
//  GLBuffer.h
//  producer
//
//  Created by Akshay Loke on 9/27/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

@interface GLBuffer : NSObject

-(id)initWithSize:(CGSize)_size pixelBufferAdaptor:(AVAssetWriterInputPixelBufferAdaptor *)_pixelBufferAdaptor textureCache:(CVOpenGLESTextureCacheRef)_textureCache useMultisample:(BOOL)useMultisample;
-(id)initWithTextureCache:(CVOpenGLESTextureCacheRef)_textureCache;

-(void)createWithPixelBuffer:(CVPixelBufferRef)pixelBuffer size:(CGSize)_size;

-(void)lock;
-(void)unlock;
-(void)bindFBO;
-(void)resolveAndUnbindFBO;
-(void)cleanupTexture;

-(CVOpenGLESTextureRef)getTexture;
-(CVPixelBufferRef)getPixelBuffer;

@end
