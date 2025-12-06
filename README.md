# 1. Install Arch Linux
- go to https://archlinux.org/download/ on your windows laptop
- download the x86_64.iso file from any of the various sources present
- download balenaetcher OR Rufus and flash the iso on to a usb stick (at least 4gb)
NOTE: This USB will get formatted!
- turn OFF the laptop on which you want to install linux and plug in the USB.
- Now turn on the laptop while spamming escape, F10, del or which ever key lets you access the bios. When in the bios, DISABLE secure boot and tpm. Go to boot options and set the usb stick as the boot device.
- Exit the bios and let your system boot. It should boot into Arch. (You may see a menu, press enter on the Arch Linux install medium)
[Do NOT do a manual install if its your first time (it can take hours of your time)]
- the moment you are able to run commands, the first command you run is `archinstall`
- wait a little, you will now be in an interactive installation config menu.
- Navigate using arrows, go to mirrors and repos -> press enter -> Select region -> select your country or the country nearest to you 
- Now go to disk config (BE VERY CAREFUL HERE) -> Partitioning -> best-effort -> select your main drive and press enter. Use EXT4. 
- go back, next up authentication -> set root password -> set it to anything, i use root itself. You will almost never use it but its essential to remember it, root is the highest privilege. Now, go to User account in authentication itself. choose your username and password (remember BOTH exactly).
- set this user account as sudo. 
- go back, Profile -> minimal 
- ensure swap zram is enabled
- Next go to network config and select use NetworkManager
- Set your timezone (Asia/Kolkata)
do not install any packages or apps right now, not even basic things such as drivers for audio, video, bluetooth (my script takes care of everything)
- select install, ensure everything is okay.
[!ATTENTION: THIS IS THE LAST TURNING BACK POINT, YOUR DRIVE WILL BE WIPED]
- Select "yes" and continue
- Give it a few minutes
- Once it loads up, select reboot and remove the USB stick while it is turning off.
- You should now load into the cli login page of arch linux

CONGRATULATIONS! You have now installed arch linux the easy way!

# 2. get my setup <the set up isnt done yet and there will be problems>
- in the login page, enter your username followed by password; you are now in the system!
- run `nmtui` to configure internet, if you run into problems at this step, contact me
- run `ping google.com` to see if your internet is working, it should be sending and receiving packets, once you confirm it, stop it by keyboard interrupt (ctrl+C)
- run `sudo pacman -S git`, enter your password when asked. This installs the git package which we'll be using next.
- after it finishes, run `git clone https://github.com/tuningfork70/Storm-altaria.git` 
- go into the folder with `cd Storm-altaria`
- use `ls` to ensure all 3 files (pkglist, install script and configs.tar.gz) are downloaded. 
- `chmod +x install.sh` this makes the script executable.
- get yourself a cup of coffee, find a book you have been wanting to read for a while and run  `./install.sh`. This process needs an uninterrupted internet connection. 
- this process will take quite a long time, every now and then it will ask you to enter your password; do it. If all goes well, you should have my rice after the script finishes executing and you reboot!


