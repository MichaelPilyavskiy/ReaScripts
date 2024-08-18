-- @description Export selected items to RS5k instances (for McSequencer)
-- @version 1.03
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


  local scr_title = 'Export selected items to RS5k instances (for McSequencer)'
  --NOT gfx NOT reaper
  function VF_GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end  
 --------------------------------------------------------------------
  function main()
    
    Undo_BeginBlock2( 0 )
    -- item check
      local item = GetSelectedMediaItem(0,0)
      if not item then return true end  
      
      local partrack = GetMediaItemTrack( item )
      local idx = CSurf_TrackToID( partrack, false )
    -- export to RS5k
      for i = 1, CountSelectedMediaItems(0) do
        local item = reaper.GetSelectedMediaItem(0,i-1)
        local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
        local take = reaper.GetActiveTake(item)
        if not take or reaper.TakeIsMIDI(take) then goto skip_to_next_item end
        local tk_src =  GetMediaItemTake_Source( take )
        local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
        local src_len =GetMediaSourceLength( tk_src )
        local filepath = reaper.GetMediaSourceFileName( tk_src, '' )
        --msg(s_offs/src_len)
        InsertTrackAtIndex( idx, false )
        local track = GetTrack(0,idx)
        GetSetTrackGroupMembership(track, 'MEDIA_EDIT_LEAD', 1, 1)
        local shortsplname = VF_GetShortSmplName(filepath)
        if shortsplname:match('%.') then
          shortsplname1 = shortsplname:reverse():match('%.(.*)')
          if shortsplname1 then  shortsplname = shortsplname1:reverse() end
        end
        
        GetSetMediaTrackInfo_String( track, 'P_NAME', shortsplname..' SEQ', true )
        local fx_trig = TrackFX_AddByName(track, "Note Trigger", false, -1)
        TrackFX_Show(track, fx_trig, 2)
        local fx_swing = TrackFX_AddByName(track, "Swing", false, -1)
        TrackFX_Show(track, fx_swing, 2)
        local rs5k_pos = ExportItemToRS5K(filepath, s_offs/src_len, (s_offs+it_len)/src_len, track)
        TrackFX_Show(track, rs5k_pos, 2)
        ::skip_to_next_item::
      end
      
      --reaper.Main_OnCommand(40006,0)--Item: Remove items      
    -- add MIDI
      --if proceed_MIDI then ExportSelItemsToRs5k_AddMIDI(track, MIDI,base_pitch) end        
      reaper.Undo_EndBlock2( 0, 'Export selected items to RS5k instances', -1 )     
    
  end 
  ----------------------------------------------------------------------- 
  function ExportItemToRS5K(filepath, start_offs, end_offs, track)
    local rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', filepath)
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')      
    TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
    TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
    TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
    TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
    TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
    TrackFX_SetParamNormalized( track, rs5k_pos, 11, 1) -- obey note offs
    if start_offs and end_offs then
      TrackFX_SetParamNormalized( track, rs5k_pos, 13, start_offs ) -- attack
      TrackFX_SetParamNormalized( track, rs5k_pos, 14, end_offs )   
    end  
    return rs5k_pos
  end
   
    --------------------------------------------------------------------  
    if VF_CheckReaperVrs(5.95,true)   then 
      reaper.Undo_BeginBlock()
      main()
      reaper.Undo_EndBlock(scr_title, 1)
    end