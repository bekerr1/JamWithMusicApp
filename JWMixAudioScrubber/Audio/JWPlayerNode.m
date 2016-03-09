//
//  JWPlayerNode.m
//  JamWIthT
//
//  Created by brendan kerr on 10/18/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWPlayerNode.h"

@interface JWPlayerNode () {
    float _startInset;
    float _endInset;
}
@end

@implementation JWPlayerNode

-(CGFloat)progressOfAudioFile {
    return [self progressOfAudioFile:_audioFile];
}

-(CGFloat)durationInSecondsOfAudioFile {
    return [self durationInSecondsOfAudioFile:_audioFile];
}

-(CGFloat)remainingDurationInSecondsOfAudioFile {
    return [self remainingDurationInSecondsOfAudioFile:_audioFile];
}

-(CGFloat)currentPositionInSecondsOfAudioFile {
    return [self currentPositionInSecondsOfAudioFile:_audioFile];
}

-(NSString*)processingFormatStrOfAudioFile {
    return [self processingFormatStrOfAudioFile:_audioFile];
}


#pragma mark - audiofile Methods

-(NSString*)processingFormatStrOfAudioFile:(AVAudioFile*)audioFile
{
    NSString *result = nil;
    if (audioFile) {
        AVAudioFormat *fileFormat = [audioFile fileFormat];
        NSString *fileFormatIdStr;
        AVAudioFormat *processingFormat = [audioFile processingFormat];
        NSString *processingFormatIdStr;
        
        {
            unsigned char bytes[4];
            unsigned long n = fileFormat.streamDescription->mFormatID;
            bytes[0] = (n >> 24) & 0xFF;
            bytes[1] = (n >> 16) & 0xFF;
            bytes[2] = (n >> 8) & 0xFF;
            bytes[3] = n & 0xFF;
            fileFormatIdStr = [[NSString alloc] initWithBytes:bytes  length:4 encoding:NSASCIIStringEncoding];
        }
        
        {
            unsigned char bytes[4];
            unsigned long n = processingFormat.streamDescription->mFormatID;
            bytes[0] = (n >> 24) & 0xFF;
            bytes[1] = (n >> 16) & 0xFF;
            bytes[2] = (n >> 8) & 0xFF;
            bytes[3] = n & 0xFF;
            processingFormatIdStr = [[NSString alloc] initWithBytes:bytes  length:4 encoding:NSASCIIStringEncoding];
        }
        
        NSLog(@"%s FileFormat_______ : %@",__func__,[NSString stringWithFormat:@"%@ %d ch %.0f %u %@",
                                             fileFormatIdStr,
                                             (unsigned int)fileFormat.streamDescription->mChannelsPerFrame,
                                             fileFormat.streamDescription->mSampleRate,
                                             (unsigned int)fileFormat.streamDescription->mBitsPerChannel,
                                             fileFormat.interleaved ? @"i" : @"ni"
                                             ]);
        NSLog(@"%s ProcessingFormat_ : %@",__func__,[NSString stringWithFormat:@"%@ %u ch %.0f %u %@",
                                                   processingFormatIdStr,
                                                   (unsigned int)processingFormat.streamDescription->mChannelsPerFrame,
                                                   processingFormat.streamDescription->mSampleRate,
                                                   (unsigned int)processingFormat.streamDescription->mBitsPerChannel,
                                                   processingFormat.interleaved ? @"i" : @"ni"
                                                   ]);
        
        result = [NSString stringWithFormat:@"%@/%@ %u ch(%.1f)%u %@",
                  fileFormatIdStr,processingFormatIdStr,
                  (unsigned int)processingFormat.streamDescription->mChannelsPerFrame,
                  processingFormat.streamDescription->mSampleRate/1000.0,
                  (unsigned int)processingFormat.streamDescription->mBitsPerChannel,
                  processingFormat.interleaved ? @"i" : @"ni"
                  ];
        
        //        format.interleaved ? @"inter" : @"non-interleaved"
        //        format.standard ? @"Fl32 std" : @"std NO  ",
        
    }

    NSLog(@"%s %@",__func__,result);
    
    return result;
}



-(CGFloat)progressOfAudioFile:(AVAudioFile*)audioFile
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [self lastRenderTime];
        AVAudioTime *playerTime = [self playerTimeForNodeTime:audioTime];
        
        if (playerTime==nil) {
            NSLog(@"%s NO PLAYER TIME  playing %@",__func__,@([self isPlaying]));
            result = 1.00f;
        } else {
            double fileLenInSecs = fileLength / [playerTime sampleRate];

            fileLenInSecs -= _startInset;
            fileLenInSecs -= _endInset;
            fileLenInSecs += _delayStart;
            
            double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
            currentPosInSecs += _startPlayingInset;
            
            if (currentPosInSecs > fileLenInSecs ) {
                if (/* DISABLES CODE */ (YES)) {
                    double normalizedProgress = currentPosInSecs/fileLenInSecs - floorf(currentPosInSecs/fileLenInSecs);
                    result = normalizedProgress;
                } else {
                    result = 1.0;
                }
                
            } else {
                result = currentPosInSecs/fileLenInSecs;
            
            }
        }
    }
//    NSLog(@"%s %.3f",__func__,result);
    return result;
}


-(CGFloat)durationInSecondsOfAudioFile:(AVAudioFile*)audioFile
{
    CGFloat result = 0.000f;
    
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [self lastRenderTime];
        AVAudioTime *playerTime = [self playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = 0.0f;
        if (playerTime) {
            fileLenInSecs = fileLength / [playerTime sampleRate];
        } else {
            Float64 mSampleRate = audioFile.processingFormat.streamDescription->mSampleRate;
            Float64 duration =  (1.0 / mSampleRate) * audioFile.processingFormat.streamDescription->mFramesPerPacket;
            fileLenInSecs = duration * fileLength;
        }
        
        fileLenInSecs -= _startInset;
        fileLenInSecs -= _endInset;
        fileLenInSecs += _delayStart;
        fileLenInSecs -= _startPlayingInset;

        result = (CGFloat)fileLenInSecs;
    }
    //    NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(CGFloat)remainingDurationInSecondsOfAudioFile:(AVAudioFile*)audioFile
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioTime *audioTime = [self lastRenderTime];
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *playerTime = [self playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = fileLength / [playerTime sampleRate];

        fileLenInSecs -= _startInset;
        fileLenInSecs -= _endInset;
        fileLenInSecs += _delayStart;

        double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];

        currentPosInSecs += _startPlayingInset;

        if (currentPosInSecs >= fileLenInSecs ) {
            if (/* DISABLES CODE */ (YES)) {
                double normalizedProgress = currentPosInSecs/fileLenInSecs - floorf(currentPosInSecs/fileLenInSecs);
                result = fileLenInSecs - (normalizedProgress * fileLenInSecs);
            } else {
                result = 0.0;
            }
        } else {
            result = (fileLenInSecs - currentPosInSecs);
        }
    }
//        NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(CGFloat)currentPositionInSecondsOfAudioFile:(AVAudioFile*)audioFile
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [self lastRenderTime];
        AVAudioTime *playerTime = [self playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = fileLength / [playerTime sampleRate];
        
        fileLenInSecs -= _startInset;
        fileLenInSecs -= _endInset;
        fileLenInSecs += _delayStart;

        double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];

        currentPosInSecs += _startPlayingInset;

        if (currentPosInSecs > fileLenInSecs ) {
            if (/* DISABLES CODE */ (YES)) {
                // Looops player time keeps playing past ened figure out where in Loop
                double normalizedProgress = currentPosInSecs/fileLenInSecs - floorf(currentPosInSecs/fileLenInSecs);
                result = fileLenInSecs / (normalizedProgress * fileLenInSecs);
            } else {
                result = fileLenInSecs;
            }
        } else {
            result = currentPosInSecs;
        }
    }
//    NSLog(@"%s %.3f",__func__,result);
    return result;
}

#pragma mark -

-(void)setFileReference:(NSDictionary *)fileReference {

    if (fileReference) {
        id startInsetValue = fileReference[@"startinset"];
        float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        id endInsetValue = fileReference[@"endinset"];
        float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
        
        _startInset = startInset;
        _endInset = endInset;
    } else {
        _startInset = 0.0;
        _endInset = 0.0;
    }
    
//    result =
//    [[JWPlayerFileInfo alloc] initWithCurrentPosition:0.0 duration:durationSeconds
//                                        startPosition:startTime
//                                           startInset:startInset
//                                             endInset:endInset];
    
}


@end




/*
 
 mFormatID
 An identifier specifying the general audio data format in the stream. See “Audio Data Format Identifiers”. This value must be nonzero.
 
 kAudioFormatLinearPCM               = 'lpcm',
 kAudioFormatAC3                     = 'ac-3',
 kAudioFormat60958AC3                = 'cac3',
 kAudioFormatAppleIMA4               = 'ima4',
 kAudioFormatMPEG4AAC                = 'aac ',
 kAudioFormatMPEG4CELP               = 'celp',
 kAudioFormatMPEG4HVXC               = 'hvxc',
 kAudioFormatMPEG4TwinVQ             = 'twvq',
 kAudioFormatMACE3                   = 'MAC3',
 kAudioFormatMACE6                   = 'MAC6',
 kAudioFormatULaw                    = 'ulaw',
 kAudioFormatALaw                    = 'alaw',
 kAudioFormatQDesign                 = 'QDMC',
 kAudioFormatQDesign2                = 'QDM2',
 kAudioFormatQUALCOMM                = 'Qclp',
 kAudioFormatMPEGLayer1              = '.mp1',
 kAudioFormatMPEGLayer2              = '.mp2',
 kAudioFormatMPEGLayer3              = '.mp3',
 kAudioFormatTimeCode                = 'time',
 kAudioFormatMIDIStream              = 'midi',
 kAudioFormatParameterValueStream    = 'apvs',
 kAudioFormatAppleLossless           = 'alac'
 kAudioFormatMPEG4AAC_HE             = 'aach',
 kAudioFormatMPEG4AAC_LD             = 'aacl',
 kAudioFormatMPEG4AAC_ELD            = 'aace',
 kAudioFormatMPEG4AAC_ELD_SBR        = 'aacf',
 kAudioFormatMPEG4AAC_HE_V2          = 'aacp',
 kAudioFormatMPEG4AAC_Spatial        = 'aacs',
 kAudioFormatAMR                     = 'samr',
 kAudioFormatAudible                 = 'AUDB',
 kAudioFormatiLBC                    = 'ilbc',
 kAudioFormatDVIIntelIMA             = 0x6D730011,
 kAudioFormatMicrosoftGSM            = 0x6D730031,
 kAudioFormatAES3                    = 'aes3'
 
 struct AudioStreamBasicDescription { 
 Float64 mSampleRate; UInt32 mFormatID; UInt32 mFormatFlags; 
 UInt32 mBytesPerPacket; UInt32 mFramesPerPacket; 
 UInt32 mBytesPerFrame; UInt32 mChannelsPerFrame; UInt32 mBitsPerChannel; 
 UInt32 mReserved; }; 
 typedef struct AudioStreamBasicDescription AudioStreamBasicDescription;
 
 Fields
 mSampleRate
 The number of frames per second of the data in the stream, when the stream is played at normal speed. For compressed formats, this field indicates the number of frames per second of equivalent decompressed data.
 
 The mSampleRate field must be nonzero, except when this structure is used in a listing of supported formats (see “kAudioStreamAnyRate”).
 
 mFormatID
 An identifier specifying the general audio data format in the stream. See “Audio Data Format Identifiers”. This value must be nonzero.
 
 mFormatFlags
 Format-specific flags to specify details of the format. Set to 0 to indicate no format flags. See “Audio Data Format Identifiers” for the flags that apply to each format.
 
 mBytesPerPacket
 The number of bytes in a packet of audio data. To indicate variable packet size, set this field to 0. For a format that uses variable packet size, specify the size of each packet using an AudioStreamPacketDescription structure.
 
 mFramesPerPacket
 The number of frames in a packet of audio data. For uncompressed audio, the value is 1. For variable bit-rate formats, the value is a larger fixed number, such as 1024 for AAC. For formats with a variable number of frames per packet, such as Ogg Vorbis, set this field to 0.
 
 mBytesPerFrame
 The number of bytes from the start of one frame to the start of the next frame in an audio buffer. Set this field to 0 for compressed formats.
 
 For an audio buffer containing interleaved data for n channels, with each sample of type AudioSampleType, calculate the value for this field as follows:
 
 mBytesPerFrame = n * sizeof (AudioSampleType);
 For an audio buffer containing noninterleaved (monophonic) data, also using AudioSampleType samples, calculate the value for this field as follows:
 
 mBytesPerFrame = sizeof (AudioSampleType);
 mChannelsPerFrame
 The number of channels in each frame of audio data. This value must be nonzero.
 
 mBitsPerChannel
 The number of bits for one audio sample. For example, for linear PCM audio using the kAudioFormatFlagsCanonical format flags, calculate the value for this field as follows:
 
 mBitsPerChannel = 8 * sizeof (AudioSampleType);
 Set this field to 0 for compressed formats.
 
 mReserved
 Pads the structure out to force an even 8-byte alignment. Must be set to 0.
 
 -------------------------------
 To determine the duration represented by one packet, use the mSampleRate field with the mFramesPerPacket field, as follows:
 
 duration = (1 / mSampleRate) * mFramesPerPacket

 In Core Audio, the following definitions apply:
 An audio stream is a continuous series of data that represents a sound, such as a song.
 A channel is a discrete track of monophonic audio. A monophonic stream has one channel; a stereo stream has two channels.
 A sample is single numerical value for a single audio channel in an audio stream.
 A frame is a collection of time-coincident samples. For instance, a linear PCM stereo sound file has two samples per frame, one for the left channel and one for the right channel.
 
 A packet is a collection of one or more contiguous frames. A packet defines the smallest meaningful set of frames for a given audio data format, and is the smallest data unit for which time can be measured. In linear PCM audio, a packet holds a single frame. In compressed formats, it typically holds more; in some formats, the number of frames per packet varies.
 
 The sample rate for a stream is the number of frames per second of uncompressed (or, for compressed formats, the equivalent in decompressed) audio.
 */



