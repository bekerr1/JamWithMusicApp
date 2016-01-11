//
//  ViewController.m
//  JamWithV1.0
//
//  Created by brendan kerr on 9/4/15.
//  Copyright (c) 2015 b3k3r. All rights reserved.
//

#import "JWYoutubeMP3ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "JWCurrentWorkItem.h"
#import "JWSourceAudioFilesTableViewController.h"
#import "JWYouTubeVideoData.h"
#import "JWClipAudioViewController.h"
#import "JWDBKeys.h"
#import "JWFileDowloadController.h"
#import "JWYoutubeMP3ConvertController.h"
#import "JWFileController.h"

const NSString *JWDbKeyDownloadLink = @"downloadlink";
const NSString *JWDbKeyVideoTitle = @"videoTitle";
const NSString *JWDbKeyYouTubeData = @"ytdata";
const NSString *JWDbKeyYouTubeTitle = @"yttitle";
const NSString *JWDbKey = @"dbkey";
const NSString *JWDbKeyCreationDate = @"created";
const NSString *JWDbKeyYouTubeLinkStr = @"linkstr";
const NSString *JWDbKeyArtist = @"artist";  // JW Proprietary not Youtube
const NSString *JWDbKeyYouTubeVideoId = @"videoId";
const NSString *JWDbKeyYoutubeThumbnails = @"ytthumbnails";
const NSString *JWDbKeyYoutubeThumbnailMedium = @"ytdataimageurlm";
const NSString *JWDbKeyYoutubeThumbnailDefault = @"ytdataimageurld";
const NSString *JWDbKeyYoutubeThumbnailHigh = @"ytdataimageurlh";
const NSString *JWDbKeyYoutubeThumbnailMaxres = @"ytdataimageurlmax";


@interface JWYoutubeMP3ViewController () <JWYoutubeMP3ConvertDelegate, JWClipAudioViewDelegate>
{
    BOOL pasting;
    AVAudioEngine * _engine;
    AVAudioPlayer * _audioPlayer;
    UIColor * _startupColor;
    BOOL _showsYoutubeMP3;
    BOOL _useSwipeDownToReConvert;
    BOOL _useLongPressToPaste;
    BOOL _proceedForwardOnSuccess;
    float _convertProgressOfTotal;  // each progress of total must equal 1
    float _downloadProgressOfTotal;  // maybe convert is .20 and download is .80
    dispatch_queue_t _imageRetrievalQueue;
}
@property (nonatomic) NSString* youtubeString;
@property (nonatomic) NSString* videoTitle;
@property (nonatomic) NSString* youtubeVideoId;
@property (strong, nonatomic) NSMutableDictionary *linksDirector;
@property (strong, nonatomic) NSMutableDictionary *mp3FilesInfo;
@property (strong, nonatomic) NSMutableDictionary *mp3FilesDescriptions;
@property (nonatomic) NSURL *currentMP3FileURL;
@property (nonatomic) NSString *currentCacheItem;
@property (strong, nonatomic) IBOutlet UIView *avPlayerView;
@property (nonatomic) AVPlayerViewController *avPlayerViewController;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webviewHeightConstraint;
@property (strong, nonatomic) IBOutlet UIVisualEffectView *effectsView;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic)  JWYoutubeMP3ConvertController *mp3ConvertController;
@property (strong, nonatomic)  JWFileDowloadController *downloadController;
@end


@implementation JWYoutubeMP3ViewController

- (void)viewDidLoad {
    
    _startupColor = self.view.backgroundColor;
    
    [super viewDidLoad];

    _showsYoutubeMP3 = NO;
    _proceedForwardOnSuccess = NO;
    _convertProgressOfTotal = .20f;
    _downloadProgressOfTotal = .80f;
    
    
    _mp3FilesInfo = [[JWFileController sharedInstance] mp3FilesInfo];
    _linksDirector = [[JWFileController sharedInstance] linksDirector];
    
//    [self readMetaData];
//    if (! _mp3FilesInfo)
//        self.mp3FilesInfo = [NSMutableDictionary new];
//    if (! _linksDirector)
//        self.linksDirector = [NSMutableDictionary new];
    
    [self.activity stopAnimating];
    self.effectsView.hidden = NO;
    self.webView.hidden = YES;
    self.imageView.hidden = YES;
//    self.activity.transform = CATransform3DGetAffineTransform(CATransform3DMakeScale(3.0, 3.0, 1.0));
    self.progressView.transform = CATransform3DGetAffineTransform(CATransform3DMakeScale(1.0, 11.2, 1.0));
    self.progressView.progress = 0.0;
    self.progressView.hidden = YES;
    self.imageView.layer.borderWidth = 3.2f;
    self.imageView.layer.borderColor = [[UIColor blueColor] colorWithAlphaComponent:0.70f].CGColor;
    self.imageView.layer.cornerRadius = 12.0f;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;

    self.mp3ConvertController = [[JWYoutubeMP3ConvertController alloc] initWithWebview:_webView andDelegate:self];
    
    if (_imageRetrievalQueue == nil) {
        _imageRetrievalQueue =
        dispatch_queue_create("imageProcessingYoutubeMP3",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_UTILITY, 0));
    }

    //    [self newSessionWithLinkURLString:_youtubeString andVideoTitle:_videoTitle];
    // TODO: brendan lets use below sett the linkurl
    
    if (_youTubeLinkURL ) {
        
        [self newSessionWithLinkURLString:[_youTubeLinkURL absoluteString]];
  
    } else {
        // not given link try to obtain active one
        NSString *dbkey = [[NSUserDefaults standardUserDefaults] valueForKey:@"currentItem"];
        if (dbkey) {
            //[self.activity startAnimating];
            // resume with key
            self.currentCacheItem = dbkey;
            self.currentMP3FileURL = [self fileURLForCacheItem:dbkey];
            [JWCurrentWorkItem sharedInstance].currentAudioFileURL = _currentMP3FileURL;
        } else {
            [self.activity stopAnimating];
        }
    }
    
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.isMovingToParentViewController) {
        // The first time when it is moving to the container
        NSLog(@"%s MOVINGTO",__func__);
    } else {
        // Every other time
        NSLog(@"%s STAYING",__func__);

        [self finalStatusMessage:self.currentCacheItem];
        
        if (self.imageView.image == nil) {
            id mp3DataRecord = _mp3FilesInfo[_currentCacheItem];
            if (mp3DataRecord) {
                NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
                dispatch_async(_imageRetrievalQueue, ^{
                    UIImage* youtubeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.imageView.image =youtubeImage;
                        self.imageView.hidden = NO;
                    });
                });
            }
        }  // imge = nil
        
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        // The first time when it is moving to the container
        NSLog(@"%s LEAVING",__func__);
        
        [_downloadController cancel];
        
    } else {
        // Every other time
        NSLog(@"%s STAYING",__func__);
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"%s",__func__);
    
    if ([segue.identifier isEqualToString:@"AVPlayerView"]) {
        self.avPlayerViewController = (AVPlayerViewController*)segue.destinationViewController;
        
    } else if ([segue.identifier isEqualToString:@"JWFileList"]) {
        JWSourceAudioFilesTableViewController *sourceAudioTableViewController = (JWSourceAudioFilesTableViewController*)segue.destinationViewController;
        sourceAudioTableViewController.previewMode = YES;
        
    } else if ([segue.identifier isEqualToString:@"JWMP3DownloadToClipEngineSegue"]) {
        
        id mp3DataRecord = _mp3FilesInfo[_currentCacheItem];
        NSString *title = mp3DataRecord ? mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeTitle] : @"unknown";
        
        JWClipAudioViewController *clipController = (JWClipAudioViewController*)segue.destinationViewController;
        clipController.trackName = title;
        clipController.thumbImage = self.imageView.image;
        clipController.delegate = self;
        
        NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
        if (imageURL) {
            NSLog(@"DISPATCH %@",[imageURL absoluteString]);
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    clipController.thumbImage = youtubeThumb;
                });
            });
        }
    }
    
    self.view.backgroundColor = _startupColor;
}


#pragma mark - JWCLipAudioViewDelegate


// passes the new key for the trimmed files
-(void)finishedTrim:(JWClipAudioViewController *)controller withDBKey:(NSString*)key {
    
    id mp3DataRecord = _mp3FilesInfo[_currentCacheItem];
    if (mp3DataRecord) {
        id trimmedFilesValue = mp3DataRecord[@"trimmedfilekeys"];
        if (trimmedFilesValue){
            [(NSMutableArray*)trimmedFilesValue addObject:key];
        } else {
            mp3DataRecord[@"trimmedfilekeys"] = [@[key] mutableCopy];
        }
    }

//    if ([_delegate respondsToSelector:@selector(finishedTrim:withTrimKey:forKey:)]) {
//        [_delegate finishedTrim:self withTrimKey:key forKey:_currentCacheItem];
//    }
    
    NSString * title = nil;
    id ytData = mp3DataRecord[JWDbKeyYouTubeData];
    if (ytData) {
        id titleValue = ytData[JWDbKeyYouTubeTitle];
        if (titleValue)
            title = titleValue;
    }

    if ([_delegate respondsToSelector:@selector(finishedTrim:withTrimKey:title:forKey:)]) {
        [_delegate finishedTrim:self withTrimKey:key title:title forKey:_currentCacheItem];
    }
    
}

#pragma mark -


- (IBAction)didTap:(id)sender {
    
    if (self.currentMP3FileURL) {
        [self proceedForwardAction:nil];
    } else {
        [self effectsBackgroundError];
    }
}

-(void)proceedForwardAction:(NSString *)dbkey {

    if (_tapToJam) {
        [self performSegueWithIdentifier:@"JWMP3DownloadToClipEngineSegue" sender:self];
        
    } else {
        (self.currentMP3FileURL) ? [self playFile] : [self effectsBackgroundError];
    }
}

- (IBAction)didSwipeLeft:(id)sender
{
    [self performSegueWithIdentifier:@"JWFileList" sender:self];
}

#pragma mark -

-(void)setUrlSessionYoutubeString:(NSString *)youtubeString videoId:(NSString *)videoId andVideoTitle:(NSString *)videoTitle {
    NSLog(@"%s %@ %@ %@",__func__,youtubeString,videoId,videoTitle );
    _youtubeVideoId = videoId;
    _youtubeString = youtubeString;
    _videoTitle = videoTitle;
}

-(void)setUrlSessionYoutubeString:(NSString *)youtubeString andVideoTitle:(NSString *)videoTitle {
    [self setUrlSessionYoutubeString:youtubeString videoId:nil andVideoTitle:videoTitle];
}

-(void) newSessionWithLinkURLString:(NSString*)linkURLStr {
    NSLog(@"%s %@",__func__,linkURLStr);
    [self newSessionWithLinkURLString:linkURLStr andVideoTitle:nil];
}

-(void) newSessionWithLinkURLString:(NSString*)linkURLStr andVideoTitle:(NSString *)videoTitle {
    NSLog(@"%s %@",__func__,linkURLStr);
    if (!linkURLStr)
        return;

    // Init UI for begin process
    
    self.avPlayerView.hidden = YES;
    self.webView.hidden = YES;
    self.effectsView.hidden = NO;

    BOOL doesConvert = YES;
    BOOL doesDownload = NO;
    BOOL doesFile = NO;
    
    NSURL *downLoadLinkURL;
    
    NSString *dbkey = [self cacheItemForLinkStr:linkURLStr andVideoTitle:videoTitle];
    
    if (dbkey){
        
        self.currentCacheItem = dbkey;
        id mp3DataRecord = _mp3FilesInfo[dbkey];
        if (mp3DataRecord) {
            
            NSLog(@"%s FOUND RECORD %@",__func__,[mp3DataRecord description]);
            NSURL *fileURL = [self fileURLForCacheItem:dbkey];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]){
                doesFile = YES;
                doesConvert = NO;
                NSLog(@"%s FILE EXIST",__func__);
            } else {
                NSLog(@"%s FILE DOES NOT EXIST",__func__);
            }
            
            id downloadLink = mp3DataRecord[JWDbKeyDownloadLink];
            if (downloadLink) {
                NSLog(@"%s LINK EXIST",__func__);
                doesDownload = YES;
                doesConvert = NO;
                downLoadLinkURL = [NSURL URLWithString:downloadLink];
            } else {
                NSLog(@"%s LINK DOES NOT EXIST",__func__);
            }
            
            // check for status of existing info
            // decide if we have the file, need to download or reconvert
        }
    }

    
    // Decide to GET YouTube DATA for video
    // and init controllers depending on next process
    // convert file download
    
    BOOL retrieveYoutubeData = YES;
    
    if (doesConvert) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.webviewHeightConstraint.constant = 128; // shows converted
            self.statusLabel.text = [NSString stringWithFormat:@"Converting to MP3"];
        });
        
        [_mp3ConvertController prepareToBeginNewSessionWithLinkURL:[NSURL URLWithString:linkURLStr] forDbKey:dbkey];
        
    } else {
        
        id ytdata = _mp3FilesInfo[dbkey][JWDbKeyYouTubeData];
        // if no ytdata then retrieve is YES
        if (ytdata )
            retrieveYoutubeData = NO;

        if (doesFile) {

            [self setBestImageForDbKey:dbkey];

            NSURL *fileURL = [self fileURLForCacheItem:dbkey];
            NSString* fileTitle = [(NSDictionary *)_mp3FilesInfo valueForKey:(NSString*)JWDbKeyVideoTitle];
            [JWCurrentWorkItem sharedInstance].currentAudioFileURL = fileURL;
            [JWCurrentWorkItem sharedInstance].currentAudioTitle  = fileTitle;
            [JWCurrentWorkItem sharedInstance].timeStamp = [NSDate date];
            self.currentMP3FileURL = fileURL;

            NSLog(@"\nUSES EXISTING FILE %@",[_currentMP3FileURL lastPathComponent]);
            
        } else if (doesDownload) {
            
            [self.activity stopAnimating];
            self.progressView.hidden = NO;
            _convertProgressOfTotal = 0.0f;
            _downloadProgressOfTotal = 1.0f;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = [NSString stringWithFormat:@"Downloading MP3"];
            });
            NSLog(@"\nUSES EXISTING DOWNLOAD LINK\n");

        } else {
            NSLog(@"\nUSES UNKNOWN\n");
        }
    }


    // are we gonna use the current file
    // or download from the link recorded
    // or all with the convert process which does all three

    if  (retrieveYoutubeData) {
        
        // retrieveYoutubeData methods are called and oncompletion there proceed normally

        if (_mp3FilesDescriptions == nil) {
            [self readDescriptions]; // from file
            if (! _mp3FilesDescriptions)
                self.mp3FilesDescriptions = [NSMutableDictionary new];
        }
        
        // GET YouTube DATA for video

        NSString *videoId = _youtubeVideoId ? _youtubeVideoId : [linkURLStr lastPathComponent];
        
        if (doesConvert) {
            [self retrieveYoutubeDataDoesConvert:dbkey videoId:videoId linkURLString:linkURLStr andTitle:videoTitle];
        } else {
            if (doesFile) {
                [self retrieveYoutubeDataDoesFile:dbkey videoId:videoId];
            } else if (doesDownload) {
                [self retrieveYoutubeDataDoesDownload:dbkey videoId:videoId downloadLinkURL:downLoadLinkURL];
            }
        }
        
    } else {
         // do not retrieveYoutubeData
        // Since we are not retrieving youtube data we need to proceed normally
        // the same on the completion of retrieving youtube data
        
        if (doesFile) {
            if (_proceedForwardOnSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusLabel.text = @"";
                    [self proceedForwardAction:dbkey];
                });
            } else {
                
                [self finalStatusMessage:dbkey];
            }
            
        } else if (doesDownload) {
            
            [self setBestImageForDbKey:dbkey];
            
            [self downloadTask:downLoadLinkURL  dbKey:dbkey];
        }
    }

}



-(void)setBestImageForDbKey:(NSString*)dbkey {
    
    id mp3DataRecord = _mp3FilesInfo[dbkey];
    if (mp3DataRecord) {
        NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
        if (imageURL) {
            NSLog(@"DISPATCH %@",[imageURL absoluteString]);
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image =youtubeImage;
                    self.imageView.hidden = NO;
                });
            });
        }
    }
}

-(NSURL*)bestImageURLForMP3Record:(NSDictionary*)mp3DataRecord {
    if (mp3DataRecord == nil) {
        return nil;
    }
    id urlStr;
//    urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMaxres];
//    if (!urlStr)
        urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailHigh];
    if (!urlStr)
        urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMedium];
    if (!urlStr)
        urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailDefault];
    
//    urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"high"][@"url"];
//    if (!urlStr)
//        urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"medium"][@"url"];
//    if (!urlStr)
//        urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"medium"][@"url"];
    
    NSURL *imageURL = urlStr ? [NSURL URLWithString:urlStr] : nil;
    
    NSLog(@"%s %@",__func__,[imageURL absoluteString]);
    return imageURL;
}

#pragma mark - retrieveYoutubeData methods

-(void) retrieveYoutubeDataDoesDownload:(NSString*)dbkey videoId:(NSString*)videoId downloadLinkURL:(NSURL*)downLoadLinkURL{

    NSLog(@"%s %@ [%@]",__func__,videoId,dbkey);
    
    // GET YouTube DATA for video - on completion proceed to use file
    
    JWYouTubeVideoData *videoDataRetriever = [[JWYouTubeVideoData alloc] initWithVideoId:videoId];
    
    [videoDataRetriever getVideoDataOnCompletion:^(NSArray *videoDataResult){
        
        id responseData = videoDataResult[0];
        id errorInResponse = [responseData valueForKey:@"statuscode"];
        if (errorInResponse) {
            NSLog(@"%s ERROR response%@",__func__,[responseData description]);
        } else {
            
            [self processTheYoutubeDataRecord:responseData forDbKey:dbkey];
//            [self saveMetaData];
            [[JWFileController sharedInstance] saveMeta];
            [self saveDescriptions];
        }
        
        [self downloadTask:downLoadLinkURL  dbKey:dbkey];
    }];
}


-(void) retrieveYoutubeDataDoesFile:(NSString*)dbkey videoId:(NSString*)videoId{
    
    NSLog(@"%s %@ [%@]",__func__,videoId,dbkey);
    
    // GET YouTube DATA for video - on completion proceed to download
    
    JWYouTubeVideoData *videoDataRetriever = [[JWYouTubeVideoData alloc] initWithVideoId:videoId];
    
    [videoDataRetriever getVideoDataOnCompletion:^(NSArray *videoDataResult){
        
        id responseData = videoDataResult[0];
        id errorInResponse = [responseData valueForKey:@"statuscode"];
        if (errorInResponse) {
            NSLog(@"%s ERROR response%@",__func__,[responseData description]);
        } else {
            [self processTheYoutubeDataRecord:responseData forDbKey:dbkey];
//            [self saveMetaData];
            [[JWFileController sharedInstance] saveMeta];
            [self saveDescriptions];
        }
        
        if (_proceedForwardOnSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // no need for a message we are moving forward, no time to waste
                self.statusLabel.text = @"";
                [self proceedForwardAction:dbkey];
            });
        } else {
            
            [self finalStatusMessage:dbkey];
        }
    }];
    
}


-(void) retrieveYoutubeDataDoesConvert:(NSString*)dbkey videoId:(NSString*)videoId linkURLString:(NSString*)linkURLStr andTitle:(NSString*)videoTitle {
    
    NSLog(@"%s %@ [%@]",__func__,videoId,dbkey);
    
    // GET YouTube DATA for video - on completion proceed to convert
    
    JWYouTubeVideoData *videoDataRetriever = [[JWYouTubeVideoData alloc] initWithVideoId:videoId];
    
    [videoDataRetriever getVideoDataOnCompletion:^(NSArray *videoDataResult){
        
        id responseData = videoDataResult[0];
        
        id errorInResponse = [responseData valueForKey:@"statuscode"];
        if (errorInResponse) {
            NSLog(@"%s ERROR response%@",__func__,[responseData description]);
        } else {
            
            [self processTheYoutubeDataRecord:responseData forDbKey:dbkey];
            [[JWFileController sharedInstance] saveMeta];
//            [self saveMetaData];
            [self saveDescriptions];
        }
        
        id mp3DataRecord = _mp3FilesInfo[dbkey];
        
        // Convert by creating a newWebSesssion in mp3ConvertController
        
        NSString *statusTitle = @"";
        if (mp3DataRecord) {
            statusTitle = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeTitle];
            
            NSString *imageURLStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMedium];
            NSURL *imageURL = [NSURL URLWithString:imageURLStr];
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image =youtubeImage;
                    self.imageView.hidden = NO;
                });
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusLabel.text = [NSString stringWithFormat:@"Converting to MP3\n\n%@",statusTitle];
        });
        
        // Start a new websession
        
        [_mp3ConvertController startSession];
    }];
}


-(void)processTheYoutubeDataRecord:(NSDictionary*)youtubeDataRecord forDbKey:(NSString*)dbkey
{
    // BRINGS THE YOUTUBE DATA INTO OUR DB
    // ADDS YTDATA TO MP3INFO AND STRIPS THE DESCRIPTIONS AND PLACES IN DESCRIPTION TABLE

    id mp3DataRecord = _mp3FilesInfo[dbkey];
    
    // Remove the description from ytdata before adding to _mp3Info
    NSMutableDictionary *ytdata = [youtubeDataRecord mutableCopy];
    NSMutableDictionary *mp3DescriptionRecord = [@{} mutableCopy];
    
    id ytdescription = ytdata[JWDbKeyYoutubeDataDescription];
    if (ytdescription)
        mp3DescriptionRecord[JWDbKeyYoutubeDataDescription] = ytdescription;
    id ytlocalized = ytdata[JWDbKeyYoutubeDataLocalized];
    if (ytlocalized)
        mp3DescriptionRecord[JWDbKeyYoutubeDataLocalized] = ytlocalized;
    
    mp3DescriptionRecord[JWDbKeyYouTubeDataVideoId] = ytdata[JWDbKeyYouTubeDataVideoId];
    
    //   Create a Cross reference key
    NSString*descriptionKey = [[NSUUID UUID] UUIDString];
    
    //   add to descriptions table
    _mp3FilesDescriptions[descriptionKey] = mp3DescriptionRecord;
    
    // remove the descriptions items from ytdata
    [ytdata removeObjectForKey:JWDbKeyYoutubeDataDescription];
    [ytdata removeObjectForKey:JWDbKeyYoutubeDataLocalized];
    
    
    // With the descriptions renoved
    // add the crossreference to the Info table
    ytdata[@"ytdescriptionskey"] = descriptionKey;
    
    // and add the ytdata record to the toplevel of the mp3record
    if (mp3DataRecord)
        mp3DataRecord[JWDbKeyYouTubeData]=ytdata;
    
    // helper URLS added to the toplevel so dont have o dig down into ytdata
    NSString *imageURLStr;
    NSURL *imageURL;
    imageURLStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"default"][@"url"];
    imageURL = [NSURL URLWithString:imageURLStr];
    if (mp3DataRecord)
        [mp3DataRecord setValue:imageURLStr forKey:(NSString*)JWDbKeyYoutubeThumbnailDefault];
    imageURLStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"medium"][@"url"];
    imageURL = [NSURL URLWithString:imageURLStr];
    if (mp3DataRecord)
        [mp3DataRecord setValue:imageURLStr forKey:(NSString*)JWDbKeyYoutubeThumbnailMedium];
    imageURLStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"high"][@"url"];
    imageURL = [NSURL URLWithString:imageURLStr];
    if (mp3DataRecord)
        [mp3DataRecord setValue:imageURLStr forKey:(NSString*)JWDbKeyYoutubeThumbnailHigh];
    imageURLStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"maxres"][@"url"];
    imageURL = [NSURL URLWithString:imageURLStr];
    if (mp3DataRecord)
        [mp3DataRecord setValue:imageURLStr forKey:(NSString*)JWDbKeyYoutubeThumbnailMaxres];
    
}


#pragma mark - mp3Converter controler delegate

-(void)didInitiateWebView:(JWYoutubeMP3ConvertController *)controller{
    
    NSLog(@"%s", __func__);

    // the replaceURL will be submitted ... and the process has started
    
    float totalProgress = _convertProgressOfTotal * .10f;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:NO];
        [self.progressView setProgress:totalProgress animated:YES];
    });
}

-(void)didInitiateWebView2:(JWYoutubeMP3ConvertController *)controller {
    // just submitted the replaceURL ... and the process has started
    // the end of nitialization

    if (_showsYoutubeMP3) {
        self.webView.hidden = NO;
        self.effectsView.hidden = YES;
    }
    
    [self.activity startAnimating];
    
    // things are going
}

-(void)conversionProgress:(JWYoutubeMP3ConvertController *)controller progress:(float)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:progress animated:YES];
    });
}

-(void)conversionProgress1:(JWYoutubeMP3ConvertController *)controller  {
    float totalProgress = _convertProgressOfTotal * .15f;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:totalProgress animated:YES];
    });
}

-(void)conversionProgress2:(JWYoutubeMP3ConvertController *)controller  {
    float totalProgress = _convertProgressOfTotal * .25f;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:totalProgress animated:YES];
    });

    [self simulateProgress];
}

-(void)simulateProgress {
    // simulate progress
    float maxP = .80;
    float minP = .30;
    float dur = 1.2;
    int iter = 8;
    for (int i=0; i < iter; i++) {
        double delay = (i+1) * (dur/iter);
        float progressfactor =  minP + ((maxP - minP) * (double)(i+1)/iter );
        float pvalue = _convertProgressOfTotal * progressfactor;
        //        NSLog(@"%s %.3f %.3f  %.3f %.3f",__func__,delay,pvalue,progressfactor,(double)(i+1)/iter);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.progressView setProgress:pvalue animated:YES];
        });
    }
}

-(void)foundLinkInWebView {
    float totalProgress = _convertProgressOfTotal * .90f;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:totalProgress animated:YES];
    });
}

-(void)webViewDidFinishFirstLoad
{
    self.webviewHeightConstraint.constant = 128; // shows converted
}

-(void)didSaveFileDataForDbKey:(NSString*)dbkey {
    
    NSURL *fileUrl = [self fileURLForCacheItem:dbkey];
    
    NSString* fileTitle = [(NSDictionary *)_mp3FilesInfo valueForKey:(NSString*)JWDbKeyVideoTitle];
    self.currentMP3FileURL = fileUrl;
    
    NSLog(@"\nSAVED\n%@",[_currentMP3FileURL lastPathComponent]);
    [JWCurrentWorkItem sharedInstance].currentAudioFileURL = fileUrl;
    [JWCurrentWorkItem sharedInstance].currentAudioTitle  = fileTitle;
    [JWCurrentWorkItem sharedInstance].timeStamp = [NSDate date];
    
    if (dbkey) {
        // save for restarts - last item used
        [[NSUserDefaults standardUserDefaults] setValue:dbkey forKey:@"currentItem"];
    }
}


#pragma mark - db

- (NSString *)cacheItemForLinkStr:(NSString*)linkURLStr
{
    return [self cacheItemForLinkStr:linkURLStr andVideoTitle:nil];
}

- (NSString *)cacheItemForLinkStr:(NSString*)linkURLStr andVideoTitle:(NSString *)videoTitle
{
    NSString *linkKey = linkURLStr?linkURLStr:@"NULL";

    id linkRecord = _linksDirector[linkKey];
    
    NSString *dbkey = nil;
    if (linkRecord) {
        dbkey = linkRecord[@"dbkey"];
        
        if (dbkey) {
            id mp3Record = _mp3FilesInfo[dbkey];
            if (!mp3Record) {
                _mp3FilesInfo[dbkey] = [
                                        @{JWDbKeyCreationDate:[NSDate date],
                                          JWDbKeyYouTubeLinkStr:linkKey,
                                          JWDbKeyArtist:@"unknown",
                                          JWDbKeyVideoTitle:videoTitle?videoTitle:@"unknown"}
                                        mutableCopy];
                
                if (_youtubeVideoId)
                    _mp3FilesInfo[dbkey][JWDbKeyYouTubeVideoId] = _youtubeVideoId;
            }
            
        } else {
            // no cache key found in links directory record
        }
    }
    
    if (dbkey == nil) {
        dbkey = [[NSUUID UUID] UUIDString];
        _linksDirector[linkKey] = @{JWDbKeyCreationDate:[NSDate date],
                                    JWDbKey:dbkey};
        _mp3FilesInfo[dbkey] = [
                                @{JWDbKeyCreationDate:[NSDate date],
                                  JWDbKeyYouTubeLinkStr:linkKey,
                                  JWDbKeyArtist:@"unknown",
                                  JWDbKeyVideoTitle:videoTitle?videoTitle:@"unknown"}
                                mutableCopy];
        if (_youtubeVideoId) {
            _mp3FilesInfo[dbkey][JWDbKeyYouTubeVideoId] = _youtubeVideoId;
        }
    }
    
    return dbkey;
    
}

#pragma mark - URLManip delegate

-(void)didRetrieveFile:(JWYoutubeMP3ConvertController *)controller
{
    if (_showsYoutubeMP3){
        self.webView.hidden = YES;
    }
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.statusLabel.text = @"Download Complete";
//    });

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activity stopAnimating];
    });

    if (_proceedForwardOnSuccess) {
        [self proceedForwardAction:controller.dbkey];
    } else {
        [self finalStatusMessage:controller.dbkey];
    }

}

-(void)didObtainLink:(JWYoutubeMP3ConvertController *)controller linkToMP3String:(NSString*)linkStr {
    
    // We are done converting

    NSLog(@"%s\n%@",__func__,linkStr);
    [self.activity stopAnimating];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.statusLabel.text = @"Conversion Complete";
//    });
//    double delayInSecs = 0.42;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.statusLabel.text = @"Downloading";
//    });

    
    NSLog(@"%s%@",__func__,controller.dbkey);
    
    id mp3DataRecord = _mp3FilesInfo[controller.dbkey];
    if (mp3DataRecord)
        [mp3DataRecord setValue:linkStr forKey:(NSString*)JWDbKeyDownloadLink];

    if (_showsYoutubeMP3){
        self.webviewHeightConstraint.constant = 310; // shows converted
        double delayInSecs = 1.5 + 1.0; // plus animdelay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.effectsView.hidden = NO;
        });
        delayInSecs = 2.5 + 1.0; // plus animdelay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.webView.hidden = YES;
        });
    }
    
    float totalProgress = _convertProgressOfTotal; // 100% of conversion process
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:totalProgress animated:YES];
    });

    // begin Download

    [self downloadTask:[NSURL URLWithString:linkStr]  dbKey:controller.dbkey];
    
}


-(void)downloadTask:(NSURL*)linkURL dbKey:(NSString*)dbkey{
    
    self.downloadController = [JWFileDowloadController new];

    [ _downloadController dowloadFileWithURL:linkURL withDBKey:dbkey onProgress:^(float progress) {

        float totalProgress = _convertProgressOfTotal + (_downloadProgressOfTotal * progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView setProgress:totalProgress animated:YES];
        });
        
    } onCompletion:^(NSURL *downloadedFileURL,NSString *dbkey){

        [self didDownloadFile:downloadedFileURL dbKey:dbkey];
        
        if (_proceedForwardOnSuccess) {
            double delayInSecs = 0.25;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self proceedForwardAction:dbkey];
            });

        } else {
            [self effectsBackgroundSuccess];
            [self finalStatusMessage:dbkey];
        }

        NSLog(@"COMPLETED");
    }];
}


-(void)didDownloadFile:(NSURL*)fileURL dbKey:(NSString*)dbkey {

    NSLog(@"%s%@",__func__,dbkey);

    if (_showsYoutubeMP3)
        self.webView.hidden = YES;
    
    // may or may not exists
    NSURL *newFileUrl = [self fileURLForCacheItem:dbkey];
    NSError *error;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[newFileUrl path]]) {
        if ([[NSFileManager defaultManager] removeItemAtURL:newFileUrl error:&error]) {
            NSLog(@"FILE REMOVED ");
        } else {
            NSLog(@"DID NOT REMOVE FILE %@",[error description]);
        }
    }

    if ([[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:newFileUrl error:&error]) {
        self.currentMP3FileURL = newFileUrl;
        NSLog(@"\nSAVED\n%@",[_currentMP3FileURL lastPathComponent]);
        NSString* fileTitle = [(NSDictionary *)_mp3FilesInfo valueForKey:(NSString*)JWDbKeyVideoTitle];
        [JWCurrentWorkItem sharedInstance].currentAudioFileURL = newFileUrl;
        [JWCurrentWorkItem sharedInstance].currentAudioTitle  = fileTitle;
        [JWCurrentWorkItem sharedInstance].timeStamp = [NSDate date];
        NSLog(@"FILE MOVED ");
    } else {
        NSLog(@"DID NOT MOVE FILE %@",[error description]);
    }
    
    if (dbkey) {
        // save for restarts - last item used
        [[NSUserDefaults standardUserDefaults] setValue:dbkey forKey:@"currentItem"];
    }
    
    
    if (_proceedForwardOnSuccess ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.hidden = YES;
        });

    } else {
        double delayInSecs = 0.25;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.progressView.alpha = 0.1;
            } completion:^(BOOL fini){
                self.progressView.hidden = YES;
            } ];
        });
    }

    
//    [self saveMetaData];
    [[JWFileController sharedInstance] saveMeta];

    
    [self.activity stopAnimating];
}


-(void)finalStatusMessage:(NSString*)dbkey {
    NSString *statusTitle;
    if (dbkey) {
        id mp3DataRecord = _mp3FilesInfo[dbkey];
        if (mp3DataRecord)
            statusTitle = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeTitle];
    }
    
    NSString *titleString;
    if (_tapToJam) {
        titleString = [NSString stringWithFormat:@"Tap To JAM With\n%@",statusTitle ? statusTitle:@""];
    } else {
        titleString = [NSString stringWithFormat:@"Converted to MP3\n%@",statusTitle ? statusTitle : @""];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = titleString;
    });
}


#pragma mark - File Name and Save methods

-(NSURL *)fileURLForCacheItem:(NSString*)dbkey {
    NSURL *result;
    NSString *thisfName = @"mp3file";
    NSString *thisName = [NSString stringWithFormat:@"%@_%@.mp3",thisfName,dbkey?dbkey:@""];
    
    NSMutableString *fname = [[self documentsDirectoryPath] mutableCopy];
    [fname appendFormat:@"/%@",thisName];
    
    result = [NSURL fileURLWithPath:fname];
    NSLog(@"%s FileName: %@",__func__,[result lastPathComponent]);
    
    return result;
}
-(NSString*)documentsDirectoryPath{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}


#pragma mark - PLAY File Using

// ------------------------------------------------------------
//
// NO real value to have all of these methods will need to decide whichone if any we want to use
// This would be to play the file downloaded for preview - but as it stands
// we proceed normally to Clipper and starts playing
// We should keeep all of this methods somewhere to know how each works
// possibly a new controller object with a method:Playfile using
// ------------------------------------------------------------

-(void)playFile
{
    [self playFileUsingAVPlayer];
    return;
}
// Some other play options
//    self.avPlayerView.hidden = NO;
//    [self playFileUsingAVPlayerController];
//    return;
//    [self playFileUsingAudioPlayer];
//    return;
////    [self playBufferedFileInEngine];
////    return;
//    [self playFileInEngine];
//    return;

-(void)playFileUsingAVPlayer{
    AVPlayer *myPlayer = [AVPlayer playerWithURL:self.currentMP3FileURL];
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = myPlayer;
    playerViewController.showsPlaybackControls = YES;
    [self presentViewController:playerViewController animated:NO completion:^{
        [myPlayer play];
    }];
    NSLog(@"%s \n%@\n%@",__func__,[_mp3FilesInfo description],[_linksDirector description]);
}
-(void)playFileUsingAVPlayerController{
    // uses iVar avPlayerViewController possibly from sb
    AVPlayer *myPlayer = [AVPlayer playerWithURL:self.currentMP3FileURL];
    self.avPlayerViewController.player = myPlayer;
    [myPlayer play];
    NSLog(@"%s \n%@\n%@",__func__,[_mp3FilesInfo description],[_linksDirector description]);
}

-(void)playFileUsingAudioPlayer
{
    // Plays in AVAudioPlayer either using data or from file
    NSError *error;
    
    BOOL useData = YES;
    
    if (useData) {
        NSData * data = [NSData dataWithContentsOfURL:self.currentMP3FileURL];
        _audioPlayer = [[AVAudioPlayer alloc] initWithData: data error: & error];
    } else {
        _audioPlayer =[[AVAudioPlayer alloc] initWithContentsOfURL:self.currentMP3FileURL error: & error];
    }
    
    [_audioPlayer play];
}

-(void)playFileInEngine
{
    _engine = [AVAudioEngine new];
    AVAudioPlayerNode *player = [AVAudioPlayerNode new];

    NSError *error;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:self.currentMP3FileURL error:&error];
    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];

    [_engine attachNode:player];
    [_engine connect:player to:mainMixer format:file.processingFormat];
    error = nil;
    [_engine startAndReturnError:&error];
    mainMixer.volume = 0.5;
    // attime nil play immediately
    [player scheduleFile:file atTime:nil completionHandler:nil];
    [player play];
}

-(void)playBufferedFileInEngine
{
    [self initAVAudioSession];
    _engine = [AVAudioEngine new];
    AVAudioPlayerNode *player = [AVAudioPlayerNode new];
    
    NSURL *fileURL = [self fileURLForCacheItem:self.currentCacheItem];
    NSError *error = nil;
    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
    if (error) {
        NSLog(@"ERROR  Cannot read file");
    }
    const AVAudioFrameCount kBufferFrameCapacity = 128 * 1024L;
    AVAudioPCMBuffer *readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:
                                    audioFile.processingFormat frameCapacity: kBufferFrameCapacity];
    
    AVAudioFramePosition fileLength = audioFile.length;
    NSLog(@"Length:            %lld frames, %.3f seconds\n", (long long)fileLength, fileLength / audioFile.fileFormat.sampleRate);
    float loudestSample = 0.0f;
    AVAudioFramePosition loudestSamplePosition = 0;
    while (audioFile.framePosition < fileLength) {
        AVAudioFramePosition readPosition = audioFile.framePosition;
        if (![audioFile readIntoBuffer: readBuffer error: &error]) {
            NSLog(@"failed to read audio file: %@", error);
            //return NO;
        }
        for (AVAudioChannelCount channelIndex = 0; channelIndex < readBuffer.format.channelCount; ++channelIndex)
        {
            float *channelData = readBuffer.floatChannelData[channelIndex];
            for (AVAudioFrameCount frameIndex = 0;
                 frameIndex < readBuffer.frameLength; ++frameIndex)
            {
                float sampleAbsLevel = fabs(channelData[frameIndex]);
                if (sampleAbsLevel > loudestSample)
                {
                    loudestSample = sampleAbsLevel;
                    loudestSamplePosition = readPosition + frameIndex;
                }
            }
        }
    }
    [_engine attachNode:player];
    [_engine connect:player to:[_engine mainMixerNode] format:audioFile.processingFormat];
    error = nil;
    [_engine startAndReturnError:&error];
    
}


#pragma mark - AVAudioSession

- (void)initAVAudioSession
{
    // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
    // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    //bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
}


#pragma mark - save retrieve metadata

-(void)saveMetaData {
    [_linksDirector writeToURL:
     [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyLinksDirectoryFileName]] atomically:YES];
    [_mp3FilesInfo writeToURL:[NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]] atomically:YES];

    NSLog(@"%sLINKSCOUNT[%ld] MP3INFOCOUNT[%ld]",__func__,[_linksDirector count],[_mp3FilesInfo count]);
//    NSLog(@"\n%s\nLINKS\n%@\nMP3INFO\n%@",__func__,[_linksDirector description],[_mp3FilesInfo description]);
}
-(void)readMetaData {
    _linksDirector = [[NSMutableDictionary alloc] initWithContentsOfURL:
                      [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyLinksDirectoryFileName]]];
    
    NSMutableDictionary *mp3Dict = [[NSMutableDictionary alloc] initWithContentsOfURL:
                                    [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]]];
    _mp3FilesInfo = [@{} mutableCopy];
    for (id key in [mp3Dict allKeys]) {
        _mp3FilesInfo[key] = [mp3Dict[key] mutableCopy];
    }
    
//    _mp3FilesInfo = [[NSMutableDictionary alloc] initWithContentsOfURL:
//                     [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]]];

    
    NSLog(@"%sLINKSCOUNT[%ld] MP3INFOCOUNT[%ld]",__func__,[_linksDirector count],[_mp3FilesInfo count]);
//    NSLog(@"\n%s\nLINKS\n%@\nMP3INFO\n%@",__func__,[_linksDirector description],[_mp3FilesInfo description]);
}


-(void)saveDescriptions {
    [_mp3FilesDescriptions writeToURL:[NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:@"mp3descriptions.dat"]] atomically:YES];
    NSLog(@"%sMP3DESCRIPCOUNT[%ld]",__func__,[_mp3FilesDescriptions count]);
}
-(void)readDescriptions {
    _mp3FilesDescriptions = [[NSMutableDictionary alloc] initWithContentsOfURL:
                             [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:@"mp3descriptions.dat"]]];
    NSLog(@"%sMP3DESCRIPCOUNT[%ld]",__func__,[_mp3FilesDescriptions count]);
}


#pragma mark - effects background

-(void)effectsBackgroundError {
    UIColor *cb = self.view.backgroundColor;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.backgroundColor =[[UIColor redColor] colorWithAlphaComponent:0.4];
    });
    double delayInSecs = 0.75;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.backgroundColor =cb;
    });
}
-(void)effectsBackgroundSuccess {
    UIColor *cb = self.view.backgroundColor;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.backgroundColor =[[UIColor blueColor] colorWithAlphaComponent:0.4];
    });
    double delayInSecs = 0.75;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.backgroundColor =cb;
    });
}


#pragma mark - extra gestures and paste
- (IBAction)didSwipeDown:(id)sender
{
    if (_useSwipeDownToReConvert) {
        [_mp3ConvertController reconvert];
        
        // Re Convert
//        if (self.urlSession.youTubeLinkURL) {
//            self.urlSession.youTubeURLReplaceString = self.urlSession.youTubeLinkURL;
//            [self newSessionWithLinkURLString:self.urlSession.youTubeURLReplaceString];
//            [self effectsBackgroundSuccess];
//        } else {
//            NSLog(@"%s no link URL available",__func__);
//            [self effectsBackgroundError];
//        }
    }
}
- (IBAction)longPress:(id)sender {
    if (_useLongPressToPaste) {
        NSLog(@"%s",__func__);
        if (!pasting) {
            NSLog(@"%s paste",__func__);
            pasting = YES;
            [self paste:nil];
        }
    }
}
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL retValue = NO;
    if (_useLongPressToPaste) {
        if (action == @selector(paste:) )
            retValue = YES;
        //    else if ( action == @selector(cut:) || action == @selector(copy:) )
        //        retValue = (theTile != nil);
        else
            retValue = [super canPerformAction:action withSender:sender];
    }
    return retValue;
}

- (void)paste:(id)sender {
    NSLog(@"%s ",__func__);
    UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];
    if ([gpBoard containsPasteboardTypes:UIPasteboardTypeListURL]) {
        NSURL *theURL = [gpBoard URL];
        [self newSessionWithLinkURLString:[theURL absoluteString]];
        [self effectsBackgroundSuccess];
    } else {
        NSLog(@"%s NOT UIPasteboardTypeListURL. ignore.",__func__);
        //        pasting=NO;
        [self effectsBackgroundError];
    }
    double delayInSecs = 0.65;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        pasting = NO;
    });
}


@end

