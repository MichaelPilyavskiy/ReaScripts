-- @version 1.0
-- @author mpl
-- @changelog
--    + init

--[[
   * ReaScript Name: Align selected track items vertically
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
  ]]
  
  function msg(s) reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(s) end
  
-------------------------------------------
  
  function main()
    local f_sel_item = reaper.GetSelectedMediaItem( 0, 0 )
    if not f_sel_item then return end
    local f_sel_item_tr = reaper.GetMediaItem_Track( f_sel_item )
    if not f_sel_item_tr then return end
    
    -- create items table
      items = {}
      for i = 1,  reaper.CountSelectedMediaItems( 0 ) do
        local item = reaper.GetSelectedMediaItem( 0, i-1 )
        local item_tr = reaper.GetMediaItem_Track( item ) 
        if item_tr == f_sel_item_tr then
          local take = reaper.GetActiveTake(item)
          items[#items +1 ] = 
            {guid = reaper.BR_GetMediaItemGUID( item ),
             pos =  reaper.GetMediaItemInfo_Value( item, 'D_POSITION'  ), 
             len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH'),
             name =  reaper.GetTakeName( take ),
             ypos_FIP = GetYPOS(item) }
        end
      end
    
    -- get maximum of crossings per track
      max_cross = 1
      for i = 1, #items do    
        cross = 0   
        pos1 = items[i].pos 
        len1 = items[i].len 
        for j = 1, #items do
          if i ~= j then
            pos2 = items[j].pos 
            len2 = items[j].len
            if IsAcontainB(pos1, len1, pos2, len2) then cross = cross + 1 end
          end
        end
        max_cross = math.max(max_cross, cross)
      end
    
      max_cross = max_cross +1   
      
    -- quant item vert positions  
      for i = 1, #items do
        items[i].ypos_FIP = Quantize ( items[i].ypos_FIP, 1 / max_cross)
        items[i].ypos_FIP2 = 1 / max_cross
      end
      
    -- apply chunks
      for i = 1, #items do
        item =  reaper.BR_GetMediaItemByGUID( 0, items[i].guid )
        if item ~= nil then
          local _, itemchunk =  reaper.GetItemStateChunk( item, '' )
          itemchunk = itemchunk:gsub('YPOS [%d%.]+ [%d%.]+', 
                         'YPOS '..items[i].ypos_FIP..' '..items[i].ypos_FIP2 )
          --msg(itemchunk)
          reaper.SetItemStateChunk( item, itemchunk )
        end
      end
      
    reaper.UpdateArrange()
  end  
  -------------------------------------------  
  function GetYPOS (item)
    if not item then return 0 end
    local _, itemchunk =  reaper.GetItemStateChunk( item, '' )
    local ypos = itemchunk:match('YPOS .*')
          if not ypos then  return  0 end
          ypos = ypos:sub(0,ypos:find('\n'))
          if not ypos then  return  0 end
          ypos = tonumber(ypos:match('[%d%.]+'))
          if not ypos then  return  0 else return ypos end
  end
-------------------------------------------  
  function IsAcontainB(pos1, len1, pos2, len2)
    local end1 = pos1+len1
    local end2 = pos2+len2
    if   (pos2 < pos1 and pos2 < end1 and end2 > pos1)
      or (pos2 > pos1 and pos2 < end1 and end2 > pos1)
     then   
      return true
    end
  end
-------------------------------------------  
  function Quantize(input, step)
    local out_m = input / step
    local int , fr = math.modf (out_m)
    if fr >= 0.5 then out_m = int + 1 else out_m = int end
    return out_m * step
  end
-------------------------------------------
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Align selected track items vertically', 0)
