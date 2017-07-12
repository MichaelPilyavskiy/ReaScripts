-- @version 1.01
-- @author MPL
-- @changelog
--    + Menu/Show shortcuts
--    + Menu/Dock: show dockstate check 
-- @description ProjectPlaylist
-- @website http://forum.cockos.com/member.php?u=70694
  
  -- requested here https://forum.cockos.com/showpost.php?p=1854775&postcount=1
  
  
  --[[ full changelog
    0.02 init alpha 01.07.2017  
      basic GUI
      load current opened project on start 
      save/load playlist
      selecting tabs
      objects init/update improvements
      dragndrop project in list
    0.25 02.07.2017
      progress bar
      active state
      clickable play buttons
      dragndrop
      redraw background/static buttons fix
      small menu button
      limit playing progress to end of every project
      redraw and update playlist if project closed manually
    0.30 03.07.2017
      tab selection: fill white rectangle, bold and bigger font
      color current playing tab green
      green progress line under the tab name
      scroll with mouse wheel
      shortcuts
        space to Play/Stop active tab
        space+shift: stop all tabs
        arrow up: upper tab
        arrow down: lower tab
      dockable window
      store dock state
      left aligned tab names
      order numbers
      refresh playlist
    0.4
      take out play state buttons
      take out gradient
      take out menu
      right click run menu
      item separators
      item state: the play cursor while playing and the Edit cursor while Stopped
      cycle arrows
      user input on save
      reload list after save optionally
      save/load playlists with .rpl extension
    0.50
      Prefix - Weekday MM DD HH-MM-SS YYYY.RPL
      shortcuts : esc for exit
      shortcuts : Shift+Alt+K for exit
      shortcuts : tab to focus arrange
      shift blit if active tab out of window  
      keep ID order
    0.60
      Menu: toggle dock
      take gradient back
    0.61
      force reload after SWS save test
    1.01 12/07/2017
      Menu/Show shortcuts
      Menu dock: show dockstate check 
  ]]
  
  
  
  
  
  
  
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end   
  local item_height = 20
  local global_font_size = 16
  local global_font_name = 'Arial'
  local max_proj_cnt = 100
  local playlists_path = GetResourcePath()..'/MPL ProjectPlaylists/'  
  
   
  
  
  
  
  
  --  INIT -------------------------------------------------  
  local vrs = 1.01
  debug = 0
  local mouse = {}
  local gui -- see GUI_define()
  local obj = {blit_offs = 0}
   conf = {}
  local cycle = 0
  local redraw = 1
  local SCC, lastSCC, SCC_trig,drag_mode,last_drag_mode
  local ProjState
  local playlist = {}
  ---------------------------------------------------
  local function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------
  local function ExtState_Save()
    conf.dock, conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h = gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
  end
  ---------------------------------------------------
  local function msg(s) ShowConsoleMsg(s..'\n') end
  if debug == 1 then function deb(s) ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  local function col(col_s, a) gfx.set( table.unpack(gui.col[col_s])) if a then gfx.a = a end  end
  ---------------------------------------------------
  local function GUI_DrawObj(o)
    if not o then return end 
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    
    -- gradient back
      gfx.a = o.a or 0.3
      gfx.blit( 2, 1, math.rad(o.grad_blit_rot),
                0,0,  obj.grad_sz,math.ceil(obj.grad_sz*o.grad_blit_h_coeff),
                x,y,w,h, 0,0)
      
    -- separator         
      col('white', 0.3)
      gfx.line(x,y+h,x+w,y+h)
              
              
    local flag = ''
    local fontsz_add = 0
    
    -- selection active tab
      if o.active  then  
        col('white', 0.45)
        gfx.rect(x,y+1,w,h-1,1) 
        flag = string.byte("b",1)   
        fontsz_add = 2   
      end
    
    -- progress      
      if o.progress then 
        col('green', 0.43) 
        gfx.rect(x,y+h-2,w*o.progress,2,0)
      end    
       
    -- font on play
      col('white', 0.8)
      if o.playstate then col('green', 0.7)  end
    
    -- text
      gfx.setfont(1, gui.fontname, gui.fontsz + fontsz_add, flag  )
      local x_offs = 5
      gfx.x = x + (w-gfx.measurestr(txt))/2
      if o.leftaligned then gfx.x = x + x_offs end
      gfx.y = y+ (h-gfx.texth)/2
      gfx.drawstr(o.txt)
  end
  ---------------------------------------------------
  local function GUI_Playlist()
    gfx.dest = 4
    gfx.setimgdim(4, -1, -1)  
    gfx.setimgdim(4, gfx.w, obj.it_h * #playlist)  
    for key in pairs(obj) do if type(obj[key]) == 'table' and key:find('PLitem') then GUI_DrawObj(obj[key]) end end          
    
    if drag_id_dest and drag_id_src and drag_id_dest ~= drag_id_src then 
     local add
     if drag_id_dest > drag_id_src then add = 0 else add =1 end
     gfx.a = 1
     gfx.line(0,obj.it_h*(drag_id_dest-add),
              gfx.w, obj.it_h*(drag_id_dest-add)
               )
    end
    
  end
  ---------------------------------------------------
  local function GUI_draw()
    gfx.mode = 0
    -- redraw: -1 init, 1 maj changes, 2 minor changes
    -- 1 back
    -- 2 gradient
    --// 3 dynamic stuff
    -- 4 playlist
      
    --  init
      if math.abs(redraw )== 1 then
        gfx.dest = 2
        gfx.setimgdim(2, -1, -1)  
        gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 0.9,0.9,1,0.62
        gfx.x, gfx.y = 0,0
        local c = 0.5
        local drdx = c*0.00001
        local drdy = c*0.00001
        local dgdx = c*0.00008
        local dgdy = c*0.0001    
        local dbdx = c*0.00008
        local dbdy = c*0.00001
        local dadx = c*0.00003
        local dady = c*0.0004       
        gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady) 
        -- refresh backgroung
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz,
                    0,0,  gfx.w,gfx.h, 0,0)
          gfx.a = 1
 
      end
    -- dynamic list
      GUI_Playlist()
    
      
    --  render    
      gfx.dest = -1  
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      --  back
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
      --  PL
      local y_sh = lim(obj.it_h * #playlist - gfx.h, 0, gfx.h) * obj.blit_offs
      local h = lim(obj.it_h * #playlist, 0, y_sh+gfx.h)
      gfx.blit(4, 1, 0, -- PL
          0,0, gfx.w,h ,
          0,-y_sh, gfx.w, h, 0,0)  
                   
      GUI_DrawObj(obj.scrollbar)
      GUI_DrawObj(obj.menu)  
      --[[ line fix
        col('white', 0.3)
        gfx.line(0,gfx.h-obj.it_h, gfx.w,gfx.h-obj.it_h)]]     
        
    redraw = 0
    gfx.update()
  end
  ---------------------------------------------------
  function HasWindXYWHChanged()
    local  dock, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    local retval=0
    if wx ~= obj.last_gfxx or wy ~= obj.last_gfxy then retval= 2 end --- minor
    if    ww ~= obj.last_gfxw 
      or  wh ~= obj.last_gfxh 
      or  wdock ~= obj.last_gfxdock 
      then retval= 1 end --- major
    if not obj.last_gfxx then retval = -1 end
    obj.last_gfxx, obj.last_gfxy, obj.last_gfxw, obj.last_gfxh, obj.last_gfxdock = wx,wy,ww,wh, dock
    return retval
  end
  ---------------------------------------------------
  local function ExtState_Def()
    return {ES_key = 'MPL_ProjectPlaylist',
            wind_x =  50,
            wind_y =  50,
            wind_w =  200,
            wind_h =  500,
            dock =    0}
  end
  ---------------------------------------------------
  local function ExtState_Load()
    local def = ExtState_Def()
    for key in pairs(def) do 
      local es_str = GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end
  end
  ---------------------------------------------------
  local function Actions_AddOpenedProjectsToPlaylist()
    for i = 1, max_proj_cnt do
      local retval, projfn=  EnumProjects( i-1, '' )
      if projfn == '' then break end
      playlist[#playlist+1] = {ptr = retval, path = projfn, ID = i}
    end  
  end
  ---------------------------------------------------
  local function Actions_ReloadPlaylist(fp)
    if not fp and not playlist.fn then return end
    if not fp then fp = playlist.fn end
    if not tp then return end
    playlist = {}  
    local f = io.open(fp, 'r')
    if not f then return end
    local context = f:read('a')
    f:close()
    local t = {}
    Main_OnCommand(40886,0) -- File: Close all projects
    playlist = {fn = fp}
    for line in context:gmatch('[^\r\n]+') do 
      Main_OnCommand(41929, 0 ) -- New project tab (ignore default template)
      Main_openProject( line )
      local retval=  EnumProjects( -1, '' )
      playlist[#playlist+1] = {path = line,
                                ptr = retval} 
    end
    SelectProjectInstance( EnumProjects( 0, '') )
    Main_OnCommand(40860,0) -- Close current project tab
    redraw = 1
    OBJ_define()  
  end
  ---------------------------------------------------  
  function Menu()
    gfx.x, gfx.y = mouse.mx, mouse.my  
    local is_dirty = '#' if playlist.fn then is_dirty = '' end
    local is_docked 
    if conf.dock==1 then is_docked = '!' else is_docked = '' end
    local str_t = {
             {  txt = 'Add current saved project to playlist',
                func =  function() 
                          local retval, projfn=  EnumProjects( -1, '' )
                          playlist[#playlist+1] = {ptr = retval, path = projfn }
                          redraw = 1
                          OBJ_define()
                        end
              },
              {  txt = '|Add all opened saved projects to playlist (ignore projects without saved RPP)',
                 func = function() 
                          Actions_AddOpenedProjectsToPlaylist() 
                          redraw = 1
                          OBJ_define()
                        end
               },
              { txt = '||Load projects from playlist',
                func =  function()  
                          local ret =  MB( 'Are you sure you want to close ALL project tabs?', 'MPL ProjectPlaylist', 4 )
                          if ret == 6 then 
                            local r, fn = GetUserFileNameForRead('', 'Open ProjectPlaylist', 'rpl' )
                            if not r then return end 
                            local f = io.open(fn, 'r')
                            if not f then return end
                            local context = f:read('a')
                            f:close()
                            local t = {}
                            Main_OnCommand(40886,0) -- File: Close all projects
                            playlist = {fn = fn}
                            for line in context:gmatch('[^\r\n]+') do 
                              Main_OnCommand(41929, 0 ) -- New project tab (ignore default template)
                              Main_openProject( line )
                              local retval=  EnumProjects( -1, '' )
                              playlist[#playlist+1] = {path = line,
                                                        ptr = retval} 
                            end
                            SelectProjectInstance( EnumProjects( 0, '') )
                            Main_OnCommand(40860,0) -- Close current project tab
                            redraw = 1
                            OBJ_define()
                          end
                        end   
                },   
              { txt = '|'..is_dirty..'Save playlist',
                func =  function()  
                          local out_str = ''
                          for i = 1, #playlist do out_str = out_str..playlist[i].path..'\n' end                          
                          local f = io.open(playlist.fn, 'w')                          
                          f:write(out_str)
                          f:close()
                        end       
                },                                            
              { txt = '|Save playlist to /REAPER/MPL ProjectPlaylist/(timestamp)',
                func =  function()  
                          local out_str = ''
                          RecursiveCreateDirectory( playlists_path, 0 )
                          r, UI = GetUserInputs('Save playlist', 1, 'new name', 'playlist')
                          if r then 
                            local timest = os.date():gsub('%:', '-')
                            timest = os.date('%Y-%m-%d - %H-%M-%S')
                            local fp = playlists_path..UI..' - '..timest..'.rpl'
                            for i = 1, #playlist do out_str = out_str..playlist[i].path..'\n' end                          
                            local f = io.open(fp, 'w')                          
                            f:write(out_str)
                            f:close()
                            playlist.fn = fp
                            r2 = MB( 'Reload playlist?', '', 4 )
                            if r2 == 5 then 
                              Actions_ReloadPlaylist(fp)                            
                            end
                          end
                        end
                },
              { txt = '|Open /REAPER/MPL ProjectPlaylist path',
                func =  function()  
                          local OS, cmd = GetOS()                          
                          if OS:find("OSX") then cmd = 'open' else cmd = 'start' end
                          os.execute(cmd..' "" "' .. playlists_path .. '"')
                        end
                },
              { txt = '||Refresh GUI',
                func =  function()  
                          playlist = {}
                          Actions_AddOpenedProjectsToPlaylist() 
                          redraw = 1
                          OBJ_define()
                        end
              }   ,
              { txt = '|'..is_docked..'Dock GUI',
                func =  function()  
                          dock_state = gfx.dock(-1)
                          gfx.dock(math.abs(1-dock_state))
                        end
              }   ,
              { txt = '|Show shortcuts',
                func =  function()  
                          MB(
[[
Space - Transport: Play/stop active tab
Up arrow - Previous tab
Down arrow - Next tab
Tab - SWS/S&M: Focus main window (close others)
Ctrl+Alt+K - SWS/S&M: Save List of Open Project, reload playlist 
]]                          
                          
                          ,'Keyboard shortcuts',0)
                        end
              }        
                       
            }
    local str = ""
    for i = 1, #str_t do str = str..str_t[i].txt end
    local ret = gfx.showmenu(str)
    if ret > 0 then str_t[ret].func() end
  end
  ---------------------------------------------------
  function OBJ_define()  
    obj.offs = 2
    obj.menu_b_h = 15
    obj.it_h = item_height
    obj.grad_sz = 300 -- gradient rect
    obj.proj_playb_w = 20
    obj.scrollbar_w = 10
    
    obj.scrollbar = {x = gfx.w-obj.scrollbar_w,
                y = 0,--obj.menu_b_h,
                w= obj.scrollbar_w,
                h =gfx.h,---obj.menu_b_h,
                a = 0.8,
                grad_blit_h_coeff = 1,
                grad_blit_rot = 0,
                txt = '',
                draw_dyn = true}    
                               
                    
    --[[obj.menu = {x = gfx.w-obj.scrollbar_w,
                y = 0,
                w= obj.scrollbar_w,
                h = obj.menu_b_h,
                a = 0.2,
                grad_blit_h_coeff = 1,
                grad_blit_rot = 0,
                txt = 'M',
                func = function() Menu() end}]]
                
    for i = 1, #playlist do
      if ValidatePtr2( nil, playlist[i].ptr, 'ReaProject*' ) then 
        --[[obj['PLitem_play_'..i] = {x = 0,
                         y = obj.it_h*(i-1),
                         w = obj.proj_playb_w,
                         h = obj.it_h,
                         txt = '',
                         a = 1,
                         grad_blit_h_coeff = 0.3,
                         grad_blit_rot = 180,
                         func = function()           
                                  local state = GetPlayStateEx( playlist[i].ptr ) == 1                   
                                  if state then OnStopButtonEx( playlist[i].ptr  )
                                   else OnPlayButtonEx( playlist[i].ptr ) end
                                end}   ]]   
        if not playlist[i].ID then playlist[i].ID = 0 end
        obj['PLitem_'..i] = {x = -1,--obj.proj_playb_w,
                         y = obj.it_h*(i-1),
                         w = gfx.w-obj.scrollbar_w,---obj.proj_playb_w,
                         h = obj.it_h,
                         txt = i..'. '..GetProjectName( playlist[i].ptr, '' ):sub(0,-5),
                         a = 1,
                         leftaligned = true,
                         grad_blit_h_coeff = 0.3,
                         grad_blit_rot = 180,func = function()                                 
                                  SelectProjectInstance( playlist[i].ptr )
                                  redraw = 1
                                  OBJ_Update()
                                end}
      end
    end        
  end
  ---------------------------------------------------
  function OBJ_Update()
    for i = 1, max_proj_cnt do
      local retval, projfn=  EnumProjects( i-1, '' )
      if projfn == '' then break end
      for j = 1, #playlist do
        if playlist[j].ptr == retval then playlist[j].ID = i end
      end
    end  
    
    obj.blit_h = obj.it_h * #playlist
    
    obj.scrollbar.x = gfx.w-obj.scrollbar_w
    obj.scrollbar.h = gfx.h * lim( gfx.h/obj.blit_h , 0, 1)
    --(gfx.h-obj.menu_b_h ) * lim( gfx.h/obj.blit_h , 0, 1)
    obj.scrollbar.y = obj.blit_offs * (gfx.h - obj.scrollbar.h)
    --obj.menu.x = gfx.w-obj.scrollbar_w
    
    for i = #playlist , 1, -1 do 
      if not ValidatePtr2( nil, playlist[i].ptr, 'ReaProject*' ) then
        obj['PLitem_'..i] = nil
        table.remove(playlist, i)
        redraw =1
      end
    end
          
    for i = 1, #playlist do 
      if  ValidatePtr2( nil, playlist[i].ptr, 'ReaProject*' ) and obj['PLitem_'..i] then 
        obj['PLitem_'..i].w = gfx.w-obj.scrollbar_w--obj.proj_playb_w
        obj['PLitem_'..i].active = EnumProjects( -1, '' ) == playlist[i].ptr
        if obj['PLitem_'..i].active then
          obj.active_item = i
          
        end
        obj['PLitem_'..i].playstate = GetPlayStateEx( playlist[i].ptr ) == 1
        obj['PLitem_'..i].mouse_offs_y = -lim(obj.it_h * #playlist - gfx.h, 0, gfx.h) * obj.blit_offs
        --[[obj['PLitem_play_'..i].mouse_offs_y = obj['PLitem_'..i].mouse_offs_y
        if GetPlayStateEx( playlist[i].ptr ) == 1 then obj['PLitem_play_'..i].txt = '>'
         else obj['PLitem_play_'..i].txt = '|'  end]]
        if GetProjectLength( playlist[i].ptr ) > 0 then 
          if GetPlayStateEx( playlist[i].ptr ) == 1 then 
            obj['PLitem_'..i].progress = lim(GetPlayPositionEx( playlist[i].ptr ) / GetProjectLength( playlist[i].ptr ),0,1) 
           else
            obj['PLitem_'..i].progress = lim( GetCursorPositionEx( playlist[i].ptr ) / GetProjectLength( playlist[i].ptr ),0,1) 
          end
        end
      end  
    end
    
    if obj.last_active_item and obj.active_item and obj.active_item ~= obj.last_active_item then 
      shift_to_tab = true
    end
    
    if shift_to_tab then
      if obj['PLitem_'..obj.active_item].y+obj['PLitem_'..obj.active_item].mouse_offs_y  > gfx.h - obj.it_h  then  
        obj.blit_offs = lim(obj.blit_offs + 0.08, 0, 1)
        redraw = 1
       elseif obj['PLitem_'..obj.active_item].y+obj['PLitem_'..obj.active_item].mouse_offs_y  < 0  then 
        obj.blit_offs = lim(obj.blit_offs - 0.08, 0, 1)
        redraw = 1
       else
        shift_to_tab = false
      end
    end
    
    obj.last_active_item = obj.active_item
    
  end
 ---------------------------------------------------
  local function MOUSE_Match(b) 
    if not b.mouse_offs_y then b.mouse_offs_y = 0 end
    if not b.ignore_mouse then 
      return mouse.mx > b.x 
        and mouse.mx < b.x+b.w 
        and mouse.my > b.y+b.mouse_offs_y
        and mouse.my < b.y+b.mouse_offs_y+b.h 
    end 
  end
 --------------------------------------------------- 
  local function MOUSE_Click(b) return MOUSE_Match(b) and mouse.LMB_state and not mouse.last_LMB_state end
  ---------------------------------------------------    
  local function MOUSE()
    mouse.mx = gfx.mouse_x
    mouse.my = gfx.mouse_y
    mouse.LMB_state = gfx.mouse_cap&1 == 1 
    mouse.RMB_state = gfx.mouse_cap&2 == 2 
    mouse.MMB_state = gfx.mouse_cap&64 == 64
    mouse.LMB_state_doubleclick = false
    mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
    mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
    mouse.Shift_state = gfx.mouse_cap&8 == 8
    mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
    mouse.wheel = gfx.mouse_wheel
    if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end 
    if mouse.LMB_state and not mouse.last_LMB_state then  mouse.last_mx_onclick = mouse.mx     mouse.last_my_onclick = mouse.my end    
    if mouse.last_mx_onclick and mouse.last_my_onclick then mouse.dx = mouse.mx - mouse.last_mx_onclick  mouse.dy = mouse.my - mouse.last_my_onclick else mouse.dx, mouse.dy = 0,0 end
    
    -- butts    
      for key in pairs(obj) do 
        if type(obj[key]) == 'table'then 
          if MOUSE_Match(obj[key]) then mouse.context = key end
          if MOUSE_Click(obj[key]) then           
            mouse.context_latch = key
            if obj[key].func  then 
              obj[key].func() break 
            end 
          end           
        end 
      end
    
    -- drag
      drag_mode = mouse.LMB_state and mouse.context and mouse.context_latch and mouse.context_latch ~= ''
      if drag_mode then
        drag_id_src = mouse.context_latch:match('[%d]+') if drag_id_src then drag_id_src = tonumber(drag_id_src) end
        drag_id_dest = mouse.context:match('[%d]+') if drag_id_dest then drag_id_dest = tonumber(drag_id_dest) end
        if mouse.my < 0 then 
          obj.blit_offs = lim(obj.blit_offs - 0.05, 0,1)
         elseif mouse.my > gfx.h then 
          obj.blit_offs = lim(obj.blit_offs + 0.05, 0,1)
        end
      end
      if last_drag_mode and not drag_mode and drag_id_dest and drag_id_src then
        local entry = playlist[drag_id_src]
        table.remove(playlist, drag_id_src)
        table.insert(playlist, drag_id_dest, entry)
        drag_id_src, drag_id_dest = nil, nil 
        OBJ_define()
        OBJ_Update()
        redraw = 1
      end
      
    -- scrollbar      
      if  obj.it_h * #playlist > gfx.h - obj.menu_b_h  then
        if MOUSE_Click(obj.scrollbar) then blit_offs_latch = obj.blit_offs end
        if mouse.context_latch and mouse.context_latch == 'scrollbar' then
          obj.blit_offs = lim(blit_offs_latch + mouse.dy/100)
        end
      end
      
      if mouse.wheel_trig then obj.blit_offs = lim(obj.blit_offs - mouse.wheel_trig/1200, 0,1) end
    if mouse.LMB_state and MOUSE_Match({x=0,y=0,w=gfx.w,h=gfx.h}) then OBJ_Update() redraw = 1 end
    
    if not mouse.last_RMB_state and mouse.RMB_state then Menu() end
    
    -- mouse release    
      last_drag_mode = drag_mode
      if mouse.last_LMB_state and not mouse.LMB_state   then  mouse.context_latch = '' end
      mouse.last_LMB_state = mouse.LMB_state  
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state 
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_Alt_state = mouse.Alt_state
      mouse.last_wheel = mouse.wheel      
  end
  ---------------------------------------------------
  local function Actions_Shift_Tab(add)
    if not obj.active_item then return end
    local id = obj.active_item + add , 1, #playlist
    if id < 1 then id = #playlist elseif id > #playlist then id = 1 end
    if playlist[id] then SelectProjectInstance( playlist[id].ptr ) end
  end
  ---------------------------------------------------
  local function Actions_StopAllTabs()
    for i = 1, #playlist do if playlist[i].ptr then reaper.OnStopButtonEx( playlist[i].ptr ) end end
  end
  ---------------------------------------------------
  local function SHORTCUTS(chr)
    if        chr == 32 and not mouse.Shift_state    then Main_OnCommand(40044, 0) -- Transport: Play/stop active tab // Space
     elseif   chr == 30064  then Actions_Shift_Tab(-1)
     elseif   chr == 1685026670  then Actions_Shift_Tab(1)
     elseif   chr == 32 and mouse.Shift_state then Actions_StopAllTabs()
     elseif   chr == 9 then Main_OnCommand(NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'), 0)-- SWS/S&M: Focus main window (close others)
     elseif   chr == 019 then 
      reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_PROJLISTSAVE'),0)-- SWS/S&M: Save List of Open Project 
      Actions_ReloadPlaylist()
     elseif   chr == 015 then reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_PROJLISTSOPEN'),0)-- SWS/S&M: Open Projects from List  
    end
  end
  ---------------------------------------------------
  local function run()
    SCC =  GetProjectStateChangeCount( 0 ) if not lastSCC or lastSCC ~= SCC then SCC_trig = true else SCC_trig = false end lastSCC = SCC
    clock = os.clock()
    cycle = cycle+1
    local st_wind = HasWindXYWHChanged()
    if st_wind == -1 then 
      redraw = -1 
     elseif st_wind == 1 then
      redraw = 1
      --OBJ_define()
      ExtState_Save()
     elseif st_wind == 2 then
      ExtState_Save()      
    end
    
    
    OBJ_Update()
    GUI_draw()
    MOUSE()
     chr = gfx.getchar()
     chr_ms = gfx.mouse_cap
    SHORTCUTS(chr)
    if  chr>= 0 
      and chr ~= 27 
      and not (chr == 331 and chr_ms == 24)  then defer(run) else atexit(gfx.quit) end
  end
  ---------------------------------------------------
  local function GUI_define()
    gui = {
                aa = 1,
                mode = 3,
                fontname = global_font_name,
                fontsz = global_font_size,
                col = { grey =    {0.5, 0.5,  0.5 },
                        white =   {1,   1,    1   },
                        red =     {1,   0,    0   },
                        green =   {0,   1,    0.3   },
                        blue =    {0,   0,    1}
                      }
                
                }
    
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz = gui.fontsz - 3 end
  end
  ---------------------------------------------------
  ExtState_Load()  
  gfx.init('MPL ProjectPlaylist '..vrs,conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
  Actions_AddOpenedProjectsToPlaylist()
  OBJ_define()
  GUI_define()
  run()
  
  