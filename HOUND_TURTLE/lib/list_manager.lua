local mod = math.fmod
local max = math.max

list_manager = {}

function list_manager.loopScrollIndex(indx,limit)
	return mod(indx-1+limit,limit)+1
end

function list_manager.IndexedListScroller()
	return{
	target_index=1,
	index_scroll_direction=1,
	list_size = 1,
	updateListSize=function(self,size)
		self.list_size = size
	end,
	getCurrentIndex=function(self)
		return self.target_index
	end,
	getNextIndex=function(self)
		return list_manager.loopScrollIndex(self.target_index+1,self.list_size)
	end,
	getPrevIndex=function(self)
		return list_manager.loopScrollIndex(self.target_index-1,self.list_size)
	end,
	scrollUp=function(self)
		if(self.list_size==0)then return end
		self.index_scroll_direction = 1
		self.target_index = list_manager.loopScrollIndex(self.target_index+self.index_scroll_direction,self.list_size)
	end,
	scrollDown=function(self)
		if(self.list_size==0)then return end
		self.index_scroll_direction = -1
		self.target_index = list_manager.loopScrollIndex(self.target_index+self.index_scroll_direction,self.list_size)
	end,
	skip=function(self)
		if(self.list_size==0)then return end
		self.target_index = list_manager.loopScrollIndex(self.target_index+self.index_scroll_direction,self.list_size)
	end,
	getCurrentItem=function(self,list)
		return list[self.target_index]
	end
	}
end

return list_manager