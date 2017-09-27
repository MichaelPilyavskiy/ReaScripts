-- @description Latch all automation items to edit cursor
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init release
  

  --NOT gfx NOT reaper
  local scr_title = 'Latch all automation items to edit cursor'
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local function msg(s) if not s then return end ShowConsoleMsg('==================\n'..os.date()..'\n'..s..'\n') end
  -----------------------------------------------------
  function GetLatchValue(envelope,mouse_pos,SR)
    if not envelope then return end
    local ex = false
    local out_val
    for autoitem_idx = CountAutomationItems( envelope ), 1, -1 do
      local AI_pos = GetSetAutomationItemInfo( envelope, autoitem_idx-1, 'D_POSITION', -1, false )
      local AI_len = GetSetAutomationItemInfo( envelope, autoitem_idx-1, 'D_LENGTH', -1, false )
      if  AI_pos + AI_len < mouse_pos and not  (AI_pos<mouse_pos and AI_pos + AI_len > mouse_pos)  then
        local retval, value = Envelope_Evaluate( envelope, AI_pos + AI_len-0.0001, SR, 1 )
        if retval then 
          ex = true
          out_val = value
          break 
        end
       elseif AI_pos<mouse_pos and AI_pos + AI_len > mouse_pos then 
        break 
      end
    end
    
    -- return value/search post AI
    if ex then return out_val
      else
       for autoitem_idx = 1, 1 do--CountAutomationItems( envelope ) do
         local AI_pos = GetSetAutomationItemInfo( envelope, autoitem_idx-1, 'D_POSITION', -1, false )
         local AI_len = GetSetAutomationItemInfo( envelope, autoitem_idx-1, 'D_LENGTH', -1, false )
         if  AI_pos > mouse_pos  then
           local retval, value = Envelope_Evaluate( envelope, AI_pos, SR, 1 )
           return value
         end
       end
    end
  end
  -----------------------------------------------------
  function SetEnvValue(track, envelope, fx_id, param_id, value)
    if fx_id >= 0 then    
      TrackFX_SetParamNormalized( track, fx_id, param_id, value ) 
     --[[else
      local trackid = reaper.CSurf_TrackToID( track, false )
      local retval, env_name = GetEnvelopeName( envelope, '' )
      if env_name == 'Volume' then
        reaper.CSurf_OnVolumeChangeEx( track, value, false, false )
      end]]
    end
  end

  -----------------------------------------------------
  function main()
    local SR =   tonumber(format_timestr_len( 1, '', 0, 4 ))  
    BR_GetMouseCursorContext()
    --local pos =  BR_GetMouseCursorContext_Position()
    local pos = GetCursorPositionEx( 0 )
    for tr_id = 1, CountTracks(0) do
      local track = GetTrack(0,tr_id-1)
      for envidx = 1 , CountTrackEnvelopes( track ) do
        local envelope = GetTrackEnvelope( track, envidx-1 )
        local val = GetLatchValue(envelope,pos,SR)
        local track, fx_id, param_id = Envelope_GetParentTrack( envelope )
        if val then SetEnvValue(track, envelope, fx_id, param_id, val) end
      end
    end
  end
  -----------------------------------------------------  
  main()