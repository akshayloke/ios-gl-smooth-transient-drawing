//
//  GLLinePrimitives.m
//  producer
//
//  Created by Akshay Loke on 6/6/16.
//  Copyright © 2016 Dom Hofmann. All rights reserved.
//


#import "GLPrimitives.h"

@implementation GLLinePoint

-(id)initWithPoint:(GLKVector2)point normal:(GLKVector2)normal position:(GLLinePointPosition)position drawTimeDelta:(float)drawTimeDelta {
    if (self = [super init]) {
        self.point = point;
        self.normal = normal;
        self.linePointPosition = position;
        self.drawTimeDelta = drawTimeDelta;
    }
    return self;
}

@end
