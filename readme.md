# **Vector Kong** #

A vectorised version of Donkey Kong for MAME.  A hack of the original arcade game which suppresses the normal video output completely and renders high resolution vectors to the screen instead of pixels.  The techniques used could be applied to other classic arcade games.

The plugin makes use of the drawing capabilities of LUA scripting language (available in MAME from version 0.196 to current).  


![VectorKong Plugin Screenshot](https://i.imgur.com/BnjPCD9.gif)


Tested with MAME version 0.241

Compatible with all MAME versions from 0.196

  
## Installing and running
 
The Plugin is installed by copying the "vectorkong" folder into your MAME plugins folder.

The Plugin is run by adding `-plugin vectorkong` to your MAME arguments.  I also recommend that you use opengl video e.g.

```mame dkong -plugin vectorkong -video opengl```

or you can enable the plugin in your MAME configuration.


## Feedback

Please send feedback to jon123wilson@hotmail.com

Jon

![VectorKong Plugin Logo](https://i.imgur.com/TzLTdeE.gif)
