-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Copy LFO settings from last touched FX parameter
-- @changelog
--    + init
  
  st = 'Copy LFO settings from last touched FX parameter'
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
  function RemovePM(tr,  fxnumber, paramnumber)
    data = {}
    if not tr then return end
    local fx_guid =  reaper.TrackFX_GetFXGUID( tr, fxnumber):gsub('[{}-]','')
    PM_ch = {}
    -- chunk stuff
      local _, chunk = GetTrackStateChunk(  tr, '', false )
      local t= {} for line in chunk:gmatch('[^\n\r]+') do t[#t+1] = line end
      for i = 1, #t do 
        if t[i]:match('FXID') and t[i]:gsub('[{}-]','') and t[i]:gsub('[{}-]',''):match(fx_guid) then search_PM = true end
        if search_PM and (t[i]:match('<PROGRAMENV '..paramnumber) or t[i]:match('<PARMENV') )then erase_chunk = true end
        if erase_chunk and t[i]:find('>') then 
          erase_chunk = false 
          PM_ch[#PM_ch+1] = t[i] 
          break 
        end
        if erase_chunk then 
          PM_ch[#PM_ch+1] = t[i] 
        end        
      end
    
    
    if #PM_ch > 1 then 
      for i = #PM_ch, 1, -1 do
        if not (PM_ch[i]:match('LFO') or
                PM_ch[i]:match('PARAMBASE')) then table.remove(PM_ch, i)
        end
      end
      SetExtState('mpl_copy_lfo_settings_buf', 'buf', table.concat(PM_ch, '\n'), false)
      MB( 'Copied LFO settings:\n\n'..table.concat(PM_ch, '\n'), st, 0 )
    end
    
  end
  ----------------------------------------------------------------
  
  local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
  
  if retval then
    local tr =  reaper.CSurf_TrackFromID( tracknumber, false )
    reaper.Undo_BeginBlock()
    RemovePM(tr, fxnumber, paramnumber)       
    reaper.Undo_EndBlock(st, 1)
  end