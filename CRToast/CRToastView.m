//
//  CRToast
//  Copyright (c) 2014-2015 Collin Ruffenach. All rights reserved.
//

#import "CRToastView.h"
#import "CRToast.h"
#import "CRToastLayoutHelpers.h"

@interface CRToastView ()
@end

static CGFloat const kCRStatusBarViewNoImageLeftContentInset = 10;
static CGFloat const kCRStatusBarViewNoImageRightContentInset = 10;

// UIApplication's statusBarFrame will return a height for the status bar that includes
// a 5 pixel vertical padding. This frame height is inappropriate to use when centering content
// vertically under the status bar. This adjustment is used to correct the frame height when centering
// content under the status bar.

static CGFloat const CRStatusBarViewUnderStatusBarYOffsetAdjustment = -5;

static CGFloat CRImageViewFrameXOffsetForAlignment(CRToastAccessoryViewAlignment alignment, CGSize contentSize) {
    CGFloat imageSize = contentSize.height;
    CGFloat xOffset = 0;

    if (alignment == CRToastAccessoryViewAlignmentLeft) {
        xOffset = 0;
    } else if (alignment == CRToastAccessoryViewAlignmentCenter) {
        // Calculate mid point of contentSize, then offset for x for full image width
        // that way center of image will be center of content view
        xOffset = (contentSize.width / 2) - (imageSize / 2);
    } else if (alignment == CRToastAccessoryViewAlignmentRight) {
        xOffset = contentSize.width - imageSize;
    }
    
    return xOffset;
}

static CGFloat CRContentXOffsetForViewAlignmentAndWidth(CRToastAccessoryViewAlignment alignment, CGFloat width) {
    return (width == 0 || alignment != CRToastAccessoryViewAlignmentLeft) ?
    kCRStatusBarViewNoImageLeftContentInset :
    width;
}

static CGFloat CRToastWidthOfViewWithAlignment(CGFloat height, BOOL showing, CRToastAccessoryViewAlignment alignment) {
    return (!showing || alignment == CRToastAccessoryViewAlignmentCenter) ?
    0 :
    height;
}

CGFloat CRContentWidthForAccessoryViewsWithAlignments(CGFloat fullContentWidth, CGFloat fullContentHeight, BOOL showingImage, CRToastAccessoryViewAlignment imageAlignment, BOOL showingActivityIndicator, CRToastAccessoryViewAlignment activityIndicatorAlignment) {
    CGFloat width = fullContentWidth;
    
    width -= CRToastWidthOfViewWithAlignment(fullContentHeight, showingImage, imageAlignment);
    width -= CRToastWidthOfViewWithAlignment(fullContentHeight, showingActivityIndicator, activityIndicatorAlignment);
    
    if (imageAlignment == activityIndicatorAlignment && showingActivityIndicator && showingImage) {
        width += fullContentWidth;
    }
    
    if (!showingImage && !showingActivityIndicator) {
        width -= (kCRStatusBarViewNoImageLeftContentInset + kCRStatusBarViewNoImageRightContentInset);
    }
    
    return width;
}

static CGFloat CRCenterXForActivityIndicatorWithAlignment(CRToastAccessoryViewAlignment alignment, CGFloat viewWidth, CGFloat contentWidth) {
    CGFloat center = 0;
    CGFloat offset = viewWidth / 2;
    
    switch (alignment) {
        case CRToastAccessoryViewAlignmentLeft:
            center = offset; break;
        case CRToastAccessoryViewAlignmentCenter:
            center = (contentWidth / 2); break;
        case CRToastAccessoryViewAlignmentRight:
            center = contentWidth - offset; break;
    }
    
    return center;
}

@implementation CRToastView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.accessibilityLabel = NSStringFromClass([self class]);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.userInteractionEnabled = NO;
        imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:imageView];
        self.leftImageView = imageView;
        
        UIImageView *rightImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        rightImageView.userInteractionEnabled = NO;
        rightImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:rightImageView];
        self.rightImageView = rightImageView;
        
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicator.userInteractionEnabled = NO;
        [self addSubview:activityIndicator];
        self.activityIndicator = activityIndicator;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.userInteractionEnabled = NO;
        [self addSubview:label];
        self.label = label;
        
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subtitleLabel.userInteractionEnabled = NO;
        [self addSubview:subtitleLabel];
        self.subtitleLabel = subtitleLabel;
        
        self.isAccessibilityElement = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect contentFrame = self.bounds;
    CGSize imageSize = self.leftImageView.image.size;
    
    CGFloat statusBarYOffset = self.toast.displayUnderStatusBar ? (CRGetStatusBarHeight()+CRStatusBarViewUnderStatusBarYOffsetAdjustment) : 0;
    contentFrame.size.height = CGRectGetHeight(contentFrame) - statusBarYOffset;
    
    self.backgroundView.frame = self.bounds;
    
    CGSize toastLeftImageSize = self.toast.leftImageSize;
    
//    CGFloat imageXOffset = CRImageViewFrameXOffsetForAlignment(self.toast.imageAlignment, contentFrame.size);
    
    CGSize imageViewSize = CGSizeMake(imageSize.width == 0 ?
                                      0 :
                                      toastLeftImageSize.width == 0 ?
                                      CGRectGetHeight(contentFrame)
                                      : toastLeftImageSize.width, imageSize.height == 0 ?
                                      0 :
                                      toastLeftImageSize.height == 0
                                      ? CGRectGetHeight(contentFrame)
                                      : toastLeftImageSize.height);
    
    UIEdgeInsets imageViewInset = self.toast.leftImageInsets;
    
    CGPoint imageViewPosition = CGPointMake(imageViewInset.left,
                                            contentFrame.size.height / 2 - imageViewSize.height / 2 + imageViewInset.top - imageViewInset.bottom);
    
    self.leftImageView.frame = CGRectMake(imageViewPosition.x,
                                      imageViewPosition.y,
                                      imageViewSize.width,
                                      imageViewSize.height);
    
    CGFloat leftImageCornerRadius = self.toast.leftImageCornerRadius;
    
    self.leftImageView.layer.cornerRadius = leftImageCornerRadius;
    self.leftImageView.clipsToBounds = leftImageCornerRadius != 0;
    
    
    //right
    CGSize toastRightImageSize = self.toast.rightImageSize;
    CGSize rightImageSize = self.rightImageView.image.size;
    
    CGSize rightImageViewSize = CGSizeMake(rightImageSize.width == 0 ?
                                           0 :
                                           toastRightImageSize.width == 0 ?
                                           CGRectGetHeight(contentFrame)
                                           : toastRightImageSize.width, rightImageSize.height == 0 ?
                                           0 :
                                           toastRightImageSize.height == 0
                                           ? CGRectGetHeight(contentFrame)
                                           : toastRightImageSize.height);
    
    UIEdgeInsets rightImageInset = self.toast.rightImageInsets;
    
    CGPoint rightImageViewPosition = CGPointMake(CGRectGetWidth(contentFrame) - rightImageViewSize.width - rightImageInset.right,
                                                 contentFrame.size.height / 2 - rightImageViewSize.height / 2 + rightImageInset.top - rightImageInset.bottom);
    
    self.rightImageView.frame = CGRectMake(rightImageViewPosition.x,
                                           rightImageViewPosition.y,
                                           rightImageViewSize.width,
                                           rightImageViewSize.height);
    
    CGFloat rightImageCornerRadius = self.toast.rightImageCornerRadius;
    
    self.rightImageView.layer.cornerRadius = rightImageCornerRadius;
    self.rightImageView.clipsToBounds = rightImageCornerRadius != 0;
    
    CGFloat rightImageViewOffsetValue = (rightImageViewSize.width + rightImageInset.left + rightImageInset.right);
    
    CGFloat imageWidth = imageSize.width == 0 ? 0 : CGRectGetMaxX(_leftImageView.frame);
    CGFloat x = imageWidth + imageViewInset.right;
    
    
    if (self.toast.showActivityIndicator) {
        CGFloat centerX = CRCenterXForActivityIndicatorWithAlignment(self.toast.activityViewAlignment, CGRectGetHeight(contentFrame), CGRectGetWidth(contentFrame));
        self.activityIndicator.center = CGPointMake(centerX,
                                     CGRectGetMidY(contentFrame) + statusBarYOffset);
        
        [self.activityIndicator startAnimating];
        x = MAX(CRContentXOffsetForViewAlignmentAndWidth(self.toast.activityViewAlignment, CGRectGetHeight(contentFrame)), x);

        [self bringSubviewToFront:self.activityIndicator];
    }
    
    BOOL showingImage = imageSize.width > 0;
    
    CGFloat width = CRContentWidthForAccessoryViewsWithAlignments(CGRectGetWidth(contentFrame),
                                                                  CGRectGetHeight(contentFrame),
                                                                  showingImage,
                                                                  self.toast.imageAlignment,
                                                                  self.toast.showActivityIndicator,
                                                                  self.toast.activityViewAlignment);
    
    width -= rightImageViewOffsetValue;
    
    if (self.toast.subtitleText == nil) {
        self.label.frame = CGRectMake(x,
                                      statusBarYOffset,
                                      width,
                                      CGRectGetHeight(contentFrame));
    } else {
        CGFloat height = MIN([self.toast.text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:@{NSFontAttributeName : self.toast.font}
                                                           context:nil].size.height,
                             CGRectGetHeight(contentFrame));
        CGFloat subtitleHeight = [self.toast.subtitleText boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                                    attributes:@{NSFontAttributeName : self.toast.subtitleFont }
                                                                       context:nil].size.height;
        if ((CGRectGetHeight(contentFrame) - (height + subtitleHeight)) < 5) {
            subtitleHeight = (CGRectGetHeight(contentFrame) - (height))-10;
        }
        CGFloat offset = (CGRectGetHeight(contentFrame) - (height + subtitleHeight))/2;
        
        self.label.frame = CGRectMake(x,
                                      offset+statusBarYOffset,
                                      CGRectGetWidth(contentFrame)-x-rightImageViewOffsetValue,
                                      height);
        
        
        self.subtitleLabel.frame = CGRectMake(x,
                                              height+offset+statusBarYOffset,
                                              CGRectGetWidth(contentFrame)-x-rightImageViewOffsetValue,
                                              subtitleHeight);
    }
}

#pragma mark - Overrides

- (void)setToast:(CRToast *)toast {
    _toast = toast;
    _label.text = toast.text;
    _label.font = toast.font;
    _label.textColor = toast.textColor;
    _label.textAlignment = toast.textAlignment;
    _label.numberOfLines = toast.textMaxNumberOfLines;
    _label.shadowOffset = toast.textShadowOffset;
    _label.shadowColor = toast.textShadowColor;

    if (toast.attributedText != nil) {
        _label.attributedText = toast.attributedText;
    }
    
    if (toast.subtitleText != nil) {
        _subtitleLabel.text = toast.subtitleText;
        _subtitleLabel.font = toast.subtitleFont;
        _subtitleLabel.textColor = toast.subtitleTextColor;
        _subtitleLabel.textAlignment = toast.subtitleTextAlignment;
        _subtitleLabel.numberOfLines = toast.subtitleTextMaxNumberOfLines;
        _subtitleLabel.shadowOffset = toast.subtitleTextShadowOffset;
        _subtitleLabel.shadowColor = toast.subtitleTextShadowColor;
    }
    
    if (toast.attributedSubtitleText != nil) {
        _subtitleLabel.attributedText = toast.attributedSubtitleText;
    }
    
    _leftImageView.image = toast.image;
    _leftImageView.contentMode = toast.imageContentMode;
    
    _rightImageView.image = toast.rightImage;
    _rightImageView.contentMode = toast.rightImageContentMode;
    
    
    _activityIndicator.activityIndicatorViewStyle = toast.activityIndicatorViewStyle;
    
    self.backgroundColor = toast.backgroundColor;
    
    if (toast.backgroundView) {
        _backgroundView = toast.backgroundView;
        if (!_backgroundView.superview) {
            [self insertSubview:_backgroundView atIndex:0];
        }
    }
}

@end
