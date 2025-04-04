This is a toy todo list made using Odin, Raylib, and Clay. 

It's not meant to be anything crazy, but rather a learning project. As such, it's not a polished project at all. 

DELETE -> Clears the textbox
BACKSPACE -> Removes the last character types
ENTER -> Adds the types input into the list. 

There is a 'button' (really just a blank square after every todo list item. That button removes the item from the list. 

There is no saving or loading functionality.


How to build:

run 'odin run .' from the directory. Make sure the font is in the same directory of the main.odin file. And that the clay renderer is that there as well. 
Make sure you have clay as well. By default, it's set to look in once directory up. So:

Folder
- clay-bindings
- project
-   src code

The clay bidnings are not included in this repo so you'll need to download them yourself from here:  https://github.com/nicbarker/clay

There is a .exe you can run as well, included in this repo. 
