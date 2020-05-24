-- @description Propagate last touched parameter to all pooled FX parameters
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=236979
-- @noindex
-- @changelog
--    + init

  --NOT gfx NOT reaper
  function IsTrackPoolMaster(tr,groupID)
    if not groupID then groupID = '%d+' end
    local ret, tr_name = GetSetMediaTrackInfo_String( tr, 'P_NAME', '', 0 )
    return tr_name:match('POOL FX'..groupID..' master')~=nil, tonumber(tr_name:match('POOL FX(%d+) master'))
  end
  ---------------------------------------------------------------------
  function GetSlaveJSFXid(track, group)
    for fx = 1,  TrackFX_GetCount( track ) do 
      local retval, fxname = TrackFX_GetFXName( track, fx-1, '' )
      if fxname:match('POOL FX slave')and math.floor(TrackFX_GetParamNormalized( track, fx-1, 0 )*7) == group-1 then return  fx-1 end
    end
  end
  ---------------------------------------------------------------------
  function main()
    retval, tracknumber, LTfx, LTparamnumber = GetLastTouchedFX()
    local LTtrack = GetTrack(0,tracknumber-1)
    if tracknumber == 0 then LTtrack =  GetMasterTrack(0) end 
    local param_val = TrackFX_GetParamNormalized( LTtrack, LTfx, LTparamnumber )
    local is_on_master, groupID = IsTrackPoolMaster(LTtrack)
    
    local original_fxname, pool_position
    if is_on_master == true then
       _, original_fxname = TrackFX_GetFXName( LTtrack, LTfx, '' )
       pool_position = LTfx+1
     else
      local _, original_fxname0 = TrackFX_GetFXName( LTtrack, LTfx, '' )
      original_fxname = original_fxname0:match('POOL FX%d+ (.*)')
      if original_fxname then  groupID = tonumber(original_fxname0:match('POOL FX(%d+)')) end
      if groupID then
        local jsfx_id = GetSlaveJSFXid(LTtrack, groupID)
        pool_position = LTfx + jsfx_id
      end
    end
    
    if not (original_fxname and pool_position and groupID) then return end

    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1) 
      if tr~= LTtrack then
        PropagateParam(tr, LTparamnumber, param_val, original_fxname, pool_position, groupID) 
      end
    end
  end
  ---------------------------------------------------------------------
  function PropagateParam(track, paramnumber, param_val, original_fxname, pool_position, groupID) 
    local is_on_master = IsTrackPoolMaster(track, groupID)
    if is_on_master then 
      fxid = pool_position -1
     else
      local jsfx_id = GetSlaveJSFXid(track, groupID)
      fxid = jsfx_id + pool_position
    end
    
    if not fxid then return end
    local _, fxname = TrackFX_GetFXName( track, fxid, '' )
    local is_ID_valid = fxname:match(literalize(original_fxname)) or fxname == original_fxname
    if is_ID_valid then TrackFX_SetParamNormalized( track, fxid, paramnumber,param_val ) end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
      defer(main)
    end
  end
  