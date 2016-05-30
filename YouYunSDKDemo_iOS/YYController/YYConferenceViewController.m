//
//  YYConferenceViewController.m
//  YouYunSDKDemo
//
//  Created by Frederic on 15/11/16.
//  Copyright © 2015年 stylejar. All rights reserved.
//

#import "YYConferenceViewController.h"
#import <MediaPlayer/MPMusicPlayerController.h>
#import <AudioToolbox/AudioToolbox.h>

#import "CoreEngine.h"
#import "MediaSDKDelegate.h"
#import "TimeView.h"

@interface YYConferenceViewController ()<UITableViewDataSource,UITableViewDelegate,MediaSDKDelegate>
{
    NSMutableArray *member;
    NSString *roomid;
    BOOL muteEnable;
    BOOL speakerEnable;
}

@property (weak, nonatomic) IBOutlet UILabel *conRoomInfoLabel;
@property (weak, nonatomic) IBOutlet UITableView *connectionMemberTableView;
@property (weak, nonatomic) IBOutlet UIButton *moteButton;
@property (weak, nonatomic) IBOutlet UIButton *speckButton;
@property (weak, nonatomic) IBOutlet TimeView *timeView;
@property (weak, nonatomic) IBOutlet UIButton *inviteMoreButton;

@end

@implementation YYConferenceViewController

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
    NSString * conRoomInfoText = [NSString stringWithFormat:@"我的ID:%@",[CoreEngine sharedInstance].myuid];
    if ([_conUserInfo objectForKey:@"room"]) {
        roomid = [_conUserInfo objectForKey:@"room"];
        conRoomInfoText = [conRoomInfoText stringByAppendingString:[NSString stringWithFormat:@"  当前房间: %@",[_conUserInfo objectForKey:@"room"]]];
    }
    if ([_conUserInfo objectForKey:@"groupid"]) {
        conRoomInfoText = [conRoomInfoText stringByAppendingString:[NSString stringWithFormat:@"  当前群组:%@",[_conUserInfo objectForKey:@"groupid"]]];
    }
    [_conRoomInfoLabel setText:conRoomInfoText];
    
    [_moteButton setImage:[UIImage imageNamed:@"nomute"] forState:UIControlStateNormal];
    [_speckButton setImage:[UIImage imageNamed:@"nospeaker"] forState:UIControlStateNormal];
    member = [[NSMutableArray alloc]init];
    [self hideEmptyCells];
    
    [_inviteMoreButton.layer setBorderWidth:1.0 / [UIScreen mainScreen].scale];
    [_inviteMoreButton.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    OSStatus lStatus = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, (__bridge void *)(self));
    if (lStatus) {
        NSLog(@"cannot un register route change handler [%d]", lStatus);
    }
    
    [CoreEngine sharedInstance].delegate = self;
    //通过通知获取通话中的状态变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedUser:) name:NotificationMediaCallConnected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callEndByUser:) name:NotificationMediaCallEnd object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callPauseUser:) name:NotificationMediaCallRemotePause object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callerrorUser:) name:NotificationMediaCallError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callExpired:) name:@"conferenceRoomExpired" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callWillEnd:) name:@"conferenceRoomWillEnd" object:nil];
    //获取电话会议成员
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(membersgot:) name:@"conferenceRoomMenber" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadMembers];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timeView Stop];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)muteButtonAction:(id)sender {
    // 话筒按钮
    if (!muteEnable) {
        [_moteButton setImage:[UIImage imageNamed:@"mute"] forState:UIControlStateNormal];
    }else{
        [_moteButton setImage:[UIImage imageNamed:@"nomute"] forState:UIControlStateNormal];
    }
    muteEnable = !muteEnable;
    [[CoreEngine sharedInstance]enabelMute:muteEnable];
    
}
- (IBAction)speckButtonAction:(id)sender {
    // 刷新按钮
    if (!speakerEnable) {
        [_speckButton setImage:[UIImage imageNamed:@"speaker"] forState:UIControlStateNormal];
    }else{
        [_speckButton setImage:[UIImage imageNamed:@"nospeaker"] forState:UIControlStateNormal];
    }
    speakerEnable = !speakerEnable;
    [[CoreEngine sharedInstance]enabelSpeaker:speakerEnable];
}

- (IBAction)takeOffAction:(id)sender {
    // 挂断
    [[CoreEngine sharedInstance]terminateCall];
    [self selfDismiss];
}

- (IBAction)fefreshAction:(id)sender {
    // 刷新
    [self reloadMembers];
}
// 邀请更多人
- (IBAction)inviteMoreButtonAction:(id)sender {
    
}

- (void)reloadMembers {
    if (![_conUserInfo objectForKey:@"room"] || ![_conUserInfo objectForKey:@"groupid"]) {
        return;
    }
    [[CoreEngine sharedInstance]conferenceFetchUsersinRoom:[_conUserInfo objectForKey:@"room"] groupID:[_conUserInfo objectForKey:@"groupid"]];
}

#pragma mark- 通过Delegate方法 获取通话状态的变化
#pragma mark - CoreEngine Delegate
- (void)mediaCallConnectedByUser:(NSString *)userId {
    [_timeView Start];
    [self reloadMembers];
}
-(void)mediaCallRemotePauseByUser:(NSString *)userId {
    [[CoreEngine sharedInstance] terminateCall];
    [self selfDismiss];
}

-(void)mediaCallEndByUser:(NSString *)userId {
    NSLog(@"************** delegate receive end");
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

- (void)callExpired:(NSNotification *)notice {
    NSLog(@"************** conference notice.userinfo:%@",notice.userInfo);
    NSString *noticeRoomid = [NSString stringWithFormat:@"%@",[notice.userInfo objectForKey:@"room"]];
    if ([noticeRoomid isEqualToString:roomid]) {
        [self performSelectorOnMainThread:@selector(mainselfDismiss) withObject:nil waitUntilDone:NO];
    }
}
- (void)callWillEnd:(NSNotification *)notice {
    NSLog(@"************** conferece notice.userinfo:%@",notice.userInfo);
    NSString *noticeRoomid = [NSString stringWithFormat:@"%@",[notice.userInfo objectForKey:@"room"]];
    if ([noticeRoomid isEqualToString:roomid]) {
        [self performSelectorOnMainThread:@selector(mainselfDismiss) withObject:nil waitUntilDone:NO];
    }
}

- (void)mainselfDismiss {
    [self performSelector:@selector(selfDismiss) withObject:nil afterDelay:0.5];
}
#pragma mark - conference 电话会议
- (void)membersgot:(NSNotification *)notice {
    NSLog(@"************** got list :%@",notice.userInfo);
    NSArray *othermenbers = [notice.userInfo objectForKey:@"users"];
    [self performSelectorOnMainThread:@selector(showusers:) withObject:othermenbers waitUntilDone:NO];
}
- (void)showusers:(NSArray *)users {
    [member removeAllObjects];
    for (int i = 0; i < users.count; i++) {
        NSString *uid = [NSString stringWithFormat:@"%@",[users objectAtIndex:i]];
        NSLog(@"************** uid :%@",uid);
        [member addObject:uid];
    }
    NSLog(@"************** menbers is :%@",member);
    [_connectionMemberTableView reloadData];
}

#pragma mark - UITableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
- (NSInteger )numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [member count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * identifiers = @"yyConferenceTableViewCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifiers];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifiers];
    }
    [cell.textLabel setText:[NSString stringWithFormat:@"%d 用户 %@", (int)indexPath.row + 1, [member objectAtIndex:indexPath.row]]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)hideEmptyCells {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [_connectionMemberTableView setTableFooterView:view];
}

- (NSIndexPath*)getIndexOfCellContentButton:(UIButton*)sender {
    if (![sender isKindOfClass:[UIButton class]]) {
        return 0;
    }
    UIView * v = sender.superview.superview;
    if (![v isKindOfClass:[UITableViewCell class]]) {
        //ios 8.0以前 需要取三次才能取到 cell
        v = sender.superview.superview.superview;
    }
    NSIndexPath *indexPath = [_connectionMemberTableView indexPathForCell:(UITableViewCell *)v];
    return indexPath;
}

@end
