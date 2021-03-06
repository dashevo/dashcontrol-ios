//
//  DCWalletAccount.h
//  DashControl
//
//  Created by Sam Westrich on 10/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint32_t, WalletAccountState) {
    WalletAccountFailed = -1,
    WalletAccountStopped = 0,
    WalletAccountStarting = 1,
    WalletAccountActive = 2
};

@class DCWalletAccountEntity;
@class NSManagedObjectContext;
@class DSChain;

@interface DCWalletAccount : NSObject

@property (readonly, assign, nonatomic) WalletAccountState state;

- (instancetype)initWithAccountPublicKey:(NSString *)accountPublicKey
                                    hash:(nullable NSString *)hash
                               inContext:(NSManagedObjectContext *)context
                                 onChain:(DSChain *)chain;

- (void)startUpWithWalletAccountEntity:(DCWalletAccountEntity *)walletAccountEntity;

- (NSArray *)addressesWithGapLimit:(NSUInteger)gapLimit internal:(BOOL)internal withWalletAccountEntity:(nullable DCWalletAccountEntity *)walletAccountEntity;

@end

NS_ASSUME_NONNULL_END
