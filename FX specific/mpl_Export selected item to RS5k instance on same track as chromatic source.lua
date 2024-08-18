-- @version 1.07
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Export selected item to RS5k instance on same track as chromatic source
-- @changelog
--    # VF independent
--    # use modern API, remove chunking part

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

  local script_title = 'Export selected item to RS5k instance on same track as chromatic source'
  
  ------------------------------------------------------------------------------- 
  function ExportSelItemsToRs5k(track, item)      
    local take = reaper.GetActiveTake(item)
    if not take or reaper.TakeIsMIDI(take) then return end
      
    local tk_src =  reaper.GetMediaItemTake_Source( take )
    local filename = reaper.GetMediaSourceFileName( tk_src, '' )
      
    local rs5k_pos = reaper.TrackFX_AddByName( track, 'ReaSamplOmatic5000 (Cockos)', false, -1 )
    reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
    reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
    reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 11, 1 ) -- obey note offs
    local new_name = F_extract_filename(filename)
    reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, 'renamed_name', 'RS5K '..new_name )
    reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE0", filename)
    reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "MODE", '0')
    reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE","")
  end
  ------------------------------------------------------------------------------- 
    function F_extract_filename(orig_name)
    local reduced_name_slash = orig_name:reverse():find('[%/%\\]')
    local reduced_name = orig_name:sub(-reduced_name_slash+1)
    reduced_name = reduced_name:sub(0,-1-reduced_name:reverse():find('%.'))
    return reduced_name
  end

  -------------------------------------------------------------------------------  
  function main(track) 
    -- check for one items  
      if reaper.CountSelectedMediaItems(0) > 1 then return end
    -- item check
      local item = reaper.GetSelectedMediaItem(0,0)
      if not item then return end
      if reaper.TakeIsMIDI(reaper.GetActiveTake(item)) then return end
      if not item then return end        
      local track =  reaper.GetMediaItemTrack( item )
      
    -- glue item      
      reaper.Main_OnCommand(40289, 0) -- unselect all items
      reaper.SetMediaItemSelected(item, true)
      reaper.Main_OnCommand(40362, 0) -- glue without time selection]]
      local item = reaper.GetSelectedMediaItem(0,0)
      
    -- export to RS5k
      ExportSelItemsToRs5k(track, item)
      reaper.Main_OnCommand(40006,0)--Item: Remove items
      
    MIDI_prepare(track)
      
  end
  ------------------------------------------------------------------------------- 
  function MIDI_prepare(tr)
    local bits_set=tonumber('111111'..'00000',2)
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+bits_set ) -- set input to all MIDI
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI in
  end
  ---------------------------------------------------------------------
   if VF_CheckReaperVrs(6,true)    then 
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock(script_title, 1)
  end
