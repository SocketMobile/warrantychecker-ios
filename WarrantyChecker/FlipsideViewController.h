//
//  FlipsideViewController.h
//  WarrantyChecker
//
//  Created by Eric Glaenzer on 2/10/14.
//
// Copyright 2015 Socket Mobile, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>

@class FlipsideViewController;
@class SKTCvi;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
- (SKTCvi*)getCvi;
@end

@interface FlipsideViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *userEmail;
@property (weak, nonatomic) IBOutlet UITextField *userCompany;
@property (weak, nonatomic) IBOutlet UITextField *userAddress;
@property (weak, nonatomic) IBOutlet UITextField *userCity;
@property (weak, nonatomic) IBOutlet UITextField *userState;
@property (weak, nonatomic) IBOutlet UITextField *userZipCode;
@property (weak, nonatomic) IBOutlet UITextField *userCountry;
@property (weak, nonatomic) IBOutlet UITextField *userIndustry;
@property (weak, nonatomic) IBOutlet UITextField *whrPurchased;
@property (weak, nonatomic) IBOutlet UISwitch *purchaser;
@property (weak, nonatomic) IBOutlet UISwitch *usingSoftScan;
@property (weak, nonatomic) IBOutlet UIView *insideView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) id <FlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
