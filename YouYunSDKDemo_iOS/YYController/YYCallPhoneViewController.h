//
//  YYCallPhoneViewController.h
//  YouYunSDKDemo
//
//  Created by Frederic on 15/11/16.
//  Copyright © 2015年 stylejar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YYCallPhoneViewController : UIViewController

/**
 *  单对单电话信息
 *  uid : 对方的ID
 *  nickName : 对方的名称
 */
@property (nonatomic, strong) NSDictionary * callPhoneUserInfo;
// 是否是接听对方来电
@property (nonatomic) BOOL isAnswer;

@end
