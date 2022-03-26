-- @description Create ReaGate sidechain routing from selected track to track under mouse cursor
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  
  threshold = 0.25
  defsendvol = 1
        
  --------------------------------------------------------------------------------------
  function main(threshold, ratio, defsendvol)
  
    -- get source
      src_tr = {}
      for tr_i = 1, CountSelectedTracks(0) do
        track = GetSelectedTrack(0,tr_i-1)
        src_tr[#src_tr+1] = GetTrackGUID( track )
      end 
      if #src_tr == 0 then return end
  
    -- get dest
      dest_tr = VF_GetTrackUnderMouseCursor()
      if not dest_tr then return end
      dest_trGUID = GetTrackGUID( dest_tr )

    -- increase chan
      ch_cnt = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN' )
      SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', math.max(4, ch_cnt) )
      
    -- insert reacomp
      local reacompid = TrackFX_AddByName( dest_tr, 'ReaGate (Cockos)', false, 1 )
      TrackFX_SetOpen(dest_tr, reacompid, true)
      TrackFX_SetParam(dest_tr, reacompid, 0, threshold)
      --TrackFX_SetParam(dest_tr, reacompid, 1, ratio)    
      TrackFX_SetParam(dest_tr, reacompid, 7, (1/1084)*2)  
    
    -- add sends                  
      for i = 1, #src_tr do
        if src_tr[i] ~= dest_trGUID then
          local src_tr =  BR_GetMediaTrackByGUID( 0, src_tr[i] )
          
          local new_id
          -- check for existing id
          for sid = 1, GetTrackNumSends( src_tr, 0 ) do
            local dest_tr_pointer = BR_GetMediaTrackSendInfo_Track( src_tr, 0,  sid-1, 1 )
            local dest_tr_pointerGUID = GetTrackGUID(dest_tr_pointer)
            if dest_tr_pointerGUID == dest_trGUID then new_id = sid-1 break end
          end
          
          if not new_id then new_id = CreateTrackSend( src_tr, dest_tr ) end
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 2) -- 3/4
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_MIDIFLAGS', 31) -- MIDI None
        end
      end
    
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.982,true)    
  if ret and ret2 then 
    Undo_BeginBlock()
    main(threshold, ratio, defsendvol)
    Undo_EndBlock('Create ReaGate sidechain routing', -1)
  end   
  
  
  