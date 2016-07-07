--[[=====================================================================================
* 
*    Filename:  lmap.lua
* 
*    Description: 
* 
*    Created:  2016年07月07日 20时44分41秒
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

local lrbtree = require"lrbtree"

local tostring = tostring

local lmap = {}

local function comp_func( a, b )
	local stra = tostring(a.k)
	local strb = tostring(b.k)

	if stra > strb then
		return 1
	elseif stra < strb then
		return -1
	end
	return 0
end

local function pair_func(t)
	local tab = t
	local iter = tab.container:first()
	return function(t, k)
		if not iter then
			return nil, nil
		end
		local tmp = iter
		iter = tab.container:next( iter )
		return tmp.k, tmp.v
	end
end

--[[
	支持[]或.访问元素
--]]
local function index_func(t, k)
	local lmap_func = lmap[k]
	if lmap_func then
		return  lmap_func
	end
	return lmap.find(t, k)
end

--[[
	支持[]或.修改或添加新元素
--]]
local function newindex_func(t, k, v)
	local value = t.container:find{k=k}
	if value then
		value.v = v
	else
		t.container:insert{k=k, v=v}
	end
end

local meta = {
	__index = index_func,
	__newindex = newindex_func,
	__pairs = pair_func, -- lua5.2以上版本支持
	__ipairs = pair_func,  -- lua5.2以上版本支持
}

function lmap.new()

	local container = lrbtree.new(comp_func)

	local self = 
	{
		container = container,
	}

	setmetatable( self, meta )

	return self
end

function lmap:find( key )
	local value = self.container:find{k=key}
	return value and value.v or nil
end

-- key存在,插入将失败
function lmap:insert(key, val)
	local value = self.container:find{k=key}
	if value then
		return false
	end
	return self.container:insert{k=key, v=val}
end

function lmap:erase(key)
	return self.container:erase{k=key, v=val}
end

function lmap:count()
	return self.container:count()
end

-- 遍历所有元素
function lmap:pairs()
	return pair_func(self)
end

--[[
	返回值:
	迭代器表 = 
	{
		k = key,  -- 不要修改k值
		v = val,
	}
--]]
function lmap:first()
	return self.container:first()
end


--[[
	返回值:
	迭代器表 = 
	{
		k = key,  -- 不要修改k值
		v = val,
	}
--]]
function lmap:last()
	return self.container:last()
end

function lmap:next( iter )
	return self.container:next( iter )
end

function lmap:prev( iter )
	return self.container:prev( iter )
end


return lmap


