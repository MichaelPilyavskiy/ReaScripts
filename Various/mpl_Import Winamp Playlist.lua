-- @description Import Winamp Playlist
-- @version 1.0
-- @author mpl
-- @changelog
--    + init
-- @website http://forum.cockos.com/member.php?u=70694


  function msg(s) reaper.ShowConsoleMsg(s) end
  
  function main()
    -- ask for file
      retval, filePath = reaper.GetUserFileNameForRead('', 'Import Winamp Playlist', 'pls')
      if not retval then return end
    
    
    -- read file
      file = io.open(filePath)
      if not file then return end
      file:close()
        
    -- get count entries
      retval, count = reaper.BR_Win32_GetPrivateProfileString( 'playlist', 'NumberOfEntries', 0, filePath )     
      if not count or not tonumber(count) then return end
      count = tonumber(count)
      
    -- parse pls
    
      for i = 1, count do
        _, source_file_name = reaper.BR_Win32_GetPrivateProfileString( 'playlist', 'File'..i, 0, filePath )  
        if source_file_name then
          source_file = io.open(source_file_name )
          if source_file then
            _, title = reaper.BR_Win32_GetPrivateProfileString( 'playlist', 'Title'..i, 0, filePath ) 
            if title then
              reaper.InsertMedia( source_file_name, 0 )
            end
            source_file:close()
          end
        end
      end
      
    -- update
      reaper.UpdateTimeline()
      reaper.UpdateArrange()
      
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Import Winamp Playlist', 0)
