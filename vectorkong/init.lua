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
	local vector_chars = {}
	vector_chars[0x00] = {0,2,0,4,2,6,4,6,6,4,6,2,4,0,2,0,0,2}
	vector_chars[0x01] = {0,0,0,5,0,3,6,3,5,1}
	vector_chars[0x02] = {0,6,0,0,5,6,6,3,5,0}
	vector_chars[0x03] = {1,0,0,1,0,5,1,6,2,6,3,5,3,2,6,6,6,1}
	vector_chars[0x04] = {0,5,6,5,6,3,3,0,2,0,2,6}
	vector_chars[0x05] = {1,0,0,1,0,5,2,6,4,5,4,0,6,0,6,5}
	vector_chars[0x06] = {3,0,1,0,0,1,0,5,1,6,2,6,3,5,3,0,6,2,6,5}
	vector_chars[0x07] = {5,0,6,0,6,6,2,2,0,2}
	vector_chars[0x08] = {2,0,1,0,0,1,0,5,1,6,4,0,5,0,6,1,6,4,5,5,4,5,2,0}
	vector_chars[0x09] = {0,1,0,4,2,6,5,6,6,5,6,1,5,0,4,0,3,1,3,6}
	vector_chars[0x11] = {0,0,4,0,6,3,4,6,0,6,2,6,2,0}
	vector_chars[0x12] = {0,0,6,0,6,5,5,6,4,6,3,5,2,6,1,6,0,5,0,0}
	vector_chars[0x13] = {1,6,0,5,0,2,2,0,4,0,6,2,6,5,5,6}
	vector_chars[0x14] = {0,0,6,0,6,4,4,6,2,6,0,4,0,0}
	vector_chars[0x15] = {0,5,0,0,3,0,3,4,3,0,6,0,6,5}
	vector_chars[0x16] = {0,0,3,0,3,5,3,0,6,0,6,6}
	vector_chars[0x17] = {3,4,3,6,0,6,0,2,2,0,4,0,6,2,6,6}
	vector_chars[0x18] = {0,0,6,0,3,0,3,6,0,6,6,6}
	vector_chars[0x19] = {0,0,0,6,0,3,6,3,6,0,6,6}
	vector_chars[0x1a] = {1,0,0,1,0,5,1,6,6,6}
	vector_chars[0x1b] = {0,0,6,0,3,0,0,6,3,0,6,6}
	vector_chars[0x1c] = {6,0,0,0,0,5}
	vector_chars[0x1d] = {0,0,6,0,2,3,6,6,0,6}
	vector_chars[0x1e] = {0,0,6,0,0,6,6,6}
	vector_chars[0x1f] = {1,0,5,0,6,1,6,5,5,6,1,6,0,5,0,1,1,0}
	vector_chars[0x20] = {0,0,6,0,6,5,5,6,3,6,2,5,2,0}
	vector_chars[0x21] = {1,0,5,0,6,1,6,5,5,6,2,6,1,5,2,3,0,6,1,5,0,4,0,1,1,0}
	vector_chars[0x22] = {0,0,6,0,6,5,5,6,4,6,2,3,2,0,2,3,0,6}
	vector_chars[0x23] = {1,0,0,1,0,5,1,6,2,6,4,0,5,0,6,1,6,4,5,5}
	vector_chars[0x24] = {6,0,6,3,0,3,6,3,6,6}
	vector_chars[0x25] = {} -- U

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

			--cls()
			draw_girders_stage()
			draw_vector_characters()
			--debug_limits(4000)
			--debug_vector_count()
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
		draw_girder( 29, 207,  41,   0)
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
		draw_girder( 95, 207, 107,   0)
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
				if _y and _x then vector(data[_i]+_offy, data[_i+1]+_offx, _y, _x) end
				_y, _x =data[_i]+_offy, data[_i+1]+_offx
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
		box(y,     x,  1,  16)  -- outline of oil can
		box(y+1, x+1, 14,  14)  -- bottom lip
		box(y+15,  x,  1,  16)  -- top lip
		box(y+7,   x+4,  3,   3)  -- "O"
		vector(y+7, x+9, y+10, x+9)  -- "I"
		polyline({y+7,x+13,y+7,x+11,y+10,x+11})  -- "L"
		vector(y+5, x+1, y+5, x+15)  -- horizontal stripe
		vector(y+12, x+1, y+12, x+15)  -- horizontal stripe
	end

	function draw_hammer(y, x)
		polyline({y+5,x,y+7,x,y+8,x+1,y+8,x+8,y+7,x+9,y+5,x+9,y+4,x+8,y+4,x+1,y+5,x})  -- hammer
		box(y,   x+4, 4, 1)  -- bottom handle
		box(y+8, x+4, 1, 1)  -- top handle
	end

	function draw_barrel(y, x)
		-- draw an upright/stacked barrel
		polyline({y+3,x,y+12,x,y+15,x+2,y+15,x+7,y+12,x+9,y+3,x+9,y,x+7,y,x+7,y,x+2,y+3,x})  -- barrel outline
		vector(y+1,  x+1, y+1,  x+8)  -- horizontal bands
		vector(y+14, x+1, y+14, x+8)
		vector(y+2,  x+3, y+13, x+3)  -- vertical bands
		vector(y+2,  x+6, y+13, x+6)
	end

	function draw_ladder(y, x, h)
		-- draw a single ladder at given y, x position of given height in pixels
		vector(y, x,   y+h, x)  -- left leg
		vector(y, x+8, y+h, x+8)  -- right leg
		for i=0, h-2 do  -- draw rung every 4th pixel (skipping 2 pixels at bottom)
			if i % 4 == 0 then vector(y+i+2, x, y+i+2, x+8) end
		end
	end

	function draw_girder(y1, x1, y2, x2)
		-- draw parallel vectors (offset by 7 pixels) to form a girder.  Co-ordinates relate to the bottom vector.
		vector(y1,   x1,   y2, x2, intensity())
		vector(y1+7, x1, y2+7, x2, intensity())
	end

	function draw_vector_characters()
		-- Output vector characters based on contents of video ram ($7400-77ff)
		local _code
		local _addr = 0x7440
		for _x=223, 0, -8 do
			for _y=255, 0, -8 do
				polyline(vector_chars[mem:read_u8(_addr)], _y - 6, _x - 6)
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