//
//  GLPrimitives.h
//  producer
//
//  Created by Akshay Loke on 6/6/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef enum GLLinePointPosition {
    GLLinePointPositionStart, GLLinePointPositionMiddle, GLLinePointPositionEnd, GLLinePointPositionDot
} GLLinePointPosition;

@interface GLLinePoint : NSObject

@property (nonatomic) GLKVector2 point;
@property (nonatomic) GLKVector2 normal;
@property (nonatomic) GLLinePointPosition linePointPosition;
@property (nonatomic) float drawTimeDelta;

-(id)initWithPoint:(GLKVector2)point normal:(GLKVector2)normal position:(GLLinePointPosition)position drawTimeDelta:(float)drawTimeDelta;

@end
