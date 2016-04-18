//
//  JWHomeTableViewController.m
//  JamWDev
//
//  Created by brendan kerr on 4/17/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWHomeTableViewController.h"

@interface JWHomeTableViewController()

@property (nonatomic) NSMutableArray *homeControllerData;

@end

@implementation JWHomeTableViewController


-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self readHomeMenuLists];
    
}



#pragma mark - TABLE VIEW DELEGATE

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
}





#pragma mark - FILE SYSTEM (THINKING ABOUT SINGLETON)

-(void)readHomeMenuLists {
    _homeControllerData = [[NSMutableArray alloc] initWithContentsOfURL:[self fileURLWithFileName:@"homeObjects"]];
    NSLog(@"home Controller URL: %@", [self fileURLWithFileName:@"homeObjects"]);
    [self serializeInJamTracks];
    //    NSLog(@"%s homeObjects %@",__func__,[_homeControllerSections description]);
    NSLog(@"%s HOMEOBJECTS [%ld]",__func__,(unsigned long)[_homeControllerData count]);
}


-(void)serializeInJamTrackNode:(id)jamTrackNode {
    id fileRelativePath = jamTrackNode[@"fileRelativePath"];
    if (fileRelativePath)
        jamTrackNode[@"fileURL"] =[self fileURLWithRelativePathName:fileRelativePath];
}



-(void)serializeInJamTracks {
    for (id objectSection in _homeControllerData) {
        id jamTracksInSection = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracksInSection) {
            id jamTrackNodes = jamTrack[@"trackobjectset"];
            for (id jamTrackNode in jamTrackNodes) {
                [self serializeInJamTrackNode:jamTrackNode];
            }
        }
    }
}


-(NSURL *)fileURLWithFileName:(NSString*)name {
    return [self fileURLWithFileName:name inPath:nil];
}

-(NSURL *)fileURLWithRelativePathName:(NSString*)pathName {
    NSURL *result;
    NSURL *baseURL = [NSURL fileURLWithPath:[self documentsDirectoryPath]];
    NSURL *url = [NSURL fileURLWithPath:pathName relativeToURL:baseURL];
    result = url;
    return result;
}


-(NSURL *)fileURLWithFileFlatFileURL:(NSURL*)flatURL{
    NSString *fileName = [flatURL lastPathComponent];
    NSArray *pathComponents = [flatURL pathComponents];
    __block NSUInteger indexToDocuments = 0;
    [pathComponents enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                         if ([obj isEqualToString:@"Documents"]) {
                                             indexToDocuments = idx;
                                             *stop = YES;
                                         }
                                     }];
    
    NSMutableArray *pathFromDocuments = [NSMutableArray new];
    // Iterate one past Documents til count -1 end slash
    for (NSUInteger i = (indexToDocuments + 1); i <  ([pathComponents count] - 1); i++) {
        [pathFromDocuments addObject:pathComponents[i]];
    }
    
    NSURL *result = [self fileURLWithFileName:fileName  inPath:pathFromDocuments];
    return result;
}



-(NSURL *)fileURLWithFileName:(NSString*)name inPath:(NSArray*)pathComponents{
    NSURL *result;
    NSURL *baseURL = [NSURL fileURLWithPath:[self documentsDirectoryPath]];
    NSString *pathString = @"";
    for (id path in pathComponents) {
        pathString = [pathString stringByAppendingPathComponent:path];
    }
    pathString = [pathString stringByAppendingPathComponent:name];
    NSURL *url = [NSURL fileURLWithPath:pathString relativeToURL:baseURL];
    result = url;
    return result;
}

-(NSString*)documentsDirectoryPath {
    NSString *result = nil;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    result = [searchPaths objectAtIndex:0];
    return result;
}



@end
