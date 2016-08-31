-- @description Duplicate envelope points
-- @version 1.02
--    #fixed -1 sample offset
--    #fixed comparing time beetween points
-- @author mpl
-- @changelog
-- @website http://forum.cockos.com/member.php?u=70694


--[[changelog
  -- 1.02 / 31.08.2016
    #fixed -1 sample offset
    #fixed comparing time beetween points
  -- 1.01 / 31.08.2016
    + fx envelope support
    + take envelope support
    + proper unselect all points function
    - Disabled track envelope support, see below
    - Prevent REAPER bad behaviour: CountTrackEnvelopes / GetTrackEnvelope() include FX envelopes
  -- 1.0  / 31.08.2016
]]
    
  
function Unset(env, id)
  local _, pnt_pos, pnt_value, pnt_shape, pnt_tension, selected = reaper.GetEnvelopePoint(env, id)
  reaper.SetEnvelopePoint( env, id, pnt_pos, pnt_value, pnt_shape, pnt_tension, false, false ) 
end
----------------------------------------------------------------------  
  function UnselectAllPoints()   -- native action works with selected envelope only
    for i = 1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0, i-1)
      
      -- clear track envelope points
      for env_id = 1, reaper.CountTrackEnvelopes(track) do          
        local tr_env = reaper.GetTrackEnvelope(track, env_id-1)
        for point_id = 1, reaper.CountEnvelopePoints(tr_env) do Unset(tr_env, point_id-1) end
      end  
      
      -- clear take env
      for j = 1,  reaper.CountTrackMediaItems( track ) do
        local item = reaper.GetTrackMediaItem( track, j-1 )
        for k = 1, reaper.CountTakes(item) do
          local take = reaper.GetTake(item, k-1)
          for env_id = 1, reaper.CountTakeEnvelopes(take) do 
            local take_env = reaper.GetTakeEnvelope(take, env_id-1)
            for point_id = 1, reaper.CountEnvelopePoints(take_env) do Unset(take_env, point_id-1) end
          end
        end
      end          
      
      -- clear fx env
      for fx_id = 1, reaper.TrackFX_GetCount( track ) do
        for par_id = 1,  reaper.TrackFX_GetNumParams( track, fx_id-1 ) do
          local fx_env = reaper.GetFXEnvelope( track, fx_id-1, par_id-1, false )
          if fx_env then 
            for point_id = 1, reaper.CountEnvelopePoints(fx_env) do Unset(fx_env, point_id-1) end  
          end      
        end
      end
      
    end 
  end
  
---------------------------------------------------------------------
  function GetSelPoints()   
    local EP = {}
    --[[ track envelopes
    for i = 1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0, i-1)
      
      
      -- Expected: CountTrackEnvelopes / GetTrackEnvelope() should NOT include FX envelopes      
      for env_id = 1, reaper.CountTrackEnvelopes(track) do          
        local tr_env = reaper.GetTrackEnvelope(track, env_id-1)         
        
        
        for point_id = 1, reaper.CountEnvelopePoints(tr_env) do    
          local _, pnt_pos, pnt_value, pnt_shape, pnt_tension, selected = reaper.GetEnvelopePoint(tr_env, point_id-1)
          if selected then                  
            EP[#EP+1] = {
              parent = 0, -- track envelope
              guid = reaper.BR_GetMediaTrackGUID(track),
              env_id = env_id-1,
              pnt_id = point_id, 
              pnt_pos = pnt_pos, 
              pnt_value = pnt_value, 
              pnt_shape = pnt_shape, 
              pnt_tension = pnt_tension
              } 
          end
        end 
      end  
    end]]
    
    -- take envelopes
    for i = 1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0, i-1)
      for j = 1,  reaper.CountTrackMediaItems( track ) do
        local item = reaper.GetTrackMediaItem( track, j-1 )
        for k = 1, reaper.CountTakes(item) do
          local take = reaper.GetTake(item, k-1)
          for env_id = 1, reaper.CountTakeEnvelopes(take) do 
            local take_env = reaper.GetTakeEnvelope(take, env_id-1)
            for point_id = 1, reaper.CountEnvelopePoints(take_env) do    
              local _, pnt_pos, pnt_value, pnt_shape, pnt_tension, selected = reaper.GetEnvelopePoint(take_env, point_id-1)
              if selected then                  
                EP[#EP+1] = {
                    parent = 1, -- take envelope
                    guid = reaper.BR_GetMediaItemTakeGUID(take),
                    env_id = env_id-1,
                    pnt_id = point_id, 
                    pnt_pos = pnt_pos, 
                    pnt_value = pnt_value, 
                    pnt_shape = pnt_shape, 
                    pnt_tension = pnt_tension
                  } 
              end
            end
          end
        end
      end  
    end
      
    -- get FX env points
    for i = 1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0, i-1)
      for fx_id = 1, reaper.TrackFX_GetCount( track ) do
        for par_id = 1,  reaper.TrackFX_GetNumParams( track, fx_id-1 ) do
          local fx_env = reaper.GetFXEnvelope( track, fx_id-1, par_id-1, false )
          if fx_env then
            for point_id = 1, reaper.CountEnvelopePoints(fx_env) do    
              local _, pnt_pos, pnt_value, pnt_shape, pnt_tension, selected = reaper.GetEnvelopePoint(fx_env, point_id-1)
              if selected then                  
                EP[#EP+1] = {
                  parent = 2, -- fx envelope
                  guid = reaper.BR_GetMediaTrackGUID(track),
                  fx_id = fx_id-1,
                  par_id = par_id-1,
                  pnt_id = point_id, 
                  pnt_pos = pnt_pos, 
                  pnt_value = pnt_value, 
                  pnt_shape = pnt_shape, 
                  pnt_tension = pnt_tension
                  } 
              end
            end
          end         
        end
      end
    end

    
    return EP
  end
----------------------------------------------------------------------  
  function msg(s) reaper.ShowConsoleMsg(s..'\n') end
----------------------------------------------------------------------   
  function GetValue(ep_t) -- get difference beetween first and last point in env.points table
    if not ep_t or #ep_t < 2 then return end
    local max_v = 0
    local min_v = math.huge
    for i = 1, #ep_t do
      max_v = math.max (max_v, ep_t[i].pnt_pos)
      min_v = math.min (min_v, ep_t[i].pnt_pos)
    end
    return max_v - min_v
  end
----------------------------------------------------------------------  
  function GetSR()
    local time_smpl = reaper.format_timestr_len( 1, '', 0, 4 )
    local SR = math.ceil(time_smpl)
    return SR
  end
----------------------------------------------------------------------
  function DuplicatePoints(ep_t, val_sec, SR)
    if not val_sec then return end
    UnselectAllPoints()
    for i = 1, #ep_t do
      if ep_t[i].parent == 0 then  -- track envelope point
        local track = reaper.BR_GetMediaTrackByGUID( 0, ep_t[i].guid )
        local envelope =  reaper.GetTrackEnvelope( track, ep_t[i].env_id )  
        ReplaceAdd(envelope, ep_t[i], val_sec)
        
       elseif ep_t[i].parent == 1 then -- take envelope
        local take =  reaper.GetMediaItemTakeByGUID( 0, ep_t[i].guid )
        local envelope =  reaper.GetTakeEnvelope( take, ep_t[i].env_id )  
        ReplaceAdd(envelope, ep_t[i], val_sec)
          
       elseif ep_t[i].parent == 2 then  -- fx envelope
        local track = reaper.BR_GetMediaTrackByGUID( 0, ep_t[i].guid )
        local envelope =   reaper.GetFXEnvelope( track, ep_t[i].fx_id, ep_t[i].par_id, false )
        ReplaceAdd(envelope, ep_t[i], val_sec)
             
      end
    end
    reaper.UpdateArrange()
  end
  -----------------------------------------------------------------------------------
  function ReplaceAdd(envelope, t, val_sec)
    local test_point_id = reaper.GetEnvelopePointByTime( envelope, t.pnt_pos + val_sec) 
    local _, test_time, value, shape, tension, selected = reaper.GetEnvelopePoint( envelope, test_point_id )
    if test_time > 0 and t.pnt_pos + val_sec == test_time then -- do move back older point
      local time_smpl = reaper.format_timestr_len( test_time, '', 0, 4 )
      local new_time_smpl = time_smpl - 1
      local new_time_sec = new_time_smpl  / SR   
      reaper.SetEnvelopePoint( envelope, test_point_id, new_time_sec, value, shape, tension, false, false )  
      reaper.InsertEnvelopePoint( envelope, 
            t.pnt_pos + val_sec, --time, 
            t.pnt_value, 
            t.pnt_shape, 
            t.pnt_tension, 
            true, --selected, 
            false)--noSortInOptional )   
     else
      reaper.InsertEnvelopePoint( envelope, 
            t.pnt_pos + val_sec, --time, 
            t.pnt_value, 
            t.pnt_shape, 
            t.pnt_tension, 
            true, --selected, 
            false)--noSortInOptional )
    end  
  end
  -----------------------------------------------------------------------------------
  reaper.Undo_BeginBlock()
  
  ep = GetSelPoints()  -- get points
  val_sec = GetValue(ep)  -- get difference
  SR = GetSR()  -- get sample rate
  DuplicatePoints(ep, val_sec, SR)  -- duplicat
  
  reaper.Undo_EndBlock('mpl_Duplicate envelope points', 0)
