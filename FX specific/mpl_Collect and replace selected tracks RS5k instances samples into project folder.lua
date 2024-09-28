-- @description Collect and replace selected tracks RS5k instances samples into project folder
-- @version 1.07
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix error

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
  local script_title = 'Collect and replace selected tracks RS5k instances samples into project folder'
  --------------------------------------------------------------------- 
  function LuaCopyFile(src, dest)
    local infile,instr = io.open(src, "rb")
    if infile then 
      instr = infile:read("*a")
      infile:close()
     else
      return 
    end 
    local outfile = io.open(dest, "wb")
    if outfile then 
      outfile:write(instr)
      outfile:close()
    end
  end
  --------------------------------------------------------------------- 
  function IsRS5K(tr, fxnumber)
    if not tr then return end
    local retval1, buf = reaper.TrackFX_GetFXName( tr, fxnumber,'' )
    if not retval1 then return end
    local retval2, buf1 = reaper.TrackFX_GetParamName(  tr, fxnumber, 3, '' )
    if not retval2 or buf1~='Note range start' then return end
    return true, tr, fxnumber
  end
  ---------------------------------------------------
  function msg(s) 
    if not s then return end 
    if type(s) == 'boolean' then
      if s then s = 'true' else  s = 'false' end
    end
    ShowConsoleMsg(s..'\n') 
  end 
  ---------------------------------------------------------------------  
  function main()
    local proj_name = reaper.GetProjectName( 0, '' )
    if proj_name == '' then MB('Project has not any parent folder.', 'Collect RS5k samples into project folder', 0) return end
    local spls_path = reaper.GetProjectPathEx( 0, '' )..'/RS5K samples/'
    RecursiveCreateDirectory( spls_path, 0 )
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      for fx = 1,  TrackFX_GetCount( tr) do
        if IsRS5K(tr, fx-1) then
          local retval, file_src = TrackFX_GetNamedConfigParm( tr, fx-1, 'FILE0' )
          file_src_sh = GetShortSmplName(file_src) 
          if file_src_sh then
            file_dest = spls_path..file_src_sh
            file_src = file_src:gsub('\\','/')
            file_dest = file_dest:gsub('\\','/')
            LuaCopyFile(file_src, file_dest)
            msg(file_src..' -> '..file_dest)
            TrackFX_SetNamedConfigParm( tr, fx-1, 'FILE0', file_dest)
          end
        end
      end
    end
    

  end
  ---------------------------------------------------------------------------------------------------------------------
  function GetShortSmplName(path) 
   local fn = path
   fn = fn:gsub('%\\','/')
   if fn then fn = fn:reverse():match('(.-)/') end
   if fn then fn = fn:reverse() end
   return fn
  end  
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock(script_title, 1)
  end  