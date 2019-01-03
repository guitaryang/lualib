--[[=====================================================================================
* 
*    Filename:  lskiplist.lua
* 
*    Description: 
* 
*    Created:  2016年05月03日 19时42分06秒
* 
*    Author:  guitar <guitaryangw@gmail.com>
*
*    Company:  UNKNOW
*
*    All rights reserved.
*    Use, modification and distribution are subject to the "MIT License"
* 
* 
=====================================================================================--]]

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
local type = type


local SKIPLIST_MAXLEVEL = 32 --[[  Should be enough for 2^32 elements 跳表结点最大层 ]]
local SKIPLIST_P = 0.25      --[[ SkipList P = 1/4 增加层数的概率 ]] 

math.randomseed(os.time())

local lskiplist = {}

--[[

-- keyinfo类型为table时,必要结构信息
keyinfo = 
{
	-- 必需存在且与其他元素不相等
	-- 注意:在比较器中,若其他数据都相等时一定要使用key做最后的比较,而且由于比较器使用方式限制,一定要用下面这两种方式其中一种
	--		1: if k1.key <= k2.key then return true end (相当于: if k1.key > k2.key then return false end)
	--		2: if k1.key >= k2.key then return true end (相当于: if k1.key < k2.key then return false end)
	key = key,  


	-- 用户数据
	score = score,
	time = time,
	...
}

-- 跳表结点信息
skipnode = 
{

	keyinfo = keyinfo,

	level =  -- 层(skiplistlevel)
	{
		[1] = 
		{

			forward = skipnode, -- 前继结点

			span = num, -- 记录同一层中当前结点和前继结点相距多少个元素(相当于排名的差距)    

		},

		...,

		[n] = 
		{

			forward = skipnode,

			span = num,

		}
	}
}
--]]

function lskiplist.new( comparator, equalkeyinfo )


	local self = 
	{
		sl = {
			header = 
			{
				level={}
			},
			tail = nil, 
			level = 1, -- 当前最大层
		},
		cur_num = 0, -- 当前元素数
		data_tab = {}, -- [key] = keyinfo 
		comparator = comparator,
		equalkeyinfo = equalkeyinfo,
	}

	local headerlevel = self.sl.header.level
	for i = 1, SKIPLIST_MAXLEVEL do
		headerlevel[i] =  {forward = nil, span = 0}
	end

	setmetatable( self, {__index = lskiplist} )

	return self
end


----------------------------------------------------------------------------------------------------------
-- lskiplist operation functions
local function slrandomLevel() 
	local level = 1
	while mrandom() < SKIPLIST_P do
		level = level + 1
	end
	if level < SKIPLIST_MAXLEVEL then
		return level
	end
	return SKIPLIST_MAXLEVEL
end

local updatetmp = {}
local function _reset_updatetmp()
	for i = 1, SKIPLIST_MAXLEVEL do
		updatetmp[i] = nil
	end
	return updatetmp
end

local ranktmp = {}
local function _reset_ranktmp()
	for i = 1, SKIPLIST_MAXLEVEL do
		ranktmp[i] = 0
	end
	return ranktmp
end

local function _insert(self, keyinfo)
	local update = _reset_updatetmp()
	local rank = _reset_ranktmp()
	local sl = self.sl
	local x = sl.header 

	-- find update_nodes
	for i = sl.level, 1, -1 do
		if i == sl.level then
			rank[i] = 0
		else
			rank[i] = rank[i+1]
		end
		while true do
			local lv = x.level[i]
			local node = lv.forward
			if not node then
				break
			end
			if self.comparator(keyinfo, node.keyinfo) then
				break
			end
			x = node
			rank[i] = rank[i] + lv.span
		end
		update[i] = x
	end

	local new_level = slrandomLevel() 
	if new_level > sl.level then 
		-- update_nodes[sl.level + 1 ... new_level] -> header
		for i = sl.level + 1, new_level do
			update[i] = sl.header
			update[i].level[i].span = self.cur_num
		end
		sl.level = new_level
	end

	local n = {	keyinfo = keyinfo,level = {},}

	-- concat n and update_nodes
	for k = 1, new_level do
		n.level[k] = {forward=nil, span=0}
		n.level[k].forward = update[k].level[k].forward
		update[k].level[k].forward = n

		n.level[k].span = update[k].level[k].span - (rank[1] - rank[k])
		update[k].level[k].span = rank[1] - rank[k] + 1
	end

	-- add unreached nodes span 
	for t = (new_level + 1), sl.level do 
		update[t].level[t].span = update[t].level[t].span + 1
	end

	if not n.level[1].forward then
		sl.tail = n
	end

	self.cur_num = self.cur_num + 1

	return rank[1] + 1
end

local function _remove(self, keyinfo)
	local update = _reset_updatetmp()
	local sl = self.sl
	local x = sl.header 

	-- find update_nodes
	for i = sl.level, 1, -1 do
		while true do
			local lv = x.level[i]
			local node = lv.forward
			if not node then
				break
			end
			if self.comparator(keyinfo, node.keyinfo) then
				break
			end
			x = node
		end
		update[i] = x
	end

	local deln = x.level[1].forward
	if (not deln) or (not self.equalkeyinfo(keyinfo, deln.keyinfo)) then
		return false
	end

	-- remove deln by update_nodes
	for k = 1, sl.level do
		local uplv = update[k].level[k]
		if uplv.forward == deln then
			uplv.forward = deln.level[k].forward
			uplv.span = uplv.span + deln.level[k].span - 1 
		else
			uplv.span = uplv.span - 1 
		end
	end

	if sl.tail == deln then
		sl.tail = x
	end

	local cur_lv = sl.level
	while cur_lv > 1 and (not sl.header.level[cur_lv].forward) do
		cur_lv = cur_lv - 1
	end
	sl.level = cur_lv

	self.cur_num = self.cur_num - 1

	return true
end

local function _getrank(self, keyinfo)
	local sl = self.sl
	local x = sl.header 

	local rank = 0
	for i = sl.level, 1, -1 do
		local node = nil
		while true do
			local lv = x.level[i]
			node = lv.forward
			if not node then
				break
			end
			if self.comparator(keyinfo, node.keyinfo) then
				break
			end
			rank = rank + lv.span
			x = node
		end

		if node and self.equalkeyinfo(node.keyinfo, keyinfo) then
			rank = rank + x.level[i].span
			break
		end
	end
	return rank
end

local function _getnodebyrank( self, rank )
	local sl = self.sl
	local x = sl.header
	local traversed = 0
	for i = sl.level, 1, -1 do
		local node = nil
		while true do
			local lv = x.level[i]
			node = lv.forward
			if not node then
				break
			end
			if (lv.span + traversed) > rank then
				break
			end

			traversed = traversed + lv.span 

			x = node
		end

		if traversed == rank then
			return x
		end
	end
	return nil
end

local function _iterator_node(self, func)
	local sl = self.sl
	local node = sl.header
	for rank = 1, self.cur_num do
		node = node.level[1]
		if not node.forward then
			break
		end
		node = node.forward
		if not func(node.keyinfo, rank) then
			break
		end
	end
end
----------------------------------------------------------------------------------------------------------

local slheadflag = "$$head&&"
local NODEFORMAT = "|node[k=%s,sp=%.5d]"
local RANKFORMAT = "|rank[k=%s,rk=%d]"
local paddingchar = "-"
local blanktmpchar = "#"
function lskiplist:dumpskiplist( istostring )
	local sl = self.sl
	local cur_num = self.cur_num
	local max_level = SKIPLIST_MAXLEVEL
	local sline = {}
	local rank = 0
	local maxstrlen = 0 
	for i = 0, cur_num do
		sline[i] = {}
		local line = sline[i]
		local node = sl.header
		-- 取第几个结点
		for j = 1, i do
			node = node.level[1].forward
		end
		
		-- 遍历此结点的每一层
		if node then
			local k = slheadflag
			if node.keyinfo then 
				if istostring or (type(node.keyinfo) ~= "table")then
					k = tostring(node.keyinfo)
				else
					k = tostring(node.keyinfo.key)
				end
			end
			local curlvmaxlen = 0
			for t = max_level, 1, -1 do
				local lv = node.level[t]
				local key = k
				if key == slheadflag then
					key = sformat(key..",lv[%.2d]", t)
				end
				if lv then
					line[t] = sformat(NODEFORMAT, key, lv.span)
					if #line[t] > maxstrlen then
						maxstrlen = #line[t]
					end
					if #line[t] > curlvmaxlen then
						curlvmaxlen = #line[t]
					end
				end
			end
			local rankstr = ""
			if k == slheadflag then
				rankstr = sformat(RANKFORMAT, slheadflag,  rank)
			else
				rankstr = sformat(RANKFORMAT, k,  rank)
			end
			rankstr = sgsub(rankstr," ", blanktmpchar)
			rankstr = sformat(sformat("%%-%ds", curlvmaxlen), rankstr)
			rankstr = sgsub(rankstr," ", paddingchar)
			rankstr = sgsub(rankstr,"%"..blanktmpchar, " ")
			line[0] = rankstr
			if #rankstr > maxstrlen then
				maxstrlen = #rankstr
			end
			rank = rank + 1
		end
	end
	local dumpstr = ""
	if maxstrlen > 30 then
		maxstrlen = maxstrlen + 5
	end
	local strformat = sformat("%%%ds", maxstrlen)
	for l = max_level, 0, -1 do
		local str = ""
		for i = 0, cur_num do
			local nstr = sline[i][l] or paddingchar
			if not sfind(nstr, slheadflag) then
				nstr = sgsub(nstr," ", blanktmpchar)
				nstr = sgsub(sformat(strformat,nstr)," ", paddingchar)
				nstr = sgsub(nstr,"%"..blanktmpchar, " ")
			end
			str = str .. nstr
		end
		dumpstr = dumpstr .. str .."\n"
	end
	return dumpstr
end

local function dumpfile(self, msg)
	local fl = io.open("sldump.txt", "a+")
	if not fl then
		return 
	end
	fl:write("\n") 
	if msg then 
		fl:write(msg.."\n") 
	end
	local dumpstr = self:dumpskiplist()
	fl:write(dumpstr)
	fl:close()
	return dumpstr
end

-- check span invalid
 function lskiplist:checkspanvalid()
	local sl = self.sl
	local cur_num = self.cur_num
	for i = 1, sl.level do
		local node = sl.header.level[i].forward
		local span = sl.header.level[i].span
		local str = "i=" .. i
		str = sformat(str..",span[%d]", span)
		while node do
			span = span + node.level[i].span
			str = sformat(str..",span[%d]", node.level[i].span)
			node = node.level[i].forward
		end
		print(str)
		if span ~= cur_num then
			dumpfile(self, "****span invalid****")
		end
		assert(span == cur_num, sformat("data invalid, span[%d], level[%d]", span,i) )
	end
end

function lskiplist:add(keyinfo)
	local key = keyinfo
	if type(keyinfo) == "table" then
		key = keyinfo.key
	end
	local old_keyinfo = self.data_tab[key] 
	if old_keyinfo then
		_remove(self, old_keyinfo)

		-- debug check
		-- self:checkspanvalid()
	end
	self.data_tab[key] = keyinfo
	--[[
	local rank = _insert(self, keyinfo)
	-- debug check
	-- self:checkspanvalid()
	return rank
	--]]
	return _insert(self, keyinfo)
end

function lskiplist:remove(key)
	local old_keyinfo = self.data_tab[key] 
	if old_keyinfo then
		_remove(self, old_keyinfo)

		self.data_tab[key] = nil

		-- debug check
		-- self:checkspanvalid()
	end
end

function lskiplist:getkeyinfo(key)
	return self.data_tab[key] 
end

function lskiplist:getrank(key)
	local keyinfo = self.data_tab[key] 
	if not keyinfo then
		return 0
	end
	return _getrank(self, keyinfo)
end

function lskiplist:get_count()
	return self.cur_num
end

function lskiplist:get_first()
	if self.cur_num <= 0 then
		return nil
	end
	return self.sl.header.level[1].forward.keyinfo
end

function lskiplist:get_last()
	if self.cur_num <= 0 then
		return nil
	end
	return self.sl.tail.keyinfo
end

function lskiplist:getrangebyrank( list, startrank, endrank )
	list = list or {}

	startrank = startrank or 1
	if startrank <= 0 then
		startrank = 1
	end
	if startrank > self.cur_num then
		return list, false
	end
	endrank = endrank or self.cur_num
	if endrank > self.cur_num then
		endrank = self.cur_num
	end
	if endrank < startrank then
		return list, false
	end

	local snode = _getnodebyrank(self, startrank)
	if not snode then
		return list, false
	end

	for i = startrank, endrank do
		if not snode then
			break
		end
		tinsert(list, snode.keyinfo)
		snode = snode.level[1].forward
	end
	return list, true
end

-- func(keyinfo, rank) end
function lskiplist:iterate( func )
	_iterator_node(self, func)
end

return lskiplist



