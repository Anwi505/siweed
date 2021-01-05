Serial port1;    //arduino mega
Serial port2;    //arduino Due
boolean megaConnected, dueConnected;
void initializeSerial() {
  ///////////initialize Serial

  printArray(Serial.list()); 
  for (int i = 0; i < Serial.list().length; i++) {
    if (!megaConnected) {
      try {
        port1 = new Serial(this, Serial.list()[i], 250000); // all communication with Megas
        megaConnected = true;
      }
      catch(Exception e) {
        megaConnected = false;
      }
      if (megaConnected) {
        delay(2000);
        readMegaSerial();    //reads serial buffer and sets bool true if recieving normal results
        if (megaUnitTests[0]) {
          //correct board found
        } else {
          megaConnected = false;
        }
      }
    }
    if (!dueConnected) {
      try {
        port2 = new Serial(this, Serial.list()[i], 250000); // all communication with Due
        dueConnected = true;
      }
      catch(Exception e) {
        dueConnected = false;
      }
      if (dueConnected) {
        delay(2000);
        readDueSerial();    //reads serial buffer and sets bool true if recieving normal results
        if (dueUnitTests[0]) {
          //correct board found
        } else {
          dueConnected = false;
        }
      }
    }
  }
  /*
  try {
   port1 = new Serial(this, Serial.list()[1], 250000); // all communication with Megas
   megaConnected = true;
   }
   catch(Exception e) {
   megaConnected = false;
   }
   try {
   port2 = new Serial(this, Serial.list()[2], 250000); // all communication with Due
   dueConnected = true;
   }
   catch(Exception e) {
   dueConnected = false;
   }
   delay(2000);
   */
  //initialize the modes on the arduinos:
  print("modes");

  if (megaConnected) {
    port1.write('!');
    sendFloat(0, port1);    //jog mode
    port1.write('j');
    sendFloat(0, port1);    //at position 0
  }
  if (dueConnected) {
    port2.write('!');
    sendFloat(-1, port2);    //off
  }
}
void sendFloat(float f, Serial port)
{
  /* 
   For mega:
  /* '!' indicates mode switch, next int is mode
   j indicates jog position
   a indicates incoming amplitude
   f indicates incoming frequency
   s :sigH
   p :peakF
   g :gamma
   
   For Due:
   '!' indicates mode switch, next int is mode
   t indicates torque command
   k indicates kp -p was taken
   d indicates kd
   s :sigH
   p :peakF
   g :gamma
   
   EDIT: numbers are now in this format:  p1234>  has a scalar of 100, so no decimal, and no start char
   */
  byte[] byteArray = floatToByteArray(f);

  port.write(byteArray);
}
void readMegaSerial() {
  /*
  mega:
   1:probe 1
   2:probe 2
   p:position
   d:other data for debugging
   */
  while (megaConnected && port1.available() > 0) {    //recieves until buffer is empty. Since it runs 30 times a second, the arduino will send many samples per execution.
    switch(port1.readChar()) {
    case '1':
      probe1 = readFloat(port1);
      if (waveElClicked == true) {
        waveChart.push("waveElevation", probe1);
      }
      break;
    case '2':
      probe2 = readFloat(port1);
      break;
    case 'p':
      waveMakerPos = readFloat(port1);
      if (wavePosClicked == true) {
        waveChart.push("waveMakerPosition", waveMakerPos);
      }
      break;
    case 'd':
      megaUnitTests[0] = true;      //for unit testing;
      debugData = readFloat(port1);
      waveChart.push("debug", debugData);
      if (waveMaker.mode == 3||waveMaker.mode == 2) fftList.add(debugData);      //adds to the tail if in the right mode
      if (fftList.size() > queueSize)
      {
        fftList.remove();          //removes from the head
      }
      break;
    case 'u':
      int testNum = (int)readFloat(port1);    //indicates which jonswap test passed(1 or 2). Negative means that test failed.
      if (testNum > 0) {    //only changes if test was passed
        megaUnitTests[testNum] = true;
      }
      break;
    }
  }
}
void readDueSerial() {
  /*
  Due:
   e: encoder position
   t: tau commanded to motor
   p: power
   v: velocity
   */
  while (dueConnected && port2.available() > 0)
  {
    switch(port2.readChar()) {
    case 'e':
      wecPos = readFloat(port2);
      //wec data
      if (wecPosClicked == true) {
        wecChart.push("wecPosition", wecPos);
      }
      break;
    case 't':
      tau = readFloat(port2);
      if (wecTorqClicked == true) {
        wecChart.push("wecTorque", tau);
      }
      break;
    case 'p':
      dueUnitTests[0] = true;
      pow = readFloat(port2);
      if (wecPowClicked == true) {
        wecChart.push("wecPower", pow);
      }
      break;
    case 'v':
      wecVel = readFloat(port2);
      if (wecVelClicked == true) {
        wecChart.push("wecVelocity", wecVel);
      }      
      break;
    case 'u':
      int testNum = (int)readFloat(port2);    //indicates which jonswap test passed(1 or 2)
      if (testNum > 0) {    //only changes if test was passed
        dueUnitTests[testNum] = true;
      }   
      break;
    }
  }
}
float readFloat(Serial port) {
  while (port.available() <= 4) {    //wait for full array to be in buffer
    delay(1);    //give serial some time to come through
  }  
  byte[] byteArray = new byte[4];
  //for (int i = 0; i < 4; i++) {
  //inBuffer = myPort.readBytes();
  port.readBytes(byteArray);
  //}
  //float f = ByteBuffer.wrap(byteArray).getFloat();
  float f = byteArrayToFloat(byteArray);
  //println(f);
  return f;
}

public static byte[] floatToByteArray(float value) {
  int intBits =  Float.floatToIntBits(value);
  return new byte[] {
    (byte) (intBits >> 24), (byte) (intBits >> 16), (byte) (intBits >> 8), (byte) (intBits) };
}
public static float byteArrayToFloat(byte[] bytes) {
  int intBits = 
    bytes[0] << 24 | (bytes[1] & 0xFF) << 16 | (bytes[2] & 0xFF) << 8 | (bytes[3] & 0xFF);
  return Float.intBitsToFloat(intBits);
}
