//
//  OLAlbumViewController.h
//  FacebookImagePicker
//
//  Created by Deon Botha on 16/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLAlbumViewController;

@protocol OLAlbumViewControllerDelegate <NSObject>
@optional
- (void)albumViewController:(OLAlbumViewController *)albumController didSelectImage:(UIImage *)image;
- (void)albumViewController:(OLAlbumViewController *)albumController didFailWithError:(NSError *)error;
- (void)albumViewControllerDidCancelPickingImages:(OLAlbumViewController *)albumController;
@end

@interface OLAlbumViewController : UIViewController
@property (nonatomic, weak) id<OLAlbumViewControllerDelegate> delegate;

- (void)closeDown;
@end
