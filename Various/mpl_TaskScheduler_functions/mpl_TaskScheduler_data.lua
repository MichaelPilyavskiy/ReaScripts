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
    data.datetime_t = os.date("!*t",data.time)
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
      local timeshed_repeat_flags= 0 
      if data.list[i].timeshed_repeat and data.list[i].timeshed_repeat == true then timeshed_repeat_flags = 1 end
      if data.list[i].timeshed_repeatuntil_check ==true then timeshed_repeat_flags = timeshed_repeat_flags + 2 end
      
      local timeshed_repeatuntil_time = 0
      if data.list[i].timeshed_repeatuntil_time then timeshed_repeatuntil_time  = data.list[i].timeshed_repeatuntil_time end
      
      local timeshed_repeat_everyday = 127
      if data.list[i].timeshed_repeat_everyday then timeshed_repeat_everyday  = data.list[i].timeshed_repeat_everyday end
      
      local timeshed = data.list[i].timeshed..'|'..timeshed_repeat_flags..'|'..timeshed_repeatuntil_time..'|'..timeshed_repeat_everyday
      str = str..'\nEVT '..data.list[i].evtID..' '..timeshed..' '..data.list[i].flags..' [['..data.list[i].stringargs..']] [['..data.list[i].comment..']]' 
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
      local perform_condition = Data_ActivateTask_GetTimeCondition(conf, obj, data, refresh, mouse, listid)  
      if perform_condition==true then -- trigger if difference less than 1 second
        --msg('listid'..listid)
        local evt = data.list[listid].evtID
        data.triggers[listid] = data.time
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
  function Data_ActivateTask_GetTimeCondition(conf, obj, data, refresh, mouse, listid)  
    if not (data.list[listid] and data.list[listid].timeshed) then return end
    -- prevent repeating 30ms trigger
      if data.triggers[listid] and math.abs(data.triggers[listid] - data.time)<1.5 then return end 
    --  single/repeat trigger
      if data.list[listid].timeshed_repeat == false and data.list[listid].timeshed == data.time then return true end 
    -- repeating forever or until some  time
      if not (data.list[listid].timeshed_repeatuntil_check == true or (data.list[listid].timeshed_repeatuntil_check == false and data.list[listid].timeshed_repeatuntil_time >= data.time)) then return end
    -- handle every day repeat
      local everyday_mask = data.list[listid].timeshed_repeat_everyday
      if everyday_mask>=0 then -- everyday repeat
        cond =      data.list[listid].timeshed_datetime_t.hour == data.datetime_t.hour
                and data.list[listid].timeshed_datetime_t.min == data.datetime_t.min
                and data.list[listid].timeshed_datetime_t.sec == data.datetime_t.sec
                and 
                    (
                      (data.datetime_t.wday==1 and everyday_mask&64==64)
                      or (data.datetime_t.wday==2 and everyday_mask&1==1)
                      or (data.datetime_t.wday==3 and everyday_mask&2==2)
                      or (data.datetime_t.wday==4 and everyday_mask&4==4)
                      or (data.datetime_t.wday==5 and everyday_mask&8==8)
                      or (data.datetime_t.wday==6 and everyday_mask&16==16)
                      or (data.datetime_t.wday==7 and everyday_mask&32==32)
                    )
            
      return cond       
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
          evtID, timeshed, flags, stringargs, comment = line:match('EVT (.-) ([%d|%-]+) ([%d]+) %[%[(.-)%]%] %[%[(.-)%]%]')
          if evtID then 
          
            -- handle custom actions 
              if tonumber(evtID) then evtID = tonumber(evtID) end
              local evtname = evtID
              local evtID_native = NamedCommandLookup(evtID )
              if data.action_table[evtID_native] then evtname = data.action_table[evtID_native] end
              if evtname == '' then evtname = '<none>' end
              if tonumber(evtID) and evtID <0 then 
                if evtID == -1 then
                  evtname = 'Play project: '
                  evtname_arg = ''
                  if not stringargs then 
                    evtname_arg = '<broken data>' 
                   else
                    local ID = VF_GetProjIDByPath(stringargs)
                    if not ID or not stringargs then 
                      evtname_arg = '<project not found> '..stringargs
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
              
            -- handle timeshedule
              local timeshed_out = 0
              local timeshed_repeat_flags = 0
              local timeshed_repeatuntil_time = 0
              if tonumber(timeshed) then 
                timeshed_out = tonumber(timeshed)
                timeshed_repeat_flags = 0
                timeshed_repeatuntil_check = false
                timeshed_repeatuntil_time = 0
                timeshed_repeat_everyday = 127
               else
                local val_t = {} for val in timeshed:gmatch('[^|]+') do val_t[#val_t+1] =val end
                timeshed_out = tonumber(val_t[1])
                if val_t[2] then 
                  timeshed_repeat_flags = tonumber(val_t[2])
                  timeshed_repeat = timeshed_repeat_flags&1==1
                  timeshed_repeatuntil_check = timeshed_repeat_flags&2==2
                  timeshed_repeatuntil_time = math.max(0,tonumber(val_t[3]))
                  timeshed_repeat_everyday = tonumber(val_t[4])
                end
              end
            
            data.list[#data.list+1] = {line = line,
                                      evtID = evtID,
                                      timeshed=timeshed_out,
                                      timeshed_repeat=timeshed_repeat,
                                      timeshed_repeatuntil_check = timeshed_repeatuntil_check,
                                      timeshed_repeatuntil_time = timeshed_repeatuntil_time,
                                      timeshed_repeat_everyday=timeshed_repeat_everyday,
                                      flags=tonumber(flags),
                                      stringargs=stringargs,
                                      comment=comment,
                                      timeshed_datetime_t = os.date("!*t",timeshed_out),
                                      
                                      evtname=evtname}
          end
        end
      end
    end
  end
