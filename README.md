# Antigravity IDE Auto Retry

This tool automatically detects when Antigravity IDE crashes or closes due to unexpected errors and transparently restarts it for you, minimizing downtime.

**Why?** If you are running long-running agent tasks (like AI coding sessions), a sudden IDE crash shouldn't stop your progress. This ensures the IDE spins right back up.

## Directory Structure

To keep things clean, the main folder only contains the essentials, while the inner workings are kept inside the `core` folder.

*   `Setup Antigravity Auto Retry.vbs` - The main GUI setup script you interact with to configure the tool and create shortcuts.
*   `README.md` - This documentation file.
*   `core/` - The folder containing all the scripts and logs that power the tool.
    *   `setup.ps1` - The actual PowerShell UI configuration script launched by the VBS file.
    *   `auto-retry.ps1` - The background monitor that watches your IDE.
    *   `launch_ide_and_retry...` - Scripts used by your shortcuts to launch both the IDE and the monitor.
    *   `config.json` - Saves your setup settings (IDE path, interval, and visibility preference).
    *   `auto-retry.log` - A text log of the tool's activity.

## Installation & Setup

<img width="607" height="287" alt="image" src="https://github.com/user-attachments/assets/8c0e0cf2-f67e-48f0-8ca4-efa2b0ea9906" />

We recommend the **"Shortcut Method"** to keep things clean. It doesn't use any registry keys or "run at startup" watchers that might trigger antivirus warnings. It just wraps your normal IDE launch.

1. **Download & Extract**
   Download this folder and extract it somewhere safe (e.g., `C:\Tools\Antigravity-Auto-Retry`).
   *(Do not move or delete this folder once you set it up, as the shortcuts will rely on its location.)*

2. **Run Setup**
   Double-click `Setup Antigravity Auto Retry.vbs`.
   * It will automatically detect where your `Antigravity IDE.exe` is located.
   * You can choose to **"Hide PowerShell window when running"** (checked by default). If you want to see the terminal and logs while it runs, uncheck this box!
   * Click one of the save buttons:
     * **Save and Start** *(recommended)* — Saves your settings AND immediately starts the background watcher. You can then just open your normal Antigravity IDE (.exe or your own shortcuts) and the auto-retry will be actively watching it!
     * **Save** — Only saves your settings. The watcher does NOT start yet.

3. **How it works after setup**
   Once you've clicked "Save and Start", the watcher silently sits in your computer's memory. You just open your normal `Antigravity IDE.exe` like you always do. The watcher spots it, monitors it, and automatically clicks "Retry" if the agent crashes. 



https://github.com/user-attachments/assets/7c371449-5867-494f-a1e0-c103d300c470



   > **Important Note:** The watcher lives in your computer's background memory. If you **restart your PC**, that memory is cleared and the watcher stops. After a reboot, simply run `Setup Antigravity Auto Retry.vbs` and click "Save and Start" again to turn the protection back on!

## Frequently Asked Questions (FAQ)

**Can I move the folder after I install it?**
Yes, but you will need to re-run the setup! The shortcuts on your Desktop and Start Menu point exactly to where the scripts are. If you move the main folder to a new location, simply double-click `Setup Antigravity Auto Retry.vbs` in the new location and click **Save** to update your shortcuts.

**Why don't I see a PowerShell window when I run it?**
By default, the tool is designed to run silently in the background so it doesn't clutter your screen. If you'd prefer to see the PowerShell terminal (to watch the logs), simply open the setup GUI, uncheck **"Hide PowerShell window when running"**, and save.

**Can I run the scripts manually without the shortcuts?**
Yes! If you prefer the command line, you can launch it manually from the `core` folder:
```powershell
.\core\launch_ide_and_retry.ps1 -IntervalMilliseconds 500
```
Or you can just double-click `core\launch_ide_and_retry.bat` to launch it with a visible terminal.

**When the script clicks "Retry", it forces the IDE to the top of my screen and interrupts my mouse if I'm dragging a window. Is that normal?**
Yes! The script uses Windows UI Automation to virtually "click" the Retry button. When the app registers this interaction, Windows immediately assumes you are actively using the IDE and aggressively brings it to the foreground. If you happen to be clicking and holding the top bar of another app (like Google Chrome) to drag it right at that exact millisecond, Windows violently steals the "focus" away from Chrome to give it to Antigravity. Because Chrome loses focus, it immediately lets go of your mouse drag. It's a small, unavoidable side-effect of automated clicks!

**Does this script take over my mouse or keyboard?**
No. It interacts directly with the software's UI elements in the background. Your physical mouse cursor and keyboard remain completely yours to use while the script is running. 

**How do I know if it is actually monitoring my IDE?**
You can check the `core\auto-retry.log` file to see a real-time log of what the script is doing. Alternatively, you can run the setup GUI, uncheck the "Hide PowerShell window" option, and watch the monitoring happen live in the terminal!

**How much CPU or RAM does this use?**
Almost zero! It is a tiny PowerShell script that sleeps for half a second, peeks at your open windows, and goes back to sleep. You will not notice it running.

**What happens if I manually close Antigravity IDE when I'm done working?**
The script is smart enough to know when the window is completely gone. If you manually close the IDE, the watcher script waits 3 seconds and then cleanly kills itself in the background so it doesn't run forever.

**Will this trigger my Windows Defender / Antivirus?**
Because this tool uses raw `.vbs` and `.ps1` scripts to interact with other programs (UI Automation), some strict antivirus settings might flag it as suspicious. This is a false positive! The code is 100% open-source, and you can open any of the files in a text editor to see exactly what it is doing.

## Detach / Uninstall

If you decide you no longer want to use the auto-retry tool:

1. Open `Setup Antigravity Auto Retry.vbs` again.
2. Click **Detach / Uninstall**. This removes the custom shortcuts from your Desktop and Start Menu and reverts everything back to normal.
3. You can now safely delete the entire folder.
