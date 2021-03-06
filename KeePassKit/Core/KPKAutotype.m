//
//  KPKAutotype.m
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
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

#import "KPKAutotype.h"
#import "KPKAutotype_Private.h"
#import "KPKEntry.h"
#import "KPKGroup.h"
#import "KPKTree.h"
#import "KPKWindowAssociation.h"
#import "KPKWindowAssociation_Private.h"

@implementation KPKAutotype

@dynamic associations;

@synthesize entry = _entry;
@synthesize defaultKeystrokeSequence = _defaultKeystrokeSequence;
@synthesize mutableAssociations = _mutableAssociations;

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSSet *)keyPathsForValuesAffectingHasDefaultKeystrokeSequence {
  return [NSSet setWithObject:NSStringFromSelector(@selector(defaultKeystrokeSequence))];
}

+ (NSSet *)keyPathsForValuesAffectingAssociations {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableAssociations))];
}

+ (instancetype)autotypeFromNotes:(NSString *)notes {
  /*
   Autotype on KeePass1 Files works with different values,
   need to be converted!
   
   Auto-Type: {USERNAME}{TAB}{PASSWORD}{ENTER}
   Auto-Type-Window: Some Dialog - *
   Auto-Type-1: {USERNAME}{ENTER}
   Auto-Type-Window-1: * - Editor
   Auto-Type-Window-1: * - Notepad
   Auto-Type-Window-1: * - WordPad
   Auto-Type-2: {PASSWORD}{ENTER}
   Auto-Type-Window-2: Some Web Page - *
   
   See http://keepass.info/help/base/autotype.html for references!
   */
  NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:@"auto-type(-window){0,1}(-[0-9]*){0,1}:\\ *(.*)" options:NSRegularExpressionCaseInsensitive error:nil];
  __block KPKAutotype *autotype = [[KPKAutotype alloc] init];
  for(NSString *line in [notes componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].reverseObjectEnumerator) {
    [regExp enumerateMatchesInString:line options:0 range:NSMakeRange(0, line.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
      @autoreleasepool {
        
        NSRange windowRange = [result rangeAtIndex:1];
        NSRange numberRange = [result rangeAtIndex:2];
        NSRange windowTitleOrCommandRange = [result rangeAtIndex:3];

        NSInteger currentIndex = 0;
        BOOL isAssociation = (windowRange.length != 0);
        BOOL hasWindowTitleOrCommand = (windowTitleOrCommandRange.length != 0);
        BOOL hasNumber = (numberRange.length != 0);
        
        /* Empty keystrokes or titles aren't allowed */
        if(!hasWindowTitleOrCommand) {
          NSLog(@"Encountered emptry %@. Aborting!", isAssociation ? @"window title" : @"keystroke sequence");
          *stop = YES;
        }
        /* Test for correct numbering */
        if(hasNumber) {
          NSScanner *numberScanner = [[NSScanner alloc] initWithString:[line substringWithRange:numberRange]];
          NSInteger index = 0;
          if([numberScanner scanInteger:&index]) {
            index = labs(index);
            if(currentIndex + 1 == index) {
              currentIndex++;
            }
            else {
              NSLog(@"Encountered Autotype index %ld but expected %ld. Aborting!", index, currentIndex + 1 );
              *stop = YES;
            }
          }
        }
        /* first encounter of non-association will get pushed to keystrokje sequence */
        NSString *windowTitleOrCommand = [line substringWithRange:windowTitleOrCommandRange];
        if(!isAssociation) {
          if(autotype.associations.count == 0) {
            autotype.defaultKeystrokeSequence = windowTitleOrCommand;
          }
        }
        else {
          if(autotype.hasDefaultKeystrokeSequence) {
            NSLog(@"Encounterd window association %@ but no Autotype sequence was specified. Aborting!", windowTitleOrCommand);
            *stop = YES;
            return;
          }
          else {
            autotype.defaultKeystrokeSequence = nil;
          }
        }
      }
    }];
  }
  return autotype;
}

- (instancetype)init {
  self = [super init];
  if(self) {
    _enabled = YES;
    _obfuscateDataTransfer = NO;
    _mutableAssociations = [[NSMutableArray alloc] initWithCapacity:2];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self) {
    _enabled = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(isEnabled))];
    _obfuscateDataTransfer = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(obfuscateDataTransfer))];
    _defaultKeystrokeSequence = [[aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(defaultKeystrokeSequence))] copy];
    self.mutableAssociations = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(associations))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeBool:_enabled forKey:NSStringFromSelector(@selector(isEnabled))];
  [aCoder encodeBool:_obfuscateDataTransfer forKey:NSStringFromSelector(@selector(obfuscateDataTransfer))];
  [aCoder encodeObject:_mutableAssociations forKey:NSStringFromSelector(@selector(associations))];
  [aCoder encodeObject:_defaultKeystrokeSequence forKey:NSStringFromSelector(@selector(defaultKeystrokeSequence))];
}

- (id)copyWithZone:(NSZone *)zone {
  KPKAutotype *copy = [[KPKAutotype alloc] init];
  copy.enabled = _enabled;
  copy.obfuscateDataTransfer = _obfuscateDataTransfer;
  copy.mutableAssociations = [[NSMutableArray alloc] initWithArray:self.mutableAssociations copyItems:YES];
  copy.defaultKeystrokeSequence = _defaultKeystrokeSequence;
  copy.entry = _entry;
  return copy;
}

- (BOOL)isEqual:(id)object {
  if(![object isKindOfClass:self.class]) {
    return NO;
  }
  return [self isEqualToAutotype:object];
}

- (BOOL)isEqualToAutotype:(KPKAutotype *)autotype {
  if(!autotype) {
    return NO;
  }
  if(self.enabled != autotype.enabled) {
    return NO;
  }
  if(self.obfuscateDataTransfer != autotype.obfuscateDataTransfer) {
    return NO;
  }
  if(self.hasDefaultKeystrokeSequence != autotype.hasDefaultKeystrokeSequence) {
    return NO;
  }
  if(!self.hasDefaultKeystrokeSequence && ![self.defaultKeystrokeSequence isEqualToString:autotype.defaultKeystrokeSequence]) {
    /* no default so the sequences need to match */
    return NO;
  }
  if(![self.mutableAssociations isEqualToArray:autotype.mutableAssociations]) {
    return NO;
  }
  return YES;
}

- (NSString *)autotypeNotes {
  NSAssert(NO, @"Missing implementation!");
  return nil;
}

- (void)setEnabled:(BOOL)enabled {
  if(_enabled == enabled) {
    return; // no changes
  }
  [[self.entry.undoManager prepareWithInvocationTarget:self] setEnabled:self.enabled];
  [self.entry touchModified];
  _enabled = enabled;
}

- (void)setObfuscateDataTransfer:(BOOL)obfuscateDataTransfer {
  if(_obfuscateDataTransfer == obfuscateDataTransfer) {
    return; // no changes
  }
  [[self.entry.undoManager prepareWithInvocationTarget:self] setObfuscateDataTransfer:self.obfuscateDataTransfer];
  [self.entry touchModified];
  _obfuscateDataTransfer = obfuscateDataTransfer;
}

- (NSString *)defaultKeystrokeSequence {
  /* The default sequence is inherited, so just bubble up */
  if(self.hasDefaultKeystrokeSequence) {
    return self.entry.parent.defaultAutoTypeSequence;
  }
  return _defaultKeystrokeSequence;
}

- (void)setDefaultKeystrokeSequence:(NSString *)defaultSequence {
  if([_defaultKeystrokeSequence isEqualToString:defaultSequence]) {
    return; // no changes
  }
  [[self.entry.undoManager prepareWithInvocationTarget:self] setDefaultKeystrokeSequence:_defaultKeystrokeSequence];
  [self.entry touchModified];
  _defaultKeystrokeSequence = defaultSequence.length  > 0 ? [defaultSequence copy] : nil;
}

- (void)setMutableAssociations:(NSMutableArray<KPKWindowAssociation *> *)mutableAssociations {
  if(self.mutableAssociations == mutableAssociations) {
    return;
  }
  _mutableAssociations = mutableAssociations;
  for(KPKWindowAssociation *association in _mutableAssociations) {
    association.autotype = self;
  }
}

- (NSArray *)associations {
  return [self.mutableAssociations copy];
}

- (void)addAssociation:(KPKWindowAssociation *)association {
  [self addAssociation:association atIndex:self.mutableAssociations.count];
}

- (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index {
  [[self.entry.undoManager prepareWithInvocationTarget:self] removeAssociation:association];
  [self.entry touchModified];
  association.autotype = self;
  [self insertObject:association inMutableAssociationsAtIndex:index];
}

- (void)removeAssociation:(KPKWindowAssociation *)association {
  NSUInteger index = [self.mutableAssociations indexOfObject:association];
  if(index != NSNotFound) {
    [[self.entry.undoManager prepareWithInvocationTarget:self] addAssociation:association atIndex:index];
    [self.entry touchModified];
    association.autotype = nil;
    [self removeObjectFromMutableAssociationsAtIndex:index];
  }
}

- (KPKWindowAssociation *)windowAssociationMatchingWindowTitle:(NSString *)windowTitle {
  for(KPKWindowAssociation *association in self.mutableAssociations) {
    if([association matchesWindowTitle:windowTitle]) {
      return association;
    }
  }
  return nil;
}

- (BOOL)hasDefaultKeystrokeSequence {
  return ! (_defaultKeystrokeSequence.length > 0);
}

#pragma mark -
#pragma mark KVO Compliance

- (void)insertObject:(KPKWindowAssociation *)association inMutableAssociationsAtIndex:(NSUInteger)index {
  index = MIN(index, self.mutableAssociations.count);
  [self.mutableAssociations insertObject:association atIndex:index];
}

- (void)removeObjectFromMutableAssociationsAtIndex:(NSUInteger)index {
  KPKWindowAssociation *association = self.mutableAssociations[index];
  if(association) {
    [self.mutableAssociations removeObjectAtIndex:index];
  }
}

@end
