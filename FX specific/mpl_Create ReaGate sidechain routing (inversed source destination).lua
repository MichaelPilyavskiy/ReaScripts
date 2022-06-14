-- @description Create ReaGate sidechain routing from track under mouse cursor to selected track
-- @version 1.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # set MIDI to none, thanks to Karl Metum github.com/MichaelPilyavskiy/ReaScripts/pull/26
  
  
  threshold = 0.25
  defsendvol = 1
        
  --------------------------------------------------------------------------------------
  function main(threshold, ratio, defsendvol)
  
    -- get source
      local dest_tr = {}
      for tr_i = 1, CountSelectedTracks(0) do
        local track = GetSelectedTrack(0,tr_i-1)
        dest_tr[#dest_tr+1] = GetTrackGUID( track )
      end 
      if #dest_tr == 0 then return end
  
    -- get dest
      local src_tr = VF_GetTrackUnderMouseCursor()
      if not src_tr then return end
      local src_trGUID = GetTrackGUID( src_tr )

    -- increase chan
      for i = 1, #dest_tr do
        local dest_tr =  BR_GetMediaTrackByGUID( 0, dest_tr[i] )
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
          local dest_tr =  BR_GetMediaTrackByGUID( 0, dest_tr[i] )
          
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
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.982,true)    
  if ret and ret2 then 
    Undo_BeginBlock()
    main(threshold, ratio, defsendvol)
    Undo_EndBlock('Create ReaGate sidechain routing', -1)
  end   
  
  
  
  
  
  
  
