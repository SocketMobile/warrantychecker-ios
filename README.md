# WarrantyChecker for iOS
This simple iOS app is a sample code for checking a scanner Warranty and
for registering it if the scanner is not already registered.
The registration requires the scanner Bluetooth address that is retrieved using
ScanAPI SDK.

## Prerequisites
This SDK uses CocoaPods. If it needs to be installed please check the CocoaPods
website for the most current instructions:
https://cocoapods.org/

The Socket Mobile ScanAPI SDK is also required in order to compile this sample.

## Documentation
The ScanAPI documentation can be found at:
http://www.socketmobile.com/docs/default-source/developer-documentation/scanapi.pdf?sfvrsn=2

## Installation

For this sample app to work out of the box, unzip the ScanApiSDK-10.x.x.zip file
at the same root as the clone of this app.

ie:
```
/Documents
        /WarrantyChecker
        /ScanApiSDK-10.2.x
```
Edit the WarrantyChecker/Podfile and make sure the ScanAPI version matches with
the one that has been unzipped.

From a Terminal window, go to the WarrantyChecker directory and type:
```sh
pod install
```

Load the WarrantyChecker workspace (NOT PROJECT) in Xcode and compile and run.

## Description
The Warranty Checker use a REST interface to know if a scanner is already
registered and to extend its warranty.

The REST requests need the credentials that is defined as follow:
username: Developer ID
password: App ID

They need to be replaced with your own Developer ID and App ID that can be
retrieved from Socket Developer Portal at: https://www.socketmobile.com/developers/welcome

The Scanner Registration API document can also be downloaded from this portal by
clicking on the Downloads button.

The App ID must be created using this Socket Developer Portal, by clicking on
the DCB Registration link in the right panel.

Then modify the file MainViewController.m to fill it with your own credentials:
```
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
#define APPLICATION_ID @"com.mycompany.myapp";
```

## Implementation
In this simple example the ScanApiHelper is "attached" to the main view
controller. This main view controller derives from the ScanApiHelperDelegate
protocol and implements some of the delegate methods.

### main view controller viewDidLoad
This handler creates and initialize a ScanApiHelper instance and a
ScanApiConsumer timer and opens ScanApiHelper after setting the delegate to this
main view controller.

### ScanApiHelperDelegate onScanApiInitializeConplete
This part is optional, but this SingleEntry app does support SoftScan. So it is
enabled here by doing a postSeftSoftScanStatus.

Then it asks for the ScanAPI version.

### handle for ScanAPI version
As example, when a ScanApiHelper set or get function is used it returns
immediately and the response will be received in the provided selector.
For getting the ScanAPI version the onGetScanApiVersion selector is invoked with
the result and response. The version is then saved to be ready to display in the
Flipside view.

### onDeviceArrival
This ScanApiHelperDelegate method is called when a scanner is successfully
detected on the host. The scanner can be SoftScan or any other Socket Mobile
scanners supported by ScanAPI.
In this particular case and since the WarrantChecker needs the Bluetooth Address
of scanner, it sends a request to get the Bluetooth address of the scanner.
The status is updated to indicate to the user that the Bluetooth address is
requested.

### onDeviceRemoval
When a scanner is no longer available (disconnected), this delegate is invoked.
In this particular case, the connection status is updated indicating to the user
that the application is waiting for a scanner to connect.

### onDecodedData(Result)
There are actually 2 onDecodedData delegates defined in ScanApiHelperDelegate.
The second one has the result as arguments and is the recommended one to use.

The WarrantyChecker simply ignores any decoded data received through this
delegate.


### onGetBdAddress
This selector is called upon completion of the Get Bluetooth address request.
The result is checked and if successful then a SKTWarrantyChecker object is
allocated and initialized passing the MainViewController as delegate recipient.

## ScanApiHelper
ScanApiHelper is provided as source code. It provides a set of very basic
features like enabling disabling barcode symbologies.

If a needed feature is not implemented by ScanApiHelper, the recommendation is
to create an extension of ScanApiHelper and copy paste of a similar feature from
ScanApiHelper to the extended one.

Following this recommendation will prevent to loose the modifications at the
next update.

## SKTWarrantyChecker
This is the client side of Socket Mobile Warranty service.

There are mainly 3 objects for handling the Warranty Checker feature and they
are:

### SKTLogger
Provide am interface for logging the various states of the Warranty Checker.
The application using Warrant Checker object can provide its own logger as long
as it implements this SKTLogger protocol.

### SKTCvi
This object contains the Customer Voluntary Information (CVI) that is required
in order to extend the warranty of a scanner.
This object has only properties.


### SKTWarranty
This object represents the actual warranty description of a particular scanner.
It has the following properties:
- registered: Boolean indicating if this scanner is already registered.
- descriptionWarranty: text for the warranty description.
- expirationDate: date when the warranty expires.
- extensionEligible: Boolean indicating if this scanner is eligible for warranty
extension.


### SKTError
This object describes an error. It has the following properties:
- statusCode
- message
- descriptionError
- details

### SKTWarrantyCheckerDelegate
Since the WarrantyChecker provides an asynchronous client interface, these
delegates are used to retrieve the response when a request has completed.
Only 2 delegates are defined:
scanner:didReturnAnError:
This delegate is invoked when an error occurs while checking if a particular
scanner is registered. The error returned is an instance of the SKTError
previously described.

scanner:didReturnWarranty:
This delegate is invoked when a scanner has a warranty. A warranty object is
passed as argument and defined in greater details the whereabouts of the
warranty.

### SKTWarrantyChecker
This object provides the main interface to the Warranty Checker service.
Its initialization requires a reference to an object that complies with its
SKTWarrantyCheckerDelegate protocol.
It has few properties required for making the request to the Warranty Checker
service.
One of its methods is the checkWarrantyScannerBdAddress. This method actually
requests a warranty check about the scanner identified by its Bluetooth address
passed as argument. If the request is successful, the delegate
scanner:didReturnWarranty is invoked with the SKTWarranty as argument containing
the actual warranty information of the scanner.

The second method is registerScannerBdAddress which is actually the registration
request with the CVI information. The scanner Bluetooth address and the SKTCvi
are passed as arguments of this method.
The scanner:didReturnWarranty is invoked in case of success. The SKTWarranty
object has then its registered boolean set to true and expirationDate is reset
to the new warranty extension date.
