-- @version 1.10
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Export selected items to RS5k instances on selected track
-- @changelog
--    + delete items after export
--    # fix version check

  local script_title = 'Export selected items to RS5k instances on selected track'
  -------------------------------------------------------------------------------
  local track = reaper.GetSelectedTrack(0,0)
  if not track then return end
  
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
  function GlueSelectedItemsIndependently()
    -- store GUIDs
      GUIDs = {}
      for it_id = 1, reaper.CountSelectedMediaItems(0) do
        local item =  reaper.GetSelectedMediaItem( 0, it_id-1 )
        local it_GUID = reaper.BR_GetMediaItemGUID( item )
        GUIDs[#GUIDs+1] = it_GUID
      end
      
    -- glue items
      new_GUIDs = {}
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
    
  end
  ------------------------------------------------------------------------------- 
  function ExportSelItemsToRs5k(base_pitch)
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
  function vrs_check()
    local appvrs = reaper.GetAppVersion()
    appvrs = appvrs:match('[%d%p]+')
    if not appvrs then return end
    appvrs =  tonumber(appvrs)
    if not appvrs or appvrs <= 5.29 then return end
    if not reaper.APIExists('TrackFX_SetNamedConfigParm')  then return end
    return true
  end
  -------------------------------------------------------------------------------    
  function main(track)
    if not vrs_check() then return end
    
    -- get base pitch
    local ret, base_pitch = reaper.GetUserInputs( script_title, 1, 'Set base pitch', 60 )
    if not ret 
      or not tonumber(base_pitch) 
      or tonumber(base_pitch) < 0 
      or tonumber(base_pitch) > 127 then
      return true
    end
    base_pitch = math.floor(tonumber(base_pitch))
    reaper.PreventUIRefresh( -1 )
    GlueSelectedItemsIndependently()
    ExportSelItemsToRs5k(base_pitch)
    reaper.Main_OnCommand(40006,0)--Item: Remove items
    reaper.PreventUIRefresh( 1 )
    return true
  end
  ------------------------------------------------------------------------------- 
    function F_extract_filename(orig_name)
    local reduced_name_slash = orig_name:reverse():find('[%/%\\]')
    local reduced_name = orig_name:sub(-reduced_name_slash+1)
    reduced_name = reduced_name:sub(0,-1-reduced_name:reverse():find('%.'))
    return reduced_name
  end
  
  -------------------------------------------------------------------------------  
  reaper.Undo_BeginBlock()
  ret = main(track)
  if not ret then reaper.MB('Script works with REAPER 5.40 and upper. Script also need SWS extension.','Error',0) end
  reaper.Undo_EndBlock(script_title, 1)