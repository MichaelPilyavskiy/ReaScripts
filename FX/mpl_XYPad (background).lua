-- @description XYPad
-- @version 3.01
-- @author MPL 
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + Add support for 2 points XY mode

  
  vrs = 3.01
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
         viewport_posX = 300,
         viewport_posY = 300,
         viewport_posW = 300,
         viewport_posH = 300, 
         
         CONF_pointscnt= 4,
       }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
         ES_key = 'MPL_XYPad',
         UI_name = 'XY Pad', 
         upd = true, 
         
         refpoint = 
          { xpos=0.5,
            ypos=0.5
          },
         
         points = {}
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
         
  UI.point_sz = 50 
  UI.man_sz = 10
  UI.activerect = 5
  UI.offs =5   
  
  
  
  
  
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
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
    --window_flags = window_flags | ImGui.WindowFlags_NoResize
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
    ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    
    
    -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    local rv,open = ImGui.Begin(ctx, DATA.UI_name..' '..vrs..'##'..DATA.UI_name, open, window_flags) 
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
    UI.calc_fieldside = math.min(DATA.display_w_region-UI.point_sz*2, DATA.display_h_region-UI.point_sz*2)
    
    local x, y = reaper.ImGui_GetWindowPos( ctx )  
    UI.calc_fieldX= x+(DATA.display_w_region-UI.calc_fieldside)/2
    UI.calc_fieldY= y+(DATA.display_h_region-UI.calc_fieldside)/2
    
    
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
    
    if DATA.upd == true then  DATA:CollectData()  end 
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
    for key in pairs(EXT) do  if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then  SetExtState( DATA.ES_key, key, EXT[key], true  )  end  end 
    EXT:load()
  end
  -------------------------------------------------------------------------------- 
  function EXT:load() 
    if not DATA.ES_key then return end
    for key in pairs(EXT) do 
    if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then  
      if HasExtState( DATA.ES_key, key ) then local val = GetExtState( DATA.ES_key, key )  EXT[key] = tonumber(val) or val  end  end   
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
  function UI.draw() 
    
    -- area
    local draw_list = ImGui.GetWindowDrawList( ctx )
    ImGui.DrawList_AddRectFilled( draw_list, UI.calc_fieldX, UI.calc_fieldY, UI.calc_fieldX + UI.calc_fieldside, UI.calc_fieldY + UI.calc_fieldside, 0xF0F0F030, 5, ImGui.DrawFlags_None )
    ImGui.SetCursorScreenPos( ctx, UI.calc_fieldX, UI.calc_fieldY )
    ImGui.InvisibleButton( ctx, 'toucharea', UI.calc_fieldside, UI.calc_fieldside, ImGui.ButtonFlags_None )
    UI.draw_handlemouseonarea() 
    
    -- point
    ImGui.DrawList_AddCircleFilled( draw_list, UI.calc_fieldX + UI.calc_fieldside * DATA.refpoint.xpos, UI.calc_fieldY + UI.calc_fieldside * DATA.refpoint.ypos, UI.man_sz, 0xF0F0F0F0, 0 )
    
    -- FXparams
    UI.draw_params()
end
--------------------------------------------------------------------------------  
  function UI.draw_handlemouseonarea() 
    if ImGui.IsItemActive( ctx ) then
      local mousex, mousey = reaper.ImGui_GetMousePos( ctx )
      DATA.refpoint.xpos = VF_lim((mousex - UI.calc_fieldX) / UI.calc_fieldside)
      DATA.refpoint.ypos = VF_lim((mousey - UI.calc_fieldY) / UI.calc_fieldside)  
      DATA:Points_WriteData() 
    end
  end
  -----------------------------------------------------------------------------------------
  function DATA:Points_WriteData() 
    local x = DATA.refpoint.xpos
    local y = DATA.refpoint.ypos 
    
    if EXT.CONF_pointscnt == 2 then
      DATA.points[2].val = x
      DATA.points[1].val = 1-y
     else
      for i = 1, #DATA.points do if DATA.points[i] then DATA.points[i].val = DATA:Points_WriteData_GetValue(i) end end
    end
    -- apply
      for i = 1, #DATA.points do 
        if DATA.points[i] and DATA.points[i].isvalid then
          local value = VF_lim(DATA.points[i].OFS + DATA.points[i].val * DATA.points[i].SCL)
          if DATA.points[i].INV == 1 then value = 1-value end
          TrackFX_SetParamNormalized( DATA.points[i].TR, 
                                      DATA.points[i].FXID, 
                                      DATA.points[i].PID, 
                                      value)
        end
      end   
  end
  ---------------------------------------------------      
  function DATA:Points_WriteData_GetValue(i) 
    local r_small = UI.calc_fieldside/2-UI.point_sz/2
    local r_circle =(UI.calc_fieldside-UI.point_sz)
    
    local ptx = DATA.points[i].ptx + UI.point_sz/2
    local pty = DATA.points[i].pty + UI.point_sz/2
    local xman = DATA.refpoint.xpos*UI.calc_fieldside+UI.calc_fieldX -ptx
    local yman = DATA.refpoint.ypos*UI.calc_fieldside+UI.calc_fieldY-pty
    local val = math.sqrt(xman^2+yman^2) / r_circle
    return 1-VF_lim(VF_math_Qdec(val,6))  
  end
  ------------------------------------------------------------------------------------------------------
  function VF_math_Qdec(num, pow) if not pow then pow = 3 end return math.floor(num * 10^pow) / 10^pow end
-------------------------------------------------------------------------------- 
  function UI.draw_params()
    local angle_step =360/ EXT.CONF_pointscnt
    local startangle = -135
    local r_small = UI.calc_fieldside/2-UI.man_sz/2
    local r_small2 = UI.calc_fieldside/2+UI.point_sz/2
    local r_circle =math.sqrt(r_small^2+r_small^2)
    local r_circle2 =r_small2
    
    for i = 1, EXT.CONF_pointscnt do
      local ang = math.floor(startangle-angle_step*(i-1))
      if DATA.points[i] then 
        DATA.points[i].ptx = UI.calc_fieldX + UI.calc_fieldside/2 + r_circle*math.sin(math.rad(ang))-UI.point_sz/2
        DATA.points[i].pty = UI.calc_fieldY + UI.calc_fieldside/2 + r_circle*math.cos(math.rad(ang))-UI.point_sz/2
        ImGui.SetCursorScreenPos( ctx, DATA.points[i].ptx, DATA.points[i].pty )
        local alpha = (DATA.points[i].val or 0.5)*0.5+0.2
        alpha = math.floor(alpha*0xFF)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,0xF0F0F0<<8|alpha)
        if ImGui.Button(ctx,i..'##pt'..i,UI.point_sz,UI.point_sz) then ImGui.OpenPopup(ctx, 'ptpopup'..i) end
        UI.draw_params_pointmenu(i) 
        ImGui.PopStyleColor(ctx)
        if DATA.points[i] and DATA.points[i].info then ImGui.SetItemTooltip( ctx, DATA.points[i].info ) else ImGui.SetItemTooltip( ctx, 'No attached FX parameter' ) end
        if DATA.points[i].isvalid then
          local draw_list = ImGui.GetWindowDrawList( ctx )
          local sz = 10
          local offs = 5 
          ImGui.DrawList_AddRectFilled( draw_list, DATA.points[i].ptx+offs, DATA.points[i].pty+offs, DATA.points[i].ptx+sz+offs , DATA.points[i].pty+sz+offs, 0x00FF00A0, 2, ImGui.DrawFlags_None )
        end
      end
    end
    
  end
  ---------------------------------------------------------------------
  function VF2_GetLTP()
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX() 
    local tr, trGUID, fxGUID, param, paramname, ret, fxname,paramformat
    if retval then 
      tr = CSurf_TrackFromID( tracknumber, false )
      trGUID = GetTrackGUID( tr )
      fxGUID = TrackFX_GetFXGUID( tr, fxnumber )
      retval, buf = reaper.GetTrackName( tr )
      ret, paramname = TrackFX_GetParamName( tr, fxnumber, paramnumber, '')
      ret, fxname = TrackFX_GetFXName( tr, fxnumber, '' )
      paramval = TrackFX_GetParam( tr, fxnumber, paramnumber )
      retval, paramformat = TrackFX_GetFormattedParamValue(  tr, fxnumber, paramnumber, '' )
     else 
      return
    end
    return {tr = tr,
            trtracknumber=tracknumber,
            trGUID = trGUID,
            fxGUID = fxGUID,
            trname = buf,
            paramnumber=paramnumber,
            paramname=paramname,
            paramformat = paramformat,
            paramval=paramval,
            fxnumber=fxnumber,
            fxname=fxname
            }
  end
  
-------------------------------------------------------------------------------- 
  function UI.draw_params_pointmenu(i)  
    if ImGui.BeginPopup(ctx, 'ptpopup'..i) then
      -- menu
      if ImGui.BeginMenu( ctx, 'Menu', true ) then
        ImGui.SeparatorText(ctx, 'Points count')
        if ImGui_MenuItem( ctx, '2 XY mode', '', EXT.CONF_pointscnt==2, true ) then EXT.CONF_pointscnt = 2 EXT:save() DATA:InitPoints() end
        if ImGui_MenuItem( ctx, '4 equdistant', '', EXT.CONF_pointscnt==4, true ) then EXT.CONF_pointscnt = 4 EXT:save() DATA:InitPoints() end
        --if ImGui_MenuItem( ctx, '8', '', EXT.CONF_pointscnt==8, true ) then EXT.CONF_pointscnt = 8 EXT:save() DATA:InitPoints() end
        ImGui.EndMenu( ctx  )
      end
      
      
      -- get ltp
      local LTP_t = VF2_GetLTP()
      local param_txt = '[tweak some plugin parameter]'
      local point_t
      if LTP_t then 
        param_txt =  LTP_t.trname..' / '..LTP_t.fxname..' / '..LTP_t.paramname
        param_txt = param_txt:gsub('[<>!#|]','') 
        point_t = {ENABLED = 1,
                        FXGUID = LTP_t.fxGUID:gsub('[%{}]',''), 
                        TRGUID=LTP_t.trGUID,
                        PID=LTP_t.paramnumber,
                        FXID=LTP_t.fxnumber,
                        INV = 0,
                        OFS = 0,
                        SCL = 1,
                        INITVAL = LTP_t.paramformat,
                        INITVALF = LTP_t.paramval
                      }
                      
      end 
      
      -- store param
      if ImGui.Button(ctx, 'Get last touched parameter') then--: '..param_txt) then 
      
        if not point_t then return end
        for key in pairs(point_t) do DATA.proj_extstate['PT'..i..'_'..key] = point_t[key] end
        VF_ExtState_SaveProj(DATA.proj_extstate, DATA.ES_key)
        DATA.upd = true
        ImGui.CloseCurrentPopup(ctx)
      end
      -- clear param
      if ImGui.Button(ctx, 'Clear') then
        if not point_t then return end
        for key in pairs(point_t) do DATA.proj_extstate['PT'..i..'_'..key] ='' end
        VF_ExtState_SaveProj(DATA.proj_extstate, DATA.ES_key)
        DATA.upd = true
        ImGui.CloseCurrentPopup(ctx)
      end
      -- invert
      if DATA.proj_extstate['PT'..i..'_INV'] then 
        if ImGui_Checkbox( ctx, 'Invert', DATA.proj_extstate['PT'..i..'_INV']==1 ) then DATA.proj_extstate['PT'..i..'_INV'] = DATA.proj_extstate['PT'..i..'_INV'] ~1 VF_ExtState_SaveProj(DATA.proj_extstate, DATA.ES_key) end
      end
      -- offset
      if DATA.proj_extstate['PT'..i..'_OFS'] and type(DATA.proj_extstate['PT'..i..'_OFS'])=='number' then 
        local retval, v = reaper.ImGui_SliderDouble( ctx, 'Offset', DATA.proj_extstate['PT'..i..'_OFS'], 0, 1, '%.2f', ImGui.SliderFlags_None )
        if retval then DATA.proj_extstate['PT'..i..'_OFS'] = v VF_ExtState_SaveProj(DATA.proj_extstate, DATA.ES_key) end
      end
      -- scale
      if DATA.proj_extstate['PT'..i..'_SCL'] and type(DATA.proj_extstate['PT'..i..'_SCL'])=='number' then  
        local retval, v = reaper.ImGui_SliderDouble( ctx, 'Scale', DATA.proj_extstate['PT'..i..'_SCL'], 0, 1, '%.2f', ImGui.SliderFlags_None )
        if retval then DATA.proj_extstate['PT'..i..'_SCL'] = v VF_ExtState_SaveProj(DATA.proj_extstate, DATA.ES_key) end      
      end
      ImGui.EndPopup(ctx)
    end
    
  end
  ------------------------------------------------------------------------------------------------------
  function VF_ExtState_SaveProj(conf,extname) 
    for key in pairs(conf) do SetProjExtState( 0, extname, key, conf[key] ) end 
  end
  ------------------------------------------------------------------------------------------------------
  function main() 
    DATA:InitPoints() 
    UI.MAIN_definecontext() 
  end  
  -----------------------------------------------------------------------------------------
  function DATA:InitPoints() 
    DATA.points = {}
    for i = 1, EXT.CONF_pointscnt do DATA.points[i] = {} end
  end
  ------------------------------------------------------------------------------------------------------
  function VF_ExtState_LoadProj(conf,extname )
    if not extname then return end
    for idx = 1, 10000 do
      local retval, key, val = reaper.EnumProjExtState( 0, extname, idx-1 )
      if not retval then break end
      conf[key] = tonumber(val) or val
    end  
  end 
  ---------------------------------------------------
  function VF_GetFXByGUID(GUID, tr, proj)
    if not GUID then return end
    local pat = '[%p]+'
    if not tr then
      for trid = 1, CountTracks(proj or 0) do
        local tr = GetTrack(proj,trid-1)
        local fxcnt_main = TrackFX_GetCount( tr ) 
        local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
        for fx = 1, fxcnt do
          local fx_dest = fx
          if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
          if TrackFX_GetFXGUID( tr, fx-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx-1 end 
        end
      end  
     else
      if not (ValidatePtr2(proj or 0, tr, 'MediaTrack*')) then return end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
        if TrackFX_GetFXGUID( tr, fx_dest-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_dest-1 end 
      end
    end    
  end
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  ---------------------------------------------------
  function VF2_ValidateFX(trGUID,fxGUID)
    if not (trGUID and fxGUID) then return end
    local tr = VF_GetTrackByGUID(trGUID)
    if not tr then return end 
    local ret, tr, fxnumber = VF_GetFXByGUID(fxGUID, tr) 
    if not ret then return end 
    return fxnumber
  end
  -----------------------------------------------------------------------------------------
  function DATA:CollectData() 
    -- ext state from 1.versions
    DATA.proj_extstate = {}
    VF_ExtState_LoadProj(DATA.proj_extstate, DATA.ES_key)
    
    for i = 1, EXT.CONF_pointscnt do
      DATA.points[i] = {}
      local id_pat = 'PT'..tostring(i)..'_'
        if DATA.proj_extstate[id_pat..'ENABLED'] then
          local ret = VF2_ValidateFX(DATA.proj_extstate[id_pat..'TRGUID'],DATA.proj_extstate[id_pat..'FXGUID'])
          if ret then 
          
            DATA.points[i].isvalid = true
            DATA.points[i].ENABLED = DATA.proj_extstate[id_pat..'ENABLED']
            DATA.points[i].FXGUID = DATA.proj_extstate[id_pat..'FXGUID']
            DATA.points[i].TRGUID = DATA.proj_extstate[id_pat..'TRGUID']
            local tr = VF_GetTrackByGUID(DATA.points[i].TRGUID)
            DATA.points[i].TR = tr
            DATA.points[i].PID = DATA.proj_extstate[id_pat..'PID']
            DATA.points[i].INV = DATA.proj_extstate[id_pat..'INV']
            DATA.points[i].SCL = DATA.proj_extstate[id_pat..'SCL']
            DATA.points[i].OFS = DATA.proj_extstate[id_pat..'OFS']
            DATA.points[i].FXID = DATA.proj_extstate[id_pat..'FXID']
            DATA.points[i].INITVAL = DATA.proj_extstate[id_pat..'INITVAL']
            DATA.points[i].INITVALF = DATA.proj_extstate[id_pat..'INITVALF']
            
            
            local retval, trname = reaper.GetTrackName( tr )
            local retval, fxname = reaper.TrackFX_GetFXName( tr, DATA.points[i].FXID, '' )
            local retval, paramname = reaper.TrackFX_GetParamName( tr, DATA.points[i].FXID, DATA.points[i].PID, '' )
            
            DATA.points[i].info = trname..'\n'..fxname..'\n'..paramname
          end
        end
      end
  end 
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
   -----------------------------------------------------------------------------------------
   main()