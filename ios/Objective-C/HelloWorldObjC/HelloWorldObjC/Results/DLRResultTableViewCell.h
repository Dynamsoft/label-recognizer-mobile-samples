//
//  DLRResultTableViewCell.h
//  HelloWorldObjC
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DLRResultTableViewCell : UITableViewCell

- (void)updateUIWithString:(NSString *)resultString;

+ (CGFloat)cellHeightWithString:(NSString *)resultString;

@end

NS_ASSUME_NONNULL_END
