//
//  ViewController.m
//  HelloWorldObjC
//
//  Created by Dynamsoft's mac on 2022/9/8.
//

#import "ViewController.h"
#import <DynamsoftCameraEnhancer/DynamsoftCameraEnhancer.h>
#import <DynamsoftLabelRecognizer/DynamsoftLabelRecognizer.h>

@interface ViewController ()<LabelResultListener>

@property (nonatomic, strong) DynamsoftLabelRecognizer *labelRecognizer;

@property (nonatomic, strong) DynamsoftCameraEnhancer *cameraEnhancer;

@property (nonatomic, strong) DCECameraView *dceView;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:59.003/255.0 green:61.9991/255.0 blue:69.0028/255.0 alpha:1]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"DynamsoftLabelRecognizer";
    
    [self configureDLR];
}

- (void)configureDLR {
    self.labelRecognizer = [[DynamsoftLabelRecognizer alloc] init];
    
    iDLRRuntimeSettings *dlrRuntimeSettings = [self.labelRecognizer getRuntimeSettings:nil];
    NSError *updateError = nil;
    [self.labelRecognizer updateRuntimeSettings:dlrRuntimeSettings error:&updateError];
    
    self.dceView = [[DCECameraView alloc] initWithFrame:self.view.bounds];
    self.cameraEnhancer = [[DynamsoftCameraEnhancer alloc] initWithView:self.dceView];
    [self.view addSubview:self.dceView];
    [self.cameraEnhancer open];
    
    [self.labelRecognizer setImageSource:self.cameraEnhancer];
    [self.labelRecognizer setLabelResultListener:self];
    [self.labelRecognizer startScanning];
    
    iRegionDefinition *region = [[iRegionDefinition alloc] init];
    region.regionLeft = 5;
    region.regionRight = 95;
    region.regionTop = 30;
    region.regionBottom = 50;
    region.regionMeasuredByPercentage = 1;
    [self.cameraEnhancer setScanRegion:region error:nil];
}


// MARK: - LabelResultListener
- (void)labelResultCallback:(NSInteger)frameId imageData:(iImageData *)imageData results:(NSArray<iDLRResult *> *)results {
    if (results.count > 0) {
        [self.labelRecognizer stopScanning];
        
        NSMutableString *msgString = [NSMutableString string];
        int index = 0;
        for (iDLRResult *dlrResult in results) {
            for (iDLRLineResult *lineResult in dlrResult.lineResults) {
                index++;
                [msgString appendString:[NSString stringWithFormat:@"Result %d:%@\n", index, lineResult.text]];
            }
           
        }
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Results" message:msgString preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.labelRecognizer startScanning];
        }];
        [alertVC addAction:okAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertVC animated:YES completion:nil];
        });
    }
}

@end
