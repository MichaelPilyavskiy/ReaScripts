-- @description Duplicate envelope points
-- @version 1.0
-- @author mpl
-- @changelog
--    + init
-- @website http://forum.cockos.com/member.php?u=70694

---------------------------------------------------------------------
  function GetSelPoints()   
    local EP = {}
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
                    pnt_id = pnt_id, 
                    pnt_pos = pnt_pos, 
                    pnt_value = pnt_value, 
                    pnt_shape = pnt_shape, 
                    pnt_tension = pnt_tension
                  } 
              end
            end         
          end
        end
        -- trackenvelopespoint
        for env_id = 1, reaper.CountTrackEnvelopes(track) do 
          local tr_env = reaper.GetTrackEnvelope(track, env_id-1) 
          for point_id = 1, reaper.CountEnvelopePoints(tr_env) do    
            local _, pnt_pos, pnt_value, pnt_shape, pnt_tension, selected = reaper.GetEnvelopePoint(tr_env, point_id-1)
            if selected then                  
              EP[#EP+1] = {
                  parent = 0, -- track envelope
                  guid = reaper.BR_GetMediaTrackGUID(track),
                  env_id = env_id-1,
                  pnt_id = pnt_id, 
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
    reaper.Main_OnCommand(40331, 0) -- unselect all points
    for i = 1, #ep_t do
      if ep_t[i].parent == 0 then  -- track envelope point
        local track = reaper.BR_GetMediaTrackByGUID( 0, ep_t[i].guid )
        local envelope =  reaper.GetTrackEnvelope( track, ep_t[i].env_id )  
        local test_point_id = reaper.GetEnvelopePointByTime( envelope, ep_t[i].pnt_pos + val_sec) 
        local _, test_time, value, shape, tension, selected = reaper.GetEnvelopePoint( envelope, test_point_id )
        if test_time > 0 and ep_t[i].pnt_pos == test_time then -- do move back older point
          local time_smpl = reaper.format_timestr_len( test_time, '', 0, 4 )
          local new_time_smpl = time_smpl + 1
          local new_time_sec = new_time_smpl  / SR   
          reaper.SetEnvelopePoint( envelope, test_point_id, new_time_sec, value, shape, tension, true, false )  
          reaper.InsertEnvelopePoint( envelope, 
            ep_t[i].pnt_pos + val_sec, --time, 
            ep_t[i].pnt_value, 
            ep_t[i].pnt_shape, 
            ep_t[i].pnt_tension, 
            true, --selected, 
            false)--noSortInOptional )   
         else
          reaper.InsertEnvelopePoint( envelope, 
            ep_t[i].pnt_pos + val_sec, --time, 
            ep_t[i].pnt_value, 
            ep_t[i].pnt_shape, 
            ep_t[i].pnt_tension, 
            true, --selected, 
            false)--noSortInOptional )
        end
        
      end
    end
    reaper.UpdateArrange()
  end
----------------------------------------------------------------------  

  reaper.Undo_BeginBlock()
  ep = GetSelPoints()
  val_sec = GetValue(ep)
  local SR = GetSR()
  DuplicatePoints(ep, val_sec, SR)
  reaper.Undo_EndBlock('mpl_Duplicate envelope points', 0)
