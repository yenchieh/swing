//
//  LoginViewController.m
//  Swing
//
//  Created by 刘武忠 on 16/7/17.
//  Copyright © 2016年 zzteam. All rights reserved.
//

#import "LoginViewController.h"
#import "CommonDef.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.emailTextField setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [self.pwdTextField setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];

    self.emailTextField.delegate = self;
    self.pwdTextField.delegate = self;
    
    self.emailTextField.text = @"123@qq.com";
    self.pwdTextField.text = @"111111";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)validateTextField {
    if (self.emailTextField.text.length == 0 || self.pwdTextField.text.length == 0) {
        [Fun showMessageBoxWithTitle:@"Error" andMessage:@"Please input info."];
        return NO;
    }
    if (![Fun isValidateEmail:self.emailTextField.text]) {
        [Fun showMessageBoxWithTitle:@"Error" andMessage:@"Email is invalid."];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.pwdTextField becomeFirstResponder];
    }
    else if (textField == self.pwdTextField) {
        [textField resignFirstResponder];
        
        if ([self validateTextField]) {
            [SVProgressHUD showWithStatus:@"Please wait..."];
            [[SwingClient sharedClient] isEmailRegistered:textField.text completion:^(NSNumber *result, NSError *error) {
                if (!error) {
                    LOG_D(@"isEmailRegistered success: %@", result);
                    if (![result boolValue]) {
                        [SVProgressHUD showSuccessWithStatus:@"The email is not registered"];
                        //Go to register
                        UIStoryboard *stroyBoard=[UIStoryboard storyboardWithName:@"LoginFlow" bundle:nil];
                        UIViewController *ctl = [stroyBoard instantiateViewControllerWithIdentifier:@"Register"];
                        [self.navigationController pushViewController:ctl animated:YES];
                    }
                    else {
                        [SVProgressHUD showWithStatus:@"Login, please wait..."];
                        [[SwingClient sharedClient] login:self.emailTextField.text password:self.pwdTextField.text completion:^(NSNumber *result, NSError *error) {
                            if (!error) {
                                //Login success
                                [SVProgressHUD dismiss];
                                
                            }
                            else {
                                LOG_D(@"login fail: %@", error);
                                [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                            }
                        }];
                    }
                }
                else {
                    LOG_D(@"isEmailRegistered fail: %@", error);
                    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                }
            }];
        }
    }
    return YES;
}

- (void)doneAction {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
