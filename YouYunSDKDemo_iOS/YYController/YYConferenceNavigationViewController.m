//
//  YYConferenceNavigationViewController.m
//  YouYunSDKDemo
//
//  Created by Frederic on 15/11/24.
//  Copyright © 2015年 stylejar. All rights reserved.
//

#import "YYConferenceNavigationViewController.h"
#import "YYConferenceViewController.h"

@interface YYConferenceNavigationViewController ()

@end

@implementation YYConferenceNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    YYConferenceViewController *confView = (YYConferenceViewController*)[self.viewControllers firstObject];
    confView.conUserInfo = self.conUserInfo;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
