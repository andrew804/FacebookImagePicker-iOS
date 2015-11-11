//
//  FacebookImagePickerController.m
//  FacebookImagePicker
//
//  Created by Deon Botha on 16/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLFacebookImagePickerController.h"
#import "OLFacebookAlbum.h"
#import "OLAlbumViewController.h"
#import "OLPhotoViewController.h"
#import "RSKImageCropViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

typedef void (^ Completed)();

@interface OLFacebookImagePickerController () <OLPhotoViewControllerDelegate, OLAlbumViewControllerDelegate, RSKImageCropViewControllerDelegate>
@property (strong, nonatomic) OLPhotoViewController *photoVC;
@property (strong, nonatomic) OLAlbumViewController *albumVC;
@property (nonatomic, copy) Completed completedFBPermissionCheck;
@end

@implementation OLFacebookImagePickerController

#pragma mark - Life Cycle
//-----------------------
- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self setup];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [self checkFacebookPhotosPermission:^{
        [self resetTabBarControllers];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}
//--------------------------------------------


#pragma mark - Setup
//-----------------
- (void)setup {
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.tabBar.tintColor = [UIColor whiteColor];
    self.tabBarController.tabBar.barTintColor = [[UIColor alloc] initWithRed:0.22 green:0.45 blue:0.89 alpha:0.9];
    self.tabBarController.hidesBottomBarWhenPushed = YES;
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:[self photoNavController], [self albumNavController], nil];
    [self.view addSubview:self.tabBarController.view];
}

- (UINavigationController *)photoNavController {
    
    self.photoVC = [[OLPhotoViewController alloc] init];
    self.photoVC.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] init];
    [navController addChildViewController:self.photoVC];
    navController.viewControllers = [NSArray arrayWithObjects:self.photoVC, nil];
    
    return navController;
}

- (UINavigationController *)albumNavController {
    
    self.albumVC = [[OLAlbumViewController alloc] init];
    self.albumVC.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] init];
    [navController addChildViewController:self.albumVC];
    navController.viewControllers = [NSArray arrayWithObjects:self.albumVC, nil];
    
    return navController;
}

- (void)resetTabBarControllers {
    
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:[self photoNavController], [self albumNavController], nil];
}
//----------------------------------


#pragma mark - Facebook Permission
//--------------------------------------------------------------
- (void)checkFacebookPhotosPermission:(Completed)completed {
    
    BOOL havePhotosPermission = [[FBSDKAccessToken currentAccessToken] hasGranted:@"user_photos"];
    
    if (!havePhotosPermission) {
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
        [self.delegate facebookImagePickerDidCancelPickingImages:self];
        [self showFBPermissionErrorAlert];
        
    } else if (result.isCancelled) {
        [self.delegate facebookImagePickerDidCancelPickingImages:self];
        
    } else {
        self.completedFBPermissionCheck();
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


#pragma mark - OLPhotoViewController Delegate
//--------------------------------------------------------------------------------------------------------
- (void)photoViewController:(OLPhotoViewController *)photoController didSelectImage:(UIImage *)image {
    
    [self showImageCropperWithImage:image];
}

- (void)photoViewController:(OLPhotoViewController *)photoController didFailWithError:(NSError *)error {
    
    [self.delegate facebookImagePicker:self didFailWithError:error];
}

- (void)photoViewControllerDidCancelPickingImages:(OLPhotoViewController *)photoController {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
//----------------------------------------------------------------------------------------------


#pragma mark - OLAlbumViewController Delegate
//--------------------------------------------------------------------------------------------------------
- (void)albumViewController:(OLAlbumViewController *)albumController didSelectImage:(UIImage *)image {
    
    [self showImageCropperWithImage:image];
}

- (void)albumViewController:(OLAlbumViewController *)albumController didFailWithError:(NSError *)error {
    
    [self.delegate facebookImagePicker:self didFailWithError:error];
}

- (void)albumViewControllerDidCancelPickingImages:(OLAlbumViewController *)albumController {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
//----------------------------------------------------------------------------------------------


#pragma mark - Show Image Cropper
//------------------------------------------------------
- (void)showImageCropperWithImage:(UIImage *)image {
    
    RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:image cropMode:RSKImageCropModeSquare];
    imageCropVC.delegate = self;
    imageCropVC.avoidEmptySpaceAroundImage = YES;
        
    [self.navigationController pushViewController:imageCropVC animated:YES];
}
//------------------------------------------------------


#pragma mark - RSKImageCropView Delegate
//------------------------------------------------------------------------------------------------------------------------------------------------
- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage usingCropRect:(CGRect)cropRect {
    
    [self.photoVC closeDown];
    [self.albumVC closeDown];
    [self.delegate facebookImagePicker:self didSelectImage:croppedImage];
}

- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller {
    
    [self.navigationController popViewControllerAnimated:YES];
}
//-----------------------------------------------------------------------------------------


@end
