const float interval = .01;    //interval of updateTau interupt in seconds
const float serialInterval = .0333; //interval of serial interupt

void initInterrupts() {
  Timer.getAvailable().attachInterrupt(sendSerial).start(serialInterval * 1.0e6);
  delay(50);
  Timer.getAvailable().attachInterrupt(updateTau).start(interval * 1.0e6);
}
volatile float pos;
void updateTau()    //called by interupt
{
  volatile float prevPos = pos;
  pos = encPos;
  vel = (pos - prevPos) / interval;
  switch (mode)
  {
    case -1:
      digitalWrite(enablePin, LOW);   //stop
      break;
    case 0:
      tauCommand = tau;       //direct control
      break;
    case 1:
      tauCommand = kp * pos + kd * vel;      //PD feedback control
      break;
    case 2:
      if (newJonswapData) {
        newJonswapData = false;
        jonswap.update(sigH, peakF, _gamma);
        for (int i = 0; i < jonswap.getNum(); i++) {
          amps[i] = jonswap.getAmp()[i];
          freqs[i] = jonswap.getF()[i];
          phases[i] = jonswap.getPhase()[i];
        }
      }
      tauCommand = 0;
      for (volatile int i = 0; i < jonswap.getNum(); i++)           //function mode
      {
        tauCommand += amps[i] * sin(2 * pi * t * freqs[i] + phases[i]);
      }
      break;
  }
  if (mode != -1)
  {
    analogWrite(tauPin, mapFloat(tauCommand, minTau, maxTau, 0, 4095));    //!!!!!!!NEEDS TO ACCOUNT FOR EDGE ZONES//sends to the motor controller after mapping from newtom/meters to analog
    digitalWrite(enablePin, HIGH);
  }
}
void sendSerial()   //called by interrupt
{
  /*
    e: encoder position
    t: tau commanded to motor
    p: power
  */
  Serial.write('e');
  sendFloat(encPos);
  Serial.write('t');
  sendFloat(tauCommand);
  Serial.write('p');
  sendFloat(power);
}
