-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Convert CUE file into markers
-- @changelog
--    +init
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local scr ='Convert CUE file into markers
  ----------------------------------------------------
  function msg(s) 
    if not s then return end 
    ShowConsoleMsg(s..'\n')  
  end
  ----------------------------------------------------
  function main(fp)
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
        regt[i] = {title = t[i]:match('TITLE "(.-)"'),
                   perf = t[i]:match('PERFORMER "(.-)"'), 
                   pos = pos}
      end
    --  add markers
      for i = 1, #regt do AddProjectMarker( 0, false, regt[i].pos, -1, regt[i].perf..' - '..regt[i].title, -1 ) end
      UpdateTimeline()
  end
  retval, fn =  GetUserFileNameForRead('', scr, '.cue' )
  if retval then 
    reaper.Undo_BeginBlock()
    main(fn)
    reaper.Undo_EndBlock(scr, 1)
  end