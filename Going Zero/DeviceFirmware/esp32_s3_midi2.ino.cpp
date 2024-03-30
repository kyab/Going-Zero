/*********************************************************************
 Adafruit invests time and resources providing this open source code,
 please support Adafruit and open-source hardware by purchasing
 products from Adafruit!

 MIT license, check LICENSE for more information
 Copyright (c) 2019 Ha Thach for Adafruit Industries
 All text above, and the splash screen below must be included in
 any redistribution
*********************************************************************/

/* This sketch is enumerated as USB MIDI device.
 * Following library is required
 * - MIDI Library by Forty Seven Effects
 *   https://github.com/FortySevenEffects/arduino_midi_library
 */

#include <Arduino.h>
#include <Adafruit_TinyUSB.h>
#include <MIDI.h>

// USB MIDI object
Adafruit_USBD_MIDI usb_midi(1);

// Create a new instance of the Arduino MIDI Library,
// and attach usb_midi as the transport.
MIDI_CREATE_INSTANCE(Adafruit_USBD_MIDI, usb_midi, MIDI);

// Variable that holds the current position in the sequence.
uint32_t position = 0;

// Store example melody as an array of note values
byte note_sequence[] = {
  74,78,81,86,90,93,98,102,57,61,66,69,73,78,81,85,88,92,97,100,97,92,88,85,81,78,
  74,69,66,62,57,62,66,69,74,78,81,86,90,93,97,102,97,93,90,85,81,78,73,68,64,61,
  56,61,64,68,74,78,81,86,90,93,98,102
};

void setup()
{
#if defined(ARDUINO_ARCH_MBED) && defined(ARDUINO_ARCH_RP2040)
  // Manual begin() is required on core without built-in support for TinyUSB such as mbed rp2040
  TinyUSB_Device_Init(0);
#endif

  pinMode(46, OUTPUT);

  pinMode(A1, ANALOG);
  
  usb_midi.setStringDescriptor("TinyUSB MIDI");
  usb_midi.setCables(1);
  usb_midi.setCableName(1, "Cable1");

  // Initialize MIDI, and listen to all MIDI channels
  // This will also call usb_midi's begin()
  MIDI.begin(MIDI_CHANNEL_OMNI);

  // Attach the handleNoteOn function to the MIDI Library. It will
  // be called whenever the Bluefruit receives MIDI Note On messages.
  MIDI.setHandleNoteOn(handleNoteOn);

  // Do the same for MIDI Note Off messages.
  MIDI.setHandleNoteOff(handleNoteOff);

  Serial.begin(115200);

  // wait until device mounted
  while( !TinyUSBDevice.mounted() ) delay(1);
}

void loop()
{
  static uint32_t start_ms2 = millis();
  static bool is_note_on = false;
  static int prev_value = 0;
  if (millis() - start_ms2 > 10){
    start_ms2 = millis();
    int val = analogReadMilliVolts(A1);
    int value = (float)val/3129.0f * 127;
    if (value > 0){
      // Serial.println(val);
      if (!is_note_on){
        if (value <= 1){
          //filter out noise
        }else{
          MIDI.sendNoteOn(77, value, 1);
          prev_value = value;
          is_note_on = true;
        }
      }else{
        if (value != prev_value ){
          MIDI.sendPolyPressure(77, value, 1);
          prev_value = value;
        }
      }
    }else{
      if (is_note_on){
        MIDI.sendNoteOff(77, 0, 1);
        prev_value = 0;
        is_note_on = false;
      }
    }
  }

  static bool toggle = false;

  static uint32_t start_ms = 0;
  if ( millis() - start_ms > 266 )
  {
    start_ms += 266;
    
    // Setup variables for the current and previous
    // positions in the note sequence.
    int previous = position - 1;
  
    // If we currently are at position 0, set the
    // previous position to the last note in the sequence.
    if (previous < 0) {
      previous = sizeof(note_sequence) - 1;
    }
  
    // Send Note On for current position at full velocity (127) on channel 1.
    // MIDI.sendNoteOn(note_sequence[position], 127, 1);
  
    // Send Note Off for previous note.
    // MIDI.sendNoteOff(note_sequence[previous], 0, 1);
  
    // Increment position
    position++;
  
    // If we are at the end of the sequence, start over.
    if (position >= sizeof(note_sequence)) {
      position = 0;
    }
    // Serial.println("serial");
    if (toggle){
      digitalWrite(46, LOW);
      toggle = false;
    }else{
      digitalWrite(46, HIGH);
      toggle = true;
    }
  }

  // read any new MIDI messages
  MIDI.read();
}

void handleNoteOn(byte channel, byte pitch, byte velocity)
{
  // Log when a note is pressed.
  Serial.print("Note on: channel = ");
  Serial.print(channel);

  Serial.print(" pitch = ");
  Serial.print(pitch);

  Serial.print(" velocity = ");
  Serial.println(velocity);
}

void handleNoteOff(byte channel, byte pitch, byte velocity)
{
  // Log when a note is released.
  Serial.print("Note off: channel = ");
  Serial.print(channel);

  Serial.print(" pitch = ");
  Serial.print(pitch);

  Serial.print(" velocity = ");
  Serial.println(velocity);
}


