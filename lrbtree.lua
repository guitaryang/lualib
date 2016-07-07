--[[=====================================================================================
 * 
 *    Filename:  lrbtree.lua
 * 
 *    Description: lua版 red black tree
 *
 *	  -- 红黑树特性
 *	  1、	一个结点不是红色就是黑色.
 *	  2、	根结点必需是黑色。
 *	  3、	所有叶子(NIL)必须是黑色。
 *	  4、	如果一个结点是红色，则它的两个孩子必需是黑色。
 *	  5、	从给定结点到其子孙叶子(NIL)结点的所有路径包含相同的黑色结点数量。
 *
 *	  (6)、由特性4得,若结点为红色，则它的父结点一定黑色
 *	  (7)、由特性5得,若结点为红色，它的两孩子要么都为叶子，要么都为非叶
 *
 *	  -- 红黑树结点
 *	  rbnode = 
 *	  {
 *	  	color = color,(RB_RED or RB_BLACK)
 *
 *	  	parent = rbnode,
 *
 *	  	left = rbnode,
 *
 *	  	right = rbnode,
 *
 *	  	val = val,
 *
 *	  }
 *
 *	  comparator 返回值为 ret == 0:表示相等, ret > 0:表示大于 ret < 0:表示小于
 *
 *	  每种情况中:大写字母表示黑色结点，小写字母表示红色结点。
 *	  		   未知颜色使用带括号的小写字母表示。并且会附带
 *			   字字注释。
 *
 * 
 *    Created:  2016年07月06日 18时45分57秒
 * 
 *    Author:  guitar 
 *
 *    Company:  UNKNOW
 * 
 ===================================================================================== --]]

local tremove = table.remove
local tinsert = table.insert

local lrbtree = {}

local RB_RED = 0
local RB_BLACK = 1


function lrbtree.new( comparator )

	local self = 
	{
		root = nil,
		comparator = comparator,
		cur_num = 0,
	}

	setmetatable( self, {__index = lrbtree} )

	return self
end

---------------------------------------------------------------------------------------------
-- kernel
local function lrb_insert_color( self, node )
	local parent = node.parent
	local gparent, tmp

	while true do
		if not parent then
			node.color = RB_BLACK
			node.parent = nil 

			break
		elseif parent.color == RB_BLACK then
			break
		end

		-- then parent.color == RB_RED and gparent is not nil
		gparent = parent.parent
		tmp = gparent.right
		if tmp ~= parent then -- parent == gparent.left
			if tmp and tmp.color == RB_RED then
				--[[
				
				 Case 1 - color flips
				
				       G            g
				      / \          / \
				     p   u  -->   P   U
				    /            /
				   n            n
				
				--]]
				parent.color = RB_BLACK
				tmp.color = RB_BLACK
				gparent.color = RB_RED

				node = gparent
				parent = node.parent

				-- continue
			else
				tmp = parent.right
				if node == tmp then
					--[[
					 Case 2 - left rotate at parent
					
					      G             G
					     / \           / \
					    p   U  -->    n   U
					     \           /
					      n         p
					
					--]]
					-- rotate left at 'parent'
					tmp = node.left
					parent.right = tmp
					node.left = parent
					if tmp then
						tmp.parent = parent
					end

					parent.parent = node

					parent = node
					tmp = node.right
				end

				--[[
				 Case 3 - right rotate at gparent
				
				        G           P
				       / \         / \
				      p   U  -->  n   g
				     /                 \
				    n                   U
				
				--]]
				gparent.left = tmp
				parent.right = gparent
				if tmp then
					tmp.parent = gparent
				end

				parent.color = RB_BLACK
				gparent.color = RB_RED

				tmp = gparent.parent
				parent.parent = tmp
				gparent.parent = parent
				if tmp then
					if tmp.left == gparent then
						tmp.left = parent
					else
						tmp.right = parent
					end
				else
					self.root = parent
				end


				break
			end
		else
			tmp = gparent.left
			if tmp and tmp.color == RB_RED then
				parent.color = RB_BLACK
				tmp.color = RB_BLACK
				gparent.color = RB_RED

				node = gparent
				parent = node.parent

				-- continue
			else
				tmp = parent.left
				if node == tmp then
					-- right rotate at 'parent'

					tmp = node.right
					parent.left = tmp
					node.right = parent
					if tmp then
						tmp.parent = parent
					end

					parent.parent = node

					parent = node
					tmp = node.left
				end
				-- left rotate at 'gparent'
				gparent.right = tmp
				parent.left = gparent
				if tmp then
					tmp.parent = gparent
				end

				parent.color = RB_BLACK
				gparent.color = RB_RED

				tmp = gparent.parent
				parent.parent = tmp
				gparent.parent = parent
				if tmp then
					if tmp.left == gparent then
						tmp.left = parent
					else
						tmp.right = parent
					end
				else
					self.root = parent
				end

				break
			end
		end
	end
end

local function lrb_erase_color( self, parent )
	local node, sibling, tmp1, tmp2, gparent
	while true do
		sibling = parent.right
		if node ~= sibling then
			-- node == parent.left
			if sibling.color == RB_RED then
				-- 此时sibling的两孩子一定是非叶黑结点,P一定是黑色, 因被删除结点为黑色,
				-- 若sibling的两个孩子都为叶子,被经过sibling的路径至少会少个黑色结点,所以sibling的两孩子肯定不是叶子
				--[[
				 Case 1 - left rotate at parent
				
				     P               S
				    / \             / \
				   N   s    -->    p   Sr
				      / \         / \
				     Sl  Sr      N   Sl
				
				--]]
				sibling.color = RB_BLACK
				parent.color = RB_RED

				tmp1 = sibling.left
				parent.right = tmp1
				tmp1.parent = parent
				sibling.left = parent

				gparent = parent.parent
				sibling.parent = gparent
				parent.parent = sibling
				if gparent then
					if parent == gparent.left then
						gparent.left = sibling
					else
						gparent.right = sibling
					end
				else
					self.root = sibling
				end

				sibling = tmp1
			end

			tmp1 = sibling.left 
			tmp2 = sibling.right
			-- 此时sibling一定为黑色
			if (not tmp1 or tmp1.color == RB_BLACK) and 
				(not tmp2 or tmp2.color == RB_BLACK) then
				if parent.color == RB_RED then
					sibling.color = RB_RED
					parent.color = RB_BLACK
					break
				end
				sibling.color = RB_RED

				node = parent
				parent = parent.parent
				if not parent then
					break
				end

				-- continue
			else
				-- 说明tmp1和tmp2中一定有一个为红色
				if tmp1 and tmp1.color == RB_RED then
					-- 以sibling进行一次右旋,并交换颜色
					--[[
					 Case 3 - right rotate at sibling
					 (p could be either color here)
					
					   (p)           (p)
					   / \           / \
					  N   S    -->  N   Sl
					     / \             \
					    sl  Sr            s
					                       \
					                        Sr
					--]]
					tmp1.color = RB_BLACK
					sibling.color = RB_RED
					
					tmp2 = tmp1.right
					sibling.left = tmp2
					sibling.parent = tmp1
					if tmp2 then
						tmp2.parent = sibling
					end
					tmp1.right = sibling
					tmp1.parent = parent

					tmp2 = sibling
					sibling = tmp1
					tmp1 = sibling.left
				end
				-- 此时tmp2为红色
				--[[
				 Case 4 - left rotate at parent + color flips
				 (p and sl could be either color here.
				  After rotation, p becomes black, s acquires
				  p's color, and sl keeps its color)
				
				      (p)             (s)
				      / \             / \
				     N   S     -->   P   Sr
				        / \         / \
				      (sl) sr      N  (sl)
				--]]

				sibling.color = parent.color
				parent.color = RB_BLACK
				tmp2.color = RB_BLACK

				sibling.left = parent
				gparent = parent.parent
				sibling.parent = gparent
				if gparent then
					if parent == gparent.left then
						gparent.left = sibling
					else
						gparent.right = sibling
					end
				else
					self.root = sibling
				end

				parent.parent = sibling
				parent.right = tmp1
				if tmp1 then
					tmp1.parent = parent
				end

				break
			end
		else
			sibling = parent.left
			-- node == parent.right
			if sibling.color == RB_RED then
				--[[
				 Case 1 - right rotate at parent
				
				     P               S       
				    / \             / \     
				   s   N    -->    Sl  p   
				  / \                 / \ 
				  Sl Sr              Sr  N 
				
				--]]
				sibling.color = RB_BLACK
				parent.color = RB_RED

				tmp1 = sibling.right
				parent.left = tmp1
				tmp1.parent = parent
				sibling.right = parent

				gparent = parent.parent
				sibling.parent = gparent
				parent.parent = sibling
				if gparent then
					if parent == gparent.left then
						gparent.left = sibling
					else
						gparent.right = sibling
					end
				else
					self.root = sibling
				end

				sibling = tmp1
			end

			tmp1 = sibling.right 
			tmp2 = sibling.left
			-- 此时sibling一定为黑色
			if (not tmp1 or tmp1.color == RB_BLACK) and 
				(not tmp2 or tmp2.color == RB_BLACK) then
				if parent.color == RB_RED then
					sibling.color = RB_RED
					parent.color = RB_BLACK
					break
				end
				sibling.color = RB_RED

				node = parent
				parent = parent.parent
				if not parent then
					break
				end

				-- continue
			else
				-- 说明tmp1和tmp2中一定有一个为红色
				if tmp1 and tmp1.color == RB_RED then
					-- 以sibling进行一次左旋,并交换颜色
					--[[
					 Case 3 - left rotate at sibling
					 (p could be either color here)
					
					   (p)           (p)
					   / \           / \
					  S   N    -->  Sr  N 
					 / \           /      
					sl  Sr        s
					             /       
					            Sl
					
					--]]
					tmp1.color = RB_BLACK
					sibling.color = RB_RED
					
					tmp2 = tmp1.left
					sibling.right = tmp2
					sibling.parent = tmp1
					if tmp2 then
						tmp2.parent = sibling
					end
					tmp1.left = sibling
					tmp1.parent = parent

					tmp2 = sibling
					sibling = tmp1
					tmp1 = sibling.right
				end
				-- 此时tmp2为红色
				--[[
				 Case 4 - right rotate at parent + color flips
				 (p and sr could be either color here.
				  After rotation, p becomes black, s acquires
				  p's color, and sr keeps its color)
				
				      (p)             (s)
				      / \             / \
				     S   N     -->   Sl  P
				    / \					/ \
				  sl (sr)			  (sr) N  
				
				--]]

				sibling.color = parent.color
				parent.color = RB_BLACK
				tmp2.color = RB_BLACK

				sibling.right = parent
				gparent = parent.parent
				sibling.parent = gparent
				if gparent then
					if parent == gparent.left then
						gparent.left = sibling
					else
						gparent.right = sibling
					end
				else
					self.root = sibling
				end

				parent.parent = sibling
				parent.left = tmp1
				if tmp1 then
					tmp1.parent = parent
				end

				break
			end
		end
	end
end

local function lrb_erase( self, node )
	local child = node.right
	local tmp = node.left
	local parent, rebalance

	parent = node.parent
	if not tmp then
		-- Case 1: node to erase has no more than 1 child (easy!)
		local ncolor = node.color
		if parent then
			if node == parent.left then
				parent.left = child
			elseif node == parent.right then
				parent.right = child
			end
		else
			self.root = child
		end
		if child then
			-- child肯定是红色
			child.color = ncolor
			child.parent = parent
		else
			if ncolor == RB_BLACK then
				rebalance = parent
			end
		end
	elseif not child then
		-- Still case 1, but this time the child is node->rb_left.
		-- tmp肯定是红色,所以不需要重新平衡
		tmp.color = node.color 
		tmp.parent = node.parent
		if parent then
			if node == parent.left then
				parent.left = tmp
			elseif node == parent.right then
				parent.right = tmp
			end
		else
			self.root = tmp
		end
	else
		local successor,child2 = child
		tmp = child.left

		if not tmp then
			--[[
			 Case 2: node's successor is its right child
			
			    (n)          (s)
			    / \          / \
			  (x) (s)  ->  (x) (c)
			        \
			        (c)
			--]]
			parent = successor
			child2 = successor.right
		else
			--[[
			 Case 3: node's successor is leftmost under
			 node's right child subtree
			
			    (n)          (s)
			    / \          / \
			  (x) (y)  ->  (x) (y)
			      /            /
			    (p)          (p)
			    /            /
			  (s)          (c)
			    \
			    (c)
			
			--]]
			repeat 
				parent = successor
				successor = tmp
				tmp = tmp.left
			until( not tmp )
			child2 = successor.right

			parent.left = child2

			successor.right = child
			child.parent = successor
		end
		
		tmp = node.left
		successor.left = tmp
		tmp.parent = successor

		tmp = node.parent
		local scolor = successor.color
		successor.color = node.color
		successor.parent = tmp
		if tmp then
			if node == tmp.left then
				tmp.left = successor
			else
				tmp.right = successor
			end
		else
			self.root = successor
		end

		if child2 then
			-- child2一定为红, successor一定为黑,否则将会违反特性5,此时只需要把child2的颜色置为黑色
			child2.color = RB_BLACK
			child2.parent = parent
		else
			if scolor == RB_BLACK then
				rebalance = parent
			end
		end
	end

	if rebalance then
		-- rebalance 一定有一个非叶结点,且被删除结点现在位置为NULL
		lrb_erase_color(self, rebalance)
	end
end

local function lrb_first( self )
	local n = self.root
	if not n then
		return nil
	end
	local tmp = n.left
	while tmp do
		n = tmp
		tmp = tmp.left
	end
	return n
end

local function lrb_last( self )
	local n = self.root
	if not n then
		return nil
	end

	local tmp = n.right
	while tmp do
		n = tmp
		tmp = tmp.right
	end
	return n
end

local function lrb_next( node )
	if not node then
		return nil
	end

	local tmp 
	if node.right then
		node = node.right
		tmp = node.left
		while tmp do
			node = tmp
			tmp = tmp.left
		end
		return node
	end

	tmp = node.parent
	while tmp and (node == tmp.right) do
		node = tmp
		tmp = node.parent
	end

	return tmp
end

local function lrb_prev( node )
	if not node then
		return nil
	end

	local tmp
	if node.left then
		node = node.left
		tmp = node.right
		while tmp do
			node = tmp
			tmp = tmp.left
		end
		return node
	end

	tmp = node.parent
	while tmp and (node == tmp.left) do
		node = tmp
		tmp = node.parent
	end

	return tmp
end

local function lrb_find( self, val )
	local node = self.root
	local comparator = self.comparator
	while node do
		local ret = comparator(val, node.val)
		if ret > 0 then
			node = node.right
		elseif ret < 0 then
			node = node.left
		else
			break
		end
	end
	return node
end

---------------------------------------------------------------------------------------------

function lrbtree:first()
	local node = lrb_first(self)
	return node and node.val or nil
end

function lrbtree:last()
	local node = lrb_last(self)
	return node and node.val or nil
end

function lrbtree:next( val )
	local node = lrb_find(self, val)
	if not node then
		return nil
	end
	node = lrb_next(node)
	return node and node.val or nil
end

function lrbtree:prev( val )
	local node = lrb_find(self, val)
	if not node then
		return nil
	end
	node = lrb_prev(node)
	return node and node.val or nil
end

function lrbtree:find( val )
	local node = lrb_find(self, val)
	return node and node.val or nil
end

function lrbtree:insert( val )
	local node = self.root
	local comparator = self.comparator
	local parent,ret
	while node do
		ret = comparator(val, node.val)
		parent = node
		if ret > 0 then
			node = node.right
		elseif ret < 0 then
			node = node.left
		else
			return false -- 已经存在
		end
	end

	node = 
	{
		color = RB_RED,
		parent = parent,
		val = val,
		left = nil,
		right = nil,
	}
	if ret then
		if ret > 0 then
			parent.right = node
		else
			parent.left = node
		end
		lrb_insert_color(self, node)
	else
		self.root = node
		node.color = RB_BLACK
	end

	self.cur_num = (self.cur_num or 0) + 1

	return true
end

function lrbtree:erase( val )
	local node = lrb_find(self, val)
	if not node then
		return false
	end

	lrb_erase(self, node)

	self.cur_num = self.cur_num - 1

	return true
end

function lrbtree:count()
	return self.cur_num
end


function lrbtree:check_valid()
	local root = self.root
	if not root then
		return 
	end
	assert(root.color == RB_BLACK, "check_valid, root color is not RB_BLACK")

	local node_count = 0
	local properties_4_check = function(node)
		node_count = node_count + 1
		if node.left then
			assert(node.left.parent == node, "check valid parent, node left val[" .. tostring(node.left.val) .."] parent is not node [".. tostring(node.val).."] ")
			if node.color == RB_RED then
				assert(node.left.color == RB_BLACK, "check valid 4, node.val[" .. tostring(node.val) .."] node left child [".. tostring(node.left.val).."] color is red too ")
			end
		end
		if node.right then
			assert(node.right.parent == node, "check valid parent, node right val[" .. tostring(node.right.val) .."] parent is not node [".. tostring(node.val) .."] ")
			if node.color == RB_RED then
				assert(node.right.color == RB_BLACK, "check valid 4, node.val[" .. tostring(node.val) .."] node right child [".. tostring(node.right.val) .. "] color is red too ")
			end
		end
	end

	-- 特性4,5 检测
	local black_count = 0
	local tmp, node = root
	-- find first node
	while tmp do

		node = tmp

		if node.color == RB_BLACK then
			black_count = black_count + 1
		end

		properties_4_check(node)

		tmp = tmp.left
	end

	-- do it ..

	local bcount = black_count
	while true and node do
		if (not node.left) or (not node.right) then
			if bcount ~= black_count then
				print(self:dump())
			end
			assert(bcount == black_count, "check_valid 5, node[".. tostring(node.val).. "] path black node count["..bcount .."] is not ".. black_count )
		end
		if node.right then
			-- 延右孩子搜索
			node = node.right
			if node.color == RB_BLACK then
				bcount = bcount + 1
			end

			properties_4_check(node)

			tmp = node.left
			while tmp do

				node = tmp

				if node.color == RB_BLACK then
					bcount = bcount + 1
				end

				properties_4_check(node)

				tmp = tmp.left
			end
		else
			-- 回退并找next结点
			if node.color == RB_BLACK then
				bcount = bcount - 1
			end
			tmp = node.parent
			while tmp and (node == tmp.right) do
				if tmp.color == RB_BLACK then
					bcount = bcount - 1
				end
				node = tmp
				tmp = node.parent
			end
			node = tmp
		end
	end

	assert(node_count == self.cur_num, "check valid count, self.cur_num[".. self.cur_num.. "] ~= count[".. node_count.."]")

end

function lrbtree:dump()
	local queues = {}
	local node = self.root
	if not node then
		return 
	end
	
	local nil_node = {}

	local q = { node }
	while #q > 0 do
		local tmp = {}

		local bOk = false
		local vals = {}
		while #q > 0 do
			local n = tremove(q, 1)
			if n == nil_node then
				tinsert(vals, {0,RB_BLACK})

				tinsert(tmp, nil_node)
				tinsert(tmp, nil_node)
			else
				tinsert(vals, {n.val, n.color})
				local ln = n.left and n.left or nil_node
				local rn = n.right and n.right or nil_node
				tinsert(tmp, ln)
				tinsert(tmp, rn)
				if (ln ~= nil_node) or (rn ~= nil_node) then
					bOk = true
				end
			end
		end

		tinsert(queues, vals)
		q = tmp
		if not bOk then
			break
		end
	end
	
	local max_lv_count = #queues[#queues]
	max_lv_count = max_lv_count / 2
	if max_lv_count < 1 then
		max_lv_count = 1
	end
	local str = ""
	for lv, queue in ipairs(queues) do
		-- local line = "lv["..lv.. "]\t" .. string.rep("\t", math.floor(max_lv_count / lv)) 
		local line = "lv["..lv.. "]\t"
		line = string.gsub(line, "\t", "----")
		str = str .. line
		for _, val in ipairs(queue) do
			str = str .. "{".. tostring(val[1]) .. ",".. (val[2] == RB_BLACK and 'B' or 'R') .."}\t"
		end
		str = str .. "\n"
	end
	return str
end

return lrbtree



