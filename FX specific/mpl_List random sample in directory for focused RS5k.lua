-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description List random sample in directory for focused RS5k
-- @changelog
--    # avoid non-media extension


function main()
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    ret, fn = reaper.TrackFX_GetNamedConfigParm(track, fxnumberOut, "FILE0")
    if not ret then     
      ret, tracknumberOut, fxnumberOut, paramnumberOut = reaper.GetLastTouchedFX()
      local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
      if not track then return end
      ret, fn = reaper.TrackFX_GetNamedConfigParm(track, fxnumberOut, "FILE0")
    end
    if not ret then return end
    
    fn = fn:gsub('\\', '/')
    
    path = fn:reverse():match('[%/]+.*')
    if path then path = path:reverse():sub(0,-2) else return end
    cur_file =     fn:reverse():match('.-[%/]')
    if cur_file then cur_file = cur_file:reverse():sub(2) else return end
    -- get files list
      local files = {}
      local i = 0
      repeat
      local file = reaper.EnumerateFiles( path, i )
      if file and reaper.IsMediaExtension(file:gsub('.+%.', ''), false) then
        files[#files+1] = file
      end
      i = i+1
      until file == nil
      
    -- search file list
      local trig_file
      if #files < 2 then return end
      trig_id = math.floor(math.random(#files-1))+1
      trig_file = path..'/'..files[trig_id] 
        
      
      if trig_file then 
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "FILE0", trig_file)
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "DONE", "")
      end
  end


  reaper.Undo_BeginBlock()
  main(track)
  reaper.Undo_EndBlock('List random sample in directory for focused RS5k', 1)
