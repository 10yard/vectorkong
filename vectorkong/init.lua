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

	function initialize()
		mame_version = tonumber(emu.app_version())
		if mame_version >= 0.196 then
			if type(manager.machine) == "userdata" then
				mac = manager.machine
				vid = mac.video
			else
				mac =  manager:machine()
				vid = mac:video()
			end
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

			--debug_limits(1000)
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
		--scr:draw_line((y1+wobble())*3, (x1+wobble())*3, (y2+wobble())*3, (x2+wobble())*3, intensity())
		vector_count = vector_count + 1
	end

	function polyline(data)
		-- draw multiple chained lines from a table of x, y points
		local _y, _x
		for _i=1, #data, 2 do
			if _y and _x then vector(data[_i], data[_i+1], _y, _x) end
			_y, _x =data[_i], data[_i+1]
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
		return (0xdd000000 * math.random(3)) + 0x00ffffff
	end

	function wobble()
		-- random change of the vector offset
		-- return math.random(-40, 60) / 100  -- bigger wobble
		return math.random(-40, 60) / 100 -- random change of the vector offset
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