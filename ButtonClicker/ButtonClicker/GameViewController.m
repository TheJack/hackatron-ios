//
//  GameViewController.m
//  ButtonClicker
//
//  Created by Todd Kerpelman on 12/9/13.
//  Copyright (c) 2013 Google. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "GameViewController.h"
#import "GameModel.h"
#import "MPManager.h"
#import "ButtonClickerPlayer.h"

@import CoreMotion;
@import SceneKit;

@interface GameViewController () <MPGameDelegate> {
  NSArray *_scoreboardViews;
}
@property(nonatomic) GameModel *model;
@property (weak, nonatomic) IBOutlet UIButton *backToLobbyButton;
@property (weak, nonatomic) IBOutlet UIButton *debugCrashButton;
@property (weak, nonatomic) IBOutlet UIButton *debugLeaveButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property(nonatomic, weak) NSTimer *updateTimer;
@property(weak, nonatomic) IBOutlet UILabel *timeLeftLabel;
@property (weak, nonatomic) IBOutlet UIView *scoreBG1;
@property (weak, nonatomic) IBOutlet UIView *scoreBG2;
@property (weak, nonatomic) IBOutlet UIView *scoreBG3;
@property (weak, nonatomic) IBOutlet UIView *scoreBG4;
@property (weak, nonatomic) IBOutlet SCNView* sceneView;

@property (strong) CMMotionManager* manager;
@property (strong) NSOperationQueue* queue;
@property (strong) CMDeviceMotionHandler handler;

@end

@implementation GameViewController

// Lazy instantiation for now
- (GameModel *)model {
  if (!_model) {
    _model = [[GameModel alloc] init];
  }
  return  _model;
}

# pragma mark - UI Handlers

- (IBAction)clickButtonWasPressed:(id)sender {
  [self.model playerDidClick];
}

// Useful for testing time-out cases. Less useful in production.
- (IBAction)crashButtonWasPressed:(id)sender {
  abort();
}

// Leave the game before it's finished, but do so elegantly. There might be times a player
// does this in an actual game.
- (IBAction)leaveButtonWasPressed:(id)sender {
  [[MPManager sharedInstance] leaveRoom];
  [self.navigationController popViewControllerAnimated:YES];
}



# pragma mark - Game handling methods
- (void)startGame {
  [self.model prepareToStart];
  [self.model startGame];
  // Let's unhide views
  self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(updateInterfaceFromTimer:)
                                                    userInfo:nil
                                                     repeats:YES];
    
    
    /*         let bundle = NSBundle.mainBundle()
     let paths = bundle.pathsForResourcesOfType("dae", inDirectory: "")
     let url = bundle.pathForResource("robot-old", ofType: "dae")
     //        NSLog(bundle.pathForResource("robot", ofType: "DAE")!)
     
     let scene = SCNScene(URL: NSURL(fileURLWithPath: url!)!, options: nil, error: nil)
     */

}

- (NSString *)formatScore:(int)playerScore isFinal:(BOOL)isFinal {
  NSString *returnMe = [NSString stringWithFormat:@"%03d %@", playerScore, (isFinal) ? @"*" : @""];
  return returnMe;
}

- (void)safelyLeaveRoom {
  [[MPManager sharedInstance] leaveRoom];
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateInterface {
  self.timeLeftLabel.text = [NSString stringWithFormat:@":%02d", (int) round(self.model.timeLeft)];
  NSArray *scores = [self.model getListOfPlayersSortedByScore];

  // We're going to bottom-align these things
  int currentRow = 4 - (int)scores.count;
  for (ButtonClickerPlayer *player in scores) {
    // Poor mans table view
    UIView *scoreBG = _scoreboardViews[currentRow];
    scoreBG.hidden = NO;
    ((UILabel *)scoreBG.subviews[0]).text = player.displayName;
    ((UILabel *)scoreBG.subviews[1]).text =
        [self formatScore:player.score isFinal:player.scoreIsFinal];
    currentRow++;
  }

  switch (self.model.gameState) {
    case BCGameStateWaitingToStart:
      self.statusLabel.text = @"Waiting...";
      break;
    case BCGameStatePlaying:
      self.statusLabel.text = @"CLICK!!";
      break;
    case BCGameStateWaitingToFinish:
      self.statusLabel.text = @"Waiting for final results";
      break;
    case BCGameStateDone:
      self.statusLabel.text = @"Finished!";
      self.backToLobbyButton.hidden = NO;
      self.debugCrashButton.hidden = YES;
      self.debugLeaveButton.hidden = YES;
      break;
    default:
      break;
  }
}

- (void)updateInterfaceFromTimer:(NSTimer *)timer {
  [self.model updateStateIfNeeded];
  [self updateInterface];
}

- (IBAction)backToLobbyWaspressed:(id)sender {
  [self safelyLeaveRoom];
}

# pragma mark - MPGameDelegate methods

- (void)playerWithId:(NSString *)playerId reportedScore:(int)score isFinal:(BOOL)final {
  [self.model playerWithId:playerId reportedScore:score isFinal:final];
}

- (void)playerSetMayHaveChanged {
  [self.model refreshPlayerSet];
  [self updateInterface];
}

# pragma mark - Lifecycle methods

- (void)viewWillAppear:(BOOL)animated {
  for (UIView *hideMe in _scoreboardViews) {
    hideMe.hidden = YES;
  }
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  self.backToLobbyButton.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.updateTimer invalidate];
  self.updateTimer = nil;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // TODO: Look into just making this my model, since all I'm doing now is redirecting calls.
  [[MPManager sharedInstance] setGameDelegate:self];
  _scoreboardViews = @[ self.scoreBG1, self.scoreBG2, self.scoreBG3, self.scoreBG4 ];

  // We'll just start for now
  [self startGame];
    
    
    NSBundle* bundle = [NSBundle mainBundle];
    id urlPath = [bundle pathForResource:@"robot with bones" ofType:@"dae"];
    id url = [NSURL fileURLWithPath:urlPath];
    SCNScene* scene = [SCNScene sceneWithURL:url options:nil error:nil];
    NSLog(@"%@", [scene.rootNode description]);
    SCNNode* voltronNode = [SCNNode node];
    NSArray* childNodes = scene.rootNode.childNodes;
    for (SCNNode* node in childNodes) {
        [node removeFromParentNode];
        [voltronNode addChildNode:node];
    }
    [scene.rootNode addChildNode:voltronNode];
    // negative on x moves right, positive moves left
    voltronNode.position = SCNVector3Make(voltronNode.position.x - 0, voltronNode.position.y, voltronNode.position.z);
    
    SCNCamera* camera = [SCNCamera camera];
    camera.usesOrthographicProjection = true;
    camera.orthographicScale = 100;
    camera.zNear = 0;
    camera.zFar = 1000;
    SCNNode* cameraNode = [SCNNode node];
    cameraNode.position = SCNVector3Make(0, 0, 50);
    cameraNode.camera = camera;
    SCNNode* cameraOrbit = [SCNNode node];
    [cameraOrbit addChildNode:cameraNode];
    [scene.rootNode addChildNode:cameraOrbit];
    SCNVector3 angles = cameraOrbit.eulerAngles;
    cameraOrbit.eulerAngles = SCNVector3Make(angles.x, angles.y + M_PI, angles.z);
    
    SCNNode* arm = [scene.rootNode childNodeWithName:@"Bone003" recursively:YES];
    arm.eulerAngles = SCNVector3Make(arm.eulerAngles.x, arm.eulerAngles.y + M_PI, arm.eulerAngles.z);
    
    self.sceneView.scene = scene;
    
    self.manager = [[CMMotionManager alloc] init];
    self.queue = [[NSOperationQueue alloc] init];
    self.manager.deviceMotionUpdateInterval = 0.05;
    self.handler = ^ (CMDeviceMotion* motion, NSError* error) {
//        NSLog(@"%f %f %f", motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z);
        NSLog(@"%f %f %f", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw);
        if (fabs(M_PI + motion.attitude.yaw * 4 - cameraOrbit.eulerAngles.y) < 1e-3) {
//            return;
        }
        cameraOrbit.eulerAngles = SCNVector3Make(cameraOrbit.eulerAngles.x, M_PI + motion.attitude.roll * 2, cameraOrbit.eulerAngles.z);
//        cameraOrbit.eulerAngles.y += motion.rotationRate.y
    };
    [self.manager startDeviceMotionUpdatesToQueue:self.queue withHandler:self.handler];
    
    
    [self.sceneView play:nil];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end