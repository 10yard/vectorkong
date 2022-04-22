# **Vectorising Donkey Kong** #

I'm working on a vectorised version of Donkey Kong for MAME.  I'll be hacking the original game,  suppressing the normal video output completely and rendering high resolution vectors to the screen instead of pixels.  The techniques I'll be  using could be applied to other classic arcade games.  I'm choosing Donkey Kong because I am very familiar with the disassembled code and mechanics of the game.

My plan is to use the simple vector drawing capabilities of MAME LUA scripting language (available in MAME from version 0.196 to current).  


![VectorKong Plugin Screenshot](https://i.imgur.com/BnjPCD9.gif)


Tested with latest MAME version 0.242

Compatible with all MAME versions from 0.196

  
## Installing and running
 
It's work in progress.  You can check out what is done so-far by copying the "vectorkong" folder into your MAME plugins folder.

The Plugin is run by adding `-plugin vectorkong` to your MAME arguments e.g.

```mame dkong -plugin vectorkong```  


## Feedback

Please send feedback to jon123wilson@hotmail.com

Jon

