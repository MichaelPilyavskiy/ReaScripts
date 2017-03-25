-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Export selected item to RS5k instance on same track as chromatic source
-- @changelog
--    # fix for x64 vrs check

  local script_title = 'Export selected item to RS5k instance on same track as chromatic source'
  
  -------------------------------------------------------------------------------
  function F_SetFXName(track, fx, new_name)
    local edited_line,edited_line_id,segm
    -- get ref guid
      if not track or not tonumber(fx) then return end
      local FX_GUID = reaper.TrackFX_GetFXGUID( track, fx )
      if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
      local plug_type = reaper.TrackFX_GetIOSize( track, fx )
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
      local t2 = {}
      for i = 1, #t1 do
        segm = t1[i]
        if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
        if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
      end
  
      if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
      if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST
  
      local out_line = table.concat(t2,' ')
      t[edited_line_id] = '<'..out_line
      local out_chunk = table.concat(t,'\n')
      --msg(out_chunk)
      reaper.SetTrackStateChunk( track, out_chunk, false )
      reaper.UpdateArrange()
  end
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
    F_SetFXName(track, rs5k_pos, 'RS5K '..new_name)
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
    -- item check
      local item = reaper.GetSelectedMediaItem(0,0)
      if not item then return end        
      local track =  reaper.GetMediaItemTrack( item )
      
    --[[ glue item      
      reaper.Main_OnCommand(40289, 0) -- unselect all items
      reaper.SetMediaItemSelected(item, true)
      reaper.Main_OnCommand(40362, 0) -- glue without time selection]]
      
    -- export to RS5k
      ExportSelItemsToRs5k(track, item)
      reaper.Main_OnCommand(40006,0)--Item: Remove items
      
  end
    -------------------------------------------------------------------------------      
  function vrs_check()
    local appvrs = reaper.GetAppVersion()
    appvrs = appvrs:match('[%d%p]+'):gsub('/','')
    if not appvrs or not tonumber(appvrs) or tonumber(appvrs) < 5.40 then return else return true end 
  end
    -------------------------------------------------------------------------------    
  if vrs_check() then 
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock(script_title, 1)
   else
    reaper.MB('Script works with REAPER 5.40+', 'Error', 0)
  end