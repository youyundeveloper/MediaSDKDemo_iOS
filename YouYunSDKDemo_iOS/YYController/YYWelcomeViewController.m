//
//  YYWelcomeViewController.m
//  YouYunSDKDemo
//
//  Created by Frederic on 15/11/16.
//  Copyright © 2015年 stylejar. All rights reserved.
//

#import "YYWelcomeViewController.h"

#import "CoreEngine.h"

@interface YYWelcomeViewController ()
{
    BOOL isAuthing;
}

// 一键登录
@property (weak, nonatomic) IBOutlet UIButton *signInOrSignUpButton;
// 加载等待
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation YYWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    isAuthing = NO;
    [_activityIndicator stopAnimating];
    [_signInOrSignUpButton.layer setCornerRadius:_signInOrSignUpButton.frame.size.height / 2.0];
    [_signInOrSignUpButton.layer setBorderWidth:1.0 / [UIScreen mainScreen].scale];
    [_signInOrSignUpButton.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [_signInOrSignUpButton.layer setMasksToBounds:YES];
    //是否获取到uid
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(uidReceived) name:getUIDnotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(uidReceiveFailed) name:getUIDnotificationFailed object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:getUIDnotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:getUIDnotificationFailed object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// 登录注册
- (IBAction)signInButtonAction:(id)sender {
    if (!isAuthing) {
        if (!_activityIndicator.isAnimating) {
            [_activityIndicator startAnimating];
        }
        [[CoreEngine sharedInstance] registerOrLoginAction];
    }
}

// 成功获取用户ID
- (void)uidReceived {
    [self performSelector:@selector(received) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}
- (void)received {
    // 显示用户ID
    if (_activityIndicator.isAnimating) {
        [_activityIndicator stopAnimating];
    }
    [self performSegueWithIdentifier:@"yywelcome_main_id" sender:self];
}
- (void)uidReceiveFailed {
    [self performSelector:@selector(receivefailed) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}
- (void)receivefailed {
    if (_activityIndicator.isAnimating) {
        [_activityIndicator stopAnimating];
    }
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"错误" message:@"登录失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
