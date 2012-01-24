//
//  ViewController.m
//  RZGridView-Demo
//
//  Created by Joe Goullaud on 1/24/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize gridView = _gridView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.gridView.dataSource = self;
    self.gridView.delegate = self;
}

- (void)viewDidUnload
{
    [self setGridView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)dealloc {
    [_gridView release];
    [super dealloc];
}

#pragma mark - RZGridViewDataSource

- (NSInteger)gridView:(RZGridView*)gridView numberOfRowsInSection:(NSInteger)section
{
    return 30;
}

- (NSInteger)gridView:(RZGridView*)gridView numberOfColumnsInRow:(NSInteger)row inSection:(NSInteger)section
{
    return 3;
}

- (RZGridViewCell*)gridView:(RZGridView*)gridView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"ExampleCell";
    
    RZGridViewCell *cell = [[[RZGridViewCell alloc] initWithStyle:RZGridViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    
    NSInteger colorIndex = indexPath.gridRow * 3 + indexPath.gridColumn;
    
    UIColor *color = nil;
    
    switch (colorIndex % 9) {
        case 0:
            color = [UIColor redColor];
            break;
        case 1:
            color = [UIColor orangeColor];
            break;
        case 2:
            color = [UIColor yellowColor];
            break;
        case 3:
            color = [UIColor greenColor];
            break;
        case 4:
            color = [UIColor cyanColor];
            break;
        case 5:
            color = [UIColor blueColor];
            break;
        case 6:
            color = [UIColor purpleColor];
            break;
        case 7:
            color = [UIColor magentaColor];
            break;
        case 8:
            color = [UIColor grayColor];
            break;
            
        default:
            color = [UIColor blackColor];
            break;
    }
    
    cell.backgroundColor = color;
    
    return cell;
}

- (void)gridView:(RZGridView *)gridView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSLog(@"Item Moved from: %@ to: %@", sourceIndexPath, destinationIndexPath);
}


@end
