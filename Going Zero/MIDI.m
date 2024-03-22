//
//  MIDI.m
//  Going Zero
//
//  Created by koji on 2024/03/23.
//  Copyright © 2024 kyab. All rights reserved.
//

#import "MIDI.h"

@implementation MIDI


void MIDIInputProc(const MIDIPacketList *pktList, void *readProcRefCon, void *srcConnRefCon)
{
    MIDIPacket *packet = (MIDIPacket *)&(pktList->packet[0]);
    UInt32 packetCount = pktList->numPackets;
 
    MIDI *midi = (__bridge MIDI *)readProcRefCon;
    
    
    for (NSInteger i = 0; i < packetCount; i++) {
        
        Byte mes = packet->data[0] & 0xF0;
        Byte ch = packet->data[0] & 0x0F;
        
        if ((mes == 0x90) && (packet->data[2] != 0)) {
            [midi onMIDINoteOn:packet->data[1] vel:packet->data[2] chan:ch];
        } else if (mes == 0x80 || mes == 0x90) {
            [midi onMIDINoteOff:packet->data[1] vel:packet->data[2] chan:ch];
        } else if (mes == 0xB0) {
            [midi onMIDICC:packet->data[1] data:packet->data[2] chan:ch];
        } else {
        }
        packet = MIDIPacketNext(packet);
    }
}

-(void)setDelegate:(id<MIDIDelegate>)delegate{
    _delegate = delegate;
}

-(void)setup{
    OSStatus err;
    CFStringRef strEndPointRef = NULL;
    
    //MIDIClient creation
    NSString *clientName = @"inputClient";
    err = MIDIClientCreate((__bridge CFStringRef)clientName, NULL, NULL, &_clientRef);
    if (err != noErr){
        NSLog(@"MIDIClientCreate err = %d", err);
        return;
    }
    
    //MIDIPort Creation
    NSString *inputPortName = @"inputPort";
    err = MIDIInputPortCreate(_clientRef, (__bridge CFStringRef)inputPortName,
                              MIDIInputProc, (__bridge void *)self, &_inputPortRef);
    if (err != noErr){
        NSLog(@"MIDInputPortCreate err = %d", err);
        return;
    }
    
    
    ItemCount sourceCount = MIDIGetNumberOfSources();
    
    for(ItemCount i = 0 ; i < sourceCount; i++){
        
        MIDIEndpointRef endPointRef = MIDIGetSource(i);
        
        //get name for this MIDI endpoint.
        err = MIDIObjectGetStringProperty(endPointRef,
                                          kMIDIPropertyName, &strEndPointRef);
        if (err != noErr){
            NSLog(@"err = %d", err);
            return;
        }else{
        }
        
        //connect
        err = MIDIPortConnectSource(_inputPortRef, endPointRef, NULL);
        if (err != noErr){
            NSLog(@"MIDIPortConnectSource err for %@ = %d",strEndPointRef, err);
            return;
        }
    }
}


-(void)onMIDINoteOn:(Byte)note vel:(Byte)vel chan:(Byte)chan{
    if ([_delegate respondsToSelector:@selector(MIDIDelegateNoteOn:vel:chan:)]){
        [_delegate MIDIDelegateNoteOn:note vel:vel chan:chan];
    }
}

-(void)onMIDINoteOff:(Byte)note vel:(Byte)vel chan:(Byte)chan{
    if ([_delegate respondsToSelector:@selector(MIDIDelegateNoteOff:vel:chan:)]){
        [_delegate MIDIDelegateNoteOff:note vel:vel chan:chan];
    }
}

-(void)onMIDICC:(Byte)cc data:(Byte)data chan:(Byte)chan{
    if ([_delegate respondsToSelector:@selector(MIDIDelegateCC:data:chan:)]){
        [_delegate MIDIDelegateCC:cc data:data chan:chan];
    }
}



@end
