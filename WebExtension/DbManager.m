//
//  DbManager.m
//  MiniKeePass
//
//  Created by Anatolii Zetilov on 13.6.15.
//  Copyright (c) 2015 Self. All rights reserved.
//

#import "DbManager.h"
#import "ExtensionCore.h"
#import "KeychainUtils.h"
#import "LockedViewController.h"
#import "ExtensionSettings.h"

@implementation DatabaseManager

static DatabaseManager *sharedInstance;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized)     {
        initialized = YES;
        sharedInstance = [[DatabaseManager alloc] init];
    }
}

+ (DatabaseManager*)sharedInstance {
    return sharedInstance;
}

- (void)openDatabaseDocument:(NSString*)filename animated:(BOOL)animated {
    BOOL databaseLoaded = NO;
    
    self.selectedFilename = filename;
    NSStringEncoding passwordEncoding = NSUnicodeStringEncoding;
    // Get the application delegate
    ExtensionCore *appDelegate = [ExtensionCore appDelegate];
    
    // Get the documents directory
    NSString *documentsDirectory = [ExtensionCore documentsDirectory];
    
    // Load the password and keyfile from the keychain
    NSString *password = [KeychainUtils stringForKey:self.selectedFilename
                                      andServiceName:@"com.jflan.MiniKeePass.passwords"];
    NSString *keyFile = [KeychainUtils stringForKey:self.selectedFilename
                                     andServiceName:@"com.jflan.MiniKeePass.keyfiles"];
    
    // Try and load the database with the cached password from the keychain
    if (password != nil || keyFile != nil) {
        // Get the absolute path to the database
        NSString *path = [documentsDirectory stringByAppendingPathComponent:self.selectedFilename];
        
        // Get the absolute path to the keyfile
        NSString *keyFilePath = nil;
        if (keyFile != nil) {
            keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
        }
        
        // Load the database
        @try {
            DatabaseDocument *dd = [[DatabaseDocument alloc] initWithFilename:path password:password keyFile:keyFilePath passwordEncoding:passwordEncoding];
            
            databaseLoaded = YES;
            
            // Set the database document in the application delegate
            appDelegate.databaseDocument = dd;
        } @catch (NSException *exception) {
            // Ignore
        }
    }
    
    // Prompt the user for the password if we haven't loaded the database yet
    if (!databaseLoaded) {
        // Prompt the user for a password
        LockedViewController *passwordViewController = [[LockedViewController alloc] initWithFilename:filename];
        passwordViewController.donePressed = ^(FormViewController *formViewController) {
            [self openDatabaseWithPasswordViewController:(LockedViewController *)formViewController];
        };
        passwordViewController.cancelPressed = ^(FormViewController *formViewController) {
            [formViewController dismissViewControllerAnimated:YES completion:nil];
        };
        
        // Create a defult keyfile name from the database name
        keyFile = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"key"];
        
        // Select the keyfile if it's in the list
        NSInteger index = [passwordViewController.keyFileCell.choices indexOfObject:keyFile];
        if (index != NSNotFound) {
            passwordViewController.keyFileCell.selectedIndex = index;
        } else {
            passwordViewController.keyFileCell.selectedIndex = 0;
        }
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:passwordViewController];
        
        [appDelegate.navigationController presentViewController:navigationController animated:animated completion:nil];
    }
}

- (void)openDatabaseWithPasswordViewController:(LockedViewController *)passwordViewController {
    NSString *documentsDirectory = [ExtensionCore documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:self.selectedFilename];
    
    NSStringEncoding passwordEncoding = NSUnicodeStringEncoding;
    
    // Get the password
    NSString *password = passwordViewController.masterPasswordFieldCell.textField.text;
    if ([password isEqualToString:@""]) {
        password = nil;
    }
    
    // Get the keyfile
    NSString *keyFile = [passwordViewController.keyFileCell getSelectedItem];
    if ([keyFile isEqualToString:NSLocalizedString(@"None", nil)]) {
        keyFile = nil;
    }
    
    // Get the absolute path to the keyfile
    NSString *keyFilePath = nil;
    if (keyFile != nil) {
        NSString *documentsDirectory = [ExtensionCore documentsDirectory];
        keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
    }
    
    // Load the database
    @try {
        // Open the database
        DatabaseDocument *dd = [[DatabaseDocument alloc] initWithFilename:path password:password keyFile:keyFilePath passwordEncoding:passwordEncoding];
        
        // Store the password in the keychain
        if ([[ExtensionSettings sharedInstance] rememberPasswordsEnabled]) {
            [KeychainUtils setString:password forKey:self.selectedFilename
                      andServiceName:@"com.jflan.MiniKeePass.passwords"];
            [KeychainUtils setString:keyFile forKey:self.selectedFilename
                      andServiceName:@"com.jflan.MiniKeePass.keyfiles"];
        }
        
        // Dismiss the view controller, and after animation set the database document
        [passwordViewController dismissViewControllerAnimated:YES completion:^{
            // Set the database document in the application delegate
            ExtensionCore *appDelegate = [ExtensionCore appDelegate];
            appDelegate.databaseDocument = dd;
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
        [passwordViewController showErrorMessage:exception.reason];
    }
}

@end