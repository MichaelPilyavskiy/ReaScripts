-- @description Duplicate envelope points
-- @version 1.06
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
  DATA2 = {}
  
  function DATA2:UnselectAllPoints_Unset(env, id)
    local _, pnt_pos, pnt_value, pnt_shape, pnt_tension, selected = reaper.GetEnvelopePoint(env, id)
    reaper.SetEnvelopePoint( env, id, pnt_pos, pnt_value, pnt_shape, pnt_tension, false, false ) 
  end
  ----------------------------------------------------------------------  
  function DATA2:UnselectAllPoints()   -- native action works with selected envelope only
    for i = 1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0, i-1)
      
      -- clear track envelope points
      for env_id = 1, reaper.CountTrackEnvelopes(track) do          
        local tr_env = reaper.GetTrackEnvelope(track, env_id-1)
        for point_id = 1, reaper.CountEnvelopePoints(tr_env) do DATA2:UnselectAllPoints_Unset(tr_env, point_id-1) end
      end  
      
      -- clear take env
      for j = 1,  reaper.CountTrackMediaItems( track ) do
        local item = reaper.GetTrackMediaItem( track, j-1 )
        for k = 1, reaper.CountTakes(item) do
          local take = reaper.GetTake(item, k-1)
          for env_id = 1, reaper.CountTakeEnvelopes(take) do 
            local take_env = reaper.GetTakeEnvelope(take, env_id-1)
            for point_id = 1, reaper.CountEnvelopePoints(take_env) do DATA2:UnselectAllPoints_Unset(take_env, point_id-1) end
          end
        end
      end          
      
      -- clear fx env
      for fx_id = 1, reaper.TrackFX_GetCount( track ) do
        for par_id = 1,  reaper.TrackFX_GetNumParams( track, fx_id-1 ) do
          local fx_env = reaper.GetFXEnvelope( track, fx_id-1, par_id-1, false )
          if fx_env then 
            for point_id = 1, reaper.CountEnvelopePoints(fx_env) do DATA2:UnselectAllPoints_Unset(fx_env, point_id-1) end  
          end      
        end
      end
      
    end 
  end
  
---------------------------------------------------------------------
  function DATA2:GetSelectedPoints()   
    DATA2.EP = {}
    -- track envelopes
    for i = 1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0, i-1)
      
         
      for env_id = 1, reaper.CountTrackEnvelopes(track) do          
        local tr_env = reaper.GetTrackEnvelope(track, env_id-1)         
        _, fxID, parID = reaper.Envelope_GetParentTrack(tr_env)
        for point_id = 1, reaper.CountEnvelopePoints(tr_env) do    
          local _, pnt_pos, pnt_value, pnt_shape, pnt_tension, selected = reaper.GetEnvelopePoint(tr_env, point_id-1)
          if selected then                  
            DATA2.EP[#DATA2.EP+1] = {
                parent = 0, -- track envelope
                guid = GetTrackGUID(track),
                env_id = env_id-1,
                pnt_id = point_id, 
                pnt_pos = pnt_pos, 
                pnt_value = pnt_value, 
                pnt_shape = pnt_shape, 
                pnt_tension = pnt_tension,
                fx_id = fxID,
                par_id = parID,
                } 
          end
        end 
      end  
    end
    
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
                item_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )    
                local retval, takeGUID = reaper.GetSetMediaItemTakeInfo_String( take, 'GUID', '', false )
                DATA2.EP[#DATA2.EP+1] = {
                    parent = 1, -- take envelope
                    guid =takeGUID,
                    env_id = env_id-1,
                    pnt_id = point_id-1, 
                    pnt_pos = pnt_pos + item_pos,
                    item_pos = item_pos, 
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

  end
----------------------------------------------------------------------   
  function  DATA2:GetBoundaryDiff() -- get difference beetween first and last point in env.points table
    if not DATA2.EP or #DATA2.EP < 2 then return end
    local max_v = 0
    local min_v = math.huge
    for i = 1, #DATA2.EP do
      max_v = math.max (max_v, DATA2.EP[i].pnt_pos)
      min_v = math.min (min_v, DATA2.EP[i].pnt_pos)
    end
    DATA2.diff = max_v - min_v
  end

----------------------------------------------------------------------
  function DATA2:DuplicatePoints()
    if not DATA2.diff then return end
    
    for i = 1, #DATA2.EP do
      if DATA2.EP[i].parent == 0 then  -- track envelope point
        local track = VF_GetTrackByGUID( DATA2.EP[i].guid )
        local envelope =  reaper.GetTrackEnvelope( track, DATA2.EP[i].env_id )
        if DATA2.EP[i].par_id >= 0 then  
          local envelope = reaper.GetFXEnvelope( track, DATA2.EP[i].fx_id, DATA2.EP[i].par_id, false )
          DATA2:ReplaceAdd(envelope, DATA2.EP[i])
         else
          -- volume pan width
          DATA2:ReplaceAdd(envelope, DATA2.EP[i])
        end
         
        
       elseif DATA2.EP[i].parent == 1 then -- take envelope
        local take =  reaper.GetMediaItemTakeByGUID( 0, DATA2.EP[i].guid )
        local envelope =  reaper.GetTakeEnvelope( take, DATA2.EP[i].env_id )  
        DATA2:ReplaceAdd(envelope, DATA2.EP[i], DATA2.diff)
          
       elseif DATA2.EP[i].parent == 2 then  -- fx envelope
        local track = VF_GetTrackByGUID( DATA2.EP[i].guid )
        
             
      end
    end
    reaper.UpdateArrange()
  end
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  -----------------------------------------------------------------------------------
  function DATA2:ReplaceAdd(envelope, t)
    local test_point_id = reaper.GetEnvelopePointByTime( envelope, t.pnt_pos + DATA2.diff) 
    local _, test_time, value, shape, tension, selected = reaper.GetEnvelopePoint( envelope, test_point_id )
      if  t.parent == 1 then 
        pnt_pos = t.pnt_pos + DATA2.diff - t.item_pos
       else 
        pnt_pos = t.pnt_pos + DATA2.diff 
      end
      
    if test_time > 0 and pnt_pos == test_time then -- do move back older point
      local time_smpl = reaper.format_timestr_len( test_time, '', 0, 4 )
      local new_time_smpl = time_smpl - 1
      local new_time_sec = new_time_smpl  / DATA2.SR   
      reaper.SetEnvelopePoint( envelope, test_point_id, new_time_sec, value, shape, tension, false, false )  
        
      reaper.InsertEnvelopePoint( envelope, 
            pnt_pos, --time, 
            t.pnt_value, 
            t.pnt_shape, 
            t.pnt_tension, 
            true, --selected, 
            false)--noSortInOptional )   
     else
      reaper.InsertEnvelopePoint( envelope, 
            pnt_pos, --time, 
            t.pnt_value, 
            t.pnt_shape, 
            t.pnt_tension, 
            true, --selected, 
            false)--noSortInOptional )
    end  
  end
  -----------------------------------------------------
  function VF_GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
  -----------------------------------------------------------------------------------

  function main() 
    DATA2:GetSelectedPoints()  -- get points
    DATA2:GetBoundaryDiff()  -- get difference
    DATA2.SR = VF_GetProjectSampleRate()  -- get sample rate
    DATA2:UnselectAllPoints()
    DATA2:DuplicatePoints()  -- duplicate
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(6,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Duplicate envelope points', 0xFFFFFFFF )
  end 