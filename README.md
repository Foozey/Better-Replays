# Better Replays
An OBS Lua script to improve replays.

## Features
- Saves replays and recordings to subfolders based on the game being played
  - For example, `..\OBS\Replays\ARC Raiders` or `..\OBS\Recordings\Desktop`
- Plays a sound notification when a replay is saved or a recording is started/stopped
- Restarts the replay buffer when a replay is saved (this prevents overlapped replays)

## Installation
1. Download the latest version of Better Replays from the [releases](https://github.com/foozey/better-replays/releases)
2. Create a folder somewhere on your PC and extract the `Better-Replays.zip` file you downloaded
3. In OBS, go to `Tools > Scripts`, click the `+`, and locate `Better Replays.lua` from the folder you created

## Guide: Replace NVIDIA Instant Replay with OBS
If you're using NVIDIA Instant Replay, you may want to replace it with OBS for a few reasons:
- Instant Replay often disables itself, causing you to miss important moments
- Instant Replay has low audio quality and no audio tracks
- Instant Replay has very limited customization options

### Prerequisites
1. Open the NVIDIA overlay (`Alt + Z` by default) and disable `Instant Replay`
2. While on the NVIDIA overlay, click the settings icon in the top right, then `Shortcuts`
3. Using the `Delete` key, delete the shortcuts for `Toggle Instant Replay on/off` and `Save last x minutes recorded`
4. Install OBS

### Setting up OBS for replays
1. In OBS, click `Settings > Output` and set the `Output Mode` to `Advanced`
2. Click the `Replay Buffer` tab and check `Enable Replay Buffer`
3. Set the `Maximum Replay Time` to how long you want your replays to be
4. If available, set the `Maximum Memory` to how much memory you want to use
   - A higher value will result in higher quality, but a larger file size
5. Click the `Recording` tab and set the `Recording Path` to where you want your replays to be saved
6. In the left panel, click `Hotkeys` and set `Save Replay` to the key you want to use to save replays
7. Click `Apply` and `OK`
8. Click `Start Replay Buffer`

### Running OBS on startup with replays
1. Create a shortcut for OBS
2. Right-click the shortcut and select `Properties`
3. In the `Target` field, add the following to the end: `--start-replay-buffer --minimize-to-tray`
    - For example: `"C:\Program Files\obs-studio\bin\64bit\obs64.exe" --startreplaybuffer --minimize-to-tray`
4. Click `Apply` and `OK`
5. Press `Win + R` and type `shell:startup`, then click `OK`
6. Drag the shortcut you created into the `Start-up` folder

### Folders for games, sound notifications, and more
1. Install the [Better Replays](https://github.com/foozey/better-replays) script using the installation instructions on the page