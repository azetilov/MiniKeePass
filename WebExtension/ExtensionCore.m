/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "ExtensionCore.h"
#import "GroupViewController.h"
//#import "SettingsViewController.h"
#import "EntryViewController.h"
#import "ExtensionSettings.h"
//#import "DatabaseManager.h"
#import "KeychainUtils.h"
//#import "LockScreenManager.h"
#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ExtensionCore ()
@end

@implementation ExtensionCore


static ExtensionCore *appDelegate;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        appDelegate = [[ExtensionCore alloc] init];
    }
}

+ (ExtensionCore *)appDelegate {
    return appDelegate;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Check file protection
    [self checkFileProtection];
    
    // Get the time when the application last exited
    ExtensionSettings *appSettings = [ExtensionSettings sharedInstance];
    NSDate *exitTime = [appSettings exitTime];
    
    // Check if closing the database is enabled
    if ([appSettings closeEnabled] && exitTime != nil) {
        // Get the lock timeout (in seconds)
        NSInteger closeTimeout = [appSettings closeTimeout];
        
        // Check if it's been longer then close timeout
        NSTimeInterval timeInterval = [exitTime timeIntervalSinceNow];
        if (timeInterval < -closeTimeout) {
            [self closeDatabase];
        }
    }
}

+ (NSString *)documentsDirectory {
    NSURL *sharedContainerUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_ID];
    return [[sharedContainerUrl URLByAppendingPathComponent:@"databases" isDirectory:YES] path];
}

+ (NSString *)sharedDirectory {
    NSURL *sharedContainerUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_ID];
    return [[sharedContainerUrl URLByAppendingPathComponent:@"databases" isDirectory:YES] path];
}

- (void)done:(NSArray *)results {
    
    NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    NSDictionary *item = [[NSDictionary alloc] initWithObjectsAndKeys: result, @"NSExtensionJavaScriptFinalizeArgumentKey", nil];
    
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem: item typeIdentifier: (NSString *)kUTTypePropertyList];
    extensionItem.attachments = [[NSArray alloc] initWithObjects:itemProvider, nil];
    
    NSExtensionContext *extensionContext = self.navigationController.extensionContext;
    if (results.count > 0) {
        KdbEntry *entry = (KdbEntry *)results.firstObject;
        if (entry != nil) {
            result[@"username"] = entry.username;
            result[@"password"] = entry.password;
        }
    }
    [extensionContext completeRequestReturningItems:[[NSArray alloc] initWithObjects:extensionItem, nil] completionHandler:nil];
}

- (void)closeDatabase {
    // Close any open database views
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    //_databaseDocument = nil;
}

- (void)deleteKeychainData {
    // Reset some settings
    ExtensionSettings *appSettings = [ExtensionSettings sharedInstance];
    [appSettings setPinFailedAttempts:0];
    [appSettings setPinEnabled:NO];
    [appSettings setTouchIdEnabled:NO];

    // Delete the PIN from the keychain
    [KeychainUtils deleteStringForKey:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin"];

    // Delete all database passwords from the keychain
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.passwords"];
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.keyfiles"];
}

- (void)deleteAllData {
    // Close the current database
    [self closeDatabase];

    // Delete data stored in system keychain
    [self deleteKeychainData];

    // Get the files in the Documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [ExtensionCore documentsDirectory];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // Delete all the files in the Documents directory
    for (NSString *file in files) {
        [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:file] error:nil];
    }
}

- (void)checkFileProtection {
    // Get the document's directory
    NSString *documentsDirectory = [ExtensionCore documentsDirectory];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Check all files to see if protection is enabled
    for (NSString *file in dirContents) {
        if (![file hasPrefix:@"."]) {
            NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

            BOOL dir = NO;
            [fileManager fileExistsAtPath:path isDirectory:&dir];
            if (!dir) {
                // Make sure file protecten is turned on
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
                NSString *fileProtection = [attributes valueForKey:NSFileProtectionKey];
                if (![fileProtection isEqualToString:NSFileProtectionComplete]) {
                    [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionComplete} ofItemAtPath:path error:nil];
                }
            }
        }
    }
}

@end
