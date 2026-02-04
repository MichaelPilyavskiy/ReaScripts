-- @description TaskScheduler
-- @version 2.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # structure overhaul
--    # fixed dayly repeat

  --------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
    local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.10'
    
    function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 640,
          viewport_posH = 480, 
          
        }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
    
    var = {
      ES_key = 'MPL_TaskScheduler',
      UI_name = 'Task Scheduler', 
      font='Arial',
      spacingX = 3,
      spacingY = 3,
      col_windowBg = 0x303030FF, 
      main_col = 0x7F7F7F, -- grey
      action_table = {},
      list = {}, 
      datetimeW = 50,
      paramnameW = 150,
    },
    process = {
      ActivateTask = { },
      GetTimeCondition = {},
      collect = {
        realtime = {},
      },
      CurrentList = {
        Store = {},
        Parse  ={},
      },
    },
    draw = {
      events = {},
    },
    utility = {
    },
    ImGui = {},  
  }
  -------------------------------------------------------------------------------- 
  function main_loop() 
    DATA.process.collect.realtime()
    if DATA.shed_remove then 
      table.remove(self.var.list,DATA.shed_remove)
      self.process.CurrentList.Store.all() 
      DATA.shed_remove = nil
    end
    local open = DATA.draw.styledefinition(true) 
    if open then defer(main_loop) end
  end
  -------------------------------------------------------------------------------- 
  function EXT:save() 
    if not DATA.var.ES_key then return end 
    for key in pairs(EXT) do  if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then SetExtState( DATA.var.ES_key, key, EXT[key], true  )  end  end 
    EXT:load()
  end
  -------------------------------------------------------------------------------- 
  function EXT:load() 
    if not DATA.var.ES_key then return end
    for key in pairs(EXT) do 
      if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
        if HasExtState( DATA.var.ES_key, key ) then 
          local val = GetExtState( DATA.var.ES_key, key ) 
          EXT[key] = tonumber(val) or val 
        end 
      end  
    end 
  end
  --------------------------------------------------------------------------------  
  function DATA:func_def_utility() 
    self.utility.GetShortSmplName = 
    function (path) 
      local fn = path
      fn = fn:gsub('%\\','/')
      if fn then fn = fn:reverse():match('(.-)/') end
      if fn then fn = fn:reverse() end
      return fn
    end 
    ---------------------------------------------------
    self.utility.GetProjIDByPath =
    function (projfn)
      for idx  = 0, 1000 do
        retval, projfn0 = reaper.EnumProjects( idx )
        if not retval then return end
        if projfn == projfn0 then return idx end
      end
    end
    ---------------------------------------------------
    self.utility.Action = 
    function (s, sectionID, ME )  
      if sectionID == 32060 and ME then 
        MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
       else
        Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
      end
    end 
  end
  ----------------------------------------------------------------------------------------- 
  function DATA:func_def_collect() 
    self.process.collect.tasklist = 
    function()
      local info = debug.getinfo(1,'S');
      self.var.script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
      self.var.cur_tasklist_fp = DATA.var.script_path .. "mpl_TaskScheduler_currentlist.tlist" 
    end
    -------------------------------------------------------------------------------- 
    self.process.collect.realtime = 
    function ()
      self.var.TS_time = os.time()  
      self.var.TS_date = os.date('%c', self.var.TS_time) 
      self.var.TS_datetime_t = os.date("*t",self.var.TS_time)
      self.process.ActivateTask.all()  
    end
    -------------------------------------------------------------------------------- 
    self.process.collect.GetActionTable =
    function ()
      for i = 0, 200000 do
        local id, actname = reaper.kbd_enumerateActions( 0, i )
        if not id or id < -1 then break end
        self.var.action_table[id] = actname
      end
    end
  end
  -------------------------------------------------------------------------------- 
  function DATA:func_def_process() 
    self.process.Remove = function(evtID) DATA.shed_remove = evtID end
    ----------------------------------------------------- 
    self.process.Event_Add = 
    function ()  
      local datetime = { year =self.var.TS_default_Year,
                         month =self.var.TS_default_Month,
                         day =self.var.TS_default_Day,
                         hour =self.var.TS_default_Hour,
                         min =self.var.TS_default_Minute,
                         sec =self.var.TS_default_Second,
                        }
      local timeshed=os.time(datetime)
      
      self.var.list[#self.var.list+1] = { evtID = tonumber(DATA.temp_commandID) or 0, 
                                  timeshed = timeshed, 
                                  flags=0,
                                  stringargs = '',
                                  comment =DATA.temp_Comment or '',
                                  
                                  timeshed_repeat = false,
                                  infinite_repeat = true,
                                  timeshed_repeatuntil_time = timeshed}
      self.process.CurrentList.Store.all() 
    end
    -----------------------------------------------------------------------------------------
    self.process.init_sched_defaults = 
    function()
      self.var.TS_default_time = self.var.TS_time + 60*60*24*7 -- week further
      self.var.TS_default_Day     = os.date("%d",self.var.TS_default_time) 
      self.var.TS_default_Month   = os.date("%m",self.var.TS_default_time)
      self.var.TS_default_Year    = os.date("%Y",self.var.TS_default_time)
      self.var.TS_default_Hour    = os.date("%H",self.var.TS_default_time)
      self.var.TS_default_Minute  = os.date("%M",self.var.TS_default_time)
      self.var.TS_default_Second  = os.date("%S",self.var.TS_default_time)
    end 
    ---------------------------------------------------  
    self.process.CurrentList.Store.datefromtable = 
    function (evtID,issched)
      local key_t = 'timeshed_datetime_t'
      local key_time = 'timeshed'
      if issched == true then
        key_t = 'timeshed_repeatuntil_time_t'
        key_time = 'timeshed_repeatuntil_time'
      end
      local datetime = { year =   self.var.list[evtID][key_t].year,
                         month =  self.var.list[evtID][key_t].month,
                         day =    self.var.list[evtID][key_t].day,
                         hour =   self.var.list[evtID][key_t].hour,
                         min =    self.var.list[evtID][key_t].min,
                         sec =    self.var.list[evtID][key_t].sec,
                         isdst = false,
                        }
      self.var.list[evtID][key_time]=os.time(datetime)
      self.process.CurrentList.Store.all()
    end
    ---------------------------------------------------  
    self.process.CurrentList.Store.all = 
    function ()  
      local str = '//MPL TaskScheduler current task list '..self.var.TS_date
      for i = 1, #self.var.list do
        local timeshed_repeat_flags= 0 
        if self.var.list[i].timeshed_repeat and self.var.list[i].timeshed_repeat == true then timeshed_repeat_flags = 1 end
        if self.var.list[i].infinite_repeat ==true then timeshed_repeat_flags = timeshed_repeat_flags + 2 end
        
        local timeshed_repeatuntil_time = 0
        if self.var.list[i].timeshed_repeatuntil_time then timeshed_repeatuntil_time  = self.var.list[i].timeshed_repeatuntil_time end
        
        local timeshed_repeat_everyday = 127
        if self.var.list[i].timeshed_repeat_everyday then timeshed_repeat_everyday  = self.var.list[i].timeshed_repeat_everyday end
        
        local timeshed = self.var.list[i].timeshed..'|'..timeshed_repeat_flags..'|'..timeshed_repeatuntil_time..'|'..timeshed_repeat_everyday
        str = str..'\nEVT '..self.var.list[i].evtID..' '..timeshed..' '..self.var.list[i].flags..' [['..self.var.list[i].stringargs..']] [['..self.var.list[i].comment..']]' 
      end
      local f = io.open(self.var.cur_tasklist_fp, 'wb')  
      if f then
        f:write(str)
        f:close()
      end 
      self.process.CurrentList.Parse.all() 
    end
    -------------------------------------------------------------------------------- 
    self.process.CurrentList.Parse.all =
    function ()  
      local f = io.open(self.var.cur_tasklist_fp, 'rb')
      if not f then
        f= io.open(self.var.cur_tasklist_fp, 'wb')
        f:write('//MPL TaskScheduler current task list')
        f:close()
        
        f = io.open(self.var.cur_tasklist_fp, 'rb')
      end
      
      if f then 
        local content = f:read('a')
        f:close()
        self.var.list = {}
        for line in content:gmatch('[^\r\n]+') do 
          if line:match('EVT ') then
            evtID, timeshed, flags, stringargs, comment = line:match('EVT (.-) ([%d|%-]+) ([%d]+) %[%[(.-)%]%] %[%[(.-)%]%]')
            self.process.CurrentList.Parse.parameters(evtID, timeshed, flags, stringargs, comment) 
          end
        end
      end
    end  
    -------------------------------------------------------------------------------- 
    self.process.CurrentList.Parse.parameters = 
    function (evtID, timeshed, flags, stringargs, comment)  
      if not (evtID and timeshed) then return end
      local retval, desc = reaper.GetActionShortcutDesc( 0, evtID, 0 )
      
      -- handle custom actions 
        if tonumber(evtID) then evtID = tonumber(evtID) end
        local evtname = evtID
        local evtID_native = NamedCommandLookup(evtID )
        if self.var.action_table[evtID_native] then evtname = self.var.action_table[evtID_native] end
        if evtname == '' then evtname = '<none>' end
        if tonumber(evtID) and evtID <0 then 
          if evtID == -1 then
            evtname = ''
            evtname_arg = ''
            if not stringargs then 
              evtname_arg = '<broken data>' 
             else
              local ID = self.utility.GetProjIDByPath(stringargs)
              if not ID or not stringargs then 
                evtname_arg = '<project not found> '..stringargs
               else
                local shortname = self.utility.GetShortSmplName(stringargs)
                if not shortname then 
                  evtname_arg = '<project not found, broken argument>'
                 else
                  evtname_arg =shortname-- '<tab '..(ID+1)..'> '..
                end
              end
            end
            evtname = evtname..evtname_arg
          end 
        end
        
      -- handle timeshedule
        --local timeshed_out = 0
        local timeshed_repeat_flags = 0
        local timeshed_repeatuntil_time = 0
    
    
        local val_t = {} for val in timeshed:gmatch('[^|]+') do val_t[#val_t+1] =val end
        local timeshed_out = tonumber(val_t[1])--+60*60*3
        if val_t[2] then 
          timeshed_repeat_flags = tonumber(val_t[2])
          timeshed_repeat = timeshed_repeat_flags&1==1
          infinite_repeat = timeshed_repeat_flags&2==2
          timeshed_repeatuntil_time = math.max(0,tonumber(val_t[3]))
          timeshed_repeat_everyday = tonumber(val_t[4])
        end
        
        self.var.list[#self.var.list+1] = {line = line,
                                evtID = evtID,
                                evtID_native= evtID_native,
                                desc=desc,
                                timeshed=timeshed_out,
                                
                                timeshed_repeat=timeshed_repeat,
                                infinite_repeat = infinite_repeat, 
                                timeshed_repeat_everyday=timeshed_repeat_everyday,
                                
                                flags=tonumber(flags),
                                stringargs=stringargs,
                                comment=comment,
                                timeshed_datetime_t = os.date("*t",timeshed_out), 
                                evtname=evtname,
                                
                                timeshed_repeatuntil_time = timeshed_repeatuntil_time,
                                timeshed_repeatuntil_time_t = os.date("*t",timeshed_repeatuntil_time),  
                                
                                --timeshed_format = os.date('*t', timeshed),
                                }
    end
    ----------------------------------------------------------------------------------------- 
    self.process.evt_perform = 
    function(evtID)
      local actionID = self.var.list[evtID].evtID
      if not tonumber(actionID) or (tonumber(actionID) and tonumber(actionID) > 0) then -- native actions/extension actions
        Main_OnCommand(tonumber(actionID),0)
       elseif tonumber(actionID) and tonumber(actionID) < 0 then -- custom actions
        local actionID=tonumber(actionID)
        if actionID == -1 and self.var.list[evtID].stringargs then -- play custom tab
          local tabID = self.utility.GetProjIDByPath(self.var.list[evtID].stringargs)
          if tabID then OnPlayButtonEx( tabID ) end
        end
      end
    end
    ----------------------------------------------------------------------------------------- 
    self.process.ActivateTask.all =
    function ()   
      for evtID = 1, #self.var.list do
        local perform_condition = self.process.GetTimeCondition.all(evtID)  
        if perform_condition==true then self.process.evt_perform(evtID) end -- trigger if difference less than 1 second
      end
      
    end
    -----------------------------------------------------
    self.process.GetTimeCondition.check_infinite_repeat_limit =
    function(evtID)
      if self.var.list[evtID].infinite_repeat == true and self.var.list[evtID].infinite_repeat == false and self.var.list[evtID].timeshed_repeatuntil_time and self.var.list[evtID].timeshed_repeatuntil_time >= self.var.TS_time then return end
      return true
    end
    -----------------------------------------------------
    self.process.GetTimeCondition.check_allowed_days =
    function(evtID)
      local day_fits = false
      local everyday_mask = self.var.list[evtID].timeshed_repeat_everyday
      if everyday_mask>=0 then -- everyday repeat
        local day_fits = (
                      (self.var.TS_datetime_t.wday==1 and everyday_mask&64==64)
                      or (self.var.TS_datetime_t.wday==2 and everyday_mask&1==1)
                      or (self.var.TS_datetime_t.wday==3 and everyday_mask&2==2)
                      or (self.var.TS_datetime_t.wday==4 and everyday_mask&4==4)
                      or (self.var.TS_datetime_t.wday==5 and everyday_mask&8==8)
                      or (self.var.TS_datetime_t.wday==6 and everyday_mask&16==16)
                      or (self.var.TS_datetime_t.wday==7 and everyday_mask&32==32)
                    )
        if day_fits~=true then return end
      end 
      return true
    end
    -----------------------------------------------------
    self.process.GetTimeCondition.check_last_triggerdTS =
    function(evtID)
      local match_time = 
        self.var.list[evtID].timeshed_datetime_t.hour == self.var.TS_datetime_t.hour and 
        self.var.list[evtID].timeshed_datetime_t.min == self.var.TS_datetime_t.min and 
        self.var.list[evtID].timeshed_datetime_t.sec == self.var.TS_datetime_t.sec 
        
        
      if match_time == true and --self.var.list[evtID].timeshed == self.var.TS_time 
        self.var.list[evtID].state ~= 1 then  
        self.var.list[evtID].triggerTS= os.clock() 
        self.var.list[evtID].state = 1 
        return true
      end 
      -- is trigger closer than 1 sec
      if self.var.list[evtID].state == 1 then
        if os.clock() - self.var.list[evtID].triggerTS < 1 then 
          return 
         else
          self.var.list[evtID].state = 0
        end 
      end
    end
    -----------------------------------------------------
    self.process.GetTimeCondition.all = 
    function (evtID) 
      local ret = self.process.GetTimeCondition.check_infinite_repeat_limit(evtID) if ret ~= true then return end -- repeating forever or until some time
      local ret = self.process.GetTimeCondition.check_allowed_days(evtID) if ret ~= true then return end -- handle every day repeat
      local ret_trigger = self.process.GetTimeCondition.check_last_triggerdTS(evtID) 
      return ret_trigger
    end
    
  end
  -----------------------------------------------------------------------------------------   
  function DATA:func_def_draw()
    --------------------------------------------------------------------------------  
    self.draw.main = 
    function ()
      local addevent_w=  200
      if ImGui.BeginChild( ctx, '##newevent', addevent_w, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Borders, ImGui.WindowFlags_None ) then 
        reaper.ImGui_SeparatorText(ctx, 'New event')
        ImGui.Text(ctx,self.var.TS_date)
        self.draw.addevent() 
        ImGui.EndChild( ctx)
      end 
      ImGui.SameLine(ctx)
      if ImGui.BeginChild( ctx, '##evtlist', 0, 0, ImGui.ChildFlags_None, ImGui.WindowFlags_None ) then --|ImGui.ChildFlags_Borders
        self.draw.events.all() 
        ImGui.EndChild( ctx)
      end
    end
    ----------------------------------------------------------------------------------------- 
    self.draw.events.actioncombo = 
    function(evtID)
      local modestr = ''
      local mode = {
          [0]   = 'ActionID',
          [-1]  = 'Play project'
        }
      local action = tonumber(self.var.list[evtID].evtID) or 0
      if action >= 0 then modestr = mode[0] else modestr = mode[self.var.list[evtID].evtID] end
      ImGui.SetNextItemWidth(ctx, self.var.paramnameW)
      if ImGui.BeginCombo( ctx, '##mode', modestr, ImGui.ComboFlags_None ) then
        if ImGui.Selectable( ctx, 'ActionID##ActionID'..evtID, self.var.list[evtID].evtID>=0, ImGui.SelectableFlags_None) then self.var.list[evtID].evtID = 0 self.process.CurrentList.Store.all()  end
        if ImGui.Selectable( ctx, 'Play current project', self.var.list[evtID].evtID==-1, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].evtID = -1 
          local retval, projfn = EnumProjects( -1 )
          self.var.list[evtID].stringargs = projfn
          self.process.CurrentList.Store.all()  
        end
        ImGui.EndCombo( ctx)
      end
    end
    ----------------------------------------------------------------------------------------- 
    self.draw.events.CommandID = 
    function(evtID)
      ImGui.SetNextItemWidth(ctx, -50)
      local retval, buf1 = ImGui.InputText( ctx, '##evt_'..evtID..'Command ID', self.var.list[evtID].evtname, ImGui.InputTextFlags_None|ImGui.InputTextFlags_EnterReturnsTrue)
      if retval then self.var.list[evtID].evtname = buf1 end
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
        if self.var.list[evtID].evtID>=0 and tonumber(buf1 ) then 
          self.var.list[evtID].evtID= tonumber(buf1 )
          self.process.CurrentList.Store.all()   
        end
      end 
    end
    ----------------------------------------------------------------------------------------- 
    self.draw.events.comment = 
    function(evtID,xpos)
      -- comment
      ImGui.SetCursorPosX(ctx,xpos) self.ImGui.Custom_InvisibleButton(ctx, 'Comment:##idcomment'..evtID,self.var.paramnameW) ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, -1)
      local retval, buf = ImGui.InputText( ctx, '##evt_'..evtID..'Comment', self.var.list[evtID].comment, ImGui.InputTextFlags_None)
      if retval then 
        self.var.list[evtID].comment = buf 
        self.process.CurrentList.Store.all()  
      end
    end
    ----------------------------------------------------------------------------------------- 
    self.draw.events.all = 
    function () 
      for evtID = 1, #self.var.list do
        if ImGui.BeginChild( ctx, '##evt'..evtID, 0, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Borders|ImGui.ChildFlags_AutoResizeY, ImGui.WindowFlags_None ) then 
        
          -- id
          self.ImGui.Custom_InvisibleButton(ctx, evtID..'##id'..evtID)
          ImGui.SameLine(ctx)
          local xpos,ypos = ImGui.GetCursorPos(ctx)
          
          self.draw.events.actioncombo(evtID) ImGui.SameLine(ctx)
          self.draw.events.CommandID(evtID) ImGui.SameLine(ctx)
          if ImGui.Button(ctx, 'X##idremove'..evtID,-1) then self.process.Remove(evtID) end
          self.draw.events.comment(evtID,xpos)
          self.draw.events.scheduletime(evtID, xpos)
          
          ImGui.SetCursorPosX(ctx,xpos)
          if ImGui.Checkbox(ctx, 'Repeat##evt_'..evtID..'Repeat',self.var.list[evtID].timeshed_repeat) then
            self.var.list[evtID].timeshed_repeat = not self.var.list[evtID].timeshed_repeat
            self.process.CurrentList.Store.datefromtable(evtID)
          end
          if self.var.list[evtID].timeshed_repeat == true then 
            ImGui.SameLine(ctx) 
            if ImGui.Checkbox(ctx, 'Infinite##evt_'..evtID..'Repeatuntil',self.var.list[evtID].infinite_repeat) then
              self.var.list[evtID].infinite_repeat = not self.var.list[evtID].infinite_repeat
              self.process.CurrentList.Store.datefromtable(evtID)
            end
            ImGui.SameLine(ctx) 
            self.draw.events.r_repeat(evtID) 
            
            ImGui.SetCursorPosX(ctx,xpos)
            self.draw.events.scheduletime(evtID, xpos,true)
            
          end
          
          ImGui.EndChild( ctx)
        end
      end
    end
    ----------------------------------------------------------------------------------------- 
    self.draw.events.scheduletime = 
    function (evtID, xpos,is_scheduntil) 
      local offs = 100
      
      local key_t = 'timeshed_datetime_t'
      local key_time = 'timeshed'
      local strid = ''
      if is_scheduntil == true then
        key_t = 'timeshed_repeatuntil_time_t'
        key_time = 'timeshed_repeatuntil_time'
        strid = 'sched'
      end
      
      
      -- datestart
      ImGui.SetCursorPosX(ctx,xpos)
      if not is_scheduntil then ImGui.Text(ctx, 'Schedule date:') else ImGui.Text(ctx, 'End date:') end
      ImGui.SameLine(ctx)  
      ImGui.SetCursorPosX(ctx,xpos+offs)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##evt_'..evtID..'day'..strid, self.var.list[evtID][key_t].day, ImGui.ComboFlags_None ) then
        for i = 1, 31 do if ImGui.Selectable( ctx, i, self.var.list[evtID][key_t].day==i, ImGui.SelectableFlags_None) then 
          self.var.list[evtID][key_t].day = i 
          self.process.CurrentList.Store.datefromtable(evtID,is_scheduntil)
        end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##evt_'..evtID..'month'..strid, self.var.list[evtID][key_t].month, ImGui.ComboFlags_None ) then
        for i = 1, 12 do if ImGui.Selectable( ctx, i, self.var.list[evtID][key_t].month==i, ImGui.SelectableFlags_None) then 
          self.var.list[evtID][key_t].month = i 
          self.process.CurrentList.Store.datefromtable(evtID,is_scheduntil)
        end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW+30)
      if ImGui.BeginCombo( ctx, '##evt_'..evtID..'year'..strid, self.var.list[evtID][key_t].year, ImGui.ComboFlags_None ) then
        for i = 2025, 2100 do if ImGui.Selectable( ctx, i, self.var.list[evtID][key_t].year==i, ImGui.SelectableFlags_None) then 
          self.var.list[evtID][key_t].year = i 
          self.process.CurrentList.Store.datefromtable(evtID,is_scheduntil)
        end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.SetCursorPosX(ctx,xpos)
      if not is_scheduntil then ImGui.Text(ctx, 'Schedule time:') else ImGui.Text(ctx, 'End time:') end
      ImGui.SameLine(ctx)
      ImGui.SetCursorPosX(ctx,xpos+offs)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##evt_'..evtID..'Hour'..strid, self.var.list[evtID][key_t].hour, ImGui.ComboFlags_None ) then
        for i = 0, 23 do if ImGui.Selectable( ctx, i, self.var.list[evtID][key_t].hour==i, ImGui.SelectableFlags_None) then 
          self.var.list[evtID][key_t].hour = i 
          self.process.CurrentList.Store.datefromtable(evtID,is_scheduntil)
        end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##evt_'..evtID..'Minute'..strid, self.var.list[evtID][key_t].min, ImGui.ComboFlags_None ) then
        for i = 0, 59 do if ImGui.Selectable( ctx, i, self.var.list[evtID][key_t].min==i, ImGui.SelectableFlags_None) then 
          self.var.list[evtID][key_t].min = i 
          self.process.CurrentList.Store.datefromtable(evtID,is_scheduntil)
        end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##evt_'..evtID..'Second'..strid, self.var.list[evtID][key_t].sec, ImGui.ComboFlags_None ) then
        for i = 0, 59 do if ImGui.Selectable( ctx, i, self.var.list[evtID][key_t].sec==i, ImGui.SelectableFlags_None) then 
          self.var.list[evtID][key_t].sec = i 
          self.process.CurrentList.Store.datefromtable(evtID,is_scheduntil)
        end end
        ImGui.EndCombo( ctx)
      end
      
    end
    ----------------------------------------------------------------------------------------- 
    self.draw.events.r_repeat =  
    function (evtID) 
       
      ImGui.SameLine(ctx) 
      local rep_preview = 'Every day' 
      local everyd_mask = self.var.list[evtID].timeshed_repeat_everyday
      if everyd_mask ~= 127 then 
        if everyd_mask == 96 then rep_preview = 'Every weekend' 
         elseif everyd_mask ~= 0 then
          rep_preview = 'Every '
          if everyd_mask&1==1 then rep_preview = rep_preview..'Mon ' end
          if everyd_mask&2==2 then rep_preview = rep_preview..'Tue ' end
          if everyd_mask&4==4 then rep_preview = rep_preview..'Wed ' end
          if everyd_mask&8==8 then rep_preview = rep_preview..'Thu ' end
          if everyd_mask&16==16 then rep_preview = rep_preview..'Fri ' end
          if everyd_mask&32==32 then rep_preview = rep_preview..'Sat ' end
          if everyd_mask&64==64 then rep_preview = rep_preview..'Sun' end
         elseif everyd_mask == 0 then
          rep_preview = '<days not set>'
        end
      end
       reaper.ImGui_SetNextItemWidth(ctx,-1)
      if ImGui.BeginCombo( ctx, '##evt_repeat'..evtID, rep_preview, ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLargest ) then
        if ImGui.Selectable( ctx, 'Monday', self.var.list[evtID].timeshed_repeat_everyday&1==1, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=self.var.list[evtID].timeshed_repeat_everyday~1
          self.process.CurrentList.Store.all() 
        end
        if ImGui.Selectable( ctx, 'Tuesday', self.var.list[evtID].timeshed_repeat_everyday&2==2, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=self.var.list[evtID].timeshed_repeat_everyday~2
          self.process.CurrentList.Store.all() 
        end          
        if ImGui.Selectable( ctx, 'Wednesday', self.var.list[evtID].timeshed_repeat_everyday&4==4, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=self.var.list[evtID].timeshed_repeat_everyday~4
          self.process.CurrentList.Store.all() 
        end   
        if ImGui.Selectable( ctx, 'Thursday', self.var.list[evtID].timeshed_repeat_everyday&8==8, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=self.var.list[evtID].timeshed_repeat_everyday~8
          self.process.CurrentList.Store.all() 
        end  
        if ImGui.Selectable( ctx, 'Friday', self.var.list[evtID].timeshed_repeat_everyday&16==16, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=self.var.list[evtID].timeshed_repeat_everyday~16
          self.process.CurrentList.Store.all() 
        end  
        if ImGui.Selectable( ctx, 'Saturday', self.var.list[evtID].timeshed_repeat_everyday&32==32, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=self.var.list[evtID].timeshed_repeat_everyday~32
          self.process.CurrentList.Store.all() 
        end
        if ImGui.Selectable( ctx, 'Sunday', self.var.list[evtID].timeshed_repeat_everyday&64==64, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=self.var.list[evtID].timeshed_repeat_everyday~64
          self.process.CurrentList.Store.all() 
        end
        ImGui.Separator(ctx)
        if ImGui.Selectable( ctx, 'All', false, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=127
          self.process.CurrentList.Store.all() 
        end
        if ImGui.Selectable( ctx, 'None', false, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=0
          self.process.CurrentList.Store.all() 
        end  
        if ImGui.Selectable( ctx, 'Weekend', false, ImGui.SelectableFlags_None) then 
          self.var.list[evtID].timeshed_repeat_everyday=96
          self.process.CurrentList.Store.all() 
        end 
        ImGui.EndCombo( ctx)
      end
    end
    -------------------------------------------------------------------------------- 
    self.draw.addevent = 
    function ()
      ImGui.Text(ctx, 'Command ID:')
      reaper.ImGui_SetNextItemWidth(ctx,-1)
      local retval, buf = ImGui.InputText( ctx, '##Command ID',self.var.TS_default_commandID, ImGui.InputTextFlags_None)
      if retval then self.var.TS_default_commandID = buf end
      
      ImGui.Text(ctx, 'Date:')
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##day',self.var.TS_default_Day, ImGui.ComboFlags_None ) then 
        for i = 1, 31 do if ImGui.Selectable( ctx, i,self.var.TS_default_Day==i, ImGui.SelectableFlags_None) then self.var.TS_default_Day = i end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##month',self.var.TS_default_Month, ImGui.ComboFlags_None ) then
        for i = 1, 12 do if ImGui.Selectable( ctx, i,self.var.TS_default_Month==i, ImGui.SelectableFlags_None) then self.var.TS_default_Month = i end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, -1)
      if ImGui.BeginCombo( ctx, '##year',self.var.TS_default_Year, ImGui.ComboFlags_None ) then
        for i = 2025, 2100 do if ImGui.Selectable( ctx, i,self.var.TS_default_Year==i, ImGui.SelectableFlags_None) then self.var.TS_default_Year = i end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.Text(ctx, 'Time:')
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##Hour',self.var.TS_default_Hour, ImGui.ComboFlags_None ) then
        for i = 0, 24 do if ImGui.Selectable( ctx, i,self.var.TS_default_Hour==i, ImGui.SelectableFlags_None) then self.var.TS_default_Hour = i end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##Minute',self.var.TS_default_Minute, ImGui.ComboFlags_None ) then
        for i = 0, 60 do if ImGui.Selectable( ctx, i,self.var.TS_default_Minute==i, ImGui.SelectableFlags_None) then self.var.TS_default_Minute = i end end
        ImGui.EndCombo( ctx)
      end
    
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, self.var.datetimeW)
      if ImGui.BeginCombo( ctx, '##Second',self.var.TS_default_Second, ImGui.ComboFlags_None ) then
        for i = 0, 60 do if ImGui.Selectable( ctx, i,self.var.TS_default_Second==i, ImGui.SelectableFlags_None) then self.var.TS_default_Second = i end end
        ImGui.EndCombo( ctx)
      end
      
      ImGui.Text(ctx, 'Comment:')
      
      reaper.ImGui_SetNextItemWidth(ctx,-1)
      local retval, buf = ImGui.InputText( ctx, '##Comment',self.var.TS_default_Comment, ImGui.InputTextFlags_None)
      if retval then self.var.TS_default_Comment = buf end
      
      if ImGui.Button(ctx, 'Add event',-1,50) then self.process.Event_Add() end
    end
    --------------------------------------------------------------------------------
    self.draw.definecontext = 
    function () 
      EXT:load() 
      ctx = ImGui.CreateContext(DATA.var.UI_name) 
      self.draw.font = ImGui.CreateFont(self.var.font) ImGui.Attach(ctx, self.draw.font)  
      defer(main_loop)
    end
    -------------------------------------------------------------------------------- 
    self.draw.styledefinition = 
    function (open)  
      
      -- window_flags
        local window_flags = ImGui.WindowFlags_None
        window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
        window_flags = window_flags | ImGui.WindowFlags_NoCollapse
        window_flags = window_flags | ImGui.WindowFlags_NoDocking
        window_flags = window_flags | ImGui.WindowFlags_TopMost
        window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      
      
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding,5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding,5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding,5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding,5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabRounding,5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize,0)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize,0) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,self.var.spacingX,self.var.spacingY)  
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,10,self.var.spacingY) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,self.var.spacingX, self.var.spacingY) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,self.var.spacingX, self.var.spacingY)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,4,0)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing,20)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,15)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,600,350)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,20)
        
        main_col = 0x70707000
        main_col_title = 0x20402000
        ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,self.var.col_windowBg)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,         main_col|0x50)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,   main_col|0xF0)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,  main_col|0xB0)
        
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,        main_col|0x50)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,  main_col|0xF0)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, main_col|0xB0)
        
        ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg,        main_col_title|0xE0)
        ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive,  main_col_title|0xFF)
        
        
      -- init UI 
        ImGui.PushFont(ctx, self.draw.font, 14) 
        local rv,open = ImGui.Begin(ctx, DATA.var.UI_name, open, window_flags) 
        if rv then
          self.var.calc_xoffset,self.var.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding) 
          local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
          local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
          self.var.calc_itemH = calcitemh + frameh * 2 
          self.draw.main() 
          ImGui.Dummy(ctx,0,0) 
          ImGui.End(ctx)
        end 
        
        ImGui.PopStyleVar(ctx,18)
        ImGui.PopStyleColor(ctx,9)
        ImGui.PopFont( ctx ) 
        if ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false ) then return end
      
        return open
    end
  end
  ----------------------------------------------------------------------------------------- 
  function DATA:func_def() 
    DATA:func_def_utility() 
    DATA:func_def_process() 
    DATA:func_def_draw() 
    DATA:func_def_ImGui_Overrides() 
    DATA:func_def_collect() 
  end
  -------------------------------------------------------------------------------- 
  function DATA:func_def_ImGui_Overrides() 
    -------------------------------------------------------------------------------- 
    self.ImGui.Custom_HelpMarker =
    function(desc, tooltip_code, do_not_show_question_sign)
      if do_not_show_question_sign ~= true then ImGui.TextDisabled(ctx, '(?)') end
      if ImGui.BeginItemTooltip(ctx) then
        if tooltip_code then 
          tooltip_code()
         else
          ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
          ImGui.Text(ctx, desc)
          ImGui.PopTextWrapPos(ctx)
        end
        ImGui.EndTooltip(ctx)
      end
    end
        
    self.ImGui.Custom_InvisibleButton = 
    function(ctx,txt,w,h,color,txtcol)
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,color or 0)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,color or 0)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,color or 0)
      if txtcol then ImGui.PushStyleColor(ctx, ImGui.Col_Text,txtcol) end
      local ret = ImGui.Button(ctx,txt,w,h)
      ImGui.PopStyleColor(ctx, 3)
      if txtcol then ImGui.PopStyleColor(ctx, 1) end
      return ret
    end
    
  end
  ----------------------------------------------------------------------------------------- 
  function main() 
    DATA:func_def() 
    DATA.process.collect.GetActionTable() 
    DATA.process.collect.tasklist()
    DATA.process.collect.realtime()
    DATA.process.init_sched_defaults()
    DATA.process.CurrentList.Parse.all() 
    
    DATA.draw.definecontext() 
  end  
  -----------------------------------------------------------------------------------------
  main()  