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
	local vector_count
	
	-- Options
	local enable_zigzags = false
	
	-- Vector character library
	local vector_lib = {}
	local B = 0xffff  -- break in a vector chain
	vector_lib[0x00] = {0,2,0,4,2,6,4,6,6,4,6,2,4,0,2,0,0,2} -- 0
	vector_lib[0x01] = {0,0,0,6,B,B,0,3,6,3,5, 1} -- 1
	vector_lib[0x02] = {0,6,0,0,5,6,6,3,5,0} -- 2
	vector_lib[0x03] = {1,0,0,1,0,5,1,6,2,6,3,5,3,2,6,6,6,1} -- 3
	vector_lib[0x04] = {0,5,6,5,2,0,2,7} -- 4
	vector_lib[0x05] = {1,0,0,1,0,5,2,6,4,5,4,0,6,0,6,5} -- 5
	vector_lib[0x06] = {3,0,1,0,0,1,0,5,1,6,2,6,3,5,3,0,6,2,6,5} -- 6
	vector_lib[0x07] = {6,0,6,6,0,2} -- 7
	vector_lib[0x08] = {2,0,0,1,0,5,2,6,5,0,6,1,6,4,5,5,2,0} -- 8
	vector_lib[0x09] = {0,1,0,4,2,6,5,6,6,5,6,2,5,0,4,0,3,1,3,6} -- 9
	vector_lib[0x11] = {0,0,4,0,6,3,4,6,0,6,B,B,2,6,2,0}  -- A
	vector_lib[0x12] = {0,0,6,0,6,5,5,6,4,6,3,5,2,6,1,6,0,5,0,0}  -- B
	vector_lib[0x13] = {1,6,0,5,0,2,2,0,4,0,6,2,6,5,5,6} -- C
	vector_lib[0x14] = {0,0,6,0,6,4,4,6,2,6,0,4,0,0} -- D
	vector_lib[0x15] = {0,5,0,0,6,0,6,5,B,B,3,0,3,4} -- E
	vector_lib[0x16] = {0,0,6,0,6,6,B,B,3,0,3,5} -- F
	vector_lib[0x17] = {3,4,3,6,0,6,0,2,2,0,4,0,6,2,6,6} -- G
	vector_lib[0x18] = {0,0,6,0,B,B,3,0,3,6,B,B,0,6,6,6} -- H
	vector_lib[0x19] = {0,0,0,6,B,B,0,3,6,3,B,B,6,0,6,6} -- I
	vector_lib[0x1a] = {1,0,0,1,0,5,1,6,6,6} -- J
	vector_lib[0x1b] = {0,0,6,0,B,B,3,0,0,6,B,B,3,0,6,6} -- K
	vector_lib[0x1c] = {6,0,0,0,0,5} -- L
	vector_lib[0x1d] = {0,0,6,0,2,3,6,6,0,6}  -- M
	vector_lib[0x1e] = {0,0,6,0,0,6,6,6} -- N
	vector_lib[0x1f] = {1,0,5,0,6,1,6,5,5,6,1,6,0,5,0,1,1,0} -- O
	vector_lib[0x20] = {0,0,6,0,6,5,5,6,3,6,2,5,2,0} -- P
	vector_lib[0x21] = {1,0,5,0,6,1,6,5,5,6,2,6,0,4,0,1,1,0,B,B,0,6,2,3} -- Q
	vector_lib[0x22] = {0,0,6,0,6,5,5,6,4,6,2,3,2,0,2,3,0,6} -- R
	vector_lib[0x23] = {1,0,0,1,0,5,1,6,2,6,4,0,5,0,6,1,6,4,5,5} -- S
	vector_lib[0x24] = {6,0,6,6,B,B,6,3,0,3} -- T
	vector_lib[0x25] = {6,0,1,0,0,1,0,5,1,6,6,6} -- U
	vector_lib[0x26] = {6,0,3,0,0,3,3,6,6,6} -- V
	vector_lib[0x27] = {6,0,2,0,0,1,4,3,0,5,2,6,6,6}  -- W
	vector_lib[0x28] = {0,0,6,6,3,3,6,0,0,6} -- X
	vector_lib[0x29] = {6,0,3,3,6,6,B,B,3,3,0,3} -- Y
	vector_lib[0x2a] = {6,0,6,6,0,0,0,6} -- Z
	vector_lib[0x2b] = {0,0,1,0,1,1,0,1,0,0}  -- dot
	vector_lib[0x34] = {2,0,2,5,B,B,4,0,4,5} -- equals
	vector_lib[0x35] = {3,0,3,5} -- dash
	vector_lib[0x6c] = {2,0,2,4,3,5,4,4,5,5,6,4,6,0,2,0,B,B,4,4,4,0,B,B,3,7,2,8,2,11,3,12,5,12,6,11,6,8,5,7,3,7,B,B,
		2,14,6,14,2,19,6,19,B,B,6,21,3,21,2,22,2,25,3,26,6,26,B,B,2,28,2,31,4,31,4,28,5,28,6,29,6,31, B,B,
		6,-2,6,-5,-12,-5,-12,36,6,36,6,33,B,B,0,-3,-10,-3,-10,34,0,34,0,-3} -- bonus
	vector_lib[0x70] = {0,2,0,4,2,6,4,6,6,4,6,2,4,0,2,0,0,2} -- Alt 0
	vector_lib[0x71] = {0,0,0,5,B,B,0,3,6,3,5, 1} -- Alt 1
	vector_lib[0x72] = {0,6,0,0,5,6,6,3,5,0} -- Alt 2
	vector_lib[0x73] = {1,0,0,1,0,5,1,6,2,6,3,5,3,2,6,6,6,1} -- Alt 3
	vector_lib[0x74] = {0,5,6,5,6,3,3,0,2,0,2,6} -- Alt 4
	vector_lib[0x75] = {1,0,0,1,0,5,2,6,4,5,4,0,6,0,6,5} -- Alt 5
	vector_lib[0x76] = {3,0,1,0,0,1,0,5,1,6,2,6,3,5,3,0,6,2,6,5} -- Alt 6
	vector_lib[0x77] = {5,0,6,0,6,6,2,2,0,2} -- Alt 7
	vector_lib[0x78] = {2,0,1,0,0,1,0,5,1,6,4,0,5,0,6,1,6,4,5,5,4,5,2,0} -- Alt 8
	vector_lib[0x79] = {0,1,0,4,2,6,5,6,6,5,6,1,5,0,4,0,3,1,3,6} -- Alt 9
	vector_lib[0x80] = {0,2,0,4,2,6,4,6,6,4,6,2,4,0,2,0,0,2} -- Alt 0
	vector_lib[0x81] = {0,0,0,5,B,B,0,3,6,3,5, 1} -- Alt 1
	vector_lib[0x82] = {0,6,0,0,5,6,6,3,5,0} -- Alt 2
	vector_lib[0x83] = {1,0,0,1,0,5,1,6,2,6,3,5,3,2,6,6,6,1} -- Alt 3
	vector_lib[0x84] = {0,5,6,5,6,3,3,0,2,0,2,6} -- Alt 4
	vector_lib[0x85] = {1,0,0,1,0,5,2,6,4,5,4,0,6,0,6,5} -- Alt 5
	vector_lib[0x86] = {3,0,1,0,0,1,0,5,1,6,2,6,3,5,3,0,6,2,6,5} -- Alt 6
	vector_lib[0x87] = {5,0,6,0,6,6,2,2,0,2} -- Alt 7
	vector_lib[0x88] = {2,0,1,0,0,1,0,5,1,6,4,0,5,0,6,1,6,4,5,5,4,5,2,0} -- Alt 8
	vector_lib[0x89] = {0,1,0,4,2,6,5,6,6,5,6,1,5,0,4,0,3,1,3,6} -- Alt 9
	vector_lib[0x8a] = {0,0,6,0,2,3,6,6,0,6}  -- Alt M
	vector_lib[0x8b] = {0,0,6,0,2,3,6,6,0,6}  -- Alt M
	vector_lib[0xb0] = {0,0,7,0,7,7,0,7,0,0,B,B,1,1,1,6} -- Block
	vector_lib[0xdd] = {7,0,5,0,B,B,6,0,6,4,B,B,7,4,4,4,B,B,7,9,7,6,4,6,3,9,B,B,5,6,5,9,B,B,7,11,3,11,2,14,B,B,
		1,16,7,16,7,19,3,19,3,16,B,B,7,22,2,21,B,B,0,20,0,21} -- Help (little H)
	vector_lib[0xed] = {7,0,5,0,B,B,6,0,6,4,B,B,7,4,4,4,B,B,7,9,7,6,4,6,3,9,B,B,5,6,5,9,B,B,7,11,3,11,2,14,B,B,
		1,16,7,16,7,19,3,19,3,16,B,B,7,22,2,21,B,B,0,20,0,21} -- Alt Help
	vector_lib[0xfb] = {5,1,6,2,6,5,5,6,4,6,2,3,B,B,0,3,0,3} -- question mark
	vector_lib[0xff] = {5,2,7,2,7,4,5,4,5,2,B,B,5,3,2,3,0,1,B,B,2,3,0,5,B,B,4,0,3,1,3,5,4,6} -- jumpman / stick man

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
			mode1 = mem:read_u8(0x6005)  -- 1-attract mode, 2-credits entered waiting to start, 3-when playing game
			mode2 = mem:read_u8(0x600a)  -- 7-climb scene, 10-how high, 15-dead, 16-game over
			stage = mem:read_u8(0x6227)  -- 1-girders, 2-pies, 3-springs, 4-rivets

			--print(tostring(mode1).."  "..tostring(mode2))
			--cls()
			if stage ==1 and (mode2 >= 2 and mode2 <= 4) or (mode2 >= 11 and mode2 <= 22) then
				draw_girders_stage()
			end
			draw_vector_characters()
			--debug_limits(1000)
			debug_vector_count()
		end
	end

	function draw_girders_stage()
		-- 1st girder
		draw_girder(  1,   0,   1, 111)  -- flat section
		draw_girder(  1, 111,   8, 223)  -- sloped section
		draw_ladder(  8,  80,   8) -- broken ladder bottom
		draw_ladder( 32,  80,   4) -- broken ladder top
		draw_ladder( 13, 184,  17) -- right ladder
		draw_oilcan(  8, 16)

		-- 2nd Girder
		draw_girder( 41,   0,  29, 207)
		draw_ladder( 46,  32,  17)  -- left ladder
		draw_ladder( 42,  96,  25)  -- right ladder
		draw_hammer( 56, 168)

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
		draw_hammer(148,  17)

		-- 6th girder
		draw_girder(165,   0, 165, 143)  -- flat section
		draw_girder(165, 143, 161, 207)  -- sloped section
		draw_ladder(172,  64,  52)  -- left ladder
		draw_ladder(172,  80,  52)  -- middle ladder
		draw_ladder(172, 128,  21)  -- right ladder
		draw_barrel(173, 0)
		draw_barrel(173, 10)
		draw_barrel(189, 0)
		draw_barrel(189, 10)

		-- Pauline's girder
		draw_girder(193,  88, 193, 136)
	end

	function vector(y1, x1, y2, x2)
		-- draw a single vector
		scr:draw_line(y1+wobble(), x1+wobble(), y2+wobble(), x2+wobble(), intensity())
		vector_count = vector_count + 1
	end

	function polyline(data, offset_y, offset_x)
		-- draw multiple chained lines from a table of y,x points.  Optional offset for start y,x.
		local _offy, _offx = offset_y or 0, offset_x or 0
		local _y, _x
		if data then
			for _i=1, #data, 2 do
				if _y and _x and data[_i] ~= B and data[_i+1] ~= B and _y ~= B and _x ~= B then
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
		return ({0xbbffffff, 0xddffffff, 0xffffffff})[math.random(3)]
	end

	function wobble()
		-- random change of the vector offset
		if not mac.paused then return math.random(-40, 60) / 100 else return 0 end -- random change of the vector offset
	end

	function cls()
		-- clear the screen
		scr:draw_box(0, 0, 256, 224, 0xff000000, 0xff000000)
	end

	-- vector objects
	-----------------
	function draw_oilcan(y, x)
		box(y+15,  x,  1,  16)  -- top lip
		box(y,     x,  1,  16)  -- bottom lip
		polyline({1,1,15,1,B,B,1,15,15,15,B,B,5,1,5,15,B,B,12,1,12,15,B,B,7,4,10,4,10,7,7,7,7,4,B,B,7,9,10,9,B,B,
				  7,13,7,11,10,11}, y, x)
	end

	function draw_hammer(y, x)
		polyline({5,0,7,0,8,1,8,8,7,9,5,9,4,8,4,1,5,0,B,B,4,4,0,4,0,5,4,5,B,B,8,4,9,4,9,5,8,5}, y, x)  -- hammer
	end

	function draw_barrel(y, x)
		-- draw an upright/stacked barrel
		polyline({3,0,12,0,15,2,15,7,12,9,3,9,0,7,0,7,0,2,3,0,B,B,1,1,1,8,B,B,14,1,14,8,B,B,2,3,13,3,B,B,
				  2,6,13,6}, y, x) -- horizontal and vertical bands
	end

	function draw_ladder(y, x, h)
		-- draw a single ladder at given y, x position of given height in pixels
		polyline({0,0,h,0,B,B,0,8,h,8},y,x)  -- left and right legs
		for i=0, h-2 do  -- draw rung every 4th pixel (skipping 2 pixels at bottom)
			if i % 4 == 0 then vector(y+i+2, x, y+i+2, x+8) end
		end
	end

	function draw_girder(y1, x1, y2, x2)
		-- draw parallel vectors (offset by 7 pixels) to form a girder.
		polyline({y1,x1,y2,x2,B,B,y1+7,x1,y2+7,x2})
		if enable_zigzags then  -- Fill the girders with optional zig zags
			local _zig = 8  -- zigzag width 4 or 8 works well
			for _x=x1, x2 - 1, _zig*2 do
				_y = y1 + (((y2 - y1) / (x2 - x1)) * (_x - x1))
				vector(_y+1,_x,_y+6,_x+_zig)
				vector(_y+6,_x+_zig,_y+1,_x+_zig*2)
			end
		end
	end

	function draw_vector_characters()
		-- Output vector characters based on contents of video ram ($7400-77ff)
		local _addr = 0x7440
		for _x=223, 0, -8 do
			for _y=255, 0, -8 do
				polyline(vector_lib[mem:read_u8(_addr)], _y - 6, _x - 6)
				_addr = _addr + 1
			end
		end
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

	-- event registration
	---------------------
	emu.register_start(function()
		initialize()
	end)

	emu.register_frame_done(main, "frame")
end
return exports