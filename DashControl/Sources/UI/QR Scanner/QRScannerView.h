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

#import <KVO-MVVM/KVOUIView.h>

NS_ASSUME_NONNULL_BEGIN

@class QRScannerViewModel;
@class QRScannerView;

@protocol QRScannerViewDelegate <NSObject>

- (void)qrScannerViewDidCancel:(QRScannerView *)view;
- (void)qrScannerView:(QRScannerView *)view didScanString:(NSString *)scannedString;

@end

@interface QRScannerView : KVOUIView

@property (strong, nonatomic) QRScannerViewModel *viewModel;
@property (nullable, weak, nonatomic) id<QRScannerViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
