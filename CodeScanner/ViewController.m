//
//  ViewController.m
//  CodeScanner
//
//  Created by roger wu on 15/11/16.
//  Copyright © 2015年 roger. All rights reserved.
//

#import "ViewController.h"
#import "ZBarSDK.h"
#import "MBProgressHUD.h"

@interface ViewController ()<
    ZBarReaderViewDelegate,
    ZBarReaderDelegate>

@property (nonatomic, strong) ZBarReaderView *readerView;

@property (nonatomic, strong) UIImageView *lineView; // 线

@property (nonatomic, strong) UIButton *flashButton; // 闪光灯

@property (nonatomic, strong) UIButton *photoButton; // 图片

@property (nonatomic, assign) CGFloat lineTop; // 线的顶部位置

@property (nonatomic, assign) CGFloat lineBottom; // 线的底部位置

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.readerView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scanAnimation)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (ZBarReaderView *)readerView {
    if (!_readerView) {
        ZBarReaderView *readerView = [[ZBarReaderView alloc] init];
        readerView.frame = self.view.bounds;
        readerView.readerDelegate = self;
        readerView.allowsPinchZoom = YES;
        readerView.showsFPS = YES;
        readerView.torchMode = 0;
        _readerView = readerView;
        
        // 正方形
        UIImage *pickImage = [UIImage imageNamed:@"scan_bg"];
        UIImageView *pickImageView = [[UIImageView alloc] initWithImage:pickImage];
        [pickImageView addSubview:self.lineView];
        [readerView addSubview:pickImageView];
        
        CGFloat screenW = self.view.bounds.size.width;
        CGFloat screenH = self.view.bounds.size.height;
        CGFloat pickImageW = pickImage.size.width;
        CGFloat pickImageH = pickImage.size.height;
        CGFloat pickX = (screenW - pickImageW) / 2;
        CGFloat pickY = (screenH - pickImageH) / 2;
        CGFloat lineH = 5.f / 2;
        CGFloat padding = 10.f;
        CGFloat lineW = pickImageW - 2 * padding;
        CGFloat lineX = padding;
        CGFloat lineY = padding;
        
        pickImageView.frame = CGRectMake(pickX, pickY, pickImageW, pickImageH);
//        readerView.scanCrop = [self getScanCrop:pickImageView.frame readerViewBounds:readerView.bounds];
        readerView.scanCrop = self.view.bounds; // 目前做的全屏都可以扫描，识别更快
        self.lineView.frame = CGRectMake(lineX, lineY, lineW, lineH);
        self.lineTop = padding;
        self.lineBottom = pickImageH - 2 * padding;
        
        [self scanAnimation];
        
        // 添加两个按钮
        CGFloat buttonW = 45.f;
        CGFloat buttonH = 45.f;
        CGFloat bigW = self.view.frame.size.width / 4;
        CGFloat buttonY = self.view.frame.size.height - 100.f;
        CGFloat flashButtonX = bigW + (bigW - buttonW) / 2;
        CGFloat photoButtonX = 2 * bigW + (bigW - buttonW) / 2;
        
        self.flashButton.frame = CGRectMake(flashButtonX, buttonY, buttonW, buttonH);
        self.photoButton.frame = CGRectMake(photoButtonX, buttonY, buttonW, buttonH);
        [readerView addSubview:self.flashButton];
        [readerView addSubview:self.photoButton];
    }
    return _readerView;
}

- (UIImageView *)lineView {
    if (!_lineView) {
        UIImage *lineImage = [UIImage imageNamed:@"line"];
        _lineView = [[UIImageView alloc] initWithImage:lineImage];
    }
    return _lineView;
}

- (UIButton *)flashButton {
    if (!_flashButton) {
        UIButton *flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [flashButton setBackgroundImage:[UIImage imageNamed:@"flash_icon"] forState:UIControlStateNormal];
        [flashButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _flashButton = flashButton;
    }
    return _flashButton;
}

- (UIButton *)photoButton {
    if (!_photoButton) {
        UIButton *photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [photoButton setBackgroundImage:[UIImage imageNamed:@"photo_icon"] forState:UIControlStateNormal];
        [photoButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _photoButton = photoButton;
    }
    return _photoButton;
}

#pragma mark - 获取扫描区域
-(CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds
{
    CGFloat x,y,width,height;
    
    x = rect.origin.x / readerViewBounds.size.width;
    y = rect.origin.y / readerViewBounds.size.height;
    width = rect.size.width / readerViewBounds.size.width;
    height = rect.size.height / readerViewBounds.size.height;
    
    return CGRectMake(x, y, width, height);
}

#pragma mark - 扫描动画
- (void)scanAnimation {
    [self.readerView start];
    
    CGRect frame = self.lineView.frame;
    frame.origin.y = self.lineTop;
    self.lineView.frame = frame;
    
    __weak __typeof (&*self)weakSelf = self;
    CGFloat animationDuration = 2.5f;
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                         CGRect frame = self.lineView.frame;
                         frame.origin.y = self.lineBottom;
                         weakSelf.lineView.frame = frame;
                     } completion:^(BOOL finished) {
                     }];
}

#pragma mark - ZBarReaderViewDelegate
- (void)readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image {
    // 得到扫描的条码内容
    const zbar_symbol_t *symbol = zbar_symbol_set_first_symbol(symbols.zbarSymbolSet);
    NSString *result = [NSString stringWithUTF8String: zbar_symbol_get_data(symbol)];
    [self parseResult:result];
}

- (void)readerView:(ZBarReaderView *)readerView didStopWithError:(NSError *)error {
//    [self showAlertWithTitle:@"扫描错误" value:[NSString stringWithFormat:@"%@", error]];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    ZBarSymbol *symbol = nil;
    for(symbol in results) { break; }
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *result = symbol.data;
    [self parseResult:result];
}

- (void)buttonAction:(UIButton *)button {
    if (button == self.flashButton) {
        if (self.readerView.torchMode) {
            self.readerView.torchMode = 0;
        } else {
            self.readerView.torchMode = 1;
        }
    } else if (button == self.photoButton) {
        ZBarReaderController *reader = [[ZBarReaderController alloc] init];
        reader.readerDelegate = self;
        reader.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        [self presentViewController:reader animated:YES completion:nil];
    }
}

#pragma mark - 显示信息
- (void)showAlertWithTitle:(NSString *)title value:(NSString *)value {
    __weak __typeof(&*self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:value
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [alert dismissViewControllerAnimated:YES completion:nil];
                                                             [weakSelf.readerView start];
                                                         }];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 解析文字
- (void)parseResult:(NSString *)result {
    if ([result containsString:@"http"]) { // 如果是网页，就用浏览器打开
        NSURL *url = [NSURL URLWithString:result];
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [self showAlertWithTitle:@"扫描结果" value:result];
    }
    
    [self.readerView stop];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
