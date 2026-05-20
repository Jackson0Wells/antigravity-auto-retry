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

We recommend the **"Shortcut Method"** to keep things clean. It doesn't use any registry keys or "run at startup" watchers that might trigger antivirus warnings. It just wraps your normal IDE launch.

1. **Download & Extract**
   Download this folder and extract it somewhere safe (e.g., `C:\Tools\Antigravity-Auto-Retry`).
   *(Do not move or delete this folder once you set it up, as the shortcuts will rely on its location.)*

2. **Run Setup**
   Double-click `Setup Antigravity Auto Retry.vbs`.
   * It will automatically detect where your `Antigravity IDE.exe` is located.
   * You can choose to **"Hide PowerShell window when running"** (checked by default). If you want to see the terminal and logs while it runs, uncheck this box!
   * Check the box for **Create Desktop and Start Menu shortcuts**.
   * Click **Save** or **Save and Start**.

3. **Use the new shortcut**
   You will now see a new shortcut called **"Antigravity IDE with Auto Retry"** on your Desktop and in your Start Menu.
   Whenever you want to use the IDE with the auto-retry safety net, just launch it using this new shortcut instead of your original one.

   *(When launched via this shortcut, a background PowerShell script monitors the IDE and restarts it if it closes unexpectedly. If you manually choose "Exit" from the IDE menus, the script knows and exits cleanly without restarting.)*

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

**When the script clicks "Retry", it forces the IDE to the top of my screen. Is that normal?**
Yes! The script uses Windows UI Automation to virtually "click" the Retry button. When the app registers this interaction, Windows assumes you are actively using the application and brings it to the foreground (even if you were looking at another app like Google Chrome). It's a small side-effect of automated clicks!

**Does this script take over my mouse or keyboard?**
No. It interacts directly with the software's UI elements in the background. Your physical mouse cursor and keyboard remain completely yours to use while the script is running. 

**How do I know if it is actually monitoring my IDE?**
You can check the `core\auto-retry.log` file to see a real-time log of what the script is doing. Alternatively, you can run the setup GUI, uncheck the "Hide PowerShell window" option, and watch the monitoring happen live in the terminal!

## Detach / Uninstall

If you decide you no longer want to use the auto-retry tool:

1. Open `Setup Antigravity Auto Retry.vbs` again.
2. Click **Detach / Uninstall**. This removes the custom shortcuts from your Desktop and Start Menu and reverts everything back to normal.
3. You can now safely delete the entire folder.
