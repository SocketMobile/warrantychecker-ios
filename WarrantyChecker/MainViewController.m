//
//  MainViewController.m
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

#import "MainViewController.h"

/**
 * defines for the defaults persistence
 */
#define USERNAME @"Username"
#define USERNAME_DEFAULT @"Robert Smith"
#define USEREMAIL @"Useremail"
#define USEREMAIL_DEFAUT @"developer@socketmobile.com"
#define USERCOMPANY @"UserCompany"
#define USERCOMPANY_DEFAUT @"Socket Mobile, Inc."
#define USERINDUSTRY @"UserIndustry"
#define USERINDUSTRY_DEFAUT @"Mobile productivity"
#define USERADDRESS @"UserAddress"
#define USERADDRESS_DEFAUT @"39500 Eureka drive"
#define USERCITY @"UserCity"
#define USERCITY_DEFAUT @"Newark"
#define USERSTATE @"UserState"
#define USERSTATE_DEFAUT @"California"
#define USERZIPCODE @"UserZipCode"
#define USERZIPCODE_DEFAUT @"95560"
#define USERCOUNTRY @"UserCountry"
#define USERCOUNTRY_DEFAUT @"US"
#define WHRPURCHASED @"WhrPurchased"
#define WHRPURCHASED_DEFAUT @"Socket Store"
#define USINGSOFTSCAN @"UsingSoftScan"
#define PURCHASER @"Purchaser"


/**
 *  Application ID and Developer ID
 *  that are used to authenticate the requests
 *  made to the Socket Mobile registration servers.
 *
 * PLEASE REPLACE THOSE BY YOUR DEVELOPER ID AND
 * APPLICATION ID OTHERWISE THE REGISTRATION WILL
 * BE VOID
 */
#define DEVELOPER_ID @"ed0587a9-d1ed-4638-bb4c-34e88780f047";
#define APPLICATION_ID @"com.socketmobile.test";

/**
 * COMMENT OUT THE FOLLOWING LINE TO USE THE
 * STAGING REGISTRATION SERVER WITH A DUMMY
 * SCANNER BLUETOOTH ADDRESS
 * YOU WILL NEED A SCANNER TO CONNECT IN ORDER
 * TO TEST THE CODE AND THE CONNECTION TO THE
 * STAGING SERVER
 */
//#define TEST

#ifdef TEST
/**
 * TESTING_ENDPOINT CAN BE USED FOR TESTING PRUPOSE
 * THERE WON'T BE ANY REGISTRATION ACCEPTED USING
 * THIS END POINT.
 * NOT SPECIFYING AN END POINT WILL MAKE THE
 * SKTWARRANTYCHECKER OBJECT USING THE OFFICIAL
 * END POINT FOR CHECKING AND REGISTERING A
 * SCANNER.
 */
#define TESTING_ENDPOINT @"sandbox/v1/scanners/"

/**
 * TESTING BLUETOOTH ADDRESS THAT CAN BE USE WITH
 * TESTING_ENDPOINT TO REGISTER A DUMMY SCANNER
 */
#define TESTING_BLUETOOTH_ADDRESS @"000555100000"

#endif
/**
 *  To know if the application is checking a registration
 *  or is registering for an extension
 */
#define CHECK_REGISTRATION 0
#define REGISTER_EXTENSION 1

// logger to catch the checker warranty traces
@implementation Logger
-(void)logFunction:(NSString *)function withMessage:(NSString *)message
{
    NSLog(@"%@: %@",function,message);
}
@end


@interface MainViewController ()

@end

@implementation MainViewController
{
    NSTimer* _scanApiConsumer;
}

#pragma mark - App Life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.version.text=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];


    // load the Client Volunteered information
    [self loadCviFromPersistentStorage];

    // create a ScanApiHelper and open it
    self.scanApi=[[ScanApiHelper alloc]init];
    [self.scanApi setDelegate:self];
    [self.scanApi open];

    // start the ScanAPI Consumer timer to check if ScanAPI has a ScanObject for us to consume
    // all the asynchronous events coming from ScanAPI or property get/set complete operation
    // will be received in this consumer timer
    _scanApiConsumer=[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// timer handler for consuming ScanObject from ScanAPI
// if ScanApiHelper is not initialized this handler does nothing
-(void)onTimer:(NSTimer*)timer{
    [self.scanApi doScanApiReceive];
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self saveCviToPersistentStorage];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    }
}
/**
 * delegate used by the FlipsideView to get or set the Socket Registration CVI
 */
-(SKTCvi*)getCvi
{
    return self.cvi;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.flipsidePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        __weak id weakSelf = self;
        [[segue destinationViewController] setDelegate:weakSelf];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            self.flipsidePopoverController = popoverController;
            popoverController.delegate = self;
        }
    }
}

- (IBAction)togglePopover:(id)sender
{
    if (self.flipsidePopoverController) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        [self saveCviToPersistentStorage];
        self.flipsidePopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}


#pragma mark - SKTWarrantyCheckerDelegate
/**
 * called by the SKTWarrantyChecker when an error occur
 * either while checking the scanner registration or while
 * registering the scanner.
 */
-(void)scanner:(NSString*)bdAddress didReturnAnError:(SKTError *)error
{
    NSLog(@"Scanner %@ return an error:%ld %@ %@",bdAddress,(long)error.statusCode,error.message,error.descriptionError);
    NSString* description=error.descriptionError;
    if(description==nil)
        description=error.details;
    [self updateStatus:[NSString stringWithFormat:@"This scanner registration checking returns an error. %@",description]];
}

/**
 * called by the SKTWarrantyChecker when the check or the registration is
 * successful. The warranty object is returned with the flags indicating if
 * the scanner is registered and if not if it is eligible for registration.
 */
-(void)scanner:(NSString*)bdAddress didReturnWarranty:(SKTWarranty*)warranty
{
    NSLog(@"scanner did return warranty:");
    NSLog(@"%@",warranty.descriptionWarranty);
    NSLog(@"registered:%@",warranty.registered?@"true":@"false");
    NSLog(@"extension Eligible:%@",warranty.extensionEligible?@"true":@"false");
    NSLog(@"expiration date:%@",warranty.expirationDate);

    if(warranty.registered==FALSE){
        if(warranty.extensionEligible==TRUE){
            [self updateStatus:@"This scanner is eligible for warranty extension. Register your scanner to take benefit of this extension."];
            self.bdAddress=bdAddress;
            self.registerScanner.hidden=FALSE;
            self.registerScanner.tag=REGISTER_EXTENSION;// change the state to registration for warranty extension
        }
        else{
            [self updateStatus:@"Sorry, this scanner is not eligible for warranty extension."];
        }
    }
    else{
        if(self.registerScanner.tag==CHECK_REGISTRATION)
            [self updateStatus:@"This scanner is already registered."];
        else
            [self updateStatus:@"This scanner is now registered."];
    }

}

#pragma mark - ScanApiHelper selectors
/**
 * call when a Bd Address Get request has completed. That
 * is a perfect place for checking if this scanner has been registered.
 */
-(void)onGetBdAddress:(ISktScanObject*)scanObj
{
    long result=[[scanObj Msg]Result];
    if(SKTSUCCESS(result)){
        SKTWarrantyChecker* checker=[[SKTWarrantyChecker alloc]initWithDelegate:self withLogger:self.logger];

        checker.developerId=DEVELOPER_ID;
        checker.applicationId=APPLICATION_ID;
#ifdef TESTING_ENDPOINT
        checker.endPoint=TESTING_ENDPOINT;
#endif

		ISktScanProperty* property=[scanObj Property];
		unsigned char array[6];
		memcpy(array, [property getArrayValue], [property getArraySize]);
		NSString* bdAddress=[[NSString alloc] initWithFormat:@"%02x%02x%02x%02x%02x%02x", array[0],
							 array[1],
							 array[2],
							 array[3],
							 array[4],
							 array[5]];


        [self updateStatus:@"Read the Bluetooth address of the scanner, now check if it's registered..."];
#ifdef TESTING_BLUETOOTH_ADDRESS
        bdAddress=TESTING_BLUETOOTH_ADDRESS;
#endif
        [checker checkWarrantyScannerBdAddress:bdAddress];
    }
    else{
        [self updateStatus:[NSString stringWithFormat:@"Failed to retrieve the Bluetooth address of the scanner (%ld).",result]];
    }
}

#pragma mark - ScanApiHelperDelegate
/**
 * called each time a device connects to the host
 * @param result contains the result of the connection
 * @param newDevice contains the device information
 */
-(void)onDeviceArrival:(SKTRESULT)result device:(DeviceInfo*)deviceInfo
{
    self.registerScanner.tag=CHECK_REGISTRATION;// this is used for status when the checker calls scanner:didReturnWarranty
    [self updateStatus:@"Scanner connected, asking for its Bluetooth address..."];
    [self.scanApi postGetBtAddress:deviceInfo Target:self Response:@selector(onGetBdAddress:)];
}

/**
 * called each time a device disconnect from the host
 * @param deviceRemoved contains the device information
 */
-(void) onDeviceRemoval:(DeviceInfo*) deviceRemoved
{
    self.registerScanner.hidden=TRUE;
    [self updateStatus:@"Scanner disconnected, waiting for a scanner to connect..."];
}

/**
 * called each time ScanAPI is reporting an error
 * @param result contains the error code
 */
-(void) onError:(SKTRESULT) result
{
    if(!SKTSUCCESS(result)){
        [self updateStatus:[NSString stringWithFormat:@"Receive an error from ScanAPI:%ld",result]];
    }
}

/**
 * called each time ScanAPI receives decoded data from scanner
 * @param deviceInfo contains the device information from which
 * the data has been decoded
 * @param decodedData contains the decoded data information
 */
-(void) onDecodedData:(DeviceInfo*) device DecodedData:(ISktScanDecodedData*) decodedData
{

}

/**
 * called when ScanAPI initialization has been completed
 * @param result contains the initialization result
 */
-(void) onScanApiInitializeComplete:(SKTRESULT) result
{
    if(!SKTSUCCESS(result)){
        [self updateStatus:[NSString stringWithFormat:@"Receive an error from ScanAPI:%ld",result]];
    }
}

/**
 * called when ScanAPI has been terminated. This will be
 * the last message received from ScanAPI
 */
-(void) onScanApiTerminated
{

}

/**
 * called when an error occurs during the retrieval
 * of a ScanObject from ScanAPI.
 * @param result contains the retrieval error code
 */
-(void) onErrorRetrievingScanObject:(SKTRESULT) result
{
    if(!SKTSUCCESS(result)){
        [self updateStatus:[NSString stringWithFormat:@"Receive an error from ScanAPI retrieving ScanObject:%ld",result]];
    }
}

#pragma mark - Utility methods
/**
 * load the CVI information from the persistent storage or
 * assign the defaults to each field of the CVI.
 */
-(void) loadCviFromPersistentStorage
{
    self.cvi=[[SKTCvi alloc]init];
    NSUserDefaults* defaults=[NSUserDefaults standardUserDefaults];
    self.cvi.userName=[self getDefaults:defaults forKey:USERNAME withDefault:USERNAME_DEFAULT];
    self.cvi.userEmail=[self getDefaults:defaults forKey:USEREMAIL withDefault:USEREMAIL_DEFAUT];
    self.cvi.userCompany=[self getDefaults:defaults forKey:USERCOMPANY withDefault:USERCOMPANY_DEFAUT];
    self.cvi.userIndustry=[self getDefaults:defaults forKey:USERINDUSTRY withDefault:USERINDUSTRY_DEFAUT];
    self.cvi.userAddress=[self getDefaults:defaults forKey:USERADDRESS withDefault:USERADDRESS_DEFAUT];
    self.cvi.userCity=[self getDefaults:defaults forKey:USERCITY withDefault:USERCITY_DEFAUT];
    self.cvi.userState=[self getDefaults:defaults forKey:USERSTATE withDefault:USERSTATE_DEFAUT];
    self.cvi.userZipcode=[self getDefaults:defaults forKey:USERZIPCODE withDefault:USERZIPCODE_DEFAUT];
    self.cvi.userCountry=[self getDefaults:defaults forKey:USERCOUNTRY withDefault:USERCOUNTRY_DEFAUT];
    self.cvi.whrPurchased=[self getDefaults:defaults forKey:WHRPURCHASED withDefault:WHRPURCHASED_DEFAUT];
    self.cvi.usingSoftscan=[defaults boolForKey:USINGSOFTSCAN];
    self.cvi.purchaser=[defaults boolForKey:PURCHASER];
}

/**
 *  save the CVI into the persistent storage
 */
-(void)saveCviToPersistentStorage
{
    NSUserDefaults* defaults=[NSUserDefaults standardUserDefaults];
    [defaults setObject:self.cvi.userName forKey:USERNAME];
    [defaults setObject:self.cvi.userEmail forKey:USEREMAIL];
    [defaults setObject:self.cvi.userCompany forKey:USERCOMPANY];
    [defaults setObject:self.cvi.userIndustry forKey:USERINDUSTRY];
    [defaults setObject:self.cvi.userAddress forKey:USERADDRESS];
    [defaults setObject:self.cvi.userCity forKey:USERCITY];
    [defaults setObject:self.cvi.userState forKey:USERSTATE];
    [defaults setObject:self.cvi.userZipcode forKey:USERZIPCODE];
    [defaults setObject:self.cvi.userCountry forKey:USERCOUNTRY];
    [defaults setObject:self.cvi.whrPurchased forKey:WHRPURCHASED];
    [defaults setBool:self.cvi.usingSoftscan forKey:USINGSOFTSCAN];
    [defaults setBool:self.cvi.purchaser forKey:PURCHASER];
    [defaults synchronize];
}

/**
 * helper method to get the default string value a CVI information out of the
 * persistent storage
 */
-(NSString*)getDefaults:(NSUserDefaults*)defaults forKey:(NSString*)key withDefault:(NSString*)defaultString
{
    NSString* value=[defaults stringForKey:key];
    if(value==nil)
        value=defaultString;
    return value;
}

/**
 *  update the status label in the UI
 */
-(void)updateStatus:(NSString*)status
{
    self.status.text=status;
}

#pragma  mark - UI Handlers
/**
 *  handler for the Register Scanner button.
 */
- (IBAction)onRegisterScanner:(id)sender {
    self.registerScanner.hidden=TRUE;
    SKTWarrantyChecker* checker=[[SKTWarrantyChecker alloc]initWithDelegate:self withLogger:self.logger];

    checker.developerId=DEVELOPER_ID;
    checker.applicationId=APPLICATION_ID;
#ifdef TESTING_ENDPOINT
    checker.endPoint=TESTING_ENDPOINT;
#endif

    [checker registerScannerBdAddress:self.bdAddress withCvi:self.cvi];
    self.bdAddress=nil;
}

@end
