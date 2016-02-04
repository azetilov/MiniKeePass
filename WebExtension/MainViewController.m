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
#import <MobileCoreServices/MobileCoreServices.h>

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
    
    filesViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(donePressed:)];
    
    [self pushViewController:filesViewController animated:YES];
}

- (void)presentSelectFileViewControllerForSearchUrl:(NSURL*)url {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *itemProvider = item.attachments.firstObject;
    if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *item, NSError *error) {
            NSDictionary *results = (NSDictionary *)item;
            NSString *requestUrl = [[results objectForKey:NSExtensionJavaScriptPreprocessingResultsKey] objectForKey:@"url"];
            NSURL *url = [[NSURL alloc] initWithString:requestUrl];
            [ExtensionCore appDelegate].searchUrl = url;
            [self presentSelectFileViewControllerForSearchUrl:url];
        }];
    }
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