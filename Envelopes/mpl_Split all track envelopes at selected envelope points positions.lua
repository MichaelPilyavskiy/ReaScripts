-- @description Split all track envelopes at selected envelope points positions
-- @version 1.0
-- @author MPL 
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init



  function main()
    local tr_env = GetSelectedEnvelope( 0 )
    if not (tr_env and ValidatePtr2( 0, tr_env, 'TrackEnvelope*')) then return end
    local track = Envelope_GetParentTrack( tr_env )
    
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
          local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint( tr_env_child, pt_idx )
          pt_far = math.abs(time - point_t[i]) > (10^-13)
          if pt_far and shape == 0 then -- linear
            local retval, value = Envelope_Evaluate( tr_env_child, point_t[i], 1, 1 ) 
            InsertEnvelopePoint( tr_env_child, point_t[i], value, -1, -1, false, true )
           elseif pt_far and shape == 1 then -- square
            local retval, value = Envelope_Evaluate( tr_env_child, point_t[i], 1, 1 ) 
            InsertEnvelopePoint( tr_env_child, point_t[i], value, shape, -1, false, true )  
           elseif pt_far and shape >= 2 then -- slow startend
            local retval, value = Envelope_Evaluate( tr_env_child, point_t[i], 1, 1 ) 
            InsertEnvelopePoint( tr_env_child, point_t[i], value, 0, -1, false, true )            
          end
        end 
        reaper.Envelope_SortPoints( tr_env_child )
      end 
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Install it via Reapack (Action: browse packages)', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_LoadVFv2') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then 
      Undo_BeginBlock2( 0 )
      main() 
      UpdateArrange()
      Undo_EndBlock2( 0, 'Split all track envelopes at selected envelope points positions', -1 )
    end
  end
  