//
//  KPKTreeArchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTreeArchiver.h"
#import "KPKTreeArchiver_Private.h"

#import "KPKKdbTreeArchiver.h"
#import "KPKKdbxTreeArchiver.h"

#import "KPKTree.h"
#import "KPKErrors.h"

@implementation KPKTreeArchiver

@dynamic masterSeed;
@dynamic encryptionIV;

+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key format:(KPKDatabaseFormat)format error:(NSError *__autoreleasing *)error {
  KPKTreeArchiver *archiver = [[KPKTreeArchiver alloc] initWithTree:tree key:key format:format];
  if(!archiver) {
      KPKCreateError(error, KPKErrorUnknownFileFormat);
  }
  return [archiver archiveTree:error];
}

+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  KPKTreeArchiver *archiver = [[KPKTreeArchiver alloc] initWithTree:tree key:key];
  return [archiver archiveTree:error];
}

- (instancetype)initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key {
  self = [self initWithTree:tree key:key format:tree.minimumType];
  return self;
}

- (instancetype)initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key format:(KPKDatabaseFormat)format {
  switch(format) {
    case KPKDatabaseFormatKdb:
      self = [[KPKKdbTreeArchiver alloc] _initWithTree:tree key:key];
    case KPKDatabaseFormatKdbx:
      self = [[KPKKdbxTreeArchiver alloc] _initWithTree:tree key:key];
    default:
      self = nil;
  }
  return self;
}

- (instancetype)_initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key {
  self = [super init];
  if(self) {
    _tree = tree;
    _key = key;
  }
  return self;
}

- (NSData *)archiveTree:(NSError *__autoreleasing *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

@end
