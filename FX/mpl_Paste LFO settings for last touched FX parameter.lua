-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Paste LFO settings for last touched FX parameter
-- @changelog
--    + init
  
  st = 'Paste LFO settings from last touched FX parameter'
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  ----------------------------------------------------  
  local function GetFxNamebyGUID(guid, fx_names)
    for key in pairs(fx_names) do
      if guid:match(key) then return fx_names[key] end
    end
  end
  reaper.ClearConsole()
  ----------------------------------------------------
  local function msg(s) ShowConsoleMsg(s..'\n') end
  ----------------------------------------------------
  function SetLFO(tr,  fxnumber, paramnumber, insert_ch)
    data = {}
    if not tr then return end
    local fx_guid =  reaper.TrackFX_GetFXGUID( tr, fxnumber):gsub('[{}-]','')
    -- chunk stuff
      local _, chunk = GetTrackStateChunk(  tr, '', false )
      local t= {} for line in chunk:gmatch('[^\n\r]+') do t[#t+1] = line end
      for i = 1, #t do 
        if t[i]:match('FXID') and t[i]:gsub('[{}-]','') and t[i]:gsub('[{}-]',''):match(fx_guid) then search_PM = true search_PM_id = i end
        if search_PM and (t[i]:match('<PROGRAMENV '..paramnumber) or t[i]:match('<PARMENV') )then erase_chunk = true end
        if erase_chunk and t[i]:find('>') then 
          erase_chunk = false 
          t[i] = ''
        end
        if erase_chunk then
          t[i] = ''
        end
      end
      if search_PM_id and t[search_PM_id+1] then t[search_PM_id] = t[search_PM_id]..'\n'..insert_ch end
    SetTrackStateChunk(  tr, table.concat(t, '\n'), true )
    --msg(table.concat(t, '\n'))
    
  end
  ----------------------------------------------------------------
  
  local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
  local ES_str = GetExtState('mpl_copy_lfo_settings_buf', 'buf')
  if retval and ES_str ~= '' then
    local insert_ch = '<PROGRAMENV '..paramnumber..'\n'..ES_str..'\n>'
    local tr =  reaper.CSurf_TrackFromID( tracknumber, false )
    reaper.Undo_BeginBlock()
    SetLFO(tr, fxnumber, paramnumber, insert_ch)       
    reaper.Undo_EndBlock(st, 1)
  end