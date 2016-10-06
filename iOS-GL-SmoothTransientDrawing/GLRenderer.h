//
//  GLRenderer.h
//  producer
//
//  Created by Akshay Loke on 6/20/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "GLTypes.h"

typedef enum GLRenderType {
    GLRenderTypeDirect, GLRenderTypeRenderToTexture
} GLRenderType;

@protocol GLRendererProtocol <NSObject>

@optional
-(void)setupDynamicVAO;
-(void)setupFBO;
-(void)bindAttributeLocations;
-(void)getUniformLocations;

-(void)updateBuffers;
-(void)renderIntoTexture;
-(void)renderDirect;

@end

@interface GLRenderer : NSObject<GLRendererProtocol>

@property (nonatomic) GLRenderType renderType;
@property (nonatomic) EAGLContext *context;
@property (nonatomic) BOOL hasContent;

-(void)setupWithSize:(CGSize)_size queue:(dispatch_queue_t)queue;
-(void)setupWithSize:(CGSize)_size queue:(dispatch_queue_t)queue context:(EAGLContext*)context;
-(void)setupWithSize:(CGSize)_size textureCache:(CVOpenGLESTextureCacheRef)_textureCache queue:(dispatch_queue_t)queue;
-(void)setupWithSize:(CGSize)_size textureCache:(CVOpenGLESTextureCacheRef)_textureCache queue:(dispatch_queue_t)queue context:(EAGLContext*)context;

-(void)setupGL;
-(void)setupStaticVAO;

-(void)teardownGL;
-(void)setColor:(UIColor*)_color;

-(CVOpenGLESTextureRef)getTexture;
-(CVPixelBufferRef)getPixelBuffer;

@end
