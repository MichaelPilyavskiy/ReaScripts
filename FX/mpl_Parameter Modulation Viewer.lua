-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description MPL Parameter Modulation Viewer
-- @website http://forum.cockos.com/member.php?u=70694

  
  --  INIT -------------------------------------------------  
  local vrs = 1.0
  local global_font_size = 15
  local global_font_name = 'Arial'
  debug = 0
  local mouse = {}
  local gui -- see GUI_define()
  local obj = {blit_offs = 0}
  L = {success = 0}
   conf = {}
  local cycle = 0
  local redraw = 1
  local SCC, lastSCC, SCC_trig,drag_mode,last_drag_mode
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  --local data
  b_offs = 0
---------------------------------------------------
  local function msg(s) ShowConsoleMsg(s..'\n') end
---------------------------------------------------
  function Action_CreateLink_TakeDest()
    local ret, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX() 
    if not ret then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    GetTrInfo( tr)
    if not ret then return end 
    L.destfx = fxnumber
    L.destpar = paramnumber
    L.desttracknumber = tracknumber
    obj.get_PM_dest.txt = 'DEST: '..({reaper.TrackFX_GetFXName( tr, fxnumber, '' )})[2]..' / '..({TrackFX_GetParamName( tr, fxnumber, paramnumber, '' )})[2]
  end
  --------------------------------------------------- 
  function Action_CheckLink()
    L.check_exists_dest = false
    if L.destpar and L.destfx then 
      for i =1, #data do
        if L.destfx == data[i].slave_fx_id and L.destpar == data[i].slave_param_num then 
          check_exists = true
          L.check_exists_dest = true
          break
        end
      end
    end
    if (L.tracknumber and L.desttracknumber and L.tracknumber == L.desttracknumber) and
     (L.destfx and L.srcfx and L.destpar and L.srcpar and not
      (L.srcfx == L.destfx and L.srcpar == L.destpar) ) and
     not L.check_exists_dest then 
      L.success = 1      
     else
      L.success = 0
    end
  end
  --------------------------------------------------- 
  function Action_CreateLink()
    if not L  then reaper.MB( 'Missed source and destination parameters (get it from last touched parameter first)', 'Error', 0 ) return end
    if not L.destfx  then reaper.MB( 'Missed destination parameter (get it from last touched parameter first)', 'Error', 0 ) return end
    if not L.srcfx  then reaper.MB( 'Missed source parameter (get it from last touched parameter first)', 'Error', 0 ) return end
    if L.tracknumber 
      and L.desttracknumber
      and L.tracknumber ~= L.desttracknumber then reaper.MB( 'REAPER support parameter linking only beetween same track', 'Error', 0 ) return end
    if L.check_exists_dest then reaper.MB( 'Modulation for destination parameter already exists', 'Error', 0 ) return end
    
    
    local tr = reaper.CSurf_TrackFromID( L.tracknumber, false )
    
local insert_chunk = 
[[
<PROGRAMENV ]]..L.destpar..[[ 0
PARAMBASE 0
LFO 0
LFOWT 1 1
AUDIOCTL 0
AUDIOCTLWT 1 1
PLINK 1 ]]..L.srcfx..':'..L.srcfx-L.destfx..'  '..L.srcpar..[[ 0
    >
    ]]  
      local _, chunk = reaper.GetTrackStateChunk(  tr, '', false )
      local dest_fxGUID = reaper.TrackFX_GetFXGUID( tr, L.destfx):gsub('-','')
      local t= {} for line in chunk:gmatch('[^\n\r]+') do t[#t+1] = line end
      for i = 1, #t do  local line = t[i]  if line:gsub('-',''):match(dest_fxGUID) then fxguid_chunkpos = i break end end
      if fxguid_chunkpos then table.insert(t, fxguid_chunkpos+1, insert_chunk) end
      local out_chunk = table.concat(t, '\n')
      reaper.SetTrackStateChunk(  tr, out_chunk, true )
      reaper.ClearConsole()
      --reaper.ShowConsoleMsg(out_chunk)]]
  
  end  
---------------------------------------------------      
  function Action_CreateLink_TakeSrc()          
    local ret, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX() 
    if not ret then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    GetTrInfo( tr)
    if not ret then return end 
    L.srcfx = fxnumber
    L.srcpar = paramnumber
    L.tracknumber = tracknumber
    obj.get_PM_src.txt = 'SRC: '..({reaper.TrackFX_GetFXName( tr, fxnumber, '' )})[2]..' / '..({TrackFX_GetParamName( tr, fxnumber, paramnumber, '' )})[2]
    
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
  local function GUI_DrawObj(o)
    col('white')
    if not o then return end 
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    
    -- gradient back
      gfx.a = o.a or 0.3
      gfx.blit( 2, 1, math.rad(o.grad_blit_rot),
                0,0,  obj.grad_sz,math.ceil(obj.grad_sz*o.grad_blit_h_coeff),
                x,y,w,h, 0,0)
      if o.col_txt then col(o.col_txt) end
    -- text
      gfx.a = 1
      gfx.setfont(1, gui.fontname, gui.fontsz  )
      local x_offs = 5
      gfx.x = x + (w-gfx.measurestr(txt))/2
      if o.leftaligned then gfx.x = x + x_offs end
      gfx.y = y+ (h-gfx.texth)/2
      gfx.drawstr(o.txt)
  end  
  ---------------------------------------------------
  local function FormGUI_str()  
    gfx.setfont(1, gui.fontname, gui.fontsz2  )
    local lines_cnt = 0
    if not data or not data.tr_name then return '' end
    local str = 'Track: '..data.tr_name..'\n'
    for i=1, #data do
      str = str
        ..'   -------------------------\n'
        --..' '..(data[i].slave_fx_id+1)..'.'
        ..'   '..data[i].slave_fx_name..' ('..(data[i].slave_fx_id+1)..')'..'\n'
        ..'     '..data[i].slave_param_name..'\n'
        ..'         '..data[i].lfo_str..'\n'
        ..'         '..data[i].aud_str..'\n'
        ..data[i].pm_offs
        ..data[i].pm_scale
        ..data[i].pm_fx_name
        ..data[i].pm_par_name
        
    end
    for line in str:gmatch('[^\n\r]+') do lines_cnt = lines_cnt+1 end
    return str, math.ceil(gfx.texth * lines_cnt)
  end
  ---------------------------------------------------
  function col(col_s, a) gfx.set( table.unpack(gui.col[col_s])) if a then gfx.a = a end  end
 ---------------------------------------------------
  local function GUI_draw_data(str)
    col('white')
    gfx.mode = 0
    gfx.x = 10
    gfx.y = 0--
    gfx.a = 1
    gfx.setfont(1, gui.fontname, gui.fontsz2  )
    
    if not data or not data.tr_name then gfx.drawstr('') return end
    gfx.drawstr(str)
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
        OBJ_update()
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
    
    if redraw == 1 then 
      for key in pairs(obj) do if type(obj[key]) == 'table' then GUI_DrawObj(obj[key]) end  end
      gfx.dest = 3
      local str, h =FormGUI_str() 
      gfx.setimgdim(3, -1, -1)  
      gfx.setimgdim(3, gfx.w, h) 
      gfx.a = 1
      GUI_draw_data(str)
    end
      
    --  render    
      gfx.dest = -1  
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      --  back
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
      local bl_w,bl_h = gfx.getimgdim(3 )    
      bl_space_h = bl_h-(gfx.h-(obj.menu_b_h+obj.offs)*3)
      gfx.blit(3, 1, 0, -- info
          0,b_offs * bl_space_h,gfx.w, bl_h,
          0,(obj.menu_b_h+obj.offs)*3
            ,gfx.w, bl_h, 0,0)          
    redraw = 0
    gfx.update()
  end  
  ---------------------------------------------------
  local function ExtState_Def()
    return {ES_key = 'MPL_ParMod_viewer',
            wind_x =  40,
            wind_y =  60,
            wind_w =  400,
            wind_h =  600,
            dock =    0}
  end
 --------------------------------------------------- 
  local function MOUSE_Click(b) return MOUSE_Match(b) and mouse.LMB_state and not mouse.last_LMB_state end
  ---------------------------------------------------
    local function GUI_define()
    gui = {
                aa = 1,
                mode = 3,
                fontname = global_font_name,
                fontsz = global_font_size,
                fontsz2 = global_font_size-1,
                col = { grey =    {0.5, 0.5,  0.5 },
                        white =   {1,   1,    1   },
                        red =     {0.8,   0.2,    0.2   },
                        green =   {0,   1,    0.3   },
                        blue =    {0,   0,    1}
                      }
                
                }
    
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz = gui.fontsz - 3 end
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
    
    -- scroll
      local y_break = (obj.menu_b_h+obj.offs)*3
      if ({gfx.getimgdim(3 ) })[2] + y_break > gfx.h then
        if mouse.my > y_break and mouse.LMB_state and not mouse.last_LMB_state then 
          mouse.catch_offs = b_offs
        end
        if mouse.LMB_state and mouse.catch_offs then 
          b_offs = math.max(0, math.min(mouse.catch_offs - mouse.dy/100, 1))
        end
      end
       
    -- mouse release    
      last_drag_mode = drag_mode
      if mouse.last_LMB_state and not mouse.LMB_state   then  
        mouse.context_latch = '' 
        mouse.catch_offs = nil 
      end
      mouse.last_LMB_state = mouse.LMB_state  
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state 
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_Alt_state = mouse.Alt_state
      mouse.last_wheel = mouse.wheel      
  end  
  local function GetFxNamebyGUID(guid, fx_names)
    for key in pairs(fx_names) do
      if guid:match(key) then return fx_names[key] end
    end
  end
    
  ---------------------------------------------------
  function GetTrInfo(tr0)
    data = {}
    local tr 
    if not tr0 then tr = GetSelectedTrack(0,0) else tr = tr0 end
    if not tr then return end
    -- name
      data.tr_name =  ({GetTrackName( tr, '' )})[2]
    -- fx names
      local fx_names = {}
      for fx =1,  TrackFX_GetCount( tr ) do
        local guid = TrackFX_GetFXGUID( tr, fx-1 ):gsub('-',''):match('{.-}')
        guid = guid:gsub('[{}]','')
        fx_names[guid] = {id = fx-1,
                          name = ({reaper.TrackFX_GetFXName( tr, fx-1, '' )})[2]}
      end
    
    -- chunk stuff
      local _, chunk = GetTrackStateChunk(  tr, '', false )
      local t= {} for line in chunk:gmatch('[^\n\r]+') do t[#t+1] = line end
      local collect_chunk = false
      local look_FXGUID = nil
      for i = 1, #t do 
        local line = t[i]
        if line:match('FXID') then look_FXGUID = line:gsub('-',''):match('{.-}') end
        if line:match('PROGRAMENV') then collect_chunk = '' end
        if collect_chunk and look_FXGUID then collect_chunk = collect_chunk..'\n'..line end
        if collect_chunk  and line:match('>') then 
          look_FXGUID = look_FXGUID:gsub('[{}]','')
          local fx_gett = GetFxNamebyGUID(look_FXGUID, fx_names)
          local fx_name =fx_gett.name
          local fx_id = fx_gett.id
          local param_num = tonumber(collect_chunk:match('[%d]+'))
          local param_name =  ({TrackFX_GetParamName( tr, fx_id, param_num, '' )})[2]
          
          local lfo_str = collect_chunk:match('LFO %d')
          if lfo_str and lfo_str:match('1') then lfo_str = 'LFO: Enabled' else lfo_str = 'LFO: Disabled' end
          
          local aud_str = collect_chunk:match('AUDIOCTL %d')
          if aud_str and aud_str:match('1') then aud_str = 'AudioControl: Enabled' else aud_str = 'AudioControl: Disabled' end
          
          local plink_str = collect_chunk:match('PLINK .-[\n]')
          local pm_offs,pm_scale,pm_par,pm_fx, pm_fx_name,pm_par_name ='','','','','',''
          if plink_str then 
            local t2 = {}
            for num in plink_str:gmatch('[%d%p]+') do t2[#t2+1]  = num end
            pm_offs = '         Link: offset '..math.floor(t2[1]*100)..'%\n'
            pm_scale = '         Link: scale '..math.floor(t2[4]*100)..'%\n'
            pm_par = tonumber(t2[3])
            pm_fx = tonumber(t2[2]:match('[%d]+'))
            pm_par_name = '         SourceParam: '..({TrackFX_GetParamName( tr, pm_fx, pm_par, '' )})[2]..'\n'
            pm_fx_name = ({reaper.TrackFX_GetFXName( tr,pm_fx, '' )})[2]
            if fx_id == pm_fx then pm_fx_name = pm_fx_name..' (self)' end
            pm_fx_name = '         SourceFX: '..pm_fx_name..'\n'
          end
          data[#data+1] = {ch = collect_chunk ,
                           slave_fx_name =fx_name,
                           slave_fx_id=fx_id,
                           slave_param_num = param_num,
                           slave_param_name=param_name,
                           lfo_str=lfo_str,
                           aud_str=aud_str,
                           plink_str=plink_str,
                           pm_offs = pm_offs,
                           pm_scale = pm_scale,
                           pm_par_name = pm_par_name,
                           pm_fx_name = pm_fx_name}
          
          
          collect_chunk = nil 
          --look_FXGUID = nil
        end
      end
    --msg(chunk)
    
  end
  ---------------------------------------------------
  function OBJ_update()
    local col_txt
    if L.success == 1 then obj.createPM.col_txt = 'green' else obj.createPM.col_txt = 'red' end
  end    
  ---------------------------------------------------
  function OBJ_define()  
    obj.offs = 2
    obj.menu_b_h = 25
    obj.menu_b_w = gfx.w
    obj.it_h = item_height
    obj.grad_sz = 300 -- gradient rect
    obj.link_w = obj.menu_b_h*2 + obj.offs
    obj.gettrinfo = {x = 0,
                y = 0,
                w= obj.menu_b_w,
                h = obj.menu_b_h,
                a = 0.2,
                grad_blit_h_coeff = 1,
                grad_blit_rot = 0,
                txt = 'Get/Update selected track info',
                func = function() GetTrInfo() redraw = 1 end}
    obj.get_PM_src = {x = 0,
                y = obj.menu_b_h+obj.offs,
                w= obj.menu_b_w-obj.link_w-obj.offs,
                h = obj.menu_b_h,
                a = 0.2,
                grad_blit_h_coeff = 1,
                grad_blit_rot = 0,
                txt = 'Get source parameter',
                func = function() Action_CreateLink_TakeSrc() Action_CheckLink() redraw = 1 end}     
    obj.get_PM_dest = {x = 0,
                y = (obj.menu_b_h+obj.offs)*2,
                w= obj.menu_b_w-obj.link_w-obj.offs,
                h = obj.menu_b_h,
                a = 0.2,
                grad_blit_h_coeff = 1,
                grad_blit_rot = 0,
                txt = 'Get destination parameter',
                func = function() Action_CreateLink_TakeDest() Action_CheckLink() redraw = 1 end}   
    obj.createPM = {x = obj.menu_b_w-obj.link_w,
                y = obj.menu_b_h+obj.offs,
                w= obj.link_w,
                h = obj.menu_b_h*2+obj.offs,
                a = 0.2,
                col_txt = col_txt,
                grad_blit_h_coeff = 1,
                grad_blit_rot = 0,
                txt = 'Link',
                func = function() Action_CreateLink() GetTrInfo() redraw = 1 end}                                           
  end  
  ---------------------------------------------------
  local function ExtState_Save()
    conf.dock, conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h = gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
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
      ExtState_Save()
     elseif st_wind == 2 then
      ExtState_Save()      
    end    
    
    GUI_draw()
    MOUSE()
     chr = gfx.getchar()
     chr_ms = gfx.mouse_cap
    if  chr>= 0 
      and chr ~= 27 
      and not (chr == 331 and chr_ms == 24)  then defer(run) else atexit(gfx.quit) end
  end
---------------------------------------------------  
  ExtState_Load()  
gfx.init('MPL Parameter Modulation Viewer '..vrs, conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
OBJ_define()
GUI_define()
GetTrInfo()
run()