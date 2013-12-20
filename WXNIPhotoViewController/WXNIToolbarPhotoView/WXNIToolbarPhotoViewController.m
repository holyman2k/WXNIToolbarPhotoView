//
//  WXNIToolbarPhotoViewController.m
//  Pictures
//
//  Created by Charlie Wu on 20/12/2013.
//  Copyright (c) 2013 Charlie Wu. All rights reserved.
//

#import "WXNIToolbarPhotoViewController.h"
#import "UIImage+Extension.h"

@interface WXNIToolbarPhotoViewController ()
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSMutableSet *activeRequest;
@property (strong, nonatomic) UIImage *imageNotFoundPlaceHolder;
@property (strong, nonatomic) DACircularProgressView *progressView;
@property (strong, nonatomic) UIView *leftTouchArea;
@property (strong, nonatomic) UIView *rightTouchArea;
@end

@implementation WXNIToolbarPhotoViewController

- (void)viewDidLoad
{
    [self.toolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *button, NSUInteger idx, BOOL *stop) {
        button.tintColor = [UIColor whiteColor];
    }];
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.activeRequest = [[NSMutableSet alloc] init];
    self.photoCache = [[NSCache alloc] init];
    
    [self setAutomaticallyAdjustsScrollViewInsets: NO];
    self.photoAlbumView.dataSource = self;
    self.photoAlbumView.loadingImage = [UIImage imageWithContentsOfFile:NIPathForBundleResource(nil, DefaultPhoto)];
    
    if (self.allowProgressBar) {
        self.progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        self.progressView.roundedCorners = YES;
        self.progressView.center = self.view.center;
        self.progressView.trackTintColor = [UIColor clearColor];
        [self.photoAlbumView.pagingScrollView addSubview:self.progressView];
        self.progressView.hidden = YES;
    }
    
    if (self.allowEdgeScroll) {
        self.leftTouchArea = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, self.view.frame.size.height)];
        self.rightTouchArea = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20, 0, 20, self.view.frame.size.height)];
        
        UITapGestureRecognizer *rightTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightTapHandler:)];
        rightTapGesture.numberOfTapsRequired = 1;
        rightTapGesture.numberOfTouchesRequired = 1;
        [self.rightTouchArea addGestureRecognizer:rightTapGesture];
        
        UITapGestureRecognizer *leftTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leftTapHandler:)];
        leftTapGesture.numberOfTapsRequired = 1;
        leftTapGesture.numberOfTouchesRequired = 1;
        [self.leftTouchArea addGestureRecognizer:leftTapGesture];
        
        [self.view addSubview:self.rightTouchArea];
        [self.view addSubview:self.leftTouchArea];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.isMovingToParentViewController) {
        self.toolbarIsTranslucent = YES;
        self.hidesChromeWhenScrolling = YES;
        self.chromeCanBeHidden = YES;
        self.toolbar.translucent = YES;
        self.hidesChromeWhenScrolling = YES;
        self.photoAlbumView.frame = self.view.frame; // fix bug with toolbar not transparent
        
        [self.photoAlbumView reloadData];
        self.photoAlbumView.centerPageIndex = self.photoIndex;
        [self refreshChromeState];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.isMovingFromParentViewController) {
        self.toolbar.translucent = NO;
        self.toolbarIsTranslucent = NO;
    }
    [super viewWillDisappear:animated];
}


- (void)requestPhoto:(id<PhotoProtocol>)photo atIndex:(NSInteger)photoIndex
{
    if ([self.activeRequest containsObject:photo]) {
        return;
    }
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:photo.photoUrlString]];
    request.timeoutInterval = 30;
    [self.activeRequest addObject:photo];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        UIImage *image = [[UIImage imageWithData:operation.responseData] scaleImageTofitSize:self.view.frame.size];
        
        [self.photoCache setObject:image forKey:photo.photoUrlString];
        [self.activeRequest removeObject:photo];
        
        [self.photoAlbumView didLoadPhoto: image
                                  atIndex: photoIndex
                                photoSize: NIPhotoScrollViewPhotoSizeOriginal];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.activeRequest removeObject:photo];
        UIImage *image = self.imageNotFoundPlaceHolder;
        [self.photoCache setObject:image forKey:photo.photoUrlString];
        [self.photoAlbumView didLoadPhoto: image
                                  atIndex: photoIndex
                                photoSize: NIPhotoScrollViewPhotoSizeOriginal];
    }];
    
    if (self.allowProgressBar) {
        [operation setDownloadProgressBlock:
         ^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
             if (self.photoAlbumView.centerPageIndex == photoIndex) {
                 double percent = (double)totalBytesRead / (double)totalBytesExpectedToRead;
                 if (totalBytesRead == totalBytesExpectedToRead) {
                     self.progressView.hidden = YES;
                 } else {
                     if (self.progressView.hidden) self.progressView.hidden = NO;
                     self.progressView.progress = percent;
                 }
             }
         }];
    }
    [self.operationQueue addOperation:operation];
}

- (UIImage*)photoAlbumScrollView:(NIPhotoAlbumScrollView *)photoAlbumScrollView
                    photoAtIndex:(NSInteger)photoIndex
                       photoSize:(NIPhotoScrollViewPhotoSize *)photoSize
                       isLoading:(BOOL *)isLoading
         originalPhotoDimensions:(CGSize *)originalPhotoDimensions
{
    id<PhotoProtocol> photo = self.photos[photoIndex];
    UIImage *image = [self.photoCache objectForKey:photo.photoUrlString];
    
    if (!image){
        [self requestPhoto:photo atIndex:photoIndex];
        return nil;
    } else {
        *originalPhotoDimensions = [image size];
        *photoSize = NIPhotoScrollViewPhotoSizeOriginal;
        
        return image;
    }
}

- (UIView<NIPagingScrollViewPage>*)pagingScrollView:(NIPagingScrollView *)pagingScrollView pageViewForIndex:(NSInteger)pageIndex
{
    return [self.photoAlbumView pagingScrollView:pagingScrollView pageViewForIndex:pageIndex];
}

- (NSInteger)numberOfPagesInPagingScrollView:(NIPagingScrollView *)pagingScrollView
{
    return self.photos.count;
}

- (void)pagingScrollViewDidChangePages:(NIPagingScrollView *)pagingScrollView
{
    self.photoIndex = self.photoAlbumView.centerPageIndex;
    if (self.allowProgressBar) {
        float x = self.photoAlbumView.pagingScrollView.contentOffset.x + self.view.frame.size.width / 2 - self.progressView.frame.size.width / 2;
        float y = self.view.frame.size.height / 2 - self.progressView.frame.size.height / 2;
        self.progressView.frame = CGRectMake(x, y, self.progressView.frame.size.width, self.progressView.frame.size.width);
    }
    self.title = [NSString stringWithFormat:@"%d of %lu", self.photoAlbumView.centerPageIndex + 1, (unsigned long)self.photos.count];
}

- (void)setImageNotFoundPlaceHolder:(UIImage *)image
{
    self.imageNotFoundPlaceHolder = image;
}

- (BOOL)allowProgressBar
{
    return YES;
}

- (BOOL)allowEdgeScroll
{
    return YES;
}

- (void)rightTapHandler:(UITapGestureRecognizer *)gesture
{
    [self setChromeVisibility:NO animated:YES];
    [self.photoAlbumView moveToNextAnimated:YES];
}

- (void)leftTapHandler:(UITapGestureRecognizer *)gesture
{
    [self setChromeVisibility:NO animated:YES];
    [self.photoAlbumView moveToPreviousAnimated:YES];
}

@end

