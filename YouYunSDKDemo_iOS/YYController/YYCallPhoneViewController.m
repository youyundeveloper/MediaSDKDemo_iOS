//
//  YYCallPhoneViewController.m
//  YouYunSDKDemo
//
//  Created by Frederic on 15/11/16.
//  Copyright © 2015年 stylejar. All rights reserved.
//

#import "YYCallPhoneViewController.h"
#import <MediaPlayer/MPMusicPlayerController.h>
#import <AudioToolbox/AudioToolbox.h>

#import "CoreEngine.h"
#import "MediaSDKDelegate.h"
#import "TimeView.h"

@interface YYCallPhoneViewController ()<MediaSDKDelegate>
{
    BOOL speakerEnable;
    BOOL muteEnable;
    MPMusicPlayerController *mpc;
    
}

@property (weak, nonatomic) IBOutlet UILabel *connectionInfoLabel;
// 通话时长
@property (weak, nonatomic) IBOutlet TimeView *timeVIew;
// 话筒
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
// 外放／耳机
@property (weak, nonatomic) IBOutlet UIButton *speckButton;
// 音量
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
// 挂断
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
// 接听
@property (weak, nonatomic) IBOutlet UIButton *acceptBtn;
// 拒绝
@property (weak, nonatomic) IBOutlet UIButton *refuseBtn;

@end

@implementation YYCallPhoneViewController

//speaker method
static void audioRouteChangeListenerCallback (
                                              void                   *inUserData,                                 // 1
                                              AudioSessionPropertyID inPropertyID,                                // 2
                                              UInt32                 inPropertyValueSize,                         // 3
                                              const void             *inPropertyValue                             // 4
) {
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return; // 5
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 显示信息
    NSString * infoText = [NSString stringWithFormat:@"我的ID:%@",[CoreEngine sharedInstance].myuid];
    if ([_callPhoneUserInfo objectForKey:@"uid"]) {
        infoText = [infoText stringByAppendingString:[NSString stringWithFormat:@"    对方ID:%@",[_callPhoneUserInfo objectForKey:@"uid"]]];
    }
    [_connectionInfoLabel setText:infoText];
    
    speakerEnable = NO;
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    OSStatus lStatus = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, (__bridge void *)(self));
    if (lStatus) {
        NSLog(@"cannot un register route change handler [%d]", lStatus);
    }
    muteEnable = NO;
    
    //添加音量控制
    mpc = [MPMusicPlayerController applicationMusicPlayer];
    [mpc beginGeneratingPlaybackNotifications];
    _volumeSlider.value = mpc.volume;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(volumeChange) name:MPMusicPlayerControllerVolumeDidChangeNotification object:nil];
    
    //按钮显示
    if (!_isAnswer) {
        //用户呼叫好友
        _connectBtn.hidden = NO;
    } else {
        //好友呼叫用户
        _acceptBtn.hidden = NO;
        _refuseBtn.hidden = NO;
    }
    [CoreEngine sharedInstance].delegate = self;
//    [[CoreEngine sharedInstance]setLocalVideoView:_localView RemoteVideoView:_remoteView];
    //处理远程推送来的来电
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"hasRemoteTel"]) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(PCuidreceived) name:getUIDnotification object:nil];
        _connectBtn.hidden = YES;
        _acceptBtn.hidden  = NO;
        _refuseBtn.hidden  = NO;
        NSString *user = [NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults]objectForKey:@"accountSaved"]];
        NSString *pwd = [NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults]objectForKey:@"passWordSaved"]];
        BOOL result = [[CoreEngine sharedInstance]login:user password:pwd];
        NSLog(@"result is :%@",result?@"yes":@"NO");
        if (!result) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"登录失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }else{
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"hasRemoteTel"];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
    }
    //通过通知获取通话中的状态变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedUser:) name:NotificationMediaCallConnected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callEndByUser:) name:NotificationMediaCallEnd object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callPauseUser:) name:NotificationMediaCallRemotePause object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callerrorUser:) name:NotificationMediaCallError object:nil];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timeVIew Stop];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)PCuidreceived {
    NSLog(@"receive got uid notice");
//    _coverView.hidden = YES;
}

- (IBAction)muteButtonAction:(id)sender {
    // 语音按钮
    if (muteEnable) {
        [_muteButton setImage:[UIImage imageNamed:@"nomute.png"] forState:UIControlStateNormal];
    }else{
        [_muteButton setImage:[UIImage imageNamed:@"mute.png"] forState:UIControlStateNormal];
    }
    muteEnable = !muteEnable;
    [[CoreEngine sharedInstance]enabelMute:muteEnable];
}

- (IBAction)speckButtonAction:(id)sender {
    // 声音按钮
    if (speakerEnable) {
        [_speckButton setImage:[UIImage imageNamed:@"nospeaker.png"] forState:UIControlStateNormal];
    }else{
        [_speckButton setImage:[UIImage imageNamed:@"speaker.png"] forState:UIControlStateNormal];
    }
    speakerEnable = !speakerEnable;
    [[CoreEngine sharedInstance]enabelSpeaker:speakerEnable];
}

- (IBAction)voiceSliderAction:(id)sender {
    mpc.volume = _volumeSlider.value;
}

- (IBAction)acceptButtonAction:(id)sender {
    NSError *error = nil;
    [[CoreEngine sharedInstance]acceptCall:&error];
    if (error) {
        NSLog(@"************** accept error is :%@",error);
    }
    _acceptBtn.hidden = YES;
    _refuseBtn.hidden = YES;
    _connectBtn.hidden = NO;
}
- (IBAction)connectionButtonAction:(id)sender {
    [[CoreEngine sharedInstance]terminateCall];
    [self selfDismiss];
}
- (IBAction)refuseButtonAction:(id)sender {
    [[CoreEngine sharedInstance]terminateCall];
    [self selfDismiss];
}

#pragma mark - VolumeChange Method
-(void)volumeChange {
    _volumeSlider.value = mpc.volume;
}

#pragma mark- 通过Delegate方法 获取通话状态的变化
#pragma mark - CoreEngine Delegate
- (void)mediaCallConnectedByUser:(NSString *)userId {
    [_timeVIew Start];
}
-(void)mediaCallRemotePauseByUser:(NSString *)userId {
    [[CoreEngine sharedInstance] terminateCall];
    [self selfDismiss];
}

-(void)mediaCallEndByUser:(NSString *)userId {
    NSLog(@"************** end by user :%@",userId);
    [self selfDismiss];
}

-(void)mediaCallError:(NSError *)error fromUser:(NSString *)userId {
    [self selfDismiss];
}

-(void)selfDismiss {
    if ([[UIDevice currentDevice].systemVersion floatValue] > 6.0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark- 通过通知获取通话状态的变化
#pragma mark- Notification right from MediaSDK
-(void)connectedUser:(NSNotification *)notice {
    //    [_timeView Start];
}
-(void)callEndByUser:(NSNotification *)notice {
}
-(void)callPauseUser:(NSNotification *)notice {
}
-(void)callerrorUser:(NSNotification *)notice {
}


@end
