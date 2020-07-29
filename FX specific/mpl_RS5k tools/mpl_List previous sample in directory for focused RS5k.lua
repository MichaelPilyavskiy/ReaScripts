-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description List previous sample in directory for focused RS5k
-- @noindex
-- @changelog
--    # avoid non-media extension


function main()
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    ret, fn = reaper.TrackFX_GetNamedConfigParm(track, fxnumberOut, "FILE0")
    if not ret then return end
    fn = fn:gsub('\\', '/')
    
    path = fn:reverse():match('[%/]+.*'):reverse():sub(0,-2)
    cur_file =     fn:reverse():match('.-[%/]'):reverse():sub(2)
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
      for i = #files-1, 1, -1 do
        if files[i+1] == cur_file then 
          trig_file = path..'/'..files[i] 
          break 
         elseif i ==1 then trig_file = path..'/'..files[#files] 
        end
      end
      
      if trig_file then 
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "FILE0", trig_file)
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "DONE", "")
      end
  end


  reaper.Undo_BeginBlock()
  main(track)
  reaper.Undo_EndBlock('List previous sample in directory for focused RS5k', 1)
