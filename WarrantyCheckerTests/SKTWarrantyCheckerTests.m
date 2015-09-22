//
//  SKTWarrantyCheckerTests.m
//  WarrantyChecker
//
//  Created by Eric Glaenzer on 2/12/14.
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

#import <XCTest/XCTest.h>
#import "SKTWarrantyChecker.h"

NSString* SCANNER_MAC_ADDRESS=@"000555000000";

@interface Logger :NSObject <SKTLogger>
@end

@implementation Logger
-(void)logFunction:(NSString*)function withMessage:(NSString*)message
{
    NSLog(@"%@: %@",function,message);
}
@end

@interface SKTWaitAsynchronous : NSObject
-(void)resetWaitOver;
-(void)setWaitOver:(BOOL)wait;
-(BOOL)waitForAsynchronousCallWithTimeout:(NSInteger)timeout;
@end

@implementation SKTWaitAsynchronous
{
    BOOL _waitOver;
}
-(id)init
{
    self=[super init];
    if(self!=nil){
        _waitOver=FALSE;
    }
    return self;
}

-(void)resetWaitOver
{
    @synchronized(self){
        _waitOver=FALSE;
    }
}
-(void)setWaitOver:(BOOL)wait
{
    @synchronized(self){
        _waitOver=wait;
    }
}
-(BOOL)waitForAsynchronousCallWithTimeout:(NSInteger)timeout
{
    BOOL waitOver=FALSE;
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    NSTimeInterval time=[NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeMax=[NSDate timeIntervalSinceReferenceDate];
    timeMax+=timeout;
    NSLog(@"waitForAsynchronousCallWithTimeout started");

    while(waitOver==FALSE){
        [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
        @synchronized(self){
            waitOver=_waitOver;
        }
        time=[NSDate timeIntervalSinceReferenceDate];
        if(time<timeMax){
            timeout=timeMax-time;// reset the timeout to the remaing time.
        }
        else{
            break;
        }
    }

    if(waitOver){
        NSLog(@"waitForAsynchronousCallWithTimeout over");
        _waitOver=FALSE;
    }
    else{
        NSLog(@"waitForAsynchronousCallWithTimeout failed in timeout");
    }
    return waitOver;
}
@end

@interface SKTWarrantyCheckerDelegateFixture : SKTWaitAsynchronous <SKTWarrantyCheckerDelegate>
@property NSString* bdAddress;
@property NSString* message;
@property NSString* descriptionWarranty;
@property NSString* details;
@property NSInteger statusCode;
@property SKTWarranty* warranty;
@end

@implementation SKTWarrantyCheckerDelegateFixture
-(void)scanner:(NSString*)bdAddress didReturnAnError:(SKTError*)error
{
    self.bdAddress=bdAddress;
    self.message=error.message;
    self.descriptionWarranty=error.descriptionError;
    self.statusCode=error.statusCode;
    self.details=error.details;
    [self setWaitOver:TRUE];
}

-(void)scanner:(NSString*)bdAddress didReturnWarranty:(SKTWarranty*)warranty
{
    self.statusCode=200;
    self.bdAddress=bdAddress;
    self.warranty=warranty;
    [self setWaitOver:TRUE];
}
@end

@interface SKTWarrantyCheckerTests : XCTestCase

@end

@implementation SKTWarrantyCheckerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testInit
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    // ignore the deprecated warning as we want to intentionnally
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertThrowsSpecificNamed(checker=[[SKTWarrantyChecker alloc]init], NSException, NSInternalInconsistencyException, @"SKTWarrantyChecker didn't throw the expected exception");
#pragma clang diagnostic pop

    XCTAssertNil(checker, "init didn't return nil when it fails");

    XCTAssertThrowsSpecificNamed(checker=[[SKTWarrantyChecker alloc]initWithDelegate:nil withLogger:nil], NSException, NSInvalidArgumentException, @"SKTWarrantyChecker initWithDelegate:withLogger didn't throw the expected exception when delegate is nil");

    XCTAssertNil(checker, "init didn't return nil when it fails");

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:nil],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    XCTAssertNotNil(checker, "init did return nil when it succeeded");
}

-(void)testCheckWarrantyWithIncorrectApplicationId
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"21EC2020-3AEA-1069-FFFF-08002B30309D";
    checker.applicationId=@"comsocketmobiletest";                // incorrect Application ID

    [checker checkWarrantyScannerBdAddress:@"000555000000"];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:10], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.message isEqualToString:@"Registration failed."],@"Error message is not what is expected");

    XCTAssertTrue([delegate.descriptionWarranty isEqualToString:@"Request failed: unauthorized (401)"],@"Error description is not what is expected");

    XCTAssertEqual(delegate.statusCode,401,@"Error code status is not 401");
}

-(void)testCheckWarrantyWithIncorrectDeveloperId
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"21EC2020=3AEA=1069=FFFF=08002B30309D";
    checker.applicationId=@"com.socketmobile.test";                // incorrect Application ID

    [checker checkWarrantyScannerBdAddress:@"000555000000"];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:10], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.message isEqualToString:@"Registration failed."],@"Error message is not what is expected");

    XCTAssertTrue([delegate.descriptionWarranty isEqualToString:@"Request failed: unauthorized (401)"],@"Error description is not what is expected");

    XCTAssertEqual(delegate.statusCode,401,@"Error code status is not 401");
}

-(void)testCheckWarrantyWithNoDeveloperIdAndApplicationId
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"";                  // no Developer ID
    checker.applicationId=@"";                // no Application ID

    [checker checkWarrantyScannerBdAddress:@"000555000000"];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:10], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.message isEqualToString:@"Registration failed."],@"Error message is not what is expected");

    XCTAssertTrue([delegate.descriptionWarranty isEqualToString:@"Request failed: unauthorized (401)"],@"Error description is not what is expected");

    XCTAssertEqual(delegate.statusCode,401,@"Error code status is not 401");
}

-(void)testCheckWarrantyWithoutDeveloperIdAndApplicationId
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
//    checker.developerId=@"";                  // no Developer ID
//    checker.applicationId=@"";                // no Application ID

    [checker checkWarrantyScannerBdAddress:@"000555000000"];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:10], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.message isEqualToString:@"Registration failed."],@"Error message is not what is expected");

    XCTAssertTrue([delegate.descriptionWarranty isEqualToString:@"Request failed: unauthorized (401)"],@"Error description is not what is expected");

    XCTAssertEqual(delegate.statusCode,401,@"Error code status is not 401");
}

-(void)testCheckWarrantyWithUnknownAddress
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");


    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"21EC2020-3AEA-1069-A2DD-08002B30309D";
    checker.applicationId=@"com.socketmobile.test";

    [checker checkWarrantyScannerBdAddress:@"112233445566"];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:5], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.bdAddress isEqualToString:@"112233445566"],@"Error bdAddress is not what is expected");

    XCTAssertTrue([delegate.message isEqualToString:@"Registration failed."],@"Error message is not what is expected");

    XCTAssertTrue([delegate.descriptionWarranty isEqualToString:@"Oops! We are unable to register your scanner at this time. Please contact Socket Mobile support to register your scanner."],@"Error description is not what is expected");

    XCTAssertEqual(delegate.statusCode,404,@"Error code status is not 404");
}

-(void)testCheckWarrantyWithKnownAddress
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"21EC2020-3AEA-1069-A2DD-08002B30309D";
    checker.applicationId=@"com.socketmobile.test";

    [checker checkWarrantyScannerBdAddress:@"000555100000"];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:5], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.bdAddress isEqualToString:@"000555100000"],@"Error bdAddress is not what is expected");

    XCTAssertTrue([delegate.warranty.descriptionWarranty isEqualToString:@"1 Year Limited Warranty (includes 90 days buffer)"],@"Error warranty description is not what is expected");

    XCTAssertTrue(delegate.warranty.extensionEligible,@"Error warranty is not eligible for extension");

    XCTAssertFalse(delegate.warranty.registered,@"Error the warranty is already registered");
}

-(void)testRegisterWarrantyWithKnownAddress
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    // create and fill a cvi
    SKTCvi* cvi=[[SKTCvi alloc]init];
    cvi.userName=@"Robert Smith";
    cvi.userEmail=@"rsmith@socketmobile.com";
    cvi.userCompany=@"Socket Mobile,Inc.";
    cvi.userAddress=@"39700 Eureka drive";
    cvi.userCity=@"Newark";
    cvi.userState=@"California";
    cvi.userZipcode=@"94560";
    cvi.userCountry=@"US";
    cvi.purchaser=YES;
    cvi.whrPurchased=@"Socket Store";
    cvi.usingSoftscan=NO;
    cvi.userIndustry=@"Mobile productivity";

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"21EC2020-3AEA-1069-A2DD-08002B30309D";
    checker.applicationId=@"com.socketmobile.test";

    [checker registerScannerBdAddress:@"000555100000" withCvi:cvi];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:5], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.bdAddress isEqualToString:@"000555100000"],@"Error bdAddress is not what is expected");

    XCTAssertTrue([delegate.warranty.descriptionWarranty isEqualToString:@"1 Year Limited Warranty (includes 90 days buffer)"],@"Error warranty description is not what is expected");

    XCTAssertFalse(delegate.warranty.extensionEligible,@"Error warranty is STILL eligible for extension");

    XCTAssertTrue(delegate.warranty.registered,@"Error the warranty is NOT registered");
}

-(void)testRegisterWarrantyWithKnownAddressAndErrorInCountry
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    // create and fill a cvi
    SKTCvi* cvi=[[SKTCvi alloc]init];
    cvi.userName=@"Robert Smith";
    cvi.userEmail=@"rsmith@socketmobile.com";
    cvi.userCompany=@"Socket Mobile,Inc.";
    cvi.userAddress=@"39700 Eureka drive";
    cvi.userCity=@"Newark";
    cvi.userState=@"California";
    cvi.userZipcode=@"94560";
    cvi.userCountry=@"USA"; // THREE LETTERS COUNTRY INSTEAD OF TWO
    cvi.purchaser=YES;
    cvi.whrPurchased=@"Socket Store";
    cvi.usingSoftscan=NO;
    cvi.userIndustry=@"Mobile productivity";

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"21EC2020-3AEA-1069-A2DD-08002B30309D";
    checker.applicationId=@"com.socketmobile.test";

    [checker registerScannerBdAddress:@"000555100000" withCvi:cvi];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:5], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.bdAddress isEqualToString:@"000555100000"],@"Error bdAddress is not what is expected");

    XCTAssertEqual(delegate.statusCode,400,@"Error status code is not what is expected");

    XCTAssertTrue([delegate.message isEqualToString:@"The request is invalid."],@"Error message is not what is expected");

    XCTAssertTrue([delegate.details isEqualToString:@"RegistrationData.UserCountry: The field UserCountry must be a string or array type with a maximum length of '2'.\r\n"],@"Error details is not what is expected");

}

-(void)testRegisterWarrantyWithKnownAddressAndErrorInEmail
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    // create and fill a cvi
    SKTCvi* cvi=[[SKTCvi alloc]init];
    cvi.userName=@"Robert Smith";
    cvi.userEmail=@"rsmith";// there is no @ in the email
    cvi.userCompany=@"Socket Mobile,Inc.";
    cvi.userAddress=@"39700 Eureka drive";
    cvi.userCity=@"Newark";
    cvi.userState=@"California";
    cvi.userZipcode=@"94560";
    cvi.userCountry=@"US";
    cvi.purchaser=YES;
    cvi.whrPurchased=@"Socket Store";
    cvi.usingSoftscan=NO;
    cvi.userIndustry=@"Mobile productivity";

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"21EC2020-3AEA-1069-A2DD-08002B30309D";
    checker.applicationId=@"com.socketmobile.test";

    [checker registerScannerBdAddress:@"000555100000" withCvi:cvi];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:5], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.bdAddress isEqualToString:@"000555100000"],@"Error bdAddress is not what is expected");

    XCTAssertEqual(delegate.statusCode,400,@"Error status code is not what is expected");

    XCTAssertTrue([delegate.message isEqualToString:@"The request is invalid."],@"Error message is not what is expected");

    XCTAssertTrue([delegate.details isEqualToString:@"RegistrationData.UserEmail: The UserEmail field is not a valid e-mail address.\r\n"],@"Error details is not what is expected");

}

-(void)testRegisterWarrantyWithKnownAddressAndErrorInCity
{
    SKTWarrantyChecker* checker=nil;
    SKTWarrantyCheckerDelegateFixture* delegate=[[SKTWarrantyCheckerDelegateFixture alloc]init];
    Logger* logger=[[Logger alloc]init];

    // create and fill a cvi
    SKTCvi* cvi=[[SKTCvi alloc]init];
    cvi.userName=@"Robert Smith";
    cvi.userEmail=@"rsmith@socketmobile.com";
    cvi.userCompany=@"Socket Mobile,Inc.";
    cvi.userAddress=@"39700 Eureka drive";
    cvi.userCity=@"";                           // city left empty
    cvi.userState=@"California";
    cvi.userZipcode=@"94560";
    cvi.userCountry=@"US";
    cvi.purchaser=YES;
    cvi.whrPurchased=@"Socket Store";
    cvi.usingSoftscan=NO;
    cvi.userIndustry=@"Mobile productivity";

    XCTAssertNoThrow(checker=[[SKTWarrantyChecker alloc]initWithDelegate:delegate withLogger:logger],@"SKTWarrantyChecker initWithDelegate:withLogger throws an exception when delegate is not nil");

    checker.endPoint=@"v1/sandbox/scanners/";
    checker.developerId=@"21EC2020-3AEA-1069-A2DD-08002B30309D";
    checker.applicationId=@"com.socketmobile.test";

    [checker registerScannerBdAddress:@"000555100000" withCvi:cvi];

    XCTAssertTrue([delegate waitForAsynchronousCallWithTimeout:5], @"Didn't receive the result for checkWarrantyScannerBdAddress");

    XCTAssertTrue([delegate.bdAddress isEqualToString:@"000555100000"],@"Error bdAddress is not what is expected");

    XCTAssertEqual(delegate.statusCode,400,@"Error status code is not what is expected");

    XCTAssertTrue([delegate.message isEqualToString:@"The request is invalid."],@"Error message is not what is expected");

    XCTAssertTrue([delegate.details isEqualToString:@"RegistrationData.UserCity: The UserCity field is required.\r\n"],@"Error details is not what is expected");

}

@end
