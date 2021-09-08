//
//  LabelResultView.m
//  PassportMRZReadingObjC
//
//  Copyright © 2021 dynamsoft. All rights reserved.
//

#import "LabelResultView.h"

@interface LabelResultView ()<UITableViewDelegate, UITableViewDataSource>

@end

@implementation LabelResultView{
    UITableView* resTableview;
    UIImageView* resImageview;
    UILabel* tipsImage;
    UILabel* tipsTry;
    UILabel* titleLabel;
    UIView* backView;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    CGFloat h = self.view.bounds.size.height;
    CGFloat w = self.view.bounds.size.width;
    CGFloat tabH = self.tabBarController.tabBar.bounds.size.height + 64;
    resImageview = [[UIImageView alloc] initWithFrame:CGRectMake(w / 6, tabH, w * 2 / 3, h / 3)];
    [resImageview setImage:_recogImg];
    if (_recogImg.imageOrientation == UIImageOrientationRight) {
        CGAffineTransform transform = CGAffineTransformIdentity;
        resImageview.transform = CGAffineTransformRotate(transform, -M_PI_2);
        resImageview.frame = CGRectMake(w / 6, tabH, w * 2 / 3, h / 3);
    }
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, tabH - 40, w * 2 / 3, 40)];
    titleLabel.text = @"PassportMRZReading";
    titleLabel.textColor = UIColor.blackColor;
    [titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    
    backView = [[UIView alloc] initWithFrame:CGRectMake(w - 60, tabH - 40, 40, 40)];
    UIImage* bg = [UIImage imageNamed:@"close"];
    [backView layer].contents = (id)bg.CGImage;
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(back)];
    [backView addGestureRecognizer:gr];
    
    tipsImage = [[UILabel alloc] initWithFrame:CGRectMake(0, h / 3 + tabH, w, 30)];
    tipsImage.textColor = UIColor.blackColor;
    tipsImage.text = @"Capture passport Image";
    tipsImage.textAlignment = NSTextAlignmentCenter;
    tipsTry = [[UILabel alloc] initWithFrame:CGRectMake(self.view.center.x - 40, h / 3 + tabH + 30, 80, 30)];
    tipsTry.textColor = UIColor.blackColor;
    NSDictionary *attribtDic = @{NSUnderlineStyleAttributeName : [NSNumber numberWithInteger:NSUnderlineStyleSingle], NSUnderlineColorAttributeName : [UIColor blackColor]};
    NSMutableAttributedString *attribtStr = [[NSMutableAttributedString alloc]initWithString:@"Try it out" attributes:attribtDic];
    tipsTry.attributedText = attribtStr;
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(Click)];
    [tipsTry addGestureRecognizer:gestureRecognizer];
    tipsTry.userInteractionEnabled = YES;
    
    resTableview = [[UITableView alloc] initWithFrame:CGRectMake(5, h / 3 + tabH + 60, w - 10, h / 2 - 64) style:UITableViewStylePlain];
    resTableview.delegate = self;
    resTableview.dataSource = self;
    resTableview.separatorColor = UIColor.grayColor;
    resTableview.userInteractionEnabled = YES;
    [self.view addSubview:titleLabel];
    [self.view addSubview:backView];
    [self.view addSubview:resImageview];
    [self.view addSubview:tipsImage];
    [self.view addSubview:resTableview];
}

- (void)back{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)Click{
    //try it out
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)addCell:(UITableViewCell*)cell txt:(NSString*)txt{
    CGSize size = CGSizeMake(100, 40);
    CGFloat tablex = resTableview.frame.origin.x + resTableview.frame.size.width;
    UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(tablex - size.width, 40 - size.height / 2, 100, 40)];
    lb.textColor = UIColor.grayColor;
    lb.text = txt;
    lb.font = [UIFont boldSystemFontOfSize:18];
    lb.textAlignment = NSTextAlignmentCenter;
    CGSize sizeNew = [lb.text sizeWithAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:18]}];
    lb.frame = CGRectMake(tablex - sizeNew.width - 15, 40 - sizeNew.height / 2, sizeNew.width, sizeNew.height);
    [cell.contentView addSubview:lb];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mrz"];
    for (UIView* v  in cell.contentView.subviews) {
        [v removeFromSuperview];
    }
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"mrz"];
    }
    NSString* title = @"";
    switch (indexPath.row) {
        case 0:
            title = @"SURNAME";
            [self addCell:cell txt:_contentArr[1]];
            break;
        case 1:
            title = @"GIVEN NAMES";
            [self addCell:cell txt:_contentArr[2]];
            break;
        case 2:
            title = @"NATIONALITY";
            [self addCell:cell txt:_contentArr[0]];
            break;
        case 3:
            title = @"SEX/GENDER";
            [self addCell:cell txt:_contentArr[6]];
            break;
        case 4:
            title = @"DATE OF BIRTH";
            [self addCell:cell txt:[self getDate:_contentArr[5]]];
            break;
        case 5:
            title = @"ISSUING COUNTRY";
            [self addCell:cell txt:_contentArr[4]];
            break;
        case 6:
            title = @"PASSPORT NUMBER";
            [self addCell:cell txt:_contentArr[3]];
            break;
        case 7:
            title = @"PASSPORT EXPIRATION";
            [self addCell:cell txt:[self getDate:_contentArr[7]]];
            break;
        default:
            break;
    }
    cell.textLabel.text = title;
    cell.textLabel.font = [UIFont italicSystemFontOfSize:16];
    return cell;
}

- (NSString*)getDate:(NSString*)str{
    int mm = [[str substringWithRange:NSMakeRange(2, 2)] intValue];
    NSArray* vals = [NSArray arrayWithObjects:@"Jan",@"Feb",@"Mar",@"Apr",@"May",@"Jun",@"Jul",@"Aug",@"Sep",@"Oct",@"Nov",@"Dec", nil];
    NSString* year = [str substringWithRange:NSMakeRange(0, 2)];
    NSString* day = [str substringWithRange:NSMakeRange(4, 2)];
    NSString* mo = vals[mm - 1];
    NSString* ret = [[day stringByAppendingFormat:@" %@",mo] stringByAppendingFormat:@" %@",year];
    return ret;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 8;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    CGFloat w = size.width;
    CGFloat h = size.height;
    CGFloat tabH = self.tabBarController.tabBar.bounds.size.height + 64;
    resImageview.frame = CGRectMake(w / 6, tabH, w * 2 / 3, h / 3);
    if (_recogImg.imageOrientation == UIImageOrientationRight) {
        CGAffineTransform transform = CGAffineTransformIdentity;
        resImageview.transform = CGAffineTransformRotate(transform, -M_PI_2);
        resImageview.frame = CGRectMake(w / 6, tabH, w * 2 / 3, h / 3);
    }
    titleLabel.frame = CGRectMake(0, tabH - 40, w * 2 / 3, 40);
    backView.frame = CGRectMake(w - 60, tabH - 40, 40, 40);
    tipsImage.frame = CGRectMake(0, h / 3 + tabH, w, 30);
    resTableview.frame = CGRectMake(5, h / 3 + tabH + 60, w - 10, h / 2 - 64);
    [resTableview reloadData];
}

@end
