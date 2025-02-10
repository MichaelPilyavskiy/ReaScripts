-- @description RS5k manager
-- @version 4.03
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic5000 data on group of connected tracks
-- @provides
--    [main] mpl_RS5k_manager_Database_NewKit.lua 
--    [main] mpl_RS5k_manager_Database_Lock.lua 
--    [main] mpl_RS5k_manager_Sampler_PreviousSample.lua 
--    [main] mpl_RS5k_manager_Sampler_NextSample.lua 
--    [main] mpl_RS5k_manager_Sampler_RandSample.lua 
--    [main] mpl_RS5k_manager_DrumRack_Solo.lua 
--    [main] mpl_RS5k_manager_DrumRack_Mute.lua 
--    [main] mpl_RS5k_manager_DrumRack_Clear.lua 
--    mpl_RS5k_manager_MacroControls.jsfx 
--    mpl_RS5K_manager_MIDIBUS_choke.jsfx
-- @changelog
--    # various minor UI tweaks



rs5kman_vrs = '4.03'


-- TODO
--[[  
      knob for samples in path
      macro quick link from parameter
      auto switch midi bus record arm if playing with another rack 
      SYSEX feedback to launchpad 
      sampler / sampl / import // or hot record from master bus 
      sequencer 
      auto color tracks by parent folder
      auto color tracks by name
        https://live.mrbillstunes.com/project-file-standards/
        Drum Group = Salmon
        Kicks & Other Low Percussion = Tomato
        Snares & Claps = Rust
        Hi-Hats & Cymbals = Peru
        Top-Kit & Grooves = Dark Olive 
      wildcards - device name
      wildcards - children - #notenuber #noteformat #samplename
      wildcards - samples path 
      launchpad layout 
      compressor
      transient
      fx rack
      fx send 
      ADSR show as curve
      pitch buttons tooltip
]]

    
--------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < 6.73 then return reaper.MB('This script require REAPER 7.0+','',0) end
    local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.9.3.2'
    
    
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 800,
          viewport_posH = 300, 
          
          -- rs5k 
          CONF_onadd_float = 0,
          CONF_onadd_obeynoteoff = 1,
          CONF_onadd_customtemplate = '',
          CONF_onadd_renametrack = 1,
          CONF_onadd_copytoprojectpath = 0,
          CONF_onadd_newchild_trackheightflags = 0, -- &1 folder collapsed &2 folder supercollapsed &4 hide tcp &8 hide mcp
          CONF_onadd_newchild_trackheight = 0,
          CONF_onadd_whitekeyspriority = 0,
          
          -- midi bus
          CONF_midiinput = 63, -- 63 all 62 midi kb
          CONF_midichannel = 0, -- 0 == all channels 
          
          -- sampler
          CONF_cropthreshold = -60, -- db
          CONF_chokegr_limit = 4, 
          CONF_default_velocity = 120,
          
          -- UI
          UI_processoninit = 0,
          UI_addundototabclicks = 0,
          UI_clickonpadselecttrack = 1,
          UI_incomingnoteselectpad = 0,
          UI_defaulttabsflags = 1|4|8, --1=drumrack   2=device  4=sampler 8=padview 16=macro 32=database 64=midi map 128=children chain
          UI_pads_sendnoteoff = 1,
          UI_drracklayout = 0,
          
          -- other 
          CONF_autorenamemidinotenames = 1|2, 
          CONF_trackorderflags = 0,  -- ==0 sort by date ascending, ==2 sort by date descending, ==3 sort by note ascending, ==4 sort by note descending
          CONF_autoreposition = 0, --0 off
          
          CONF_plugin_mapping_b64 = '',
          CONF_ignoreDBload = 0, 
          CONF_showplayingmeters = 1,
          CONF_showpadpeaks = 1,
         }
        
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          
          upd = true,
          ES_key = 'MPL_RS5K manager',
          UI_name = 'RS5K manager', 
          version = 4, -- for ext state save
          bandtypemap = {  
                  [-1] = 'Off',
                  [3] = 'Low pass' ,
                  [0] = 'Low shelf',
                  [1] = 'High shelf' ,
                  [8] = 'Band' ,
                  [4] = 'High pass' ,
                  --[5] = 'All pass' ,
                  --[6] = 'Notch' ,
                  --[7] = 'Band pass' ,
                  --[10] = 'Parallel BP' ,
                  --[9] = 'Band alt' ,
                  --[2] = 'Band alt2' ,
                  },
          playingnote = -1,
          playingnote_trigTS = 0,
          MIDI_inputs = {},
          lastMIDIinputnote = {},
          current_sample_peaks = {},
          reaperDB = {},
          MIDIOSC = {}, 
          actions_popup = {},
          VCA_mode = 0,
          plugin_mapping = {},
          }
  
  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
      -- font
        font='Arial',
        font1sz=15,
        font2sz=14,
        font3sz=12,
      -- mouse
        hoverdelay = 0.8,
        hoverdelayshort = 0.5,
      -- size / offset
        spacingX = 4,
        spacingY = 3,
      -- colors / alpha
        main_col = 0x7F7F7F, -- grey
        textcol = 0xFFFFFF, -- white
        textcol_a_enabled = 1,
        textcol_a_disabled = 0.5,
        but_hovered = 0x878787,
        windowBg = 0x303030,
          }
  
    UI.col_maintheme = 0x00B300 
    UI.col_red = 0xB31F0F  
    UI.w_min = 640
    UI.h_min = 300
    UI.settingsfixedW = 400
    UI.actionsbutW = 60
    UI.colRGBA_selectionrect = 0xF0F0F0<<8|0x9F  
    UI.colRGBA_paddefaultbackgr = 0xA0A0A03F 
    UI.colRGBA_paddefaultbackgr_inactive = 0xA0A0A010
    UI.settings_itemW = 180 
    UI.settings_indent  = 10
    UI.padplaycol = 0x00FF00
    UI.knob_resY = 150
    UI.knob_handle = 0xc8edfa
    UI.knob_handle_normal = UI.knob_handle
    UI.knob_handle_vca =0xFF0000
    UI.knob_handle_vca2 =0xFFFF00
    UI.tab_context = '' -- for context menu
    UI.sampler_peaksH = 60
    UI.col_popup = 0x005300 
    UI.controls_minH = 40
    
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
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
  ------------------------------------------------------- 
  function VF_BFpluginparam(find_Str, tr, fx, param) 
    if not find_Str then return end
    local find_Str_val = find_Str:match('[%d%-%.]+')
    if not (find_Str_val and tonumber(find_Str_val)) then return end
    local find_val =  tonumber(find_Str_val)
    
    local iterations = 500
    local mindiff = 10^-14
    local precision = 10^-10
    local min, max = 0,1
    for i = 1, iterations do -- iterations
      local param_low = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, min) 
      local param_mid = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, min + (max-min)/2) 
      local param_high = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, max)  
      if find_val <= param_low then return min  end
      if find_val == param_mid and math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
      if find_val >= param_high then return max end
      if find_val > param_low and find_val < param_mid then 
        min = min 
        max = min + (max-min)/2 
        if math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
       else
        min = min + (max-min)/2 
        max = max 
        if math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
      end
    end 
    
  end 
  -------------------------------------------------------  
  function VF_BFpluginparam_GetFormattedParamInternal(tr, fx, param, val)
    local param_n
    if val then TrackFX_SetParamNormalized( tr, fx, param, val ) end
    local _, buf = TrackFX_GetFormattedParamValue( tr , fx, param, '' )
    --local param_str = buf:match('%-[%d%.]+') or buf:match('[%d%.]+')
    local param_str = buf:match('[%d%a%-%.]+')
    if param_str then param_n = tonumber(param_str) end
    if not param_n and param_str:lower():match('%-inf') then param_n = - math.huge
    elseif not param_n and param_str:lower():match('inf') then param_n = math.huge end
    return param_n
  end
  -------------------------------------------------------  
  function VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision)
    for value_precise = min, max, precision do
      local param_form = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, value_precise)  
      if find_val == param_form then  return value_precise end
    end
    return min + (max-min)/2 
  end 
    -----------------------------------------------------------------------------  
  function VF_Open_URL(url) if GetOS():match("OSX") then os.execute('open "" '.. url) else os.execute('start "" '.. url)  end  end  
  ---------------------------------------------------------------------------------------------------------------------
  function VF_NormalizeT(t, key) 
    local m = 0 
    for i in pairs(t) do 
      if not key then 
        m = math.max(math.abs(t[i]),m) 
       else
        m = math.max(math.abs(t[i][key]),m) 
      end
    end
    for i in pairs(t) do 
      if not key then
        t[i] = t[i] / m 
       else 
        t[i][key] = t[i][key] / m 
      end
    end
  end 
  ---------------------------------------------------------------------
  function VF_GetLTP()
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
-----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
function table.exportstring( s ) return string.format("%q", s) end

--// The Save Function
function table.savestring(  tbl )
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
function table.loadstring( str )
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
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
    ---------------------------------------------------------------------  
  function VF_LIP_load(fileName) -- https://github.com/Dynodzzo/Lua_INI_Parser/blob/master/LIP.lua
    assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.');
    local file = assert(io.open(fileName, 'r'), 'Error loading file : ' .. fileName);
    local data = {};
    local section;
    for line in file:lines() do
      local tempSection = line:match('^%[([^%[%]]+)%]$');
      if(tempSection)then
        section = tonumber(tempSection) and tonumber(tempSection) or tempSection;
        data[section] = data[section] or {};
      end
      local param, value = line:match('^([%w|_]+)%s-=%s-(.+)$');
      if(param and value ~= nil)then
        if(tonumber(value))then
          value = tonumber(value);
        elseif(value == 'true')then
          value = true;
        elseif(value == 'false')then
          value = false;
        end
        if(tonumber(param))then
          param = tonumber(param);
        end
        if data[section] then 
          data[section][param] = value;
        end
      end
    end
    file:close();
    return data;
  end
    ---------------------------------------------------------------------------------------------------------------------
  function VF_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
  ------------------------------------------------------------------------------------------------------
  function VF_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
  ---------------------------------------------------------------------------------------------------------------------
  function VF_GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end
  ---------------------------------------------------------------------  
  function VF_Format_Pan(D_PAN) 
    local D_PAN_format = 'C'
    if D_PAN > 0 then 
      D_PAN_format = math.floor(math.abs(D_PAN*100))..'R'
     elseif D_PAN < 0 then 
      D_PAN_format = math.floor(math.abs(D_PAN*100))..'L'
    end
    return D_PAN_format
  end
  ----------------------------------------------------------------------- 
  function VF_Format_Note(note ,t) 
    local offs = 0
    if DATA.REAPERini and DATA.REAPERini.REAPER and DATA.REAPERini.REAPER.midioctoffs then offs = DATA.REAPERini.REAPER.midioctoffs end
    local val = math.floor(note)
    local oct = math.floor(note / 12)
    local note = math.fmod(note,  12)
    local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
    
    local out_str 
    
    -- handle names
      if t and t.P_NAME then out_str = t.P_NAME end 
    -- handle db
      if t and t.layers then 
        local hasdb
        for layer = 1, #t.layers do
          if t.layers[layer].SET_useDB and t.layers[layer].SET_useDB&1==1 then 
            hasdb = true
          end
        end
        if hasdb == true then out_str = '[DB] '..out_str  end
      end
      
      if out_str then return out_str end
      
    -- note  
      if note and oct and key_names[note+1] then 
        return key_names[note+1]..oct-1 
      end
  end
  
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else return v end
  end
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or -1) do
      local tr = GetTrack(reaproj or -1,i-1)
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  ---------------------------------------------------
  function VF_GetFXByGUID(GUID, tr, proj)
    if not GUID then return end
    local pat = '[%p]+'
    if not tr then
      for trid = 1, CountTracks(proj or -1) do
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
      if not (ValidatePtr2(proj or -1, tr, 'MediaTrack*')) then return end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
        if TrackFX_GetFXGUID( tr, fx_dest-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_dest-1 end 
      end
    end    
  end

  --------------------------------------------------------------------------------  
  function UI.Tools_setbuttonbackg(col)   
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, col or 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, col or 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, col or 0 )
  end
  --UI.Tools_setbuttonbackg()
  --UI.Tools_unsetbuttonstyle()
    --------------------------------------------------------------------------------  
  function UI.Tools_unsetbuttonstyle() ImGui.PopStyleColor(ctx,3) end 
  -------------------------------------------------------------------------------- 
  function UI.Tools_RGBA(col, a_dec) return col<<8|math.floor(a_dec*255) end  
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
      UI.anypopupopen = ImGui.IsPopupOpen( ctx, 'mainRCmenu', ImGui.PopupFlags_AnyPopup|ImGui.PopupFlags_AnyPopupLevel )
      
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      --window_flags = window_flags | ImGui.WindowFlags_MenuBar
      --window_flags = window_flags | ImGui.WindowFlags_NoMove()
      --window_flags = window_flags | ImGui.WindowFlags_NoResize
      window_flags = window_flags | ImGui.WindowFlags_NoCollapse
      --window_flags = window_flags | ImGui.WindowFlags_NoNav()
      --window_flags = window_flags | ImGui.WindowFlags_NoBackground
      --window_flags = window_flags | ImGui.WindowFlags_NoDocking
      --window_flags = window_flags | ImGui.WindowFlags_TopMost
      window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      --window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings
      --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
      --open = false -- disable the close button
    
    
    -- rounding
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,5)   
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding,3)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding,10)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding,5)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,10)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding,9)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabRounding,4)   
    -- Borders
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize,0)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize,0) 
    -- spacing
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX*2,UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,UI.spacingX, UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX, UI.spacingY)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,4,0)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing,20)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,10)
    -- size
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,20)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,UI.w_min,UI.h_min)
    -- align
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,0,0.5)
      
    -- alpha
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha,0.98)
      ImGui.PushStyleColor(ctx, ImGui.Col_Border,           UI.Tools_RGBA(0x000000, 0.3))
    -- colors
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.main_col, 0.2))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.but_hovered, 0.8))
      ImGui.PushStyleColor(ctx, ImGui.Col_DragDropTarget,   UI.Tools_RGBA(0xFF1F5F, 0.6))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,          UI.Tools_RGBA(0x1F1F1F, 0.7))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,    UI.Tools_RGBA(UI.main_col, .6))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered,   UI.Tools_RGBA(UI.main_col, 0.7))
      ImGui.PushStyleColor(ctx, ImGui.Col_Header,           UI.Tools_RGBA(UI.main_col, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive,     UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,    UI.Tools_RGBA(UI.main_col, 0.98) )
      ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,          UI.Tools_RGBA(0x303030, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGrip,       UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripHovered,UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,       UI.Tools_RGBA(UI.col_maintheme, 0.6) )
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, UI.Tools_RGBA(UI.col_maintheme, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_Tab,              UI.Tools_RGBA(UI.main_col, 0.37) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected,       UI.Tools_RGBA(UI.col_maintheme, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered,       UI.Tools_RGBA(UI.col_maintheme, 0.8) )
      ImGui.PushStyleColor(ctx, ImGui.Col_Text,             UI.Tools_RGBA(UI.textcol, UI.textcol_a_enabled) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg,          UI.Tools_RGBA(UI.main_col, 0.7) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive,    UI.Tools_RGBA(UI.main_col, 0.95) )
      ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,         UI.Tools_RGBA(UI.windowBg, 1))
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font2) 
      local titlename = ''
      if DATA.parent_track and DATA.parent_track.name and DATA.parent_track.IP_TRACKNUMBER_0based then titlename = '[Track '..math.floor(DATA.parent_track.IP_TRACKNUMBER_0based+1)..'] '..DATA.parent_track.name..' // '..DATA.UI_name..' '..rs5kman_vrs end
      local rv,open = ImGui.Begin(ctx, titlename..'##'..DATA.UI_name, open, window_flags) 
      if rv then
        local Viewport = ImGui.GetWindowViewport(ctx)
        DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
        DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
        DATA.display_x_work, DATA.display_y_work = ImGui.Viewport_GetWorkPos(Viewport)
        -- hidingwindgets
        DATA.display_whratio = DATA.display_w / DATA.display_h
        UI.hide_padoverview = false
        UI.hide_tabs = false 
        if DATA.display_whratio < 1.7 then UI.hide_padoverview = true end
        if DATA.display_w < UI.settingsfixedW * 1.8 then UI.hide_tabs = true end
        --if DATA.display_w > UI.settingsfixedW * 5 then UI.hide_tabs = true end
        
        -- calc stuff for childs
        UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
        local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
        local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
        UI.calc_itemH = calcitemh + frameh * 2
        
        -- calc Rack data
        UI.calc_cellside = (DATA.display_h - UI.spacingY*2 - UI.calc_itemH)/32
        UI.calc_padoverviewH = DATA.display_h- UI.spacingY*2- UI.calc_itemH
        UI.calc_padoverviewW = UI.calc_cellside * 4 + UI.spacingX*2
        if UI.calc_padoverviewW < 30 then UI.hide_padoverview = true end
        if EXT.UI_drracklayout == 1 then --keys
          UI.calc_cellside = (DATA.display_h - UI.spacingY*2 - UI.calc_itemH)/22
          UI.calc_padoverviewW = UI.calc_cellside * 7 + UI.spacingX*2
        end 
        local calc_padoverviewW = UI.calc_padoverviewW
        
        -- rack
        UI.calc_rackX = DATA.display_x + UI.calc_padoverviewW
        UI.calc_rackY = DATA.display_y + UI.spacingY + UI.calc_itemH
        if ImGui_IsWindowDocked( ctx ) then UI.calc_rackY = DATA.display_y + UI.spacingY end
        local settingsfixedW = UI.settingsfixedW
        if UI.hide_padoverview == true then 
          calc_padoverviewW = 0
          UI.calc_rackX = DATA.display_x+UI.spacingX*2
        end
        if UI.hide_tabs == true then settingsfixedW = UI.spacingX*4 end 
        UI.calc_rackW = math.min(DATA.display_w - settingsfixedW - calc_padoverviewW,500)
        UI.calc_rackH = math.max(math.floor(DATA.display_h  - UI.calc_itemH-UI.spacingY*2 )-1,250)
        UI.calc_rack_padw = math.floor((UI.calc_rackW-UI.spacingX*3) / 4)
        UI.calc_rack_padh = math.floor((UI.calc_rackH-UI.spacingY*3) / 4)
        if EXT.UI_drracklayout == 1 then --keys
          UI.calc_rack_padw = math.floor((UI.calc_rackW) / 7)-- -UI.spacingX
          UI.calc_rack_padh = math.floor((UI.calc_rackH) / 4)
        end
        UI.calc_rack_padctrlW = UI.calc_rack_padw / 3 
        UI.calc_rack_padctrlH = UI.calc_rack_padh*0.3
        UI.calc_rack_padnameH = UI.calc_rack_padh-UI.calc_rack_padctrlH 
        
        
        -- small knob controls
        UI.calc_knob_w_small = math.floor((settingsfixedW - UI.spacingX*9) / 8) 
        UI.calc_knob_h_small = 80--math.floor((DATA.display_h  - UI.calc_itemH*3-UI.spacingY*7 - UI.sampler_peaksH)/2)
        -- small macro controls
        UI.calc_macro_w = math.floor((settingsfixedW - UI.spacingX*7) / 4)
        UI.calc_macro_h = math.floor((DATA.display_h - UI.spacingY*4 - UI.calc_itemH*3) / 4)
        
        -- sampler 
        UI.calc_sampler4ctrl_W = math.floor((settingsfixedW - UI.spacingX*5) / 4) 
         
        -- get drawlist
        UI.draw_list = ImGui.GetWindowDrawList( ctx )
        
        -- draw stuff
        UI.draw() 
        UI.draw_actions()  
        ImGui.Dummy(ctx,0,0) 
        ImGui.End(ctx)
      end 
     
    -- pop
      ImGui.PopStyleVar(ctx, 22) 
      ImGui.PopStyleColor(ctx, 23) 
      ImGui.PopFont( ctx ) 
    
    -- shortcuts
      if UI.anypopupopen == true then 
        if ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false ) then DATA.trig_closepopup = true end 
       else 
        if ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false ) then return end
      end
  
    return open
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_loop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
    
    DATA:CollectData_Always()
    
    if DATA.upd == true then  DATA:CollectData()  end 
    DATA.upd = false 
     
    if DATA.upd_TCP == true then  
      TrackList_AdjustWindows( false ) 
      DATA.upd_TCP = false
    end
    
    -- draw UI
    if not reaper.ImGui_ValidatePtr( ctx, 'ImGui_Context*') then UI.MAIN_definecontext() end
    UI.open = UI.MAIN_styledefinition(true) 
    
    -- handle xy
    DATA:handleViewportXYWH()
    
    -- data
    if UI.open then defer(UI.MAIN_loop) end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_definecontext()
    
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
    defer(UI.MAIN_loop)
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
    --DATA.upd = true
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
    function VF_GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
  --------------------------------------------------------------------------------  
  function DATA:CollectData()  
    DATA.proj, DATA.proj_fn = EnumProjects( -1 )
    DATA.SR = VF_GetProjectSampleRate()
    
     -- parent
    DATA.parent_track = {
        valid = false,
        name = '', 
      }
    DATA:CollectData_Parent()
    
    -- children
    DATA.MIDIbus = {} 
    DATA.children = {}
    DATA:CollectData_Children()
    
    -- macro
    DATA:CollectData_Macro()
    
    
    -- other
    DATA:CollectData_ReadChoke() 
    
    -- auto handle routing and stuff
    DATA:Auto_MIDIrouting() 
    DATA:Auto_MIDInotenames() 
    DATA:Auto_TCPMCP() 
    
    -- UI
    DATA:CollectData_GetPeaks()
    
  end
  -------------------------------------------------------------------------------- 
  function DATA:Auto_TCPMCP()
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    
    if EXT.CONF_onadd_newchild_trackheightflags &1==1 then       -- set folder collapsed
      SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 1)
     elseif EXT.CONF_onadd_newchild_trackheightflags &2==2 then       -- set folder collapsed
      SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 2)
     elseif EXT.CONF_onadd_newchild_trackheightflags &2~=2 and EXT.CONF_onadd_newchild_trackheightflags &1~=1 then       -- set folder collapsed
      local foldstate = GetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT')   
      if foldstate ~=0 then SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 0)       end
    end
  
    --if EXT.CONF_onadd_newchild_trackheightflags &4==4 or EXT.CONF_onadd_newchild_trackheightflags &8==8 then
      for child in pairs(DATA.children) do
        local tr = DATA.children[child].tr_ptr
        -- device
        if tr then 
          if EXT.CONF_onadd_newchild_trackheightflags &8==8 then 
            if GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 0 )end
           elseif EXT.CONF_onadd_newchild_trackheightflags &4==4 then 
            if GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 0 )end 
           else 
            if GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 0 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 1 )end             
            if GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 0 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1 )end             
          end
        end
        -- children
        for layer = 1, #DATA.children[child].layers do 
          local tr = DATA.children[child].layers[layer].tr_ptr
          if tr then 
            if EXT.CONF_onadd_newchild_trackheightflags &8==8 then 
              if GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 0 )end
             elseif EXT.CONF_onadd_newchild_trackheightflags &4==4 then 
              if GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 0 )end 
             else 
              if GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 0 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 1 )end             
              if GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 0 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1 )end             
            end
          end
        end
      end
    --end
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_ParseREAPERDB()
    if EXT.CONF_ignoreDBload == 1 then return end
    local reaperini = get_ini_file()
    local backend = VF_LIP_load(reaperini)
    local exp_section = backend.reaper_explorer
    if not exp_section then 
      exp_section = backend.reaper_sexplorer
      if not exp_section then return end
    end 
    
    
    local reaperDB = {}
    for key in pairs(exp_section) do
      if key:match('Shortcut') then 
        if tostring(exp_section[key]) and tostring(exp_section[key]):lower():match('reaperfilelist') then 
          local db_key = key:gsub('Shortcut','ShortcutT')
          if exp_section[db_key] then   
            local dbame = exp_section[db_key]
            local db_filename = exp_section[key]
            DATA.reaperDB[dbame] = {filename = db_filename}
            
            local fullfp =  GetResourcePath()..'/MediaDB/'..db_filename
            local t = {}
            if  file_exists( fullfp ) then  
              t = {}
              local f =io.open(fullfp,'rb')
              local content = ''
              if f then  content = f:read('a') end f:close() 
              for line in content:gmatch('[^\r\n]+') do
                if line:match('FILE %"(.-)%"') then
                  local fp = line:match('FILE %"(.-)%"')
                  t [#t+1] = {fp = fp,
                              fp_short  =VF_GetShortSmplName(fp)
                              }
                end 
              end
            end
            
            DATA.reaperDB[dbame].files = t
            
          end
        end
      end
    end
    
  end
  --[[-------------------------------------------------------------------------------------------------------------------
  function DATA:CollectData_GetPeaks_sub(filename)
    local src = PCM_Source_CreateFromFileEx( filename, true )
    if not src then return end
    
    local it_len =  GetMediaSourceLength( src )
    local SR = GetMediaSourceSampleRate( src )
    local peakrate = 1000
    local src_len =  GetMediaSourceLength( src )
    if src_len > 15 then return end  
    local n_ch = 1
    local want_extra_type = 0--115  -- 's' char
    local peaks = {}
    
    local step = 0.005
    local n_spls = math.floor(step*SR)
    local buf = new_array(n_spls * n_ch * 2) -- min, max, spectral each chan(but now mono only)
    for pos = 0, src_len, step do 
      local segm_peaks = {}
      local retval =  PCM_Source_GetPeaks(    src, 
                                          peakrate, 
                                          pos,--starttime, 
                                          n_ch,--numchannels, 
                                          n_spls, 
                                          want_extra_type, 
                                          buf )
      local spl_cnt  = (retval & 0xfffff)        -- sample_count
      segm_peaks_RMS = 0
      local cnt = 0  
      for i=1, spl_cnt, 2 do cnt = cnt + 1 segm_peaks_RMS = segm_peaks_RMS + buf[i]  end
      peaks[#peaks+ 1] = -segm_peaks_RMS / cnt
      local cnt = 0 
      for i=1, spl_cnt, 2 do cnt = cnt + 1 segm_peaks_RMS = segm_peaks_RMS + buf[i]  end
      peaks[#peaks+ 1] = segm_peaks_RMS / cnt
    end
    buf.clear()
    
    
    
    PCM_Source_Destroy( src )
    VF_NormalizeT(peaks)
    return peaks,it_len
  end]]
  ---------------------------------------------------------------------------------------------------------------------
  function DATA:CollectData_GetPeaks_sub(filename)
    local src = PCM_Source_CreateFromFileEx( filename, true )
    if not src then return end
    
    local it_len =  GetMediaSourceLength( src )
    local peakrate = 1000--reaper.GetMediaSourceSampleRate( src )
    local src_len =  GetMediaSourceLength( src )
    if src_len > 15 then return {}, it_len end  
    local n_ch = 1
    local want_extra_type = 0--115  -- 's' char
    
    local n_spls = math.floor(src_len*peakrate)
    if n_spls < 10 then return end 
    
    local buf = new_array(n_spls * n_ch * 2) -- min, max, spectral each chan(but now mono only)
    local retval =  PCM_Source_GetPeaks(    src, 
                                        peakrate, 
                                        0,--starttime, 
                                        n_ch,--numchannels, 
                                        n_spls, 
                                        want_extra_type, 
                                        buf )
    local spl_cnt  = (retval & 0xfffff)        -- sample_count
    
    local spl_cnt_half = math.floor(spl_cnt)
    local peaks = buf.table()
    
    buf.clear()
    
    
    
    PCM_Source_Destroy( src )
    VF_NormalizeT(peaks)
    return peaks,it_len
  end
  ---------------------------------------------------------------------------------------------------------------------
  function DATA:CollectData_GetPeaks()
    -- validate stuff
    local t, note, layer = DATA:Sampler_GetActiveNoteLayer()
    if not (t and t.instrument_filename) then return end 
    local filename = t.instrument_filename
    
    local peaks = t.peaks_t
    
    if not peaks then 
      peaks = DATA:CollectData_GetPeaks_sub(filename)
      if peaks then 
        DATA:WriteData_Child(t.tr_ptr, {
        SET_PEAKS=table.concat(peaks,'|'),
        }) 
      end
    end
    local arr
    if peaks then arr = new_array(peaks) end
    --for i =1, #peaks do peaks[i] = peaks[i]^0.8 end
    
    DATA.current_sample_peaks = 
                        {peaks=peaks, 
                        src_len=src_len,
                        note=note,
                        layer=layer,
                        arr = arr,
                        offs_start = t.instrument_samplestoffs,
                        offs_end = t.instrument_sampleendoffs,
                        instrument_loopoffs_norm = t.instrument_loopoffs_norm,
                        }
  end    
  --------------------------------------------------------------------------------
  function DATA:CollectData_Always_RecentEvent()
    if not DATA.SR then return end
    local triggernote
    local retval, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
    if retval == 0 then return end -- stop if return null sequence
    if not ((devIdx & 0x10000) == 0 or devIdx == 0x1003e) then return end-- should works without this after REAPER6.39rc2, so thats just in case
    local isNoteOn = rawmsg:byte(1)>>4 == 0x9
    local isNoteOff = rawmsg:byte(1)>>4 == 0x8
    local playingnote = rawmsg:byte(2) 
    if isNoteOn == true and tsval > -4800 then -- only reeeally latest messages
      if (DATA.lastMIDIinputnote and DATA.lastMIDIinputnote ~= playingnote) then triggernote = true end
      DATA.lastMIDIinputnote = playingnote 
    end--{retval=retval, rawmsg=rawmsg, tsval=tsval, devIdx=devIdx, projPos=projPos, projLoopCnt=projLoopCnt,playingnote = rawmsg:byte(2) } 

    
    if triggernote == true then 
      if  EXT.UI_incomingnoteselectpad == 1 and DATA.parent_track and DATA.parent_track.ext then
        DATA.parent_track.ext.PARENT_LASTACTIVENOTE = DATA.lastMIDIinputnote
        DATA:WriteData_Parent() --trigger write parent at script initialization // false storing last touched note to ext state
        DATA.upd = true
      end
    end
    
  end
  --------------------------------------------------------------------------------
  function DATA:CollectData_Always()
    DATA:CollectData_Always_RecentEvent()
    DATA:CollectData_Always_ExtActions() 
    DATA:CollectData_Always_Peaks() 
  end
  ----------------------------------------------------------------------
  function DATA:CollectData_Always_Peaks() 
    if not DATA.children then return end
    if EXT.CONF_showplayingmeters == 0 then return end
    local max_sz = 2
    for note in pairs(DATA.children) do
      if not DATA.children[note].peaks then DATA.children[note].peaks = {} end
      local track = DATA.children[note].tr_ptr
      if track and ValidatePtr2(-1,track, 'MediaTrack*') then
        local L = Track_GetPeakInfo( track, 0 )
        local R = Track_GetPeakInfo( track, 1 )
        table.insert(DATA.children[note].peaks, 1, {L,R})
        local sz = #DATA.children[note].peaks
        local rmsL,rmsR = 0,0
        for i = 1, sz do
          rmsL = rmsL + DATA.children[note].peaks[i][1]
          rmsR = rmsR + DATA.children[note].peaks[i][2]
        end
        DATA.children[note].peaksRMS_L = rmsL / sz
        DATA.children[note].peaksRMS_R = rmsR / sz
        if sz>max_sz then DATA.children[note].peaks[max_sz+1] = nil end
      end
      
    end
  end
  ----------------------------------------------------------------------
  function DATA:CollectData_Always_ExtActions()
    local actions = gmem_read(1025)
    if actions == 0 then return end
    
    -- Device / New kit
    if actions == 1 then    DATA:Sampler_NewRandomKit() end 
    
    
    -- prev sample
    if actions == 2 then   
      local note_layer_t = DATA:Sampler_GetActiveNoteLayer() 
      DATA:Sampler_NextPrevSample(note_layer_t,1) 
    end
    
    -- next sample
    if actions == 3 then   
      local note_layer_t, spls = DATA:Sampler_GetActiveNoteLayer()
      DATA:Sampler_NextPrevSample(note_layer_t,0 )  
    end
    
    -- rand sample
    if actions == 4 then   
      local note_layer_t, spls = DATA:Sampler_GetActiveNoteLayer()
      DATA:Sampler_NextPrevSample(note_layer_t,2 ) 
    end
  
    if actions == 6 then   -- lock active note database changes 
      if DATA.parent_track and DATA.parent_track.ext then
        local note_layer_t = DATA:Sampler_GetActiveNoteLayer() 
        note_layer_t.SET_useDB = note_layer_t.SET_useDB~2
        DATA.upd = true
        Undo_BeginBlock2(DATA.proj )
        DATA:WriteData_Child(tr, {SET_useDB=note_layer_t.SET_useDB})
        Undo_EndBlock2( DATA.proj , 'RS5k manager - lock sample from randomization', 0xFFFFFFFF )  
      end 
    end
    
    if actions == 7 then   -- drumrack solo
      if DATA.parent_track and DATA.parent_track.ext then 
        local note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE
        local note_t = DATA.children[note]
        Undo_BeginBlock2(DATA.proj )
        local outval = 2 if note_t.I_SOLO>0 then outval = 0 end SetMediaTrackInfo_Value( note_t.tr_ptr, 'I_SOLO', outval ) DATA.upd = true
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Solo pad', 0xFFFFFFFF ) 
      end 
    end
    
    if actions == 8 then   -- drumrack mute
      if DATA.parent_track and DATA.parent_track.ext then 
        local note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE
        local note_t = DATA.children[note]
        Undo_BeginBlock2(DATA.proj )
        SetMediaTrackInfo_Value( note_t.tr_ptr, 'B_MUTE', note_t.B_MUTE~1 ) DATA.upd = true
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Mute pad', 0xFFFFFFFF ) 
      end 
    end
  
    if actions == 9 then   -- drumrack clear
      if DATA.parent_track and DATA.parent_track.ext then 
        DATA:Sampler_RemovePad(DATA.parent_track.ext.PARENT_LASTACTIVENOTE)
      end
    end
    
    
    gmem_write(1025,0 )
  end
  -----------------------------------------------------------------------
  function DATA:Sampler_RemovePad(note, layer) 
    if not (note and DATA.children and DATA.children[note]) then return end 
    local tr_ptr = DATA.children[note].tr_ptr
    if layer and DATA.children[note].layers and DATA.children[note].layers[layer] and DATA.children[note].layers[layer].tr_ptr then tr_ptr = DATA.children[note].layers[layer].tr_ptr end 
    --[[if not layer and not tr_ptr then 
      layer = 1
      if DATA.children[note].layers and DATA.children[note].layers[layer] then tr_ptr = DATA.children[note].layers[layer].tr_ptr end 
    end]]
    
    if not (tr_ptr and ValidatePtr2(-1,tr_ptr,'MediaTrack*')) then return end
    
    Undo_BeginBlock2(DATA.proj )
    --DeleteTrack( tr_ptr )
    Main_OnCommand(40769,0)-- Unselect (clear selection of) all tracks/items/envelope points 
    SetOnlyTrackSelected( tr_ptr )
    --Main_OnCommand(40184,0)-- Remove items/tracks/envelope points (depending on focus) - no prompting // THIS remove device with childrens AND handles keeping structure 
    Main_OnCommand(40005,0)-- Track: Remove tracks
    Undo_EndBlock2( DATA.proj , 'RS5k manager - Remove pad', 0xFFFFFFFF ) 
    SetOnlyTrackSelected( DATA.parent_track.ptr )
    DATA.upd = true
  end 
  ---------------------------------------------------------------------------------------------------------------------
  function DATA:Sampler_GetActiveNoteLayer()  
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end
    local layer =  DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER or 1  
    local note if not DATA.parent_track.ext.PARENT_LASTACTIVENOTE then return else note =DATA.parent_track.ext.PARENT_LASTACTIVENOTE end
    
    if DATA.children[note] 
      and DATA.children[note].layers 
      and DATA.children[note].layers[layer] then  
      return DATA.children[note].layers[layer],note,layer
    end
    
    if DATA.children[note] and DATA.children[note].layers and not DATA.children[note].layers[layer] then  
      return DATA.children[note],note,0
    end
    
  end
  -------------------------------------------------------------------------------- 
  function DATA:Sampler_NextPrevSample_getfilestable(note_layer_t) 
    local fn = note_layer_t.instrument_filename:gsub('\\', '/') 
    local path = fn:reverse():match('[%/]+.*'):reverse():sub(0,-2)
    local cur_file =     fn:reverse():match('.-[%/]'):reverse():sub(2)
    local files_table = {}
    if note_layer_t.SET_useDB&1~=1 then 
      local i = 0
      repeat
        local fp = reaper.EnumerateFiles( path, i )
        if fp and reaper.IsMediaExtension(fp:gsub('.+%.', ''), false) then
          files_table[#files_table+1] = { fp = path..'/'..fp,
                                          fp_short  =fp
                                        }
        end
        i = i+1
      until fp == nil
      table.sort(files_table, function(a,b) return a.fp_short<b.fp_short end )
     else
      local db_name = note_layer_t.SET_useDB_name
      if db_name and DATA.reaperDB[db_name] then files_table = DATA.reaperDB[db_name].files end
    end
    return files_table,cur_file
  end
  -------------------------------------------------------------------------------- 
  function DATA:Sampler_NextPrevSample(note_layer_t, mode) 
     
    if not mode then mode = 0 end
    if not note_layer_t.ISRS5K then return end
    
   
    local files_table,cur_file = DATA:Sampler_NextPrevSample_getfilestable(note_layer_t) 
    local trig_id
    local undohistory_str = 'Next sample'
    local files_tablesz = #files_table 
    
    local currentID = note_layer_t.SET_useDB_lastID
    if not currentID and mode ~=2 then 
      for i = 1, #files_table do if files_table[i].fp_short == cur_file then  currentID=i break end  end
    end
    
    if mode == 0  then    -- search file list next
      if #files_table < 2 then return end
      trig_id = currentID + 1
      if trig_id > files_tablesz then trig_id = 1 end--wrap
      goto trig_file_section
    end
    
    if mode == 1  then    -- search file list prev
      if files_tablesz < 2 then return end
      trig_id = currentID - 1
      if trig_id <1 then trig_id = files_tablesz end--wrap
      goto trig_file_section
    end
      
    if mode ==2 then        -- search file list random
      math.randomseed(time_precise()*10000)
      if #files_table < 2 then return end
      trig_id = math.floor(math.random(#files_table)) +1
      goto trig_file_section 
    end    
    
    ::trig_file_section::
    if trig_id and files_table[trig_id] then 
      local trig_file = files_table[trig_id].fp
      Undo_BeginBlock2(DATA.proj )
      DATA:DropSample(trig_file, note_layer_t.noteID, {layer=note_layer_t.layerID})  
      Undo_EndBlock2( DATA.proj , 'RS5k manager - '..undohistory_str, 0xFFFFFFFF ) 
      DATA:WriteData_Child(note_layer_t.tr_ptr, {SET_useDB_lastID = trig_id})   
    end
      
  end
  --------------------------------------------------------------------------------  
  function DATA:CollectData_MIDIdevices()
    DATA.MIDI_inputs = {[63]='All inputs',[62]='Virtual keyboard'}
    for dev = 1, reaper.GetNumMIDIInputs() do
      local retval, nameout = reaper.GetMIDIInputName( dev-1, '' )
      if retval then DATA.MIDI_inputs[dev-1] = nameout end
    end
  end
  --------------------------------------------------------------------- 
  function DATA:Auto_MIDInotenames() 
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    
    for note = 0,127 do 
      if EXT.CONF_autorenamemidinotenames&1==1 then 
        -- midi bus
        if DATA.MIDIbus.valid == true then
          local outname = ''
          if DATA.children[note] and DATA.children[note].P_NAME then outname = DATA.children[note].P_NAME end
          local curname = GetTrackMIDINoteNameEx( DATA.proj,  DATA.MIDIbus.tr_ptr, note,-1 )
          if curname ~= outname then SetTrackMIDINoteNameEx( DATA.proj,  DATA.MIDIbus.tr_ptr, note, -1, outname) end
        end
      end
      
      if EXT.CONF_autorenamemidinotenames&2==2 then 
        -- clear device
        if DATA.children[note] and DATA.children[note].tr_ptr and DATA.children[note].TYPE_DEVICE == true then 
          local curname = GetTrackMIDINoteNameEx( DATA.proj,  DATA.children[note].tr_ptr, note,-1 )
          if curname ~= '' then SetTrackMIDINoteNameEx( DATA.proj, DATA.children[note].tr_ptr, note, -1, '') end
        end
        -- set reg childrens to only theirs notes
        if DATA.children[note] and DATA.children[note].tr_ptr and DATA.children[note].layers then 
          for layer =1 , #DATA.children[note].layers do
            for tracknote = 0, 127 do
              local outname = ''
              if tracknote == note then outname =DATA.children[note].layers[layer].P_NAME end
              local curname = GetTrackMIDINoteNameEx( DATA.proj,  DATA.children[note].layers[layer].tr_ptr, tracknote,-1 )
              if curname ~= outname then SetTrackMIDINoteNameEx( DATA.proj,  DATA.children[note].layers[layer].tr_ptr, tracknote, -1, outname) end
            end 
          end
        end
        
      end
    end
  end
  -----------------------------------------------------------------------  
  function DATA:Validate_InitFilterDrive(note_layer_t) 
    local track = note_layer_t.tr_ptr
    if not note_layer_t.fx_reaeq_isvalid then 
      local reaeq_pos = TrackFX_AddByName( track, 'ReaEQ', 0, 1 )
      TrackFX_Show( track, reaeq_pos, 2 )
      TrackFX_SetNamedConfigParm( track, reaeq_pos, 'BANDTYPE0',3 )
      TrackFX_SetParamNormalized( track, reaeq_pos, 0, 1 )
      local GUID = reaper.TrackFX_GetFXGUID( track, reaeq_pos )
      DATA:WriteData_Child(track, {FX_REAEQ_GUID = GUID}) 
      DATA.upd = true
    end
     
    if not note_layer_t.fx_ws_isvalid then
      local ws_pos = TrackFX_AddByName( track, 'waveShapingDstr', 0, 1 )--'Distortion\\waveShapingDstr'
      TrackFX_Show( track, ws_pos, 2 )
      TrackFX_SetParamNormalized( track, ws_pos, 0, 0 )
      local GUID = reaper.TrackFX_GetFXGUID( track, ws_pos )
      DATA:WriteData_Child(track, {FX_WS_GUID = GUID}) 
      DATA.upd = true
    end
  end
  --------------------------------------------------------------------- 
  function DATA:Auto_MIDIrouting() 
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    if not (DATA.MIDIbus.valid == true) then return end
    local note_layer_tr = DATA.MIDIbus.tr_ptr
    local cntsends = GetTrackNumSends( note_layer_tr, 0 )
    local sends = {}
    for sendidx = 1, cntsends do
      local I_SRCCHAN = GetTrackSendInfo_Value( note_layer_tr, 0, sendidx-1, 'I_SRCCHAN' )
      local P_DESTTRACK = GetTrackSendInfo_Value( note_layer_tr, 0, sendidx-1, 'P_DESTTRACK' )
      local I_MIDIFLAGS = GetTrackSendInfo_Value( note_layer_tr, 0, sendidx-1, 'I_MIDIFLAGS' )
      local retval, P_DESTTRACK_GUID = reaper.GetSetMediaTrackInfo_String( P_DESTTRACK, 'GUID', '', false )
      if I_SRCCHAN == -1 then
        sends[P_DESTTRACK_GUID] = {
          I_MIDIFLAGS=I_MIDIFLAGS,
          sendidx=sendidx-1,
        }
      end
    end
      
    -- validate links
      for note in pairs(DATA.children) do
        -- make sure there is no midi send to device  
        if DATA.children[note].TYPE_DEVICE == true and DATA.children[note].TR_GUID and sends[DATA.children[note].TR_GUID] then RemoveTrackSend( note_layer_tr, 0, sends[DATA.children[note].TR_GUID].sendidx ) end
        
        -- check devicechilds/regular childs
        if DATA.children[note].layers then
          for layer in pairs(DATA.children[note].layers) do
            if DATA.children[note].layers[layer] and DATA.children[note].layers[layer].TR_GUID then
              local destGUID = DATA.children[note].layers[layer].TR_GUID
              
              if not sends[destGUID] or (sends[destGUID] and sends[destGUID].I_MIDIFLAGS ~= DATA.parent_track.ext.PARENT_MIDIFLAGS) then   
                local sendidx = CreateTrackSend( DATA.MIDIbus.tr_ptr, DATA.children[note].layers[layer].tr_ptr )
                if sendidx >=0 then
                  SetTrackSendInfo_Value( DATA.MIDIbus.tr_ptr, 0, sendidx, 'I_SRCCHAN',-1 )
                  SetTrackSendInfo_Value( DATA.MIDIbus.tr_ptr, 0, sendidx, 'I_MIDIFLAGS',DATA.parent_track.ext.PARENT_MIDIFLAGS )
                end
              end
              
            end 
          end
        end
        
      end   
  end
  --------------------------------------------------------------------- 
  function DATA:CollectData_ReadChoke() 
    -- validate choke
      if not DATA.MIDIbus.tr_ptr then return end
      local tr =  DATA.MIDIbus.tr_ptr
      local fxname = 'mpl_RS5K_manager_MIDIBUS_choke.jsfx' 
      local chokeJSFX_pos =  TrackFX_AddByName( tr, fxname, false, 0 )
      local CHOKE_GUID
      if chokeJSFX_pos == -1 then  
        DATA.MIDIbus.CHOKE_valid = true
        chokeJSFX_pos =  TrackFX_AddByName( tr, fxname, false, -1000 ) 
        CHOKE_GUID = TrackFX_GetFXGUID( tr, chokeJSFX_pos ) 
        DATA:WriteData_Child(tr, {CHOKE_GUID=CHOKE_GUID}) 
        TrackFX_Show( tr, chokeJSFX_pos, 0|2 )
        --for i = 1, 16 do TrackFX_SetParamNormalized( tr, chokeJSFX_pos, 33+i, i/1024 ) end -- ini source gmem IDs
       else
        CHOKE_GUID = TrackFX_GetFXGUID(tr, chokeJSFX_pos ) 
      end
      if chokeJSFX_pos == -1 then return end
    
    -- print to table
      DATA.MIDIbus.CHOKE_valid = true
      DATA.MIDIbus.CHOKE_pos = chokeJSFX_pos
      DATA.MIDIbus.CHOKE_GUID = CHOKE_GUID
     
    -- read group flags
      DATA.MIDIbus.CHOKE_flags = {} 
      for slider = 0, 63 do
        local flags = TrackFX_GetParamNormalized( tr, chokeJSFX_pos, slider )
        flags = math.floor(flags*65535)
        local noteID1 = slider*2
        local noteID2 = slider*2+1
        DATA.MIDIbus.CHOKE_flags[noteID1] = flags&0xFF
        DATA.MIDIbus.CHOKE_flags[noteID2] = (flags>>8)&0xFF 
      end
  end 
  -----------------------------------------------------------------------
  function DATA:Sampler_NewRandomKit() 
    if not (DATA.parent_track and DATA.parent_track.ext) then return end
    Undo_BeginBlock2(DATA.proj )
    
    
    for note in pairs(DATA.children) do 
      if DATA.children[note].TYPE_DEVICE~= true then 
        for layer =1,#DATA.children[note].layers do 
          local note_layer_t = DATA.children[note].layers[layer]
          if note_layer_t.SET_useDB&1==1 and  note_layer_t.SET_useDB&2~=2 then DATA:Sampler_NextPrevSample(note_layer_t, 2) end
        end
      end
    end
    
    
    Undo_EndBlock2( DATA.proj , 'RS5k manager - New kit', 0xFFFFFFFF )
    DATA.upd=true
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Parent()  
    DATA.parent_track.ext_load = false
    -- get track pointer
      local parent_track 
      local retval, trGUIDext = reaper.GetProjExtState( DATA.proj, 'MPLRS5KMAN', 'STICKPARENTGUID' )
      if retval and trGUIDext ~= '' then 
        parent_track = VF_GetTrackByGUID(trGUIDext, DATA.proj)
        if not parent_track then 
          parent_track = GetSelectedTrack(DATA.proj,0) 
          SetProjExtState( DATA.proj, 'MPLRS5KMAN', 'STICKPARENTGUID','' )
        end -- load selected track if external is not found
        DATA.parent_track.ext_load = true
       else
        -- get selected track
        parent_track = GetSelectedTrack(DATA.proj,0)
      end
    
    
    -- catch parent by childen
      if parent_track then 
        local ret, parGUID = DATA:CollectData_IsChildOwnedByParent(parent_track)
        if parGUID and parGUID ~= '' then parent_track = VF_GetTrackByGUID(parGUID,DATA.proj) end 
      end
      
    if not parent_track then return end 
    
    -- get native data
      local retval, trGUID = GetSetMediaTrackInfo_String( parent_track, 'GUID', '', false ) 
      local retval, name = GetSetMediaTrackInfo_String( parent_track, 'P_NAME', '', false )
      local IP_TRACKNUMBER_0based = GetMediaTrackInfo_Value( parent_track, 'IP_TRACKNUMBER')-1 
      local I_FOLDERDEPTH = GetMediaTrackInfo_Value( parent_track, 'I_FOLDERDEPTH')
      local cnt_tracks = CountTracks( DATA.proj )
      local IP_TRACKNUMBER_0basedlast = IP_TRACKNUMBER_0based
      if I_FOLDERDEPTH == 1 then
        local depth = 0
        for trid = IP_TRACKNUMBER_0based + 1, cnt_tracks do
          local tr = GetTrack(DATA.proj, trid-1)
          depth = depth + GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH')
          if depth == 0 then 
            IP_TRACKNUMBER_0basedlast = trid-1
            break
          end
        end
      end 
      
    -- init ext data
      DATA.parent_track.ext = {
          PARENT_DRRACKSHIFT = 36,
          PARENT_MACROCNT = 16,
          PARENT_LASTACTIVENOTE = -1,
          PARENT_LASTACTIVENOTE_LAYER = 1,
          PARENT_LASTACTIVEMACRO = -1,
          PARENT_MIDIFLAGS = 0,
          PARENT_MACRO_GUID = '',
        }
        
    -- read values v3 (backw compatibility)
      local retval, chunk = GetSetMediaTrackInfo_String(parent_track, 'P_EXT:MPLRS5KMAN', '', false )
      if retval and chunk ~= '' then
        for line in chunk:gmatch('[^\r\n]+') do
          local key,value = line:match('([%p%a%d]+)%s([%p%a%d]+)')
          if key and value then 
            DATA.parent_track.ext[key] = tonumber(value) or value
          end
        end
      end
    
    -- v4
      local ret, DRRACKSHIFT = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_DRRACKSHIFT', 0, false)          if ret then DATA.parent_track.ext.PARENT_DRRACKSHIFT = tonumber(DRRACKSHIFT) end
      local ret, MACROCNT = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_MACROCNT', 0, false)               if ret then DATA.parent_track.ext.PARENT_MACROCNT = tonumber(MACROCNT) end
      local ret, LASTACTIVENOTE = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_LASTACTIVENOTE', 0, false)   if ret then DATA.parent_track.ext.PARENT_LASTACTIVENOTE = tonumber(LASTACTIVENOTE) end
      local ret, LASTACTIVENOTE_LAYER = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_LASTACTIVENOTE_LAYER', 0, false)  if ret then DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER = tonumber(LASTACTIVENOTE_LAYER ) end
      local ret, LASTACTIVEMACRO = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_LASTACTIVEMACRO', 0, false)  if ret then DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = tonumber(LASTACTIVEMACRO ) end
      local ret, MIDIFLAGS = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_MIDIFLAGS', 0, false)               if ret then DATA.parent_track.ext.PARENT_MIDIFLAGS = tonumber(MIDIFLAGS) end
      local ret, MACRO_GUID = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_MACRO_GUID', 0, false)             if ret then DATA.parent_track.ext.PARENT_MACRO_GUID = MACRO_GUID end
      local ret, MACROEXT_B64 = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_MACROEXT_B64', 0, false)
       if ret then 
        DATA.parent_track.ext.PARENT_MACROEXT_B64 = MACROEXT_B64      
        DATA.parent_track.ext.PARENT_MACROEXT = table.loadstring(VF_decBase64(MACROEXT_B64)) or {}
      end
    
    DATA.parent_track.valid = true
    DATA.parent_track.ptr = parent_track
    DATA.parent_track.trGUID = trGUID
    DATA.parent_track.name = name
    DATA.parent_track.IP_TRACKNUMBER_0based = IP_TRACKNUMBER_0based
    DATA.parent_track.IP_TRACKNUMBER_0basedlast = IP_TRACKNUMBER_0basedlast
    DATA.parent_track.I_FOLDERDEPTH = I_FOLDERDEPTH
    
    
  end
  ---------------------------------------------------------------------
  function DATA:CollectData_IsChildOwnedByParent(track)  
    local ret, parGUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', '', false)
    if DATA.parent_track.trGUID and parGUID == DATA.parent_track.trGUID then ret = true else ret = false end 
    return ret, parGUID
  end
  --------------------------------------------------------------------- 
  function DATA:CollectData_Macro()
    DATA.parent_track.macro = {}
    if DATA.parent_track.valid ~= true then return end
    local MACRO_GUID = DATA.parent_track.ext.PARENT_MACRO_GUID   
    if not (MACRO_GUID and MACRO_GUID~='') then 
      --DATA:Macro_InitChildrenMacro()
      return 
    end

    -- validate macro jsfx
      local ret,tr, MACRO_pos = VF_GetFXByGUID(MACRO_GUID, DATA.parent_track.ptr, DATA.proj)
      if not (ret and MACRO_pos and MACRO_pos ~= -1) then return end
      DATA.parent_track.macro.pos = MACRO_pos 
      DATA.parent_track.macro.fxGUID = MACRO_GUID
      DATA.parent_track.macro.valid = true

    -- get sliders
      DATA.parent_track.macro.sliders = {}
      for i = 1, 16 do
        local param_val = TrackFX_GetParamNormalized( DATA.parent_track.ptr, MACRO_pos, i )
        DATA.parent_track.macro.sliders[i] = {
          val = param_val,
        }
      end

    -- get links 
      for note in pairs(DATA.children) do
        if DATA.children[note] and DATA.children[note].layers then 
          for layer in pairs(DATA.children[note].layers) do
            has_links = DATA:CollectData_Macro_sub(DATA.children[note].layers[layer])
          end
        end
      end
  end
  -------------------------------------------------------------------  
  function DATA:CollectData_Macro_sub(note_layer_t)
    if not note_layer_t then return end
    if not note_layer_t.tr_ptr then return end
    for fxid = 1,  TrackFX_GetCount( note_layer_t.tr_ptr ) do
      if fxid ~= note_layer_t.MACRO_pos then
        for paramnumber = 0, TrackFX_GetNumParams( note_layer_t.tr_ptr, fxid-1 )-1 do
          local isactive = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.active')})[2] isactive = tonumber(isactive) 
          if isactive and isactive ==1 then
            local src_fx = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.effect')})[2] src_fx = tonumber(src_fx) 
            local src_param = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.param')})[2] src_param = tonumber(src_param) 
            if src_fx and src_fx == note_layer_t.MACRO_pos then
              local retval, pname = reaper.TrackFX_GetParamName( note_layer_t.tr_ptr, fxid-1,paramnumber)
              local macroID = src_param  
              if DATA.parent_track.macro.sliders[macroID] then 
                if not DATA.parent_track.macro.sliders[macroID].links then DATA.parent_track.macro.sliders[macroID].links = {} end
                local linkID = #DATA.parent_track.macro.sliders[macroID].links+1
                local baseline = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'mod.baseline')})[2] baseline = tonumber(baseline) 
                local plink_offset = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.offset')})[2] plink_offset = tonumber(plink_offset) 
                local plink_scale = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.scale')})[2] plink_scale = tonumber(plink_scale) 
                local plink_offset_format = math.floor(plink_offset*100)..'%'
                local plink_scale_format = math.floor(plink_scale*100)..'%'
                
                
                local UI_min = baseline
                local UI_max = baseline + plink_scale
                
                
                DATA.parent_track.macro.sliders[macroID].links[linkID] = {
                    linkID=linkID,
                    param_name = pname,
                    plink_offset = plink_offset,
                    plink_offset_format = plink_offset_format,
                    plink_scale = plink_scale,
                    plink_scale_format = plink_scale_format,
                    note_layer_t = note_layer_t,
                    fx_dest = fxid-1,
                    param_dest = paramnumber,
                    UI_min = UI_min,
                    UI_max = UI_max,
                    baseline=baseline,
                  }
                DATA.parent_track.macro.sliders[macroID].has_links = true 
              end 
            end
          end
        end
      end
    end 
    return has_links
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Children()   
    if DATA.parent_track.valid ~= true then return end 
    for i = DATA.parent_track.IP_TRACKNUMBER_0based+1, DATA.parent_track.IP_TRACKNUMBER_0basedlast do -- loop through track inside selected folder
    
      -- validate parent
        local track = GetTrack(DATA.proj, i) 
        if DATA:CollectData_IsChildOwnedByParent(track) ~= true  then goto nexttrack end
        
      -- handle midi
        local retMIDI = DATA:CollectData_Children_MIDIbus(track) 
        if retMIDI == true then goto nexttrack end         
 
        
      -- get base child data
        local retval, trGUID =             GetSetMediaTrackInfo_String( track, 'GUID', '', false ) 
        local retval, P_NAME =             GetSetMediaTrackInfo_String( track, 'P_NAME', '', false ) 
        local IP_TRACKNUMBER_0based =             GetMediaTrackInfo_Value( track, 'IP_TRACKNUMBER')
        local D_VOL =                      GetMediaTrackInfo_Value( track, 'D_VOL' )
        local D_VOL_format =               ( math.floor(WDL_VAL2DB(D_VOL)*10)/10) ..'dB'
        local D_PAN =                      GetMediaTrackInfo_Value( track, 'D_PAN' )
        local D_PAN_format =               VF_Format_Pan(D_PAN)
        local B_MUTE =                     GetMediaTrackInfo_Value( track, 'B_MUTE' )
        local I_SOLO =                     GetMediaTrackInfo_Value( track, 'I_SOLO' )
        local I_CUSTOMCOLOR =              GetMediaTrackInfo_Value( track, 'I_CUSTOMCOLOR' )
        local I_FOLDERDEPTH =              GetMediaTrackInfo_Value( track, 'I_FOLDERDEPTH' ) 

  
        
      -- validate attached note
        local ret, note =                   GetSetMediaTrackInfo_String         ( track, 'P_EXT:MPLRS5KMAN_NOTE',0, false) 
        note = tonumber(note) 
        if not note then goto nexttrack end 
        
      -- init note/layer
        if not DATA.children[note] then DATA.children[note] = {
          layers = {}, 
          P_NAME = P_NAME,
          I_CUSTOMCOLOR = I_CUSTOMCOLOR,
          B_MUTE = B_MUTE,
          I_SOLO = I_SOLO,
          tr_ptr = track,
          noteID=note,
          IP_TRACKNUMBER_0based=IP_TRACKNUMBER_0based,
        } end 
        
                
      -- define type (regular_child / device / device_child)
        local ret, TYPE_REGCHILD =          GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', 0, false) TYPE_REGCHILD = (tonumber(TYPE_REGCHILD) or 0)==1
        local ret, TYPE_DEVICECHILD =       GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', 0, false) TYPE_DEVICECHILD = (tonumber(TYPE_DEVICECHILD) or 0)==1
        local ret, TYPE_DEVICE =            GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE', 0, false) TYPE_DEVICE =  (tonumber(TYPE_DEVICE) or 0)==1 
        local ret, TYPE_DEVICECHILD_PARENTDEVICEGUID = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD_PARENTDEVICEGUID', 0, false)
        local TYPE_DEVICECHILD_valid 

      -- various
        local ret, MPLRS5KMAN_TSADD = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TSADD', 0, false) MPLRS5KMAN_TSADD = tonumber(MPLRS5KMAN_TSADD) or 0
                  
                  
      -- refresh / patch on missing or non-valid devices
        if TYPE_DEVICE ~= true then 
        
          TYPE_DEVICECHILD_valid = false 
          if TYPE_DEVICECHILD_PARENTDEVICEGUID then 
            local devicetr = VF_GetTrackByGUID(TYPE_DEVICECHILD_PARENTDEVICEGUID, DATA.proj)
            if devicetr then
              TYPE_DEVICECHILD_valid = true
              --[[local ret, note_device =        GetSetMediaTrackInfo_String   ( devicetr, 'P_EXT:MPLRS5KMAN_NOTE',0, false) note_device = tonumber(note_device)
              if note_device then 
                note = note_device 
                GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_NOTE',note, true) -- refresh device child note , make sure track is not inside different device
              end]]
             else
              TYPE_REGCHILD = true -- patch for case if TYPE_DEVICECHILD_PARENTDEVICEGUID is found but parent device is not valid
            end
           else
            TYPE_REGCHILD = true -- patch for case if TYPE_DEVICECHILD_PARENTDEVICEGUID not found but TYPE_REGCHILD not set 
          end 
          
        end
        
      -- add layer to note if device child
        if TYPE_DEVICECHILD == true or TYPE_REGCHILD == true then  
            local layer = #DATA.children[note].layers +1 
            DATA.children[note].layers[layer] = { 
                                              
                                              noteID = note,
                                              layerID = layer,
                                              
                                              tr_ptr = track,
                                              TR_GUID =  trGUID,
                                              
                                              TYPE_REGCHILD=TYPE_REGCHILD, 
                                              TYPE_DEVICECHILD=TYPE_DEVICECHILD,
                                              TYPE_DEVICECHILD_PARENTDEVICEGUID=TYPE_DEVICECHILD_PARENTDEVICEGUID,
                                              TYPE_DEVICECHILD_valid = TYPE_DEVICECHILD_valid,
                                              MPLRS5KMAN_TSADD=MPLRS5KMAN_TSADD,
                                              
                                              D_VOL = D_VOL,
                                              D_VOL_format = D_VOL_format,
                                              D_PAN = D_PAN,
                                              D_PAN_format = D_PAN_format,
                                              B_MUTE = B_MUTE,
                                              I_SOLO = I_SOLO,
                                              I_CUSTOMCOLOR = I_CUSTOMCOLOR,
                                              I_FOLDERDEPTH = I_FOLDERDEPTH,
                                              P_NAME=P_NAME,
                                              IP_TRACKNUMBER_0based=IP_TRACKNUMBER_0based,
                                              }
          DATA:CollectData_Children_ExtState          (DATA.children[note].layers[layer])  
          DATA:CollectData_Children_InstrumentParams  (DATA.children[note].layers[layer]) 
          DATA:CollectData_Children_FXParams          (DATA.children[note].layers[layer]) 
        end
        
      -- add device data
        if TYPE_DEVICE then 
          DATA.children[note].TYPE_DEVICE = TYPE_DEVICE 
          DATA.children[note].tr_ptr = track
          DATA.children[note].TR_GUID = trGUID
          DATA.children[note].MACRO_GUID = MACRO_GUID
          DATA.children[note].noteID = note
          DATA.children[note].MACRO_pos =MACRO_pos
          
          DATA.children[note].D_VOL = D_VOL
          DATA.children[note].D_VOL_format = D_VOL_format
          DATA.children[note].D_PAN = D_PAN
          DATA.children[note].D_PAN_format = D_PAN_format
          DATA.children[note].B_MUTE = B_MUTE
          DATA.children[note].I_SOLO = I_SOLO
          DATA.children[note].I_CUSTOMCOLOR = I_CUSTOMCOLOR
          DATA.children[note].I_FOLDERDEPTH = I_FOLDERDEPTH
          DATA.children[note].P_NAME = P_NAME
        end
      
      
      ::nexttrack::
    end
    
    -- make sure layer exist otherwise set to 1
    if DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER and DATA.children[DATA.parent_track.ext.PARENT_LASTACTIVENOTE] and 
      not ( DATA.children[DATA.parent_track.ext.PARENT_LASTACTIVENOTE].layers and DATA.children[DATA.parent_track.ext.PARENT_LASTACTIVENOTE].layers[DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER] ) 
     then 
      DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER = 1 
    end
    
  end
  ---------------------------------------------------------------------   
  function DATA:CollectData_Children_InstrumentParams_RS5k(note_layer_t, track,instrument_pos)
    if not note_layer_t.ISRS5K then return end
    
    note_layer_t.instrument_enabled = TrackFX_GetEnabled( track, instrument_pos )
    note_layer_t.instrument_volID = 0
    note_layer_t.instrument_vol = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_volID ) 
    note_layer_t.instrument_vol_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_volID )})[2]..'dB'
    note_layer_t.instrument_panID = 1
    note_layer_t.instrument_pan = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_panID ) 
    note_layer_t.instrument_pan_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_panID )})[2]
    note_layer_t.instrument_attackID = 9
    note_layer_t.instrument_attack = TrackFX_GetParamNormalized( track, instrument_pos,note_layer_t.instrument_attackID ) 
    note_layer_t.instrument_attack_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_attackID )})[2]..'ms'
    note_layer_t.instrument_decayID = 24
    note_layer_t.instrument_decay = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_decayID ) 
    note_layer_t.instrument_decay_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_decayID )})[2]..'ms'
    note_layer_t.instrument_sustainID = 25
    note_layer_t.instrument_sustain = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_sustainID ) 
    note_layer_t.instrument_sustain_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_sustainID )})[2]..'dB'
    note_layer_t.instrument_releaseID = 10
    note_layer_t.instrument_release = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_releaseID ) 
    note_layer_t.instrument_release_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_releaseID )})[2]..'ms'
    note_layer_t.instrument_loopID = 12
    note_layer_t.instrument_loop = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_loopID )
    note_layer_t.instrument_samplestoffsID = 13
    note_layer_t.instrument_samplestoffs = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_samplestoffsID ) 
    note_layer_t.instrument_samplestoffs_format = (math.floor(note_layer_t.instrument_samplestoffs*1000)/10)..'%'
    note_layer_t.instrument_sampleendoffsID = 14
    note_layer_t.instrument_sampleendoffs = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_sampleendoffsID ) 
    note_layer_t.instrument_sampleendoffs_format = (math.floor(note_layer_t.instrument_sampleendoffs*1000)/10)..'%'
    note_layer_t.instrument_loopoffsID = 23
    note_layer_t.instrument_loopoffs = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_loopoffsID ) 
    note_layer_t.instrument_loopoffs_format = math.floor(note_layer_t.instrument_loopoffs *30*10000)/10
    
    note_layer_t.instrument_loopoffs_max = 1
    note_layer_t.instrument_attack_max = 1 
    note_layer_t.instrument_decay_max = 1 
    note_layer_t.instrument_release_max = 1 
    if note_layer_t.SAMPLELEN and note_layer_t.SAMPLELEN ~= 0 then 
      local st_s = note_layer_t.instrument_samplestoffs * note_layer_t.SAMPLELEN
      local end_s = note_layer_t.instrument_sampleendoffs * note_layer_t.SAMPLELEN
      note_layer_t.instrument_loopoffs_max = (end_s - st_s) / 30 
      note_layer_t.instrument_loopoffs_norm =  VF_lim(note_layer_t.instrument_loopoffs / note_layer_t.instrument_loopoffs_max )
      note_layer_t.instrument_attack_max = math.min(1,note_layer_t.SAMPLELEN/2) 
      note_layer_t.instrument_attack_norm = VF_lim(note_layer_t.instrument_attack / note_layer_t.instrument_attack_max   ) 
      note_layer_t.instrument_decay_max = math.min(1,note_layer_t.SAMPLELEN/15) 
      note_layer_t.instrument_decay_norm =  VF_lim(note_layer_t.instrument_decay / note_layer_t.instrument_decay_max  ) 
      note_layer_t.instrument_release_max = math.min(1,note_layer_t.SAMPLELEN/2) 
      note_layer_t.instrument_release_norm =  VF_lim(note_layer_t.instrument_release / note_layer_t.instrument_release_max )        
    end
    
    note_layer_t.instrument_maxvoicesID = 8
    note_layer_t.instrument_maxvoices = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_maxvoicesID ) 
    note_layer_t.instrument_maxvoices_format = math.floor(note_layer_t.instrument_maxvoices*64)
    note_layer_t.instrument_tuneID = 15
    note_layer_t.instrument_tune = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_tuneID ) 
    note_layer_t.instrument_tune_format = ({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_tuneID )})[2]..'st'
    note_layer_t.instrument_filename = ({TrackFX_GetNamedConfigParm(  track, instrument_pos, 'FILE0') })[2]
    note_layer_t.instrument_noteoffID = 11
    note_layer_t.instrument_noteoff = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_noteoffID ) 
    note_layer_t.instrument_noteoff_format = math.floor(note_layer_t.instrument_noteoff) 
    local filename_short = VF_GetShortSmplName(note_layer_t.instrument_filename) if filename_short and filename_short:match('(.*)%.[%a]+') then filename_short = filename_short:match('(.*)%.[%a]+') end 
    note_layer_t.instrument_filename_short = filename_short 
  end
  ---------------------------------------------------------------------   
  function DATA:CollectData_Children_InstrumentParams_3rdparty(note_layer_t, track,instrument_pos)
    if note_layer_t.ISRS5K==true then return end
    
    note_layer_t.instrument_enabled = TrackFX_GetEnabled( track, instrument_pos )
    local retval, fx_name = TrackFX_GetNamedConfigParm( track, instrument_pos, 'fx_name' )
    note_layer_t.instrument_fx_name = fx_name
    
    if not (DATA.plugin_mapping and DATA.plugin_mapping[fx_name] )then return end
    
    local supported_params = {
        'instrument_volID',
        'instrument_attackID',
        'instrument_decayID',
        'instrument_sustainID',
        'instrument_releaseID',
      }
    
    for pid=1, #supported_params do
      local param = supported_params[pid]
      local paramclear = param:match('(.*)ID')
      if DATA.plugin_mapping[fx_name][param] and paramclear then 
        note_layer_t[param] = DATA.plugin_mapping[fx_name][param]
        note_layer_t[paramclear] = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t[param] ) 
        note_layer_t[paramclear..'_format']=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t[param] )})[2]
      end
    end
  end
  ---------------------------------------------------------------------   
  function DATA:CollectData_Children_InstrumentParams(note_layer_t, is_minor)
    local track = note_layer_t.tr_ptr
    local instrument_pos
    
    -- validate tr
    if is_minor ~= true then 
      local ret, tr, instrument_pos0 = VF_GetFXByGUID(note_layer_t.INSTR_FXGUID, track, DATA.proj)
      if not ret then return end 
      note_layer_t.instrument_pos=instrument_pos0
      instrument_pos=instrument_pos0
     else
      instrument_pos = note_layer_t.instrument_pos
    end 
    
    DATA:CollectData_Children_InstrumentParams_RS5k(note_layer_t, track, instrument_pos)
    DATA:CollectData_Children_InstrumentParams_3rdparty(note_layer_t, track, instrument_pos)
    
  end 
  ---------------------------------------------------------------------  
  function DATA:CollectData_Children_FXParams(note_layer_t)  
    if not note_layer_t then return end
    -- ReaEQ
    note_layer_t.fx_reaeq_isvalid = false
    if note_layer_t.FX_REAEQ_GUID then  
      local ret,tr, reaeqpos = VF_GetFXByGUID(note_layer_t.FX_REAEQ_GUID, note_layer_t.tr_ptr)
      if ret and reaeqpos and reaeqpos ~= -1 then    
        local track = note_layer_t.tr_ptr
        note_layer_t.fx_reaeq_isvalid = true
        note_layer_t.fx_reaeq_pos = reaeqpos
        note_layer_t.fx_reaeq_cut = TrackFX_GetParamNormalized( track, reaeqpos, 0 )
        note_layer_t.fx_reaeq_gain = TrackFX_GetParamNormalized( track, reaeqpos, 1)
        note_layer_t.fx_reaeq_bw = TrackFX_GetParamNormalized( track, reaeqpos, 2 )
        local fr= math.floor(({TrackFX_GetFormattedParamValue( track, reaeqpos, 0 )})[2])
        if fr>10000 then fr = (math.floor(fr/100)/10)..'k' end
        note_layer_t.fx_reaeq_cut_format = fr..'Hz'
        
        note_layer_t.fx_reaeq_gain_format = ({TrackFX_GetFormattedParamValue( track, reaeqpos, 1 )})[2]..'dB'
        note_layer_t.fx_reaeq_bw_format = ({TrackFX_GetFormattedParamValue( track, reaeqpos, 2 )})[2]
        note_layer_t.fx_reaeq_bandenabled = ({TrackFX_GetNamedConfigParm( track, reaeqpos, 'BANDENABLED0' )})[2]=='1'
        note_layer_t.fx_reaeq_bandtype = tonumber(({TrackFX_GetNamedConfigParm( track, reaeqpos, 'BANDTYPE0' )})[2])
        local reaeq_bandtype_format = ''
        if DATA.bandtypemap and DATA.bandtypemap[note_layer_t.fx_reaeq_bandtype] then reaeq_bandtype_format = DATA.bandtypemap[note_layer_t.fx_reaeq_bandtype] end
        note_layer_t.fx_reaeq_bandtype_format = reaeq_bandtype_format  
      end
    end
    
    -- WS
    note_layer_t.fx_ws_isvalid = false
    if note_layer_t.FX_WS_GUID then
      local ret,tr, wspos = VF_GetFXByGUID(note_layer_t.FX_WS_GUID, note_layer_t.tr_ptr)
      if ret and wspos and wspos ~= -1 then 
        local track = note_layer_t.tr_ptr
        note_layer_t.fx_ws_isvalid = true
        note_layer_t.fx_ws_pos = wspos
        note_layer_t.fx_ws_drive = TrackFX_GetParamNormalized( track, wspos, 0 )
        note_layer_t.fx_ws_drive_format = (math.floor(1000*note_layer_t.fx_ws_drive)/10)..'%'
      end
    end
  end 
  --------------------------------------------------------------------- 
  function DATA:CollectData_Children_ExtState(t) 
      local track = t.tr_ptr
    -- main plug data
      local ret, INSTR_FXGUID = GetSetMediaTrackInfo_String  ( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_FXGUID', 0, false)   if INSTR_FXGUID == '' then INSTR_FXGUID = nil end 
      local ret, ISRS5K = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_CHILD_ISRS5K', 0, false) ISRS5K = (tonumber(ISRS5K) or 0)==1  
      t.INSTR_FXGUID=     INSTR_FXGUID
      t.ISRS5K=           ISRS5K
    
    -- rs5k specific 
      local ret, SAMPLELEN = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_SAMPLELEN', '', false)  SAMPLELEN = tonumber(SAMPLELEN) or 0 
      t.SAMPLELEN = SAMPLELEN
      local ret, PEAKS = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_PEAKS', '', false)
      if ret then 
        t.peaks_t = {} 
        local i = 1 
        for val in PEAKS:gmatch('[^%|]+') do 
          if tonumber(val) then t.peaks_t[i] = tonumber(val) i = i + 1 end
        end
        t.peaks_arr = new_array(t.peaks_t)
      end
      
    --[[  3rd party ADSR + tune map
      local ret, INSTR_PARAM_CACHE = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_CACHE', '', false) INSTR_PARAM_CACHE = tonumber(INSTR_PARAM_CACHE) or nil
      local ret, INSTR_PARAM_VOL = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_VOL', '', false) INSTR_PARAM_VOL = tonumber(INSTR_PARAM_VOL) or nil
      local ret, INSTR_PARAM_TUNE = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_TUNE', '', false) INSTR_PARAM_TUNE = tonumber(INSTR_PARAM_TUNE) or nil
      local ret, INSTR_PARAM_ATT = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_ATT', '', false) INSTR_PARAM_ATT = tonumber(INSTR_PARAM_ATT) or nil
      local ret, INSTR_PARAM_DEC = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_DEC', '', false) INSTR_PARAM_DEC = tonumber(INSTR_PARAM_DEC) or nil
      local ret, INSTR_PARAM_SUS = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_SUS', '', false) INSTR_PARAM_SUS = tonumber(INSTR_PARAM_SUS) or nil
      local ret, INSTR_PARAM_REL = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_REL', '', false) INSTR_PARAM_REL = tonumber(INSTR_PARAM_REL) or nil 
      t.INSTR_PARAM_CACHE=INSTR_PARAM_CACHE
      t.INSTR_PARAM_VOL=INSTR_PARAM_VOL
      t.INSTR_PARAM_TUNE=INSTR_PARAM_TUNE
      t.INSTR_PARAM_ATT=INSTR_PARAM_ATT
      t.INSTR_PARAM_DEC=INSTR_PARAM_DEC
      t.INSTR_PARAM_SUS=INSTR_PARAM_SUS
      t.INSTR_PARAM_REL=INSTR_PARAM_REL]]
      
    -- midi filter
      local ret, MIDIFILTGUID = GetSetMediaTrackInfo_String  ( track, 'P_EXT:MPLRS5KMAN_CHILD_MIDIFILTGUID', 0, false)  if MIDIFILTGUID == '' then MIDIFILTGUID = nil end
      t.MIDIFILTGUID=MIDIFILTGUID
    
    -- reaeq// validate
      local ret, FX_REAEQ_GUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_FX_REAEQ_GUID', '', false) if FX_REAEQ_GUID == '' then FX_REAEQ_GUID = nil end 
      if FX_REAEQ_GUID then 
        local ret, tr, eqpos = VF_GetFXByGUID(FX_REAEQ_GUID:gsub('[%{%}]',''),track, DATA.proj) 
        if not eqpos then FX_REAEQ_GUID=nil end
      end
      t.FX_REAEQ_GUID = FX_REAEQ_GUID
    
    -- waveshaper // validate
      local ret, FX_WS_GUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_FX_WS_GUID', '', false) if FX_WS_GUID == '' then FX_WS_GUID = nil end 
      if FX_WS_GUID then 
        local ret, tr, wspos = VF_GetFXByGUID(FX_WS_GUID:gsub('[%{%}]',''),track, DATA.proj) 
        if not wspos then FX_WS_GUID=nil end
      end
      t.FX_WS_GUID=FX_WS_GUID
    
    -- macro
      local _, MACRO_GUID = GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_MACRO_GUID', 0, false) if MACRO_GUID == '' then MACRO_GUID = nil end 
      local  ret, tr, MACRO_pos
      if MACRO_GUID then ret, tr, MACRO_pos = VF_GetFXByGUID(MACRO_GUID:gsub('[%{%}]',''),track, DATA.proj) end
      if not MACRO_pos then MACRO_GUID = nil  end 
      t.MACRO_GUID = MACRO_GUID 
      t.MACRO_pos = MACRO_pos
    
    -- list samples in path or database
      local ret, SPLLISTDB = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB', '', false) SPLLISTDB = tonumber(SPLLISTDB) or 0
      t.SET_useDB=SPLLISTDB
      local ret, SET_useDB_lastID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB_ID', '', false) SET_useDB_lastID = tonumber(SET_useDB_lastID) or 0
      t.SET_useDB_lastID = SET_useDB_lastID
      local ret, SPLLISTDB_name = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB_NAME', '', false) if SPLLISTDB_name == '' then SPLLISTDB_name = nil end 
      t.SET_useDB_name=SPLLISTDB_name
      
      
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Children_MIDIbus(track)
    local ret, isMIDIbus = GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_MIDIBUS', 0, false)    
    isMIDIbus = (tonumber(isMIDIbus) or 0)==1   
    if not (ret and isMIDIbus == true) then return end
    local IP_TRACKNUMBER_0based = GetMediaTrackInfo_Value( track, 'IP_TRACKNUMBER')-1
    local I_FOLDERDEPTH = GetMediaTrackInfo_Value( track, 'I_FOLDERDEPTH')
    
    DATA.MIDIbus = {  tr_ptr = track, 
                      IP_TRACKNUMBER_0based = IP_TRACKNUMBER_0based,
                      valid = true,
                      I_FOLDERDEPTH = I_FOLDERDEPTH
                  } 
    return true
  end
  -----------------------------------------------------------------------------  
  function DATA:Sampler_StuffNoteOn(note, vel, is_off) 
   if not note then return end
    if not is_off then 
      StuffMIDIMessage( 0, 0x90, note, vel or EXT.CONF_default_velocity ) 
     else
      StuffMIDIMessage( 0, 0x80, note, 0 ) 
    end
  end
  ----------------------------------------------------------------------
  function DATA:Sampler_CropToAudibleBoundaries() 
    local note_layer_t, note, layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if not (DATA.current_sample_peaks and DATA.current_sample_peaks.peaks)then return end
    
    -- threshold
    local threshold_lin = WDL_DB2VAL(EXT.CONF_cropthreshold)
    local cnt_peaks = #DATA.current_sample_peaks.peaks
    local loopst = 0
    local loopend = 1
    for i = 1, cnt_peaks do if math.abs(DATA.current_sample_peaks.peaks[i]) > threshold_lin then loopst = i/cnt_peaks break end end
    for i = cnt_peaks, 1, -1 do if math.abs(DATA.current_sample_peaks.peaks[i]) > threshold_lin then loopend = i/cnt_peaks break end end 
  
    TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 13, loopst ) 
    TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 14, loopend ) 
    DATA.upd = true
  end
  ----------------------------------------------------------------------
  function DATA:Sampler_SetStartToLoudestPeak() 
    local note_layer_t, note, layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if not (DATA.current_sample_peaks and DATA.current_sample_peaks.peaks)then return end
    
    local cnt_peaks = #DATA.current_sample_peaks.peaks
    for i = 1, cnt_peaks do if math.abs(DATA.current_sample_peaks.peaks[i]) ==1 then loopst = i/cnt_peaks break end end
    local note_layer_t = DATA.children[note].layers[layer]
    TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 13, loopst ) 
    DATA.upd = true
  end 
  ---------------------------------------------------------------------  
  function DATA:WriteData_Parent() 
    if not (DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.valid == true) then return end
    GetSetMediaTrackInfo_String( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.version, true)
      
    -- v4 separate stuff from chunk
    if DATA.parent_track.ext then 
      if DATA.parent_track.ext.PARENT_DRRACKSHIFT  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_DRRACKSHIFT', DATA.parent_track.ext.PARENT_DRRACKSHIFT or '', true) end
      if DATA.parent_track.ext.PARENT_LASTACTIVENOTE  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_LASTACTIVENOTE', DATA.parent_track.ext.PARENT_LASTACTIVENOTE or '', true) end
      if DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_LASTACTIVENOTE_LAYER', DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER or '', true) end
      if DATA.parent_track.ext.PARENT_MACROCNT  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_MACROCNT', DATA.parent_track.ext.PARENT_MACROCNT or '', true) end
      if DATA.parent_track.ext.PARENT_LASTACTIVEMACRO  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_LASTACTIVEMACRO', DATA.parent_track.ext.PARENT_LASTACTIVEMACRO or '', true) end
      if DATA.parent_track.ext.PARENT_MIDIFLAGS  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_MIDIFLAGS', DATA.parent_track.ext.PARENT_MIDIFLAGS or '', true) end
      if DATA.parent_track.ext.PARENT_MACRO_GUID  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_MACRO_GUID', DATA.parent_track.ext.PARENT_MACRO_GUID or '', true) end
      if DATA.parent_track.ext.PARENT_MACROEXT    then
        local outstr = table.savestring(DATA.parent_track.ext.PARENT_MACROEXT)
        GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_MACROEXT_B64', VF_encBase64(outstr), true)
      end
      
    end
    
    -- clear string
    GetSetMediaTrackInfo_String( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN', '', true) 
  end
  --------------------------------------------------------------------- 
  function DATA:WriteData_UpdateChoke() 
    if not (DATA.MIDIbus.CHOKE_valid and DATA.MIDIbus.CHOKE_flags ) then return end 
    local tr = DATA.MIDIbus.tr_ptr 
    local fx = DATA.MIDIbus.CHOKE_pos
    -- write group flags
    Undo_BeginBlock2(DATA.proj )
    for slider = 0, 63 do
      local noteID1 = slider*2
      local noteID2 = slider*2+1
      local flags1 = DATA.MIDIbus.CHOKE_flags[noteID1]
      local flags2 = DATA.MIDIbus.CHOKE_flags[noteID2]
      local out_mixed = (flags2<<8) + flags1
      TrackFX_SetParamNormalized( tr, fx, slider, out_mixed/65535 )
    end 
    Undo_EndBlock2( DATA.proj , 'RS5k manager - update choke', 0xFFFFFFFF ) 
  end
  ---------------------------------------------------------------------
  function DATA:WriteData_Child(tr, t) 
    if not ValidatePtr2(DATA.proj,tr,'MediaTrack*') then return end
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.version, true)
    
    -- meta FX
      if t.MACRO_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_MACRO_GUID', t.MACRO_GUID, true) end
      if t.CHOKE_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHOKE_GUID', t.CHOKE_GUID, true) end
      if t.MIDIFILT_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_MIDIFILTGUID', t.MIDIFILT_GUID, true) end 
      if t.FX_REAEQ_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FX_REAEQ_GUID', t.FX_REAEQ_GUID, true) end      
      if t.FX_WS_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FX_WS_GUID', t.FX_WS_GUID, true) end      
      
    -- types
      if t.SET_MarkParentForChild then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', t.SET_MarkParentForChild, true) end 
      if t.SET_MarkType_RegularChild then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', 1, true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', '', true) 
       elseif t.SET_MarkType_Device then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE', 1, true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', '', true)
       elseif t.SET_MarkType_MIDIbus then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_MIDIBUS', 1, true)
       elseif t.SET_MarkType_DeviceChild_deviceGUID then 
        --GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', 1, true) 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', '', true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD_PARENTDEVICEGUID', t.SET_MarkType_DeviceChild_deviceGUID, true) 
      end 
      
    -- rs5k manager data
      if t.SET_noteID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_NOTE', t.SET_noteID, true) end 
      if t.SET_instrFXGUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_FXGUID', t.SET_instrFXGUID, true) end 
      if t.SET_isrs5k then  GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_ISRS5K', 1, true) end      
      if t.SET_useDB then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB', t.SET_useDB, true) end  
      if t.SET_useDB_name then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB_NAME', t.SET_useDB_name, true) end  
      if t.SET_useDB_lastID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB_ID', t.SET_useDB_lastID, true) end  
      if t.SET_SAMPLELEN then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_SAMPLELEN', t.SET_SAMPLELEN, true) end  
      if t.SET_PEAKS then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_PEAKS', t.SET_PEAKS, true) end  
      
      --[[if t.INSTR_PARAM_CACHE then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_CACHE', t.INSTR_PARAM_CACHE, true) end
      if t.INSTR_PARAM_VOL then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_VOL', t.INSTR_PARAM_VOL, true) end
      if t.INSTR_PARAM_TUNE then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_TUNE', t.INSTR_PARAM_TUNE, true) end
      if t.INSTR_PARAM_ATT then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_ATT', t.INSTR_PARAM_ATT, true) end
      if t.INSTR_PARAM_DEC then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_DEC', t.INSTR_PARAM_DEC, true) end
      if t.INSTR_PARAM_SUS then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_SUS', t.INSTR_PARAM_SUS, true) end
      if t.INSTR_PARAM_REL then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_REL', t.INSTR_PARAM_REL, true) end]]
      
    
  end
  
  ---------------------------------------------------------------------  
  function DATA:Drop_Pad(src_pad0,dest_pad0)
    if not src_pad0 and dest_pad0 then return end
    src_pad,dest_pad = tonumber(src_pad0),tonumber(dest_pad0)
    if not src_pad and dest_pad then return end
    
    -- set dest device/devicechidren
    if DATA.children[dest_pad] then   
      DATA:WriteData_Child(DATA.children[dest_pad].tr_ptr, {SET_noteID = src_pad})  
      if DATA.children[dest_pad].layers then
        for layer = 1, #DATA.children[dest_pad].layers do
          DATA:WriteData_Child(DATA.children[dest_pad].layers[layer].tr_ptr, {SET_noteID = src_pad})  
          DATA:DropSample_ExportToRS5kSetNoteRange(DATA.children[dest_pad].layers[layer].tr_ptr, DATA.children[dest_pad].layers[layer].instrument_pos, src_pad)
        end
      end
    end

    -- set dest device/devicechidren
    if DATA.children[src_pad] then   
      DATA:WriteData_Child(DATA.children[src_pad].tr_ptr, {SET_noteID = dest_pad})  
      if DATA.children[src_pad].layers then
        for layer = 1, #DATA.children[src_pad].layers do
          DATA:WriteData_Child(DATA.children[src_pad].layers[layer].tr_ptr, {SET_noteID = dest_pad})  
          DATA:DropSample_ExportToRS5kSetNoteRange(DATA.children[src_pad].layers[layer].tr_ptr, DATA.children[src_pad].layers[layer].instrument_pos, dest_pad)
        end
      end
    end
    
    DATA.upd = true
    DATA.autoreposition = true
  end
  ---------------------------------------------------------------------  
  function DATA:Validate_MIDIbus_AND_ParentFolder() -- set parent as folder if need, since it is a first validation check in DATA:DropSample
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end
    if (DATA.MIDIbus and DATA.MIDIbus.valid == true) then return end
    
    -- make sure parent extstate is set
    if not ( DATA.parent_track and DATA.parent_track.ext_load == true) then 
      DATA:WriteData_Parent() 
    end
    
    -- insert new
    InsertTrackAtIndex( DATA.parent_track.IP_TRACKNUMBER_0based+1, false )
    local MIDI_tr = GetTrack(DATA.proj, DATA.parent_track.IP_TRACKNUMBER_0based+1)
    
    -- set params
    GetSetMediaTrackInfo_String( MIDI_tr, 'P_NAME', 'MIDI bus', 1 )
    SetMediaTrackInfo_Value( MIDI_tr, 'I_RECMON', 1 )
    SetMediaTrackInfo_Value( MIDI_tr, 'I_RECARM', 1 )
    SetMediaTrackInfo_Value( MIDI_tr, 'I_RECMODE', 0 ) -- record MIDI out
    local channel,physical_input = EXT.CONF_midichannel, EXT.CONF_midiinput
    SetMediaTrackInfo_Value( MIDI_tr, 'I_RECINPUT', 4096 + channel + (physical_input<<5)) -- set input to all MIDI
    
    -- make parent track folder
    if DATA.parent_track.I_FOLDERDEPTH ~= 1 then
      SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERDEPTH',1 )
      SetMediaTrackInfo_Value( MIDI_tr,               'I_FOLDERDEPTH',DATA.parent_track.I_FOLDERDEPTH-1 ) 
    end 
    
    DATA:WriteData_Child(MIDI_tr, {
      SET_MarkParentForChild = DATA.parent_track.trGUID,
      SET_MarkType_MIDIbus = true,
      })  
      
    -- refresh last track in tree if parent track was at initial state
    if DATA.parent_track.IP_TRACKNUMBER_0basedlast == DATA.parent_track.IP_TRACKNUMBER_0based then
      DATA.parent_track.IP_TRACKNUMBER_0basedlast = DATA.parent_track.IP_TRACKNUMBER_0based +1
    end
    
    DATA:CollectData_Children_MIDIbus(MIDI_tr)
    DATA.upd = true
  end
  -----------------------------------------------------------------------  
  function DATA:DropSample_ExportToRS5k_CopySrc(filename)
    local prpath = reaper.GetProjectPathEx( 0 )
    local filename_path = GetParentFolder(filename)
    local filename_name = VF_VF_GetShortSmplName(filename)
    if prpath and filename_path and filename_name then
      prpath = prpath..'/RS5kmanager_samples/'
      RecursiveCreateDirectory( prpath, 0 )
      local src = filename
      local dest = prpath..filename_name
      local fsrc = io.open(src, 'rb')
      if fsrc then
        content = fsrc:read('a') 
        fsrc:close()
        fdest = io.open(dest, 'wb')
        if fdest then 
          fdest:write(content)
          fdest:close()
          return dest
        end
      end
    end
    return filename
  end
  --------------------------------------------------------------------- 
  function DATA:DropSample_ExportToRS5kSetNoteRange(tr, instrument_pos, note, midifilt_pos) 
    if not note then return end
    if not midifilt_pos  then 
      TrackFX_SetParamNormalized( tr, instrument_pos, 3, (note)/127 ) -- note range start
      TrackFX_SetParamNormalized( tr, instrument_pos, 4, (note)/127 ) -- note range end
     else 
      TrackFX_SetParamNormalized( tr, midifilt_pos, 0, note/128)
      TrackFX_SetParamNormalized( tr, midifilt_pos, 1, note/128)
    end
  end
  --------------------------------------------------------------------- 
  function DATA:DropSample_AddNewTrack(deviceparent, note, SET_MarkType_DeviceChild_deviceGUID) 
    -- define position
    local ID = DATA.parent_track.IP_TRACKNUMBER_0based+1 -- after parent
    
    -- add / handle tree
    InsertTrackAtIndex( ID, false )
    local new_tr = GetTrack(DATA.proj, ID)  
    
    -- add custom template
    if deviceparent ~= true and EXT.CONF_onadd_customtemplate ~= '' then 
      local f = io.open(EXT.CONF_onadd_customtemplate,'rb')
      local content
      if f then 
        content = f:read('a')
        f:close()
      end
      local GUID = GetTrackGUID( new_tr )
      content = content:gsub('TRACK ', 'TRACK '..GUID)
      SetTrackStateChunk( new_tr, content, false )
      TrackFX_Show( new_tr, 0, 0 ) -- hide chain
      for fxid = 1,  TrackFX_GetCount( new_tr ) do TrackFX_Show( new_tr,fxid-1, 2 ) end-- hide chain
    end  
    
    -- set height
    if EXT.CONF_onadd_newchild_trackheight > 0 then SetMediaTrackInfo_Value( new_tr, 'I_HEIGHTOVERRIDE', EXT.CONF_onadd_newchild_trackheight ) end 
    
    -- print timestamp
    GetSetMediaTrackInfo_String(  new_tr, 'P_EXT:MPLRS5KMAN_TSADD', os.time(), true) 
    
    -- move in structure
    DATA:DropSample_AddNewTrack_Move(new_tr, deviceparent, note, SET_MarkType_DeviceChild_deviceGUID)
    
    return new_tr
  end 
  --------------------------------------------------------------------- 
  function DATA:DropSample_AddNewTrack_Move(new_tr, deviceparent, note, SET_MarkType_DeviceChild_deviceGUID)
    local exact_note 
    local next_note 
    for note0 in spairs(DATA.children) do
      if note0 == note then exact_note = true end
      if note0 > note then next_note = note0 break end
    end    
    
    -- new regular child
      if deviceparent~=true and not SET_MarkType_DeviceChild_deviceGUID then
        local beforeTrackIdx
        if next_note then
          beforeTrackIdx = DATA.children[next_note].IP_TRACKNUMBER_0based
         else
          if (DATA.MIDIbus and DATA.MIDIbus.IP_TRACKNUMBER_0based) then
            beforeTrackIdx = DATA.MIDIbus.IP_TRACKNUMBER_0based+1 -- goes before midi bus
           else
            beforeTrackIdx = DATA.parent_track.IP_TRACKNUMBER_0based+1 -- goes after parent
          end
        end
        DATA:Auto_Reposition_TrackGetSelection()
        SetOnlyTrackSelected( new_tr )
        ReorderSelectedTracks( beforeTrackIdx, 0 )
        DATA:Auto_Reposition_TrackRestoreSelection()
      end
    
    -- new layer
      if deviceparent~=true and SET_MarkType_DeviceChild_deviceGUID and exact_note then
        local beforeTrackIdx = DATA.children[note].IP_TRACKNUMBER_0based +1 -- goes after parent 
        DATA:Auto_Reposition_TrackGetSelection()
        SetOnlyTrackSelected( new_tr )
        ReorderSelectedTracks( beforeTrackIdx, 0 )--make sure parent is folder
        DATA:Auto_Reposition_TrackRestoreSelection()
      end
   
    -- new device
      if deviceparent==true then
        if exact_note then -- child exist
          SetOnlyTrackSelected( new_tr )
          local beforeTrackIdx = DATA.children[note].IP_TRACKNUMBER_0based -- before child
          ReorderSelectedTracks( beforeTrackIdx, 0 )
          local child_tr = GetTrack(-1,DATA.children[note].IP_TRACKNUMBER_0based)
          SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH', 1 ) -- enclose new device
          local I_FOLDERDEPTH = GetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH') -- enclose new device
          SetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH', I_FOLDERDEPTH-1 ) -- enclose new device
          return
        end
        
        local beforeTrackIdx
        if (DATA.MIDIbus and DATA.MIDIbus.IP_TRACKNUMBER_0based) then
          beforeTrackIdx = DATA.MIDIbus.IP_TRACKNUMBER_0based -- before midi bus
         else
          beforeTrackIdx = DATA.parent_track.IP_TRACKNUMBER_0based+1 -- after parent
        end
        if next_note then beforeTrackIdx = DATA.children[next_note].IP_TRACKNUMBER_0based end -- before next note if any
        DATA:Auto_Reposition_TrackGetSelection()
        SetOnlyTrackSelected( new_tr )
        ReorderSelectedTracks( beforeTrackIdx, 0 )
        DATA:Auto_Reposition_TrackRestoreSelection()
      end
      
  end
  ---------------------------------------------------------------------  
  function DATA:DropSample_ValidateTrack(note, layer)
    local track 
    
    -- track exists
    if  
      layer and 
      DATA.children[note] and 
      DATA.children[note].layers and 
      DATA.children[note].layers[layer] and 
      DATA.children[note].layers[layer].tr_ptr and 
      ValidatePtr2(DATA.proj, DATA.children[note].layers[layer].tr_ptr, 'MediaTrack*') then 
     return DATA.children[note].layers[layer].tr_ptr 
    end 
    
    
    -- add 
      local SET_MarkType_DeviceChild_deviceGUID
      if DATA.children[note] and DATA.children[note].TYPE_DEVICE == true then
        local deviceGUID = DATA.children[note].TR_GUID
        SET_MarkType_DeviceChild_deviceGUID = deviceGUID
       else
        -- add device parent 
        if layer ~= 1 then
          local device_parent = DATA:DropSample_AddNewTrack(true, note) 
          local retval, deviceGUID = GetSetMediaTrackInfo_String( device_parent, 'GUID', '', false  )
          SET_MarkType_DeviceChild_deviceGUID = deviceGUID
          GetSetMediaTrackInfo_String( device_parent, 'P_NAME', 'Note '..note, 1 )
          DATA:WriteData_Child(device_parent, {
            SET_MarkParentForChild = DATA.parent_track.trGUID,
            SET_MarkType_Device = true,
            SET_noteID=note,
            SET_noteID=note,
            }) 
        end
      end
      
      
      local track = DATA:DropSample_AddNewTrack(false, note, SET_MarkType_DeviceChild_deviceGUID)
      DATA:WriteData_Child(track, {
        SET_MarkParentForChild = DATA.parent_track.trGUID,
        SET_MarkType_RegularChild = true,
        SET_MarkType_DeviceChild_deviceGUID=SET_MarkType_DeviceChild_deviceGUID,
        SET_noteID=note,
        }) 
      return track
      
      
    
  end
  -----------------------------------------------------------------------  
  function DATA:DropFX_Export(track, instrument_pos, note, fxname)  
    -- set parameters
      if EXT.CONF_onadd_float == 0 then TrackFX_SetOpen( track, instrument_pos, false ) end
    
    -- store external data
      local instrumentGUID = TrackFX_GetFXGUID( track, instrument_pos)
      DATA:WriteData_Child(track, {
        SET_instrFXGUID = instrumentGUID,
        SET_noteID=note,
        SET_isrs5k=false,
      }) 
    
    -- rename track
      if EXT.CONF_onadd_renametrack==1 then 
        GetSetMediaTrackInfo_String( track, 'P_NAME', fxname, true )
      end
      
  end
  ---------------------------------------------------------------------  
  function DATA:DropFX(fx_namesrc, fxname, fxidx, src_track, note, drop_data)
    if not (fx_namesrc and src_track and note) then return end
    local layer = 1
    if drop_data and drop_data.layer then layer = drop_data.layer end
    
    -- validate parenbt track
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    DATA:Validate_MIDIbus_AND_ParentFolder() -- make sure parent track is folder for tree consistency 
    DATA.upd = true
     
    -- validate track    
    local track = DATA:DropSample_ValidateTrack(note, layer)
    if not track then return end
    
    -- validate instr pos
    local instrument_pos 
    if DATA.children[note] and DATA.children[note].layers and DATA.children[note].layers[layer or 1] and DATA.children[note].layers[layer or 1].instrument_pos then instrument_pos = DATA.children[note].layers[layer or 1].instrument_pos end 
    if instrument_pos then TrackFX_Delete( track, instrument_pos ) end
    
    -- insert rs5k
    TrackFX_CopyToTrack( src_track, fxidx, track, 0, true )
    local instrument_pos = TrackFX_AddByName( track, fx_namesrc, false, 0)  
    if instrument_pos == -1 then return end
    DATA:DropFX_Export(track, instrument_pos, note, fxname) 
    
    DATA.autoreposition = true    
  end
  ---------------------------------------------------------------------  
  function DATA:DropSample(filename, note, drop_data)
    if not (filename and note) then return end
    local layer = 1
    if drop_data and drop_data.layer then layer = drop_data.layer end
    
    -- validate parenbt track
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    DATA:Validate_MIDIbus_AND_ParentFolder() -- make sure parent track is folder for tree consistency 
    DATA.upd = true
     
    -- validate track    
    local track = DATA:DropSample_ValidateTrack(note, layer)
    if not track then return end
    
    -- validate instr pos
    local instrument_pos 
    if DATA.children[note] and DATA.children[note].layers and DATA.children[note].layers[layer or 1] and DATA.children[note].layers[layer or 1].instrument_pos then instrument_pos = DATA.children[note].layers[layer or 1].instrument_pos end 
    
    -- insert rs5k
    if not instrument_pos then
      instrument_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, 1) 
      if instrument_pos == -1 then instrument_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1000 ) end
      if instrument_pos == -1 then return end
    end
      
    DATA:DropSample_ExportToRS5k(track, instrument_pos, filename, note, drop_data) 
    
    DATA.autoreposition = true
  end   
  -----------------------------------------------------------------------  
  function DATA:DropSample_ExportToRS5k(track, instrument_pos, filename, note, drop_data) 
      
    -- validate filename
      if not (track and  instrument_pos and filename and filename~='')  then return end 
      
    -- handle file
      if EXT.CONF_onadd_copytoprojectpath == 1 then filename = DATA:DropSample_ExportToRS5k_CopySrc(filename) end 
    -- set parameters
      if EXT.CONF_onadd_float == 0 then TrackFX_SetOpen( track, instrument_pos, false ) end
      TrackFX_SetNamedConfigParm( track, instrument_pos, 'FILE0', filename)
      TrackFX_SetNamedConfigParm( track, instrument_pos, 'DONE', '')      
      TrackFX_SetParamNormalized( track, instrument_pos, 2, 0) -- gain for min vel
      TrackFX_SetParamNormalized( track, instrument_pos, 5, 0.5 ) -- pitch for start
      TrackFX_SetParamNormalized( track, instrument_pos, 6, 0.5 ) -- pitch for end
      TrackFX_SetParamNormalized( track, instrument_pos, 8, 0 ) -- max voices = 0
      TrackFX_SetParamNormalized( track, instrument_pos, 9, 0 ) -- attack
      TrackFX_SetParamNormalized( track, instrument_pos, 11, EXT.CONF_onadd_obeynoteoff) -- obey note offs
      DATA:DropSample_ExportToRS5kSetNoteRange(track, instrument_pos, note)
    
    -- set offsets
      if drop_data and drop_data.SOFFS and drop_data.EOFFS then
        TrackFX_SetParamNormalized( track, instrument_pos, 13, drop_data.SOFFS )
        TrackFX_SetParamNormalized( track, instrument_pos, 14, drop_data.EOFFS )
      end
    
    -- store external data
      local peaks,it_len = DATA:CollectData_GetPeaks_sub(filename)
      if peaks and it_len then  
        local instrumentGUID = TrackFX_GetFXGUID( track, instrument_pos)
        DATA:WriteData_Child(track, {
          SET_SAMPLELEN = it_len,
          SET_instrFXGUID = instrumentGUID,
          SET_noteID=note,
          SET_isrs5k=true,
          SET_PEAKS=table.concat(peaks,'|'),
        }) 
      end 
    
    -- rename track
      if EXT.CONF_onadd_renametrack==1 then 
        local filename_sh = VF_GetShortSmplName(filename)
        if filename_sh:match('(.*)%.[%a]+') then filename_sh = filename_sh:match('(.*)%.[%a]+') end -- remove extension
        GetSetMediaTrackInfo_String( track, 'P_NAME', filename_sh, true )
      end
      
  end
  --------------------------------------------------------------------------------
  function UI.draw_Rack_PadOverview() 
    if UI.hide_padoverview == true then return end
    local ovrvieww = UI.calc_cellside*4
    if EXT.UI_drracklayout == 1 then ovrvieww = UI.calc_cellside*7 end
    --ImGui.InvisibleButton(ctx, '##padoverview',ovrvieww,-1)
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0)
    local val = 0
    if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_DRRACKSHIFT then val = DATA.parent_track.ext.PARENT_DRRACKSHIFT /127 end
    local retval, v = ImGui.VSliderDouble( ctx, '##padoverview', ovrvieww,UI.calc_padoverviewH, val, 0, 1, '', ImGui.SliderFlags_None)
    ImGui.PopStyleColor(ctx,5)
    if retval then UI.draw_Rack_PadOverview_handlemouse(v) end
    local x, y = ImGui.GetItemRectMin(ctx)
    local w, h = ImGui.GetItemRectSize(ctx) 
    if EXT.UI_drracklayout == 0 then UI.draw_Rack_PadOverview_generategrid_pads(x+1,y,w,h) end
    if EXT.UI_drracklayout == 1 then UI.draw_Rack_PadOverview_generategrid_keys(x+1,y,w,h) end 
  end
  --------------------------------------------------------------------------------
  function UI.draw_Rack_PadOverview_handlemouse(v) 
    if not (DATA.parent_track and DATA.parent_track.ext) then return end
    -- pads 
    if EXT.UI_drracklayout == 0 then
      local activerow = math.floor(v*33)
      local qblock = 4
      if activerow < 1 then activerow = 0 end
      for block = 0, 6 do if activerow >=block*4+1 and activerow <(block*4)+4+1 then activerow =block*4+1 end end
      activerow = math.min(activerow, 28)
      local out_offs = math.floor(activerow*4)
      if out_offs ~= DATA.parent_track.ext.PARENT_DRRACKSHIFT then 
        DATA.parent_track.ext.PARENT_DRRACKSHIFT = out_offs
        DATA:WriteData_Parent()
      end
    end
     
    -- keys
    if EXT.UI_drracklayout == 1 then 
      local out_offs = 127-math.floor((1-v)*127) 
      out_offs = 12 * math.floor(out_offs/12)
      if out_offs ~= DATA.parent_track.ext.PARENT_DRRACKSHIFT then 
        DATA.parent_track.ext.PARENT_DRRACKSHIFT = out_offs
        DATA:WriteData_Parent()
      end
    end
  end
  -----------------------------------------------------------------------------  
  function UI.draw_Rack_PadOverview_generategrid_pads(x,y,w,h)
    if not DATA.children then return end
    local refnote = 127
    for note = 0, 127 do 
      -- handle col
      local blockcol = 0x757575
      if 
        (note >=0 and note<=3)or
        (note >=20 and note<=35)or
        (note >=52 and note<=67)or
        (note >=84 and note<=99)or
        (note >=116 and note<=127) 
      then blockcol =0xD5D5D5 end
      
      
      local backgr_fill2 = 0.4 
      if DATA.children[note] then backgr_fill2 = 0.8  blockcol = 0xf3f6f4 end
      if DATA.playingnote and DATA.playingnote == note  then blockcol = 0xffe494 backgr_fill2 = 0.7 end
      
      
      if note%4 == 0 then x_offs = x end
      local p_min_x = x_offs
      local p_min_y = y+h - UI.calc_cellside*(1+(math.floor(note/4)))
      local p_max_x = p_min_x+UI.calc_cellside-1
      local p_max_y = p_min_y+UI.calc_cellside-1
      ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, blockcol<<8|math.floor(backgr_fill2*0xFF), 0, ImGui.DrawFlags_None )
      ImGui_SetCursorScreenPos( ctx, p_min_x, p_min_y )
      ImGui_InvisibleButton( ctx, '##padnote'..note, UI.calc_cellside, UI.calc_cellside )
      if ImGui.BeginDragDropTarget( ctx ) then  
        --DATA:Drop_UI_interaction_padoverview() 
        DATA:Drop_UI_interaction_pad(note) 
        ImGui_EndDragDropTarget( ctx )
      end
      x_offs = x_offs + UI.calc_cellside
    end
    
    -- selection
    if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_DRRACKSHIFT then
      local row_cnt = math.floor(127/4)
      local activerow = DATA.parent_track.ext.PARENT_DRRACKSHIFT  / 4
      local p_min_x = x
      local p_min_y = y+h - w-UI.calc_cellside*(activerow)
      local p_max_x = p_min_x+w-1
      local p_max_y = p_min_y+w
      ImGui.DrawList_AddRect( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, UI.colRGBA_selectionrect, 0, ImGui.DrawFlags_None, 1 )
    end
    
  end
  -----------------------------------------------------------------------------  
  function UI.draw_Rack_PadOverview_generategrid_keys(x_offs0,y_offs0,w,h)
  
    for note = 0, 127 do 
      -- handle col
      local blockcol = 0x757575
      if 
        (
          note%12 == 0
          or note%12 == 2
          or note%12 == 4
          or note%12 == 5
          or note%12 == 7
          or note%12 == 9
          or note%12 == 11
          
        ) 
      then blockcol =0xD5D5D5 end
      
      
      local backgr_fill2 = 0.4 
      if DATA.children[note] then backgr_fill2 = 0.8  blockcol = 0xf3f6f4 end
      if DATA.playingnote and DATA.playingnote == note  then blockcol = 0xffe494 backgr_fill2 = 0.7 end
      
      local x_offs = x_offs0
      local isblack
      if note%12 == 0 then x_offs = x_offs0 end
      if note%12 == 1 then x_offs = x_offs0+UI.calc_cellside*0.5 isblack = true end
      if note%12 == 2 then x_offs = x_offs0+UI.calc_cellside*1 end
      if note%12 == 3 then x_offs = x_offs0+UI.calc_cellside*1.5 isblack = true end
      if note%12 == 4 then x_offs = x_offs0+UI.calc_cellside*2 end
      if note%12 == 5 then x_offs = x_offs0+UI.calc_cellside*3 end
      if note%12 == 6 then x_offs = x_offs0+UI.calc_cellside*3.5 isblack = true end
      if note%12 == 7 then x_offs = x_offs0+UI.calc_cellside*4 end
      if note%12 == 8 then x_offs = x_offs0+UI.calc_cellside*4.5 isblack = true end
      if note%12 == 9 then x_offs = x_offs0+UI.calc_cellside*5 end
      if note%12 == 10 then x_offs = x_offs0+UI.calc_cellside*5.5 isblack = true end
      if note%12 == 11 then x_offs = x_offs0+UI.calc_cellside*6 end
      local oct = math.floor(note/12)
      local y_offs = y_offs0 +h  - (UI.calc_cellside*2) * oct-UI.calc_cellside
      if isblack then y_offs = y_offs - UI.calc_cellside end
      local p_min_x = x_offs
      local p_min_y = y_offs
      local p_max_x = p_min_x+UI.calc_cellside-1
      local p_max_y = p_min_y+UI.calc_cellside-1
      ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, blockcol<<8|math.floor(backgr_fill2*0xFF), 0, ImGui.DrawFlags_None )
      ImGui_SetCursorScreenPos( ctx, p_min_x, p_min_y )
      ImGui_InvisibleButton( ctx, '##padnote'..note, UI.calc_cellside, UI.calc_cellside )
      if ImGui.BeginDragDropTarget( ctx ) then  
        --DATA:Drop_UI_interaction_padoverview() 
        DATA:Drop_UI_interaction_pad(note) 
        ImGui_EndDragDropTarget( ctx )
      end
    end
    
    -- selection
    if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_DRRACKSHIFT then
      local activerow = DATA.parent_track.ext.PARENT_DRRACKSHIFT/12
      local activerecth = UI.calc_cellside*2
      
      local p_min_x = x_offs0
      local p_min_y = y_offs0+(10-activerow)*activerecth-1
      local p_max_x = p_min_x+w-1
      local p_max_y = p_min_y+activerecth
      ImGui.DrawList_AddRect( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y,UI.colRGBA_selectionrect, 0, ImGui.DrawFlags_None, 1 )
    end
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_settings_combo(extkey, mapt, str_id, name)
    ImGui.SetNextItemWidth(ctx, UI.settings_itemW )
    if ImGui.BeginCombo( ctx, name..str_id, mapt[EXT[extkey] ], ImGui.ComboFlags_None ) then--|ImGui.ComboFlags_NoArrowButton
      for key in spairs(mapt) do 
        if ImGui.Selectable( ctx, mapt[key]..str_id..key, EXT[extkey] == key, ImGui.SelectableFlags_None) then EXT[extkey] = key EXT:save() DATA.upd = true end
      end
      ImGui.EndCombo( ctx)
    end
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
  ImGui.SetNextItemWidth( ctx, t.extw or -1 )
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
  function UI.draw_tabs_settings()
    
    UI.tab_current = 'Settings'
    if not UI.tab_last or (UI.tab_last and UI.tab_last ~= UI.tab_current ) then EXT.UI_activeTab = UI.tab_current EXT:save() end
    
    UI.tab_last = UI.tab_current 
    if ImGui.BeginChild( ctx, '##settingscontent',-1, 0, ImGui.ChildFlags_None, ImGui.WindowFlags_None ) then 
      ImGui.SeparatorText(ctx, 'Current project settings') 
        ImGui.Indent(ctx, UI.settings_indent)
        --DATA.parent_track.ext.PARENT_MIDIFLAGS
        
        local stickstate = DATA.parent_track and DATA.parent_track.ext_load == true
        if DATA.parent_track and DATA.parent_track.trGUID then
          if ImGui.Checkbox( ctx, 'Stick current rack to this project', stickstate) then 
            if DATA.parent_track.ext_load == true then 
              SetProjExtState( DATA.proj, 'MPLRS5KMAN', 'STICKPARENTGUID','')
              DATA.upd = true
             else
              SetProjExtState( DATA.proj, 'MPLRS5KMAN', 'STICKPARENTGUID',DATA.parent_track.trGUID )
              DATA.upd = true
            end
          end
        end
        ImGui.SameLine(ctx)
        UI.HelpMarker('This rack will be always displayed even if selected track is not related to this rack.\nThis also ignores other racks in project.')
        
        if ImGui.Button(ctx, 'Clear ALL rack choke setup') then 
          for i = 0, 127 do DATA.MIDIbus.CHOKE_flags[i] = 0 end
          Undo_BeginBlock2(DATA.proj )
          DATA:WriteData_UpdateChoke()
          Undo_EndBlock2( DATA.proj , 'RS5k manager - Clear choke setup', 0xFFFFFFFF ) 
          
        end
        
        
        ImGui.Unindent(ctx, UI.settings_indent)
        ImGui.Dummy(ctx, 0,UI.spacingY*10)
        
      ImGui.SeparatorText(ctx, 'On sample add')  
        ImGui.Indent(ctx, UI.settings_indent)
        if ImGui.Checkbox( ctx, 'Float RS5k instance',                                    EXT.CONF_onadd_float == 1 ) then EXT.CONF_onadd_float =EXT.CONF_onadd_float~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Copy samples to project path',                           EXT.CONF_onadd_copytoprojectpath == 1 ) then EXT.CONF_onadd_copytoprojectpath =EXT.CONF_onadd_copytoprojectpath~1 EXT:save() end 
        if ImGui.Checkbox( ctx, 'Set obey notes-off',                                     EXT.CONF_onadd_obeynoteoff == 1 ) then EXT.CONF_onadd_obeynoteoff =EXT.CONF_onadd_obeynoteoff~1 EXT:save() end 
        if ImGui.Checkbox( ctx, 'Rename track',                                           EXT.CONF_onadd_renametrack == 1 ) then EXT.CONF_onadd_renametrack =EXT.CONF_onadd_renametrack~1 EXT:save() end 
        if ImGui.Checkbox( ctx, 'Drop to white keys only',                                EXT.CONF_onadd_whitekeyspriority == 1 ) then EXT.CONF_onadd_whitekeyspriority =EXT.CONF_onadd_whitekeyspriority~1 EXT:save() end
        ImGui_SetNextItemWidth(ctx, UI.settings_itemW) 
        local ret, buf = ImGui.InputText( ctx, 'Custom template file',                    EXT.CONF_onadd_customtemplate, ImGui.InputTextFlags_EnterReturnsTrue) if ret then EXT.CONF_onadd_customtemplate =buf EXT:save() end
        ImGui.SameLine(ctx)
        UI.HelpMarker('Path to file')
        ImGui.Unindent(ctx, UI.settings_indent)
        ImGui.Dummy(ctx, 0,UI.spacingY*10)
        
      ImGui.SeparatorText(ctx, 'TCP / MCP')  
        ImGui.Indent(ctx, UI.settings_indent)
        if ImGui.Checkbox( ctx, 'Collapse parent folder',                                 EXT.CONF_onadd_newchild_trackheightflags&1==1 ) then 
          EXT.CONF_onadd_newchild_trackheightflags =EXT.CONF_onadd_newchild_trackheightflags~1 
          if EXT.CONF_onadd_newchild_trackheightflags&2==2 then EXT.CONF_onadd_newchild_trackheightflags = EXT.CONF_onadd_newchild_trackheightflags~2 end
          EXT:save() 
          DATA.upd = true
          DATA.upd_TCP = true
        end
        if ImGui.Checkbox( ctx, 'Supercollapse parent folder',                            EXT.CONF_onadd_newchild_trackheightflags&2==2 ) then 
          EXT.CONF_onadd_newchild_trackheightflags =EXT.CONF_onadd_newchild_trackheightflags~2 
          if EXT.CONF_onadd_newchild_trackheightflags&1==1 then EXT.CONF_onadd_newchild_trackheightflags = EXT.CONF_onadd_newchild_trackheightflags~1 end
          EXT:save() 
          DATA.upd = true
          DATA.upd_TCP = true
        end
        if ImGui.Checkbox( ctx, 'Hide children TCP',                                      EXT.CONF_onadd_newchild_trackheightflags&4==4 ) then EXT.CONF_onadd_newchild_trackheightflags =EXT.CONF_onadd_newchild_trackheightflags~4 EXT:save() DATA.upd = true DATA.upd_TCP = true end
        if ImGui.Checkbox( ctx, 'Hide children MCP',                                      EXT.CONF_onadd_newchild_trackheightflags&8==8 ) then EXT.CONF_onadd_newchild_trackheightflags =EXT.CONF_onadd_newchild_trackheightflags~8 EXT:save() DATA.upd = true DATA.upd_TCP = true end
        
        ImGui_SetNextItemWidth(ctx, UI.settings_itemW)  
        local formatin = '%dpx' if EXT.CONF_onadd_newchild_trackheight == 0 then formatin = 'default' end
        local ret, v = ImGui.SliderInt( ctx, 'New child track height',                    EXT.CONF_onadd_newchild_trackheight, 0, 300, formatin, ImGui.SliderFlags_None ) if ret then EXT.CONF_onadd_newchild_trackheight = v EXT:save() end
        --[[if ImGui.Checkbox( ctx, 'Add childs to the top',                                  EXT.CONF_trackorderflags==0 ) then EXT.CONF_trackorderflags =0 EXT:save() end
        if ImGui.Checkbox( ctx, 'Add childs to the bottom',                               EXT.CONF_trackorderflags==1 ) then EXT.CONF_trackorderflags =1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Add childs according to note, ascending',                EXT.CONF_trackorderflags==2 ) then EXT.CONF_trackorderflags =2 EXT:save() end
        if ImGui.Checkbox( ctx, 'Add childs according to note, descending',               EXT.CONF_trackorderflags==3 ) then EXT.CONF_trackorderflags =3 EXT:save() end]]
        ImGui.Unindent(ctx, UI.settings_indent)
        ImGui.Dummy(ctx, 0,UI.spacingY*10)
        
        
      ImGui.SeparatorText(ctx, 'MIDI bus')  
        ImGui.Indent(ctx, UI.settings_indent)
        UI.draw_tabs_settings_combo('CONF_midiinput',DATA.MIDI_inputs,'##settings_drracklayout', 'MIDI bus default input') 
        ImGui.SetNextItemWidth(ctx, UI.settings_itemW) 
        local chanformat = 'Channel '..EXT.CONF_midichannel if EXT.CONF_midichannel == 0 then chanformat = 'All channels' end
        local ret, v = ImGui.SliderInt( ctx, 'MIDI bus channel',                          EXT.CONF_midichannel, 0, 16, chanformat, ImGui.SliderFlags_None ) if ret then EXT.CONF_midichannel = v EXT:save() end
        if ImGui.Button(ctx, 'Initialize MIDI bus') then DATA:Validate_MIDIbus_AND_ParentFolder() end
        if ImGui.Checkbox( ctx, 'Auto rename MIDI bus MIDI notes',                                EXT.CONF_autorenamemidinotenames&1==1 ) then EXT.CONF_autorenamemidinotenames =EXT.CONF_autorenamemidinotenames~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Auto rename devices and children MIDI notes',                    EXT.CONF_autorenamemidinotenames&2==2 ) then EXT.CONF_autorenamemidinotenames =EXT.CONF_autorenamemidinotenames~2 EXT:save() end
        ImGui.Unindent(ctx, UI.settings_indent)
        ImGui.Dummy(ctx, 0,UI.spacingY*10)
      

      ImGui.SeparatorText(ctx, 'UI interaction') 
        ImGui.Indent(ctx, UI.settings_indent)
        UI.draw_tabs_settings_combo('UI_drracklayout',{[0]='Default / 8x4 pads',[1]='2 octaves keys'},'##settings_drracklayout', 'DrumRack layout') 
        if ImGui.Checkbox( ctx, 'Click on pad select track',                              EXT.UI_clickonpadselecttrack == 1 ) then EXT.UI_clickonpadselecttrack =EXT.UI_clickonpadselecttrack~1 EXT:save() end
        ImGui_SetNextItemWidth(ctx, UI.settings_itemW) 
        local ret, v = ImGui.SliderInt( ctx, 'Default playing velocity',                  EXT.CONF_default_velocity, 1, 127, '%d', ImGui.SliderFlags_None ) if ret then EXT.CONF_default_velocity = v EXT:save() end
        if ImGui.Checkbox( ctx, 'Releasing mouse on pad send NoteOff',                             EXT.UI_pads_sendnoteoff == 1 ) then EXT.UI_pads_sendnoteoff =EXT.UI_pads_sendnoteoff~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Active note follow incoming note',                       EXT.UI_incomingnoteselectpad == 1 ) then EXT.UI_incomingnoteselectpad =EXT.UI_incomingnoteselectpad~1 EXT:save() end
        ImGui.SameLine(ctx)
        UI.HelpMarker('May be CPU hungry')
        ImGui.Unindent(ctx, UI.settings_indent)
        ImGui.Dummy(ctx, 0,UI.spacingY*10)
      
      
      ImGui.SeparatorText(ctx, 'Various') 
        ImGui.Indent(ctx, UI.settings_indent)
        if ImGui.Checkbox( ctx, 'Do not load database',            EXT.CONF_ignoreDBload == 1 ) then EXT.CONF_ignoreDBload =EXT.CONF_ignoreDBload~1 EXT:save() end
        ImGui.SameLine(ctx)
        UI.HelpMarker('May increase loading time, but you wont be able to use databases')
        ImGui.Text( ctx, 'Current loading time: '..(math.floor(10000*DATA.loadtest)/10000)..'s')
        if ImGui.Checkbox( ctx, 'Show meters on pads',            EXT.CONF_showplayingmeters == 1 ) then EXT.CONF_showplayingmeters =EXT.CONF_showplayingmeters~1 EXT:save() end
        ImGui.SameLine(ctx)
        UI.HelpMarker('May be CPU hungry')
        if ImGui.Checkbox( ctx, 'Show peaks on pads',            EXT.CONF_showpadpeaks == 1 ) then EXT.CONF_showpadpeaks =EXT.CONF_showpadpeaks~1 EXT:save() end
        ImGui.SameLine(ctx)
        UI.HelpMarker('May be CPU hungry')
        
        ImGui.Unindent(ctx, UI.settings_indent)
      
      
      
      ImGui.EndChild( ctx)
    end
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Rack()  
    UI.draw_Rack_PadOverview() 
    --ImGui.SetCursorPosX(ctx,UI.calc_rackX+100)
    ImGui.SameLine(ctx) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,0,0)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,0,0) 
    
    ImGui.SetCursorScreenPos(ctx,UI.calc_rackX,UI.calc_rackY)
    if ImGui.BeginChild( ctx, 'rack', UI.calc_rackW, 0, ImGui.ChildFlags_None, ImGui.WindowFlags_None |ImGui.WindowFlags_NoScrollbar ) then--|ImGui.ChildFlags_Border --|ImGui.WindowFlags_MenuBar
      UI.draw_Rack_Pads()  
      ImGui.EndChild( ctx)
    end
    ImGui.PopStyleVar(ctx,2)
  end 
  --------------------------------------------------------------------------------  
  function UI.draw_Rack_Pads() 
    
    if not (DATA.parent_track and DATA.parent_track.valid == true) then 
      ImGui.TextWrapped(ctx,
      [[ 
  RS5k manager quick tips: 
      1. Select parent track. It will be parent track for drum rack.
      2. Once parent track is selected, drum rack is ready for adding samples to it.
      3. Drop sample to pads from OS browsr or MediaExplorer to pad.  
      4. RS5k manager will automatically initialize all needed routing setup.
      ]])
      if ImGui.Button(ctx, 'Feature requests and bug reports at Cockos forum') then VF_Open_URL('http://forum.cockos.com/showthread.php?t=207971') end
      ImGui.TextWrapped(ctx,
      [[
      For bug reports:
        - make sure you are running the latest version of RS5k manager
        - please attach FULL text of error (including error line number) and steps to reproduce.
      ]])
      return
    end
      
      
      
    
    
    local layout_mode = EXT.UI_drracklayout
    --ImGui.DrawList_AddRectFilled( UI.draw_list, UI.calc_rackX, UI.calc_rackY, UI.calc_rackX+UI.calc_rackW, UI.calc_rackY+UI.calc_rackH, 0xFFFFFFA0, 0, 0 )
    if layout_mode == 0 then
      local layout_pads_cnt = 16
      local yoffs = UI.calc_rackY  + UI.calc_rack_padh*3 + UI.spacingY*3--+ UI.calc_rackH
      local xoffs= UI.calc_rackX
      local padID0 = 0
      for note = 0+DATA.parent_track.ext.PARENT_DRRACKSHIFT, layout_pads_cnt-1+DATA.parent_track.ext.PARENT_DRRACKSHIFT do
        UI.draw_Rack_Pads_controls(DATA.children[note], note, xoffs, yoffs, UI.calc_rack_padw, UI.calc_rack_padh) 
        xoffs = xoffs + UI.calc_rack_padw + UI.spacingX
        if padID0%4==3 then 
          xoffs = UI.calc_rackX 
          yoffs = yoffs - UI.calc_rack_padh - UI.spacingY
        end
        padID0 = padID0 + 1
      end
    end
    
    if layout_mode == 1 then
      local layout_pads_cnt = 24
        
      local xoffs0 = UI.calc_rackX
      --local yoffs0 = UI.calc_rackY + UI.calc_rackH - UI.calc_rack_padh
      local yoffs0 = UI.calc_rackY  + UI.calc_rack_padh*3 --+ UI.spacingY*3
      local padID0 = 0
      local oct = -1
      local xoffs, yoffs
      for note = DATA.parent_track.ext.PARENT_DRRACKSHIFT, layout_pads_cnt-1+DATA.parent_track.ext.PARENT_DRRACKSHIFT do
        xoffs = xoffs0
        yoffs = yoffs0
        local note_oct = note%12
        if note_oct ==0 then oct = oct + 1 end
        if oct == 1 then yoffs = yoffs - UI.calc_rack_padh*2 end
        if note_oct == 0 then xoffs = xoffs0 end
        if note_oct == 1 then xoffs = xoffs0+0.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
        if note_oct == 2 then xoffs = xoffs0+1*UI.calc_rack_padw end
        if note_oct == 3 then xoffs = xoffs0+1.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
        if note_oct == 4 then xoffs = xoffs0+UI.calc_rack_padw*2 end
        if note_oct == 5 then xoffs = xoffs0+UI.calc_rack_padw*3 end
        if note_oct == 6 then xoffs = xoffs0+3.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
        if note_oct == 7 then xoffs = xoffs0+UI.calc_rack_padw*4 end
        if note_oct == 8 then xoffs = xoffs0+4.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
        if note_oct == 9 then xoffs = xoffs0+UI.calc_rack_padw*5 end
        if note_oct == 10 then xoffs = xoffs0+5.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
        if note_oct == 11 then xoffs = xoffs0+UI.calc_rack_padw*6 end
        if note >= 0 and note <=127 then UI.draw_Rack_Pads_controls(DATA.children[note], note, xoffs, yoffs, UI.calc_rack_padw, UI.calc_rack_padh) end
        padID0=padID0+1
      end
      
    end
    
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Rack_Pads_controls(note_t,note, x,y,w,h) 
    local min_h = UI.controls_minH
    -- name background 
      local color
      if note_t and note_t.I_CUSTOMCOLOR then 
        color = ImGui.ColorConvertNative(note_t.I_CUSTOMCOLOR) 
        color = color & 0x1000000 ~= 0 and (color << 8) | 0xFF-- https://forum.cockos.com/showpost.php?p=2799017&postcount=6
      end
      local h_name = h
      if h > min_h then h_name = UI.calc_rack_padnameH end
      if color then 
        ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+h_name, color, 5, ImGui.DrawFlags_RoundCornersTop) 
       else 
        if note_t then
          ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+h_name, UI.colRGBA_paddefaultbackgr, 5, ImGui.DrawFlags_RoundCornersTop)
         else
          ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+h_name, UI.colRGBA_paddefaultbackgr_inactive, 5, ImGui.DrawFlags_RoundCornersTop) 
        end
      end
    
    --
      if 
        DATA.children[note] and
        DATA.children[note].layers and 
        DATA.children[note].layers[1] and 
        DATA.children[note].layers[1].peaks_arr  then UI.draw_peaks('pad'..note, note_t,x, y+UI.calc_itemH,w, UI.calc_rack_padnameH-UI.calc_itemH,DATA.children[note].layers[1].peaks_arr) end
    
    -- controls background
      if h > min_h then ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y+UI.calc_rack_padnameH, x+w-1, y+h-1, 0xFFFFFF1F, 5, ImGui.DrawFlags_RoundCornersBottom ) end
      
    -- controls background
      --ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y+UI.calc_rack_padnameH, x+w-1, y+h-1, 0xFFFFFF1F, 5, ImGui.DrawFlags_RoundCornersBottom )
    
    -- frame / selection 
      if (DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE  == note) then 
        ImGui.DrawList_AddRect( UI.draw_list, x, y, x+w, y+h, UI.colRGBA_selectionrect, 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
       else
        ImGui.DrawList_AddRect( UI.draw_list, x, y, x+w, y+h, 0x0000005F              , 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
      end
      
    
    ImGui.SetCursorScreenPos( ctx, x, y )  
    if ImGui.BeginChild( ctx, '##rackpad'..note, w, h, ImGui.ChildFlags_None , ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then--|ImGui.ChildFlags_Border
      local note_format = VF_Format_Note(note,note_t)
      UI.Tools_setbuttonbackg() 
      
      -- name 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX, UI.spacingY)
        local local_pos_x, local_pos_y = ImGui.GetCursorPos( ctx )
        ImGui.SetCursorPos( ctx, local_pos_x+UI.spacingX, local_pos_y+UI.spacingY )
        ImGui.Button(ctx,'##rackpad_name'..note,UI.calc_rack_padw -UI.spacingX *2+1,UI.calc_rack_padnameH-UI.spacingY*2 )
        UI.draw_Rack_Pads_controls_handlemouse(note_t,note)
        ImGui.SetCursorPos( ctx, local_pos_x+UI.spacingX, local_pos_y+UI.spacingY )
        ImGui.TextWrapped( ctx, note_format )
        ImGui.PopStyleVar(ctx)
        
      if h > min_h then 
      -- mute
        ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y +UI.calc_rack_padnameH)
        local ismute = note_t and note_t.B_MUTE and note_t.B_MUTE == 1
        if ismute==true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFF0F0FF0 ) end
        if note_t and ImGui.Button(ctx,'M##rackpad_mute'..note,UI.calc_rack_padctrlW,UI.calc_rack_padctrlH ) then SetMediaTrackInfo_Value( note_t.tr_ptr, 'B_MUTE', note_t.B_MUTE~1 ) DATA.upd = true end  
        if ismute==true then ImGui.PopStyleColor(ctx) end
        ImGui.SameLine(ctx)
        
      -- play
        ImGui.InvisibleButton(ctx,'P##rackpad_playinv'..note,UI.calc_rack_padctrlW,UI.calc_rack_padctrlH )
        if ImGui.IsItemActivated( ctx ) then DATA:Sampler_StuffNoteOn(note) end
        if ImGui.IsItemDeactivated( ctx ) and EXT.UI_pads_sendnoteoff == 1 then DATA:Sampler_StuffNoteOn(note, 0, true) end
        
        local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
        local x2, y2 = reaper.ImGui_GetItemRectMax( ctx ) 
        --UI.textcol col_green
        local col = UI.textcol 
        if DATA.lastMIDIinputnote and DATA.lastMIDIinputnote == note then 
          --[[smooth green light
          r1,g1,b1 = (UI.textcol>>16)&0xFF, (UI.textcol>>8)&0xFF, UI.textcol&0xFF
          r2,g2,b2 = (UI.padplaycol>>16)&0xFF, (UI.padplaycol>>8)&0xFF, UI.padplaycol&0xFF
          col_r = r1 + (r2-r1)* DATA.lastMIDIinputnote[note ].alpha
          col_g = g1 + (g2-g1)* DATA.lastMIDIinputnote[note ].alpha
          col_b = b1 + (b2-b1)* DATA.lastMIDIinputnote[note ].alpha
          col = math.floor(col_r)<<16|math.floor(col_g)<<8|math.floor(col_b)]]
          col = UI.padplaycol
        end
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, col<<8|0xFF)
        ImGui.SetCursorScreenPos( ctx, x1+(x2-x1)/2-UI.calc_itemH/2, y1+(y2-y1)/2-UI.calc_itemH/2 )
        if note_t then ImGui.ArrowButton(ctx,'P##rackpad_play'..note ,ImGui.Dir_Right )end
        ImGui.PopStyleColor(ctx)
        
      -- solo
        ImGui.SetCursorScreenPos( ctx, x1+UI.calc_rack_padctrlW, y1 )
        local issolo = note_t and note_t.I_SOLO and note_t.I_SOLO > 0 
        if issolo == true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x00FF0FF0 ) end
        if note_t and ImGui.Button(ctx,'S##rackpad_solo'..note,UI.calc_rack_padctrlW,UI.calc_rack_padctrlH ) then
          if note_t and note_t.tr_ptr then 
            local outval = 2 if note_t.I_SOLO>0 then outval = 0 end SetMediaTrackInfo_Value( note_t.tr_ptr, 'I_SOLO', outval ) DATA.upd = true
          end 
        end   
        if issolo == true then ImGui.PopStyleColor(ctx) end
      end
      UI.Tools_unsetbuttonstyle()
      ImGui.EndChild( ctx)
    end
    
    UI.draw_Rack_Pads_controls_levels(note_t,note, x,y,w,h) 
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Rack_Pads_controls_levels(note_t,note, x,y,w,h)
    local peak_w = 5
    if DATA.children[note] and DATA.children[note].peaksRMS_L and (DATA.children[note].peaksRMS_L>0.001 or DATA.children[note].peaksRMS_R >0.001 )then
      ImGui.DrawList_AddRectFilled( UI.draw_list, x+w-peak_w*2+1, y+1+UI.calc_rack_padnameH - UI.calc_rack_padnameH*DATA.children[note].peaksRMS_L , x+w-1-peak_w, y+UI.calc_rack_padnameH, UI.col_maintheme<<8|0xFF, 0, ImGui.DrawFlags_RoundCornersTop) 
      ImGui.DrawList_AddRectFilled( UI.draw_list, x+w-peak_w, y+1+UI.calc_rack_padnameH - UI.calc_rack_padnameH*DATA.children[note].peaksRMS_R , x+w-2, y+UI.calc_rack_padnameH, UI.col_maintheme<<8|0xFF, 0, ImGui.DrawFlags_RoundCornersTop) 
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Rack_Pads_controls_handlemouse(note_t,note)
    if not (note_t and note_t.TYPE_DEVICE==true) and  ImGui.BeginDragDropTarget( ctx ) then  
      DATA:Drop_UI_interaction_pad(note) 
      ImGui_EndDragDropTarget( ctx )
    end 
    
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
      DATA.parent_track.ext.PARENT_LASTACTIVENOTE=note
      DATA:WriteData_Parent() 
      DATA.upd = true
      if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'pad' end
    end
    
    if ImGui.IsItemClicked(ctx,ImGui.MouseButton_Left) then -- click select track
      if EXT.UI_clickonpadselecttrack == 1 and note_t then SetOnlyTrackSelected( note_t.tr_ptr )  end
      DATA.parent_track.ext.PARENT_LASTACTIVENOTE=note
      DATA:WriteData_Parent() 
      DATA.upd = true
    end
    
    if note_t and note_t.noteID and ImGui.BeginDragDropSource( ctx, ImGui.DragDropFlags_None ) then 
      ImGui.SetDragDropPayload( ctx, 'moving_pad', note_t.noteID, ImGui.Cond_Once )
      ImGui.Text(ctx, 'Move pad ['..note_t.noteID..'] '..note_t.P_NAME)
      DATA.paddrop_ID = note_t.noteID
      ImGui.EndDragDropSource(ctx)
    end
    
  end
  -----------------------------------------------------------------------  
  function DATA:Sampler_ShowME(note0, layer0) 
    local note 
    if not note then 
      if not DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then return end 
      note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE 
     else 
      note = note0 
    end
    local layer if not layer then layer = 1 else layer = layer0 end
    if not DATA.children[note] then return end
    local t = DATA.children[note].layers[layer] -- layer == 1 do stuff on device/instrument or first layer only // layer defined = do stuff on defined layer 
    if not t.instrument_filename then return end
    OpenMediaExplorer( t.instrument_filename, false )
  end
  -------------------------------------------------------------------------------- 
  function UI.draw_actions() 
    if DATA.trig_openpopup then 
      ImGui.OpenPopup( ctx, 'mainRCmenu', ImGui.PopupFlags_None )
      DATA.trig_context = DATA.trig_openpopup 
      DATA.trig_openpopup = nil
    end
    
  
    local round = 4
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, round)
    
  
    -- draw content
    -- (from reaimgui demo) Always center this window when appearing
    --local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
    local windw = 300--DATA.display_w*0.3
    local windh = 200--DATA.display_h*0.5
    local center_x, center_y = ImGui.GetMouseClickedPos( ctx,ImGui.MouseButton_Right  )
    --ImGui.SetNextWindowPos(ctx, center_x+windw/2-25, center_y+windh/2-10, ImGui.Cond_Appearing, 0.5, 0.5)
    ImGui.SetNextWindowPos(ctx, center_x-25, center_y-10, ImGui.Cond_Appearing, 0, 0)
    ImGui.SetNextWindowSize(ctx, windw, windh, ImGui.Cond_Always)
    if ImGui.BeginPopupModal(ctx, 'mainRCmenu', nil, ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Border) then 
      
      if ImGui.Button(ctx, 'Close') then ImGui.CloseCurrentPopup(ctx)  end
      
      -- pad stuff
      if DATA.trig_context == 'pad' and DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE  then 
        ImGui.SeparatorText(ctx, 'Pad '..DATA.parent_track.ext.PARENT_LASTACTIVENOTE)
        local note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE 
        
        -- import last touched fx
        local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
        local track = GetTrack(-1,trackidx) if  trackidx == -1 then track = GetMasterTrack(-1) end
        local retval, fx_namesrc = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_name' )
        local fx_name = VF_ReduceFXname(fx_namesrc)
        if retval and fx_name then
          if ImGui.Button(ctx, 'Import ['..fx_name..'] as instrument',-1) then
            DATA:DropFX(fx_namesrc, fx_name, fxidx, track, note, drop_data)
            ImGui.CloseCurrentPopup(ctx) 
          end     
        end
          
        if ImGui.Button(ctx, 'Import selected items, starting this pad',-1) then
          DATA:Sampler_ImportSelectedItems()
          ImGui.CloseCurrentPopup(ctx) 
        end
        if ImGui.Button(ctx, 'Remove pad content',-1) then
          DATA:Sampler_RemovePad(note) 
        end
        
      end
      
      -- macro stuff
      if DATA.trig_context == 'macro' and DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO  then 
        local macroID = DATA.parent_track.ext.PARENT_LASTACTIVEMACRO
        ImGui.SeparatorText(ctx, 'Macro '..macroID)
        -- name
        local custom_name = ''
        if DATA.parent_track.ext and DATA.parent_track.ext.PARENT_MACROEXT and DATA.parent_track.ext.PARENT_MACROEXT[macroID] and DATA.parent_track.ext.PARENT_MACROEXT[macroID].custom_name then custom_name = DATA.parent_track.ext.PARENT_MACROEXT[macroID].custom_name end
        local retval, buf = ImGui.InputText( ctx, 'Macro name', custom_name, ImGui.InputTextFlags_None )--ImGui.InputTextFlags_EnterReturnsTrue
        if retval then 
          if buf == '' then DATA.parent_track.ext.PARENT_MACROEXT[macroID].custom_name = nil else DATA.parent_track.ext.PARENT_MACROEXT[macroID].custom_name = buf end
          DATA:WriteData_Parent() 
        end
        -- col rgb
        local col_current = 0
        if DATA.parent_track.ext.PARENT_MACROEXT and DATA.parent_track.ext.PARENT_MACROEXT[macroID] and DATA.parent_track.ext.PARENT_MACROEXT[macroID].col_rgb then
          col_current = DATA.parent_track.ext.PARENT_MACROEXT[macroID].col_rgb
        end
        local retval, col_rgb = ImGui_ColorEdit3( ctx, 'Macro '..macroID..' color', col_current, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs|ImGui.ColorEditFlags_NoAlpha )
        if retval then
          if not DATA.parent_track.ext.PARENT_MACROEXT[macroID] then DATA.parent_track.ext.PARENT_MACROEXT[macroID] = {} end
          DATA.parent_track.ext.PARENT_MACROEXT[macroID].col_rgb = col_rgb
          DATA:WriteData_Parent() 
          --ImGui.CloseCurrentPopup(ctx) 
        end
      end
      
      
      --ImGui.SameLine(ctx) 
      
      --[[ general
      if (DATA.parent_track and DATA.parent_track.valid == true) then  
        ImGui.SeparatorText(ctx, 'Actions') 
        ImGui.Indent(ctx, UI.settings_indent)
          if ImGui.Button(ctx, 'Show parent FX chain##parentmenuFX',-1) then TrackFX_Show( DATA.parent_track.ptr,-1,1)  end--ImGui.SelectableFlags_DontClosePopups
        ImGui.Unindent(ctx, UI.settings_indent)
      end]]
      
      if DATA.trig_closepopup == true then ImGui.CloseCurrentPopup(ctx) DATA.trig_closepopup = nil end
      ImGui.EndPopup(ctx)
    end 
  
    ImGui.PopStyleVar(ctx, 4)
  end 
  --------------------------------------------------------------------------------  
  function UI.draw_tabs()
    if UI.hide_tabs == true then return end
    if not (DATA.parent_track and DATA.parent_track.ext) then return end
    local xabs,yabs = ImGui.GetCursorScreenPos(ctx)
    ImGui.SetCursorScreenPos(ctx,xabs,UI.calc_rackY)
    
    local tabW = -1
    local cur_w = DATA.display_w - ImGui.GetCursorPosX(ctx)
    if cur_w > UI.settingsfixedW then tabW = UI.settingsfixedW end
    if ImGui.BeginChild( ctx, 'tabs', tabW, 0, ImGui.ChildFlags_None , ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then --|ImGui.ChildFlags_Border
      
      if ImGui.BeginTabBar( ctx, 'tabsbar', ImGui.TabItemFlags_None ) then
        
        if ImGui.BeginTabItem( ctx, 'Sampler', false, ImGui.TabItemFlags_None ) then UI.tab_context = 'Sampler' UI.draw_tabs_Sampler()  ImGui.EndTabItem( ctx)  end 
        if ImGui.BeginTabItem( ctx, 'Macro', false, ImGui.TabItemFlags_None ) then UI.tab_context = 'Macro' UI.draw_tabs_macro() ImGui.EndTabItem( ctx)  end  
        if ImGui.BeginTabItem( ctx, 'Settings', false, ImGui.TabItemFlags_None ) then UI.tab_context = '' UI.draw_tabs_settings() ImGui.EndTabItem( ctx)  end 
        if ImGui.BeginTabItem( ctx, 'Info', false, ImGui.TabItemFlags_None ) then UI.tab_context = '' UI.draw_tabs_info() ImGui.EndTabItem( ctx)  end 
        
        
        
        ImGui.EndTabBar( ctx)
      end
      
      ImGui.Dummy(ctx,0,0)
      ImGui.EndChild( ctx)
    end
  end 
    --------------------------------------------------------------------------------  
  function VF_Open_URL(url) if GetOS():match("OSX") then os.execute('open "" '.. url) else os.execute('start "" '.. url)  end  end    
  --------------------------------------------------------------------------------  
  function UI.Link(txt, url)
    local color = ImGui.GetStyleColor(ctx, ImGui.Col_CheckMark)
    ImGui.TextColored(ctx, color, txt)
    if ImGui.IsItemClicked(ctx) then
      VF_Open_URL(url)
    elseif ImGui.IsItemHovered(ctx) then
      ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_info() 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,0,0)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,0,0)  
    ImGui.Dummy(ctx,10,10)
    UI.Link('Forum thread', 'https://forum.cockos.com/showthread.php?t=207971')
    ImGui.Dummy(ctx,10,10)
    UI.Link('Donate', 'ton://transfer/UQBddyjnQwCm7kK-4Fj-y0Tplj5Alm17hCUqQiI6TC7fOq4d')
    ImGui.Dummy(ctx,10,10)
    UI.Link('Telegram chat', 'https://t.me/mplscripts_chat')
    
    ImGui.PopStyleVar(ctx,2)
  end  
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_macro()
    if not DATA.parent_track.valid == true then return end
    
    local MACRO_GUID = DATA.parent_track.ext.PARENT_MACRO_GUID   
    if not (MACRO_GUID and MACRO_GUID~='') then 
      if ImGui.Button(ctx, 'Init macro on parent track') then DATA:Macro_InitChildrenMacro() end
      return 
    end
    
    
    if not (DATA.parent_track.macro and DATA.parent_track.macro.sliders) then return end
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,0,0)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,0,0)  
    
    local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
    local lane_in_row = 4
    for sliderID = 1, 8 do--#DATA.parent_track.macro.sliders do 
      if DATA.parent_track.macro.sliders[sliderID] then 
        local x = curposx + (UI.calc_macro_w+UI.spacingX) * ((sliderID-1)%lane_in_row)
        local y = curposy + (UI.calc_macro_h+UI.spacingY) * math.floor((sliderID-1)/lane_in_row)
        local colfill_rgb 
        if DATA.parent_track.ext.PARENT_MACROEXT and DATA.parent_track.ext.PARENT_MACROEXT[sliderID] and DATA.parent_track.ext.PARENT_MACROEXT[sliderID].col_rgb then colfill_rgb = DATA.parent_track.ext.PARENT_MACROEXT[sliderID].col_rgb end
          
        local name = 'Macro '..sliderID
        if DATA.parent_track.ext.PARENT_MACROEXT and DATA.parent_track.ext.PARENT_MACROEXT[sliderID] and DATA.parent_track.ext.PARENT_MACROEXT[sliderID].custom_name then name = DATA.parent_track.ext.PARENT_MACROEXT[sliderID].custom_name end
          
        UI.draw_knob(
          {str_id = '##slider'..sliderID,
          is_selected = (DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO  == sliderID),
          val = DATA.parent_track.macro.sliders[sliderID].val,
          x = x, 
          y = y,
          w = UI.calc_macro_w,
          h = UI.calc_macro_h,
          colfill_rgb = colfill_rgb,
          name = name, 
          active_name = DATA.parent_track.macro.sliders[sliderID].has_links ,
          appfunc_atclick = function(v) 
                                  DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = sliderID
                                  DATA:WriteData_Parent()  
                                end,
          appfunc_atclickR = function(v) 
                                  DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = sliderID
                                  DATA:WriteData_Parent()  
                                  DATA.upd = true
                                  if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'macro' end
                                end,
          appfunc_atdrag = function(v) DATA.parent_track.macro.sliders[sliderID].val = v TrackFX_SetParamNormalized( DATA.parent_track.ptr, DATA.parent_track.macro.pos, sliderID, v )   end,
          appfunc_atclick_name= function()
                                  DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = sliderID
                                  DATA:WriteData_Parent() 
                                end,
          appfunc_atclick_nameR= function()
                                  DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = sliderID
                                  DATA:WriteData_Parent()  
                                  DATA.upd = true
                                  if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'macro' end
                                end,            
          }) 
        ImGui.SameLine(ctx)
      end
    end
    
    
    
    
    ImGui.PopStyleVar(ctx,2)
    ImGui.SetCursorScreenPos(ctx,curposx, curposy+UI.calc_macro_h*2+UI.spacingY*2)
    UI.draw_tabs_macro_links()
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_macro_links_SetParams(UI_min,UI_max,link_t,note_layer_t)
    TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.offset', 0)  
    TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'mod.baseline', UI_min) 
    
    local ret, baseline = TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'mod.baseline')  baseline = tonumber(baseline)
    local ret, scale = TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.scale')  scale = tonumber(scale)
    
    if baseline + scale < 0 or baseline + scale > 1 then 
      UI_max = VF_lim(baseline + scale)
      TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.scale', UI_max - baseline)  
     else
      TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.scale', UI_max - baseline)  
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_macro_links()
    local indent= 20
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY)  
    --ImGui.SetCursorPos(ctx, 0,0)
     
    -- link list
    if ImGui.BeginChild( ctx, 'macrolinks', 0, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then--|ImGui.ChildFlags_Border --|ImGui.WindowFlags_MenuBar-- |ImGui.WindowFlags_NoScrollbar -- UI.calc_rackW
    
      
      if (DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO) then
        
        local macroID = DATA.parent_track.ext.PARENT_LASTACTIVEMACRO
        if DATA.parent_track.macro.sliders[macroID] and DATA.parent_track.macro.sliders[macroID].links then
          for linkID = 1, #DATA.parent_track.macro.sliders[macroID].links do
            local link_t = DATA.parent_track.macro.sliders[macroID].links[linkID] 
            local note_layer_t= link_t.note_layer_t
            local note = note_layer_t.noteID or 0
            local layer = note_layer_t.layerID or 1
            local P_NAME = note_layer_t.P_NAME or ''
            -- name
            UI.Tools_setbuttonbackg()
            ImGui.Button(ctx, P_NAME..' [N'..note..' L'..layer..'] - '..DATA.parent_track.macro.sliders[macroID].links[linkID].param_name)
            UI.Tools_unsetbuttonstyle()
            
            
            ImGui.Indent(ctx,indent)
            
              --[[ offset
              ImGui.SetNextItemWidth(ctx, 80)
              local formatIn = math.floor(link_t.plink_offset*100)..'%%'
              local retval, v = ImGui_SliderDouble( ctx, 'Offset##offs'..linkID, link_t.plink_offset, -1, 1, formatIn )
              if retval then TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.offset', v) DATA.upd = true end 
              
              -- scale
              ImGui.SameLine(ctx)
              ImGui.SetNextItemWidth(ctx, 80)
              local formatIn = math.floor(link_t.plink_scale*100)..'%%'
              local retval, v = ImGui_SliderDouble( ctx, 'Scale##scale'..linkID, link_t.plink_scale, -1, 1, formatIn )
              if retval then TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.scale', v) DATA.upd = true end     
              ImGui.SameLine(ctx)]]
              
              
              
              -- min
              ImGui.SetNextItemWidth(ctx, 80)
              local retval, v = ImGui_SliderDouble( ctx, 'Min##UI_min'..linkID, link_t.UI_min, 0, 1, '%.3f' )
              if retval then
                v = VF_lim(v,link_t.UI_max)
                UI.draw_tabs_macro_links_SetParams(v,link_t.UI_max,link_t,note_layer_t)
                DATA.upd = true 
              end 
              -- max
              ImGui.SameLine(ctx)
              ImGui.SetNextItemWidth(ctx, 80)
              local retval, v = ImGui_SliderDouble( ctx, 'Max##UI_max'..linkID, link_t.UI_max, 0, 1, '%.3f' )
              if retval then 
                v = VF_lim(v)
                UI.draw_tabs_macro_links_SetParams(link_t.UI_min,v,link_t,note_layer_t)
                DATA.upd = true 
              end 
              
              -- min format
              local buf = link_t.UI_min 
              local noteT = link_t.note_layer_t
              local track = noteT.tr_ptr
              local retval, buf1 = reaper.TrackFX_FormatParamValue( track, link_t.fx_dest, link_t.param_dest, link_t.UI_min )
              if retval then 
                ImGui.SetNextItemWidth(ctx, 80)
                local retval, v = ImGui.InputText( ctx, 'Min##UI_minformat'..linkID, buf1, ImGui.InputTextFlags_None )
                if retval and v ~= '' then 
                  local valout = VF_BFpluginparam(v, track, link_t.fx_dest, link_t.param_dest)
                  if valout then 
                    UI.draw_tabs_macro_links_SetParams(valout,link_t.UI_max,link_t,note_layer_t)
                  end
                end
              end
              -- max format
              local buf = link_t.UI_max
              local noteT = link_t.note_layer_t
              local track = noteT.tr_ptr
              local retval, buf1 = reaper.TrackFX_FormatParamValue( track, link_t.fx_dest, link_t.param_dest, link_t.UI_max )
              if retval then 
                ImGui.SameLine(ctx)
                ImGui.SetNextItemWidth(ctx, 80)
                local retval, v = ImGui.InputText( ctx, 'Max##UI_maxformat'..linkID, buf1, ImGui.InputTextFlags_None )
                if retval and v ~= '' then 
                  local valout = VF_BFpluginparam(v, track, link_t.fx_dest, link_t.param_dest)
                  if valout then 
                    UI.draw_tabs_macro_links_SetParams(link_t.UI_min,valout,link_t,note_layer_t)
                  end
                end
              end
              
              
              
              -- remove
              if ImGui.Button(ctx, 'Remove##rem'..linkID) then
                Undo_BeginBlock2(DATA.proj )
                TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.active', 0)
                Undo_EndBlock2( DATA.proj , 'RS5k manager - Remove link', 0xFFFFFFFF ) 
                DATA.upd = true
              end
              
              -- Mod
              ImGui.SameLine(ctx)
              if ImGui.Button(ctx, 'Mod##modshow'..linkID) then
                TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'mod.visible', 1)
              end            
            
            ImGui.Unindent(ctx,indent)
            
            
          end
        end
      end 
      ImGui.Dummy(ctx,0,10)
      
      -- control actions
      if ImGui.Button(ctx,'Add last touched parameter') then 
        Undo_BeginBlock2(DATA.proj )
        DATA:Macro_AddLink()
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Macro - add link', 0xFFFFFFFF )
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx,'Clear all links') then 
        Undo_BeginBlock2(DATA.proj )
        DATA:Macro_ClearLink()
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Macro - clear links', 0xFFFFFFFF )
      end 
      
      ImGui.EndChild( ctx)
    end
    ImGui.PopStyleVar(ctx,2)
  end
  -----------------------------------------------------------------------------  
  function DATA:Macro_ConfirmLastTouchedParamIsChild()
    local t = VF_GetLTP()
    if not t then return end
    local note_out, layer_out
    local lt_TR_GUID = t.trGUID
    for note in pairs(DATA.children) do
      if DATA.children[note].TR_GUID then 
        if DATA.children[note].TR_GUID == lt_TR_GUID then 
          return true, DATA.children[note], t.fxnumber, t.paramnumber
        end
      end
      if DATA.children[note].layers then
        for layer in pairs(DATA.children[note].layers) do
          if DATA.children[note].layers[layer].TR_GUID and DATA.children[note].layers[layer].TR_GUID == lt_TR_GUID then
            return true, DATA.children[note].layers[layer], t.fxnumber, t.paramnumber
          end
        end
      end
    end
  end
  -----------------------------------------------------------------------------  
  function DATA:Macro_AddLink(srct0,fxnumber0,paramnumber0, offset0, scale0)
    DATA.upd = true
    -- validate stuff
      if DATA.parent_track.valid ~= true then return end 
      if not DATA.parent_track.ext.PARENT_LASTACTIVEMACRO then return end 
      if DATA.parent_track.ext.PARENT_LASTACTIVEMACRO == -1 then return end
    
    -- validate locals / last touched param
      local ret, srct, fxnumber, paramnumber = DATA:Macro_ConfirmLastTouchedParamIsChild()
      if not ret and not srct0 then 
        return 
       elseif (srct0 and fxnumber0 and paramnumber0) then
        srct, fxnumber, paramnumber = srct0, fxnumber0, paramnumber0
      end 
    
    -- init child macro
      if not srct.MACRO_pos then DATA:Macro_InitChildrenMacro(true, srct) fxnumber=fxnumber+1 end 
      
    -- link
      local param_src = tonumber(DATA.parent_track.ext.PARENT_LASTACTIVEMACRO)
      local fx_src = tonumber(srct.MACRO_pos)
      
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.active', 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.scale', scale0 or 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.offset', offset0 or 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.effect',fx_src)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.param', param_src)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_bus', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_chan', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_msg', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_msg2', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.mod.active', 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.mod.visible', 0)
  end
  
  -----------------------------------------------------------------------  
  function DATA:Macro_InitChildrenMacro(child_mode, srct)
    --if DATA.parent_track.macro.valid == true and not child_mode then return end
    
    local fxname = 'mpl_RS5k_manager_MacroControls.jsfx'
    
    -- master
    if not child_mode then
      local macroJSFX_pos =  TrackFX_AddByName( DATA.parent_track.ptr, fxname, false, 0 )
      if macroJSFX_pos == -1 then
        macroJSFX_pos =  TrackFX_AddByName( DATA.parent_track.ptr, fxname, false, -1000 ) 
        local macroJSFX_fxGUID = reaper.TrackFX_GetFXGUID( DATA.parent_track.ptr, macroJSFX_pos ) 
        DATA.parent_track.ext.PARENT_MACRO_GUID =macroJSFX_fxGUID
        DATA:WriteData_Parent()
        TrackFX_Show( DATA.parent_track.ptr, macroJSFX_pos, 0|2 )
        for i = 1, 16 do TrackFX_SetParamNormalized( DATA.parent_track.ptr, macroJSFX_pos, 33+i, i/1024 ) end -- init source gmem IDs
      end
      return macroJSFX_pos
    end
    
    
    -- child_mode
    if child_mode == true then 
      if not srct then return end
      if not srct.MACRO_pos then
        macroJSFX_pos =  TrackFX_AddByName( srct.tr_ptr, fxname, false, -1000 )
        if macroJSFX_pos == -1 then return end --MB('RS5k manager_MacroControls JSFX is missing. Make sure you installed it correctly via ReaPack.', '', 0) end
        local macroJSFX_fxGUID = reaper.TrackFX_GetFXGUID( srct.tr_ptr, macroJSFX_pos )  
        TrackFX_Show( srct.tr_ptr, macroJSFX_pos, 0|2 )
        TrackFX_SetParamNormalized( srct.tr_ptr, macroJSFX_pos, 0, 1 ) -- set mode to slave
        for i = 1, 16 do TrackFX_SetParamNormalized( srct.tr_ptr, macroJSFX_pos, 17+i, i/1024 ) end -- ini source gmem IDs
        DATA:WriteData_Child(srct.tr_ptr, {MACRO_GUID=macroJSFX_fxGUID})
        srct.MACRO_pos = macroJSFX_pos
        return macroJSFX_pos
      end
    end
    
  end
  -----------------------------------------------------------------------  
  function DATA:Macro_ClearLink()
    if not (DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO) then return end 
    local macroID = DATA.parent_track.ext.PARENT_LASTACTIVEMACRO
    if not DATA.parent_track.macro.sliders[macroID].links then return end
    for link = #DATA.parent_track.macro.sliders[macroID].links, 1, -1 do
      local tmacro = DATA.parent_track.macro.sliders[macroID].links[link]
      TrackFX_SetNamedConfigParm(tmacro.note_layer_t.tr_ptr, tmacro.fx_dest, 'param.'..tmacro.param_dest..'plink.active', 0) 
    end
        
  end
    ------------------------------------------------------------------------------ 
  function UI.draw_knob(knob_t)
    local debug = 0
    local x,y,w,h = knob_t.x,knob_t.y,knob_t.w,knob_t.h
    local name  = knob_t.name 
    local disabled  = knob_t.disabled 
    local val_form  = knob_t.val_form or '' 
    local str_id  = knob_t.str_id 
    ImGui.SetCursorScreenPos(ctx,x,y) 
    local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX, UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,UI.spacingY) 
    
    -- size 
      local knobname_h = UI.calc_itemH
      local knobctrl_h = h- knobname_h-      UI.spacingY
      if knob_t.is_small_knob == true then 
        ImGui.PushFont(ctx, DATA.font3) 
        knobname_h = UI.calc_itemH
        knobctrl_h = h- knobname_h-UI.spacingY -UI.calc_itemH
      end
      
    -- name background 
      local color
      if knob_t and knob_t.I_CUSTOMCOLOR then 
        color = ImGui.ColorConvertNative(knob_t.I_CUSTOMCOLOR) 
        color = color & 0x1000000 ~= 0 and (color << 8) | 0xFF-- https://forum.cockos.com/showpost.php?p=2799017&postcount=6
      end
      if knob_t and knob_t.colfill_rgb then color = (knob_t.colfill_rgb << 8) | 0xFF end


      if color then 
        ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+knobname_h, color, 5, ImGui.DrawFlags_RoundCornersTop)
       else 
        if knob_t.active_name == true then
          ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+knobname_h, UI.colRGBA_paddefaultbackgr, 5, ImGui.DrawFlags_RoundCornersTop) 
         else
          ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+knobname_h, UI.colRGBA_paddefaultbackgr_inactive, 5, ImGui.DrawFlags_RoundCornersTop) 
        end
      end   
      
      
    -- frame / selection  
      if knob_t.is_selected == true  then 
        ImGui.DrawList_AddRect( UI.draw_list, x, y, x+w, y+h, UI.colRGBA_selectionrect, 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
       else
        ImGui.DrawList_AddRect( UI.draw_list, x, y, x+w, y+h, 0x0000005F              , 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
      end  
      
      
      if debug ~= 1 then UI.Tools_setbuttonbackg() end
      
      
      local local_pos_x, local_pos_y = ImGui.GetCursorPos( ctx )
      
    -- name  
      ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y )
      ImGui.Button(ctx,'##slider_name'..str_id,w ,knobname_h ) 
      if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left)then
        if knob_t.appfunc_atclick_name then knob_t.appfunc_atclick_name() end
      end
      if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right)then
        if knob_t.appfunc_atclick_nameR then knob_t.appfunc_atclick_nameR() end
      end
      
    -- control
      ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y+knobname_h )
      ImGui.Button(ctx,'##slider_name2'..str_id,w ,knobctrl_h) 
      UI.draw_knob_handlelatchstate(knob_t)
      local item_w, item_h = reaper.ImGui_GetItemRectSize( ctx )
      
      
       
    
    local val =  0
    if knob_t.val and knob_t.val then val = knob_t.val end
    if not val then return end
    local draw_list = UI.draw_list
    local roundingIn = 0
    local col_rgba = 0xF0F0F0FF
    
    local radius = math.floor(math.min(item_w, item_h )/2)
    local radius_draw = math.floor(0.8 * radius)
    local center_x = curposx + item_w/2--radius
    local center_y = curposy + item_h/2  + knobname_h
    local ang_min = -220
    local ang_max = 40
    local ang_val = ang_min + math.floor((ang_max - ang_min)*val)
    local radiusshift_y = (radius_draw- radius)
    
    -- filled arc
    ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
    ImGui.DrawList_PathStroke(draw_list, 0xF0F0F02F,  ImGui.DrawFlags_None, 2)
    
    if not disabled == true then 
      -- back arc
      ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
      ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
      -- value
      local radius_draw2 = radius_draw
      local radius_draw3 = radius_draw-6
      ImGui.DrawList_PathClear(draw_list)
      ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
      ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
      ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
    end
    
    -- text
      ImGui.SetCursorPos( ctx, local_pos_x+UI.spacingX, local_pos_y+UI.spacingY )
      ImGui.TextWrapped( ctx, name )
    
    if not disabled == true then 
    -- format value
      ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y+h-UI.calc_itemH-UI.spacingY )
      local formatval_str_id = '##slider_formatval'..str_id
      if not (DATA.knob_strid_input and DATA.knob_strid_input  == formatval_str_id ) then 
        ImGui.Button(ctx,val_form..formatval_str_id,w ,UI.calc_itemH )
       else
        ImGui.SetNextItemWidth(ctx ,w)
        ImGui.SetKeyboardFocusHere( ctx, 0 )
        local retval, buf = ImGui.InputText( ctx, formatval_str_id, val_form, ImGui.InputTextFlags_None|ImGui.InputTextFlags_AutoSelectAll|ImGui.InputTextFlags_EnterReturnsTrue )
        if retval then
          if knob_t.parseinput then knob_t.parseinput(buf) end
          DATA.knob_strid_input = nil
        end
        
      end
      if knob_t.parseinput and ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui.IsMouseDoubleClicked( ctx, ImGui.MouseButton_Left ) then
        DATA.knob_strid_input = '##slider_formatval'..str_id
      end
      
    end
    
    ImGui.SetCursorScreenPos(ctx, curposx, curposy)
    ImGui.Dummy(ctx,knob_t.w,  knob_t.h)
    if debug ~= 1 then UI.Tools_unsetbuttonstyle() end
    ImGui.PopStyleVar(ctx,2) 
    if knob_t.is_small_knob == true then 
      ImGui.PopFont(ctx) 
    end
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_knob_handlelatchstate(t)  
    local paramval = t.val or 0
    
    -- trig
    if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
      DATA.temp_latchstate = paramval  
      if t.appfunc_atclick then t.appfunc_atclick() end
      return 
    end
    
    if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
      DATA.temp_latchstate = paramval 
      if t.appfunc_atclickR then t.appfunc_atclickR() end
      return 
    end

    
    -- drag
    if  ImGui.IsItemActive( ctx ) then
      local x, y = ImGui.GetMouseDragDelta( ctx )
      local outval = DATA.temp_latchstate - y/(t.knob_resY or UI.knob_resY)
      outval = math.max(0,math.min(outval,1))
      local dx, dy = ImGui.GetMouseDelta( ctx )
      if dy~=0 then
        if t.appfunc_atdrag then t.appfunc_atdrag(outval) end
      end
    end
    
    if ImGui.IsItemDeactivated( ctx ) then
      if t.appfunc_atrelease then t.appfunc_atrelease() DATA.upd = true end
    end
    
  end
  -------------------------------------------------------------------------------- 
  function UI.HelpMarker(desc)
    ImGui.TextDisabled(ctx, '(?)')
    if ImGui.BeginItemTooltip(ctx) then
      ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
      ImGui.Text(ctx, desc)
      ImGui.PopTextWrapPos(ctx)
      ImGui.EndTooltip(ctx)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw()  
    if DATA.VCA_mode == 0 then 
      UI.knob_handle  = UI.knob_handle_normal 
     elseif DATA.VCA_mode == 1 then 
      UI.knob_handle = UI.knob_handle_vca
     elseif DATA.VCA_mode == 2 then 
      UI.knob_handle = UI.knob_handle_vca2       
    end
    UI.draw_Rack() 
    ImGui.SameLine(ctx)
    UI.draw_tabs()
    
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler()
    local note_layer_t, note, layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end 
    
    -- name
    local name = DATA.children[note].P_NAME
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0,0.5)
    UI.Tools_setbuttonbackg()
    ImGui.SetNextItemWidth(ctx, 170)
    if DATA.children[note].TYPE_DEVICE == true then ImGui.SetNextItemWidth(ctx, 140) end
    local retval, buf = reaper.ImGui_InputText( ctx, '##sampler_activename', name, ImGui.InputTextFlags_EnterReturnsTrue )
    if retval then
      if DATA.children[note].TYPE_DEVICE == true then 
        GetSetMediaTrackInfo_String( DATA.children[note].tr_ptr, 'P_NAME', buf, true )
       else
        GetSetMediaTrackInfo_String( note_layer_t.tr_ptr, 'P_NAME', buf, true )
      end
      DATA.upd = true
    end
    UI.Tools_unsetbuttonstyle()
    ImGui.PopStyleVar(ctx)
    
    -- device fx
      if DATA.children[note].TYPE_DEVICE == true then 
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'FX##device_fx',30) then TrackFX_Show( DATA.children[note].tr_ptr,0, 1 ) end
      end
    
    ImGui.SameLine(ctx)
    local col_rgb  = DATA.children[note].I_CUSTOMCOLOR 
    
    col_rgb = ImGui.ColorConvertNative(col_rgb)
    local col_rgba = (col_rgb << 8) | 0xFF--col_rgb & 0x1000000 ~= 0 and 
    if col_rgb & 0x1000000 == 0 then col_rgba = 0x5F5F5FFF end
    --local r, g, b = reaper.ColorFromNative( col_rgb )
    --local col_rgba = r<<24|g<<16|b<<8|0xFF
    if col_rgba then 
      local retval, col_rgba = ImGui.ColorEdit4( ctx, '##coloreditpad', col_rgba, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs)--|ImGui.ColorEditFlags_NoAlpha )
      if retval then 
        local r, g, b = (col_rgba>>24)&0xFF, (col_rgba>>16)&0xFF, (col_rgba>>8)&0xFF
        col_rgb = ColorToNative( r, g, b )
        DATA.children[note].I_CUSTOMCOLOR  = col_rgb
        SetMediaTrackInfo_Value( note_layer_t.tr_ptr, 'I_CUSTOMCOLOR', col_rgb|0x1000000 )
        DATA.upd = true
      end
    end
    
    ImGui.SameLine(ctx)
    
    -- layer selector
    local layerselectW = 150
    if DATA.children[note] and DATA.children[note].TYPE_DEVICE==true and layer ~= 0 then
      ImGui.SameLine(ctx)
      preview_value = string.format('%02d',layer)..' '..note_layer_t.P_NAME
      ImGui.SetNextItemWidth(ctx, layerselectW)
      if ImGui.BeginCombo( ctx, '##layerselect', preview_value, ImGui.ComboFlags_None ) then
        for layerID = 1, #DATA.children[note].layers do
          if ImGui.Selectable(ctx, string.format('%02d',layerID)..' '..DATA.children[note].layers[layerID].P_NAME..'##layers_selectorNsame'..layerID,layerID == layer, ImGui.SelectableFlags_None) then
            DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER = layerID
            DATA:WriteData_Parent()
            DATA.upd = true
          end
        end
        ImGui.EndCombo( ctx )
      end 
      ImGui.SameLine(ctx)
     else
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx,layerselectW,0)
      ImGui.SameLine(ctx)
    end
      
    -- fx
    if layer ~= 0 then 
      if ImGui.Button(ctx, 'FX##sampler_fx',-1) then TrackFX_Show( note_layer_t.tr_ptr, note_layer_t.instrument_pos or 0, 1 ) end
     else
      ImGui.Dummy(ctx,0,0)
    end
    
    -- peaks
    UI.Tools_setbuttonbackg()
    local plotx, ploty = ImGui.GetCursorPos( ctx)
    local plotx_abs, ploty_abs = ImGui.GetCursorScreenPos( ctx )
    ImGui.Button(ctx, '##sampler_peaks',-1, UI.sampler_peaksH) 
    if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left) and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then DATA:Sampler_StuffNoteOn(DATA.parent_track.ext.PARENT_LASTACTIVENOTE) end
    if ImGui.IsItemDeactivated(ctx) and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then DATA:Sampler_StuffNoteOn(DATA.parent_track.ext.PARENT_LASTACTIVENOTE, 0 , true) end
    if ImGui.BeginDragDropTarget( ctx ) then  
      DATA:Drop_UI_interaction_sampler() 
      ImGui_EndDragDropTarget( ctx )
    end
    
    if DATA.current_sample_peaks and DATA.current_sample_peaks.arr then UI.draw_peaks('cur',note_layer_t,plotx_abs, ploty_abs,-1, UI.sampler_peaksH, DATA.current_sample_peaks.arr ) end
    UI.Tools_unsetbuttonstyle()
    --
    ImGui.SetCursorPos( ctx, plotx, ploty+UI.sampler_peaksH )
    UI.draw_tabs_Sampler_tabs()
  end
  --------------------------------------------------------------------------------
  function UI.draw_peaks (id,note_layer_t,plotx_abs,ploty_abs,w,h, arr) 
    --if h < UI.controls_minH then return end
    if EXT.CONF_showpadpeaks == 0 and not id:match('cur') then return end
    ImGui.SetCursorScreenPos( ctx, plotx_abs, ploty_abs )
    ImGui.PushStyleColor(ctx,ImGui.Col_FrameBg,0)
    ImGui.PushStyleColor(ctx,ImGui.Col_PlotHistogram,0xF0F0F0BF)
    if not arr then return end
    
    local size = arr.get_alloc()
    local size_new = math.floor(size/2)-1
    local t1 = arr.table(1,size_new)
    local t2 = arr.table(size_new+2,size_new)
    local arr1 = new_array(t1)
    local arr2 = new_array(t2) 
    
    ImGui.PlotHistogram( ctx, '##sampler_peaks_plot'..id, arr1, 0,  '', -1, 1,w,h)
    ImGui.SetCursorScreenPos( ctx, plotx_abs, ploty_abs )
    ImGui.PlotHistogram( ctx, '##sampler_peaks_plot2'..id, arr2, 0,  '', -1, 1, w,h)  
    arr1.clear()
    arr2.clear()
    ImGui.PopStyleColor(ctx,2)
    
    
    --ImGui.PlotHistogram( ctx, '##sampler_peaks_plot'..id, arr2, 0,  '', -1, 1, w,h)  
    if note_layer_t and note_layer_t.instrument_filename then ImGui.SetItemTooltip(ctx, note_layer_t.instrument_filename) end
    local plotw, ploth = reaper.ImGui_GetItemRectSize( ctx )
    
    if not id:match('cur') then return end
    if not (DATA.current_sample_peaks.offs_start == 0 and DATA.current_sample_peaks.offs_end == 1 ) then 
      local p_min_x, p_min_y, p_max_x, p_max_y = plotx_abs + plotw * DATA.current_sample_peaks.offs_start, ploty_abs,plotx_abs + plotw * DATA.current_sample_peaks.offs_end, ploty_abs+ploth
      ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, UI.col_maintheme<<8|0x30, 2, ImGui.DrawFlags_None )
    end 
    if DATA.current_sample_peaks.instrument_loopoffs_norm > 0 and DATA.current_sample_peaks.instrument_loopoffs_norm <1 then
      local p_min_x, p_min_y, p_max_x, p_max_y = plotx_abs + plotw * (DATA.current_sample_peaks.offs_start + (DATA.current_sample_peaks.offs_end - DATA.current_sample_peaks.offs_start) * DATA.current_sample_peaks.instrument_loopoffs_norm), ploty_abs,plotx_abs + plotw * DATA.current_sample_peaks.offs_end, ploty_abs+10
      ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, UI.col_maintheme<<8|0x50, 2, ImGui.DrawFlags_None )
    end 
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_tabs()
    if ImGui.BeginTabBar( ctx, 'tabsbar_sampler', ImGui.TabItemFlags_None ) then 
      local note_layer_t = DATA:Sampler_GetActiveNoteLayer()
      if note_layer_t then
        if note_layer_t.ISRS5K then
          if ImGui.BeginTabItem( ctx, 'General', false, ImGui.TabItemFlags_None ) then        UI.draw_tabs_Sampler_tabs_rs5kcontrols()ImGui.EndTabItem( ctx) end
          if ImGui.BeginTabItem( ctx, 'Sample', false, ImGui.TabItemFlags_None ) then         UI.draw_tabs_Sampler_tabs_sample()      ImGui.EndTabItem( ctx) end 
          if ImGui.BeginTabItem( ctx, 'Boundary', false, ImGui.TabItemFlags_None ) then       UI.draw_tabs_Sampler_tabs_boundary()    ImGui.EndTabItem( ctx) end 
          if ImGui.BeginTabItem( ctx, 'FX', false, ImGui.TabItemFlags_None ) then             UI.draw_tabs_Sampler_tabs_FX()          ImGui.EndTabItem( ctx) end   
          if ImGui.BeginTabItem( ctx, 'Device', false, ImGui.TabItemFlags_None ) then         UI.draw_tabs_Sampler_tabs_device()      ImGui.EndTabItem( ctx) end
         else
          if ImGui.BeginTabItem( ctx, 'General (3rd party)', false, ImGui.TabItemFlags_None ) then        UI.draw_tabs_Sampler_tabs_3rdpartycontrols()ImGui.EndTabItem( ctx) end
          if ImGui.BeginTabItem( ctx, 'FX', false, ImGui.TabItemFlags_None ) then             UI.draw_tabs_Sampler_tabs_FX()          ImGui.EndTabItem( ctx) end 
          if ImGui.BeginTabItem( ctx, 'Device', false, ImGui.TabItemFlags_None ) then         UI.draw_tabs_Sampler_tabs_device()      ImGui.EndTabItem( ctx) end
        end
      end
      
      ImGui.EndTabBar( ctx)
    end
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_tabs_boundary()
    local note_layer_t = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if note_layer_t.TYPE_DEVICE== true then return end
    
    
    local curposx_abs, curposy_abs = ImGui.GetCursorScreenPos(ctx)
    
    UI.draw_knob(
      {str_id = '##spl_stoffs',
      is_small_knob = true,
      val = note_layer_t.instrument_samplestoffs,
      x = curposx_abs , 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Start',
      knob_resY = 1000,
      val_form = note_layer_t.instrument_samplestoffs_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_samplestoffs =v 
        if DATA.current_sample_peaks then DATA.current_sample_peaks.offs_start = v end
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_samplestoffsID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })
      
    UI.draw_knob(
      {str_id = '##spl_endoffs',
      is_small_knob = true,
      val = note_layer_t.instrument_sampleendoffs,
      x = curposx_abs + UI.calc_knob_w_small + UI.spacingX, 
      y = curposy_abs,
      w = UI.calc_knob_w_small ,
      h = UI.calc_knob_h_small,
      name = 'End',
      knob_resY = 1000,
      val_form = note_layer_t.instrument_sampleendoffs_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_samplestoffs =v 
        if DATA.current_sample_peaks then DATA.current_sample_peaks.offs_end = v end
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sampleendoffsID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })   
      
      
    UI.draw_knob(
      {str_id = '##spl_loopoffs',
      is_small_knob = true,
      val = note_layer_t.instrument_loopoffs_norm,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*2, 
      y = curposy_abs,
      w = UI.calc_knob_w_small ,
      h = UI.calc_knob_h_small,
      name = 'Loop',
      val_form = note_layer_t.instrument_loopoffs_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_loopoffsoffs =v *note_layer_t.instrument_loopoffs_max
        if DATA.current_sample_peaks then DATA.current_sample_peaks.instrument_loopoffs_norm = v end
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_loopoffsID, v* note_layer_t.instrument_loopoffs_max  )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })   
      

      
      ImGui.SetCursorScreenPos(ctx, curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*3, curposy_abs)
      -- loop
      local retval, v = ImGui.Checkbox( ctx, 'Loop', note_layer_t.instrument_loop==1 )
      if retval then TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 12, note_layer_t.instrument_loop~1 ) DATA.upd = true end
      
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx, UI.spacingX*5,0)
      ImGui.SameLine(ctx)
      -- instrument_noteoff
      local retval, v = ImGui.Checkbox( ctx, 'Obey note-off', note_layer_t.instrument_noteoff==1 )
      if retval then TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 11, note_layer_t.instrument_noteoff~1 ) DATA.upd = true end
      
      ImGui.SetCursorScreenPos(ctx, curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*3, curposy_abs + UI.calc_itemH+ UI.spacingY)
      if ImGui.Button( ctx, 'Crop sample') then DATA:Sampler_CropToAudibleBoundaries() end
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, 70) 
      local ret, v = ImGui.SliderDouble( ctx, 'Threshold##cropsplthresh', EXT.CONF_cropthreshold, -80, -20, '%.0f dB', ImGui.SliderFlags_None ) if ret then EXT.CONF_cropthreshold = v EXT:save() end  -- Sampler: Crop threshold
      
      ImGui.SetCursorScreenPos(ctx, curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*3, curposy_abs + (UI.calc_itemH+ UI.spacingY)*2)
      if ImGui.Button( ctx, 'Set start offset to a loudest peak',-1) then DATA:Sampler_SetStartToLoudestPeak()  end
      
      --ImGui.EndCombo( ctx )
    --end      
      
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_tabs_sample()
    local note_layer_t = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if note_layer_t.TYPE_DEVICE== true then return end
    
    ImGui.Dummy(ctx,0,0)
    
    if ImGui.Button(ctx, '< Previous spl',UI.calc_sampler4ctrl_W) then DATA:Sampler_NextPrevSample(note_layer_t, 1) end 
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Next spl >',UI.calc_sampler4ctrl_W) then DATA:Sampler_NextPrevSample(note_layer_t, 0) end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Random spl',UI.calc_sampler4ctrl_W) then DATA:Sampler_NextPrevSample(note_layer_t, 2) end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'MediaExplorer',UI.calc_sampler4ctrl_W) then  DATA:Sampler_ShowME() ImGui.CloseCurrentPopup(ctx) end
    
    
    -- database stuff
    local retval, v = ImGui.Checkbox( ctx, 'Use database', note_layer_t.SET_useDB&1==1 )
    if retval then 
      DATA:CollectData_ParseREAPERDB()
      DATA:WriteData_Child(note_layer_t.tr_ptr, { SET_useDB = note_layer_t.SET_useDB~1, SET_useDB_lastID = 0, })  
      DATA.upd = true 
    end 
    
    
    if note_layer_t.SET_useDB&1==1 then  
      -- select db
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, -1)
      if ImGui.BeginCombo( ctx, '##dbselect', note_layer_t.SET_useDB_name, ImGui.ComboFlags_None ) then
        for dbname in pairs(DATA.reaperDB) do
          if ImGui.Selectable( ctx, dbname, false, ImGui.SelectableFlags_None) then 
            DATA:WriteData_Child(note_layer_t.tr_ptr, {SET_useDB_name = dbname})  
            DATA.upd = true 
          end
        end
        ImGui.EndCombo( ctx )
      end
      
      -- lock
      local retval, v = ImGui.Checkbox( ctx, 'Lock from "New random kit" action', note_layer_t.SET_useDB&2==2 )
      if retval then 
        DATA:WriteData_Child(note_layer_t.tr_ptr, {SET_useDB = note_layer_t.SET_useDB~2})  
        DATA.upd = true 
      end
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx,UI.spacingX,40)
      --ImGui.SameLine(ctx)
      
      -- new kit
      ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xFF000050)
      if ImGui.Button(ctx, 'New random database kit',-30) then  
        Undo_BeginBlock2(DATA.proj )
        DATA:Sampler_NewRandomKit()
        Undo_EndBlock2( DATA.proj , 'RS5k manager - New kit', 0xFFFFFFFF )
      end
      ImGui.PopStyleColor(ctx)
      ImGui.SameLine(ctx)
      UI.HelpMarker('Randomize ALL samples linked to databases in current rack') 
    end
    
  end
  -----------------------------------------------------------------------------------------  
  function UI.draw_tabs_Sampler_tabs_FX()
    local note_layer_t, note = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if note_layer_t.TYPE_DEVICE== true then return end
    local curposx_abs, curposy_abs = ImGui.GetCursorScreenPos(ctx)
     
    UI.draw_knob(
      {str_id = '##note_layer_fx_reaeq_cut',
      is_small_knob = true,
      val = note_layer_t.fx_reaeq_cut,
      x = curposx_abs, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Freq',
      --knob_resY = 10000,
      val_form = note_layer_t.fx_reaeq_cut_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        DATA:Validate_InitFilterDrive(note_layer_t) 
        if note_layer_t.fx_reaeq_pos then 
          note_layer_t.fx_reaeq_cut =v 
          TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 0, v ) 
          DATA:CollectData_Children_FXParams(note_layer_t)  
        end
      end,
      }) 
    
    UI.draw_knob(
      {str_id = '##note_layer_fx_reaeq_gain', 
      is_small_knob = true,
      val =note_layer_t.fx_reaeq_gain,
      x = curposx_abs + UI.calc_knob_w_small + UI.spacingX, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Gain',
      --knob_resY = 10000,
      disabled = true,--(note_layer_t.fx_reaeq_bandtype == -1  or note_layer_t.fx_reaeq_bandtype == 3 or note_layer_t.fx_reaeq_bandtype == 4),
      val_form = note_layer_t.fx_reaeq_gain_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        DATA:Validate_InitFilterDrive(note_layer_t) 
        if note_layer_t.fx_reaeq_pos then 
          note_layer_t.fx_reaeq_gain =v 
          TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 1, v ) 
          DATA:CollectData_Children_FXParams(note_layer_t)  
        end
      end,
      })

    -- filter
    ImGui.SetCursorScreenPos(ctx,curposx_abs, curposy_abs+ UI.calc_knob_h_small+UI.spacingY)
    
    ImGui.SetNextItemWidth(ctx, UI.calc_knob_w_small*2+UI.spacingX)
    local preview_value = 'Filter OFF'
    if note_layer_t.fx_reaeq_bandenabled == true  then  preview_value = DATA.bandtypemap[note_layer_t.fx_reaeq_bandtype] end
    if ImGui.BeginCombo( ctx, '##filter', preview_value, ImGui.ComboFlags_None ) then
      for band_type_val in spairs(DATA.bandtypemap) do
        local label = DATA.bandtypemap[band_type_val]
        if ImGui.Selectable( ctx, label, p_selected, ImGui.SelectableFlags_None ) then
          DATA:Validate_InitFilterDrive(note_layer_t) 
          if note_layer_t.fx_reaeq_pos then 
            if band_type_val == -1 then 
              TrackFX_SetNamedConfigParm( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 'BANDENABLED0', 0 )
             else
              TrackFX_SetNamedConfigParm( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 'BANDTYPE0', band_type_val )
              TrackFX_SetNamedConfigParm( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 'BANDENABLED0', 1 )
            end
          end
          DATA.upd = true
        end
      end
      ImGui.EndCombo( ctx)
    end
  
    UI.draw_knob(
      {str_id = '##note_layer_fx_ws_drive', 
      is_small_knob = true,
      val =note_layer_t.fx_ws_drive,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*2, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Drive',
      --knob_resY = 10000,
      val_form = note_layer_t.fx_ws_drive_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        DATA:Validate_InitFilterDrive(note_layer_t) 
        if note_layer_t.fx_ws_pos then 
          note_layer_t.fx_ws_drive =v 
          TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.fx_ws_pos, 0, v ) 
          DATA:CollectData_Children_FXParams(note_layer_t)  
        end
      end,
      })
    
    
    
    
    
    -- choke flags
    for groupID = 1, EXT.CONF_chokegr_limit do
      local byte = 1<<(groupID-1)
      ImGui.SetCursorScreenPos(ctx,curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*4, curposy_abs + (UI.calc_itemH + UI.spacingY)*(groupID-1))
      local retval, v = ImGui.Checkbox( ctx, 'Choke group '..groupID, DATA.MIDIbus.CHOKE_flags[note]&byte==byte )
      if retval then 
        DATA.MIDIbus.CHOKE_flags[note] = DATA.MIDIbus.CHOKE_flags[note]~byte
        DATA:WriteData_UpdateChoke()
      end
      local tooltip = ''
      for i = 0, 127 do 
        if DATA.MIDIbus.CHOKE_flags[i]&byte==byte and DATA.children[i]then
          tooltip = tooltip..string.format('%02d',i)..' '..DATA.children[i].P_NAME..'\n'
        end
      end
      if tooltip ~= '' then 
        ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,          UI.Tools_RGBA(UI.col_popup, 1) )
        ImGui.SetItemTooltip( ctx, tooltip ) 
        ImGui.PopStyleColor(ctx )
      end
    end
    
  end
  -----------------------------------------------------------------------------------------    
  function UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA(str_id,v,note_layer_t,note,layer,follow)
    if DATA.VCA_mode == 0 then return end
    
    
    local diff = v - note_layer_t['instrument_'..str_id]
    
    for note0 in pairs(DATA.children) do
      if DATA.children[note0].layers then 
        for layer0  = 1, #DATA.children[note0].layers do
        
          local tweak
          if DATA.VCA_mode &1==1 then tweak = true end -- tweak everything
          if tweak~=true and DATA.VCA_mode &2==2 and (note0 == note) then tweak  = true end -- tweak all layers match source note
          
          if tweak == true and (note0 == note and layer0 == layer) then tweak = false end -- prevent setting source param
          if tweak~=true then goto nextlayer end
          

          note_layer_t0 = DATA.children[note0].layers[layer0]
          note_layer_t0['instrument_'..str_id] =note_layer_t0['instrument_'..str_id] + diff  
          if not follow then 
            TrackFX_SetParamNormalized( note_layer_t0.tr_ptr, note_layer_t0.instrument_pos, note_layer_t0['instrument_'..str_id..'ID'], note_layer_t0['instrument_'..str_id] + diff)  
           else
            
            local out = v--note_layer_t['instrument_'..str_id]
            if str_id == 'attack' or str_id == 'decay' or str_id == 'release' then out = out / 10 end
            TrackFX_SetParamNormalized( note_layer_t0.tr_ptr, note_layer_t0.instrument_pos, note_layer_t0['instrument_'..str_id..'ID'], out)  
          end
          
          ::nextlayer::
        end
      end
    end 
  end
    ----------------------------------------------------------------------------------------- 
  function UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(x,y,note_layer_t,key)
    if not (note_layer_t and note_layer_t.instrument_fx_name) then return end
    local fx_name = note_layer_t.instrument_fx_name
    local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
    
    if not retval then return end
    
    ImGui.SetCursorScreenPos(ctx, x,y)
    if ImGui.Button(ctx, 'Link##'..key, UI.calc_knob_w_small) then
      if not DATA.plugin_mapping[fx_name] then DATA.plugin_mapping[fx_name] = {} end
      DATA.plugin_mapping[fx_name][key] = parm
      DATA:CollectData_PluginParametersMapping_Set() 
      DATA.upd = true
    end
    --
    --DATA.plugin_mapping
  end
  ------------------------------------------------------------------------------------------   
  function DATA:CollectData_PluginParametersMapping_Get() 
    DATA.plugin_mapping = table.loadstring(VF_decBase64(EXT.CONF_plugin_mapping_b64)) or {}
  end
  ------------------------------------------------------------------------------------------   
  function DATA:CollectData_PluginParametersMapping_Set() 
    EXT.CONF_plugin_mapping_b64 = VF_encBase64(table.savestring(DATA.plugin_mapping))
    EXT:save()
  end
    ----------------------------------------------------------------------------------------- 
  function UI.draw_tabs_Sampler_tabs_3rdpartycontrols()
    local note_layer_t,note,layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if not note_layer_t.instrument_pos then return end
    if note_layer_t.ISRS5K then return end
    local curposx_abs, curposy_abs = ImGui.GetCursorScreenPos(ctx)
    
    UI.draw_knob(
      {str_id = '##spl_vol',
      is_small_knob = true,
      val = note_layer_t.instrument_vol,
      x = curposx_abs, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Gain',
      val_form = note_layer_t.instrument_vol_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v)  
        if not note_layer_t.instrument_volID then return end
        note_layer_t.instrument_vol =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not note_layer_t.instrument_volID then return end
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID)
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_volID')
    
    local xpos = curposx_abs + UI.calc_knob_w_small + UI.spacingX
    UI.draw_knob(
      {str_id = '##note_layer_tune',
      is_small_knob = true,
      val = note_layer_t.instrument_tune,
      x = xpos, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Tune',
      knob_resY = 10000,
      val_form = note_layer_t.instrument_tune_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_tuneID then return end
        note_layer_t.instrument_tune =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_tuneID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })  
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(xpos,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_tuneID')
    
    UI.draw_knob(
      {str_id = '##note_layer_instrument_attack',
      is_small_knob = true,
      val = note_layer_t.instrument_attack,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*3, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Attack',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_attack_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_attackID then return end
        note_layer_t.instrument_attack =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID, v)    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_attackID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*3,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_attackID')
    
    UI.draw_knob(
      {str_id = '##note_layer_instrument_decay',
      is_small_knob = true,
      val = note_layer_t.instrument_decay,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*4, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Decay',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_decay_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_decayID then return end
        note_layer_t.instrument_decay =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_decayID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*4,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_decayID')
        
    UI.draw_knob(
      {str_id = '##note_layer_instrument_sustain',
      is_small_knob = true,
      val = note_layer_t.instrument_sustain,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*5, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Sustain',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_sustain_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_sustainID then return end
        note_layer_t.instrument_sustain =v
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v)    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_sustainID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*5,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_sustainID')
    
    UI.draw_knob(
      {str_id = '##note_layer_instrument_release',
      is_small_knob = true,
      val = note_layer_t.instrument_release,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*6, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Release',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_release_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_releaseID then return end
        note_layer_t.instrument_release =v
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_releaseID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*6,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_releaseID')
  end  
    ----------------------------------------------------------------------------------------- 
  function UI.draw_tabs_Sampler_tabs_rs5kcontrols()
    local note_layer_t,note,layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if not note_layer_t.instrument_pos then return end
    if not note_layer_t.ISRS5K then return end
    local curposx_abs, curposy_abs = ImGui.GetCursorScreenPos(ctx)
    
    UI.draw_knob(
      {str_id = '##spl_vol',
      is_small_knob = true,
      val = note_layer_t.instrument_vol,
      x = curposx_abs, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Gain',
      val_form = note_layer_t.instrument_vol_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v)  
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('vol',v,note_layer_t,note,layer,true) 
        note_layer_t.instrument_vol =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
        
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID)
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('vol',v,note_layer_t,note,layer,true)
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })
      
    UI.draw_knob(
      {str_id = '##note_layer_tune',
      is_small_knob = true,
      val = note_layer_t.instrument_tune,
      x = curposx_abs + UI.calc_knob_w_small + UI.spacingX, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Tune',
      knob_resY = 10000,
      val_form = note_layer_t.instrument_tune_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('tune',v,note_layer_t,note,layer) 
        note_layer_t.instrument_tune =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID) 
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('tune',v,note_layer_t,note,layer) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })  
    
    if ImGui.Checkbox(ctx, 'Tweak ALL samples ',(DATA.VCA_mode or 0 )&1==1) then DATA.VCA_mode = (DATA.VCA_mode or 0 )~1 end
    if ImGui.Checkbox(ctx, 'Tweak ony current pad layers',(DATA.VCA_mode or 0 )&2==2 or (DATA.VCA_mode or 0 )&1==1) then DATA.VCA_mode = (DATA.VCA_mode or 0 )~2 end
    
    UI.draw_knob(
      {str_id = '##note_layer_instrument_attack',
      is_small_knob = true,
      val = note_layer_t.instrument_attack_norm,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*3, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Attack',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_attack_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_attack =v /note_layer_t.instrument_attack_max
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('attack',v,note_layer_t,note,layer,true) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID, v*note_layer_t.instrument_attack_max )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID) 
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('attack',v,note_layer_t,note,layer,true) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 

    UI.draw_knob(
      {str_id = '##note_layer_instrument_decay',
      is_small_knob = true,
      val = note_layer_t.instrument_decay_norm,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*4, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Decay',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_decay_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_decay =v /note_layer_t.instrument_decay_max
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('decay',v,note_layer_t,note,layer,true) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v*note_layer_t.instrument_decay_max )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID) 
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('decay',v,note_layer_t,note,layer,true) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 

        
    UI.draw_knob(
      {str_id = '##note_layer_instrument_sustain',
      is_small_knob = true,
      val = note_layer_t.instrument_sustain,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*5, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Sustain',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_sustain_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_sustain =v
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('sustain',v,note_layer_t,note,layer,true) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v)    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID) 
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('sustain',v,note_layer_t,note,layer,true) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 

    UI.draw_knob(
      {str_id = '##note_layer_instrument_release',
      is_small_knob = true,
      val = note_layer_t.instrument_release_norm,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*6, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Release',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_release_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_release =v /note_layer_t.instrument_release_max
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('release',v,note_layer_t,note,layer,true) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID, v*note_layer_t.instrument_release_max )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID) 
        UI.draw_tabs_Sampler_tabs_rs5kcontrols_VCA('release',v,note_layer_t,note,layer,true) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
            
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_tabs_device()
    local note_layer_t, note, layer0 = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end  
    
    if ImGui.BeginChild( ctx, 'device' ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,5)
      
      local name_w = 185
      local slider_w = 60
      
      for layer = 1, #DATA.children[note].layers do
        
        local posx,posy = ImGui.GetCursorPos(ctx)
        local layer_t = DATA.children[note].layers[layer]
        
        -- name
        ImGui.SetNextItemWidth(ctx, name_w)
        if ImGui.Checkbox(ctx, layer_t.P_NAME..'##layer'..layer, layer == layer0) then
          DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER = layer
          DATA:WriteData_Parent()
          DATA.upd = true
        end
        
        -- D_VOL
        ImGui.SetCursorPos(ctx,posx+name_w,posy)
        ImGui.SetNextItemWidth(ctx, slider_w)
        local formatIn = layer_t.D_VOL_format
        local retval, v = reaper.ImGui_SliderDouble( ctx, '##layervol'..layer, layer_t.D_VOL, 0, 2, formatIn, ImGui.SliderFlags_None )
        if retval then SetMediaTrackInfo_Value( layer_t.tr_ptr, 'D_VOL',v ) DATA.upd = true end
        ImGui.SameLine(ctx)
        
        -- D_PAN
        ImGui.SetNextItemWidth(ctx, slider_w)
        local formatIn = layer_t.D_PAN_format
        local retval, v = reaper.ImGui_SliderDouble( ctx, '##layerpan'..layer, layer_t.D_PAN, -1,1, formatIn, ImGui.SliderFlags_None )
        if retval then SetMediaTrackInfo_Value( layer_t.tr_ptr, 'D_PAN',v ) DATA.upd = true end
        ImGui.SameLine(ctx)
        
        -- solo
        if layer_t.I_SOLO>0 then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x00FF00FF ) end
        if ImGui.Button(ctx, 'S##layerS'..layer, 23)  then 
          Undo_BeginBlock2(DATA.proj )
          local outval = 2 if layer_t.I_SOLO>0 then outval = 0 end SetMediaTrackInfo_Value( layer_t.tr_ptr, 'I_SOLO', outval ) DATA.upd = true
          Undo_EndBlock2( DATA.proj , 'RS5k manager - Solo pad', 0xFFFFFFFF ) 
        end 
        if layer_t.I_SOLO>0 then ImGui.PopStyleColor(ctx ) end
          
        -- mute
        ImGui.SameLine(ctx)
        if layer_t.B_MUTE>0 then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFF0000FF ) end
        if ImGui.Button(ctx, 'M##layerM'..layer, 23)  then
          Undo_BeginBlock2(DATA.proj )
          SetMediaTrackInfo_Value( layer_t.tr_ptr, 'B_MUTE', layer_t.B_MUTE~1 ) DATA.upd = true
          Undo_EndBlock2( DATA.proj , 'RS5k manager - Mute pad', 0xFFFFFFFF )         
        end
        if layer_t.B_MUTE>0 then ImGui.PopStyleColor(ctx ) end
        
        -- remove
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'X##layerem'..layer, -1) then DATA:Sampler_RemovePad(note,layer) end
        
      end
      
      -- device drop
      
      local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
      local track = GetTrack(-1,trackidx) if  trackidx == -1 then track = GetMasterTrack(-1) end
      local retval, fx_namesrc = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_name' )
      local fx_name = VF_ReduceFXname(fx_namesrc)
      -- prevent control jsfx / rs5k
      if retval then 
        if fx_namesrc: match('ReaSampl') or fx_namesrc:match('Macro') then retval = nil end 
      end
      local fxadd = ''
      if retval then fxadd = '\nor click to import ['..fx_name..']' end
      if ImGui.Button(ctx, 'Drop new layers here'..fxadd, -1,-1) then
        local cntlayers = 0
        if DATA.children[note] and DATA.children[note].layers then cntlayers = #DATA.children[note].layers end
        local drop_data = {layer = cntlayers + 1}
        if fx_namesrc and track then DATA:DropFX(fx_namesrc, fx_name, fxidx, track, note, drop_data) end
      end
      if ImGui.BeginDragDropTarget( ctx ) then  
        local cntlayers = 0
        if DATA.children[note] and DATA.children[note].layers then cntlayers = #DATA.children[note].layers end
        DATA:Drop_UI_interaction_device(note, cntlayers + 1)  
        ImGui_EndDragDropTarget( ctx )
      end
      
      ImGui.PopStyleVar(ctx,2)  
      ImGui.EndChild( ctx)
    end
  end
  ---------------------------------------------------------------------  
  function DATA:Drop_UI_interaction_device(note, layer) 
    -- validate is file or pad dropped
    local retval, count = ImGui.AcceptDragDropPayloadFiles( ctx, 127, ImGui.DragDropFlags_None )
    if not retval then return end
      
    Undo_BeginBlock2(DATA.proj )
    for i = 1, count do 
      local retval, filename = reaper.ImGui_GetDragDropPayloadFile( ctx, i-1 )
      if not retval then return end 
      DATA:DropSample(filename, note + i-1, {layer=layer})
    end 
    Undo_EndBlock2( DATA.proj , 'RS5k manager - drop samples to pads', 0xFFFFFFFF ) 

  end
  ---------------------------------------------------------------------  
  function DATA:Drop_UI_interaction_pad(note) 
    -- validate is file or pad dropped
    local retval, count = ImGui.AcceptDragDropPayloadFiles( ctx, 127, ImGui.DragDropFlags_None )
    if retval then 
      Undo_BeginBlock2(DATA.proj )
      for i = 1, count do 
        local retval, filename = reaper.ImGui_GetDragDropPayloadFile( ctx, i-1 )
        if not retval then return end 
        DATA:DropSample(filename, note + i-1, {layer=1})
      end  
      
      Undo_EndBlock2( DATA.proj , 'RS5k manager - drop samples to pads', 0xFFFFFFFF ) 
     else
      local retval, payload = reaper.ImGui_AcceptDragDropPayload( ctx, 'moving_pad', '', ImGui.DragDropFlags_None )-- accept pad drop
      if retval and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then 
        Undo_BeginBlock2(DATA.proj )
        local retval, types, payload, is_preview, is_delivery = reaper.ImGui_GetDragDropPayload( ctx )
        if retval and tonumber(payload)then DATA:Drop_Pad(tonumber(payload),note) end  
        Undo_EndBlock2( DATA.proj , 'RS5k manager - move pad', 0xFFFFFFFF ) 
      end 
    end
  end
  ---------------------------------------------------------------------  
  function DATA:Drop_UI_interaction_sampler() 
    -- validate is file or pad dropped
    local retval, count = ImGui.AcceptDragDropPayloadFiles( ctx, 1, ImGui.DragDropFlags_None )
    if not retval then return end
    
    -- drop on sampler
    if DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER then  
      local retval, filename = reaper.ImGui_GetDragDropPayloadFile( ctx, 0 )
      if retval then 
        local note_layer_t, note, layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
        DATA:DropSample(filename, note, {layer=layer})
      end
    end
  end 
  -----------------------------------------------------------------------------------------  
  function _main() 
    local loadtest = time_precise()
    gmem_attach('RS5K_manager')
    DATA.REAPERini = VF_LIP_load( reaper.get_ini_file()) 
    DATA:CollectData_MIDIdevices()
    DATA:CollectData_ParseREAPERDB() 
    UI.MAIN_definecontext()  
    DATA:CollectData_PluginParametersMapping_Get() 
    DATA.loadtest = time_precise() - loadtest
  end   
  ------------------------------------------------------------------------------------------   
  function DATA:Sampler_ImportSelectedItems() 
    local note =  0
    if  DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE end
    
    
    Undo_BeginBlock2(DATA.proj)
    local items_to_remove = {}
    for  i = 1, CountSelectedMediaItems(-1) do
      local drop_data = {layer=1}
      local item = GetSelectedMediaItem(-1,i-1)
      
      local retval, GUID = reaper.GetSetMediaItemInfo_String( item, 'GUID', '', false ) 
      items_to_remove[GUID] = true
      
      local tk = GetActiveTake( item ) 
      if not(tk and not TakeIsMIDI( tk )) then goto nextitem end
      
      local section,src_len 
      local src = GetMediaItemTake_Source( tk)
      local src_len =  GetMediaSourceLength( src )
      
      -- handle reversed source
      if not src or (src and GetMediaSourceType( src ) == 'SECTION') then  
        parent_src =  GetMediaSourceParent( src ) 
        src_len =  GetMediaSourceLength( parent_src )
       else
        parent_src = src
      end
      
      -- handle section
      if parent_src and (GetMediaSourceType( src ) == 'SECTION' or GetMediaSourceType( src ) == 'WAVE') then 
        local retval, offs, len, rev = reaper.PCM_Source_GetSectionInfo( src )
        drop_data.SOFFS = offs / src_len
        drop_data.EOFFS = (offs + len)/ src_len
      end  
      
      if parent_src then 
        local filenamebuf = GetMediaSourceFileName( parent_src )
        if filenamebuf then 
          filenamebuf = filenamebuf:gsub('\\','/')
          DATA:DropSample(filenamebuf,note+i-1, drop_data) 
        end
      end
      
      ::nextitem::
    end
    
    for itemGUID in pairs(items_to_remove ) do 
      local it = VF_GetMediaItemByGUID(DATA.proj, itemGUID)
      if it then DeleteTrackMediaItem(  reaper.GetMediaItemTrack( it ), it ) end
    end
    
    Undo_EndBlock2(DATA.proj, 'RS5k manager - import selected items', 0xFFFFFFFF)
    
    UpdateArrange()
  end
  ---------------------------------------------------------------------
  function VF_GetMediaItemByGUID(optional_proj, itemGUID)
    local optional_proj0 = optional_proj or -1
    local itemCount = CountMediaItems(optional_proj);
    for i = 1, itemCount do
      local item = GetMediaItem(0, i-1);
      local retval, stringNeedBig = GetSetMediaItemInfo_String(item, "GUID", '', false)
      if stringNeedBig  == itemGUID then return item end
    end
  end 
  -------------------------------------------------------------------------------- 
  function DATA:Auto_Reposition_TrackGetSelection()
    DATA.TrackSelection = {}
    local cnt = CountTracks(-1)
    for i = 1, cnt do
      local track = GetTrack(-1,i-1)
      local GUID = GetTrackGUID( track )
      if IsTrackSelected( track ) then DATA.TrackSelection[GUID] = true end
    end
  end
  -------------------------------------------------------------------------------- 
  function DATA:Auto_Reposition_TrackRestoreSelection()
    local cnt = CountTracks(-1)
    for i = 1, cnt do
      local track = GetTrack(-1,i-1)
      local GUID = GetTrackGUID( track )
      SetTrackSelected( track, DATA.TrackSelection[GUID]==true )
    end 
    DATA.TrackSelection = {}
  end
  -----------------------------------------------------------------------------------------    
  
    --[[  
    -----------------------------------------------------------------------
    function DATA2:Actions_GrabSamplers(note)
      local cnt = CountSelectedTracks(0)
      
      
      --[[
      local max_items = 8
      if cnt > max_items then
        local ret = MB('There are more than '..max_items..' items to import, continue?', '',3 )
        if ret~=6 then return end
      end
      
      local itt = {}
      for selitem = 1, cnt do itt[#itt+1] = GetSelectedMediaItem( 0, selitem -1) end
      
      for i = 1, #itt do
        local item = itt[i]
        local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
        local take = reaper.GetActiveTake(item)
        if not take or reaper.TakeIsMIDI(take) then goto skip_to_next_item end
        local tk_src =  GetMediaItemTake_Source( take )
        local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
        local src_len =GetMediaSourceLength( tk_src )
        if GetMediaSourceType( tk_src ) == 'SECTION' or GetMediaSourceType( tk_src ) == 'WAVE' and GetMediaSourceParent( tk_src ) then tk_src = GetMediaSourceParent( tk_src ) end
        local filename = reaper.GetMediaSourceFileName( tk_src, '' )
        local layer = 1
        local drop_data = {}
        drop_data.offs =s_offs
        drop_data.len =it_len
        drop_data.src =tk_src
        drop_data.src_len =src_len
        drop_data.SOFFS =s_offs/src_len
        drop_data.EOFFS =(s_offs+it_len)/src_len 
        DATA:DropSample(note+i-1, layer, filename,drop_data)
        DeleteTrackMediaItem(  reaper.GetMediaItemTrack( item), item )
        ::skip_to_next_item::
      end] ]
    end
    
    
    --[[
                 -------------------------------------------------------------
                 fu nction v2OBJ_Layouts(conf, obj, data, refresh, mouse)
                     local shifts,w_div ,h_div
                     if conf.keymode ==0 then 
                       w_div = 7
                       h_div = 2
                       shifts  = {{0,1},{0.5,0},{1,1},{1.5,0},{2,1},{3,1},{3.5,0},{4,1},{4.5,0},{5,1},{5.5,0},{6,1},}
                     elseif conf.keymode ==1 then 
                       w_div = 14
                       h_div = 2
                       shifts  = {{0,1},{0.5,0},{1,1},{1.5,0},{2,1},{3,1},{3.5,0},{4,1},{4.5,0},{5,1},{5.5,0},{6,1},{7,1},{7.5,0},{8,1},{8.5,0},{9,1},{10,1},{10.5,0},{11,1},{11.5,0},{12,1},{12.5,0},{13,1}                 
                               }                
                      elseif conf.keymode == 2 then -- korg nano
                       w_div = 8
                       h_div = 2     
                       shifts  = {{0,1},{0,0},{1,1},{1,0},{2,1},{2,0},{3,1},{3,0},{4,1},{4,0},{5,1},{5,0},{6,1},{6,0},{7,1},{7,0},}   
                      elseif conf.keymode == 3 then -- live dr rack
                       w_div = 4
                       h_div = 4     
                       shifts  = { {0,3},{1,3},{2,3},{3,3},{0,2},{1,2},{2,2},{3,2},{0,1},{1,1},{2,1},{3,1},{0,0},{1,0},{2,0},{3,0}                                                               
                               }      
                      elseif conf.keymode == 4 then -- s1 impact
                       w_div = 4
                       h_div = 4 
                       start_note_shift = -1    
                       shifts  = { {0,3},{1,3},{2,3},{3,3},{0,2},{1,2},{2,2},{3,2},{0,1},{1,1},{2,1},{3,1},{0,0},{1,0},{2,0},{3,0}                                                               
                               }  
                      elseif conf.keymode == 5 then -- ableton push
                       w_div = 8
                       h_div = 8  
                       shifts  = { 
                                   {0,7},{1,7},{2,7},{3,7},{4,7},{5,7},{6,7},{7,7},{0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,6},{7,6},{0,5},{1,5},{2,5},{3,5},{4,5},{5,5},{6,5},{7,5},{0,4},{1,4},{2,4},{3,4},{4,4},{5,4},{6,4},{7,4},{0,3},{1,3},{2,3},{3,3},{4,3},{5,3},{6,3},{7,3},{0,2},{1,2},{2,2},{3,2},{4,2},{5,2},{6,2},{7,2},{0,1},{1,1},{2,1},{3,1},{4,1},{5,1},{6,1},{7,1},{0,0},{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},}        
                      elseif conf.keymode == 6 then -- 8x8 segmented
                       w_div = 8
                       h_div = 8  
                       shifts  = { 
                                   {0,7},{1,7},{2,7},{3,7},{0,6},{1,6},{2,6},{3,6},{0,5},{1,5},{2,5},{3,5},{0,4},{1,4},{2,4},{3,4},{0,3},{1,3},{2,3},{3,3},{0,2},{1,2},{2,2},{3,2},{0,1},{1,1},{2,1},{3,1},{0,0},{1,0},{2,0},{3,0},{4,7},{5,7},{6,7},{7,7},{4,6},{5,6},{6,6},{7,6},{4,5},{5,5},{6,5},{7,5},{4,4},{5,4},{6,4},{7,4},{4,3},{5,3},{6,3},{7,3},{4,2},{5,2},{6,2},{7,2},{4,1},{5,1},{6,1},{7,1},{4,0},{5,0},{6,0},{7,0},}      
               elseif conf.keymode == 7 then -- 8x8, vertical columns
                       w_div = 8
                       h_div = 8  
                       shifts  = { 
                                   {0,7},{0,6},{0,5},{0,4},{0,3},{0,2},{0,1},{0,0},{1,7},{1,6},{1,5},{1,4},{1,3},{1,2},{1,1},{1,0},{2,7},{2,6},{2,5},{2,4},{2,3},{2,2},{2,1},{2,0},{3,7},{3,6},{3,5},{3,4},{3,3},{3,2},{3,1},{3,0},{4,7},{4,6},{4,5},{4,4},{4,3},{4,2},{4,1},{4,0},{5,7},{5,6},{5,5},{5,4},{5,3},{5,2},{5,1},{5,0},{6,7},{6,6},{6,5},{6,4},{6,3},{6,2},{6,1},{6,0},{7,7},{7,6},{7,5},{7,4},{7,3},{7,2},{7,1},{7,0},}  
               elseif conf.keymode == 8 then -- allkeys
                       w_div = 12
                       h_div = 12 
                       shifts  = { 
                                   {0,0},{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{0,1},{1,1},{2,1},{3,1},{4,1},{5,1},{6,1},{7,1},{8,1},{9,1},{10,1},{11,1},{0,2},{1,2},{2,2},{3,2},{4,2},{5,2},{6,2},{7,2},{8,2},{9,2},{10,2},{11,2},{0,3},{1,3},{2,3},{3,3},{4,3},{5,3},{6,3},{7,3},{8,3},{9,3},{10,3},{11,3},{0,4},{1,4},{2,4},{3,4},{4,4},{5,4},{6,4},{7,4},{8,4},{9,4},{10,4},{11,4},{0,5},{1,5},{2,5},{3,5},{4,5},{5,5},{6,5},{7,5},{8,5},{9,5},{10,5},{11,5},{0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,6},{7,6},{8,6},{9,6},{10,6},{11,6},{0,7},{1,7},{2,7},{3,7},{4,7},{5,7},{6,7},{7,7},{8,7},{9,7},{10,7},{11,7},{0,8},{1,8},{2,8},{3,8},{4,8},{5,8},{6,8},{7,8},{8,8},{9,8},{10,8},{11,8},{0,9},{1,9},{2,9},{3,9},{4,9},{5,9},{6,9},{7,9},{8,9},{9,9},{10,9},{11,9},{0,10},{1,10},{2,10},{3,10},{4,10},{5,10},{6,10},{7,10},{8,10},{9,10},{10,10},{11,10},{0,11},{1,11},{2,11},{3,11},{4,11},{5,11},{6,11},{7,11},{8,11},{9,11},{10,11},{11,11},}
               elseif conf.keymode == 9 then -- allkeys bot to top
                       w_div = 12
                       h_div = 12 
                       shifts  = {                      
                                    
               {0,11},{1,11},{2,11},{3,11},{4,11},{5,11},{6,11},{7,11},{8,11},{9,11},{10,11},{11,11},{0,10},{1,10},{2,10},{3,10},{4,10},{5,10},{6,10},{7,10},{8,10},{9,10},{10,10},{11,10},{0,9},{1,9},{2,9},{3,9},{4,9},{5,9},{6,9},{7,9},{8,9},{9,9},{10,9},{11,9},{0,8},{1,8},{2,8},{3,8},{4,8},{5,8},{6,8},{7,8},{8,8},{9,8},{10,8},{11,8},{0,7},{1,7},{2,7},{3,7},{4,7},{5,7},{6,7},{7,7},{8,7},{9,7},{10,7},{11,7},{0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,6},{7,6},{8,6},{9,6},{10,6},{11,6},{0,5},{1,5},{2,5},{3,5},{4,5},{5,5},{6,5},{7,5},{8,5},{9,5},{10,5},{11,5},{0,4},{1,4},{2,4},{3,4},{4,4},{5,4},{6,4},{7,4},{8,4},{9,4},{10,4},{11,4},{0,3},{1,3},{2,3},{3,3},{4,3},{5,3},{6,3},{7,3},{8,3},{9,3},{10,3},{11,3},{0,2},{1,2},{2,2},{3,2},{4,2},{5,2},{6,2},{7,2},{8,2},{9,2},{10,2},{11,2},{0,1},{1,1},{2,1},{3,1},{4,1},{5,1},{6,1},{7,1},{8,1},{9,1},{10,1},{11,1},{0,0},{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0}}
                                    
                     end
                     return  shifts,w_div ,h_div
                 end
                 

               { str = '>Layouts'},
               { str = 'Korg NanoPad (8x2)',
                 func = function() conf.keymode = 2 end ,
                 state = conf.keymode == 2},
                 
               { str = 'launchpad},                 
  
        ]]
        
       
  _main()
  