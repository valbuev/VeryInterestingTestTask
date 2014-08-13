//
//  FuulScreenImageView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 13.08.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "FullScreenImageView.h"

@interface FullScreenImageView ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation FullScreenImageView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"no_photo.jpg"]];
    CGRect frame = self.scrollView.frame;
    [imageView setFrame:frame];
    [self.scrollView addSubview:imageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
