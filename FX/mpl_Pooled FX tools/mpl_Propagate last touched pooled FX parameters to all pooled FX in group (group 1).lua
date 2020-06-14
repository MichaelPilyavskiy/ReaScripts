-- @description Propagate last touched pooled FX parameters to all pooled FX in group (group 1)
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=236979
-- @noindex
-- @changelog
--    # fix error

  groupID = 1
  
  --NOT gfx NOT reaper
  ---------------------------------------------------------------------  
  function CollectFXData(src_track,pool_state,jsfx_id, fx_data0)
    local fx_data = {}
    if pool_state == 1 then
      for fx = 1,  TrackFX_GetCount( src_track ) do
        local retval, fxname = TrackFX_GetFXName( src_track, fx-1, '' )
        local params ={} 
        for paramnumber = 1, TrackFX_GetNumParams(  src_track, fx-1) do params[#params+1] = TrackFX_GetParam( src_track, fx-1, paramnumber-1) end
        fx_data[#fx_data+1] = {fxname=fxname,
                              params=params}
      end 
     elseif pool_state == 2 then
      for fx = jsfx_id+2,  jsfx_id +1+#fx_data0 do
        local retval, fxname = TrackFX_GetFXName( src_track, fx-1, '' )
        local params ={} 
        for paramnumber = 1, TrackFX_GetNumParams(  src_track, fx-1) do params[#params+1] = TrackFX_GetParam( src_track, fx-1, paramnumber-1) end
        fx_data[#fx_data+1] = {fxname=fxname,
                              params=params}
      end       
    end
    return fx_data
  end
 ---------------------------------------------------------------------    
  function ValidatePoolFXOrder(dest_track, jsfx_id, fx_data)
    local cnt_fx = TrackFX_GetCount( dest_track )
    for fx = jsfx_id+1, jsfx_id+#fx_data do 
      local retval, fxname = TrackFX_GetFXName( dest_track, fx, '' )
      if not fxname:match(literalize(fx_data[fx-jsfx_id].fxname)) then return end
    end
    return true
  end
 ---------------------------------------------------------------------  
  function PropagatePoolFX_state(dest_track, fx_data, groupID, fx_data0) 
    local jsfx_id = GetSlaveJSFXid(dest_track, groupID) 
    if jsfx_id then 
      local ret = ValidatePoolFXOrder(dest_track, jsfx_id, fx_data0)
      if not ret then return end
      for i = 1, #fx_data do
        for paramnumber = 1, TrackFX_GetNumParams(  dest_track, i+jsfx_id)-1 do 
          TrackFX_SetParam( dest_track, i+jsfx_id, paramnumber-1,fx_data[i].params[paramnumber]) 
        end
      end
     else
      for i = 1, #fx_data do
        for paramnumber = 1, TrackFX_GetNumParams(  dest_track, i-1)-1 do 
          if fx_data[i].params[paramnumber] then  TrackFX_SetParam( dest_track, i-1, paramnumber-1,fx_data[i].params[paramnumber])  end
        end
      end      
    end
    
    
  end
 ---------------------------------------------------------------------
  function GetSlaveJSFXid(track, group)
    for fx = 1,  TrackFX_GetCount( track ) do 
      local retval, fxname = TrackFX_GetFXName( track, fx-1, '' )
      if fxname:match('POOL FX slave')and math.floor(TrackFX_GetParamNormalized( track, fx-1, 0 )*7) == group-1 then  return  fx-1 end
    end
  end
  ---------------------------------------------------------------------
  function GetPoolState(groupID)
    -- get src track
      local jsfx_id
      local pool_state = 0 -- 1 master 2 slave
      local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
      local track = GetTrack(0,tracknumber-1) if tracknumber == 0 then track = GetMasterTrack( 0 ) end
      if not track then return end
      local mastername = 'POOL FX'..groupID..' master'    
      local retval, trname = GetSetMediaTrackInfo_String( track, 'P_NAME', '', 0 )
      if trname == mastername then pool_state = 1 end
      if pool_state == 0 then 
         jsfx_id = GetSlaveJSFXid(track, groupID)
        if jsfx_id >= 0 then pool_state = 2 end
      end
      if pool_state == 0 then return end
    return true, track, pool_state, jsfx_id
  end
  ---------------------------------------------------------------------
  function FindPoolmaster(groupID)
      local src_track
      local mastername = 'POOL FX'..groupID..' master'
      for i = 1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        local retval, trname = GetSetMediaTrackInfo_String( track, 'P_NAME', '', 0 )
        if trname == mastername then src_track = track break end
      end
      if not src_track then MB('Track called "'..mastername..'" not found', 'Pooled FX tools', 0) return end
    return true, src_track
  end
  ---------------------------------------------------------------------
  function main(groupID)
    local ret_master, master_track = FindPoolmaster(groupID)
    if not ret_master then return end
    local fx_data0 = CollectFXData(master_track,1)
    --local fx_data
    local ret, src_track, pool_state, jsfx_id = GetPoolState(groupID)
    if pool_state == 0 then 
      MB('Last touched FX is not pooled', 'Pooled FX tools', 0)
      return 
     elseif pool_state == 1 then fx_data = CopyTable(fx_data0)
     elseif pool_state == 2 then 
      local ret_valid_slave_order = ValidatePoolFXOrder(src_track, jsfx_id, fx_data0)
      if not ret_valid_slave_order then 
        MB('Slave pooled FX track doesn`t have pools in right order, use Script: mpl_Propagate pooled FX.lua to fix FX order', 'Pooled FX tools', 0)
        return 
      end
      fx_data = CollectFXData(src_track,2,jsfx_id, fx_data0)
    end
    
    
      
    -- loop through tracks
      for i = 1, CountTracks(0) do 
        local track = GetTrack(0,i-1)
        if track ~= src_track then PropagatePoolFX_state(track, fx_data, groupID, fx_data0) end
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
      Undo_EndBlock( 'Propagate last touched pooled FX parameters to all pooled FX in group (group 1)', -1 )
    end
  end
  