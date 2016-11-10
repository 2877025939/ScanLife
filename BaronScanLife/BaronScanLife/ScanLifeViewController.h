//
//  ScanLifeViewController1.h
//  AnAnScanLife
//
//  Created by anan on 16/11/9.
//  Copyright © 2016年 anan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScanLifeViewController : UIViewController

@property (nonatomic,strong) UIViewController *controller;

@property (nonatomic, copy) void (^ScanCancleBlock) (ScanLifeViewController *);//扫描取消
@property (nonatomic, copy) void (^ScanSuncessBlock) (ScanLifeViewController *,NSString *);//扫描结果



@end
