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
	local vector_count, vector_color, vector_flip
	local game_mode, last_mode, enable_zigzags
	local vector_lib = {}
	local barrel_state = {}

	-- Constants
	local MODE, STAGE, LEVEL = 0x600a, 0x6227, 0x6229
	local VRAM_TR, VRAM_BL = 0x7440, 0x77bf  -- top-right and bottom-left corner bytes
    local BLK, WHT, YEL, ORA, RED, BLU = 0xff000000, 0xffffffff, 0xfff0f050, 0xfff4ba15, 0xfff00000, 0xff0000f0  -- colors
	local BRN, MAG, PNK, LBR, CYN = 0xffee7511, 0xfff057e8, 0xffffd1dc, 0xfff5bb9f, 0xff14f3ff
	local BR = 0xffff  -- break in a vector chain

	function initialize()
		mame_version = tonumber(emu.app_version())
		if mame_version >= 0.196 then
			if type(manager.machine) == "userdata" then mac = manager.machine else mac = manager:machine() end
		else
			print("ERROR: The vectorkong plugin requires MAME version 0.196 or greater.")
		end
		if mac ~= nil then
			scr = mac.screens[":screen"]
			cpu = mac.devices[":maincpu"]
			mem = cpu.spaces["program"]
		end
		vector_lib = load_vector_library()
	end

	function main()
		if cpu ~= nil then
			vector_count = 0
			vector_flip = 0
			vector_color = WHT
			game_mode = read(MODE)

			cls()

			-- skip the intro scene and stay on girders stage
			if game_mode == 0x07 then write(MODE, 0x08) end
			if game_mode == 0x08 and last_mode == 0x16 then debug_stay_on_girders() end

			-- handle stage backgrounds
			if game_mode == 0x06 then draw_title_screen() end
			if read(VRAM_BL, 0xf0) then draw_girder_stage() end
			--if read(VRAM_BL, 0xb0) then draw_rivet_stage() end
			if game_mode == 0x10 then draw_gameover_screen() end
			if game_mode == 0x15 then draw_name_entry_screen() end

			draw_vector_characters()
			draw_points()

			--debug_limits(1000)
			--debug_vector_count()
			last_mode = game_mode
		end
	end

	function draw_title_screen()
		-- use simple block on title screen
		vector_lib[0xb0] = vector_lib[0xb0a]
	end

	function draw_gameover_screen()
		-- emphasise the game over message
		scr:draw_box(64, 64, 88, 160, BLK, BLK)
	end

	function draw_name_entry_screen()
		-- highlight selected character with blue box
		if game_mode == 0x15 then
			_index = read(0x6035)
			_y = math.floor(_index / 10) * -16 + 156
			_x = _index % 10 * 16 + 36
			vector_color = BLU
			box(_y, _x, 16, 16)
			vector_color = WHT
		end
	end

	function draw_girder_stage()
		enable_zigzags = false
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

		-- 6th girder
		draw_girder(165,   0, 165, 143, "R")  -- flat section
		draw_girder(165, 143, 161, 207, "L")  -- sloped section
		draw_ladder(172,  64,  52)  -- left ladder
		draw_ladder(172,  80,  52)  -- middle ladder
		draw_ladder(172, 128,  21)  -- right ladder

		-- Pauline's girder
		draw_girder(193,  88, 193, 136, "L")

		draw_stacked_barrels()
		draw_hammers()

		-- Sprites
		draw_jumpman()
		draw_pauline()
		draw_barrels()
		draw_fireball()
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

		-- Sprites
		draw_jumpman()
		draw_fireball()
	end

	function vector(y1, x1, y2, x2)
		-- draw a single vector
		scr:draw_line(y1, x1, y2, x2, vector_color)
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
					if vector_flip > 0 then
						vector(data[_i]+_offy, vector_flip-data[_i+1]+_offx, _y+_offy, vector_flip-_x+_offx)
					else
						vector(data[_i]+_offy, data[_i+1]+_offx, _y+_offy, _x+_offx)
					end
				end
				_y, _x =data[_i], data[_i+1]
			end
		end
	end

	function box(y, x, h, w)
		-- draw a simple box at given position with height and width
		polyline({y,x,y+h,x,y+h,x+w,y,x+w,y,x})
	end

	function intensity()
		-- we can vary the brightness of the vectors
		--if not mac.paused then return ({0xddffffff, 0xeeffffff, 0xffffffff})[math.random(3)] else return 0xffffffff end
		return WHT
	end

	function wobble()
		-- random change of the vector offset
		return 0
	end

	function cls()
		-- clear the screen
		scr:draw_box(0, 0, 256, 224, BLK, BLK)
	end

	-- vector objects
	-----------------
	function draw_object(name, y, x, color)
		-- draw object from the vector library
		if color then vector_color = color end
		polyline(vector_lib[name], y, x)
		if color then vector_color = WHT
		end
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
			local _cnt = 0
			for _x=x1, x2 - 1, 8 do
				_y = y1 + (((y2 - y1) / (x2 - x1)) * (_x - x1))
				if _cnt % 2 == 0 then polyline({3,4,4,8,3,12}, _y, _x) end ; _cnt = _cnt + 1
			end
		end
	end

	function draw_stacked_barrels()
		for _, _v in ipairs({{173,0},{173,10},{189,0},{189,10}}) do
			draw_object("stack", _v[1], _v[2], BRN)
			draw_object("stack-1", _v[1], _v[2], LBR)
		end
	end

	function draw_hammers()
		if read(0x6a18, 0x24) and read(0x6680, 1) then draw_object("hammer", 148,  17) end  -- top hammer
		if read(0x6a1c, 0xbb) and read(0x6690, 1) then draw_object("hammer", 56, 168) end -- bottom hammer
	end

	function draw_oilcan_and_flames(y, x)
		draw_object("oilcan",  y, x)
		print(read(0x6a29))
		if not read(0x6a29, 0x70) then  -- is the oilcan on fire?
			vector_color = ({ YEL, ORA, RED})[math.random(3)]
			polyline(vector_lib["flames"], y+16+math.random(1,3), x)
			polyline(vector_lib["flames"], y+16, x)
			vector_color = WHT
		end
	end

	function draw_vector_characters()
		-- Output vector characters based on contents of video ram ($7400-77ff)
		local _addr = VRAM_TR
		local _char
		for _x=223, 0, -8 do
			for _y=255, 0, -8 do
				_char = mem:read_u8(_addr)
				vector_color = character_colouring(_char)
				polyline(vector_lib[_char], _y - 6, _x - 6)
				vector_color = WHT
				_addr = _addr + 1
			end
		end
	end

	function character_colouring(character)
		-- optional vector character colouring
		if character == 0xb7 then return YEL
		end  -- Yellow Rivets
	end

	-- Sprites
	----------
	function draw_barrels()
		local _y, _x, _skull, _state
		for _addr = 0x6700, 0x68e0, 0x20 do  -- loop through array of barrels in memory
			if not read(_addr, 0) and read(0x6200,1) then  -- barrel is active and Jumpman is alive
				_y, _x = 251 - read(_addr+5), read(_addr+3) - 20
				_skull = read(_addr+0x15, 1) -- is a skull/blue barrel
				if read(_addr+1, 1) or bits(read(_addr+2))[1] == 1 then -- barrel is crazy or going down a ladder
					_state = read(_addr+0xf)
					draw_object("down", _y, _x-2, ({BRN, CYN})[idx(_skull)])
					draw_object("down-"..tostring(_state % 2 + 1), _y, _x-2, ({LBR, BLU})[idx(_skull)])
				else  -- barrel is rolling
					_state = barrel_state[_addr] or 0
					if scr:frame_number() % 10 == 0 then
						if read(_addr+2, 2) then _state = _state-1 else _state = _state+1 end -- rolling left or right?
						barrel_state[_addr] = _state
					end
					draw_object("roll", _y, _x, ({BRN, CYN})[idx(_skull)])
					draw_object(({"roll-","skull-"})[idx(_skull)]..tostring(_state%4+1),_y,_x,({LBR,BLU})[idx(_skull)])
				end
			end
		end
		vector_color = WHT
	end

	function draw_fireball()
		local _y, _x
		for _, _addr in ipairs{0x6400, 0x6420, 0x6440, 0x6460, 0x6480} do
			if read(_addr, 1) then  -- fireball is active
				_y, _x = 247 - read(_addr+5), read(_addr+3) - 22
				_r = math.random(4)
				vector_color = ({YEL-_r*0x10000000, ORA-_r*0x10000000, RED-_r*0x10000000})[math.random(3)] -- random color/intensity
				if read(_addr+0xd, 1) then vector_flip = 13 end  -- fireball moving right so flip the vectors
				draw_object("fire-1", _y+_r, _x)  -- flame/body
				draw_object("fire-2", _y+2, _x, RED)  -- eyes
				vector_flip = 0
			end
		end
	end

	function draw_pauline()
		local _y, _x = 235 - read(0x6903), 90
		if read(0x6905) ~= 17 then _y = _y + 3 end
		draw_object("paul-1", _y, _x, MAG)
		draw_object("paul-2", _y, _x, PNK)
		vector_flip = 0
	end

	function draw_jumpman()
		local _y, _x = 255 - read(0x6205), read(0x6203) - 15
		--local _sprite = read(0x694d)
		vector_color = BLU
		box(_y-7,_x-6,16,10)
		vector_color = WHT
	end

	function draw_kong()
	end

	function draw_points()
		-- draw 100, 300, 500 or 800 when points awarded
		if read(0x6a30) ~= 0 then
			_y, _x = 254 - read(0x6a33), read(0x6a30) - 22
			draw_object(read(0x6a31)+0xf00, _y+3, _x, YEL)  -- move points up a little so they don't overlap as much
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

	function bits(num)
		--return a table of bits, least significant first
		local _t={}
		while num>0 do
			rest=math.fmod(num,2)
			_t[#_t+1]=rest
			num=(num-rest)/2
		end
		return _t
	end

	function idx(bool)
		-- return table index 2 when true, 1 when false
		if bool then return 2 else return 1 end
	end

	-- Debugging functions
	----------------------
	function debug_vector_count()
		mac:popmessage(tostring(vector_count).." vectors")
	end

	function debug_limits(limit)
		local _rnd, _ins = math.random, table.insert
		local _cycle = math.floor(scr:frame_number() % 540 / 180)  -- cycle through the 3 tests, each 3 seconds long
		if _cycle == 0 then
			for _=1, limit do vector(256, 224, _rnd(248), _rnd(224)) end  -- single vectors
		elseif _cycle == 1 then
			_d={}; for _=0,limit do _ins(_d,_rnd(256)); _ins(_d,_rnd(224)) end; polyline(_d)  -- polylines
		else
			for _=1, limit / 4 do box(_rnd(216), _rnd(200), _rnd(32)+8, _rnd(24)+8) end  -- boxes
		end
		debug_vector_count()
	end

	function debug_stay_on_girders()
		write(STAGE, 1);
		write(LEVEL, read(LEVEL) + 1)
	end

	-- vector library
	function load_vector_library()
		local _lib = {}
		_lib[0x00] = {0,2,0,4,2,6,4,6,6,4,6,2,4,0,2,0,0,2} -- 0
		_lib[0x01] = {0,0,0,6,BR,BR,0,3,6,3,5, 1} -- 1
		_lib[0x02] = {0,6,0,0,5,6,6,3,5,0} -- 2
		_lib[0x03] = {1,0,0,1,0,5,1,6,2,6,3,5,3,2,6,6,6,1} -- 3
		_lib[0x04] = {0,5,6,5,2,0,2,7} -- 4
		_lib[0x05] = {1,0,0,1,0,5,2,6,4,5,4,0,6,0,6,5} -- 5
		_lib[0x06] = {3,0,1,0,0,1,0,5,1,6,2,6,3,5,3,0,6,2,6,5} -- 6
		_lib[0x07] = {6,0,6,6,0,2} -- 7
		_lib[0x08] = {2,0,0,1,0,5,2,6,5,0,6,1,6,4,5,5,2,0} -- 8
		_lib[0x09] = {0,1,0,4,2,6,5,6,6,5,6,1,5,0,4,0,3,1,3,6} -- 9
		_lib[0x11] = {0,0,4,0,6,3,4,6,0,6,BR,BR,2,6,2,0}  -- A
		_lib[0x12] = {0,0,6,0,6,5,5,6,4,6,3,5,2,6,1,6,0,5,0,0,BR,BR,3,0,3,4}  -- B
		_lib[0x13] = {1,6,0,5,0,2,2,0,4,0,6,2,6,5,5,6} -- C
		_lib[0x14] = {0,0,6,0,6,4,4,6,2,6,0,4,0,0} -- D
		_lib[0x15] = {0,5,0,0,6,0,6,5,BR,BR,3,0,3,4} -- E
		_lib[0x16] = {0,0,6,0,6,6,BR,BR,3,0,3,5} -- F
		_lib[0x17] = {3,4,3,6,0,6,0,2,2,0,4,0,6,2,6,6} -- G
		_lib[0x18] = {0,0,6,0,BR,BR,3,0,3,6,BR,BR,0,6,6,6} -- H
		_lib[0x19] = {0,0,0,6,BR,BR,0,3,6,3,BR,BR,6,0,6,6} -- I
		_lib[0x1a] = {1,0,0,1,0,5,1,6,6,6} -- J
		_lib[0x1b] = {0,0,6,0,BR,BR,3,0,0,6,BR,BR,3,0,6,6} -- K
		_lib[0x1c] = {6,0,0,0,0,5} -- L
		_lib[0x1d] = {0,0,6,0,2,3,6,6,0,6}  -- M
		_lib[0x1e] = {0,0,6,0,0,6,6,6} -- N
		_lib[0x1f] = {1,0,5,0,6,1,6,5,5,6,1,6,0,5,0,1,1,0} -- O
		_lib[0x20] = {0,0,6,0,6,5,5,6,3,6,2,5,2,0} -- P
		_lib[0x21] = {1,0,5,0,6,1,6,5,5,6,2,6,0,4,0,1,1,0,BR,BR,0,6,2,3} -- Q
		_lib[0x22] = {0,0,6,0,6,5,5,6,4,6,2,3,2,0,2,3,0,6} -- R
		_lib[0x23] = {1,0,0,1,0,5,1,6,2,6,4,0,5,0,6,1,6,4,5,5} -- S
		_lib[0x24] = {6,0,6,6,BR,BR,6,3,0,3} -- T
		_lib[0x25] = {6,0,1,0,0,1,0,5,1,6,6,6} -- U
		_lib[0x26] = {6,0,3,0,0,3,3,6,6,6} -- V
		_lib[0x27] = {6,0,2,0,0,1,4,3,0,5,2,6,6,6}  -- W
		_lib[0x28] = {0,0,6,6,3,3,6,0,0,6} -- X
		_lib[0x29] = {6,0,3,3,6,6,BR,BR,3,3,0,3} -- Y
		_lib[0x2a] = {6,0,6,6,0,0,0,6} -- Z
		_lib[0x2b] = {0,0,1,0,1,1,0,1,0,0}  -- dot
		_lib[0x2c] = {3,0,3,5} -- dash
		_lib[0x2d] = {5,0,5,6} -- underscore
		_lib[0x2e] = {4,3,4,3,BR,BR,2,3,2,3} -- colon
		_lib[0x2f] = {5,0,5,6} -- Alt underscore
		_lib[0x30] = {0,2,2,0,4,0,6,2} -- Left bracket
		_lib[0x31] = {0,2,2,4,4,4,6,2} -- Right bracket
		_lib[0x34] = {2,0,2,5,BR,BR,4,0,4,5} -- equals
		_lib[0x35] = {3,0,3,5} -- dash
		_lib[0x44] = {0,5,4,5,4,7,2,7,0,8,BR,BR,2,5,2,7,BR,BR,4,10,1,10,0,11,0,12,1,13,4,13,BR,BR,0,15,4,15,4,17,2,17,2,18,0,18,0,15,BR,BR,2,15,2,17,BR,BR,0,23,0,21,4,21,4,23,BR,BR,2,21,2,22,BR,BR,0,25,4,25,0,28,4,28,BR,BR,0,30,4,30,4,32,3,33,1,33,0,32,0,30} -- rub / end
		_lib[0x49] = {0,4,2,2,5,2,7,4,7,8,5,10,2,10,0,8,0,4,BR,BR,2,7,2,5,5,5,5,7} -- copyright
		_lib[0x6c] = {2,0,2,4,3,5,4,4,5,5,6,4,6,0,2,0,BR,BR,4,4,4,0,BR,BR,3,7,2,8,2,11,3,12,5,12,6,11,6,8,5,7,3,7,BR,BR,2,14,6,14,2,19,6,19,BR,BR,6,21,3,21,2,22,2,25,3,26,6,26,BR,BR,2,28,2,31,4,31,4,28,5,28,6,29,6,31,BR,BR,6,-2,6,-5,-12,-5,-12,36,6,36,6,33,BR,BR,0,-3,-10,-3,-10,34,0,34,0,-3} -- bonus
		_lib[0x70] = _lib[0x00] -- Alternative 0-9
		_lib[0x71] = _lib[0x01] --
		_lib[0x72] = _lib[0x02] --
		_lib[0x73] = _lib[0x03] --
		_lib[0x74] = _lib[0x04] --
		_lib[0x75] = _lib[0x05] --
		_lib[0x76] = _lib[0x06] --
		_lib[0x77] = _lib[0x07] --
		_lib[0x78] = _lib[0x08] --
		_lib[0x79] = _lib[0x09] --
		_lib[0x80] = _lib[0x00] -- Alternative 0-9
		_lib[0x81] = _lib[0x01] --
		_lib[0x82] = _lib[0x02] --
		_lib[0x83] = _lib[0x03] --
		_lib[0x84] = _lib[0x04] --
		_lib[0x85] = _lib[0x05] --
		_lib[0x86] = _lib[0x06] --
		_lib[0x87] = _lib[0x07] --
		_lib[0x88] = _lib[0x08] --
		_lib[0x89] = _lib[0x09] --
		_lib[0x8a] = _lib[0x1d] -- Alternative M's
		_lib[0x8b] = _lib[0x1d] --
		_lib[0x9f] = {2,0,0,2,0,13,2,15,5,15,7,13,7,2,5,0,2,0,BR,BR,5,3,5,7,BR,BR,5,5,2,5,BR,BR,2,8,5,8,4,10,5,12,2,12} -- TM
		_lib[0xb0a] = {0,0,0,8,BR,BR,6,0,6,8} -- Simple Block for Title Screen
		_lib[0xb0b] = {4,2,4,4,BR,BR,3,2,3,4} -- Simple Block for Rivet Stage
		_lib[0xb0] = _lib[0xb0a]
		_lib[0xb1] = {0,0,7,0,7,7,0,7,0,0} -- Box
		_lib[0xb7] = {0,0,1,0,1,1,6,1,6,0,7,0,7,6,6,6,6,5,1,5,1,6,0,6,0,0} -- Rivet
		_lib[0xdd] = {0,0,7,0,BR,BR,4,0,4,4,BR,BR,1,4,7,4,BR,BR,2,9,1,6,7,6,7,9,BR,BR,5,6,5,9,BR,BR,7,11,2,11,3,14,BR,BR,3,16,7,16,7,18,6,19,5,18,5,16,BR,BR,7,22,5,21,BR,BR,3,21,3,21} -- Help (big H)
		_lib[0xed] = {7,1,5,1,BR,BR,6,1,6,5,BR,BR,7,5,4,5,BR,BR,7,10,7,7,4,7,3,10,BR,BR,5,7,5,10,BR,BR,7,12,3,12,2,15,BR,BR,1,17,7,17,7,20,3,20,3,17,BR,BR,7,23,2,22,BR,BR,0,21,0,22} -- Help (little H)
		_lib[0xfb] = {5,1,6,2,6,5,5,6,4,6,2,3,BR,BR,0,3,0,3} -- question mark
		_lib[0xfd] = {-1,0,8,0,BR,BR,-1,-1,8,-1} -- vertical line
		_lib[0xfe] = {0,0,7,0,7,7,0,7,0,0} -- cross
		_lib[0xff] = {5,2,7,2,7,4,5,4,5,2,BR,BR,5,3,2,3,0,1,BR,BR,2,3,0,5,BR,BR,4,0,3,1,3,5,4,6} -- jumpman / stick man
		-- points
		_lib[0xf7b] = {5,0,6,1,0,1,BR,BR,0,0,0,2,BR,BR,0,4,0,8,6,8,6,4,0,4,BR,BR,0,10,0,14,6,14,6,10,0,10}  -- 100 Points
		_lib[0xf7d] = {0,0,0,4,2,4,3,1,6,4,6,0,BR,BR,0,6,0,9,6,9,6,6,0,6,BR,BR,0,11,0,14,6,14,6,11,0,11} -- 300 Points
		_lib[0xf7e] = {1,0,0,1,0,3,1,4,3,4,4,0,6,0,6,4,BR,BR,0,6,0,9,6,9,6,6,0,6,BR,BR,0,11,0,14,6,14,6,11,0,11} -- 500 Points
		_lib[0xf7f] = {1,0,2,0,4,4,5,4,6,3,6,1,5,0,4,0,2,4,1,4,0,3,0,1,1,0,BR,BR,0,6,0,9,6,9,6,6,0,6,BR,BR,0,11,0,14,6,14,6,11,0,11} -- 800 Points
		-- non character objects:
		_lib["oilcan"] = {1,1,15,1,BR,BR,1,15,15,15,BR,BR,5,1,5,15,BR,BR,12,1,12,15,BR,BR,7,4,10,4,10,7,7,7,7,4,BR,BR,7,9,10,9,BR,BR,7,13,7,11,10,11,BR,BR,15,0,16,0,16,16,15,16,15,0,BR,BR,1,0,0,0,0,16,1,16,1,0}
		_lib["flames"] = {0,4,2,2,3,3,8,0,4,5,5,6,9,4,5,8,4,7,2,10,2,11,4,12,9,10,4,14,0,12}
		_lib["stack"] = {3,0,12,0,15,2,15,7,12,9,3,9,0,7,0,7,0,2,3,0}  -- stacked barrels
		_lib["stack-1"] = {1,2,1,7,BR,BR,14,2,14,7,BR,BR,2,3,13,3,BR,BR,2,6,13,6}
		_lib["roll"]   = {3,0,6,0,8,2,8,3,9,4,9,7,8,8,8,9,6,11,3,11,1,9,1,8,0,7,0,4,1,3,1,2,3,0}  -- barrel outline
		_lib["roll-1"] = {2,3,3,4,BR,BR,3,3,2,4,BR,BR,6,5,3,8}  -- regular barrel
		_lib["roll-2"] = {2,7,3,8,BR,BR,3,7,2,8,BR,BR,3,3,6,6}
		_lib["roll-3"] = {6,7,7,8,BR,BR,7,7,6,8,BR,BR,6,3,3,6}
		_lib["roll-4"] = {6,3,7,4,BR,BR,7,3,6,4,BR,BR,3,5,6,8}
		_lib["skull-1"] = {3,3,5,3,6,4,6,7,7,8,6,9,5,8,3,8,2,7,2,4,3,3,BR,BR,5,4,3,6}  -- skull/blue barrel
		_lib["skull-2"] = {5,8,3,8,2,7,2,4,3,3,5,3,6,2,7,3,6,4,6,7,5,8,BR,BR,3,5,5,7}
		_lib["skull-3"] = {7,4,7,7,6,8,4,8,3,7,3,4,2,3,3,2,4,3,6,3,7,4,BR,BR,6,5,4,7}
		_lib["skull-4"] = {4,3,6,3,7,4,7,7,6,8,4,8,3,9,2,8,3,7,3,4,4,3,BR,BR,6,6,4,4}
		_lib["down"]   = {2,0,7,0,9,3,9,12,7,15,2,15,0,12,0,3,2,0}  -- barrel going down ladder or crazy barrel
		_lib["down-1"] = {1,1,8,1,BR,BR,1,14,8,14,BR,BR,2,3,2,12,BR,BR,7,3,7,12}
		_lib["down-2"] = {1,1,8,1,BR,BR,1,14,8,14,BR,BR,3,3,3,12,BR,BR,6,3,6,12}
		_lib["paul-1"] = {14,11,1,12,4,0,10,7,15,6,15,7,13,9,14,11}  -- Pauline
		_lib["paul-2"] = {20,14,21,13,21,8,15,1,15,6,15,7,20,10,20,14,18,14,16,12,16,10,14,10,BR,BR,19,12,19,13,BR,BR,2,5,0,6,1,2,3,3,2,5,BR,BR,13,6,12,2,11,2,11,7,BR,BR,10,12,9,15,10,15,12,11,BR,BR,1,12,0,13,0,9,2,9,1,12}
		_lib["hammer"] = {5,0,7,0,8,1,8,8,7,9,5,9,4,8,4,1,5,0,BR,BR,4,4,0,4,0,5,4,5,BR,BR,8,4,9,4,9,5,8,5}
		_lib["fire-1"] = {12,2,5,0,3,0,1,1,0,3,0,8,1,10,3,11,6,12,11,13,9,10,13,12,10,9,15,11,10,7,13,8,10,5,14,7,9,3,12,2}
		_lib["fire-2"] = {5,3,6,4,5,5,4,4,5,3,BR,BR,5,6,6,7,5,8,4,7,5,6}
		return _lib
	end

	-- event registration
	---------------------
	emu.register_start(function()
		initialize()
	end)

	emu.register_frame_done(main, "frame")
end
return exports