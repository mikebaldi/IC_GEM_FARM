[< Return to the Readme](../Readme.md)

# Setting Idle Champions game location for Steam

## Overview

The scripts inside `IC Script Hub` need to know where your game is installed.

> ⚠️ There is a good chance that you don't need to do anything here if you are using Steam. Try the script and return here if it doesn't work. ⚠️

## Opening `IC Script Hub`

Navigate to the folder you cloned the repo into using Windows Explorer. 

You can press `Ctrl+Shift+F` from within GitHub Desktop if you used that to clone the repository.

Double-click on `ICScriptHub.ahk` in the explorer window that opens to launch `IC Script Hub`.

You should see the `IC Script Hub` window and it should look something like this:

![IC Script Hub window](../docimages/ic-script-hub.png)

You may need to [install or update AutoHotKey](https://www.autohotkey.com/) if you receive an error at this point.

## Setting the Steam game location
### Step 0: Make sure your addons are enabled

You'll want to make sure you have the game shortcut addon enabled. Click into the addons tab and ensure the addon highlighted by the green arrow is enabled and saved.

I recommend making sure the ones with the yellow arrow are also enabled too.

![Addons tab](../docimages/addons-tab.png)

It should reload your Script Hub for you but should you ever want to do a manual reload (to reset the stats screen for instance, just remember to reconnect to your Gem Farm script if you do this) hit the reload button:

![Reload button](../docimages/reload-script-hub.png)

### Step 1: Grab the shortcut you need

1. Open the `Steam client`
2. Go to your `Library`
3. Right click the `Idle Champions` game entry in your `Library` and pick `Properties`

![Properties in Steam](../docimages/steam-properties.png)

4. Click `Local Files` in the left and then `Browse...`

![Open in Explorer](../docimages/steam-local-files.png)

5. Click in the whitespace in the Windows Explorer path

![Explorer window](../docimages/steam-explorer.png)

6. Copy the file location that appears

![Explorer window](../docimages/steam-local-url.png)

### Step 2: Populate the location in `IC Script Hub`

1. Return to your `IC Script Hub` window
2. Click the `Briv Gem Farm` tab
3. Click the `Change Game Location` button at the bottom of the `Briv Gem Farm` window
4. Paste the link copied the steps above into the `Install Path` box adding a slash to the end of it if missing, and leave the `Install Exe` box as `IdleDragons.exe`
5. Click `Save and Close`

## Now that's done, what can I do with this thing?

[Let's find out.](an-introduction-to-ic-script-hub.md)