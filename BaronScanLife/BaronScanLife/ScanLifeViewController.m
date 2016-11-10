//
//  ScanLifeViewController1.m
//  AnAnScanLife
//
//  Created by anan on 16/11/9.
//  Copyright © 2016年 anan. All rights reserved.
//

// 宽高
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define IOS8 ([[UIDevice currentDevice].systemVersion intValue] >= 8 ? YES : NO)
#define  Nav_Height         64

#import "ScanLifeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SDAutoLayout.h"


#define KDeviceFrame [UIScreen mainScreen].bounds

static const float kLineMinY = 185;


@interface ScanLifeViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate>
    
@property(nonatomic,strong)UIImageView *imageView;
@property (nonatomic, strong) AVCaptureSession *qrSession;//回话
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *qrVideoPreviewLayer;//读取
@property (nonatomic, strong) UIImageView *line;//交互线
@property (nonatomic, strong) NSTimer *lineTimer;//交互线控制
@property(nonatomic)BOOL isLight;
@property (strong, nonatomic) CIDetector *detector;
    
@end

@implementation ScanLifeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpView];
    
    [self initUI];
    
    [self setOverlayPickerView];
    
    [self startReading];
}
-(void)setUpView{
    
    self.title = @"扫描";
//    self.view.backgroundColor = [UIColor whiteColor];
    
//    UIBarButtonItem * rbbItem = [[UIBarButtonItem alloc]initWithTitle:@"相册" style:UIBarButtonItemStyleDone target:self action:@selector(clickToImagePicker)];
//    self.navigationItem.rightBarButtonItem = rbbItem;
    
    UIBarButtonItem * lbbItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStyleDone target:self action:@selector(clickToBack)];
    self.navigationItem.leftBarButtonItem = lbbItem;
}
    
    
- (void)initUI{
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //摄像头判断
    NSError *error = nil;
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error){
        NSLog(@"没有摄像头-%@", error.localizedDescription);
        [self dismissViewControllerAnimated:YES completion:nil];
        
        return;
    }
    //设置输出(Metadata元数据)
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    //设置输出的代理
    //使用主线程队列，相应比较同步，使用其他队列，相应不同步，容易让用户产生不好的体验
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [output setRectOfInterest:[self getReaderViewBoundsWithSize:CGSizeMake(SCREEN_WIDTH-140, SCREEN_WIDTH-140)]];
    
    //拍摄会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    // 读取质量，质量越高，可读取小尺寸的二维码
    if ([session canSetSessionPreset:AVCaptureSessionPreset1920x1080]){
        [session setSessionPreset:AVCaptureSessionPreset1920x1080];
    }else if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]){
        [session setSessionPreset:AVCaptureSessionPreset1280x720];
    }else{
        [session setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    
    if ([session canAddInput:input]){
        [session addInput:input];
    }
    
    if ([session canAddOutput:output]){
        [session addOutput:output];
    }
    
    //设置输出的格式
    //一定要先设置会话的输出为output之后，再指定输出的元数据类型
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeAztecCode,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeCode39Mod43Code]];
    
    //设置预览图层
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    
    //设置preview图层的属性
    [preview setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //设置preview图层的大小
    preview.frame = self.view.layer.bounds;
    
    //将图层添加到视图的图层
    [self.view.layer insertSublayer:preview atIndex:0];
    //[self.view.layer addSublayer:preview];
    self.qrVideoPreviewLayer = preview;
    self.qrSession = session;
}
    
- (CGRect)getReaderViewBoundsWithSize:(CGSize)asize{
    
    return CGRectMake(kLineMinY / SCREEN_HEIGHT, ((SCREEN_WIDTH - asize.width) / 2.0) / SCREEN_WIDTH, asize.height / SCREEN_HEIGHT, asize.width / SCREEN_WIDTH);
}
    
- (void)setOverlayPickerView{
    
    //画中间的基准线
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(70,64+100,SCREEN_WIDTH - 140, 8)];
    [_line setImage:[UIImage imageNamed:@"scanImage-1"]];
    [self.view addSubview:_line];
    
    //最上部view
    UIView* upView = [[UIView alloc]init];
    [self.view addSubview:upView];
    upView.sd_layout.topSpaceToView(self.view,Nav_Height).leftSpaceToView(self.view,0).rightSpaceToView(self.view,0).heightIs(100);
    upView.alpha = 0.3;
    upView.backgroundColor = [UIColor blackColor];
    
    //左侧的view
    UIView *leftView = [[UIView alloc] init];
    [self.view addSubview:leftView];
    leftView.sd_layout.topSpaceToView(upView,0).leftSpaceToView(self.view,0).bottomSpaceToView(self.view,0).widthIs(70);
    leftView.alpha = 0.3;
    leftView.backgroundColor = [UIColor blackColor];
    
    //右侧的view
    UIView *rightView = [[UIView alloc] init];
    [self.view addSubview:rightView];
    rightView.sd_layout.topSpaceToView(upView,0).rightSpaceToView(self.view,0).bottomSpaceToView(self.view,0).widthIs(70);
    rightView.alpha = 0.3;
    rightView.backgroundColor = [UIColor blackColor];
    
    //扫描区域
    UIView *scanCropView = [[UIView alloc] initWithFrame:CGRectMake(60,64+100,SCREEN_WIDTH - 120, SCREEN_WIDTH - 140)];
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(70-3,64+100-3,SCREEN_WIDTH-140+4, SCREEN_WIDTH-140+4)];
    self.imageView.image = [UIImage imageNamed:@"scanImage"];
    
    [self.view addSubview:scanCropView];
    [self.view addSubview:self.imageView];
    //底部view
    UIView *downView = [[UIView alloc] init];
    [self.view addSubview:downView];
    downView.sd_layout.topSpaceToView(scanCropView,0).leftSpaceToView(leftView,0).bottomSpaceToView(self.view,0).rightSpaceToView(rightView,0);
    downView.alpha = 0.3;
    downView.backgroundColor = [UIColor blackColor];
    
    //说明label
    UILabel *labIntroudction = [[UILabel alloc] init];
    [self.view addSubview:labIntroudction];
    labIntroudction.sd_layout.bottomSpaceToView(scanCropView,2).leftSpaceToView(leftView,0).heightIs(44).rightSpaceToView(rightView,0);
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.textColor = [UIColor whiteColor];
    labIntroudction.text = @"将二维码/条码置入框内,可自动扫描";
    labIntroudction.adjustsFontSizeToFitWidth =YES;
    //开启闪光灯
    
    UIButton *light = [[UIButton alloc]init];
    [self.view addSubview:light];
    [light setBackgroundImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    light.sd_layout.topSpaceToView(self.view,Nav_Height+15).rightSpaceToView(self.view,15).heightIs(40).widthIs(40);
    [light addTarget:self action:@selector(lightClick:) forControlEvents:UIControlEventTouchUpInside];
    self.isLight = NO;
    
}
-(void)lightClick:(UIButton *)light{
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (self.isLight ==NO) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureTorchModeOn];
                self.isLight  = YES;
                [light setBackgroundImage:[UIImage imageNamed:@"open"] forState:UIControlStateNormal];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                self.isLight  = NO;
                [light setBackgroundImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
                
            }
            [device unlockForConfiguration];
        }
    }
    
}
    
-(void)clickToBack{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 相册
- (void)clickToImagePicker{
        
}

#pragma mark 输出代理方法
//此方法是在识别到QRCode，并且完成转换
//如果QRCode的内容越大，转换需要的时间就越长
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    //扫描结果
    if (metadataObjects.count > 0){
        [self stopSYQRCodeReading];
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        if (self.ScanSuncessBlock) {
            self.ScanSuncessBlock(self,obj.stringValue);
        }
        
    }
    else{
        
    }
}
#pragma mark 交互事件
- (void)startReading
{
    _lineTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 20 target:self selector:@selector(animationLine) userInfo:nil repeats:YES];
    
    [self.qrSession startRunning];
    
    NSLog(@"start reading");
}
    
    
- (void)stopSYQRCodeReading
{
    if (_lineTimer)
    {
        [_lineTimer invalidate];
        _lineTimer = nil;
    }
    
    [self.qrSession stopRunning];
    
    NSLog(@"stop reading");
}
    
    
#pragma mark 上下滚动交互线
- (void)animationLine{
    
    __block CGRect frame = _line.frame;
    
    static BOOL flag = YES;
    if (flag){
        
        frame.origin.y = Nav_Height+100;
        flag = NO;
        [UIView animateWithDuration:1.0 / 20 animations:^{
            
            frame.origin.y += 5;
            _line.frame = frame;
        }];
    }else{
        if (_line.frame.origin.y >= Nav_Height+100){
            if (_line.frame.origin.y >= Nav_Height+100+SCREEN_WIDTH - 140 - 12){
                frame.origin.y = Nav_Height+100;
                _line.frame = frame;
                
                flag = YES;
            }else{
                [UIView animateWithDuration:1.0 / 20 animations:^{
                    
                    frame.origin.y += 5;
                    _line.frame = frame;
                    
                }];
            }
        }else{
            flag = !flag;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //摄像头判断
    NSError *error = nil;
    
    if (error){
        // NSLog(@"没有摄像头-%@", error.localizedDescription);
        [self dismissViewControllerAnimated:YES completion:nil];
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"没有相机权限，请在设置里面打开" preferredStyle:UIAlertControllerStyleAlert];
        
        [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:ac animated:YES completion:nil];
        
        return;
    }
    
    
}
-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
