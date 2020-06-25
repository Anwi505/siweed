import meter.*;
import controlP5.*; //importing GUI library
import processing.serial.*;
import java.lang.Math.*;
import java.util.LinkedList;
import java.util.Queue;

int queueSize = 1024;    //power of 2 closest to 30 seconds at 32 samples/second    !!Needs to match arduino
miniWaveTankJonswap jonswap;
LinkedList fftList;
FFTbase myFFT;
fftNew myNewFFT;         //!!!rename class eventually
float[] fftArr;

int previousMillis = 0;    //used to update fft 
int fftInterval = 100;    //in milliseconds

///test vars:
/*
float TSVal;
*/
void setup() {
  ////////
  fullScreen(P2D);
  frameRate(32);    //sets draw() to run x times a second.
  ///////initialize objects
  jonswap = new miniWaveTankJonswap();
  waveMaker = new UIData();
  wec = new UIData();
  fftList = new LinkedList();
  myFFT = new FFTbase();
  myNewFFT = new fftNew();
  fftArr = new float[queueSize*2];
  //fftComplexArr = new Complex[queueSize];
  waveMaker.mode = 1;    // 1 = jog, 2 = function, 3 = sea, 4 = off
  wec.mode = 3;  //1 = torque, 2 = "sea", 3 = off
  initializeDataLogging();
  initializeSerial();    //has a 2 second delay
  initializeUI();

  //initialize the modes on the arduinos:
  port1.write('!');
  sendFloat(0, port1);    //jog mode
  port1.write('j');
  sendFloat(0, port1);    //at position 0

  port2.write('!');
  sendFloat(-1, port2);    //off
  port2.write('n');
  sendFloat(1, port2);    //initialize n at 1
  //testing
  /*
  jonswap.update(5.0,3.0,7.0);
  println(jonswap.getNum());
  for(int i = 0; i<jonswap.getNum(); i++){
    print(jonswap.getAmp()[i]);
    print("  ");
  }
  println();println();
  for(int i = 0; i<jonswap.getNum(); i++){
    print(jonswap.getF()[i]);
    print("  ");
  }
  println();println();
  for(int i = 0; i<jonswap.getNum(); i++){
    print(jonswap.getPhase()[i]);
    print("  ");
  }
  println();
  */
}

void draw() {
  // Background color
  background(dblue);
  //Title 
  textFont(fb, 32);
  fill(green);
  textLeading(15);
  textAlign(CENTER, TOP);
  text("CAPTURING the POWER of WAVES", width/6, 20);

  tint(255, 126);  // Apply transparency without changing color
  image(snlLogo, 5, height-snlLogo.height*0.25-5, snlLogo.width*0.25, snlLogo.height*0.25);
  //dividing line
  stroke(green);
  strokeWeight(1.5);
  line(width/3, 75, width/3, height-75);
  //Jog:
  if (waveMaker.mode == 1 && position.getValue() != waveMaker.mag) {  //only sends if value has changed  
    waveMaker.mag = position.getValue();
    port1.write('j');
    sendFloat(waveMaker.mag, port1);
    //function:
  } else if (waveMaker.mode == 2 && !mousePressed && (waveMaker.amp != h.getValue() || waveMaker.freq != freq.getValue())) {    //only executes if a value has changed and the mouse is lifted(smooths transition)
    waveMaker.amp = h.getValue();
    waveMaker.freq = freq.getValue();
    port1.write('a');
    sendFloat(waveMaker.amp, port1);
    port1.write('f');
    sendFloat(waveMaker.freq, port1);
    //Sea State:
  } else if (waveMaker.mode == 3 && !mousePressed && (waveMaker.sigH != sigH.getValue() || waveMaker.peakF != peakF.getValue() || waveMaker.gamma != gamma.getValue())) {    //only executes if a value has changed and the mouse is lifted(smooths transition)
    waveMaker.sigH = sigH.getValue();
    waveMaker.peakF = peakF.getValue();
    waveMaker.gamma = gamma.getValue();
    port1.write('s');
    sendFloat(waveMaker.sigH, port1);
    port1.write('p');
    sendFloat(waveMaker.peakF, port1);
    port1.write('g');
    sendFloat(waveMaker.gamma, port1);    //gamma always needs to be the last sent
    //update the jonswap values with new inputs
    //jonswap.update(waveMaker.sigH, waveMaker.peakF, waveMaker.gamma);
    //then send to arduino
    //thread("sendJonswap");    //put this in a thread to not slow down processing(maybe)
  }
  /////FFT section(move to fft tab eventually):  //!!needs to be activated and deactivated(maybe)
  if (millis() > previousMillis+fftInterval) {
    previousMillis = millis();
    Complex[] fftIn = new Complex[queueSize];
    for (int i = 0; i < queueSize; i++) {    //fill with zeros
      fftIn[i] = new Complex(0,0);
    }
    for (int i = 0; i < fftList.size(); i++) {
      fftIn[i] = new Complex((float)fftList.get(i), 0);
    }
    //fftIn[0] = new Complex(1,0);
    //fftIn[1] = new Complex(0,0);
    //fftIn[2] = new Complex(-1,0);
    //fftIn[3] = new Complex(0,0);
    Complex[] fftOut = myNewFFT.fft(fftIn);
    for (int i = 0; i < queueSize; i++) {
      fftArr[i] = (float)Math.sqrt( fftOut[i].re()*fftOut[i].re() + fftOut[i].im()*fftOut[i].im() );      //magnitude
      //println(fftOut[i].re()+" + "+fftOut[i].im()+"i");
    }
  }
  for (int i=0; i<queueSize*2; i++) {
    line((width*2/6)+1.5*i, height*4/6, (width*2/6)+1.5*i, height*4/6 - 0.6*fftArr[i]);
  }
  
  /////////testing section////
  /*
  //amp graph:
  for (int i=0; i<jonswap.getNum(); i++) {
    line((width*2/6)+5*i, height*5/6, (width*2/6)+5*i, height*5/6 - 100*jonswap.getAmp()[i]);
  }
  ///
  TSVal = 0;
  for (int i = 0; i < jonswap.getNum(); i++) {
    TSVal += jonswap.getAmp()[i] * sin(2.0 * PI * (millis()/1000.0 - 2.0) * jonswap.getF()[i] + jonswap.getPhase()[i]);
    //val = sin(2.0 * PI * millis()/1000.0);
  }
  waveSig.push("incoming", TSVal);
  if (waveMaker.mode == 3) {
    fftList.add(TSVal);      //adds to the tail if in the right mode
    if (fftList.size() > queueSize)
    {
      fftList.remove();          //removes from the head
    }
  }

  ///////////////////*/

  //readMegaSerial();
  thread("readMegaSerial");    //will run this funciton in parallel thread
  thread("readDueSerial");
  thread("logData");
}
