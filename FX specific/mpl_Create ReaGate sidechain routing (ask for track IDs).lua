-- @description Create ReaGate sidechain routing (ask for track IDs)
-- @version 1.02
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
  
  
  threshold = 0.25
  defsendvol = 1
        ------------------------------------------------------------------------------------------------------  
        function VF_GetMediaTrackByGUID(optional_proj, GUID)
          local optional_proj0 = optional_proj or 0
          for i= 1, CountTracks(optional_proj0) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
          local mast = reaper.GetMasterTrack( optional_proj0 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
        end  
  --------------------------------------------------------------------------------------
  function main(threshold, ratio, defsendvol)
  
    local ret, str = reaper.GetUserInputs('Set src / dest track IDs', 2, 'source,destination', '')
    local id_src, id_dest = str:match('([%d]+),([%d]+)')
    if not (id_dest and id_src) then return end 
    
    -- get source
      local src_tr = GetTrack(0,id_src-1)
      if not src_tr then return end
  
    -- get dest
      local dest_tr_ptr = GetTrack(0,id_dest-1)
      if not dest_tr_ptr then return end
      local dest_tr = {[1]=GetTrackGUID(dest_tr_ptr)}
      
    -- increase chan
      for i = 1, #dest_tr do
        local dest_tr =  VF_GetMediaTrackByGUID( 0, dest_tr[i] )
        local ch_cnt = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN' )
        SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', math.max(4, ch_cnt) )
        
        -- insert reacomp
        local reagateid = TrackFX_AddByName( dest_tr, 'ReaGate (Cockos)', false, 1 )
        TrackFX_SetOpen(dest_tr, reagateid, true)
        TrackFX_SetParam(dest_tr, reagateid, 0, threshold)
        TrackFX_SetParam(dest_tr, reagateid, 7, (1/1084)*2)  
      end
      
    
    
    -- add sends                  
      for i = 1, #dest_tr do
        if dest_tr[i] ~= src_trGUID then
          local dest_tr =  VF_GetMediaTrackByGUID( 0, dest_tr[i] )
          
          local ex
          
          -- check for existing id
          for sid = 1, GetTrackNumSends( dest_tr, -1 ) do
            local src_tr_pointer = GetTrackSendInfo_Value( dest_tr, -1, sid-1, 'P_SRCTRACK' )
            local src_tr_pointerGUID = GetTrackGUID(src_tr_pointer)
            if src_tr_pointerGUID == src_trGUID then ex = true break end
          end
          
          if not ex then 
            new_id = CreateTrackSend( src_tr, dest_tr )
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 2) -- 3/4
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_MIDIFLAGS', 31) -- MIDI None
          end
        end
      end
    
  end
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.982,true)     then 
    Undo_BeginBlock()
    main(threshold, ratio, defsendvol)
    Undo_EndBlock('Create ReaGate sidechain routing', -1)
  end   
  
  
  
  
  
  
  
