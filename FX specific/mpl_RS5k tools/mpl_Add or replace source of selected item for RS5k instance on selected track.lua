-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Add or replace source of selected item for RS5k instance on selected track
-- @noindex
-- @changelog
--    #header


  function GetRS5Kpos(track)
    local name_ref = 'reasamplomatic'
    local name_ref2= 'rs5k'
    for i = 1, reaper.TrackFX_GetCount( track ) do
     local retval, nameOut = reaper.TrackFX_GetFXName( track, i-1, '' )
      if nameOut:lower():find(name_ref) or nameOut:lower():find(name_ref2)  then return i-1 end
    end
  end
  -------------------------------------------------------------------------------   
  function FormMIDItake_data(item)
    local MIDI = {}
    -- check for same track/get items info
      if not item then return end
      MIDI.it_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
      MIDI.it_end_pos = MIDI.it_pos + 0.1
      local proceed_MIDI = true
      local it_tr0 = reaper.GetMediaItemTrack( item )
      for i = 1, reaper.CountSelectedMediaItems(0) do
        local item = reaper.GetSelectedMediaItem(0,i-1)
        local it_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
        local it_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
        MIDI[#MIDI+1] = {pos=it_pos, end_pos = it_pos+it_len}
        MIDI.it_end_pos = it_pos + it_len
        local it_tr = reaper.GetMediaItemTrack( item )
        if it_tr ~= it_tr0 then proceed_MIDI = false break end
      end
      
    return proceed_MIDI, MIDI
  end
  ------------------------------------------------------------------------------- 
    function F_extract_filename(orig_name)
    local reduced_name_slash = orig_name:reverse():find('[%/%\\]')
    local reduced_name = orig_name:sub(-reduced_name_slash+1)
    reduced_name = reduced_name:sub(0,-1-reduced_name:reverse():find('%.'))
    return reduced_name
  end
  
  
  -------------------------------------------------------------------------------    
  function AddMIDI(track, MIDI, base_pitch)    
    if not MIDI then return end
      new_it = reaper.CreateNewMIDIItemInProj( track, MIDI.it_pos, MIDI.it_end_pos )
      local new_tk = reaper.GetActiveTake( new_it )
      for i = 1, #MIDI do
        local startppqpos =  reaper.MIDI_GetPPQPosFromProjTime( new_tk, MIDI[i].pos )
        local endppqpos =  reaper.MIDI_GetPPQPosFromProjTime( new_tk, MIDI[i].end_pos )
        local ret = reaper.MIDI_InsertNote( new_tk, 
            false, --selected, 
            false, --muted, 
            startppqpos, 
            endppqpos, 
            0, 
            base_pitch+i-1, 
            100, 
            true)--noSortInOptional )
          --if ret then reaper.ShowConsoleMsg('done') end
      end
      reaper.MIDI_Sort( new_tk )
      reaper.GetSetMediaItemTakeInfo_String( new_tk, 'P_NAME', 'sliced loop', 1 )
      reaper.UpdateArrange()    
  end
  -------------------------------------------------------------------------------    
  function main()
    local item = reaper.GetSelectedMediaItem(0,0)
    if not item then return end
    local track = reaper.GetSelectedTrack(0,0)
    if not track then return end
    local take = reaper.GetActiveTake(item) 
    if not take or reaper.TakeIsMIDI(take) then return end
    local tk_src =  reaper.GetMediaItemTake_Source( take )
    local filename = reaper.GetMediaSourceFileName( tk_src, '' )        
    local rs5k_pos = GetRS5Kpos(track)
    if not rs5k_pos then 
      rs5k_pos = reaper.TrackFX_AddByName( track, 'ReaSamplOmatic5000 (Cockos)', false, -1 )       
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 11, 0 ) -- obey note offs
    end
    reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE0", filename)
    reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE","")    
    _, midi_t = FormMIDItake_data(item)
    reaper.Main_OnCommand(40006,0)--Item: Remove items
    AddMIDI(track, midi_t, 60)
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Add or replace source of selected item for RS5k instance on selected track', 1)