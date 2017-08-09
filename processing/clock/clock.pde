/**
 * Telepulssi template for Processing.
 */

import java.util.*;
import java.text.*;

Telepulssi telepulssi;
final static DateFormat fmt = new SimpleDateFormat("HHmmss");
PImage logo;

public void settings() {
  // Telepulssi screen resolution is 40x7
  size(40, 7);
}

void setup() {  
  // First set up your stuff.
  noStroke();
  PFont font = loadFont("Ubuntu-10.vlw");
  textFont(font);
  logo = loadImage("logo.png");

  // Initialize real Telepulssi, emulated one, or both. Pick the on you like to use
  telepulssi = new Telepulssi(this, true, "/dev/ttyACM0"); // Preview and real hardware
  //telepulssi = new Telepulssi(this, true, null); // Preview only
  //telepulssi = new Telepulssi(this, false, "/dev/ttyACM0"); // Real hardware only

  // Hide the original window
  surface.setVisible(false);
}

void draw() {
  // Clear screen
  background(0);
  fill(255);

  // Angle function which pauses for a moment at zero. Used for pausing to clock position.
  final float phaseShift = 1.1;
  final float speed = 0.0001;
  final int pause = 40;
  float angle = 2*PI*pow(sin((speed*millis()) % (PI/2)), pause) + phaseShift;

  float y = -0.5*(sin(-angle)+1)*(logo.height-height);
  float x = -0.5*(cos(angle)+1)*(logo.width-width);

  // Rotate the whole thing
  translate((int)x,(int)y);
  
  // Draw clock in some coordinates in the logo
  pushMatrix();
  translate(16, 0);
  drawClock();
  popMatrix();

  drawLogo();

  // Finally update the screen and preview.
  telepulssi.update();
}

void drawLogo() {
  image(logo, 0, 0);
}

void drawClock() {
  long ts = System.currentTimeMillis();
  String now = fmt.format(new Date(ts));
  String next = fmt.format(new Date(ts+1000));
  double phase = (double)(ts % 1000) / 1000;

  // Draw actual digits
  drawDigit(now, next, phase, 0, 0);
  drawDigit(now, next, phase, 1, 6);
  drawDigit(now, next, phase, 2, 14);
  drawDigit(now, next, phase, 3, 20);
  drawDigit(now, next, phase, 4, 28);
  drawDigit(now, next, phase, 5, 34);

  // Blinking digits
  if ((int)(ts/1000) % 2 == 0) {
    text(':', 12, 6);
    text(':', 26, 6);
  }

  // Draw nice gradient to rolling numbers
  fill(0,70);
  rect(0, 7, 40, 2);
  fill(0);
  rect(0, 9, 40, 5);
}

void drawDigit(String a, String b, double phase, int i, int pos) {
  int ya, yb;
  if (a.charAt(i) == b.charAt(i)) {
    // Position static
    ya = 7;
  } else {
    // Use textPhase which stops for a moment
    double textPhase = phase < 0.5 ? 0 : (phase-0.5)*2;
    ya = (int)(-textPhase*8)+7;
  }
  yb = ya+8;

  text(a.charAt(i), pos, ya);
  if (yb < 14) {
    println(yb);
    // Draw next digit only if visible
    text(b.charAt(i), pos, yb);
  }
}