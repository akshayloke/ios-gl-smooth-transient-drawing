//
//  GLRenderToScreen.h
//  producer
//
//  Created by Akshay Loke on 9/29/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "GLRenderer.h"

@interface GLRenderToScreen : GLRenderer

-(void)setInputCompositeTexture:(CVOpenGLESTextureRef)_compositeTexture;

@end
