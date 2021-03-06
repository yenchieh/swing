//
//  KidBindViewController.m
//  Swing
//
//  Created by Mapple on 16/7/26.
//  Copyright © 2016年 zzteam. All rights reserved.
//

#import "KidBindViewController.h"
#import "VPImageCropperViewController.h"
#import "CommonDef.h"
#import "BindReadyViewController.h"
#import "EditProfileViewController.h"
#import "SyncDeviceViewController.h"

@interface KidBindViewController ()<UITextFieldDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, VPImageCropperDelegate>
{
    UIImage *image;
}

@end

@implementation KidBindViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = self.title;
    
    [self.firstNameTF setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [self.lastNameTF setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [self.birthdayTF setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    
    self.firstNameTF.delegate = self;
    self.lastNameTF.delegate = self;
    self.birthdayTF.delegate = self;
    
    self.imageBtn.layer.cornerRadius = 60.f;
    self.imageBtn.layer.borderColor = [self.imageBtn titleColorForState:UIControlStateNormal].CGColor;
    self.imageBtn.layer.borderWidth = 2.f;
    self.imageBtn.layer.masksToBounds = YES;
    image = nil;
    
    [self setCustomBackButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)validateTextField {
    if (self.firstNameTF.text.length == 0 || self.lastNameTF.text.length == 0) {
        [Fun showMessageBoxWithTitle:@"Error" andMessage:@"Please input info."];
        return NO;
    }
    
    return YES;
}

- (void)goNext {
    if (_macAddress && [GlobalCache shareInstance].local.deviceMAC == nil) {
        [GlobalCache shareInstance].local.deviceMAC = _macAddress;
    }
    for (UIViewController *ctl in self.navigationController.viewControllers) {
        if ([ctl isKindOfClass:[EditProfileViewController class]] || [ctl isKindOfClass:[SyncDeviceViewController class]]) {
            //EditProfile add device flow
            [self.navigationController popToViewController:ctl animated:YES];
            return;
        }
    }
    
    UIStoryboard *stroyBoard=[UIStoryboard storyboardWithName:@"LoginFlow" bundle:nil];
    BindReadyViewController *ctl = [stroyBoard instantiateViewControllerWithIdentifier:@"BindReady"];
    ctl.image = image;
    ctl.name = [NSString stringWithFormat:@"%@ %@", self.firstNameTF.text, self.lastNameTF.text];
    [self.navigationController pushViewController:ctl animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.firstNameTF) {
        [self.lastNameTF becomeFirstResponder];
    }
    else if (textField == self.lastNameTF) {
        
        if ([self validateTextField]) {
            [SVProgressHUD showWithStatus:@"Add kid info, please wait..."];
            
            NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:@{@"firstName":self.firstNameTF.text, @"lastName":self.lastNameTF.text}];
            if (self.macAddress) {
                NSString *mac = [Fun dataToHex:self.macAddress];
                [data setObject:mac forKey:@"note"];
            }
            
            [[SwingClient sharedClient] kidsAdd:data completion:^(id kid, NSError *error) {
                if (error) {
                    LOG_D(@"kidsAdd fail: %@", error);
                    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                }
                else {
                    KidModel *model = kid;
                    if ([GlobalCache shareInstance].kidsList) {
                        [[GlobalCache shareInstance].kidsList arrayByAddingObject:model];
                    }
                    else {
                        [GlobalCache shareInstance].kidsList = @[model];
                    }
                    if (image && model) {
                        [SVProgressHUD showWithStatus:@"UploadImage, please wait..."];
                        [[SwingClient sharedClient] kidsUploadKidsProfileImage:image kidId:[NSString stringWithFormat:@"%d", model.objId] completion:^(NSString *profileImage, NSError *error) {
                            if (error) {
                                LOG_D(@"uploadProfileImage fail: %@", error);
                            }
                            else {
                                model.profile = profileImage;
                            }
                            [SVProgressHUD dismiss];
                            [self goNext];
                        }];
                    }
                    else {
                        [SVProgressHUD dismiss];
                        [self goNext];
                    }
                }
            }];
            
            
        }
        
    }
    return YES;
}

- (IBAction)imageAction:(id)sender {
    [self.firstNameTF resignFirstResponder];
    [self.lastNameTF resignFirstResponder];
    [self.birthdayTF resignFirstResponder];
    
    UIActionSheet *choiceSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Camera", nil), NSLocalizedString(@"Album", nil), nil];
    [choiceSheet showInView:self.view];
}

- (void)setHeaderImage:(UIImage*)headImage {
    [self.imageBtn setBackgroundImage:headImage forState:UIControlStateNormal];
    
    self.imageBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.imageBtn setTitle:nil forState:UIControlStateNormal];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
#if TARGET_IPHONE_SIMULATOR
        [Fun showMessageBoxWithTitle:NSLocalizedString(@"Prompt", nil) andMessage:@"Simulator does not support camera."];
#else
        // 拍照
        if ([CameraUtility isCameraAvailable] && [CameraUtility doesCameraSupportTakingPhotos]) {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
//            if ([CameraUtility isFrontCameraAvailable]) {
//                controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
//            }
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            controller.mediaTypes = mediaTypes;
            controller.delegate = self;
            [self presentViewController:controller
                               animated:YES
                             completion:^(void){
                                 LOG_D(@"Picker View Controller is presented");
                             }];
        }
#endif
    } else if (buttonIndex == 1) {
        // 从相册中选取
        if ([CameraUtility isPhotoLibraryAvailable]) {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            controller.mediaTypes = mediaTypes;
            controller.delegate = self;
            [self presentViewController:controller
                               animated:YES
                             completion:^(void){
                                 LOG_D(@"Picker View Controller is presented");
                             }];
        }
    }
}


#pragma mark VPImageCropperDelegate
- (void)imageCropper:(VPImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage {
    [cropperViewController dismissViewControllerAnimated:YES completion:^{
        // TO DO
        image = [Fun imageByScalingToMaxSize:editedImage maxWidth:TAGET_MAX_WIDTH];
        [self setHeaderImage:image];
    }];
}

- (void)imageCropperDidCancel:(VPImageCropperViewController *)cropperViewController {
    [cropperViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^() {
        UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        portraitImg = [Fun imageByScalingToMaxSize:portraitImg maxWidth:ORIGINAL_MAX_WIDTH];
        // present the cropper view controller
        VPImageCropperViewController *imgCropperVC = [[VPImageCropperViewController alloc] initWithImage:portraitImg cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
        imgCropperVC.delegate = self;
        [self presentViewController:imgCropperVC animated:YES completion:nil];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
