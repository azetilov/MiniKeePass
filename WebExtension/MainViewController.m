//
//  MainViewController.m
//  MiniKeePass
//
//  Created by Anatolii Zetilov on 24.1.15.
//  Copyright (c) 2015 Self. All rights reserved.
//
#import "MainViewController.h"
#import "SelectFileViewController.h"
#import "ExtensionCore.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)loadView
{
    [super loadView];
    [ExtensionCore appDelegate].navigationController = self;
    
    // TODO: display toolbar button to open the containing app
    self.toolbarHidden = YES;
    
    self.navigationBarHidden = NO;
    
    SelectFileViewController *filesViewController = [[SelectFileViewController alloc] initWithStyle:UITableViewStylePlain];
    
    filesViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(donePressed:)];
    
    [self pushViewController:filesViewController animated:YES];
}

- (IBAction)done {
    
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

#pragma mark - Button actions

- (void)donePressed:(id)sender {
    if (self.donePressed != nil) {
        self.donePressed(self);
    }
    [self done];
}

@end