//
//  DLRResultView.m
//  HelloWorldObjC
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

#import "DLRResultView.h"

@interface DLRResultView ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *resultTableView;

@property (nonatomic, strong) NSMutableArray *resultDataArray;

@end

@implementation DLRResultView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 2.0f;
    [self addSubview:self.resultTableView];
}

- (void)updateUIWithResult:(NSArray<iDLRResult *> *)results {
    [self.resultDataArray removeAllObjects];
    int index = 0;
    for (iDLRResult *dlrResult in results) {
        for (iDLRLineResult *lineDlrResult in dlrResult.lineResults) {
            index++;
            [self.resultDataArray addObject:[NSString stringWithFormat:@"Result %d:%@", index, lineDlrResult.text]];
        }
    }
    [self.resultTableView reloadData];
}

// MARK: - TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultDataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [DLRResultTableViewCell cellHeightWithString:self.resultDataArray[indexPath.row]];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 40)];
    UILabel *resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(kComponentLeftMargin, 0, headerView.bounds.size.width - kComponentLeftMargin, 40)];
    resultLabel.backgroundColor = [UIColor clearColor];
    resultLabel.text = @"Results";
    resultLabel.textColor = [UIColor whiteColor];
    resultLabel.font = [UIFont systemFontOfSize:20];
    [headerView addSubview:resultLabel];
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"DLRResultCell";
    DLRResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[DLRResultTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    [cell updateUIWithString:self.resultDataArray[indexPath.row]];
    return cell;
}

// MARK: - Lazy
- (UITableView *)resultTableView {
    if (!_resultTableView) {
        _resultTableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        _resultTableView.backgroundColor = [UIColor clearColor];
        _resultTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _resultTableView.delegate = self;
        _resultTableView.dataSource = self;
    }
    return _resultTableView;
}

- (NSMutableArray *)resultDataArray {
    if (!_resultDataArray) {
        _resultDataArray = [NSMutableArray array];
    }
    return _resultDataArray;
}

@end
