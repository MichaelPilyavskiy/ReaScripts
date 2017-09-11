-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description List random impulse in directory for focused ReaVerb
-- @changelog
--    + init


function main()
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    local ret, fn0 = reaper.TrackFX_GetNamedConfigParm(track, fxnumberOut, "ITEM0")
    if not ret then return end
    fn = fn0:gsub('\\', '/')
    
     f_path = fn0:match('"(.*)"')
     path = f_path:match('(.*)[%/\\]')
     cur_file = f_path:reverse():match('[^%/\\]+'):reverse()
    -- get files list
      local files = {}
      local i = 0
      repeat
      local file = reaper.EnumerateFiles( path, i )
      if file then
        files[#files+1] = file
      end
      i = i+1
      until file == nil
      
    -- search file list
      --local trig_file
      if #files < 2 then return end
      trig_id = math.floor(math.random(#files-1))+1
      trig_file = path..'/'..files[trig_id] 
      
      if trig_file then 
        trig_file = 'FILELDR "'..trig_file..'" 12'
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "ITEM0", trig_file)
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "DONE", "")
      end
  end


  reaper.Undo_BeginBlock()
  main(track)
  reaper.Undo_EndBlock('List random impulse in directory for focused ReaVerb', 1)