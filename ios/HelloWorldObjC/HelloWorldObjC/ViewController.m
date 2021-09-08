#import "ViewController.h"

#import <DynamsoftLabelRecognizer/DynamsoftLabelRecognizer.h>

@interface ViewController ()<DLRLicenseVerificationDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end

@implementation ViewController{
    DynamsoftLabelRecognizer *dlr;
    UIImage* img;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 1.Initialize license.
    // The string "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" here is a 7-day free license. Note that network connection is required for this license to work.
    // If you want to use an offline license, please contact Dynamsoft Support: https://www.dynamsoft.com/company/contact/
    // You can also request a 30-day trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=github&package=ios
    [DynamsoftLabelRecognizer initLicense:@"DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" verificationDelegate:self];
    
    // 2.Create an instance of Label Recognizer.
    dlr = [[DynamsoftLabelRecognizer alloc] init];

}

- (IBAction)onClickTakePhoto:(id)sender {
    self.imagePickerController = [[UIImagePickerController alloc]init];
    
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    
    self.imagePickerController.delegate = self;
    
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *) picker
    didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *) info{
    [picker dismissViewControllerAnimated:YES completion:nil];

    img = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.imgView.image = img;
}

- (IBAction)onRecognizeText:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self recognizeText];
    });
}

- (void)recognizeText{
    NSError* error = [[NSError alloc] init];
    
    // 3.Recognize text from an image.
    NSArray<iDLRResult*>* results = [self->dlr recognizeByImage:img templateName:@"" error:&error];
    
    if (error.code != 0) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:error.userInfo options:0 error:0];
        NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self showResults:@"Error" msgText:dataStr];
    }else{
        NSString* msgText = @"";
        
        // 4. Get all recognized results.
        if (results.count > 0) {
            for (NSInteger i = 0; i < [results count]; i++) {
                for (iDLRLineResult* lineResult in results[i].lineResults) {
                    msgText = [msgText stringByAppendingString:[NSString stringWithFormat:@"\nValue: %@\n",lineResult.text]];
                }
            }
        }else{
            msgText = @"No data detected.";
        }
        [self showResults:@"Results" msgText:msgText];
    }
}

- (void)showResults:(NSString *)title msgText:(NSString*)msgText{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msgText preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });

}

- (void)DLRLicenseVerificationCallback:(bool)isSuccess error:(NSError *)error {
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
        [self showResults:title msgText:msg];
    }
}

@end

