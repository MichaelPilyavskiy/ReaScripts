-- @description Create ReaVocode routing from selected track to track under mouse cursor
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
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
  
  
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end      
  --------------------------------------------------------------------------------------
  function main(threshold, ratio, defsendvol)
  
    -- get source
      local src_tr = {}
      for tr_i = 1, CountSelectedTracks(0) do
        track = GetSelectedTrack(0,tr_i-1)
        src_tr[#src_tr+1] = GetTrackGUID( track )
      end 
      if #src_tr == 0 then return end
  
    -- get dest
      local dest_tr = VF_GetTrackUnderMouseCursor()
      if not dest_tr then return end

    MPL_CreateReaVocodeSidechainRouting_incresachan(dest_tr) 
    MPL_CreateReaVocodeSidechainRouting_add(dest_tr)
    MPL_CreateReaVocodeSidechainRouting_addsend(src_tr, dest_tr)
    
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaVocodeSidechainRouting_incresachan(dest_tr)
    local ch_cnt = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN' )
    SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', math.max(4, ch_cnt) )
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaVocodeSidechainRouting_add(dest_tr)
      local ReaVocodeid = TrackFX_AddByName( dest_tr, 'ReaVocode', false, 1 )
      TrackFX_SetOpen(dest_tr, ReaVocodeid, true)
  end
  ------------------------------------------------------------------------------------------------------  
  function VF_GetMediaTrackByGUID(optional_proj, GUID)
    local optional_proj0 = optional_proj or 0
    for i= 1, CountTracks(optional_proj0) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
    local mast = reaper.GetMasterTrack( optional_proj0 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaVocodeSidechainRouting_addsend(src_tr, dest_tr)
    local dest_trGUID = GetTrackGUID( dest_tr )
    -- add sends                  
      for i = 1, #src_tr do
        if src_tr[i] ~= dest_trGUID then
          local src_tr = VF_GetMediaTrackByGUID(0, src_tr[i] )
          
          local new_id
          -- check for existing id
          for sid = 1, GetTrackNumSends( src_tr, 0 ) do
            local dest_tr_pointer = GetTrackSendInfo_Value( src_tr, 0, sid-1, 'P_DESTTRACK' )
            local dest_tr_pointerGUID = GetTrackGUID(dest_tr_pointer)
            if dest_tr_pointerGUID == dest_trGUID then 
              if GetTrackSendInfo_Value( src_tr, 0, sid-1 , 'I_DSTCHAN') ==2 then return end
            end
          end
          
          if not new_id then new_id = CreateTrackSend( src_tr, dest_tr ) end
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', 1)
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', 3)
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 2) -- 3/4
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_MIDIFLAGS', 31) -- MIDI None
          SetMediaTrackInfo_Value( src_tr, 'B_MAINSEND',0 )
        end
      end
  end
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true)  then 
    Undo_BeginBlock()
    main()
    Undo_EndBlock('Create ReaVocode routing', 0xFFFFFFFF)  
  end 
  