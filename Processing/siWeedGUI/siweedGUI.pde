import meter.*;
import controlP5.*; //importing GUI library
import processing.serial.*;


// Custom colors
color green = color(190, 214, 48);
color turq = color(0, 173, 208);
color dblue = color(0, 83, 118);

// Fonts
PFont f; // Regular font
PFont fb; // Bold font

// Sandia logo
PImage snlLogo;

int nComponents = 10;     //number of wave components in sea state
float hVal, freqVal, sigHval, peakVal, peakFval, pVal;



Serial port1;
ControlP5 cp5; 
Chart waveSig; //wave Signal chart
Slider position; //slider for position mode
Slider h, freq; //sliders for function mode
Slider sigH, peakF, gama;  //sliders for sea state mode
Slider torque, other; // WEC sliders
Button jog, function, sea, off; // mode buttons

int mode = 1; // 1 = jog, 2 = function, 3 = sea, 4 = off
Table table; //create Table
int m; 





void setup() {
  fullScreen(P2D);
  frameRate(30);    //sets draw() to run 30 times a second. It would run around 40 without this restriciton
  port1 = new Serial(this, "COM4", 9600); // all communication with Mega
  delay(1000);
  // Fonts
  f = createFont("Arial", 16, true);
  fb = createFont("Arial Bold Italic", 32, true);


  // starting ControlP5 stuff

  cp5 = new ControlP5(this);

  // Buttons //

  jog = cp5.addButton("jog")
    .setPosition(100, 100)
    .setSize(100, 50)
    .setLabel("Jog Mode");

  function = cp5.addButton("fun")
    .setPosition(200, 100)
    .setSize(100, 50)
    .setLabel("Function Mode"); 

  sea = cp5.addButton("sea")
    .setPosition(300, 100)
    .setSize(100, 50)
    .setLabel("Sea State"); 

  off = cp5.addButton("off")
    .setPosition(400, 100)
    .setSize(100, 50)
    .setLabel("OFF"); 


  // Sliders // 
  position = cp5.addSlider("Position (CM)")  //name slider
    .setRange(-10, 10) //slider range
    .setPosition(150, 250) //x and y coordinates of upper left corner of button
    .setSize(300, 20); //size (width, height)

  h = cp5.addSlider("Height (CM)")  //name slider
    .setRange(0, 10) //slider range
    .setPosition(150, 250) //x and y coordinates of upper left corner of button
    .setSize(300, 20)
    .hide(); //size (width, height)

  freq = cp5.addSlider("Frequency (Hz)")  //name of button
    .setRange(0, 4)
    .setPosition(150, 300) //x and y coordinates of upper left corner of button
    .setSize(300, 20)
    .hide(); //size (width, height)

  sigH = cp5.addSlider("Significant Height (CM)")  //name slider
    .setRange(0, 10) //slider range
    .setPosition(150, 250) //x and y coordinates of upper left corner of button
    .setSize(300, 20)
    .hide(); //size (width, height)

  peakF = cp5.addSlider("Peak Frequency (Hz)")  //name of button
    .setRange(2, 4)
    .setPosition(150, 300) //x and y coordinates of upper left corner of button
    .setSize(300, 20)
    .hide(); //size (width, height)

  gama = cp5.addSlider("Peakedness")  //name of button
    .setRange(1, 7)
    .setPosition(150, 350) //x and y coordinates of upper left corner of button
    .setSize(300, 20)
    .hide(); //size (width, height)

  torque = cp5.addSlider("Torque")  //name of button
    .setRange(0, 0.5)
    .setPosition(150, 650) //x and y coordinates of upper left corner of button
    .setSize(300, 20); //size (width, height)

  other = cp5.addSlider("otherthing")  //name of button
    .setRange(0, 0.5)
    .setPosition(150, 700) //x and y coordinates of upper left corner of button
    .setSize(300, 20); //size (width, height)

  // Charts //

  waveSig =  cp5.addChart("Sin Wave")
    .setPosition(933.375, 100  )
    .setSize(800, 300)
    .setRange(-20, 20)
    .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
    .setStrokeWeight(4)
    .setColorCaptionLabel(color(40))
    .setColorBackground(turq)
    .setColorLabel(green)
    ;



  waveSig.addDataSet("incoming");
  waveSig.setData("incoming", new float[250]);    //use to set the domain of the plot

  port1.write('!');
  sendFloat(0);    //initialize arduino in jog mode at position 0
  port1.write('j');
  sendFloat(0);
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


  // Sandia Labs logo
  snlLogo = loadImage("SNL_Stacked_White.png");
  tint(255, 126);  // Apply transparency without changing color
  image(snlLogo, 5, height-snlLogo.height*0.25-5, snlLogo.width*0.25, snlLogo.height*0.25);

  //dividing line
  stroke(green);
  strokeWeight(1.5);
  line(width/3, 75, width/3, height-75);

  //updates chart for function mode  
  //Jog:
  if (mode == 1 && position.getValue() != pVal) {  //only sends if value has changed  
    pVal = position.getValue();
    port1.write('j');
    sendFloat(pVal);
    //function:
  } else if (mode == 2 && !mousePressed && (hVal != h.getValue() || freqVal != freq.getValue())) {    //only executes if a value has changed and the mouse is lifted(smooths transition)
    hVal = h.getValue();
    freqVal = freq.getValue();
    port1.write('a');
    sendFloat(hVal);
    port1.write('f');
    sendFloat(freqVal);
    //Sea State:
  } else if (mode == 3 && !mousePressed && (sigHval != sigH.getValue() || peakFval != peakF.getValue())) {    //only executes if a value has changed and the mouse is lifted(smooths transition)
    sigHval = sigH.getValue();
    peakFval = peakF.getValue();
    //Here we will call other java function

    //then send to arduino
    //waveSig.push("incoming", (sin(frameCount*peakFval)*sigHval));
  }
  thread("readSerial");    //will run this funciton in parallel thread
}

/////////////////// MAKES BUTTONS DO THINGS ////////////////////////////////////

void jog() {
  mode = 1;
  h.hide();
  freq.hide();
  sigH.hide();
  peakF.hide();
  gama.hide();
  position.show();
  //set mode on arduino:
  port1.write('!');
  sendFloat(0);
}

void fun() {
  mode = 2;
  position.hide();
  gama.hide();

  h.show();
  freq.show();
  //set mode on arduino:
  port1.write('!');
  sendFloat(1);
  //tell arduino to only look at one component
  port1.write('n');
  sendFloat(1);
}

void sea() {
  mode = 3;
  h.hide();
  freq.hide();
  h.hide();
  position.hide();
  sigH.show();
  peakF.show();
  gama.show();
  //set mode on arduino:
  port1.write('!');
  sendFloat(1);
  //tell arduino to look at all components
  port1.write('n');
  sendFloat(nComponents);
}

void off() {
  mode = 4;
  h.setValue(0);
  freq.setValue(0);
  sigH.setValue(0);
  peakF.setValue(0); 
  position.setValue(0);
  //set mode on arduino:
  port1.write('!');
  sendFloat(-1);
}
void sendFloat(float f)
{
  /* '!' indicates mode switch
   j indicates jog position
   
   n indicates length of vectors/number of functions in sea state(starting at 1)
   a indicates incoming amp vector
   p indicates incoming phase vector
   f indicates incoming frequency vector
   
   ex:  !<1>n<2>a<1.35><2.36>p<1.35><2.36>f<1.35><2.36>    
   
   with this function sending data will look something like this:
   if(values have changed)    //or run certain lines on a button press
   port1.write('!');    set mode(only needs to be done when switching)
   sendFloat(1);
   
   port1.write('n');    set number of components(only needs to be done once)
   sendFloat(30);        
   
   port1.write('a');
   sendFloat(2.3);
   sendFloat(1.2);
   .
   .
   .
   .
   //needs to send n number of floats
   
   */
  f= Math.round(f*100.0)/100.0;    //limits to two decimal places
  String posStr = "<";    //starts the string
  posStr = posStr.concat(Float.toString(f));
  posStr = posStr.concat(">");    //end of string "keychar"
  port1.write(posStr);
}
void readSerial() {
  while (port1.available() > 0)    //recieves until buffer is empty. Since it runs 30 times a second, the arduino will send many samples per execution
  {
    waveSig.push("incoming", readFloat());
  }
}
float readFloat() {
  if (port1.readChar() == '<') {
    String str = "";    //port1.readStringUntil('>');
    do {
      while (port1.available() < 1) {
        //println("waiting");
        delay(1);        //doesn't work without this for some reason
      }    //wait until data comes through
      str += port1.readChar();
    } while (str.charAt(str.length()-1) != '>');
    str = str.substring(0, str.length()-1);    //removes the >
    return float(str);
  } else {
    return -1.0;
  }
}
/*
//Funciton to test CSV functionality     //didn't compile with this for me
 void mouseClicked() { //we will want this to log data every 10 milli seconds 
 //table.addColumn("timeStamp");
 //table.addColumn("waveMakerMode");
 //table.addColumn("wec_kp");
 //table.addColumn("wec_ki");
 TableRow newRow = table.addRow();
 newRow.setFloat("timeStamp", m);
 newRow.setInt("waveMakerMode", mode);
 newRow.setFloat("wec_kp", torque.getValue());
 newRow.setFloat("wec_ki", other.getValue()); 
 saveTable(table, "data/new.csv");
 } 
 */
