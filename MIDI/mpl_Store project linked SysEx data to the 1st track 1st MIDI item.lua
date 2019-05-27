-- @description Store project linked SysEx data to the 1st track 1st MIDI item
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  function PushDataToItem(SysEx_msg)
    -- navigate for track
      local tr = GetTrack(0,0)
      if not tr then 
        InsertTrackAtIndex( 0, false )
        TrackList_AdjustWindows( false )
        local tr = GetTrack(0,0)
        GetSetMediaTrackInfo_String( tr, 'P_NAME', 'SysEx Output', true )
      end
      
    -- navigate for item 
      local item = GetTrackMediaItem( tr, 0 )
      if not item then 
        item =  reaper.CreateNewMIDIItemInProj( tr, 0,  math.max(2, GetProjectLength( 0 )) )
        UpdateArrange()
      end
      
      local take = GetActiveTake(item)
      if not take or (take and not TakeIsMIDI(take)) then
        item =  reaper.CreateNewMIDIItemInProj( tr, 0,  math.max(2, GetProjectLength( 0 )) )
        local take = GetActiveTake(item)
        UpdateArrange()
      end
      
    -- write SysEx
      local it_pos = GetMediaItemInfo_Value( item, 'D_POSITION')
      local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH')
      SetMediaItemInfo_Value( item, 'B_LOOPSRC', 0 )
      local offset = 0
      local flags = 0
      MIDI_SetAllEvts( take, string.pack("i4Bs4", offset, flags, SysEx_msg) )
      MIDI_Sort( take )
      MIDI_SetItemExtents( item, TimeMap_timeToQN(it_pos), TimeMap_timeToQN( it_pos+it_len) )
  end
  ---------------------------------------------------------------------  
  function main()
    local ret, str = GetProjExtState( 0, 'MPL_SysExData', 'SLOT1', '' )
    if ret == 1 then 
      local hex_t = {}
      for hex in str:gmatch('[^%s]+') do if tonumber(hex,16 ) then  hex_t[#hex_t+1] = tonumber(hex,16 ) end end
      local SysEx_msg = string.char(table.unpack(hex_t)) 
      PushDataToItem(SysEx_msg)
      --msg(SysEx_msg)
     else
      MB('There is no stored project SysEx data', 'Error', 0)
    end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end 
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    main() 
  end