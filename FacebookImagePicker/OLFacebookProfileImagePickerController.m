//
//  OLFacebookProfileImagePickerController.m
//  FacebookImagePicker
//
//  Created by Andrew Morris on 25/04/2016.
//  Copyright © 2016 Deon Botha. All rights reserved.
//

#import "OLFacebookProfileImagePickerController.h"
#import "OLFacebookAlbum.h"
#import "OLFacebookImage.h"
#import "OLFacebookAlbumRequest.h"
#import "OLFacebookPhotosForAlbumRequest.h"
#import <SDWebImage/SDWebImageManager.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#define PROFILE_PICTURES_ALBUM_NAME @"Profile Pictures"
#define PROFILE_PICTURES_ALBUM_TYPE @"profile"

typedef void (^ CompletedPermissionCheck)();

@interface OLFacebookProfileImagePickerController ()
@property (nonatomic, strong) OLFacebookAlbumRequest *albumRequest;
@property (nonatomic, strong) OLFacebookPhotosForAlbumRequest *photosForAlbumRequest;
@property (nonatomic, strong) OLFacebookCompletedGettingProfileImages completedGettingProfileImages;
@property (nonatomic, strong) CompletedPermissionCheck completedFBPermissionCheck;
@end

static OLFacebookProfileImagePickerController *defaultController;

@implementation OLFacebookProfileImagePickerController

#pragma mark - Life Cycle
//------------------------
- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.albumRequest = [OLFacebookAlbumRequest new];
        self.photosForAlbumRequest = [OLFacebookPhotosForAlbumRequest new];
    }
    
    return self;
}

+ (OLFacebookProfileImagePickerController *)defaultController {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultController = [OLFacebookProfileImagePickerController new];
    });
    
    return defaultController;
}
//-----------------------------------------------------------------


#pragma mark - Current Profile Image
//-----------------------------------------------------------------------------------------------------------------------------
- (void)getFirstXProfileImages:(NSInteger)numOfProfileImages completed:(OLFacebookCompletedGettingProfileImages)completed {
    
    self.completedGettingProfileImages = completed;
    
    [self checkFacebookPhotosPermission:^{
        [self.albumRequest getAlbums:^(NSArray *albums, NSError *error, OLFacebookAlbumRequest *nextPageRequest) {
            
            OLFacebookAlbum *profilePicturesAlbum = [self extractFacebookProfilePicturesAlbum:albums];
            self.photosForAlbumRequest = [[OLFacebookPhotosForAlbumRequest alloc] initWithAlbum:profilePicturesAlbum];
            
            if (!profilePicturesAlbum) {
                [self showGetFBProfilePicturesErrorAlert];
                if (completed) completed(nil);
                return;
            }
            
            [self.photosForAlbumRequest getPhotos:^(NSArray *photos, NSError *error, OLFacebookPhotosForAlbumRequest *nextPageRequest) {
                
                if (photos.count < 1) {
                    [self showGetFBProfilePicturesErrorAlert];
                    if (completed) completed(nil);
                    return;
                }
                
                photos = [photos subarrayWithRange:NSMakeRange(0, MIN(numOfProfileImages, photos.count))];
                
                [self downloadFacebookPhotos:photos completed:^(NSArray *images) {
                    if (completed) completed(images);
                }];
            }];
        }];
    }];
}

- (void)showGetFBProfilePicturesErrorAlert {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"There was a problem getting your profile pictures from Facebook, please try again."
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}

- (OLFacebookAlbum *)extractFacebookProfilePicturesAlbum:(NSArray *)albums {
    
    for (OLFacebookAlbum *album in albums) {
        if ([album.name isEqualToString:PROFILE_PICTURES_ALBUM_NAME] && [album.type isEqualToString:PROFILE_PICTURES_ALBUM_TYPE]) {
            return album;
        }
    }
    
    return nil;
}

- (void)downloadFacebookPhotos:(NSArray *)photos completed:(void(^)(NSArray *images))completed {
    
    NSMutableArray *images = [NSMutableArray new];
    __block NSInteger numOfImagesToDownload = photos.count;
    
    for (OLFacebookImage *facebookImage in photos) {
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:facebookImage.fullURL
                                                        options:0
                                                       progress:nil
                                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                          
                                                          if (image) {
                                                              [images addObject:image];
                                                              if (images.count == numOfImagesToDownload && completed) completed(images);
                                                          } else {
                                                              numOfImagesToDownload--;
                                                              if (images.count == numOfImagesToDownload && completed) completed(images);
                                                          }
                                                      }];
    }
}
//--------------------------------------------------------------------------------------------------


#pragma mark - Facebook Permission
//-----------------------------------------------------------------------------
- (void)checkFacebookPhotosPermission:(CompletedPermissionCheck)completed {
    
    BOOL havePhotosPermission = [[FBSDKAccessToken currentAccessToken] hasGranted:@"user_photos"];
    
    if (havePhotosPermission) {
        if (completed) completed();
        
    } else {
        self.completedFBPermissionCheck = completed;
        [self requestPhotosPermission];
    }
}

- (void)requestPhotosPermission {
    
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    
    [loginManager logInWithReadPermissions:@[@"user_photos"]
                        fromViewController:nil
                                   handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                       [self handlePermissionReqestResult:result error:error];
                                   }];
}

- (void)handlePermissionReqestResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    
    if (error) {
        [self showFBPermissionErrorAlert];
        if (self.completedGettingProfileImages) self.completedGettingProfileImages(nil);
        
    } else if (result.isCancelled) {
        if (self.completedGettingProfileImages) self.completedGettingProfileImages(nil);
        
    } else {
        if (self.completedFBPermissionCheck) self.completedFBPermissionCheck();
    }
}

- (void)showFBPermissionErrorAlert {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"There was a problem getting your photos permission from Facebook, please try again."
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}
//--------------------------------------


@end










