//////////////////////////////////////////////////////////////////////////
//Filenames: MeU_Square_GIF_Converter_Teensy.pde
//Authors: Robert Tu
//Date Created: February 5, 2014
//Notes:
/*
  
  This is Processing sketch that converts animated GIF files into an Arduino
  sketch file that you can then download into the MeU panel. 
  
  Only animated GIF files are accepted, although GIF files with one animation
  frame can be converted. GIF dimensions MUST be 16x16 to show properly
  on MeU. 
  
  Any image file can be converted into a 16x16 animated GIF by using standard
  photo editing software such as PhotoShop or Gimp.
  
  Follow instructions on the screen to converted a selected GIF file.
  
  Once conversion is complete, locate the newly created Arduino sketch folder
  and open the Arduino IDE.
  
  Before you download, make sure the right Arduino board is chosen. 
  
  MeU uses the Arduion Mini Pro (5V 16MHz) with ATMega 328 board.
  
*/

//////////////////////////////////////////////////////////////////////////


//import libraries

//library can be found here:
////http://www.extrapixel.ch/processing/gifAnimation/
import gifAnimation.*;

//library can be found here:
//http://www.sojamo.de/libraries/controlP5/
import controlP5.*;

//File Handler variables
PrintWriter output;
PrintWriter LoopFileOutput;

//store the GIF animation frames in this array
PImage[] animation;
int FrameNumber;

//File names and text status variables
String GIFPath="None Chosen";
String OutputPath = "None Chosen";
String Status = " ";

//variable to access ControlP5 class
ControlP5 cp5;


//****************************
//Change GIF dimensions here:

final int HEIGHT = 16;
final int WIDTH = 16;
//****************************

void setup() {
 
  //set up the screen size and layout the buttons
  
  size(550, 650);
  cp5 = new ControlP5(this);
  
  
  cp5.addButton("GIFSelect")
    .setSize(130, 35)
    .setPosition(43, 180)
    .setLabel("Select a GIF");
  
  
  
  cp5.addTextfield("ArduinoName")
    .setLabel("Arduino Sketch File Name")
    .setPosition(43, 269)
    .setSize(300, 30);
    
  
  cp5.addButton("OutputSelect")
    .setLabel("Select Directory")
    .setPosition(43, 347)
    .setSize(130, 35);
  
  
  
  cp5.addButton("Run")
    .setPosition(43, 440)
    .setSize(130, 35);
  
    
  cp5.addButton("Exit")
    .setPosition(43, 550)
    .setSize(130, 35);
  
}

void draw() {
  //continuosly draw background and update text statuses
  background(10, 30, 30);
  drawText();

}

void drawText() {
  
  textSize(12);
  text("MeU Animation Conversion Program", 43, 50);
  text("- Only 16x16 gif files will work with MeU", 43, 75);
  text("- After program runs, an Arduino sketch will be produced", 43, 90);
  text("- Download the sketch to MeU using the Arduino IDE", 43, 105);
  text("- In Arduino IDE, choose Teensy 3.1", 43, 120);
  
  text("1. Select a 16x16 GIF File", 43, 160);
  textSize(8);
  text(GIFPath, 43, 227);
  textSize(12);
  text("2. Choose a file name for the Arduino sketch (no spaces or special char)", 43,255);
  text("3. Select a directory to store the Arduino Sketch", 43, 335);
  textSize(8);
  text(OutputPath, 43, 392);
  textSize(12);
  text("4. Only run if steps 1 to 3 have been completed", 43, 425);
  textSize(13);
  
  text(Status, 43, 490);
}

//Button Functions

public void GIFSelect() {
  selectInput("Select a 16x16 GIF file: ", "GIFProcess");

} 

void GIFProcess(File selection) {
  
  if (selection == null) {
    GIFPath = "None Chosen";
  } else {
    GIFPath = selection.getAbsolutePath();
  }
}

public void OutputSelect() {
  selectFolder("Select an output Folder: ", "OutputProcess");
}

void OutputProcess(File selection) {
  if (selection == null) {
    OutputPath = "None Chosen";
  } else {
    OutputPath = selection.getAbsolutePath();
  }

}

public void Run() {
  
  
  String ArduinoFileName = cp5.get(Textfield.class,"ArduinoName").getText();
  String thePattern = "[^A-Za-z0-9]+";
  String [] m = match(ArduinoFileName, thePattern);
  
  println("Found: " + m);
  if (m != null) {
    Status = "NOT A VALID ARDUINO NAME";
  } else {
    try {
      Status = "Running";
      
      //resize screen to fit 16x16 gifs so processing can read into array 
      //and translate into Arduino sketch
      size(WIDTH,HEIGHT);
      animation = Gif.getPImages(this, GIFPath);
      try {
        
        output = createWriter(OutputPath+"/"+ArduinoFileName+"/"+ArduinoFileName + ".ino");
        WriteHeader();
            
        for (int i = 0; i < animation.length; i++) {
          WriteFile(animation[i], i, ArduinoFileName);
        }
        
        WriteBody();
        WriteLoopFile(animation.length, ArduinoFileName);
        
        output.flush();
        output.close();
        
        //retore the screen size
        size(550, 650);
        Status = "File Conversion Complete";
      } catch (Exception e) {
        
        //restore the screen size
        size(550, 650);
        e.printStackTrace();
        Status = "THIS IS NOT A VALID GIF!";
        GIFPath = "Choose new file";
      }
        
    } catch (Exception e) {
      size(550, 650);
      Status = "NOT A VALID GIF FILE!";
      GIFPath = "Choose new file";
    }
  } 

}

void Exit() {
  exit();
}

// Functions to Write Arduino Sketch
void WriteHeader() {
  //output.println("#include <avr/pgmspace.h>");
  output.println("#include <Adafruit_GFX.h>");
  output.println("#include <Adafruit_NeoMatrix.h>");
  output.println("#include <Adafruit_NeoPixel.h>");
  output.println("#include <Metro.h>");
  output.println("#ifndef PSTR");
  output.println("  #define PSTR"); // Make Arduino Due happy
  output.println("#endif");
  
  output.println("#define PIN 6");
  
  output.println("Adafruit_NeoMatrix matrix = Adafruit_NeoMatrix("+WIDTH+","+HEIGHT+", PIN, NEO_MATRIX_TOP + NEO_MATRIX_LEFT + NEO_MATRIX_COLUMNS + NEO_MATRIX_ZIGZAG, NEO_GRB + NEO_KHZ800);");
  


}
void WriteBody() {
  output.println("Metro AnimateTimer = Metro(72);");
  output.println("byte FrameNumber = 0;");
  output.println("void setup() {");
  output.println("  Serial.begin(115200);");
  output.println("  matrix.begin();");
  output.println("  matrix.setBrightness(40);");
  output.println("  matrix.fillScreen(0);");
  output.println("  matrix.show();");
  output.println("  delay(100);");
  //output.println("  AnimateTimer.setInterval(100, TimerEvent);");
  output.println("}");
  output.println("void loop() {");
  //output.println("  AnimateTimer.run();");
  output.println("  if (AnimateTimer.check() == 1) {");
  output.println("    TimerEvent();");
  output.println("  }");
  //output.println("  matrix.show();");
  output.println("}");
  output.println("uint16_t drawRGB24toRGB565(byte r, byte g, byte b) {");
  output.println("  return ((r / 8) << 11) | ((g / 4) << 5) | (b / 8);");
  output.println("}");
 
  
}

void WriteLoopFile(int NumberOfFrames, String VarName) {
  int NextFrame;
  output.println("void TimerEvent() {");
  
  for (int i = 0; i < NumberOfFrames; i++) {
    if (i == 0) output.println("  if (FrameNumber == " + i + ") {");
    else output.println("   else if (FrameNumber == " + i + ") {");
    
    output.println("      for (byte y = 0; y < "+HEIGHT+"; y++) {");
    output.println("        for (byte x = 0; x < "+WIDTH+"; x++) {");
    output.println("          byte loc = x + y*"+WIDTH+";");
    output.println("          matrix.drawPixel(x, y, drawRGB24toRGB565(("+ VarName + "RedFrame" + i + "[loc]), (" + VarName + "GreenFrame" + i + "[loc]), (" + VarName + "BlueFrame" + i + "[loc])));"); 
    output.println("        }");
    output.println("      }");
    
    if (i == NumberOfFrames - 1) output.println("      FrameNumber = 0;");
    else { 
      NextFrame = i + 1;
      output.println("      FrameNumber = " + NextFrame + ";");
      output.println("      Serial.println(\" Frame " + i + " completed\");");
    }
    output.println("  }");
  }
  output.println("  matrix.show();");
  output.println("}");
}
    
void WriteFile(PImage img, int FrameNumber, String VarName) {
  //img = loadImage(ImageFileName);
  img.loadPixels(); 
  output.print("const unsigned char " + VarName + "RedFrame" + FrameNumber + "["+WIDTH+"*"+HEIGHT+"] = ");
  output.print("{");
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int loc = x + y*width;
      
      // The functions red(), green(), and blue() pull out the 3 color components from a pixel.
      int r = int(red(img.pixels[loc]));
      if (loc < 255) output.print(r+",");
      else output.print(r);
     
    }
  }
  
  output.println("};");
  output.print("const unsigned char " + VarName + "GreenFrame" + FrameNumber + "["+WIDTH+"*"+HEIGHT+"] = ");
  output.print("{");
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int loc = x + y*width;
      
      // The functions red(), green(), and blue() pull out the 3 color components from a pixel.
      int g = int(green(img.pixels[loc]));
      if (loc < 255) output.print(g+",");
      else output.print(g);
     
    }
  }
  
  output.println("};");
  
  output.print("const unsigned char " + VarName + "BlueFrame" + FrameNumber + "["+WIDTH+"*"+HEIGHT+"] = ");
  output.print("{");
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int loc = x + y*width;
      
      // The functions red(), green(), and blue() pull out the 3 color components from a pixel.
      int b = int(blue(img.pixels[loc]));
      if (loc < 255) output.print(b+",");
      else output.print(b);
     
    }
  }
  
  output.println("};");


}

