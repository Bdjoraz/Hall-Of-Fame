import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
// Variables
Minim minim;
AudioPlayer track;
FFT fft;

// Configuration
int canvasWidth = 1080;
int canvasHeight = 1080;

// Change song name here!!
String audioFileName = "song.mp3"; 

float incrementalAngle = 0.0;

//zonas do espetro
float specLow = 0.03; // 3%
float specMid = 0.125;  // 12.5%
float specHi = 0.20;   // 20%

float scoreLow = 0;
float scoreMid = 0;
float scoreHi = 0;

float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
float oldScoreHi = scoreHi;

float scoreDecreaseRate = 300;

int numCubes = 1200;
int numCubesPerRow = 50;
Cube[] cubes;
Ball center;

class Ball {
  float minZ = 0;
  float maxZ = 10;
  float gravity = 0.1;
  float startingZ = 1;
  float _x, _y, _z;
  
  Ball(float x, float y) {
    _x = x;
    _y = y;
    _z = 0;
  }
  
  void shape(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    color shapeColor = color(scoreLow*0.55, scoreMid*0.55, scoreHi*0.55, intensity/3); 
    fill(shapeColor, 255);
    
    color strokeColor = color(150, 150-(25*intensity));
    stroke(strokeColor);
    strokeWeight(0.5 + (scoreGlobal/300));
    
    pushMatrix();

    translate(_x, _y, _z);
    
    sphere(20+(intensity/30));
    
    popMatrix();
    _z += intensity/5;
    if (_z > 20) {
      _z -= _z/5;
    }
  }
}
class Cube {
  float minZ = 0;
  float maxZ = 10;
  float gravity = 0.1;
  
  float _x, _y, _z, startingZ;
  float rotX, rotY, rotZ;
  float sumRotX, sumRotY, sumRotZ;
  
  Cube(float x, float y) {
    _x = x;
    _y = y;
    rotX = random(0, 1);
    rotY = random(0, 1);
    rotZ = random(0, 1);
    startingZ = 1;
  }
  
  void shape(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    color shapeColor = color(scoreLow*0.55, scoreMid*0.55, scoreHi*0.55, intensity*2); 
    fill(shapeColor, 255);
    
    color strokeColor = color(150, intensity/2);
    stroke(strokeColor);
    strokeWeight(1 + (scoreGlobal/500));
    
    pushMatrix();

    translate(_x, _y, _z);
    
    sumRotX += scoreGlobal*(rotX/5000);
    sumRotY += scoreGlobal*(rotY/5000);
    sumRotZ += scoreGlobal*(rotZ/5000);
    
    rotateX(sumRotX);
    rotateY(sumRotY);
    rotateZ(sumRotZ);
    
    box(15+(intensity/30));
    
    _z += intensity;
    if (_z > 20) {
      _z -= _z/8;
    }
    popMatrix();

  }
}
void settings() {
  size(canvasWidth, canvasHeight, P3D);
}

void setup() {
  
  minim = new Minim(this);
  
  track = minim.loadFile(audioFileName);
  
  //FFT for analysis
  fft = new FFT(track.bufferSize(), track.sampleRate());
  
  //Initiate ellipses
  cubes = new Cube[numCubes];
  center = new Ball(width/2, height/2);
  for (int row = 25; row < 350; row += 25) {
    for(int i = 0; i < numCubesPerRow ; i++){
      if (row > 0) {
        float x = row * cos(incrementalAngle) + width/2;
        float y = row * sin(incrementalAngle) + height/2;
        cubes[row + i] = new Cube(x, y);
        incrementalAngle += TWO_PI / (numCubes / 50);
      }
    }
  }
  track.play(0);
}

void draw() {
    
    fft.forward( track.mix );
    

    oldScoreLow = scoreLow;
    oldScoreMid = scoreMid;
    oldScoreHi = scoreHi;
    
    scoreLow = 0;
    scoreMid = 0;
    scoreHi = 0;
    

    for(int i = 0; i < fft.specSize()*specLow; i++)
    {
      scoreLow += fft.getBand(i);
    }
    
    for(int i = (int)(fft.specSize()*specLow); i < fft.specSize()*specMid; i++)
    {
      scoreMid += fft.getBand(i);
    }
    
    for(int i = (int)(fft.specSize()*specMid); i < fft.specSize()*specHi; i++)
    {
      scoreHi += fft.getBand(i);
    }
    
    if (oldScoreLow > scoreLow) {
      scoreLow = oldScoreLow - scoreDecreaseRate;
    }
    
    if (oldScoreMid > scoreMid) {
      scoreMid = oldScoreMid - scoreDecreaseRate;
    }
    
    if (oldScoreHi > scoreHi) {
      scoreHi = oldScoreHi - scoreDecreaseRate;
    }
    
    float scoreGlobal = 0.66*scoreLow + 0.8*scoreMid + 1*scoreHi;
    background(scoreLow/250, scoreMid/250, scoreHi/250);
    visualize(scoreGlobal);
}

void visualize(float scoreGlobal) {
  for (int row = 0; row < 350; row += 25) {
    for(int i = 25; i < numCubesPerRow ; i++){
      if (row > 100) {
        float bandValue = fft.getBand((int)map(100, 300, 101, 300, row));
        cubes[row + i].shape(scoreLow, scoreMid, scoreHi, bandValue, scoreGlobal);
      } else if (row == 0) {
        float bandValue = fft.getBand(1);
        center.shape(scoreLow, scoreMid, scoreHi, bandValue, scoreGlobal);
        break;
      } else {
        float bandValue = fft.getBand((int)map(1, 20, 0, 100, row));
        cubes[row + i].shape(scoreLow, scoreMid, scoreHi, bandValue, scoreGlobal);
      }
    }
  }
}
