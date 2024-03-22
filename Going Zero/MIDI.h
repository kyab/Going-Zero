//
//  MIDI.h
//  Going Zero
//
//  Created by koji on 2024/03/23.
//  Copyright © 2024 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MIDIDelegate <NSObject>
@optional
-(void)MIDIDelegateNoteOn:(Byte)note vel:(Byte)vel chan:(Byte)chan;
-(void)MIDIDelegateNoteOff:(Byte)note vel:(Byte)vel chan:(Byte)chan;
-(void)MIDIDelegateCC:(Byte)cc data:(Byte)data chan:(Byte)chan;
@end

@interface MIDI : NSObject{
    MIDIClientRef _clientRef;
    MIDIPortRef _inputPortRef;
    id<MIDIDelegate> _delegate;
}

-(void)setup;
-(void)setDelegate:(id<MIDIDelegate>)delegate;
-(void)onMIDINoteOn:(Byte)note vel:(Byte)vel chan:(Byte)chan;
-(void)onMIDINoteOff:(Byte)note vel:(Byte)vel chan:(Byte)chan;
-(void)onMIDICC:(Byte)cc data:(Byte)data chan:(Byte)chan;

@end

NS_ASSUME_NONNULL_END
