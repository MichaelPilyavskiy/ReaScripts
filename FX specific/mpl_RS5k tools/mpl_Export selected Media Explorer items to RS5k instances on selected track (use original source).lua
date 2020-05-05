-- @description Export selected Media Explorer items to RS5k instances on selected track (use original source)
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    + init


  local vrs = 'v1.0'
  local scr_title = 'Export selected items to RS5k instances on selected track (use original source)'
  --NOT gfx NOT reaper
  -----------------------------------------------------------
  function MediaExplorer_GetSelectedFiles(t)--https://forum.cockos.com/showthread.php?t=218977
    local title = reaper.JS_Localize("Media Explorer", "common")
    local hWnd = reaper.JS_Window_Find(title, true)
    if hWnd == nil then return end local container = reaper.JS_Window_FindChildByID(hWnd, 0)
    local file_LV = reaper.JS_Window_FindChildByID(container, 1000)
    local sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(file_LV)
    if sel_count == 0 then return end
    
    local index = 0
    -- get path from combobox
    local combo = reaper.JS_Window_FindChildByID(hWnd, 1002)
    local edit = reaper.JS_Window_FindChildByID(combo, 1001)
    local path = reaper.JS_Window_GetTitle(edit, "", 1024)
    --index = index + 1
    --t[index] = path
    -- get selected items in 1st column of ListView.
    for ndx in string.gmatch(sel_indexes, '[^,]+') do
      local name = reaper.JS_ListView_GetItemText(file_LV, tonumber(ndx), 0)
      --index = index + 1
      if reaper.file_exists(path..'\\'..name) then t[#t+1] = path..'\\'..name end
    end
  end

 --------------------------------------------------------------------
  function main()
    
    Undo_BeginBlock2( 0 )
    -- track check
      local track = GetSelectedTrack(0,0)
      if not track then return end        
    --[[ item check
      local item = GetSelectedMediaItem(0,0)
      if not item then return true end  ]]
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
      items_t = {}
      MediaExplorer_GetSelectedFiles(items_t)
      for i = 1, #items_t do
      --for i = 1, CountSelectedMediaItems(0) do
        --local item = reaper.GetSelectedMediaItem(0,i-1)
        local filename = items_t[i]
        local tk_src = PCM_Source_CreateFromFile( filename )
        local it_len =  GetMediaSourceLength( tk_src ) --GetMediaItemInfo_Value( item, 'D_LENGTH' )
        --local take = reaper.GetActiveTake(item)
        --if not take or reaper.TakeIsMIDI(take) then goto skip_to_next_item end
        --local tk_src =  GetMediaItemTake_Source( take )
        --local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
        --local src_len =GetMediaSourceLength( tk_src )
        local filepath = reaper.GetMediaSourceFileName( tk_src, '' )
        --msg(s_offs/src_len)
        ExportItemToRS5K(base_pitch + i-1,filepath, nil, nil, track)
        ::skip_to_next_item::
      end
      
      reaper.Main_OnCommand(40006,0)--Item: Remove items      
    -- add MIDI
      if proceed_MIDI then ExportSelItemsToRs5k_AddMIDI(track, MIDI,base_pitch) end        
      reaper.Undo_EndBlock2( 0, 'Export selected items to RS5k instances', -1 )     
    
  end 
  ----------------------------------------------------------------------- 
  function ExportItemToRS5K(note,filepath, start_offs, end_offs, track)
    local rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
    TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', filepath)
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
  end
   
    ---------------------------------------------------------------------
      function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
      if not APIExists('JS_Localize') then 
       MB('JS Extension not installed', '', 0)
       else
        reaper.Undo_BeginBlock()
        main()
        reaper.Undo_EndBlock(scr_title, -1)
      end
    end