//
//  ViewController.m
//  AnAnScanLife
//
//  Created by anan on 16/11/9.
//  Copyright © 2016年 anan. All rights reserved.
//

#import "ViewController.h"
#import "ScanLifeViewController.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *lable;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)scanClick:(id)sender {
    
    __weak ViewController *weakSelf = self;
    
    //扫描二维码
    ScanLifeViewController *scanfLiftVC = [[ScanLifeViewController alloc]init];
    UINavigationController * scanfVC = [[UINavigationController alloc]initWithRootViewController:scanfLiftVC];
    
    scanfLiftVC.ScanSuncessBlock = ^(ScanLifeViewController *scanfLiftVC,NSString *qrString){

        self.lable.text= qrString;

        [scanfLiftVC dismissViewControllerAnimated:NO completion:nil];
    };
    
    
    [weakSelf presentViewController:scanfVC animated:YES completion:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
