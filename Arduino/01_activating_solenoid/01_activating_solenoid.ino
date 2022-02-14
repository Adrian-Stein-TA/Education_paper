
// Code for the receiver
// This code helps you determine the delay time between the moment you push the bit to activate the solenoid and it actually gets activated
// It enables you to calibrate your gyroscope remotely too

#include <SPI.h>
#include "nRF24L01.h"
#include "RF24.h"

RF24 radio(9, 10); // make sure this corresponds to the pins you are using
const byte addresses[][32] = {"0xF0F0F0F0AA", "0xF0F0F0F066"};
char incomingByte = 0; // for incoming serial data
const char reset_byte[] = "Reset"; // reset bit

typedef struct {
  float time_ms, y_dot, z_ddot;
} mystruct_type_1;
mystruct_type_1 mystruct_1; // Declaration

unsigned int pin_Relay_5 = 5;
boolean bit_calibration = 0;

float start_time_ms = 0, time_ms_now = 0, time_ms_prev = 0, time_relative_ms = 0;

unsigned long percent = 0, percent_sup = 47;

void setup() {
  pinMode(pin_Relay_5, OUTPUT);
  Serial.begin(115200);
  radio.begin();
  radio.openWritingPipe(addresses[0]);
  radio.openReadingPipe(1, addresses[1]);
  radio.setDataRate( RF24_2MBPS );
  radio.setPALevel(RF24_PA_HIGH);

  radio.startListening(); // Listen to see if information received

  while ((incomingByte != '1' || incomingByte != '2') && bit_calibration == 0) {
    time_relative_ms = millis();
    while (millis() - time_relative_ms < 100 && radio.available()) {
      radio.read( &mystruct_1, sizeof(mystruct_1) );
      time_ms_prev = time_ms_now;
      time_ms_now = mystruct_1.time_ms;
      delay(5);
    }
    Serial.print(F("Press: 1 (Calibration)   or   2 (Start)  ||  sampling frequency: "));
    Serial.println(1000 / (time_ms_now - time_ms_prev));

    delay(400);
    if (incomingByte == '1') {
      Serial.println(F("---> Calibration chosen"));
      bit_calibration = function_calibration();
      if (bit_calibration == 1) {
        while (incomingByte != '2') {
          delay(500);
          time_relative_ms = millis();
          while (millis() - time_relative_ms < 100 && radio.available()) {
            radio.read( &mystruct_1, sizeof(mystruct_1) );
            time_ms_prev = time_ms_now;
            time_ms_now = mystruct_1.time_ms;
            delay(5);
          }
          Serial.print(F("Calibration successful, press: 2 (Start) ||  sampling frequency: "));
          Serial.println(1000 / (time_ms_now - time_ms_prev));
          incomingByte = Serial.read();
        }
      }
      else if (bit_calibration == 0) {
        Serial.println(F("Calibration wasn't successful, please try again"));
      }
    }
    else if (incomingByte == '2') {
      Serial.println(F("---> Start"));
      bit_calibration = 1;
    }
    incomingByte = Serial.read();
  }

  start_time_ms = millis();

  // Start with deactivated solenoids
  digitalWrite(pin_Relay_5, LOW);

  while (millis() - start_time_ms < 4700) {
    percent = (millis() - start_time_ms) / percent_sup;
    Serial.print(percent);
    Serial.println(F("% (Press 3 to activate the solenoids after the countdown)"));
    delay(200);
  }
}

void loop() {
  radio.startListening(); // Listen to see if information received
  while (radio.available())
  {
    radio.read( &mystruct_1, sizeof(mystruct_1) );
    delay(5);
    if (mystruct_1.y_dot != 0) {
      Serial.print(mystruct_1.time_ms); Serial.print(F(", "));
      Serial.print(mystruct_1.z_ddot, 4);  Serial.println(F(", "));

      if (Serial.read() == '3') {
        digitalWrite(pin_Relay_5, HIGH);
        Serial.println(F("############## Now the button was pushed ##############"));
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////
/// Function for Calibration ///////////////////////////////////////////////////////

boolean function_calibration() {
  const char reset_byte[] = "Reset"; // reset bit

  typedef struct {
    float time_ms, y_dot, z_ddot;
  } mystruct_type_1;
  mystruct_type_1 mystruct_1; // Declaration

  float time_relative_ms = 0, time_ms_prev = 0, time_ms_now = 1000;
  float data_freq_Hz = 0;
  boolean bit_calibration;

  Serial.println(F("---> Calibration initiated (wait 10 seconds) ..."));

  radio.stopListening();
  delay(50);
  radio.write(&reset_byte, sizeof(reset_byte));
  delay(8000); // wait until calibration is done on payload (wait a bit longer than calibration time)

  radio.startListening();
  radio.read( &mystruct_1, sizeof(mystruct_1) );
  delay(50);

  time_relative_ms = millis();
  while (millis() - time_relative_ms < 1000 && radio.available()) {
    radio.read( &mystruct_1, sizeof(mystruct_1) );
    time_ms_prev = time_ms_now;
    time_ms_now = mystruct_1.time_ms;
    delay(5);
  }

  if (time_ms_now - time_ms_prev < 20) {
    bit_calibration = 1;
  }
  else {
    bit_calibration = 0;
  }

  return bit_calibration;
}
