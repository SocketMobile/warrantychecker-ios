//
//  SKTWarrantyChecker.h
//  WarrantyChecker
//
//  Created by Eric Glaenzer on 2/11/14.
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

#import <Foundation/Foundation.h>

/**
 * defines a protocol for a logger
 */
@protocol SKTLogger <NSObject>
-(void)logFunction:(NSString*)function withMessage:(NSString*)message;
@end

/**
 * Customer Voluntary Information that can be filled out
 * for extension of the Scanner Warranty.
 */
@interface SKTCvi : NSObject

@property NSString* userName;
@property NSString* userEmail;
@property NSString* userCompany;
@property NSString* userAddress;
@property NSString* userCity;
@property NSString* userState;
@property NSString* userZipcode;
@property NSString* userCountry;
@property NSString* userIndustry;
@property BOOL purchaser;
@property NSString* whrPurchased;
@property BOOL usingSoftscan;

@end

/**
 * Warranty of a Barcode Scanner.
 */
@interface SKTWarranty: NSObject
@property BOOL registered;
@property NSString* descriptionWarranty;
@property NSDate* expirationDate;
@property BOOL extensionEligible;
@end


/**
 * Holds information about an error
 */
@interface SKTError : NSObject
@property NSInteger statusCode;
@property NSString* message;
@property NSString* descriptionError;
@property NSString* details;
@end

/**
 * delegate for the SKTWarrantyChecker
 * Implement this protocol in the view where the result are expected.
 */
@protocol SKTWarrantyCheckerDelegate <NSObject>
-(void)scanner:(NSString*)bdAddress didReturnAnError:(SKTError*)error;
-(void)scanner:(NSString*)bdAddress didReturnWarranty:(SKTWarranty*)warranty;
@end

/**
 * class helper to check the warranty of a Socket Mobile scanner.
 * To use it, initialize it with a delegate to receive the results
 * directly in your app, and call the dci and cvi methods.
 * The logger is optional and should be set to nil if not used.
 */
@interface SKTWarrantyChecker : NSObject
@property id<SKTWarrantyCheckerDelegate> delegate;
@property id<SKTLogger> logger;

/**
 * base URL, doesn't need to change other than for testing purpose
 */
@property NSString* baseUrl;
/**
 * change to the webstaging for testing
 */
@property NSString* endPoint;

/**
 * application ID used for authentication
 */
@property NSString* applicationId;
/**
 * developer ID: used for authentication
 */
@property NSString* developerId;

/**
 * this method is not supported by SKTWarrantyChecker, use initWithDelegate: instead
 */
-(id)init __attribute__((deprecated));

/**
 * initialize this SKTWarrantyChecker object with a delegate.
 */
-(id)initWithDelegate:(id<SKTWarrantyCheckerDelegate>) delegate withLogger:(id<SKTLogger>)logger;

/**
 * check the warranty of the scanner identified by its Bluetooth MAC address
 */
-(void)checkWarrantyScannerBdAddress:(NSString*)bdAddress;


/**
 * register a scanner with the CVI informations
 */
-(void)registerScannerBdAddress:(NSString*)bdAddress withCvi:(SKTCvi*)cvi;
@end
