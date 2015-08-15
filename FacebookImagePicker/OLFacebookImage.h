//
//  OLFacebookImage.h
//  FacebookImagePicker
//
//  Created by Deon Botha on 15/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLFacebookImageURL : NSObject <NSCoding, NSCopying>
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) CGSize imageSize;

- (id)initWithURL:(NSURL *)url size:(CGSize)size;
@end

/**
 The OLFacebookImage class provides a simple model object representation of an Facebook album photo.
 */
@interface OLFacebookImage : NSObject <NSCoding, NSCopying>
/**
 The URL to access the thumb resolution image
 */
@property (nonatomic, readonly) NSURL *thumbURL;

/**
 The URL to access the standard resolution image
 */
@property (nonatomic, readonly) NSURL *fullURL;

/**
 The Facebook album id to which this photo belongs
 */
@property (nonatomic, readonly) NSString *albumId;

@property (nonatomic, readonly) NSArray/*<OLFacebookImageURL>*/ *sourceImages;

/**
 Initialises a new OLFacebookImage object instance.
 
 @param thumbURL The URL to access the thumbnail image
 @param fullURL The URL to access the standard resolution image
 @param albumId The Facebook album id to which this photo belongs
 @return Returns an initialised OLFacebookImage instance
 */
- (id)initWithThumbURL:(NSURL *)thumbURL fullURL:(NSURL *)fullURL albumId:(NSString *)albumId sourceImages:(NSArray/*<OLFacebookImageURL>*/ *)sourceImages;

- (NSURL *)bestURLForSize:(CGSize)size;
@end




