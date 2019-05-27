-- @description Store project linked SysEx data to SYX file into project folder
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  function main()
    local ret, str = GetProjExtState( 0, 'MPL_SysExData', 'SLOT1', '' )
    if ret == 1 then 
      local hex_t = {}
      for hex in str:gmatch('[^%s]+') do if tonumber(hex,16 ) then  hex_t[#hex_t+1] = tonumber(hex,16 ) end end
      local SysEx_msg = string.char(table.unpack(hex_t))
      local retval, projfn = reaper.EnumProjects( -1, '' )
      if projfn ~= '' then
        projfn = GetParentFolder(projfn)
        f = io.open(projfn..'/SysEx data.syx', 'w')
        if f then 
          f:write(SysEx_msg)
          f:close()
        end
      end
      --msg(SysEx_msg)
      --StuffMIDIMessage( 0, SysEx_msg)
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