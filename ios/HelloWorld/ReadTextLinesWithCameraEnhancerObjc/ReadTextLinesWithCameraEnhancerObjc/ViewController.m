/*
 * This is the sample of Dynamsoft Label Recognizer.
 *
 * Copyright © Dynamsoft Corporation.  All rights reserved.
 */

#import "ViewController.h"
#import <DynamsoftCaptureVisionRouter/DynamsoftCaptureVisionRouter.h>
#import <DynamsoftLabelRecognizer/DynamsoftLabelRecognizer.h>
#import <DynamsoftCameraEnhancer/DynamsoftCameraEnhancer.h>
#import <DynamsoftUtility/DynamsoftUtility.h>

#define weakSelfs(self) __weak typeof(self) weakSelf = self;

typedef void (^ConfirmCompletion)(void);

@interface ViewController ()<DSCapturedResultReceiver>

@property (nonatomic, strong) DSCaptureVisionRouter *cvr;

@property (nonatomic, strong) DSCameraEnhancer *dce;

@property (nonatomic, strong) DSCameraView *dceView;

@property (nonatomic, strong) DSMultiFrameResultCrossFilter *resultFilter;

@property (nonatomic, strong) UITextView *resultView;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    weakSelfs(self)
    // Start capturing by specifying the preset template, PT_RECOGNIZE_TEXT_LINES.
    // There will be a callback when the capture start succeed or failed.
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
    [self setupUI];
}

- (void)configureCVR {
    // Create an instance of Dynamsoft Capture Vision Router (CVR).  The CVR instance will responsible for retrieving images and dispatch results.
    _cvr = [[DSCaptureVisionRouter alloc] init];
    // The CapturedResultReceiver interface provides methods for monitoring the output of captured results. 
    // The CapturedResultReceiver can add a receiver for any type of captured result or for a specific type of captured result, based on the method that is implemented.	
    [_cvr addResultReceiver:self];
    
    // Add filter.
    _resultFilter = [[DSMultiFrameResultCrossFilter alloc] init];
    [_resultFilter enableResultCrossVerification:DSCapturedResultItemTypeTextLine isEnabled:YES];
    [_cvr addResultFilter:_resultFilter];
}

- (void)configureDCE {
    // Add camera view for previewing video.
    _dceView = [[DSCameraView alloc] initWithFrame:self.view.bounds];
    //Add a scan laser on the view.
    _dceView.scanLaserVisible = YES;
    [self.view addSubview:_dceView];
    
    // Get the layer of DLR and set the visible property to true.
    DSDrawingLayer *dlrDrawingLayer = [_dceView getDrawingLayer:DSDrawingLayerIdDLR];
    dlrDrawingLayer.visible = YES;

    // Create an instance of Dynamsoft Camera Enhancer for video streaming.
    _dce = [[DSCameraEnhancer alloc] initWithView:_dceView];
    [_dce open];
    
    // Set a scan region for the text line recognition.
    DSRect *region = [[DSRect alloc] init];
    region.top = 0.4;
    region.bottom = 0.6;
    region.left = 0.1;
    region.right = 0.9;
    region.measuredInPercentage = YES;
    [_dce setScanRegion:region error:nil];
    
    // Set camera enhance as the video input.
    [_cvr setInput:_dce error:nil];
}

- (void)setupUI {
    [self.view addSubview:self.resultView];
}

// Implement this method to receive RecognizedTextLinesResult.
- (void)onRecognizedTextLinesReceived:(DSRecognizedTextLinesResult *)result {
    if (result.items != nil) {
        // Extract the content of the results.
        int index = 0;
        NSMutableString *resultText = [NSMutableString string];
        for (DSTextLineResultItem *dlrLineResults in result.items) {
            index++;
            [resultText appendString:[NSString stringWithFormat:@"Result %d:%@\n", index, dlrLineResults.text != nil ? dlrLineResults.text : @""]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resultView.text = [NSString stringWithFormat:@"Results(%d)\n%@", (int)result.items.count, resultText];
        });
    }
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
// Configure the text view for displaying the text line recognition results.
- (UITextView *)resultView {
    if (!_resultView) {
        CGFloat left = 0.0;
        CGFloat width = self.view.bounds.size.width;
        CGFloat height = self.view.bounds.size.height / 2.5;
        CGFloat top = self.view.bounds.size.height - height;
        _resultView = [[UITextView alloc] initWithFrame:CGRectMake(left, top, width, height)];
        _resultView.layer.backgroundColor = [UIColor clearColor].CGColor;
        _resultView.layoutManager.allowsNonContiguousLayout = NO;
        _resultView.userInteractionEnabled = NO;
        _resultView.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        _resultView.textColor = [UIColor whiteColor];
        _resultView.textAlignment = NSTextAlignmentCenter;
    }
    return _resultView;
}

@end
