# Antigravity IDE Auto Retry

This tool automatically detects when Antigravity IDE crashes or closes due to unexpected errors and transparently clicks the "Retry" button for you, minimizing downtime.

**Why?** If you are running long-running agent tasks (like AI coding sessions), a sudden IDE crash shouldn't stop your progress. This ensures the IDE spins right back up.

## Directory Structure

To keep things clean, the main folder only contains the essentials, while the inner workings are kept inside the `core` folder.

*   `Setup Antigravity Auto Retry.vbs` - The main GUI setup script you interact with to configure and start the tool.
*   `README.md` - This documentation file.
*   `core/` - The folder containing all the scripts and logs that power the tool.
    *   `setup.ps1` - The actual PowerShell UI configuration script launched by the VBS file.
    *   `auto-retry.ps1` - The background monitor that watches your IDE.
    *   `config.json` - Saves your setup settings (interval, and visibility preference).
    *   `auto-retry.log` - A text log of the tool's activity.

## Installation & Setup

This tool runs purely in the background and attaches directly to your normal Antigravity IDE. It doesn't create any custom shortcuts or modify your installation. 

1. **Download & Extract**
   Download this folder and extract it somewhere safe (e.g., `C:\Tools\Antigravity-Auto-Retry`).
   *(Do not move or delete this folder while the watcher is running.)*

2. **Run Setup**
   Double-click `Setup Antigravity Auto Retry.vbs`.
   * You can choose to **"Hide PowerShell window when running"** (checked by default). If you want to see the terminal and logs while it runs, uncheck this box!
   * Click one of the save buttons:
     * **Save and Start** *(recommended)* — Saves your settings AND immediately starts the background watcher. You can then just open your normal Antigravity IDE (.exe or your own shortcuts) and the auto-retry will be actively watching it!
     * **Save** — Only saves your settings. The watcher does NOT start yet.

3. **How it works after setup**
   Once you've clicked "Save and Start", the watcher silently sits in your computer's background memory. You just open your normal `Antigravity IDE` like you always do. The watcher spots it, monitors it, and automatically clicks "Retry" if the agent crashes. 
   
   > **Important Note:** The watcher lives in your computer's background memory. If you **restart your PC**, that memory is cleared and the watcher stops. After a reboot, simply run `Setup Antigravity Auto Retry.vbs` and click "Save and Start" again to turn the protection back on!

## Frequently Asked Questions (FAQ)

**Can I move the folder after I start the watcher?**
No. If you want to move the folder, you should first restart your computer (or manually stop the background process), move the folder, and then run `Setup Antigravity Auto Retry.vbs` again from the new location.

**Why don't I see a PowerShell window when I run it?**
By default, the tool is designed to run silently in the background so it doesn't clutter your screen. If you'd prefer to see the PowerShell terminal (to watch the logs), simply open the setup GUI, uncheck **"Hide PowerShell window when running"**, and click Save and Start.

**When the script clicks "Retry", it forces the IDE to the top of my screen and interrupts my mouse if I'm dragging a window. Is that normal?**
Yes! The script uses Windows UI Automation to virtually "click" the Retry button. When the app registers this interaction, Windows immediately assumes you are actively using the IDE and aggressively brings it to the foreground. If you happen to be clicking and holding the top bar of another app (like Google Chrome) to drag it right at that exact millisecond, Windows violently steals the "focus" away from Chrome to give it to Antigravity. Because Chrome loses focus, it immediately lets go of your mouse drag. It's a small, unavoidable side-effect of automated clicks!

**Does this script take over my mouse or keyboard?**
No. It interacts directly with the software's UI elements in the background. Your physical mouse cursor and keyboard remain completely yours to use while the script is running. 

**How do I know if it is actually monitoring my IDE?**
You can check the `core\auto-retry.log` file to see a real-time log of what the script is doing. Alternatively, you can run the setup GUI, uncheck the "Hide PowerShell window" option, and watch the monitoring happen live in the terminal!

**How much CPU or RAM does this use?**
Almost zero! It is a tiny PowerShell script that sleeps for half a second, peeks at your open windows, and goes back to sleep. You will not notice it running.

**What happens if I manually close Antigravity IDE when I'm done working?**
The script is smart enough to know when the window is completely gone. If you manually close the IDE, the watcher script waits a few seconds and then cleanly kills itself in the background so it doesn't run forever.

**Will this trigger my Windows Defender / Antivirus?**
Because this tool uses raw `.vbs` and `.ps1` scripts to interact with other programs (UI Automation), some strict antivirus settings might flag it as suspicious. This is a false positive! The code is 100% open-source, and you can open any of the files in a text editor to see exactly what it is doing.

**I am seeing `updateWindowsJumpList#setJumpList` or `jump_list.cc` errors in the logs. Is something broken?**
No, this is completely normal and not an issue with the auto-retry script! These logs come directly from the IDE itself. They appear when your Windows Privacy Settings have "Show recently opened items in Start, Jump Lists, and File Explorer" turned off. The IDE tries to update its recent files list, gets denied by Windows, and prints this error. It does not affect the IDE or the auto-retry functionality at all. You can safely ignore it.

## Uninstall

If you decide you no longer want to use the auto-retry tool, simply restart your computer (so the background process ends) and then delete the folder. It leaves no trace on your system!
