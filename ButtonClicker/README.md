# Button Clicker 2000!

A sample application that demonstrates some simple real-time multiplayer using both
invites and matchmaking with strangers. It's also compatible with the Android version
for some cross-platform button-clicking excitement! 

## Code

Button Clicker 2000 consists of a number of files that might be of interest to you:

* `AppDelegate` contains some of the code required to handle incoming notifications

* `ButtonClickerPlayer` contains a very simple class that represents our player in
the game.

* `Constants.h` contains the constants that you will need to run this game on your 
own.

* `GameModel` is the game's model. It supplies information about all the players 
in the game for your ViewController.

* `GameViewController` is the ViewController for the game itself. This contains the
gameplay elements, a scoreboard, and some debug buttons to leave the game early and
simulate a crash.

* `MPManager` is a singleton class that handles all of the multiplayer logic. It 
contains all of the GPGRealTimeRoomDelegate methods and also has delegates that
point to the lobby and game view controllers, so that it can alert them when important
messages are received from the network

* `LobbyViewController` contains methods that handle sign-in and create real-time
mutliplayer games, either through invites or through automatching.

* `Main.storyboard` is the main storyboard used by the application. We currently
use the same storyboard for both iPhone and iPad games 


## Running the sample application

To run Button Clicker 2000  on your own device, you will need to create
your own version of the game in the Play Console and copy over some information to
your Xcode project. To follow this process, perform the following steps:

1. Open up your Button Clicker project settings. Select the "Button Clicker" target and,
  on the "Summary" tab, change the Bundle Identifier from `com.example.ButtonClicker` to
  something appropriate for your Provisioning Profile. (It will probably look like
  `com.<your_company>.ButtonClicker`)
2. Click the "Info" tab and go down to the bottom where you see "URL Types". Expand
  this and change the "Identifier" and "URL Schemes" from `com.example.ButtonClicker` to
  whatever you used in Step 1.
3. Create your own application in the Play Console, as described in our [Developer
  Documentation](https://developers.google.com/games/services/console/enabling). Make
  sure you follow the "iOS" instructions for creating your client ID and linking
  your application.
    * If you have already created an application (because you tested the Android version,
  for instance), you can use that application, and just add a new linked iOS client to the same
  application.
    * Again, you will be using the Bundle ID that you created in Step 1.
    * You can leave your App Store ID blank for testing purposes.
 	* Don't forget to turn on the "Real-time multiplayer" switch!
4. If you want to try out receiving invites, you will need to get an APNS certificate
  from iTunes Connect and upload it to the developer console as well. Please review our 
  documentation for how to do this.
5. Make a note of your client ID and application ID as described in the
  documentation
6. Once that's done, open up your `Constants.h` file, and replace the `CLIENT_ID` value
  with your own OAuth2.0 client ID.
7. Go to your ButtonClicker-info.plist file and replace the `GPGApplication` value with
  the actual Applicaton ID of your game.

That's it! Your application should be ready to run!  Give it a try, and add some button-clicking
excitement to your evening!

## Known issues

* We should probably add some icons and other supporting graphics. Any artists out there?
