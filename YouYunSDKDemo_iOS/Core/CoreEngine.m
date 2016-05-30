//
//  CoreEngine.m
//  YouYunSDKDemo
//
//  Created by 湛奇 on 13-7-31.
//  Copyright (c) 2013年 stylejar. All rights reserved.
//

#import "CoreEngine.h"
#import "MediaSDK.h"


#define CLIENT_ID       @"1-20113-576fe88462af94a8f0867fabdb09c2c2-ios"
#define SECRET          @"2e4b26434900f6c1bb06f4e478a3f4a3"

@interface CoreEngine ()
{
    WChatSDK        *wchatInstance;
    MediaSDK        *mediaSdkInstance;
}
@property (nonatomic,readwrite)BOOL isLogin;

@end

NSString *const getUIDnotification = @"getuidnotification";
NSString *const getUIDnotificationFailed = @"getuidnotificationfailed";
@implementation CoreEngine

@synthesize delegate,XWVersion,isLogin,myuid,userList;

#pragma mark - Life Circle
static CoreEngine *sharedInstance = nil;

+(CoreEngine *)sharedInstance
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[CoreEngine alloc] init];
        }
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initWchatInstance];
        mediaSdkInstance = [MediaSDK sharedInstance];
        mediaSdkInstance.delegate = self;
        //设置media的端口 和 wchat的端口
        [mediaSdkInstance startWithWchatPort:(int)[wchatInstance getwchatPort]];
        [wchatInstance setSipMediaPort:mediaSdkInstance.mediaPort];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(wchatBindPortOK) name:@"wchatBindPortOK" object:nil];
    }
    return self;
}

//初始化wchat instance
- (void)initWchatInstance{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSError *error = nil;
    
    wchatInstance = [WChatSDK sharedInstance];
    BOOL result = [wchatInstance init:path platform:TestPlatform channel:@"appstore" clientId:CLIENT_ID//@"1-1-8eda6533c616a1ffdf57154550e87c83"
                              version:@"9.9.8" language:@"CH" delegate:self error:&error];
    if (!result) {
        NSLog(@"chatIstance 初始化设置失败");
    }
    
}

-(void)wchatBindPortOK{
    //设置media的端口 和 wchat的端口
    [mediaSdkInstance startWithWchatPort:(int)[wchatInstance getwchatPort]];
    [wchatInstance setSipMediaPort:mediaSdkInstance.mediaPort];
}
#pragma mark - coreEngine method
- (void)registerOrLoginAction {
    [wchatInstance registerApp:[NSString stringWithFormat:@"udid-%@",[WChatSDK getUDID]] clientId:CLIENT_ID secret:SECRET delegate:self];
}

-(BOOL)login:(NSString *)account password:(NSString *)password{
    NSError *error = nil;
    BOOL result = [wchatInstance wchatLogin:account password:password onBackGround:NO withTimeout:20.0 error:nil];
    if (!result) {
        NSLog(@"登录失败 error:%@",error);
    }
    self.isLogin = result;
    return result;
}

-(void)onwchatAuth:(WChatSDK *)instance userinfo:(NSDictionary *)userinfo withError:(NSError *)error{
    if (error != nil) {
        NSLog(@"------------ login error %@", [error description]);
        [[NSNotificationCenter defaultCenter]postNotificationName:getUIDnotificationFailed object:nil];
        return;
    }
    NSLog(@"------------ login ok %@",instance.userId);
    self.myuid = instance.userId;
    self.XWVersion = [instance getXWVersion];
    
    NSLog(@"************** now post getuid");
    [[NSNotificationCenter defaultCenter]postNotificationName:getUIDnotification object:nil];
}

#pragma mark - conference 电话会议

-(BOOL)conferenceRequestRoomWithGroupID:(NSString *)goupID{
    return [wchatInstance wchatConferenceRequestRoomWithGroupID:goupID myuid:wchatInstance.userId error:nil];
}
-(BOOL)conferenceInviteUsers:(NSArray *)users groupID:(NSString *)groupID roomID:(NSString *)roomID key:(NSString *)key{
    return [wchatInstance wchatConferenceInviteUsers:users groupID:groupID roomID:roomID key:key error:nil];
}
-(BOOL)conferenceFetchUsersinRoom:(NSString *)roomID groupID:(NSString *)groupID{
    return [wchatInstance wchatConferenceFetchUsersinRoom:roomID groupID:groupID error:nil];
}

#pragma mark - voip 网络电话（一对一电话)
-(void)callUser:(NSString *)userID enableVideo:(BOOL)enableVideo error:(NSError **)error{
    [mediaSdkInstance callUser:userID from:wchatInstance.userId enabelVideo:enableVideo error:error];
}
-(void)callRoom:(NSString *)Room withKey:(NSString *)key error:(NSError **)error{
    return [mediaSdkInstance callRoom:Room from:wchatInstance.userId withKey:key error:error];
}
-(void)acceptCall:(NSError **)error{
    [mediaSdkInstance callAccept:error];
}

-(void)terminateCall{
    [mediaSdkInstance callTerminate];
}

-(void)terminateLive{
    [mediaSdkInstance terminateLive];
}

-(void)enabelSpeaker:(BOOL)enable{
    mediaSdkInstance.enableSpeaker = enable;
}

-(void)enabelMute:(BOOL)enable{
    mediaSdkInstance.enableMicrophone = enable;
}

-(BOOL)enterBackgroundMode{
    //nsloop
    //register keepalive
    if ([[UIApplication sharedApplication] setKeepAliveTimeout:600/*(NSTimeInterval)linphone_proxy_config_get_expires(proxyCfg)*/
                                                       handler:^{
                                                           [wchatInstance wchatKeepAlive:3];
                                                           [mediaSdkInstance keepAlive];
                                                       }
         ]) {
        
        
    } else {
    }

    
    return [mediaSdkInstance enterBackgroundMode];
}

-(void)willResignActiveAction{
    [mediaSdkInstance willResignActiveAction];
}

-(void)didBecomeActiveAction{
    [mediaSdkInstance didBecomeActiveAction];
}

#pragma mark - MediaSDKDelegate
//来电

-(void)mediaCallIncomingByUser:(NSString *)userId
{
    NSLog(@"------------ mediaCallIncomingByUser %@", userId);
}

//接通
- (void)mediaCallConnectedByUser:(NSString *)userId{
    if ([self.delegate respondsToSelector:@selector(mediaCallConnectedByUser:)]) {
        [self.delegate mediaCallConnectedByUser:userId];
    }
}
//挂断
-(void)mediaCallEndByUser:(NSString*)userId
{
    if ([self.delegate respondsToSelector:@selector(mediaCallEndByUser:)]) {
        [self.delegate mediaCallEndByUser:userId];
    }
}

//挂起(被优先级更高任务打断)
-(void)mediaCallRemotePauseByUser:(NSString*)userId
{
    NSLog(@"--zq-- coreEngine call paused");
    if ([self.delegate respondsToSelector:@selector(mediaCallRemotePauseByUser:)]) {
        [self.delegate mediaCallRemotePauseByUser:userId];
    }
}

//错误
-(void)mediaCallError:(NSError*)error fromUser:(NSString*)userId
{
    if ([self.delegate respondsToSelector:@selector(mediaCallError:fromUser:)]) {
        [self.delegate mediaCallError:error fromUser:userId];
    }
}

#pragma mark - WChatSDK delegate
-(void)missCallFromUser:(NSString *)fromUid atTime:(NSInteger)time
{
    NSLog(@"------------! miss call from %@ at time %d", fromUid, time);
    NSString *timeStr = [NSString stringWithFormat:@"%d",time];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"updateMissCall" object:nil userInfo:@{@"uid": fromUid,@"time":timeStr}];
}

//申请电话会议房间 或 邀请好友加入电话会议 或 收到电话会议邀请 或 获取成员列表 的 callback
-(void)onReceiveConfeneceCallback:(WChatSDK *)instance type:(cfcallbackType)type fromUser:(NSString *)fromUid groupID:(NSString *)groupID roomID:(NSString *)roomID key:(NSString *)key users:(NSArray *)users startTime:(NSString *)startTime endTime:(NSString *)endTime error:(NSError *)error{
    if (error) {
        NSLog(@"************** there is a error :%@",error);
    }
    if (type==cfcallbackTypeRoomRequest) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"conferenceRoomInfoNotice" object:nil userInfo:@{@"room": roomID,@"key":key,@"start":startTime,@"end":endTime}];
    }else if (type==cfcallbackTypeSendInvite){
        //邀请已经发送成功 可以在这里添加 通知 做UI呈现
    }else if (type==cfcallbackReceiveInvite){
        [[NSNotificationCenter defaultCenter]postNotificationName:@"conferenceRoomInvite" object:nil userInfo:@{@"from": fromUid,@"groupid":groupID,@"room":roomID,@"key":key}];
    }else if (type==cfcallbackTypeFetch){
        [[NSNotificationCenter defaultCenter]postNotificationName:@"conferenceRoomMenber" object:nil userInfo:@{@"users": users}];
    }
}

-(void)conferenceJoinedWith:(NSString *)roomID groupID:(NSString *)groupID users:(NSArray *)users{
    NSLog(@"************** joined with room:%@ group:%@ user:%@",roomID,groupID,users);
}
-(void)conferenceMutedWith:(NSString *)roomID groupID:(NSString *)groupID fromUid:(NSString *)fromUid users:(NSArray *)users{
    NSLog(@"************** muted with room:%@ group:%@ from:%@ users:%@",roomID,groupID,fromUid,users);
}
-(void)conferenceUnmutedWith:(NSString *)roomID groupID:(NSString *)groupID fromUid:(NSString *)fromUid users:(NSArray *)users{
    NSLog(@"************** unmuted with room:%@ group:%@ from:%@ users:%@",roomID,groupID,fromUid,users);
}
-(void)conferenceKickedWith:(NSString *)roomID groupID:(NSString *)groupID fromUid:(NSString *)fromUid users:(NSArray *)users{
    NSLog(@"************** kicked with room:%@ group:%@ from:%@ users:%@",roomID,groupID,fromUid,users);
}
-(void)conferenceLeftWith:(NSString *)roomID groupID:(NSString *)groupID users:(NSArray *)users{
    NSLog(@"************** left with room:%@ group:%@ user:%@",roomID,groupID,users);
}
-(void)conferenceWillbeEndWith:(NSString *)roomID groupID:(NSString *)groupID intime:(NSInteger)second{
    NSLog(@"************** will end with room:%@ group:%@ intime:%d",roomID,groupID,second);
    NSString *time = [NSString stringWithFormat:@"%d",second];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"conferenceRoomWillEnd" object:nil userInfo:@{@"room": roomID,@"groupid":groupID,@"time":time}];
}
-(void)conferenceExpiredWithRoomID:(NSString *)roomID key:(NSString *)key{
    NSLog(@"************** conference expired with roomid :%@ key :%@",roomID,key);
    [[NSNotificationCenter defaultCenter]postNotificationName:@"conferenceRoomExpired" object:nil userInfo:@{@"room": roomID,@"key":key}];
}


#pragma mark- help method
-(NSString *)getMAuth{
    return [wchatInstance wchatGetMAuth];
}
@end
