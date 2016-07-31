//
//  UVIViewController.m
//  Swing
//
//  Created by Mapple on 16/7/30.
//  Copyright © 2016年 zzteam. All rights reserved.
//

#import "UVIndexViewController.h"

@interface UVIndexViewController ()

@end

@implementation UVIndexViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.uvLabel.layer.cornerRadius = 50.f;
    self.uvLabel.layer.borderColor = [self.uvLabel titleColorForState:UIControlStateNormal].CGColor;
    self.uvLabel.layer.borderWidth = 5.f;
    self.uvLabel.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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