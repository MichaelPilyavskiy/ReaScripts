-- @description Move cursor to next selected item edge, keep overlapping condition
-- @about
--    Calculate edges of selected items and move cursor to next edge
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  for key in pairs(reaper) do _G[key]=reaper[key]  end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end  
  ---------------------------------------------------  
  function Modify(t)
    local ret
    -- sort t
      local t0 = {}
      for i = 1, #t do t0[t[i].pos] = t[i] end
      local t={}  for key in spairs(t0) do t [#t+1] = t0[key] end   
    -- mod
      for i = #t, 2, -1 do
        if t[i].pos and t[i-1].pos and t[i].pos < t[i-1].end_s and t[i].end_s > t[i-1].end_s then 
          t[i-1].end_s = t[i].end_s
          t[i] = {}
          ret = true  
         elseif t[i].pos > t[i-1].pos and t[i].end_s < t[i-1].end_s then 
          t[i] = {}  
          ret = true        
        end
      end
    -- clear empty
    for i = #t, 1, -1 do if not t[i].pos then table.remove(t,i) end end      
    return t, ret
  end
  ---------------------------------------------------  
  function NavEdges()
    local cur_pos = GetCursorPositionEx( 0 )
    
    -- gen table
      local t = {}
      for i = 1, CountSelectedMediaItems(0) do
        it = GetSelectedMediaItem( 0, i-1 )
        t[#t+1] = {pos = GetMediaItemInfo_Value( it , 'D_POSITION'),
                   end_s = GetMediaItemInfo_Value( it , 'D_POSITION')+GetMediaItemInfo_Value( it , 'D_LENGTH' )}
      end
      if #t < 2 then return end
      
    -- modify t      
      repeat 
        local ret= false
        t, ret = Modify(t)
      until not ret
    
    -- combine val
      local edges = {}
      for i = 1, #t do
        edges[#edges+1] = t[i].pos
        edges[#edges+1] = t[i].end_s
      end
      table.sort(edges, function(a,b) return a<b end)
      
      
    -- seek next edge
      for i = 1, #edges do
        if edges[i] > cur_pos then SetEditCurPos( edges[i], true, false ) break         end        
      end
    
  end
  ---------------------------------------------------    
  NavEdges()