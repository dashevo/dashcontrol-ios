//
//  Created by Andrew Podkovyrin
//
//  Copyright (c) 2015-2018 Spotify AB.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the
//  "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HTTPRequest;

@protocol HTTPLoaderAuthoriser;

@protocol HTTPLoaderAuthoriserDelegate <NSObject>

- (void)httpLoaderAuthoriser:(id<HTTPLoaderAuthoriser>)httpLoaderAuthoriser authorisedRequest:(HTTPRequest *)request;
- (void)httpLoaderAuthoriser:(id<HTTPLoaderAuthoriser>)httpLoaderAuthoriser didFailToAuthoriseRequest:(HTTPRequest *)request withError:(NSError *)error;

@end

@protocol HTTPLoaderAuthoriser <NSObject, NSCopying>

@property (readonly, copy, nonatomic) NSString *identifier;
@property (nullable, weak, nonatomic) id<HTTPLoaderAuthoriserDelegate> delegate;

- (BOOL)requestRequiresAuthorisation:(HTTPRequest *)request;
- (void)authoriseRequest:(HTTPRequest *)request;
- (void)requestFailedAuthorisation:(HTTPRequest *)request;
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
