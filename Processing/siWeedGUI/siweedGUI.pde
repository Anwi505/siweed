import meter.*;
import controlP5.*; //importing GUI library
import processing.serial.*;
import java.lang.Math.*;
import java.util.LinkedList;
import java.util.Queue;

int queueSize = 512;    //power of 2 closest to 30(15) seconds at 32 samples/second    !!Needs to match arduino
LinkedList fftList;
fft myFFT;
float[] fftArr;

int previousMillis = 0;    //used to update fft 
int fftInterval = 100;    //in milliseconds

///test vars:
/*
float TSVal;
 */
 
// meter set up  
Meter m;
String fundingState = "Sandia National Laboratories is a multi-mission laboratory managed and operated by National Technology and Engineering Solutions of Sandia, LLC., a wholly owned subsidiary \n of Honeywell International, Inc., for the U.S. Department of Energy's National Nuclear Security Administration under contract DE-NA0003525.";

void setup() {
  ////////
  frameRate(32);    //sets draw() to run x times a second.
  ///////initialize objects
  size(1920,1200, P2D);
  waveMaker = new UIData();
  wec = new UIData();
  fftList = new LinkedList();
  myFFT = new fft();
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
  
  //adding meter 
  m = new Meter(this, 805, 300);
  m.setTitle("Power");
  m.setFrameColor(color(buttonblue));
  m.setMinInputSignal(0);
  m.setMaxInputSignal(500);
  //// Use the default values for testing, 0 - 255.
  //minIn = m.getMinInputSignal();
  //maxIn = m.getMaxInputSignal();
  
}
/*
public void settings() {
  fullScreen(2);
}*/

void draw() {
  // Background color
  background(dblue);
  //Title 
  textFont(fb, 40);
  fill(green);
  textLeading(15);
  textAlign(CENTER, TOP);
  
  image(wavePic, 0, 0, width, height); //background
  fill(buttonblue);
  stroke(buttonblue);
  strokeWeight(0);
  rect(0, 1120, width, 80); //bottom banner
  image(snlLogo, width-snlLogo.width*0.25-5, height-snlLogo.height*0.25-5, snlLogo.width*0.25, snlLogo.height*0.25); //Logo
  rect(0, 0, width, 95); // Top Banner
  //banner text
  fill(green);
  text("Sandia Interactive Wave Energy Educational Display", width/2, 30);
  fill(255,255,255);
  textSize(12);
  textLeading(14);
  text(fundingState, width/2, 1150);
 
  //Mission Control
  fill(turq, 150);
  stroke(buttonblue, 150);
  strokeWeight(3);
  rect(25, 150, 705, 930, 7); // background
  fill(green);
  stroke(buttonblue);
  rect(25, 130, 225, 75, 7); //Mission Control Title Box 
  //Mission Control Text
  textFont(fb, 25);
  fill(buttonblue);
  textLeading(15);
  textAlign(CENTER, TOP);
  text("Mission Control", 140, 155);
  
  // System Status
  fill(turq, 150);
  stroke(buttonblue, 150);
  rect(780, 150, 1115, 930, 7); // background
  fill(green);
  stroke(buttonblue);
  rect(780, 130, 225, 75, 7); //system title
  fill(buttonblue);
  rect(805, 610, 1065, 420, 7); //graph background
  //System Status Text
  textFont(fb, 25);
  fill(buttonblue);
  textLeading(15);
  textAlign(CENTER, TOP);
  stroke(buttonblue);
  text("System Status", 895, 155);
  stroke(green);
  rect(1387, 400, 100, 75);
  rect(1487, 400, 100, 75);
  rect(1587, 400, 100, 75);
  rect(1687, 400, 100, 75);
  
  textFont(fb, 20);
  fill(255,255,255);
  textLeading(15);
  textAlign(CENTER, TOP);
  text("Change Wave Dimensions", 175, 230);
  
  textFont(fb, 20); 
  fill(255,255,255);
  textLeading(15);
  textAlign(CENTER, TOP);
  text("Change WEC Controls", 175, 680);
  
  //meter
  // Input for testing.
  // Update the sensor value to the meter.
  m.updateMeter((int)(100*pow));
  // Use a delay to see the changes.
  
  //controls button pop up behavior
  if (mousePressed && waveText.isVisible()){
    waveText.hide();
  }
  //controls button pop up behavior
  if (mousePressed && wecText.isVisible()){
    wecText.hide();
  }
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
  }
  
  /////FFT section(move to fft tab eventually):  //!!needs to be activated and deactivated(maybe)
  if (millis() > previousMillis+fftInterval) {
    previousMillis = millis();
    Complex[] fftIn = new Complex[queueSize];
    for (int i = 0; i < queueSize; i++) {    //fill with zeros
      fftIn[i] = new Complex(0, 0);
    }
    for (int i = 0; i < fftList.size(); i++) {
      fftIn[i] = new Complex((float)fftList.get(i), 0);
    }
    //fftIn[0] = new Complex(1,0);
    //fftIn[1] = new Complex(0,0);
    //fftIn[2] = new Complex(-1,0);
    //fftIn[3] = new Complex(0,0);
    Complex[] fftOut = myFFT.fft(fftIn);
    for (int i = 0; i < queueSize; i++) {
      fftArr[i] = 2.0*(float)Math.sqrt( fftOut[i].re()*fftOut[i].re() + fftOut[i].im()*fftOut[i].im() )/queueSize;      //magnitude
      //println(fftOut[i].re()+" + "+fftOut[i].im()+"i");
    }
    //println("in: "+fftIn[16]);
    //println("out: "+fftArr[16]);
  }
  drawFFT();
  thread("readMegaSerial");    //will run this funciton in parallel thread
  thread("readDueSerial");
  thread("logData");
}
