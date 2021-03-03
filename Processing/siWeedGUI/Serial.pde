Serial port1;    //arduino mega
Serial port2;    //arduino Due
boolean megaConnected, dueConnected;
int connectionDelay  = 3500;      //how many ms to wait after connecting to a device. Can greatly slow the startup
void initializeSerial() {
  ///////////initialize Serial

  printArray(Serial.list());     //for debugging, shows all attached devices
  if (debug) println("mega Serial:");
  for (int i = 0; i < Serial.list().length; i++) {    //tries each device
    if (!megaConnected) {
      try {
        if (debug) println("trying port"+i);
        port1 = new Serial(this, Serial.list()[i], 250000); //attempts to connect
        megaConnected = true;
        if (debug) println("mega test port connected");
      }
      catch(Exception e) {
        megaConnected = false;
        if (debug) println("exception caught");
      }
      if (megaConnected) {    //if the device successfully connected
        delay(2000);          //wait for connection to stabilize
        if (debug) println("testing mega serial");
        readMegaSerial();    //reads serial buffer and sets bool true if recieving normal results
        if (debug) println("finished testing mega serial");
        if (megaUnitTests[0]) {
          //correct board found
          if (debug) println("correct board found");
        } else {
          megaConnected = false;    //if not found, keep testing
          port1.stop();    //disconnect the port so Due function can try
          if (debug) println("wrong board");
        }
      }
    }
    if (debug) println("Due Serial");
    if (debug) println(Serial.list()[i]);
    if (!dueConnected) {
      try {
        if (debug) println("trying port");
        port2 = new Serial(this, Serial.list()[i], 250000); // all communication with Due
        dueConnected = true;
        if (debug) println("due port found");
      }
      catch(Exception e) {
        dueConnected = false;
      }
      if (dueConnected) {
        delay(2000);
        if (debug) println("testing Due Serial");
        readDueSerial();    //reads serial buffer and sets bool true if recieving normal results
        if (dueUnitTests[0]) {
          //correct board found
        } else {
          dueConnected = false;
          port1.stop();    //disconnect the port
        }
      }
    }
  }

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
  if (megaConnected) {
    for (int i = 0; i <port1.available()/20; i++) {    //runs as many times to empty the buffer(bytes availible/ bytes read per loop).
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
        megaUnitTests[0] = true;      //for unit testing and acquiring serial.
        debugData = readFloat(port1);
        waveChart.push("debug", debugData);
        if (waveMaker.mode == 3||waveMaker.mode == 2) fftList.add(debugData);      //adds to the tail if in the right mode
        if (fftList.size() > queueSize) fftList.remove();          //removes from the head
        break;
      case 'u':
        int testNum = (int)readFloat(port1);    //indicates which jonswap test passed(1 or 2). Negative means that test failed.
        if(debug){println("testNum:"+testNum);}
        if (testNum > 0) {    //only changes if test was passed
          megaUnitTests[testNum] = true;
        }
        break;
      }
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
  if (dueConnected) {
    for (int i = 0; i <port2.available()/20; i++) {    //runs as many times to empty the buffer(bytes availible/ bytes read per loop). Since it runs 30 times a second, the arduino will send many samples per execution.
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
}
float readFloat(Serial port) {
  while (port.available() <= 4) {    //wait for full array to be in buffer
    delay(1);    //give serial some time to come through
  }  
  byte[] byteArray = new byte[4];
  port.readBytes(byteArray);
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
