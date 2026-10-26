TIDE: a focus timer that plays your Spotify music
==================================================

What it does
------------
* A focus and break timer you can set to any length. Presets for 25/5, 50/10
  and 90/20, or set your own, plus a long break after a number of rounds.
* The whole window fills up from the bottom as a session passes, so you can
  read it from the corner of your eye on a second screen.
    Dark room       = focus
    Light room      = break
    Hollow numbers  = the timer isn't running
* Plays your Spotify music right in the Tide window, or controls Spotify on
  your PC or phone. The music pauses when a break starts and picks up where
  it left off when you focus again (you can change this in Settings).
* Browse your playlists and liked songs, search, see the queue, skip,
  shuffle, repeat, like songs, change the volume and switch devices.
* The room takes its colour from the album art of whatever is playing.


You need
--------
* Windows 10 or 11 with Chrome or Edge.
* Spotify Premium. Spotify only lets Premium accounts use developer apps.


First-time setup (about 5 minutes)
----------------------------------
1. Right-click the downloaded zip, choose Properties, tick "Unblock" at the
   bottom and click OK. Then extract it somewhere it can stay, for example
   Documents\Tide.

2. Double-click "Start Tide.bat". A small black window opens and Tide opens
   in your browser. If Windows says "Windows protected your PC", click
   "More info" and then "Run anyway".

3. Tide walks you through connecting Spotify. In short:
   a. Go to https://developer.spotify.com/dashboard and log in.
   b. Click "Create app". The name and description can be anything.
      Redirect URI:  http://127.0.0.1:8457/callback
      (exactly this. Spotify rejects "localhost".)
      Tick "Web API" and "Web Playback SDK", agree to the terms and save.
   c. Open the app's Settings, copy the Client ID, paste it into Tide and
      click Connect Spotify. Then click Agree on Spotify's page.

4. Click Music, pick a playlist and press Start focus.


Keep it on your second monitor
------------------------------
* Install Tide as an app so it gets its own window:
    Edge:   ... menu > Apps > Install this site as an app
    Chrome: menu > Cast, save and share > Install page as app
  (or the install icon at the right end of the address bar, or the Install
  button in Tide's Settings).
* Drag the Tide window onto your second monitor. Right-click its taskbar icon
  and choose "Pin to taskbar".
* After the first run you don't need the black launcher window. Open Tide
  from the taskbar or Start menu. If it ever says the page can't be reached,
  double-click "Start Tide.bat" again.


Everyday use
------------
Settings (the sliders icon, or press the comma key):
  session lengths, rounds before a long break, auto-start, what the music
  does on a break (pause / play a break playlist / turn down / keep
  playing), a focus playlist, the chime, desktop notifications and keeping
  the screen on.

Keyboard:
  Space        start or pause the timer
  S            skip to the next session
  R            reset (press again to start over from round 1)
  M            play or pause the music
  Left/Right   previous / next song
  L            open the music library
  ,            settings

The device button under the song moves the music between Tide and Spotify
on your other devices.


If something goes wrong
-----------------------
"INVALID_CLIENT: Invalid redirect URI"
  The redirect URI in your Spotify app must be exactly
  http://127.0.0.1:8457/callback

"User not registered" / your account isn't registered for the app
  In the Spotify dashboard open your app > Settings > User Management and
  add the email address of your Spotify account.

The music doesn't start by itself after a break
  Click anywhere in Tide once. Browsers block sound until you've clicked on
  the page.

No sound in the Tide window
  Use Chrome or Edge. Some privacy or ad-blocking extensions block Spotify's
  player, so try turning them off for 127.0.0.1. You can still play music
  through the Spotify app and control it from Tide with the device button.

"Another program is using port 8457"
  Open server.ps1 in Notepad, change  $Port = 8457  near the top, and change
  the redirect URI in your Spotify app to use the same number.

PowerShell scripts are blocked (common on school or work computers)
  If Python is installed, open a terminal in the Tide folder and run:
    py -m http.server 8457 --bind 127.0.0.1 --directory app
  then open http://127.0.0.1:8457 in your browser.

Tide stops in a background tab
  Chrome's Memory Saver can put hidden tabs to sleep. Installing Tide as an
  app avoids this, or add 127.0.0.1 under Chrome Settings > Performance >
  "Always keep these sites active".

Spotify asks you to connect again
  Spotify sign-ins last up to six months. Click Connect and you're back.


Privacy
-------
Everything runs on your own computer. Tide talks only to Spotify. Your
Spotify sign-in is kept in your browser's storage for this site, and
Settings > Disconnect removes it.


What's in the folder
--------------------
Start Tide.bat   double-click this to start Tide
server.ps1       the small local web server it starts (built-in PowerShell)
app\             Tide itself
