//
//  DynamsoftLabelRecognizer sample
//
//  Copyright © 2021 Dynamsoft. All rights reserved.
//

#import "ViewController.h"
#import "LabelResultView.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <DynamsoftLabelRecognizer/DynamsoftLabelRecognizer.h>

@interface ViewController ()<UINavigationControllerDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, DLRLicenseVerificationDelegate>

@end

@implementation ViewController{
    DynamsoftLabelRecognizer *recognizer;
    UIButton *pickFileBtn;
    UIButton *pickPicBtn;
    NSInteger sourceType;
    LabelResultView *labelVC;
    UIActivityIndicatorView *loadingView;
    
    AVCaptureSession *session;
    AVCaptureDevice* inputDevice;
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureStillImageOutput *photoOutput;
    dispatch_queue_t sessionQueue;
    UIButton *photoButton;
    UIView *captureView;
    UIView *leadView;
    UIView *subLeadView;
    int orientationNum;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // The string "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" will grant you a public trial license good for 7 days. After that, please visit: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=code-gallery&package=ios to request for 30 days extension.
    [DynamsoftLabelRecognizer initLicense:@"DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" verificationDelegate:self];
    recognizer = [[DynamsoftLabelRecognizer alloc] init];
    
    [self DLRSettings];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopSession];
}

- (void)DLRSettings {
    NSArray* models = [NSArray arrayWithObjects:@"NumberUppercase",
                       @"NumberUppercase_Assist_1lIJ",
                       @"NumberUppercase_Assist_8B",
                       @"NumberUppercase_Assist_8BHR",
                       @"NumberUppercase_Assist_number",
                       @"NumberUppercase_Assist_O0DQ",
                       @"NumberUppercase_Assist_upcase",
                       nil];
    NSError* error = [[NSError alloc] init];
    for (NSString* model in models) {
        NSString* prototxt = [[NSBundle mainBundle] pathForResource:model ofType:@"prototxt"];
        NSData* datapro = [NSData dataWithContentsOfFile:prototxt];
        NSString* txt = [[NSBundle mainBundle] pathForResource:model ofType:@"txt"];
        NSData* datatxt = [NSData dataWithContentsOfFile:txt];
        NSString* caffemodel = [[NSBundle mainBundle] pathForResource:model ofType:@"caffemodel"];
        NSData* datacaf = [NSData dataWithContentsOfFile:caffemodel];
        [DynamsoftLabelRecognizer appendCharacterModel:model prototxtBuffer:datapro txtBuffer:datatxt characterModelBuffer:datacaf];
    }
    [recognizer appendSettingsFromFile:[[NSBundle mainBundle] pathForResource:@"wholeImgMRZTemplate" ofType:@"json"] error:&error];
    if (error.code != 0) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:error.userInfo options:0 error:0];
        NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self showResult:@"Error" msg:dataStr completion:^{
        }];
    }
}

- (void)setTextArea{
    iDLRRuntimeSettings* settings = [recognizer getRuntimeSettings:nil];
    settings.textArea = [self handleTextArea];
    [recognizer updateRuntimeSettings:settings error:nil];
}

- (iQuadrilateral*)handleTextArea {
    //When the phone screen is potrait, the vertex of the lower left corner is the origin of the coordinate system, the horizontal side is the y-axis, the vertical side is the x-axis. (0, 0):lower left corner of the screen;(100, 100):upper right corner of the screen.
    iQuadrilateral* qua = [[iQuadrilateral alloc] init];
    qua.points = [NSArray arrayWithObjects:
                  [NSNumber valueWithCGPoint:CGPointMake(0, 30)],
                  [NSNumber valueWithCGPoint:CGPointMake(100, 30)],
                  [NSNumber valueWithCGPoint:CGPointMake(100, 90)],
                  [NSNumber valueWithCGPoint:CGPointMake(0, 90)], nil];
    return qua;
}

- (void)DLRLicenseVerificationCallback:(bool)isSuccess error:(NSError *)error{
    NSString* msg = @"";
    NSString* title = @"Server license verify failed";
    if(error != nil)
    {
        if (error.code == -1009) {
            msg = @"Dynamsoft Label Recognizer is unable to connect to the public Internet to acquire a license. Please connect your device to the Internet or contact support@dynamsoft.com to acquire an offline license.";
            title = @"No Internet";
        }else{
            msg = error.userInfo[NSUnderlyingErrorKey];
            if(msg == nil)
            {
                msg = [error localizedDescription];
            }
        }
        [self showResult:title msg:msg completion:^{
            
        }];
    }
}

#pragma mark - doc pick
//ios 8 - 11
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url{
    [self recoByFile:url];
}

//ios 11 -
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        [self recoByFile:[urls lastObject]];
    }
}

- (void)recoByFile:(NSURL*)url{
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData: data];
    NSError* error = [[NSError alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->loadingView startAnimating];
    });
    NSArray<iDLRResult*>* results = [recognizer recognizeByFile:[url path] templateName:@"locr" error:&error];
    if (error.code != 0) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:error.userInfo options:0 error:0];
        NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self showResult:@"Error" msg:dataStr completion:^{
        }];
    }else{
        [self handleResults:results err:error img:image];
    }
}

- (void)pickFileClick{
    NSArray *types = @[@"public.content",
                       @"public.text",
                       @"public.data",
                       @"public.source-code",
                       @"public.image",
                       @"public.audiovisual-content",
                       @"com.adobe.pdf",
                       @"com.microsoft.word.doc"];
    UIDocumentPickerViewController *vc = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeImport];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - image pick

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    size_t bpr = CGImageGetBytesPerRow(image.CGImage);
    CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
    NSData* buffer = (__bridge_transfer NSData*)CGDataProviderCopyData(provider);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->loadingView startAnimating];
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError* error = [[NSError alloc] init];
        iImageData* data = [[iImageData alloc] init];
        data.bytes  = buffer;
        data.format = EnumImagePixelFormatARGB_8888;
        data.width  = width;
        data.height = height;
        data.stride = bpr;
        NSArray<iDLRResult*>* results = [self->recognizer recognizeByBuffer:data templateName:@"locr" error:&error];
        if (error.code != 0) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:error.userInfo options:0 error:0];
            NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self showResult:@"Error" msg:dataStr completion:^{
            }];
        }else{
            [self handleResults:results err:error img:image];
        }
    });
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleResults:(NSArray<iDLRResult*>*)results err:(NSError*)error img:(UIImage*)image{
    if (results.count > 0 && results.firstObject.lineResults.count == 2) {
        NSString* line1 = results.firstObject.lineResults[0].text ? results.firstObject.lineResults[0].text:@"";
        NSString* line2 = results.firstObject.lineResults[1].text ? results.firstObject.lineResults[1].text:@"";
        [self sendResult:line1 line2:line2 img:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->loadingView stopAnimating];
        });
    }else{
        NSString *msg = error.code == 0 ? @"" : error.userInfo[NSUnderlyingErrorKey];
        [self showResult:@"No result" msg:msg completion:^{
            [self->loadingView stopAnimating];
        }];
    }
}

- (void)sendResult:(NSString*)line1 line2:(NSString*)line2 img:(UIImage*)img{
    NSMutableArray* contentArr = [NSMutableArray arrayWithCapacity:1];
    [contentArr addObject:[line1 substringWithRange:NSMakeRange(2, 3)]];
    NSString *fullN = [line1 substringFromIndex:5];
    NSRange index = [fullN rangeOfString:@"<<"];
    NSString *surN = [[fullN substringToIndex:index.location] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
    [contentArr addObject:surN];
    NSString *givenN = [fullN substringFromIndex:index.location + 2];
    NSArray* givArr = [givenN componentsSeparatedByString:@"<"];
    NSMutableArray* tmp = [NSMutableArray arrayWithCapacity:1];
    for (NSString *item in givArr) {
        if (![item isEqualToString:@""]) {
            [tmp addObject:item];
        }
    }
    [contentArr addObject:[tmp componentsJoinedByString:@" "]];
    NSString *pattern2 = @"([A-Z0-9<]{9})[0-9]([A-Z]{3})([0-9]{2}[0-1][0-9][0-3][0-9])[0-9]([MF])([0-9]{2}[0-1][0-9][0-3][0-9])[0-9][A-Z0-9<]{14}[0-9][0-9]";
    NSRegularExpression* reg2 = [[NSRegularExpression alloc] initWithPattern:pattern2 options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> *matchs2 = [reg2 matchesInString:line2 options:NSMatchingReportProgress range:NSMakeRange(0, line2.length)];
    for (NSTextCheckingResult *match in matchs2) {
        for (int i = 1; i < [match numberOfRanges]; i++) {
            NSString *component = [line2 substringWithRange:[match rangeAtIndex:i]];
            [contentArr addObject:component];
        }
    }
    if (contentArr.count < 8) {
        [self showResult:@"No result" msg:@"" completion:^{
            [self->loadingView stopAnimating];
        }];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self->labelVC = [self.storyboard instantiateViewControllerWithIdentifier:@"LabelResultView"];
        self->labelVC.modalPresentationStyle = UIModalPresentationPageSheet;
        self->labelVC.recogImg = img;
        self->labelVC.contentArr = contentArr;
        [self presentViewController:self->labelVC animated:YES completion:nil];
    });
}

- (BOOL)prefersStatusBarHidden{
    CGFloat w = [[UIScreen mainScreen] bounds].size.width;
    CGFloat h = [[UIScreen mainScreen] bounds].size.height;
    if (w > h) {
        return YES;
    }
    return NO;
}

- (void)setupUI {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    sessionQueue = dispatch_queue_create("mrzQueue", NULL);
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    CGFloat w = [[UIScreen mainScreen] bounds].size.width;
    CGFloat h = [[UIScreen mainScreen] bounds].size.height;
    UIColor* co = [[UIColor alloc] initWithRed:254.0/255.0 green:142.0/255.0 blue:20.0/255.0 alpha:1.0];
    
    pickPicBtn = [[UIButton alloc] init];
    pickPicBtn.frame = CGRectMake(w / 6, h / 2 - 40, w * 2 / 3, 50);
    [pickPicBtn setTitleColor:co forState:UIControlStateNormal];
    [pickPicBtn setTitle:@"Select Picture" forState:UIControlStateNormal];
    [pickPicBtn addTarget:self action:@selector(pickPicClick) forControlEvents:UIControlEventTouchUpInside];
    pickPicBtn.layer.borderWidth = 1;
    pickPicBtn.layer.borderColor = co.CGColor;
    pickPicBtn.layer.cornerRadius = 6;
    pickFileBtn = [[UIButton alloc] init];
    pickFileBtn.frame = CGRectMake(w / 6, h / 2 + 40, w * 2 / 3, 50);
    [pickFileBtn setTitleColor:co forState:UIControlStateNormal];
    [pickFileBtn setTitle:@"Select File" forState:UIControlStateNormal];
    [pickFileBtn addTarget:self action:@selector(pickFileClick) forControlEvents:UIControlEventTouchUpInside];
    pickFileBtn.layer.borderWidth = 1;
    pickFileBtn.layer.borderColor = co.CGColor;
    pickFileBtn.layer.cornerRadius = 6;
    
    loadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    loadingView.center = self.view.center;
    [loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:pickFileBtn];
    [self.view addSubview:pickPicBtn];
    [self.view addSubview:loadingView];
}

- (void)pickPicClick{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *photoAlbumAction = [UIAlertAction actionWithTitle:@"PhotoLibrary" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self getAlertActionType:1];
    }];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //[self getAlertActionType:2];
        [self addCamera];
        [self addBack];
    }];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self getAlertActionType:0];
    }];
    [alertController addAction:photoAlbumAction];
    [alertController addAction:cancleAction];
    [self imagePickerControlerIsAvailabelToCamera] ? [alertController addAction:cameraAction]:nil;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)getAlertActionType:(NSInteger)type {
    NSInteger sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if (type == 1) {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }else if (type == 2) {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    [self creatUIImagePickerControllerWithAlertActionType:sourceType];
}

- (void)creatUIImagePickerControllerWithAlertActionType:(NSInteger)type {
    sourceType = type;
    NSInteger cameragranted = [self AVAuthorizationStatusIsGranted];
    if (cameragranted == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Tips"
                                                                                 message:@"Settings-Privacy-Camera/Album-Authorization"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *comfirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }];
        [alertController addAction:comfirmAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }else if (cameragranted == 1) {
        [self presentPickerViewController];
    }
}

- (BOOL)imagePickerControlerIsAvailabelToCamera {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (NSInteger)AVAuthorizationStatusIsGranted{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatusVideo = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    PHAuthorizationStatus authStatusAlbm  = [PHPhotoLibrary authorizationStatus];
    NSInteger authStatus = sourceType == UIImagePickerControllerSourceTypePhotoLibrary ? authStatusAlbm : authStatusVideo;
    switch (authStatus) {
        case 0: {
            if (sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (status == PHAuthorizationStatusAuthorized) {
                        [self presentPickerViewController];
                    }
                }];
            }else{
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        [self presentPickerViewController];
                    }
                }];
            }
        }
            return 2;
        case 1: return 0;
        case 2: return 0;
        case 3: return 1;
        default:return 0;
    }
}

- (void)presentPickerViewController{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        if (@available(iOS 11.0, *)){
            [[UIScrollView appearance] setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentAlways];
        }
        picker.delegate = self;
        picker.sourceType = self->sourceType;
        [self presentViewController:picker animated:YES completion:nil];
    });
}

- (void)showResult:(NSString *)title msg:(NSString *)msg completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    completion();
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)addBack{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(BackToHome)];
}

- (void)BackToHome{
    [self stopSession];
    self.navigationItem.leftBarButtonItem = nil;
}

- (void)handleOrientationDidChange{
    CGFloat w = [[UIScreen mainScreen] bounds].size.width;
    CGFloat h = [[UIScreen mainScreen] bounds].size.height;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect mainBounds = CGRectZero;
        AVCaptureVideoOrientation avOri = AVCaptureVideoOrientationPortrait;
        switch ([[UIApplication sharedApplication] statusBarOrientation]) {
            case UIInterfaceOrientationPortrait:
                mainBounds.size.width = MIN(h, w);
                mainBounds.size.height = MAX(h, w);
                avOri = AVCaptureVideoOrientationPortrait;
                self->orientationNum = 0;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                mainBounds.size.width = MIN(h, w);
                mainBounds.size.height = MAX(h, w);
                avOri = AVCaptureVideoOrientationPortraitUpsideDown;
                self->orientationNum = 3;
                break;
            case UIInterfaceOrientationLandscapeRight:
                mainBounds.size.width = MAX(h, w);
                mainBounds.size.height = MIN(h, w);
                avOri = AVCaptureVideoOrientationLandscapeRight;
                self->orientationNum = 2;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                mainBounds.size.width = MAX(h, w);
                mainBounds.size.height = MIN(h, w);
                avOri = AVCaptureVideoOrientationLandscapeLeft;
                self->orientationNum = 1;
                break;
            default:
                mainBounds.size.width = MIN(h, w);
                mainBounds.size.height = MAX(h, w);
                avOri = AVCaptureVideoOrientationPortrait;
                self->orientationNum = 0;
                break;
        }
        self->previewLayer.connection.videoOrientation = avOri;
        self->previewLayer.frame = mainBounds;
        self->captureView.frame = mainBounds;
        CGFloat SafeAreaBottomHeight = [[UIApplication sharedApplication] statusBarFrame].size.height > 20 ? 34 : 0;
        if (mainBounds.size.width > mainBounds.size.height) {
            self->leadView.frame = CGRectMake(100, 50, mainBounds.size.width - 200, mainBounds.size.height - 100);
            self->photoButton.frame = CGRectMake(mainBounds.size.width - 90, mainBounds.size.height / 2 - 39, 78, 78);
        }else{
            self->leadView.frame = CGRectMake(5, mainBounds.size.height / 3, mainBounds.size.width - 10, mainBounds.size.height / 3 + 30);
            self->photoButton.frame = CGRectMake(mainBounds.size.width / 2 - 39, mainBounds.size.height - 126 - SafeAreaBottomHeight, 78, 78);
        }
        self->subLeadView.frame = CGRectMake(0, self->leadView.bounds.size.height - 60, self->leadView.bounds.size.width, 60);
        self->loadingView.frame = CGRectMake(mainBounds.size.width / 2 - 25, mainBounds.size.height / 2 - 25, 50, 50);
        self->pickPicBtn.frame = CGRectMake(mainBounds.size.width / 6, mainBounds.size.height / 2 - 40, mainBounds.size.width * 2 / 3, 50);
        self->pickFileBtn.frame = CGRectMake(mainBounds.size.width / 6, mainBounds.size.height / 2 + 40, mainBounds.size.width * 2 / 3, 50);
    });
}

- (void)addCamera{
    [self setVideoSession];
    CGFloat w = [[UIScreen mainScreen] bounds].size.width;
    CGFloat h = [[UIScreen mainScreen] bounds].size.height;
    CGFloat SafeAreaBottomHeight = [[UIApplication sharedApplication] statusBarFrame].size.height > 20 ? 34 : 0;
    CGFloat tabH = [[UIApplication sharedApplication] statusBarFrame].size.height;
    UIColor *co = [[UIColor alloc] initWithRed:254.0/255.0 green:142.0/255.0 blue:20.0/255.0 alpha:1.0];
    previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    previewLayer.frame = CGRectMake(0, tabH, w, h - tabH);
    photoButton = [[UIButton alloc] initWithFrame:CGRectMake(w / 2 - 39, h - 126 - SafeAreaBottomHeight, 78, 78)];
    [photoButton setImage:[UIImage imageNamed:@"icon_capture"] forState:UIControlStateNormal];
    [photoButton addTarget:self action:@selector(takePictures) forControlEvents:UIControlEventTouchUpInside];
    leadView = [[UIView alloc] initWithFrame:CGRectMake(5, h / 3, w - 10, h / 3 + 30)];
    leadView.backgroundColor = UIColor.clearColor;
    leadView.layer.cornerRadius = 5;
    leadView.layer.borderWidth = 1;
    leadView.layer.borderColor = co.CGColor;
    subLeadView = [[UIView alloc] initWithFrame:CGRectMake(0, leadView.bounds.size.height - 60, leadView.bounds.size.width, 60)];
    subLeadView.backgroundColor = UIColor.clearColor;
    subLeadView.layer.cornerRadius = 5;
    subLeadView.layer.borderWidth = 1;
    subLeadView.layer.borderColor = co.CGColor;
    captureView = [[UIView alloc] initWithFrame:CGRectMake(0, tabH, w, h - tabH)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->leadView addSubview:self->subLeadView];
        [self->captureView.layer addSublayer:self->previewLayer];
        [self.view insertSubview:self->captureView belowSubview:self->loadingView];
        [self.view insertSubview:self->leadView belowSubview:self->loadingView];
        [self.view addSubview:self->photoButton];
    });
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            [self startSession];
        }
    }];
}

- (void)takePictures{
    AVCaptureConnection *videoConnect = [photoOutput connectionWithMediaType:AVMediaTypeVideo];
    if (videoConnect == nil) {
        [photoButton setEnabled:true];
        return;
    }
    [photoOutput captureStillImageAsynchronouslyFromConnection:videoConnect completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        if (imageDataSampleBuffer == nil) {
            [self->photoButton setEnabled:true];
            return;
        }
        NSData *imgData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = nil;
        if (self->orientationNum == 2) {
            image = [UIImage imageWithData:imgData];
        }else{
            image = [self imageWithRightOrientation:[UIImage imageWithData:imgData]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->loadingView startAnimating];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError* error = [[NSError alloc] init];
            NSArray<iDLRResult*>* results = [self->recognizer recognizeByImage:image templateName:@"locr" error:&error];
            if (error.code != 0) {
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:error.userInfo options:0 error:0];
                NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self showResult:@"Error" msg:dataStr completion:^{
                }];
            }else{
                [self handleResults:results err:error img:image];
            }
        });
    }];
}

#pragma mark - take photo
- (void)setVideoSession{
    inputDevice = [self getAvailableCamera];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
                                          deviceInputWithDevice:inputDevice
                                          error:nil];
    if ([inputDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *error = nil;
        if ([inputDevice lockForConfiguration:&error]) {
            inputDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [inputDevice unlockForConfiguration];
        }
    }
    if([inputDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] &&
       inputDevice.autoFocusRangeRestrictionSupported) {
        if([inputDevice lockForConfiguration:nil]) {
            inputDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
            [inputDevice unlockForConfiguration];
        }
    }
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    [captureOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    if(captureInput == nil || captureOutput == nil) return;
    
    session = [[AVCaptureSession alloc] init];
    photoOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([session canAddInput:captureInput]) [session addInput:captureInput];
    if ([session canAddOutput:captureOutput]) [session addOutput:captureOutput];
    if ([session canAddOutput:photoOutput]) [session addOutput:photoOutput];
    else if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]){
        [session setSessionPreset :AVCaptureSessionPreset1280x720];
    }
}

- (void)startSession{
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
    dispatch_async(sessionQueue, ^{
        if (!self->session.isRunning) [self->session startRunning];
    });
}

- (void)stopSession{
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
    dispatch_async(sessionQueue, ^{
        if (self->session.isRunning) [self->session stopRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->previewLayer) [self->previewLayer removeFromSuperlayer];
            [self->photoButton removeFromSuperview];
            [self->leadView removeFromSuperview];
            [self->captureView removeFromSuperview];
        });
        for (AVCaptureInput *input in self->session.inputs) {
            [self->session removeInput:input];
        }
        for (AVCaptureOutput *output in self->session.outputs) {
            [self->session removeOutput:output];
        }
        self->inputDevice = nil;
    });
}

- (AVCaptureDevice *)getAvailableCamera{
#if TARGET_IPHONE_SIMULATOR
    return nil;
#endif
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == AVCaptureDevicePositionBack) {
            captureDevice = device;
            break;
        }
    }
    if (!captureDevice) captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    return captureDevice;
}

- (UIImage *)imageWithRightOrientation:(UIImage *)aImage {
    if (aImage.imageOrientation == UIImageOrientationUp) return aImage;
     
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (aImage.imageOrientation) {
       case UIImageOrientationLeft:
       case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
       case UIImageOrientationRight:
       case UIImageOrientationRightMirrored:
            if(orientationNum == 1){
                transform = CGAffineTransformTranslate(transform, aImage.size.height, aImage.size.width);
                transform = CGAffineTransformRotate(transform, -M_PI);
            } else{
                transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
                transform = CGAffineTransformRotate(transform, -M_PI_2);
            }
            break;
       default:
            break;
    }
    switch (aImage.imageOrientation) {
       case UIImageOrientationUpMirrored:
       case UIImageOrientationDownMirrored:
           transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
           transform = CGAffineTransformScale(transform, -1, 1);
           break;
             
       case UIImageOrientationLeftMirrored:
       case UIImageOrientationRightMirrored:
           transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
           transform = CGAffineTransformScale(transform, -1, 1);
           break;
       default:
           break;
    }
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = nil;
    if (orientationNum == 1) {
        ctx = CGBitmapContextCreate(NULL, aImage.size.height, aImage.size.width,
                                    CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                    CGImageGetColorSpace(aImage.CGImage),
                                    CGImageGetBitmapInfo(aImage.CGImage));
    }else{
        ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                         CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                         CGImageGetColorSpace(aImage.CGImage),
                                         CGImageGetBitmapInfo(aImage.CGImage));
    }
    
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
@end
