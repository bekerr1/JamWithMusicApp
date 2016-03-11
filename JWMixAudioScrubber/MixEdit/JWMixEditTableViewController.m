//
//  JWMixerTableViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/14/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWMixEditTableViewController.h"
#import "JWEffectPresetsTableViewController.h"
// Effect slider Cell Types
#import "JWSliderTableViewCell.h"
#import "JWRecorderTableViewCell.h"
#import "JWSliderAndSwitchTableViewCell.h"
#import "JWEffectParametersTableViewCell.h"
#import "JWEffectPresetTableViewCell.h"
// Player node types
#import "JWMixNodes.h"
#import "JWCustomCellBackground.h"
#import "UIColor+JW.h"


@interface JWMixEditTableViewController ()
{
    BOOL _sectionEnabledScrubber;
    BOOL _sectionEnabledMixer;
    NSUInteger _mixerSection;
    NSUInteger _scrubberSection;
    JWEffectNodeTypes _currentSelectedEffectType;
}

@property (strong, nonatomic) NSMutableArray *playerNodeList;
@property (strong, nonatomic) NSMutableDictionary *playerNodeSelected;

@end


@implementation JWMixEditTableViewController

#pragma mark - Table view data source

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _sectionEnabledScrubber = YES;
    _sectionEnabledMixer = YES;
    _currentSelectedEffectType = 20;
    self.clearsSelectionOnViewWillAppear = NO;  // preserve selection between presentations.
    
    CGRect fr = self.tableView.tableHeaderView.frame;
    fr.size.height = 66;
    self.tableView.tableHeaderView.frame = fr;

    _mixerSection = 0;
    _scrubberSection = 0;

    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundView = backgroundView;

    self.tableView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.tableView.bounces = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];

    [self refresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refresh {
    
    [self getTableViewDataSource];
    
    [self.tableView reloadData];
}


-(void)getTableViewDataSource
{
    
    self.playerNodeList = [self.effectsHandler configPlayerNodeList];
    self.playerNodeSelected = self.playerNodeList[_selectedNodeIndex];
    
}


#pragma mark -

- (IBAction)returnPressed:(id)sender
{
    [_delegateMixEdit doneWithMixEdit:self];
}



//_playerNodeList
//   [@{@"title":@"Player node 1",
//      @"type":@(JWMixerNodeTypePlayer),
//      @"name":@"playernode1",
//      @"volumevalue":@(0.50),
//      @"panvalue":@(0.50),
//      } mutableCopy],
//   [@{@"title":@"Player Recorder node 2",
//      @"type":@(JWMixerNodeTypePlayerRecorder),
//      @"name":@"playerrecordernode1",
//      @"volumevalue":@(0.50),
//      @"panvalue":@(0.50),
//      } mutableCopy],
//   [@{@"title":@"Mixer Player node3",
//      @"type":@(JWMixerNodeTypeMixerPlayerRecorder),
//      @"name":@"mixerplayerrecordere3",
//      @"volumevalue":@(0.50),
//      @"panvalue":@(0.50),
//      } mutableCopy]


#pragma mark - Helper

// helper
-(JWMixerNodeTypes)typeForNodeAtIndex:(NSUInteger)index {
    
    JWMixerNodeTypes result = 0;
    if ([_playerNodeList count] > index) {
        NSDictionary *playerNodeInfo = _playerNodeList[index];
        id type = playerNodeInfo[@"type"];
        if (type)
            result = [(NSNumber*)type integerValue];
    }
    return result;
}

-(NSURL*) playerNodeFileURLAtIndex:(NSUInteger)index {
    NSURL *result = nil;
    if ([_playerNodeList count] > index) {
        id fileURLString = _playerNodeList[index][@"fileURLString"];
        if (fileURLString) {
            result = [NSURL fileURLWithPath:fileURLString];
        }
    }
    return result;
}

-(NSArray*)effectsForNodeAtIndex:(NSUInteger)index {
    
    NSArray * result = nil;
    if ([_playerNodeList count] > index) {
        NSDictionary *playerNodeInfo = _playerNodeList[index];
        
        id effects = playerNodeInfo[@"effects"];
        if (effects)
            result = effects;
    }
    return result;
}


-(JWEffectNodeTypes)effectNodeTypeForNodeAtIndex:(NSUInteger)index effectIndex:(NSUInteger)eIndex {
    
    JWEffectNodeTypes result;
    NSArray * effects = self.playerNodeSelected[@"effects"];
    //TODO: replaced index with zero?
    if ([effects count] > 0) {
        id typeValue = effects[eIndex][@"type"];
        if (typeValue)
            result = [typeValue unsignedIntegerValue];
    }
    return result;
}

-(NSString *)effectTitleForNodeAtIndex:(NSUInteger)index effectIndex:(NSUInteger)eIndex {
    
    NSString * result;
    NSArray * effects = self.playerNodeSelected[@"effects"];
    //TODO: replaced index with zero?
    if ([effects count] > 0) {
        id titleValue = effects[eIndex][@"title"];
        if (titleValue)
            result = titleValue;
    }
    return result;
}



/*
 DOCUMENTATION
 
 Each tableview section is a player node and the first two rows are volume and pan
 any rows after are effect nodes
 
 The Last two sections are mixernode and scrubber controller
 Scrubber Controller is the last section
 */

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    //NSInteger count = [_playerNodeList count];
    NSInteger count = 1;  // SELECTED
    
    // mixer node and scrubber controller row
    
    if (_sectionEnabledMixer){
        _mixerSection = count;
        count++;
    }

    if (_sectionEnabledScrubber) {
        _scrubberSection = count;
        count++;
    }
    
    return count;
}

#define NEW_TABLEVIEW_MODEL
#ifdef NEW_TABLEVIEW_MODEL

/* 
 Data source is the actual player node so can refer to it directly when creating
    number of rows
 keys: player, effectnodes, title, trackid, audiofile, type, audiobuffer, fileURLString
 
 MixerSection = 1 if enabled and ScrubberSection = 2 if enabled
 
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    //JWMixerNodeTypes playerNodeType = [self.playerNodeSelected[@"type"] integerValue];
    NSDictionary *effectNodes = self.playerNodeSelected[@"effectnodes"];
    NSUInteger effectNodesCount = effectNodes.count;
    
    NSUInteger count = 0;
    NSUInteger playerNodeSection = 0;
    NSUInteger bottomSections = 0;

    if (_sectionEnabledMixer)
    bottomSections++;
    if (_sectionEnabledScrubber)
    bottomSections++;
    
    if (bottomSections > 0  && section > playerNodeSection) {
       
        if (_mixerSection > 0 && section == _mixerSection) {
            count = 2;
        }
        if (_scrubberSection > 0 && section == _scrubberSection) {
            count = 1;
        }
    } else {
        
        count = [self numberOfBaseRowsForNode] + effectNodesCount;
        
//        if (playerNodeType == JWMixerNodeTypePlayer) {
//            count = baseCount + effectNodesCount;
//            
//        } else if (playerNodeType == JWMixerNodeTypePlayerRecorder) {
//            
//            id fileURL = self.playerNodeSelected[@"fileURLString"];
//            if (fileURL) {
//                count = baseCount + effectNodesCount;
//            } else {
//                count = 1;
//            }
//        } else {
//            count = 1;
//        }
    }

    
    
    return count;
    
}

#else



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger count = 0;
//    NSUInteger mixNodeCount = [_playerNodeList count];
//    NSUInteger lastPlayerNodeSection = mixNodeCount -1;

    NSUInteger lastPlayerNodeSection = 0;  // selectedNode

    
    // mixer node and scrubber controller sections
    NSUInteger bottomSections = 0;
    if (_sectionEnabledMixer)
        bottomSections++;
    if (_sectionEnabledScrubber)
        bottomSections++;

    if (bottomSections > 0  && section > lastPlayerNodeSection) {
        
        // MIXER, SCRUBBER SECTION
        
        if (_mixerSection > 0 && section == _mixerSection) {
            count = 2;
        }
        
        if (_scrubberSection > 0 && section == _scrubberSection) {
            count = 1;
        }

    }
    else {
        
//        NSUInteger nBaseRowsForNode = [self numberOfBaseRowsForNodeAtIndex:section];

        NSUInteger nodeSection = section;
        nodeSection = _selectedNodeIndex;
        NSUInteger nBaseRowsForNode = [self numberOfBaseRowsForNodeAtIndex:nodeSection];

        // PLAYER SECTION WITH EFFECTS
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:nodeSection];
        
        if (nodeType == JWMixerNodeTypePlayer) {
            count = nBaseRowsForNode; // 2 primary cells volume and pan
            count += [[self effectsForNodeAtIndex:nodeSection] count];
            
        } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
            
            id fileURL = [self playerNodeFileURLAtIndex:nodeSection];
            if (fileURL) {
                count = nBaseRowsForNode; // 2 primary cells volume and pan
                count += [[self effectsForNodeAtIndex:nodeSection] count];
            } else {
                count = 1; // one for recorder, 1 - ignore the player until URL
            }
        }
    }
    
    return count;
}



#endif


-(NSUInteger)numberOfBaseRowsForNode
{
    NSUInteger nBaseRowsForNode = 0;
    JWMixerNodeTypes nodeType = [self.playerNodeSelected[@"type"] integerValue];
    if (nodeType == JWMixerNodeTypePlayer) {
        nBaseRowsForNode = 2; // 2 primary cells volume and pan
    } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
        id fileURL = self.playerNodeSelected[@"fileURLString"];
        if (fileURL) {
            nBaseRowsForNode = 2; // 2 primary cells volume and pan two for player,
            nBaseRowsForNode++; //one for recorder
//            nBaseRowsForNode += [[self effectsForNodeAtIndex:index] count];
        } else {
            nBaseRowsForNode = 1; // one for recorder, 1 - ignore the player until URL
        }
        //            nBaseRowsForNode = fileURL ? 3 : 1;  // two for player, one for recorder, 1 - ignore the player until URL
    }
    return nBaseRowsForNode;
}



- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {

    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    cell.backgroundView = backgroundView;
}


// Last sections MIXER and SCRUBBER
// nodelist = 2 : 0 1,  2 > 2-1(1) true
// next to last mixer then scrubber

- (UITableViewCell *)tableView:(UITableView *)tableView bottomSectionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    NSUInteger nodeSection = indexPath.section;
    nodeSection = _selectedNodeIndex;

    JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
    
    [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
    
    //JWCustomCellBackground *cback = [[JWCustomCellBackground alloc] init];
    
    // First section beyond mixNodeCount
    
    if (_mixerSection > 0 && indexPath.section == _mixerSection) {

        // mixer
        // count == 2;
        
        id <JWEffectsModifyingProtocol> node = [_effectsHandler mixerNodeAtIndex:nodeSection];
        
        // OUTPUTVOLUME
        if (indexPath.row ==0) {
            sliderCell.slider.minimumValue = 0.0;
            sliderCell.slider.maximumValue = 1.0;
            sliderCell.slider.value = [node floatValue1];
            
            [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
            sliderCell.sliderLabel.text = @"outputvolume";
        }
        
        // PAN
        else if (indexPath.row ==1) {
            sliderCell.slider.minimumValue = -1.0;
            sliderCell.slider.maximumValue = 1.0;
            sliderCell.slider.value = [node floatValue2];
            [sliderCell.slider addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
            sliderCell.sliderLabel.text = @"pan";
        }

    } else if (_scrubberSection > 0 && indexPath.section == _scrubberSection) {
        
        // scrubber
        // count == 1;
        
        id <JWEffectsModifyingProtocol> node = [_delegateMixEdit mixNodeControllerForScrubber];
        
        // BACKLIGHT
        if (indexPath.row ==0) {
            sliderCell.slider.minimumValue = 0.0;
            sliderCell.slider.maximumValue = 1.0;
            sliderCell.slider.value = [node floatValue1];
            [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
            sliderCell.sliderLabel.text = @"backlight";
        }
    }
    
    cell = sliderCell;
    
    //cell.backgroundView = cback;
    
    return cell;
    
}


// PLAYER

- (UITableViewCell *)tableView:(UITableView *)tableView basePlayerNodeCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    NSUInteger nodeSection = indexPath.section;
    nodeSection = _selectedNodeIndex;

    NSUInteger nBaseRowsForNode = [self numberOfBaseRowsForNode];
    JWMixerNodeTypes nodeType = [self.playerNodeSelected[@"type"] integerValue];
    
    // within BASE ROWS
    
    //JWCustomCellBackground *cback = [[JWCustomCellBackground alloc] init];
    
    if (indexPath.row < nBaseRowsForNode) {
        
        if (nodeType == JWMixerNodeTypePlayer) {
            
            JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
            [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            
            id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:nodeSection];

            id <JWEffectsModifyingProtocol> tnode = [_delegateMixEdit trackNodeControllerForNodeAtIndex:nodeSection];
            
            // PLAYER VOLUME
            if (indexPath.row ==0) {
                sliderCell.slider.minimumValue = 0.0;
                sliderCell.slider.maximumValue = 1.0;
                sliderCell.slider.value = [node floatValue1];
                [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:)
                            forControlEvents:UIControlEventValueChanged];

                [tnode adjustFloatValue1:[node floatValue1]];
                [sliderCell.slider addTarget:tnode action:@selector(adjustFloatValue1WithSlider:)
                            forControlEvents:UIControlEventValueChanged];

                
                [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
                //[sliderCell.slider addTarget:cback action:@selector(adjustGOffsetVolume:) forControlEvents:UIControlEventValueChanged];
                //[sliderCell.slider addTarget:cback action:@selector(sliderDidFinish:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
                
                sliderCell.sliderLabel.text = @"volume";
                cell = sliderCell;
                
            }
            
            // PLAYER PAN
            else if (indexPath.row ==1) {
                sliderCell.slider.minimumValue = -1.0;
                sliderCell.slider.maximumValue = 1.0;
                sliderCell.slider.value = [node floatValue2];
                [sliderCell.slider addTarget:node action:@selector(adjustFloatValue2WithSlider:)
                            forControlEvents:UIControlEventValueChanged];
                
                [tnode adjustFloatValue2:[node floatValue2]];
                [sliderCell.slider addTarget:tnode action:@selector(adjustFloatValue2WithSlider:)
                            forControlEvents:UIControlEventValueChanged];

                sliderCell.sliderLabel.text = @"pan";
                cell = sliderCell;
            }
            
        } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
            
            if  (nBaseRowsForNode > 1){
                // means 3 two for player one for recprder
                
                // PLAYER RECORDER VOLUME
                if (indexPath.row ==0) {
                    
                    JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
                    [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
                    id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:nodeSection];
                    id <JWEffectsModifyingProtocol> tnode = [_delegateMixEdit trackNodeControllerForNodeAtIndex:nodeSection];
                    
                    sliderCell.slider.minimumValue = 0.0;
                    sliderCell.slider.maximumValue = 1.0;
                    sliderCell.slider.value = [node floatValue1];
                    
                    [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
                    
                    [tnode adjustFloatValue1:[node floatValue1]];
                    [sliderCell.slider addTarget:tnode action:@selector(adjustFloatValue1WithSlider:)
                                forControlEvents:UIControlEventValueChanged];

                    sliderCell.sliderLabel.text = @"volume";
                    cell = sliderCell;
                    
                }

                // PLAYER RECORDER PAN
                else if (indexPath.row ==1) {
                    
                    JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
                    [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
                    id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:nodeSection];
                    id <JWEffectsModifyingProtocol> tnode = [_delegateMixEdit trackNodeControllerForNodeAtIndex:nodeSection];

                    sliderCell.slider.minimumValue = -1.0;
                    sliderCell.slider.maximumValue = 1.0;
                    sliderCell.slider.value = [node floatValue2];
                    [sliderCell.slider addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
                    [tnode adjustFloatValue2:[node floatValue2]];
                    [sliderCell.slider addTarget:tnode action:@selector(adjustFloatValue2WithSlider:)
                                forControlEvents:UIControlEventValueChanged];

                    sliderCell.sliderLabel.text = @"pan";
                    cell = sliderCell;
                    
                }

                // PLAYER RECORDER RECORD
                else if (indexPath.row ==2) {
                    
                    JWRecorderTableViewCell *recorderCell = [tableView dequeueReusableCellWithIdentifier:@"JWRecorderCell" forIndexPath:indexPath];
                    //[recorderCell.recorderSwitch removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
                    [recorderCell.recordButton removeTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    id <JWEffectsModifyingProtocol> node = [_effectsHandler recorderNodeAtIndex:nodeSection];
                    
                    recorderCell.recordButton.tag = nodeSection;
                    [recorderCell.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    
                    BOOL recording = [node boolValue1];
                    recorderCell.recording = recording;
                    recorderCell.recordingEnabled = NO;
                    recorderCell.titleLabel.text = @"Recorder";
                    recorderCell.switchLabel.text = @"Enabled";
                    cell = recorderCell;
                }
                
            } else {
                
                // PLAYER RECORDER RECORD

                // just one row - have no fileURL yet for player controls
                JWRecorderTableViewCell *recorderCell = [tableView dequeueReusableCellWithIdentifier:@"JWRecorderCell" forIndexPath:indexPath];
                
                //[recorderCell.recorderSwitch removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
                [recorderCell.recordButton removeTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                
                id <JWEffectsModifyingProtocol> node = [_effectsHandler recorderNodeAtIndex:nodeSection];
                
                recorderCell.recordButton.tag = indexPath.section;
                [recorderCell.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                
                BOOL recording = [node boolValue1];
                recorderCell.recordingEnabled = YES;
                recorderCell.recording = recording;
                recorderCell.titleLabel.text = @"Recorder";
                recorderCell.switchLabel.text = @"Enabled";
                cell = recorderCell;
            }
            
        }  // end playerrecorder
        
        
    } else {
        
        cell = [self tableView:tableView effectCellForRowAtIndexPath:indexPath baseRowForNodes:nBaseRowsForNode];
    }
    
    //cell.backgroundView = cback;

    return cell;
}


// effects nodes
// indexPath row is == 2 or GREATER

- (UITableViewCell *)tableView:(UITableView *)tableView effectCellForRowAtIndexPath:(NSIndexPath *)indexPath
               baseRowForNodes:(NSUInteger)nBaseRowsForNode {
    
    UITableViewCell *cell;
    
    NSUInteger arrayIndex = indexPath.row - nBaseRowsForNode; // -2 the first cells for player
    
    NSUInteger nodeSection = indexPath.section;
    nodeSection = _selectedNodeIndex;
    
    //JWCustomCellBackground *cback = [[JWCustomCellBackground alloc] init];
    //TODO: could just use playernodeselected dictionary?
    id <JWEffectsModifyingProtocol> node = [_effectsHandler effectNodeAtIndex:arrayIndex forPlayerNodeAtIndex:nodeSection];
    
    if (node) {
        
        NSString *effectTitle = [self effectTitleForNodeAtIndex:indexPath.section effectIndex:arrayIndex];
        
        JWEffectNodeTypes effectKind = [self effectNodeTypeForNodeAtIndex:indexPath.section effectIndex:arrayIndex];

        if (effectKind == JWEffectNodeTypeReverb) {
            
            JWSliderAndSwitchTableViewCell *sliderAndSwitchCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWSliderAndSwitchCell" forIndexPath:indexPath];
            
            [sliderAndSwitchCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            sliderAndSwitchCell.slider.minimumValue = 0;
            sliderAndSwitchCell.slider.maximumValue = 100;  // wet dry is percent 0 to 100
            sliderAndSwitchCell.slider.value = [node floatValue1];
            
            sliderAndSwitchCell.switchControl.on = [node boolValue1];
            
            [sliderAndSwitchCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
            [sliderAndSwitchCell.switchControl addTarget:node action:@selector(adjustBoolValue1WithSwitch:) forControlEvents:UIControlEventValueChanged];
            
            sliderAndSwitchCell.sliderLabel.text = @"Wet/Dry";
            sliderAndSwitchCell.nodeTitleLabel.text = effectTitle;
            
            cell = sliderAndSwitchCell;
            
        } else if (effectKind == JWEffectNodeTypeDistortion) {
            
            
            JWEffectParametersTableViewCell *paramCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWEffectParametersCell" forIndexPath:indexPath];
            
            // Slider 1
            paramCell.parameterLabel1.text = @"Wet/Dry";
            [paramCell.effectParameter1 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter1.minimumValue = 0;
            paramCell.effectParameter1.maximumValue = 100;  // wet dry is percent 0 to 100
            paramCell.effectParameter1.value = [node floatValue1];
            [paramCell.effectParameter1 addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 2
            paramCell.parameterLabel2.text = @"Pre-Gain";
            [paramCell.effectParameter2 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter2.minimumValue = 0;
            paramCell.effectParameter2.maximumValue = 100;  // wet dry is percent 0 to 100
            paramCell.effectParameter2.value = [node floatValue2];
            [paramCell.effectParameter2 addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 3
            paramCell.parameterLabel3.hidden = YES;
            [paramCell.effectParameter3 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter3.hidden = YES;
            
            paramCell.nodeTitleLabel.text = effectTitle;
            
            cell = paramCell;
            
        } else if (effectKind == JWEffectNodeTypeDelay) {
            
            JWEffectParametersTableViewCell *paramCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWEffectParametersCell" forIndexPath:indexPath];
            
            
            // Slider 1
            paramCell.parameterLabel1.text = @"Wet/Dry";
            [paramCell.effectParameter1 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter1.minimumValue = 0;
            paramCell.effectParameter1.maximumValue = 100;
            paramCell.effectParameter1.value = [node floatValue1];
            [paramCell.effectParameter1 addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 2
            paramCell.parameterLabel2.text = @"Feedback";
            [paramCell.effectParameter2 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter2.minimumValue = -100;
            paramCell.effectParameter2.maximumValue = 100;  // wet dry is percent 0 to 100
            paramCell.effectParameter2.value = [node floatValue2];
            
            [paramCell.effectParameter2 addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 3
            paramCell.parameterLabel3.text = @"LowPass\nCutoff";
            [paramCell.effectParameter3 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter3.minimumValue = 10;
            paramCell.effectParameter3.maximumValue = 25000;  //
            paramCell.effectParameter3.value = [node floatValue3];
            [paramCell.effectParameter3 addTarget:node action:@selector(adjustFloatValue3WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            paramCell.nodeTitleLabel.text = effectTitle;

            
            cell = paramCell;
            
            
        } else if (effectKind == JWEffectNodeTypeEQ) {
            
            id <JWEffectsModifyingProtocol> node = [_effectsHandler effectNodeAtIndex:arrayIndex forPlayerNodeAtIndex:nodeSection];
            
            JWEffectParametersTableViewCell *paramCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWEffectParametersCell" forIndexPath:indexPath];
            
            // Slider 1
            paramCell.parameterLabel1.text = @"parm1";
            [paramCell.effectParameter1 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter1.minimumValue = 0;
            paramCell.effectParameter1.maximumValue = 2;  // wet dry is percent 0 to 100
            paramCell.effectParameter1.value = [node timeInterval1];
            [paramCell.effectParameter1 addTarget:node action:@selector(adjustTimeInterval1WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 2
            paramCell.parameterLabel2.text = @"parm2";
            [paramCell.effectParameter2 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter2.minimumValue = 0;
            paramCell.effectParameter2.maximumValue = 100;  // wet dry is percent 0 to 100
            paramCell.effectParameter2.value = [node floatValue1];
            
            [paramCell.effectParameter2 addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 3
            paramCell.parameterLabel3.text = @"parm3";
            [paramCell.effectParameter3 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter3.minimumValue = -100;
            paramCell.effectParameter3.maximumValue = 100;  //
            paramCell.effectParameter3.value = [node floatValue1];
            [paramCell.effectParameter3 addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            paramCell.nodeTitleLabel.text = effectTitle;
            
            cell = paramCell;
        } else {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
            
            NSLog(@"No effect Found. %s", __func__);
        }
        
        
    }
    
    //cell.backgroundView = cback;
    
    return cell;
    
}

//        JWEffectNodeTypeReverb,
//        JWEffectNodeTypeDelay,
//        JWEffectNodeTypeEQ,
//        JWEffectNodeTypeDistortion

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;

    //    NSUInteger mixNodeCount = [_playerNodeList count];
    //    NSUInteger lastPlayerNodeSection = mixNodeCount -1;
    
    NSUInteger lastPlayerNodeSection = 0;  // selectedNode

    // mixer node and scrubber controller sections
    NSUInteger bottomSections = 0;
    if (_sectionEnabledMixer)
        bottomSections++;
    if (_sectionEnabledScrubber)
        bottomSections++;
    
    if (bottomSections > 0 &&  indexPath.section > lastPlayerNodeSection) {
        
        // non player section
        
        cell = [self tableView:tableView bottomSectionCellForRowAtIndexPath:indexPath];
        
    } else {
        
        // player Section
        
        cell = [self tableView:tableView basePlayerNodeCellForRowAtIndexPath:indexPath];
        
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;//UITableViewCellSelectionStyleNone;
    
    if (![cell.selectedBackgroundView isKindOfClass:[JWCustomCellBackground class]]) {
        cell.selectedBackgroundView = [[JWCustomCellBackground alloc] init];
    }
    
    return cell;
    
}


-(void)recordButtonPressed:(id)sender
{
    NSUInteger indexNode = [(UIButton *)sender tag];
    NSLog(@"%s record button pressed for node at index %ld",__func__,indexNode);
    [_delegateMixEdit recordAtNodeIndex:indexNode];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    //    NSUInteger mixNodeCount = [_playerNodeList count];
    //    NSUInteger lastPlayerNodeSection = mixNodeCount -1;
    
    NSUInteger lastPlayerNodeSection = 0;  // selectedNode
    // mixer node and scrubber controller sections
    NSUInteger bottomSections = 0;
    if (_sectionEnabledMixer)
        bottomSections++;
    if (_sectionEnabledScrubber)
        bottomSections++;
    
    if (bottomSections > 0 &&  indexPath.section > lastPlayerNodeSection) {
        // non player section
        
    } else {
        
        // player Section
        
        NSUInteger nBaseRowsForNode = [self numberOfBaseRowsForNode];
        NSUInteger arrayIndex = indexPath.row - nBaseRowsForNode; // -2 the first cells for player

        if (indexPath.row < nBaseRowsForNode) {

        } else {
            
            JWEffectNodeTypes effectKind = [self effectNodeTypeForNodeAtIndex:indexPath.section effectIndex:arrayIndex];
            if (effectKind == JWEffectNodeTypeReverb) {
                return 90.0f;  // effects
            } else if (effectKind == JWEffectNodeTypeDelay) {
                return 200.0f;  // effects
            } else if (effectKind == JWEffectNodeTypeDistortion) {
                return 160.0f;  // effects
            } else if (effectKind == JWEffectNodeTypeEQ) {
                return 200.0f;  // effects
            }
        }
    }
    

    return 44.0f;
}


#pragma mark - Table view delegate

//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 80;
//}
//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
//    }


-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    //Set the background color of the View
    view.tintColor = [[UIColor blackColor] colorWithAlphaComponent:1.0];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{

    NSString *result;
    
    //    NSUInteger mixNodeCount = [_playerNodeList count];
    //    NSUInteger lastPlayerNodeSection = mixNodeCount -1;
    
    NSUInteger nodeSection = section;
    nodeSection = _selectedNodeIndex;

    NSUInteger lastPlayerNodeSection = 0;  // selectedNode
    
    // mixer node and scrubber controller sections
    NSUInteger bottomSections = 0;
    if (_sectionEnabledMixer)
        bottomSections++;
    if (_sectionEnabledScrubber)
        bottomSections++;
    
    if (bottomSections > 0 &&  section > lastPlayerNodeSection) {
        
        // non player section
        
        if (_mixerSection > 0 && section == _mixerSection) {
            result =  @"mixer";
        }
        
        if (_scrubberSection > 0 && section == _scrubberSection) {
            result = @"scrubber";
        }
        
    } else {
        
        // player Section
        
        result =  _playerNodeList[nodeSection][@"title"];
    }
    
    return result;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWHeaderViewX"];
    if (view == nil)
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"JWHeaderViewX"];
    view.contentView.backgroundColor = [UIColor jwBlackThemeColor];
    view.textLabel.textColor = [UIColor jwSectionTextColor];
    return view;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}


#pragma mark - Prepare for Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
    _currentSelectedEffectType = [self effectNodeTypeForNodeAtIndex:selected.section effectIndex:selected.row - [self numberOfBaseRowsForNode]];
    
    JWEffectPresetsTableViewController *prvc = [segue destinationViewController];
    
    if ([segue.identifier isEqualToString:@"PresetSegue"]) {
        if (_currentSelectedEffectType == JWEffectNodeTypeEQ) {
            
        } else if (_currentSelectedEffectType == JWEffectNodeTypeReverb) {
            
            NSArray *stringReverbPresets = [_effectsHandler stringRepresentedReverbPreset];
            [prvc setSystemDefinedpresets:stringReverbPresets];
            
        } else if (_currentSelectedEffectType == JWEffectNodeTypeDistortion) {
            
            NSArray *stringDistortionPresets = [_effectsHandler stringRepresentedDistortionPresets];
            [prvc setSystemDefinedpresets:stringDistortionPresets];
            
        } else if (_currentSelectedEffectType == JWEffectNodeTypeDelay) {
            
            NSDictionary *usrp = self.playerNodeList[_selectedNodeIndex][@"userpresets"];
            NSMutableArray *presetStrings = [[NSMutableArray alloc] init];
            for (NSString *preset in usrp[@"presetname"]) {
                [presetStrings addObject:preset];
            }
            
            [prvc setUserDefinedPresets:presetStrings];
            
        }
        
        if (_currentSelectedEffectType == JWEffectNodeTypeDistortion || _currentSelectedEffectType == JWEffectNodeTypeReverb) {
            NSArray *ef = self.playerNodeSelected[@"effects"];
            if (ef.count > 0) {
                NSDictionary *currentEF = ef[selected.row - [self numberOfBaseRowsForNode]];
                [prvc setSelectedEffectIndex:[currentEF[@"factorypreset"] integerValue]];
            }
        }                
        
    }
}



@end


