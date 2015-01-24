//
//  MainViewController.m
//  MiniKeePass
//
//  Created by Anatolii Zetilov on 24.1.15.
//  Copyright (c) 2015 Self. All rights reserved.
//
#import "MainViewController.h"
#import "SelectFileViewController.h"

@interface MainViewController ()

@property (nonatomic, strong) SelectFileViewController *filesViewController;
@property (nonatomic, strong) UINavigationController *navigationController;

@end

@implementation MainViewController

- (void)loadView
{
    [super loadView];
    
    self.filesViewController = [[SelectFileViewController alloc] initWithStyle:UITableViewStylePlain];
    
    [self pushViewController:self.filesViewController animated:YES];
}

@end