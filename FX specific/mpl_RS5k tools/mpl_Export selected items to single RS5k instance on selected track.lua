-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Export selected items to single RS5k instance on selected track
-- @noindex
-- @changelog
--    # use VF version check

  local script_title = 'Export selected items to single RS5k instance on selected track'
  -------------------------------------------------------------------------------   
  function GlueSelectedItemsIndependently()
    -- store GUIDs
      local GUIDs = {}
      for it_id = 1, reaper.CountSelectedMediaItems(0) do
        local item =  reaper.GetSelectedMediaItem( 0, it_id-1 )
        local it_GUID = reaper.BR_GetMediaItemGUID( item )
        GUIDs[#GUIDs+1] = it_GUID
      end
      
    -- glue items
      local new_GUIDs = {}
      for i = 1, #GUIDs do
        local item = reaper.BR_GetMediaItemByGUID( 0, GUIDs[i] )
        if item then 
          reaper.Main_OnCommand(40289, 0) -- unselect all items
          reaper.SetMediaItemSelected(item, true)
          reaper.Main_OnCommand(40362, 0) -- glue without time selection
          local cur_item =  reaper.GetSelectedMediaItem( 0, 0)
          if cur_item then new_GUIDs[#new_GUIDs+1] = reaper.BR_GetMediaItemGUID( cur_item ) end
        end
      end
    
    reaper.Main_OnCommand(40289, 0) -- unselect all items
    -- add new items to selection
      for i = 1, #new_GUIDs do
        local item = reaper.BR_GetMediaItemByGUID( 0, new_GUIDs[i] )
        if item then reaper.SetMediaItemSelected(item, true) end
      end
    reaper.UpdateArrange() 
  end
  ------------------------------------------------------------------------------- 
  function GetRS5kID(tr)
    local id = -1
    for i = 1,  reaper.TrackFX_GetCount( tr ) do
      if  ({reaper.TrackFX_GetFXName( tr, i-1, '' )})[2]:find('RS5K') then return i-1 end
    end
    return id
  end
  ------------------------------------------------------------------------------- 
  function ExportSelItemsToRs5k(track)   
    --local rs5k_pos   
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem(0,i-1)
      local take = reaper.GetActiveTake(item)
      if not take or reaper.TakeIsMIDI(take) then goto skip_to_next_item end
      
      local tk_src =  reaper.GetMediaItemTake_Source( take )
      local filename = reaper.GetMediaSourceFileName( tk_src, '' )
      
      rs5k_pos = reaper.TrackFX_AddByName( track, 'ReaSamplOmatic5000 (Cockos)', false,0 )
      if rs5k_pos == -1 then 
        rs5k_pos = GetRS5kID(track)
        if rs5k_pos == -1 then rs5k_pos = reaper.TrackFX_AddByName( track, 'ReaSamplOmatic5000 (Cockos)', false,-1 ) end
      end
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
      --reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
      --reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
      --reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 11, 1 ) -- obey note offs
      reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE"..(i-1), filename)
      ::skip_to_next_item::
    end
    if rs5k_pos then reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE","") end
  end
  
  -------------------------------------------------------------------------------  
  function main(track)   
    -- track check
      local track = reaper.GetSelectedTrack(0,0)
      if not track then return end
      
    -- item check
      local item = reaper.GetSelectedMediaItem(0,0)
      if not item then return true end        
    
 
    -- glue items
      GlueSelectedItemsIndependently()
      
    -- export to RS5k
      ExportSelItemsToRs5k(track)
      reaper.Main_OnCommand(40006,0)--Item: Remove items
    
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
  
    ---------------------------------------------------------------------
      function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.4,true)    
    if ret and ret2 then 
      reaper.Undo_BeginBlock()
      main()
      reaper.Undo_EndBlock(script_title, 1)
    end
