-- Vector Kong by Jon Wilson (10yard)
--
-- Tested with latest MAME version 0.242
-- Compatible with MAME versions from 0.196
--
-- Minimum start up arguments:
--   mame dkong -plugin vectorkong
-----------------------------------------------------------------------------------------

local exports = {}
exports.name = "vectorkong"
exports.version = "0.1"
exports.description = "Vector Kong"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local vectorkong = exports

function vectorkong.startplugin()
	local mame_version
	local vector_count, vector_color
	local game_mode, last_mode, enable_zigzags

	-- Constants
	local MODE, STAGE, LEVEL = 0x600a, 0x6227, 0x6229
	local VRAM_TR, VRAM_BL = 0x7440, 0x77bf  -- top-right and bottom-left corner bytes
    local WHITE, YELLOW, ORANGE, RED = 0xffffffff, 0xfff0f050, 0xfff4ba15, 0xfff00000

	-- Vector character library
	local BR = 0xffff  -- break in a vector chain
	local vector_lib = {}
	vector_lib[0x00] = {0,2,0,4,2,6,4,6,6,4,6,2,4,0,2,0,0,2} -- 0
	vector_lib[0x01] = {0,0,0,6,BR,BR,0,3,6,3,5, 1} -- 1
	vector_lib[0x02] = {0,6,0,0,5,6,6,3,5,0} -- 2
	vector_lib[0x03] = {1,0,0,1,0,5,1,6,2,6,3,5,3,2,6,6,6,1} -- 3
	vector_lib[0x04] = {0,5,6,5,2,0,2,7} -- 4
	vector_lib[0x05] = {1,0,0,1,0,5,2,6,4,5,4,0,6,0,6,5} -- 5
	vector_lib[0x06] = {3,0,1,0,0,1,0,5,1,6,2,6,3,5,3,0,6,2,6,5} -- 6
	vector_lib[0x07] = {6,0,6,6,0,2} -- 7
	vector_lib[0x08] = {2,0,0,1,0,5,2,6,5,0,6,1,6,4,5,5,2,0} -- 8
	vector_lib[0x09] = {0,1,0,4,2,6,5,6,6,5,6,1,5,0,4,0,3,1,3,6} -- 9
	vector_lib[0x11] = {0,0,4,0,6,3,4,6,0,6,BR,BR,2,6,2,0}  -- A
	vector_lib[0x12] = {0,0,6,0,6,5,5,6,4,6,3,5,2,6,1,6,0,5,0,0,BR,BR,3,0,3,4}  -- B
	vector_lib[0x13] = {1,6,0,5,0,2,2,0,4,0,6,2,6,5,5,6} -- C
	vector_lib[0x14] = {0,0,6,0,6,4,4,6,2,6,0,4,0,0} -- D
	vector_lib[0x15] = {0,5,0,0,6,0,6,5,BR,BR,3,0,3,4} -- E
	vector_lib[0x16] = {0,0,6,0,6,6,BR,BR,3,0,3,5} -- F
	vector_lib[0x17] = {3,4,3,6,0,6,0,2,2,0,4,0,6,2,6,6} -- G
	vector_lib[0x18] = {0,0,6,0,BR,BR,3,0,3,6,BR,BR,0,6,6,6} -- H
	vector_lib[0x19] = {0,0,0,6,BR,BR,0,3,6,3,BR,BR,6,0,6,6} -- I
	vector_lib[0x1a] = {1,0,0,1,0,5,1,6,6,6} -- J
	vector_lib[0x1b] = {0,0,6,0,BR,BR,3,0,0,6,BR,BR,3,0,6,6} -- K
	vector_lib[0x1c] = {6,0,0,0,0,5} -- L
	vector_lib[0x1d] = {0,0,6,0,2,3,6,6,0,6}  -- M
	vector_lib[0x1e] = {0,0,6,0,0,6,6,6} -- N
	vector_lib[0x1f] = {1,0,5,0,6,1,6,5,5,6,1,6,0,5,0,1,1,0} -- O
	vector_lib[0x20] = {0,0,6,0,6,5,5,6,3,6,2,5,2,0} -- P
	vector_lib[0x21] = {1,0,5,0,6,1,6,5,5,6,2,6,0,4,0,1,1,0,BR,BR,0,6,2,3} -- Q
	vector_lib[0x22] = {0,0,6,0,6,5,5,6,4,6,2,3,2,0,2,3,0,6} -- R
	vector_lib[0x23] = {1,0,0,1,0,5,1,6,2,6,4,0,5,0,6,1,6,4,5,5} -- S
	vector_lib[0x24] = {6,0,6,6,BR,BR,6,3,0,3} -- T
	vector_lib[0x25] = {6,0,1,0,0,1,0,5,1,6,6,6} -- U
	vector_lib[0x26] = {6,0,3,0,0,3,3,6,6,6} -- V
	vector_lib[0x27] = {6,0,2,0,0,1,4,3,0,5,2,6,6,6}  -- W
	vector_lib[0x28] = {0,0,6,6,3,3,6,0,0,6} -- X
	vector_lib[0x29] = {6,0,3,3,6,6,BR,BR,3,3,0,3} -- Y
	vector_lib[0x2a] = {6,0,6,6,0,0,0,6} -- Z
	vector_lib[0x2b] = {0,0,1,0,1,1,0,1,0,0}  -- dot
	vector_lib[0x2c] = {3,0,3,5} -- dash
	vector_lib[0x2d] = {5,0,5,6} -- underscore
	vector_lib[0x2e] = {4,3,4,3,BR,BR,2,3,2,3} -- colon
	vector_lib[0x2f] = {5,0,5,6} -- Alt underscore
	vector_lib[0x30] = {0,2,2,0,4,0,6,2} -- Left bracket
	vector_lib[0x31] = {0,2,2,4,4,4,6,2} -- Right bracket
	vector_lib[0x34] = {2,0,2,5,BR,BR,4,0,4,5} -- equals
	vector_lib[0x35] = {3,0,3,5} -- dash
	vector_lib[0x44] = {0,5,4,5,4,7,2,7,0,8,BR,BR,2,5,2,7,BR,BR,4,10,1,10,0,11,0,12,1,13,4,13,BR,BR,0,15,4,15,4,17,2,17,2,18,0,18,0,15,BR,BR,2,15,2,17,BR,BR,0,23,0,21,4,21,4,23,BR,BR,2,21,2,22,BR,BR,0,25,4,25,0,28,4,28,BR,BR,0,30,4,30,4,32,3,33,1,33,0,32,0,30} -- rub / end
	vector_lib[0x49] = {0,4,2,2,5,2,7,4,7,8,5,10,2,10,0,8,0,4,BR,BR,2,7,2,5,5,5,5,7} -- copyright
	vector_lib[0x6c] = {2,0,2,4,3,5,4,4,5,5,6,4,6,0,2,0,BR,BR,4,4,4,0,BR,BR,3,7,2,8,2,11,3,12,5,12,6,11,6,8,5,7,3,7,BR,BR,2,14,6,14,2,19,6,19,BR,BR,6,21,3,21,2,22,2,25,3,26,6,26,BR,BR,2,28,2,31,4,31,4,28,5,28,6,29,6,31,BR,BR,6,-2,6,-5,-12,-5,-12,36,6,36,6,33,BR,BR,0,-3,-10,-3,-10,34,0,34,0,-3} -- bonus
	vector_lib[0x70] = vector_lib[0x00] -- Alternative 0-9
	vector_lib[0x71] = vector_lib[0x01] --
	vector_lib[0x72] = vector_lib[0x02] --
	vector_lib[0x73] = vector_lib[0x03] --
	vector_lib[0x74] = vector_lib[0x04] --
	vector_lib[0x75] = vector_lib[0x05] --
	vector_lib[0x76] = vector_lib[0x06] --
	vector_lib[0x77] = vector_lib[0x07] --
	vector_lib[0x78] = vector_lib[0x08] --
	vector_lib[0x79] = vector_lib[0x09] --
	vector_lib[0x80] = vector_lib[0x00] -- Alternative 0-9
	vector_lib[0x81] = vector_lib[0x01] --
	vector_lib[0x82] = vector_lib[0x02] --
	vector_lib[0x83] = vector_lib[0x03] --
	vector_lib[0x84] = vector_lib[0x04] --
	vector_lib[0x85] = vector_lib[0x05] --
	vector_lib[0x86] = vector_lib[0x06] --
	vector_lib[0x87] = vector_lib[0x07] --
	vector_lib[0x88] = vector_lib[0x08] --
	vector_lib[0x89] = vector_lib[0x09] --
	vector_lib[0x8a] = vector_lib[0x1d] -- Alternative M's
	vector_lib[0x8b] = vector_lib[0x1d] --
	vector_lib[0x9f] = {2,0,0,2,0,13,2,15,5,15,7,13,7,2,5,0,2,0,BR,BR,5,3,5,7,BR,BR,5,5,2,5,BR,BR,2,8,5,8,4,10,5,12,2,12} -- TM
	vector_lib[0xb0a] = {0,0,0,8,BR,BR,6,0,6,8} -- Simple Block for Title Screen
	vector_lib[0xb0b] = {4,2,3,3,BR,BR,4,3,3,2} -- Rivet block
	vector_lib[0xb0] = vector_lib[0xb0a]
	vector_lib[0xb1] = {0,0,7,0,7,7,0,7,0,0} -- Box
	vector_lib[0xb7] = {0,0,1,0,1,1,6,1,6,0,7,0,7,2,6,2,6,4,7,4,7,6,6,6,6,5,1,5,1,6,0,6,0,0} -- Rivet
	vector_lib[0xdd] = {0,0,7,0,BR,BR,4,0,4,4,BR,BR,1,4,7,4,BR,BR,2,9,1,6,7,6,7,9,BR,BR,5,6,5,9,BR,BR,7,11,2,11,3,14,BR,BR,3,16,7,16,7,18,6,19,5,18,5,16,BR,BR,7,22,5,21,BR,BR,3,21,3,21} -- Help (big H)
	vector_lib[0xed] = {7,0,5,0,BR,BR,6,0,6,4,BR,BR,7,4,4,4,BR,BR,7,9,7,6,4,6,3,9,BR,BR,5,6,5,9,BR,BR,7,11,3,11,2,14,BR,BR,1,16,7,16,7,19,3,19,3,16,BR,BR,7,22,2,21,BR,BR,0,20,0,21} -- Help (little H)
	vector_lib[0xfb] = {5,1,6,2,6,5,5,6,4,6,2,3,BR,BR,0,3,0,3} -- question mark
	vector_lib[0xfd] = {-1,0,8,0,BR,BR,-1,-1,8,-1} -- vertical line
	vector_lib[0xfe] = {0,0,7,0,7,7,0,7,0,0} -- cross
	vector_lib[0xff] = {5,2,7,2,7,4,5,4,5,2,BR,BR,5,3,2,3,0,1,BR,BR,2,3,0,5,BR,BR,4,0,3,1,3,5,4,6} -- jumpman / stick man
	-- non character objects:
	vector_lib["oilcan"] = {1,1,15,1,BR,BR,1,15,15,15,BR,BR,5,1,5,15,BR,BR,12,1,12,15,BR,BR,7,4,10,4,10,7,7,7,7,4,BR,BR,7,9,10,9,BR,BR,7,13,7,11,10,11,BR,BR,15,0,16,0,16,16,15,16,15,0,BR,BR,1,0,0,0,0,16,1,16,1,0}
	vector_lib["hammer"] = {5,0,7,0,8,1,8,8,7,9,5,9,4,8,4,1,5,0,BR,BR,4,4,0,4,0,5,4,5,BR,BR,8,4,9,4,9,5,8,5}
	vector_lib["barrel"] = {3,0,12,0,15,2,15,7,12,9,3,9,0,7,0,7,0,2,3,0,BR,BR,1,2,1,7,BR,BR,14,2,14,7,BR,BR,2,3,13,3,BR,BR,2,6,13,6}
	vector_lib["flames"] = {0,4,2,2,3,3,8,0,4,5,5,6,9,4,5,8,4,7,2,10,2,11,4,12,9,10,4,14,0,12}

	function initialize()
		mame_version = tonumber(emu.app_version())
		if mame_version >= 0.196 then
			if type(manager.machine) == "userdata" then mac = manager.machine else mac =  manager:machine() end
		else
			print("ERROR: The vectorkong plugin requires MAME version 0.196 or greater.")
		end
		if mac ~= nil then
			scr = mac.screens[":screen"]
			cpu = mac.devices[":maincpu"]
			mem = cpu.spaces["program"]
		end
	end

	function main()
		if cpu ~= nil then
			vector_count = 0
			vector_color = WHITE
			game_mode = read(MODE)

			cls()

			-- skip the intro scene and stay on girders stage
			if game_mode == 0x07 then write(MODE, 0x08) end
			--if game_mode == 0x08 and last_mode == 0x16 then debug_stay_on_girders() end

			-- handle stage backgrounds
			if game_mode == 0x06 then draw_title_screen() end
			if read(VRAM_BL, 0xf0) then draw_girder_stage() end
			if read(VRAM_BL, 0xb0) then draw_rivet_stage() end

			draw_vector_characters()

			--debug_limits(1000)
			debug_vector_count()
			last_mode = game_mode
		end
	end

	function draw_title_screen()
		-- use simple block on title screen
		vector_lib[0xb0] = vector_lib[0xb0a]
	end

	function draw_girder_stage()
		enable_zigzags = true
		-- 1st girder
		draw_girder(  1,   0,   1, 111, "R")  -- flat section
		draw_girder(  1, 111,   8, 223, "L")  -- sloped section
		draw_ladder(  8,  80,   8) -- broken ladder bottom
		draw_ladder( 32,  80,   4) -- broken ladder top
		draw_ladder( 13, 184,  17) -- right ladder
		draw_oilcan_and_flames(8, 16)

		-- 2nd Girder
		draw_girder( 41,   0,  29, 207)
		draw_ladder( 46,  32,  17)  -- left ladder
		draw_ladder( 42,  96,  25)  -- right ladder
		draw_object("hammer", 56, 168)

		-- 3rd Girder
		draw_girder( 62,  16,  74, 223)
		draw_ladder( 72,  64,   9)  -- broken ladder bottom
		draw_ladder( 96,  64,   7)  -- broken ladder top
		draw_ladder( 75, 112,  25)  -- middle ladder
		draw_ladder( 79, 184,  17)  -- right ladder

		-- 4th Girder
		draw_girder(107,   0,  95, 207)
		draw_ladder(112,  32,  17)  -- left ladder
		draw_ladder(110,  72,  21)  -- middle ladder
		draw_ladder(104, 168,   9)  -- broken ladder bottom
		draw_ladder(128, 168,   9)  -- broken ladder top

		-- 5th girder
		draw_girder(128,  16, 140, 223)
		draw_ladder(139,  88,  13)  -- broken ladder bottom
		draw_ladder(160,  88,   5)  -- broken ladder top
		draw_ladder(145, 184,  17)  -- right ladder
		draw_object("hammer", 148,  17)

		-- 6th girder
		draw_girder(165,   0, 165, 143, "R")  -- flat section
		draw_girder(165, 143, 161, 207, "L")  -- sloped section
		draw_ladder(172,  64,  52)  -- left ladder
		draw_ladder(172,  80,  52)  -- middle ladder
		draw_ladder(172, 128,  21)  -- right ladder
		draw_object("barrel", 173, 0)
		draw_object("barrel", 173, 10)
		draw_object("barrel", 189, 0)
		draw_object("barrel", 189, 10)

		-- Pauline's girder
		draw_girder(193,  88, 193, 136, "L")
	end

	function draw_rivet_stage()
		enable_zigzags = false
		-- alternative block for this stage
		vector_lib[0xb0] = vector_lib[0xb0b]

		-- 1st floor
		draw_girder(  1,   0,   1, 223)
		draw_ladder( 8, 8,  33) -- left ladder
		draw_ladder( 8, 104,  33) -- middle ladder
		draw_ladder( 8, 208,  33) -- right ladder

		-- 2nd floor
		draw_girder(  41,   8,   41, 56)
		draw_girder(  41,   64,   41, 160)
		draw_girder(  41,   168,   41, 216)
		draw_ladder( 48, 16,  33) -- ladder 1
		draw_ladder( 48, 72,  33) -- ladder 2
		draw_ladder( 48, 144,  33) -- ladder 3
		draw_ladder( 48, 200,  33) -- ladder 4

		-- 3rd floor
		draw_girder(  81,   16,   81, 56)
		draw_girder(  81,   64,   81, 160)
		draw_girder(  81,   168,   81, 208)
		draw_ladder( 88, 24,  33) -- left ladder
		draw_ladder( 88, 104,  33) -- middle ladder
		draw_ladder( 88, 192,  33) -- right ladder

		-- 4th floor
		draw_girder(  121,   24,   121, 56)
		draw_girder(  121,   64,   121, 160)
		draw_girder(  121,   168,   121, 200)
		draw_ladder( 128, 32,  33) -- ladder 1
		draw_ladder( 128, 64,  33) -- ladder 2
		draw_ladder( 128, 152,  33) -- ladder 3
		draw_ladder( 128, 184,  33) -- ladder 4

		-- 5th floor
		draw_girder(  161,   32,   161, 56)
		draw_girder(  161,   64,   161, 160)
		draw_girder(  161,  168,   161, 192)

		-- Pauline's floor
		draw_girder(  201,   56,   201, 168)
	end

	function vector(y1, x1, y2, x2)
		-- draw a single vector
		scr:draw_line(y1+wobble(), x1+wobble(), y2+wobble(), x2+wobble(), vector_color)
		--scr:draw_line(y1+wobble(), x1+wobble(), y2+wobble(), x2+wobble(), intensity())
		vector_count = vector_count + 1
	end

	function polyline(data, offset_y, offset_x)
		-- draw multiple chained lines from a table of y,x points.  Optional offset for start y,x.
		local _offy, _offx = offset_y or 0, offset_x or 0
		local _y, _x
		if data then
			for _i=1, #data, 2 do
				if _y and _x and data[_i] ~= BR and data[_i+1] ~= BR and _y ~= BR and _x ~= BR then
					vector(data[_i]+_offy, data[_i+1]+_offx, _y+_offy, _x+_offx)
				end
				_y, _x =data[_i], data[_i+1]
			end
		end
	end

	function box(y, x, h, w)
		-- draw a simple box at given position with height and width
		polyline({y,x,y+h,x,y+h,x+w,y,x+w,y,x})
	end

	function circle(y, x, r)
		-- draw a 20 segment circle at given position with radius
		local _save_segy, _save_segx
		for _segment=0, 360, 18 do
			local _angle = _segment * (math.pi / 180)
			local _segy, _segx = y + r * math.sin(_angle), x + r * math.cos(_angle)
			if _save_segy then vector(_save_segy, _save_segx, _segy, _segx) end
			_save_segy, _save_segx = _segy, _segx
		end
	end

	function intensity()
		-- we can vary the brightness of the vectors
		--if not mac.paused then return ({0xddffffff, 0xeeffffff, 0xffffffff})[math.random(3)] else return 0xffffffff end
		return WHITE
	end

	function wobble()
		-- random change of the vector offset
		return 0
	end

	function cls()
		-- clear the screen
		scr:draw_box(0, 0, 256, 224, 0xff000000, 0xff000000)
	end

	-- vector objects
	-----------------
	function draw_object(name, y, x)
		-- draw object from the vector library
		polyline(vector_lib[name], y, x)
	end

	function draw_ladder(y, x, h)
		-- draw a single ladder at given y, x position of given height in pixels
		polyline({0,0,h,0,BR,BR,0,8,h,8},y,x)  -- left and right legs
		for i=0, h-2 do  -- draw rung every 4th pixel (skipping 2 pixels at bottom)
			if i % 4 == 0 then vector(y+i+2, x, y+i+2, x+8) end
		end
	end

	function draw_girder(y1, x1, y2, x2, open)
		-- draw girder at given y,x position.  Girders are based on parallel vectors (offset by 7 pixels).
		polyline({y1,x1,y2,x2,BR,BR,y1+7,x1,y2+7,x2})
		if not open or open ~= "L" then	polyline({y1,x1,y1+7,x1}) end
		if not open or open ~= "R" then polyline({y2,x2,y2+7,x2}) end
		if enable_zigzags then  -- Fill the girders with optional zig zags
			local _zig = 4  -- zigzag width 4 or 8 works well
			local _cnt = 0
			for _x=x1, x2 - 1, _zig*2 do
				_y = y1 + (((y2 - y1) / (x2 - x1)) * (_x - x1))
				if _cnt % 2 == 0 then polyline({3,_zig,4,_zig*2,3,_zig*3}, _y, _x) end ; _cnt = _cnt + 1
				--if _cnt % 2 == 0 then polyline({2,_zig,5,_zig*2,2,_zig*3}, _y, _x) end ; _cnt = _cnt + 1
				--polyline({2,0,5,_zig,2,_zig*2}, _y, _x)
				--polyline({2,0,5,_zig}, _y, _x)
			end
		end
	end

	function draw_oilcan_and_flames(y, x)
		draw_object("oilcan",  y, x)
		if not read(0x6a29, 0x70) then  -- is the oilcan on fire?
			local _data = {}
			local _flames = vector_lib["flames"]
			for _i=1, #_flames, 2 do
				if _i > 2 and _i < #_flames -2 then _adjust = math.random(-2,2) else _adjust = 0 end
				table.insert(_data, _flames[_i] + _adjust)
				table.insert(_data, _flames[_i+1])
			end
			vector_color = ({YELLOW, ORANGE, RED})[math.random(3)]
			polyline(_data, y+16, x)
			vector_color = WHITE
		end
	end

	function draw_vector_characters()
		-- Output vector characters based on contents of video ram ($7400-77ff)
		local _addr = VRAM_TR
		for _x=223, 0, -8 do
			for _y=255, 0, -8 do
				polyline(vector_lib[mem:read_u8(_addr)], _y - 6, _x - 6)
				_addr = _addr + 1
			end
		end
	end

	-- General functions
	--------------------
	function read(address, comparison)
		-- return data from memory address or boolean when the comparison value is provided
		_d = mem:read_u8(address)
		if comparison then return _d == comparison else return _d end
	end

	function write(address, value)
		mem:write_u8(address, value)
	end

	-- Debugging functions
	----------------------
	function debug_vector_count()
		mac:popmessage(tostring(vector_count).." vectors")
	end

	function debug_limits(limit)
		local _rnd, _ins = math.random, table.insert
		local _cycle = math.floor(scr:frame_number() % 720 / 180)  -- cycle through the 4 tests, each 3 seconds long
		if _cycle == 0 then
			for _=1, limit do vector(256, 224, _rnd(248), _rnd(224)) end  -- single vectors
		elseif _cycle == 1 then
			_d={}; for _=0,limit do _ins(_d,_rnd(256)); _ins(_d,_rnd(224)) end; polyline(_d)  -- polylines
		elseif _cycle == 2 then
			for _=1, limit/20 do circle(_rnd(200)+24, _rnd(176)+24, _rnd(16)+8) end  -- circles
		else
			for _=1, limit / 4 do box(_rnd(216), _rnd(200), _rnd(32)+8, _rnd(24)+8) end  -- boxes
		end
		debug_vector_count()
	end

	function debug_stay_on_girders()
		write(STAGE, 1);
		write(LEVEL, read(LEVEL) + 1)
	end

	-- event registration
	---------------------
	emu.register_start(function()
		initialize()
	end)

	emu.register_frame_done(main, "frame")
end
return exports