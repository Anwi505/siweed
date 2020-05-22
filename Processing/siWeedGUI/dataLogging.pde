void initializeDataLogging() {
  startTime = month() + "-" + day() + "-" + year() + "_" + hour() + "-" + minute() + "-" + second();
  //Table initialization:
  table = new Table();
  table.addColumn("timeStamp");
  table.addColumn("UIWaveMakerMode");
  table.addColumn("UIWaveMakerPos");
  table.addColumn("UIWaveMakerHeight");
  table.addColumn("UIWaveMakerFrequency");
  table.addColumn("UIWaveMakerSigH");
  table.addColumn("UIWaveMakerPeakF");
  table.addColumn("UIWaveMakergamma");
  table.addColumn("UIWecMode");
  table.addColumn("UIWecTorque");
  table.addColumn("UIWeckP");
  table.addColumn("UIWeckD");
  table.addColumn("UIWecHeight");
  table.addColumn("UIWecFrequency");
  table.addColumn("UIWecSigH");
  table.addColumn("UIWecPeakF");
  table.addColumn("UIWecgamma");
  table.addColumn("probe1");
  table.addColumn("probe2");
  table.addColumn("waveMakerPos");
  table.addColumn("waveMakerDebugData");
  table.addColumn("wecPos");
  table.addColumn("wecTau");
  table.addColumn("wecPower");
}
//Funciton to test CSV functionality
void logData() {     //will be called at the framerate
  TableRow newRow = table.addRow();
  newRow.setFloat("timeStamp", millis());
  newRow.setInt("UIWaveMakerMode", waveMaker.mode);
  newRow.setFloat("UIWaveMakerPos", waveMaker.mag);
  newRow.setFloat("UIWaveMakerHeight", waveMaker.amp);
  newRow.setFloat("UIWaveMakerFrequency", waveMaker.freq);
  newRow.setFloat("UIWaveMakerSigH", waveMaker.sigH);
  newRow.setFloat("UIWaveMakerPeakF", waveMaker.peakF);
  newRow.setFloat("UIWaveMakergamma", waveMaker.gamma);
  newRow.setFloat("UIWecMode", wec.mode);
  newRow.setFloat("UIWecTorque", wec.mag);
  newRow.setFloat("UIWeckP", torque.getValue());
  newRow.setFloat("UIWeckD", other.getValue()); 
  newRow.setFloat("UIWecHeight", wec.amp);
  newRow.setFloat("UIWecFrequency", wec.freq);
  newRow.setFloat("UIWecSigH", wec.sigH);
  newRow.setFloat("UIWecPeakF", wec.peakF);
  newRow.setFloat("UIWecgamma", wec.gamma);
  newRow.setFloat("probe1", probe1);
  newRow.setFloat("probe2", probe2);
  newRow.setFloat("waveMakerPos", waveMakerPos);
  newRow.setFloat("waveMakerDebugData", debugData);
  newRow.setFloat("wecPos", wecPos);
  newRow.setFloat("wecTau", tau);
  newRow.setFloat("wecPower", pow);
  saveTable(table, "data/"+startTime+".csv");
} 
