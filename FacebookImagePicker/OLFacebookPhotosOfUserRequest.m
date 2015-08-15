//
//  OLFacebookPhotosOfUserRequest.m
//  FacebookImagePicker
//
//  Created by Andrew Morris on 14/08/2015.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLFacebookPhotosOfUserRequest.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "OLFacebookImage.h"
#import "OLFacebookImagePickerConstants.h"

@interface OLFacebookPhotosOfUserRequest ()
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, strong) NSString *after;
@end

@implementation OLFacebookPhotosOfUserRequest

- (id)initAfter:(NSString *)after {
    
    if (self = [super init]) {
        self.after = after;
    }
    
    return self;
}

- (void)getPhotos:(OLFacebookPhotosOfUserRequestHandler)handler {
    
    __block BOOL runOnce = NO;
    
    if ([FBSDKAccessToken currentAccessToken]) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        if (runOnce || self.cancelled) {
            return;
        }
        runOnce = YES;
        
        
        NSString *graphPath = @"me/photos?limit=500";
        if (self.after) {
            graphPath = [graphPath stringByAppendingFormat:@"&after=%@", self.after];
        }
        [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:nil]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             
             if (!error) {
                 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                 if (self.cancelled) {
                     return;
                 }
                 
                 NSString *parsingErrorMessage = @"Failed to parse Facebook Response. Please check your internet connectivity and try again.";
                 NSError *parsingError = [NSError errorWithDomain:kOLErrorDomainFacebookImagePicker code:kOLErrorCodeFacebookImagePickerBadResponse userInfo:@{NSLocalizedDescriptionKey: parsingErrorMessage}];
                 
                 id data = [result objectForKey:@"data"];
                 if (![data isKindOfClass:[NSArray class]]) {
                     handler(nil, parsingError, nil);
                     return;
                 }
                 
                 NSMutableArray *photosOfUser = [[NSMutableArray alloc] init];
                 for (id photo in data) {
                     id thumbURLString = [photo objectForKey:@"picture"];
                     id fullURLString  = [photo objectForKey:@"source"];
                     
                     if (!([thumbURLString isKindOfClass:[NSString class]] && [fullURLString isKindOfClass:[NSString class]])) {
                         continue;
                     }
                     
                     NSMutableArray *sourceImages = [[NSMutableArray alloc] init];
                     if ([photo[@"images"] isKindOfClass:[NSArray class]]) {
                         for (id image in photo[@"images"]) {
                             id source = image[@"source"];
                             id width = image[@"width"];
                             id height = image[@"height"];
                             if ([source isKindOfClass:[NSString class]] &&
                                 [width isKindOfClass:[NSNumber class]] &&
                                 [height isKindOfClass:[NSNumber class]]) {
                                 [sourceImages addObject:[[OLFacebookImageURL alloc] initWithURL:[NSURL URLWithString:source] size:CGSizeMake([width doubleValue], [height doubleValue])]];
                             }
                         }
                     }
                     
                     OLFacebookImage *image = [[OLFacebookImage alloc] initWithThumbURL:[NSURL URLWithString:thumbURLString] fullURL:[NSURL URLWithString:fullURLString] albumId:nil sourceImages:sourceImages];
                     [photosOfUser addObject:image];
                 }
                 
                 // get next page cursor
                 OLFacebookPhotosOfUserRequest *nextPageRequest = nil;
                 id paging = [result objectForKey:@"paging"];
                 if ([paging isKindOfClass:[NSDictionary class]]) {
                     id cursors = [paging objectForKey:@"cursors"];
                     id next = [paging objectForKey:@"next"]; // next will be non nil if a next page exists
                     if (next && [cursors isKindOfClass:[NSDictionary class]]) {
                         id after = [cursors objectForKey:@"after"];
                         if ([after isKindOfClass:[NSString class]]) {
                             nextPageRequest = [[OLFacebookPhotosOfUserRequest alloc] initAfter:after];
                         }
                     }
                 }
                 
                 handler(photosOfUser, nil, nextPageRequest);
             }
         }];
    }
}

- (void)cancel {
    
    self.cancelled = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

+ (void)handleFacebookError:(NSError *)error completionHandler:(OLFacebookPhotosOfUserRequestHandler)handler {
    
    /*
     NSString *message;
     if ([FBErrorUtility shouldNotifyUserForError:error]) {
     message = [FBErrorUtility userMessageForError:error];
     } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
     message = @"Your current Facebook session is no longer valid. Please log in again.";
     } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
     message = @"The app requires authorization to access your Facebook photos to continue. Please open Settings and provide access.";
     } else {
     message = @"Failed to access your Facebook photos. Please check your internet connectivity and try again.";
     }
     
     handler(nil, [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedDescriptionKey: message}], nil);
     
     */
}


@end
