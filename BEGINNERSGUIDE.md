# Getting Started

## macOS

1. Open Terminal. 

2. Either cd into the 'brainstormer' folder, or open a new Terminal at the folder directly (right-click > Services > New Terminal at Folder).


3. Copy and paste into terminal:

   sudo xattr -d -r com.apple.quarantine . && sudo chmod +x Setup.command brainstormer.command

4. Terminal will ask for your root/admin password. Type it in and hit enter.

   If you're unfamiliar with the above commands, here's that they do:
   - chmod makes the two .command files able to be double-clicked.
   - xattr removes the macOS flags that marks everything as 'broken' or 'unidentified'.
   - sudo runs the commands as an administrator.

5. Double click the setup wizard and follow it through.

6. Done! From here on out, you should only ever need to run 'brainstormer.command'.

## Windows

1. Open the folder.
2. Double-click `Setup.bat`.
3. If a blue "Windows protected your PC" box pops up, click **More
   info** then **Run anyway**. (Just SmartScreen being cautious about an
   unsigned script — nothing wrong with the file.)
4. Follow the setup wizard through.
5. Done! From here on out, you should only ever need to run
   `brainstormer.bat`.

## Linux

1. Open a terminal in the `brainstormer` folder (most file managers let
   you right-click inside it and choose something like "Open Terminal
   Here").
2. Copy and paste into terminal:
   
   chmod +x Setup.sh brainstormer.sh && ./Setup.sh
   
   - `chmod` makes the two `.sh` files runnable.
3. Follow the setup wizard through.
4. Done! From here on out, you should only ever need to run
   `./brainstormer.sh`.