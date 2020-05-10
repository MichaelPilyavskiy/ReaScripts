-- @description TaskScheduler_data
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  function Data_GetProjectStateChangeCountAll() 
    local cnt = 0
    for idx  = 0, 1000 do
      local retval, projfn0 = reaper.EnumProjects( idx )
      if not retval then return cnt end
      cnt = cnt + GetProjectStateChangeCount( idx )
    end
    return cnt
  end
  ---------------------------------------------------  
  function CheckUpdates(obj, conf, refresh)
  
    -- force by proj change state
      obj.SCC =  Data_GetProjectStateChangeCountAll() 
      if not obj.lastSCC then 
        refresh.GUI_onStart = true  
        refresh.data = true
       elseif obj.lastSCC and obj.lastSCC ~= obj.SCC then 
        --if conf.dev_mode == 1 then msg(obj.SCC..'2') end
        refresh.data = true
        refresh.GUI = true
        refresh.GUI_WF = true
      end 
      obj.lastSCC = obj.SCC
      
    -- window size
      local ret = HasWindXYWHChanged(obj)
      if ret == 1 then 
        refresh.conf = true 
        --refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        --refresh.data = true
      end
  end
  -------------------------------------------------------------
  function DataUpdate(conf, obj, data, refresh, mouse)   
    data.time = os.time()
    data.time_shed_default = data.time + 60*60*24*7 -- week further
    data.date = os.date('%c', data.time)
    Data_ActivateTask(conf, obj, data, refresh, mouse)  
  end
  -------------------------------------------------------------
  function DataUpdate2(conf, obj, data, refresh, mouse) 
    DataUpdate2_ParseCurrentList(conf, obj, data, refresh, mouse) 
  end
  ---------------------------------------------------  
  function DataUpdate2_StoreCurrentList(conf, obj, data, refresh, mouse) 
    local str = '//MPL TaskScheduler current task list '..data.date
    for i = 1, #data.list do
      str = str..'\nEVT '..data.list[i].evtID..' '..data.list[i].timeshed..' '..data.list[i].flags..' [['..data.list[i].stringargs..']] [['..data.list[i].comment..']]' 
    end
    local f = io.open(conf.cur_tasklist, 'w')
    if f then
      f:write(str)
      f:close()
     else
      MB('Error writing file', conf.mb_title, 0)
    end  
  end
  ---------------------------------------------------------------------
  function Data_ActivateTask(conf, obj, data, refresh, mouse) 
    for listid = 1, #data.list do
      local cur_time = data.time
      local timeshed = data.list[listid].timeshed
      if not data.triggers[listid] and timeshed == cur_time then -- trigger if difference less than 1 second
        local evt = data.list[listid].evtID
        data.triggers[listid] = true
        if not tonumber(evt) or (tonumber(evt) and tonumber(evt) > 0) then -- native actions/extension actions
          Action(data.list[listid].evtID)
          refresh.GUI = true
         elseif tonumber(evt) and tonumber(evt) < 0 then -- custom actions
          local evt=tonumber(evt)
          if evt == -1 and data.list[listid].stringargs then -- play custom tab
            local tabID = VF_GetProjIDByPath(data.list[listid].stringargs)
            if tabID then OnPlayButtonEx( tabID ) end
          end
        end
      end
    end
  end
  ---------------------------------------------------  
  function DataUpdate2_ParseCurrentList(conf, obj, data, refresh, mouse) 
    local f = io.open(conf.cur_tasklist, 'r')
    if not f then
      f= io.open(conf.cur_tasklist, 'w')
      f:write('//MPL TaskScheduler current task list')
      f:close()
     else
      local content = f:read('a')
      f:close()
      --msg('clear list')
      data.list = {}
      for line in content:gmatch('[^\r\n]+') do
        if line:match('EVT ') then
          evtID, timeshed, flags, stringargs, comment = line:match('EVT (.-) ([%d]+) ([%d]+) %[%[(.-)%]%] %[%[(.-)%]%]')
          if evtID then 
            if tonumber(evtID) then evtID = tonumber(evtID) end
            local evtname = evtID
            local evtID_native = NamedCommandLookup(evtID )
            if data.action_table[evtID_native] then evtname = data.action_table[evtID_native] end
            if evtname == '' then evtname = '<none>' end
            if tonumber(evtID) and evtID <0 then -- custom actions
            
              if evtID == -1 then
                evtname = 'Play project: '
                evtname_arg = ''
                if not stringargs then 
                  evtname_arg = '<broken data>' 
                 else
                  local ID = VF_GetProjIDByPath(stringargs)
                  if not ID or not stringargs then 
                    evtname_arg = '<project not found> '..GetShortSmplName(stringargs)
                   else
                    local shortname = GetShortSmplName(stringargs)
                    if not shortname then 
                      evtname_arg = '<project not found, broken argument>'
                     else
                      evtname_arg = '<tab '..(ID+1)..'> '..shortname
                    end
                  end
                end
                evtname = evtname..evtname_arg
              end
              
            end
            data.list[#data.list+1] = {line = line,
                                      evtID = evtID,
                                      timeshed=tonumber(timeshed),
                                      flags=tonumber(flags),
                                      stringargs=stringargs,
                                      comment=comment,
                                      --has_triggered=false,
                                      evtname=evtname}
          end
        end
      end
    end
  end
