-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description List next sample in directory for RS5k on selected track
-- @changelog
--    # fix version check
--    + Support wrap
--    + Use native API instead chunking, require REAPER 6.37+

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  local script_title = 'List next sample for RS5k on selected track'
  -------------------------------------------------------------------------------  
  function GetRS5K_FXid(track) 
    local cnt = TrackFX_GetCount( track )
    for pos = 1, cnt do
      local ret, name = TrackFX_GetNamedConfigParm(track, pos-1, "fx_name")
      if name:match('ReaSamplOmatic5000') then return pos-1 end
    end 
    return -1
  end
  -------------------------------------------------------------------------------
  function isvalidmedia(path)
    if not path then return end
    local filename = path:match("([^/\\]+)$") or path 
    local extension = filename:match("%.([^%.]+)$")
    if IsMediaExtension( extension, false ) == true then return true end
  end
  -------------------------------------------------------------------------------
  function splitPath(path)
      path = path:gsub("[/\\]+$", "")
      local parent, name = path:match("^(.*)[/\\]([^/\\]*)$")
      if not parent then
          return "", path
      end
      return parent, name
  end
  -------------------------------------------------------------------------------
  function main(track)
    local rs5k_pos = GetRS5K_FXid(track)
    local ret, fn = reaper.TrackFX_GetNamedConfigParm(track, rs5k_pos, "FILE0")
    if not ret then return end
    local path, cur_file = splitPath(fn)
    
    -- get files list
      local files = {}
      local i = 0
      repeat
      local file = reaper.EnumerateFiles( path, i )
      if isvalidmedia(file)==true then 
        files[#files+1] = file 
      end
      i = i+1
      until file == nil
      table.sort(files, function(a,b) return a<b end )
      
    -- search file list
      local trig_file
      if #files < 2 then return end
      if files[#files] == cur_file then 
        trig_file = path..'/'..files[1] 
       else
        for i = 1, #files do 
          if files[i-1] == cur_file then trig_file = path..'/'..files[i] break end
        end
      end
      if trig_file then 
        reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE0", trig_file)
        reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE", "")
      end
  end
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num = reaper.GetAppVersion() vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then  if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end return else return true end
  end
  
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(6.37,true) then 
    local track = reaper.GetSelectedTrack(-1,0)
    if not track then return end 
    Undo_BeginBlock2( 0 ) 
    main(track)
    Undo_EndBlock2( 0, script_title, 0xFFFFFFFF )
  end 
  