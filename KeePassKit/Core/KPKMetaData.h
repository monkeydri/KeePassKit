//
//  KPKMetaData.h
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
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

#import <Cocoa/Cocoa.h>
#import "KPKModificationRecording.h"

@class KPKBinary;
@class KPKIcon;
@class KPKTree;

@interface KPKMetaData : NSObject <KPKModificationRecording>

/* Setting for cipher */
@property(copy) NSUUID *keyDerivationUUID; // UUID for the key derivation function to use, KDB and KDBX3 default ist AES, KDBX4 should default to Argon2
@property(copy) NSDictionary *keyDerivationOptions; // NSDictionary(Variant) with parameters for the key derivation operation
@property(copy) NSUUID *cipherUUID; // UUID for the chipher used to encrypt the content, defaults are AES (KDB, KDBX3.1) and ChaCha20 (KDBX4)
@property(assign) uint32_t compressionAlgorithm;

@property(nonatomic, copy) NSString *generator;

@property(copy) NSDate *settingsChanged;

@property(nonatomic, copy) NSString *databaseName;
@property(nonatomic, copy) NSDate *databaseNameChanged;
@property(nonatomic, copy) NSString *databaseDescription;
@property(nonatomic, copy) NSDate *databaseDescriptionChanged;

@property(nonatomic, copy) NSString *defaultUserName;
@property(nonatomic, copy) NSDate *defaultUserNameChanged;
@property(nonatomic) NSInteger maintenanceHistoryDays;
#
/* Hexstring - #AA77FF */
@property(nonatomic, copy) NSColor *color;

@property(nonatomic, copy) NSDate *masterKeyChanged;
@property(nonatomic, readonly) BOOL recommendMasterKeyChange;
@property(nonatomic) NSInteger masterKeyChangeRecommendationInterval;
@property(nonatomic, readonly) BOOL enforceMasterKeyChange;
@property(nonatomic) NSInteger masterKeyChangeEnforcementInterval;

@property(nonatomic) BOOL protectTitle;
@property(nonatomic) BOOL protectUserName;
@property(nonatomic) BOOL protectPassword;
@property(nonatomic) BOOL protectUrl;
@property(nonatomic) BOOL protectNotes;

@property(nonatomic) BOOL useTrash;
@property(nonatomic, copy) NSUUID *trashUuid;
@property(nonatomic, copy) NSDate *trashChanged;

@property(nonatomic, copy) NSUUID *entryTemplatesGroup;
@property(nonatomic, copy) NSDate *entryTemplatesGroupChanged;

@property(nonatomic, readonly) BOOL isHistoryEnabled;
@property NSInteger historyMaxItems;
@property NSInteger historyMaxSize; // Megabytes

@property(copy) NSUUID *lastSelectedGroup;
@property(copy) NSUUID *lastTopVisibleGroup;

@property(nonatomic, copy, readonly) NSArray<KPKBinary *> *customData;
@property(nonatomic, copy, readonly) NSArray<KPKIcon *> *customIcons;
@property(nonatomic, copy, readonly) NSDictionary *customPublicData;
/**
 *	Array of KPKBinary objects - extracted from unknown meta entries. Notes is mapped to name, data to data
 */
@property(nonatomic, copy, readonly) NSArray<KPKBinary *> *unknownMetaEntryData;

- (BOOL)isEqualToMetaData:(KPKMetaData *)other;

- (KPKIcon *)findIcon:(NSUUID *)uuid;

- (void)addCustomIcon:(KPKIcon *)icon;
- (void)addCustomIcon:(KPKIcon *)icon atIndex:(NSUInteger)index;
- (void)removeCustomIcon:(KPKIcon *)icon;


@end
