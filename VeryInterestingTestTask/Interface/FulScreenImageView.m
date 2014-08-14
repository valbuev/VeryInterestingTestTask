//
//  FuulScreenImageView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 13.08.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "FullScreenImageView.h"

@interface FullScreenImageView () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation FullScreenImageView
@synthesize image;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initScrollView];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    // add gestureRecognizer for hidding/showing navigationBar
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self
                                             action:@selector(scrollViewTapped:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.scrollView addGestureRecognizer: tapRecognizer];
    
    // calculate scales
    //[self calculateScrollViewScales];
}

- (void)viewDidAppear:(BOOL)animated {
    // recalculate scales
    [self calculateScrollViewScales];
}

// initialization of scrollView and its content
- (void) initScrollView {
    
    // initialization of imageView
    self.imageView = [[UIImageView alloc] initWithImage: self.image];
    CGSize imageSize = self.image.size;
    
    //scale image
    self.imageView.frame = CGRectMake(0, 0, imageSize.width, imageSize.width);
    // add imageView on scrollView
    [self.scrollView addSubview:self.imageView];
    
    // change contentSize
    self.scrollView.contentSize = image.size;
}

// User tapped on scrollView
- (void) scrollViewTapped:(UITapGestureRecognizer *) recognizer {
    BOOL hidden = self.navigationController.navigationBar.hidden;
    // hide/show navigationBar
    [self.navigationController setNavigationBarHidden: !hidden animated: YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// ScrollView Will zoom image
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

// Recalculate scales
- (void) calculateScrollViewScales {
    
    // calculating and setting min scale
    CGFloat scaleWidth = self.scrollView.bounds.size.width / self.image.size.width;
    CGFloat scaleHeight = self.scrollView.bounds.size.height / self.image.size.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    self.scrollView.minimumZoomScale = minScale;
    
    NSLog(@"scale %f %f %f %f %f %f",scaleWidth, self.scrollView.bounds.size.width, self.image.size.width, scaleHeight, self.scrollView.bounds.size.height, self.image.size.height);
    
    // setting maximum scale and current scale
    self.scrollView.maximumZoomScale = 1.0f;
    self.scrollView.zoomScale = minScale;
    
    // center content
    [self centerScrollViewContents];
}

// Centers scrollView's content on screen when imageSize < screenSize
- (void) centerScrollViewContents {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    // if contentsWidth < scrollViewWidth, then center by x
    if ( contentsFrame.size.width < boundsSize.width ) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    }
    else {
        contentsFrame.origin.x = 0.0f;
    }
    
    // if contentsHeight < scrollViewHeight, then center by y
    if ( contentsFrame.size.height < boundsSize.height ) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    }
    else {
        contentsFrame.origin.y = 0.0f;
    }
    
    // set new frame for content
    self.imageView.frame = contentsFrame;
}

// center content
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerScrollViewContents];
}

// The device did rotated
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    // recalculate scales
    [self calculateScrollViewScales];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
