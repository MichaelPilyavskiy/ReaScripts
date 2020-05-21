-- @description Show and arm envelopes with learn and parameter modulation for selected tracks (LearnEditor)
-- @version 1.0
-- @author MPL
-- @noindex
-- @website http://forum.cockos.com/showthread.php?t=235521
-- @changelog
--    + init


  local vrs = 'v1.0'
  
  --NOT gfx NOT reaper

 --  INIT -------------------------------------------------
  data = {}
  conf= {mb_title = 'LearnEditor'}
  --local obj = {touched_log={}}
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------
  function main()
    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_LearnEditor_data.lua") 
    Data_ParseDefMap(conf, obj, data, refresh, mouse)
    DataReadProject(conf, obj, data, refresh, mouse)
    Data_Actions_SHOWARMENV(conf, obj, data, refresh, mouse, 'Show and arm envelopes with learn and parameter modulation for selected tracks', true)
  end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end
  end
