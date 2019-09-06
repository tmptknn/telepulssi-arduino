/*
Requires https://github.com/tmptknn/puck.git
to work currently branch there is kellopeli
also you need to change websocket ip in this file
*/

import processing.dxf.*;
    
import websockets.*;
import org.eclipse.jetty.websocket.api.Session;

import java.lang.reflect.Method;
import java.net.URI;
import org.eclipse.jetty.websocket.client.ClientUpgradeRequest;
import org.eclipse.jetty.websocket.client.WebSocketClient;
import processing.core.PApplet;
import java.util.concurrent.CountDownLatch;
import org.eclipse.jetty.websocket.api.annotations.WebSocket;
import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketConnect;
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketError;
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketMessage;

boolean notConnected = true;

@WebSocket
public class WebsocketClientEvents2 {
  private Session session;
  CountDownLatch latch = new CountDownLatch(1);
  private PApplet parent;
  private Method onMessageEvent;
  private Method onMessageEventBinary;

  public WebsocketClientEvents2(PApplet p, Method event, Method eventBinary) {
    parent = p;
    onMessageEvent = event;
    onMessageEventBinary = eventBinary;
  }

  /**
   * 
   * Sending incoming messages to the Processing sketch's websocket event function 
   * 
   * @param session The connection between server and client
   * @param message The received message
   * @throws IOException If no event fonction is registered in the Processing sketch then an exception is thrown, but it will be ignored
   */
  @OnWebSocketMessage
  public void onText(Session session, String message) throws IOException {
    if (onMessageEvent != null) {
      try {
        onMessageEvent.invoke(parent, message);
      } catch (Exception e) {
        System.err
            .println("Disabling webSocketEvent() because of an error.");
        e.printStackTrace();
        onMessageEvent = null;
      }
    }
  }

  @OnWebSocketMessage
  public void onBinary(Session session, byte[] buf, int offset, int length) throws IOException {
    if (onMessageEventBinary != null) {
      try {
        onMessageEventBinary.invoke(parent, buf, offset, length);
      } catch (Exception e) {
        System.err
            .println("Disabling webSocketEvent() because of an error.");
        e.printStackTrace();
        onMessageEventBinary = null;
      }
    }
  }

  /**
   * 
   * Handling establishment of the connection
   * 
   * @param session The connection between server and client
   */
  @OnWebSocketConnect
  public void onConnect(Session session) {
    this.session = session;
    latch.countDown();
  }

  /**
   * 
   * Sends message to the websocket server
   * 
   * @param str The message to send to the server
   */
  public void sendMessage(String str) {
    try {
      session.getRemote().sendString(str);
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  public void sendMessage(byte[] data) {
    try {
      ByteBuffer buf = ByteBuffer.wrap(data);
      session.getRemote().sendBytes(buf);
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  /**
   * 
   * Handles errors occurring and writing them to the console 
   * 
   * @param cause The cause of an error
   */
  @OnWebSocketError
  public void onError(Throwable cause) {
    System.out.printf("onError(%s: %s)%n",cause.getClass().getSimpleName(), cause.getMessage());
    //cause.printStackTrace(System.out);
    
      println("here we are?");
      notConnected = true;
      getLatch().countDown();
  }

  public CountDownLatch getLatch() {
    return latch;
  }
}

public class WebsocketClient2 {
  private Method webSocketEvent;
  private Method webSocketEventBinary;
  private WebsocketClientEvents2 socket;
  
  /**
   * 
   * Initiating the client connection
   * 
   * @param parent The PApplet object coming from Processing
   * @param endpointURI The URI to connect to Ex. ws://localhost:8025/john
   */
  public WebsocketClient2(PApplet parent, String endpointURI) {
    parent.registerMethod("dispose", this);
    
    try {
          webSocketEvent = parent.getClass().getMethod("webSocketEvent", String.class);
          webSocketEventBinary = parent.getClass().getMethod("webSocketEvent", byte[].class, int.class, int.class);
        } catch (Exception e) {
          // no such method, or an error.. which is fine, just ignore
        }
    
    WebSocketClient client = new WebSocketClient();
    try {
      socket = new WebsocketClientEvents2(parent, webSocketEvent, webSocketEventBinary);
      client.start();
      URI echoUri = new URI(endpointURI);
      ClientUpgradeRequest request = new ClientUpgradeRequest();
      client.connect(socket, echoUri, request);
      socket.getLatch().await();

    } catch (Exception e) {
      //t.printStackTrace();
    }
  }
  
  /**
   * 
   * Send message to the websocket server. At a later stage it should be possible to send messages to specific clients connected to the same server
   * 
   * @param message The message to send
   */
  public void sendMessage(String message){
    socket.sendMessage(message);
  }

  public void sendMessage(byte[] data){
    socket.sendMessage(data);
  }
  
  public void dispose(){
    // Anything in here will be called automatically when 
      // the parent sketch shuts down. For instance, this might
      // shut down a thread used by this library.
  }
}


WebsocketClient2 wsc;

/**
 * Telepulssi template for Processing.
 */

import java.util.*;
import java.net.*;
import java.io.*;

import java.text.*;

Telepulssi telepulssi;
final static DateFormat timeFmt = new SimpleDateFormat("HHmmss");
final static DateFormat dayFmt = new SimpleDateFormat("E d.M.y");
PImage logo;
PImage degree;
String tempString = "N/A";
boolean noTemp = true;
Timer timer;
Timer websocketTimer;
boolean gameOn=false;

int myId = -1;

public class GameObject{
   public int id = -1;
   public float x=-1.0f,y=-1.0f,size=0.0f;
   public color c;
   public GameObject(int id,float size,float x,float y,color c){
     this.id =id;
     this.size =size;
     this.x = x;
     this.y = y;
     this.c = c;
   }
}

int maxclients =4;

GameObject objects[] = new GameObject[maxclients+1];
int team0Score =0,team1Score =0;

public void settings() {
  // Telepulssi screen resolution is 40x7
  size(40, 7);
}

void setup() {  
  
  for(int i=0; i< maxclients; i++){
    objects[i] = new GameObject(i,50f,-1280f/2.0f,768.0f/2.0f,(i%2==0)?color(255,0,0):color(255,0,0));
  }
  objects[maxclients] = new GameObject(maxclients,25f,-400f,300f,color(255,255,255) );
  
  // First set up your stuff.
  noStroke();
   TimerTask repeatedTask = new TimerTask() {
        public void run() {
            fetchTemperaturePage();
        }
    };
    timer = new Timer("Timer");
     
    long delay  = 5000L;
    long period = 600000L;
    timer.scheduleAtFixedRate(repeatedTask, delay, period);
  PFont font = loadFont("Ubuntu-Medium-10.vlw");
  textFont(font);
  logo = loadImage("logo.png");
  degree = loadImage("degree.png");

   TimerTask repeatedWebsocketTask = new TimerTask() {
        public void run() {
            openSocket();
        }
    };
    websocketTimer = new Timer("WebsocketTimer");
     
    long delayws  = 60000L;
    long periodws = 60000L;
    websocketTimer.scheduleAtFixedRate(repeatedWebsocketTask, delayws, periodws);

  // If you supply serial port from command-line, use that. Emulate otherwise.
  String port = args == null ? null : args[0];
  telepulssi = new Telepulssi(this, port == null, port); // Preview only
  
  // Hide the original window
  surface.setVisible(false);
}

void openSocket(){
  try{
    wsc= new WebsocketClient2(this, "ws://192.168.1.108:57331");
  }catch(Exception e){
    println("Failed to open socket"); 
  }
}

void drawGame(){
  for(int i=0; i<=maxclients; i++){
    GameObject g=objects[i];
    ellipse(g.x*20.0f/1280.0f,g.y*7.0f/768.0f,g.size*20.0/1280.0f,g.size*20.0/1280.0f);
  }
  
  text(Integer.toString(team0Score)+":"+Integer.toString(team1Score),20,7);
}

void draw() {
  // Clear screen
  background(0);
  fill(255);

  if(gameOn){
    drawGame();
  }else{
  // Angle function which pauses for a moment at zero. Used for pausing to clock position.
  final float phaseShift = PI/2;
  final float speed = 0.0001;
  final int pause = 40;
  float angle = 2*PI*pow(sin((speed*millis()) % (PI/2)), pause) + phaseShift;
  float round = (speed * millis() / (PI/2) % 2) < 1 ? 1 : -1;

  float y = min(-0.5*(sin(-angle)+1)*(logo.height/2-height) * round, 10);
  float x = -0.5*(cos(angle)+1)*(logo.width/2-width);

  // Rotate the whole thing
  translate(x,y);
  
  // Draw clock in some coordinates in the logo
  pushMatrix();
  translate(15, 0);
  drawText();
  popMatrix();

  scale(0.5);
  drawLogo();
  }
  // Finally update the screen and preview.
  telepulssi.update();
}

void drawLogo() {
  image(logo, 0, 0);
}


void drawTemperature() {
  text(tempString, 0, 7);
  image(degree,26,-1);
  text("C",31,7);
}

void drawText() {
  if((millis()/4000)%4==0 && !noTemp){
    drawTemperature();
  }else{
    drawClock();
  }
}

void drawClock() {
  long ts = System.currentTimeMillis();
  String now = format(ts);
  String next = format(ts+1000);
  float phase = (float)(ts % 1000) / 1000;

  // Draw actual digits
  drawDigit(now, next, phase, 0, 0);
  drawDigit(now, next, phase, 1, 6);
  drawDigit(now, next, phase, 2, 14);
  drawDigit(now, next, phase, 3, 20);
  drawDigit(now, next, phase, 4, 28);
  drawDigit(now, next, phase, 5, 34);

  // Blinking digits
  if (ts % 1000 < 500) {
    text(':', 11, 6);
    text(':', 25, 6);
  }

  // Draw nice gradient to rolling numbers
  fill(0);
  rect(0, 7.5, 40, 8);
  rect(0, -8.5, 40, 8);
  
  // Write weekday
  fill(255);
  text(dayFmt.format(new Date(ts)), -13, -3);
}

String format(long ts) {
  String s = timeFmt.format(new Date(ts));
  if ("133700".equals(s)) return "ELITE!";
  if ("140000".equals(s)) return "KAHVIA";
  return s;
}

void drawDigit(String a, String b, float phase, int i, float pos) {
  float textPhase;
  if (a.charAt(i) == b.charAt(i)) {
    // Position static
    textPhase = 0;
  } else {
    // Use textPhase which stops for a moment
    textPhase = phase < 0.5 ? 0 : (phase-0.5)*2;
  }

  pushMatrix();
  translate(pos, -textPhase*8);
  text(a.charAt(i), 0, 7);
  text(b.charAt(i), 0, 15);
  popMatrix();
}

void fetchTemperaturePage(){
  String content = null;
  URLConnection connection = null;
  try {
    connection =  new URL("http://weather.jyu.fi").openConnection();
    Scanner scanner = new Scanner(connection.getInputStream());
    scanner.useDelimiter("\\Z");
    content = scanner.next();
    scanner.close();
  }catch ( Exception ex ) {
    // noconnection
    noTemp = true;
  }
  try{
    int indexOfTemp = content.indexOf("font-size:20px; strong")+25;
    tempString =content.substring(indexOfTemp,indexOfTemp+5);
    noTemp = false;
  }catch(Exception ex){
    noTemp = true;
  }
}

void move(int id,float size, float x,float y){
  objects[id].size = size;
  objects[id].x = x;
  objects[id].y = y;
}

void webSocketEvent(String msg){
  notConnected =false;
  String lines[] = msg.split(",");
  
  int id =-1;
  float x = -100.0f;
  float y = -100.0f;
  float size = 0.0f;
  
  for(int i=0; i< lines.length; i++){
    String pair[] = lines[i].split(":");
    String name = pair[0].split("\"")[1];
    String value = pair[1].split("}")[0];
    //println("name = "+name+" value = "+value);
    switch(name){
      case "yourId":
        myId =Integer.parseInt(value);
         //println("my id is "+myId);
        break;
      case "id":
        id = Integer.parseInt(value);
        break;
      case "x":
        x = Float.parseFloat(value);
        break;
      case "y":
        y = Float.parseFloat(value);
        break;
      case "size":
        size = Float.parseFloat(value);
        break;
      case "gameOn":
        int go = Integer.parseInt(value);
        gameOn =(go==1);
        break;
      case "team0Score":
        team0Score = Integer.parseInt(value);
        break;
      case "team1Score":
        team1Score = Integer.parseInt(value);
        break;
    } 
    if(id!=-1 &&id>=0 && id<=5){
      move(id,size,x,y);
    }
  }  
}
  
