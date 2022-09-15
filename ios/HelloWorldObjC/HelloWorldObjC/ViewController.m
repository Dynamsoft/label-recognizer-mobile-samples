//
//  ViewController.m
//  HelloWorldObjC
//
//  Created by Dynamsoft's mac on 2022/9/8.
//

#import "ViewController.h"

@interface ViewController ()<LabelResultListener>

@property (nonatomic, strong) DynamsoftLabelRecognizer *labelRecognizer;

@property (nonatomic, strong) DynamsoftCameraEnhancer *cameraEnhancer;

@property (nonatomic, strong) DCECameraView *dceView;

@property (nonatomic, strong) DLRResultView *dlrResultView;

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
    [self setupUI];
}

- (void)configureDLR {
    self.labelRecognizer = [[DynamsoftLabelRecognizer alloc] init];
    
    iDLRRuntimeSettings *dlrRuntimeSettings = [self.labelRecognizer getRuntimeSettings:nil];
    dlrRuntimeSettings.textArea = [self handleTextArea];
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

- (void)setupUI {
    [self.view addSubview:self.dlrResultView];
}

- (iQuadrilateral*)handleTextArea {
    iQuadrilateral* qua = [[iQuadrilateral alloc] init];
    qua.points = [NSArray arrayWithObjects:
                  [NSNumber valueWithCGPoint:CGPointMake(0, 100)],
                  [NSNumber valueWithCGPoint:CGPointMake(0, 0)],
                  [NSNumber valueWithCGPoint:CGPointMake(100, 0)],
                  [NSNumber valueWithCGPoint:CGPointMake(100, 100)], nil];
    return qua;
}

// MARK: - LabelResultListener
- (void)labelResultCallback:(NSInteger)frameId imageData:(iImageData *)imageData results:(NSArray<iDLRResult *> *)results {

    if (results.count > 0) {
        [self.dlrResultView updateUIWithResult:results];
    }
}

// MARK: - Lazy
- (DLRResultView *)dlrResultView {
    if (!_dlrResultView) {
        _dlrResultView = [[DLRResultView alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height * 0.55 , self.view.bounds.size.width - 40, self.view.bounds.size.height * 0.45 - 34)];
    }
    return _dlrResultView;
}

@end
