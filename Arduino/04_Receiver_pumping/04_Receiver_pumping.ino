
// Code for the receiver
// This covers the pumping part
// You can calibrate the gyrscope remotely too

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

unsigned int pin_Relay_5 = 5, counter_stable = 0;
boolean bit_switch = 1, bit_start = 1, bit_calibration = 0;

float time_n1_ms = 0, time_n_ms = 0, start_time_ms = 0, time_relative_ms = 0;
float vel_filtered_n = 0, vel_raw_n = 0, vel_filtered_n1 = 0;

float difference_vel = 0;
float time_bound_s[2] = {0, 40};
float bound[2] = {10, 15};

unsigned long switch_time_s_n1 = 0, switch_time_s_n = 0;

float bound_interp;
unsigned long percent = 0, percent_sup = 47;

void setup() {
  pinMode(pin_Relay_5, OUTPUT);

  Serial.begin(115200);
  radio.begin();
  radio.openWritingPipe(addresses[0]);
  radio.openReadingPipe(1, addresses[1]);
  radio.setDataRate( RF24_2MBPS );
  radio.setPALevel(RF24_PA_HIGH);

  bound_interp = bound[0];
  radio.startListening(); // Listen to see if information received

  while ((incomingByte != '1' || incomingByte != '2') && bit_calibration == 0) {
    time_relative_ms = millis();
    while (millis() - time_relative_ms < 100 && radio.available()) {
      radio.read( &mystruct_1, sizeof(mystruct_1) );
      time_n1_ms = time_n_ms;
      time_n_ms = mystruct_1.time_ms;
      delay(5);
    }
    Serial.print(F("Press: 1 (Calibration)   or   2 (Start)  ||  sampling frequency: "));
    Serial.println(1000 / (time_n_ms - time_n1_ms));

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
            time_n1_ms = time_n_ms;
            time_n_ms = mystruct_1.time_ms;
            delay(5);
          }
          Serial.print(F("Calibration successful, press: 2 (Start) ||  sampling frequency: "));
          Serial.println(1000 / (time_n_ms - time_n1_ms));
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

  // Start with deactivated
  digitalWrite(pin_Relay_5, LOW);

  radio.read( &mystruct_1, sizeof(mystruct_1) );

  Serial.println(F("Bring it to -30° ... "));

  while (counter_stable < 100) {
    if ( radio.available()) {
      radio.read( &mystruct_1, sizeof(mystruct_1) );
      delay(5);
      if (mystruct_1.z_ddot > 0.82 && mystruct_1.z_ddot < 0.92) {
        counter_stable = counter_stable + 1;
      }
      else {
        counter_stable = 0;
      }
    }
  }
  Serial.println(F(" ---> -30° are confirmed"));
  Serial.println(F(" ---> Hold it"));
  start_time_ms = millis();

  while (millis() - start_time_ms < 4700) {
    percent = (millis() - start_time_ms) / percent_sup;
    Serial.print(percent);
    Serial.println("%");
    delay(200);
  }

  Serial.println(F("!!!!!!!!!!!!!!!!!!!!!!!!!!!"));
  Serial.println(F("!!!!!!!! Let it go !!!!!!!!"));
  Serial.println(F("!!!!!!!!!!!!!!!!!!!!!!!!!!!"));
  delay(200);
  start_time_ms = millis(); // Reset start time

  radio.startListening(); // Listen to see if information received
  radio.read( &mystruct_1, sizeof(mystruct_1) );
  switch_time_s_n1 = millis() - 1648.5 / 2;
  switch_time_s_n = millis();
  time_n1_ms = 0;
  time_n_ms = 0;
}

void loop() {
  radio.startListening(); // Listen to see if information received
  while (radio.available())
  {
    radio.read( &mystruct_1, sizeof(mystruct_1) );
    delay(5);

    if (mystruct_1.y_dot != 0) {

      // Getting current time and velocity
      time_n_ms = mystruct_1.time_ms;
      vel_raw_n = mystruct_1.y_dot;

      // Apply Low-Pass filter to the velocity
      vel_filtered_n = 0.7627 * vel_filtered_n1 + 0.2373 * vel_raw_n;

      // Predicting when the velocity will be zero
      difference_vel = (vel_filtered_n - vel_filtered_n1) / (time_n_ms - time_n1_ms) * 0.09 + vel_filtered_n1;

      // If velocity is within the bound of -50 < alpha < 50 [deg/s] ---> activate once
      if (difference_vel < bound_interp && difference_vel > -bound_interp && bit_switch == 0 && (millis() > switch_time_s_n + 700)) {
        digitalWrite(pin_Relay_5, LOW);
        bit_switch = 1;
        switch_time_s_n1 = switch_time_s_n;
        switch_time_s_n = millis();

        // security gate that is doesn't switch too fast (cannot be faster than 350ms for our setup)
        if (switch_time_s_n - switch_time_s_n1 < 350) {
          switch_time_s_n1 = millis() - 350;
        }
      }

      // after 1/4 of time period in contracted mode minus dead time of releasing (100ms)
      if (millis() > (switch_time_s_n + (switch_time_s_n - switch_time_s_n1) / 2 - 100) && bit_switch == 1) {
        digitalWrite(pin_Relay_5, HIGH);
        bit_switch = 0;
      }

      Serial.print(time_n_ms);  Serial.print(F(", "));
      Serial.print(vel_filtered_n); Serial.println(F(", "));

      time_n1_ms = time_n_ms;
      vel_filtered_n1 = vel_filtered_n;

      // interpolate the boundary for 0-velocity detection and get rid of 5s from the countdown
      bound_interp = (bound[1] - bound[0]) / (time_bound_s[1] - time_bound_s[0]) * ((millis() - start_time_ms) / 1000) + bound[0];

      // keep the minimum
      if (bound_interp > bound[1]) {
        bound_interp = bound[1];
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
