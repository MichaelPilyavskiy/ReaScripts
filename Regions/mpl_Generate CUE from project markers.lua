-- @version 1.02
-- @author mpl
-- @changelog
--   + fix split name

--[[
   * ReaScript Name: Generate CUE from project markers
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
  ]]
  
  function msg (s) reaper.ShowConsoleMsg(s) end
  
  function main()
    local scr_name = 'MPL Generate CUE from markers'
    local _, cnt_markers =  reaper.CountProjectMarkers(0)
    if not cnt_markers or cnt_markers == 0 then reaper.MB('Add markers to project first', scr_name, 0) return end
    
    reaper.ClearConsole()
    local _, user_inputs = reaper.GetUserInputs('Cue', 5, 
        'Genre,Year,Performer,Album Title,File name (with extension)', 
        'Other,2016,Performer,Album_Title,FileName.wav')
    local fields = {}
    for word in user_inputs:gmatch('[^%,]+') do fields[#fields+1] = word end
    if #fields ~= 5 then reaper.MB('Empty fields not supported', scr_name, 0) return end
    local ext_len = fields[5]:reverse():find('%.')
    if not ext_len then reaper.MB('Enter filename with extension', scr_name, 0) return end
    local extension = fields[5]:sub(1-ext_len):upper()
    
    out_str = 
      ' REM GENRE '..   fields[1]..
      '\n REM DATE '..  fields[2]..
      '\n PERFORMER '.. fields[3]..
      '\n TITLE '..     fields[4]..
      '\n FILE '..      fields[5]..' '..extension..'\n'
    
    ind3 = '   '
    ind5 = '     '

      for i = 1, cnt_markers do
      
        _, _, posOut, _, nameOut, markrgnindexnumber = reaper.EnumProjectMarkers2(0, i-1)
        posOut = reaper.format_timestr_pos(posOut, '', 5)
        
        -- format hours/minutes to minutes 
          local time = {}
          for num in posOut:gmatch('[%d]+') do 
            if tonumber(num) > 10 then num = tonumber(num) end
            time[#time+1] = num
          end
          if tonumber(time[1]) > 0 then time[2] = tonumber(time[2]) + tonumber(time[1]) * 60 end
        
        perf = fields[3]
        posOut = table.concat(time,':',2)
        
        local s_name  = nameOut:find('[%-]')
        if s_name ~=nil then
          perf = nameOut:sub(0, s_name-2)
          nameOut1 = nameOut:sub(s_name+2)
        end
        
        if nameOut1 == nil or nameOut1 == '' then nameOut1 = 'Untitled '..("%02d"):format(markrgnindexnumber) end
        out_str = out_str..ind3..'TRACK '..("%02d"):format(markrgnindexnumber)..' AUDIO'..'\n'..
                           ind5..'TITLE '..'"'..nameOut1..'"'..'\n'..
                           ind5..'PERFORMER '..'"'..perf..'"'..'\n'..
                           ind5..'INDEX 01 '..posOut..'\n'
      end
      
      reaper.ShowConsoleMsg(out_str)
        
  end
  
  main()
