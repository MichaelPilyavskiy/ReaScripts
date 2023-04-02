-- @description Align selected track items vertically (free positioned mode)
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # remove SWS dependency

  
------------------------------------------- 
  function main()
    local f_sel_item = reaper.GetSelectedMediaItem( 0, 0 )
    if not f_sel_item then return end
    local f_sel_item_tr = reaper.GetMediaItem_Track( f_sel_item )
    if not f_sel_item_tr then return end
    
    local fipmode = GetMediaTrackInfo_Value( f_sel_item_tr, 'I_FREEMODE' )
    if fipmode == 0 then SetMediaTrackInfo_Value( f_sel_item_tr, 'I_FREEMODE',1 ) UpdateTimeline()  end
    -- create items table
      items = {}
      for i = 1,  reaper.CountSelectedMediaItems( 0 ) do
        local item = reaper.GetSelectedMediaItem( 0, i-1 )
        local item_tr = reaper.GetMediaItem_Track( item ) 
        if item_tr == f_sel_item_tr then
          local take = reaper.GetActiveTake(item)
          local retval, itGUID = reaper.GetSetMediaItemInfo_String( item, 'GUID', '', 0 )
          local ypos_FIP = GetMediaItemInfo_Value( item, 'F_FREEMODE_Y' ) or 0
          items[#items +1 ] = 
            {guid = itGUID,
             pos =  reaper.GetMediaItemInfo_Value( item, 'D_POSITION'  ), 
             len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH'),
             name =  reaper.GetTakeName( take ),
             ypos_FIP = ypos_FIP }
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
        item =  VF_GetMediaItemByGUID( 0, items[i].guid )
        if item and ValidatePtr(item,'MediaItem*') then 
          SetMediaItemInfo_Value( item, 'F_FREEMODE_Y',items[i].ypos_FIP )
          SetMediaItemInfo_Value( item, 'F_FREEMODE_H',items[i].ypos_FIP2 )
        end
      end
      
    reaper.UpdateArrange()
  end  
  -------------------------------------------  
  function IsAcontainB(pos1, len1, pos2, len2)
    local end1 = pos1+len1
    local end2 = pos2+len2
    return (pos2 >= pos1 and pos2 <= end1) or (end2 >= pos1 and end2 <= end1) or (pos2 <= pos1 and end2>end1)
    --[[if   (pos2 < pos1 and pos2 < end1 and end2 > pos1)
      or (pos2 > pos1 and pos2 < end1 and end2 > pos1)
     then   
      return true
    end]]
  end
  -------------------------------------------  
  function Quantize(input, step)
    local out_m = input / step
    local int , fr = math.modf (out_m)
    if fr >= 0.5 then out_m = int + 1 else out_m = int end
    return out_m * step
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Align selected track items vertically (free positioned mode)', 0xFFFFFFFF )
  end end