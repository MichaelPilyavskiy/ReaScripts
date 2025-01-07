-- @description Randomize Track FX parameters
-- @version 3.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=233358
-- @changelog
--    # small tweaks


--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.3.2'
     
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 640,
          viewport_posH = 480, 
          
          -- filter
          CONF_filter_all = 0, -- 
          CONF_filter_untitledparams = 0, -- untitled / reserved
          CONF_filter_system = 0, -- bypas wet delta
          CONF_filter_Keywords1str = 'preview solo mute active master dry wet bypass',
          CONF_filter_Keywords1 = 1,                          
          CONF_filter_Keywords2str = 'att dec sust rel',
          CONF_filter_Keywords2 = 1,
          CONF_filter_Keywords3str = 'lfo osc pitch',
          CONF_filter_Keywords3 = 1,
          CONF_filter_Keywords4str = 'arp eq porta chor delay unison pitchbend',
          CONF_filter_Keywords4 = 0,
          CONF_filter_Keywords5str = 'gain vol input power feed mix out make level limit peak velocity',
          CONF_filter_Keywords5 = 0,
          CONF_filter_Keywords6str = 'ctrl control midi upsmpl upsampl render oversamp alias auto resvd meter depr sign aud dest',
          CONF_filter_Keywords6 = 0,
          CONF_filter_Keywords7str = 'sync core',
          CONF_filter_Keywords7 = 0,
          CONF_filter_Keywords8str = 'mode type priority',
          CONF_filter_Keywords8 = 0,
          CONF_filter_invert = 0 ,
          CONF_filter_formatstrings = 0,
          
          -- other 
          CONF_smooth = 0, -- seconds
        }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          ES_key = 'mpl_randomizefxparams',
          UI_name = 'Randomize FX parameters', 
          upd = true, 
          
          FX={},
          Keywords_num = 8,
          morphstate = 0,
          }
          
  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
            -- font
              font='Arial',
              font1sz=15,
            -- mouse
              hoverdelay = 0.8,
              hoverdelayshort = 0.8,
            -- size / offset
              spacingX = 4,
              spacingY = 3,
            -- colors / alpha
              main_col = 0x7F7F7F, -- grey
              textcol = 0xFFFFFF,
              textcol_a_enabled = 1,
              textcol_a_disabled = 0.5,
              but_hovered = 0x878787,
              windowBg = 0x303030,
          }

          
UI.main_buth = 60
              
 --[[   UI.font2sz=14
    UI.font3sz=12
  -- special 
    UI.butBg_green = 0x00B300
    UI.butBg_red = 0xB31F0F
  
  -- MP
  -- size
    UI.main_butw = 150
    UI.main_butclosew = 20
    UI.flowchildW = 600
    UI.flowchildH = UI.main_buth*8
    UI.plotW = UI.flowchildW - 200
    UI.plotH = UI.main_buth
  ]]
  
  
  
  
  
  
  
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
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
  -------------------------------------------------------------------------------- 
  function ImGui.PushStyle(key, value, value2)  
    if not (ctx and key and value) then return end
    local iscol = key:match('Col_')~=nil
    local keyid = ImGui[key]
    if not iscol then 
      ImGui.PushStyleVar(ctx, keyid, value, value2)
      if not UI.pushcnt_var then UI.pushcnt_var = 0 end
      UI.pushcnt_var = UI.pushcnt_var + 1
    else 
      if not value2 then
        ReaScriptError( key ) 
       else
        ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
        if not UI.pushcnt_col then UI.pushcnt_col = 0 end
        UI.pushcnt_col = UI.pushcnt_col + 1
      end
    end 
  end
  -------------------------------------------------------------------------------- 
  function ImGui.PopStyle_var()  
    if not (ctx) then return end
    ImGui.PopStyleVar(ctx, UI.pushcnt_var)
    UI.pushcnt_var = 0
  end
  -------------------------------------------------------------------------------- 
  function ImGui.PopStyle_col()  
    if not (ctx) then return end
    ImGui.PopStyleColor(ctx, UI.pushcnt_col)
    UI.pushcnt_col = 0
  end 
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
    
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
      --window_flags = window_flags | ImGui.WindowFlags_NoMove()
      window_flags = window_flags | ImGui.WindowFlags_NoResize
      window_flags = window_flags | ImGui.WindowFlags_NoCollapse
      --window_flags = window_flags | ImGui.WindowFlags_NoNav()
      --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
      window_flags = window_flags | ImGui.WindowFlags_NoDocking
      window_flags = window_flags | ImGui.WindowFlags_TopMost
      window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      --window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings()
      --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
      --open = false -- disable the close button
    
    
      -- rounding
        ImGui.PushStyle('StyleVar_FrameRounding',5)   
        ImGui.PushStyle('StyleVar_GrabRounding',3)  
        ImGui.PushStyle('StyleVar_WindowRounding',10)  
        ImGui.PushStyle('StyleVar_ChildRounding',5)  
        ImGui.PushStyle('StyleVar_PopupRounding',0)  
        ImGui.PushStyle('StyleVar_ScrollbarRounding',9)  
        ImGui.PushStyle('StyleVar_TabRounding',4)   
      -- Borders
        ImGui.PushStyle('StyleVar_WindowBorderSize',0)  
        ImGui.PushStyle('StyleVar_FrameBorderSize',0) 
      -- spacing
        ImGui.PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
        ImGui.PushStyle('StyleVar_FramePadding',10,UI.spacingY) 
        ImGui.PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
        ImGui.PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
        ImGui.PushStyle('StyleVar_ItemInnerSpacing',4,0)
        ImGui.PushStyle('StyleVar_IndentSpacing',20)
        ImGui.PushStyle('StyleVar_ScrollbarSize',10)
      -- size
        ImGui.PushStyle('StyleVar_GrabMinSize',20)
        ImGui.PushStyle('StyleVar_WindowMinSize',w_min,h_min)
      -- align
        ImGui.PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
        ImGui.PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      -- alpha
        ImGui.PushStyle('StyleVar_Alpha',0.98)
        ImGui.PushStyle('Col_Border',UI.main_col, 0.3)
      -- colors
        ImGui.PushStyle('Col_Button',UI.main_col, 0.2) --0.3
        ImGui.PushStyle('Col_ButtonActive',UI.main_col, 1) 
        ImGui.PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
        ImGui.PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
        ImGui.PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
        ImGui.PushStyle('Col_FrameBgActive',UI.main_col, .6)
        ImGui.PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
        ImGui.PushStyle('Col_Header',UI.main_col, 0.5) 
        ImGui.PushStyle('Col_HeaderActive',UI.main_col, 1) 
        ImGui.PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
        ImGui.PushStyle('Col_PopupBg',0x303030, 0.9) 
        ImGui.PushStyle('Col_ResizeGrip',UI.main_col, 1) 
        ImGui.PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
        ImGui.PushStyle('Col_SliderGrab',UI.butBg_green, 0.4) 
        ImGui.PushStyle('Col_Tab',UI.main_col, 0.37) 
        ImGui.PushStyle('Col_TabHovered',UI.main_col, 0.8) 
        ImGui.PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
        ImGui.PushStyle('Col_TitleBg',UI.main_col, 0.7) 
        ImGui.PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
        ImGui.PushStyle('Col_WindowBg',UI.windowBg, 1)
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      w,h = 480,430
      ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font1) 
      local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
      if rv then
        local Viewport = ImGui.GetWindowViewport(ctx)
        DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
        DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
        DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetSize(Viewport) 
        
      -- calc stuff for childs
        UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
        local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
        local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
        UI.calc_itemH = calcitemh + frameh * 2
        UI.calc_butW = math.floor(DATA.display_w - UI.spacingX*3)/2
        
      -- draw stuff
        UI.draw()
        ImGui.Dummy(ctx,0,0) 
        ImGui.PopStyle_var() 
        ImGui.PopStyle_col() 
        ImGui.End(ctx)
       else
        ImGui.PopStyle_var() 
        ImGui.PopStyle_col() 
      end 
      ImGui.PopFont( ctx ) 
      if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
    
      return open
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_UIloop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
    
    
    if DATA.morphstate == 1 then DATA:SetParameters() end
    
    --if DATA.upd == true then  DATA:CollectData()  end 
    DATA.upd = false
    
    -- draw UI
    UI.open = UI.MAIN_styledefinition(true) 
    
    -- handle xy
    DATA:handleViewportXYWH()
    -- data
    if UI.open then defer(UI.MAIN_UIloop) end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_definecontext()
    
    EXT:load() 
    
    -- imgUI init
    ctx = ImGui.CreateContext(DATA.UI_name) 
    -- fonts
    DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
    --DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
    --DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
    -- config
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
    
    
    -- run loop
    defer(UI.MAIN_UIloop)
  end
  -------------------------------------------------------------------------------- 
  function EXT:save() 
    if not DATA.ES_key then return end 
    for key in pairs(EXT) do 
      if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
        SetExtState( DATA.ES_key, key, EXT[key], true  ) 
      end 
    end 
    EXT:load()
  end
  -------------------------------------------------------------------------------- 
  function EXT:load() 
    if not DATA.ES_key then return end
    for key in pairs(EXT) do 
      if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
        if HasExtState( DATA.ES_key, key ) then 
          local val = GetExtState( DATA.ES_key, key ) 
          EXT[key] = tonumber(val) or val 
        end 
      end  
    end 
    DATA.upd = true
  end
  -------------------------------------------------------------------------------- 
  function DATA:handleViewportXYWH()
    if not (DATA.display_x and DATA.display_y) then return end 
    if not DATA.display_x_last then DATA.display_x_last = DATA.display_x end
    if not DATA.display_y_last then DATA.display_y_last = DATA.display_y end
    if not DATA.display_w_last then DATA.display_w_last = DATA.display_w end
    if not DATA.display_h_last then DATA.display_h_last = DATA.display_h end
    
    if  DATA.display_x_last~= DATA.display_x 
      or DATA.display_y_last~= DATA.display_y 
      or DATA.display_w_last~= DATA.display_w 
      or DATA.display_h_last~= DATA.display_h 
      then 
      DATA.display_schedule_save = os.clock() 
    end
    if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
      EXT.viewport_posX = DATA.display_x
      EXT.viewport_posY = DATA.display_y
      EXT.viewport_posW = DATA.display_w
      EXT.viewport_posH = DATA.display_h
      EXT:save() 
      DATA.display_schedule_save = nil 
    end
    DATA.display_x_last = DATA.display_x
    DATA.display_y_last = DATA.display_y
    DATA.display_w_last = DATA.display_w
    DATA.display_h_last = DATA.display_h
  end
  -------------------------------------------------------------------------------- 
  function DATA:handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
    local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
    local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
  end
  --------------------------------------------------------------------------------  
  function UI.draw_unsetbuttonstyle() ImGui.PopStyleColor(ctx,3) end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttonbackgtransparent() 
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0 )
  end
  --------------------------------------------------------------------------------  
  function UI.draw()  
    -- plugin info
    local txt = '[open plugin, then press "Print"]'
    if DATA.FX.UI_name then txt = DATA.FX.UI_name end
    UI.draw_setbuttonbackgtransparent() 
    ImGui.Button(ctx, txt) 
    UI.draw_unsetbuttonstyle()
    
    
    if ImGui.Button(ctx, 'Print plugin state',UI.calc_butW,UI.main_buth) then DATA:GetFocusedFXData() DATA:GetFocusedFXData_Filter() end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Morph',UI.calc_butW,UI.main_buth) then 
      DATA:GetFocusedFXData()
      DATA:GenerateRandomSnapshot()
      DATA:SetParameters()
    end
    
    
    
    
    
    local szw = 35
    -- catch params
    if ImGui.Checkbox(ctx, 'Filter FX Bypass / Wet / Delta', EXT.CONF_filter_system==1) then EXT.CONF_filter_system = EXT.CONF_filter_system~ 1 EXT:save() DATA:GetFocusedFXData_Filter() end  
    if ImGui.Checkbox(ctx, 'Filter untitled params', EXT.CONF_filter_untitledparams==1) then EXT.CONF_filter_untitledparams = EXT.CONF_filter_untitledparams~1 EXT:save() DATA:GetFocusedFXData_Filter() end
    if ImGui.Checkbox(ctx, 'Filter values without formatted numbers', EXT.CONF_filter_formatstrings==1) then EXT.CONF_filter_formatstrings = EXT.CONF_filter_formatstrings~1 EXT:save() DATA:GetFocusedFXData_Filter() end
    for key =1, DATA.Keywords_num do
      local retval, p_selected = ImGui.Selectable( ctx, 'Pass##a'..key, EXT['CONF_filter_Keywords'..key]==1, reaper.ImGui_SelectableFlags_None(), szw, 0 )
      if retval then
        if EXT['CONF_filter_Keywords'..key] == 1 then EXT['CONF_filter_Keywords'..key] = 0 else EXT['CONF_filter_Keywords'..key] = 1 end
        EXT:save() 
        DATA:GetFocusedFXData_Filter() 
        DATA.upd = true      
      end
      ImGui.SameLine(ctx)
      local retval, p_selected = ImGui.Selectable( ctx, 'Filter##f'..key, EXT['CONF_filter_Keywords'..key]==2, reaper.ImGui_SelectableFlags_None(), szw, 0 )
      if retval then
        if EXT['CONF_filter_Keywords'..key] == 2 then EXT['CONF_filter_Keywords'..key] = 0 else EXT['CONF_filter_Keywords'..key] = 2 end
        EXT:save() 
        DATA:GetFocusedFXData_Filter() 
        DATA.upd = true      
      end
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth( ctx, UI.calc_butW*2-szw*2-UI.spacingX )
      local retval, buf = reaper.ImGui_InputText( ctx, '##keyin'..key, EXT['CONF_filter_Keywords'..key..'str'], flagsIn, callbackIn )
      if retval then 
        EXT['CONF_filter_Keywords'..key..'str'] = buf 
        EXT:save() 
        DATA:GetFocusedFXData_Filter() 
        DATA.upd = true
      end
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then 
        EXT['CONF_filter_Keywords'..key..'str'] = EXTdefaults['CONF_filter_Keywords'..key..'str']
        EXT:save() 
        DATA:GetFocusedFXData_Filter() 
        DATA.upd = true
      end
    end
    
    if ImGui.BeginChild( ctx, '##options', 0, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then
      local retval, v = ImGui.SliderDouble( ctx, 'Smooth transition', EXT.CONF_smooth, 0, 10, '%.2fs', ImGui.SliderFlags_None)
      if retval then EXT.CONF_smooth = v EXT:save() end
      local retval, v = ImGui.SliderDouble( ctx, 'Manual change', DATA.morph_value, 0, 1, '%.2f%', ImGui.SliderFlags_None)
      if retval then DATA.morph_value = v DATA:SetParameters(true) end
      ImGui.EndChild( ctx)
    end
    
  end
  ----------------------------------------------------------------------------------------- 
  function main() 
    EXTdefaults = CopyTable(EXT)
    UI.MAIN_definecontext() 
    DATA:GetFocusedFXData()
    DATA:GetFocusedFXData_Filter()
  end  
  ---------------------------------------------------
  function VF_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if not s_out then return s else 
      if s_out ~= '' then return s_out else return s end
    end
  end
  --------------------------------------------------------------------  
  function DATA:GetFocusedFXData() -- also update to current params
    DATA.FX = {params = {}}
    
    -- get main stuff
    local retval, trackidx, itemidx, takeidx, fxnum, parm = reaper.GetTouchedOrFocusedFX( 1 )
    if not retval then return end
    local tr = GetTrack(-1, trackidx)
    if trackidx == -1 then tr = GetMasterTrack(-1) end
    
    local it = GetMediaItem( -1, itemidx ) 
    local func_str = 'TrackFX_'
    --[[if it then 
      local takeidx = (fxnum>>16)&0xFFFF 
      ptr = GetTake( it, takeidx ) 
      func_str = 'TakeFX_'
     else
      ptr = tr  
    end]]
    local ptr = tr 
    
    local ret, trname = GetTrackName(tr)
    local fx_GUID = _G[func_str..'GetFXGUID'](ptr, fxnum&0xFFFF)    
    local retval, buf = _G[func_str..'GetFXName'](ptr, fxnum&0xFFFF)
    local cnt_params = _G[func_str..'GetNumParams'](ptr, fxnum&0xFFFF)
    
    DATA.FX.ptr = ptr
    DATA.FX.func_str = func_str
    DATA.FX.cnt_params = cnt_params
    DATA.FX.cnt_params_filtered = 0
    DATA.FX.ptr = ptr
    DATA.FX.fx_GUID = fx_GUID
    DATA.FX.FXname_short = VF_ReduceFXname(buf)
    DATA.FX.trname = trname
    DATA.FX.params = {}
    DATA.FX.fxnum = fxnum&0xFFFF
    
    
    DATA.FX.UI_name = trname..' | '..DATA.FX.FXname_short..' | '..cnt_params..' parameters, '..DATA.FX.cnt_params_filtered..' filtered'
    
    for i = 1, cnt_params do
      local value = _G[func_str..'GetParamNormalized'](ptr, fxnum, i-1) 
      local retval, bufparam = _G[func_str..'GetParamName'](ptr, fxnum, i-1) 
      local retval, formatparam = _G[func_str..'GetFormattedParamValue'](ptr, fxnum, i-1) 
      local retval, step, smallstep, largestep, istoggle = _G[func_str..'GetParameterStepSizes'](ptr, fxnum, i-1) 
       
      local bufparam_check = bufparam:lower():gsub('%s+','_')
      
      DATA.FX.params[i] =
      { value = value,
        name=bufparam,
        formatparam=formatparam,
        istoggle=istoggle,
        bufparam_check=bufparam_check
      }
    end 
  end
  -------------------------------------------------------------------- 
  function DATA:GetFocusedFXData_Filter_Strings(formatparam)
    if EXT.CONF_filter_formatstrings == 1 and formatparam:match('[%d%.]+')==nil then return true end
  end
  -------------------------------------------------------------------- 
  function DATA:GetFocusedFXData_Filter()
    if not DATA.FX.func_str then return end
    local param_bypass = _G[DATA.FX.func_str..'GetParamFromIdent']( DATA.FX.ptr, DATA.FX.fxnum, ':bypass' )
    local param_wet = _G[DATA.FX.func_str..'GetParamFromIdent']( DATA.FX.ptr, DATA.FX.fxnum, ':wet' )
    local param_delta = _G[DATA.FX.func_str..'GetParamFromIdent']( DATA.FX.ptr, DATA.FX.fxnum, ':delta' )  
    DATA.FX.cnt_params_filtered = 0
    
    -- custom keywords
    local parse_globalfilt = {}
    for key = 1, DATA.Keywords_num do
      parse_globalfilt[key] = {}
      if EXT['CONF_filter_Keywords'..key..'str'] ~= '' then for word in EXT['CONF_filter_Keywords'..key..'str']:gmatch('[^%s]+') do parse_globalfilt[key][#parse_globalfilt[key]+1] = word end  end
    end
    
    
    local haspass for key = 1, DATA.Keywords_num do if EXT['CONF_filter_Keywords'..key] == 1 then  haspass = true break end end
    local hasfilt for key = 1, DATA.Keywords_num do if EXT['CONF_filter_Keywords'..key] == 2 then  hasfilt = true break end end
    
    -- loop through params
    for i = 1 , #DATA.FX.params do
      local bufparam_check = DATA.FX.params[i].bufparam_check
      local pass_temp1 = DATA:GetFocusedFXData_Filter_System(i-1,param_bypass,param_wet,param_delta)
      local pass_temp2 = DATA:GetFocusedFXData_Filter_Untitled(bufparam_check)
      local pass_temp3 = DATA:GetFocusedFXData_Filter_Strings(DATA.FX.params[i].formatparam) 
      DATA.FX.params[i].ignore =(pass_temp1 or pass_temp2 or pass_temp3)
    end

    -- pass filter
    if haspass == true then 
      for i = 1 , #DATA.FX.params do
        if DATA.FX.params[i].ignore == true then goto nextparam end 
        local bufparam_check = DATA.FX.params[i].bufparam_check
        local set_ignore
        for key = 1, DATA.Keywords_num do
          local val = EXT['CONF_filter_Keywords'..key]
          if val == 1 then
            local ret = DATA:GetFocusedFXData_Filter_CustomKeyWords(bufparam_check, parse_globalfilt, key)
            if ret==true then set_ignore = true end
          end
        end 
        if set_ignore ~= true then DATA.FX.params[i].ignore = true end
        ::nextparam::
      end
    end

    -- filter out kwords 
    if hasfilt == true then 
      for i = 1 , #DATA.FX.params do
        if DATA.FX.params[i].ignore == true then goto nextparam end 
        local bufparam_check = DATA.FX.params[i].bufparam_check
        for key = 1, DATA.Keywords_num do
          local val = EXT['CONF_filter_Keywords'..key]
          if val == 2 then
            local ret = DATA:GetFocusedFXData_Filter_CustomKeyWords(bufparam_check, parse_globalfilt, key)
            if ret==true then DATA.FX.params[i].ignore = true end
          end
        end 
        ::nextparam::
      end
    end
    
    -- count
    for i = 1 , #DATA.FX.params do 
      if DATA.FX.params[i].ignore == true then  DATA.FX.cnt_params_filtered = DATA.FX.cnt_params_filtered  + 1 end
    end
    
    DATA.FX.UI_name = DATA.FX.trname..' | '..DATA.FX.FXname_short..' | '..DATA.FX.cnt_params..' parameters, '..DATA.FX.cnt_params_filtered..' filtered'
  end
  --------------------------------------------------------------------  
  function DATA:GetFocusedFXData_Filter_System(i,param_bypass,param_wet,param_delta)
    if EXT.CONF_filter_system == 1 and (i==param_bypass or  i==param_wet or i==param_delta ) then return true end
  end
  -------------------------------------------------------------------- 
  function DATA:GetFocusedFXData_Filter_CustomKeyWords(bufparam_check, parse_globalfilt, key)
    for word = 1, #parse_globalfilt[key] do
      local excludefilt = parse_globalfilt[key][word]:lower()
      excludefilt = excludefilt:gsub('_', ' ')
      if bufparam_check:lower():match(excludefilt) then return true end
    end 
  end
  --------------------------------------------------------------------  
  function DATA:GetFocusedFXData_Filter_Untitled(bufparam)
    if EXT.CONF_filter_untitledparams == 1 and 
      (
        bufparam:gsub('_','') == '' 
        or bufparam == ''
        or bufparam:match('reserv')
        or bufparam:match('untitled')
      )
      then 
      return true
    end
  end 
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ----------------------------------------------------------------------  
  function DATA:SetParameters(ignore_morph)
    if not (DATA.FX.cnt_params and DATA.FX.params) then return end
    
    if EXT.CONF_smooth > 0 and not ignore_morph == true then
      if DATA.morphstate == 0 then
        DATA.morphstate_TS = os.clock()
        DATA.morphstate = 1
        return
      end
      
      if DATA.morphstate == 1 then
        DATA.morph_value = (os.clock() - DATA.morphstate_TS) / EXT.CONF_smooth
        DATA.morph_value = VF_lim(DATA.morph_value)
        if DATA.morph_value == 1 then DATA.morphstate = 0 end
      end      
    end
    
    for paramid = 1, DATA.FX.cnt_params do  
      if DATA.FX.params[paramid].ignore == true then goto nextparam end
      if not DATA.FX.params[paramid].value_morph then goto nextparam end 
      if EXT.CONF_smooth ==0 or 
        ignore_morph == true or
        (EXT.CONF_smooth > 0 and DATA.morph_value and DATA.morphstate == 1) then 
        local out_val = DATA.FX.params[paramid].value - (DATA.FX.params[paramid].value - DATA.FX.params[paramid].value_morph ) * (DATA.morph_value or 1)
        _G[DATA.FX.func_str..'SetParamNormalized'](DATA.FX.ptr, DATA.FX.fxnum, paramid-1, out_val) 
      end
      ::nextparam::
    end 
  end 
  ---------------------------------------------------------------------  
  function DATA:GenerateRandomSnapshot()
    if not (DATA.FX.cnt_params and DATA.FX.params) then return end
    for paramid = 1, DATA.FX.cnt_params do
      if  DATA.FX.params[paramid].ignore ~= true then
        DATA.FX.params[paramid].value_morph = math.random()
      end
    end
  end 
  -----------------------------------------------------------------------------------------
  main()