//
//  WXNIToolbarPhotoViewController.h
//  Pictures
//
//  Created by Charlie Wu on 20/12/2013.
//  Copyright (c) 2013 Charlie Wu. All rights reserved.
//

#import "NIToolbarPhotoViewController.h"

#define DefaultPhoto @"NimbusPhotos.bundle/gfx/default.png"

@protocol PhotoProtocol <NSObject>

- (NSString *)thumbnailUrlString;
- (NSString *)photoUrlString;

@end

@protocol CacheProtocol <NSObject>

- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id)key;

@end

@interface WXNIToolbarPhotoViewController : NIToolbarPhotoViewController <NIPhotoAlbumScrollViewDataSource>

@property (strong, nonatomic) NSArray *photos;
@property (nonatomic) NSUInteger photoIndex;
@property (strong, nonatomic) NSCache *photoCache;

- (void)setImageNotFoundPlaceHolder:(UIImage *)image;

- (BOOL)allowProgressBar;   // default YES;
- (BOOL)allowEdgeScroll;    // default YES;

@end
