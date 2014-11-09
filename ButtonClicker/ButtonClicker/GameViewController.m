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
#include "stdlib.h"

@import CoreMotion;
@import SceneKit;

@interface GameViewController () <MPGameDelegate> {
  NSArray *_scoreboardViews;
}
@property(nonatomic) GameModel *model;
@property(nonatomic, weak) NSTimer *updateTimer;
@property (weak, nonatomic) IBOutlet SCNView* sceneView;

@property (strong) CMMotionManager* manager;
@property (strong) NSOperationQueue* queue;
@property (strong) CMDeviceMotionHandler handler;
@property (strong) SCNNode* voltronNode;

@property float firstRenderTime;
@property float lastRenderTime;
@property float movementX;

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

  // We'll just start for now
  [self startGame];
    
    
    NSBundle* bundle = [NSBundle mainBundle];
    id urlPath = [bundle pathForResource:@"robot with bones" ofType:@"dae"];
    id url = [NSURL fileURLWithPath:urlPath];
    SCNScene* scene = [SCNScene sceneWithURL:url options:nil error:nil];
    
    
    SCNPhysicsWorld* world = scene.physicsWorld;
    world.contactDelegate = self;
    
    NSLog(@"%@", [scene.rootNode description]);
    self.voltronNode = [SCNNode node];
    NSArray* childNodes = scene.rootNode.childNodes;
    for (SCNNode* node in childNodes) {
        [node removeFromParentNode];
        [self.voltronNode addChildNode:node];
    }
    [scene.rootNode addChildNode:self.voltronNode];
    // negative on x moves right, positive moves left
    self.voltronNode.position = SCNVector3Make(self.voltronNode.position.x - 0, self.voltronNode.position.y, self.voltronNode.position.z);
    self.voltronNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithNode:self.voltronNode options:nil]];
    self.voltronNode.name = @"voltron";
    
    SCNCamera* camera = [SCNCamera camera];
    camera.usesOrthographicProjection = true;
    camera.orthographicScale = 140;
    camera.zNear = 0;
    camera.zFar = 1000;
    SCNNode* cameraNode = [SCNNode node];
    cameraNode.position = SCNVector3Make(0, 0, 200);
    cameraNode.camera = camera;
    SCNNode* cameraOrbit = [SCNNode node];
    [cameraOrbit addChildNode:cameraNode];
    [scene.rootNode addChildNode:cameraOrbit];
    SCNVector3 angles = cameraOrbit.eulerAngles;
    cameraOrbit.eulerAngles = SCNVector3Make(angles.x, angles.y + M_PI, angles.z);
    
    SCNNode* arm = [scene.rootNode childNodeWithName:@"Bone003" recursively:YES];
    arm.eulerAngles = SCNVector3Make(arm.eulerAngles.x, arm.eulerAngles.y + M_PI, arm.eulerAngles.z);
    
    self.sceneView.scene = scene;
    
    __weak typeof(self) weakSelf = self;
    self.manager = [[CMMotionManager alloc] init];
    self.queue = [[NSOperationQueue alloc] init];
    self.manager.deviceMotionUpdateInterval = 0.05;
    self.handler = ^ (CMDeviceMotion* motion, NSError* error) {
//        NSLog(@"%f %f %f", motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z);
//        NSLog(@"%f %f YAWWW: %f", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw);
        if (fabs(M_PI + motion.attitude.yaw * 4 - cameraOrbit.eulerAngles.y) < 1e-3) {
//            return;
        }
        cameraOrbit.eulerAngles = SCNVector3Make(cameraOrbit.eulerAngles.x, M_PI + motion.attitude.roll * 2, cameraOrbit.eulerAngles.z);
        
        if (motion.attitude.yaw > 0.2) {
            weakSelf.movementX = 100;
        } else if (motion.attitude.yaw < -0.2) {
            weakSelf.movementX = -100;
        } else {
            weakSelf.movementX = 0;
        }
//        cameraOrbit.eulerAngles.y += motion.rotationRate.y
    };
    [self.manager startDeviceMotionUpdatesToQueue:self.queue withHandler:self.handler];
    
    self.sceneView.delegate = self;
    
    [self.sceneView play:nil];
    self.firstRenderTime = -1;
    self.lastRenderTime = 0;
    self.movementX = 0;
}

- (void)renderer:(id<SCNSceneRenderer>)aRenderer updateAtTime:(NSTimeInterval)time {
    if (self.firstRenderTime == -1) {
        self.firstRenderTime = time;
    }
    time -= self.firstRenderTime;
    float stoneTime = 5;
    float x = 20;
//    float x = arc4random_uniform(20) - 10;
    float y = 200;
    float z = 0;
    float dx = 0;
    float dy = -40;
    int stoneId = 0;
//    NSLog(@"wtf");
    float newX = self.voltronNode.position.x + (time - self.lastRenderTime) * self.movementX;
    newX = MIN(newX, 100);
    newX = MAX(newX, -100);
    self.voltronNode.position = SCNVector3Make(newX, self.voltronNode.position.y, self.voltronNode.position.z);
    if (time > stoneTime) {
        SCNNode* rootNode = self.sceneView.scene.rootNode;
        NSString* nodeName = [NSString stringWithFormat:@"stone%d", stoneId];
        SCNNode* node = [rootNode childNodeWithName:nodeName recursively:true];
        BOOL found = node;
        if (!node) {
            node = [SCNNode node];
            node.geometry = [SCNSphere sphereWithRadius:8];
            node.name = nodeName;
            node.physicsBody = [SCNPhysicsBody kinematicBody];
        }
        node.position = SCNVector3Make(x + (time - stoneTime) * dx, y + (time - stoneTime) * dy, z);
        
//        node.position = SCNVector3Make(0, 0, 0);
        if (!found) {
            [self.sceneView.scene.rootNode addChildNode:node];
        }
    }
    self.lastRenderTime = time;
}

- (void) physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact {
    NSLog(@"collision");
    SCNNode* a = contact.nodeA;
    SCNNode* b = contact.nodeB;
    int stones = 0;
    if ([a.name containsString:@"stone"]) {
        ++stones;
    }
    if ([b.name containsString:@"stone"]) {
        ++stones;
    }
    if (stones == 1) {
        SCNNode* voltron;
        if ([a.name containsString:@"stone"]) {
            voltron = b;
        } else {
            voltron = a;
        }
        voltron.hidden = true;
        
    }
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end