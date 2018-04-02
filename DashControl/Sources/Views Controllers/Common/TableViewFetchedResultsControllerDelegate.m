//
//  Created by Andrew Podkovyrin
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "TableViewFetchedResultsControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TableViewFetchedResultsControllerDelegate ()

@property (strong, nonatomic) NSMutableArray<NSIndexPath *> *deletedRowIndexPaths;
@property (strong, nonatomic) NSMutableArray<NSIndexPath *> *insertedRowIndexPaths;
@property (strong, nonatomic) NSMutableArray<NSIndexPath *> *updatedRowIndexPaths;

@end

@implementation TableViewFetchedResultsControllerDelegate

- (NSMutableArray<NSIndexPath *> *)deletedRowIndexPaths {
    if (!_deletedRowIndexPaths) {
        _deletedRowIndexPaths = [NSMutableArray array];
    }
    return _deletedRowIndexPaths;
}

- (NSMutableArray<NSIndexPath *> *)insertedRowIndexPaths {
    if (!_insertedRowIndexPaths) {
        _insertedRowIndexPaths = [NSMutableArray array];
    }
    return _insertedRowIndexPaths;
}

- (NSMutableArray<NSIndexPath *> *)updatedRowIndexPaths {
    if (!_updatedRowIndexPaths) {
        _updatedRowIndexPaths = [NSMutableArray array];
    }
    return _updatedRowIndexPaths;
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.insertedRowIndexPaths addObject:self.transformationBlock ? self.transformationBlock(newIndexPath) : newIndexPath];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.deletedRowIndexPaths addObject:self.transformationBlock ? self.transformationBlock(indexPath) : indexPath];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self.updatedRowIndexPaths addObject:self.transformationBlock ? self.transformationBlock(indexPath) : indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.insertedRowIndexPaths addObject:self.transformationBlock ? self.transformationBlock(newIndexPath) : newIndexPath];
            [self.deletedRowIndexPaths addObject:self.transformationBlock ? self.transformationBlock(indexPath) : indexPath];
            break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSParameterAssert(self.tableView);

    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:self.deletedRowIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView insertRowsAtIndexPaths:self.insertedRowIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView reloadRowsAtIndexPaths:self.updatedRowIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];

    [self.deletedRowIndexPaths removeAllObjects];
    [self.insertedRowIndexPaths removeAllObjects];
    [self.updatedRowIndexPaths removeAllObjects];
}

@end

NS_ASSUME_NONNULL_END
