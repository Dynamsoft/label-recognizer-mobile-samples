//
//  DLRResultView.h
//  HelloWorldObjC
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DLRResultView : UIView

- (void)updateUIWithResult:(NSArray<iDLRResult *> *)results;

@end

NS_ASSUME_NONNULL_END
