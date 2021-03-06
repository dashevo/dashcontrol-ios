//
//  Created by Andrew Podkovyrin
//  Copyright © 2018 Andrew Podkovyrin. All rights reserved.
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

#ifndef HTTPLoaderBlocks_h
#define HTTPLoaderBlocks_h

NS_ASSUME_NONNULL_BEGIN

@class HTTPResponse;

typedef void (^HTTPLoaderCompletionBlock)(id _Nullable parsedData, NSDictionary *_Nullable responseHeaders, NSInteger statusCode, NSError *_Nullable error);
typedef void (^HTTPLoaderRawCompletionBlock)(BOOL success, BOOL cancelled, HTTPResponse * _Nullable response);

NS_ASSUME_NONNULL_END

#endif /* HTTPLoaderBlocks_h */
