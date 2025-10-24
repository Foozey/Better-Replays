----------------------------------------------------------------------------------------------------
-- Better Replays by Fooze
-- An OBS Lua script to improve replays.

-- Version: 1.0.0
-- License: MIT
----------------------------------------------------------------------------------------------------

local obs = obslua
local ffi = require("ffi")
local winmm = ffi.load("Winmm")
local user32 = ffi.load("user32")
local is_restarting = false

ffi.cdef[[
    typedef void* HWND;
    typedef int BOOL;
    typedef struct { long left; long top; long right; long bottom; } RECT;
    
    BOOL GetWindowRect(HWND hWnd, RECT *lpRect);
    HWND MonitorFromWindow(HWND window, uint32_t dwFlags);
    BOOL GetMonitorInfoA(void *hMonitor, void *lpmi);
    HWND GetForegroundWindow(void);
    int GetWindowTextA(HWND hWnd, char *lpString, int nMaxCount);
    bool PlaySound(const char *pszSound, void *hmod, uint32_t fdwSound);
]]

-- Checks if the window is fullscreen or borderless
local function is_fullscreen(window)
    -- Return false if no window is given
    if not window then
        return false
    end

    local rect = ffi.new("RECT")

    -- Return false if the window isn't accessible
    if user32.GetWindowRect(window, rect) == 0 then
        return false
    end

    local monitor = user32.MonitorFromWindow(window, 1)

    -- Return false if the window isn't on a monitor
    if not monitor then
        return false
    end

    local monitor_info = ffi.new("char[40]")
    ffi.cast("int*", monitor_info)[0] = 40

    -- Return false if the monitor info can't be retrieved
    if user32.GetMonitorInfoA(monitor, monitor_info) == 0 then
        return false
    end

    -- Get the window size
    local window_width, window_height = rect.right - rect.left, rect.bottom - rect.top

    -- Get the monitor size
    local m = ffi.cast("long*", monitor_info + 4)
    local monitor_width, monitor_height = m[2] - m[0], m[3] - m[1]

    -- Compare the window size with the monitor size to determine if the window is fullscreen
    return math.abs(window_width - monitor_width) <= 3 and
        math.abs(window_height - monitor_height) <= 3
end

-- Gets the active window title
local function get_title()
    local window = user32.GetForegroundWindow()

    -- Return null if no window is active
    if not window then
        return nil, nil
    end

    -- Set the title to the window title
    local buffer = ffi.new("char[256]")
    local length = user32.GetWindowTextA(window, buffer, 256)
    local title = ffi.string(buffer, length)

    -- Known title cases that need to be modified
    local known_titles = {
        ["Minecraft"] = "Minecraft",
        ["osu!"] = "osu!",

        -- Force desktop folder with commonly fullscreen apps
        ["Google Chrome"] = "Desktop",
        ["Discord"] = "Discord",
        ["Stremio"] = "Desktop",
        ["VLC"] = "Desktop"
    }

    -- Map known titles to corrected versions
    for key, name in pairs(known_titles) do
        if title:lower():find(key:lower()) then
            return name, window
        end
    end

    return title, window
end

-- Gets the OBS recordings folder
local function get_folder()
    local config = obs.obs_frontend_get_profile_config()

    -- Return either the simple or advanced path
    return obs.config_get_string(config, "SimpleOutput", "FilePath") or
        obs.config_get_string(config, "AdvOut", "RecFilePath")
end

-- Finds the latest replay file in the recordings folder
local function get_replay(folder)
    local valid_extensions = { ".mp4", ".mov", ".mkv", ".flv" }

    for file in io.popen('dir "'..folder..'" /b /a-d /o-d'):lines() do
        for _, ext in ipairs(valid_extensions) do
            if file:lower():match(ext.."$") then
                return folder .. "\\" .. file
            end
        end
    end
end

-- Moves the replay file to a folder matching the active fullscreen window
local function move_file()
    local title, window = get_title()

    -- Sets the folder name to the window title, or defaults to "Desktop"
    local folder_name = (title and is_fullscreen(window)) and title or "Desktop"
    folder_name = folder_name:gsub("[<>:\"/\\|?*]", "")

    -- Get the recordings path, the latest replay file, and the destination folder
    local path = get_folder()
    local file = get_replay(path)
    local folder = path .. "\\Replays\\" .. folder_name

    -- Make the destination folder and move the replay file to it
    os.execute('mkdir "' .. path .. '\\Replays"')
    os.execute('mkdir "' .. folder .. '"')
    os.execute('move "' .. file .. '" "' .. folder .. '"')
end

-- Plays a replay saved notification sound effect
local function play_replay_saved_sound()
    winmm.PlaySound(script_path() .. "Replay Saved.wav", nil, 0x00020000)
end

-- Plays a notification sound effect when a recording is started
local function play_recording_started_sound()
    winmm.PlaySound(script_path() .. "Recording Started.wav", nil, 0x00020000)
end

-- Plays a notification sound effect when a recording is stopped
local function play_recording_stopped_sound()
    winmm.PlaySound(script_path() .. "Recording Stopped.wav", nil, 0x00020000)
end

-- Restarts the replay buffer
local function restart_replay_buffer()
    if obs.obs_frontend_replay_buffer_active() then
        is_restarting = true
        obs.obs_frontend_replay_buffer_stop()
    else
        obs.obs_frontend_replay_buffer_start()
    end
end

-- Runs code during replay events
function on_event(event)
    -- When the replay buffer is restarting automatically
    if is_restarting then
        if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STOPPED then
            obs.timer_add(obs.obs_frontend_replay_buffer_start, 1)
        elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STARTED then
            obs.timer_remove(obs.obs_frontend_replay_buffer_start)
            is_restarting = false
        end
    end

    -- When a replay is saved
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        move_file()
        play_replay_saved_sound()
        restart_replay_buffer()
    end

    -- When a recording is started
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        play_recording_started_sound()
    end

    -- When a recording is stopped
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        play_recording_stopped_sound()
    end
end

-- Loads the script
function script_load(settings)
    obs.obs_frontend_add_event_callback(on_event)
end