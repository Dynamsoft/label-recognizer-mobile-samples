//
//  ViewController.h
//  HelloWorldObjc
//
//  Created by dynamsoft on 2021/6/30.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) UIImagePickerController *imagePickerController;

@end

