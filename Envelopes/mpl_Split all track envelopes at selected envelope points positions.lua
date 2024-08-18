-- @description Split all track envelopes at selected envelope points positions
-- @version 1.02
-- @author MPL 
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
    ---------------------------------------------------
  function main()
    local tr_env = GetSelectedEnvelope( 0 )
    if not (tr_env and ValidatePtr2( 0, tr_env, 'TrackEnvelope*')) then return end
    local track = Envelope_GetParentTrack( tr_env )
    
    local SR =tonumber(format_timestr_pos( 1, '', 4 ))
    local b_size = 256
    local nosort = false
    
    -- collect points
      local point_t = {}
      for ptidx=1,  CountEnvelopePoints( tr_env ) do
        local retval, time, value, shape, tension, selected = GetEnvelopePoint( tr_env, ptidx-1 )
        if selected then point_t[#point_t+1] = time end
      end
      
    -- split
      for envidx = 1,  CountTrackEnvelopes( track ) do
        local tr_env_child = GetTrackEnvelope( track, envidx-1 )
        for i = 1, #point_t do 
          -- get env point
          local pt_idx = GetEnvelopePointByTime( tr_env_child, point_t[i]+(10^-14) )
          local retval, time, value, shape, tension, selected = GetEnvelopePoint( tr_env_child, pt_idx )
          local pt_far = math.abs(time - point_t[i]) > (10^-13)
          if pt_far and shape == 0 then -- linear
            local retval, value = Envelope_Evaluate( tr_env_child, point_t[i], SR , b_size ) 
            InsertEnvelopePoint( tr_env_child, point_t[i], value, -1, -1, false, nosort )
           elseif pt_far and shape == 1 then -- square
            local retval, value = Envelope_Evaluate( tr_env_child, point_t[i], SR , b_size ) 
            InsertEnvelopePoint( tr_env_child, point_t[i], value, shape, -1, false, nosort )  
           elseif pt_far and shape >= 2 then -- slow startend
            local retval, value = Envelope_Evaluate( tr_env_child, point_t[i], SR , b_size ) 
            InsertEnvelopePoint( tr_env_child, point_t[i], value, 0, -1, false, nosort )            
          end
        end 
      end 
  end
  if VF_CheckReaperVrs(5.975,true) then
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Split all track envelopes at selected envelope points positions', 0xFFFFFFFF ) 
    UpdateArrange()
  end
  
