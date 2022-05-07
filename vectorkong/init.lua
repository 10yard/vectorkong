-- Vector Kong by Jon Wilson (10yard)
-- This plugin replaces DK pixel graphics with high resolution vectors
--
-- Tested with latest MAME version 0.243
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
	local game_mode, last_mode, smashed
	local vector_lib = {}
	local barrel_state = {}

	-- Constants
	local MODE, STAGE, LEVEL = 0x600a, 0x6227, 0x6229
	local VRAM_TR, VRAM_BL = 0x7440, 0x77bf  -- top-right and bottom-left bytes of video ram
	local BLK, WHT, YEL, RED, BLU, MBR = 0xff000000, 0xffffffff, 0xfff0f050, 0xfff00000, 0xff0000f0, 0xe0f27713 -- color
	local BRN, MAG, PNK, LBR, CYN, GRY = 0xffD60609, 0xfff057e8, 0xffffd1dc, 0xfff5bca0, 0xff14f3ff, 0xffb0b0b0
	local STACKED_BARRELS = {{173,0},{173,10},{189,0},{189,10}}
	local BARRELS = {0x6700,0x6720,0x6740,0x6760,0x6780,0x67a0,0x67c0,0x67e0,0x6800,0x6820}
	local FIREBALLS = {0x6400, 0x6420, 0x6440, 0x6460, 0x6480, 0x64a0}
	local BR = 0xffff  -- instuction to break in a vector chain

	function initialize()
		mame_version = tonumber(emu.app_version())
		if mame_version >= 0.196 then
			if type(manager.machine) == "userdata" then
				mac = manager.machine
				bnk = mac.memory
			else
				mac = manager:machine()
				bnk = mac:memory()
			end
		else
			print("ERROR: The vectorkong plugin requires MAME version 0.196 or greater.")
		end
		if mac ~= nil then
			scr = mac.screens[":screen"]
			cpu = mac.devices[":maincpu"]
			mem = cpu.spaces["program"]
		end
		clear_graphic_banks()
		vector_lib = load_vector_library()
	end

	function main()
		if cpu ~= nil then
			vector_count = 0
			vector_color = WHT
			game_mode = read(MODE)

			-- skip the intro scene and stay on girders stage
			if game_mode == 0x07 then write(MODE, 0x08) end
			if game_mode == 0x08 and last_mode == 0x16 then debug_stay_on_girders() end

			-- handle stage backgrounds
			if read(VRAM_BL, 0xf0) then draw_girder_stage() end
			--if read(VRAM_BL, 0xb0) then draw_rivet_stage() end

			screen_specific_changes()
			draw_vector_characters()

			--debug_limits(3000)
			--debug_vector_count()
			last_mode = game_mode
		end
	end

	function screen_specific_changes()
		local _y, _x
		if game_mode == 0x10 then
			-- emphasise the game over message
			scr:draw_box(64, 64, 88, 160, BLK, BLK)
		elseif game_mode == 0x15 then
			-- highlight selected character during name registration
			_y, _x = math.floor(read(0x6035) / 10) * -16 + 156, read(0x6035) % 10 * 16 + 36
			draw_object("select", _y, _x, CYN)
		elseif game_mode == 0x6 then
			-- restore basic block for title screen and display growling kong
			vector_lib[0xb0] = vector_lib[0xfb0]
			draw_kong(48, 92, true)
		elseif game_mode == 0xa then
			-- display multiple kongs on the how high can you get screen
			_y, _x = 24, 92
			for _i=1, mem:read_u8(0x622e) do
				draw_kong(_y, _x)
				_y = _y + 32
			end
		end
	end

	---- Draw stage backgrounds
	---------------------------
	function draw_girder_stage()
		local _growling = game_mode == 0x16 and read(0x6388) >= 4
		smashed = read(0x6352)

		-- 1st girder
		draw_girder(1, 0, 1, 111, "R")  -- flat section
		draw_girder(1, 111, 8, 223, "L")  -- sloped section
		draw_ladder(8, 80, 8) -- broken ladder bottom
		draw_ladder(32, 80, 4) -- broken ladder top
		draw_ladder(13, 184, 17) -- right ladder
		draw_oilcan_and_flames(8, 16)
		-- 2nd Girder
		draw_girder(41, 0, 29, 207)
		draw_ladder(46, 32, 17)  -- left ladder
		draw_ladder(42, 96, 25)  -- right ladder
		-- 3rd Girder
		draw_girder(62, 16, 74, 223)
		draw_ladder(72, 64, 9)  -- broken ladder bottom
		draw_ladder(96, 64, 7)  -- broken ladder top
		draw_ladder(75, 112, 25)  -- middle ladder
		draw_ladder(79, 184, 17)  -- right ladder
		-- 4th Girder
		draw_girder(107, 0, 95, 207)
		draw_ladder(112, 32, 17)  -- left ladder
		draw_ladder(110, 72, 21)  -- middle ladder
		draw_ladder(104, 168, 9)  -- broken ladder bottom
		draw_ladder(128, 168, 9)  -- broken ladder top
		-- 5th girder
		draw_girder(128, 16, 140, 223)
		draw_ladder(139, 88, 13)  -- broken ladder bottom
		draw_ladder(160, 88, 5)  -- broken ladder top
		draw_ladder(145, 184, 17)  -- right ladder
		-- 6th girder
		draw_girder(165, 0, 165, 143, "R")  -- flat section
		draw_girder(165, 143, 161, 207, "L")  -- sloped section
		draw_ladder(172, 64, 52)  -- left ladder
		draw_ladder(172, 80, 52)  -- middle ladder
		draw_ladder(172, 128, 21)  -- right ladder
		draw_stacked_barrels()
		-- Pauline's girder
		draw_girder(193, 88, 193, 136, "L")
		draw_pauline()
		draw_loveheart()
		-- Other sprites
		draw_jumpman()
		draw_barrels()
		draw_fireballs()
		draw_hammers()
		draw_points()
		draw_kong(172, 24, _growling)
	end

	function draw_rivet_stage()
		-- Work in progress
		vector_lib[0xb0] = {}  -- clear basic block

		-- 1st floor
		draw_girder(1, 0, 1, 223)
		draw_ladder(8, 8, 33) -- left ladder
		draw_ladder(8, 104, 33) -- middle ladder
		draw_ladder(8, 208, 33) -- right ladder
		-- 2nd floor
		draw_girder(41, 8, 41, 56)
		draw_girder(41, 64, 41, 160)
		draw_girder(41, 168, 41, 216)
		draw_ladder(48, 16, 33) -- ladder 1
		draw_ladder(48, 72, 33) -- ladder 2
		draw_ladder(48, 144, 33) -- ladder 3
		draw_ladder(48, 200, 33) -- ladder 4
		-- 3rd floor
		draw_girder(81, 16, 81, 56)
		draw_girder(81, 64, 81, 160)
		draw_girder(81, 168, 81, 208)
		draw_ladder(88, 24, 33) -- left ladder
		draw_ladder(88, 104, 33) -- middle ladder
		draw_ladder(88, 192, 33) -- right ladder
		-- 4th floor
		draw_girder(121, 24, 121, 56)
		draw_girder(121, 64, 121, 160)
		draw_girder(121, 168, 121, 200)
		draw_ladder(128, 32, 33) -- ladder 1
		draw_ladder(128, 64, 33) -- ladder 2
		draw_ladder(128, 152, 33) -- ladder 3
		draw_ladder(128, 184, 33) -- ladder 4
		-- 5th floor
		draw_girder(161, 32, 161, 56)
		draw_girder(161, 64, 161, 160)
		draw_girder(161, 168, 161, 192)
		-- Pauline's floor
		draw_girder(201, 56, 201, 168)
		-- Sprites
		draw_jumpman()
		draw_fireballs()
		draw_points()
	end

	---- Basic vector drawing functions
	-----------------------------------
	function vector(y1, x1, y2, x2)
		-- draw a single vector
		scr:draw_line(y1, x1, y2, x2, vector_color)
		vector_count = vector_count + 1
	end

	function polyline(data, offset_y, offset_x, flip)
		-- draw multiple chained lines from a table of y,x points.  Optional offset for start y,x.
		local _offy, _offx = offset_y or 0, offset_x or 0
		local _savey, _savex, _datay, _datax
		if data then
			for _i=1, #data, 2 do
				_datay, _datax = data[_i], data[_i+1]
				if _savey and _savex and _datay ~= BR and _datax ~= BR and _savey ~= BR and _savex ~= BR then
					if flip and flip > 0 then
						vector(_datay+_offy, flip-_datax+_offx, _savey+_offy, flip-_savex+_offx)
					else
						vector(_datay+_offy, _datax+_offx, _savey+_offy, _savex+_offx)
					end
				end
				_savey, _savex = _datay, _datax
			end
		end
	end

	function box(y, x, h, w)
		-- draw a simple box at given position with height and width
		polyline({y,x,y+h,x,y+h,x+w,y,x+w,y,x})
	end

	function draw_vector_characters()
		-- Output vector characters based on contents of video ram ($7400-77ff)
		local _addr = VRAM_TR
		for _x=223, 0, -8 do
			for _y=255, 0, -8 do
				draw_object(mem:read_u8(_addr), _y - 6, _x - 6)
				_addr = _addr + 1
			end
		end
	end

	function draw_object(name, y, x, color, flip)
		-- draw object from the vector library
		vector_color = color or vector_color
		polyline(vector_lib[name], y, x, flip)
		vector_color = WHT
	end

	---- Draw game objects
	----------------------
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
		if not open or open ~= "L" then	polyline({y1,x1,y1+7,x1}) end  -- close the girder ends
		if not open or open ~= "R" then polyline({y2,x2,y2+7,x2}) end
		for _x=x1, x2 - 1, 16 do  -- Fill the girders with zig zags
			draw_object("zigzag", y1 + (((y2 - y1) / (x2 - x1)) * (_x - x1)), _x, GRY)
		end
	end

	function draw_stacked_barrels()
		for _, _v in ipairs(STACKED_BARRELS) do
			draw_object("stack", _v[1], _v[2], MBR)
			draw_object("stack-1", _v[1], _v[2], LBR)
		end
	end

	function draw_hammers()
		if read(0x6a18, 0x24) and read(0x6680, 1) then draw_object("hammer", 148,  17, MBR) end  -- top
		if read(0x6a1c, 0xbb) and read(0x6690, 1) then draw_object("hammer", 56, 168, MBR) end -- bottom
	end

	function draw_oilcan_and_flames(y, x)
		draw_object("oilcan",  y, x)
		local _sprite = read(0x6a29)
		if _sprite >= 0x40 and _sprite <= 0x43 then  -- oilcan is on fire
			draw_object("flames", y+16, x, YEL)  -- draw base of flames
			draw_object("flames", y+16+math.random(0,3), x, RED) -- draw flames extending upwards
		end
	end

	---- Sprites
	------------
	function draw_barrels()
		local _y, _x, _type, _state
		for _i, _addr in ipairs(BARRELS) do
			if read(_addr) > 0 and read(0x6200, 1) and read(_addr+3) > 0 then  -- barrel active and Jumpman alive
				_y, _x = 251 - read(_addr+5), read(_addr+3) - 20
				_type = read(_addr+0x15) + 1 -- type of barrel: 1 is normal, 2 is blue/skull

				if smashed == 0x67 and _i == read(0x6354) + 1 then -- this item was hit
					write(_addr+3, 0)  -- clear barrel
				elseif read(_addr+1, 1) or bits(read(_addr+2))[1] == 1 then -- barrel is crazy or going down a ladder
					_state = read(_addr+0xf)
					draw_object("down", _y, _x-2, ({MBR, CYN})[_type])
					draw_object("down-"..tostring(_state % 2 + 1), _y, _x - 2, ({LBR, BLU})[_type])
				else  -- barrel is rolling
					_state = barrel_state[_addr] or 0
					if scr:frame_number() % 10 == 0 then
						if read(_addr+2, 2) then _state = _state - 1 else _state = _state+1 end -- roll left or right?
						barrel_state[_addr] = _state
					end
					draw_object("roll", _y, _x, ({MBR, CYN})[_type])
					draw_object(({"roll-", "skull-"})[_type]..tostring(_state % 4 + 1), _y, _x,({LBR, BLU})[_type])
				end
			end
		end
	end

	function draw_fireballs()
		local _y, _x, _flip
		for _i, _addr in ipairs(FIREBALLS) do
			if read(_addr, 1) then  -- fireball is active
				if smashed == 0x64 and _i == read(0x6354) + 1 then -- fireball smashed
					write(_addr+3, 0)  -- clear fireball
				else
					_y, _x = 247 - read(_addr+5), read(_addr+3) - 22
					if read(_addr+0xd, 1) then _flip = 13 end  -- fireball moving right so flip the vectors
					draw_object("fire-1", _y, _x, YEL, _flip) -- draw body
					draw_object("fire-2", _y+math.random(0,3), _x, RED, _flip) -- draw flames extending upwards
					draw_object("fire-3", _y+1, _x, RED, _flip) -- draw eyes
				end
			end
		end
	end

	function draw_pauline()
		local _y, _x = 235 - read(0x6903), 90
		if read(0x6905) ~= 17 and read(0x6a20, 0) then _y = _y + 3 end  -- Pauline jumps when heart not showing
		draw_object("paul-1", _y, _x, MAG)
		draw_object("paul-2", _y, _x, PNK)
	end

	function draw_loveheart()
		_y, _x = 250 - read(0x6a23), read(0x6a20) - 23
		if _x > 0 then draw_object(read(0x6a21) + 0xf00, _y, _x, MAG) end
	end

	function draw_jumpman()
		local _y, _x = 255 - read(0x6205), read(0x6203) - 15
		----local _sprite = read(0x694d)
		if _y < 255 then
			vector_color = RED ; box(_y-7,_x-6,16,10)
			vector_color = BLU ; polyline({-7,-6,9,4,BR,BR,9,-6,-7,4}, _y, _x)
			vector_color = WHT
		end
	end

	function draw_kong(y, x, growl)
		local _data = {"roll-1", MBR, LBR}
		local _state = read(0x691d)
		if _state == 45 or _state == 173 or _state == 42 then
			if read(0x6382, 128) or read(0x6382, 129) then _data = {"skull-1", CYN, BLU} end
			if _state == 45 then
				-- DK grabbing barrel to left
				draw_object("dksd-1", y, x-3, BRN, 42)
				draw_object("dksd-2", y, x-3, MBR, 42)
				draw_object("dksd-3", y, x-3, LBR, 42)
				draw_object("roll", y, x-15, _data[2])
				draw_object(_data[1], y, x-15, _data[3])
			elseif _state == 173 then
				-- DK releasing barrel to right
				draw_object("dksd-1", y, x+1, BRN)
				draw_object("dksd-2", y, x+1, MBR)
				draw_object("dksd-3", y, x+1, LBR)
				draw_object("roll", y, x+44, _data[2])
				draw_object(_data[1], y, x+44, _data[3])
			elseif _state == 42 then
				-- DK front facing (mirrored) - needs a sprite with grabbing hands
				draw_object("dkfr-1", y, x, BRN); draw_object("dkfr-1", y, x+20, BRN, 20)
				draw_object("dkfr-2", y, x, MBR); draw_object("dkfr-2", y, x+20, MBR, 20)
				draw_object("dkfr-3", y, x, LBR); draw_object("dkfr-3", y, x+20, LBR, 20)
				draw_object("down", y, x+13, _data[2])
				draw_object("down-1", y, x+13, _data[3])
			end
		else
			-- DK front facing (mirrored)
			draw_object("dkfr-1", y, x, BRN); draw_object("dkfr-1", y, x+20, BRN, 20)
			draw_object("dkfr-2", y, x, MBR); draw_object("dkfr-2", y, x+20, MBR, 20)
			draw_object("dkfr-3", y, x, LBR); draw_object("dkfr-3", y, x+20, LBR, 20)
			if growl then
				draw_object("growl-1", y, x, MBR); draw_object("growl-1", y, x+20, MBR, 20)
				draw_object("growl-2", y, x, LBR); draw_object("growl-2", y, x+20, LBR, 20)
			end
		end
	end

	function draw_points()
		-- draw 100, 300, 500 or 800 when points awarded
		if read(0x6a30) > 0 then
			_y, _x = 254 - read(0x6a33), read(0x6a30) - 22
			draw_object(read(0x6a31) + 0xf00, _y+3, _x, YEL)  -- move points up a little so they don't overlap as much
		end
	end

	---- General functions
	----------------------
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

	---- Debugging functions
	------------------------
	function debug_vector_count()
		mac:popmessage(tostring(vector_count).." vectors")
	end

	function debug_limits(limit)
		local _rnd, _ins = math.random, table.insert
		local _cycle = math.floor(scr:frame_number() % 540 / 180)  -- cycle through the 3 tests, each 3 seconds long
		vector_color = 0x44ffffff
		if _cycle == 0 then
			for _=1, limit do vector(256, 224, _rnd(248), _rnd(224)) end  -- single vectors
		elseif _cycle == 1 then
			_d={}; for _=0,limit do _ins(_d,_rnd(256)); _ins(_d,_rnd(224)) end; polyline(_d)  -- polylines
		else
			for _=1, limit / 4 do box(_rnd(216), _rnd(200), _rnd(32)+8, _rnd(24)+8) end  -- boxes
		end
		vector_color = WHT
	end

	function debug_stay_on_girders()
		write(STAGE, 1)
		write(LEVEL, read(LEVEL) + 1)
	end

	---- Graphics memory
	--------------------
	function clear_graphic_banks()
		-- clear the contents of the DK graphics banks 1 and 2
		local _bank1, _bank2 = bnk.regions[":gfx1"], bnk.regions[":gfx2"]
		if _bank1 and _bank2 then
			for _addr=0, 0xfff do _bank1:write_u8(_addr, 0) end
			for _addr=0, 0x1fff do _bank2:write_u8(_addr, 0) end
		end
	end

	---- Vector library
	--------------------
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
		_lib[0x39] = {0,0,7,0,7,7,0,7,0,0} -- smash
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
		_lib[0xb0] = {0,0,0,8,BR,BR,6,0,6,8} -- Basic block for title Screen
		_lib[0xfb0] = {0,0,0,8,BR,BR,6,0,6,8} -- Copy of basic block
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
		-- Love heart
		_lib[0xf76] = {0,8,5,2,7,1,10,1,12,3,12,6,10,8,12,10,12,13,10,15,7,15,5,14,0,8}  -- full heart
		_lib[0xf77] = {0,7,5,1,7,0,10,0,12,5,11,6,10,5,8,7,5,4,2,7,0,7,BR,BR,1,9,2,9,5,7,8,10,10,8,12,10,12,13,10,15,7,15,5,14,1,9} -- broken heart
		-- non character objects:
		_lib["select"] = {0,0,16,0,16,16,0,16,0,0}  -- selection box
		_lib["zigzag"] = {3,4,4,8,3,12} -- zig zags for girders
		_lib["oilcan"] = {1,1,15,1,BR,BR,1,15,15,15,BR,BR,5,1,5,15,BR,BR,12,1,12,15,BR,BR,7,4,10,4,10,7,7,7,7,4,BR,BR,7,9,10,9,BR,BR,7,13,7,11,10,11,BR,BR,15,0,16,0,16,16,15,16,15,0,BR,BR,1,0,0,0,0,16,1,16,1,0}
		_lib["flames"] = {0,4,2,2,3,3,8,0,4,5,5,6,9,4,5,8,4,7,2,10,2,11,4,12,9,10,4,14,0,12}
		_lib["stack"] = {3,0,12,0,15,2,15,7,12,9,3,9,0,7,0,7,0,2,3,0}  -- stacked barrels
		_lib["stack-1"] = {1,2,1,7,BR,BR,14,2,14,7,BR,BR,2,3,13,3,BR,BR,2,6,13,6}
		_lib["roll"] = {3,0,6,0,8,2,8,3,9,4,9,7,8,8,8,9,6,11,3,11,1,9,1,8,0,7,0,4,1,3,1,2,3,0}  -- barrel outline
		_lib["roll-1"] = {2,3,3,4,BR,BR,3,3,2,4,BR,BR,6,5,3,8}  -- regular barrel
		_lib["roll-2"] = {2,7,3,8,BR,BR,3,7,2,8,BR,BR,3,3,6,6}
		_lib["roll-3"] = {6,7,7,8,BR,BR,7,7,6,8,BR,BR,6,3,3,6}
		_lib["roll-4"] = {6,3,7,4,BR,BR,7,3,6,4,BR,BR,3,5,6,8}
		_lib["skull-1"] = {3,3,5,3,6,4,6,7,7,8,6,9,5,8,3,8,2,7,2,4,3,3,BR,BR,5,4,3,6}  -- skull/blue barrel
		_lib["skull-2"] = {5,8,3,8,2,7,2,4,3,3,5,3,6,2,7,3,6,4,6,7,5,8,BR,BR,3,5,5,7}
		_lib["skull-3"] = {7,4,7,7,6,8,4,8,3,7,3,4,2,3,3,2,4,3,6,3,7,4,BR,BR,6,5,4,7}
		_lib["skull-4"] = {4,3,6,3,7,4,7,7,6,8,4,8,3,9,2,8,3,7,3,4,4,3,BR,BR,6,6,4,4}
		_lib["down"] = {2,0,7,0,9,3,9,12,7,15,2,15,0,12,0,3,2,0}  -- barrel going down ladder or crazy barrel
		_lib["down-1"] = {1,1,8,1,BR,BR,1,14,8,14,BR,BR,2,3,2,12,BR,BR,7,3,7,12}
		_lib["down-2"] = {1,1,8,1,BR,BR,1,14,8,14,BR,BR,3,3,3,12,BR,BR,6,3,6,12}
		_lib["paul-1"] = {14,11,1,12,4,0,10,7,15,6,15,7,13,9,14,11}  -- Pauline
		_lib["paul-2"] = {20,14,21,13,21,8,15,1,15,6,15,7,20,10,20,14,18,14,16,12,16,10,14,10,BR,BR,19,12,19,13,BR,BR,2,5,0,6,1,2,3,3,2,5,BR,BR,13,6,12,2,11,2,11,7,BR,BR,10,12,9,15,10,15,12,11,BR,BR,1,12,0,13,0,9,2,9,1,12}
		_lib["hammer"] = {5,0,7,0,8,1,8,8,7,9,5,9,4,8,4,1,5,0,BR,BR,4,4,0,4,0,5,4,5,BR,BR,8,4,9,4,9,5,8,5}
		_lib["fire-1"] = {12,2,5,0,3,0,1,1,0,3,0,8,1,10,3,11,6,12,11,13,9,10,13,12,10,9,15,11,10,7,13,8,10,5,14,7,9,3,12,2}
		_lib["fire-2"] = {12,2,5,0,BR,BR,6,12,11,13,9,10,13,12,10,9,15,11,10,7,13,8,10,5,14,7,9,3,12,2}
		_lib["fire-3"] = {5,3,6,4,5,5,4,4,5,3,BR,BR,5,6,6,7,5,8,4,7,5,6}
		_lib["dkfr-1"] = {27,13,25,13,25,15,28,15,29,16,30,18,30,19,29,20,BR,BR,31,20,31,17,27,13,BR,BR,25,20,25,18,24,18,24,20,BR,BR,21,15,22,16,22,20,BR,BR,26,18,27,18,27,19,26,19,26,18,BR,BR,6,20,6,16,2,12,BR,BR,2,4,4,4,5,3,7,3,11,7,13,7,13,4,16,1,19,1,23,6,24,8,24,10,BR,BR,7,15,8,14,10,14,BR,BR,19,6,17,10,16,13,BR,BR,10,13,11,10}  -- DK front
		_lib["dkfr-2"] = {27,13,27,11,26,10,25,10,21,11,20,14,19,14,18,16,18,20,BR,BR,2,12,0,11,0,0,2,2,2,4,BR,BR,16,13,16,15,15,18,14,19,12,19,10,17,10,13,BR,BR,6,17,7,17,8,16,BR,BR,6,19,7,19,8,18,BR,BR,1,10,2,11,BR,BR,1,5,2,6,BR,BR,28,17,28,19,26,19,26,17,28,17} -- DK highlights
		_lib["dkfr-3"] = {26,18,27,18,27,19,26,19,26,18} -- DK eyes
		_lib["dksd-1"] = {7,1,7,5,9,7,11,7,17,13,23,15,26,18,28,23,28,26,30,28,31,30,31,35,30,36,BR,BR,2,6,3,7,3,13,5,15,5,23,4,23,2,22,BR,BR,2,30,5,31,10,28,BR,BR,3,35,10,28,18,21,23,21,24,22,BR,BR,7,39,13,35,17,32,BR,BR,19,35,21,37,21,41,BR,BR,26,38,26,40,25,40,25,38,26,38,BR,BR,6,16,7,17,10,23,10,25,BR,BR,6,22,8,24,9,26,BR,BR,30,36,30,35,27,31,24,34,22,34,21,33,21,32}  -- DK side
		_lib["dksd-2"] = {7,1,1,1,0,2,0,8,2,6,BR,BR,5,2,5,3,BR,BR,1,2,2,3,BR,BR,2,22,0,22,0,34,2,32,2,30,BR,BR,1,24,2,24,BR,BR,1,29,2,28,BR,BR,3,35,0,39,0,41,1,42,2,42,4,40,5,40,6,42,7,42,7,39,BR,BR,17,32,17,36,18,39,21,42,22,42,24,41,25,40,BR,BR,26,38,30,36,BR,BR,21,32,23,30,25,30,26,29,26,28,25,27,24,27,20,31,17,32,BR,BR,28,36,28,34,26,34,26,36,28,36} -- DK highlights
		_lib["dksd-3"] = {27,36,27,35,26,35,26,36,27,36}  -- DK eyes
		_lib["growl-1"] = {21,15,22,16,22,20,BR,BR,21,14,20,16,20,20} -- DK growling mouth
		_lib["growl-2"] = {21,16,21,18,BR,BR,22,17,20,17,BR,BR,21,19,21,20,BR,BR,22,20,20,20} -- DK teeth
		return _lib
	end

	---- event registration
	-----------------------
	emu.register_start(function()
		initialize()
	end)

	emu.register_frame_done(main, "frame")
end
return exports