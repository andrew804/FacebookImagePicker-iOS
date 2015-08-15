//
//  OLFacebookPhotosOfUserRequest.h
//  FacebookImagePicker
//
//  Created by Andrew Morris on 14/08/2015.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLFacebookPhotosOfUserRequest;

typedef void (^OLFacebookPhotosOfUserRequestHandler)(NSArray/*<OLFacebookImage>*/ *photos, NSError *error, OLFacebookPhotosOfUserRequest *nextPageRequest);

@interface OLFacebookPhotosOfUserRequest : NSObject
- (void)getPhotos:(OLFacebookPhotosOfUserRequestHandler)handler;
- (void)cancel;
@end
