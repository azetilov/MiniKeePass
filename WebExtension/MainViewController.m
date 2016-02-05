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

@property (nonatomic, strong) SelectFileViewController *filesViewController;

@end

@implementation MainViewController

- (void)loadView
{
    [super loadView];
    [ExtensionCore appDelegate].navigationController = self;
    
    // TODO: display toolbar button to open the containing app
    self.toolbarHidden = YES;
    
    self.navigationBarHidden = NO;
    
    self.filesViewController = [[SelectFileViewController alloc] initWithStyle:UITableViewStylePlain];
    
    self.filesViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                         target:self
                                                                                                         action:@selector(cancelPressed:)];
    
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *itemProvider = item.attachments.firstObject;
    if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *item, NSError *error) {
            NSDictionary *results = (NSDictionary *)item;
            NSString *requestUrl = [[results objectForKey:NSExtensionJavaScriptPreprocessingResultsKey] objectForKey:@"url"];
            NSURL *url = [[NSURL alloc] initWithString:requestUrl];
            [self presentFilesViewController: url];
        }];
    }
}

- (void)presentFilesViewController: (NSURL *)url {
    
    self.filesViewController.searchUrl = url;
    
    [self pushViewController:self.filesViewController animated:YES];
}

- (void)cancel {
    [self.extensionContext completeRequestReturningItems:self.navigationController.extensionContext.inputItems completionHandler:nil];
}

#pragma mark - Button actions

- (void)cancelPressed:(id)sender {
    if (self.cancelPressed != nil) {
        [self cancelPressed];
    }
    [self cancel];
}
@end