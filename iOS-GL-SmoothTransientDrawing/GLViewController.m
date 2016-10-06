//
//  GLViewController.m
//  FullscreenGLTest
//
//  Created by Akshay Loke on 2/3/16.
//  Copyright © 2016 Akshay Loke. All rights reserved.
//

#import "GLViewController.h"
#import "GLRenderToScreen.h"
#import "GLDrawingRenderer.h"

@interface GLViewController () {
    EAGLContext *context;
    
    CVOpenGLESTextureCacheRef textureCache;
    
    GLRenderToScreen *renderToScreen;
    GLDrawingRenderer *drawingRenderer;
    
    GLKView *glkView;
}

- (void) setupGL;
- (void) teardownGL;

@end

@implementation GLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"Failed to create GL Context");
    }
    
    glkView = (GLKView*)self.view;
    glkView.context = context;
    
    
    [self setupGL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupGL {
    [EAGLContext setCurrentContext:context];
    
    CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &textureCache);
    if (error) {
        NSLog(@"Error creating texture cache: %d", error);
        return;
    }
    
    renderToScreen = [[GLRenderToScreen alloc] init];
    [renderToScreen setupWithSize:self.view.frame.size queue:nil context:context];
    
    drawingRenderer = [[GLDrawingRenderer alloc] init];
    [drawingRenderer setupWithSize:self.view.frame.size textureCache:textureCache queue:nil context:context];
    [drawingRenderer setColor:[UIColor orangeColor]];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self teardownGL];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    context = nil;
}

- (void)teardownGL {
    
}

- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect {
    if (self.paused)
        self.paused = NO;
    
    [drawingRenderer renderIntoTexture];
    
    [glkView bindDrawable];
    
    [renderToScreen setInputCompositeTexture:[drawingRenderer getTexture]];
    [renderToScreen renderDirect];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    CGPoint drawTouchPoint = [touches.anyObject locationInView:self.view];
    [drawingRenderer didTouchAtPoint:drawTouchPoint withType:BEGAN];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    CGPoint drawTouchPoint = [touches.anyObject locationInView:self.view];
    [drawingRenderer didTouchAtPoint:drawTouchPoint withType:MOVED];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    CGPoint drawTouchPoint = [touches.anyObject locationInView:self.view];
    [drawingRenderer didTouchAtPoint:drawTouchPoint withType:ENDED];
}


@end

