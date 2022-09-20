//
//  DLRResultTableViewCell.m
//  HelloWorldObjC
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

#import "DLRResultTableViewCell.h"

@interface DLRResultTableViewCell ()

@property (nonatomic, strong) UILabel *resultLabel;

@end

@implementation DLRResultTableViewCell

+ (CGFloat)cellHeightWithString:(NSString *)resultString {
    return [[DynamsoftToolsManager manager] calculateHeightWithText:resultString font:[UIFont systemFontOfSize:KDLRResultTextFont] AndComponentWidth:KDLRResultTextWidth] + 10;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    
    [self addSubview:self.resultLabel];
}

- (void)updateUIWithString:(NSString *)resultString {
    self.resultLabel.text = resultString;
    self.resultLabel.height = [[DynamsoftToolsManager manager] calculateHeightWithText:resultString font:[UIFont systemFontOfSize:KDLRResultTextFont] AndComponentWidth:KDLRResultTextWidth];
}

// MARK: - Lazy
- (UILabel *)resultLabel {
    if (!_resultLabel) {
        _resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(kComponentLeftMargin, 0, KDLRResultTextWidth, 0)];
        _resultLabel.textColor = [UIColor whiteColor];
        _resultLabel.font = [UIFont systemFontOfSize:KDLRResultTextFont];
        _resultLabel.numberOfLines = 0;
    }
    return _resultLabel;
}

@end
