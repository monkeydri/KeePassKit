//
//  KPKKDBXFileHeader.h
//  KeePassKit
//
//  Created by Michael Starke on 14/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKFileHeader.h"

@interface KPKKdbxFileHeader : KPKFileHeader

@property (nonatomic, readonly, copy) NSData *contentHash; // only KDBX 3.1

@end