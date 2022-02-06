var w = 800;
var h = 600;
var margin = 30
var spacing = 30
var framerate = 24;

var soundFileWelcome;
var soundFileSuccess;
var soundFileFailure;

var objectSpeed = [1.5, -1.5]
var bgColorStandard = [0, 0, 0]
var fgColorStandard = [255, 255, 255]
var bgColorInvert = [255, 255, 255]
var fgColorInvert = [0, 0, 0]
var bgColorSuccess = [0, 255, 0]
var fgColorSuccess = [0, 0, 0]
var bgColorFailure = [255, 125, 125]
var fgColorFailure = [0, 0, 0]
var bgColorInfo = [0, 0, 255]
var fgColorInfo = [255, 255, 255]

var SPACE_KEY = 32;
// var ENTER_KEY = 10;
// var RIGHT_ARROW_KEY = 39;
// var LEFT_ARROW_KEY = 37;
// var UP_ARROW_KEY = 38;
// var DOWN_ARROW_KEY = 40;

window.onkeydown = function(e) {
  e.preventDefault()
}

var numbers = [
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
]

var levels;
var state; // the current state of the game
var scoreboard;
var cheatSheet;

function preload () {
  // Load the sound file.
  // We have included both an MP3 and an OGG version.
  soundFormats('mp3')
  // prepare sounds
  window.soundFileWelcome = loadSound("./audio/vibraphon.mp3")
  window.soundFileSuccess = null; //loadSound("Glass.aiff")
  window.soundFileFailure = null; //loadSound("Basso.aiff")
  // console.log(soundfile.duration())
  
}

function setup () {
  // console.log('windowing')
  // console.log(windowWidth + ":" + windowHeight)
  createCanvas(windowWidth, windowHeight) // size(w, h);

  textAlign(CENTER, CENTER)

  frameRate(framerate) //  24 frames per second
  background(bgColorStandard[0], bgColorStandard[1], bgColorStandard[2])

  window.levels = []
  let levels = window.levels
  for (let i=0; i<numbers.length; i++) {
    //int numQuestions = parseInt(Math.pow(numbers[i].length, 3)); // how many questions to ask at this level - cube the number of numbers in this level
    numQuestions = numbers[i].length * 2;
    numCorrectRequired = parseInt(numQuestions * 3 / 4); // how many must be answered correctly in order to pass this level - 3/4
    numOperands = 2; // how many numbers to multiply together.... 2 for now
    levels[i] = new Level(this, numbers[i], numOperands, numQuestions, numCorrectRequired); // create a new level
  }

  // set the initial state of the game
  currentLevelIndex = 1;
  currentLevel = levels[currentLevelIndex];
  subtexts = [
    "For each question, type your answer and press ENTER.", 
    "- SPACE bar to see a cheat sheet -",
    "- LEFT or RIGHT arrows to skip levels -",
    "- UP or DOWN arrows to adjust speed -",
  ]
  let currentInterstitial = new Interstitial(this, 8, "WELCOME TO MULTIPLICATION LEVEL " + currentLevelIndex, subtexts, fgColorInvert, bgColorInvert, soundFileWelcome);
  let cheatSheet = new CheatSheet(this, fgColorInvert, bgColorInvert);
  let currentMode = "level_start";
  
  window.state = new State(levels, currentLevel, currentLevelIndex, currentInterstitial, "", currentMode, cheatSheet);

  window.scoreboard = new Scoreboard(this, fgColorInvert, bgColorInvert);
}

function draw() {
  let state = window.state
  let scoreboard = window.scoreboard

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
      state.question.bubbles.forEach(bubble => {
        bubble.draw();
        bubble.move();
        if (!bubble.inBounds()) {
          state.mode = "answer_timeout";
          const subtexts = [
            "You didn't answer in time!"
          ]
          state.interstitial = new Interstitial(this, 2, "Timeout!", subtexts, fgColorInfo, bgColorInfo, soundFileFailure);
        }
      })

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

function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
}

function keyReleased () {
  window.state.showCheatSheet = false
}

function keyPressed () {
  let state = window.state
  if (state.mode == "question" && keyCode == ENTER) {
    // the user has submitted an answer... check whether the answer is correct
    if (state.question.isCorrect(state.givenAnswer)) {
      state.level.numCorrect++; // keep track of how many questions the user answered correct at this level
      state.score += (state.levelIndex + 1) + 1;
      state.mode = "answer_correct";
      let subtexts = [
        state.question.numbers[0] + " X " + state.question.numbers[1] + " is certainly " + state.question.getAnswer() + "!",
        "Well done!"
      ]
      state.interstitial = new Interstitial(this, 2, "CORRECT!", subtexts, fgColorSuccess, bgColorSuccess, soundFileSuccess);
    }
    else {
      state.mode = "answer_incorrect";
      let subtexts = [
        state.givenAnswer + " is incorrect!",
        state.question.numbers[0] + " X " + state.question.numbers[1] + " = " + state.question.getAnswer()
      ]
      state.interstitial = new Interstitial(this, 4, "WRONG!", subtexts, fgColorFailure, bgColorFailure, soundFileFailure);
    }
    state.givenAnswer = ""; // reset
    
    // check whether the level is finished
    if (state.level.isOver()) {
      if (state.level.isPassed()) {
        console.log("You passed the level!");
        state.levelIndex++;
        state.level = state.levels[state.levelIndex]; // move on to the next level
        let subtexts = [
          "You must answer " + state.level.requiredNumCorrect + " of " + state.level.numQuestions + " questions correctly!"
        ]
        state.interstitial = new Interstitial(this, 4, "STARTING LEVEL " + state.levelIndex, subtexts, fgColorInvert, bgColorInvert, soundFileWelcome);
        state.mode = "level_start";
        state.level.reset();
       
      } // isPassed()
      else {
        console.log("You failed the level!");
        let subtexts = [
          "You must answer " + state.level.requiredNumCorrect + " of " + state.level.numQuestions + " questions correctly!", 
          "You only answered " + state.level.numCorrect + " correctly."
        ]
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
  else if (keyCode == LEFT_ARROW) {
    // jump to previous level
    if (state.levelIndex > 0) {
      state.givenAnswer = "";
      state.level.reset();
      state.levelIndex--;
      state.level = state.levels[state.levelIndex];
      let subtexts = [
        "You must answer " + state.level.requiredNumCorrect + " of " + state.level.numQuestions + " questions correctly!"
      ]
      state.interstitial = new Interstitial(this, 4, "SKIPPING TO LEVEL " + state.levelIndex, subtexts, fgColorStandard, bgColorStandard, soundFileWelcome);
      state.mode = "level_start";
    }
  }
  else if (keyCode == RIGHT_ARROW) {
    // jump to next level
    if (state.levelIndex < state.levels.length-1) {
      state.givenAnswer = "";
      state.level.reset();
      state.levelIndex++;
      state.level = state.levels[state.levelIndex];
      let subtexts = [
        "You must answer " + state.level.requiredNumCorrect + " of " + state.level.numQuestions + " questions correctly!"
      ]
      state.interstitial = new Interstitial(this, 4, "SKIPPING TO LEVEL " + state.levelIndex, subtexts, fgColorInvert, bgColorInvert, soundFileWelcome);
      state.mode = "level_start";
    }
  }
  else if (keyCode == UP_ARROW) {
    // increase the speed
    console.log("Speeding up...");
    objectSpeed[0] = objectSpeed[0] * 1.25;
    objectSpeed[1] = objectSpeed[1] * 1.25;
    if (state.mode == "question") {
      state.question.bubbles.forEach(bubble => {
        bubble.speed[0] = bubble.speed[0] * 1.25;
        bubble.speed[1] = bubble.speed[1] * 1.25;
      })
    }
  }
  else if (keyCode == DOWN_ARROW) {
    // decrease the speed
    console.log("Slowing down...");
    objectSpeed[0] = objectSpeed[0] * 0.75;
    objectSpeed[1] = objectSpeed[1] * 0.75;
    if (state.mode == "question") {
      state.question.bubbles.forEach(bubble => {
        bubble.speed[0] = bubble.speed[0] * 0.75;
        bubble.speed[1] = bubble.speed[1] * 0.75;
      })
    }
  }
  else if (state.mode == "question") {
    // the user is answering... append any keystroke to the user's answer-in-progress
    state.givenAnswer += key;
    //console.log(givenAnswer);
  }
}


class Footer {
  
  constructor(app, fgColor) {
    this.app = app;
    this.fgColor = fgColor;
  }

  draw(text) {
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    window.text("- " + text + " -", windowWidth/2, windowHeight - 20);
  }
}

class Interstitial {
  
  constructor(app, timeout, text, subtexts, fgColor, bgColor, soundFile) {
    this.app = app;
    this.timeout = timeout; // number of seconds for which to show this interstitial
    this.frameCounter = 0;
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
  
  isTimedOut() {
    // has this interstitial been shown long enough?
    let totalNumFrames = parseInt(framerate * this.timeout);
    // console.log(this.frameCounter + " : " + totalNumFrames);
    return this.frameCounter > totalNumFrames;
  }
  
  draw() {
    background(this.bgColor[0], this.bgColor[1], this.bgColor[2]);
    // stroke(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    window.text(this.text, windowWidth/2, windowHeight/2);
    let ySubtextOffset = 50;
    let ySubtextSpacing = 25;
    this.subtexts.forEach(subtext => {
      window.text(subtext, windowWidth/2, (windowHeight/2)+ySubtextOffset);
      ySubtextOffset += ySubtextSpacing;
    })
    // draw the timer to the footer
    let secondsLeft = parseInt((this.timeout*framerate - this.frameCounter) / framerate) + 1; // seconds until this interstitial times out
    this.footer.draw(secondsLeft + "");

  }
  
}

class CheatSheet {
  
  constructor(app, fgColor, bgColor) {
    this.app = app;
    this.fgColor = fgColor;
    this.bgColor = bgColor;
    this.footer = new Footer(app, fgColor);
  }
  
  draw() {
    const margin = window.margin
    const spacing = window.spacing
    const state = window.state
    // console.log(`margin: ${margin}, spacing: ${spacing}`)

    background(this.bgColor[0], this.bgColor[1], this.bgColor[2]);
    //stroke(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    let x = margin + spacing*2;
    let y = margin;
    // console.log(`x ${x}, y ${y}`)
    
    // print out the x axis
    state.level.numbers.forEach(num => {
      window.text(num, x, y);
      x = x + spacing;
    })
    window.line(margin, y+spacing, window.windowWidth-margin, y+spacing);
    
    // print out the y axis
    x = margin;
    y = margin + spacing*2;
    state.level.numbers.forEach(num => {
      window.text(num, x, y);
      y = y + spacing;
    })
    window.line(x+spacing, margin, x+spacing, window.windowHeight-margin);
    
    // print out the multiplication chart for this level
    x = margin + spacing*2;
    y = margin + spacing*2;
    state.level.numbers.forEach(num1 => {
      x = margin + spacing*2;
      state.level.numbers.forEach(num2 => {
        window.text(num1 * num2, x, y);
        x = x + spacing;
      })
      y = y + spacing;
    })
    
    // draw the footer
    this.footer.draw("Copyright (c) Foo Barstein. All rights reserved.");
  }
}

class Bubble {
  
  constructor(app, number, radius) {
    this.app = app;
    this.fgColor = window.bgColorStandard; //r, g, b
    this.bgColor = window.fgColorStandard; //r, g, b
    this.position = [parseFloat(windowWidth / 2), parseFloat(windowHeight / 2)]; //(float) (Math.random() * windowWidth); //(float) (Math.random() * windowHeight);
    this.shape = [ radius * 2, radius * 2] // width; height
    let speedX = parseFloat(Math.random() * objectSpeed[0]*2) - objectSpeed[0]; // speedX
    let speedY = parseFloat(Math.random() * objectSpeed[1]*2) - objectSpeed[1]; // speedY
    this.speed = []
    this.setSpeedX(speedX);
    this.setSpeedY(speedY);
    this.number = number;
  }
  
  draw() {
    fill(this.bgColor[0], this.bgColor[1], this.bgColor[2]);
    window.ellipse(this.position[0], this.position[1], this.shape[0], this.shape[1]);
    //stroke(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    window.text(this.number, this.position[0], this.position[1]);
  }
  
  move() {
    let newX = (this.position[0] + this.speed[0]);
    let newY = (this.position[1] + this.speed[1]);
    //console.log(newX + " : " + newY);
    this.position[0] = newX;
    this.position[1] = newY;
  }
  
  inBounds() {
    let inBounds = true;
    if (this.position[0] <= 0 || this.position[1] <= 0 || this.position[0] >= windowWidth || this.position[1] >= windowHeight) {
      inBounds = false;
    }
    return inBounds;
  }
  
  setSpeedX(speed) {
    this.speed[0] = speed;
  }
  setSpeedY(speed) {
    this.speed[1] = speed;
  }
  
}

class Scoreboard {
  
  constructor(app, fgColor, bgColor) {
    this.app = app;
    this.fgColor = bgColor; //r, g, b
    this.bgColor = fgColor; //r, g, b
    this.shape = [150, 150]; // width, height
    this.setPosition()
  }
  
  setPosition() {
    this.position = [windowWidth - this.shape[0], windowHeight - this.shape[1]]; // right-aligned bottom-aligned    
  }

  draw() {
    textAlign(CENTER, CENTER);
    fill(this.bgColor[0], this.bgColor[1], this.bgColor[2]);
    this.setPosition()
    window.rect(this.position[0], this.position[1], this.shape[0], this.shape[1]);
    fill(this.fgColor[0], this.fgColor[1], this.fgColor[2]);
    window.text("LEVEL " + window.state.levelIndex, this.position[0] + this.shape[0]/2, this.position[1] + this.shape[1]/2 - 20);
    //window.text(window.state.level.numCorrect + " / " + window.state.level.questionCounter + " correct", this.position[0] + this.shape[0]/2, this.position[1] + this.shape[1]/2);
    window.text("Correct: " + window.state.level.numCorrect + " of " + window.state.level.questionCounter, this.position[0] + this.shape[0]/2, this.position[1] + this.shape[1]/2);
    window.text("Score: " + window.state.score, this.position[0] + this.shape[0]/2, this.position[1] + this.shape[1]/2 + 20);
  }

}

class Question {
  
  constructor(app, numbers) {
    this.numbers = numbers;
    this.app = app;
    // make a bubble from each number
    this.bubbles = [] // make as many bubbles as there are numbers in this question
    for (let i=0; i<numbers.length; i++) {
      this.bubbles[i] = new Bubble(this.app, numbers[i], 50);
    }
  }

  getAnswer() {
    let product = 1;
    this.numbers.forEach(num => {
      product = product * num;
    })
    return product + ""; // as a string
  }
  
  isCorrect(answer) {
    let correctAnswer = this.getAnswer();
    console.log(answer + " : " + correctAnswer);
    if (answer == correctAnswer) {
      console.log("Correct!");
      return true;
    }
    else {
      console.log("Incorrect!");
      return false;
    }
  }
  
}

class Level {
  constructor(app, numbers, numOperands, numQuestions, requiredNumCorrect) {
    this.app = app;
    this.numbers = numbers;
    this.numOperands = numOperands;
    this.numQuestions = numQuestions;
    this.requiredNumCorrect = requiredNumCorrect;
    this.questionCounter = 0
    this.numCorrect = 0
  }
  
  reset() {
    // reset the level
    this.questionCounter = 0;
    this.numCorrect = 0;
  }
  
  createQuestion() {
    let nums = []; // create an array to hold the operands
    for (let i=0; i<this.numOperands; i++) {
      nums[i] = this.getNumber(); // generate each operand number
    }

    let q = new Question(this.app, nums); // create a question from the numbers
    this.questionCounter++; // remember how many questions we've asked already at this level
    console.log("Question #" + this.questionCounter + " out of " + this.numQuestions + " at this level.");
    return q;
  }
  
  getNumber() {
    let num = this.numbers[parseInt(Math.random() * this.numbers.length)]; // pull a random number from this level's numbers
    return num;
  }
  
  isOver() {
    // whether the all questions at this level have been asked yet
    let isOver = this.questionCounter >= this.numQuestions;
    return isOver;
  }
  
  isPassed() {
    // whether the user passed the level or not
    return this.numCorrect >= this.requiredNumCorrect;
  }
}

class State {
  
  constructor(levels, currentLevel, levelIndex, currentInterstitial, givenAnswer, currentMode, cheatSheet) {
    this.levels = levels;
    this.level = currentLevel;
    this.levelIndex = levelIndex;
    this.interstitial = currentInterstitial;
    this.givenAnswer = givenAnswer;
    this.mode = currentMode;
    this.cheatSheet = cheatSheet;
    this.score = 0;
  }
  
}

function getSequence(start, end, step) {
  // figure out how many numbers are in this sequence
  let length = 0;
  for (let i=start; i<end; i=i+step) {
    length++;
  }
  // create the sequence
  let counter = 0;
  let sequence = [];
  for (let i=start; i<end; i=i+step) {
    sequence[counter] = i;
    counter++;
  }
  return sequence;
}

