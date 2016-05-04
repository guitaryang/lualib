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



