//
//  YYConferenceNavigationViewController.h
//  YouYunSDKDemo
//
//  Created by Frederic on 15/11/24.
//  Copyright © 2015年 stylejar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YYConferenceNavigationViewController : UINavigationController

/**
 *  会议页面的显示信息
 *  room    房间号(必须)
 *  groupid 群组ID(必现)
 *  key     请求key(非必需)
 *  from    发起人(必需)
 *
 */
@property (nonatomic, strong) NSDictionary * conUserInfo;

@end
