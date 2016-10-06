//
//  ViewController.m
//  GL-Drawing
//
//  Created by Akshay Loke on 7/26/16.
//  Copyright © 2016 Akshay Loke. All rights reserved.
//

#import "ViewController.h"
#import "GLViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated {
    GLViewController *glViewController = [[GLViewController alloc] init];
    [self presentViewController:glViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
