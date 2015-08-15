//
//  OLPhotoViewController.h
//  FacebookImagePicker
//
//  Created by Deon Botha on 16/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLPhotoViewController;
@class OLFacebookAlbum;

@protocol OLPhotoViewControllerDelegate <NSObject>
@optional
- (void)photoViewController:(OLPhotoViewController *)photoController didSelectImage:(UIImage *)image;
- (void)photoViewController:(OLPhotoViewController *)photoController didFailWithError:(NSError *)error;
- (void)photoViewControllerDidCancelPickingImages:(OLPhotoViewController *)photoController;
@end

@interface OLPhotoViewController : UIViewController
@property (nonatomic, weak) id<OLPhotoViewControllerDelegate> delegate;

- (id)initWithAlbum:(OLFacebookAlbum *)album;
- (void)closeDown;
@end
