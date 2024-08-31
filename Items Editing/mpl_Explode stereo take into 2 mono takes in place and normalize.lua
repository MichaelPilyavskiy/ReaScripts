-- @description Explode stereo take into 2 mono takes in place and normalize
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  --------------------------------------------------------------------  

  
  --NOT gfx NOT reaper
  function main(item)
    if  CountTakes( item ) ~= 1 then return end
    local take = GetActiveTake(item)
    if not take then return end
    local pcm_src = GetMediaItemTake_Source( take )
    if not pcm_src then return end
    
    local new_take = AddTakeToMediaItem( item )
    SetMediaItemTake_Source( new_take, pcm_src )
    reaper.SetMediaItemInfo_Value( item,'B_ALLTAKESPLAY', 1 )
    SetMediaItemTakeInfo_Value( take, 'D_PAN', -1 )
    SetMediaItemTakeInfo_Value( take, 'I_CHANMODE', 3 ) 
    SetMediaItemTakeInfo_Value( new_take, 'D_PAN', 1 )
    SetMediaItemTakeInfo_Value( new_take, 'I_CHANMODE', 4 )
     
    Action(40289) -- Item: Unselect all items
    SetMediaItemInfo_Value( item, 'B_UISEL', 1 )
    SetActiveTake( take )
    Action(40108) -- normalize
    SetActiveTake( new_take )
    Action(40108) -- normalize
    
    UpdateItemInProject( item ) 
  end
  ------------------------------------------------------------------------------------------------------
  function Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end  
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true) then 
      Undo_BeginBlock() 
      local t = {} for selitem = 1,  reaper.CountSelectedMediaItems( 0 ) do t[#t+1] = reaper.GetSelectedMediaItem( 0, selitem-1 ) end
      for i= 1, #t do main(t[i]) end
      Undo_EndBlock('Explode stereo take into 2 mono takes in place and normalize', 4) 
  end
  