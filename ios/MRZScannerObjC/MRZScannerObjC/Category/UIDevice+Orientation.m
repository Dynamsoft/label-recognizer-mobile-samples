//
//  UIDevice+Orientation.m
//  MRZScannerObjC
//
//  Created by Dynamsoft's mac on 2022/9/13.
//

#import "UIDevice+Orientation.h"

@implementation UIDevice (Orientation)

+ (void)setOrientation:(UIInterfaceOrientation)orientation {
    SEL selector = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[self currentDevice]];
    int val = (int)orientation;
    [invocation setArgument:&val atIndex:2];
    [invocation invoke];
}

@end
