#import "CameraBoostprefs.h"

@implementation CameraBoostprefsListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.axs.cameraboost.plist"];
    if (!prefs[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return prefs[specifier.properties[@"key"]];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    [prefs addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.axs.cameraboost.plist"]];
    [prefs setObject:value forKey:specifier.properties[@"key"]];
    [prefs writeToFile:@"/var/mobile/Library/Preferences/com.axs.cameraboost.plist" atomically:YES];
    
    // 通知设置更改
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), 
                                        CFSTR("com.axs.cameraboost/preferencesChanged"), 
                                        NULL, NULL, YES);
}

#pragma mark - 备份/恢复
- (NSString *)documentsBackupDirectory {
    NSString *docs = @"/var/mobile/Documents/CameraBoost";
    [[NSFileManager defaultManager] createDirectoryAtPath:docs withIntermediateDirectories:YES attributes:nil error:nil];
    return docs;
}

- (void)exportPreferencesAction {
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.axs.cameraboost.plist";
    NSString *backupPath = [[self documentsBackupDirectory] stringByAppendingPathComponent:@"CameraBoost_Backup.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:prefsPath]) {
        NSError *error;
        if ([[NSFileManager defaultManager] copyItemAtPath:prefsPath toPath:backupPath error:&error]) {
            [self showToast:@"设置已备份到 Documents/CameraBoost/"];
        } else {
            [self showToast:@"备份失败"];
        }
    } else {
        [self showToast:@"没有找到设置文件"];
    }
}

- (void)importPreferencesAction {
    NSString *backupPath = [[self documentsBackupDirectory] stringByAppendingPathComponent:@"CameraBoost_Backup.plist"];
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.axs.cameraboost.plist";
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:backupPath]) {
        NSError *error;
        if ([[NSFileManager defaultManager] copyItemAtPath:backupPath toPath:prefsPath error:&error]) {
            [self showToast:@"设置已恢复"];
            [self reloadSpecifiers];
        } else {
            [self showToast:@"恢复失败"];
        }
    } else {
        [self showToast:@"没有找到备份文件"];
    }
}

- (void)zdyprefs {
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.axs.cameraboost.plist";
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"filza://"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"filza://%@", prefsPath]]];
    } else {
        [self showToast:@"请安装 Filza"];
    }
}

#pragma mark - 支持与链接
- (void)openSileoRepo {
    NSURL *url = [NSURL URLWithString:@"https://axs66.github.io/repo"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
        [self showToast:@"无法打开链接"];
    }
}

- (void)openTelegramChannel {
    NSURL *url = [NSURL URLWithString:@"https://t.me/wxfx8"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
        [self showToast:@"无法打开链接"];
    }
}

- (void)showToast:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CameraBoost" 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

@end
