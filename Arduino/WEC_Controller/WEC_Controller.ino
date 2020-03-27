#include <Encoder.h>
#include<math.h>
int mode = -1;    //-1 stop, 0 torque control, 1 feedback control, 2 function mode
double t = 0;    //time in seconds
float tau = 0, kp = 0, kd = 0, power = 0, vel = 0;
const int tauPin = DAC0, l1Pin = 10, l2Pin = 11, l3Pin = 12, l4Pin = 13;
Encoder wecEnc(2, 3); //pins 2 and 3(interupts)//for 800 ppr/3200 counts per revolution set dip switches(0100) //2048ppr/8192 counts per revolution max(0000)
float encPos;
const float encStepsPerTurn = 3200.0;
const float teethPerTurn = 5;   //EDIT
const float mmPerTooth = 10;    //EDIT

const float interval = .001;    //interval of updateTau interupt in seconds
const float serialInterval = .02; //interval of serial interupt

int n = 1;            //numbe of components
const int maxComponents = 60;   //max needed number of frequency components
float amps[maxComponents];
float phases[maxComponents];
float freqs[maxComponents];

void setup()
{
  Serial.begin(9600);
  analogWriteResolution(12);    //analog write now runs from 0 to 4095
  wecEnc.write(0);     //zero encoder
}

void loop()
{
  encPos = wecEnc.read() * (1 / encStepsPerTurn) * teethPerTurn * mmPerTooth; //steps*(turns/step)*(mm/turn)
  t = micros() / 1000000.0;
  power = -1 * tau * vel;
  readSerial();
}
float pos;
void updateTau()    //will need to be called by an interupt
{
  float prevPos = pos;
  pos = encPos;
  vel = (pos - prevPos) / interval;
  analogWrite(tauPin, tau);   //writes the torque value to the dac
}
void sendSerial()   //will need to be called by an interupt
{
  /*
    e: encoder position
    t: tau
    p: power
  */
  Serial.write('e');
  sendFloat(encPos);
  Serial.write('t');
  sendFloat(tau);
  Serial.write('p');
  sendFloat(power);

}
void readSerial()
{
  /* '!' indicates mode switch, next int is mode
    t indicates torque command
    k indicates kp -p was taken
    d indicates kd
    n indicates length of vectors/number of functions in sea state(starting at 1)
    a indicates incoming amp vector
    p indicates incoming phase vector
    f indicates incoming frequency vector
  */
  if (Serial.available() > 0)
  {
    char c = Serial.read();
    switch (c)
    {
      case '!':
        mode = (int)readFloat();
        break;
      case 'n':
        n = (int)readFloat();
        if (n > maxComponents)
        {
          n = maxComponents;     //to prevents reading invalid index
        }
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
      case 'a':
        for (int i = 0; i < n; i++)
        {
          amps[i] = readFloat();
        }
        break;
      case 'p':
        for (int i = 0; i < n; i++)
        {
          phases[i] = readFloat();
        }
        break;
      case 'f':
        for (int i = 0; i < n; i++)
        {
          freqs[i] = readFloat();
        }
        break;
    }
  }
}
float readFloat()
{
  while (Serial.available() < 1) {}
  if (Serial.read() == '<')
  {
    String str = Serial.readStringUntil('>');
    return str.toFloat();
  }
  else
  {
    return 0.0;
  }
}
void sendFloat(float f)
{
  f = round(f * 100.0) / 100.0; //limits to two decimal places
  String dataStr = "<";    //starts the string
  dataStr += String(f);
  dataStr += ">";    //end of string
  Serial.print(dataStr);
}
