-- @description Export selected items to single RS5k instance on selected track (use original source)
-- @version 1.03
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix empty files when using section

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


  local vrs = 'v1.0'
  local scr_title = 'Export selected items to RS5k instances on selected track (use original source, roundrobin into single note)'
  --NOT gfx NOT reaper
  -------------------------------------------------------------------------------   
  function ExportSelItemsToRs5k_FormMIDItake_data()
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
 --------------------------------------------------------------------
  function main()
    
    Undo_BeginBlock2( 0 )
    -- track check
      local track = GetSelectedTrack(0,0)
      if not track then return end        
    -- item check
      local item = GetSelectedMediaItem(0,0)
      if not item then return true end  
    -- get base pitch
      local ret, base_pitch = reaper.GetUserInputs( scr_title, 1, 'Set base pitch', 60 )
      if not ret 
        or not tonumber(base_pitch) 
        or tonumber(base_pitch) < 0 
        or tonumber(base_pitch) > 127 then
        return 
      end
      base_pitch = math.floor(tonumber(base_pitch))      
    -- get info for new midi take
      local proceed_MIDI, MIDI = ExportSelItemsToRs5k_FormMIDItake_data()        
    -- export to RS5k 
      local it_cnt = CountSelectedMediaItems(0)
      local rs5k_fxid
      for i = 1, it_cnt do
        local item = reaper.GetSelectedMediaItem(0,i-1)
        local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
        local take = reaper.GetActiveTake(item)
        if not take or reaper.TakeIsMIDI(take) then goto skip_to_next_item end
        local tk_src =  GetMediaItemTake_Source( take )
        local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
        local retval, len, rev
        local offs = 0
        if GetMediaSourceParent( tk_src ) ~= nil then  
          retval, offs, len, rev = reaper.PCM_Source_GetSectionInfo( tk_src )
          tk_src = GetMediaSourceParent( tk_src ) 
        end 
        local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' ) + offs
        local src_len =GetMediaSourceLength( tk_src )
        local filepath = reaper.GetMediaSourceFileName( tk_src, '' )
        --msg(s_offs/src_len)
        rs5k_fxid = ExportItemToRS5K(base_pitch,filepath, s_offs/src_len, (s_offs+it_len)/src_len, track, i, rs5k_fxid)
        ::skip_to_next_item::
      end
      
      reaper.Main_OnCommand(40006,0)--Item: Remove items      
    -- add MIDI
      if proceed_MIDI then ExportSelItemsToRs5k_AddMIDI(track, MIDI,base_pitch, true) end        
      reaper.Undo_EndBlock2( 0, 'Export selected items to RS5k instances', 0 )     
    
  end 
  ----------------------------------------------------------------------- 
  function ExportItemToRS5K(note,filepath, start_offs, end_offs, track, fileid, rs5k_pos0)
    local inst = -1
    local rs5k_pos
    if not rs5k_pos0 then 
      rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
     else
      rs5k_pos = rs5k_pos0
    end
    local f = 'FILE0'
    if fileid then f = 'FILE'..(fileid-1) end
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, f, filepath)
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')      
    TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
    TrackFX_SetParamNormalized( track, rs5k_pos, 3, note/127 ) -- note range start
    TrackFX_SetParamNormalized( track, rs5k_pos, 4, note/127 ) -- note range end
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
  if VF_CheckReaperVrs(5.975,true)then  main() end
