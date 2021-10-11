-- @description Create ReaComp sidechain routing from selected track to track under mouse cursor
-- @version 1.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # improve logic around existing send
--    # remove SWS dependency
  
  
  local threshold = 0.25
  local ratio = 0.06
  local defsendvol = 1
        
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

    MPL_CreateReaCompSidechainRouting_incresachan(dest_tr) 
    MPL_CreateReaCompSidechainRouting_addcomp(dest_tr)
    MPL_CreateReaCompSidechainRouting_addsend(src_tr, dest_tr)
    
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaCompSidechainRouting_incresachan(dest_tr)
    local ch_cnt = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN' )
    SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', math.max(4, ch_cnt) )
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaCompSidechainRouting_addcomp(dest_tr)
      local reacompid = TrackFX_AddByName( dest_tr, 'ReaComp (Cockos)', false, 1 )
      TrackFX_SetOpen(dest_tr, reacompid, true)
      TrackFX_SetParam(dest_tr, reacompid, 0, threshold)
      TrackFX_SetParam(dest_tr, reacompid, 1, ratio)    
      TrackFX_SetParam(dest_tr, reacompid, 8, (1/1084)*2)  
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaCompSidechainRouting_addsend(src_tr, dest_tr)
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
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', 3)
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 2) -- 3/4
        end
      end
  end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end --------------------------------------------------------------------  
  ---------------------------------------------------------------------
  local ret = VF_CheckFunctions(2.58) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    Undo_BeginBlock()
    main(threshold, ratio, defsendvol)
    Undo_EndBlock('Create ReaComp sidechain routing', -1)  
  end end  
  