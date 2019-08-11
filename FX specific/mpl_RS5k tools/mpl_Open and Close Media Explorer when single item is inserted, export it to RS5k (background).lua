-- @version 1.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Open and Close Media Explorer when single item is inserted, export it to RS5k
-- @noindex
-- @changelog
--    # use VF version check


  local script_title = 'Open and Close Media Explorer when single item is inserted, export it to RS5k'
  ------------------------------------------------------------------------------- 
  function ExportSelItemsToRs5k(base_pitch, track)
    if not track then return true end
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
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
      reaper.TrackFX_SetParamNormalized( track, rs5k_pos, 11, 1 ) -- obey note offs
      local new_name = F_extract_filename(filename)
      F_SetFXName(track, rs5k_pos, 'RS5K '..new_name)
      reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE0", filename)
      reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE","")
      base_pitch = base_pitch + 1                
      ::skip_to_next_item::
    end
  end
  ------------------------------------------------------------------------------- 
    function F_extract_filename(orig_name)
    local reduced_name_slash = orig_name:reverse():find('[%/%\\]')
    local reduced_name = orig_name:sub(-reduced_name_slash+1)
    reduced_name = reduced_name:sub(0,-1-reduced_name:reverse():find('%.'))
    return reduced_name
  end
  -------------------------------------------------------------------------------
  function F_SetFXName(track, fx, new_name)
    local edited_line,edited_line_id
    -- get ref guid
      if not track or not tonumber(fx) then return end
      local FX_GUID = reaper.TrackFX_GetFXGUID( track, fx )
      if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
      plug_type = reaper.TrackFX_GetIOSize( track, fx )
    -- get chunk t
      local _, chunk = reaper.GetTrackStateChunk( track, '', false )
      local t = {} for line in chunk:gmatch("[^\r\n]+") do t[#t+1] = line end
    -- find edit line
      local search
      for i = #t, 1, -1 do
        local t_check = t[i]:gsub('-','')
        if t_check:find(FX_GUID) then search = true  end
        if t[i]:find('<') and search and not t[i]:find('JS_SER') then
          edited_line = t[i]:sub(2)
          edited_line_id = i
          break
        end
      end
    -- parse line
      if not edited_line then return end
      local t1 = {}
      for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
      t2 = {}
      for i = 1, #t1 do
        segm = t1[i]
        if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
        if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
      end
  
      if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
      if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST
  
      local out_line = table.concat(t2,' ')
      t[edited_line_id] = '<'..out_line
      out_chunk = table.concat(t,'\n')
      --msg(out_chunk)
      reaper.SetTrackStateChunk( track, out_chunk, false )
      reaper.UpdateArrange()
  end
  -------------------------------------------------------------------------------  
  function run()
    count_items0 = reaper.CountMediaItems(0)
    if count_items0 ~= count_items or isME_open() then 
      if not isME_open() then reaper.Main_OnCommand(50124, 0)  end
      
        -- get base pitch
        local ret, base_pitch = reaper.GetUserInputs( script_title, 1, 'Set base pitch', 60 )
        if not ret 
          or not tonumber(base_pitch) 
          or tonumber(base_pitch) < 0 
          or tonumber(base_pitch) > 127 then
          reaper.atexit()
          return true
        end
        base_pitch = math.floor(tonumber(base_pitch))        
        local f_item = reaper.GetSelectedMediaItem(0,0)        
        if f_item then 
          reaper.PreventUIRefresh( -1 )
          local f_item_tr =  reaper.GetMediaItemTrack( f_item )
          ExportSelItemsToRs5k(base_pitch, f_item_tr)
          MIDI_prepare(f_item_tr)
          reaper.Main_OnCommand(40289, 0) -- unselect items
          reaper.SetMediaItemSelected( f_item, true )
          reaper.Main_OnCommand(40006, 0)
          reaper.PreventUIRefresh( 1 )
         else
          reaper.atexit()
        end
        
      reaper.atexit() 
     else 
      reaper.defer(run) 
    end
  end

  ------------------------------------------------------------------------------- 
  function isME_open()  return reaper.GetToggleCommandState(50124) == 0 end
  -------------------------------------------------------------------------------   
  function MIDI_prepare(tr)
    local bits_set=tonumber('111111'..'00000',2)
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+bits_set ) -- set input to all MIDI
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI in
  end
    ---------------------------------------------------------------------
      function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.4,true)    
    if ret and ret2 then 
      reaper.Undo_BeginBlock()
      count_items = reaper.CountMediaItems(0)
          if isME_open() then reaper.Main_OnCommand(50124, 0) end -- open MediaExplorer
          run()  
      reaper.Undo_EndBlock(script_title, 1)
    end
