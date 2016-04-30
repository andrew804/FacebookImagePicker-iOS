//
//  OLFacebookProfileImagePickerController.h
//  FacebookImagePicker
//
//  Created by Andrew Morris on 25/04/2016.
//  Copyright © 2016 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ OLFacebookCompletedGettingProfileImages)(NSArray *images);

@interface OLFacebookProfileImagePickerController : NSObject

+ (OLFacebookProfileImagePickerController *)defaultController;
- (void)getFirstXProfileImages:(NSInteger)numOfProfileImages completed:(OLFacebookCompletedGettingProfileImages)completed;
@end
