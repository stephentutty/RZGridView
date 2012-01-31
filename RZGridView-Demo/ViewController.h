//
//  ViewController.h
//  RZGridView-Demo
//
//  Created by Joe Goullaud on 1/24/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZGridView.h"

@interface ViewController : UIViewController <RZGridViewDelegate, RZGridViewDataSource>
@property (retain, nonatomic) IBOutlet RZGridView *gridView;
@property (retain, nonatomic) NSMutableArray *numbersArray;

@end
