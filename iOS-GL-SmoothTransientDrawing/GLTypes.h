//
//  GLTypes.h
//  producer
//
//  Created by Akshay Loke on 9/27/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import <GLKit/GLKit.h>

typedef struct GLVertex {
    GLKVector4 position;
    GLKVector2 uv;
} GLVertex;

typedef struct GLLineVertex {
    GLKVector4 position;
    GLKVector2 uv;
} GLLineVertex;

typedef struct GLPointVertex {
    GLKVector4 position;
    GLKVector4 uv;
} GLPointVertex;

typedef struct GLThoughtVertex {
    GLKVector4 position;
    GLKVector4 uv0;
    GLKVector4 uv1;
} GLThoughtVertex;

typedef struct GLNotificationVertex {
    GLKVector4 position;
    GLKVector4 uv;
} GLNotificationVertex;
