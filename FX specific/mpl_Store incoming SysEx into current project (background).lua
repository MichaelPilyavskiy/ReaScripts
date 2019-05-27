-- @description Store incoming SysEx into current project (background)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init, mpl_SysEx_Tracker.jsfx must be installed

  function StoreSysEx()
    local datastr_len = gmem_read(3) -- data string length
    if datastr_len >=3 then  
      out_msg = '' 
      local offs = 10
      for i = offs, offs+datastr_len-1 do
        --out_msg = out_msg..string.char(math.floor(gmem_read(i)))
        out_msg = out_msg .. ' '.. string.format("%.2X", math.floor(gmem_read(i)))
      end
      SetProjExtState( 0, 'MPL_SysExData', 'SLOT1', out_msg:sub(2) )
    end
  end
  ---------------------------------------------------------------------
  function main()
    local check_data = gmem_read(1) -- has any data
    local msg_TS = gmem_read(2) -- timestamp
    if check_data == 1 then 
      local cur_TS =os.time()
      if cur_TS - msg_TS < 0.1 then
        local ret = MB('Save SysEx to project?', 'mpl_Store incoming SysEx', 3)
        if ret == 6 then
          StoreSysEx()
        end
      end 
    end

    defer(main)
  end
  ---------------------------------------------------------------------
  function SetButton(val0)
    local is_new_value, filename, sec, cmd, mode, resolution, val = get_action_context()
    --state = reaper.GetToggleCommandStateEx( sec, cmd ) 
    if not val0 then val0 = 0 end
    SetToggleCommandState( sec, cmd, val0 )
    RefreshToolbar2( sec, cmd )
  end 
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end 
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    gmem_attach('MPL_SysExTracker')
    SetButton(1)
    main() 
    atexit( SetButton )  
  end