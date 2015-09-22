//
//  FlipsideViewController.m
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

#import "FlipsideViewController.h"
#import "SKTWarrantyChecker.h"

@interface FlipsideViewController ()

@end

@implementation FlipsideViewController
{
    BOOL moveScreenUp;
    NSInteger _keyboardTranslate;
    NSTimeInterval _animationInterval;
}
- (void)awakeFromNib
{
    self.preferredContentSize = CGSizeMake(320.0, 480.0);
    [super awakeFromNib];
}

-(void)viewWillAppear:(BOOL)animated
{
    moveScreenUp=NO;
    _keyboardTranslate=0;
    _animationInterval=0;
    // listen for keyboard hide/show notifications so we can properly adjust the table's height
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

-(void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard events notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    SKTCvi* cvi=[self.delegate getCvi];
    self.userName.text=cvi.userName;
    self.userCompany.text=cvi.userCompany;
    self.userEmail.text=cvi.userEmail;
    self.userAddress.text=cvi.userAddress;
    self.userCity.text=cvi.userCity;
    self.userState.text=cvi.userState;
    self.userZipCode.text=cvi.userZipcode;
    self.userCountry.text=cvi.userCountry;
    self.userIndustry.text=cvi.userIndustry;
    self.whrPurchased.text=cvi.whrPurchased;
    self.purchaser.selected=cvi.purchaser;
    self.usingSoftScan.selected=cvi.usingSoftscan;

    [self.userName setDelegate:self];
    [self.userCompany setDelegate:self];
    [self.userEmail setDelegate:self];
    [self.userAddress setDelegate:self];
    [self.userCity setDelegate:self];
    [self.userState setDelegate:self];
    [self.userZipCode setDelegate:self];
    [self.userCountry setDelegate:self];
    [self.userIndustry setDelegate:self];
    [self.whrPurchased setDelegate:self];

    // make sure the navigation stays always on top
    // this is useful when the all screen moves up
    // for the keyboard not to mask the last edit in the form
    [self.contentView bringSubviewToFront: self.navigationBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    SKTCvi* cvi=[self.delegate getCvi];
    cvi.userName=self.userName.text;
    cvi.userCompany=self.userCompany.text;
    cvi.userEmail=self.userEmail.text;
    cvi.userAddress=self.userAddress.text;
    cvi.userCity=self.userCity.text;
    cvi.userState=self.userState.text;
    cvi.userZipcode=self.userZipCode.text;
    cvi.userCountry=self.userCountry.text;
    cvi.userIndustry=self.userIndustry.text;
    cvi.whrPurchased=self.whrPurchased.text;
    cvi.purchaser=self.purchaser.selected;
    cvi.usingSoftscan=self.usingSoftScan.selected;

    [self.delegate flipsideViewControllerDidFinish:self];
}

#pragma mark - UITextFieldDelegate handlers
- (BOOL)textFieldShouldReturn:(UITextField *)textField// called when 'return' key pressed. return NO to
{
    [textField resignFirstResponder];
    return TRUE;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // the screen should move up only if the last edit
    // field is active for input
    // and if that's not the field active then
    // move down the screen if it was moved up
    if(textField==self.whrPurchased){
        moveScreenUp=YES;
    }
    else{
        if(moveScreenUp==YES)
            [self moveViewDown];
        moveScreenUp=NO;
    }
    return YES;
}

#pragma mark - Keyboard management
- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if(_animationInterval==0){
        _animationInterval =
            [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    }
    if(moveScreenUp){
        // the keyboard is showing so resize the text view height
        CGRect keyboardRect = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        // convert the keyboard rect into the View coordinates
        keyboardRect =[self.insideView convertRect:keyboardRect fromView:nil];


        CGRect frameWhrPurchasedView = self.whrPurchased.frame;
        CGRect frameInsideView = self.insideView.frame;

        _keyboardTranslate=frameWhrPurchasedView.origin.y- keyboardRect.origin.y;
        if(_keyboardTranslate>0){
            _keyboardTranslate+=50;
            frameInsideView.origin.y -= _keyboardTranslate;

            [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
            [UIView setAnimationDuration:_animationInterval];
            self.insideView.frame = frameInsideView;
            [UIView commitAnimations];
        }
    }
    else{
        [self moveViewDown];
    }
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    // move the view down if it was
    // previously moved up
    [self moveViewDown];
}

#pragma mark - Utility methods

// move the view down if it was previously
// moved up
-(void)moveViewDown
{
    if(_keyboardTranslate>0){
        CGRect frameInsideView = self.insideView.frame;

        frameInsideView.origin.y+=_keyboardTranslate;

        [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
        [UIView setAnimationDuration:_animationInterval];

        self.insideView.frame = frameInsideView;
        [UIView commitAnimations];
        _keyboardTranslate=0;
    }
}
@end
