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

#import "PortfolioViewController.h"

#import <StoreKit/StoreKit.h>

#import "UIColor+DCStyle.h"
#import "AddItemTableViewCell.h"
#import "ItemTableViewCell.h"
#import "MasternodeViewController.h"
#import "PortfolioHeaderView.h"
#import "PortfolioHeaderViewModel.h"
#import "PortfolioMasternodeTableViewCellModel.h"
#import "PortfolioViewModel.h"
#import "PortfolioWalletAddressTableViewCellModel.h"
#import "PortfolioWalletTableViewCellModel.h"
#import "SubtitleTableViewCell.h"
#import "TableViewFRCDelegate.h"
#import "WalletAddressViewController.h"

static NSString *const ADD_CELL_ID = @"AddItemTableViewCell";
static NSString *const ITEM_CELL_ID = @"ItemTableViewCell";
static NSString *const SUBTITLE_CELL_ID = @"SubtitleTableViewCell";

static CGFloat const HEADER_VIEW_HEIGHT = 88.0;

typedef NS_ENUM(NSInteger, PortfolioSection) {
    PortfolioSection_AddWallet = 0,
    PortfolioSection_Wallet = 1,
    PortfolioSection_AddWalletAddress = 2,
    PortfolioSection_WalletAddress = 3,
    PortfolioSection_AddMasternode = 4,
    PortfolioSection_Masternode = 5,
};

NS_ASSUME_NONNULL_BEGIN

@interface PortfolioViewController () <TableViewFRCDelegateNotifier, SKStoreProductViewControllerDelegate>

@property (strong, nonatomic) PortfolioHeaderViewModel *headerViewModel;
@property (strong, nonatomic) PortfolioViewModel *viewModel;
@property (strong, nonatomic) TableViewFRCDelegate *walletFRCDelegate;
@property (strong, nonatomic) TableViewFRCDelegate *walletAddressFRCDelegate;
@property (strong, nonatomic) TableViewFRCDelegate *masternodeFRCDelegate;
@property (strong, nonatomic) IBOutlet PortfolioHeaderView *portfolioHeaderView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topViewTopConstraint;

@end

@implementation PortfolioViewController

- (void)awakeFromNib {
    [super awakeFromNib];

    self.title = NSLocalizedString(@"Portfolio", nil);
    self.tabBarItem.title = self.title;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor dc_darkBlueColor];

    UIImage *emptyImage = [[UIImage alloc] init];
    self.navigationController.navigationBar.shadowImage = emptyImage;
    [self.navigationController.navigationBar setBackgroundImage:emptyImage forBarMetrics:UIBarMetricsDefault];

    self.portfolioHeaderView.viewModel = self.headerViewModel;

    NSArray<NSString *> *cellIds = @[
        ADD_CELL_ID,
        ITEM_CELL_ID,
        SUBTITLE_CELL_ID,
    ];
    for (NSString *cellId in cellIds) {
        UINib *nib = [UINib nibWithNibName:cellId bundle:nil];
        NSParameterAssert(nib);
        [self.tableView registerNib:nib forCellReuseIdentifier:cellId];
    }
    self.tableView.backgroundColor = self.view.backgroundColor;
    self.tableView.contentInset = UIEdgeInsetsMake(HEADER_VIEW_HEIGHT, 0.0, 0.0, 0.0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor dc_darkBlueColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    [refreshControl addTarget:self action:@selector(refreshControlAction:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    [self reload];

    // KVO

    [self mvvm_observe:@"viewModel.walletFetchedResultsController" with:^(typeof(self) self, id value) {
        self.viewModel.walletFetchedResultsController.delegate = self.walletFRCDelegate;
        [self.tableView reloadData];
    }];

    [self mvvm_observe:@"viewModel.walletAddressFetchedResultsController" with:^(typeof(self) self, id value) {
        self.viewModel.walletAddressFetchedResultsController.delegate = self.walletAddressFRCDelegate;
        [self.tableView reloadData];
    }];

    [self mvvm_observe:@"viewModel.masternodeFetchedResultsController" with:^(typeof(self) self, id value) {
        self.viewModel.masternodeFetchedResultsController.delegate = self.masternodeFRCDelegate;
        [self.tableView reloadData];
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark Actions

- (void)refreshControlAction:(UIRefreshControl *)sender {
    [self reload];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSFetchedResultsController *_Nullable frc = [self frcForSection:section];
    if (frc) {
        id<NSFetchedResultsSectionInfo> sectionInfo = frc.sections.firstObject;
        NSUInteger numberOfObjects = sectionInfo.numberOfObjects;
        return numberOfObjects;
    }
    else {
        // 'Add' section
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case PortfolioSection_AddWallet: {
            AddItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ADD_CELL_ID forIndexPath:indexPath];
            cell.titleText = NSLocalizedString(@"My Dash Wallet", nil);

            NSFetchedResultsController *frc = self.viewModel.walletFetchedResultsController;
            id<NSFetchedResultsSectionInfo> sectionInfo = frc.sections.firstObject;
            NSUInteger numberOfObjects = sectionInfo.numberOfObjects;
            cell.addViewHidden = (numberOfObjects > 0);

            return cell;
        }
        case PortfolioSection_AddWalletAddress: {
            AddItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ADD_CELL_ID forIndexPath:indexPath];
            cell.titleText = NSLocalizedString(@"My Wallet Addresses", nil);
            return cell;
        }
        case PortfolioSection_AddMasternode: {
            AddItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ADD_CELL_ID forIndexPath:indexPath];
            cell.titleText = NSLocalizedString(@"My Masternodes", nil);
            return cell;
        }
        case PortfolioSection_WalletAddress:
        case PortfolioSection_Masternode: {
            SubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SUBTITLE_CELL_ID forIndexPath:indexPath];
            [self configureSubtitleCell:cell atIndexPath:indexPath];
            return cell;
        }
        default: {
            ItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ITEM_CELL_ID forIndexPath:indexPath];
            [self configureItemCell:cell atIndexPath:indexPath];
            return cell;
        }
    }
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case PortfolioSection_AddWallet:
        case PortfolioSection_AddWalletAddress:
        case PortfolioSection_AddMasternode:
            return 12.0;
        default:
            return CGFLOAT_MIN;
    }
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case PortfolioSection_AddWallet:
        case PortfolioSection_AddWalletAddress:
        case PortfolioSection_AddMasternode:
            return [[UIView alloc] initWithFrame:CGRectZero];
        default:
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case PortfolioSection_AddWallet: {
            NSFetchedResultsController *frc = self.viewModel.walletFetchedResultsController;
            id<NSFetchedResultsSectionInfo> sectionInfo = frc.sections.firstObject;
            NSUInteger numberOfObjects = sectionInfo.numberOfObjects;
            if (numberOfObjects > 0) {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                return;
            }

            if ([[UIApplication sharedApplication] canOpenURL:self.viewModel.dashWalletRequestURL]) {
                [[UIApplication sharedApplication] openURL:self.viewModel.dashWalletRequestURL options:@{} completionHandler:nil];
            }
            else {
                [self openAppStoreControllerForDashWallet];
            }
            break;
        }
        case PortfolioSection_AddWalletAddress: {
            WalletAddressViewController *walletAddressController = [WalletAddressViewController controllerWalletAddress:nil];
            [self showViewController:walletAddressController sender:self];
            break;
        }
        case PortfolioSection_AddMasternode: {
            [self showAddMasternodeController];
            break;
        }
        case PortfolioSection_Wallet: {
            if ([[UIApplication sharedApplication] canOpenURL:self.viewModel.dashWalletURL]) {
                [[UIApplication sharedApplication] openURL:self.viewModel.dashWalletURL options:@{} completionHandler:nil];
            }
            else {
                [self openAppStoreControllerForDashWallet];
            }
            break;
        }
        case PortfolioSection_WalletAddress: {
            DCWalletAddressEntity *walletAddress = [self walletAddressEntityAtIndexPath:indexPath];
            WalletAddressViewController *walletAddressController = [WalletAddressViewController controllerWalletAddress:walletAddress];
            [self showViewController:walletAddressController sender:self];
            break;
        }
        case PortfolioSection_Masternode: {
            DSSimplifiedMasternodeEntryEntity *masternode = [self masternodeEntityAtIndexPath:indexPath];
            MasternodeViewController *masternodeViewController = [MasternodeViewController controllerWithMasternode:masternode];
            [self showViewController:masternodeViewController sender:self];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offset = scrollView.contentOffset.y + scrollView.contentInset.top;
    self.topViewTopConstraint.constant = MIN(-offset, 0.0);
}

#pragma mark Public

- (void)showAddMasternodeController {
    MasternodeViewController *masternodeViewController = [MasternodeViewController controllerWithMasternode:nil];
    [self showViewController:masternodeViewController sender:self];
}

#pragma mark Private

- (PortfolioViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[PortfolioViewModel alloc] init];
    }
    return _viewModel;
}

- (PortfolioHeaderViewModel *)headerViewModel {
    if (!_headerViewModel) {
        _headerViewModel = [[PortfolioHeaderViewModel alloc] init];
    }
    return _headerViewModel;
}

- (TableViewFRCDelegate *)walletFRCDelegate {
    if (!_walletFRCDelegate) {
        _walletFRCDelegate = [[TableViewFRCDelegate alloc] init];
        _walletFRCDelegate.tableView = self.tableView;
        _walletFRCDelegate.notifier = self;
        weakify;
        _walletFRCDelegate.configureCellBlock = ^(NSFetchedResultsController *_Nonnull fetchedResultsController, UITableViewCell *_Nonnull cell, NSIndexPath *_Nonnull indexPath) {
            strongify;
            [self configureItemCell:(ItemTableViewCell *)cell atIndexPath:indexPath];
        };
        _walletFRCDelegate.transformationBlock = ^NSIndexPath *_Nonnull(NSIndexPath *_Nonnull indexPath) {
            return [NSIndexPath indexPathForRow:indexPath.row inSection:PortfolioSection_Wallet];
        };
    }
    return _walletFRCDelegate;
}

- (TableViewFRCDelegate *)walletAddressFRCDelegate {
    if (!_walletAddressFRCDelegate) {
        _walletAddressFRCDelegate = [[TableViewFRCDelegate alloc] init];
        _walletAddressFRCDelegate.tableView = self.tableView;
        _walletAddressFRCDelegate.notifier = self;
        weakify;
        _walletAddressFRCDelegate.configureCellBlock = ^(NSFetchedResultsController *_Nonnull fetchedResultsController, UITableViewCell *_Nonnull cell, NSIndexPath *_Nonnull indexPath) {
            strongify;
            [self configureSubtitleCell:(SubtitleTableViewCell *)cell atIndexPath:indexPath];
        };
        _walletAddressFRCDelegate.transformationBlock = ^NSIndexPath *_Nonnull(NSIndexPath *_Nonnull indexPath) {
            return [NSIndexPath indexPathForRow:indexPath.row inSection:PortfolioSection_WalletAddress];
        };
    }
    return _walletAddressFRCDelegate;
}

- (TableViewFRCDelegate *)masternodeFRCDelegate {
    if (!_masternodeFRCDelegate) {
        _masternodeFRCDelegate = [[TableViewFRCDelegate alloc] init];
        _masternodeFRCDelegate.tableView = self.tableView;
        _masternodeFRCDelegate.notifier = self;
        weakify;
        _masternodeFRCDelegate.configureCellBlock = ^(NSFetchedResultsController *_Nonnull fetchedResultsController, UITableViewCell *_Nonnull cell, NSIndexPath *_Nonnull indexPath) {
            strongify;
            [self configureSubtitleCell:(SubtitleTableViewCell *)cell atIndexPath:indexPath];
        };
        _masternodeFRCDelegate.transformationBlock = ^NSIndexPath *_Nonnull(NSIndexPath *_Nonnull indexPath) {
            return [NSIndexPath indexPathForRow:indexPath.row inSection:PortfolioSection_Masternode];
        };
    }
    return _masternodeFRCDelegate;
}

- (NSFetchedResultsController *)frcForSection:(PortfolioSection)section {
    switch (section) {
        case PortfolioSection_Wallet:
            return self.viewModel.walletFetchedResultsController;
        case PortfolioSection_WalletAddress:
            return self.viewModel.walletAddressFetchedResultsController;
        case PortfolioSection_Masternode:
            return self.viewModel.masternodeFetchedResultsController;
        default:
            return nil;
    }
}

- (DCWalletEntity *)walletEntityAtIndexPath:(NSIndexPath *)indexPath {
    NSFetchedResultsController *frc = self.viewModel.walletFetchedResultsController;
    id<NSFetchedResultsSectionInfo> sectionInfo = frc.sections.firstObject;
    NSArray *objects = sectionInfo.objects;
    DCWalletEntity *entity = objects[indexPath.row];
    return entity;
}

- (DCWalletAddressEntity *)walletAddressEntityAtIndexPath:(NSIndexPath *)indexPath {
    NSFetchedResultsController *frc = self.viewModel.walletAddressFetchedResultsController;
    id<NSFetchedResultsSectionInfo> sectionInfo = frc.sections.firstObject;
    NSArray *objects = sectionInfo.objects;
    DCWalletAddressEntity *entity = objects[indexPath.row];
    return entity;
}

- (DSSimplifiedMasternodeEntryEntity *)masternodeEntityAtIndexPath:(NSIndexPath *)indexPath {
    NSFetchedResultsController *frc = self.viewModel.masternodeFetchedResultsController;
    id<NSFetchedResultsSectionInfo> sectionInfo = frc.sections.firstObject;
    NSArray *objects = sectionInfo.objects;
    DSSimplifiedMasternodeEntryEntity *entity = objects[indexPath.row];
    return entity;
}

- (void)configureItemCell:(ItemTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    id<ItemTableViewCellModel> viewModel = nil;
    switch (indexPath.section) {
        case PortfolioSection_Wallet: {
            DCWalletEntity *entity = [self walletEntityAtIndexPath:indexPath];
            viewModel = [[PortfolioWalletTableViewCellModel alloc] initWithEntity:entity];
            break;
        }
        default: {
            NSAssert(NO, @"Invalid section");
            break;
        }
    }

    cell.viewModel = viewModel;
}

- (void)configureSubtitleCell:(SubtitleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    id<SubtitleTableViewCellModel> viewModel = nil;
    switch (indexPath.section) {
        case PortfolioSection_WalletAddress: {
            DCWalletAddressEntity *entity = [self walletAddressEntityAtIndexPath:indexPath];
            viewModel = [[PortfolioWalletAddressTableViewCellModel alloc] initWithEntity:entity];
            break;
        }
        case PortfolioSection_Masternode: {
            DSSimplifiedMasternodeEntryEntity *entity = [self masternodeEntityAtIndexPath:indexPath];
            viewModel = [[PortfolioMasternodeTableViewCellModel alloc] initWithEntity:entity];
            break;
        }
        default: {
            NSAssert(NO, @"Invalid section");
            break;
        }
    }
    cell.viewModel = viewModel;
}

- (void)reload {
    if (self.tableView.contentOffset.y == -HEADER_VIEW_HEIGHT) {
        self.tableView.contentOffset = CGPointMake(0.0, -(self.tableView.refreshControl.frame.size.height + HEADER_VIEW_HEIGHT));
        [self.tableView.refreshControl beginRefreshing];
    }

    // triggers update on wallet address view models
    [self.tableView reloadData];

    weakify;
    [self.headerViewModel reloadWithCompletion:^{
        strongify;

        [self.tableView.refreshControl endRefreshing];
    }];
}

- (void)openAppStoreControllerForDashWallet {
    SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
    storeViewController.delegate = self;
    NSDictionary *parameters = @{ SKStoreProductParameterITunesItemIdentifier : @(self.viewModel.dashWalletAppStoreID) };
    [storeViewController loadProductWithParameters:parameters completionBlock:nil];
    [self presentViewController:storeViewController animated:YES completion:nil];
}

#pragma mark TableViewFRCDelegateNotifier

- (void)tableViewFRCDelegateDidUpdate:(TableViewFRCDelegate *)frcDelegate {
    if (frcDelegate == self.walletFRCDelegate) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:PortfolioSection_AddWallet] ] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }

    [self.headerViewModel updateDashTotalWorth];
}

#pragma mark SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

NS_ASSUME_NONNULL_END
