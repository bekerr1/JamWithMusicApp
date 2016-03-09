//
//  JWActivityItemProvider.m
//  JamWDev
//
//  Created by JOSEPH KERR on 1/30/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWActivityItemProvider.h"

@implementation JWActivityItemProvider


-(id)item {

    id result;

    NSLog(@"%s %@ %@",__func__,self.activityType,[_fileURL lastPathComponent]);

    if ([self.activityType isEqualToString:UIActivityTypeAirDrop]) {
        NSLog(@"AIRDROP");
        _useData = NO;
    }
    else if ([self.activityType isEqualToString:UIActivityTypeMail]) {
        NSLog(@"MAIL");
        _useData = NO;
    }
    else if ([self.activityType isEqualToString:UIActivityTypeMessage]) {
        NSLog(@"MESSAGE");
        _useData = NO;
        
    }
    else if ([self.activityType isEqualToString:@"com.getdropbox.Dropbox.ActionExtension"]) {
        NSLog(@"DROPBOX");
        _useData = NO;
    }
    else if ([self.activityType isEqualToString:@"com.apple.mobilenotes.SharingExtension"]) {
        NSLog(@"NOTES");
        _useData = NO;
        
    }
    else{
        
    }
    
    if (_useData) {
        NSData *fileData = [NSData dataWithContentsOfFile:[_fileURL path]];
        result = fileData;
    } else {
        result =  _fileURL;
    }
    
    
    return result;
}


@end

/*
2016-01-30 13:55:00.896 JamWDev[2420:994279] -[JWActivityItemProvider item] com.apple.UIKit.activity.Mail clipRecording_035747CC-535C-4428-A093-430310359CFC.caf
2016-01-30 13:55:15.791 JamWDev[2420:992535] MAIL completed 0 (null)
2016-01-30 13:55:20.282 JamWDev[2420:994454] -[JWActivityItemProvider item] com.apple.UIKit.activity.Message clipRecording_035747CC-535C-4428-A093-430310359CFC.caf
2016-01-30 13:55:29.803 JamWDev[2420:992535] |warning| Got a keyboard will hide notification, but keyboard was not even present.
2016-01-30 13:55:30.341 JamWDev[2420:992535] |warning| Got a keyboard will hide notification, but keyboard was not even present.
2016-01-30 13:55:30.356 JamWDev[2420:992535] MESSAGE completed 0 (null)

*/