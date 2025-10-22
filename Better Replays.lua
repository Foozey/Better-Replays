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
local replay_buffer_restarting = false

ffi.cdef[[
    bool PlaySound(const char *pszSound, void *hmod, uint32_t fdwSound);
    
    typedef void* HWND;
    typedef int BOOL;
    typedef struct { long left; long top; long right; long bottom; } RECT;
    
    BOOL GetWindowRect(HWND hWnd, RECT *lpRect);
    HWND MonitorFromWindow(HWND window, uint32_t dwFlags);
    BOOL GetMonitorInfoA(void *hMonitor, void *lpmi);
    HWND GetForegroundWindow(void);
    int GetWindowTextA(HWND hWnd, char *lpString, int nMaxCount);
]]

-- Plays a notification sound effect
local function play_sound()
    winmm.PlaySound(script_path() .. "Replay Sound.wav", nil, 0x00020000)
end

-- Restarts the replay buffer
local function restart_replay_buffer()
    -- Only restart when the replay buffer is active
    if not obs.obs_frontend_replay_buffer_active() then
        return
    end

    replay_buffer_restarting = true

    -- Stop the replay buffer
    obs.obs_frontend_replay_buffer_stop()

    -- Start the replay buffer after a 500ms delay
    obs.timer_add(function()
        obs.obs_frontend_replay_buffer_start()
        replay_buffer_restarting = false
        obs.timer_remove()
    end, 500)
end

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
        ["osu!"] = "osu!"
    }

    -- Map known titles to simplified versions
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

-- Runs when a replay is saved
function on_event(event)
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        move_file()
        play_sound()

        -- If the user didn't manually stop it, restart the replay buffer
        if obs.obs_frontend_replay_buffer_active() or script_started_replay then
            restart_replay_buffer()
        end
    end
end

-- Loads the script
function script_load(settings)
    obs.obs_frontend_add_event_callback(on_event)
end