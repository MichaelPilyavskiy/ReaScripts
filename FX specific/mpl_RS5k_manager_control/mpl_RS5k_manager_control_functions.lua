-- @description RS5k_manager_control_functions
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  -----------------------------------------------------------------------   
  function SetGlobalParam(val, param, incr)
    local tr 
    local haspintrack = reaper.GetExtState('MPL_RS5K manager', 'pintrack')
    if not haspintrack or not tonumber(haspintrack) then return end
    if  tonumber(haspintrack) == 1 then 
      local ret, trGUID = reaper.GetProjExtState( 0, 'MPLRS5KMANAGE', 'PINNEDTR' )
      tr = reaper.BR_GetMediaTrackByGUID( 0, trGUID )
      if not tr  then return end
     else
      tr = reaper.GetSelectedTrack(0,0)
    end
      
    if not tr then return end
    SetGlobalParam_sub(tr, param, val, incr) 
      
    for sid = 1,  reaper.GetTrackNumSends( tr, 0 ) do
      local srcchan = reaper.GetTrackSendInfo_Value( tr, 0, sid-1, 'I_SRCCHAN' )
      local dstchan = reaper.GetTrackSendInfo_Value( tr, 0, sid-1, 'I_DSTCHAN' )
      local midiflags = reaper.GetTrackSendInfo_Value( tr, 0, sid-1, 'I_MIDIFLAGS' )
      if srcchan == -1 and dstchan ==0 and midiflags == 0 then
        local desttr = reaper.BR_GetMediaTrackSendInfo_Track( tr, 0, sid-1, 1 )
        SetGlobalParam_sub(desttr, param, val, incr)
      end
    end    
  end
  ----------------------------  
  function SetGlobalParam_sub(tr, param, val, incr)    
    for fxid = 1,  reaper.TrackFX_GetCount( tr ) do
      -- validate RS5k by param names
        local retval, p3 = reaper.TrackFX_GetParamName( tr, fxid-1, 3, '' )
        local retval, p4 = reaper.TrackFX_GetParamName( tr, fxid-1, 4, '' )
        local isRS5k = retval and p3:match('range')~= nil and p4:match('range')~= nil
        if not isRS5k then goto skipFX end
      
      if val then 
        reaper.TrackFX_SetParamNormalized( tr, fxid-1, param, val)
       elseif incr then
        local val = reaper.TrackFX_GetParamNormalized( tr, fxid-1, param) 
        --reaper.ShowConsoleMsg((val )..'\n')
        if param == 9 or param == 10 then
          reaper.TrackFX_SetParamNormalized( tr, fxid-1, param, math.max(0,math.min(1,val + incr/2000)) )
         elseif param == 1 then
          reaper.TrackFX_SetParamNormalized( tr, fxid-1, param, math.max(0,math.min(1,val + incr)) )
         elseif param == 15 then
          reaper.TrackFX_SetParamNormalized( tr, fxid-1, param, math.max(0,math.min(1,val + incr/160)) )
         elseif param == 22 then
          reaper.TrackFX_SetParamNormalized( tr, fxid-1, param, math.max(0,math.min(1,val + incr/1000)) )
         elseif param == 13 then
          local end_val = reaper.TrackFX_GetParamNormalized( tr, fxid-1, 14 ) -0.001
          reaper.TrackFX_SetParamNormalized( tr, fxid-1, param, math.max(0,math.min(end_val,val + incr)) )
         elseif param == 14 then
          local st_val = reaper.TrackFX_GetParamNormalized( tr, fxid-1, 13 ) +0.001
          reaper.TrackFX_SetParamNormalized( tr, fxid-1, param, math.max(st_val,math.min(1,val + incr)) )   
         elseif param == 24 then
          reaper.TrackFX_SetParamNormalized( tr, fxid-1, param, math.max(0,math.min(1,val + incr/14990)) )                   
        end
      end
        
      ::skipFX::
    end 
  end
