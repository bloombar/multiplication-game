import processing.sound.*;


int w = 800;
int h = 600;
int framerate = 24;
SoundFile soundFileWelcome;
SoundFile soundFileSuccess;
SoundFile soundFileFailure;

PFont f;
float[] speed = {1.5, -1.5};
int[] bgColorStandard = {0, 0, 0};
int[] fgColorStandard = {255, 255, 255};
int[] bgColorInvert = {255, 255, 255};
int[] fgColorInvert = {0, 0, 0};
int[] bgColorSuccess = {0, 255, 0};
int[] fgColorSuccess = {0, 0, 0};
int[] bgColorFailure = {255, 125, 125};
int[] fgColorFailure = {0, 0, 0};
int[] bgColorInfo = {0, 0, 255};
int[] fgColorInfo = {255, 255, 255};

final int SPACE_KEY = 32;
final int ENTER_KEY = 10;
final int RIGHT_ARROW_KEY = 39;
final int LEFT_ARROW_KEY = 37;
final int UP_ARROW_KEY = 38;
final int DOWN_ARROW_KEY = 40;

int[][] numbers = {
  getSequence(0, 3, 1), // level 0 - numbers from 0-2
  getSequence(0, 4, 1), // level 1 - numbers from 0-3
  getSequence(1, 5, 1), // level 2
  getSequence(1, 6, 1), // level 3
  getSequence(2, 7, 1), // level 4
  getSequence(2, 8, 1), // level 5
  getSequence(2, 12, 1), // level 6
  getSequence(2, 13, 1), // level 7
  getSequence(2, 15, 1), // level 8
  getSequence(2, 17, 1), // level 9
  getSequence(11, 17, 1), // level 10
  getSequence(2, 26, 1), // level 11
  getSequence(11, 26, 1), // level 12
  getSequence(11, 126, 3), // level 13
  getSequence(12, 126, 3), // level 14
  getSequence(123, 2023, 1) // level 15
};

Level[] levels;
State state; // the current state of the game
Scoreboard scoreboard;
CheatSheet cheatSheet;

void settings() {
  size(w, h);
}

void setup() {
  // Create the font
  // printArray(PFont.list());
  // f = createFont("SourceCodePro-Regular.ttf", 24);
  // textFont(f);
  textAlign(CENTER, CENTER);

  // prepare sounds
  soundFileWelcome = new SoundFile(this, "vibraphon.aiff");
  soundFileSuccess = null; //new SoundFile(this, "Glass.aiff");
  soundFileFailure = null; //new SoundFile(this, "Basso.aiff");
  //System.out.println(soundfile.duration());
  
  frameRate(framerate); //  24 frames per second
  background(bgColorStandard[0], bgColorStandard[1], bgColorStandard[2]);
  
  levels = new Level[numbers.length];
  for (int i=0; i<numbers.length; i++) {
    //int numQuestions = (int) Math.pow(numbers[i].length, 3); // how many questions to ask at this level - cube the number of numbers in this level
    int numQuestions = numbers[i].length * 2;
    int numCorrectRequired = (int) (numQuestions * 3 / 4); // how many must be answered correctly in order to pass this level - 3/4
    int numOperands = 2; // how many numbers to multiply together.... 2 for now
    levels[i] = new Level(this, numbers[i], numOperands, numQuestions, numCorrectRequired); // create a new level
  }

  // set the initial state of the game
  int currentLevelIndex = 1;
  Level currentLevel = levels[currentLevelIndex];
  String[] subtexts = {
    "For each question, type your answer and press ENTER.", 
    "- SPACE bar to see a cheat sheet -",
    "- LEFT or RIGHT arrows to skip levels -",
    "- UP or DOWN arrows to adjust speed -",
  };
  Interstitial currentInterstitial = new Interstitial(this, 8, "WELCOME TO MULTIPLICATION LEVEL " + currentLevelIndex, subtexts, fgColorInvert, bgColorInvert, soundFileWelcome);
  CheatSheet cheatSheet = new CheatSheet(this, fgColorInvert, bgColorInvert);
  String currentMode = "level_start";
  
  state = new State(levels, currentLevel, currentLevelIndex, currentInterstitial, "", currentMode, cheatSheet);

  scoreboard = new Scoreboard(this, fgColorInvert, bgColorInvert);
}

void draw() {

  // handle any interestitial screen currently showing
  if (state.interstitial != null) {
    state.interstitial.frameCounter++;
    // time out the interstitial screens after the specified number of seconds
    if (state.interstitial.isTimedOut()) {
      state.interstitial = null; // wipe the interestitial
      state.mode = "question"; // return to question mode
      state.question = state.level.createQuestion();
    }
  }
  
  switch(state.mode) {
    case "question":
      background(bgColorStandard[0], bgColorStandard[1], bgColorStandard[2]);

      // show the scoreboard
      scoreboard.draw();
      
      // draw the bubbles
      for (Bubble bubble : state.question.bubbles) {
        bubble.draw();
        bubble.move();
        if (!bubble.inBounds()) {
          state.mode = "answer_timeout";
          String[] subtexts = {
            "You didn't answer in time!"
          };
          state.interstitial = new Interstitial(this, 2, "Timeout!", subtexts, fgColorInfo, bgColorInfo, soundFileFailure);
        }
      }

      // draw cheat sheet if activated
      if (state.showCheatSheet) {
        state.cheatSheet.draw();
      }
      break;
    case "answer_correct":
      state.interstitial.draw();
      break;
    case "answer_incorrect":
      state.interstitial.draw();
      break;
    case "answer_timeout":
      state.interstitial.draw();
      break;
    case "level_start":
      state.interstitial.draw();
      break;
  }
}

void keyReleased() {
  state.showCheatSheet = false;
}

void keyPressed() {
  //System.out.println(keyCode);
  if (state.mode == "question" && keyCode == ENTER_KEY) {
    // the user has submitted an answer... check whether the answer is correct
    if (state.question.isCorrect(state.givenAnswer)) {
      state.level.numCorrect++; // keep track of how many questions the user answered correct at this level
      state.score += (state.levelIndex + 1) + 1;
      state.mode = "answer_correct";
      String[] subtexts = {
        state.question.numbers[0] + " X " + state.question.numbers[1] + " is certainly " + state.question.getAnswer() + "!",
        "Well done!"
      };
      state.interstitial = new Interstitial(this, 2, "CORRECT!", subtexts, fgColorSuccess, bgColorSuccess, soundFileSuccess);
    }
    else {
      state.mode = "answer_incorrect";
      String[] subtexts = {
        state.givenAnswer + " is incorrect!",
        state.question.numbers[0] + " X " + state.question.numbers[1] + " = " + state.question.getAnswer()
      };
      state.interstitial = new Interstitial(this, 4, "WRONG!", subtexts, fgColorFailure, bgColorFailure, soundFileFailure);
    }
    state.givenAnswer = ""; // reset
    
    // check whether the level is finished
    if (state.level.isOver()) {
      if (state.level.isPassed()) {
        System.out.println("You passed the level!");
        state.levelIndex++;
        state.level = state.levels[state.levelIndex]; // move on to the next level
        String[] subtexts = {
          "You must answer " + state.level.requiredNumCorrect + " of " + state.level.numQuestions + " questions correctly!"
        };
        state.interstitial = new Interstitial(this, 4, "STARTING LEVEL " + state.levelIndex, subtexts, fgColorInvert, bgColorInvert, soundFileWelcome);
        state.mode = "level_start";
        state.level.reset();
       
      } // isPassed()
      else {
        System.out.println("You failed the level!");
        String[] subtexts = {
          "You must answer " + state.level.requiredNumCorrect + " of " + state.level.numQuestions + " questions correctly!", 
          "You only answered " + state.level.numCorrect + " correctly."
        };
        state.interstitial = new Interstitial(this, 4, "FAILED LEVEL " + state.levelIndex, subtexts, fgColorStandard, bgColorStandard, soundFileWelcome);
        state.mode = "level_start";
        state.level.reset();
      }
    } // state.level.isOver()
    
  }
  else if (state.mode == "question" && keyCode == SPACE_KEY) {
    // show the cheat sheet
    state.showCheatSheet = true;
  }
  else if (keyCode == LEFT_ARROW_KEY) {
    // jump to previous level
    if (state.levelIndex > 0) {
      state.givenAnswer = "";
      state.level.reset();
      state.levelIndex--;
      state.level = state.levels[state.levelIndex];
      String[] subtexts = {
        "You must answer " + state.level.requiredNumCorrect + " of " + state.level.numQuestions + " questions correctly!"
      };
      state.interstitial = new Interstitial(this, 4, "SKIPPING TO LEVEL " + state.levelIndex, subtexts, fgColorStandard, bgColorStandard, soundFileWelcome);
      state.mode = "level_start";
    }
  }
  else if (keyCode == RIGHT_ARROW_KEY) {
    // jump to next level
    if (state.levelIndex < state.levels.length-1) {
      state.givenAnswer = "";
      state.level.reset();
      state.levelIndex++;
      state.level = state.levels[state.levelIndex];
      String[] subtexts = {
        "You must answer " + state.level.requiredNumCorrect + " of " + state.level.numQuestions + " questions correctly!"
      };
      state.interstitial = new Interstitial(this, 4, "SKIPPING TO LEVEL " + state.levelIndex, subtexts, fgColorInvert, bgColorInvert, soundFileWelcome);
      state.mode = "level_start";
    }
  }
  else if (keyCode == UP_ARROW_KEY) {
    // increase the speed
    System.out.println("Speeding up...");
    speed[0] = speed[0] * 1.25;
    speed[1] = speed[1] * 1.25;
    if (state.mode == "question") {
      for (Bubble bubble : state.question.bubbles) {
        bubble.speed[0] = bubble.speed[0] * 1.25;
        bubble.speed[1] = bubble.speed[1] * 1.25;
      }
    }
  }
  else if (keyCode == DOWN_ARROW_KEY) {
    // decrease the speed
    System.out.println("Slowing down...");
    speed[0] = speed[0] * 0.75;
    speed[1] = speed[1] * 0.75;
    if (state.mode == "question") {
      for (Bubble bubble : state.question.bubbles) {
        bubble.speed[0] = bubble.speed[0] * 0.75;
        bubble.speed[1] = bubble.speed[1] * 0.75;
      }
    }
  }
  else if (state.mode == "question") {
    // the user is answering... append any keystroke to the user's answer-in-progress
    state.givenAnswer += key;
    //System.out.println(givenAnswer);
  }
}

int[] getSequence(int start, int end, int step) {
  // figure out how many numbers are in this sequence
  int length = 0;
  for (int i=start; i<end; i=i+step) {
    length++;
  }
  // create the sequence
  int counter = 0;
  int[] sequence = new int[length];
  for (int i=start; i<end; i=i+step) {
    sequence[counter] = i;
    counter++;
  }
  return sequence;
}

class Footer {
  
  Footer(multiplication app, int[] fgColor) {
    this.app = app;
    this.fgColor = fgColor;
  }

  void draw(String text) {
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    this.app.text("- " + text + " -", this.app.width/2, this.app.height - 20);
  }
  
  multiplication app;
  String text;
  int[] fgColor = new int[3];
}

class Interstitial {
  
  Interstitial(multiplication app, int timeout, String text, String[] subtexts, int[] fgColor, int[] bgColor, SoundFile soundFile) {
    this.app = app;
    this.timeout = timeout; // number of seconds for which to show this interstitial
    this.text = text;
    this.subtexts = subtexts;
    this.fgColor = fgColor;
    this.bgColor = bgColor;
    this.footer = new Footer(app, fgColor);
    this.soundFile = soundFile;
    // play the sound, if any
    if (this.soundFile != null) {
      this.soundFile.play();
    }
    
    
  }
  
  boolean isTimedOut() {
    // has this interstitial been shown long enough?
    int totalNumFrames = (int) (app.frameRate * this.timeout);
    // System.out.println(this.frameCounter + " : " + totalNumFrames);
    return this.frameCounter > totalNumFrames;
  }
  
  void draw() {
    background(this.bgColor[0], this.bgColor[1], this.bgColor[2]);
    stroke(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    this.app.text(this.text, this.app.width/2, this.app.height/2);
    int ySubtextOffset = 50;
    int ySubtextSpacing = 25;
    for (String subtext : subtexts) {
      this.app.text(subtext, this.app.width/2, (this.app.height/2)+ySubtextOffset);
      ySubtextOffset += ySubtextSpacing;
    }
    // draw the timer to the footer
    int secondsLeft = (int) ((timeout*app.framerate - frameCounter) / framerate) + 1; // seconds until this interstitial times out
    footer.draw(secondsLeft + "");

  }
  
  multiplication app;
  int timeout;
  int frameCounter = 0;
  String text;
  String[] subtexts;
  int[] fgColor = new int[3];
  int[] bgColor = new int[3];
  Footer footer;
  SoundFile soundFile;
}

class CheatSheet {
  
  CheatSheet(multiplication app, int[] fgColor, int[] bgColor) {
    this.app = app;
    this.fgColor = fgColor;
    this.bgColor = bgColor;
    footer = new Footer(app, fgColor);
  }
  
  void draw() {
    background(this.bgColor[0], this.bgColor[1], this.bgColor[2]);
    //stroke(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    int x = margin + spacing*2;
    int y = margin;
    
    // print out the x axis
    for (int num : app.state.level.numbers) {
      app.text(num, x, y);
      x = x + spacing;
    }
    app.line(0, y+spacing, app.width, y+spacing);
    
    // print out the y axis
    x = margin;
    y = margin + spacing*2;
    for (int num : app.state.level.numbers) {
      app.text(num, x, y);
      y = y + spacing;
    }
    app.line(x+spacing, 0, x+spacing, app.height);
    
    // print out the multiplication chart for this level
    x = margin + spacing*2;
    y = margin + spacing*2;
    for (int num1 : app.state.level.numbers) {
      x = margin + spacing*2;
      for (int num2 : app.state.level.numbers) {
        app.text(num1 * num2, x, y);
        x = x + spacing;
      }
      y = y + spacing;
    }
    
    // draw the footer
    footer.draw("Copyright (c) Foo Barstein. All rights reserved.");
  }
  
  multiplication app;
  int[] fgColor = new int[3]; // r, g, b
  int[] bgColor = new int[3]; // r, g, b
  int margin = 30;
  int spacing = 30;
  Footer footer;
}

class Bubble {
  
  Bubble(multiplication app, int number, int radius) {
    this.app = app;
    this.fgColor = app.bgColorStandard; //r, g, b
    this.bgColor = app.fgColorStandard; //r, g, b
    this.position[0] = (float) (app.width / 2); //(float) (Math.random() * app.width);
    this.position[1] = (float) (app.height / 2); //(float) (Math.random() * app.height);
    this.shape[0] = radius * 2; // width
    this.shape[1] = radius * 2; // height
    float speedX = (float) (Math.random() * app.speed[0]*2) - app.speed[0]; // speedX
    float speedY = (float) (Math.random() * app.speed[1]*2) - app.speed[1]; // speedY
    this.setSpeedX(speedX);
    this.setSpeedY(speedY);
    this.number = number;
  }
  
  void draw() {
    fill(this.bgColor[0], this.bgColor[1], this.bgColor[2]);
    this.app.ellipse(this.position[0], this.position[1], this.shape[0], this.shape[1]);
    //stroke(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    this.app.text(this.number, this.position[0], this.position[1]);
  }
  
  void move() {
    float newX = (this.position[0] + this.speed[0]);
    float newY = (this.position[1] + this.speed[1]);
    //System.out.println(newX + " : " + newY);
    this.position[0] = newX;
    this.position[1] = newY;
  }
  
  boolean inBounds() {
    boolean inBounds = true;
    if (this.position[0] <= 0 || this.position[1] <= 0 || this.position[0] >= this.app.width || this.position[1] >= this.app.height) {
      inBounds = false;
    }
    return inBounds;
  }
  
  void setSpeedX(float speed) {
    this.speed[0] = speed;
  }
  void setSpeedY(float speed) {
    this.speed[1] = speed;
  }
  
  multiplication app;
  float[] position = new float[2]; // x, y
  int[] shape = new int[2]; // width, height
  float[] speed = new float[2]; // speedX, speedY
  int[] fgColor = new int[3]; // r, g, b
  int[] bgColor = new int[3]; // r, g, b
  int number;
}

class Scoreboard {
  
  Scoreboard(multiplication app, int[] fgColor, int[] bgColor) {
    this.app = app;
    this.fgColor = bgColor; //r, g, b
    this.bgColor = fgColor; //r, g, b
    this.shape[0] = 150; // width
    this.shape[1] = 150; // height
    this.position[0] = app.width - this.shape[0]; // right-aligned
    this.position[1] = app.height - this.shape[1]; // bottom-aligned
  }
  
  void draw() {
    textAlign(CENTER, CENTER);
    fill(this.bgColor[0], this.bgColor[1], this.bgColor[2]);
    this.app.rect(this.position[0], this.position[1], this.shape[0], this.shape[1]);
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    this.app.text("LEVEL " + this.app.state.levelIndex, this.position[0] + this.shape[0]/2, this.position[1] + this.shape[1]/2 - 20);
    //this.app.text(this.app.state.level.numCorrect + " / " + this.app.state.level.questionCounter + " correct", this.position[0] + this.shape[0]/2, this.position[1] + this.shape[1]/2);
    this.app.text("Correct: " + this.app.state.level.numCorrect + " of " + this.app.state.level.questionCounter, this.position[0] + this.shape[0]/2, this.position[1] + this.shape[1]/2);
    this.app.text("Score: " + this.app.state.score, this.position[0] + this.shape[0]/2, this.position[1] + this.shape[1]/2 + 20);
  }
  
  multiplication app;
  float[] position = new float[2]; // x, y
  int[] shape = new int[2]; // width, height
  int[] fgColor = new int[3]; // r, g, b
  int[] bgColor = new int[3]; // r, g, b
}

class Question {
  
  Question(multiplication app, int[] numbers) {
    this.numbers = numbers;
    this.app = app;
    // make a bubble from each number
    bubbles = new Bubble[numbers.length]; // make as many bubbles as there are numbers in this question
    for (int i=0; i<numbers.length; i++) {
      bubbles[i] = new Bubble(this.app, numbers[i], 50);
    }
  }

  String getAnswer() {
    int product = 1;
    for (int num : this.numbers) {
      product = product * num;
    }
    return product + ""; // as a string
  }
  
  boolean isCorrect(String answer) {
    String correctAnswer = this.getAnswer();
    System.out.println(answer + " : " + correctAnswer);
    if (answer.equals(correctAnswer)) {
      System.out.println("Correct!");
      return true;
    }
    else {
      System.out.println("Incorrect!");
      return false;
    }
  }
  
  
  multiplication app;
  int[] numbers;
  Bubble[] bubbles;
  int correctAnswer;
}

class Level {
  Level(multiplication app, int[] numbers, int numOperands, int numQuestions, int requiredNumCorrect) {
    this.app = app;
    this.numbers = numbers;
    this.numOperands = numOperands;
    this.numQuestions = numQuestions;
    this.requiredNumCorrect = requiredNumCorrect;
  }
  
  void reset() {
    // reset the level
    this.questionCounter = 0;
    this.numCorrect = 0;
  }
  
  Question createQuestion() {
    int[] nums = new int[this.numOperands]; // create an array to hold the operands
    for (int i=0; i<nums.length; i++) {
      nums[i] = this.getNumber(); // generate each operand number
    }
    Question q = new Question(this.app, nums); // create a question from the numbers
    this.questionCounter++; // remember how many questions we've asked already at this level
    System.out.println("Question #" + this.questionCounter + " out of " + this.numQuestions + " at this level.");
    return q;
  }
  
  int getNumber() {
    int num = numbers[(int) (Math.random() * numbers.length)]; // pull a random number from this level's numbers
    return num;
  }
  
  boolean isOver() {
    // whether the all questions at this level have been asked yet
    boolean isOver = this.questionCounter >= this.numQuestions;
    return isOver;
  }
  
  boolean isPassed() {
    // whether the user passed the level or not
    return this.numCorrect >= this.requiredNumCorrect;
  }
  
  multiplication app;
  int[] numbers; // the set of numbers questions are drawn from
  int numOperands; // how many numbers to multiply together in this question
  int numQuestions; // the number of questions to ask at this level
  int requiredNumCorrect; // how many must be answered correctly before moving on to the next level
  int questionCounter = 0; // how many questions we have asked so far
  int numCorrect = 0; // how many the user answered correctly
}

class State {
  
  State(Level[] levels, Level currentLevel, int levelIndex, Interstitial currentInterstitial, String givenAnswer, String currentMode, CheatSheet cheatSheet) {
    this.levels = levels;
    this.level = currentLevel;
    this.levelIndex = levelIndex;
    this.interstitial = currentInterstitial;
    this.givenAnswer = givenAnswer;
    this.mode = currentMode;
    this.cheatSheet = cheatSheet;
  }
  
  Level[] levels;
  Level level;
  int levelIndex;
  Question question;
  String givenAnswer;
  String mode;
  Interstitial interstitial;
  int score = 0;
  CheatSheet cheatSheet;
  boolean showCheatSheet = false;
  
}
