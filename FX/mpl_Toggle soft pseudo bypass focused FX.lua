-- @description Toggle soft pseudo bypass focused FX
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
time = 0.5 -- time in seconds

  com_incr = 1 / (time * 32) -- assuming 32hZ is about the standard defer rate, even
------------------------------------------------------------------ ---
  function Ex_Set1(track, fx, wet_id, val)
    
  end   
---------------------------------------------------------------------
  function main() 
    local ret, tracknumberOut, _, fx = GetFocusedFX()
    if not ret or tracknumberOut < 1 or fx < 0 then return end
    
    -- get src info
      local track = CSurf_TrackFromID( tracknumberOut, false )
      local fx_GUID = TrackFX_GetFXGUID( track, fx )
      local wet_id = TrackFX_GetNumParams( track, fx ) -1 
      local wet_val = TrackFX_GetParam( track, fx, wet_id )
      if wet_val ~= 0 then
        SetProjExtState( 0, 'mplsoftbypass', fx_GUID, wet_val )
        
        local  val = wet_val
        function Ex_Set0()
          val = math.max(val - com_incr, 0)
          if val > 0 then
            TrackFX_SetParam( track, fx, wet_id, val )
            defer(Ex_Set0)
           else
            TrackFX_SetParam( track, fx, wet_id, 0 )
          end
        end
        
        Ex_Set0()
        
       else
        local retval, wet_val = GetProjExtState( 0, 'mplsoftbypass', fx_GUID )
        if retval ~= 0 then 
          
          local val = 0
          function Ex_Set1()
            val = math.min(val + com_incr, 1)
            if val < tonumber(wet_val) then
              TrackFX_SetParam( track, fx, wet_id, val )
              defer(Ex_Set1)
             else
              TrackFX_SetParam( track, fx, wet_id, wet_val )
            end
          end
          
          Ex_Set1()
          
        end
      end
      
    
  end
  
  ---------------------------------------------------------------------
    if VF_CheckReaperVrs(5.95,true) then main() end    
