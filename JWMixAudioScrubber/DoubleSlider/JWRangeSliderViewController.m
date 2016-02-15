//
//  JWRangeSliderViewController.m
//  JamWDev
//
//  Created by brendan kerr on 1/23/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWRangeSliderViewController.h"


@interface JWRangeSliderViewController () {

}

@end

@implementation JWRangeSliderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    NSUInteger margin = 20;
    CGRect sliderFrame = CGRectMake(margin, margin * 3, self.view.frame.size.width - margin * 2, 33);
    _rangeSlider = [[CERangeSlider alloc] initWithFrame:sliderFrame];
    
    _lowerTimeCount = [CETimeCountLayer layer];
    [_lowerTimeCount setFrame:CGRectMake(0, 0, 50, 50)];
    [_lowerTimeCount setLower:YES];
    [_lowerTimeCount createText];
    //[_lowerTimeCount setReferenceObjectPosition:_rangeSlider.lowerKnobCenterInParent];
    //[_lowerTimeCount setReferenceObjectFrame:_rangeSlider.lowerKnobLayer.frame];
    
    _upperTimeCount = [CETimeCountLayer layer];
    [_upperTimeCount setFrame:CGRectMake(0, 0, 50, 50)];
    [_upperTimeCount setLower:NO];
    [_upperTimeCount createText];
    //[_upperTimeCount setReferenceObjectPosition:_rangeSlider.upperKnobCenterInParent];
    //[_upperTimeCount setReferenceObjectFrame:_rangeSlider.upperKnobLayer.frame];
    
    [self.view addSubview:_rangeSlider];
    [self.view.layer insertSublayer:_lowerTimeCount atIndex:0];
    [self.view.layer addSublayer:_upperTimeCount];
    //[self updateLayout:nil];
    
    [_rangeSlider addTarget:self action:@selector(updateCountLabels:) forControlEvents:UIControlEventValueChanged];
    [_rangeSlider addTarget:self action:@selector(touchesOver:) forControlEvents:UIControlEventTouchUpInside];
    
    
    

}



-(void)setCustom:(BOOL)custom {
    
    _custom = custom;
    
    if (_custom) {
        [self setPreview:NO];
        _rangeSlider.lowerKnobLayer.enabled = YES;
        _rangeSlider.upperKnobLayer.enabled = YES;
        _rangeSlider.upperKnobLayer.hidden = NO;
        self.upperTimeCount.hidden = NO;
        [_rangeSlider redrawLayers];
    }
    

}

-(void)setPreview:(BOOL)preview {
    
    _preview = preview;
    
    if (_preview) {
        [self setCustom:NO];
        _rangeSlider.lowerKnobLayer.enabled = YES;
        _rangeSlider.upperKnobLayer.hidden = YES;
        self.upperTimeCount.hidden = YES;
        [_rangeSlider redrawLayers];
    }
   
}


-(void)updateCountLabels:(id)sender {
    
    NSLog(@"Slider value changed: (%.2f,%.2f)",
          _rangeSlider.lowerValue, _rangeSlider.upperValue);
    
    self.currentlyPanning = YES;
    
    [_lowerTimeCount setOpacity:1.0];
    [_upperTimeCount setOpacity:1.0];
    
    [_lowerTimeCount setReferenceObjectPosition:_rangeSlider.lowerKnobCenterInParent];
    [_lowerTimeCount setKnobTime:_rangeSlider.lowerValue];
    [_lowerTimeCount updateTextLayerString];
    
    [_upperTimeCount setReferenceObjectPosition:_rangeSlider.upperKnobCenterInParent];
    [_upperTimeCount setKnobTime:_rangeSlider.upperValue];
    [_upperTimeCount updateTextLayerString];
    
    if (_rangeSlider.lowerKnobLayer.highlighted || !_rangeSlider.upperKnobLayer.enabled) {
        [self.view.layer insertSublayer:_lowerTimeCount above:_upperTimeCount];
    } else if (_rangeSlider.upperKnobLayer.highlighted || !_rangeSlider.lowerKnobLayer.enabled) {
        [self.view.layer insertSublayer:_upperTimeCount above:_lowerTimeCount];
    } else {
        //do nothing
    }
    
    [_lowerTimeCount setNeedsDisplay];
    [_upperTimeCount setNeedsDisplay];
}

-(void)updateDuration {
    
    _lowerTimeCount.trackDuration = _rangeSlider.trackDuration;
    _upperTimeCount.trackDuration = _rangeSlider.trackDuration;
}

-(void)updateLabelPositionForSeek {
    
    [self updateCountLabels:self.rangeSlider];
}

-(void)showHideLabels {
    
    if (_lowerTimeCount.opacity == 1.0) {
        _lowerTimeCount.opacity = 0.0;
        _upperTimeCount.opacity = 0.0;
    } else {
        _lowerTimeCount.opacity = 1.0;
        _upperTimeCount.opacity = 1.0;
    }
    
}

-(void)showLabels {
    _lowerTimeCount.opacity = 1.0;
    _upperTimeCount.opacity = 1.0;
}

-(void)hideLabels {
    _lowerTimeCount.opacity = 0.0;
    _upperTimeCount.opacity = 0.0;
}




-(void)touchesOver:(id)sender {
    NSLog(@"%s", __func__);
    
    if (_currentlyPanning) {
        CABasicAnimation *animateToClear = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [animateToClear setFromValue:[NSNumber numberWithFloat:_lowerTimeCount.opacity]];
        [animateToClear setToValue:[NSNumber numberWithFloat:0.0]];
        [animateToClear setDuration:5.0];
        
        if (_rangeSlider.animateToClear) {
            [_lowerTimeCount addAnimation:animateToClear forKey:@"opacity"];
            [_lowerTimeCount setOpacity:0.0];
            
            [_upperTimeCount addAnimation:animateToClear forKey:@"opacity"];
            [_upperTimeCount setOpacity:0.0];
        }
        
        _currentlyPanning = NO;
    }
    
    }



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
