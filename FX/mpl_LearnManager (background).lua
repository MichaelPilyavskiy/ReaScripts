-- @description LearnManager
-- @version 1.10
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Add support for load/save custom mappings (4 slots)
--    + Action: Show envelopes for mapped parameters (all in selected tracks)
--    + Action: Hide envelopes for mapped parameters
--    + Action: Remove parameter from mapping by ID
--    + Action: Remove OSC mappings
--    + Action: Remove MIDI mappings
--    + Action: Clear mapping
--    + Action: Change MIDI mappings to specific channel
--    + Action: Build dummy mapping from TCP controls
--    + Action: Build dummy mapping from FX envelopes
--    + Action: Build mapping by incrementing OSC address
--    + Action: Build mapping by incrementing MIDI CC
--    # highlight buttons
--    # fix update tracklist after showing envelopes
--    # fix replacing multiple empty lines in learn chunks

  local vrs = '1.10'  
  local scr_title = 'LearnManager'
  --NOT gfx NOT reaper
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local mouse = {}
  data = {}
  local gui -- see GUI_define()
  local obj = {}
  local conf = {}
  local cycle = 0
  local redraw = -1
  local SCC, lastSCC, SCC_trig, clock,ProjState
  
  
  ---------------------------------------------------
  local gui = {
                aa = 1,
                mode = 3,
                fontname = 'Calibri',
                fontsz = 18,
                fontsz2 = 16,
                col = { grey =    {0.5, 0.5,  0.5 },
                        white =   {1,   1,    1   },
                        red =     {1,   0,    0   },
                        green =   {0.3,   0.9,    0.3   }
                      }
                
                }
    
  if GetOS():match('OSX') then 
    gui.fontsz = gui.fontsz - 7 
    gui.fontsz2 = gui.fontsz2 - 7 
  end
  ---------------------------------------------------
  local function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------
  local function ExtState_Save()
    _, conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h = gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
  end
  ---------------------------------------------------
  local function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  local function col(col_s, a) gfx.set( table.unpack(gui.col[col_s])) if a then gfx.a = a end  end
  ---------------------------------------------------
  local function GUI_DrawBut(o) 
    if not o then return end
    local x,y,w,h, txt = o.x, o.y, o.w, o.h, o.txt
    if not x or not y or not w or not h then return end
    local txt_offs = 5
    gfx.a = o.alpha_back or 0.3
    gfx.blit( 2, 1, 0, -- grad back
              0,0,  obj.grad_sz,obj.grad_sz,
              x,y,w,h, 0,0)
    col(o.col, o.alpha_back or 0.2)
    gfx.rect(x,y,w,h,1)
    if o.frame_a and o.use_frame then
      col(o.col, o.frame_a)
      gfx.rect(x+1,y,w-1,h-1,1)
    end
    if o.txt then 
      col('white', o.alpha_txt or 0.8)
      gfx.setfont(1, gui.fontname, o.txtsz)
      gfx.x = x+ (w-gfx.measurestr(txt))/2
      if o.txt_align_left then gfx.x = x + txt_offs end
      if o.txt_align_right then gfx.x = x+ w - txt_offs - gfx.measurestr(txt) end
      gfx.y = y+ (h-gfx.texth)/2
      if o.txt_align_top then gfx.y = y + txt_offs end
      gfx.drawstr(o.txt)
    end
    if o.rect_a then 
      col(o.col, o.alpha_back or 0.2)
      gfx.rect(x,y,w,h,0)
    end
  end
  ---------------------------------------------------
  local function GUI_draw()
    gfx.mode = 0
    -- redraw: -1 init, 1 maj changes, 2 minor changes
    -- 1 back
    -- 2 gradient
    --// 3 dynamic stuff
      
    --  init
      if redraw == -1 then
        OBJ_Update()
        gfx.dest = 2
        gfx.setimgdim(2, -1, -1)  
        gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 0.9,0.9,1,0.6
        gfx.x, gfx.y = 0,0
        local c = 0.6
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
        redraw = 1 -- force com redraw after init 
      end
      
    -- refresh
      if redraw == 1 then 
        OBJ_Update()
        -- refresh backgroung
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          gfx.blit( 2, 1, 0, -- grad back
                    0,0,  obj.grad_sz,obj.grad_sz,
                    0,0,  gfx.w,gfx.h, 0,0)
          gfx.a = 0.2
          gfx.line(gfx.w/2, obj.item_h+obj.item_h2,gfx.w/2, gfx.h )
        -- refresh all buttons
          for key in pairs(obj) do
            if not key:match('knob') and type(obj[key]) == 'table' and obj[key].is_but then
              GUI_DrawBut(obj[key])
            end
          end        
      end
      
      
    --  render    
      gfx.dest = -1   
      gfx.a = 1
      gfx.x,gfx.y = 0,0
    --  back
      gfx.blit(1, 1, 0, -- backgr
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
    
    
    redraw = 0
    gfx.update()
  end
  ---------------------------------------------------
  function HasWindXYWHChanged()
    local  _, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    local retval=0
    if wx ~= obj.last_gfxx or wy ~= obj.last_gfxy then retval= 2 end --- minor
    if ww ~= obj.last_gfxw or wh ~= obj.last_gfxh then retval= 1 end --- major
    if not obj.last_gfxx then retval = -1 end
    obj.last_gfxx, obj.last_gfxy, obj.last_gfxw, obj.last_gfxh = wx,wy,ww,wh
    return retval
  end
  ---------------------------------------------------
  local function ExtState_Def()
    return {ES_key = 'MPL_'..scr_title,
            wind_x =  50,
            wind_y =  50,
            wind_w =  400,
            wind_h =  300,
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
  function SaveCurrentMapping(slot)
    if not data.FX_name or not data0.type_t then return end
    --local ini_path_BU = GetResourcePath()..'/reaper-fxlearn.ini-backup'
    --[[ create backup
    local f_bu = io.open(ini_path_BU, 'w')
    f_bu:write(context)
    f_bu:close()]]
    ---------
    local context,replace_str,add_new,context_full,ini_path
    
    if slot > 0 then 
      CheckAddCustomMap()
      GetSlotContext(slot)
      ini_path = GetResourcePath()..'/reaper-fxlearn_extended.ini'
      local f = io.open(ini_path, 'r')
      if not f then return end
      context_full = f:read('a')
      context = context_full:match('<SLOT'..slot..'(.-)>')
      f:close()
      
     else
     
      ini_path = GetResourcePath()..'/reaper-fxlearn.ini'    
      local f = io.open(ini_path, 'r')
      if not f then 
        f = io.open(ini_path, 'w')
        f:write()
        f:close()
        context = ''
        return 
       else
        context = f:read('a')
        f:close()
      end      
    end
    
    replace_str = context:match('(%['..literalize(data.FX_name)..'.-)%[')
    if not replace_str then replace_str = context:match('%['..literalize(data.FX_name)..'.*') end
    if not replace_str then add_new = true end
    if not add_new and not replace_str then return end
    
    ---------
    local add_str = '['..data.FX_name..']'
    local cnt = 0
    for key in spairs(data.lrn) do
      add_str = add_str..'\np'..cnt..'='
        ..key..','
        ..data.lrn[key].MIDI_int..','
        ..'5'
      if data.lrn[key].OSC_str and data.lrn[key].OSC_str ~= '' then add_str = add_str..','..data.lrn[key].OSC_str end
      cnt = cnt +1 
    end
    add_str = add_str..'\n'..'numparm='..cnt
    ---------
    if not add_new then   
      if replace_str then    
        context =context:gsub(literalize(replace_str), '') 
        context =context..add_str
      end
     else 
      context =context..add_str
    end
    
    --local ret = MB('Overwrite default mapping?', scr_title, 4)
    --if ret then 
    
    if slot == 0 then
      f = io.open(ini_path, 'w')
      f:write(context)
      f:close()
      return true
     else
      f = io.open(ini_path, 'w')
      context_full = context_full:gsub('<SLOT'..slot..'.->','')
      context_full = context_full..'\n<SLOT'..slot..'\n'..context..'\n>'      
      context_full = context_full:gsub('\n\n', '\n')
      --ClearConsole()
      --msg(context_full)
      f:write(context_full)
      f:close()
      return true      
    end
  end
  ---------------------------------------------------
  function CountFXEnv(track)
        local tr_chunk = eugen27771_GetTrackStateChunk( track )
        local t_ret = ''
        local t = {} for line in tr_chunk:gmatch('[^\r\n]+') do t[#t+1] = line  end
        local check_str = literalize(data.FX_GUID)
        local search,line_id
        for i = 1, #t do
          if search and t[i]:match('WAK') then break end
          if search then 
            if t[i]:match('PARMENV') then 
              t_ret = t_ret..' '..t[i]:match('PARMENV ([%d]+)')
            end
          end
          if t[i]:match(check_str) then search = true end
        end
        return t_ret
  end
  
  ---------------------------------------------------
  function ClearTCP(track, return_existed_only)
        local tr_chunk = eugen27771_GetTrackStateChunk( track )
        local t_ret = ''
        local t = {} for line in tr_chunk:gmatch('[^\r\n]+') do t[#t+1] = line  end
        local check_str = literalize(data.FX_GUID)
        local search,line_id
        for i = 1, #t do
          if search and t[i]:match('WAK') then break end
          if search then 
            if t[i]:match('PARM_TCP') then 
              if return_existed_only then t_ret = t[i] end
              t[i] = '\n' 
            end
          end
          if t[i]:match(check_str) then search = true end
        end
        local out_chunk = table.concat(t, '\n'):gsub('(\n\n)', '')
        if not return_existed_only then
          SetTrackStateChunk( track, out_chunk, true )
         else 
          return t_ret
        end
  end
  ---------------------------------------------------
  function CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[CopyTable(orig_key)] = CopyTable(orig_value)
          end
          setmetatable(copy, CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end  
  ---------------------------------------------------
  function ApplyMappingToFX(mode, src_t, track0, fx_guid0)
    if not src_t then src_t = CopyTable(data) end
    if not src_t or not src_t.lrn then return end
    
    -- GET CHUNK DATA
      local track 
      if track0 then track = track0 else track = data.TR_ptr end
      if fx_guid0 then fx_guid = fx_guid0 else fx_guid = data.FX_GUID end
      
      if not track then return end
      local tr_chunk = eugen27771_GetTrackStateChunk( track )
      if not tr_chunk then return end
      local t = {} for line in tr_chunk:gmatch('[^\r\n]+') do t[#t+1] = line  end
      local check_str = literalize(fx_guid)
      local search,line_id
      for i = 1, #t do
        if search and t[i]:match('WAK') then break end
        if search then 
          if t[i]:match('PARMLEARN') then t[i] = '' end
        end
        if t[i]:match(check_str) then search = true line_id = i end
      end
    
    -- GENERATE NEW DATA
    local function form_lrn_str(t,i)
      return 'PARMLEARN '
                  ..i..' '
                  ..t.lrn[i].MIDI_int..' '
                  ..'5'..' '
                  ..t.lrn[i].OSC_str
                  ..'\n'
    end
    
    --------------------------- MODES 
    local add_str = ''
    
    if mode == 0 then -- add/replace
      for i = 1, #data.param_names do
        if src_t.lrn[i] then
          add_str = add_str ..form_lrn_str(src_t, i)
         elseif data.lrn[i] then 
          add_str = add_str ..form_lrn_str(data, i)
        end
      end
      
     elseif mode == 1 then -- add only
      for i = 1, #data.param_names do
        if src_t.lrn[i] and not data.lrn[i] then
          add_str = add_str ..form_lrn_str(src_t, i)
         elseif data.lrn[i] then 
          add_str = add_str ..form_lrn_str(data, i)
        end
      end  

     elseif mode == 2 then -- clear/add
      for i = 1, #data.param_names do
        if src_t.lrn[i] then
          add_str = add_str ..form_lrn_str(src_t, i)
        end
      end        
         
    end
    
    ------------------------
    --- APPLY DATA
    if line_id then
      t[line_id] = t[line_id]..'\n'..add_str..'\n\n\n'
      local out_chunk = table.concat(t, '\n'):gsub('(\n\n)', '\n')
      --msg(out_chunk)
      SetTrackStateChunk( track, out_chunk, false )
    end
    src_t = nil
  end
  ---------------------------------------------------
  function SetEnvProp(envelope, visible)
     local BR_env = reaper.BR_EnvAlloc( envelope, false )
     local active, _, armed, inLane,laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties( BR_env )
     reaper.BR_EnvSetProperties( BR_env, active, visible, armed, inLane, laneHeight, defaultShape, faderScaling )
     reaper.BR_EnvFree( BR_env, true )
   end
  ---------------------------------------------------
  function OBJ_define()  
    obj.offs = 2
    obj.grad_sz = 200
    obj.item_h = 40
    obj.item_h2 = 20
    
    obj.get = { x = 0,
                y = 0,
                h = obj.item_h,
                txt = "Last Touched FX: Update info",
                col = 'white',
                state = 0,
                use_frame = true,
                is_but = true,
                txtsz = gui.fontsz,
                alpha_back = 0.3,
                func =  function() 
                          UpdateInfo() 
                          --ParseMap()
                          redraw = 1                       
                        end}
                                                        
    obj.t1type = { x = 0,
                y = obj.item_h + obj.item_h2,
                h = obj.item_h2*2,
                txt = "Current mapping",
                --txt_align_left = true,
                --txt_align_top = true,
                use_frame = true,
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz2,
                alpha_back = 0.1,
                func = function()
                  Menu({  {str = 'Save mapping to default / slotX (current right table)',
                           func = function()                        
                                    if data0 and data0.type_t then            
                                      local ret = SaveCurrentMapping(data0.type_t)
                                      if ret then 
                                        ParseMap(data0.type_t)
                                        redraw = 1 
                                      end 
                                    end
                                  end
                          },
                          {str = 'Apply to all FX instances on selected tracks',
                           func = function() 
                                    if not  data.FX_name then return end  
                                    for i = 1, CountSelectedTracks(0) do
                                      local tr = GetSelectedTrack(0,i-1)
                                      if tr ~= data.TR_ptr then
                                        for fxid = 1, TrackFX_GetCount( tr ) do
                                          local fx_name = ({TrackFX_GetFXName( tr, fxid-1, '' )})[2]
                                          if fx_name == data.FX_name then 
                                            local fx_guid = TrackFX_GetFXGUID( tr, fxid-1 )
                                            ApplyMappingToFX(2, data, tr, fx_guid)
                                          end
                                        end
                                      end
                                    end
                                    
                                  end
                          },                          
                          
                          {str = '|Show TCP controls for mapped parameters',
                           func = function()  
                                    if data.lrn then
                                      for key in spairs(data.lrn) do
                                        SNM_AddTCPFXParm( data.TR_ptr, data.FX_id, key )
                                      end
                                      UpdateInfo() 
                                      redraw = 1 
                                    end                              
                                  end
                          },    
                          {str = 'Show TCP controls for mapped parameters (all in selected tracks)',
                           func = function()  
                                   if not  data.FX_name then return end  
                                    for i = 1, CountSelectedTracks(0) do
                                      local tr = GetSelectedTrack(0,i-1)
                                      for fxid = 1, TrackFX_GetCount( tr ) do
                                        local fx_name = ({TrackFX_GetFXName( tr, fxid-1, '' )})[2]
                                        if fx_name == data.FX_name then 
                                          if data.lrn then
                                            for key in spairs(data.lrn) do
                                              SNM_AddTCPFXParm( tr,  fxid-1, key )
                                            end
                                          end  
                                        end
                                      end
                                    end                           
                                    UpdateInfo() 
                                    redraw = 1                             
                                  end
                          },                           
                          {str = 'Clear TCP controls',
                           func = function()  
                                    if not data.TR_ptr then return end
                                    ClearTCP(data.TR_ptr)
                                  end
                          },                          
                          {str = '|Show envelopes for mapped parameters',
                           func = function()  
                                    if data.lrn then
                                      for key in spairs(data.lrn) do
                                        GetFXEnvelope(  data.TR_ptr, data.FX_id, key, true )
                                      end
                                      UpdateInfo() 
                                      redraw = 1 
                                      UpdateArrange()
                                      TrackList_AdjustWindows( false )
                                    end                              
                                  end
                          },         
                          {str = 'Show envelopes for mapped parameters (all in selected tracks)',
                           func = function()  
                                    if data.lrn then
                                    for i = 1, CountSelectedTracks(0) do
                                      local tr = GetSelectedTrack(0,i-1)
                                      for fxid = 1, TrackFX_GetCount( tr ) do
                                        local fx_name = ({TrackFX_GetFXName( tr, fxid-1, '' )})[2]
                                        if fx_name == data.FX_name then 
                                          if data.lrn then
                                            for key in spairs(data.lrn) do
                                              GetFXEnvelope(  tr, fxid-1, key, true )
                                            end
                                          end  
                                        end
                                      end
                                    end    
                                    UpdateInfo() 
                                    UpdateArrange()
                                    TrackList_AdjustWindows( false )
                                    redraw = 1 
                                    end                              
                                  end
                          },                          
                          
                                                                  
                          {str = 'Hide envelopes for mapped parameters',
                           func = function()  
                                    if data.lrn then
                                      for key in spairs(data.lrn) do
                                        local env = GetFXEnvelope(  data.TR_ptr, data.FX_id, key, true )
                                        SetEnvProp(env, false)
                                      end
                                      UpdateInfo() 
                                      redraw = 1 
                                      UpdateArrange()
                                    end                              
                                  end
                          },                           
                          {str = '|Remove parameter from mapping by ID',
                           func = function()  
                                    local ret, ID = GetUserInputs(scr_title, 1, 'Remove learn for parameter', '0')
                                    if ret then
                                      if tonumber(ID) then
                                        data.lrn[tonumber(ID)] = nil
                                        ApplyMappingToFX(2, data)
                                        UpdateInfo() 
                                        redraw = 1  
                                      end
                                    end                 
                                  end
                          },  
                          {str = 'Remove OSC mappings',
                           func = function()  
                                    if data.lrn then
                                      local t_keys = {}
                                      for key in spairs(data.lrn) do if data.lrn[key].OSC_str ~= '' then t_keys[#t_keys+1] = key end   end
                                      for i = 1, #t_keys do data.lrn[ t_keys[i] ] = nil end
                                      ApplyMappingToFX(2, data)
                                      UpdateInfo() 
                                      redraw = 1 
                                    end                                                      
                                  end
                          },  
                          {str = 'Remove MIDI mappings',
                           func = function()  
                                    if data.lrn then
                                      local t_keys = {}
                                      for key in spairs(data.lrn) do if data.lrn[key].MIDI_int > 0 then t_keys[#t_keys+1] = key end   end
                                      for i = 1, #t_keys do data.lrn[ t_keys[i] ] = nil end
                                      ApplyMappingToFX(2, data)
                                      UpdateInfo() 
                                      redraw = 1 
                                    end                                                      
                                  end
                          },    
                          {str = 'Change MIDI mappings to specific channel',
                           func = function()  
                                    if data.lrn then
                                      local ret, ID = GetUserInputs(scr_title, 1, 'Set MIDI channel', '1')
                                      if ret and tonumber(ID) then
                                        local new_ch = math.floor(tonumber(ID))
                                        if new_ch < 1 or new_ch > 12 then return end
                                        for key in spairs(data.lrn) do 
                                          if data.lrn[key].MIDI_int > 0 then 
                                            local midi_int = (data.lrn[key].MIDI_CC << 8) | 0xB0 + (new_ch - 1) 
                                            data.lrn[key].MIDI_int = midi_int
                                          end
                                        end
                                        ApplyMappingToFX(2, data)
                                        UpdateInfo() 
                                        redraw = 1 
                                      end
                                    end                                                      
                                  end
                          },       
                          {str = 'Clear mapping',
                           func = function()  
                                    if data.lrn then
                                      data.lrn = {}
                                      ApplyMappingToFX(2, data)
                                      UpdateInfo() 
                                      redraw = 1 
                                    end                                                      
                                  end
                          },                                               
                          {str = '|Build dummy mapping from TCP controls',
                           func = function()  
                                    if data.lrn then
                                      local tcp = ClearTCP(data.TR_ptr, true)
                                      t = {}
                                      for num in tcp:gmatch('[%d]+') do if tonumber(num) then t[#t+1] = tonumber(num) end end
                                      data.lrn = {}
                                      for i = 1, #t do
                                        data.lrn[ t[i] ] = {MIDI_int = 0,
                                                          OSC_str = '(dummy)'}
                                      end
                                      ApplyMappingToFX(2, data)
                                      UpdateInfo() 
                                      redraw = 1 
                                    end                                                      
                                  end
                          },    
                          {str = 'Build dummy mapping from FX envelopes',
                           func = function()  
                                    if data.lrn then
                                      local fx_env_ids = CountFXEnv(data.TR_ptr)
                                      local t = {}  for num in fx_env_ids:gmatch('[%d]+') do if tonumber(num) then t[#t+1] = tonumber(num) end end
                                      data.lrn = {}
                                      for i = 1, #t do
                                        data.lrn[ t[i] ] = {MIDI_int = 0,
                                                          OSC_str = '(dummy)'}
                                      end
                                      ApplyMappingToFX(2, data)
                                      UpdateInfo() 
                                      redraw = 1 
                                    end                                                      
                                  end
                          },                            
                          {str = 'Build mapping by incrementing OSC address',
                           func = function()  
                                    if data.lrn then
                                      local ret, str = GetUserInputs('Build mapping by incrementing OSC address', 1, 'Set OSC adress,extrawidth=200', '/some_address')
                                      if ret and str ~= '' then
                                        local i = 1
                                        for key in spairs(data.lrn) do 
                                          data.lrn[key] = {MIDI_int = 0,
                                                              OSC_str = str..i}
                                          i = i + 1
                                        end
                                        ApplyMappingToFX(2, data)
                                        UpdateInfo() 
                                      end
                                      redraw = 1 
                                    end                                                      
                                  end
                          },   
                          {str = 'Build mapping by incrementing MIDI CC',
                           func = function()  
                                    if data.lrn then
                                      local ret, ID = GetUserInputs('Build mapping by incrementing MIDI CC', 1, 'Set MIDI Channel', '1')
                                      if ret and tonumber(ID) then
                                        local new_ch = math.floor(tonumber(ID))
                                        if new_ch < 1 or new_ch > 12 then return end                                      
                                        local ret2, CC = GetUserInputs('Build mapping by incrementing MIDI CC', 1, 'Set MIDI CC', '1')
                                        if ret2 and tonumber(CC) then
                                          local CC = tonumber(CC)                                          
                                          for key in spairs(data.lrn) do 
                                            if CC < 0 or CC > 127 then 
                                              break 
                                            end
                                            data.lrn[key].MIDI_CC = CC
                                            data.lrn[key].MIDI_Ch = new_ch
                                            data.lrn[key].MIDI_int = (CC << 8) | 0xB0 + (new_ch - 1)                                             
                                            data.lrn[key].OSC_str = ''
                                            CC = CC+ 1
                                          end
                                          ApplyMappingToFX(2, data)
                                          UpdateInfo()
                                          redraw = 1
                                        end
                                      end
                                    end                                                      
                                  end
                          },                                                      
                                                                                                                           
                        })
                        end} 
                
    obj.t2type = { x = 0,
                y = obj.item_h + obj.item_h2,
                h = obj.item_h2*2,
                txt = '(no type selected)',
                --txt_align_left = true,
                --txt_align_right = true,
                --txt_align_top = true,
                use_frame = true,
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz2,
                alpha_back = 0.1,
                func = function()
                  Menu({  {str = 'Add to current mapping, replace existed',
                           func = function()                                    
                                    ApplyMappingToFX(0, data0)
                                    UpdateInfo() 
                                    redraw = 1
                                  end
                          },
                          {str = 'Add to current mapping, prevent replacing',
                           func = function()                                    
                                    ApplyMappingToFX(1, data0)
                                    UpdateInfo() 
                                    redraw = 1
                                  end
                          },
                          {str = 'Add to current mapping, clear current',
                           func = function()                                    
                                    ApplyMappingToFX(2, data0)
                                    UpdateInfo() 
                                    redraw = 1
                                  end
                          },
                          {str = '|Load default mapping',
                           func = function() ParseMap() redraw = 1 end },
                          {str = 'Load custom mapping slot 1',
                           func = function() ParseMap(1) redraw = 1 end },
                          {str = 'Load custom mapping slot 2',
                           func = function() ParseMap(2) redraw = 1 end },
                          {str = 'Load custom mapping slot 3',
                           func = function() ParseMap(3) redraw = 1 end },
                          {str = 'Load custom mapping slot 4',
                           func = function() ParseMap(4) redraw = 1 end },                                                                                                            
                        })
                        end}                   
                               
    obj.t1 = { x = 0,
                y = obj.item_h + obj.item_h2*3,
                h = gfx.h - obj.item_h - obj.item_h2*3,
                txt = "(no data)",
                txt_align_left = true,
                txt_align_top = true,
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz2,
                alpha_back = 0}    
                    
    obj.t2 = { 
                y = obj.item_h + obj.item_h2*3,
                h = gfx.h - obj.item_h - obj.item_h2*3,
                txt = "(no data)",
                txt_align_left = true,
                txt_align_top = true,
                col = 'white',
                state = 0,
                is_but = true,
                txtsz = gui.fontsz2,
                alpha_back = 0}                        
    
                      
  end
  ---------------------------------------------------
  function OBJ_Update()
    if data.FX_name or data.TR_name then
      
      obj.fxname = { x = 0,
              y = obj.item_h,
              w = gfx.w,
              h = obj.item_h2,
              col = 'white',   
              txtsz= gui.fontsz2,  
              txt=   data.TR_name..'  / '..data.FX_name ,  
              state = 0,
              is_but = true,
              alpha_back = 0.2} 
    end
    obj.get.w = gfx.w
    
    obj.t1type.w = math.floor(gfx.w/2)
    obj.t2type.x = math.floor(gfx.w/2)
    obj.t2type.w = math.floor(gfx.w/2)
    
    local str_cur_learn = GenerateButtonTxt(data)
    obj.t1.w = math.floor(gfx.w/2)
    obj.t1.txt = str_cur_learn
    
    local dest_learn = GenerateButtonTxt(data0)
    obj.t2.x = math.floor(gfx.w/2)
    obj.t2.w = math.floor(gfx.w/2)
    obj.t2.txt = dest_learn
  end
  ---------------------------------------------------
  function CheckAddCustomMap()
    local ini_path = GetResourcePath()..'/reaper-fxlearn_extended.ini'
    local f = io.open(ini_path, 'r')
    if not f then 
      f = io.open(ini_path, 'w')
      f:write('')
      f:close()
    end
  end
  ---------------------------------------------------
  function GetSlotContext(slot) local create
    local ini_path = GetResourcePath()..'/reaper-fxlearn_extended.ini'
    local f = io.open(ini_path, 'r')
    if not f then return end
    local context_full = f:read('a')
    local context = context_full:match('<SLOT'..slot..'(.-)>')
    if not context then create = true end
    f:close()
    
    if create == true then
      f = io.open(ini_path, 'a+')
      f:write('\n<SLOT'..slot..'\n>')
      f:close()
      return ''
    end
    
    return context
  end
  ---------------------------------------------------
  function ParseMap(slot)
    CheckAddCustomMap()
    data0 = {lrn = {}}
    if not data.FX_name or data.FX_name == '' then return end
    data0.FX_name = data.FX_name
    
    local context = ''
    if not slot or slot == 0 then
      obj.t2type.txt = 'Default mapping'
      data0.type_t = 0
      local ini_path = GetResourcePath()..'/reaper-fxlearn.ini'
      local f = io.open(ini_path, 'r')
      if not f then 
        return 
       else
        context = f:read('a')
        f:close()
      end
     else
      context = GetSlotContext(slot)
      obj.t2type.txt = 'Custom mapping: slot '..slot
      data0.type_t = slot
    end
      
    local ini_str = context:match('(%['..literalize(data.FX_name)..'.-)%[')
    if not ini_str then ini_str = context:match('%['..literalize(data.FX_name)..'.*') end
    if not ini_str then return end
    for line in ini_str:gmatch('[^\r\n]+') do 
      if line:match('p[%d]+=') then 
        local t = {} 
        for csv in line:gmatch('[^%,%=]+') do t[#t+1] = csv end
        local par_idx = tonumber(t[2])
        if par_idx then
          local isMIDI = tonumber(t[3]) > 0
          local OSC_str, MIDI_Ch, MIDI_CC
          if not isMIDI then 
            OSC_str = t[5]
           else
            MIDI_Ch = 1 +t[3] & 0x0F
            MIDI_CC = t[3] >> 8 
            OSC_str = '' 
          end
          data0.lrn[par_idx] = {OSC_str = OSC_str,
                              MIDI_Ch= MIDI_Ch,
                              MIDI_CC = MIDI_CC,
                              MIDI_int = tonumber(t[3])
                              }
        end
      end 
    end
      
      
  end
  ---------------------------------------------------
  function GenerateButtonTxt(t)
    if not t or not t.FX_name or not data.param_names then return end
    local ind = ' '
    local str = ''
    for key in spairs(t.lrn) do
      if data.param_names[tonumber(key)] then 
        str = str..'#'..key..' '..data.param_names[tonumber(key)+1]
        if t.lrn[key].OSC_str and t.lrn[key].OSC_str ~= ''  then
          str = str..':'..ind:rep(2)..'OSC '..t.lrn[key].OSC_str..'\n'
         elseif t.lrn[key].MIDI_Ch then
          str = str..':'..ind:rep(2)..'MIDI Channel '..t.lrn[key].MIDI_Ch..' CC '..t.lrn[key].MIDI_CC..'\n'
         elseif t.lrn[key].MIDI_Ch == 0 and t.lrn[key].OSC_str ~= '' then
          str = str..':'..'(dummy)\n\n'
        end
      end
    end
    return str
  end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
  ---------------------------------------------------
  function Menu(t)
    local str, check = '', ''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      str = str..check..t[i].str..'|'
    end
    gfx.x = mouse.mx
    gfx.y = mouse.my
    local ret = gfx.showmenu(str)
    if ret > 0 then if t[ret].func then t[ret].func() end end
  end
  ---------------------------------------------------
  function eugen27771_GetTrackStateChunk(track)
    if not track then return end
    local fast_str, track_chunk
    fast_str = SNM_CreateFastString("")
    if SNM_GetSetObjectState(track, fast_str, false, false) then track_chunk = SNM_GetFastString(fast_str) end
    SNM_DeleteFastString(fast_str)  
    return track_chunk
  end  
  ---------------------------------------------------
  function UpdateInfo()
    -- get chunk data
      local retval, tracknumberOut, _, fxnumberOut = GetFocusedFX()
      --local retval, tracknumberOut, fxnumberOut = GetLastTouchedFX()
      if not retval or fxnumberOut < 0 then return end
      local track = CSurf_TrackFromID( tracknumberOut, false )
      local GUID = TrackFX_GetFXGUID( track, fxnumberOut )
      if not track then return end
      data= { FX_GUID = GUID,
              FX_id = fxnumberOut,
              FX_name = ({TrackFX_GetFXName( track, fxnumberOut, '' )})[2],
              TR_GUID = GetTrackGUID( track ),
              TR_name  = ({GetTrackName( track, '' )})[2],
              TR_ptr = track,
              lrn = {},
              param_names = {}
              }
             
      for i = 1,  TrackFX_GetNumParams( track, fxnumberOut ) do
        data.param_names[ #data.param_names + 1 ]= ({TrackFX_GetParamName( track, fxnumberOut, i-1, '' )})[2]     
      end
      
      local tr_chunk = eugen27771_GetTrackStateChunk( track)
      if not tr_chunk or not GUID then return end
      local str = tr_chunk:match(literalize(GUID)..'(.-)WAK')
      if not str then return end
      for line in str:gmatch('[^\r\n]+') do
        if line:find('PARMLEARN') then
          local t = {}
          for val in line:gmatch('[^%s]+') do t[#t+1] = val end
          local par_idx = tonumber(t[2])
          local isMIDI = tonumber(t[3]) > 0
          local OSC_str, MIDI_Ch, MIDI_CC
          if not isMIDI then 
            OSC_str = t[5]
           else
            MIDI_Ch = 1 +t[3] & 0x0F
            MIDI_CC = t[3] >> 8  
            OSC_str = ''
          end
          data.lrn[par_idx] = {
                              OSC_str = OSC_str,
                              MIDI_Ch= MIDI_Ch,
                              MIDI_CC = MIDI_CC,
                              MIDI_int = tonumber(t[3])
                              }
        end
      end
    
  end
  ---------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end
 ---------------------------------------------------
  local function MOUSE_Match(b) if b.x and b.y and b.w and b.h then return mouse.mx > b.x and mouse.mx < b.x+b.w and mouse.my > b.y and mouse.my < b.y+b.h end  end
 ------------- -------------------------------------- 
  local function MOUSE_Click(b) return MOUSE_Match(b) and mouse.LMB_state and not mouse.last_LMB_state end
  local function MOUSE_ClickR(b) return MOUSE_Match(b) and mouse.RMB_state and not mouse.last_RMB_state end
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
    mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
    mouse.wheel = gfx.mouse_wheel
    if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end 
    if mouse.LMB_state and not mouse.last_LMB_state then  mouse.last_mx_onclick = mouse.mx     mouse.last_my_onclick = mouse.my end    
    if mouse.last_mx_onclick and mouse.last_my_onclick then mouse.dx = mouse.mx - mouse.last_mx_onclick  mouse.dy = mouse.my - mouse.last_my_onclick else mouse.dx, mouse.dy = 0,0 end

    -- butts    
    for key in pairs(obj) do
      if not key:match('knob') and type(obj[key]) == 'table'and obj[key].is_but then
        if MOUSE_Match(obj[key]) then obj[key].frame_a = 0.3 else obj[key].frame_a = 0 end
        if MOUSE_Click(obj[key]) and obj[key].func then obj[key].func() end
      end
    end
          
    if mouse.last_mouse and mouse.last_mouse ~= mouse.mx  + mouse.my then
      redraw = 1
    end
    mouse.last_mouse = mouse.mx  + mouse.my
    
    -- mouse release    
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
  function run()
    SCC =  GetProjectStateChangeCount( 0 ) 
    if not lastSCC or lastSCC ~= SCC then SCC_trig = true else SCC_trig = false end lastSCC = SCC
    clock = os.clock()
    cycle = cycle+1
    local st_wind = HasWindXYWHChanged()
    if st_wind >= -1 then ExtState_Save() if math.abs(st_wind) == 1 then redraw = st_wind  end end
    if SCC_trig then redraw = -1 end
    MOUSE()
    GUI_draw()
    if gfx.getchar() >= 0 then defer(run) else atexit(gfx.quit) end
  end
  ---------------------------------------------------
  ExtState_Load()  
  gfx.init('MPL '..scr_title..' v'..vrs,conf.wind_w, conf.wind_h, conf.dock, conf.wind_x, conf.wind_y)
  OBJ_define()
  OBJ_Update()
  UpdateInfo()
  ParseMap()
  run()