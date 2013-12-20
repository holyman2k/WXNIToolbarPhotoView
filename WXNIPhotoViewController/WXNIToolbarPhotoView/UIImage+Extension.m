//
//  UIImage+Extension.m
//  Pictures
//
//  Created by Charlie Wu on 3/12/2013.
//  Copyright (c) 2013 Charlie Wu. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (WXExtension)

- (UIImage *)scaleImageTofitSize:(CGSize)size
{
    float screenScale = [[UIScreen mainScreen] scale];
    size = CGSizeMake(size.width * screenScale, size.height * screenScale);
    float scale = size.width / self.size.width;
    
    if (self.size.height * scale > size.height || self.size.width * scale > size.width) scale = size.height / self.size.height;
    
    UIImage *scaledImage = [UIImage imageWithCGImage:[self CGImage] scale: 1 / scale orientation:self.imageOrientation];
    return scaledImage;
}

@end
