/*
 * This is the sample of Dynamsoft Label Recognizer.
 *
 * Copyright © Dynamsoft Corporation.  All rights reserved.
 */

#import "ViewController.h"
#import <DynamsoftCaptureVisionRouter/DynamsoftCaptureVisionRouter.h>
#import <DynamsoftLabelRecognizer/DynamsoftLabelRecognizer.h>
#import <DynamsoftCameraEnhancer/DynamsoftCameraEnhancer.h>

#define weakSelfs(self) __weak typeof(self) weakSelf = self;

typedef void (^ConfirmCompletion)(void);

@interface ViewController ()<DSCapturedResultReceiver>

@property (nonatomic, strong) DSCaptureVisionRouter *cvr;

@property (nonatomic, strong) DSCameraEnhancer *dce;

@property (nonatomic, strong) DSCameraView *dceView;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    weakSelfs(self)
    [self.cvr startCapturing:DSPresetTemplateRecognizeTextLines completionHandler:^(BOOL isSuccess, NSError * _Nullable error) {
        if (error != nil) {
            [weakSelf displayError:error.localizedDescription completion:nil];
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self configureCVR];
    [self configureDCE];
}

- (void)configureCVR {
    _cvr = [[DSCaptureVisionRouter alloc] init];
    [_cvr addResultReceiver:self];
}

- (void)configureDCE {
    _dceView = [[DSCameraView alloc] initWithFrame:self.view.bounds];
    _dceView.scanLaserVisible = YES;
    [self.view addSubview:_dceView];
    
    DSDrawingLayer *dlrDrawingLayer = [_dceView getDrawingLayer:DSDrawingLayerIdDLR];
    dlrDrawingLayer.visible = YES;
    
    _dce = [[DSCameraEnhancer alloc] initWithView:_dceView];
    [_dce open];
    
    // ScanRegion.
    DSRect *region = [[DSRect alloc] init];
    region.top = 0.4;
    region.bottom = 0.6;
    region.left = 0.1;
    region.right = 0.9;
    region.measuredInPercentage = YES;
    [_dce setScanRegion:region error:nil];
    
    // CVR link DCE.
    [_cvr setInput:_dce error:nil];
}

// MARK: - CapturedResultReceiver
- (void)onRecognizedTextLinesReceived:(DSRecognizedTextLinesResult *)result {
    if (result.items != nil) {
        [self.cvr stopCapturing];
        [DSFeedback vibrate];
        [DSFeedback beep];
        
        // Parse results.
        int index = 0;
        NSMutableString *resultText = [NSMutableString string];
        for (DSTextLineResultItem *dlrLineResults in result.items) {
            index++;
            [resultText appendString:[NSString stringWithFormat:@"Result %d:%@\n", index, dlrLineResults.text != nil ? dlrLineResults.text : @""]];
        }
        
        weakSelfs(self)
        [self displaySingleResult:[NSString stringWithFormat:@"Results(%ld)", result.items.count] msg:resultText acTitle:@"OK" completion:^{
            [weakSelf.cvr startCapturing:DSPresetTemplateRecognizeTextLines completionHandler:nil];
        }];
    }
}

- (void)displaySingleResult:(NSString *)title msg:(NSString *)msg acTitle:(NSString *)acTitle
                 completion:(nullable ConfirmCompletion)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:acTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (completion) completion();
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)displayError:(NSString *)msg completion:(nullable ConfirmCompletion)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (completion) completion();
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
