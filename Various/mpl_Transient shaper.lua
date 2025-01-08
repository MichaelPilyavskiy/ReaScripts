-- @description Transient shaper
-- @version 2.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Ported to ReaimGui

 
  
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
          
          CONF_attack_khsTS = 0,
          CONF_pump_khsTS = 0,
          CONF_sustain_khsTS = 0,
          CONF_rate_khsTS = 1,
        }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          ES_key = 'MPLEBTRANSSHAPE',
          UI_name = 'Transient shaper', 
          upd = true, 
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
 --[[   UI.font2sz=14
    UI.font3sz=12
  -- special 
    UI.butBg_green = 0x00B300
    UI.butBg_red = 0xB31F0F
  
  -- MP
  -- size
    UI.main_butw = 150
    UI.main_butclosew = 20
    UI.main_buth = 40
    UI.flowchildW = 600
    UI.flowchildH = UI.main_buth*8
    UI.plotW = UI.flowchildW - 200
    UI.plotH = UI.main_buth
  ]]
  
  
  
  
  
  
  
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
      ImGui.SetNextWindowSize(ctx, 300, 150, ImGui.Cond_Appearing)
      
      
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
  ------------------------------------------------------------------------------------------------------
  function VF_math_Qdec(num, pow) if not pow then pow = 3 end return math.floor(num * 10^pow) / 10^pow end
  -------------------------------------------------------------------------------- 
  function DATA:handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
    local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
    local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
  end
  ------------------------------------------------------------------------------------------------------
  function vars_form_def(f) if f then return (VF_math_Qdec(f,2)*100)..'%%' else return '' end end
  function vars_formrev_def(v) return tonumber(v)/100 end
  --------------------------------------------------------------------------------  
  function UI.draw()  
    local retval, v = ImGui.SliderDouble( ctx, 'Attack', EXT.CONF_attack_khsTS, -1, 1, vars_form_def(EXT.CONF_attack_khsTS), ImGui.SliderFlags_None )
    if retval then EXT.CONF_attack_khsTS = v EXT:save() DATA:Process_SetItemsEnvelopes() end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA:Process_GetItems() end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then EXT.CONF_attack_khsTS = EXT_defaults.CONF_attack_khsTS EXT:save() DATA:Process_SetItemsEnvelopes() Undo_OnStateChange2( 0, 'mpl_Transient shaper' ) end
    if ImGui.IsItemDeactivated( ctx )  then DATA:Process_SetItemsEnvelopes() Undo_OnStateChange2( 0, 'mpl_Transient shaper' ) end
    
    local retval, v = ImGui.SliderDouble( ctx, 'Pump', EXT.CONF_pump_khsTS, -1, 1, vars_form_def(EXT.CONF_pump_khsTS), ImGui.SliderFlags_None )
    if retval then EXT.CONF_pump_khsTS = v EXT:save() DATA:Process_SetItemsEnvelopes() end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA:Process_GetItems() end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then EXT.CONF_pump_khsTS = EXT_defaults.CONF_pump_khsTS EXT:save() DATA:Process_SetItemsEnvelopes() Undo_OnStateChange2( 0, 'mpl_Transient shaper' ) end
    if ImGui.IsItemDeactivated( ctx )  then DATA:Process_SetItemsEnvelopes() Undo_OnStateChange2( 0, 'mpl_Transient shaper' ) end
        
    local retval, v = ImGui.SliderDouble( ctx, 'Sustain', EXT.CONF_sustain_khsTS, -1, 1, vars_form_def(EXT.CONF_sustain_khsTS), ImGui.SliderFlags_None )
    if retval then EXT.CONF_sustain_khsTS = v EXT:save() DATA:Process_SetItemsEnvelopes() end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA:Process_GetItems() end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then EXT.CONF_sustain_khsTS = EXT_defaults.CONF_sustain_khsTS EXT:save() DATA:Process_SetItemsEnvelopes() Undo_OnStateChange2( 0, 'mpl_Transient shaper' ) end
    if ImGui.IsItemDeactivated( ctx )  then DATA:Process_SetItemsEnvelopes() Undo_OnStateChange2( 0, 'mpl_Transient shaper' ) end
    
    local retval, v = ImGui.SliderDouble( ctx, 'Rate', EXT.CONF_rate_khsTS, -1, 1, vars_form_def(EXT.CONF_rate_khsTS), ImGui.SliderFlags_None )
    if retval then EXT.CONF_rate_khsTS = v EXT:save() DATA:Process_SetItemsEnvelopes() end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA:Process_GetItems() end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then EXT.CONF_rate_khsTS = EXT_defaults.CONF_rate_khsTS EXT:save() DATA:Process_SetItemsEnvelopes() Undo_OnStateChange2( 0, 'mpl_Transient shaper' )end
    if ImGui.IsItemDeactivated( ctx )  then DATA:Process_SetItemsEnvelopes() Undo_OnStateChange2( 0, 'mpl_Transient shaper' ) end
    
  end
  
  function DATA:Process_GetItems() 
    DATA.items = {}
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem(0,i-1)
      local tk = GetActiveTake(it)
      if tk then 
        local env_ptr = reaper.GetTakeEnvelopeByName( tk, 'Volume' )
        if not env_ptr then 
          DATA:Process_ActivateTakeVolEnvelope(it,tk)
          local env_ptr = reaper.GetTakeEnvelopeByName( tk, 'Volume' )
          DeleteEnvelopePointRangeEx( env_ptr, -1, 0, math.huge )
          SetEnvelopePointEx( env_ptr, -1, 0, 
            0.1, --pos
            0,--valueIn, 
            0,--shapeIn, 
            0,--tensionIn, 
            0,--selectedIn, 
            true)--noSortIn )
          Envelope_SortPointsEx( env_ptr, -1 )
        end
        if env_ptr then
          DATA.items[#DATA.items+1] = {
                          it_ptr = it,
                          tk_ptr = tk,
                          transients = {0},
                          toggle_env = toggle_env,
                          env_ptr=env_ptr
                        }
        end
      end
    end
    DATA.getstate = true
  end
  ------------------------------------------------------------------------------------------------------
  function DATA:Process_ActivateTakeVolEnvelope(item,take)
    local ID = GetMediaItemTakeInfo_Value( take, 'IP_TAKENUMBER' )
    if not item then return end
    -- get
      local chunksrc = ({GetItemStateChunk( item, '', false )})[2]
      local chunk = 'TAKE\n'..chunksrc:match('NAME.*'):gsub('TAKE[%s-]','ENDTAKE\nTAKE '):sub(0,-3)..'ENDTAKE'
      local item_t  = {itemchunk = chunksrc:match('(.-)NAME'), takes = {}} 
      for takeblock in chunk:gmatch('TAKE(.-)ENDTAKE') do 
        local tkid = #item_t.takes+1
        item_t.takes[tkid] = {}
        if takeblock:match('%sSEL%s') then item_t.takes[tkid].selected = true end
        takeblock = takeblock:gsub('%sSEL%s','') 
        item_t.takes[tkid].chunk=takeblock 
      end 
    -- handle active take
      local found_active = false
      for tkid = 1, #item_t.takes do if item_t.takes[tkid].selected == true then item_t.active_take = tkid found_active = true break end end
      if not found_active then item_t.active_take = 1 item_t.takes[1].selected = true end
      
    -- set
      local out_chunk = item_t.itemchunk
      for tkid = 1, #item_t.takes do
        local tkchunksrc = item_t.takes[tkid].chunk:gsub('SPECTRAL_.-[\r\n]','')
        local issel = '' if tkid > 1 and item_t.takes[tkid].selected then  issel = ' SEL' end
        local head = 'TAKE'..issel..'\n'
        if tkid == 1 then head = '' end
        if item_t.takes[tkid].selected then
        
tk_env_chunk = [[       
<VOLENV
EGUID {] ]..genGuid( )..[[}
ACT 1 -1
VIS 1 1 1
LANEHEIGHT 0 0
ARM 0
DEFSHAPE 0 -1 -1
VOLTYPE 1
PT 0 1 0
>]]
          tkchunksrc = tkchunksrc..'\n'..tk_env_chunk
        end
        out_chunk = out_chunk..'\n\n'..head..tkchunksrc 
      end
      out_chunk = out_chunk..'\n>'
      
    SetItemStateChunk( item, out_chunk, false )
    UpdateItemInProject( item )
  end
  
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h  
  ------------------------------------------------------------------------------------------  
  function DATA:Process_SetItemsEnvelopes()
    local attack_max = 0.1 -- at negative attack
    local linear_zero = WDL_DB2VAL(0)
    local pump_mid_pos = 0.1
    
    if not DATA.items then return end
    for i = 1, #DATA.items do
      local env = DATA.items[i]. env_ptr
      local scaling_mode = GetEnvelopeScalingMode( env )
      local linear_zero_scaled = ScaleToEnvelopeMode( scaling_mode, linear_zero )
      DeleteEnvelopePointRangeEx( env, -1, 0, math.huge )
      
      -- init at zero
      SetEnvelopePointEx( env, -1, 0, 
        0, --pos
        ScaleToEnvelopeMode( scaling_mode, 0.01 ),--valueIn, 
        0,--shapeIn, 
        0,--tensionIn, 
        0,--selectedIn, 
        true)--noSortIn )
      
      -- attack
        local attacktime_s
        if EXT.CONF_attack_khsTS <0 then attacktime_s = math.abs(EXT.CONF_attack_khsTS)*attack_max else attacktime_s = 10*10^-14 end
        local attack_val = ScaleToEnvelopeMode( scaling_mode, linear_zero )
        if EXT.CONF_attack_khsTS >=0 then attack_val = ScaleToEnvelopeMode( scaling_mode, 1+EXT.CONF_attack_khsTS ) end
        InsertEnvelopePointEx( env, -1, 
          EXT.CONF_rate_khsTS*attacktime_s, --pos
          attack_val,--valueIn, 
          3,--shapeIn, 
          -0.05,--tensionIn, 
          0,--selectedIn, 
          true)--noSortIn )
      
      --pump_mid_pos
        InsertEnvelopePointEx( env, -1, 
          EXT.CONF_rate_khsTS*(attacktime_s + pump_mid_pos), --pos
          ScaleToEnvelopeMode( scaling_mode, linear_zero+EXT.CONF_pump_khsTS ),--valueIn, 
          2,--shapeIn, 
          0,--tensionIn, 
          1,--selectedIn, 
          true)--noSortIn ) 
      
      -- sustain
        InsertEnvelopePointEx( env, -1, 
          EXT.CONF_rate_khsTS*(attacktime_s + pump_mid_pos*2), --pos
          ScaleToEnvelopeMode( scaling_mode, linear_zero+EXT.CONF_sustain_khsTS ),--valueIn, 
          0,--shapeIn, 
          0,--tensionIn, 
          0,--selectedIn, 
          true)--noSortIn ) 
          
      Envelope_SortPointsEx( env, -1 )
    end
    
    
  end
  ----------------------------------------------------------------------------------------- 
  function main() 
    EXT_defaults = CopyTable(EXT)
    UI.MAIN_definecontext() 
  end  
  -----------------------------------------------------------------------------------------
  main()