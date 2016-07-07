
local lmap = require"lmap"

local tinsert = table.insert

local function test()

	local mm = lmap.new()

	mm:insert("gutiar1", 100)
	mm:insert("gutiar2", 200)
	mm:insert("gutiar3", 300)
	mm:insert("gutiar4", 400)
	mm:insert("gutiar5", 500)
	mm:insert("gutiar6", 600)

	mm["guitar7"] = 700
	print(mm.guitar7)

	mm["guitar7"] = 800
	print(mm.guitar7)

	mm.guitar7 = 900
	print(mm.guitar7)
	print(mm.guitar8)
	mm.guitar8 = nil

	mm:insert(50, 50000)
	mm:insert(50, 40000)
	print(mm[50])

	print("count = ", #mm)
	print("count = ", mm:count())

	for k, v in mm:pairs() do
		print("pairs---k,v=", k,v)
	end

	local iter = mm:first()
	while iter do
		print("iter--first---k,v=", iter.k, iter.v)
		iter = mm:next(iter)
	end

	local iter = mm:last()
	while iter do
		print("iter--last---k,v=", iter.k, iter.v)
		iter = mm:prev(iter)
	end

	--[[

	math.randomseed(os.time())
	local start = os.clock()

	local keyprefix = "robot"
	local count = 10000
	local record = {}
	for i = 1, count do
		 -- local posfix = math.random(1, count)
		local posfix = i
		local key = keyprefix ..  posfix
		local score = math.random(1, 1000 * 10000)
		mm[key] = score
		tinsert(record, key)
	end

	collectgarbage()
	local k, b = collectgarbage("count")
	k = k * 1024 + (b or 0)
	print("insert************cost--time=", os.clock() - start, k, mm:count())

	local start = os.clock()
	for i = 1, 4 do 
		local key = keyprefix .. i
		print(key, mm[key])
	end

	print("get val------------cost--time=", os.clock() - start, collectgarbage("count"), mm:count())




	local lr = #record
	if lr > 0 then
		local start = os.clock()
		for i = 1, count / 2  do
			-- local idx = math.random(1, #record)
			-- local val = record[math.random(1, #record)]
			local posfix = math.random(1, count)
			local key = keyprefix ..  posfix
			if mm:erase(key) then
				-- trb:check_valid()
			end
		end
		print("erase************cost--time=", os.clock() - start, collectgarbage("count"), mm:count())
		collectgarbage()
	end

	local start = os.clock()
	for i = 1, 400 do 
		local key = keyprefix .. i
		print(key, mm[key])
	end

	print("get val------------cost--time=", os.clock() - start, collectgarbage("count"), mm:count())
	--]]

end

test()


