import processing.io.*;
import grafica.*;

GPlot plot_x, plot_y, plot_z;
int npoints = 100;
GPointsArray points_x = new GPointsArray(npoints);
GPointsArray points_y = new GPointsArray(npoints);
GPointsArray points_z = new GPointsArray(npoints);
int points_count = 0;

SPI spi0,spi1;
SPI currentSPI;
int currentSensor = 0;

static final byte DEVICE_CONFIG = 0x00;
static final byte SENSOR_CONFIG = 0x01;
static final byte SYSTEM_CONFIG = 0x02;
static final byte TEST_CONFIG = 0x0F;
static final int X_CH_RESULT = 0x89;
static final int Y_CH_RESULT = 0x8A;
static final int Z_CH_RESULT = 0x8B;
static final int TEMP_RESULT = 0x8C;

static final int S0 = 76;
static final int S1 = 38;
static final int S2 = 200;
static final int S3 = 149;

int chipSelectPin;
int nextSelect;
boolean pinChange=false;

void setup() {
  size(600,400);
  printArray(SPI.list());
  
  spi0 = new SPI(SPI.list()[0]);
  spi1 = new SPI(SPI.list()[1]);
  spi0.settings(500000, SPI.MSBFIRST, SPI.MODE0);
  spi1.settings(500000, SPI.MSBFIRST, SPI.MODE0);
  delay(50);

  GPIO.pinMode(S0, GPIO.OUTPUT);
  GPIO.pinMode(S1, GPIO.OUTPUT);
  GPIO.pinMode(S2, GPIO.OUTPUT);
  GPIO.pinMode(S3, GPIO.OUTPUT);
  delay(50);

  selectSensor(0);
  initializeSensor();
  
  selectSensor(1);
  initializeSensor();

  selectSensor(2);
  initializeSensor();
  
  selectSensor(3);;
  initializeSensor();
  
  plot_x = new GPlot(this);
  plot_x.setPos(0,0);
  plot_x.setDim(500,300);
  plot_x.setPointSize(2);
  plot_x.setLineWidth(0.5);
  plot_x.setYLim(-5000,5000);

  plot_y = new GPlot(this);
  plot_y.setPos(0,0);
  plot_y.setDim(500,300);
  plot_y.getRightAxis().setDrawTickLabels(true);
  plot_y.setPointColor(color(0,0,255));
  plot_y.setPointSize(2);
  plot_y.setLineWidth(0.5);
  plot_y.setYLim(-5000,5000);
  
  plot_z = new GPlot(this);
  plot_z.setPos(0,0);
  plot_z.setDim(500,300);
  plot_z.setPointColor(color(0,255,0));
  plot_z.setPointSize(2);
  plot_z.setLineWidth(0.5);
  plot_z.setYLim(-5000,5000);

}

void draw() {
  
  background(255);
  if (pinChange) {
    selectSensor(currentSensor);
    pinChange = false;
  }
  int x_ch = readRegister((byte) X_CH_RESULT, (byte) 0x00, (byte) 0x00, (byte) 0x00);
  delay(30);
  int y_ch = readRegister((byte) Y_CH_RESULT, (byte) 0x00, (byte) 0x00, (byte) 0x00);
  delay(30);
  int z_ch = readRegister((byte) Z_CH_RESULT, (byte) 0x00, (byte) 0x00, (byte) 0x00);
  delay(30);
  
  points_x.add(points_count, x_ch);
  points_y.add(points_count, y_ch);
  points_z.add(points_count, z_ch);
  points_count++;
  
  if (points_count >= npoints-1) {
    points_x.remove(0);
    points_y.remove(0);
    points_z.remove(0);
  }
  
  plot_x.setPoints(points_x);
  plot_y.setPoints(points_y);
  plot_z.setPoints(points_z);
  
  plot_x.beginDraw();
  plot_x.drawBox();
  plot_x.drawXAxis();
  plot_x.drawYAxis();
  plot_x.drawPoints();
  plot_x.drawLines();
  plot_x.endDraw();
  
  plot_y.beginDraw();
  plot_y.drawRightAxis();
  plot_y.drawPoints();
  plot_y.drawLines();
  plot_y.endDraw();
  
  plot_z.beginDraw();
  plot_z.drawPoints();
  plot_z.drawLines();
  plot_z.endDraw();

}

void selectSensor(int nsensor) {
 switch (nsensor) {
   case 0:
     currentSPI = spi0;
     chipSelectPin = S3;
     break;
   case 1:
     currentSPI = spi0;
     chipSelectPin = S2;
     break;
   case 2:
     currentSPI = spi1;
     chipSelectPin = S1;
     break;
   case 3:
     currentSPI = spi1;
     chipSelectPin = S0;
     break;
 }
}

void initializeSensor() {
  writeRegister(TEST_CONFIG, (byte) 0x00, (byte) 0x04, (byte) 0x07);
  delay(30);
  writeRegister(SENSOR_CONFIG, (byte) 0x01, (byte) 0xEA, (byte) 0x00);
  delay(30);
  writeRegister(DEVICE_CONFIG, (byte) 0b00110001, (byte) 0x20, (byte) 0x00);
  delay(30);
}

void writeRegister(byte thisRegister, byte thisValueA, byte thisValueB, byte thisCommand) {
 
  GPIO.digitalWrite(chipSelectPin, GPIO.LOW);
  byte[] out = {thisRegister, thisValueA, thisValueB, thisCommand};
  currentSPI.transfer(out);
  GPIO.digitalWrite(chipSelectPin, GPIO.HIGH);
}

int readRegister(byte thisRegister, byte thisValueA, byte thisValueB, byte thisCommand) {
 byte[] outByte = {thisRegister, thisValueA, thisValueB, thisCommand};
 byte[] inByte;
 int result = 0;
 
 GPIO.digitalWrite(chipSelectPin, GPIO.LOW);
 inByte = currentSPI.transfer(outByte);
 result = (inByte[1] << 8) + inByte[2];
 GPIO.digitalWrite(chipSelectPin, GPIO.HIGH);
 
 return result;
}

void resetSelectorPins() {
  GPIO.digitalWrite(S0, GPIO.HIGH);
  GPIO.digitalWrite(S1, GPIO.HIGH);
  GPIO.digitalWrite(S2, GPIO.HIGH);
  GPIO.digitalWrite(S3, GPIO.HIGH);
}

void keyPressed() {
 if (key == '1') {
   currentSensor = 0;
   pinChange = true;
 }
  if (key == '2') {
   currentSensor = 1;
   pinChange = true;
 }
  if (key == '3') {
   currentSensor = 2;
   pinChange = true;
 }
  if (key == '4') {
   currentSensor = 3;
   pinChange = true;
 }
}
