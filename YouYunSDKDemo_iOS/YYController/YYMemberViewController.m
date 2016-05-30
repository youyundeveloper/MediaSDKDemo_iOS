//
//  YYGroupViewController.m
//  YouYunSDKDemo
//
//  Created by Frederic on 15/11/16.
//  Copyright © 2015年 stylejar. All rights reserved.
//

#import "YYMemberViewController.h"
#import "YYCallPhoneViewController.h"
#import "YYConferenceViewController.h"
#import "YYConferenceNavigationViewController.h"

#import "CoreEngine.h"
#import "MediaConferenceFetchUsersRequest.h"

@interface YYMemberViewController()<UITableViewDataSource,UITableViewDelegate,MediaConferenceFetchUsersRequestDelegate>
{
    // 群联系人员列表
    NSArray * allFriendsArray;
    // 选中群聊成员列表
    NSMutableArray * selectedFriendsArray;
    NSDictionary   * userInfo;
    NSMutableDictionary   * conferenceInviteInfo;
    
    MediaConferenceFetchUsersRequest *fetchRequest;
    // 正在拨打电话
    BOOL isCallingPhone;
    // 来电用户ID
    NSString * fromUid;
    BOOL isFromNotice;
}

@property (weak, nonatomic) IBOutlet UILabel *userInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *guideLabel;
@property (weak, nonatomic) IBOutlet UITableView *membersTableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *inviteConferenceButton;
@property (weak, nonatomic) IBOutlet UITextField *callIDTextFiled;

@end

@implementation YYMemberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *userInfoText = [NSString stringWithFormat:@"我的ID:%@",[CoreEngine sharedInstance].myuid];
    if ([_memberUserInfo objectForKey:@"gid"]) {
        userInfoText = [userInfoText stringByAppendingString:[NSString stringWithFormat:@"  当前群组:%@",[_memberUserInfo objectForKey:@"gid"]]];
    }
    [_userInfoLabel setText:userInfoText];
    [_inviteConferenceButton.layer setBorderWidth:1.0 / [UIScreen mainScreen].scale];
    [_inviteConferenceButton.layer setBorderColor:[[UIColor lightGrayColor]CGColor]];
    [self hideEmptyCells];
    isFromNotice = NO;
    [_activityIndicator stopAnimating];
    allFriendsArray = [[NSArray alloc]init];
    selectedFriendsArray = [[NSMutableArray alloc]init];
    conferenceInviteInfo = [[NSMutableDictionary alloc]init];
    [self setTextFiled];
    
    // 刷新群成员列表
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(refreshMembersAction)];
    [self fetchUserList];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    isCallingPhone = NO;
    // 有会议通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receiveConferenceRoomInfo:) name:@"conferenceRoomInfoNotice" object:nil];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"conferenceRoomInfoNotice" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.callIDTextFiled resignFirstResponder];
}

- (void)setTextFiled {
    UIButton *callIDButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [callIDButton setFrame:CGRectMake(0, 0, 60, 40)];
    [callIDButton setTitle:@"语音聊天" forState:UIControlStateNormal];
    [callIDButton addTarget:self action:@selector(callUserIDButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UILabel *idLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 60, 40)];
    [idLabel setText:@"对方ID:"];
    [self.callIDTextFiled setPlaceholder:@"10086"];
    [self.callIDTextFiled setLeftView:idLabel];
    [self.callIDTextFiled setLeftViewMode:UITextFieldViewModeAlways];
    [self.callIDTextFiled setRightViewMode:UITextFieldViewModeAlways];
    [self.callIDTextFiled setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.callIDTextFiled setRightView:callIDButton];
}

- (void)callUserIDButtonAction:(id)sender {
    [self.callIDTextFiled resignFirstResponder];
    if (![[self.callIDTextFiled text] isEqualToString:@""]) {
        if (isCallingPhone) {
            return;
        }
        isCallingPhone = YES;
        NSError *error = nil;
        [[CoreEngine sharedInstance] callUser:[self.callIDTextFiled text] enableVideo:EnabelVedio error:&error];
        if (error) {
            //通话有错误 提示用户 并挂断
            NSLog(@"%@",error.domain);
            NSLog(@"%@",error.userInfo);
        }
        userInfo = @{@"id":[self.callIDTextFiled text]};
        isFromNotice = NO;
        fromUid = [self.callIDTextFiled text];
        [self performSegueWithIdentifier:@"yyMember_callPhoneID" sender:self];
    }
}

// 来电通知
- (void)FLincomingPhoneCall:(NSNotification *)notification{
    NSString *userId = @"";
    if ([notification.userInfo objectForKey:@"uid"] != nil) {
        userId = [NSString stringWithFormat:@"%@",[notification.userInfo objectForKey:@"uid"]];
    }
    fromUid = userId;
    isFromNotice = YES;
    [self performSegueWithIdentifier:@"yyMember_callPhoneID" sender:self];
    NSLog(@"************** incoming call uid :%@",fromUid);
}
// 来会议通知
- (void)VCConferenceInvite:(NSNotification *)notification{
    NSLog(@"************** receive conference invite ");
    conferenceInviteInfo = [[NSMutableDictionary alloc]initWithDictionary:notification.userInfo];
    [self performSelectorOnMainThread:@selector(showInviteAlert) withObject:nil waitUntilDone:NO];
}
- (void)showInviteAlert{
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
            isFromNotice = YES;
            [self performSegueWithIdentifier:@"yyMember_conferenceID" sender:self];
        }
    }
}

- (void)fetchUserList {
    if (_activityIndicator.isAnimating) {
        return;
    }
    if (!fetchRequest) {
        fetchRequest = [[MediaConferenceFetchUsersRequest alloc]init];
    }
    [fetchRequest setDelegate:self];
    [fetchRequest fetchFriendsDataWithGroupID:[_memberUserInfo objectForKey:@"gid"] userID:[CoreEngine sharedInstance].myuid mAuth:[[CoreEngine sharedInstance]getMAuth]];
}

#pragma mark - MediaConferenceFetchUsersRequestDelegate

- (void)fetchUserLists:(id)resultList requestStatus:(SHFetchUserListRequestStatus)status error:(NSError *)error {
    if (status == SHFetchUserListRequestStatusStart) {
        if (!_activityIndicator.isAnimating) {
            [_activityIndicator startAnimating];
        }
    } else if (status == SHFetchUserListRequestStatusError) {
        if (_activityIndicator.isAnimating) {
            [_activityIndicator stopAnimating];
        }
    } else if (status == SHFetchUserListRequestStatusSuccess) {
        if (_activityIndicator.isAnimating) {
            [_activityIndicator stopAnimating];
        }
        NSMutableArray *tmpGroup = [NSMutableArray array];
        if ([[resultList objectForKey:@"result"] isKindOfClass:[NSDictionary class]]) {
            NSArray *responseRoles = [[resultList objectForKey:@"result"] objectForKey:@"roles"];
            for (id member in responseRoles) {
                NSString *myUserID = [member objectForKey:@"id"];
                if (![myUserID isEqualToString:[CoreEngine sharedInstance].myuid]) {
                    NSMutableDictionary * friend = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                    [member objectForKey:@"id"],@"id",
                                                    [member objectForKey:@"nickname"],@"nickname", nil];
                    [tmpGroup addObject:friend];
                }
            }
        }
        allFriendsArray = tmpGroup;
        [_membersTableView reloadData];
    }
}

// 请求会议房间回调
- (void)receiveConferenceRoomInfo:(NSNotification *)notice {
    NSLog(@"************** notice :%@",notice.userInfo);
    conferenceInviteInfo = [[NSMutableDictionary alloc]initWithDictionary:notice.userInfo];
    NSString *roomid = [NSString stringWithFormat:@"%@",[conferenceInviteInfo objectForKey:@"room"]];
    //房间资源不够 申请失败
    if ([roomid isEqualToString:@"0"]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"房间资源不够，请稍后重试" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    NSError *error = nil;
    [[CoreEngine sharedInstance]callRoom:roomid withKey:[conferenceInviteInfo objectForKey:@"key"] error:&error];
    [[CoreEngine sharedInstance]conferenceInviteUsers:selectedFriendsArray groupID:[_memberUserInfo objectForKey:@"gid"] roomID:[conferenceInviteInfo objectForKey:@"room"] key:[conferenceInviteInfo objectForKey:@"key"]];
    [self performSelectorOnMainThread:@selector(gotoConference) withObject:nil waitUntilDone:NO];
}
- (void)gotoConference {
    [self performSegueWithIdentifier:@"yyMember_conferenceID" sender:self];
}

- (void)refreshMembersAction {
    // 刷新群成员列表
    if (selectedFriendsArray) {
        [selectedFriendsArray removeAllObjects];
    }
    [self fetchUserList];
}
// 邀请群会议
- (IBAction)inviteConButtonAction:(id)sender {
//    if ([selectedFriendsArray count] == 0) {
//        return;
//    }
    isFromNotice = NO;
    [[CoreEngine sharedInstance]conferenceRequestRoomWithGroupID:[_memberUserInfo objectForKey:@"gid"]];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"yyMember_callPhoneID"]) {
        // 电话
        YYCallPhoneViewController * call = segue.destinationViewController;
        if (isFromNotice) {
            // 来电
            call.isAnswer = YES;
            if (fromUid) {
                call.callPhoneUserInfo = @{@"uid":fromUid,@"nickName":@"来电用户"};
            }
        } else {
            // 拨打
            call.isAnswer = NO;
            if (fromUid && [userInfo objectForKey:@"nickname"]) {
                call.callPhoneUserInfo = @{@"uid":fromUid,@"nickName":[userInfo objectForKey:@"nickname"]};
            }
        }
    } else if ([segue.identifier isEqualToString:@"yyMember_conferenceID"]) {
        // 会议
//        YYConferenceViewController *confView = segue.destinationViewController;
        YYConferenceNavigationViewController *confView = segue.destinationViewController;
        
        if (isFromNotice) {
            // 推送通知请求会议
            if (conferenceInviteInfo) {
                [confView setConUserInfo:conferenceInviteInfo];
            }
        } else {
            if ([_memberUserInfo objectForKey:@"gid"] && [conferenceInviteInfo count] > 0) {
                [conferenceInviteInfo setObject:[_memberUserInfo objectForKey:@"gid"] forKey:@"groupid"];
            }
            if (conferenceInviteInfo) {
                [conferenceInviteInfo setObject:[CoreEngine sharedInstance].myuid forKey:@"from"];
                [confView setConUserInfo:conferenceInviteInfo];
            }
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
    return [allFriendsArray count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"yygroup_cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:@"yygroup_cell"];
    }
    NSDictionary *dic = [allFriendsArray objectAtIndex:indexPath.row];
    
    NSString *uid = [NSString stringWithFormat:@"%@",[dic objectForKey:@"id"]];
    // 用户ID
    UILabel *codeLabel = (UILabel *)[cell viewWithTag:100];
    [codeLabel setText:[NSString stringWithFormat:@"%d 用户 %@",(int)indexPath.row + 1,[dic objectForKey:@"id"]]];
    // 单人拨打电话
    UIButton *callPhoneButton = (UIButton *)[cell viewWithTag:102];
    [callPhoneButton addTarget:self action:@selector(callPhoneButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    // 选中
    UIImageView *selectMemberImage = (UIImageView *)[cell viewWithTag:101];
    if ([selectedFriendsArray containsObject:uid]) {
        [selectMemberImage setImage:[UIImage imageNamed:@"CellBlueSelected"]];
    }else{
        [selectMemberImage setImage:[UIImage imageNamed:@"CellNotSelected"]];
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self selectMemberButtonAction:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)hideEmptyCells {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [_membersTableView setTableFooterView:view];
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
    NSIndexPath *indexPath = [_membersTableView indexPathForCell:(UITableViewCell *)v];
    return indexPath;
}

// 拨打一个人的电话
- (void)callPhoneButtonAction:(UIButton*)sender {
    if (isCallingPhone) {
        return;
    }
    isCallingPhone = YES;
    NSIndexPath *indexPath = [self getIndexOfCellContentButton:sender];
    NSError *error = nil;
    [[CoreEngine sharedInstance] callUser:[[allFriendsArray objectAtIndex:indexPath.row]objectForKey:@"id"] enableVideo:EnabelVedio error:&error];
    if (error) {
        //通话有错误 提示用户 并挂断
        NSLog(@"%@",error.domain);
        NSLog(@"%@",error.userInfo);
    }
    userInfo = [allFriendsArray objectAtIndex:indexPath.row];
    isFromNotice = NO;
    fromUid = [[allFriendsArray objectAtIndex:indexPath.row]objectForKey:@"id"];
    [self performSegueWithIdentifier:@"yyMember_callPhoneID" sender:self];
}
// 选中／取消人员
- (void)selectMemberButtonAction:(NSIndexPath*)indexPath {
    NSString *uid = [NSString stringWithFormat:@"%@",[[allFriendsArray objectAtIndex:indexPath.row]objectForKey:@"id"]];
    if ([selectedFriendsArray containsObject:uid]) {
        [selectedFriendsArray removeObject:uid];
    } else {
        [selectedFriendsArray addObject:uid];
    }
    [_membersTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
