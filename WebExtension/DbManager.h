//
//  DbManager.h
//  MiniKeePass
//
//  Created by Anatolii Zetilov on 13.6.15.
//  Copyright (c) 2015 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FormViewController.h"

@interface DatabaseManager : NSObject

/// A string containing the name of the KeePass DatabaseDocument to be managed
@property (nonatomic, copy) NSString *selectedFilename;

/// Create a DatabaseManager instance
+ (DatabaseManager*)sharedInstance;

/// Open the specified KeePass DatabaseDocument
/// @param path Path to the chosen KeePass DatabaseDocument
/// @param animated Animate the ViewController transition
- (void)openDatabaseDocument:(NSString*)path animated:(BOOL)newAnimated;

@end
