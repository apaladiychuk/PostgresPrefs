//
//  PGData.m
//  PostgreSQL
//
//  Created by Francis McKenzie on 11/7/15.
//  Copyright (c) 2015 Macca Tech Ltd. All rights reserved.
//

#import "PGData.h"

#pragma mark - Interfaces

@interface PGData()
- (NSDictionary *)allPreferencesWithClass:(Class)valueClass orClass:(Class)valueClass2;
- (id)preferenceForKey:(NSString *)key;
- (void)setPreference:(id)value forKey:(NSString *)key;
@end



#pragma mark - PGData

@implementation PGData

- (id)initWithAppID:(NSString *)appID
{
    self = [super init];
    
    if (self) {
        _appID = TrimToNil(appID);
    }
    return self;
}

- (NSArray *)allKeys
{
    CFStringRef appIDRef = self.appID ? (__bridge CFStringRef) self.appID : kCFPreferencesCurrentApplication;
    
    return (NSArray *)CFBridgingRelease(CFPreferencesCopyKeyList(appIDRef, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
}

- (NSDictionary *)allPreferencesWithClass:(Class)valueClass orClass:(Class)valueClass2
{
    CFStringRef appIDRef = self.appID ? (__bridge CFStringRef) self.appID : kCFPreferencesCurrentApplication;
    
    // Get all keys
    NSArray *keys = self.allKeys;
    
    // Give up if array empty
    if (keys.count == 0) return nil;
    
    // Put a sensible maximum limit on the number of keys, just in case!
    if (keys.count > 100) {
        DLog(@"ERROR: Too many keys: %@", keys);
        keys = [keys subarrayWithRange:NSMakeRange(0, 100)];
    }
    
    // Get all values for keys
    NSDictionary *data = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple((__bridge CFPropertyListRef) keys, appIDRef, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
    if (data.count == 0) return nil;
    
    // Filter out anything not of form (string,dictionary)
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:data.count];
    for (id key in data.allKeys) {
        id value = data[key];
        
        if (![key isKindOfClass:[NSString class]]) continue;
        if (!( // Note: Nil with capital 'N' means nil class
              (valueClass != Nil && [value isKindOfClass:valueClass]) ||
              (valueClass2 != Nil && [value isKindOfClass:valueClass2])
        )) continue;
        
        result[key] = value;
    }
    
    return result.count == 0 ? nil : result;
}

- (NSDictionary *)allData
{
    // Note: Nil with capital 'N' means nil class
    return [self allPreferencesWithClass:[NSDictionary class] orClass:Nil];
}

- (NSDictionary *)allPrimitives
{
    return [self allPreferencesWithClass:[NSString class] orClass:[NSNumber class]];
}

- (id)preferenceForKey:(NSString *)key
{
    if (!NonBlank(key)) return nil;
    
    CFStringRef appIDRef = self.appID ? (__bridge CFStringRef) self.appID : kCFPreferencesCurrentApplication;
    CFStringRef keyRef = (__bridge CFStringRef) key;
    
    return (NSObject *)CFBridgingRelease(CFPreferencesCopyValue(keyRef, appIDRef, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
}

- (void)setPreference:(id)value forKey:(NSString *)key
{
    if (!NonBlank(key)) return;
    
    CFStringRef appIDRef = self.appID ? (__bridge CFStringRef) self.appID : kCFPreferencesCurrentApplication;
    CFStringRef keyRef = (__bridge CFStringRef) key;
    CFPropertyListRef valueRef = value ? (__bridge CFPropertyListRef) value : NULL;
    
    CFPreferencesSetValue(keyRef, valueRef, appIDRef, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (NSNumber *)numberForKey:(NSString *)key
{
    id value = [self preferenceForKey:key];
    return [value isKindOfClass:[NSNumber class]] ? (NSNumber *) value : nil;
}

- (void)setNumber:(NSNumber *)value forKey:(NSString *)key
{
    [self setPreference:value forKey:key];
}

- (NSString *)stringForKey:(NSString *)key
{
    id value = [self preferenceForKey:key];
    return [value isKindOfClass:[NSString class]] ? (NSString *) value : nil;
}

- (void)setString:(NSString *)value forKey:(NSString *)key
{
    [self setPreference:value forKey:key];
}

- (NSDictionary *)dataForKey:(NSString *)key
{
    id value = [self preferenceForKey:key];
    return [value isKindOfClass:[NSDictionary class]] ? (NSDictionary *) value : nil;
}

- (void)setData:(NSDictionary *)data forKey:(NSString *)key
{
    [self setPreference:data.count>0?data:nil forKey:key];
}

- (void)removeKey:(NSString *)key
{
    [self setPreference:nil forKey:key];
}

- (void)removeKeys:(NSArray *)keys
{
    if (keys.count == 0) return;
    
    CFStringRef appIDRef = self.appID ? (__bridge CFStringRef) self.appID : kCFPreferencesCurrentApplication;
    CFArrayRef keysRef = (__bridge CFArrayRef) keys;
    
    CFPreferencesSetMultiple(NULL, keysRef, appIDRef, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (void)synchronize
{
    CFStringRef appIDRef = self.appID ? (__bridge CFStringRef) self.appID : kCFPreferencesCurrentApplication;
    
    CFPreferencesSynchronize(appIDRef, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

@end
