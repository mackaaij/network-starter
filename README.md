# Network Starter

[AutoIt](https://www.autoitscript.com/site/) script for mobile workers to run programs depending on the available network. Mobile workers often use a laptop in multiple network environments. Think about the office, at home, stand alone or at the customer.

At the office the mobile user might use a synchronization tool to keep the laptop up-to-date with files on the network. And maybe a specific instant messaging application which only runs at the office due to the use of an internal server. Running such programs automatically using Windows Start menu is not really an option since the applications will always run, also when the required servers are not available. If the tools are supposed to be started by hand then they are likely to be forgotten.

Network Starter script offers a solution by running programs dependent on the network environment of the laptop.

## How it works in general
Create a folder for each network environment, naming it to a servername (hostname) unique to this network environment. At home this might be the name of the router or main PC. And at the office it could be the main server.

Place shortcuts to applications which should be started in this network environment in the respective folder.

Network Starter script tries to contact each folder (hostname or IP address) using the network command ping. If this works it concludes the laptop is connected to this network environment. A list of all applications in the corresponding subfolder is presented to the user in a popup. The user can cancel execution of the application by pressing Cancel within 10 seconds.

If there are no programs to start then Network Starter script will try again for twelve times, allowing a (wireless) network connection to be established. After these attempts Network Starter script remains in the system tray allowing for a manual Rescan by the user.

## Configuration
The script is easy to configure following these three simple steps.

1. Save Network Starter script somewhere on the laptop (not in the Start menu however).
2. Create folders for each environment and create shortcuts to applications to run in this environment in the corresponding folder. The default location for the folders would be the same folder Network Starter script resides, as the script uses this folder as a default base location.
3. Create a shortcut to Network Starter script in the Start menu. Windows open the Start menu as an Explorer window if you type the following in Start>Run: %userprofile%\Start Menu \Programs\Startup.

Tip #1: If you use Network Starter script in a controlled computer environment in which you roll out applications to laptops, centralise the use of the executable. Create a shortcut to the executable in the Start menu. This enables you to distribute new versions quite easily if required. It also enables you to configure which applications to run in what environment at a single location. The mobile worker may configure other applications to run by changing the shortcut. If a folder is passed to the script as a parameter then this folder will be used as a base location.

Tip #2: If you'd rather not start Network Starter script with Windows because you don't like all programs to run in a certain configuration, place a shortcut on the Windows Quick Launch bar (next to the Start button). You are now in full control to run your stuff with a single click.

Tip #3: If ping traffic is blocked by a firewall (for instance in office environments) Network Starter script tries to resolve the hostname into an IP address. In this case Network Starter script ignores folders which are named as an IP address.