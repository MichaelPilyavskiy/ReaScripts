-- @description Propagate pooled FX master parameters to all slaves (group 1)
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=236979
-- @noindex
-- @changelog
--    + init

  groupID = 1
  
  --NOT gfx NOT reaper
  function ValidatePoolFXOrder(dest_track, jsfx_id, fx_data)
    local cnt_fx = TrackFX_GetCount( dest_track )
    for fx = jsfx_id+1, jsfx_id+#fx_data do 
      local retval, fxname = TrackFX_GetFXName( dest_track, fx, '' )
      if not fxname:match(literalize(fx_data[fx-jsfx_id].fxname)) then return end
    end
    return true
  end
 ---------------------------------------------------------------------  
  function PropagatePoolFX_state(dest_track, src_track, jsfx_id, fx_data)
    local ret = ValidatePoolFXOrder(dest_track, jsfx_id, fx_data)
    if not ret then return end
    
    for i = 1, #fx_data do
      for paramnumber = 1, TrackFX_GetNumParams(  dest_track, i+jsfx_id)-1 do 
        TrackFX_SetParam( dest_track, i+jsfx_id, paramnumber-1,fx_data[i].params[paramnumber]) 
      end
    end
  end
 ---------------------------------------------------------------------
  function GetSlaveJSFXid(track, group)
    for fx = 1,  TrackFX_GetCount( track ) do 
      local retval, fxname = TrackFX_GetFXName( track, fx-1, '' )
      if fxname:match('POOL FX slave')and math.floor(TrackFX_GetParamNormalized( track, fx-1, 0 )*7) == group-1 then return  fx-1 end
    end
  end
  ---------------------------------------------------------------------
  function main(groupID)
    -- find master
      local src_track
      local mastername = 'POOL FX'..groupID..' master'
      for i = 1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        local retval, trname = GetSetMediaTrackInfo_String( track, 'P_NAME', '', 0 )
        if trname == mastername then src_track = track break end
      end
      if not src_track then MB('Track called "'..mastername..'" not found', 'Pooled FX tools', 0) return end
    
    -- collect fx data
      local fx_data = {}
      for fx = 1,  TrackFX_GetCount( src_track ) do
        local retval, fxname = TrackFX_GetFXName( src_track, fx-1, '' )
        local params ={} 
        for paramnumber = 1, TrackFX_GetNumParams(  src_track, fx-1) do params[#params+1] = TrackFX_GetParam( src_track, fx-1, paramnumber-1) end
        fx_data[#fx_data+1] = {fxname=fxname,
                              params=params}
      end  
      
    -- loop through tracks
      for i = 1, CountTracks(0) do 
        local track = GetTrack(0,i-1)
        if track ~= src_track then
          local jsfx_id = GetSlaveJSFXid(track, groupID) --local jsfx_id= TrackFX_AddByName( track, 'POOL FX slave.jsfx', false, 0 ) 
          if jsfx_id and jsfx_id >= 0 then PropagatePoolFX_state(track, src_track, jsfx_id, fx_data) end 
        end
      end    
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then  
      Undo_BeginBlock()
      main(groupID)
      Undo_EndBlock( 'Propagate pooled FX master parameters to all pooled FX slaves (group 1)', -1 )
    end
  end
  