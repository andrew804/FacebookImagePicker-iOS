//
//  OLPhotoViewController.m
//  FacebookImagePicker
//
//  Created by Deon Botha on 16/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLPhotoViewController.h"
#import "OLFacebookAlbum.h"
#import "OLFacebookImagePickerCell.h"
#import "OLFacebookPhotosForAlbumRequest.h"
#import "OLFacebookPhotosOfUserRequest.h"
#import "OLFacebookImage.h"
#import "OLFacebookImagePickerController.h"
#import "OLAlbumViewController.h"
#import "UIImageView+FacebookFadeIn.h"
#import <tgmath.h>

static NSString *const kImagePickerCellReuseIdentifier = @"co.oceanlabs.facebookimagepicker.kImagePickerCellReuseIdentifier";
static NSString *const kSupplementaryViewFooterReuseIdentifier = @"co.oceanlabs.ps.kSupplementaryViewHeaderReuseIdentifier";

@interface SupplementaryView : UICollectionReusableView
@end

@interface OLPhotoViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) OLFacebookAlbum *album;
@property (nonatomic, strong) OLFacebookPhotosForAlbumRequest *inProgressPhotosForAlbumRequest, *nextPagePhotosForAlbumRequest;
@property (nonatomic, strong) OLFacebookPhotosOfUserRequest *inProgressPhotosOfUserRequest, *nextPagePhotosOfUserRequest;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSArray *overflowPhotos; // We can only insert multiples of 4 images each request, overflow must be saved and inserted on a subsequent request.
@end

@implementation OLPhotoViewController

#pragma mark - Life Cycle
//------------------------------------------------
- (id)initWithAlbum:(OLFacebookAlbum *)album {
    
    if (self = [super init]) {
        self.album = album;
        self.title = album.name;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self setup];
}

- (void)closeDown {
    
    [self.nextPagePhotosForAlbumRequest cancel];
    [self.inProgressPhotosForAlbumRequest cancel];
    
    [self.nextPagePhotosOfUserRequest cancel];
    [self.inProgressPhotosOfUserRequest cancel];
}
//---------------------


#pragma mark - Setup
//-----------------
- (void)setup {
    
    [self setupCollectionView];
    
    self.photos = [[NSMutableArray alloc] init];
    self.overflowPhotos = [[NSArray alloc] init];
    
    if ([[self.navigationController.viewControllers firstObject] isEqual:self]) {
        [self setupRootViewElements];
    }
    
    if (self.album) {
        self.nextPagePhotosForAlbumRequest = [[OLFacebookPhotosForAlbumRequest alloc] initWithAlbum:self.album];
    } else {
        self.nextPagePhotosOfUserRequest = [[OLFacebookPhotosOfUserRequest alloc] init];
    }
    
    [self loadNextPage];
}

- (void)setupCollectionView {
    
    CGFloat itemSize = MIN([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width)/4.0 - 1.0;
    
    UICollectionViewFlowLayout *layout  = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize                     = CGSizeMake(itemSize, itemSize);
    layout.sectionInset                 = UIEdgeInsetsMake(9.0, 0, 0, 0);
    layout.minimumInteritemSpacing      = 1.0;
    layout.minimumLineSpacing           = 1.0;
    layout.footerReferenceSize          = CGSizeMake(0, 0);
    
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.alwaysBounceVertical = YES;
    
    [self.collectionView registerClass:[OLFacebookImagePickerCell class] forCellWithReuseIdentifier:kImagePickerCellReuseIdentifier];
    [self.collectionView registerClass:[SupplementaryView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kSupplementaryViewFooterReuseIdentifier];
}

- (void)setupRootViewElements {
    
    self.title = @"Photos of Me";
    self.tabBarItem.image = [UIImage imageNamed:@"profile_dark"];
    [self.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]} forState:UIControlStateNormal];
    [self.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]} forState:UIControlStateSelected];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [[UIColor alloc] initWithRed:0.22 green:0.45 blue:0.89 alpha:0.9];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancel)];
}
//---------------------------------


#pragma mark - Buttons
//------------------
- (void)cancel {
    
    [self closeDown];
    [self.delegate photoViewControllerDidCancelPickingImages:self];
}
//------------------


#pragma mark - Load Next Page
//------------------------
- (void)loadNextPage {
    
    if (self.album) {
        [self loadNextPageOfPhotosForAlbum];
    } else {
        [self loadNextPageOfPhotosOfUser];
    }
}

- (void)loadNextPageOfPhotosForAlbum {
    
    self.inProgressPhotosForAlbumRequest = self.nextPagePhotosForAlbumRequest;
    self.nextPagePhotosForAlbumRequest = nil;
    
    [self.inProgressPhotosForAlbumRequest getPhotos:^(NSArray *photos, NSError *error, OLFacebookPhotosForAlbumRequest *nextPageRequest) {
        self.inProgressPhotosForAlbumRequest = nil;
        self.nextPagePhotosForAlbumRequest = nextPageRequest;
        self.loadingIndicator.hidden = YES;
        
        if (error) {
            [self.delegate photoViewController:self didFailWithError:error];
            return;
        }
        
        NSAssert(self.overflowPhotos.count < 4, @"oops");
        NSUInteger photosStartCount = self.photos.count;
        [self.photos addObjectsFromArray:self.overflowPhotos];
        if (nextPageRequest != nil) {
            // only insert multiple of 4 images so we fill complete rows
            NSInteger overflowCount = (self.photos.count + photos.count) % 4;
            [self.photos addObjectsFromArray:[photos subarrayWithRange:NSMakeRange(0, photos.count - overflowCount)]];
            self.overflowPhotos = [photos subarrayWithRange:NSMakeRange(photos.count - overflowCount, overflowCount)];
        } else {
            // we've exhausted all the users images so show the remainder
            [self.photos addObjectsFromArray:photos];
            self.overflowPhotos = @[];
        }
        
        // Insert new items
        NSMutableArray *addedItemPaths = [[NSMutableArray alloc] init];
        for (NSUInteger itemIndex = photosStartCount; itemIndex < self.photos.count; ++itemIndex) {
            [addedItemPaths addObject:[NSIndexPath indexPathForItem:itemIndex inSection:0]];
        }
        
        [self.collectionView insertItemsAtIndexPaths:addedItemPaths];
        ((UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout).footerReferenceSize = CGSizeMake(0, nextPageRequest == nil ? 0 : 44);
    }];
}

- (void)loadNextPageOfPhotosOfUser {
    
    self.inProgressPhotosOfUserRequest = self.nextPagePhotosOfUserRequest;
    self.nextPagePhotosOfUserRequest = nil;
    
    [self.inProgressPhotosOfUserRequest getPhotos:^(NSArray *photos, NSError *error, OLFacebookPhotosOfUserRequest *nextPageRequest) {
        self.inProgressPhotosOfUserRequest = nil;
        self.nextPagePhotosOfUserRequest = nextPageRequest;
        self.loadingIndicator.hidden = YES;
        
        if (error) {
            [self.delegate photoViewController:self didFailWithError:error];
            return;
        }
        
        NSAssert(self.overflowPhotos.count < 4, @"oops");
        NSUInteger photosStartCount = self.photos.count;
        [self.photos addObjectsFromArray:self.overflowPhotos];
        if (nextPageRequest != nil) {
            // only insert multiple of 4 images so we fill complete rows
            NSInteger overflowCount = (self.photos.count + photos.count) % 4;
            [self.photos addObjectsFromArray:[photos subarrayWithRange:NSMakeRange(0, photos.count - overflowCount)]];
            self.overflowPhotos = [photos subarrayWithRange:NSMakeRange(photos.count - overflowCount, overflowCount)];
        } else {
            // we've exhausted all the users images so show the remainder
            [self.photos addObjectsFromArray:photos];
            self.overflowPhotos = @[];
        }
        
        // Insert new items
        NSMutableArray *addedItemPaths = [[NSMutableArray alloc] init];
        for (NSUInteger itemIndex = photosStartCount; itemIndex < self.photos.count; ++itemIndex) {
            [addedItemPaths addObject:[NSIndexPath indexPathForItem:itemIndex inSection:0]];
        }
        
        [self.collectionView insertItemsAtIndexPaths:addedItemPaths];
        ((UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout).footerReferenceSize = CGSizeMake(0, nextPageRequest == nil ? 0 : 44);
    }];
}
//--------------------------------------


#pragma mark - UICollectionView DataSource
//------------------------------------------------------------------------------------------------------------
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    OLFacebookImagePickerCell *cell = (OLFacebookImagePickerCell *) [collectionView dequeueReusableCellWithReuseIdentifier:kImagePickerCellReuseIdentifier forIndexPath:indexPath];
    OLFacebookImage *image = [self.photos objectAtIndex:indexPath.item];
    [cell bind:image];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    
    SupplementaryView *v = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kSupplementaryViewFooterReuseIdentifier forIndexPath:indexPath];
    return v;
}
//-------------------------------------------------------------------------


#pragma mark - UICollectionView Delegate
//----------------------------------------------------------
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView.contentOffset.y >= self.collectionView.contentSize.height - self.collectionView.frame.size.height) {
        // we've reached the bottom, lets load the next page of facebook images (as long as there is no in-progress request)
        if (self.album && self.inProgressPhotosForAlbumRequest == nil) {
            [self loadNextPage];
        } else if (!self.album && self.inProgressPhotosOfUserRequest == nil) {
            [self loadNextPage];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    OLFacebookImage *OLFacebookImage = [self.photos objectAtIndex:indexPath.item];
    NSData *data = [NSData dataWithContentsOfURL:OLFacebookImage.fullURL];
    UIImage *image = [[UIImage alloc] initWithData:data];
    
    [self.delegate photoViewController:self didSelectImage:image];
}
//---------------------------------------------------------------------------------------------------------------


@end


@implementation SupplementaryView

- (id)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        ai.frame = CGRectMake((frame.size.width - ai.frame.size.width) / 2, (frame.size.height - ai.frame.size.height) / 2, ai.frame.size.width, ai.frame.size.height);
        ai.color = [UIColor grayColor];
        [ai startAnimating];
        [self addSubview:ai];
    }
    
    return self;
}

@end


