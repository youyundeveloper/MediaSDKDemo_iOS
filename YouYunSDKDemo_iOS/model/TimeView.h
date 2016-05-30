//
//  TimeView.h
//  YouYunSDKDemo
//
//  Created by 湛奇 on 13-9-12.
//  Copyright (c) 2013年 stylejar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeView : UIView{
    UILabel *timeLabel;
}
@property (nonatomic,strong)UILabel *timeLabel;

-(void)Start;
-(void)Stop;
@end
