//
//  YYMainViewController.m
//  YouYunSDKDemo
//
//  Created by Frederic on 15/11/16.
//  Copyright © 2015年 stylejar. All rights reserved.
//

#import "YYMainViewController.h"
#import "YYMemberViewController.h"
#import "YYCallPhoneViewController.h"
#import "YYConferenceViewController.h"

#import "CoreEngine.h"
#import "MediaConferenceJoinGroupRequest.h"

@interface YYMainViewController ()<UITableViewDataSource,UITableViewDelegate,MediaConferenceJoinGroupRequestDelegate>
{
    // 可用群组
    NSArray * allGroupArray;
    // 加入群组请求
    MediaConferenceJoinGroupRequest * joinRequest;
    // 准备加入的群组id
    NSString * fetchGroupID;
    // 打入电话的uid
    NSString * fromUid;
    // 请求会议通知的信息
    NSDictionary *conferenceInviteInfo;
    // 当前是否正在加入群组
    BOOL isFetchingGroup;
    
}
// 页面显示信息
@property (weak, nonatomic) IBOutlet UILabel *userInfoLabel;
// 页面提示
@property (weak, nonatomic) IBOutlet UILabel *addGroupLabel;
// 群组列表
@property (weak, nonatomic) IBOutlet UITableView *groupTableView;
// 等待加载
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation YYMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    allGroupArray = [[NSArray alloc]initWithObjects:@"151849", @"105472", nil];
    [_activityIndicator stopAnimating];
    // 显示当前用户ID
    [_userInfoLabel setText:[NSString stringWithFormat:@"当前用户ID：%@",[CoreEngine sharedInstance].myuid]];
    [self hideEmptyCells];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    isFetchingGroup = NO;
    if (_activityIndicator.isAnimating) {
        [_activityIndicator stopAnimating];
    }
    
    // 有来电通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(FLincomingPhoneCall:) name:NotificationMediaCallIncoming object:nil];
    // 有来电会议通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(VCConferenceInvite:) name:@"conferenceRoomInvite" object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 页面消失时移除对来电的监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationMediaCallIncoming object:nil];
    // 页面消失时移除对来会议的监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"conferenceRoomInvite" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 来电通知
- (void)FLincomingPhoneCall:(NSNotification *)notification{
    NSString *userId = @"";
    if ([notification.userInfo objectForKey:@"uid"] != nil) {
        userId = [NSString stringWithFormat:@"%@",[notification.userInfo objectForKey:@"uid"]];
    }
    fromUid = userId;
    [self performSegueWithIdentifier:@"yyMain_callphoneID" sender:self];
    NSLog(@"************** incoming call uid :%@",fromUid);
}
// 来会议通知
- (void)VCConferenceInvite:(NSNotification *)notification{
    NSLog(@"************** receive conference invite ");
    conferenceInviteInfo = notification.userInfo;
    [self performSelectorOnMainThread:@selector(showInviteAlert) withObject:nil waitUntilDone:NO];
}
- (void)showInviteAlert {
    NSLog(@"************** show alert for invite");
    NSString *msg = [NSString stringWithFormat:@"%@ 邀请你加入房间：%@ 的电话会议",[conferenceInviteInfo objectForKey:@"from"],[conferenceInviteInfo objectForKey:@"room"]];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"电话会议" message:msg delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"接受", nil];
    alert.tag = 333;
    [alert show];
}
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 333) {
        if (buttonIndex == 1) {
            NSError *error = nil;
            [[CoreEngine sharedInstance]callRoom:[conferenceInviteInfo objectForKey:@"room"] withKey:[conferenceInviteInfo objectForKey:@"key"] error:&error];
            [self performSegueWithIdentifier:@"yyMain_conferenceID" sender:self];
        }
    }
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"yyMain_memberID"]) {
        // 进入群组成员列表页面
        YYMemberViewController *memberViewController = segue.destinationViewController;
        if (fetchGroupID) {
            memberViewController.memberUserInfo = @{@"gid":fetchGroupID};
        }
    } else if ([segue.identifier isEqualToString:@"yyMain_callphoneID"]) {
        // 有来电，进入接听电话页面
        YYCallPhoneViewController * callPhone = segue.destinationViewController;
        callPhone.isAnswer = YES;
        if (fromUid) {
            [callPhone setCallPhoneUserInfo:@{@"uid":fromUid}];
        }
        
    } else if ([segue.identifier isEqualToString:@"yyMain_conferenceID"]) {
        // 有来电会议，进入会议页面
        YYConferenceViewController * confernce = segue.destinationViewController;
        if (conferenceInviteInfo) {
            confernce.conUserInfo = conferenceInviteInfo;
        }
    }
}

- (void)showAlertViewWithMessage:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"错误" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
    [alertView show];
}
// 加入群组
- (void)fetchFriendsDataWithGroupID:(NSString*)groupID{
    if (isFetchingGroup || !groupID || [groupID isEqualToString:@""]) {
        return;
    }
    isFetchingGroup = YES;
    fetchGroupID = groupID;
    
    if (!joinRequest) {
        joinRequest = [[MediaConferenceJoinGroupRequest alloc]init];
    }
    [joinRequest setDelegate:self];
    [joinRequest joinGroupWithGroupID:groupID userID:[CoreEngine sharedInstance].myuid mAuth:[[CoreEngine sharedInstance]getMAuth]];
}

#pragma mark - MediaConferenceJoinGroupRequestDelegate 

- (void)joinGroupResponse:(id)resultList requestStatus:(SHJoinGroupRequestStatus)status error:(NSError *)error {
    if (status == SHJoinGroupRequestStatusStart) {
        if (!_activityIndicator.isAnimating) {
            [_activityIndicator startAnimating];
        }
    } else if (status == SHJoinGroupRequestStatusLoading) {
        
    } else if (status == SHJoinGroupRequestStatusError) {
        isFetchingGroup = NO;
        if (_activityIndicator.isAnimating) {
            [_activityIndicator stopAnimating];
        }
    } else if ( status == SHJoinGroupRequestStatusSuccess) {
        if ([resultList count] > 0) {
            // 加入群组成功
            [self performSegueWithIdentifier:@"yyMain_memberID" sender:self];
        } else {
            isFetchingGroup = NO;
            [self showAlertViewWithMessage:@"加入群组请求失败，请重试"];
        }
        if (_activityIndicator.isAnimating) {
            [_activityIndicator stopAnimating];
        }
    }
}

#pragma mark - UITableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
- (NSInteger )numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [allGroupArray count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * yyGroupTabelViewCellID = @"yyGroupTabelViewCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:yyGroupTabelViewCellID];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:yyGroupTabelViewCellID];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    [cell.textLabel setText:[NSString stringWithFormat:@"群组%d - %@", (int)indexPath.row + 1, [allGroupArray objectAtIndex:indexPath.row]]];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self fetchFriendsDataWithGroupID:[allGroupArray objectAtIndex:indexPath.row]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)hideEmptyCells {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [_groupTableView setTableFooterView:view];
}

@end
