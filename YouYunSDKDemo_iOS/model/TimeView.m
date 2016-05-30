//
//  TimeView.m
//  YouYunSDKDemo
//
//  Created by 湛奇 on 13-9-12.
//  Copyright (c) 2013年 stylejar. All rights reserved.
//

#import "TimeView.h"
@interface TimeView (){
    NSTimer *timer;
    NSDate  *date;
}
@end

@implementation TimeView
@synthesize timeLabel;

//代码创建
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        timeLabel.textColor = [UIColor blackColor];
        timeLabel.backgroundColor = [UIColor clearColor];
        timeLabel.font = [UIFont systemFontOfSize:17];
        timeLabel.textAlignment = UITextAlignmentCenter;
        timeLabel.text = @"00:00:00";
        [self addSubview:timeLabel];
    }
    return self;
}

//IB 创建
- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        timeLabel.textColor = [UIColor blackColor];
        timeLabel.backgroundColor = [UIColor clearColor];
        timeLabel.font = [UIFont systemFontOfSize:17];
        timeLabel.textAlignment = UITextAlignmentCenter;
        timeLabel.text = @"00:00:00";
        [self addSubview:timeLabel];
    }
    return self;
}

- (void)Start{
    date = [NSDate date];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countTime) userInfo:nil repeats:YES];
}
- (void)Stop{
    [timer invalidate];
    timer = nil;
}
- (void)countTime{
    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:date];
    int totalseconds = (int)time;
    int hour = totalseconds/(60*60);
    int min  = (totalseconds-hour*60*60)/60;
    int second = totalseconds - hour*60*60 - min*60;
    NSString *hourStr = [NSString stringWithFormat:@"%d",hour];
    if (hourStr.length<2) {
        hourStr = [NSString stringWithFormat:@"0%@",hourStr];
    }
    NSString *minStr = [NSString stringWithFormat:@"%d",min];
    if (minStr.length<2) {
        minStr = [NSString stringWithFormat:@"0%@",minStr];
    }
    NSString *secondStr = [NSString stringWithFormat:@"%d",second];
    if (secondStr.length<2) {
        secondStr = [NSString stringWithFormat:@"0%@",secondStr];
    }
    self.timeLabel.text = [NSString stringWithFormat:@"%@:%@:%@",hourStr,minStr,secondStr];
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
