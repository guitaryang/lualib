local tinsert = table.insert
local mrandom = math.random
local setmetatable = setmetatable
local print = print
local assert = assert
local sformat = string.format
local ssub = string.sub
local sgsub = string.gsub
local sfind = string.find
local string = string
local io = io
local os = os
local table = table
local tostring = tostring

local lskiplist = require"lskiplist"


local function test()

	--[[
	-- keyinfo为table, score大值在前,key以字典顺序排
	--]]

	-- test
	-- [[
	local function comp(k1,k2)
		if k1.score > k2.score then
			return true
		elseif k1.score < k2.score then
			return false
		end
		if k1.key > k2.key then
			return false
		end
		return true
	end

	local function equalkeyinfo(k1,k2)
		if k1.key == k2.key and k1.score == k2.score then
			return true
		end
		return false
	end

	local keytostring = function(ki)
		return sformat("[%s][%s]", ki.key,ki.score)
	end

	local tls = lskiplist.new(comp, equalkeyinfo)

	local keyprefix = "guitar"

	local start = os.clock()
	local maxcount = 1000
	for i = 1, maxcount do
		local posfix = mrandom(1, maxcount)
		-- local posfix = i
		local key = keyprefix ..  posfix
		local score = mrandom(1, 1000000)
		tls:add(setmetatable({key=key, score = score}, {__tostring=keytostring}))
	end
	print("cost--time",os.clock() - start)

	tls:add(setmetatable({key=keyprefix.." test", score = 2000}, {__tostring=keytostring}))
	local dumpstr = tls:dumpskiplist(true)
	local fl = io.open("sldump.txt", "a+")
	fl:write("\ntest result\n")
	fl:write(dumpstr)
	fl:close()

	for i = 1, 4 do 
		local key = keyprefix .. i
		print(key, tls:getrank(key))
	end

	local list,err = tls:getrangebyrank(nil, 10, 20)
	--]]

end

local function test1()


	--[[
	-- keyinfo为table,但只有一个key值.key以字典顺序排
	--]]

	-- test
	-- [[
	local function comp(k1,k2)
		if k1.key > k2.key then
			return false
		end
		return true
	end

	local function equalkeyinfo(k1,k2)
		if k1.key == k2.key then
			return true
		end
		return false
	end

	local keytostring = function(ki)
		return sformat("[%s]", ki.key)
	end

	local tls = lskiplist.new(comp, equalkeyinfo)

	local start = os.clock()
	local maxcount = 1000
	for i = 1, maxcount do
		local posfix = mrandom(1, maxcount)
		local key = posfix
		tls:add(setmetatable({key=key}, {__tostring=keytostring}))
	end
	print("cost--time",os.clock() - start)

	tls:add(setmetatable({key= 2000}, {__tostring=keytostring}))
	local dumpstr = tls:dumpskiplist(true)
	local fl = io.open("sldump.txt", "a+")
	fl:write("\ntest result\n")
	fl:write(dumpstr)
	fl:close()

	for i = 1, 4 do 
		local key = i
		print(key, tls:getrank(key))
	end

	-- local list,err = tls:getrangebyrank(nil, 10, 20)
	--]]

end

local function test2()

	--[[
	-- keyinfo为字符串, 长度小的排名在前,长度相同的以字典顺序排
	--]]

	-- test
	-- [[
	local function comp(k1,k2)
		local l1 = #k1
		local l2 = #k2
		if l1 < l2 then
			return true
		elseif l1 > l2 then
			return false
		end
		if k1 <= k2 then
			return true
		end
		return false
	end

	local function equalkeyinfo(k1,k2)
		if k1 == k2 then
			return true
		end
		return false
	end

	local keytostring = function(ki)
		return sformat("[%s]", key)
	end

	local tls = lskiplist.new(comp, equalkeyinfo)

	local keyprefix = "guitar"

	local start = os.clock()
	local maxcount = 1000
	for i = 1, maxcount do
		local posfix = mrandom(1, maxcount)
		local key = keyprefix ..  posfix
		tls:add(key)
	end
	print("cost--time",os.clock() - start)

	tls:add( keyprefix .. 2000 )
	local dumpstr = tls:dumpskiplist(true)
	local fl = io.open("sldump.txt", "a+")
	fl:write("\ntest result\n")
	fl:write(dumpstr)
	fl:close()

	for i = 1, 4 do 
		local key = keyprefix .. i
		print(key, tls:getrank(key))
	end

	local list,err = tls:getrangebyrank(nil, 10, 20)
	--]]




end


test()
test1()
test2()


