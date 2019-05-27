-- @description Store incoming SysEx to the 1st track 1st MIDI item, no prompt (background)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


  local last_ts
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
  --------------------------------------------------------------------
  function GetSysEx()
    local datastr_len = gmem_read(3) -- data string length
    if datastr_len >=3 then  
      out_msg = '' 
      local offs = 10
      for i = offs, offs+datastr_len-1 do
        out_msg = out_msg..string.char(math.floor(gmem_read(i)))
        --out_msg = out_msg .. ' '.. string.format("%.2X", math.floor(gmem_read(i)))
      end
      return true, out_msg
      --SetProjExtState( 0, 'MPL_SysExData', 'SLOT1', out_msg:sub(2) )
    end
  end
  ---------------------------------------------------------------------
  function main()
    local check_data = gmem_read(1) -- has any data
    local msg_TS = gmem_read(2) -- timestamp
    if check_data == 1 then 
      local cur_TS =os.time()
      if cur_TS - msg_TS < 0.1 then 
        --local ret = MB('Save SysEx to project?', 'mpl_Store incoming SysEx', 3) ret == 6
        if not last_ts or cur_TS - last_ts > 1 then
          ret, SysEx_msg = GetSysEx()
          if ret then PushDataToItem(SysEx_msg) end 
        end
        last_ts = cur_TS
      end 
    end

    defer(main)
  end
  ---------------------------------------------------------------------
  function SetButton(val0)
    local is_new_value, filename, sec, cmd, mode, resolution, val = get_action_context()
    --state = reaper.GetToggleCommandStateEx( sec, cmd ) 
    if not val0 then val0 = 0 end
    SetToggleCommandState( sec, cmd, val0 )
    RefreshToolbar2( sec, cmd )
  end 
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end 
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    gmem_attach('MPL_SysExTracker')
    SetButton(1)
    main() 
    atexit( SetButton )  
  end