void initSerial() {
  Serial.begin(57600);
}
void readSerial()
{
  /*
    '!' indicates mode switch, next int is mode
    t indicates torque command
    k indicates kp -p was taken
    d indicates kd
    s :sigH
    p :peakF
    g :gamma
    u :serial mode
  */
  if (Serial.available() >  4) {   //if a whole float is through: 1 byte tag + 4 byte float
    char c = Serial.read();
    switch (c)
    {
      case '!':
        mode = (int)readFloat();
        break;
      case 't':
        tau = readFloat();
        break;
      case 'k':
        kp = readFloat();
        break;
      case 'd':
        kd = readFloat();
        break;
      case 's':
        sigH = readFloat();
        break;
      case 'p':
        peakF = readFloat();
        break;
      case 'g':     //should always be recieved after s and p
        _gamma = readFloat();
        newJonswapData = true;
        break;
      case 'u':
        int u = (int)readFloat();    // if 1, unit test sending mode, if 0, normal serial operation.
        if (u)
        {
          sendUnitTests = true;
        } else {
          sendUnitTests = false;
        }
        break;
    }
  }
}

volatile float readFloat() {
  volatile byte byteArray[4];
  for (volatile int i = 0; i < 4; i++) {
    byteArray[i] = Serial.read();
  }
  volatile float f = bin2float((byte*)&byteArray);
  return f;
}

volatile void sendFloat(volatile float f) {
  volatile byte byteArray[4];
  float2bin(f, (byte*)&byteArray);
  for (volatile int i = 0; i < 4; i++) {
    Serial.write(byteArray[i]);
  }
}

volatile void float2bin(volatile float target, volatile byte * byteArray) {
  volatile uint32_t temp32;
  temp32 = (uint32_t)(*(uint32_t*)&target);
  for (volatile int i = 0; i < 4; i++) {
    byteArray[i] = (byte)(temp32 >> (8 * (3 - i)));
  }
}

volatile float bin2float(volatile byte * byteArray) {
  volatile uint32_t temp32 = 0;
  volatile byte temp8;

  for (volatile int i = 0; i < 4; i++) {
    temp8 = byteArray[i];
    temp32 |= ((uint32_t)temp8 << (8 * (3 - i)));
  }

  float returnFloat;
  returnFloat = (float)(*(float*)&temp32);
  return returnFloat;
}
