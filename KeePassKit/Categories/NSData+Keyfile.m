//
//  NSData+Keyfile.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


#import "NSData+Keyfile.h"
#import <CommonCrypto/CommonCrypto.h>

#import "KPKErrors.h"
#import "KPKFormat.h"

#import "DDXMLElementAdditions.h"
#import "NSString+Hexdata.h"
#import "NSData+Random.h"

@implementation NSData (Keyfile)

+ (NSData *)dataWithContentsOfKeyFile:(NSURL *)url version:(KPKDatabaseFormat)version error:(NSError *__autoreleasing *)error {
  switch (version) {
    case KPKDatabaseFormatKdb:
      return [self _dataVersion1WithWithContentsOfKeyFile:url error:error];
    case KPKDatabaseFormatKdbx:
      return [self _dataVersion2WithWithContentsOfKeyFile:url error:error];
    default:
      return nil;
  }
}

+ (NSData *)generateKeyfiledataForVersion:(KPKDatabaseFormat)version {
  NSData *data = [NSData dataWithRandomBytes:32];
  switch(version) {
    case KPKDatabaseFormatKdb:
      return [[NSString hexstringFromData:data] dataUsingEncoding:NSUTF8StringEncoding];
      
    case KPKDatabaseFormatKdbx:
      return [self _xmlKeyForData:data];
    
    default:
      return nil;
  }
}

+ (NSData *)_xmlKeyForData:(NSData *)data {
  NSString *dataString = [data base64Encoding];
  NSString *xmlString = [NSString stringWithFormat:@"<KeyFile><Meta><Version>1.00</Version></Meta><Key><Data>%@</Data></Key></KeyFile>", dataString];
  DDXMLDocument *keyDocument = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:NULL];
  return [keyDocument XMLDataWithOptions:DDXMLNodePrettyPrint];
}

+ (NSData *)_dataVersion1WithWithContentsOfKeyFile:(NSURL *)url error:(NSError *__autoreleasing *)error {
  // Open the keyfile
  NSData *fileData = [NSData dataWithContentsOfURL:url options:0 error:error];
  if(!fileData) {
    return nil;
  }
  
  if(fileData.length == 32) {
    return fileData; // Loading of a 32 bit binary file succeded;
  }
  NSData *decordedData = nil;
  if (fileData.length == 64) {
    decordedData = [self _keyDataFromHex:fileData];
  }
  /* Hexdata loading failed, so just hash the key */
  if(!decordedData) {
    decordedData = [self _keyDataFromHash:fileData];
  }
  return decordedData;
}

+ (NSData *)_dataVersion2WithWithContentsOfKeyFile:(NSURL *)url error:(NSError *__autoreleasing *)error {
  // Try and load a 2.x XML keyfile first
  NSData *data = [self _dataWithContentOfXMLKeyFile:url error:error];
  if(!data) {
    return [self _dataVersion1WithWithContentsOfKeyFile:url error:error];
  }
  return data;
}

+ (NSData *)_dataWithContentOfXMLKeyFile:(NSURL *)fileURL error:(NSError *__autoreleasing *)error {
  /*
   Format of the Keyfile
   <KeyFile>
   <Meta>
   <Version>1.00</Version>
   </Meta>
   <Key>
   <Data>L8JyIjlAd3SowrQPm6ZaR9mMolm/7iL6T1GJRGBNrAE=</Data>
   </Key>
   </KeyFile>
   */
  NSData *xmlData = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:error];
  if(!xmlData) {
    // eror is already filled
    return nil;
  }
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:error];
  if (document == nil) {
    return nil;
  }
  
  // Get the root document element
  DDXMLElement *rootElement = [document rootElement];
  
  DDXMLElement *metaElement = [rootElement elementForName:kKPKXmlMeta];
  if(metaElement) {
    DDXMLElement *versionElement = [metaElement elementForName:kKPKXmlVersion];
    NSScanner *versionScanner = [[NSScanner alloc] initWithString:[versionElement stringValue]];
    double version = 1;
    if(![versionScanner scanDouble:&version] || version > 1) {
      KPKCreateError(error, KPKErrorKdbxKeyUnsupportedVersion);
      return nil;
    }
  }
  
  DDXMLElement *keyElement = [rootElement elementForName:kKPKXmlKey];
  if (keyElement == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyKeyElementMissing);
    return nil;
  }
  
  DDXMLElement *dataElement = [keyElement elementForName:kKPKXmlData];
  if (dataElement == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyDataElementMissing);
    return nil;
    
  }
  
  NSString *dataString = [dataElement stringValue];
  if (dataString == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyDataParsingError);
    return nil;
  }
  return [[NSData alloc] initWithBase64Encoding:dataString];
}

+ (NSData *)_keyDataFromHex:(NSData *)hexData {
  NSString *hexString = [[NSString alloc] initWithData:hexData encoding:NSUTF8StringEncoding];
  if(!hexString) {
   return nil;
  }
  if(hexString.length != 64) {
    return nil; // No valid lenght found
  }
  return [hexString dataFromHexString];
}

+ (NSData *)_keyDataFromHash:(NSData *)fileData {
  uint8_t buffer[32];
  NSData *chunk;
  
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  @autoreleasepool {
    const NSUInteger chunkSize = 2048;
    for(NSUInteger iIndex = 0; iIndex < fileData.length; iIndex += chunkSize) {
      NSUInteger maxChunkLenght = MIN(fileData.length - iIndex, chunkSize);
      chunk = [fileData subdataWithRange:NSMakeRange(iIndex, maxChunkLenght)];
      CC_SHA256_Update(&ctx, chunk.bytes, (CC_LONG)chunk.length);
    }
  }
  CC_SHA256_Final(buffer, &ctx);
  
  return [NSData dataWithBytes:buffer length:32];
}



@end
