//
//  XXLocalDataService.m
//  XXTouchApp
//
//  Created by Zheng on 8/30/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXLocalDataService.h"
#import "JTSImageViewController.h"
#import "FYPhotoLibrary.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "ALAssetsLibrary+SingleInstance.h"
#import "PHPhotoLibrary+CustomPhotoCollection.h"

static NSString * const kXXStorageAlbumName = @"XXTouch";

static NSString * const kXXTouchStorageDB = @"kXXTouchStorageDB-1";
static NSString * const kXXStorageKeyApplicationBundles = @"kXXStorageKeyApplicationBundles-1";
static NSString * const kXXStorageKeyStartUpConfigScriptPath = @"kXXStorageKeyStartUpConfigScriptPath-1";
static NSString * const kXXStorageKeyRemoteAccessStatus = @"kXXStorageKeyRemoteAccessStatus-1";
static NSString * const kXXStorageKeyDeviceInfo = @"kXXStorageKeyDeviceInfo-%@";
static NSString * const kXXStorageKeyLocalUserConfig = @"kXXStorageKeyLocalUserConfig-1";
static NSString * const kXXStorageKeyRemoteUserConfig = @"kXXStorageKeyRemoteUserConfig-1";
static NSString * const kXXStorageKeyExpirationDate = @"kXXStorageKeyExpirationDate-1";
static NSString * const kXXStorageKeyNowDate = @"kXXStorageKeyNowDate-1";
static NSString * const kXXStorageKeySortMethod = @"kXXStorageKeySortMethod-1";
static NSString * const kXXStorageKeyStartUpConfigSwitch = @"kXXStorageKeyStartUpConfigSwitch-1";
static NSString * const kXXStorageKeyActivatorInstalled = @"kXXStorageKeyActivatorInstalled-1";
static NSString * const kXXStorageKeyRecordConfigRecordVolumeUp = @"kXXStorageKeyRecordConfigRecordVolumeUp-1";
static NSString * const kXXStorageKeyRecordConfigRecordVolumeDown = @"kXXStorageKeyRecordConfigRecordVolumeDown-1";
static NSString * const kXXStorageKeyPressConfigHoldVolumeUp = @"kXXStorageKeyPressConfigHoldVolumeUp-1";
static NSString * const kXXStorageKeyPressConfigHoldVolumeDown = @"kXXStorageKeyPressConfigHoldVolumeDown-1";
static NSString * const kXXStorageKeyPressConfigPressVolumeUp = @"kXXStorageKeyPressConfigPressVolumeUp-1";
static NSString * const kXXStorageKeyPressConfigPressVolumeDown = @"kXXStorageKeyPressConfigPressVolumeDown-1";
static NSString * const kXXStorageKeyHidesMainPath = @"kXXStorageKeyHidesMainPath-1";
static NSString * const kXXStorageKeyFontFamily = @"kXXStorageKeyFontFamily-1";
static NSString * const kXXStorageKeyFontFamilySize = @"kXXStorageKeyFontFamilySize-1";
static NSString * const kXXStorageKeyLineNumbersEnabled = @"kXXStorageKeyLineNumbersEnabled-1";
static NSString * const kXXStorageKeyTabWidth = @"kXXStorageKeyTabWidth-1";
static NSString * const kXXStorageKeySoftTabsEnabled = @"kXXStorageKeySoftTabsEnabled-1";
static NSString * const kXXStorageKeyAutoIndentEnabled = @"kXXStorageKeyAutoIndentEnabled-1";
static NSString * const kXXStorageKeyReadOnlyEnabled = @"kXXStorageKeyReadOnlyEnabled-1";
static NSString * const kXXStorageKeyAutoCorrectionEnabled = @"kXXStorageKeyAutoCorrectionEnabled-1";
static NSString * const kXXStorageKeyAutoCapitalizationEnabled = @"kXXStorageKeyAutoCapitalizationEnabled-1";

@interface XXLocalDataService () <
    JTSImageViewControllerInteractionsDelegate
>
@property (nonatomic, strong) NSArray <NSString *> *randStrings;

@end

@implementation XXLocalDataService {
    NSString *_mainPath;
    NSString *_rootPath;
    
    NSDateFormatter *_defaultDateFormatter;
    NSDateFormatter *_shortDateFormatter;
    NSDateFormatter *_miniDateFormatter;
}

+ (id)sharedInstance {
    static XXLocalDataService *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] initWithName:kXXTouchStorageDB];
    });
    
    return sharedInstance;
}

- (instancetype)initWithName:(NSString *)name {
    if (self = [super initWithName:name]) {
        // Init Local Data Configure
        if (![self localUserConfig]) {
            // First
            NSError *err = nil;
            NSString *demoPath = [[NSBundle mainBundle] pathForResource:@"XXTReferences.bundle/demo" ofType:@"lua"];
            BOOL result = [FCFileManager copyItemAtPath:demoPath
                                                 toPath:[self.rootPath stringByAppendingPathComponent:@"demo.lua"]
                                              overwrite:NO
                                                  error:&err];
            if (!result)
            {
                
            }
            [self setLocalUserConfig:[[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                       kXXLocalConfigHidesMainPath: @YES
                                                                                       }]];
        }
    }
    return self;
}

- (NSString *)mainPath {
    if (!_mainPath) {
        if ([[NSFileManager defaultManager] isReadableFileAtPath:MAIN_PATH]) {
            _mainPath = MAIN_PATH;
        } else {
            _mainPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        }
    }
    return _mainPath;
}

- (NSString *)rootPath {
    if (!_rootPath) {
        if ([[NSFileManager defaultManager] isReadableFileAtPath:FEVER_PATH]) {
            _rootPath = FEVER_PATH;
        } else {
            NSString *feverPath = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"lua"] stringByAppendingPathComponent:@"scripts"];
            [FCFileManager createDirectoriesForPath:feverPath error:nil];
            NSError *err = nil;
            if ([FCFileManager isDirectoryItemAtPath:feverPath error:&err] == NO) {
                NSAssert(err == nil, @"Cannot access root directory");
            }
            _rootPath = feverPath;
        }
    }
    return _rootPath;
}

- (NSDateFormatter *)defaultDateFormatter {
    if (!_defaultDateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        _defaultDateFormatter = dateFormatter;
    }
    return _defaultDateFormatter;
}

- (NSDateFormatter *)shortDateFormatter {
    if (!_shortDateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"d/M/yy, h:mm a"];
        _shortDateFormatter = dateFormatter;
    }
    return _shortDateFormatter;
}

- (NSDateFormatter *)miniDateFormatter {
    if (!_miniDateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"d/M/yy"];
        _miniDateFormatter = dateFormatter;
    }
    return _miniDateFormatter;
}

- (NSMutableArray <NSString *> *)pasteboardArr {
    if (!_pasteboardArr) {
        _pasteboardArr = [[NSMutableArray alloc] init];
    }
    return _pasteboardArr;
}

- (NSString *)startUpConfigScriptPath {
    return (NSString *)[self objectForKey:kXXStorageKeyStartUpConfigScriptPath];
}

- (void)setStartUpConfigScriptPath:(NSString *)startUpConfigScriptPath {
    [self setObject:startUpConfigScriptPath forKey:kXXStorageKeyStartUpConfigScriptPath];
}

- (BOOL)isSelectedScriptInPath:(NSString *)path {
    if (![path hasSuffix:@"/"]) {
        path = [path stringByAppendingString:@"/"];
    }
    return [self.selectedScript hasPrefix:path];
}

- (BOOL)isSelectedStartUpScriptInPath:(NSString *)path {
    if (![path hasSuffix:@"/"]) {
        path = [path stringByAppendingString:@"/"];
    }
    return [self.startUpConfigScriptPath hasPrefix:path];
}

- (NSString *)remoteAccessURL {
    NSString *wifiAddress = [[UIDevice currentDevice] ipAddressWIFI];
    if (wifiAddress == nil) {
        return nil;
    }
    return [NSString stringWithFormat:remoteAccessUrl(), wifiAddress];
}

- (BOOL)remoteAccessStatus {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyRemoteAccessStatus] boolValue];
}

- (void)setRemoteAccessStatus:(BOOL)remoteAccessStatus {
    [self setObject:[NSNumber numberWithBool:remoteAccessStatus] forKey:kXXStorageKeyRemoteAccessStatus];
}

- (NSDictionary *)deviceInfo {
    return (NSDictionary *)[self objectForKey:[NSString stringWithFormat:kXXStorageKeyDeviceInfo, VERSION_BUILD]];
}

- (void)setDeviceInfo:(NSDictionary *)deviceInfo {
    [self setObject:deviceInfo forKey:[NSString stringWithFormat:kXXStorageKeyDeviceInfo, VERSION_BUILD]];
}

- (NSMutableDictionary *)localUserConfig {
    NSMutableDictionary *localUserConfig = (NSMutableDictionary *)[self objectForKey:kXXStorageKeyLocalUserConfig];
    return localUserConfig;
}

- (void)setLocalUserConfig:(NSMutableDictionary *)localUserConfig {
    [self setObject:localUserConfig forKey:kXXStorageKeyLocalUserConfig];
}

- (NSMutableDictionary *)remoteUserConfig {
    return (NSMutableDictionary *)[self objectForKey:kXXStorageKeyRemoteUserConfig];
}

- (void)setRemoteUserConfig:(NSMutableDictionary *)remoteUserConfig {
    [self setObject:remoteUserConfig forKey:kXXStorageKeyRemoteUserConfig];
}

- (NSDate *)nowDate {
    return (NSDate *)[self objectForKey:kXXStorageKeyNowDate];
}

- (void)setNowDate:(NSDate *)nowDate {
    [self setObject:nowDate forKey:kXXStorageKeyNowDate];
}

- (NSDate *)expirationDate {
    return (NSDate *)[self objectForKey:kXXStorageKeyExpirationDate];
}

- (void)setExpirationDate:(NSDate *)expirationDate {
    [self setObject:expirationDate forKey:kXXStorageKeyExpirationDate];
}

#pragma mark - JTSImageViewControllerInteractionsDelegate

- (void)imageViewerDidLongPress:(JTSImageViewController *)imageViewer atRect:(CGRect)rect {
    imageViewer.view.userInteractionEnabled = NO;
    [imageViewer.view makeToastActivity:CSToastPositionCenter];
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        // 7.x
        [[ALAssetsLibrary sharedLibrary] saveImage:imageViewer.image
                                           toAlbum:kXXStorageAlbumName
                                        completion:^(NSURL *assetURL, NSError *error) {
                                            if (error == nil) {
                                                dispatch_async_on_main_queue(^{
                                                    imageViewer.view.userInteractionEnabled = YES;
                                                    [imageViewer.view hideToastActivity];
                                                    [imageViewer.view makeToast:NSLocalizedString(@"Image saved to the album", nil)];
                                                });
                                            }
                                        } failure:^(NSError *error) {
                                            if (error != nil) {
                                                dispatch_async_on_main_queue(^{
                                                    imageViewer.view.userInteractionEnabled = YES;
                                                    [imageViewer.view hideToastActivity];
                                                    [imageViewer.view makeToast:[error localizedDescription]];
                                                });
                                            }
                                        }];
    } else {
        // 8.0+
        [[FYPhotoLibrary sharedInstance] requestLibraryAccessHandler:^(FYPhotoLibraryPermissionStatus statusResult) {
            if (statusResult == FYPhotoLibraryPermissionStatusDenied) {
                imageViewer.view.userInteractionEnabled = YES;
                [imageViewer.view hideToastActivity];
                [imageViewer.view makeToast:NSLocalizedString(@"Failed to request photo library access", nil)];
            } else if (statusResult == FYPhotoLibraryPermissionStatusGranted) {
                [[PHPhotoLibrary sharedPhotoLibrary] saveImage:imageViewer.image
                                                       toAlbum:kXXStorageAlbumName
                                                    completion:^(BOOL success) {
                                                        if (success) {
                                                            dispatch_async_on_main_queue(^{
                                                                imageViewer.view.userInteractionEnabled = YES;
                                                                [imageViewer.view hideToastActivity];
                                                                [imageViewer.view makeToast:NSLocalizedString(@"Image saved to the album", nil)];
                                                            });
                                                        }
                                                    } failure:^(NSError * _Nullable error) {
                                                        if (error != nil) {
                                                            dispatch_async_on_main_queue(^{
                                                                imageViewer.view.userInteractionEnabled = YES;
                                                                [imageViewer.view hideToastActivity];
                                                                [imageViewer.view makeToast:[error localizedDescription]];
                                                            });
                                                        }
                                                    }];
            }
        }];
    }
}

- (kXXScriptListSortMethod)sortMethod {
    return [(NSNumber *)[self objectForKey:kXXStorageKeySortMethod] unsignedIntegerValue];
}

- (void)setSortMethod:(kXXScriptListSortMethod)sortMethod {
    [self setObject:[NSNumber numberWithUnsignedInteger:sortMethod] forKey:kXXStorageKeySortMethod];
}

- (BOOL)startUpConfigSwitch {
    return [(NSNumber *)[self objectForKey:kXXStartUpConfigSwitch] boolValue];
}

- (void)setStartUpConfigSwitch:(BOOL)startUpConfigSwitch {
    [self setObject:[NSNumber numberWithBool:startUpConfigSwitch] forKey:kXXStartUpConfigSwitch];
}

- (BOOL)keyPressConfigActivatorInstalled {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyActivatorInstalled] boolValue];
}

- (void)setKeyPressConfigActivatorInstalled:(BOOL)keyPressConfigActivatorInstalled {
    [self setObject:[NSNumber numberWithBool:keyPressConfigActivatorInstalled] forKey:kXXStorageKeyActivatorInstalled];
}

- (BOOL)recordConfigRecordVolumeUp {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyRecordConfigRecordVolumeUp] boolValue];
}

- (void)setRecordConfigRecordVolumeUp:(BOOL)recordConfigRecordVolumeUp {
    [self setObject:[NSNumber numberWithBool:recordConfigRecordVolumeUp] forKey:kXXStorageKeyRecordConfigRecordVolumeUp];
}

- (BOOL)recordConfigRecordVolumeDown {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyRecordConfigRecordVolumeDown] boolValue];
}

- (void)setRecordConfigRecordVolumeDown:(BOOL)recordConfigRecordVolumeDown {
    [self setObject:[NSNumber numberWithBool:recordConfigRecordVolumeDown] forKey:kXXStorageKeyRecordConfigRecordVolumeDown];
}

- (kXXKeyPressConfig)keyPressConfigHoldVolumeUp {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyPressConfigHoldVolumeUp] unsignedIntegerValue];
}

- (void)setKeyPressConfigHoldVolumeUp:(kXXKeyPressConfig)keyPressConfigHoldVolumeUp {
    [self setObject:[NSNumber numberWithUnsignedInteger:keyPressConfigHoldVolumeUp] forKey:kXXStorageKeyPressConfigHoldVolumeUp];
}

- (kXXKeyPressConfig)keyPressConfigHoldVolumeDown {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyPressConfigHoldVolumeDown] unsignedIntegerValue];
}

- (void)setKeyPressConfigHoldVolumeDown:(kXXKeyPressConfig)keyPressConfigHoldVolumeDown {
    [self setObject:[NSNumber numberWithUnsignedInteger:keyPressConfigHoldVolumeDown] forKey:kXXStorageKeyPressConfigHoldVolumeDown];
}

- (kXXKeyPressConfig)keyPressConfigPressVolumeUp {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyPressConfigPressVolumeUp] unsignedIntegerValue];
}

- (void)setKeyPressConfigPressVolumeUp:(kXXKeyPressConfig)keyPressConfigPressVolumeUp {
    [self setObject:[NSNumber numberWithUnsignedInteger:keyPressConfigPressVolumeUp] forKey:kXXStorageKeyPressConfigPressVolumeUp];
}

- (kXXKeyPressConfig)keyPressConfigPressVolumeDown {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyPressConfigPressVolumeDown] unsignedIntegerValue];
}

- (void)setKeyPressConfigPressVolumeDown:(kXXKeyPressConfig)keyPressConfigPressVolumeDown {
    [self setObject:[NSNumber numberWithUnsignedInteger:keyPressConfigPressVolumeDown] forKey:kXXStorageKeyPressConfigPressVolumeDown];
}

- (NSArray <NSString *> *)randStrings {
    if (!_randStrings) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"extendHisLife" ofType:@"plist"];
        NSArray *arr = [[NSArray alloc] initWithContentsOfFile:plistPath];
        if (arr) {
            _randStrings = arr;
        } else {
            _randStrings = @[];
        }
    }
    return _randStrings;
}

- (NSString *)randString {
    NSUInteger rand = arc4random() % self.randStrings.count;
    return self.randStrings[rand];
}

- (NSArray *)bundles {
    NSArray *bundles = (NSArray *)[self objectForKey:kXXStorageKeyApplicationBundles];
    if (!bundles)
        return @[];
    return bundles;
}

- (void)setBundles:(NSArray *)bundles {
    [self setObject:bundles forKey:kXXStorageKeyApplicationBundles];
}

- (BOOL)hidesMainPath {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyHidesMainPath] boolValue];
}

- (void)setHidesMainPath:(BOOL)hidesMainPath {
    [self setObject:[NSNumber numberWithBool:hidesMainPath] forKey:kXXStorageKeyHidesMainPath];
}

- (kXXEditorFontFamily)fontFamily {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyFontFamily] unsignedIntegerValue];
}

- (void)setFontFamily:(kXXEditorFontFamily)fontFamily {
    [self setObject:[NSNumber numberWithUnsignedInteger:fontFamily] forKey:kXXStorageKeyFontFamily];
}

- (NSString *)fontFamilyName {
    if (self.fontFamily == kXXEditorFontFamilyCourierNew) {
        return @"Courier New";
    } else if (self.fontFamily == kXXEditorFontFamilyMenlo) {
        return @"Menlo";
    } else if (self.fontFamily == kXXEditorFontFamilySourceCodePro) {
        return @"Source Code Pro";
    } else if (self.fontFamily == kXXEditorFontFamilySourceSansPro) {
        return @"Source Sans Pro";
    }
    return @"";
}

- (NSArray <UIFont *> *)fontFamilyArray {
    CGFloat fontSize = self.fontFamilySize;
    switch (self.fontFamily) {
        case kXXEditorFontFamilyCourierNew:
            return @[
                     [UIFont fontWithName:@"CourierNewPSMT" size:fontSize],
                     [UIFont fontWithName:@"CourierNewPS-BoldMT" size:fontSize],
                     [UIFont fontWithName:@"CourierNewPS-ItalicMT" size:fontSize],
                     ];
            break;
        case kXXEditorFontFamilyMenlo:
            return @[
                     [UIFont fontWithName:@"Menlo" size:fontSize],
                     [UIFont fontWithName:@"Menlo-Bold" size:fontSize],
                     [UIFont fontWithName:@"Menlo-Italic" size:fontSize],
                     ];
            break;
        case kXXEditorFontFamilySourceCodePro:
            return @[
                     [UIFont fontWithName:@"SourceCodePro-Regular" size:fontSize],
                     [UIFont fontWithName:@"SourceCodePro-Bold" size:fontSize],
                     [UIFont fontWithName:@"SourceCodePro-It" size:fontSize],
                     ];
            break;
        case kXXEditorFontFamilySourceSansPro:
            return @[
                     [UIFont fontWithName:@"SourceSansPro-Regular" size:fontSize],
                     [UIFont fontWithName:@"SourceSansPro-Bold" size:fontSize],
                     [UIFont fontWithName:@"SourceSansPro-It" size:fontSize],
                     ];
            break;
        default:
            break;
    }
    return @[];
}

- (CGFloat)fontFamilySize {
    NSNumber *sizeObj = (NSNumber *)[self objectForKey:kXXStorageKeyFontFamilySize];
    if (!sizeObj) {
        sizeObj = [NSNumber numberWithFloat:14.f];
    }
    return [sizeObj floatValue];
}

- (void)setFontFamilySize:(CGFloat)fontFamilySize {
    [self setObject:[NSNumber numberWithFloat:fontFamilySize] forKey:kXXStorageKeyFontFamilySize];
}

- (BOOL)lineNumbersEnabled {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyLineNumbersEnabled] boolValue];
}

- (void)setLineNumbersEnabled:(BOOL)lineNumbersEnabled {
    [self setObject:[NSNumber numberWithBool:lineNumbersEnabled] forKey:kXXStorageKeyLineNumbersEnabled];
}

- (NSUInteger)tabWidth {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyTabWidth] unsignedIntegerValue];
}

- (void)setTabWidth:(NSUInteger)tabWidth {
    [self setObject:[NSNumber numberWithUnsignedInteger:tabWidth] forKey:kXXStorageKeyTabWidth];
}

- (BOOL)softTabsEnabled {
    return [(NSNumber *)[self objectForKey:kXXStorageKeySoftTabsEnabled] boolValue];
}

- (void)setSoftTabsEnabled:(BOOL)softTabsEnabled {
    [self setObject:[NSNumber numberWithBool:softTabsEnabled] forKey:kXXStorageKeySoftTabsEnabled];
}

- (BOOL)autoIndentEnabled {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyAutoIndentEnabled] boolValue];
}

- (void)setAutoIndentEnabled:(BOOL)autoIndentEnabled {
    [self setObject:[NSNumber numberWithBool:autoIndentEnabled] forKey:kXXStorageKeyAutoIndentEnabled];
}

- (BOOL)readOnlyEnabled {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyReadOnlyEnabled] boolValue];
}

- (void)setReadOnlyEnabled:(BOOL)readOnlyEnabled {
    [self setObject:[NSNumber numberWithBool:readOnlyEnabled] forKey:kXXStorageKeyReadOnlyEnabled];
}

- (BOOL)autoCorrectionEnabled {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyAutoCorrectionEnabled] boolValue];
}

- (void)setAutoCorrectionEnabled:(BOOL)autoCorrectionEnabled {
    [self setObject:[NSNumber numberWithBool:autoCorrectionEnabled] forKey:kXXStorageKeyAutoCorrectionEnabled];
}

- (BOOL)autoCapitalizationEnabled {
    return [(NSNumber *)[self objectForKey:kXXStorageKeyAutoCapitalizationEnabled] boolValue];
}

- (void)setAutoCapitalizationEnabled:(BOOL)autoCapitalizationEnabled {
    [self setObject:[NSNumber numberWithBool:autoCapitalizationEnabled] forKey:kXXStorageKeyAutoCapitalizationEnabled];
}

@end
