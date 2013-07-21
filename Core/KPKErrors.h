//
//  KPKErrors.h
//  KeePassKit
//
//  Created by Michael Starke on 13.07.13.
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

#ifndef MacPass_KPKErrors_h
#define MacPass_KPKErrors_h

#import <Foundation/Foundation.h>

#define KPKCreateError(errorCode,localizedKey,comment) [NSError errorWithDomain:KPKErrorDomain code:errorCode userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedStringFromTable(localizedKey, @"LocalizeableErrors", comment)}]


FOUNDATION_EXPORT NSString *const KPKErrorDomain;

typedef NS_ENUM( NSUInteger, KPKErrorCode ) {
  KPKErrorUnknownFileFormat = -1000, // The file format is unknown
  KPKErrorFileCorrupted, // The File is courruptes
  KPKErrorKDBXHeaderCorrupted, // The header is Corrupted
  KPKErrorWriteFailed, // Could write the File
  KPKErrorDatabaseParsingFailed, // The XML-Database couldn be parsed
  KPKErrorKeyParsingFailed, // The XML-Keyfile file couldn be parsed
  KPKErrorKDBDatabaseVersionUnsupported, // The database version is to high/low
  KPKErrorKDBXChipherUnsupported, // The header specifies a unsupported and/or wrong chipher methed
  KPKErrorKDBXUnsupportedCompressionAlgorithm, // The header specifies an unsupporte and/or wrong compressoing algorithm
  KPKErrorKDBXUnsupportedRandomStream, // The header specifies an unsupporte stream or it's corrupted
  KPKErrorKDBXIntegrityCheckFaild // The startbytes in the header aren't matching the AES stream-start
};

#endif