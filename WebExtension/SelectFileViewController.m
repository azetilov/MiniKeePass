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
#import "SelectFileViewController.h"
#import "DbManager.h"
//#import "AppSettings.h"
//#import "KeychainUtils.h"
//#import "Kdb3Writer.h"
//#import "Kdb4Writer.h"

//#import <MobileCoreServices/UTCoreTypes.h>

enum {
    SECTION_DATABASE,
    SECTION_KEYFILE,
    SECTION_NUMBER
};

@interface SelectFileViewController () <UIDocumentPickerDelegate, UIDocumentMenuDelegate>

@property (nonatomic, strong) NSMutableArray *databaseFiles;
@property (nonatomic, strong) NSMutableArray *keyFiles;
@end

@implementation SelectFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Files", nil);
    self.tableView.editing = NO;
    self.tableView.allowsSelectionDuringEditing = NO;
    self.tableView.allowsSelection = YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateFiles];

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

    [self.tableView reloadData];

    if (selectedIndexPath != nil) {
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }

    [super viewWillAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)updateFiles {
    self.databaseFiles = [[NSMutableArray alloc] init];
    self.keyFiles = [[NSMutableArray alloc] init];

    // Get the document's directory
    NSString *documentsDirectory = [ExtensionCore documentsDirectory];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Sort the files into database files and keyfiles
    for (NSString *file in dirContents) {
        NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

        // Check if it's a directory
        BOOL dir = NO;
        [fileManager fileExistsAtPath:path isDirectory:&dir];
        if (!dir) {
            NSString *extension = [[file pathExtension] lowercaseString];
            if ([extension isEqualToString:@"kdb"] || [extension isEqualToString:@"kdbx"]) {
                [self.databaseFiles addObject:file];
            } else {
                [self.keyFiles addObject:file];
            }
        }
    }

    // Sort the list of files
    [self.databaseFiles sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [self.keyFiles sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // If there's only one database, then open it
    if (self.databaseFiles.count == 1) {
        [[DatabaseManager sharedInstance] openDatabaseDocument:[self.databaseFiles objectAtIndex:0] animated:NO searchUrl:nil];
    }
}

- (void)displayInfoView {

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
}

- (void)hideInfoView {

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.scrollEnabled = YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DATABASE:
            if ([self.databaseFiles count] != 0) {
                return NSLocalizedString(@"Databases", nil);
            }
            break;
        case SECTION_KEYFILE:
            if ([self.keyFiles count] != 0) {
                return NSLocalizedString(@"Key Files", nil);
            }
            break;
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger databaseCount = [self.databaseFiles count];
    NSUInteger keyCount = [self.keyFiles count];

    NSInteger n;
    switch (section) {
        case SECTION_DATABASE:
            n = databaseCount;
            break;
        case SECTION_KEYFILE:
            n = keyCount;
            break;
        default:
            n = 0;
            break;
    }

    // Show the help view if there are no files
    if (databaseCount == 0 && keyCount == 0) {
        [self displayInfoView];
    } else {
        [self hideInfoView];
    }

    return n;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSString *filename = @"";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    // Configure the cell
    switch (indexPath.section) {
        case SECTION_DATABASE:
            filename = [self.databaseFiles objectAtIndex:indexPath.row];
            cell.textLabel.text = filename;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
        case SECTION_KEYFILE:
            filename = [self.keyFiles objectAtIndex:indexPath.row];
            cell.textLabel.text = filename;
            cell.textLabel.textColor = [UIColor grayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        default:
            return nil;
    }

    // Retrieve the Document directory
    NSString *documentsDirectory = [ExtensionCore documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    // Get the file's modification date
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDate *modificationDate = [[fileManager attributesOfItemAtPath:path error:nil] fileModificationDate];

    // Format the last modified time as the subtitle of the cell
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@",
                                 NSLocalizedString(@"Last Modified", nil),
                                 [dateFormatter stringFromDate:modificationDate]];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        // Database file section
        case SECTION_DATABASE:
            if (self.editing == NO) {
                // Load the database
                [[DatabaseManager sharedInstance] openDatabaseDocument:[self.databaseFiles objectAtIndex:indexPath.row] animated:YES searchUrl:nil];
            }
            break;
        default:
            break;
    }
}

#pragma mark - Actions

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    //[[MiniKeePassAppDelegate appDelegate] importUrl:url];
}


- (IBAction)donePressed:(id)sender {
    //[self.navigationController popViewControllerAnimated:YES];
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
    //[self dismissViewControllerAnimated:YES completion:nil];
}
@end
