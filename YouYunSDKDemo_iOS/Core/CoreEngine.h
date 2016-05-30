//
//  CoreEngine.h
//  YouYunSDKDemo
//
//  Created by 湛奇 on 13-7-31.
//  Copyright (c) 2013年 stylejar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WChatSDK.h"
#import "MediaSDK.h"

//notifications
// 成功获取UserID
extern NSString *const getUIDnotification;
// 获取UserID失败
extern NSString *const getUIDnotificationFailed;

#define EnabelVedio       0  //是否开启直播的视频功能
#define UseOnlinPlatform  1  //是否使用线上平台

@interface CoreEngine : NSObject <WChatSDKDelegate, MediaSDKDelegate>

@property (nonatomic, weak)id<MediaSDKDelegate>delegate;
@property (nonatomic, strong)NSString *myuid; // 当前用户UserID
@property (nonatomic, strong)NSString *XWVersion;
@property (nonatomic, readonly)BOOL isLogin; // 是否已经登录
@property (nonatomic,strong)NSDictionary *userList;   //用于demo

+(CoreEngine*)sharedInstance;

/**
 *  Auth 登录
 */
-(void)registerOrLoginAction;
/// 用户名密码登录
-(BOOL)login:(NSString *)account password:(NSString *)password;
/**
 *  进入某个群后 申请创建一个电话会议的房间
 *
 *  @param goupID 群组ID
 *
 *  @return 是否申请成功
 */
-(BOOL)conferenceRequestRoomWithGroupID:(NSString *)goupID;
/**
 *  邀请多个成员进入申请好的电话会议房间
 *
 *  @param users   被邀请人的uID
 *  @param groupID 群组ID
 *  @param roomID  房间ID
 *  @param key     房间key
 *
 *  @return 是否成功
 */
-(BOOL)conferenceInviteUsers:(NSArray *)users groupID:(NSString *)groupID roomID:(NSString *)roomID key:(NSString *)key;
/**
 *  获取电话会议当前成员
 *
 *  @param roomID  房间ID
 *  @param groupID 群组ID
 *
 *  @return 是否成功
 */
-(BOOL)conferenceFetchUsersinRoom:(NSString *)roomID groupID:(NSString *)groupID;
/**
 *  请求某人语音聊天
 *
 *  @param userID      被请求人UID
 *  @param enableVideo 是否视频（咱不支持视频）
 *  @param error       错误句柄
 */
-(void)callUser:(NSString *)userID enableVideo:(BOOL)enableVideo error:(NSError **)error;
/**
 *  拨通某个电话会议房间
 *
 *  @param Room  房间ID
 *  @param key   房间key
 *  @param error 错误句柄
 */
-(void)callRoom:(NSString *)Room withKey:(NSString *)key error:(NSError **)error;
-(void)acceptCall:(NSError **)error;
-(void)terminateCall;
-(void)enabelSpeaker:(BOOL)enable;
-(void)enabelMute:(BOOL)enable;
-(BOOL)enterBackgroundMode;
-(void)willResignActiveAction;
-(void)didBecomeActiveAction;

//demo需要用到的方法
-(NSString *)getMAuth;
@end