-- @description Toggle soft pseudo bypass focused FX
-- @version 1.0.1
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   + Time based counter incrementation variable

time = 0.5 -- time in seconds

  com_incr = 1 / (time * 32) -- assuming 32hZ is about the standard defer rate, even
------------------------------------------------------------------ ---
---------------------------------------------------------------------
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
    function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then
      main()
    end    
