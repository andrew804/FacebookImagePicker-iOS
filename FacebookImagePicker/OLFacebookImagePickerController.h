//
//  FacebookImagePickerController.h
//  FacebookImagePicker
//
//  Created by Deon Botha on 16/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLFacebookImagePickerController;
@protocol OLFacebookImagePickerControllerDelegate <NSObject>
@optional
- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didSelectImage:(UIImage *)image;
- (void)facebookImagePicker:(OLFacebookImagePickerController *)imagePicker didFailWithError:(NSError *)error;
- (void)facebookImagePickerDidCancelPickingImages:(OLFacebookImagePickerController *)imagePicker;
@end

/**
 The OLFacebookImagePickerController class provides a simple UI for a user to pick photos from their Facebook account. It
 provides an image picker interface that matches the iOS SDK's UIImagePickerController. It takes care of all
 authentication with Facebook as and when necessary. It will automatically renew auth tokens or prompt
 the user to re-authorize the app if needed. You need to have set up your application correctly to work with Facebook as per
 https://developers.facebook.com/docs/ios/getting-started
 */
@interface OLFacebookImagePickerController : UIViewController
/**
 The image picker’s delegate object.
 */
@property (nonatomic, weak) id <OLFacebookImagePickerControllerDelegate> delegate;
@property (strong, nonatomic) UITabBarController *tabBarController;
@end
