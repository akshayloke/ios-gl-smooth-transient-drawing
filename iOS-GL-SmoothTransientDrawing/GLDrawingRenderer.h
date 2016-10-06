//
//  GLDrawingTool.h
//  producer
//
//  Created by Akshay Loke on 6/6/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "GLRenderer.h"

typedef enum TouchType {
    BEGAN, MOVED, ENDED
} TouchType;

@interface GLDrawingRenderer : GLRenderer

-(void)didTouchAtPoint:(CGPoint)point withType:(TouchType)type;

@end
