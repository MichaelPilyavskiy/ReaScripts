-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Select tracks with SWS Notes
-- @website http://forum.cockos.com/member.php?u=70694
  
  function msg(s) reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(s) end


  function main()
    _, projfn = reaper.EnumProjects( -1, '' )
    file = io.open(projfn, 'r')
    if file then
      ext_line_C = ''
      content = file:read("*all")
      for ext_line in content:gmatch('S&M_TRACKNOTES.->') do 
        ext_line_C = ext_line_C..'\n'..ext_line:sub(16)
      end
      file:close()
    end
    
    if not ext_line_C then return end
    local cnt_tracks = reaper.CountTracks(0)
    for i = 1, cnt_tracks do
      local track = reaper.GetTrack(0,i-1)
      local tr_guid =  reaper.GetTrackGUID( track )
      if ext_line_C:find(tr_guid) then  
        reaper.SetTrackSelected( track, true )
       else
        reaper.SetTrackSelected( track, false )
      end
      
    end
  end

  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Select tracks with SWS Notes', 0)
