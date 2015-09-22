//
//  SKTWarrantyChecker.m
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

#import "SKTWarrantyChecker.h"
#import "AFNetworking.h"

NSString* DEVELOPER_ID=@"21EC2020-3AEA-1069-A2DD-08002B30309D";
NSString* APPLICATION_ID=@"com.socketmobile.test";
NSString* BASE_URL=@"https://api.socketmobile.com/";
NSString* DB_ENDPOINT_CHECK=@"v1/scanners/";
NSString* SANDBOX_ENDPOINT_CHECK=@"v1/sandbox/scanners/";

/**
 FIELDS NAME RECEIVED IN JSON
 */
NSString* SKTWARRANTY=@"Warranty";
NSString* SKTDESCRIPTION=@"Description";
NSString* SKTEXTENSION_ELIGIBLE=@"ExtensionEligible";
NSString* SKTEXPIRATION_DATE=@"EndDate";
NSString* SKTIS_REGISTERED=@"IsRegistered";

@implementation SKTCvi

-(id)init
{
    self=[super init];
    if(self!=nil){
        self.userName=@"";
        self.userEmail=@"";
        self.userCompany=@"";
        self.userAddress=@"";
        self.userCity=@"";
        self.userState=@"";
        self.userZipcode=@"";
        self.userCountry=@"";
        self.userIndustry=@"";
        self.purchaser=FALSE;
        self.whrPurchased=@"";
        self.usingSoftscan=FALSE;
    }
    return self;
}
@end

@implementation SKTWarranty
@end

@implementation SKTError
@end

@implementation SKTWarrantyChecker

-(id)init
{
@throw [NSException exceptionWithName:NSInternalInconsistencyException
                               reason:@"-init is not a valid initializer for the class SKTWarrantyChecker, use initWithDelegate"
                             userInfo:nil];
return nil;
}

-(id)initWithDelegate:(id<SKTWarrantyCheckerDelegate>) delegate withLogger:(id<SKTLogger>)logger
{
    if(delegate==nil){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"-initWithDelegate delegate cannot be nil. Please provide a valid DmccParserDelegate"
                                     userInfo:nil];
    }
    else{
        self=[super init];
        if(self!=nil){
            self.delegate=delegate;
            self.logger=logger;
            self.baseUrl=BASE_URL;
            self.endPoint=@"v1/scanners/";// official end point for checking and registering a scanner
        }
    }
    return self;
}

-(void)checkWarrantyScannerBdAddress:(NSString *)bdAddress
{
    NSString* url=[NSString stringWithFormat:@"%@%@%@?hostPlatform=%@&osVersion%@",self.baseUrl,self.endPoint,bdAddress,@"iOS",[[UIDevice currentDevice] systemVersion]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSURLCredential* credential=[[NSURLCredential alloc]initWithUser:self.developerId password:self.applicationId persistence:NSURLCredentialPersistenceNone];
    [manager setCredential:credential];

    [self logFunction:@"SKTWarrantyChecker" withMessage:[NSString stringWithFormat:@"About to check the warranty for scanner:%@",bdAddress]];

    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSURL* url=operation.request.URL;
        NSString* bdAddress=url.lastPathComponent;
        [self logFunction:@"SKTWarrantyChecker" withMessage:[NSString stringWithFormat:@"Success in receiving the warranty information for %@",bdAddress]];
        [self sendWarrantyResultFor:bdAddress withResponseObject:operation.responseObject];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSURL* url=operation.request.URL;
        NSString* bdAddress=url.lastPathComponent;

        [self logFunction:@"SKTWarrantyChecker" withMessage:[NSString stringWithFormat:@"Checking the Warranty returned an error %ld",(long)operation.response.statusCode]];

        NSDictionary* response=operation.responseObject;
        if(response==nil){
            response=error.userInfo;
        }
        [self sendErrorForBdAddress:bdAddress withStatusCode:operation.response.statusCode withResponse:response];
    }];

}

-(void)registerScannerBdAddress:(NSString*) bdAddress withCvi:(SKTCvi *)cvi
{
    NSString* url=[NSString stringWithFormat:@"%@%@%@/registrations",self.baseUrl,self.endPoint,bdAddress];
//    NSString* url=[NSString stringWithFormat:@"http://localhost:3000/%@%@/registrations",self.endPoint,bdAddress];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSURLCredential* credential=[[NSURLCredential alloc]initWithUser:self.developerId password:self.applicationId persistence:NSURLCredentialPersistenceNone];
    [manager setCredential:credential];

    NSMutableDictionary* parameters=[[NSMutableDictionary alloc]init];
    [parameters setValue:cvi.userName forKey:@"userName"];
    [parameters setValue:cvi.userEmail forKey:@"userEmail"];
    [parameters setValue:cvi.userCompany forKey:@"userCompany"];
    [parameters setValue:cvi.userAddress forKey:@"userAddress"];
    [parameters setValue:cvi.userCity forKey:@"userCity"];
    [parameters setValue:cvi.userState forKey:@"userState"];
    [parameters setValue:cvi.userZipcode forKey:@"userZipcode"];
    [parameters setValue:cvi.userCountry forKey:@"userCountry"];
    [parameters setValue:cvi.userIndustry forKey:@"userIndustry"];
    if(cvi.purchaser==FALSE){
        parameters[@"isPurchaser"]=@"false";
        //[parameters setObject:[NSNumber numberWithBool:NO] forKey:@"isPurchaser"];
    }
    else{
        parameters[@"isPurchaser"]=@"true";
        //[parameters setObject:[NSNumber numberWithBool:YES] forKey:@"isPurchaser"];
    }
    [parameters setObject:cvi.whrPurchased forKey:@"whrPurchased"];
    if(cvi.usingSoftscan==FALSE){
        [parameters setValue:@"false" forKey:@"useSoftscan"];
    }
    else{
        [parameters setValue:@"true" forKey:@"useSoftScan"];
    }

    [self logFunction:@"SKTWarrantyChecker" withMessage:[NSString stringWithFormat:@"About to register scanner:%@",bdAddress]];

    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSURL* url2=operation.request.URL;
        NSInteger count=url2.pathComponents.count;
        NSString* bdAddress=url2.pathComponents[count-2];// last component is registrations, the previous one is the BD Address
        [self logFunction:@"SKTWarrantyChecker" withMessage:[NSString stringWithFormat:@"Success in registering the warranty information for %@",bdAddress]];
        [self sendWarrantyResultFor:bdAddress withResponseObject:operation.responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSURL* url2=operation.request.URL;
        NSInteger count=url2.pathComponents.count;
        NSString* bdAddress=url2.pathComponents[count-2];// last component is registrations, the previous one is the BD Address
        [self logFunction:@"SKTWarrantyChecker" withMessage:[NSString stringWithFormat:@"Registering the scanner returned an error %ld",(long)operation.response.statusCode]];
        [self logFunction:@"SKTWarrantyChecker" withMessage:[NSString stringWithFormat:@"Response: %@",operation]];

        [self sendErrorForBdAddress:bdAddress withStatusCode:operation.response.statusCode withResponse:operation.responseObject];
    }];

}

#pragma mark - utility methods
// return an error object with the status code to the application
// using the didReturnAndError delegate
-(void)sendErrorForBdAddress:(NSString*)bdAddress withStatusCode:(NSInteger) statusCode withResponse:(id)responseObject
{
    SKTError* sktError=[[SKTError alloc]init];
    sktError.statusCode=statusCode;

    NSDictionary* response=responseObject;
    for(NSString* key in response)
    {
        if([key isEqualToString:@"Message"]){
            sktError.message=[response valueForKey:key];
        }
        else if([key isEqualToString:@"ErrorMessage"]){
            sktError.descriptionError=[response valueForKey:key];
        }
        else if([key isEqualToString:@"NSLocalizedDescription"]){
            sktError.message=@"Registration failed.";
            sktError.descriptionError=[response valueForKey:key];
        }
        else if([key isEqualToString:@"ModelState"]){
            NSDictionary* subResponse=[response valueForKey:key];
            NSMutableString* description=[[NSMutableString alloc]init];
            for(NSString* subKey in subResponse)
            {
                [description appendString:subKey];
                [description appendString:@": "];
                NSArray* array=[subResponse valueForKey:subKey];
                [description appendString:array[0]];
                [description appendString:@"\r\n"];
            }
            sktError.details=description;
        }
    }
    if(self.delegate!=nil){
        [self.delegate scanner:bdAddress didReturnAnError:sktError];
    }
}

-(void)sendWarrantyResultFor:(NSString*) bdAddress withResponseObject:(id)responseObject
{
    SKTWarranty* warranty=[[SKTWarranty alloc]init];
    NSDictionary* response=responseObject;
    [self logFunction:@"SKTWARRANTYCHECKER" withMessage:[NSString stringWithFormat:@"Received:%@",responseObject]];
    for(NSString* key in response)
    {
        if([key isEqualToString:SKTWARRANTY]){
            NSDictionary* subwarranty=[response valueForKey:key];
            for(NSString* subKey in subwarranty){
                if([subKey isEqualToString:SKTDESCRIPTION]){
                    warranty.descriptionWarranty=[subwarranty valueForKey:subKey];
                }
                else if([subKey isEqualToString:SKTEXTENSION_ELIGIBLE]){
                    warranty.extensionEligible=[[subwarranty objectForKey:subKey]boolValue];
                }
                else if([subKey isEqualToString:SKTEXPIRATION_DATE]){
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"yyyy-MM-dd'T'hh:mm:ssZ"];
                    NSString* formatString=[subwarranty valueForKey:subKey];
                    NSDate *date = [df dateFromString: formatString];
                    warranty.expirationDate=date;
                }
            }
        }
        else if([key isEqualToString:SKTIS_REGISTERED]){
            warranty.registered=[[response objectForKey:key] boolValue];
        }
    }
    if(self.delegate!=nil){
        [self.delegate scanner:bdAddress didReturnWarranty:warranty];

    }
}

-(void)logFunction:(NSString*)function withMessage:(NSString *)message
{
    if(self.logger!=nil){
        [self.logger logFunction:function withMessage:message];
    }
}
@end
