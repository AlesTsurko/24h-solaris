import oscP5.*;
import netP5.*;
import processing.video.*;

Movie solaris;
Movie solZOut;
Movie solZIn;
OscP5 oscP5;
NetAddress netAdress;
int videoWidth = 484; // должно быть равно ширине видео
int videoHeight = 212; // должно быть равно высоте видео
int jumpCounter = 0; // считает, когда нужно запустить новый кадр
float speed = 0.12; // скорость воспроизведения
int fps = 25; // частота кадров
int frameDelay = 4;
int jumpNum = fps * frameDelay;
int blockSize = 60; // размер блока пикселизации
color movColors[];

int multipleWide = int(round(videoWidth / blockSize));
int multipleHeight = int(round(videoHeight / blockSize));

void setup() {
  size(blockSize * multipleWide * 2, 
  blockSize * multipleHeight * 3);

  frameRate(fps);

  noStroke();
  
  frame.setTitle("24h Solaris");

  solaris = new Movie(this, "SolarisSD.mov");
  solaris.frameRate(25.0);
  solaris.loop();
  solaris.read();
  solaris.speed(speed);

  solZOut = new Movie(this, "SolarisSDZOut.mov");
  solZOut.loop();
  solZOut.read();
  solZOut.speed(speed);
  
  solZIn = new Movie(this, "SolarisSDZIn.mov");
  solZIn.loop();
  solZIn.read();
  solZIn.speed(speed);

  // открывает порт отправки OSC-сообщений
  oscP5 = new OscP5(this, 5001);
  netAdress = new NetAddress("127.0.0.1", 5001);

  int pixelsNum = multipleWide * multipleHeight;

  OscMessage oscPixelsNum = new OscMessage("/pixelsnum");
  OscMessage oscFrameDelay = new OscMessage("/framedelay");

  oscPixelsNum.add(pixelsNum);
  oscFrameDelay.add(frameDelay);

  oscP5.send(oscPixelsNum, netAdress);
  oscP5.send(oscFrameDelay, netAdress);

  movColors = new color[pixelsNum];
}

int frameRedSum = 0;
int frameGreenSum = 0;
int frameBlueSum = 0;
int redAverage = 0;
int greenAverage = 0;
int blueAverage = 0;

void movieEvent(Movie m) {
  if (m != solaris) {
    m.read();
  }
}

void draw() {
  image(solZOut, 0, height/3, width/2, height/3);  
  image(solZIn, width/2, height/3, width/2, height/3);
  if (solaris.available()) {
    jumpCounter++;

    // получение ключевого кадра и его обработка
    if (jumpCounter == 1) {
      solaris.read();
      solaris.loadPixels();
      int count = 0;
      for (int h = 0; h < multipleHeight; h++) {
        for (int w = 0; w < multipleWide; w++) {
          movColors[count] = solaris.get(w*blockSize, h*blockSize);

          // посылает все пиксели кадра
          int redEach = (movColors[count] >> 16) & 0xFF;
          int greenEach = (movColors[count] >> 8) & 0xFF;
          int blueEach = movColors[count] & 0xFF;

          OscMessage sendRedPixels = new OscMessage("/redpixels");
          OscMessage sendGreenPixels = new OscMessage("/greenpixels");
          OscMessage sendBluePixels = new OscMessage("/bluepixels");

          sendRedPixels.add(redEach);
          sendGreenPixels.add(greenEach);
          sendBluePixels.add(blueEach);

          oscP5.send(sendRedPixels, netAdress);
          oscP5.send(sendGreenPixels, netAdress);
          oscP5.send(sendBluePixels, netAdress);

          // расчет среднего значения цвета кадра
          frameRedSum = frameRedSum + redEach;
          frameGreenSum = frameGreenSum + greenEach;
          frameBlueSum = frameBlueSum + blueEach;

          redAverage = round(
          frameRedSum /
          (multipleWide * multipleHeight)
            );

          greenAverage = round(
          frameGreenSum /
          (multipleWide * multipleHeight)
            );

          blueAverage = round(
          frameBlueSum /
          (multipleWide * multipleHeight)
            );

          count++;
        }
      }
    }

    // единожды за кадр посылает среднее значение
    if (jumpCounter == 1) {

      fill(redAverage, greenAverage, blueAverage);
      noStroke();
      rect(0, 0, 
      blockSize * multipleWide * 2, 
      blockSize * multipleHeight);
      smooth();

      // отправка OSC-сообщений о среднем значении R, G, B кадра
      OscMessage newFrame = new OscMessage("/newframe");
      OscMessage sendRedAverage = new OscMessage("/redaverage");
      OscMessage sendGreenAverage = new OscMessage("/greenaverage");
      OscMessage sendBlueAverage = new OscMessage("/blueaverage");

      sendRedAverage.add(redAverage);
      sendGreenAverage.add(greenAverage);
      sendBlueAverage.add(blueAverage);

      oscP5.send(newFrame, netAdress);
      oscP5.send(sendRedAverage, netAdress);
      oscP5.send(sendGreenAverage, netAdress);
      oscP5.send(sendBlueAverage, netAdress);

      // pixelation colorisation
      for (int j = 0; j < multipleHeight; j++) {
        for (int i = 0; i < multipleWide; i++) {
          fill(movColors[j*multipleWide + i]);
          noStroke();
          rect(i*blockSize*2, j*blockSize + (height/3*2), blockSize*2, blockSize);
        }
      }
    }

    if (jumpCounter == jumpNum) {
      jumpCounter = 0;
      frameRedSum = 0;
      frameGreenSum = 0;
      frameBlueSum = 0;
      redAverage = 0;
      greenAverage = 0;
      blueAverage = 0;
    }
  }
}
