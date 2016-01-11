//
//  JWJamMP3TableViewController.m
//  JamWIthT
//
//  Created by brendan kerr on 10/3/15.
//  Copyright (c) 2015 JOSEPH KERR. All rights reserved.
//

#import "JWJamMP3TableViewController.h"
#import "JWCurrentWorkItem.h"
#import "JWYoutubeMP3ViewController.h"

@interface JWJamMP3TableViewController () {
    NSArray* _dictKeys;
}
@property (nonatomic) NSMutableDictionary* websiteDataTestDict;
@property (nonatomic) NSURL* pastedLinkURL;
@end


@implementation JWJamMP3TableViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    [self pasteBoardHasLink];
}


-(BOOL)pasteBoardHasLink {
 
    BOOL result;
    UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];
    if ([gpBoard containsPasteboardTypes:UIPasteboardTypeListURL]) {
        NSURL *theURL = [gpBoard URL];
        self.pastedLinkURL = theURL;
        result = YES;
        
    } else {
        NSLog(@"%s NOT UIPasteboardTypeListURL. ignore.",__func__);
    }
    return result;
}


-(NSMutableDictionary *)websiteDataTestDict {
    
    if (!_websiteDataTestDict) {
        _websiteDataTestDict = [NSMutableDictionary dictionaryWithObjects:@[@1, @2, @3] forKeys:@[@"Website One Title", @"Website Two Title", @"Website Three Title"]];
    }
    return _websiteDataTestDict;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
    // Return the number of rows in the section.
    
    NSInteger count = 1;  // THE Default
    if (section == 3) {
        count = 1;// youtube search
        if (self.pastedLinkURL)
        {
            count++; // pasted link
        }
        count++;  // mp3 FIles
        
    }
    
    return count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    _dictKeys = [self.websiteDataTestDict allKeys];
    
    if (section == 3) {
        return @"Find A Youtube Video";
    }
    return _dictKeys[section];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    return 2.0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:  forIndexPath:indexPath];
    UITableViewCell* cell;
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell__ID"];
    }
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.text = @"Son Little Audio";
    }
    
    if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Search Youtube!";
            
        } else {

            if (_pastedLinkURL) {
                
                if (indexPath.row == 1) {
                    cell.textLabel.text = [self.pastedLinkURL absoluteString];
                } else if (indexPath.row == 2) {
                    cell.textLabel.text = @"MP3Files";
                    
                }
            } else {
                cell.textLabel.text = @"MP3Files";
            }
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        NSString* pathString = [[NSBundle mainBundle] pathForResource:@"layDown" ofType:@"mp3"];
        
        [JWCurrentWorkItem sharedInstance].currentAudioFileURL = [NSURL fileURLWithPath:pathString];
        [JWCurrentWorkItem sharedInstance].currentAudioOrigin = JamSiteOrigin;
        [self performSegueWithIdentifier:@"JWClipAudioSegue" sender:nil];
        
    } else if (indexPath.section == 3 ) {

        if (indexPath.row == 0) {
            [JWCurrentWorkItem sharedInstance].currentAudioOrigin = YouTubeOrigin;
            [self performSegueWithIdentifier:@"JWYoutubeSearchSegue" sender:nil];
        } else {
            
            if (_pastedLinkURL) {
                
                if (indexPath.row == 1) {
                    [self performSegueWithIdentifier:@"JWPastedLinkSegue" sender:nil];
                } else if (indexPath.row == 2) {
                    [self performSegueWithIdentifier:@"JWHomePageToMP3FilesSegue" sender:nil];
                }
            } else {
                [self performSegueWithIdentifier:@"JWHomePageToMP3FilesSegue" sender:nil];
            }
        }
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSLog(@"%s %@",__func__,[segue identifier]);
    
    if ([[segue identifier] isEqualToString:@"JWPastedLinkSegue"]) {
        JWYoutubeMP3ViewController *youtubeMP3ViewController = (JWYoutubeMP3ViewController*)segue.destinationViewController;
        youtubeMP3ViewController.youTubeLinkURL = self.pastedLinkURL;
        
    }
    
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
*/


@end
