-- @description Export selected items to RS5k instances (for McSequencer)
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init, version for McSequencer


  local vrs = 'v1.0'
  local scr_title = 'Export selected items to RS5k instances (for McSequencer)'
  --NOT gfx NOT reaper
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
        TrackFX_AddByName(track, "Note Trigger", false, -1)
        TrackFX_AddByName(track, "Swing", false, -1)
        ExportItemToRS5K(filepath, s_offs/src_len, (s_offs+it_len)/src_len, track)
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
  end
   
    ---------------------------------------------------------------------
      function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
      reaper.Undo_BeginBlock()
      main()
      reaper.Undo_EndBlock(scr_title, 1)
    end