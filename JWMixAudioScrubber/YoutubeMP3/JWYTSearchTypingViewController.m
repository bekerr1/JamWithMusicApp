//
//  JWYTSearchTypingViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/19/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

/*
 ENTER text and search as you type
 currently disabled (buggy) will search on return
*/

#import "JWYTSearchTypingViewController.h"
#import "JWYouTubeSearchTypingData.h"
#import "JWYoutubeMP3ViewController.h"
#import "JWDBKeys.h"

@interface JWYTSearchTypingViewController () <UISearchBarDelegate, JWYoutubeMP3ViewDelegate> {
    NSString* _youtubeVideoId;
    NSString* _youtubeLinkWithoutId;
    NSString* _youtubeVideoCompleteURL;
    NSString* _youtubeVideoTitle;
    BOOL _newSearchResults;
    dispatch_queue_t _imageRetrievalQueue;
}
@property (nonatomic) JWYouTubeSearchTypingData* youTubeData;
@property (nonatomic) NSMutableArray* channelsDataArray;
@property (nonatomic) NSMutableDictionary* images;
@property (nonatomic) NSString* searchString;
@property (nonatomic) NSDate *lastKeyHitTimeStamp;
@property NSIndexPath *selectedDetailIndexPath;
@property (strong, nonatomic) IBOutlet UISearchBar *youTubeSearchQuery;
@end


//        _youtubeLinkWithoutId = https: //www.youtube.com/watch?v=";
//        _youtubeLinkWithoutId = https: //www.youtube.com/";



@implementation JWYTSearchTypingViewController

-(JWYouTubeSearchTypingData *)youTubeData {
    if (!_youTubeData) {
        _youTubeData = [JWYouTubeSearchTypingData new];
        _youtubeLinkWithoutId = @"http://youtu.be/";
    }
    
    return _youTubeData;
}

- (void)viewDidLoad {

    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    if (_imageRetrievalQueue == nil)
        _imageRetrievalQueue =
        dispatch_queue_create("imageProcessing",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_USER_INTERACTIVE, 0));

    _channelsDataArray = [[NSMutableArray alloc] init];
    _images = [@{} mutableCopy];
    _newSearchResults = YES;
    if (_searchTerm)
        _searchString = _searchTerm;
    _youTubeSearchQuery.text = _searchString;
    _youTubeSearchQuery.delegate = self;
    [_youTubeSearchQuery becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    NSLog(@"%s",__func__);
    [super didReceiveMemoryWarning];
}

#pragma mark - Delegate

-(void)finishedTrim:(JWYoutubeMP3ViewController *)controller withTrimKey:(NSString*)trimKey forKey:(NSString*)key {
    if ([_delegate respondsToSelector:@selector(finishedTrim:withDBKey:)])
        [_delegate finishedTrim:self withDBKey:trimKey];
}

-(void)finishedTrim:(JWYoutubeMP3ViewController *)controller withTrimKey:(NSString*)trimKey title:(NSString*)title forKey:(NSString*)key {
    if ([_delegate respondsToSelector:@selector(finishedTrim:title:withDBKey:)])
        [_delegate finishedTrim:self title:title withDBKey:trimKey];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = 0;
    NSUInteger more = 0;
    @synchronized(_channelsDataArray) {
        if (self.channelsDataArray.count > 0)
            more = 1;
        result = self.channelsDataArray.count + more;
    }
    return result;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *titleStr;
    NSUInteger count = 0;
    
    @synchronized(_channelsDataArray) {
        count = [_channelsDataArray count];
    }
    
    if (count > 0)
        titleStr = [NSString stringWithFormat:@"Search Results %ld videos",count];
    else
        titleStr = _newSearchResults ? @"Search Results" : [NSString stringWithFormat:@"Search Results %ld videos",count];

    return titleStr;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JWYoutubeSearchResultCell" forIndexPath:indexPath];

    @synchronized(_channelsDataArray) {
        
        if (indexPath.row < self.channelsDataArray.count) {
            
            NSDictionary* ytVideoInfo = self.channelsDataArray[indexPath.row];
            id description = ytVideoInfo[@"ytdescriptionsnippet"];
            cell.textLabel.text = [ytVideoInfo valueForKey:(NSString*)JWDbKeyVideoTitle];
            cell.detailTextLabel.text = description;
            
            _youtubeVideoTitle = [self.channelsDataArray[indexPath.row] valueForKey:(NSString*)JWDbKeyVideoTitle];
            @synchronized(_images) {
                cell.imageView.image = _images[ ytVideoInfo[@"ytvideoid"] ];
            }
            
        } else {
            cell.textLabel.text = @"Load More ...";
            cell.detailTextLabel.text = @"if you dare";
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row < self.channelsDataArray.count) {
        _youtubeVideoId = [self.channelsDataArray[indexPath.row] valueForKey:@"ytvideoid"];
        _youtubeVideoCompleteURL = [_youtubeLinkWithoutId stringByAppendingString:_youtubeVideoId];
        _youtubeVideoTitle = [self.channelsDataArray[indexPath.row] valueForKey:(NSString*)JWDbKeyVideoTitle];
        
        [self performSegueWithIdentifier:@"JWYoutubeSearchToMP3Segue" sender:nil];
    } else {
        _newSearchResults = NO;
        [self getYoutubeDataFromSearchText:_searchString];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.selectedDetailIndexPath = indexPath;
    [self detailInfo];
}

#pragma mark -

-(void)detailInfo {
    
    if (_selectedDetailIndexPath.row < self.channelsDataArray.count) {
        NSDictionary* ytVideoInfo = self.channelsDataArray[_selectedDetailIndexPath.row];

        NSString *title;
        NSMutableString *message = [NSMutableString new];
        NSString *videoTitleValue = ytVideoInfo[JWDbKeyVideoTitle];
        if  (videoTitleValue)
            title = [NSString stringWithFormat:@"Youtube Video\n %@",videoTitleValue];
        else
            title = @"Youtube Video";
        
        id description = ytVideoInfo[@"ytdescriptionsnippet"];
        if (description) {
            [message appendString:@"\n"];
            [message appendString:description];
        }
        
        id videoId = ytVideoInfo[@"ytvideoid"];
        if (videoId) {
            [message appendString:@"\n\n"];
            [message appendString:[NSString stringWithFormat:@"Youtube Videoid %@",videoId]];
        }
        
        [self detailInfoAlertController:title message:message];
    }
}

-(void)detailInfoAlertController:(NSString*)title message:(NSString*)message {
    
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okAction =
    [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        self.selectedDetailIndexPath = nil;
    }];
    [actionController addAction:okAction];
    [self presentViewController:actionController animated:YES completion:nil];
}


#pragma mark -

-(void)cleanupImageCache {
    
    NSMutableArray *deleteItems = [@[] mutableCopy];
    NSUInteger beforeCount = [_images count];
    
    @synchronized(_images) {
        for (id item in [_images allKeys]) {
            
            NSUInteger index = NSNotFound;
            @synchronized(_channelsDataArray) {
                index = [_channelsDataArray indexOfObjectPassingTest:
                         ^BOOL(NSDictionary *dict, NSUInteger idx, BOOL *stop){
                             return [[dict objectForKey:@"ytvideoid"] isEqualToString:item];
                         }
                         ];
            }
            
            if (index == NSNotFound) {
                //                NSLog(@"%s delete image",__func__);
                [deleteItems addObject:item];
            } else{
                //                NSLog(@"%s keep image",__func__);
            }
        }
    }
    
    //    NSUInteger count = 0;
    //    for (id item in _channelsDataArray) {
    //        NSLog(@"%s %02ld %@",__func__,count++,item[@"ytvideoid"]);
    //    }
    
    NSLog(@"%s delete %ld images",__func__,[deleteItems count]);
    
    @synchronized(_images) {
        [_images removeObjectsForKeys:deleteItems];
        NSLog(@"%s  %ld images , was %ld images ",__func__,[_images count],beforeCount);

    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
    
    
    //    [self.tableView reloadData];
    
}

// ReRetrieve for all items
//    NSUInteger index = 0;
//    for (id channelItem in _channelsDataArray) {
//        NSString *youtubeVideoId = [channelItem valueForKey:@"ytvideoid"];
//        dispatch_async(_imageRetrievalQueue, ^{
//
//            UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[channelItem valueForKey:@"thumbnail"]]]];
//            if (youtubeThumb) {
//                @synchronized(_images) {
//                    self.images[youtubeVideoId] = youtubeThumb;
//                }
//            } else {
//                NSLog(@"%s image unavailable %@ %@",__func__,youtubeVideoId,[channelItem valueForKey:@"thumbnail"]);
//            }
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.tableView beginUpdates];
//                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//                [self.tableView endUpdates];
//            });
//        });
//        index++;
//    }



-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.lastKeyHitTimeStamp = nil;
    [self cleanupImageCache];
    self.searchString = [NSString stringWithString:searchBar.text];
    _searchTerm = _searchString;
    [_delegate searchTermChanged:self];
    [searchBar resignFirstResponder];
    @synchronized(_channelsDataArray) {
        [self.channelsDataArray removeAllObjects];
    }
    _newSearchResults = YES;

    [self.tableView reloadData];
    [self getYoutubeDataFromSearchText:_searchString];
}

-(void)textFieldDidChange:(id)sender
{
    
    return;
}
/*
 WIP
    NSLog(@"%s %@",__func__,[(UITextField*)sender text]);
    
    self.lastKeyHitTimeStamp = [NSDate date];

    self.searchString = [(UITextField*)sender text];

    // SEND out the probes for no key hit
    NSTimeInterval maxIntervalBeforeSearch = 0.7500;
    
    double delayInSecs = maxIntervalBeforeSearch + .001;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSTimeInterval interval = 0.000f;
        if (self.lastKeyHitTimeStamp) {
            if (interval < - maxIntervalBeforeSearch) {  // longer than
                
//                NSTimeInterval interval = [self.lastKeyHitTimeStamp timeIntervalSinceNow]; // is negative go back in time
                
                [self doYoutubeSearch];
                NSLog(@"YOUTUBE Search first one");
            } else {
                
                double delayInSecs = 0.2;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.lastKeyHitTimeStamp) {
                        NSTimeInterval interval = [self.lastKeyHitTimeStamp timeIntervalSinceNow]; // is negative go back in time
                        if (interval < - maxIntervalBeforeSearch) {  // longer than
                            [self doYoutubeSearch];
                            NSLog(@"YOUTUBE Search second one");
                        } else {
                            
                            double delayInSecs = 0.2;
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if (self.lastKeyHitTimeStamp) {
                                    NSTimeInterval interval = [self.lastKeyHitTimeStamp timeIntervalSinceNow]; // is negative go back in time
                                    if (interval < - maxIntervalBeforeSearch) {  // longer than
                                        [self doYoutubeSearch];
                                        NSLog(@"YOUTUBE Search third one");
                                    }
                                }
                            });
                        }
                    }
                });
                
            }
        }
    });
}
*/

-(void)doYoutubeSearch {

    _newSearchResults = YES;
    @synchronized(_channelsDataArray) {
        [self.channelsDataArray removeAllObjects];
    }
    [self.tableView reloadData];
    [self getYoutubeDataFromSearchText:_searchString];
}

//#define TRACEIMAGE

//    NSString* modifiedString = [text stringByReplacingOccurrencesOfString:@" " withString:@"+"];

-(void)getYoutubeDataFromSearchText:(NSString *)text {
    
    NSString *modifiedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                              NULL,(CFStringRef)text,
                                                              NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8 ));
  
    [self.youTubeData initWebDataKeyWithSearchString:modifiedString newSearch:_newSearchResults];
    
    [self.youTubeData getSearchKeywordDetailsWithString:text newSearch:_newSearchResults onCompletion:
     ^(NSMutableArray* channelData,NSString* searchStr) {
         
         //        NSUInteger count = [self.channelsDataArray count];  // get the index before adding
         
         if ([searchStr isEqualToString:self.searchString]) {
             
#ifdef TRACEIMAGE
             for (id channelItem in channelData) {
                 NSLog(@"%@",[channelItem valueForKey:@"ytvideoid"]);
             }
#endif
             @synchronized(_channelsDataArray) {
                 _channelsDataArray = channelData;
//                 [_channelsDataArray addObjectsFromArray:channelData];
             }
             
             NSUInteger countAlreadyHas = 0;
             NSUInteger retrieveCount = 0;
             NSUInteger index = 0;
             @synchronized(_channelsDataArray) {
                 
                 index = 0;
                 
                 for (id channelItem in _channelsDataArray) {
                     NSString *youtubeVideoId = [channelItem valueForKey:@"ytvideoid"];
                     id obj;
                     @synchronized(_images) {
                         obj = _images[youtubeVideoId];
                     }
                     if (obj) {
#ifdef TRACEIMAGE
//                         NSLog(@"already has image");
#endif
                         countAlreadyHas++;
                         // already have image
                         
                     } else {
#ifdef TRACEIMAGE
                         NSLog(@"retrieve %ld %@ image %@",index,youtubeVideoId,[channelItem valueForKey:@"thumbnail"]);
#endif
                         retrieveCount++;
                         
                         dispatch_async(_imageRetrievalQueue, ^{
                             UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                                             [NSURL URLWithString:[channelItem valueForKey:@"thumbnail"]]]];
                             @synchronized(_images) {
                                 self.images[youtubeVideoId] = youtubeThumb;
                             }
                             
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 NSUInteger index = NSNotFound;
                                 @synchronized(_channelsDataArray) {
                                     index = [_channelsDataArray indexOfObjectPassingTest:
                                              ^BOOL(NSDictionary *dict, NSUInteger idx, BOOL *stop){
                                                  return [[dict objectForKey:@"ytvideoid"] isEqualToString:youtubeVideoId];
                                              }];
                                 }
                                 if (index == NSNotFound) {
                                     //                NSLog(@"%s delete image",__func__);
                                 } else{
                                     //                NSLog(@"%s keep image",__func__);
                                     [self.tableView beginUpdates];
                                     [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                                           withRowAnimation:UITableViewRowAnimationFade];
                                     [self.tableView endUpdates];
                                 }
                             });
                         });
                     }
                     
                     index++;
                 }  // for
                 
                 
             } // synchronozed
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.tableView reloadData];
             });

             NSLog(@"%ld already has images",countAlreadyHas);
             NSLog(@"%ld retrieve images",retrieveCount);
             
         } else {
             // Not interested in these results
             NSLog(@"Searchstr is DIFFERENT");
         }
     }];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"JWYoutubeSearchToMP3Segue"]) {
        
        JWYoutubeMP3ViewController* youtubeMP3ViewController = (JWYoutubeMP3ViewController *)segue.destinationViewController;
        [youtubeMP3ViewController setUrlSessionYoutubeString:_youtubeVideoCompleteURL videoId:_youtubeVideoId andVideoTitle:_youtubeVideoTitle];
        youtubeMP3ViewController.youTubeLinkURL = [NSURL URLWithString:_youtubeVideoCompleteURL];
        youtubeMP3ViewController.tapToJam = YES;
        youtubeMP3ViewController.delegate = self;
    }
}

@end

