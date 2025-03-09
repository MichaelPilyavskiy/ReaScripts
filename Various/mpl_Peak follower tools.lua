-- @description Peak follower tools
-- @version 2.12
-- @author MPL
-- @about Generate envelope from audio data
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # shifting envelope points moved to output
--    + Revert back Gate/PF/Compressor mode
--    + Compressor: implement attack/release quantized to window



vrs = 2.12
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
        viewport_posX = 0,
        viewport_posY = 0,
        viewport_posW = 600,
        viewport_posH = 480,
        
        preset_base64_user = '',
        update_presets = 1, -- grab presets ONCE from old version
        
        UI_compactmode =1,
        UI_appatchange = 0,
        
        -- global
        CONF_name = 'default',

        -- mode
        CONF_bypass = 0,
        CONF_mode2 = 0, -- 0 peak follower 1 compressor 2 gate
        CONF_boundary = 0, -- 0 item edges 1 time selection
        
        -- audio data
        CONF_removetkenvvol = 1, -- remove take vol
        CONF_window = 0.02,
        CONF_windowoverlap = 1,
        CONF_FFTsz = -1,
        CONF_FFT_min = 0,
        CONF_FFT_max = 1,
        CONF_gate_threshold_dB = -90,
        CONF_gate_quantize =1,
        
        -- dest
        CONF_dest = 1, -- 0 AI track vol 1 take vol env 2 AI pre-fx track vol
        
        -- output
        CONF_reducesamevalues = 1, -- do not add point if previous point has same value
        CONF_zeroboundary = 1, -- zero reset for boundaries 
        CONF_out_pointsshape = 0, 
        CONF_gate_inv = 0, 
        
        CONF_PF_inv = 0,
        CONF_PF_scale = 1, 
        
        CONF_out_shift_ms = 0, 
        CONF_applylive = 0,
        
        CONF_comp_thresh = -2,
        CONF_comp_attack_wind = 0,
        CONF_comp_release_wind = 0,
        CONF_comp_mult = 0.2,
        
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'PeakFollowTools',
        UI_name = 'Peak follower tools', 
        upd = true, 
        preset_name = 'untitled', -- for inputtext
        presets_factory = {
        
          },
        presets = {
          factory= {},
          user= {}, 
          },
        }
        
        
-------------------------------------------------------------------------------- UI init variables
UI = {}
  
  UI.popups = {}
-- font  
  UI.font='Arial'
  UI.font1sz=15
  UI.font2sz=14
  UI.font3sz=12
-- style
  UI.pushcnt = 0
  UI.pushcnt2 = 0
-- size / offset
  UI.spacingX = 4
  UI.spacingY = 3
-- mouse
  UI.hoverdelay = 0.8
  UI.hoverdelayshort = 0.8
-- colors 
  UI.main_col = 0x7F7F7F -- grey
  UI.textcol = 0xFFFFFF
  UI.but_hovered = 0x878787
  UI.windowBg = 0x303030
-- alpha
  UI.textcol_a_enabled = 1
  UI.textcol_a_disabled = 0.5
  
  UI.knob_handle = 0xc8edfa
  UI.default_data_col_adv = '#00ff00' -- green
  UI.default_data_col_adv2 = '#e61919 ' -- red

  UI.indent = 20
  UI.knob_resY = 120



function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
-------------------------------------------------------------------------------- 
function UI.MAIN_PushStyle(key, value, value2)  
  local iscol = key:match('Col_')~=nil
  local keyid = ImGui[key]
  if not iscol then 
    ImGui.PushStyleVar(ctx, keyid, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw(open) 
  local w_min = 250
  local h_min = 80
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
    --window_flags = window_flags | ImGui.WindowFlags_TopMost
    window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
    --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings() end
    --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
    --open = false -- disable the close button
  
  
    -- set style
      UI.pushcnt = 0
      UI.pushcnt2 = 0
    -- rounding
      UI.MAIN_PushStyle('StyleVar_FrameRounding',5)  
      UI.MAIN_PushStyle('StyleVar_GrabRounding',5)  
      UI.MAIN_PushStyle('StyleVar_WindowRounding',10)  
      UI.MAIN_PushStyle('StyleVar_ChildRounding',5)  
      UI.MAIN_PushStyle('StyleVar_PopupRounding',0)  
      UI.MAIN_PushStyle('StyleVar_ScrollbarRounding',9)  
      UI.MAIN_PushStyle('StyleVar_TabRounding',4)   
    -- Borders
      UI.MAIN_PushStyle('StyleVar_WindowBorderSize',0)  
      UI.MAIN_PushStyle('StyleVar_FrameBorderSize',0) 
    -- spacing
      UI.MAIN_PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
      UI.MAIN_PushStyle('StyleVar_FramePadding',10,5) 
      UI.MAIN_PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
      UI.MAIN_PushStyle('StyleVar_ItemInnerSpacing',4,0)
      UI.MAIN_PushStyle('StyleVar_IndentSpacing',20)
      UI.MAIN_PushStyle('StyleVar_ScrollbarSize',20)
    -- size
      UI.MAIN_PushStyle('StyleVar_GrabMinSize',30)
      UI.MAIN_PushStyle('StyleVar_WindowMinSize',w_min,h_min)
    -- align
      UI.MAIN_PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      --UI.MAIN_PushStyle('StyleVar_SelectableTextAlign,0,0 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextAlign,0,0.5 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextPadding,20,3 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextBorderSize,3 )
    -- alpha
      UI.MAIN_PushStyle('StyleVar_Alpha',0.98)
      --UI.MAIN_PushStyle('StyleVar_DisabledAlpha,0.6 ) 
      UI.MAIN_PushStyle('Col_Border',UI.main_col, 0.3)
    -- colors
      --UI.MAIN_PushStyle('Col_BorderShadow(),0xFFFFFF, 1)
      UI.MAIN_PushStyle('Col_Button',UI.main_col, 0.3) 
      UI.MAIN_PushStyle('Col_ButtonActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
      --UI.MAIN_PushStyle('Col_CheckMark(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true) 
      
      
      --Constant: Col_DockingEmptyBg
      --Constant: Col_DockingPreview
      --Constant: Col_DragDropTarget 
      UI.MAIN_PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
      UI.MAIN_PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
      UI.MAIN_PushStyle('Col_FrameBgActive',UI.main_col, .6)
      UI.MAIN_PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
      UI.MAIN_PushStyle('Col_Header',UI.main_col, 0.5) 
      UI.MAIN_PushStyle('Col_HeaderActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
      --Constant: Col_MenuBarBg
      --Constant: Col_ModalWindowDimBg
      --Constant: Col_NavHighlight
      --Constant: Col_NavWindowingDimBg
      --Constant: Col_NavWindowingHighlight
      --Constant: Col_PlotHistogram
      --Constant: Col_PlotHistogramHovered
      --Constant: Col_PlotLines
      --Constant: Col_PlotLinesHovered 
      UI.MAIN_PushStyle('Col_PopupBg',0x303030, 0.9) 
      UI.MAIN_PushStyle('Col_ResizeGrip',UI.main_col, 1) 
      --Constant: Col_ResizeGripActive 
      UI.MAIN_PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
      --Constant: Col_ScrollbarBg
      --Constant: Col_ScrollbarGrab
      --Constant: Col_ScrollbarGrabActive
      --Constant: Col_ScrollbarGrabHovered
      --Constant: Col_Separator
      --Constant: Col_SeparatorActive
      --Constant: Col_SeparatorHovered
      --Constant: Col_SliderGrab
      --Constant: Col_SliderGrabActive
      UI.MAIN_PushStyle('Col_Tab',UI.main_col, 0.37) 
      --UI.MAIN_PushStyle('Col_TabActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_TabHovered',UI.main_col, 0.8) 
      --Constant: Col_TabUnfocused
      --'Col_TabUnfocusedActive
      --UI.MAIN_PushStyle('Col_TabUnfocusedActive(),UI.main_col, 0.8, true)
      --Constant: Col_TableBorderLight
      --Constant: Col_TableBorderStrong
      --Constant: Col_TableHeaderBg
      --Constant: Col_TableRowBg
      --Constant: Col_TableRowBgAlt
      UI.MAIN_PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
      --Constant: Col_TextDisabled
      --Constant: Col_TextSelectedBg
      UI.MAIN_PushStyle('Col_TitleBg',UI.main_col, 0.7) 
      UI.MAIN_PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
      --Constant: Col_TitleBgCollapsed 
      UI.MAIN_PushStyle('Col_WindowBg',UI.windowBg, 1)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    local fixedw = 410
    local fixedh = 600
    ImGui.SetNextWindowSize(ctx, fixedw,fixedh , ImGui.Cond_Always)
    
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
      UI.calc_childH = math.floor(DATA.display_h_region - UI.calc_yoffset*6 - UI.calc_itemH*2)/3
      UI.calc_mainbut = math.floor(DATA.display_w_region - UI.calc_xoffset*4)/3
      if EXT.CONF_act_appbuttoexecute ==1 then  
        UI.calc_mainbut = math.floor(DATA.display_w_region - UI.calc_xoffset*5)/4
      end
      
    -- draw stuff
      UI.draw()
      ImGui.Dummy(ctx,0,0) 
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.End(ctx)
     else
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
    end 
    ImGui.PopFont( ctx ) 
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
  
    return open
end
--------------------------------------------------------------------------------  
function UI.MAIN_PopStyle(ctx, cnt, cnt2)
  if cnt then 
    ImGui.PopStyleVar(ctx,cnt)
    UI.pushcnt = UI.pushcnt -cnt
  end
  if cnt2 then
    ImGui.PopStyleColor(ctx,cnt2)
    UI.pushcnt2 = UI.pushcnt2 -cnt2
  end
end
-------------------------------------------------------------------------------- 
function DATA:CollectData() 
  DATA.SR = VF_GetProjectSampleRate()
  
end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  UI.MAIN_shortcuts()
  -- handle xy
  DATA:handleViewportXYWH()
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) ImGui.SameLine(ctx) end
-------------------------------------------------------------------------------- 
function UI.MAIN() 
  EXT:load() 
  -- imgUI init
  ctx = ImGui.CreateContext(DATA.UI_name) 
  -- fonts
  DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
  DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
  DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
  -- config
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
  -- run loop
  defer(UI.MAINloop)
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
-----------------------------------------------------------------------------------------
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
function main() 
  EXT_defaults = CopyTable(EXT)
  EXT:load()  
  DATA.PRESET_GetExtStatePresets()
  UI.MAIN() 
end
-----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
function table.exportstring( s ) return string.format("%q", s) end

--// The Save Function
function table.save(  tbl )
local outstr = ''
  local charS,charE = "   ","\n"

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  outstr = outstr..'\n'..( "return {"..charE )

  for idx,t in ipairs( tables ) do
     outstr = outstr..'\n'..( "-- Table: {"..idx.."}"..charE )
     outstr = outstr..'\n'..( "{"..charE )
     local thandled = {}

     for i,v in ipairs( t ) do
        thandled[i] = true
        local stype = type( v )
        -- only handle value
        if stype == "table" then
           if not lookup[v] then
              table.insert( tables, v )
              lookup[v] = #tables
           end
           outstr = outstr..'\n'..( charS.."{"..lookup[v].."},"..charE )
        elseif stype == "string" then
           outstr = outstr..'\n'..(  charS..table.exportstring( v )..","..charE )
        elseif stype == "number" then
           outstr = outstr..'\n'..(  charS..tostring( v )..","..charE )
        end
     end

     for i,v in pairs( t ) do
        -- escape handled values
        if (not thandled[i]) then
        
           local str = ""
           local stype = type( i )
           -- handle index
           if stype == "table" then
              if not lookup[i] then
                 table.insert( tables,i )
                 lookup[i] = #tables
              end
              str = charS.."[{"..lookup[i].."}]="
           elseif stype == "string" then
              str = charS.."["..table.exportstring( i ).."]="
           elseif stype == "number" then
              str = charS.."["..tostring( i ).."]="
           end
        
           if str ~= "" then
              stype = type( v )
              -- handle value
              if stype == "table" then
                 if not lookup[v] then
                    table.insert( tables,v )
                    lookup[v] = #tables
                 end
                 outstr = outstr..'\n'..( str.."{"..lookup[v].."},"..charE )
              elseif stype == "string" then
                 outstr = outstr..'\n'..( str..table.exportstring( v )..","..charE )
              elseif stype == "number" then
                 outstr = outstr..'\n'..( str..tostring( v )..","..charE )
              end
           end
        end
     end
     outstr = outstr..'\n'..( "},"..charE )
  end
  outstr = outstr..'\n'..( "}" )
  return outstr
end

--// The Load Function
function table.load( str )
if str == '' then return end
  local ftables,err = load( str )
  if err then return _,err end
  local tables = ftables()
  for idx = 1,#tables do
     local tolinki = {}
     for i,v in pairs( tables[idx] ) do
        if type( v ) == "table" then
           tables[idx][i] = tables[v[1]]
        end
        if type( i ) == "table" and tables[i[1]] then
           table.insert( tolinki,{ i,tables[i[1]] } )
        end
     end
     -- link indices
     for _,v in ipairs( tolinki ) do
        tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
     end
  end
  return tables[1]
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle('Col_Button',col, 0.5) 
    UI.MAIN_PushStyle('Col_ButtonActive',col, 1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8)
end
--------------------------------------------------------------------- 
function DATA.PRESET_GetExtStatePresets()
  DATA.presets.factory = DATA.presets_factory
  
  local preset_base64_user = EXT.preset_base64_user
  if preset_base64_user:match('{')== nil and preset_base64_user~= '' then preset_base64_user = DATA.PRESET_decBase64(preset_base64_user) end
  DATA.presets.user = table.load(preset_base64_user) or {}
  
  -- ported from old version
  if EXT.update_presets == 1 then
    local t = {}
    for id_out=1, 32 do
      local str = GetExtState( DATA.ES_key, 'PRESET'..id_out)
      local str_dec = DATA.PRESET_decBase64(str)
      if str_dec== '' then goto nextpres end
      local tid = #t+1
      t[tid] = {str=str}
      for line in str_dec:gmatch('[^\r\n]+') do
        local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
        if key and value then
          t[tid][key]= tonumber(value) or value
        end
      end   
      local name = t[tid].CONF_NAME
      test = t[tid]
      DATA.presets.user[name] = CopyTable(t[tid])
      ::nextpres::
    end
    EXT.update_presets = 0
    EXT:save()
  end
end
-------------------------------------------------------------------------------- 
function UI.MAIN_shortcuts()
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then 
    for key in pairs(UI.popups) do UI.popups[key].draw = false end
    ImGui.CloseCurrentPopup( ctx ) 
  end
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then  reaper.Main_OnCommand(40044,0) end
end
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 end 
    return v 
  end  
  -------------------------------------------------------------------  
  function DATA:Process_GetAudioData(item)
    local window_sec = EXT.CONF_window
    
    -- init 
      if not (item and window_sec) then return end  
      local take =  reaper.GetActiveTake( item )
      if TakeIsMIDI( take ) then return end  
      
      if EXT.CONF_removetkenvvol == 1 then
        local env = reaper.GetTakeEnvelopeByName(take, 'Volume')
        if env then
          reaper.DeleteEnvelopePointRange( env, 0, math.huge )
          reaper.Envelope_SortPoints( env )
        end
      end
      
      local track = GetMediaItem_Track(item)
      local accessor = CreateTrackAudioAccessor( track ) 
      local id = 0
      local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
      local bufsz = math.ceil(window_sec * SR_spls)
      local data = {}
      
      local ret, boundary_start, boundary_end = DATA:Process_GetBoundary(item)
      if not ret then return end
      
      
    -- peak follower in RMS mode
      if EXT.CONF_FFTsz==-1 then 
        for pos = boundary_start, boundary_end, window_sec/EXT.CONF_windowoverlap do 
          local samplebuffer = new_array(bufsz);
          GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
          local sum = 0 
          for i = 1, bufsz do 
            local val = math.abs(samplebuffer[i]) 
            sum = sum + val 
          end 
          samplebuffer.clear()
          id = id + 1
          data[id] = WDL_VAL2DB(sum / bufsz) -- get RMS
        end
        reaper.DestroyAudioAccessor( accessor )
      end

      -- peak follower in FFT mode
      if EXT.CONF_FFTsz~=-1 then 
        local fftsz = EXT.CONF_FFTsz
        local bufsz = fftsz *2
        --local window_sec = fftsz / SR_spls
        for pos = boundary_start, boundary_end, window_sec/EXT.CONF_windowoverlap do 
          local samplebuffer = new_array(bufsz);
          GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
          samplebuffer.fft_real(fftsz, true)
          local sum = 0 
          local cnt = 0
          local fftst = math.max(1,math.ceil(EXT.CONF_FFT_min*fftsz))
          local fftend = math.floor(EXT.CONF_FFT_max*fftsz)
          for i = fftst, fftend do 
            local val = math.abs(samplebuffer[i]) 
            sum = sum + val 
          end 
          samplebuffer.clear()
          id = id + 1
          data[id] = WDL_VAL2DB(sum / (fftend-fftst))
        end
        reaper.DestroyAudioAccessor( accessor )
      end
      
    return data
  end
  
  ---------------------------------------------------------------------------------------------------------------------  
  function DATA:Process_GenerateAI(item) 
    
    -- get boundary
      local ret, boundary_start, boundary_end, i_pos = DATA:Process_GetBoundary(item)
      if not ret then return end
      
    -- destination
      local env
      local AI_idx = -1
      if EXT.CONF_dest == 0 then -- track vol AI
        local track = GetMediaItem_Track(item)
        env =  GetTrackEnvelopeByName( track, 'Volume' )
        if not ValidatePtr2( -1, env, 'TrackEnvelope*' ) then 
          SetOnlyTrackSelected(track)
          Main_OnCommand(40406,0) -- show vol envelope
          env =  GetTrackEnvelopeByName( track, 'Volume' ) 
        end 
        AI_idx = DATA:Process_GetEditAIbyEdges(env, boundary_start, boundary_end)   
        if not AI_idx then AI_idx = InsertAutomationItem( env, -1, boundary_start, boundary_end-boundary_start )end
      end
      
    -- destination
      if EXT.CONF_dest == 2 then -- prefx track vol AI
        local track = GetMediaItem_Track(item)
        env =  GetTrackEnvelopeByName( track, 'Volume (Pre-FX)' )
        if not ValidatePtr2( -1, env, 'TrackEnvelope*' ) then 
          SetOnlyTrackSelected(track)
          Main_OnCommand(40408,0) -- show Pre-FX vol envelope
          env =  GetTrackEnvelopeByName( track, 'Volume (Pre-FX)' )
        end
        AI_idx = DATA:Process_GetEditAIbyEdges(env, boundary_start, boundary_end)  
        if not AI_idx then AI_idx = InsertAutomationItem( env, -1, boundary_start, boundary_end-boundary_start )end
      end
      
      -- take env
      if EXT.CONF_dest == 1 then 
        local take = GetActiveTake(item)
        if not take then return end
        for envidx = 1,  CountTakeEnvelopes( take ) do local tkenv = GetTakeEnvelope( take, envidx-1 ) local retval, envname = reaper.GetEnvelopeName(tkenv ) if envname == 'Volume' then env = tkenv break end end
        if not ValidatePtr2( 0, env, 'TrackEnvelope*' ) then 
          VF_Action(40693) -- Take: Toggle take volume envelope 
          for envidx = 1,  CountTakeEnvelopes( take ) do 
            local tkenv = GetTakeEnvelope( take, envidx-1 ) 
            local retval, envname = reaper.GetEnvelopeName(tkenv ) 
            if envname == 'Volume' then env = tkenv break end 
          end 
        end
      end
            
            
    -- apply points
      if not env then return end
      --local cntpts = CountEnvelopePointsEx( env, AI_idx )
      --DeleteEnvelopePointEx( env, AI_idx,  cntpts )
      --Envelope_SortPointsEx( env, AI_idx )
      
      
      return true, env, AI_idx
  end
  ------------------------------------------------------------------------------------------------------
  function VF_Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end    
  ---------------------------------------------------------------------------------------------------------------------  
  function DATA:Process_GetEditAIbyEdges(env, AIpos, AIend)    
    local qerr = 0.1
    for AI_idx = 1, CountAutomationItems( env ) do
      local pos = GetSetAutomationItemInfo( env, AI_idx-1, 'D_POSITION', 0, 0 )
      local len = GetSetAutomationItemInfo( env, AI_idx-1, 'D_LENGTH', 0, 0 )
      if (pos > AIpos-qerr and pos < AIend+qerr ) 
          or (pos+len > AIpos-qerr and pos+len < AIend+qerr ) 
          or (pos < AIpos-qerr and pos+len > AIend+qerr )  
       then
        GetSetAutomationItemInfo( env, AI_idx-1, 'D_POSITION', AIpos, 1 )
        GetSetAutomationItemInfo( env, AI_idx-1, 'D_LENGTH', AIend-AIpos, 1 )
        GetSetAutomationItemInfo( env, AI_idx-1, 'D_POOL_QNLEN',  TimeMap_timeToQN_abs( 0, AIend )-TimeMap_timeToQN_abs( 0, AIpos ), 1 ) 
        return AI_idx-1
      end
    end
  end
----------------------------------------------------------------------
function DATA:Process()
  Undo_BeginBlock()
  for i = 1,  CountSelectedMediaItems( -1 ) do
    local item = GetSelectedMediaItem(-1,i-1)
    local t0 = DATA:Process_GetAudioData(item)
    local ret, env, AI_idx =  DATA:Process_GenerateAI(item)
    if ret then DATA:Process_InsertData(item, env, AI_idx, t0) end
  end 
  
  Undo_EndBlock( DATA.UI_name..' - process', 0 )
end
--------------------------------------------------------------------------------  
function UI.draw()  
  if ImGui.Button(ctx, 'Generate') then  DATA:Process() end
  ImGui.SameLine(ctx)
  UI.draw_preset()  
  ImGui.Separator(ctx)
  UI.draw_settings()  
end
--------------------------------------------------------------------------------  
function UI.draw_flow_COMBO(t)
  local trig_action
  local preview_value
  if t.hide == true then return end
  if type(EXT[t.extstr]) == 'number' then 
    for key in pairs(t.values) do 
      local isint = ({math.modf(EXT[t.extstr])})[2] == 0 and ({math.modf(key)})[2] == 0 
      if type(key) == 'number' and key ~= 0 and ((isint==true and EXT[t.extstr]&key==key) or EXT[t.extstr]==key) then preview_value = t.values[key] break end 
    end
   elseif type(EXT[t.extstr]) == 'string' then 
    preview_value = EXT[t.extstr] 
  end
  if not preview_value and t.values[0] then preview_value = t.values[0] end 
  ImGui.SetNextItemWidth( ctx, 280 )
  if t.extw then ImGui.SetNextItemWidth( ctx, t.extw ) end
  if ImGui.BeginCombo( ctx, t.key, preview_value ) then
    for id in spairs(t.values) do
      local selected 
      if type(EXT[t.extstr]) == 'number' then 
        
        local isint = ({math.modf(EXT[t.extstr])})[2] == 0 and ({math.modf(id)})[2] == 0 
        selected = ((isint==true and id&EXT[t.extstr]==EXT[t.extstr]) or id==EXT[t.extstr])  and EXT[t.extstr]~= 0 
      end
      if type(EXT[t.extstr]) == 'string' then selected = EXT[t.extstr]==id end
      
      if ImGui.Selectable( ctx, t.values[id],selected  ) then
        EXT[t.extstr] = id
        trig_action = true
        EXT:save()
        if EXT.CONF_applylive == 1 then DATA:Process() end
      end
    end
    ImGui.EndCombo(ctx)
  end
  
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    trig_action = true
    if EXT.CONF_applylive == 1 then DATA:Process() end
  end  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return  trig_action
end
--------------------------------------------------------------------------------  
function UI.draw_flow_SLIDER(t) 
  local trig_action
    ImGui.SetNextItemWidth( ctx, 150 )
    local retval, v
    local format = t.format
    if type(format)=='function' then format = format(EXT[t.extstr]) end
    if t.int or t.block then 
      retval, v = reaper.ImGui_SliderInt ( ctx, t.key..'##'..t.extstr, math.floor(EXT[t.extstr]), t.min, t.max, format )
      if retval then trig_action = true end
     elseif t.percent then
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr]*100, t.percent_min or 0, t.percent_max or 100, t.format or '%.1f%%' )
      if retval then trig_action = true end
     else  
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr], t.min, t.max, format )
      if retval then trig_action = true end
    end 
    
    if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
      DATA.PRESET_RestoreDefaults(t.extstr)
      trig_action = true
      if EXT.CONF_applylive == 1 then DATA:Process() end
     else
      if retval then 
        if t.percent then EXT[t.extstr] = v /100 else EXT[t.extstr] = v  end
        EXT:save() 
      end
    end 
    if ImGui.IsItemDeactivatedAfterEdit( ctx ) then 
      if EXT.CONF_applylive == 1 then DATA:Process() end
    end
    
    if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return trig_action
end
--------------------------------------------------------------------------------  
function UI.draw_flow_CHECK(t)
  local trig_action
  local byte = t.confkeybyte or 0
  if reaper.ImGui_Checkbox( ctx, t.key, EXT[t.extstr]&(1<<byte)==(1<<byte) ) then 
    EXT[t.extstr] = EXT[t.extstr]~(1<<byte) 
    trig_action = true 
    EXT:save()  
    if EXT.CONF_applylive == 1 then DATA:Process() end
  end
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    trig_action = true 
    if EXT.CONF_applylive == 1 then DATA:Process() end
  end
  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return trig_action
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle('Col_Button',col, 0.5) 
    UI.MAIN_PushStyle('Col_ButtonActive',col, 1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8)
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttonbackgtransparent() 
    UI.MAIN_PushStyle('Col_Button',0, 0) 
    UI.MAIN_PushStyle('Col_ButtonActive',0, 0) 
    UI.MAIN_PushStyle('Col_ButtonHovered',0, 0)
end
--------------------------------------------------------------------- 
function DATA.PRESET_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
--------------------------------------------------------------------- 
function DATA.PRESET_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end
--------------------------------------------------------------------- 
function DATA.PRESET_ApplyPreset(base64str, preset_name)  
  if not base64str then return end
  local  preset_t = {}
  
  local str_dec = DATA.PRESET_decBase64(base64str)
  if str_dec~= '' then 
    for line in str_dec:gmatch('[^\r\n]+') do
      local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
      if key and value and key:match('CONF_') then preset_t[key]= tonumber(value) or value end
    end   
  end 
  for key in pairs(preset_t) do
    if key:match('CONF_') then 
      local presval = preset_t[key]
      EXT[key] = tonumber(presval) or presval
    end
  end 
  
  if preset_name then EXT.CONF_NAME = preset_name end
  EXT:save() 
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttonstyle() UI.MAIN_PopStyle(ctx, nil, 3)end
--------------------------------------------------------------------- 
function DATA.PRESET_RestoreDefaults(key, UI)
  if not key then
    for key in pairs(EXT) do
      if key:match('CONF_') or (UI and UI == true and key:match('UI_'))then
        local val = EXT_defaults[key]
        if val then EXT[key]  = val end
      end
    end
   else
    local val = EXT_defaults[key]
    if val then EXT[key]  = val end
  end
  
  EXT:save() 
end
--------------------------------------------------------------------- 
function DATA.PRESET_GetCurrentPresetData()
  local str = ''
  for key in spairs(EXT) do if key:match('CONF_') then str = str..'\n'..key..'='..EXT[key] end end
  return DATA.PRESET_encBase64(str)
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
--------------------------------------------------------------------------------  
function UI.draw_preset() 
  -- preset 
  
  local select_wsz = 250
  local select_hsz = 18--UI.calc_itemH
  UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Preset') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
  --ImGui.SetCursorPosX( ctx, DATA.display_w-UI.combo_w-UI.spacingX_wind )
  --ImGui.SetNextItemWidth( ctx, UI.combo_w )  
  local preview = EXT.CONF_name 
  
  
  reaper.ImGui_SetNextItemWidth(ctx,-1)
  if ImGui.BeginCombo(ctx, '##Preset', preview, ImGui.ComboFlags_HeightLargest) then 
    if ImGui.Button(ctx, 'Restore defaults') then DATA.PRESET_RestoreDefaults() end
    local retval, buf = reaper.ImGui_InputText( ctx, '##presname', DATA.preset_name )
    if retval then DATA.preset_name = buf end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Save current') then 
      local newID = DATA.preset_name--os.date()
      EXT.CONF_name = newID
      DATA.presets.user[newID] = DATA.PRESET_GetCurrentPresetData() 
      EXT.preset_base64_user =   DATA.PRESET_encBase64(table.save(DATA.presets.user))
      EXT:save() 
    end
    
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5,1)
    
    local id = 0
    for preset in spairs(DATA.presets.factory) do
      id = id + 1
      if ImGui.Selectable(ctx, '[F] '..preset..'##factorypresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.factory[preset], preset)
        EXT:save() 
      end
    end 
    local id = 0
    for preset in spairs(DATA.presets.user) do
      id = id + 1
      if ImGui.Selectable(ctx, preset..'##userpresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.user[preset], preset)
        EXT:save() 
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Remove##remove'..id,0,select_hsz) then 
        DATA.presets.user[preset] = nil
        EXT.preset_base64_user =   DATA.PRESET_encBase64(table.save(DATA.presets.user))
        EXT:save() 
      end
    end 
    
    
    
    ImGui.PopStyleVar(ctx)
    
    
    ImGui.EndCombo(ctx) 
  end  
  
  
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
-------------------------------------------------------------------
function DATA:Process_GetBoundary(item)
  local i_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
  local i_len = GetMediaItemInfo_Value( item, 'D_LENGTH' ) 
  local boundary_start = i_pos
  local boundary_end = i_pos + i_len
  if EXT.CONF_boundary == 1 then
    local tsstart, tsend = GetSet_LoopTimeRange2( 0, false, 0, 0, 0, 0 )
    if tsend - tsstart < 0.1 then return end
    boundary_start = tsstart
    boundary_end = tsend
  end
  return true, boundary_start, boundary_end, i_pos
end
  -------------------------------------------------------------------
  function DATA:Process_InsertData(item, env, AI_idx, t)
    local scaling_mode = GetEnvelopeScalingMode( env )
    
    -- get boundary
      local ret, boundary_start, boundary_end, i_pos = DATA:Process_GetBoundary(item)
      if not ret then return end
      
    -- init vars
      
      local offs = 0 if EXT.CONF_dest == 1 then  offs = i_pos end -- compensate points for AI
    
    -- clear
      DeleteEnvelopePointRangeEx( env, AI_idx, boundary_start-offs, boundary_end-offs )  
      
    -- do window shift
      local wind_offs = 0--window_ms
      
    -- get output points
       output = DATA:Process_InsertData_PF(t, boundary_start, boundary_end, offs, env, AI_idx)
      if EXT.CONF_bypass == 1 then output = nil end
      
    -- add points
      if output then 
        DATA:Process_InsertData_reduceSameVal(output)
        local valout
        local valout_max = ScaleToEnvelopeMode( scaling_mode,1)
        local sz = #output  
        for i = 1, sz do 
          if output[i] and (not output[i].ignore or output[i].ignore==false) then 
            valout = output[i].val 
            
            if EXT.CONF_mode2 == 2 then 
              if valout < EXT.CONF_gate_threshold_dB  then valout = -150 end
              if EXT.CONF_gate_quantize == 1 then if valout > -150 then valout = 0 end end  
            end
            
            local valout = ScaleToEnvelopeMode( scaling_mode, WDL_DB2VAL(valout))
            InsertEnvelopePointEx( env, AI_idx, output[i].tpos+ EXT.CONF_out_shift_ms, valout, EXT.CONF_out_pointsshape , 0, 0, true )
          end 
        end 
        
        Envelope_SortPointsEx( env, AI_idx ) 
        --[[if (EXT.CONF_dest == 0 or EXT.CONF_dest == 2) then -- if AI set scale offset for AI
          GetSetAutomationItemInfo( env, AI_idx, 'D_BASELINE', EXT.CONF_out_AI_D_BASELINE, true )
          GetSetAutomationItemInfo( env, AI_idx, 'D_AMPLITUDE', EXT.CONF_out_AI_D_AMPLITUDE, true )
        end]]
      end
      
      
    -- boundary
      if EXT.CONF_zeroboundary == 1 then
        local ptidx = GetEnvelopePointByTimeEx(env, AI_idx, #t*EXT.CONF_window+boundary_start-offs )
        if ptidx then
          local retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, AI_idx, ptidx )
          reaper.SetEnvelopePointEx(  env, AI_idx, ptidx, time,     ScaleToEnvelopeMode( scaling_mode, 1 ) , shape, tension, selected, true )
        end
      end
      
    -- sort 2nd pass
      Envelope_SortPointsEx( env, AI_idx ) 
  end
  -------------------------------------------------------------------
  function DATA:Process_InsertData_PF(t, boundary_start, boundary_end, offs, env, AI_idx)
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    local output = {}
    local val_norm
    local window_sec = EXT.CONF_window/EXT.CONF_windowoverlap
    local scale = 1 
    if EXT.CONF_mode2 == 0 then scale = EXT.CONF_PF_scale end
    local compressorstate =0
    local compressorstate_latchID
    local compressorstate_latchval
    local norm_out_last
    if 
      (EXT.CONF_mode2 == 0 and EXT.CONF_PF_inv == 0) or  
      (EXT.CONF_mode2 == 2 and EXT.CONF_gate_inv == 0) 
    
      then
    
    
    
    
      local max_dB = -math.huge
      for i = 1,#t do max_dB = math.max(t[i],max_dB) end 
      for i = 1,#t do  
        local tpos = (i-1)*window_sec+boundary_start-offs
        local norm_out = t[i]-max_dB*scale
        output[#output+1] = {tpos=tpos,val=norm_out}
      end 
      
     else
      -- default section for comressor EXT.mode2 == 1
      local min_dB = math.huge
      for i = 1,#t do min_dB = math.min(t[i],min_dB) end 
      for i = 1,#t do  
        local tpos = (i-1)*window_sec+boundary_start-offs
        local norm_out = -(t[i]-min_dB)*scale
        
        -- compressor section
        if EXT.CONF_mode2 == 1 then
          if norm_out > EXT.CONF_comp_thresh then norm_out = 0 end
          if norm_out_last then
            --compressorstate 0 idle 1 attack 2 working 3 release
            
            -- open attack state
            if compressorstate == 0 and norm_out_last == 0 and norm_out < 0 then
              compressorstate = 1
              compressorstate_latchID = i
              compressorstate_latchval = norm_out_last
            end
            
            -- close attack state by release state
            if compressorstate == 1 and norm_out == 0 then
              compressorstate_latchID = i
              compressorstate = 3
            end

            -- open working state
            if compressorstate == 1 and i> compressorstate_latchID + EXT.CONF_comp_attack_wind then
              compressorstate = 2
            end

            -- close working state  by release state
            if compressorstate == 2 and norm_out == 0 then
              compressorstate_latchID = i
              compressorstate_latchval = norm_out_last
              compressorstate = 3
            end

            
            -- close release state by attack state
            if compressorstate == 3 and norm_out < 0 then
              compressorstate = 1
            end

           -- close release state by idle state
           if compressorstate == 3 and i> compressorstate_latchID + EXT.CONF_comp_release_wind then
             compressorstate = 0
           end
          
          
          -- handle attack level
          if compressorstate == 1 and EXT.CONF_comp_attack_wind ~= 0 then 
            local latchedval = compressorstate_latchval
            local attackratio = (i- compressorstate_latchID) / EXT.CONF_comp_attack_wind
            norm_out = norm_out * attackratio
          end
          
          -- handle attack level
          if compressorstate == 3 and EXT.CONF_comp_release_wind ~= 0 then 
            local latchedval = compressorstate_latchval
            local releaseratio = 1-((i- compressorstate_latchID) / EXT.CONF_comp_release_wind)
            norm_out =latchedval * releaseratio
          end
          
          end
          norm_out_last = norm_out
        end
        
        output[#output+1] = {tpos=tpos,val=norm_out*EXT.CONF_comp_mult}
      end 
    end
    
    
    return output
  end  
  -------------------------------------------------------------------
  function DATA:Process_InsertData_reduceSameVal(output)
    local sz = #output  
    -- reduce pts with same values
      if EXT.CONF_reducesamevalues == 1 then
        local last_val = 0
        local trigval
        for i = 1, sz-1 do  
          local val = output[i].val
          local valnext = output[i+1].val
          if last_val == val and valnext == val then output[i].ignore = true end 
          last_val = val
        end
      end
  end
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ----------------------------------------------------------------------
  function UI.draw_settings()  
    if ImGui.BeginTabBar(ctx, 'tabs', ImGui.TabBarFlags_None) then 
    
  
      if ImGui.BeginTabItem(ctx, 'General') then
        UI.draw_flow_CHECK({['key']='Apply parameters at every change',   ['extstr'] = 'CONF_applylive'}) 
        UI.draw_flow_CHECK({['key']='Bypass',                             ['extstr'] = 'CONF_bypass'}) 
        UI.draw_flow_COMBO({['key']='Boundaries',                         ['extstr'] = 'CONF_boundary',               ['values'] = {[0]='Item edges', [1]='Time selection' } })  
        UI.draw_flow_COMBO({['key']='Destination',                        ['extstr'] = 'CONF_dest',                   ['values'] = {[0]='Track volume envelope AI', [1]='Take volume envelope', [2]='Track pre-FX volume envelope AI'} }) 
        UI.draw_flow_SLIDER({['key']='RMS window',                        ['extstr'] = 'CONF_window',                  ['format']=function(x) return (math.floor(x*1000)/1000)..'s' end,    ['min']=0.001,  ['max']=0.4})   
        
        if ImGui.BeginChild(ctx, '##modes',0,0,ImGui.ChildFlags_Border) then
          UI.draw_flow_COMBO({['key']='Mode',                              ['extstr'] = 'CONF_mode2',                   ['values'] = {[0]='Peak follower', [1]='Compressor',[2]='Gate'} }) 
           
          if EXT.CONF_mode2 == 0 then -- pf
            UI.draw_flow_SLIDER({['key']='Scale',                             ['extstr'] = 'CONF_PF_scale',              ['format']=function(x) return math.floor(100*x)..'%%' end,    ['min']=0,  ['max']=1})
            UI.draw_flow_CHECK({['key']='Invert values',                      ['extstr'] = 'CONF_PF_inv',               }) 
          end
          
          if EXT.CONF_mode2 == 1 then -- comp
            UI.draw_flow_SLIDER({['key']='Threshold',                    ['extstr'] = 'CONF_comp_thresh',       int=true, ['format']=function(x) return x..'dB' end,    ['min']=-60,  ['max']=0})
            UI.draw_flow_SLIDER({['key']='Attack',                        ['extstr'] = 'CONF_comp_attack_wind',       int=true, ['format']=function(x) return x*EXT.CONF_window..'s' end,    ['min']=0,  ['max']=40})
            UI.draw_flow_SLIDER({['key']='Release',                        ['extstr'] = 'CONF_comp_release_wind',       int=true, ['format']=function(x) return x*EXT.CONF_window..'s' end,    ['min']=0,  ['max']=40}) 
            UI.draw_flow_SLIDER({['key']='Scale',                             ['extstr'] = 'CONF_comp_mult',              ['format']=function(x) return math.floor(100*x)..'%%' end,    ['min']=0,  ['max']=1})
          end
          
          if EXT.CONF_mode2 == 2 then -- gate
            UI.draw_flow_SLIDER({['key']='Threshold',                    ['extstr'] = 'CONF_gate_threshold_dB',       int=true, ['format']=function(x) return x..'dB' end,    ['min']=-90,  ['max']=0})
            UI.draw_flow_CHECK({['key']='Quantize to 0dB',                    ['extstr'] = 'CONF_gate_quantize',        })
            UI.draw_flow_CHECK({['key']='Invert values',                      ['extstr'] = 'CONF_gate_inv',               }) 
          end
          
          
          
          
          
          ImGui.EndChild(ctx)
        end
        ImGui.EndTabItem(ctx)
      end
      
      
      if ImGui.BeginTabItem(ctx, 'Audio data reader') then
        UI.draw_flow_CHECK({['key']='Clear take volume envelope before',  ['extstr'] = 'CONF_removetkenvvol'}) 
        UI.draw_flow_COMBO({['key']='FFT size',                           ['extstr'] = 'CONF_FFTsz',                   ['values'] = {[-1]='[disabled]', [1024]='1024', [2048] ='2048'}})
        UI.draw_flow_SLIDER({['key']='FFT min freq',                      ['extstr'] = 'CONF_FFT_min',                 ['format']=function(x) return math.floor(x*DATA.SR/2)..'Hz' end,    ['min']=0,  ['max']=1,hide=EXT.CONF_FFTsz==-1})  
        UI.draw_flow_SLIDER({['key']='FFT max freq',                      ['extstr'] = 'CONF_FFT_max',                 ['format']=function(x) return math.floor(x*DATA.SR/2)..'Hz' end,    ['min']=0,  ['max']=1,hide=EXT.CONF_FFTsz==-1 })  
        UI.draw_flow_SLIDER({['key']='RMS window',                        ['extstr'] = 'CONF_window',                  ['format']=function(x) return (math.floor(x*1000)/1000)..'s' end,    ['min']=0.001,  ['max']=0.4})  
        UI.draw_flow_SLIDER({['key']='Window overlap',                    ['extstr'] = 'CONF_windowoverlap',           ['min']=1,  ['max']=16,  int = true})  
        ImGui.EndTabItem(ctx)
      end

      if ImGui.BeginTabItem(ctx, 'Output') then 
        
        UI.draw_flow_CHECK({['key']='Reduce points with same values',            ['extstr'] = 'CONF_reducesamevalues'}) 
        UI.draw_flow_CHECK({['key']='Reset boundary edges',                      ['extstr'] = 'CONF_zeroboundary'}) 
        UI.draw_flow_COMBO({['key']='Points shape',                              ['extstr'] = 'CONF_out_pointsshape',                   ['values'] = {[0]='Linear',[1]='Square',[2]='Slow start/end',[5]='Bezier'} }) 
        UI.draw_flow_SLIDER({['key']='Shift envelope points',                             ['extstr'] = 'CONF_out_shift_ms',           ['format']=function(x) return (math.floor(100*x)/100)..'ms' end,    ['min']=-0.1,  ['max']=0.1})
        ImGui.EndTabItem(ctx)
      end
      
      
      ImGui.EndTabBar(ctx) 
    end
  end
  -----------------------------------------------------
  function VF_GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
  ----------------------------------------------------------------------
  main()