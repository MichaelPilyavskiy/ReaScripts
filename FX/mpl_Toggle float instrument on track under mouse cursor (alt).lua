-- @description Toggle float instrument on track under mouse cursor (alt)
-- @version 1.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # cleanup
--    # SWS independent
--    + Close FX if already opened
--    + Open multiple FX

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  ---------------------------------------------------------------------
  function ApplyFunctionToTrackInTree(track, func, setparam) -- function return true stop search
    if not track then return end
    
    -- search tree
      local parent_track
      local track2 = track
      func(track, setparam )
      repeat
        parent_track = reaper.GetParentTrack(track2)
        if parent_track ~= nil and parent_track ~= track2 then 
          func(parent_track, setparam )
          track2 = parent_track
        end
      until parent_track == nil    
      
    -- search sends
      local cnt_sends = GetTrackNumSends( track, 0)
      for sendidx = 1,  cnt_sends do
        local dest_tr = reaper.GetTrackSendInfo_Value( track, 0, sendidx-1, 'P_DESTTRACK' )
        func(dest_tr,setparam )
      end
  end
  -------------------------------------------------------------------------------     
  function VF_IsInstrument(track,fx)
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+')) 
    local exceptions_list =
      {
        "Transpose", 
        "m trans", 
        "m pc", 
        "m chan" 
      }
    local retval, fxname = reaper.TrackFX_GetNamedConfigParm( track, fx, 'fx_name' )
    local retval, is_instrument = reaper.TrackFX_GetNamedConfigParm( track, fx, 'is_instrument' )
    if (vrs_num<7.40 and fxname:match('.-i%:.*')) or (vrs_num >=7.40 and is_instrument == '1') then 
      -- check exceptions list
      local ignore
      for i = 1, #exceptions_list do 
        if fxname:lower():match(exceptions_list[i]:lower()) then ignore = true end 
      end  
      if not ignore then return true end
    end
  end
  -------------------------------------------------------------------------------     
  function FloatInstrument3(track, enable)
    if not track then return end
    local instrument_IDs = {}
    for fx = 1,  TrackFX_GetCount( track ) do
      if VF_IsInstrument(track, fx-1) == true then instrument_IDs[#instrument_IDs+1] = fx-1 end
    end
    
    for i = 1, #instrument_IDs do
      local vsti_id = instrument_IDs[i]
      if enable==true then TrackFX_Show(track, vsti_id, 3) else 
        --TrackFX_SetOpen( track, vsti_id, false )
        TrackFX_Show(track, vsti_id, 2) 
      end
    end
    
  end
  ------------------------------------------------------------------------------------------------------  
  function VF_GetMediaTrackByGUID(GUID)
    local tr
    for i= 1, CountTracks(-1) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
    local mast = reaper.GetMasterTrack( -1 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
  end 
  ---------------------------------------------------
  function msg(s) 
    if not s then return end 
    if type(s) == 'boolean' then
      if s then s = 'true' else  s = 'false' end
    end
    ShowConsoleMsg(s..'\n') 
  end 
  ---------------------------------------------------
  function main()
    -- check for REAPER version
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if vrs_num < 6.37 then MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) return end
     
    
    -- GetTrackUnderMouseCursor
    local screen_x, screen_y = GetMousePosition()
    local track, info = GetTrackFromPoint( screen_x, screen_y ) 
    local retval, GUID
    if track then 
      -- check is track changed
      retval, GUID = GetSetMediaTrackInfo_String( track, 'GUID', '', 0 )
    end
    
    local retvalExt, LASTTRGUID = GetProjExtState( -1, 'MPL_TOGGLEFLOATINSTR', 'LASTTRGUID' )
    local track_changed =  (retvalExt and GUID and LASTTRGUID and LASTTRGUID ~= GUID) or track == nil
    local LASTTR = VF_GetMediaTrackByGUID(LASTTRGUID)
      
    if track_changed == true then 
      -- close all FX that are sit at previous track 
      ApplyFunctionToTrackInTree(LASTTR, FloatInstrument3, false)
      -- float FX instrument at currently pointed track
      ApplyFunctionToTrackInTree(track, FloatInstrument3, true)
     else
      
      
      -- count opened/closed
      local cnt_opened = 0
      local  cnt_closed = 0
      for fx = 1,  TrackFX_GetCount( track ) do
        if VF_IsInstrument(track, fx-1) == true then 
          if TrackFX_GetOpen( track, fx-1 ) then cnt_opened = cnt_opened + 1 else cnt_closed = cnt_closed + 1 end
        end
      end
      -- close FX at currently pointed track if at least one of them is opened
      if cnt_opened > 0 then ApplyFunctionToTrackInTree(track, FloatInstrument3, false) end
      -- open FX at currently pointed track if at least one of them is closed
      if cnt_closed > 0 then ApplyFunctionToTrackInTree(track, FloatInstrument3, true) end
    end
      
    -- store last floated track
    if GUID then 
      SetProjExtState( -1, 'MPL_TOGGLEFLOATINSTR', 'LASTTRGUID', GUID ) 
     else 
      -- clean state
      SetProjExtState( -1, 'MPL_TOGGLEFLOATINSTR', 'LASTTRGUID', '' )
    end
    
    
    
  end
  
  Undo_BeginBlock() 
  main()
  Undo_EndBlock("Toggle float instrument on track under mouse cursor", 0xFFFFFFFF)