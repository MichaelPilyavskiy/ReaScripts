-- @description Retrospective record of focused FX parameter tweaks - log (background)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


  local fpath = reaper.GetResourcePath()..'/mpl_FXRetrospectiveLog.txt'
  history = {}
  ----------------------------------------------------------------------
  function StoreRRL(fxGUID, srct, curt)
    local ts = math.floor(os.clock()*1000)/1000
    local playpos
    if GetPlayStateEx( 0 )&1==1 then playpos = GetPlayPosition() end
    for i = 1, #srct do
      if srct[i] ~= curt[i] then
        history[#history + 1] = {ts = ts, fxGUID = fxGUID, paramid = i-1, val = curt[i], playpos=playpos}
      end
    end
  end
  ----------------------------------------------------------------------
  function main()
    isclear = reaper.gmem_read(1 )
    if math.floor(isclear)==1 then history = {} reaper.gmem_write(1,0 ) end
    
    if not last_pscc then last_pscc = -1 end
    pscc = reaper.GetProjectStateChangeCount( 0 )
    if last_pscc ~= pscc then trigger_save = true table.save(history, fpath) end
    last_pscc = pscc
    
    retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX2()
    if retval&1==1 
      and retval&4~=4 
      and (last_tracknumber and last_tracknumber == tracknumber)
      and (last_fxnumber and last_fxnumber == fxnumber)
     then
      local tr = CSurf_TrackFromID( tracknumber, false )
      local params =  TrackFX_GetNumParams( tr, fxnumber )
      local fxGUID = TrackFX_GetFXGUID( tr, fxnumber)
      local hashsum = 0
      param_t = {}
      for  param = 1, params do
        local val, minval, maxval = reaper.TrackFX_GetParam( tr, fxnumber, param-1)
        param_t[ param] = val
        hashsum=hashsum + val
      end
      
      if last_hashsum and last_hashsum ~= hashsum and last_param_t and last_param_t ~= param_t then
        StoreRRL(fxGUID, last_param_t, param_t)
      end
      last_hashsum = hashsum
      last_param_t= param_t
     else
      last_hashsum = nil
      last_param_t = nil
    end
    last_tracknumber = tracknumber
    last_fxnumber = fxnumber
    trigger_save = false
    defer(main)
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.03) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) 
  if ret2 then
    gmem_attach('mpl_retrospectrec' ) 
    main() 
  end end