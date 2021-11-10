-- @description Convert CUE file into markers (DDP formatted)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  function main(scrname)
    local retval, fp =  GetUserFileNameForRead('', scrname or '', '.cue' )
    if not retval then return end
    -- check file
      local f = io.open(fp, 'r')
      if not f then return end
      content = f:read('a')
      f:close()
    -- collect content
      local t, id = {}, 0
      for data in content:gmatch('[^\r\n]+') do 
        if data:find('TRACK') then id = id +1 end
        if not t[id] then t[id] = '' end
        t[id] = t[id]..data 
      end
    -- parse data
      regt = {}
      for i = 1, #t do
        local time = t[i]:match('INDEX [%d]+ ([%d%p]+)')
        local pos = 0
        if time:match('[%d]+%:[%d]+%:[%d]+') then
          pos = time:match('([%d]+)%:[%d]+%:[%d]+')*60 + time:match('[%d]+%:([%d]+)%:[%d]+') + time:match('[%d]+%:[%d]+%:([%d]+)')/100
        end
        regt[i] = {TITLE = t[i]:match('TITLE "(.-)"'),
                   PERFORMER = t[i]:match('PERFORMER "(.-)"'), 
                   SONGWRITER = t[i]:match('SONGWRITER "(.-)"'), 
                   ISRC = t[i]:match('ISRC%s+([%d%a]+)'), 
                   pos = pos}
      end
    --  add markers
      for i = 1, #regt do 
        local name = '#'..regt[i].TITLE
        if regt[i].PERFORMER then name=name..'|PERFORMER='..regt[i].PERFORMER end
        if regt[i].SONGWRITER then name=name..'|SONGWRITER='..regt[i].SONGWRITER end
        if regt[i].ISRC then name=name..'|ISRC='..regt[i].ISRC end
        AddProjectMarker( 0, false, regt[i].pos, -1,name, -1 )  
      end
      UpdateTimeline()
  end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  scrname = 'Convert CUE file into markers (DDP formatted)'
  local ret = VF_CheckFunctions(2.5) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then reaper.Undo_BeginBlock() main(scrname) reaper.Undo_EndBlock(scrname, 0) end end