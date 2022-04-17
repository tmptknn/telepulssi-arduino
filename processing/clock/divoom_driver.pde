import processing.net.*;
import java.nio.ByteBuffer;



public class Divoom extends PApplet {
  private PApplet source;
  Client myClient; 
  ByteBuffer out = ByteBuffer.allocateDirect(3*16*16);
  boolean socket_ready = false;
  Integer mPort = null;
  
  Divoom(PApplet source, boolean preview, Integer port) {
    super();
    this.source = source;
    if (preview) {
      // We want to preview
      PApplet.runSketch(new String[] {this.getClass().getSimpleName()}, this);
    }
   mPort = port;
   connect();
   
    
    // Serial traffic distorts the PWM so we don't want to do it too often.
    source.frameRate(18);
    if (preview) frameRate(18);
  }

  void settings() {
    size(800,900);
  }

  void setup() {
    noStroke();
    source.loadPixels();
  }
  
  void connect(){
    if(mPort != null) {
     myClient = new Client(this, "127.0.0.1", mPort); 
     if(myClient != null && myClient.active())  {
       socket_ready = true;
     }
   }
  }

  void draw() {
    // Do not load pixel array, done in updateTelepulssi()
    background(0);
    
    // Calculate proper preview size
    int scaling = min(width/source.width, height/source.height);
    
    // Draw round preview pixels
    for (int y=0; y<source.height; y++) {
      for (int x=0; x<source.width; x++) {
        fill(source.pixels[source.width*y+x]>>16 & 0xff, (source.pixels[source.width*y+x]>>8) & 0xff, (source.pixels[source.width*y+x]) & 0xff, 255);
        square(scaling*(0.5+x), scaling*(0.5+y), 0.95*scaling);
      }
    }
  }

  // Update explicitly
  public void update() {
    // Update pixel buffer and preview
    source.loadPixels();
    if(!myClient.active()) connect();
    if (!socket_ready) return;
    
    // Prepare data
    out.position(0);
    for (int y=0; y<16; y++) {
      for (int x=0; x<16; x++) {
        int i = source.width*y+x;
        int offset = (x+y*16);
        byte br = byte(source.pixels[offset]>>16& 0xff);
        out.put(br);
        byte bg = byte((source.pixels[offset]>>8)& 0xff);
        out.put(bg);
        byte bb = byte((source.pixels[offset])& 0xff);
        out.put(bb);
      }
    }
  
    // Extract array and write to serial port.
    byte buf[] = new byte[out.position()];
    out.rewind();
    out.get(buf);
    if(myClient != null && myClient.active()){
      myClient.write(buf);
      //String test = myClient.readString();
      //System.out.println(test);
    }
  }

}
