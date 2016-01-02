//
//  JWMixerTableViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/14/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWMixEditTableViewController.h"
// Effect slider Cell Types
#import "JWSliderTableViewCell.h"
#import "JWRecorderTableViewCell.h"
#import "JWSliderAndSwitchTableViewCell.h"
#import "JWEffectParametersTableViewCell.h"
#import "JWEffectPresetTableViewCell.h"
// Player node types
#import "JWMixNodes.h"


//    NSUInteger _expandSection;
//    NSInteger _expandRow;
//@property (nonatomic) CurrentEffect currentEffect;
//    _effectChosen = YES;
//    _expandRow = -1;


@interface JWMixEditTableViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
{
    BOOL _sectionEnabledScrubber;
    BOOL _sectionEnabledMixer;
    NSUInteger _mixerSection;
    NSUInteger _scrubberSection;
}
@property (strong, nonatomic) NSMutableArray *playerNodeList;
@property (strong, nonatomic) NSArray *effectnodesList;
@property (nonatomic) NSIndexPath* expandedEffectsCellIndexPath;
@end


@implementation JWMixEditTableViewController

#pragma mark - Table view data source

- (void)viewDidLoad {
    [super viewDidLoad];
//    _newConfig = NO;
    
    _sectionEnabledScrubber = YES;
    _sectionEnabledMixer = YES;
    self.clearsSelectionOnViewWillAppear = NO;  // preserve selection between presentations.
    
    CGRect fr = self.tableView.tableHeaderView.frame;
    fr.size.height = 66;
    self.tableView.tableHeaderView.frame = fr;

    _mixerSection = 0;
    _scrubberSection = 0;
    [self refresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refresh {
    
    [self getPlayerNodeListFromHandler];
    
    [self.tableView reloadData];
}

//    [self getListFromHandler];  // dont do this anymore effects are in playerNodeList
// dont do this anymore effects are in playerNodeList
//-(void)getListFromHandler
//    self.effectnodesList = [self.effectsHandler config];

-(void)getPlayerNodeListFromHandler
{
    self.playerNodeList = [self.effectsHandler configPlayerNodeList];
}

#pragma mark -

- (IBAction)didTapPanel:(id)sender
{
    [_delegateMixEdit doneWithMixEdit:self];
}

- (IBAction)returnPressed:(id)sender
{
    [_delegateMixEdit doneWithMixEdit:self];
}

-(void)refreshNewConfig
{
    [self refresh];
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
    NSArray * effects = [self effectsForNodeAtIndex:index];
    if ([effects count] > index) {
        id typeValue = effects[eIndex][@"type"];
        if (typeValue)
            result = [typeValue unsignedIntegerValue];
    }
    return result;
}

-(NSString *)effectTitleForNodeAtIndex:(NSUInteger)index effectIndex:(NSUInteger)eIndex {
    
    NSString * result;
    NSArray * effects = [self effectsForNodeAtIndex:index];
    if ([effects count] > index) {
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
    
    NSInteger count = [_playerNodeList count];
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger count = 0;
    NSUInteger mixNodeCount = [_playerNodeList count];

    NSUInteger lastPlayerNodeSection = mixNodeCount -1;

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
        
        NSUInteger nBaseRowsForNode = [self numberOfBaseRowsForNodeAtIndex:section];
     
        // PLAYER SECTION WITH EFFECTS
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:section];
        
        if (nodeType == JWMixerNodeTypePlayer) {
            count = nBaseRowsForNode; // 2 primary cells volume and pan
            count += [[self effectsForNodeAtIndex:section] count];
            
        } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
            
            id fileURL = [self playerNodeFileURLAtIndex:section];
            if (fileURL) {
                count = nBaseRowsForNode; // 2 primary cells volume and pan
                count += [[self effectsForNodeAtIndex:section] count];
            } else {
                count = 1; // one for recorder, 1 - ignore the player until URL
            }
        }
    }
    
    NSLog(@"%s %ld",__func__,count);
    return count;
    
}


-(NSUInteger)numberOfBaseRowsForNodeAtIndex:(NSUInteger)index
{
    NSUInteger nBaseRowsForNode = 0;
    JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
    if (nodeType == JWMixerNodeTypePlayer) {
        nBaseRowsForNode = 2; // 2 primary cells volume and pan
    } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
        id fileURL = [self playerNodeFileURLAtIndex:index];
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


//        NSUInteger thisSectionInBottomSections = section - lastPlayerNodeSection;
//        // 1 based
//        if (thisSectionInBottomSections == bottomSections) {
//            // Last section
//            if (thisSectionInBottomSections == 1) {
//                // There is just 1
//                if (_sectionEnabledMixer)
//                    count = 2;
//                else if (_sectionEnabledScrubber)
//                    count = 1;
//            } else {
//                // is the mixer section
//                count = 2;
//        } else {
//            // NOT Last section
//            if (thisSectionInBottomSections == 1) {
//                // There is just 1
//                if (_sectionEnabledMixer)
//                    count = 2;
//                else if (_sectionEnabledScrubber)
//                    count = 1;
//
//            } else {
//                // is the mixer section
//                count = 2;


// Last sections MIXER and SCRUBBER
// nodelist = 2 : 0 1,  2 > 2-1(1) true
// next to last mixer then scrubber

- (UITableViewCell *)tableView:(UITableView *)tableView bottomSectionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
    
    [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
    
    // First section beyond mixNodeCount
    
    if (_mixerSection > 0 && indexPath.section == _mixerSection) {

        // mixer
        // count == 2;
        
        id <JWEffectsModifyingProtocol> node = [_effectsHandler mixerNodeAtIndex:indexPath.section];
        
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
    
    return cell;
    
}





// PLAYER

- (UITableViewCell *)tableView:(UITableView *)tableView basePlayerNodeCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    NSUInteger nBaseRowsForNode = [self numberOfBaseRowsForNodeAtIndex:indexPath.section];
    JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:indexPath.section];
    
//    if (nodeType == JWMixerNodeTypePlayer) {
//        nBaseRowsForNode = 2; // 2 primary cells volume and pan
//        
//    } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
//        id fileURL = [self playerNodeFileURLAtIndex:indexPath.section];
//        if (fileURL) {
//            nBaseRowsForNode = 2; // 2 primary cells volume and pan
//            nBaseRowsForNode += [[self effectsForNodeAtIndex:indexPath.section] count];
//        } else {
//            nBaseRowsForNode = 1; // one for recorder, 1 - ignore the player until URL
//        }
//        
//        //nBaseRowsForNode = fileURL ? 3 : 1;  // two for player, one for recorder, 1 - ignore the player until URL
//    }
    
    // within BASE ROWS
    
    if (indexPath.row < nBaseRowsForNode) {
        
        if (nodeType == JWMixerNodeTypePlayer) {
            
            JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
            [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            
            id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:indexPath.section];
            
            // PLAYER VOLUME
            if (indexPath.row ==0) {
                sliderCell.slider.minimumValue = 0.0;
                sliderCell.slider.maximumValue = 1.0;
                sliderCell.slider.value = [node floatValue1];
                [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
                sliderCell.sliderLabel.text = @"volume";
                cell = sliderCell;
                
            }
            
            // PLAYER PAN
            else if (indexPath.row ==1) {
                sliderCell.slider.minimumValue = -1.0;
                sliderCell.slider.maximumValue = 1.0;
                sliderCell.slider.value = [node floatValue2];
                [sliderCell.slider addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
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
                    id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:indexPath.section];
                    sliderCell.slider.minimumValue = 0.0;
                    sliderCell.slider.maximumValue = 1.0;
                    sliderCell.slider.value = [node floatValue1];
                    [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
                    sliderCell.sliderLabel.text = @"volume";
                    cell = sliderCell;
                    
                }

                // PLAYER RECORDER PAN
                else if (indexPath.row ==1) {
                    
                    JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
                    [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
                    id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:indexPath.section];
                    sliderCell.slider.minimumValue = -1.0;
                    sliderCell.slider.maximumValue = 1.0;
                    sliderCell.slider.value = [node floatValue2];
                    [sliderCell.slider addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
                    sliderCell.sliderLabel.text = @"pan";
                    cell = sliderCell;
                    
                }

                // PLAYER RECORDER RECORD
                else if (indexPath.row ==2) {
                    
                    JWRecorderTableViewCell *recorderCell = [tableView dequeueReusableCellWithIdentifier:@"JWRecorderCell" forIndexPath:indexPath];
                    //[recorderCell.recorderSwitch removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
                    [recorderCell.recordButton removeTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    id <JWEffectsModifyingProtocol> node = [_effectsHandler recorderNodeAtIndex:indexPath.section];
                    
                    recorderCell.recordButton.tag = indexPath.section;
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
                id <JWEffectsModifyingProtocol> node = [_effectsHandler recorderNodeAtIndex:indexPath.section];
                
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

    return cell;
}


// effects nodes
// indexPath row is == 2 or GREATER

- (UITableViewCell *)tableView:(UITableView *)tableView effectCellForRowAtIndexPath:(NSIndexPath *)indexPath
               baseRowForNodes:(NSUInteger)nBaseRowsForNode {
    
    UITableViewCell *cell;
    
    NSUInteger arrayIndex = indexPath.row - nBaseRowsForNode; // -2 the first cells for player
    
    id <JWEffectsModifyingProtocol> node = [_effectsHandler effectNodeAtIndex:arrayIndex forPlayerNodeAtIndex:indexPath.section];
    
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
            
            sliderAndSwitchCell.sliderLabel.text = @"wetDry";
            sliderAndSwitchCell.nodeTitleLabel.text = effectTitle;
            
            cell = sliderAndSwitchCell;
            
        } else if (effectKind == JWEffectNodeTypeDistortion) {
            
            
            JWEffectParametersTableViewCell *paramCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWEffectParametersCell" forIndexPath:indexPath];
            
            // Slider 1
            paramCell.parameterLabel1.text = @"wetDry";
            [paramCell.effectParameter1 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter1.minimumValue = 0;
            paramCell.effectParameter1.maximumValue = 100;  // wet dry is percent 0 to 100
            paramCell.effectParameter1.value = [node floatValue1];
            [paramCell.effectParameter1 addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 2
            paramCell.parameterLabel2.text = @"pregain";
            [paramCell.effectParameter2 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter2.minimumValue = 0;
            paramCell.effectParameter2.maximumValue = 100;  // wet dry is percent 0 to 100
            paramCell.effectParameter2.value = [node floatValue1];
            [paramCell.effectParameter2 addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 3
            paramCell.parameterLabel3.hidden = YES;
            [paramCell.effectParameter3 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter3.hidden = YES;
            
            paramCell.nodeTitleLabel.text = effectTitle;
            
            cell = paramCell;

//            JWSliderAndSwitchTableViewCell *sliderAndSwitchCell =
//            [tableView dequeueReusableCellWithIdentifier:@"JWSliderAndSwitchCell" forIndexPath:indexPath];
//            
//            [sliderAndSwitchCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
//            sliderAndSwitchCell.slider.minimumValue = 0;
//            sliderAndSwitchCell.slider.maximumValue = 100;  // wet dry is percent 0 to 100
//            sliderAndSwitchCell.slider.value = [node floatValue1];
//            
//            sliderAndSwitchCell.switchControl.on = [node boolValue1];
//            
//            [sliderAndSwitchCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
//            [sliderAndSwitchCell.switchControl addTarget:node action:@selector(adjustBoolValue1WithSwitch:) forControlEvents:UIControlEventValueChanged];
//            sliderAndSwitchCell.sliderLabel.text = @"pregain";
//            sliderAndSwitchCell.nodeTitleLabel.text = effectTitle;
//            cell = sliderAndSwitchCell;
            
        } else if (effectKind == JWEffectNodeTypeDelay) {
            
            JWEffectParametersTableViewCell *paramCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWEffectParametersCell" forIndexPath:indexPath];
            
            
            // Slider 1
            paramCell.parameterLabel1.text = @"delayTime";
            [paramCell.effectParameter1 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter1.minimumValue = 0;
            paramCell.effectParameter1.maximumValue = .9;
            paramCell.effectParameter1.value = [node timeInterval1];
            [paramCell.effectParameter1 addTarget:node action:@selector(adjustTimeInterval1WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 2
            paramCell.parameterLabel2.text = @"wetDry";
            [paramCell.effectParameter2 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter2.minimumValue = 0;
            paramCell.effectParameter2.maximumValue = 100;  // wet dry is percent 0 to 100
            paramCell.effectParameter2.value = [node floatValue1];
            
            [paramCell.effectParameter2 addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            // Slider 3
            paramCell.parameterLabel3.text = @"feedBack";
            [paramCell.effectParameter3 removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
            paramCell.effectParameter3.minimumValue = -100;
            paramCell.effectParameter3.maximumValue = 100;  //
            paramCell.effectParameter3.value = [node floatValue1];
            [paramCell.effectParameter3 addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
            
            paramCell.nodeTitleLabel.text = effectTitle;

            
            cell = paramCell;
            
            
        } else if (effectKind == JWEffectNodeTypeEQ) {
            
            id <JWEffectsModifyingProtocol> node = [_effectsHandler effectNodeAtIndex:arrayIndex forPlayerNodeAtIndex:indexPath.section];
            
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
    
    return cell;
    
}



//    typedef NS_ENUM(NSUInteger, JWEffectNodeTypes) {
//        JWEffectNodeTypeReverb,
//        JWEffectNodeTypeDelay,
//        JWEffectNodeTypeEQ,
//        JWEffectNodeTypeDistortion
//    };
//    JWEffectNodeTypes type = JWEffectNodeTypeDistortion
//    if ([nodeTitle isEqualToString:@"Effect Reverb"]) {
//        sliderAndSwitchCell.sliderLabel.text = @"wetDry";
//        sliderAndSwitchCell.nodeTitleLabel.text = nodeTitle;
//    } else  if ([nodeTitle isEqualToString:@"Effect Delay"]) {
//        sliderAndSwitchCell.sliderLabel.text = @"wetDry";
//        sliderAndSwitchCell.nodeTitleLabel.text = nodeTitle;
//    } else if ([nodeTitle isEqualToString:@"Effect EQ"]) {
//        sliderAndSwitchCell.sliderLabel.text = @"wetDry";
//        sliderAndSwitchCell.nodeTitleLabel.text = nodeTitle;
//    }else if ([nodeTitle isEqualToString:@"Effect Distortion"]) {
//        sliderAndSwitchCell.sliderLabel.text = @"wetDry";
//        sliderAndSwitchCell.nodeTitleLabel.text = nodeTitle;
//    }




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    NSUInteger mixNodeCount = [_playerNodeList count] ;
    NSUInteger lastPlayerNodeSection = mixNodeCount -1;
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
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
    
}


-(void)recordButtonPressed:(id)sender
{
    NSUInteger indexNode = [(UIButton *)sender tag];
    NSLog(@"%s record button pressed for node at index %ld",__func__,indexNode);

    // TODO: have a delaget method to get to recordjam to begin recording
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    NSUInteger mixNodeCount = [_playerNodeList count] ;
    NSUInteger lastPlayerNodeSection = mixNodeCount -1;
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
        
        NSUInteger nBaseRowsForNode = [self numberOfBaseRowsForNodeAtIndex:indexPath.section];
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


//        NSUInteger nBaseRowsForNode = 0;
//        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:indexPath.section];
//        if (nodeType == JWMixerNodeTypePlayer) {
//            nBaseRowsForNode = 2; // 2 primary cells volume and pan
//        } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
//            id fileURL = [self playerNodeFileURLAtIndex:indexPath.section];
//            if (fileURL) {
//                nBaseRowsForNode = 2; // 2 primary cells volume and pan
//                nBaseRowsForNode += [[self effectsForNodeAtIndex:indexPath.section] count];
//            } else {
//                nBaseRowsForNode = 1; // one for recorder, 1 - ignore the player until URL
//            }
////            nBaseRowsForNode = fileURL ? 3 : 1;  // two for player, one for recorder, 1 - ignore the player until URL
//        }


#pragma mark - Table view delegate

//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 80;
//}
//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
//    }

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{

    NSString *result;

    NSUInteger mixNodeCount = [_playerNodeList count];
    NSUInteger lastPlayerNodeSection = mixNodeCount -1;
    
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
        
        result =  _playerNodeList[section][@"title"];
    }
    
    return result;
}


//if (section > mixNodeCount -1) {
//    // Last sections
//    if (section == mixNodeCount) {
//        result =  @"mixer";
//    } else {
//        result = @"scrubber";
//    }
//} else {
//    result =  _playerNodeList[section][@"title"];
//}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}

#pragma mark save and retrieve

#pragma mark - PICKER VIEW

//just copied and pasted this from the mix table, will be changed later
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 4;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0 )
        return @"Delay";
    else if (row == 1 )
        return @"Distortion";
    else if (row == 2 )
        return @"EQ";
    else if (row == 3 )
        return @"Reverb";
    
    return @"err";
}


@end



//    else if (indexPath.section == 1) {
//        // PLAYER 2
//        if (indexPath.row < 2) {
//            JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
//            [sliderCell.slider removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
//            if (indexPath.row ==0) {
//                sliderCell.slider.minimumValue = 0.0;
//                sliderCell.slider.maximumValue = 1.0;
//                sliderCell.slider.value = [_delegateMixEdit valueForVolumePlayer2];
//                [sliderCell.slider addTarget:self action:@selector(player2SliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
//                sliderCell.sliderLabel.text = @"volume";
//            } else if (indexPath.row ==1) {
//                sliderCell.slider.minimumValue = -1.0;
//                sliderCell.slider.maximumValue = 1.0;
//                sliderCell.slider.value = [_delegateMixEdit valueForPanPlayer2];
//                [sliderCell.slider addTarget:self action:@selector(player2PanSliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
//                sliderCell.sliderLabel.text = @"pan";
//            }
//            cell = sliderCell;
//        } else {
//            // effects nodes



//if (_expandSection == section) {
//    if (_expandRow >= 0) {
//        count += [_effectnodesList[section] count] + 1;
//        NSLog(@"Should return %ld Cells section %ld", count,section);
//    } else {  //Not expanded
//        // this one
//        count += [_effectnodesList[section] count];
//        NSLog(@"Should return %ld Cells section %ld", count,section);
//} else {
//    count += [_effectnodesList[section] count];
//    NSLog(@"Should return %ld Cells section %ld", count,section);


//    if (_expandedEffectsCellIndexPath && _expandedEffectsCellIndexPath.section == indexPath.section && _expandedEffectsCellIndexPath.row == indexPath.row) {
//            return 200.0f;
//    }

//-(CurrentEffect)setCurrentEffectForString:(NSString *)nodeTitle {
//
//    if ([nodeTitle isEqualToString:@"Effect Reverb"]) {
//        return EffectReverb;
//    } else if ([nodeTitle isEqualToString:@"Effect Delay"]) {
//        return EffectDelay;
//    } else if ([nodeTitle isEqualToString:@"Effect Distortion"]) {
//        return EffectDistortion;
//    } else if ([nodeTitle isEqualToString:@"Effect EQ"]) {
//        return EffectEQ;
//    }
//    return -1;
//}

// PLAYER 2
//-(void)player2SliderValueDidChange:(id)sender{
////    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit playerNode2SliderValueChanged:[(UISlider*)sender value]];
//-(void)player2PanSliderValueDidChange:(id)sender{
////    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit playerNode2PanSliderValueChanged:[(UISlider*)sender value]];

////called from the mix panel when the mix table's picker view is collapsed
////This just shows that an effect has been chosen and the mix edit needs to be expanded
////need some condition to collapse the cell
//-(void)expandCellAtSection:(NSUInteger)section andRow:(NSUInteger)row {
//    _expandRow = row;
//    _expandSection = section;
//    NSString* nodeType = _effectnodesList[section][row - 2][@"title"];
//    //gonna use this for effect customization for the picker view and other things that need specific
//    //effect type customization
//    self.currentEffect = [self setCurrentEffectForString:nodeType];
//    [self refresh];

//// indexPath row is == 2 or GREATER
//
//// effects nodes
//NSUInteger arrayIndex;
////Player tag to identify when selector sends slider value did change - starts with 0 and every time a slider and switch
////cell is created it gets ++ after set to the sliders tag
//NSUInteger currentPlayerTag = 0;
//NSString *nodetype;
//NSString *nodeTitle;
//JWSliderAndSwitchTableViewCell *sliderAndSwitchCell;
//
////the expand row + 1 is the row that should be expanded, is given to this controller
////from the mix table controller when the cell gets colapsed ( means the user wants that effect)
////I combined all of the sliders into one and would like to identify them by using the .tag of the slider
//if (indexPath.row != _expandRow + 1) {
//    NSLog(@"index row is %ld, index mod 2 is %ld", (long)indexPath.row, indexPath.row % 2);
//    arrayIndex = indexPath.row / 2 - 1;
//} else {
//    //Bool value not really utilized right now, maybe sholdnt even have it
//    if (_effectChosen) {
//
//        _expandedEffectsCellIndexPath = indexPath;
//        if (_expandedEffectsCellIndexPath) {
//            //Only should have presets
//            if ( self.currentEffect == EffectReverb || self.currentEffect == EffectEQ) {
//                JWEffectPresetTableViewCell* presetCell = [tableView dequeueReusableCellWithIdentifier:@"JWEffectPresetCell" forIndexPath:indexPath];
//                presetCell.effectPresets.delegate = self;
//                presetCell.effectPresets.dataSource = self;
//                cell = presetCell;
//                //Has some sliders you can change
//            } else if (self.currentEffect == EffectDelay) {
//
//                JWEffectParametersTableViewCell* parametersCell = [tableView dequeueReusableCellWithIdentifier:@"JWEffectParametersCell" forIndexPath:indexPath];
//                cell = parametersCell;
//                //Has presets and a slider
//            }  else if (self.currentEffect == EffectDistortion) {
//
//                JWEffectPresetTableViewCell* presetCell = [tableView dequeueReusableCellWithIdentifier:@"JWEffectPresetCell" forIndexPath:indexPath];
//                presetCell.effectPresets.delegate = self;
//                presetCell.effectPresets.dataSource = self;
//                cell = presetCell;
//        //Not sure if this works
//    } else {
//        NSArray *indexPaths = @[[NSIndexPath indexPathForRow:_expandedEffectsCellIndexPath.row+1  inSection:_expandedEffectsCellIndexPath.section]];
//        _expandedEffectsCellIndexPath = nil;
//
//        [self.tableView beginUpdates];
//        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
//        [self.tableView endUpdates];

//            if (arrayIndex==0) {
//            } else if (arrayIndex==1) {
//                sliderAndSwitchCell.slider.value = [_delegateMixEdit floatValue1ForPlayer:0 forEffectNodeAtIndex:1];
//                sliderAndSwitchCell.switchControl.on = [_delegateMixEdit boolValue1ForPlayer:0 forEffectNodeAtIndex:1];
//
//                [sliderAndSwitchCell.slider addTarget:self action:@selector(player1EffectNode2SliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
//                [sliderAndSwitchCell.switchControl addTarget:self action:@selector(player1EffectNode2BoolValueDidChange:) forControlEvents:UIControlEventValueChanged];
//            } else if (arrayIndex==2) {
//                sliderAndSwitchCell.slider.value = [_delegateMixEdit floatValue1ForPlayer:0 forEffectNodeAtIndex:2];
//                sliderAndSwitchCell.switchControl.on = [_delegateMixEdit boolValue1ForPlayer:0 forEffectNodeAtIndex:2];
//
//                [sliderAndSwitchCell.slider addTarget:self action:@selector(player1EffectNode3SliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
//                [sliderAndSwitchCell.switchControl addTarget:self action:@selector(player1EffectNode3BoolValueDidChange:) forControlEvents:UIControlEventValueChanged];
//            } else if (arrayIndex==3) {
//                sliderAndSwitchCell.slider.value = [_delegateMixEdit floatValue1ForPlayer:0 forEffectNodeAtIndex:3];
//                sliderAndSwitchCell.switchControl.on = [_delegateMixEdit boolValue1ForPlayer:0 forEffectNodeAtIndex:3];
//
//                [sliderAndSwitchCell.slider addTarget:self action:@selector(player1EffectNode4SliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
//                [sliderAndSwitchCell.switchControl addTarget:self action:@selector(player1EffectNode4BoolValueDidChange:) forControlEvents:UIControlEventValueChanged];
//            }

//-(void)loadPlayerNodeData {
//    if (_playerNodeList == nil) {
//        NSLog(@"%s no list creating new one ",__func__ );
////        _playerNodeList = [@[] mutableCopy];
//        _playerNodeList =
//        [@[
//           @{@"title":@"playernode1",
//             @"type":@"playernode"
//             },
//           @{@"title":@"playernode2",
//             @"type":@"playernode"
//             }
//           ] mutableCopy];
//    }
//}

// joe: not used
//- (void)loadData {
//
//    // joe: No, is not read here get from audio engine
//    //[self readUserOrderedList];
//
//    if (_playerNodeList == nil) {
//        NSLog(@"%s no list creating new one ",__func__ );
//
//        _playerNodeList =
//        [@[
//           @{@"title":@"playernode1",
//             @"type":@"playernode"
//             },
//           @{@"title":@"playernode2",
//             @"type":@"playernode"
//             }
//           ] mutableCopy];
//    }
//
//    if (_effectnodesList == nil) {
//        NSLog(@"%s no effects list creating new one ",__func__ );
//
//    //joe:
//        self.effectnodesList = [@[] mutableCopy];
//
//        [_effectnodesList addObject:[@[] mutableCopy]];
//        [_effectnodesList addObject:[@[] mutableCopy]];
////        _effectnodesList[0] =
////        [@[
////           @{@"title":@"Effect Reverb",
////             @"type":@"effectsnodeReverbPresetMediumHall3",
////             },
////           @{@"title":@"Effect Delay",
////             @"type":@"effectsnodeDelay",
////             }
////           ] mutableCopy];
//    }
//
//}


//-(NSString*)documentsDirectoryPath {
//    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    return [searchPaths objectAtIndex:0];
//}
//
//// joe: dont need this
////-(void)saveMetaData{
////
////}
////-(void)readMetaData{
////}
////
//
//// joe: probably dont need these either let the engine read and write to disk
////
//-(void)savePlayerNodeList
//{
//    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"mixerlist.dat"];
//    [_playerNodeList writeToURL:[NSURL fileURLWithPath:fpath] atomically:YES];
//
//    NSLog(@"\n%s\nmixerlist.dat\n%@",__func__,[_playerNodeList description]);
//}
//
//-(void)readPlayerNodeList
//{
//    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"mixerlist.dat"];
//    _playerNodeList = [[NSMutableArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fpath]];
//
//    NSLog(@"\n%s\nmixerlist.dat\n%@",__func__,[_playerNodeList description]);
//}


//
// joe: NO, we do not read and write effects to disk we get from audio engine
//
//-(void)saveUserOrderedList
//{
//    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"mixereffects.dat"];
//    [_effectnodesList writeToURL:[NSURL fileURLWithPath:fpath] atomically:YES];
//
//    NSLog(@"\n%s\nmixereffects.dat\n%@",__func__,[_effectnodesList description]);
//}
//
//-(void)readUserOrderedList
//{
//    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"mixereffects.dat"];
//    _effectnodesList = [[NSMutableArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fpath]];
//
//    NSLog(@"\n%s\nmixereffects.dat\n%@",__func__,[_effectnodesList description]);
//}



// PLAYER 1

// joe: category of AVAudioUnitEffect
//-(void)player1EffectNode1BoolValueDidChange:(id)sender{
//    //    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit switchValueDidChangeForPlayerAtIndex:0 effectNodeAtIndex:0 toValue:[(UISwitch*)sender isOn]];
//}
//-(void)player1EffectNode2BoolValueDidChange:(id)sender{
//    //    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit switchValueDidChangeForPlayerAtIndex:0 effectNodeAtIndex:1 toValue:[(UISwitch*)sender isOn]];
//}
//-(void)player1EffectNode3BoolValueDidChange:(id)sender{
//    //    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit switchValueDidChangeForPlayerAtIndex:0 effectNodeAtIndex:2 toValue:[(UISwitch*)sender isOn]];
//}
//-(void)player1EffectNode4BoolValueDidChange:(id)sender{
//    //    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit switchValueDidChangeForPlayerAtIndex:0 effectNodeAtIndex:3 toValue:[(UISwitch*)sender isOn]];
//}
//
//-(void)player1EffectNode1SliderValueDidChange:(id)sender{
////    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit slider1ValueDidForPlayerAtIndex:0 effectNodeAtIndex:0 toValue:[(UISlider*)sender value]];
//}
//-(void)player1EffectNode2SliderValueDidChange:(id)sender{
////    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit slider1ValueDidForPlayerAtIndex:0 effectNodeAtIndex:1 toValue:[(UISlider*)sender value]];
//}
//-(void)player1EffectNode3SliderValueDidChange:(id)sender{
//    //    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit slider1ValueDidForPlayerAtIndex:0 effectNodeAtIndex:2 toValue:[(UISlider*)sender value]];
//}
//-(void)player1EffectNode4SliderValueDidChange:(id)sender{
//    //    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit slider1ValueDidForPlayerAtIndex:0 effectNodeAtIndex:3 toValue:[(UISlider*)sender value]];
//}

//-(void)player1SliderValueDidChange:(id)sender{
////    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit playerNode1SliderValueChanged:[(UISlider*)sender value]];
//}
//-(void)player1PanSliderValueDidChange:(id)sender{
////    NSLog(@"%s %.3f",__func__,[(UISlider*)sender value]);
//    [_delegateMixEdit playerNode1PanSliderValueChanged:[(UISlider*)sender value]];
//}



//// LAST SECTIONS
//if (indexPath.section > mixNodeCount -1) {
//    // -----------------------
//    //        bottomSectionCellForRowAtIndexPath:indexPath];
//    // -----------------------
//    // nodelist = 2 : 0 1,  2 > 2-1(1) true
//    // next to last mixer then scrubber
//    JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
//    [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
//    // First section beyond mixNodeCount
//    if (indexPath.section == mixNodeCount) {
//        // mixer
//        id <JWEffectsModifyingProtocol> node = [_effectsHandler mixerNodeAtIndex:indexPath.section];
//        if (indexPath.row ==0) {
//            sliderCell.slider.minimumValue = 0.0;
//            sliderCell.slider.maximumValue = 1.0;
//            sliderCell.slider.value = [node floatValue1];
//            [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
//            sliderCell.sliderLabel.text = @"outputvolume";
//        } else if (indexPath.row ==1) {
//            sliderCell.slider.minimumValue = -1.0;
//            sliderCell.slider.maximumValue = 1.0;
//            sliderCell.slider.value = [node floatValue2];
//            [sliderCell.slider addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
//            sliderCell.sliderLabel.text = @"pan";
//    } else {
//        // very last node  scrubber always last
//        id <JWEffectsModifyingProtocol> node = [_delegateMixEdit mixNodeControllerForScrubber];
//        if (indexPath.row ==0) {
//            sliderCell.slider.minimumValue = 0.0;
//            sliderCell.slider.maximumValue = 1.0;
//            sliderCell.slider.value = [node floatValue1];
//            [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
//            sliderCell.sliderLabel.text = @"backlight";
//    }
//    cell = sliderCell;

//// WITHIN PLAYER NODES SECTIONS
//
//else  {
//    // -----------------------
//    //        basePlayerNodeCellForRowAtIndexPath:indexPath];
//    // -----------------------
//    NSUInteger nBaseRowsForNode = 0;
//    // PLAYER
//    JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:indexPath.section];
//    if (nodeType == JWMixerNodeTypePlayer) {
//        nBaseRowsForNode = 2; // 2 primary cells volume and pan
//    } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
//        id fileURL = [self playerNodeFileURLAtIndex:indexPath.section];
//        nBaseRowsForNode = fileURL ? 3 : 1;  // two for player, one for recorder, 1 - ignore the player until URL
//    }
//    // within BASE ROWS
//    if (indexPath.row < nBaseRowsForNode) {
//        if (nodeType == JWMixerNodeTypePlayer) {
//            JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
//            [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
//            id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:indexPath.section];
//            if (indexPath.row ==0) {
//                sliderCell.slider.minimumValue = 0.0;
//                sliderCell.slider.maximumValue = 1.0;
//                sliderCell.slider.value = [node floatValue1];
//                [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
//                sliderCell.sliderLabel.text = @"volume";
//                cell = sliderCell;
//            } else if (indexPath.row ==1) {
//                sliderCell.slider.minimumValue = -1.0;
//                sliderCell.slider.maximumValue = 1.0;
//                sliderCell.slider.value = [node floatValue2];
//                [sliderCell.slider addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
//                sliderCell.sliderLabel.text = @"pan";
//                cell = sliderCell;
//            }
//        } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
//            if  (nBaseRowsForNode > 1){
//                // means 3 two for player one for recprder
//                if (indexPath.row ==0) {
//                    JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
//                    [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
//                    id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:indexPath.section];
//                    sliderCell.slider.minimumValue = 0.0;
//                    sliderCell.slider.maximumValue = 1.0;
//                    sliderCell.slider.value = [node floatValue1];
//                    [sliderCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
//                    sliderCell.sliderLabel.text = @"volume";
//                    cell = sliderCell;
//                } else if (indexPath.row ==1) {
//                    JWSliderTableViewCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:@"JWMixEditSliderCell" forIndexPath:indexPath];
//                    [sliderCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
//                    id <JWEffectsModifyingProtocol> node = [_effectsHandler playerNodeAtIndex:indexPath.section];
//                    sliderCell.slider.minimumValue = -1.0;
//                    sliderCell.slider.maximumValue = 1.0;
//                    sliderCell.slider.value = [node floatValue2];
//                    [sliderCell.slider addTarget:node action:@selector(adjustFloatValue2WithSlider:) forControlEvents:UIControlEventValueChanged];
//                    sliderCell.sliderLabel.text = @"pan";
//                    cell = sliderCell;
//                } else if (indexPath.row ==2) {
//                    JWRecorderTableViewCell *recorderCell = [tableView dequeueReusableCellWithIdentifier:@"JWRecorderCell" forIndexPath:indexPath];
//                    //[recorderCell.recorderSwitch removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
//                    [recorderCell.recordButton removeTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//                    id <JWEffectsModifyingProtocol> node = [_effectsHandler recorderNodeAtIndex:indexPath.section];
//                    
//                    recorderCell.recordButton.tag = indexPath.section;
//                    [recorderCell.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//                    
//                    BOOL recording = [node boolValue1];
//                    recorderCell.recording = recording;
//                    recorderCell.recordingEnabled = NO;
//                    recorderCell.titleLabel.text = @"Recorder";
//                    recorderCell.switchLabel.text = @"Enabled";
//                    cell = recorderCell;
//                }
//            } else {
//                // just one row - have no fileURL yet for player controls
//                JWRecorderTableViewCell *recorderCell = [tableView dequeueReusableCellWithIdentifier:@"JWRecorderCell" forIndexPath:indexPath];
//                //[recorderCell.recorderSwitch removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
//                [recorderCell.recordButton removeTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//                id <JWEffectsModifyingProtocol> node = [_effectsHandler recorderNodeAtIndex:indexPath.section];
//                
//                recorderCell.recordButton.tag = indexPath.section;
//                [recorderCell.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//                
//                BOOL recording = [node boolValue1];
//                recorderCell.recordingEnabled = YES;
//                recorderCell.recording = recording;
//                recorderCell.titleLabel.text = @"Recorder";
//                recorderCell.switchLabel.text = @"Enabled";
//                cell = recorderCell;
//            }
//            
//        }  // end playerrecorder
//    }
//    // BEYOND BASE ROWS
//    else {
//        // effects nodes
//        // indexPath row is == 2 or GREATER
//        NSUInteger arrayIndex;
//        NSString *nodetype;
//        NSString *nodeTitle;
//        arrayIndex = indexPath.row - 2; // -2 the first cells for player
//        
//        nodetype = _effectnodesList[0][arrayIndex][@"type"];
//        nodeTitle = _effectnodesList[0][arrayIndex][@"title"];
//        
//        JWSliderAndSwitchTableViewCell *sliderAndSwitchCell =
//        [tableView dequeueReusableCellWithIdentifier:@"JWSliderAndSwitchCell" forIndexPath:indexPath];
//        
//        [sliderAndSwitchCell.slider removeTarget:nil action:nil forControlEvents:UIControlEventValueChanged];
//        id <JWEffectsModifyingProtocol> node = [_effectsHandler effectNodeAtIndex:arrayIndex forPlayerNodeAtIndex:indexPath.section];
//        
//        sliderAndSwitchCell.slider.minimumValue = 0;
//        sliderAndSwitchCell.slider.maximumValue = 100;  // wet dry is percent 0 to 100
//        sliderAndSwitchCell.slider.value = [node floatValue1];
//        
//        sliderAndSwitchCell.switchControl.on = [node boolValue1];
//        
//        [sliderAndSwitchCell.slider addTarget:node action:@selector(adjustFloatValue1WithSlider:) forControlEvents:UIControlEventValueChanged];
//        [sliderAndSwitchCell.switchControl addTarget:node action:@selector(adjustBoolValue1WithSwitch:) forControlEvents:UIControlEventValueChanged];
//        
//        if ([nodeTitle isEqualToString:@"Effect Reverb"]) {
//            sliderAndSwitchCell.sliderLabel.text = @"wetDry";
//            sliderAndSwitchCell.nodeTitleLabel.text = nodeTitle;
//        } else  if ([nodeTitle isEqualToString:@"Effect Delay"]) {
//            sliderAndSwitchCell.sliderLabel.text = @"wetDry";
//            sliderAndSwitchCell.nodeTitleLabel.text = nodeTitle;
//        } else if ([nodeTitle isEqualToString:@"Effect EQ"]) {
//            sliderAndSwitchCell.sliderLabel.text = @"wetDry";
//            sliderAndSwitchCell.nodeTitleLabel.text = nodeTitle;
//        }else if ([nodeTitle isEqualToString:@"Effect Distortion"]) {
//            sliderAndSwitchCell.sliderLabel.text = @"wetDry";
//            sliderAndSwitchCell.nodeTitleLabel.text = nodeTitle;
//        }
//        cell = sliderAndSwitchCell;
//        
//cell.selectionStyle = UITableViewCellSelectionStyleNone;
//return cell;
