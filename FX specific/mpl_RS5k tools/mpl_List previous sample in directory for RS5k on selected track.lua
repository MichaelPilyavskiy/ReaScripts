-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description List previous sample in directory for RS5k on selected track
-- @noindex
-- @changelog
--    #header


  local script_title = 'List previous sample for RS5k on selected track'
  -------------------------------------------------------------------------------
  local track = reaper.GetSelectedTrack(0,0)
  if not track then return end
  
  ext = {'wav'}
  
  -------------------------------------------------------------------------------  
  function GetRS5K_FXid(track) local catch_id, catch
    -- seems  reaper.BR_TrackFX_GetFXModuleName( track, fx ) doesnt work
    local _, chunk = reaper.GetTrackStateChunk( track, '', false )
    for line in chunk:gmatch('[^\r\n]+') do
      if line:find('FXCHAIN') then catch_id = 0 end
      if line:find('FXID') and catch_id then catch_id = catch_id + 1 end
      if line:find('reasamplomatic.dll') then return catch_id end
    end
    return -1
  end
  -------------------------------------------------------------------------------
  function main(track)
    local rs5k_pos = GetRS5K_FXid(track)
    local ret, fn = reaper.TrackFX_GetNamedConfigParm(track, rs5k_pos, "FILE0")
    if not ret then return end
    -- find path
      local slash 
      local slash_win = fn:reverse():find('\\') if slash_win then slash = slash_win end
      local slash_osx = fn:reverse():find('/') if slash_osx then slash = slash_osx end
      if not slash then return end
      local path = fn:sub(0,-slash-1)
      local cur_file = fn:sub(-slash+1)
    -- get files list
      local files = {}
      local i = 0
      repeat
      local file = reaper.EnumerateFiles( path, i )
      if file then
        for i = 1, #ext do
          if file:lower():reverse():find(ext[i]:lower():reverse()) == 1 then
            files[#files+1] = file
            break
          end
        end
      end
      i = i+1
      until file == nil
    -- search file list
      local trig_file
      if #files < 2 then return end
      for i = #files-1, 1, -1 do
        if files[i+1] == cur_file then trig_file = path..'/'..files[i] break end
      end
      if trig_file then 
        reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE0", trig_file)
        reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE", "")
      end
  end
    -------------------------------------------------------------------------------      
  function vrs_check()
    local appvrs = reaper.GetAppVersion()
    appvrs = appvrs:match('[%d%p]+'):gsub('/','')
    if not appvrs or not tonumber(appvrs) or tonumber(appvrs) < 5.40 then return else return true end 
  end
  -------------------------------------------------------------------------------   
  if not vrs_check() then 
    reaper.MB('Script works with REAPER 5.40 and upper.','Error',0) 
   else
    reaper.Undo_BeginBlock()
    main(track)
    reaper.Undo_EndBlock(script_title, 1)
  end
  