//
//  JWFileTransferActivity.m
//  JamWDev
//
//  Created by JOSEPH KERR on 1/30/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWFileTransferActivity.h"
#import "JWActivityItemProvider.h"

@interface JWFileTransferActivity () <UIDocumentInteractionControllerDelegate>
@property (nonatomic) NSArray *items;
@property (nonatomic)  UIDocumentInteractionController *interactionControllerRef;
@end


@implementation JWFileTransferActivity

-(NSString*)activityType {
    return @"com.joker.openInApp";
}

-(NSString*)activityTitle {
    return @"Open in ..";
}

-(UIImage*)activityImage {
    return [UIImage imageNamed:@"scrub_sq100_enh.png"];
}

-(BOOL)canPerformWithActivityItems:(NSArray*)activityItems {
    BOOL result = YES;
    
    return result;
}

-(void)prepareWithActivityItems:(NSArray*)activityItems {
 // UI perhaps, and refer
    self.items = activityItems;
    NSLog(@"  activityItems %@",@([activityItems count]));
}

+(UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

-(void)performActivity {
    
    for (id activity in _items) {
        NSLog(@"  activity %@",[activity description]);
        
        UIDocumentInteractionController *interactionController = [self setupControllerWithURL:(NSURL*)activity usingDelegate:self];
        interactionController.UTI = @"public.audio";
        interactionController.name = [(NSURL*)activity lastPathComponent];
        self.interactionControllerRef = interactionController;
        [interactionController presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
    }
    
//    UIDocumentInteractionController *interactionController = [self setupControllerWithURL:self.fileURL usingDelegate:self];
//    interactionController.UTI = @"public.audio";
//    interactionController.name = [_fileURL lastPathComponent];
//    self.interactionControllerRef = interactionController;
//    [interactionController presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
}


-(UIViewController*)activityViewController {

    return nil;

//    UIViewController *vc = [UIViewController new];
//    vc.view.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
//    return vc;
}

#pragma mark - documentInteractionController

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    NSLog(@"%s",__func__);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self activityDidFinish:YES];
//    });
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
           didEndSendingToApplication:(NSString *)application {
    NSLog(@"%s %@",__func__,application);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self activityDidFinish:YES];
    });
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(nullable NSString *)application {
    NSLog(@"%s %@",__func__,application);
}

- (UIDocumentInteractionController *) setupControllerWithURL: (NSURL*) fileURL
                                               usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate {
    
    UIDocumentInteractionController *interactionController =
    [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;
    return interactionController;
}


#pragma mark activity

-(void)activityActionDocument {
    //    NSURL *fileURL;
    //    if ([self.trackItems count] > 0) {
    //        id item = _trackItems[0];
    //        fileURL = item[@"fileURL"];
    //    }
    UIDocumentInteractionController *interactionController = [self setupControllerWithURL:self.fileURL usingDelegate:self];
    interactionController.UTI = @"public.audio";
    interactionController.annotation = @{@"url":self.fileURL};
    //    interactionController.UTI = @"public.caf";
    //    interactionController.UTI = @"com.apple.coreaudio-format";
    //    interactionController. = @"public.caf";
    [interactionController presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
    //    [interactionController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
}


@end
