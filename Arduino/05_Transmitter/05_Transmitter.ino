
// Code for the transmitter

#include "Wire.h"
#include <MPU6050_light.h>

//////////////////////////////////
#include <SPI.h>
#include "nRF24L01.h"
#include "RF24.h"
//////////////////////////////////
MPU6050 mpu(Wire);
//////////////////////////////////
RF24 radio(9, 10); // make sure this corresponds to the pins you are using
const byte addresses[][32] = {"0xF0F0F0F0AA", "0xF0F0F0F066"};
char reset_byte[32] = {0};

int counter_offsets = 0;
float calibration_time_ms = 0;

typedef struct {
  float time_ms, y_dot, z_ddot;
} mystruct_type_1;
mystruct_type_1 mystruct_1; // Declaration



void setup() {
  Serial.begin(115200);
  Wire.begin();

  byte status = mpu.begin();
  Serial.print(F("MPU6050 status: "));
  Serial.println(status);
  while (status != 0) { } // stop everything if could not connect to MPU6050

  Serial.println(F("Calculating offsets, do not move MPU6050"));
  delay(5000);
  mpu.calcOffsets(true, true); // gyro and accelero

  Serial.println("Done!\n");
  ///////////////////////////////////////

  radio.begin();
  radio.openWritingPipe(addresses[1]);
  radio.openReadingPipe(1, addresses[0]);
  radio.setDataRate(RF24_2MBPS);
  radio.setPALevel(RF24_PA_HIGH);

}

void loop() {
  mpu.update();
  
  mystruct_1.time_ms = millis();
  mystruct_1.y_dot = mpu.getGyroY();
  mystruct_1.z_ddot = mpu.getAccZ();

  
  radio.stopListening();
  radio.write( &mystruct_1, sizeof(mystruct_1) );
  delay(5);

  if (calibration_time_ms - millis() < 0){
  
  radio.startListening(); // Listen to see if information received
  delay(200);
  
      if (radio.available())  {

      Wire.begin();

      byte status = mpu.begin();
      Serial.print(F("MPU6050 status: "));
      Serial.println(status);
      while (status != 0) { } // stop everything if could not connect to MPU6050

      radio.read(&reset_byte, sizeof(reset_byte));
      Serial.println(reset_byte);
      Serial.println(F("Calculating offsets, do not move MPU6050"));

      delay(5000);
     
      mpu.calcOffsets(true, true); // gyro and accelero 
      
      calibration_time_ms = millis() + 100000;   
    }
  }
}
