-- @description Generate CUE from project markers
-- @version 1.06
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use essential order fro markers rather that markers IDs
--    # fix use marker name or Untitled X
  

  function patternamtch(nameOut) return nameOut:gsub('%s',''):sub(0,1) end
  function main()
    local scr_name = 'MPL Generate CUE from markers'
    local _, cnt_markers =  CountProjectMarkers(0)
    if not cnt_markers or cnt_markers == 0 then MB('Add markers to project first', scr_name, 0) return end
    
    local mrkerid = 0
    local ret, user_inputs = GetUserInputs('Cue', 5, 
        'Genre,Year,Performer,Album Title,File name (with extension)', 
        'Other,2016,Performer,Album_Title,FileName.wav')
    if not ret then return end
    local fields = {}
    for word in user_inputs:gmatch('[^%,]+') do fields[#fields+1] = word end
    if #fields ~= 5 then MB('Empty fields not supported', scr_name, 0) return end
    local ext_len = fields[5]:reverse():find('%.')
    if not ext_len then MB('Enter filename with extension', scr_name, 0) return end
    local extension = fields[5]:sub(1-ext_len):upper()
    
    out_str = 
      ' REM GENRE '..   fields[1]..
      '\n REM DATE '..  fields[2]..
      '\n PERFORMER '.. fields[3]..
      '\n TITLE '..     fields[4]..
      '\n FILE '..      fields[5]..' '..extension..'\n'
    
    ind3 = '   '
    ind5 = '     '

    -- loop markers
    local tsstart, tsend = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
    local hastimesel = math.abs(tsend-tsstart) >0.01
    
    -- test loop for patterns
      local haspattern
      for i = 1, cnt_markers do 
        local _, _, posOut, _, nameOut, markrgnindexnumber = EnumProjectMarkers2(0, i-1)
        if not haspattern then 
          haspattern = patternamtch(nameOut) == '#'
                      or patternamtch(nameOut) == '!'
                      or patternamtch(nameOut) == '@'
        end
        if not include then include = patternamtch(nameOut) == '#' end
      end
      
      for i = 1, cnt_markers do 
        local _, _, posOut, _, nameOut, markrgnindexnumber = EnumProjectMarkers2(0, i-1)
        if (hastimesel and not (posOut >= tsstart and posOut<=tsend)) or 
           (patternamtch(nameOut) == '!' or patternamtch(nameOut) == '@') or (include and patternamtch(nameOut) ~= '#')
         then
          goto skip_next 
        end 
        
        
        -- check time sel
          if not hastimesel then 
            posOut = format_timestr_pos(posOut, '', 5) 
           else
            posOut = format_timestr_pos(posOut-tsstart, '', 5) 
          end
        
        -- format hours/minutes to minutes 
          local time = {}
          for num in posOut:gmatch('[%d]+') do 
            if tonumber(num) > 10 then num = tonumber(num) end
            time[#time+1] = num
          end
          if tonumber(time[1]) > 0 then time[2] = tonumber(time[2]) + tonumber(time[1]) * 60 end
          
        perf = fields[3]
        posOut = table.concat(time,':',2)
        
        --[[local s_name  = nameOut:find('[%-]')
        if s_name ~=nil then
          perf = nameOut:sub(0, s_name-2)
          nameOut1 = nameOut:sub(s_name+2)
        end]]
        
        --local id = ("%02d"):format(markrgnindexnumber)
        local id = ("%02d"):format(mrkerid)
        mrkerid=mrkerid+1
        if nameOut == nil or nameOut == '' then nameOut1 = 'Untitled '..id end
        out_str = out_str..ind3..'TRACK '..id..' AUDIO'..'\n'..
                           ind5..'TITLE '..'"'..nameOut..'"'..'\n'..
                           ind5..'PERFORMER '..'"'..perf..'"'..'\n'..
                           ind5..'INDEX 01 '..posOut..'\n'
        ::skip_next::
      end
      
    -- write to file
      local retval0,  saving_folder = JS_Dialog_BrowseForSaveFile('Generate CUE file', '', '', ".cue")
      if retval0 == 1 then 
        if not saving_folder:lower():match('%.cue') then saving_folder = saving_folder..'.cue' end
        local f = io.open(saving_folder, 'w')
        if f then 
          f:write(out_str)
          f:close()
         else
          msg('(error creating file, here is CUE file content instead)\n'..out_str) 
        end 
      end
        
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end 
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_LoadVFv2') 
    
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.95,true)  
    if ret2 then 
      if JS_Dialog_BrowseForSaveFile then main() else MB('Missed JS ReaScript API extension', 'Error', 0)  end
    end
  end