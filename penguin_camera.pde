import gab.opencv.*;
import processing.video.*;
import java.awt.*;

Capture video;
OpenCV opencv;
PImage penguin_img;
PImage egg_img;

int screen_width = 640;
int screen_height = 500;

// Parameters for penguin simulation 
float step_size = 5.0;
float diam = 20;
int pop_size = 20;


int[] step = new int[8];

float radius = diam/2;
boolean overlapping = false;
ArrayList<PVector> directions = new ArrayList<PVector>();

Penguin[] population = new Penguin [pop_size];
 
void setup() {
  size(640, 500);
  background(255);
  frameRate(80);
  
  // Initalize video capture and face detection 
  video = new Capture (this, screen_width/2, screen_height/2);
  opencv = new OpenCV (this, screen_width/2, screen_height/2);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
  
  // Start the camera
  video.start();
  
  // Add directions to the list
  directions.add(new PVector(0, -1 * step_size)); // Top
  directions.add(new PVector(1 * step_size, 0));  // Right
  directions.add(new PVector(0, 1 * step_size));  // Bottom
  directions.add(new PVector(-1 * step_size, 0)); // Left
  directions.add(new PVector(1* step_size , -1 * step_size)); // Top Right
  directions.add(new PVector(1 * step_size, 1 * step_size));  // Bottom Right
  directions.add(new PVector(-1 * step_size, 1 * step_size)); // Bottom Left
  directions.add(new PVector(-1 * step_size, -1 * step_size));// Top Left
  penguin_img = loadImage("penguin.png");
  egg_img = loadImage("egg.png");

  // intalize the penguin population
  for (int i = 0; i < population.length; i++) {
    population[i] = new Penguin(0, 0);
  }
  
  // Initalise penguins without overlap
  for (int i = 0; i < population.length; i++) {
    int position[] = noOverlap(); // Get non-overlapping position
    population[i] = new Penguin(position[0], position[1]); // Create penguin at that position
    population[i].display();  // Display that penguin
  }
}

// Class representing a penguin
class Penguin {
  float xpos, ypos;
  // Array to store the trajectory of the penguin
  float[] trajectoryX = new float[1000]; 
  float[] trajectoryY = new float[1000]; 
  int trajectoryIndex = 0; // Index for storing the coordinates

  
  Penguin(float xpos, float ypos) {
    this.xpos = xpos;
    this.ypos = ypos;
  }
  
  // Function to calculate penguin movement
  void move(Rectangle[] faces) {
    float[] distances = new float[directions.size()];
    float distance_nose = 0;
    boolean noseDetected = false;

  //calculate distance to nose position
    if (faces.length > 0) {
      for (int i = 0; i < population.length; i++){
        if (population[i] != this){
          distance_nose = dist((faces[0].x + faces[0].width/2), (faces[0].y + faces[0].height/2), xpos, ypos);
        }
      }
    }

 
  // Calculate sum of distances to neighbors in each direction
  for (int i = 0; i < directions.size(); i++) {
    PVector dir = directions.get(i);
    float sum = 0;

    for (int j = 0; j < population.length; j++) {
        if (population[j] != this){
          float d = dist(xpos + dir.x, ypos + dir.y, population[j].xpos, population[j].ypos);
          sum += d;
          if (faces.length > 0) {
            noseDetected = true;
            distance_nose = dist((faces[0].x + faces[0].width/2), (faces[0].y + faces[0].height/2), xpos, ypos);
     
          }
        }
    }
    distances[i] = sum;
  }

  // Find the index of the direction with the minimum total distance sum
  int minIndex = 0;
  float minSum = distances[0];
  for (int i = 1; i < distances.length; i++) {
    if (distances[i] < minSum) {
      minSum = distances[i];
      minIndex = i;
    }
  }
  
    // Calculate the new position considering the combined influence of nose position and other penguins
  float weightFactor = 0.7; // Adjust this value to balance between nose position and penguin distances
  PVector moveDir = directions.get(minIndex);
  
  if (noseDetected){
    PVector towardsNose = new PVector(((faces[0].x + faces[0].width / 2) - xpos),((faces[0].y + faces[0].height / 2) - ypos)).normalize().mult(weightFactor);
    moveDir.add(towardsNose); // Add the direction towards the nose with weight
  }
  
  moveDir.normalize().mult(step_size); // Ensure constant step size

  // Calculate the new position with the lowest total distance sum
  //PVector moveDir = directions.get(minIndex);
  float newX = xpos + moveDir.x;
  float newY = ypos + moveDir.y;

  // Check if the new position is occupied by another penguin
  boolean occupied = false;
  for (int i = 0; i < population.length; i++) {
    if (population[i] != this && population[i].xpos == newX && population[i].ypos == newY) {
      occupied = true;
      break;
    }
  }

  // If the new position is occupied, push the other penguin to a random direction
  if (occupied) {
    int randomDirectionIndex = int(random(directions.size()));
    PVector pushDir = directions.get(randomDirectionIndex);
    float pushX = newX - pushDir.x;
    float pushY = newY - pushDir.y;

    // Check if the pushed position is unoccupied
    boolean unoccupied = true;
    for (int i = 0; i < population.length; i++) {
      if (population[i] != this && population[i].xpos == pushX && population[i].ypos == pushY) {
        unoccupied = false;
        break;
      }
    }

    // Update the position of the pushed penguin if it is unoccupied
    if (unoccupied) {
      for (int i = 0; i < population.length; i++) {
        if (population[i] != this && population[i].xpos == newX && population[i].ypos == newY) {
          population[i].xpos = pushX;
          population[i].ypos = pushY;
          break;
        }
      }
    }
  }

  // Update the position of the current penguin
  xpos = newX;
  ypos = newY;
  
  // Store the current position in the trajectory arrays
  trajectoryX[trajectoryIndex] = xpos;
  trajectoryY[trajectoryIndex] = ypos;
  trajectoryIndex++;
  }

  
  void display() {
      fill(0, 255, 255, 0);
      stroke(0,255,255, 0);
      circle(xpos, ypos, diam);
      imageMode(CENTER);
      image(penguin_img, xpos, ypos, width/45, height/45);
    
      
    //// Uncomment this function to draw the trajectory line
    //  noFill();
    //  beginShape();
    //  for (int i = 0; i < trajectoryIndex; i++) {
    //    vertex(trajectoryX[i], trajectoryY[i]);
    //  }
    //  endShape();
  } 
}

void draw() {
  scale(2);
  opencv.loadImage(video);
  imageMode(CORNER);
  image(video, 0, 0);
  
  noFill();
  stroke(0, 255, 0);
  strokeWeight(2);
  
  // Detect faces in the video feed
  Rectangle[] faces = opencv.detect();
  
  // Draws a egg in the middle of the face (nose)
  stroke(255, 0, 0);
  for (int i = 0; i < faces.length; i++) {;
   imageMode(CENTER);
   image(egg_img, (faces[i].x + faces[i].width/2), (faces[i].y + faces[i].height/2), width/45, height/30);
  }

  // Move a randomly chosen penguin and display all the penguins
  Penguin currentPenguin = population[int(random(population.length))];
  currentPenguin.move(faces);
  
  // Display all penguins
  for (Penguin penguin : population) {
    penguin.display();
  }
}

// Function that creates random positions until there is no overlap
int[] noOverlap () {
  boolean overlap = false;
  int[] coordinates = new int[2];

 // Loop until a non-overlapping position is found
  while (!overlap) {
    coordinates[0] = int(random(radius, width/2 - radius));
    coordinates[1] = int(random(radius, height/2 - radius));
    // call function to check on overlap
    overlap = check_overlap(coordinates[0], coordinates[1]);
  }
  return coordinates;
}

// Function to check for overlap with existing penguins
Boolean check_overlap (float x_check, float y_check) {
  // loops through exisiting penguin objects
  for (int i=0; i < population.length; i++) {
  
    // calculates if there is overlap
    float distance = dist(x_check, y_check, population[i].xpos, population[i].ypos);
    float minDistance = radius * 2;
    // if there is an overlap set to true
    if (distance > minDistance) {
      overlapping = true;
      return true;
    } 
  }
  return false;
}

// Function to handle capture events
void captureEvent(Capture c) {
  c.read();
}
