-- @version 1.18
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Export selected items to RS5k instances on selected track
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

  local script_title = 'Export selected items to RS5k instances on selected track'
  ---------------------------------------------------------------------
  function VF_GetMediaItemByGUID(optional_proj, itemGUID)
    local optional_proj0 = optional_proj or 0
    local itemCount = CountMediaItems(optional_proj);
    for i = 1, itemCount do
      local item = GetMediaItem(0, i-1);
      local retval, stringNeedBig = GetSetMediaItemInfo_String(item, "GUID", '', false)
      if stringNeedBig  == itemGUID then return item end
    end
  end  
  -------------------------------------------------------------------------------   
  function GlueSelectedItemsIndependently()
    -- store GUIDs
      local GUIDs = {}
      for it_id = 1, reaper.CountSelectedMediaItems(0) do
        local item =  reaper.GetSelectedMediaItem( 0, it_id-1 )
        local it_GUID = VF_GetItemGUID( item )
        GUIDs[#GUIDs+1] = it_GUID
      end
      
    -- glue items
      local new_GUIDs = {}
      for i = 1, #GUIDs do
        local item = VF_GetMediaItemByGUID( 0, GUIDs[i] )
        if item then 
          reaper.Main_OnCommand(40289, 0) -- unselect all items
          reaper.SetMediaItemSelected(item, true)
          reaper.Main_OnCommand(40362, 0) -- glue without time selection
          local cur_item =  reaper.GetSelectedMediaItem( 0, 0)
          local retval, GUID = reaper.GetSetMediaItemInfo_String( cur_item, 'GUID', '', 0 )
          if cur_item then new_GUIDs[#new_GUIDs+1] = GUID end
        end
      end
    
    reaper.Main_OnCommand(40289, 0) -- unselect all items
    -- add new items to selection
      for i = 1, #new_GUIDs do
        local item = VF_GetMediaItemByGUID( 0, new_GUIDs[i] )
        if item then reaper.SetMediaItemSelected(item, true) end
      end
    reaper.UpdateArrange() 
  end
  ------------------------------------------------------------------------------- 
  function ExportSelItemsToRs5k(track, base_pitch)      
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem(0,i-1)
      local take = reaper.GetActiveTake(item)
      if not take or reaper.TakeIsMIDI(take) then goto skip_to_next_item end
      
      local tk_src =  reaper.GetMediaItemTake_Source( take )
      local filename = reaper.GetMediaSourceFileName( tk_src, '' )
      
      local rs5k_pos = reaper.TrackFX_AddByName( track, 'ReaSamplOmatic5000 (Cockos)', false, -1 )
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 3, base_pitch/127 ) -- note range start
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 4, base_pitch/127 ) -- note range end
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
      --reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 11, 1 ) -- obey note offs
      local new_name = F_extract_filename(filename)
      reaper.TrackFX_SetNamedConfigParm( track, rs5k_pos, 'renamed_name', 'RS5K '..new_name )
      reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE0", filename)
      reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE","")
      base_pitch = base_pitch + 1                
      ::skip_to_next_item::
    end
  end
  -------------------------------------------------------------------------------   
  function FormMIDItake_data()
    local MIDI = {}
    -- check for same track/get items info
      local item = reaper.GetSelectedMediaItem(0,0)
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
  function AddMIDI(track, MIDI,base_pitch)    
    if not MIDI then return end
      local new_it = reaper.CreateNewMIDIItemInProj( track, MIDI.it_pos, MIDI.it_end_pos )
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
  function main(track)   
    -- track check
      local track = reaper.GetSelectedTrack(0,0)
      if not track then return end
      
    -- item check
      local item = reaper.GetSelectedMediaItem(0,0)
      if not item then return true end        
    
    -- get base pitch
      local ret, base_pitch = reaper.GetUserInputs( script_title, 1, 'Set base pitch', 60 )
      if not ret 
        or not tonumber(base_pitch) 
        or tonumber(base_pitch) < 0 
        or tonumber(base_pitch) > 127 then
        return 
      end
      base_pitch = math.floor(tonumber(base_pitch))
    
    -- glue items
      GlueSelectedItemsIndependently()
    
    -- get info for new midi take
      local proceed_MIDI, MIDI = FormMIDItake_data()
      
    -- export to RS5k
      ExportSelItemsToRs5k(track, base_pitch)
      reaper.Main_OnCommand(40006,0)--Item: Remove items
    
    -- add MIDI
      if proceed_MIDI then AddMIDI(track, MIDI,base_pitch) end 
        
      MIDI_prepare(track)
        
    end
    ------------------------------------------------------------------------------- 
    function MIDI_prepare(tr)
      local bits_set=tonumber('111111'..'00000',2)
      reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+bits_set ) -- set input to all MIDI
      reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
      reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track
      reaper.SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
    end
  
  --------------------------------------------------------------------  
  if  VF_CheckReaperVrs(5.975,true) then 
    reaper.Undo_BeginBlock() 
    main() 
    reaper.Undo_EndBlock(script_title, 1) 
  end