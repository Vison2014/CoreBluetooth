//
//  MBProgressHUD+Extension.h
//
//  Created by 李文深 on 16/3/22.
//  Copyright © 2016年 30pay. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (Extension)
+ (void)showSuccess:(NSString *)success toView:(UIView *)view;
+ (void)showError:(NSString *)error toView:(UIView *)view;

+ (MBProgressHUD *)showMessage:(NSString *)message toView:(UIView *)view;


+ (void)showSuccess:(NSString *)success;
+ (void)showError:(NSString *)error;

+ (MBProgressHUD *)showMessage:(NSString *)message;

+ (void)hideHUDForView:(UIView *)view;
+ (void)hideHUD;

@end
