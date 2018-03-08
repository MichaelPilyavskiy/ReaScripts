-- @version 1.1
-- @author MPL
-- @changelog
--   #proper match GUID
-- @description Select tracks with SWS Notes
-- @website http://forum.cockos.com/member.php?u=70694

  function main()
    local ext_line_C
    local _, projfn = reaper.EnumProjects( -1, '' )
    local file = io.open(projfn, 'r')
    if file then
      ext_line_C = ''
      local content = file:read("*all")      
      for ext_line in content:gmatch('S&M_TRACKNOTES.-[\n]') do 
        ext_line_C = ext_line_C..' '..ext_line:sub(17,-3):gsub('-', '')
      end
      file:close()
    end
    
    if not ext_line_C then return end
    local cnt_tracks = reaper.CountTracks(0)
    for i = 1, cnt_tracks do
      local track = reaper.GetTrack(0,i-1)
      local tr_guid =  reaper.GetTrackGUID( track ):sub(2,-2):gsub('-', '')
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
