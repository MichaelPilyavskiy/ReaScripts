-- @description InteractiveToolbar
-- @version 3.08
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=203393
-- @about This script displaying information about different objects, also allow to edit them quickly without walking through menus and windows.
-- @changelog
--    # Space to play/paus (regression from 2.0+)
--    # Persisten widgets/LTFX: rightclick on parameter create envelope (regression from 2.0+)
--    + Persisten widgets/LTFX: tweaking parameter with ctrl modify envelope when transport is stopped
--    + Persisten widgets/LTFX: ctrl+enter when entering value modify envelope when transport is stopped



--[[
  TODO:
  -- item stretch markers size/ pitchmode
  -- color different context
  -- allow to switch doubleclick and right click for widgets with drag
]]

--------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    vrsmin = 7.0
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < vrsmin then return reaper.MB('This script require REAPER '..vrsmin..'+','',0) end
    --local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.10'
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = { 
          UI_Settings_widgetsorder_section = 1,
          CONF_availablewidgets =     '#pwrepeatstate #fxoversample #meevtchan #menotevel #meCCval #menotepitch #menotelen #meevtposition #metakename #envmarksame #envAIlooplen #envpointval #envpointpos #envfx #envname #trackrecin #trackmediaoffs #trackparentsend #trackpolarity #trackfreeze #trackdelay #trackfxlist #trackpan #trackvol #trackcolor #trackname #itempan #itemrate #itempitch #itemvol #itemcomlen #itemfadeout #itemfadein #itemsourceoffset #itemlength #itemrightedge #itemleftedge #itemsnap #itemposition #itemtimebase #itembwfsrc #itemreverse #itemchanmode #itemmute #itemloop #itempreservepitch #itemlock #itemcolor #itemname #pwswing #pwgrid #pwtimesellen #pwtimeselend #pwtimeselstart #pwtimeselLeftEdge #pwlasttouchfx #pwtransport #pwbpm #pwclock #pwmastermeter #pwmasterscope #pwtaptempo #pwmasterswapmono #pwmchanmeter',
          CONF_contextpriority =      '#MIDIEditor1 #SpecEdit1 #Item1 #FX1 #Envelope1 #Track1 ',
          
          
          -- default widgets
          CONF_widgetsH_Persist =     '#pwswing #pwgrid #pwtimesellen #pwtimeselend #pwtimeselstart #pwtimeselLeftEdge #pwlasttouchfx #pwtransport #pwrepeatstate #pwbpm #pwclock #pwmastermeter #pwmasterscope #pwtaptempo #pwmasterswapmono #pwmchanmeter',
          CONF_widgetsH_Item =        '#itemname #itemcolor #itemlock #itempreservepitch #itemloop #itemmute #itemchanmode #itemreverse #itembwfsrc #itemtimebase #itemposition #itemsnap #itemleftedge #itemrightedge #itemlength #itemsourceoffset #itemfadein #itemfadeout #itemvol #itempitch #itemrate #itempan',-- #itemcomlen  
          CONF_widgetsH_Track =       '#trackname #trackcolor #trackvol #trackpan #trackfxlist #trackdelay #trackfreeze #trackpolarity #trackparentsend #trackmediaoffs #trackrecin',
          CONF_widgetsH_Envelope =    '#envname #envfx #envpointpos #envpointval #envAIlooplen #envmarksame',
          CONF_widgetsH_MIDIEditor =  '#metakename #meevtposition #meevtchan #menotelen #menotevel #menotepitch #meCCval ',
          CONF_widgetsH_FX =          '#fxoversample #fxautobypass',
          CONF_widgetsH_SpecEdit =    '#sebypass',
          
          
          CONF_perswidgets_Wratio = 0.5, 
          CONF_widg_time_formatoverride=-1, 
          CONF_widg_clock_formatoverride=-1, 
          CONF_widg_clock_formatoverride2=-2, 
          CONF_widg_time_snaptogrid=1,
          CONF_widg_transport_flicker =1,
          CONF_widg_taptempo_quantize = 1,
          CONF_widg_itemcolor_lastcolRGBA = 0,
          CONF_widg_trackcolor_lastcolRGBA = 0,
          CONF_widg_envpointval_apprelative = 1,
          CONF_widg_envpointval_usebrutforce = 1,
          CONF_enablepersistwidg = 1,
          CONF_swapdoubleclickrightclick = 0,
          
          theming_rgba_windowBg = 0x303030FF,
          theming_rgba_widgetBg = 0x404040FF,
          theming_str_font = 'Arial',
          theming_float_fontscaling = 1,
          theming_rgba_valtxt = 0xFFFFFFDF,
          theming_rgba_valtxt_unavailable = 0x808080FF,
         }
        
  -------------------------------------------------------------------------------- INIT data
  DATA = { 
          upd = true,
          ES_key = 'MPL_InteractiveToolbar',
          UI_name = 'Interactive Toolbar H',  
          
          taptempo = {},
          func_quere = {},
          CurState = {},
          context = '',
          temp_inputmode = {},
          temp_inputmode_focus = {},
          
    -- widgets dsc
          widgets_desc_info =
          { 
            ['pwgrid'] = {desc = 'Show current grid, allow to change grid lines visibility and relative snap'},
            ['pwswing'] = {desc = 'Show current swing value, toggle'},
            ['pwtimesellen'] = {desc = 'Time selection length'},
            ['pwtimeselend'] = {desc = 'Time selection right edge'},
            ['pwtimeselstart'] = {desc = 'Time selection left edge'},
            ['pwtimeselLeftEdge'] = {desc = 'Time selection left edge, preserve length'},
            ['pwlasttouchfx'] = {desc = 'edit last touched FX parameter'},
            ['pwtransport'] = {desc = 'Show current play state, RightClick - options, LeftClick - transport play/stop, Cltr+Left - record'},
            ['pwrepeatstate'] = {desc = 'Show repeat state'},
            ['pwbpm'] = {desc = 'Shows/edit tempo and time signature for project (or tempo marker falling at edit cursor if any)'},
            ['pwclock'] = {desc = 'Shows play/edit cursor positions'},
            ['pwmastermeter'] = {desc = 'Show master RMS / peak / LUFS depending on master peak metering settings'},
            ['pwmasterscope'] = {desc = 'Show master oscillogram'},
            ['pwtaptempo'] = {desc = 'Get a tempo from tap, allow to distribute that info in different ways. RightClick for options. 10 seconds of no-op resets tap'},
            ['pwmasterswapmono'] = {desc = 'Shortcuts for inverting master width and toggle mono'},
            ['pwmchanmeter'] = {desc = 'Number of master channels + multichannel peak meter'},
            
            ['itemposition'] = {desc = 'edit item positions, relative if multiple items'},
            ['itemlength'] = {desc = 'edit item lengths, relative if multiple items'},
            ['itemsnap'] = {desc = 'edit take snap offset'},
            ['itemfadeout'] = {desc = 'edit item fadeout'},
            ['itemfadein'] = {desc = 'edit item fadein'},
            ['itemsourceoffset'] = {desc = 'edit take source offset'},
            ['itemcomlen'] = {desc = 'selected item common length, readout. Caution, takes more CPU on huge count of items', txtcol = 0xF05050FF} ,
            ['itemrightedge'] = {desc = 'edit item right edge positions, relative if multiple items'},
            ['itemleftedge'] = {desc = 'edit item left edge positions, relative if multiple items'},
            ['itemtimebase'] = {desc = 'edit item timebase'},
            ['itembwfsrc'] = {desc = 'shortcut to "Item: Move to source preferred position (used by BWF)"'},
            ['itemreverse'] = {desc = 'shortcut to "Item properties: Toggle take reverse"'},
            ['itemchanmode'] = {desc = 'Channel mode'},
            ['itemmute'] = {desc = 'Toggle mute, apply first item state to selection'},
            ['itemloop'] = {desc = 'Toggle loop, apply first item state to selection'},
            ['itempreservepitch'] = {desc = 'Toggle take preserve pitch, apply first item state to selection'},
            ['itemlock'] = {desc = 'Toggle lock, apply first item state to selection'},
            ['itemcolor'] = {desc = 'Set take color'},
            ['itemname'] = {desc = 'Set take name'},
            
            ['itemvol'] = {desc = 'edit item volume, relative if multiple items'},
            ['itempitch'] = {desc = 'edit item pitch, relative if multiple items'},
            ['itemrate'] = {desc = 'edit take playrate, relative if multiple items'},
            ['itempan'] = {desc = 'edit take pan, relative if multiple items'},
            
            ['trackname'] = {desc = 'edit track name'},
            ['trackcolor'] = {desc = 'edit track color'},
            ['trackvol'] = {desc = 'edit track gain'},
            ['trackpan'] = {desc = 'edit track pan'},
            ['trackfxlist'] = {desc = 'Show track FX chain, wheel to scroll, mouse modifiers - mixer behavious'},
            ['trackdelay'] = {desc = "Edit value in seconds for 'JS: time adjustment'"},
            ['trackfreeze'] = {desc = "Allow to freeze/unfreeze track, show freeze count"},
            ['trackpolarity'] = {desc = 'Toggle inversed polarity ("phase" in REAPER) of track audio output'},
            ['trackparentsend'] = {desc = 'Toggle Master/Parent send, apply first track state to selection'},
            ['trackmediaoffs'] = {desc = 'Adjust track media offset'},
            ['trackrecin'] = {desc = 'Wheel scroll between inputs: none/audio/midi, auto set record arm and monitoring. Click to toggle between MIDI:All and none.'}, 
            
            ['envname'] = {desc = 'edit envelope name'},
            ['envfx'] = {desc = 'Float Take/Track FX if related to applicable, shift click to toggle bypass'},
            ['envpointpos'] = {desc = 'edit point position'},
            ['envpointval'] = {desc = 'edit point value, volume envelopes use db<>linear convertion, apply relative to selection, see options'},
            ['envAIlooplen'] = {desc = 'edit loop length of selected automation item'},
            ['envmarksame'] = {desc = 'select points with same value'},
            
            ['metakename'] = {desc = 'edit take name'},
            ['meevtposition'] = {desc = 'edit event position, clamp to MIDI item boundaries'},
            ['menotelen'] = {desc = 'change note length, relative to selection'},
            ['menotepitch'] = {desc = 'change note pitch, Shift+wheel or Shift + drag to adjust octave, relative to selection'},
            ['menotevel'] = {desc = 'change note velocity, relative to selection'},
            ['meCCval'] = {desc = 'change CC value, relative to selection, preserve init positions'},
            ['meevtchan'] = {desc = 'change 3byte event channel'},
            
            ['fxoversample'] = {desc = 'change FX chain oversampling'},
            ['fxautobypass'] = {desc = 'toggle auto bypass'},
            
            ['sebypass'] = {desc = 'toggle bypass spectral edit'},
            
            
            
          }
          
          }
          
          
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
      -- min size
        w_min = 300,
        h_min = 70,
        
      -- font
        font_widgname=13,
        font_widgval=13,
        font_widgclock=25,
        font_widgbut=12,
        font_fxlist=12,
        
      -- mouse
        hoverdelay = 0.8,
        hoverdelayshort = 0.5,
        mouse_scalingY = 0.01,
        popupmouseoffs = 10,
        
      -- size / offset
        spacingX = 2,
        spacingY = 2,
        
      -- colors / alpha
        main_col = 0x7F7F7F, -- grey
        but_hovered = 0x878787, 
        col_green = 0x50FF50,
        
      -- widget
        widget_default_W = 50, 
        widget_defaultfloat_W = 60, 
        widget_defaulttiming_W = 100,  
        widget_defaultname_W = 180,  
        widget_defaultbut_W = 40,
        widget_defaultcolor_W = 25,
        widget_defaulttiming_W_minimalblock = 25,   
        widget_defaulttiming_W_minimalblock_ruler_beats = 25,
        widget_defaulttiming_W_minimalblock_ruler_seconds = 25, -- 0.XXX seconds 
        widget_defaulttiming_W_minimalblock_ruler_HMSF = 20, -- 0.XXX seconds 
        widget_default_H = 50, 
        widget_name_H = 20, 
        widget_name_col = 0x97DDFFFF,
        widget_val_col_disabled = 0x909090FF,
        widget_val_col = 0xFFFFFFFF,
        widget_active_col = 0x507F50FF, -- green
        widget_active_col2 = 0x30309FFF, -- blue
        widget_active_col_red = 0x7F5050FF, -- red
        widget_masterscopeW = 100,
        
        widget_col_peaksnormal = 0xFFFFFF8F,
        widget_col_peaksloud = 0xFF5050FF,
        
        image_repeat = ImGui.CreateImageFromMem(
                 "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\z
                   \x00\x00\x00\x40\x00\x00\x00\x40\x08\x06\x00\x00\x00\xAA\x69\x71\z
                   \xDE\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x0E\xC4\x00\x00\x0E\z
                   \xC4\x01\x95\x2B\x0E\x1B\x00\x00\x05\x5D\x49\x44\x41\x54\x78\x9C\z
                   \xED\x9B\x5F\x88\x54\x55\x1C\xC7\xBF\x67\x18\x96\x25\x96\x25\x24\z
                   \x44\x24\x6A\x91\x4D\x6A\x1F\x44\x42\x24\x62\x2B\x8D\xA0\xD8\x72\z
                   \x59\x16\x8D\xED\x25\xA4\x7A\x90\x08\x95\x9E\x2C\x7A\x89\x9E\xA4\z
                   \x44\xC2\x2C\xC2\x87\x1E\x44\x42\x2C\x0C\x7A\x58\x44\x48\x4A\xD2\z
                   \xCA\xCC\xB4\xB4\x14\x62\xB5\xC2\x56\x2C\x6D\xD1\xD6\xDC\x75\xFC\z
                   \xF4\x70\x66\x72\xFE\xDC\xB9\xF7\x77\x66\xEE\xCC\x75\x65\x3F\xB0\z
                   \xB0\x3B\x7B\xEE\xEF\x7C\x7F\xBF\x7B\xCF\xB9\xE7\x9C\xDF\x6F\xA4\z
                   \x9B\x14\xE0\x31\xE0\x28\xB0\x13\x98\x9B\xB5\x9E\xB6\x02\x0C\x01\z
                   \x57\xB8\xC1\x07\x59\x6B\x6A\x1B\xC0\x08\x30\x4D\x25\x87\xB2\xD6\z
                   \xD5\x16\x80\xD5\x11\xCE\x03\xFC\x94\xB5\xB6\x96\x03\xBC\x00\x14\z
                   \x22\x9C\x07\x38\x99\xB5\xBE\x96\x02\xAC\x89\x71\xFE\xD6\x0E\x00\z
                   \xF0\x52\x82\xF3\x2D\x0D\x80\x6B\xE4\x22\x60\x8E\xA4\x45\x92\x7A\z
                   \x25\xCD\x91\x74\x4D\xD2\xCF\x92\x3E\x73\xCE\xFD\x1B\x60\x67\xAD\z
                   \xA4\xCD\x92\x72\x09\x4D\x2F\x48\x7A\xB7\xEA\xB3\xAB\x92\x2E\x17\z
                   \xFF\xF7\xAB\xA4\x1F\x9D\x73\x7F\x5A\xFB\x0E\x06\x98\x0F\x6C\x00\z
                   \x0E\xD7\x99\xA8\x00\xCE\x00\xFD\x46\x7B\xEB\x13\xEE\x7A\x28\x85\z
                   \xA2\xB6\x0D\xC0\xFC\x34\x1D\xBF\x13\xD8\x06\x5C\x35\x0A\xB9\x04\z
                   \x2C\x6A\xB3\xF3\xD5\x5C\x01\xDE\xA7\x99\x40\x00\x39\xFC\xE4\x34\z
                   \xD1\x80\x80\x3D\x31\x76\x2D\x63\x3E\x2D\x26\x80\x17\x81\xA4\x21\z
                   \x56\x23\xB2\x13\xF8\xB0\x89\x8E\xA7\x81\xDB\x23\xEC\xAE\xA4\x7D\z
                   \xCE\x97\xB3\x13\xB8\x2D\xCA\xD7\x9A\xC8\x00\x5D\x92\x46\x25\x8D\z
                   \x04\x45\xAD\x92\xBC\xA4\x9A\x00\x48\x7A\x26\xAA\xCF\x36\xF0\xB4\z
                   \xA4\xD1\xA2\x6F\x15\x54\x88\x01\xF2\x92\x76\x49\x5A\xD6\x64\x87\z
                   \x93\x92\xC6\x23\x3E\xDF\x26\x69\xAA\x49\xDB\x8D\xF2\xB0\xA4\xDD\z
                   \x40\x47\xDD\x16\xC0\xC6\x94\x1E\xB9\xED\x31\x7D\x0C\x63\x9F\x50\z
                   \x5B\xC1\xE6\x7A\xC2\xFA\x49\x67\x7C\x9E\x21\x61\xF6\x25\xDB\x20\z
                   \x14\x80\x65\xD5\x82\x72\xF8\x77\x68\xB3\x86\x47\x81\xBB\xE2\x9C\z
                   \x2F\xEB\x73\x90\xEC\x82\x70\x14\x3F\xDC\xFD\x4A\x10\x18\x96\xF4\z
                   \xB1\x45\x78\x19\x67\x25\x7D\x22\xE9\xB8\xA4\xD3\x92\x8E\x39\xE7\z
                   \x7E\x0F\x31\x00\x3C\x25\x3F\xE7\x74\x26\x34\x1D\x97\xB4\xAE\xF8\z
                   \x7B\xAE\xF8\xD3\x21\xA9\x4B\xD2\x3D\x92\x86\x24\x99\x02\x5F\xC6\z
                   \x2A\xE7\xDC\x47\x25\x21\xFB\x02\xA2\xF7\x0F\xB0\x96\xB8\xC9\x24\z
                   \x00\xE0\x89\xA2\xCD\x38\x62\xF7\x02\x40\x07\x7E\x7D\x71\x29\xC0\z
                   \x8F\xFD\xA5\x8B\x7B\xB0\x8F\xFD\x8B\xC0\xD2\x34\x1C\xAF\x72\xE0\z
                   \xD1\x04\xF1\xA6\xCD\x10\xB0\xB4\xA8\xD1\x4A\x4F\x69\x65\x66\xA1\z
                   \x00\x0C\xA4\xED\x7C\x99\xF8\x7E\xEA\xAF\x3A\xCD\xBB\x41\x60\x00\z
                   \xFB\x0D\x5D\x23\x60\xBB\xB1\xF1\xEE\x56\x39\x5F\x26\x7E\x29\xF0\z
                   \x57\x44\xDF\x41\x27\x42\xC0\x2E\xA3\x4F\x3B\x72\xB2\x4F\x1E\xEF\z
                   \x85\xBB\x14\x86\x73\xEE\x1B\x49\xCB\x55\xBB\x88\xFA\x3B\xD0\xD4\z
                   \x56\x63\xBB\x05\x39\x49\xDD\x86\x86\xD7\x25\x7D\x1B\x28\xA2\x21\z
                   \x9C\x73\xC7\x24\x3D\x22\xFF\x66\x29\xF1\x45\xA0\x99\xEF\xE5\xCF\z
                   \x28\x92\xE8\xCE\xCB\xBF\x4E\x92\xB8\x26\xBF\xBC\x6D\x0B\xCE\xB9\z
                   \x53\xC0\x43\x92\x5E\x97\x34\x26\xE9\xAD\x40\x13\x93\xF2\x9A\xF3\z
                   \x09\xED\x3A\xF2\x86\x46\x92\x7F\x02\x2C\x11\x4D\x8D\xE2\x9A\xE2\z
                   \xF9\x06\xAF\x9D\x02\xAE\x1B\x9A\xE6\x4B\x8B\x8A\x24\xAE\x39\xE7\z
                   \xDA\x1A\x80\x14\x30\x6D\xBA\xAC\x5B\xD3\x99\xE6\xBC\x64\xD4\x9C\z
                   \x93\x7D\x08\xCC\x34\x4C\x9A\x67\x9F\x00\xA3\xB1\x99\xF8\x04\x98\z
                   \x98\x0D\x40\xD6\x02\xB2\xC6\x1A\x80\x5B\x36\x50\xB3\x01\x30\xB6\z
                   \xB3\xBC\x2A\x6F\x36\x4C\x9A\x73\xB2\xBD\x2E\x66\xE2\x13\x60\xD2\z
                   \x3C\xFB\x04\x58\x8D\x11\x9A\x5F\xCB\x1E\xD3\x99\x65\xC8\x10\x08\z
                   \x3A\x04\xC5\x1F\xB5\x8F\x00\xAF\x02\x96\x33\x87\xD4\xC0\x1F\x79\z
                   \x9B\x36\x79\x02\x7E\x30\x1C\x1D\x15\x88\x48\x76\x26\x88\x78\xB9\z
                   \xEC\xFA\x23\xC0\xBC\xC6\xDC\x09\x07\xE8\xA6\x7E\x0D\x43\x39\xC7\z
                   \x73\xF2\x55\x16\x49\xE4\x24\xF5\x05\xEA\x58\x51\xF6\xFB\x62\x49\z
                   \x9F\x63\x4C\x9A\xA4\xC0\xBD\xB2\xCD\x01\x93\x39\x55\x1E\x3D\xC5\z
                   \x11\x7A\x38\x31\xA7\xEA\xEF\x85\xF2\x41\xE8\x0D\xB4\xD3\x08\x56\z
                   \xAD\xA7\x73\x92\x0E\x1A\x1B\x3F\x0B\x3C\x10\x20\x22\x6A\xCE\xE8\z
                   \x91\x0F\x42\xE8\xD3\x64\x06\x58\x22\x69\xB5\xB1\xF9\x41\x01\x0B\z
                   \x0D\x63\xA5\xC4\x6F\xD6\x3B\x08\x9C\x8C\xB1\x73\x8E\x84\x32\x9A\z
                   \x46\xC0\x27\x79\xC6\x02\xFC\xE9\x2B\x5D\x78\x28\xE0\xA2\x73\xF8\z
                   \x9C\x5E\x33\x01\x00\x38\x8F\xBF\x5B\x69\x39\x3F\x00\xFC\x11\xE0\z
                   \xC7\x11\xE9\xC6\x44\xB1\x55\x92\xB5\x20\x79\xAE\xA4\x4F\x81\x03\z
                   \xF2\x89\xCD\x53\xF2\x13\xE9\x94\x2A\xB7\xCD\x49\x09\xCF\x3B\x24\z
                   \xED\x05\x1E\x2F\xE6\x03\xCC\xE0\xF3\x92\x0B\xE4\x87\x54\x9F\xA4\z
                   \x55\x92\x42\x86\xA7\x54\x9E\x3B\xC0\x27\x17\x7F\x09\x88\x5E\x9A\z
                   \x5C\x04\x1E\x34\x3A\xDE\x0D\x6C\x21\x2C\xFF\x17\xC5\x18\xD0\x59\z
                   \x6D\x7C\xA8\x49\xA3\xCD\x30\x41\x42\x7D\x21\xDE\xF9\x66\x6B\x18\z
                   \x4A\x0C\xD6\xEB\xC4\x9A\x27\x6C\x05\x97\x88\x09\x02\xB0\x29\xA5\z
                   \x7E\xEA\x96\xEF\x08\xE8\x22\xBD\x28\x37\xC2\x04\x11\xE9\x77\x20\z
                   \x4F\x74\xD2\x34\x94\xC3\x54\x55\x8A\x55\xAC\x97\x9D\x73\x97\x25\z
                   \x3D\x29\xE9\x44\xDC\xE3\xD8\x42\xBA\x25\xBD\x12\xF1\xF9\x3C\xD5\z
                   \x2E\xAC\x42\x39\x21\x69\x45\xD1\xC7\xFF\xA9\xD9\x30\x38\xE7\xC6\z
                   \xE5\x33\xB4\x07\x9A\xEC\xB0\x51\xF6\x45\x7C\x76\x59\xCD\x1D\xCC\z
                   \x7E\x25\x69\xB9\x73\xEE\xAC\xF9\x0A\xFC\x9B\x61\x23\xB6\x4D\x45\z
                   \x5A\x44\x97\xB0\x79\x3D\xFB\x1B\xB0\x37\x0D\xBC\x49\x33\xE5\x3C\z
                   \xC0\xFD\xC0\x9E\x34\xBD\xAC\xC3\x16\x62\xCE\x1C\xF0\x15\x24\x21\z
                   \x55\x65\x7B\x49\x71\xA1\x25\x60\x09\xBE\x02\xFB\x5C\xFA\xBE\xC7\z
                   \x3B\x5F\xA6\x61\x98\xF8\xE2\xED\xF3\xF8\xCA\x76\x73\x1D\x53\xF0\z
                   \x17\x26\xF0\x87\x0D\x8B\xE5\xBF\x30\x71\xB7\xFC\xE4\xD4\xA5\xDA\z
                   \xED\xE7\xA0\x6C\xC5\x17\xEF\x48\x5A\xE7\x9C\x33\x8D\x71\xFC\x77\z
                   \x08\x57\x4A\xBA\x4F\x7E\x0E\xBB\x20\x5F\x43\xF0\x9D\xFC\x97\x26\z
                   \x6E\x8E\x34\x1E\xC9\x7B\x01\x80\xB7\x2D\x77\x7E\x46\x62\x08\xC0\z
                   \xA6\xAC\x35\xB6\x94\x84\x00\x6C\xCC\x5A\x5F\xCB\xA1\xFE\x59\xE3\z
                   \x1B\x59\x6B\x6B\x0B\xC0\xD7\x11\xCE\xBF\x96\xB5\xAE\xB6\x01\xEC\z
                   \x28\x73\xBC\x00\xAC\xCF\x5A\x53\x5B\x01\x7A\x81\x2F\xF1\x7B\xEF\z
                   \xE7\xB2\xD6\x53\x8F\xFF\x00\x32\x4E\xE2\xEE\xAF\x55\x2D\x5C\x00\z
                   \x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"),
        }
    
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  -------------------------------------------------------------------------------- 
  function UI.Tools_RGBA(col, a_dec) return col<<8|math.floor(a_dec*255) end  
  -------------------------------------------------------------------------------- ImGui overrides
  function ImGui.Custom_InvisibleButton(ctx,txt,w,h,color,txtcol)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,color or 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,color or 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,color or 0)
    if txtcol then ImGui.PushStyleColor(ctx, ImGui.Col_Text,txtcol) end
    local ret = ImGui.Button(ctx,txt,w,h)
    ImGui.PopStyleColor(ctx, 3)
    if txtcol then ImGui.PopStyleColor(ctx, 1) end
    return ret
  end
  -------------------------------------------------------------------------------- ImGui overrides
  function ImGui.Custom_ColoredButton(ctx,txt,w,h,color,txtcol)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,         (color|0x80) or 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,   (color|0xA0) or 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,  (color|0xFF) or 0)
    if txtcol then ImGui.PushStyleColor(ctx, ImGui.Col_Text,txtcol) end
    local ret = ImGui.Button(ctx,txt,w,h)
    ImGui.PopStyleColor(ctx, 3)
    if txtcol then ImGui.PopStyleColor(ctx, 1) end
    return ret
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
      UI.anypopupopen = ImGui.IsPopupOpen( ctx, 'mainRCmenu', ImGui.PopupFlags_AnyPopup|ImGui.PopupFlags_AnyPopupLevel )
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,UI.w_min,UI.h_min)
      
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      window_flags = window_flags | ImGui.WindowFlags_NoCollapse
      window_flags = window_flags | ImGui.WindowFlags_NoNav
      --window_flags = window_flags | ImGui.WindowFlags_NoBackground
      --window_flags = window_flags | ImGui.WindowFlags_NoDocking
      --window_flags = window_flags | ImGui.WindowFlags_TopMost
      window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      --open = false -- disable the close button
    
    
    -- rounding
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,1)   
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding,3)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding,3)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding,1)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,3)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding,3)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabRounding,3)   
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
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,30)
      
    -- align
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,0,0.5)
      
    -- alpha
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha,1)
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
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,       UI.Tools_RGBA(UI.col_green, 0.4) )
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, UI.Tools_RGBA(UI.col_green, 0.7) )
      ImGui.PushStyleColor(ctx, ImGui.Col_Tab,              UI.Tools_RGBA(UI.main_col, 0.37) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected,       UI.Tools_RGBA(UI.col_green, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered,       UI.Tools_RGBA(UI.col_green, 0.8) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg,          UI.Tools_RGBA(UI.main_col, 0.7) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive,    UI.Tools_RGBA(UI.main_col, 0.95) )
      ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,         EXT.theming_rgba_windowBg)
      ImGui.PushStyleColor(ctx, ImGui.Col_Text,             EXT.theming_rgba_valtxt)
    
    -- font 
      ImGui.PushFont(ctx, DATA.font,13) 
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      
    -- init UI 
      local ret,open =  ImGui.Begin(ctx, DATA.UI_name, open, window_flags)
      if ret then 
      
        -- get drawlist
        UI.draw_list = ImGui.GetWindowDrawList( ctx )
        
        -- calc stuff for childs
        UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
        local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
        local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'Test')
        UI.calc_itemH = calcitemh + frameh * 2
        
        -- mousewheel
        local vertical, horizontal = reaper.ImGui_GetMouseWheel( ctx )
        UI.vertical, UI.horizontal = vertical, horizontal
        UI.draw() 
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
        
        if ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false ) then Main_OnCommandEx(40073,0,-1) end
        if ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false ) then return end
      end
  
    return open
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_loop() 
    DATA.clock = os.clock() 
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1)) 
    if not DATA.temp_valinit then DATA:CollectData_Always()  end -- do not refresh stuff on edit
    --if DATA.upd == true then DATA:CollectData_AtStateChange()  end 
    --DATA.upd = false  
    if not reaper.ImGui_ValidatePtr( ctx, 'ImGui_Context*') then UI.MAIN_definecontext() end
    UI.open = UI.MAIN_styledefinition(true) 
    if UI.open ==true then defer(UI.MAIN_loop) end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_definecontext() 
    DATA:ParseWidgetsOrder()
    ctx = ImGui.CreateContext(DATA.UI_name) 
    DATA.font = ImGui.CreateFont(EXT.theming_str_font) ImGui.Attach(ctx, DATA.font)
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort) 
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
  end
  --------------------------------------------------------------------------------  
  function UI.draw_settings_contextpriority()  
    local extkey = 'CONF_contextpriority'
    local listw = 150
    ImGui.SeparatorText(ctx, 'Context priority')--,listw) 
    if ImGui.ArrowButton( ctx, '##MoveUpwidg', ImGui.Dir_Up ) then DATA:Actions_Widgets_Write({moveup = extkey}) DATA.upd = true end ImGui.SameLine(ctx)
    if ImGui.ArrowButton( ctx, '##MoveDownwidg', ImGui.Dir_Down ) then DATA:Actions_Widgets_Write({movedown = extkey}) DATA.upd = true  end ImGui.SameLine(ctx) 
    if ImGui.Custom_ColoredButton(ctx, 'Reset',listw-43,0,0xF0303000) then EXT[extkey] = EXT.defaults[extkey] EXT:save() DATA:ParseWidgetsOrder() end
    if ImGui.BeginListBox( ctx, '##CONF_contextpriority', listw, 200 ) then 
      for i = 1, #DATA.widgets[extkey] do 
        local t = DATA.widgets[extkey][i] 
        local widget_ID = t.widget_ID 
        -- toggle ignore
        if ImGui.Checkbox(ctx, '##chignore'..t.widget_ID, t.widget_flags&1==1) then
          DATA.widgets[extkey][i].widget_flags = DATA.widgets[extkey][i].widget_flags~1
          DATA:Actions_Widgets_Write({printext = extkey}) DATA.upd = true
        end
        -- select to move
        ImGui.SameLine(ctx) 
        if DATA.context ==widget_ID then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x50FF50FF) end
        if ImGui.Selectable(ctx, widget_ID..'##curwidglist'..widget_ID, DATA.widgets[extkey][i].selected==true) then
          for i2 = 1, #DATA.widgets[extkey] do DATA.widgets[extkey][i2].selected=false end-- reset selection 
          DATA.widgets[extkey][i].selected=true
        end
        if DATA.context ==widget_ID then ImGui.PopStyleColor(ctx) end
      end 
      ImGui.EndListBox( ctx)
    end
    if ImGui.Checkbox(ctx, 'Enable persistent widgets', EXT.CONF_enablepersistwidg&1==1) then EXT.CONF_enablepersistwidg = EXT.CONF_enablepersistwidg~1 EXT:save() end
    if ImGui.Checkbox(ctx, 'Doubleclick for enter value, rightclick for reset', EXT.CONF_swapdoubleclickrightclick&1==1) then EXT.CONF_swapdoubleclickrightclick = EXT.CONF_swapdoubleclickrightclick~1 EXT:save() end
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_settings_theming()
    -- reset all
      if ImGui.Custom_ColoredButton(ctx, 'Reset ALL##resetall', 0,30, 0xF8505000) then 
        for extkey in pairs(EXT) do
          if extkey:match('theming_') then 
            EXT[extkey] = EXT.defaults[extkey] 
          end
        end
        EXT:save() 
        DATA.font = ImGui.CreateFont(EXT.theming_str_font) 
        ImGui.Attach(ctx, DATA.font)
      end
      
    -- colors
      local map = {
        ['Window background'] =       {extkey = 'theming_rgba_windowBg'},
        ['Widget background'] =       {extkey = 'theming_rgba_widgetBg'},
        ['Value text'] =              {extkey = 'theming_rgba_valtxt'},
        ['Value text unavailable'] =  {extkey = 'theming_rgba_valtxt_unavailable'},
      }
      for alias in spairs(map) do
        local extkey= map[alias].extkey
        if ImGui.Button(ctx, 'Reset##reset'..extkey) then EXT[extkey] = EXT.defaults[extkey] EXT:save() end  ImGui.SameLine(ctx)
        local retval, col_rgba = ImGui.ColorEdit4( ctx, alias, EXT[extkey], reaper.ImGui_ColorEditFlags_None() )
        if retval then EXT[extkey] = col_rgba EXT:save() end
      end
    
    -- font
      local extkey = 'theming_str_font'
      if ImGui.Button(ctx, 'Reset##reset'..extkey) then EXT[extkey] = EXT.defaults[extkey] EXT:save() DATA.font = ImGui.CreateFont(EXT.theming_str_font) ImGui.Attach(ctx, DATA.font) end  ImGui.SameLine(ctx)
      local retval, buf = ImGui.InputText( ctx, 'Font', EXT[extkey], ImGui.InputFlags_None )
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT[extkey] = buf EXT:save() DATA.font = ImGui.CreateFont(EXT.theming_str_font) ImGui.Attach(ctx, DATA.font) end
    
    -- scaling  
      local lim_min, lim_max = 0.5,3
      local extkey = 'theming_float_fontscaling'
      if ImGui.Button(ctx, 'Reset##reset'..extkey) then EXT[extkey] = EXT.defaults[extkey] EXT:save() DATA.font = ImGui.CreateFont(EXT.theming_str_font) ImGui.Attach(ctx, DATA.font) end  ImGui.SameLine(ctx)
      local retval, v = reaper.ImGui_SliderDouble( ctx, 'Font scaling', EXT[extkey], lim_min, lim_max, '%.2f', ImGui.SliderFlags_None )
      if retval then 
        EXT[extkey] = lim(v, lim_min, lim_max)
        EXT:save() 
        DATA:_DefineWidgets() 
        DATA:CollectData_RefreshTimeWidgetsSizing() 
      end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_settings_widgetsorder()   
    -- context selector
      local map = {
        {extkey = 'CONF_widgetsH_Persist', str = 'Persistent widgets'},
        {extkey = 'CONF_widgetsH_Item', str = 'Item context widgets'},
        {extkey = 'CONF_widgetsH_Track', str = 'Track context widgets'},
        {extkey = 'CONF_widgetsH_Envelope', str = 'Envelope widgets'},
        {extkey = 'CONF_widgetsH_MIDIEditor', str = 'MIDIEditor widgets'},
        {extkey = 'CONF_widgetsH_FX', str = 'Focused FX widgets'},
        {extkey = 'CONF_widgetsH_SpecEdit', str = 'Spectral edit widgets'},
      } 
      local preview_value = map[EXT.UI_Settings_widgetsorder_section].str
      if ImGui.BeginCombo( ctx, '##UI_Settings_widgetsorder_section', preview_value, ImGui.ComboFlags_HeightLargest ) then
        for i=1,#map do if ImGui.Selectable(ctx, map[i].str) then EXT.UI_Settings_widgetsorder_section=i EXT:save() end end
        ImGui.EndCombo(ctx)
      end 
      local extkey
      if map[EXT.UI_Settings_widgetsorder_section] then extkey = map[EXT.UI_Settings_widgetsorder_section].extkey end
    
    -- reset  
      ImGui.SameLine(ctx)
      if extkey then if ImGui.Custom_InvisibleButton(ctx, 'Reset',0,0,0x803030FF) then EXT[extkey] = EXT.defaults[extkey] EXT:save() DATA:ParseWidgetsOrder() end end
    
    -- cacha use widgets
      DATA.temp_used_widget = {}
    
            
    -- current widgets
      local widg_W = 250
      ImGui.Custom_InvisibleButton(ctx, 'Current widgets##dummycurwidg', widg_W)
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx,30,0)
      ImGui.SameLine(ctx)
      ImGui.Custom_InvisibleButton(ctx, 'Available widgets##dummyavwidg', -1)
      if extkey then 
        if DATA.widgets[extkey]then 
          if ImGui.BeginListBox( ctx, '##Current widgets', widg_W, -1 ) then
            
            for i = 1, #DATA.widgets[extkey] do
              local widget_ID = DATA.widgets[extkey][i].widget_ID
              DATA.temp_used_widget[widget_ID] = true
              
              if DATA.widgets_desc_info[widget_ID] and DATA.widgets_desc_info[widget_ID].txtcol then ImGui.PushStyleColor(ctx, ImGui.Col_Text,DATA.widgets_desc_info[widget_ID].txtcol) end  
              if ImGui.Selectable(ctx, widget_ID..'##curwidglist'..widget_ID, DATA.widgets[extkey][i].selected==true) then
                if not ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl) then for i2 = 1, #DATA.widgets[extkey] do DATA.widgets[extkey][i2].selected=false end end-- reset selection 
                DATA.widgets[extkey][i].selected=true
              end
              if DATA.widgets_desc_info[widget_ID] and DATA.widgets_desc_info[widget_ID].txtcol then ImGui.PopStyleColor(ctx)  end
              if DATA.widgets_desc_info[widget_ID] and DATA.widgets_desc_info[widget_ID].desc then 
                ImGui.SameLine(ctx)
                local padd = 5
                ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,padd,padd) 
                ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,padd,padd) 
                ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,0x205020FF)  
                UI.HelpMarker(DATA.widgets_desc_info[widget_ID].desc) 
                ImGui.PopStyleColor(ctx) 
                ImGui.PopStyleVar(ctx, 2) 
              end
              
            end
            
            ImGui.EndListBox( ctx)
          end
        end
      end
    
    -- arr
      ImGui.SameLine(ctx)
      local posx,posy = ImGui.GetCursorPos(ctx)
      if ImGui.ArrowButton( ctx, '##Removewidg', ImGui.Dir_Right ) then DATA:Actions_Widgets_Write({remove = extkey}) end
      ImGui.SameLine(ctx)
      local posx_avwidg,posy_avwidg = ImGui.GetCursorPos(ctx)
      ImGui.SetCursorPos(ctx, posx, posy + 30)
      if ImGui.ArrowButton( ctx, '##Addwidg', ImGui.Dir_Left ) then DATA:Actions_Widgets_Write({add = extkey}) end
      ImGui.SetCursorPos(ctx, posx, posy + 60)
      if ImGui.ArrowButton( ctx, '##MoveUpwidg', ImGui.Dir_Up ) then DATA:Actions_Widgets_Write({moveup = extkey}) end
      ImGui.SetCursorPos(ctx, posx, posy + 90)
      if ImGui.ArrowButton( ctx, '##MoveDownwidg', ImGui.Dir_Down ) then DATA:Actions_Widgets_Write({movedown = extkey}) end
      
    -- available widgets 
      ImGui.SetCursorPos(ctx, posx_avwidg,posy_avwidg)
      local widg_W = 250
      extkey = 'CONF_availablewidgets'
      if DATA.widgets[extkey]then 
        if ImGui.BeginListBox( ctx, '##Av widgets', widg_W, -1 ) then
          
          for i = 1, #DATA.widgets[extkey] do
            local widget_ID = DATA.widgets[extkey][i].widget_ID
            if not DATA.temp_used_widget[widget_ID] then
            
              if DATA.widgets_desc_info[widget_ID] and DATA.widgets_desc_info[widget_ID].txtcol then ImGui.PushStyleColor(ctx, ImGui.Col_Text,DATA.widgets_desc_info[widget_ID].txtcol) end  
              if ImGui.Selectable(ctx, widget_ID..'##curwidglist'..widget_ID, DATA.widgets[extkey][i].selected==true) then
                if not ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl) then for i2 = 1, #DATA.widgets[extkey] do DATA.widgets[extkey][i2].selected=false end end-- reset selection 
                DATA.widgets[extkey][i].selected=true
              end
              if DATA.widgets_desc_info[widget_ID] and DATA.widgets_desc_info[widget_ID].txtcol then ImGui.PopStyleColor(ctx)  end
              if DATA.widgets_desc_info[widget_ID] and DATA.widgets_desc_info[widget_ID].desc then 
                ImGui.SameLine(ctx)
                local padd = 5
                ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,padd,padd) 
                ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,padd,padd) 
                ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,0x205020FF)  
                UI.HelpMarker(DATA.widgets_desc_info[widget_ID].desc) 
                ImGui.PopStyleColor(ctx) 
                ImGui.PopStyleVar(ctx, 2) 
              end
              
            end
          end 
          ImGui.EndListBox( ctx)
        end
      end
      
  end
    --------------------------------------------------------------------------------  
  function UI.draw_settings()   
    ImGui.PushFont(ctx, DATA.font, 13)
    ImGui.OpenPopupOnItemClick( ctx, 'Settings_page', ImGui.PopupFlags_None )
    local x, y = reaper.ImGui_GetMousePos( ctx )
    ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize( ctx, 500, 500, ImGui.Cond_Always)
    if ImGui.BeginPopup( ctx, 'Settings_page', ImGui.PopupFlags_None ) then 
      ImGui.PushStyleColor(ctx, ImGui.Col_Text,0xFFFFFFDF)
      if ImGui.BeginTabBar( ctx, 'Settings_pageTab', ImGui.TabBarFlags_None ) then
      
        if ImGui.BeginTabItem( ctx, 'General', false,  ImGui.TabBarFlags_None ) then
          UI.draw_settings_contextpriority()
          ImGui.EndTabItem( ctx)
        end
        if ImGui.BeginTabItem( ctx, 'Widgets order', false,  ImGui.TabBarFlags_None ) then
          UI.draw_settings_widgetsorder() 
          ImGui.EndTabItem( ctx)
        end
        if ImGui.BeginTabItem( ctx, 'Theming', false,  ImGui.TabBarFlags_None ) then
          UI.draw_settings_theming() 
          ImGui.EndTabItem( ctx)
        end
        ImGui.EndTabBar( ctx)
      end
      ImGui.PopStyleColor(ctx)
      ImGui.EndPopup( ctx )
    end
    ImGui.PopFont(ctx)
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
    -- Settings_page
      ImGui.Button(ctx, '>',0,-1)
      if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_ForTooltip) then
        if ImGui.BeginTooltip(ctx) then
          ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
          ImGui.Text(ctx, 'Context:'); 
          ImGui.SameLine(ctx)
          ImGui.TextColored(ctx, 0x50FF50FF, DATA.context)
          ImGui.PopTextWrapPos(ctx)
          ImGui.EndTooltip(ctx)
        end
      end
      local menubutW = ImGui.GetItemRectSize(ctx)
      UI.draw_settings()  
      
    -- main widgets
      ImGui.SameLine(ctx)
      local widgX = reaper.ImGui_GetCursorScreenPos(ctx)
      local widgW,y = ImGui.GetContentRegionAvail(ctx)
      local mainwidgetsblockW = EXT.CONF_perswidgets_Wratio*widgW
      if EXT.CONF_enablepersistwidg==0 then mainwidgetsblockW = widgW end
      
    -- mainwidgetsblock widgets      
      ImGui.SameLine(ctx)
      if ImGui.BeginChild( ctx, 'mainwidgetsblock', mainwidgetsblockW, 0, ImGui.ChildFlags_None, ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar|ImGui.WindowFlags_NoScrollWithMouse ) then--|ImGui.ChildFlags_Borders
        local widget_spacingX= 1
        local mainwidg_avX,mainwidg_avY = ImGui.GetContentRegionAvail(ctx)
        local widget_Xcursor = 0
        local key_context = 'CONF_widgetsH_'..DATA.context
        local widgH = UI.widgetBuild_handleHstretch() 
        if DATA.widgets[key_context] then 
          for widget = 1, #DATA.widgets[key_context] do 
            local widget_ID = DATA.widgets[key_context][widget].widget_ID
            local widget_W =  UI.widget_default_W*EXT.theming_float_fontscaling -- upcoming widget 
            if DATA.widget_def[widget_ID] and DATA.widget_def[widget_ID].widget_W then widget_W = DATA.widget_def[widget_ID].widget_W end 
            
            if widget_Xcursor + widget_W < mainwidg_avX  then
              if widget ~= 1 then ImGui.SameLine(ctx)  end
              widget_Xcursor = widget_Xcursor + widget_W + widget_spacingX
             else
              ImGui.Dummy(ctx,0,0)
              widget_Xcursor = widget_W + widget_spacingX
            end
            
            if widget_ID then 
              if UI['widget_'..widget_ID] then UI['widget_'..widget_ID](DATA.widgets[key_context][widget]) end 
            end 
            
          end
        end
        ImGui.Dummy(ctx, 0,0)
        ImGui.EndChild( ctx)
      end 
    
    if EXT.CONF_enablepersistwidg == 1 then
      -- separator
        ImGui.SameLine(ctx)
        local butsep_W = 5
        ImGui.Custom_InvisibleButton(ctx,'##seaparator',butsep_W,-1,0x505050FF)
        if ImGui.IsItemActive(ctx) and ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left) then
          local mx, my = reaper.ImGui_GetMousePos( ctx )
          local out_ratio = math.min(0.9,math.max(0.1,(mx-widgX-butsep_W*0.5)/widgW))
          out_ratio = math.floor(out_ratio*1000)/1000
          if EXT.CONF_perswidgets_Wratio ~= out_ratio then EXT.CONF_perswidgets_Wratio = out_ratio EXT:save() end
        end
        
      -- pers widgets      
        ImGui.SameLine(ctx)
        if ImGui.BeginChild( ctx, 'perswidgetsblock', -1, 0, ImGui.ChildFlags_None, ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar|ImGui.WindowFlags_NoScrollWithMouse ) then -- |ImGui.ChildFlags_Borders
          local curposX, curposY = ImGui_GetCursorPos(ctx)
          local key_context = 'CONF_widgetsH_Persist'
          local widgH = UI.widgetBuild_handleHstretch() 
          if DATA.widgets[key_context] then 
            local xav, yav = ImGui.GetContentRegionAvail(ctx) 
            local xav_used = xav
            for widget = 1, #DATA.widgets[key_context] do 
              local widget_ID = DATA.widgets[key_context][widget].widget_ID
              if DATA.widget_def[widget_ID] then   
                local widget_W = DATA.widget_def[widget_ID].widget_W or UI.widget_default_W*EXT.theming_float_fontscaling
                local xpos = xav_used-widget_W+ UI.spacingX
                ImGui.SetCursorPos(ctx, xpos, curposY)
                xav_used = xav_used-widget_W-UI.spacingX
                if xav_used < 0 and widgH ~= -1 then 
                  ImGui.Dummy(ctx,0,widgH)
                  curposY = ImGui_GetCursorPosY(ctx)
                  xav_used = xav
                  local xpos = xav_used-UI.spacingX
                  ImGui.SetCursorPos(ctx, xpos, curposY)
                end
                if UI['widget_'..widget_ID] then UI['widget_'..widget_ID](DATA.widgets[key_context][widget]) end
              end 
            end
          end
          ImGui.Dummy(ctx, 0,0)
          ImGui.EndChild( ctx)
        end 
    end
    
    
  end 
  --------------------------------------------------------------------------------  
  function UI.widgetBuild_pushstyling()
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,0,0) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,0) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX, 0)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5, 0.5)  
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,EXT.theming_rgba_widgetBg)--0x404040FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg,EXT.theming_rgba_widgetBg) 
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,EXT.theming_rgba_widgetBg)--0x404040FF)
  end
  --------------------------------------------------------------------------------   
  function UI.widgetBuild_handleHstretch() 
    local xav, yav = ImGui.GetContentRegionAvail(ctx)
    local widgH = -1 
    if yav > UI.widget_default_H*EXT.theming_float_fontscaling*2 then widgH = UI.widget_default_H*EXT.theming_float_fontscaling end
    return widgH
  end
  --------------------------------------------------------------------------------  
  function UI.widgetBuild_popstyling()
    ImGui.PopStyleVar(ctx,4)
    ImGui.PopStyleColor(ctx,3)
  end
  --------------------------------------------------------------------------------   
  function UI.widgetBuild_name(widget_ID, name)
    ImGui.PushFont(ctx, DATA.font, UI.font_widgname*EXT.theming_float_fontscaling) 
    ImGui.PushStyleColor(ctx, ImGui.Col_Text,UI.widget_name_col)
    local ret = ImGui.Custom_InvisibleButton(ctx, name..'##but'..widget_ID,-1, UI.widget_name_H*EXT.theming_float_fontscaling)
    local retR
    if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then retR = true end
    ImGui.PopFont(ctx)
    ImGui.PopStyleColor(ctx,1)
    return ret,retR
  end
  --------------------------------------------------------------------------------   
  function UI.widgetBuild_value_single(widget_ID, params)
    local val_format = params.val_format
    local width = -1
    if params.width then width = params.width end
    local rxav,ryav = ImGui_GetContentRegionAvail(ctx)
     
    -- input
      if params.setoutputformatted_func and DATA.temp_inputmode[widget_ID] == widget_ID then 
        local input_preview = val_format
        if params.curvalue_format  then input_preview =  params.curvalue_format end
        ImGui.SetNextItemWidth(ctx, width)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,1,0.5*(ryav - UI.font_widgval*EXT.theming_float_fontscaling-UI.spacingY) )
        local retval, buf = ImGui.InputText( ctx, '##butinput'..widget_ID, input_preview, ImGui.InputFlags_None) 
        ImGui.PopStyleVar(ctx,1)
        ImGui.SetKeyboardFocusHere(ctx,-1) 
        if reaper.ImGui_IsItemDeactivated(ctx) then
          params.setoutputformatted_func(buf)
          DATA.temp_inputmode[widget_ID] = nil
          if params.onrelease then params.onrelease() end
          Undo_BeginBlock2( -1 ) Undo_EndBlock2( -1, 'Interactive toolbar edit', 0xFFFFFFFF )
        end 
        return
      end 
    
    -- draw current formatted value
      ImGui.InvisibleButton(ctx, '##butval'..widget_ID,width, -1)
      local x,y = ImGui.GetItemRectMin(ctx)
      local w,h = ImGui.GetItemRectSize(ctx)
      ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling) 
      local txtw, txth = ImGui.CalcTextSize(ctx, val_format)
      local valcol = EXT.theming_rgba_valtxt 
      if params.val_available~= true then valcol = EXT.theming_rgba_valtxt_unavailable end 
      ImGui.DrawList_AddText(UI.draw_list, x+0.5*(w-txtw),y+0.5*(h-txth), valcol, val_format) 
      ImGui.PopFont(ctx) 
      
    -- latch val
      if reaper.ImGui_IsItemActivated(ctx) and not DATA.temp_valinit then 
        DATA.temp_valinit = params.val or 0
        DATA.temp_clickx, DATA.temp_clicky = ImGui.GetMouseClickedPos( ctx, ImGui.MouseButton_Left )
        --DATA.temp_clickingpos_Xinfluence = lim(2*(1-(DATA.temp_clickx - x ) / w),0.1,2)  
        if params.atclick_func then params.atclick_func() end
      end
  
    
    -- apply val
      if DATA.temp_valinit and ImGui.IsItemActive(ctx) and ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left) then
        local dx_px, dy_py = ImGui.GetMouseDragDelta( ctx,DATA.temp_clickx, DATA.temp_clicky, ImGui.MouseButton_Left, -1 )
        local dx_pxabs, dy_pxabs = ImGui.GetMouseDelta( ctx)
        if dy_pxabs ~= 0 then 
          if ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl) then  dy_py = dy_py*0.1  end 
          local outval = DATA.temp_valinit - dy_py*(params.mousedy_drag_ratio or 0.01)
          --if params.allow_clickX_ratio then dy_py = dy_py * DATA.temp_clickingpos_Xinfluence end
          if params.setoutput_func then params.setoutput_func(outval) end
        end
      end
      
    -- wheel
      local vertical, horizontal = UI.vertical, UI.horizontal--reaper.ImGui_GetMouseWheel( ctx )
      if reaper.ImGui_IsItemHovered(ctx) and vertical ~= 0 and params.val then
        
        local temp_valinit = params.val--or 0
        local dy_py = math.abs(vertical)/vertical
        if ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl)  then dy_py = dy_py*0.1  end
        local outval = temp_valinit + dy_py*(params.mousedy_wheel_ratio or 0.01)
        if params.setoutput_func then params.setoutput_func(outval) end
        if params.onrelease then params.onrelease() end
        Undo_BeginBlock2( -1 ) Undo_EndBlock2( -1, 'Interactive toolbar edit', 0xFFFFFFFF )
      end 
      
    --reset latch
      if ImGui.IsItemDeactivated(ctx) then 
        DATA.temp_valinit = nil 
        DATA.temp_printstate = nil 
        if params.onrelease then params.onrelease() end
        Undo_BeginBlock2( -1 ) Undo_EndBlock2( -1, 'Interactive toolbar edit', 0xFFFFFFFF )
      end
      
    -- doubleclick
      if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked( ctx, ImGui.MouseButton_Left ) then
        if params.setoutput_func_reset then params.setoutput_func_reset() end 
        Undo_BeginBlock2( -1 ) Undo_EndBlock2( -1, 'Interactive toolbar edit', 0xFFFFFFFF )
      end
      
    -- onrightclick
      if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right)  then 
        if params.setoutputformatted_func and not DATA.temp_inputmode[widget_ID] then DATA.temp_inputmode[widget_ID] = widget_ID end
      end
      
  end
  
  --------------------------------------------------------------------------------   
  function UI.widgetBuild_value_multi_mousehandler(params, val_format_t, i, widget_ID) 
    
    -- latch val
      if reaper.ImGui_IsItemActivated(ctx) and not DATA.temp_valinit then 
        local val = val_format_t.num[i]
        if val_format_t.is_negative and i == 1 then val = -val end
        DATA.temp_valinit = val or 0
        DATA.temp_val_format_t_init =CopyTable(val_format_t)
        DATA.temp_clickx, DATA.temp_clicky = ImGui.GetMouseClickedPos( ctx, ImGui.MouseButton_Left ) 
        if params.atclick_func then params.atclick_func() end
        test= params
      end
      
    -- apply val
      if DATA.temp_valinit and ImGui.IsItemActive(ctx) and ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left) then
        local dx_px, dy_py = ImGui.GetMouseDragDelta( ctx,DATA.temp_clickx, DATA.temp_clicky, ImGui.MouseButton_Left, -1 )
        local dx_pxabs, dy_pxabs = ImGui.GetMouseDelta(ctx)
        if dy_pxabs ~= 0 and dy_py ~= 0 then
        
          local mult =  math.abs(dy_py)/dy_py  -- get mouse wheel direction / normalizes
          local mult2 = 1 if DATA.temp_val_format_t_init and DATA.temp_val_format_t_init.is_negative == true then mult2= -mult2 end -- negative handling 
          local abs = math.floor(math.abs(dy_py)) * (params.Ctrl_drag_override or 0.1 )
          local val_format_t_new = CopyTable(DATA.temp_val_format_t_init)
          val_format_t_new.num[i] = math.floor(DATA.temp_val_format_t_init.num[i] - mult * abs*mult2  ) 
          local val_new,val_format_new = UI.widgetBuild_value_ReverseFormatting(params,val_format_t_new)  
          if not DATA.temp_val_format_t_UI then DATA.temp_val_format_t_UI = {} end
          DATA.temp_val_format_t_UI[widget_ID] = Utils_SplitValues(val_format_new) 
          if params.setoutput_func then params.setoutput_func(val_new) end
        end
      end   
      
    -- wheel
      local vertical, horizontal = UI.vertical, UI.horizontal--reaper.ImGui_GetMouseWheel( ctx )
      if reaper.ImGui_IsItemHovered(ctx) and vertical ~= 0 then
        local dy_py = (math.abs(vertical)/vertical)  * (params.Ctrl_drag_override or 1 )
        local val_format_t_new = CopyTable(val_format_t)
        local mult2 = 1 if val_format_t_new.is_negative == true then mult2= -mult2 end -- negative handling 
        val_format_t_new.num[i] = math.floor(val_format_t.num[i] + dy_py*mult2 )
        
        local val_new,val_format_new = UI.widgetBuild_value_ReverseFormatting(params,val_format_t_new)
        
        if not DATA.temp_val_format_t_UI then DATA.temp_val_format_t_UI = {} end
        DATA.temp_val_format_t_UI[widget_ID] = Utils_SplitValues(val_format_new) 
        if params.setoutput_func then params.setoutput_func(val_new) end
        if params.onrelease then params.onrelease() end
        Undo_BeginBlock2( -1 ) Undo_EndBlock2( -1, 'Interactive toolbar edit', 0xFFFFFFFF )
      end 

    -- doubleclick
      local reset_trig = (EXT.CONF_swapdoubleclickrightclick&1==0 and  ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked( ctx, ImGui.MouseButton_Left ) )
        or (EXT.CONF_swapdoubleclickrightclick&1==1 and  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) )
      if reset_trig == true then
        local allow_reset = 
          --widget_ID == 'itemsnap'
          --or widget_ID == 'itemsourceoffset'
          widget_ID == 'itemvol'
          or widget_ID == 'itempitch'
          or widget_ID == 'trackvol'
          or (DATA.upd_last_rulerformat == 4 and i == 4) -- frames for H:M:S:F
          or (DATA.upd_last_rulerformat == 4 and i == 3) -- seconds for H:M:S:F
          or (DATA.upd_last_rulerformat == 1 and i == 3) -- sub beats for ruler=beats
          or (DATA.upd_last_rulerformat == 1 and i == 2) 
          
        local reset_value = 0
        if (DATA.upd_last_rulerformat == 1 and i == 2)  then reset_value  = 1 end -- reset beats to 1
        
        if allow_reset == true then 
          local val_format_t_new = CopyTable(val_format_t)
          val_format_t_new.num[i] = reset_value
          
          --if widget_ID == 'itemsnap' then for i2 = 1, #val_format_t_new.num do val_format_t_new.num[i2] = 0 end end -- #itemsourceoffset reset to 0
          --if widget_ID == 'itemsourceoffset' then for i2 = 1, #val_format_t_new.num do val_format_t_new.num[i2] = 0 end end -- #itemsourceoffset reset to 0
          
          -- any value double click reset to 0
          if 
            widget_ID == 'itemvol' or 
            widget_ID == 'itempitch' or
            widget_ID == 'trackvol' 
            then 
            for i2 = 1, #val_format_t_new.num do val_format_t_new.num[i2] = 0 end 
          end
          
          local val_new,val_format_new = UI.widgetBuild_value_ReverseFormatting(params,val_format_t_new)
          
          if not DATA.temp_val_format_t_UI then DATA.temp_val_format_t_UI = {} end
          DATA.temp_val_format_t_UI[widget_ID] = Utils_SplitValues(val_format_new) 
          if params.setoutput_func then params.setoutput_func(val_new) end
          Undo_BeginBlock2( -1 ) Undo_EndBlock2( -1, 'Interactive toolbar edit', 0xFFFFFFFF )
        end
      end
    
    -- reset latch on release
      if ImGui.IsItemDeactivated(ctx) then 
        DATA.temp_valinit = nil  
        if DATA.temp_val_format_t_UI then DATA.temp_val_format_t_UI[widget_ID] = nil end-- clear formatted overrides, force real measured values
        DATA.temp_printstate = nil 
        if params.onrelease then params.onrelease() end
        Undo_BeginBlock2( -1 ) Undo_EndBlock2( -1, 'Interactive toolbar edit', 0xFFFFFFFF )
      end
 
    -- onrightclick
      local input_trig = (EXT.CONF_swapdoubleclickrightclick&1==1 and  ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked( ctx, ImGui.MouseButton_Left ) )
        or (EXT.CONF_swapdoubleclickrightclick&1==0 and  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) )
        
      if input_trig ==true  then 
        if not DATA.temp_inputmode[widget_ID] then  
          DATA.temp_inputmode[widget_ID] = widget_ID 
          DATA.temp_inputmode_focus[widget_ID] = i 
        end
      end      
      
  end
  --------------------------------------------------------------------------------   
  function UI.widgetBuild_value_multi_inputhandler(params, val_format_t, i, widget_ID, retval, buf) 
    
    if retval and tonumber(buf)then 
      val_format_t[i] = buf
    end
    if reaper.ImGui_IsItemDeactivated(ctx) then -- AfterEdit
      local val_format_t_new = CopyTable(val_format_t) 
      val_format_t_new.num[i] = tonumber(buf)
      if val_format_t_new.num[i] then 
        if i==1 then val_format_t_new.is_negative = buf:match('%-') ~= nil val_format_t_new.num[i]=math.abs(val_format_t_new.num[i]) end -- negative handling 
        
        local val_new,val_format_new = UI.widgetBuild_value_ReverseFormatting(params,val_format_t_new)
        
        if not DATA.temp_val_format_t_UI then DATA.temp_val_format_t_UI = {} end
        DATA.temp_val_format_t_UI[widget_ID] = Utils_SplitValues(val_format_new) 
        if params.setoutput_func then params.setoutput_func(val_new) end
        DATA.temp_inputmode[widget_ID] = nil
        if DATA.temp_val_format_t_UI and DATA.temp_val_format_t_UI[widget_ID] then DATA.temp_val_format_t_UI[widget_ID] = nil end
       else -- reset at invalid string
        DATA.temp_inputmode[widget_ID] = nil
        if DATA.temp_val_format_t_UI and DATA.temp_val_format_t_UI[widget_ID] then DATA.temp_val_format_t_UI[widget_ID] = nil end
      end
      if params.onrelease then params.onrelease() end
      Undo_BeginBlock2( -1 ) Undo_EndBlock2( -1, 'Interactive toolbar edit', 0xFFFFFFFF )
    end
  end
  --------------------------------------------------------------------------------   
  function UI.widgetBuild_value_multi(widget_ID, params)
    local val_format = params.val_format 
    local val_format_t = params.val_format_t 
    if not val_format_t then return end
    
    local width = -1
    if params.width then width = params.width end
    local rxav,ryav = ImGui_GetContentRegionAvail(ctx)
    local div_str = val_format_t.div
    local ext_str = val_format_t.ext
    local control_W = -1
    
    local xoffs = UI.spacingX
    local X_spacing = 5
    if #val_format_t.num ~= 1 then
      control_W = math.min(rxav / #val_format_t.num, params.minimalblock_W or UI.widget_defaulttiming_W_minimalblock)
      local com_cntrl_w = control_W * #val_format_t.num + (#val_format_t.num-1) * X_spacing
      if com_cntrl_w +  X_spacing  < rxav then 
        xoffs = 0.5*(rxav - com_cntrl_w)
        --ImGui.Dummy(ctx, xoffs,0)
        --ImGui.SameLine(ctx) 
      end
    end
    
    local valcol = EXT.theming_rgba_valtxt 
    if params.val_available~= true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, EXT.theming_rgba_valtxt_unavailable) valcol = EXT.theming_rgba_valtxt_unavailable end 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,UI.spacingY *2)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, X_spacing,0 )
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling) 
    local div_w, div_h = ImGui.CalcTextSize(ctx, div_str) 
    local active_values = 0
    local ctrlval_W
    for i = 1, #val_format_t.num do
      ctrlval_W = control_W
      if i == 1 then ctrlval_W = xoffs + control_W-UI.spacingX end
      
      -- replace formatted param while dragging
        local format_split_val = val_format_t.num[i] 
        if val_format_t.is_negative and i ==1 then format_split_val = '-'..format_split_val end
        if DATA.temp_val_format_t_UI and DATA.temp_val_format_t_UI[widget_ID] then format_split_val = DATA.temp_val_format_t_UI[widget_ID].num[i] end
        if DATA.temp_val_format_t_UI and DATA.temp_val_format_t_UI[widget_ID] and DATA.temp_val_format_t_UI[widget_ID].is_negative and i ==1 then format_split_val = '-'..format_split_val end
      -- input --------------------------------------------
        if DATA.temp_inputmode[widget_ID] == widget_ID then 
        
          -- input  
            ImGui.SetNextItemWidth(ctx, ctrlval_W)
            local retval, buf = ImGui.InputText( ctx, '##butinput'..widget_ID..'val'..i, format_split_val, ImGui.InputFlags_None|ImGui.InputTextFlags_AutoSelectAll) 
            if DATA.temp_inputmode_focus[widget_ID] and DATA.temp_inputmode_focus[widget_ID] == i then
              ImGui.SetKeyboardFocusHere(ctx,-1)
              DATA.temp_inputmode_focus[widget_ID] = nil
            end
            UI.widgetBuild_value_multi_inputhandler(params, val_format_t, i, widget_ID, retval, buf)
            
          -- draw separator / forward same line
            local x,y = ImGui.GetItemRectMin(ctx)
            local w,h = ImGui.GetItemRectSize(ctx)
            if i~= #val_format_t.num then 
              if div_str then ImGui.DrawList_AddText(UI.draw_list, x+w+1,y+(h-div_h)*0.5, valcol, div_str) end 
              ImGui.SameLine(ctx) 
            end
        end 
        
        
        
      -- drag value --------------------------------------------
      if DATA.temp_inputmode[widget_ID] ~= widget_ID then  
        -- invisible contrl
          ImGui.InvisibleButton(ctx, '##butval'..widget_ID..'val'..i,ctrlval_W, -1) -- Custom_ -- 
        
        -- mouse
          if params.val_available == true then UI.widgetBuild_value_multi_mousehandler(params, val_format_t, i, widget_ID) end
        
        -- draw value
          local x,y = ImGui.GetItemRectMin(ctx)
          local w,h = ImGui.GetItemRectSize(ctx)
          local formval_w, formval_h = ImGui.CalcTextSize(ctx, format_split_val) 
          local xposval = x+w-formval_w
          if #val_format_t.num == 1  then xposval = x+0.5*(w-formval_w) end -- centered
          ImGui.DrawList_AddText(UI.draw_list, xposval,y+(h-formval_h)*0.5, valcol, format_split_val)  
          
        -- draw separator / forward same line
          if i~= #val_format_t.num then 
            if div_str then ImGui.DrawList_AddText(UI.draw_list, x+w+1,y+(h-div_h)*0.5, valcol, div_str) end 
            ImGui.SameLine(ctx) 
           elseif ext_str then 
            ImGui.DrawList_AddText(UI.draw_list, x+w+1,y+(h-div_h)*0.5, valcol, ext_str) 
          end
      end
      
        
    end 
    if params.val_available~= true then ImGui.PopStyleColor(ctx) end 
    ImGui.PopStyleVar(ctx,2)
    ImGui.PopFont(ctx)
    
    
  end
  
  --------------------------------------------------------------------------------  
  function DATA:FuncQuere_Run()
    if not DATA.func_quere then return end
    for key in pairs(DATA.func_quere) do
      --msg(key)
      local f = DATA[key]
      if f then f() end
    end
    DATA.func_quere = {}
  end
  --------------------------------------------------------------------------------  
  function DATA:CollectData_AtStateChange() 
  
    if not DATA.CurState then DATA.CurState = {} end
    DATA:CollectData_Project_Various()
    DATA:_CollectData_GetContext() 
    
    -- form quere
      -- main widgets
        local key_context = 'CONF_widgetsH_'..DATA.context
        if DATA.widgets[key_context] then
          for widget = 1, #DATA.widgets[key_context] do 
            local widget_ID = DATA.widgets[key_context][widget].widget_ID
            DATA:FuncQuere_Build(widget_ID) 
          end
        end
        
      -- pers widgets 
        local key_context = 'CONF_widgetsH_Persist'
        if DATA.widgets[key_context] then
          for widget = 1, #DATA.widgets[key_context] do 
            local widget_ID = DATA.widgets[key_context][widget].widget_ID
            DATA:FuncQuere_Build(widget_ID) 
          end
        end 
      
      -- clean state
        if not DATA.CurState then DATA.CurState = {} end
      
        
  end 
  -------------------------------------------------------------------------------- 
  function Utils_GetProjectSampleRate() return tonumber(format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_RefreshTimeWidgetsSizing() 
    DATA.func_quere['CollectData_Project_TimeSel'] = true 
    DATA.func_quere['CollectData_Item'] = true 
    DATA.func_quere['CollectData_Envelope'] = true 
    DATA.func_quere['CollectData_MIDIEditor'] = true 
    
    local rulerformat = DATA.CurState.Project.rulerformat
    if EXT.CONF_widg_time_formatoverride ~= -1 then rulerformat = EXT.CONF_widg_time_formatoverride end
    
    if rulerformat == 3  then UI.widget_defaulttiming_W_minimalblock = UI.widget_defaulttiming_W_minimalblock_ruler_beats  end
    if rulerformat == 2  then UI.widget_defaulttiming_W_minimalblock = UI.widget_defaulttiming_W_minimalblock_ruler_seconds  end
    if rulerformat == 5  then UI.widget_defaulttiming_W_minimalblock = UI.widget_defaulttiming_W_minimalblock_ruler_HMSF  end
    
    UI.widget_defaulttiming_W_minimalblock = UI.widget_defaulttiming_W_minimalblock*EXT.theming_float_fontscaling
    DATA:_DefineWidgets()
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Always() 
    if not DATA.CurState then DATA.CurState = {} end 
    if not DATA.CurState.Project then DATA.CurState.Project = {} end
    
    DATA.time_precise = time_precise()
    
    -- DATA:CollectData_AtStateChange() 
      -- state change
        local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA:CollectData_AtStateChange() end  DATA.upd_lastSCC = SCC 
      -- edit cursor
        local editcurpos =  GetCursorPosition()  if GetPlayStateEx( -1 )&1==1 then editcurpos = GetPlayPositionEx(-1) end 
        if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos -- DO NOT REMOVE, for legacy reasons
        DATA.CurState.editcurpos = editcurpos 
      -- proj change
        local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA:CollectData_AtStateChange()  end DATA.upd_last_reaproj = reaproj
      -- selected envelope (cause click on empty track doesn`t trigger state change update)
        local selenv = GetSelectedEnvelope( -1 )
        if (DATA.upd_lastselenv and DATA.upd_lastselenv~=selenv ) then DATA:CollectData_AtStateChange() end  DATA.upd_lastselenv = selenv 
      -- ME (cause closing ME doesn`t trigger state change update)
        local ME = MIDIEditor_GetActive()
        if (DATA.upd_lastME and DATA.upd_lastME~=ME ) then DATA:CollectData_AtStateChange() end  DATA.upd_lastME = ME         
      -- FX
        local hasfocFX, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 1 )
        if (DATA.upd_lasthasfocFX and DATA.upd_lasthasfocFX~=hasfocFX ) then DATA:CollectData_AtStateChange() end  DATA.upd_lasthasfocFX = hasfocFX  
      --[[ SE
        local SE = DATA:_CollectData_GetContext_SEcheck()
        if (DATA.upd_lastSE and DATA.upd_lastSE~=SE ) then DATA:CollectData_AtStateChange() end  DATA.upd_lastSE = SE  ]]
        
    -- local updates 
      -- time sel
        local TS_st, TS_end = GetSet_LoopTimeRange2( -1, false, false, -1, -1, false )
        local TS = TS_st+TS_end if (DATA.upd_last_TS and DATA.upd_last_TS ~= TS) then DATA.func_quere['CollectData_Project_TimeSel'] = true end DATA.upd_last_TS = TS
      
      -- LTFX
        local retval, tr, itemidx, takeidx, fx, param = reaper.GetTouchedOrFocusedFX( 0)
        local LTFXsum = tr+fx<<8+param<<16
        if (DATA.upd_last_LTFXsum and DATA.upd_last_LTFXsum ~= LTFXsum) then DATA.func_quere['CollectData_Project_LTFX'] = true end DATA.upd_last_LTFXsum = LTFXsum
      
      -- play state
        local playstate = GetPlayStateEx( -1 )
        if (DATA.upd_last_playstate and DATA.upd_last_playstate ~= playstate) then DATA.func_quere['CollectData_Project_Transport'] = true end DATA.upd_last_playstate = playstate
      
      -- grid
        local retval, division, swingmode, swingamt = reaper.GetSetProjectGrid( -1, false, 0, 0, 0 )
        local quickgridhash = retval + division + swingmode + swingamt
        if (DATA.upd_last_quickgridhash and DATA.upd_last_quickgridhash ~= quickgridhash) then DATA.func_quere['CollectData_Project_Grid'] = true  end DATA.upd_last_quickgridhash = quickgridhash
      
      -- ruler format
        local rulerformat = Utils_GetCurrentRulerFormat()
        DATA.CurState.Project.rulerformat  = rulerformat
        if (not DATA.upd_last_rulerformat or (DATA.upd_last_rulerformat and DATA.upd_last_rulerformat ~= rulerformat)) then 
          DATA:CollectData_RefreshTimeWidgetsSizing() 
        end 
        DATA.upd_last_rulerformat = rulerformat
    
    
    
    -- run functions
      DATA:FuncQuere_Run()
      DATA:CollectData_Always_Post() 
      DATA:CollectData_Project_Master() 
  end 
  ---------------------------------------------------
  function Utils_GetCurrentRulerFormat()
    local ruler = -1
    local buf = format_timestr_pos( 30, '',-1 )
    if buf:match('%d%:%d%d%.%d%d%d') then return 0      -- Minutes:seconds
      elseif buf:match('%d%.%d+.%d%d') then return 2    -- Measures.Beats / Minutes:seconds
                                                        -- Measures.Beats (minimal)
                                                        -- Measures.Beats (minimal) / Minutes:seconds
      elseif buf:match('%d%.%d%d%d') then return 3      -- Seconds
      elseif buf:match('[^%p]%d+[^%p]') then 
        if tonumber(buf) > 10000 then 
          return 4                                      -- Samples
         else 
          return 6                                      -- Frames
        end           
      elseif buf:match('%d%:%d%d%:%d%d%:%d%d') then return 5 -- hhmmssfr
    end
    return ruler
  end
  ---------------------------------------------------  
  function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------------------------------------------------------------------------
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  --------------------------------------------------------------------------------  
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
  function DATA:CollectData_Always_Post() 
    if not DATA.CurState then DATA.CurState = {} end
    if not DATA.CurState.PostCalc then DATA.CurState.PostCalc = {} end
    
    -- editcursor_pos_rel 
      DATA.CurState.PostCalc.editcursor_pos_rel = 0
      if DATA.CurState.Project and DATA.upd_last_editcurpos and DATA.CurState.Project.TS_end and DATA.upd_last_editcurpos <= DATA.CurState.Project.TS_end and DATA.upd_last_editcurpos >= DATA.CurState.Project.TS_st then
        DATA.CurState.PostCalc.editcursor_pos_rel = (DATA.upd_last_editcurpos - DATA.CurState.Project.TS_st) / (DATA.CurState.Project.TS_len)
      end
    
    -- play_flicker
      if DATA.CurState.Transport and DATA.CurState.Transport.play == true then 
        local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( -1, DATA.upd_last_editcurpos )
        local val = ((retval%1)^2)
        local min = 0.5
        DATA.CurState.PostCalc.play_flicker = lim(1-val, min,1)
      end
      
    -- bigclock
      DATA.CurState.PostCalc.editcurpos_format = Utils_formattimestr( DATA.upd_last_editcurpos, '',EXT.CONF_widg_clock_formatoverride ) 
      if EXT.CONF_widg_clock_formatoverride2 ~= -2 then DATA.CurState.PostCalc.editcurpos_format2 = Utils_formattimestr( DATA.upd_last_editcurpos, '',EXT.CONF_widg_clock_formatoverride2 ) end
      
  end
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  -------------------------------------------------------------------------------- 
  function WDL_VAL2DB(x)
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else return string.format('%.2f', v) end
  end
  ---------------------------------------------------
  function Utils_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if s_out and s_out == '' then return s end 
    if not s_out then return s end 
    
    if s_out:match('[%/%\\]') then s_out = s_out:match('[%/%\\](.*)') end
    if not s_out then return s else return s_out end 
  end
    --------------------------------------------------------------------------------   
  function Utils_BFpluginparam_str2num(str) local str = str:match('[%d%-%.]+') if str then return tonumber(str) end end
  ------------------------------------------------------- 
  function Utils_BFpluginparam(find_Str, ptr, fx, param) 
    if not (find_Str and find_Str~= '' ) then return end
    
    -- catch ptr
    local ptr_type
    if ValidatePtr2(-1,ptr, 'MediaTrack*') then ptr_type = 'Track'
      elseif ValidatePtr2(-1,ptr, 'MediaItem_Take*') then ptr_type = 'Take'
    end
    
    if not ptr_type then return end
    local dest_val = Utils_BFpluginparam_str2num(find_Str) 
    if not dest_val then return end
    
    local iterations = 100
    local min, max, mid = 0,1,0.5
    for i = 1, iterations do -- iterations
      mid = min + 0.5*(max - min) 
      _G[ptr_type..'FX_SetParamNormalized']( ptr, fx, param, mid ) 
      local _, buf = _G[ptr_type..'FX_GetFormattedParamValue']( ptr , fx, param, '' )
      local val = Utils_BFpluginparam_str2num(buf) 
      if val then 
        if val <= dest_val then 
          min = mid
         else
          max = mid
        end
      end
    end
    return mid
    
  end
  --------------------------------------------------------------------------------  
  function DATA:FuncQuere_Build(widget_ID)  
    if DATA.widget_def[widget_ID] and DATA.widget_def[widget_ID].collectdata_func then 
      local collectdata_func = DATA.widget_def[widget_ID].collectdata_func 
      DATA.func_quere[collectdata_func] = true
    end
  end
  ---------------------------------------------------  
  function DATA:CollectData_Project_Master(set, params)   
    if not DATA.CurState then DATA.CurState = {} end
    if not DATA.CurState.Master then DATA.CurState.Master = {} end
    
    local track = GetMasterTrack(-1)
    DATA.CurState.Master.chancnt = GetMediaTrackInfo_Value( track, 'I_NCHAN')
    DATA.CurState.Master.chancntformat = math.floor(DATA.CurState.Master.chancnt)..'ch'
    DATA.CurState.Master.D_WIDTH = GetMediaTrackInfo_Value( track, 'D_WIDTH')
    DATA.CurState.Master.Swap = DATA.CurState.Master.D_WIDTH<0
    DATA.CurState.Master.MONO = GetToggleCommandStateEx(0,40917) == 1
    
    -- mch peaks
    DATA.CurState.Master.MCpeaks = {}
    DATA.CurState.Master.MCpeaks_tooltip = {}
    local peak,peak_dB
    for i = 1, DATA.CurState.Master.chancnt do
      peak = Track_GetPeakInfo( track,i-1 )
      peak_dB = WDL_VAL2DB(peak)
      if peak <=1 then peak = peak^0.5 end 
      DATA.CurState.Master.MCpeaks[i] = peak
      DATA.CurState.Master.MCpeaks_tooltip[i] = 'Channel '..i..': '..peak_dB..'dB'
    end
    if not DATA.CurState.Master.MCpeaks_tooltip_conc then DATA.CurState.Master.MCpeaks_tooltip_conc = '' end
    
    -- loudness  // reduced refresh for 
    if not DATA.CurState.Master.last_check or (DATA.CurState.Master.last_check and DATA.time_precise - DATA.CurState.Master.last_check > 0.3) then
      DATA.CurState.Master.loudness = WDL_VAL2DB(Track_GetPeakInfo( track, 1024 ))..'dB'
      local VU_mode = GetMediaTrackInfo_Value( track, 'I_VUMODE' ) -- track vu mode &30==20:LUFS-S (readout=current), &32:LUFS calculation on channels 1+2 only 
      DATA.CurState.Master.VU_mode = VU_mode
      DATA.CurState.Master.last_check = DATA.time_precise 
      
      local ttstr = table.concat(DATA.CurState.Master.MCpeaks_tooltip,'\n')
      DATA.CurState.Master.MCpeaks_tooltip_conc = ttstr
    end
    
    
    -- peaks
    local peaks_cnt = UI.widget_masterscopeW 
    if not DATA.CurState.Master.peakL then DATA.CurState.Master.peakL = {}  end
    if not DATA.CurState.Master.peakR then DATA.CurState.Master.peakR = {}  end 
    local pkL =  Track_GetPeakInfo( track,0 ) if pkL < 0.001 then pkL = 0 end
    local pkR = Track_GetPeakInfo( track,1 ) if pkR < 0.001 then pkR = 0 end
    table.insert(DATA.CurState.Master.peakL, 1 , pkL)
    table.insert(DATA.CurState.Master.peakR, 1 , pkR)
    if #DATA.CurState.Master.peakL>peaks_cnt then table.remove(DATA.CurState.Master.peakL, peaks_cnt+1) end
    if #DATA.CurState.Master.peakR>peaks_cnt then table.remove(DATA.CurState.Master.peakR, peaks_cnt+1) end
    
    if set == true then 
      if params.setchancnt then 
        local tr =  reaper.GetMasterTrack( -1)
        reaper.SetMediaTrackInfo_Value( tr, 'I_NCHAN', params.setchancnt)
      end
      
      if params.togglemono then 
        Main_OnCommandEx(40917,0,-1) -- Master track: Toggle stereo/mono (L+R)
      end
      
      if params.swap then
        local tr =  reaper.GetMasterTrack( -1)
        SetMediaTrackInfo_Value( track, 'D_WIDTH', -1*DATA.CurState.Master.D_WIDTH)
        SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5 )
      end
      
      -- recursively run local update
      DATA:CollectData_Project_Master()
    end
  end
  ---------------------------------------------------  
  function DATA:CollectData_Project_Grid(set, params)  
    if not DATA.CurState.Project then DATA.CurState.Project = {} end
    DATA.CurState.Project.grid_enabled = GetToggleCommandState(1157)==1 
    DATA.CurState.Project.grid_relative = GetToggleCommandState(41054)==1 
    local retval, division, swingmode, swingamt = GetSetProjectGrid( -1, false )
    DATA.CurState.Project.swingamt = swingamt
    DATA.CurState.Project.swingamt_format = math.floor(swingamt*100)..'%'
    DATA.CurState.Project.swingmode = swingmode 
    
    DATA.CurState.Project.grid_division = division
    DATA.CurState.Project.grid_istriplet = false
    DATA.CurState.Project.grid_denom = 1/division
    if DATA.CurState.Project.grid_denom >=2 then 
      DATA.CurState.Project.grid_istriplet = (1/DATA.CurState.Project.grid_division) % 3 == 0 
      DATA.CurState.Project.grid_format = '1/'..math.floor(DATA.CurState.Project.grid_denom)
      if DATA.CurState.Project.grid_istriplet ==true then DATA.CurState.Project.grid_format = '1/'..math.floor(DATA.CurState.Project.grid_denom*2/3) end
     else 
      DATA.CurState.Project.grid_format = 1
      DATA.CurState.Project.grid_istriplet = math.abs(DATA.CurState.Project.grid_division - 0.6666) < 0.001
    end
    if DATA.CurState.Project.grid_istriplet == true then 
      DATA.CurState.Project.grid_denom_pow = math.log(DATA.CurState.Project.grid_denom*2/3,2)
     else
      DATA.CurState.Project.grid_denom_pow = math.log(DATA.CurState.Project.grid_denom,2)
    end
    
    
    
    if set and params then 
    
      -- swing
      if params.toggleswing == true then 
        GetSetProjectGrid( -1, true, division, DATA.CurState.Project.swingmode~1, DATA.CurState.Project.swingamt )
      end
      if params.setswing then
        GetSetProjectGrid( -1, true, division, DATA.CurState.Project.swingmode, params.setswing )
      end
      if params.setswing_format then 
        local outputval = lim(params.setswing_format/100,-1,1)
        GetSetProjectGrid( -1, true, division, DATA.CurState.Project.swingmode, outputval )
      end
      
      -- grid
      if params.toggeltriplet then
        if DATA.CurState.Project.grid_istriplet ==true then 
          GetSetProjectGrid( 0, true, DATA.CurState.Project.grid_division  * 3/2, DATA.CurState.Project.swingmode, DATA.CurState.Project.swingamt )
         else
          GetSetProjectGrid( 0, true, DATA.CurState.Project.grid_division  * 2/3, DATA.CurState.Project.swingmode, DATA.CurState.Project.swingamt )
        end
      end
      if params.togglegrid then
        Main_OnCommand(1157, 0) -- switch grid
        if GetToggleCommandState(1157)~= GetToggleCommandState(40145) then  
          Main_OnCommand(40145,0) -- lines follow grid
        end 
        RefreshToolbar2( 0, 40145 )
        RefreshToolbar2( 0, 1157 )
      end 
      if params.togglegridrel then
        Main_OnCommand(41054, 0) -- switch rel
        RefreshToolbar2( 0, 41054 )
      end 
      if params.setgrid then
        local out_division = math.floor(params.setgrid) 
        out_division = lim(out_division,0,5)
        -- normalize from triplet
        if DATA.CurState.Project.grid_istriplet ==true then out_division = out_division  * 3/2 end 
        out_division = math.floor(out_division)
        local out_division = 1/(2^out_division)
        if DATA.CurState.Project.grid_istriplet ==true then out_division = out_division  * 2/3 end 
        GetSetProjectGrid( -1, true, out_division)
      end
      
      
      -- recursively run local update
      DATA:CollectData_Project_Grid()
    end
  end
  ---------------------------------------------------
  function DATA:CollectData_Project_TimeSel(set, params) 
    if not DATA.CurState.Project then DATA.CurState.Project = {} end
    local TS_st, TS_end = GetSet_LoopTimeRange2( -1, false, false, -1, -1, false )
    
    DATA.CurState.Project.TS_st = TS_st
    DATA.CurState.Project.TS_end = TS_end
    DATA.CurState.Project.TS_len = TS_end-TS_st
    
    DATA.CurState.Project.TS_st_format = Utils_formattimestr( TS_st, '',EXT.CONF_widg_time_formatoverride ) 
    DATA.CurState.Project.TS_st_format_t = Utils_SplitValues(DATA.CurState.Project.TS_st_format)
    
    DATA.CurState.Project.TS_end_format = Utils_formattimestr(TS_end, '', EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Project.TS_end_format_t = Utils_SplitValues(DATA.CurState.Project.TS_end_format)
    
    DATA.CurState.Project.TS_len_format = Utils_formattimestr_len(TS_end-TS_st, '', TS_st,EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Project.TS_len_format_t = Utils_SplitValues(DATA.CurState.Project.TS_len_format)
    
    
    
    if set and params then 
      local snap_area = 0.2
      
      if params.set_tslen or params.set_tslen_format then
        local out = 0
        if params.set_tslen then out = params.set_tslen end
        if params.set_tslen_format then out = parse_timestr_len( params.set_tslen_format, DATA.CurState.Project.TS_st, EXT.CONF_widg_time_formatoverride ) end
        local endpoint = out + TS_st
        if EXT.CONF_widg_time_snaptogrid&1==1 and DATA.CurState.Project.grid_enabled == true and math.abs(endpoint - SnapToGrid( -1, endpoint )) < snap_area then  endpoint = SnapToGrid( -1, endpoint ) end
        GetSet_LoopTimeRange2( -1, true, true, TS_st,  endpoint, false )
        Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      end
      
      if params.set_tsend or params.set_tsend_format then
        local out = params.set_tsend
        if params.set_tsend_format then out = parse_timestr_pos( params.set_tsend_format, EXT.CONF_widg_time_formatoverride ) end
        if EXT.CONF_widg_time_snaptogrid&1==1 and DATA.CurState.Project.grid_enabled == true and math.abs(out - SnapToGrid( -1, out )) < snap_area then  out = SnapToGrid( -1, out ) end
        GetSet_LoopTimeRange2( -1, true, true, out-DATA.CurState.Project.TS_len, out, false )
        Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      end
      
      if params.set_tsst or params.set_tsst_format then
        local out = params.set_tsst
        if params.set_tsst_format then out = parse_timestr_pos( params.set_tsst_format , EXT.CONF_widg_time_formatoverride ) end
        if EXT.CONF_widg_time_snaptogrid&1==1 and DATA.CurState.Project.grid_enabled == true and math.abs(out - SnapToGrid( -1, out )) < snap_area then  out = SnapToGrid( -1, out ) end
        GetSet_LoopTimeRange2( -1, true, true, out, out+DATA.CurState.Project.TS_len, false )
        Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      end
      if params.set_tsledge or params.set_tsledge_format then
        local out = params.set_tsledge
        if params.set_tsledge_format then out = parse_timestr_pos( params.set_tsledge_format, EXT.CONF_widg_time_formatoverride ) end
        if EXT.CONF_widg_time_snaptogrid&1==1 and DATA.CurState.Project.grid_enabled == true and math.abs(out - SnapToGrid( -1, out )) < snap_area then  out = SnapToGrid( -1, out ) end
        GetSet_LoopTimeRange2( -1, true, true, out, DATA.CurState.Project.TS_end, false )
        Main_OnCommand(40749,0) -- Options: Set loop points linked to time selection
      end
      
      -- recursively run local update
      DATA:CollectData_Project_TimeSel()
    end
  end
  --------------------------------------------------- 
  function DATA:CollectData_Project_LTFX(set,params)
    DATA.CurState.LTFX = {}
    DATA.CurState.LTFX.exist = false
    local ret, tr, fx, param = GetLastTouchedFX()
    local retval, tr, itemidx, takeidx, fx, param = reaper.GetTouchedOrFocusedFX( 0)
    if retval and itemidx == -1 then
      local tr = GetTrack( -1,tr)
      local isvalid = reaper.ValidatePtr2(-1, tr, 'MediaTrack*' )
      if isvalid ==true then
        
        DATA.CurState.LTFX.exist = true
        DATA.CurState.LTFX_trptr = tr
        DATA.CurState.LTFX_fxID = fx
        DATA.CurState.LTFX_parID = param
        _, DATA.CurState.LTFX_fxname = TrackFX_GetFXName( tr, fx, '' )  
        DATA.CurState.LTFX_fxname = Utils_ReduceFXname(DATA.CurState.LTFX_fxname)
        local ret, paramname = TrackFX_GetParamName( tr, fx, param, '' )
        if paramname:match('%:(.*)') then paramname = paramname:match('%:(.*)') end
        DATA.CurState.LTFX_parname = paramname
        DATA.CurState.LTFX_val =  TrackFX_GetParamNormalized( tr, fx, param )
        local _, LTFX_val_format = TrackFX_GetFormattedParamValue( tr, fx, param, '' )
        DATA.CurState.LTFX_val_format = LTFX_val_format
        local retval, step, smallstep, largestep, istoggle = reaper.TrackFX_GetParameterStepSizes( tr, fx, param)
        local istoggle_inverted
        if paramname:lower():match('bypass') then istoggle = true istoggle_inverted = true end
        DATA.CurState.LTFX_istoggle = istoggle
        DATA.CurState.LTFX_istoggle_inverted = istoggle_inverted
      end
    end
    
    if set and params then 
      local outparamval =  params.set_fxparam
      if params.set_fxparam then
        reaper.TrackFX_SetParamNormalized( DATA.CurState.LTFX_trptr, DATA.CurState.LTFX_fxID, DATA.CurState.LTFX_parID, params.set_fxparam )
      end
      if params.set_fxparam_formatted then
        outparamval =  Utils_BFpluginparam(params.set_fxparam_formatted, DATA.CurState.LTFX_trptr, DATA.CurState.LTFX_fxID, DATA.CurState.LTFX_parID) 
      end
      
      -- app envelope
      if outparamval and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Mod_Ctrl()) then
        if GetPlayStateEx(-1)&1==1 and GetPlayStateEx(-1)&2~=2 then  -- playing/not paused
          local env = GetFXEnvelope( DATA.CurState.LTFX_trptr, DATA.CurState.LTFX_fxID, DATA.CurState.LTFX_parID, true )
          local time = GetPlayPosition2Ex( -1 )
          --InsertEnvelopePoint( env, time, outparamval, 0, 0, 0, false )
          --reaper.UpdateTimeline()
         else
          local env = GetFXEnvelope( DATA.CurState.LTFX_trptr, DATA.CurState.LTFX_fxID, DATA.CurState.LTFX_parID, true )
          if env then 
            local time = GetCursorPositionEx( -1 )
            local pt = GetEnvelopePointByTime( env, time )
            local retval, timecloserpt, value, shape, tension, selected = reaper.GetEnvelopePoint( env, pt )
            if math.abs(time - timecloserpt) > 0.04 then 
              pt = InsertEnvelopePoint( env, time, outparamval, 0, 0, 0, false )
             else
              SetEnvelopePoint( env, pt, time, outparamval, 0, 0, 0, false )
            end
            reaper.UpdateTimeline()
          end
        end
      end
      
      DATA:CollectData_Project_LTFX()-- recursively run local update
    end
    
  end  
  ---------------------------------------------------  
  function DATA:CollectData_Project_Various(set,params)
    if not DATA.CurState.Project then DATA.CurState.Project = {} end
    DATA.CurState.Project.SR = Utils_GetProjectSampleRate()
    DATA.CurState.Project.FR = TimeMap_curFrameRate( -1 ) 
    DATA.CurState.Project.CountTempoTimeSigMarkers = CountTempoTimeSigMarkers( -1 )
    
  end
  ---------------------------------------------------  
  function DATA:CollectData_Project_Transport(set,params)
    if not DATA.CurState.Transport then DATA.CurState.Transport = {} end
    local playstate = GetPlayStateEx( -1 ) 
    DATA.CurState.Transport.play = playstate&1==1
    DATA.CurState.Transport.pause = playstate&2==2
    DATA.CurState.Transport.record = playstate&4==4
    DATA.CurState.Transport.repeat_state = GetSetRepeatEx( -1, -1 )
    if set and params then 
      if params.setplay then OnPlayButtonEx(-1) end
      if params.setpause then OnPauseButtonEx(-1) end
      if params.setstop then OnStopButtonEx(-1) end
      if params.setrecord then CSurf_OnRecord() end
      if params.repeat2 then GetSetRepeatEx( -1,2 ) end
      DATA:CollectData_Project_Transport() -- recursively run local update
    end
  end
  ---------------------------------------------------  
  function DATA:CollectData_Project_Tempo(set,params)
    if not DATA.CurState.Tempo then DATA.CurState.Tempo = {} end
    
    local int_TM = FindTempoTimeSigMarker( 0, DATA.upd_last_editcurpos )
    DATA.CurState.Tempo.TempoMarker_ID = int_TM
    if int_TM == -1 then 
      local bpm= Master_GetTempo()
      local _, timesig_num = GetProjectTimeSignature2( 0 )
      local _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, 0 )
      DATA.CurState.Tempo.TempoMarker_timesig1 = math.floor(timesig_num)
      DATA.CurState.Tempo.TempoMarker_timesig2 = math.floor(timesig_denom)
      DATA.CurState.Tempo.TempoMarker_bpm= bpm 
      DATA.CurState.Tempo.TempoMarker_lineartempochange = false
     else
      local _, timepos, measureposOut, beatposOut, bpm, timesig_num, timesig_denom, lineartempoOut = GetTempoTimeSigMarker( -1, int_TM )
      DATA.CurState.Tempo.TempoMarker_bpm= bpm
      DATA.CurState.Tempo.TempoMarker_lineartempochange = lineartempoOut
      DATA.CurState.Tempo.TempoMarker_timepos = timepos
      DATA.CurState.Tempo.TempoMarker_timesig_num = timesig_num
      DATA.CurState.Tempo.TempoMarker_timesig_denom = timesig_denom
      if timesig_num > 0 and timesig_denom > 0  then
        DATA.CurState.Tempo.TempoMarker_timesig1 = math.floor(timesig_num)
        DATA.CurState.Tempo.TempoMarker_timesig2 = math.floor(timesig_denom)
       else
        local _, timesig_num = GetProjectTimeSignature2( 0 )
        local _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, 0 )
        DATA.CurState.Tempo.TempoMarker_timesig1 = math.floor(timesig_num)
        DATA.CurState.Tempo.TempoMarker_timesig2 = math.floor(timesig_denom)
      end
    end
    if DATA.CurState.Tempo.TempoMarker_bpm then DATA.CurState.Tempo.TempoMarker_bpm_format= string.format("%.1f", DATA.CurState.Tempo.TempoMarker_bpm) end
    DATA.CurState.Tempo.TempoMarker_timesig_format = DATA.CurState.Tempo.TempoMarker_timesig1..'/'..DATA.CurState.Tempo.TempoMarker_timesig2
    
    if set and params then 
      
      if params.settempo or params.changetempo then 
        local new_tempo = DATA.CurState.Tempo.TempoMarker_bpm
        if params.settempo then new_tempo = params.settempo end
        if params.changetempo then new_tempo = new_tempo + params.changetempo*0.5 end
        if DATA.CurState.Tempo.TempoMarker_ID == -1 then 
          CSurf_OnTempoChange(  tonumber (new_tempo) )
          UpdateTimeline()
         else 
          SetTempoTimeSigMarker( -1, DATA.CurState.Tempo.TempoMarker_ID, 
                                    DATA.CurState.Tempo.TempoMarker_timepos, 
                                    -1, 
                                    -1, 
                                    tonumber (new_tempo), 
                                    DATA.CurState.Tempo.TempoMarker_timesig_num, 
                                    DATA.CurState.Tempo.TempoMarker_timesig_denom, 
                                    DATA.CurState.Tempo.TempoMarker_lineartempochange )
          UpdateTimeline()
        end
      end
      
      if params.addtempomarker then 
        SetTempoTimeSigMarker( -1, -1, 
                                  DATA.CurState.editcurpos, 
                                  -1, 
                                  -1, 
                                  params.addtempomarker, 
                                  0, 
                                  0, 
                                  0 )
        UpdateTimeline()
      end
      
      if params.stretchitem and DATA.CurState.Tempo.TempoMarker_bpm then 
        local new_rate = DATA.CurState.Tempo.TempoMarker_bpm / params.stretchitem
        for i = 1 , CountSelectedMediaItems(0) do
          local item = GetSelectedMediaItem(0, i-1)
          local take = GetActiveTake(item)
          if take then 
            local D_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH' )
            SetMediaItemInfo_Value( item, 'D_LENGTH', D_LENGTH /new_rate  )
            SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE', new_rate ) 
          end 
        end
        UpdateArrange()
      end
      
      
      if params.settimesig then 
        if not params.settimesig:match('(%d+)%/(%d+)') then return end
        local num, denom = params.settimesig:match('(%d+)%/(%d+)')
        if not tonumber(num) or not tonumber(denom) then return end
        if DATA.CurState.Tempo.TempoMarker_ID ~= -1 then 
          SetTempoTimeSigMarker( -1, DATA.CurState.Tempo.TempoMarker_ID, 
                                      DATA.CurState.Tempo.TempoMarker_timepos, 
                                      -1, 
                                      -1, 
                                      DATA.CurState.Tempo.TempoMarker_bpm, 
                                      tonumber(num), 
                                      tonumber(denom), 
                                      DATA.CurState.Tempo.TempoMarker_lineartempochange )
            UpdateTimeline()
          else 
          SetTempoTimeSigMarker( -1,-1, 
                                      DATA.CurState.Tempo.editcur_pos, 
                                      -1, 
                                      -1, 
                                      DATA.CurState.Tempo.TempoMarker_bpm, 
                                      tonumber(num), 
                                      tonumber(denom), 
                                      DATA.CurState.Tempo.TempoMarker_lineartempochange )
            UpdateTimeline()                                     
        end
      end
      DATA:CollectData_Project_Tempo() -- recursively run local update
    end 
  end
  ----------------------------------------------------  
  function DATA:WriteData_Item_ApplyToSelection(params)
    local src_item = reaper.GetSelectedMediaItem(-1,0)
    local src_D_POSITION = GetMediaItemInfo_Value( src_item, 'D_POSITION')
    local src_D_LENGTH = GetMediaItemInfo_Value( src_item, 'D_LENGTH')
    local src_D_END = src_D_POSITION + src_D_LENGTH 
    local src_D_VOL = GetMediaItemInfo_Value( src_item, 'D_VOL')
    
    local src_take = GetActiveTake(src_item)
    local src_D_STARTOFFS
    local src_D_PITCH
    local src_D_PLAYRATE
    if src_take then 
      src_D_STARTOFFS = GetMediaItemTakeInfo_Value( src_take, 'D_STARTOFFS' )
      src_D_PITCH = GetMediaItemTakeInfo_Value( src_take, 'D_PITCH' )
      src_D_PLAYRATE = GetMediaItemTakeInfo_Value( src_take, 'D_PLAYRATE' )
      src_D_PAN = GetMediaItemTakeInfo_Value( src_take, 'D_PAN' )
    end
    
    for i = 1, CountSelectedMediaItems(-1) do
      local item = reaper.GetSelectedMediaItem(-1,i-1)
      local D_POSITION = GetMediaItemInfo_Value( item, 'D_POSITION')
      local D_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH')
      local D_VOL = GetMediaItemInfo_Value( item, 'D_VOL')
      
      if item then 
        local take = GetActiveTake(item)
        local D_STARTOFFS if take then    D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' ) end
        local D_PITCH if take then        D_PITCH = GetMediaItemTakeInfo_Value( take, 'D_PITCH' ) end
        local D_PLAYRATE if take then     D_PLAYRATE = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' ) end
        local D_PAN if take then          D_PAN = GetMediaItemTakeInfo_Value( take, 'D_PAN' ) end
        
        local take = GetActiveTake(item)
        if take then 
          -- take abs
            if params.set_color then              SetMediaItemTakeInfo_Value( take, 'I_CUSTOMCOLOR', params.set_color ) end
            if params.toggle_preservepitch then   SetMediaItemTakeInfo_Value( take, 'B_PPITCH', params.toggle_preservepitch ) end
            if params.set_chanmode then           SetMediaItemTakeInfo_Value( take, 'I_CHANMODE', params.set_chanmode ) end
            --if params.toggle_reverse then         SetMediaItemTakeInfo_Value( take, '', params.set_chanmode ) end -- moved further, since not possible from reascript native API
            
          -- take relative
            if params.set_offset then     local diff = params.set_offset - src_D_STARTOFFS     SetMediaItemTakeInfo_Value( take, 'D_STARTOFFS', D_STARTOFFS + diff ) end
            if params.set_pitch then  
              local outputval = lim(params.set_pitch,-48,48)
              local diff = outputval - src_D_PITCH          
              SetMediaItemTakeInfo_Value( take, 'D_PITCH', lim(D_PITCH + diff,-48,48) ) 
            end
            if params.set_rate then       
              local outputval = lim(params.set_rate,0.1,100)
              local diff = outputval - src_D_PLAYRATE   
              local new_rate = lim(D_PLAYRATE + diff,0.1,100)
              SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE', new_rate )
              SetMediaItemInfo_Value( item, 'D_LENGTH', D_LENGTH * D_PLAYRATE /new_rate ) 
            end 
            if params.set_pan then        
              local outputval = lim(params.set_pan,-1,1)
              local diff = outputval - src_D_PAN              
              SetMediaItemTakeInfo_Value( take, 'D_PAN', lim(D_PAN + diff,-1,1) ) 
            end
        end
        
        
        -- item absolute
          if params.toggle_lock then              SetMediaItemInfo_Value( item, 'C_LOCK', params.toggle_lock ) end
          if params.toggle_loop then              SetMediaItemInfo_Value( item, 'B_LOOPSRC', params.toggle_loop ) end
          if params.toggle_mute then              SetMediaItemInfo_Value( item, 'B_MUTE', params.toggle_mute ) end 
          if params.set_snap then                 SetMediaItemInfo_Value( item, 'D_SNAPOFFSET', params.set_snap ) end
          if params.set_fadein then               SetMediaItemInfo_Value( item, 'D_FADEINLEN', params.set_fadein ) end
          if params.set_fadeout then               SetMediaItemInfo_Value( item, 'D_FADEOUTLEN', params.set_fadeout ) end
          if params.set_timebase then              
            if params.set_timebase == 0 then 
              SetMediaItemInfo_Value( item, 'C_BEATATTACHMODE', -1 ) 
              SetMediaItemInfo_Value( item, 'C_AUTOSTRETCH', 0 ) 
             elseif params.set_timebase == 1 then 
              SetMediaItemInfo_Value( item, 'C_BEATATTACHMODE', 1 ) 
              SetMediaItemInfo_Value( item, 'C_AUTOSTRETCH', 1 ) 
             elseif params.set_timebase == 2 then 
              SetMediaItemInfo_Value( item, 'C_BEATATTACHMODE', 1 ) 
              SetMediaItemInfo_Value( item, 'C_AUTOSTRETCH', 0 )      
             elseif params.set_timebase == 3 then 
              SetMediaItemInfo_Value( item, 'C_BEATATTACHMODE', 2 ) 
              SetMediaItemInfo_Value( item, 'C_AUTOSTRETCH', 0 ) 
             elseif params.set_timebase == 4 then 
              SetMediaItemInfo_Value( item, 'C_BEATATTACHMODE', 0 ) 
              SetMediaItemInfo_Value( item, 'C_AUTOSTRETCH', 0 )             
            end
          end 
          
        -- item relative          
          if params.set_pos then                local diff = params.set_pos - src_D_POSITION        SetMediaItemInfo_Value( item, 'D_POSITION', diff + D_POSITION )  end
          if params.set_ledge then              local diff = params.set_ledge - src_D_POSITION      SetMediaItemInfo_Value( item, 'D_POSITION', diff + D_POSITION )  
                                                                                                    SetMediaItemInfo_Value( item, 'D_LENGTH', D_LENGTH - diff ) end
          if params.set_redge then              local diff = params.set_redge - src_D_END           SetMediaItemInfo_Value( item, 'D_LENGTH', D_LENGTH + diff ) end
          if params.set_length then             local diff = params.set_length - src_D_LENGTH       SetMediaItemInfo_Value( item, 'D_LENGTH', D_LENGTH + diff ) end
          if params.set_vol then                local diff = params.set_vol - src_D_VOL             SetMediaItemInfo_Value( item, 'D_VOL', D_VOL + diff ) end
        
        
        
      end
    end
    
    if params.toggle_reverse ~=nil then reaper.Main_OnCommandEx(41051,0,-1) end -- Item properties: Toggle take reverse
    
    
  end
  ----------------------------------------------------  
  function DATA:CollectData_Item_Multiple() 
    if not DATA.CurState.Item then DATA.CurState.Item = {} end
    DATA.CurState.Item.COMLEN = 0
    DATA.CurState.Item.COMLEN_min = 0
    DATA.CurState.Item.COMLEN_max = 0
    DATA.CurState.Item.COMLEN_format = Utils_formattimestr_len( DATA.CurState.Item.COMLEN, '', DATA.CurState.Item.COMLEN_min, EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Item.COMLEN_format_t = Utils_SplitValues(DATA.CurState.Item.COMLEN_format)
    
    if CountSelectedMediaItems(-1) ==0 then return end
    
    DATA.CurState.Item.COMLEN_min = math.huge
    DATA.CurState.Item.COMLEN_max = 0
    for i = 1, CountSelectedMediaItems(-1) do
      local item = reaper.GetSelectedMediaItem(-1,i-1)
      local D_POSITION = GetMediaItemInfo_Value( item, 'D_POSITION')
      local D_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH')
      DATA.CurState.Item.COMLEN_min = math.min(DATA.CurState.Item.COMLEN_min, D_POSITION)
      DATA.CurState.Item.COMLEN_max = math.max(DATA.CurState.Item.COMLEN_max, D_POSITION+D_LENGTH)
    end
    DATA.CurState.Item.COMLEN = DATA.CurState.Item.COMLEN_max - DATA.CurState.Item.COMLEN_min 
    DATA.CurState.Item.COMLEN_format = Utils_formattimestr_len( DATA.CurState.Item.COMLEN, '', DATA.CurState.Item.COMLEN_min, EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Item.COMLEN_format_t = Utils_SplitValues(DATA.CurState.Item.COMLEN_format)
  end
  ----------------------------------------------------  
  function DATA:WriteData_MIDIEditor(params) 
    local ME = MIDIEditor_GetActive()
    local take = MIDIEditor_GetTake( ME )
    if not take then return end
    
    if params.set_name then 
      GetSetMediaItemTakeInfo_String( take, "P_NAME", params.set_name, true ) 
    end
    
    DATA:CollectData_MIDIEditor() 
  end
  ----------------------------------------------------  
    function DATA:CollectData_Envelope() 
      if not DATA.CurState.Envelope then DATA.CurState.Envelope = {} end
    
    local env = GetSelectedEnvelope( -1 )
    if not env then return end
    
    -- reset 
      DATA.CurState.Envelope.env_ptr = env
      DATA.CurState.Envelope.fxid = nil
      DATA.CurState.Envelope.selectedpoints = {}
      DATA.CurState.Envelope.scaling_mode = GetEnvelopeScalingMode( env )
      DATA.CurState.Envelope.sel_point = {}
             
    -- name
      local retval, envname = reaper.GetEnvelopeName( env )
      DATA.CurState.Envelope.name  =envname
    
    -- get AI 
      local autoitem_idx=  -1
      DATA.CurState.Envelope.autoitem = {}
      for AI_idx = 1,  reaper.CountAutomationItems( env ) do
        local D_UISEL = reaper.GetSetAutomationItemInfo( env, AI_idx-1, 'D_UISEL', 0, 0 )
        if D_UISEL>0 then autoitem_idx=AI_idx-1  break end
      end 
      DATA.CurState.Envelope.autoitem_idx = autoitem_idx
      if autoitem_idx ~= -1 then 
        DATA.CurState.Envelope.autoitem.D_POSITION = GetSetAutomationItemInfo( env, autoitem_idx, 'D_POSITION', 0, 0 )
        DATA.CurState.Envelope.autoitem.D_POOL_QNLEN = GetSetAutomationItemInfo( env, autoitem_idx, 'D_POOL_QNLEN', 0, 0 )
        DATA.CurState.Envelope.autoitem.D_POOL_LEN = TimeMap2_QNToTime( -1,DATA.CurState.Envelope.autoitem.D_POOL_QNLEN )
        DATA.CurState.Envelope.autoitem.D_POOL_LEN_format = Utils_formattimestr_len( DATA.CurState.Envelope.autoitem.D_POOL_LEN, '', DATA.CurState.Envelope.autoitem.D_POSITION, EXT.CONF_widg_time_formatoverride )
        DATA.CurState.Envelope.autoitem.D_POOL_LEN_format_t = Utils_SplitValues(DATA.CurState.Envelope.autoitem.D_POOL_LEN_format)
      end
      
    -- parent pointers / fx / param
      local track, fxid, paramid = Envelope_GetParentTrack( env )
      local take, fxid, paramid = Envelope_GetParentTake( env )
      if track then
        local retval, name = GetSetMediaTrackInfo_String( track, 'P_NAME', '', false ) 
        DATA.CurState.Envelope.srcUIname = name
        DATA.CurState.Envelope.srctype = 'Track'
        DATA.CurState.Envelope.srcptr = track
       elseif take then 
        DATA.CurState.Envelope.srcUIname = GetTakeName( take )
        DATA.CurState.Envelope.srctype = 'Take'
        DATA.CurState.Envelope.srcptr = take
      end
      DATA.CurState.Envelope.fxname = ''
      if fxid~=-1 then 
        DATA.CurState.Envelope.fxid = fxid
        DATA.CurState.Envelope.paramid = paramid
        local retval, buf = _G[DATA.CurState.Envelope.srctype..'FX_GetFXName']( DATA.CurState.Envelope.srcptr, fxid )
        buf = Utils_ReduceFXname(buf)
        DATA.CurState.Envelope.fxname = buf 
        if envname:match('[%/%\\]') then envname = envname:match('(.*)[%/%\\]') end
        DATA.CurState.Envelope.name  =envname
        DATA.CurState.Envelope.FXbypstate = _G[DATA.CurState.Envelope.srctype..'FX_GetEnabled']( DATA.CurState.Envelope.srcptr, fxid  )  
        local retval, curvalue_format = _G[DATA.CurState.Envelope.srctype..'FX_GetFormattedParamValue'](  DATA.CurState.Envelope.srcptr, fxid,paramid )
        DATA.CurState.Envelope.curvalue_format = curvalue_format
      end
    
    -- overrides 
      DATA.CurState.Envelope.volume_mode = DATA.CurState.Envelope.fxid == nil and DATA.CurState.Envelope.name:match('Volume')~=nil
      
    -- selection
      local selected_ptidx
      local cnt = CountEnvelopePointsEx( env, autoitem_idx )
      local sel_point_table_id = 0
      for ptidx=1,cnt  do
        local retval, time, value, shape, tension, selected = GetEnvelopePointEx( env, autoitem_idx, ptidx-1 )
        if selected ==true then 
          if not selected_ptidx then selected_ptidx = ptidx-1 end -- get first selected point
          sel_point_table_id = sel_point_table_id + 1
          DATA.CurState.Envelope.selectedpoints[sel_point_table_id] = ptidx-1
        end 
      end 
    
    -- first selected point
      if selected_ptidx then 
        DATA.CurState.Envelope.sel_point.id = selected_ptidx
        local retval, time, value, shape, tension = GetEnvelopePointEx( env, autoitem_idx, selected_ptidx )
        if DATA.CurState.Envelope.autoitem_idx ~= -1 then time = time - DATA.CurState.Envelope.autoitem.D_POSITION end
        DATA.CurState.Envelope.sel_point.D_POSITION = time
        DATA.CurState.Envelope.sel_point.D_POSITION_format = Utils_formattimestr(DATA.CurState.Envelope.sel_point.D_POSITION, '', EXT.CONF_widg_time_formatoverride )
        DATA.CurState.Envelope.sel_point.D_POSITION_format_t = Utils_SplitValues(DATA.CurState.Envelope.sel_point.D_POSITION_format)
        
        value = ScaleFromEnvelopeMode( DATA.CurState.Envelope.scaling_mode,value) 
        DATA.CurState.Envelope.sel_point.D_VAL = value
        DATA.CurState.Envelope.sel_point.D_VAL_format = tostring(math.floor(value*1000)/1000)
        
        -- format override for volume
        if DATA.CurState.Envelope.volume_mode ==true then
          DATA.CurState.Envelope.sel_point.D_VAL_format = string.format("%.2f", WDL_VAL2DB(DATA.CurState.Envelope.sel_point.D_VAL))..'db'
        end
      end
    
  end
  
  ----------------------------------------------------  
  function DATA:CollectData_MIDIEditor() 
    if not DATA.CurState.MIDIEditor then DATA.CurState.MIDIEditor = {} end
    
    local s_unpack = string.unpack
    local s_pack   = string.pack
    
    -- take
      local ME = MIDIEditor_GetActive()
      local take = MIDIEditor_GetTake( ME )
      if not take then return end
    
    -- item
      local item  = GetMediaItemTake_Item( take )
      local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION')
      DATA.CurState.MIDIEditor.item_pos = item_pos
      DATA.CurState.MIDIEditor.item_ptr = item
      DATA.CurState.MIDIEditor.sel_evt = nil
      
    -- take name
      local _, take_name = GetSetMediaItemTakeInfo_String( take, "P_NAME", '', false ) 
      DATA.CurState.MIDIEditor.take_name = take_name
      
    -- init
      DATA.CurState.MIDIEditor.evts = {}
      local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
      if not gotAllOK then return end
      local MIDIlen = MIDIstring:len()
      local idx, ppq_pos, offset, flags, msg1,selected = 0,0 
      local nextPos, prevPos = 1, 1  
      local note_open = {}
      local is3byte
      
    -- parse RAW MIDI data
      local sel_evt_idx
      while nextPos <= MIDIlen do  
        prevPos = nextPos
        offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
        ppq_pos = ppq_pos + offset
        selected = flags&1==1
        muted = flags&2==2 
        
        local is3byte = msg1:len() == 3
        -- handle note off / on
        local byte2 = msg1:byte(2)
        local isNoteOn = msg1:byte(1)>>4 == 0x9 
        local isNoteOff = msg1:byte(1)>>4 == 0x8 or (msg1:byte(1)>>4 == 0x9 and msg1:byte(3)==0) 
        if isNoteOff ~= true then idx = idx + 1 end
        
        if isNoteOn then 
          if not note_open[byte2] then note_open[byte2] = {} end 
          note_open[byte2][#note_open[byte2] + 1] = idx 
        end
        if isNoteOff then 
          local noteOn_on_same_pitch_idx 
          if note_open[byte2] and note_open[byte2][1] then 
            noteOn_on_same_pitch_idx = note_open[byte2][1]
            table.remove(note_open[byte2],1)
          end
          if noteOn_on_same_pitch_idx then 
            DATA.CurState.MIDIEditor.evts[noteOn_on_same_pitch_idx].ppq_pos2 = ppq_pos
            DATA.CurState.MIDIEditor.evts[noteOn_on_same_pitch_idx].msg1_OFF = msg1
            goto skipnextevt
          end
        end
        
        
        if not sel_evt_idx and selected == true then sel_evt_idx = idx end
        DATA.CurState.MIDIEditor.evts[idx] = {
            int_type = msg1:byte(1)>>4,
            msg1=msg1,
            ppq_pos=ppq_pos,
            flags=flags,
            selected=selected,
            muted=muted,
            offset=offset,
            is3byte = is3byte,
            }
            
        ::skipnextevt::
      end
      
      DATA.CurState.MIDIEditor.max_ppq = DATA.CurState.MIDIEditor.evts[#DATA.CurState.MIDIEditor.evts].ppq_pos
      
      if sel_evt_idx then
        
        DATA.CurState.MIDIEditor.sel_evt = {idx = sel_evt_idx }
        
        local str_type = '[Other]'
        if DATA.CurState.MIDIEditor.evts[sel_evt_idx].int_type == 0x9 then str_type = 'Note' 
         elseif DATA.CurState.MIDIEditor.evts[sel_evt_idx].int_type == 0xA then str_type = 'Poly AT' 
         elseif DATA.CurState.MIDIEditor.evts[sel_evt_idx].int_type == 0xB then str_type = 'CC' 
         elseif DATA.CurState.MIDIEditor.evts[sel_evt_idx].int_type == 0xC then str_type = 'Program Ch' 
         elseif DATA.CurState.MIDIEditor.evts[sel_evt_idx].int_type == 0xD then str_type = 'Chan AT' 
         elseif DATA.CurState.MIDIEditor.evts[sel_evt_idx].int_type == 0xE then str_type = 'Pitch Wheel'  
        end
        DATA.CurState.MIDIEditor.sel_evt.str_type = str_type
        DATA.CurState.MIDIEditor.sel_evt.int_type = DATA.CurState.MIDIEditor.evts[sel_evt_idx].int_type
        DATA.CurState.MIDIEditor.sel_evt.is3byte = DATA.CurState.MIDIEditor.evts[sel_evt_idx].is3byte
        DATA.CurState.MIDIEditor.sel_evt.msg1 = DATA.CurState.MIDIEditor.evts[sel_evt_idx].msg1
        DATA.CurState.MIDIEditor.sel_evt.CHAN = DATA.CurState.MIDIEditor.evts[sel_evt_idx].msg1:byte(1)&0x0F
        DATA.CurState.MIDIEditor.sel_evt.CHAN_format = math.floor(DATA.CurState.MIDIEditor.sel_evt.CHAN+1) 
        if DATA.CurState.MIDIEditor.sel_evt.CHAN == 0 then DATA.CurState.MIDIEditor.sel_evt.CHAN_format = 'All' end
        
        DATA.CurState.MIDIEditor.sel_evt.D_POSITION = MIDI_GetProjTimeFromPPQPos( take, DATA.CurState.MIDIEditor.evts[sel_evt_idx].ppq_pos ) -  item_pos
        DATA.CurState.MIDIEditor.sel_evt.D_POSITION_format = Utils_formattimestr( DATA.CurState.MIDIEditor.sel_evt.D_POSITION, '', EXT.CONF_widg_time_formatoverride )
        DATA.CurState.MIDIEditor.sel_evt.D_POSITION_format_t = Utils_SplitValues(DATA.CurState.MIDIEditor.sel_evt.D_POSITION_format)
        
        -- note len
        if DATA.CurState.MIDIEditor.sel_evt.int_type == 0x9 and DATA.CurState.MIDIEditor.evts[sel_evt_idx].ppq_pos and DATA.CurState.MIDIEditor.evts[sel_evt_idx].ppq_pos2 then
          local start_pos = MIDI_GetProjTimeFromPPQPos( take, DATA.CurState.MIDIEditor.evts[sel_evt_idx].ppq_pos)
          local end_pos = MIDI_GetProjTimeFromPPQPos( take, DATA.CurState.MIDIEditor.evts[sel_evt_idx].ppq_pos2 )
          DATA.CurState.MIDIEditor.sel_evt.start_pos = start_pos
          DATA.CurState.MIDIEditor.sel_evt.D_LENGTH = end_pos - start_pos
          DATA.CurState.MIDIEditor.sel_evt.D_LENGTH_format = Utils_formattimestr_len(DATA.CurState.MIDIEditor.sel_evt.D_LENGTH, '', start_pos, EXT.CONF_widg_time_formatoverride )
          DATA.CurState.MIDIEditor.sel_evt.D_LENGTH_format_t = Utils_SplitValues(DATA.CurState.MIDIEditor.sel_evt.D_LENGTH_format)
        end
         
        -- note PITCH
        if DATA.CurState.MIDIEditor.sel_evt.int_type == 0x9 then
          DATA.CurState.MIDIEditor.sel_evt.PITCH = DATA.CurState.MIDIEditor.sel_evt.msg1:byte(2)
          DATA.CurState.MIDIEditor.sel_evt.PITCH_format = math.floor(DATA.CurState.MIDIEditor.sel_evt.PITCH)
        end
        
        -- note VEL
        if DATA.CurState.MIDIEditor.sel_evt.int_type == 0x9 then
          DATA.CurState.MIDIEditor.sel_evt.VEL = DATA.CurState.MIDIEditor.sel_evt.msg1:byte(3)
          DATA.CurState.MIDIEditor.sel_evt.VEL_format = math.floor(DATA.CurState.MIDIEditor.sel_evt.VEL)
        end
        
        -- CC
        if DATA.CurState.MIDIEditor.sel_evt.int_type == 0xB then
          DATA.CurState.MIDIEditor.sel_evt.CCVAL = DATA.CurState.MIDIEditor.sel_evt.msg1:byte(3)
          DATA.CurState.MIDIEditor.sel_evt.CCVAL_format = math.floor(DATA.CurState.MIDIEditor.sel_evt.CCVAL)
        end
      end
    
    
  end
  ----------------------------------------------------  
  function DATA:WriteData_MIDIEditor(params) 
    local s_unpack = string.unpack
    local s_pack   = string.pack
    
    -- take
      local ME = MIDIEditor_GetActive()
      local take = MIDIEditor_GetTake( ME )
      if not take then return end
    
    -- item
      local item  = GetMediaItemTake_Item( take )
      local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION')
    
    -- get src 
      local src_D_POSITION = DATA.CurState.MIDIEditor.sel_evt.D_POSITION
      local src_D_LENGTH = DATA.CurState.MIDIEditor.sel_evt.D_LENGTH
      local src_CCVAL = DATA.CurState.MIDIEditor.sel_evt.CCVAL
      local src_PITCH = DATA.CurState.MIDIEditor.sel_evt.PITCH
      local src_VEL = DATA.CurState.MIDIEditor.sel_evt.VEL
      local src_CHAN = DATA.CurState.MIDIEditor.sel_evt.CHAN
    
    -- loop through events / add new modified table
      local evts
      if params.modify_evts == true then
        evts = CopyTable(DATA.CurState.MIDIEditor.evts)
        local cnt_evts  = #evts
        for i = 1, cnt_evts do
          if params.set_pos then  
            if evts[i].selected== true then
              local diff = params.set_pos - src_D_POSITION    
              local ppq_pos = evts[i].ppq_pos
              local D_POSITION = MIDI_GetProjTimeFromPPQPos( take, ppq_pos )
              local outsec = diff + D_POSITION
              local new_ppq = MIDI_GetPPQPosFromProjTime( take, outsec )
              local lim_max = DATA.CurState.MIDIEditor.max_ppq - ppq_pos
              if evts[i].ppq_pos2 then lim_max = DATA.CurState.MIDIEditor.max_ppq - evts[i].ppq_pos2 end
              local ppq_diff = math.min(lim_max, math.floor(new_ppq - ppq_pos)) 
              evts[i].ppq_pos = ppq_pos + ppq_diff
              if evts[i].ppq_pos2 then evts[i].ppq_pos2 = evts[i].ppq_pos2 + ppq_diff end
            end
          end
          
          if params.set_len then  
            if evts[i].selected== true and DATA.CurState.MIDIEditor.evts[i].int_type == 0x9 then -- only valid for notes
              local diff = math.max(params.set_len,0.01) - src_D_LENGTH    
              local ppq_pos = evts[i].ppq_pos2
              local D_LENGTH = MIDI_GetProjTimeFromPPQPos( take, ppq_pos )
              local outsec = diff + D_LENGTH
              local new_ppq = MIDI_GetPPQPosFromProjTime( take, outsec )--math.max(,ppq_pos + 10)
              local lim_max = DATA.CurState.MIDIEditor.max_ppq - ppq_pos
              local ppq_diff = math.min(lim_max, math.floor(new_ppq - ppq_pos)) 
              evts[i].ppq_pos2 = ppq_pos + ppq_diff
            end
          end 
          
          if params.set_PITCH then
            local outpitch = params.set_PITCH
            if ImGui.IsKeyDown(ctx, ImGui.Mod_Shift)  then outpitch = src_PITCH + math.ceil(params.set_PITCH - src_PITCH)*12 end
            if evts[i].selected== true and DATA.CurState.MIDIEditor.evts[i].int_type == 0x9 then -- only valid for notes
              local diff = math.floor(outpitch - src_PITCH  )
              local cur_pitch = evts[i].msg1:byte(2)
              local out_pitch = lim(cur_pitch + diff,0,127)
              if i == DATA.CurState.MIDIEditor.sel_evt.idx then DATA.CurState.MIDIEditor.sel_evt.PITCH_format = math.floor(out_pitch) end
              evts[i].msg1 = string.char(evts[i].msg1:byte(1), out_pitch , evts[i].msg1:byte(3) )
              evts[i].msg1_OFF = string.char(evts[i].msg1_OFF:byte(1), out_pitch , evts[i].msg1_OFF:byte(3) )
            end
          end 
          
          if params.set_VEL then
            if evts[i].selected== true and DATA.CurState.MIDIEditor.evts[i].int_type == 0x9 then -- only valid for notes
              local diff = math.floor(params.set_VEL - src_VEL  )
              local cur_VEL = evts[i].msg1:byte(3)
              local out_VEL = lim(cur_VEL + diff,0,127)
              if i == DATA.CurState.MIDIEditor.sel_evt.idx then DATA.CurState.MIDIEditor.sel_evt.VEL_format = math.floor(out_VEL) end
              evts[i].msg1 = string.char(evts[i].msg1:byte(1), evts[i].msg1:byte(2), out_VEL  )
              evts[i].msg1_OFF = string.char(evts[i].msg1_OFF:byte(1), evts[i].msg1_OFF:byte(2), out_VEL  )
            end
          end 
          
          if params.set_CCVAL then  
            if evts[i].selected== true and DATA.CurState.MIDIEditor.evts[i].int_type == 0xB then -- only valid for CC
              local diff = math.floor(params.set_CCVAL - src_CCVAL)
              local curCCVAL = evts[i].msg1:byte(3)
              local outCCVAL = lim(curCCVAL + diff,0,127) 
              if i == DATA.CurState.MIDIEditor.sel_evt.idx then DATA.CurState.MIDIEditor.sel_evt.CCVAL_format = math.floor(outCCVAL) end
              evts[i].msg1 = string.char(evts[i].msg1:byte(1), evts[i].msg1:byte(2), outCCVAL )
            end
          end 
          
          if params.set_CHAN then  
            if evts[i].selected== true and DATA.CurState.MIDIEditor.evts[i].is3byte == true then -- only valid for 3 byte
              local outCHAN = math.floor(lim(params.set_CHAN,0,15.1))
              local outmsgtype = (evts[i].msg1:byte(1)&0xF0)|outCHAN
              if i == DATA.CurState.MIDIEditor.sel_evt.idx then 
                DATA.CurState.MIDIEditor.sel_evt.CHAN_format = math.floor(outCHAN+1) 
                if outCHAN == 0 then DATA.CurState.MIDIEditor.sel_evt.CHAN_format = 'All' end
              end
              evts[i].msg1 = string.char(outmsgtype, evts[i].msg1:byte(2), evts[i].msg1:byte(3) )
              if evts[i].msg1_OFF then 
                local outmsgtype = (evts[i].msg1_OFF:byte(1)&0xF0)|outCHAN
                evts[i].msg1_OFF = string.char(outmsgtype, evts[i].msg1_OFF:byte(2), evts[i].msg1_OFF:byte(3) )
              end
            end
          end 
          
        end
    
      -- concat / apply MIDI string
        local str = ''
        local ppq_pos, last_ppq_pos = 0,0
        for i = 1, #evts do 
          ppq_pos = evts[i].ppq_pos
          offset = ppq_pos - last_ppq_pos
          last_ppq_pos = ppq_pos
          str = str..string.pack("i4Bs4", offset, evts[i].flags , evts[i].msg1)
          if evts[i].ppq_pos2 then -- NoteOFF
            ppq_pos = evts[i].ppq_pos2
            offset = ppq_pos - last_ppq_pos
            last_ppq_pos = ppq_pos
            str = str..string.pack("i4Bs4", offset, evts[i].flags , evts[i].msg1_OFF)
          end
        end
        MIDI_SetAllEvts(take, str)
        MIDI_Sort(take)
    end
    
    if params.confirm_changes  then
      DATA:CollectData_MIDIEditor() 
    end
  end
  ----------------------------------------------------  
  function DATA:WriteData_Envelope(params) 
    local env = GetSelectedEnvelope( -1 )
    if not env then return end
    
    local ptr = DATA.CurState.Envelope.srcptr
    local fxid = DATA.CurState.Envelope.fxid
    
    if params then 
      -- abs for current state
      if params.toggle_FXbypass then 
        _G[DATA.CurState.Envelope.srctype..'FX_SetEnabled']( ptr, fxid,not DATA.CurState.Envelope.FXbypstate  )
      end
      if params.toggle_FXfloat then 
        local is_open = _G[DATA.CurState.Envelope.srctype..'FX_GetOpen'](ptr, fxid)
        if not is_open then _G[DATA.CurState.Envelope.srctype..'FX_Show']( ptr, fxid, 3 ) else _G[DATA.CurState.Envelope.srctype..'FX_Show'](ptr, fxid, 2 ) end
      end
      
      if params.set_pos then DATA:WriteData_Envelope_ApplyToSelection(params) end
      if params.set_val then DATA:WriteData_Envelope_ApplyToSelection(params) end
      if params.set_val_format then DATA:WriteData_Envelope_ApplyToSelection(params) end
      if params.set_val_printstate then DATA:WriteData_Envelope_ApplyToSelection(params) end
      
      if params.set_AIpoollen then
        local qnlen  =TimeMap2_timeToQN( -1, math.max(params.set_AIpoollen,0.2 ))
        GetSetAutomationItemInfo( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx, 'D_POOL_QNLEN', qnlen, true )
      end
      
      if params.mark_same then DATA:WriteData_Envelope_ApplyToSelection(params) end
      DATA:CollectData_Envelope() 
    end
  end
  
  ----------------------------------------------------  
  function DATA:WriteData_Envelope_ApplyToSelection(params)
    local cnt_selectedpoints = #DATA.CurState.Envelope.selectedpoints
    if cnt_selectedpoints == 0 then return end
    if params.set_val_printstate then DATA.temp_printstate = {pts = {}} end
    local volume_mode = DATA.CurState.Envelope.volume_mode 
    
    
    local retval, src_D_POSITION, src_D_VAL, shape, tension, selected = GetEnvelopePointEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx, DATA.CurState.Envelope.selectedpoints[1] )
    src_D_VAL = ScaleFromEnvelopeMode( DATA.CurState.Envelope.scaling_mode,src_D_VAL) 
    -- handle printstate 
      if params.set_val_printstate then 
        DATA.temp_printstate.src_D_VAL = src_D_VAL 
        DATA.temp_printstate.src_D_POSITION = src_D_POSITION 
      end
      if params.set_val and DATA.temp_printstate then src_D_VAL = DATA.temp_printstate.src_D_VAL end
      if params.set_pos and DATA.temp_printstate then src_D_POSITION = DATA.temp_printstate.src_D_POSITION end
    local src_D_VAL_DB if volume_mode==true then src_D_VAL_DB = WDL_VAL2DB(src_D_VAL)   end
    
    if params.mark_same then
      local cnt_points = CountEnvelopePointsEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx )
      for ptidx= 1, cnt_points do 
        local retval, time, D_VAL, shape, tension, selected = GetEnvelopePointEx(DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx, ptidx-1 )
        local D_VAL = ScaleFromEnvelopeMode( DATA.CurState.Envelope.scaling_mode,D_VAL) 
        if math.abs(D_VAL -src_D_VAL) < 10^-9 then 
          SetEnvelopePointEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx, ptidx-1, time, value, shape, tension, 1, true )
        end
      end
      Envelope_SortPointsEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx )
      UpdateTimeline()
    end
    
    
    for i = 1, cnt_selectedpoints do 
      local retval, D_POSITION, D_VAL, shape, tension, selected = GetEnvelopePointEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx, DATA.CurState.Envelope.selectedpoints[i] )
      D_VAL = ScaleFromEnvelopeMode( DATA.CurState.Envelope.scaling_mode,D_VAL) 
      -- handle printstate 
        if params.set_val_printstate then 
          DATA.temp_printstate.pts[i] = {
            D_POSITION = D_POSITION,
            D_VAL=D_VAL,
          }
        end 
        if (params.set_val or params.set_pos) and DATA.temp_printstate then 
          D_POSITION = DATA.temp_printstate.pts[i].D_POSITION
          D_VAL = DATA.temp_printstate.pts[i].D_VAL
        end  
      local D_VAL_DB if volume_mode==true then D_VAL_DB = WDL_VAL2DB(D_VAL)   end
      
      
      
      
      if params.set_pos then   
        local diff = params.set_pos - src_D_POSITION        
        local timeIn = diff + D_POSITION
        if DATA.CurState.Envelope.autoitem_idx ~= -1 then timeIn = lim(timeIn + DATA.CurState.Envelope.autoitem.D_POSITION,DATA.CurState.Envelope.autoitem.D_POSITION, DATA.CurState.Envelope.autoitem.D_POSITION+DATA.CurState.Envelope.autoitem.D_POOL_LEN) end
        SetEnvelopePointEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx, DATA.CurState.Envelope.selectedpoints[i],
          timeIn, value, shape, tension, true, true)
      end
      
      if params.set_val then  
        local diff, value
        if EXT.CONF_widg_envpointval_apprelative&1==1 then 
          diff = params.set_val - src_D_VAL        
          value = diff + D_VAL
         else
          value = params.set_val
        end
        value = ScaleToEnvelopeMode( DATA.CurState.Envelope.scaling_mode,lim(value)) 
        SetEnvelopePointEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx, DATA.CurState.Envelope.selectedpoints[i], D_POSITION,value , shape, tension, true, true)
      end
      if params.set_val_format then  
        local set_param = params.set_val_format
        local diff, value
        
        if DATA.CurState.Envelope.volume_mode~=true and EXT.CONF_widg_envpointval_usebrutforce&1==1 then
          value = Utils_BFpluginparam(tostring(set_param), DATA.CurState.Envelope.srcptr, DATA.CurState.Envelope.fxid, DATA.CurState.Envelope.paramid) 
          if not value then return else set_param = value end
        end
        
        if EXT.CONF_widg_envpointval_apprelative&1==1 then 
          diff = set_param - src_D_VAL        
          value = diff + D_VAL
          if volume_mode ==true then -- format override for volume 
            diff_DB = params.set_val_format - src_D_VAL_DB  
            value = WDL_DB2VAL(diff_DB + D_VAL_DB)   
          end
         else
          value = set_param
          if volume_mode==true then value = WDL_DB2VAL(set_param) end    -- format override for volume 
        end
        value = ScaleToEnvelopeMode( DATA.CurState.Envelope.scaling_mode,value) 
        SetEnvelopePointEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx, DATA.CurState.Envelope.selectedpoints[i],
          D_POSITION, lim(value), shape, tension, true, true)
      end
      
    end
    Envelope_SortPointsEx( DATA.CurState.Envelope.env_ptr, DATA.CurState.Envelope.autoitem_idx )
    --UpdateArrange()
    UpdateTimeline()
  end
  ----------------------------------------------------  
  function DATA:CollectData_Track()  
    if not DATA.CurState.Track then DATA.CurState.Track = {} end
    
    local track = GetSelectedTrack(-1,0)
    if not track then return end
    DATA.CurState.Track.tr_ptr = track
    
    local IP_TRACKNUMBER = GetMediaTrackInfo_Value( track, 'IP_TRACKNUMBER' )
    DATA.CurState.Track.type_str = 'Track '..math.floor(IP_TRACKNUMBER)
    
    DATA.CurState.Track.I_CUSTOMCOLOR = GetMediaTrackInfo_Value( track, 'I_CUSTOMCOLOR' )
    local retval, name = reaper.GetSetMediaTrackInfo_String( track, 'P_NAME', '', false ) 
    DATA.CurState.Track.name = name
    
    DATA.CurState.Track.I_FREEZECOUNT = GetMediaTrackInfo_Value( track, 'I_FREEZECOUNT' )
    DATA.CurState.Track.B_PHASE = GetMediaTrackInfo_Value( track, 'B_PHASE' )
    DATA.CurState.Track.B_MAINSEND = GetMediaTrackInfo_Value( track, 'B_MAINSEND' )
    
    DATA.CurState.Track.I_PLAY_OFFSET_FLAG = GetMediaTrackInfo_Value( track, 'I_PLAY_OFFSET_FLAG' )
    DATA.CurState.Track.D_PLAY_OFFSET = GetMediaTrackInfo_Value( track, 'D_PLAY_OFFSET' )
    if DATA.CurState.Track.I_PLAY_OFFSET_FLAG &2==2 then  -- DATA.CurState.Track.I_PLAY_OFFSET_FLAG&1~=1 and 
      DATA.CurState.Track.D_PLAY_OFFSET = DATA.CurState.Track.D_PLAY_OFFSET / DATA.CurState.Project.SR 
    end
    DATA.CurState.Track.D_PLAY_OFFSET_format = (math.floor(DATA.CurState.Track.D_PLAY_OFFSET*10000)/10)..'ms'
    
    
    DATA.CurState.Track.D_VOL = GetMediaTrackInfo_Value( track, 'D_VOL' )
    DATA.CurState.Track.D_VOL_format = Utils_formatvolumestr(DATA.CurState.Track.D_VOL)
    DATA.CurState.Track.D_VOL_format_t = Utils_SplitValues(DATA.CurState.Track.D_VOL_format)
    DATA.CurState.Track.D_VOL_format_t.ext ='dB'
    
    DATA.CurState.Track.D_PAN = GetMediaTrackInfo_Value( track, 'D_PAN' )
    DATA.CurState.Track.D_PAN_format = Utils_formatpanstr(DATA.CurState.Track.D_PAN)
    DATA.CurState.Track.D_PAN_format_t = Utils_SplitValues(DATA.CurState.Track.D_PAN_format) 
    
    -- fx
    DATA.CurState.Track.FX = {count = TrackFX_GetCount( track ),list = {}}
    for fx = 1, DATA.CurState.Track.FX.count do
      local retval, buf = TrackFX_GetFXName( track, fx-1 )
      local bypstate = TrackFX_GetEnabled( track, fx-1  )
      DATA.CurState.Track.FX.list[fx] = {
        name = buf, 
        name_reduced = Utils_ReduceFXname(buf),
        bypstate = bypstate,
        }
    end
    local retval, INTTOOLBAR_TRFXID = reaper.GetSetMediaTrackInfo_String( track, 'P_EXT:INTTOOLBAR_TRFXID', '', 0 ) -- #trackfxlist
    DATA.CurState.Track.FX.INTTOOLBAR_TRFXID = tonumber(INTTOOLBAR_TRFXID) or 1
    
    
    -- ext plugins
      -- delay time_adjustment
      DATA.CurState.Track.DELAY = 0
      local delayFX_pos = TrackFX_AddByName( track, 'time_adjustment', false, 0 )
      if delayFX_pos >=0 then 
        DATA.CurState.Track.DELAY_pos = delayFX_pos
        local val = TrackFX_GetParam( track, delayFX_pos, 0 )
        DATA.CurState.Track.DELAY = math.floor(val)-- * 10)/10
        DATA.CurState.Track.DELAY_format = DATA.CurState.Track.DELAY..'ms'
      end
      
      DATA.CurState.Track.D_VOL = GetMediaTrackInfo_Value( track, 'D_VOL' )
      DATA.CurState.Track.I_RECINPUT = GetMediaTrackInfo_Value( track, 'I_RECINPUT')
    
    -- generate possible rec states
      DATA.CurState.Track.RECINPUT_states = {
        [-1] = 'Input:\nNone', 
        [4096|(63<<5)] = 'MIDI:\nAll',
        [4096|(62<<5)] = 'MIDI:\nVKB',
      }
      for i = 1, GetNumAudioInputs() do
        local str = GetInputChannelName( i-1 )
        DATA.CurState.Track.RECINPUT_states[i-1] = 'Audio:\n'..str
      end
  end
  ----------------------------------------------------  
  function DATA:WriteData_Track(params) 
    local track = GetSelectedTrack(-1,0)
    if not track then return end
    
    if params then 
      if params.freeze then Main_OnCommandEx(41223,0,-1) end
      if params.unfreeze then Main_OnCommandEx(41644,0,-1)  end
      if params.set_name then GetSetMediaTrackInfo_String( track, 'P_NAME', params.set_name, 1 ) end
      if params.set_fxlistactivefx then GetSetMediaTrackInfo_String( track, 'P_EXT:INTTOOLBAR_TRFXID', params.set_fxlistactivefx, 1 ) end
      if params.set_fxtogglebypass then 
        local bypstate = TrackFX_GetEnabled( track, params.set_fxtogglebypass   )
        TrackFX_SetEnabled( track, params.set_fxtogglebypass, not bypstate  )
      end
      if params.set_fxremove then 
        TrackFX_Delete( track, params.set_fxremove )
      end
      if params.set_fxfloatchain then 
        TrackFX_Show( track, params.set_fxfloatchain, 1 )
      end
      if params.set_fxfloat then 
        local is_open = reaper.TrackFX_GetOpen(track, params.set_fxfloat)
        if not is_open then TrackFX_Show( track, params.set_fxfloat, 3 ) else TrackFX_Show(track, params.set_fxfloat, 2 ) end
      end
      -- set_trackrecin
      if params.set_trackrecin_reset then 
        if DATA.CurState.Track.I_RECINPUT == -1 then 
          SetMediaTrackInfo_Value( track, 'I_RECINPUT',4096|(63<<5))
          SetMediaTrackInfo_Value( track, 'I_RECMON', 1) 
          SetMediaTrackInfo_Value( track, 'I_RECARM', 1) 
         else
          SetMediaTrackInfo_Value( track, 'I_RECINPUT',-1)
          SetMediaTrackInfo_Value( track, 'I_RECMON', 0) 
          SetMediaTrackInfo_Value( track, 'I_RECARM', 0)  
        end
      end
      if params.set_trackrecin_next or params.set_trackrecin_prev then 
        local has_set
        
        if params.set_trackrecin_next then 
        
          for i in spairs(DATA.CurState.Track.RECINPUT_states, function(t,a,b) return a<b end) do
            if i > DATA.CurState.Track.I_RECINPUT then 
              has_set = i  
              break
            end
          end
          
         elseif params.set_trackrecin_prev then 
         
          for i in spairs(DATA.CurState.Track.RECINPUT_states, function(t,a,b) return a>b end) do 
            if i < DATA.CurState.Track.I_RECINPUT then 
              has_set = i  
              break
            end
          end
          
        end
        
        -- set monitor and record arm depending on input
          if has_set then
            SetMediaTrackInfo_Value( track, 'I_RECINPUT',has_set)
            if has_set ~= -1 then 
              SetMediaTrackInfo_Value( track, 'I_RECMON', 1) 
              SetMediaTrackInfo_Value( track, 'I_RECARM', 1)  
             else
              SetMediaTrackInfo_Value( track, 'I_RECMON', 0) 
              SetMediaTrackInfo_Value( track, 'I_RECARM', 0)  
            end
          end
        
      end
      
        
      
      if params.set_color then DATA:WriteData_Track_ApplyToSelection(params)  end
      if params.set_vol then DATA:WriteData_Track_ApplyToSelection(params)  end
      if params.set_pan then DATA:WriteData_Track_ApplyToSelection(params)  end
      if params.set_delay then DATA:WriteData_Track_ApplyToSelection(params)  end
      if params.toggle_phase then DATA:WriteData_Track_ApplyToSelection(params)  end
      if params.toggle_parent then DATA:WriteData_Track_ApplyToSelection(params)  end
      if params.set_offset then DATA:WriteData_Track_ApplyToSelection(params)  end
    end
    
    DATA:CollectData_Track() 
  end
  
  ----------------------------------------------------  
  function DATA:WriteData_Track_ApplyToSelection(params)
    local src_tr = reaper.GetSelectedTrack(-1,0)
    local src_D_VOL = GetMediaTrackInfo_Value( src_tr, 'D_VOL')
    local src_D_PAN = GetMediaTrackInfo_Value( src_tr, 'D_PAN')
    local src_D_PLAY_OFFSET = GetMediaTrackInfo_Value( src_tr, 'D_PLAY_OFFSET')
    local src_I_PLAY_OFFSET_FLAG = GetMediaTrackInfo_Value( src_tr, 'I_PLAY_OFFSET_FLAG')
    if src_I_PLAY_OFFSET_FLAG&1~=1 and src_I_PLAY_OFFSET_FLAG &2==2 then src_D_PLAY_OFFSET = src_D_PLAY_OFFSET / DATA.CurState.Project.SR end
    
    for i = 1, CountSelectedTracks(-1) do
      local track = reaper.GetSelectedTrack(-1,i-1)
      local D_VOL = GetMediaTrackInfo_Value( track, 'D_VOL')
      local D_PAN = GetMediaTrackInfo_Value( track, 'D_PAN')
      local B_PHASE = GetMediaTrackInfo_Value( track, 'B_PHASE')
      local D_PLAY_OFFSET = GetMediaTrackInfo_Value( track, 'D_PLAY_OFFSET')
      local I_PLAY_OFFSET_FLAG = GetMediaTrackInfo_Value( track, 'I_PLAY_OFFSET_FLAG')
      if I_PLAY_OFFSET_FLAG&1~=1 and I_PLAY_OFFSET_FLAG &2==2 then D_PLAY_OFFSET = D_PLAY_OFFSET / DATA.CurState.Project.SR end
      
      -- absolute
      if params.set_color then SetMediaTrackInfo_Value( track, 'I_CUSTOMCOLOR', params.set_color ) end
       
      -- track relative   
      if params.set_vol then                
        local diff = params.set_vol - src_D_VOL             
        SetMediaTrackInfo_Value( track, 'D_VOL', D_VOL + diff ) 
      end
      if params.set_offset then             
        local diff = params.set_offset - src_D_PLAY_OFFSET  
        SetMediaTrackInfo_Value( track, 'D_PLAY_OFFSET', D_PLAY_OFFSET + diff ) 
        SetMediaTrackInfo_Value( track, 'I_PLAY_OFFSET_FLAG', 0 ) 
      end
      if params.set_pan then        
        local outputval = lim(params.set_pan,-1,1)
        local diff = outputval - src_D_PAN              
        SetMediaTrackInfo_Value( track, 'D_PAN', lim(D_PAN + diff,-1,1) ) 
      end
      if params.toggle_phase then   SetMediaTrackInfo_Value( track, 'B_PHASE', B_PHASE~1 ) end
      if params.toggle_parent then   SetMediaTrackInfo_Value( track, 'B_MAINSEND', params.toggle_parent ) end
      
      
      -- 3rd party
      if params.set_delay then 
        local fx_pos = TrackFX_AddByName( track, 'time_adjustment', false, 1 )
        local value = lim(params.set_delay,-1000,1000)
        TrackFX_SetParam(track, fx_pos, 0, value )
      end
      
    end
    
  end
  ----------------------------------------------------  
  function DATA:CollectData_FX()  
    if not DATA.CurState.FX then DATA.CurState.FX = {} end
    
    local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 1 )
    if not retval then return end
    
    
    DATA.CurState.FX.fxidx=fxidx
    DATA.CurState.FX.parm=parm
    
    local tr
    if trackidx == -1 then tr = reaper.GetMasterTrack(-1) else tr = GetTrack(-1,trackidx) end 
    if tr then src_ptr = tr DATA.CurState.FX.srctype = 'Track' end
    
    if itemidx ~= -1 then 
      local item = reaper.GetMediaItem(-1, itemidx)
      if item then
        local tk = GetTake(item , takeidx)
        src_ptr = tk
        DATA.CurState.FX.srctype = 'Take'
      end
    end
    
    if not src_ptr then return end
    DATA.CurState.FX.src_ptr = src_ptr
    local retval, buf = _G[DATA.CurState.FX.srctype..'FX_GetNamedConfigParm']( src_ptr, fxidx, 'chain_oversample_shift' )
    DATA.CurState.FX.chain_oversample = tonumber(buf)
    DATA.CurState.FX.chain_oversample_format = math.floor(2^(DATA.CurState.FX.chain_oversample))..'x' if DATA.CurState.FX.chain_oversample == 0 then DATA.CurState.FX.chain_oversample_format = 'none' end 
    
    local retval, buf = _G[DATA.CurState.FX.srctype..'FX_GetNamedConfigParm']( src_ptr, fxidx, 'force_auto_bypass' )
    DATA.CurState.FX.force_auto_bypass = tonumber(buf)
    
  end
  ----------------------------------------------------  
  function DATA:WriteData_FX(params) 
    if params.set_CHOS then 
      local outOS = lim(math.floor(params.set_CHOS),0,4)
      _G[DATA.CurState.FX.srctype..'FX_SetNamedConfigParm']( DATA.CurState.FX.src_ptr, DATA.CurState.FX.fxidx, 'chain_oversample_shift', outOS )
    end
    if params.toggle_force_auto_bypass then  
      local ret, buf = _G[DATA.CurState.FX.srctype..'FX_GetNamedConfigParm']( DATA.CurState.FX.src_ptr, DATA.CurState.FX.fxidx, 'force_auto_bypass' )
      buf = tonumber(buf)
      _G[DATA.CurState.FX.srctype..'FX_SetNamedConfigParm']( DATA.CurState.FX.src_ptr, DATA.CurState.FX.fxidx, 'force_auto_bypass', buf~1 )
    end
     DATA:CollectData_FX()  
  end
  ----------------------------------------------------  
  function DATA:CollectData_SpecEdit()  
    if not DATA.CurState.SpecEdit then DATA.CurState.SpecEdit = {} end 
    local item = GetSelectedMediaItem(-1,0)
    if not item then return end
    local take = GetActiveTake(item)
    if not take then return end 
    
    DATA.CurState.SpecEdit.item=item
    DATA.CurState.SpecEdit.take=take
    local IP_SPECEDITCNT = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:CNT' )
    if IP_SPECEDITCNT == 0 then return end 
    for i=1, IP_SPECEDITCNT do
      local SELECTED = GetMediaItemTakeInfo_Value( take, 'B_SPECEDIT:'..(i-1)..':SELECTED' )
      if SELECTED == 1 then 
        local FLAGS = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..(i-1)..':FLAGS' )
        DATA.CurState.SpecEdit.FLAGS = FLAGS
        DATA.CurState.SpecEdit.selectedID = i-1
        return 
      end
    end
  end
  ----------------------------------------------------  
  function DATA:WriteData_SpecEdit(params) 
    if params.toggle_bypass then 
      SetMediaItemTakeInfo_Value( DATA.CurState.SpecEdit.take, 'I_SPECEDIT:'..DATA.CurState.SpecEdit.selectedID..':FLAGS',DATA.CurState.SpecEdit.FLAGS~1  )
    end
    reaper.UpdateItemInProject(DATA.CurState.SpecEdit.item)
     DATA:CollectData_SpecEdit()  
  end
  ----------------------------------------------------  
    function DATA:CollectData_Item()  
      if not DATA.CurState.Item then DATA.CurState.Item = {} end
    
    local item = reaper.GetSelectedMediaItem(-1,0)
    if not item then return end
    DATA.CurState.Item.it_ptr = item
    DATA.CurState.Item.tk_ptr = nli
    DATA.CurState.Item.tk_name = ''
    --[[ reset stuff
      DATA.CurState.Item.type_str = 'Empty item'
      DATA.CurState.Item.tk_name = '' 
      DATA.CurState.Item.I_CUSTOMCOLOR = 0
      DATA.CurState.Item.C_LOCK = 0
      DATA.CurState.Item.B_PPITCH = 0
      DATA.CurState.Item.B_LOOPSRC = 0
      DATA.CurState.Item.B_MUTE = 0
      DATA.CurState.Item.Reverse = 0
      DATA.CurState.Item.C_AUTOSTRETCH = 0
      DATA.CurState.Item.C_BEATATTACHMODE = -1
      DATA.CurState.Item.D_SNAPOFFSET = 0
      DATA.CurState.Item.D_POSITION = 0
      DATA.CurState.Item.D_LENGTH = 0
      DATA.CurState.Item.D_END = 0
      DATA.CurState.Item.D_STARTOFFS = 0
      DATA.CurState.Item.D_FADEINLEN = 0
      DATA.CurState.Item.D_FADEOUTLEN = 0
      DATA.CurState.Item.D_VOL = 0
      DATA.CurState.Item.D_PITCH = 0
      DATA.CurState.Item.D_PLAYRATE = 0]]
    
    DATA.CurState.Item.C_LOCK = GetMediaItemInfo_Value( item, 'C_LOCK' )
    DATA.CurState.Item.B_LOOPSRC = GetMediaItemInfo_Value( item, 'B_LOOPSRC' )
    DATA.CurState.Item.B_MUTE = GetMediaItemInfo_Value( item, 'B_MUTE' )
    DATA.CurState.Item.C_AUTOSTRETCH = GetMediaItemInfo_Value( item, 'C_AUTOSTRETCH' )
    DATA.CurState.Item.C_BEATATTACHMODE = GetMediaItemInfo_Value( item, 'C_BEATATTACHMODE' )
    
    DATA.CurState.Item.D_VOL = GetMediaItemInfo_Value( item, 'D_VOL' )
    DATA.CurState.Item.D_VOL_format = Utils_formatvolumestr(DATA.CurState.Item.D_VOL)
    DATA.CurState.Item.D_VOL_format_t = Utils_SplitValues(DATA.CurState.Item.D_VOL_format)
    DATA.CurState.Item.D_VOL_format_t.ext ='dB'
    
    DATA.CurState.Item.D_SNAPOFFSET = GetMediaItemInfo_Value( item, 'D_SNAPOFFSET' ) 
    DATA.CurState.Item.D_SNAPOFFSET_format = Utils_formattimestr( DATA.CurState.Item.D_SNAPOFFSET, '', EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Item.D_SNAPOFFSET_format_t = Utils_SplitValues(DATA.CurState.Item.D_SNAPOFFSET_format)
    
    DATA.CurState.Item.D_POSITION = GetMediaItemInfo_Value( item, 'D_POSITION' ) 
    DATA.CurState.Item.D_POSITION_format = Utils_formattimestr( DATA.CurState.Item.D_POSITION, '', EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Item.D_POSITION_format_t = Utils_SplitValues(DATA.CurState.Item.D_POSITION_format)
    
    DATA.CurState.Item.D_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH' ) 
    DATA.CurState.Item.D_LENGTH_format = Utils_formattimestr_len( DATA.CurState.Item.D_LENGTH, '', DATA.CurState.Item.D_POSITION, EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Item.D_LENGTH_format_t = Utils_SplitValues(DATA.CurState.Item.D_LENGTH_format)
    
    DATA.CurState.Item.D_END = DATA.CurState.Item.D_POSITION + DATA.CurState.Item.D_LENGTH
    DATA.CurState.Item.D_END_format = Utils_formattimestr( DATA.CurState.Item.D_END, '', EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Item.D_END_format_t = Utils_SplitValues(DATA.CurState.Item.D_END_format)
    
    DATA.CurState.Item.D_FADEINLEN = GetMediaItemInfo_Value( item, 'D_FADEINLEN' ) 
    DATA.CurState.Item.D_FADEINLEN_format = Utils_formattimestr_len( DATA.CurState.Item.D_FADEINLEN, '', DATA.CurState.Item.D_POSITION,EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Item.D_FADEINLEN_format_t = Utils_SplitValues(DATA.CurState.Item.D_FADEINLEN_format)
    
    DATA.CurState.Item.D_FADEOUTLEN = GetMediaItemInfo_Value( item, 'D_FADEOUTLEN' ) 
    DATA.CurState.Item.D_FADEOUTLEN_format = Utils_formattimestr_len( DATA.CurState.Item.D_FADEOUTLEN,'',DATA.CurState.Item.D_POSITION + DATA.CurState.Item.D_LENGTH - DATA.CurState.Item.D_FADEOUTLEN, EXT.CONF_widg_time_formatoverride )
    DATA.CurState.Item.D_FADEOUTLEN_format_t = Utils_SplitValues(DATA.CurState.Item.D_FADEOUTLEN_format)
    
    local take = GetActiveTake( item )
    if not take then 
      DATA.CurState.Item.type_str = 'Empty item'
      return 
    end
    
    DATA.CurState.Item.type_str = 'Audio item'
    if reaper.TakeIsMIDI(take) then DATA.CurState.Item.type_str = 'MIDI item' end
    DATA.CurState.Item.tk_ptr = take
    local retval, stringNeedBig = GetSetMediaItemTakeInfo_String( take, 'P_NAME', '', 0 )
    DATA.CurState.Item.tk_name = stringNeedBig
    DATA.CurState.Item.I_CUSTOMCOLOR = GetMediaItemTakeInfo_Value( take, 'I_CUSTOMCOLOR' )
    DATA.CurState.Item.B_PPITCH = GetMediaItemTakeInfo_Value( take, 'B_PPITCH' )
    DATA.CurState.Item.I_CHANMODE = GetMediaItemTakeInfo_Value( take, 'I_CHANMODE' )
    
    DATA.CurState.Item.D_PITCH = GetMediaItemTakeInfo_Value( take, 'D_PITCH' )
    DATA.CurState.Item.D_PITCH_format = Utils_formatdecstr(DATA.CurState.Item.D_PITCH)
    DATA.CurState.Item.D_PITCH_format_t = Utils_SplitValues(DATA.CurState.Item.D_PITCH_format)
    
    DATA.CurState.Item.D_PLAYRATE = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
    DATA.CurState.Item.D_PLAYRATE_format = Utils_formatdecstr(DATA.CurState.Item.D_PLAYRATE)
    DATA.CurState.Item.D_PLAYRATE_format_t = Utils_SplitValues(DATA.CurState.Item.D_PLAYRATE_format)   
    
    DATA.CurState.Item.D_PAN = GetMediaItemTakeInfo_Value( take, 'D_PAN' )
    DATA.CurState.Item.D_PAN_format = Utils_formatpanstr(DATA.CurState.Item.D_PAN)
    DATA.CurState.Item.D_PAN_format_t = Utils_SplitValues(DATA.CurState.Item.D_PAN_format)        
    
    
    
    local force_ruler_format = EXT.CONF_widg_time_formatoverride if DATA.CurState.Project.CountTempoTimeSigMarkers > 1 then force_ruler_format = 3 end -- force #itemsourceoffset to seconds if more than 1 timsigture marker
    DATA.CurState.Item.D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    DATA.CurState.Item.D_STARTOFFS_format = Utils_formattimestr( DATA.CurState.Item.D_STARTOFFS, '', force_ruler_format )
    DATA.CurState.Item.D_STARTOFFS_format_t = Utils_SplitValues(DATA.CurState.Item.D_STARTOFFS_format) 
    
    local src = GetMediaItemTake_Source( take ) 
    local retval, offs, len, rev = reaper.PCM_Source_GetSectionInfo( src )
    --if GetMediaSourceParent( src ) then src = GetMediaSourceParent( src ) end  
    local rev_int = 0 if rev == true then rev_int = 1 end
    DATA.CurState.Item.Reverse = rev_int
    
    
  end    
  ----------------------------------------------------  
  function DATA:WriteData_Item(params) 
    local item = reaper.GetSelectedMediaItem(-1,0)
    if not item then return end
    local take = GetActiveTake( item )
    if not take then return end
    if params then 
      if params.set_name then
        GetSetMediaItemTakeInfo_String( take, 'P_NAME', params.set_name, 1 ) 
      end
      if params.set_color then DATA:WriteData_Item_ApplyToSelection(params)  end
      if params.toggle_lock then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.toggle_preservepitch then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.toggle_loop then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.toggle_mute then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_chanmode then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.toggle_reverse then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_timebase then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_snap then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_pos then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_ledge then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_redge then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_length then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_offset then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_fadein then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_fadeout then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_vol then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_pitch then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_rate then DATA:WriteData_Item_ApplyToSelection(params) end
      if params.set_pan then DATA:WriteData_Item_ApplyToSelection(params) end
      
      -- recursively run local update 
        --if DATA.temp_valinit==nil then
          reaper.UpdateItemInProject(item)
          DATA:CollectData_Item()
        --end
      
    end
  end
  -----------------------------------------------------------------------------------------  
  function DATA:Actions_Tap()
    local time_precise = time_precise()
    if not DATA.taptempo.taps then DATA.taptempo.taps = {} end
    
    
    -- add tap
    local taps_cnt = 20
    if DATA.taptempo.last_tap and time_precise - DATA.taptempo.last_tap> 10 then DATA.taptempo.taps = {} end -- clear table at new tapping
    DATA.taptempo.last_tap = time_precise
    table.insert(DATA.taptempo.taps, time_precise )
    if #DATA.taptempo.taps > taps_cnt+1 then table.remove(DATA.taptempo.taps, 1) end -- clamp table
    if #DATA.taptempo.taps < 3 then return end  
    
    -- convert to tempo
    DATA.taptempo.tempocandidates = {}
    DATA.taptempo.tempocandidates_av = 0
    for i = 1, #DATA.taptempo.taps-1 do DATA.taptempo.tempocandidates[i] = 60 / math.abs(DATA.taptempo.taps[i] - DATA.taptempo.taps[i+1]) DATA.taptempo.tempocandidates_av = DATA.taptempo.tempocandidates_av + DATA.taptempo.tempocandidates[i] end
    DATA.taptempo.tempocandidates_av = DATA.taptempo.tempocandidates_av / (#DATA.taptempo.taps-1)
    
    -- av over measures
    if #DATA.taptempo.taps > 17 then
      DATA.taptempo.tempocandidates_av3 = {}
      tempocandidates_av1 = 60/((DATA.taptempo.taps[9] - DATA.taptempo.taps[1]) / 8)
      tempocandidates_av2 = 60/((DATA.taptempo.taps[17] - DATA.taptempo.taps[1]) / 16)
      DATA.taptempo.tempocandidates_av = (tempocandidates_av1 + tempocandidates_av2)  / 2
      table.insert(DATA.taptempo.tempocandidates_av3, DATA.taptempo.tempocandidates_av )
      if #DATA.taptempo.tempocandidates_av3 > 5 then table.remove(DATA.taptempo.tempocandidates_av3, 1) end -- clamp table
      local av = 0
      if #DATA.taptempo.tempocandidates_av3 > 3 then 
        for i = 1, #DATA.taptempo.tempocandidates_av3 do av = av + DATA.taptempo.tempocandidates_av3 end
        DATA.taptempo.tempocandidates_av = av / #DATA.taptempo.tempocandidates_av3
      end
    end
    
    DATA.taptempo.output = DATA.taptempo.tempocandidates_av
    DATA.taptempo.output_q = math_q(DATA.taptempo.output)
    
  end
  
  -----------------------------------------------------------------------------------------  
  function DATA:Actions_Widgets_Write(params)
    -- set
      local extkey
      --local widg_to_shift
      if params.remove then 
        extkey = params.remove
        for i = #DATA.widgets[extkey],1,-1 do
          if DATA.widgets[extkey][i].selected == true then table.remove(DATA.widgets[extkey], i) end
        end
      end
      
      if params.add then 
        extkey = params.add
        local extkey_src = 'CONF_availablewidgets'
        for i = 1, #DATA.widgets[extkey_src] do
          if DATA.widgets[extkey_src][i].selected == true then DATA.widgets[extkey][#DATA.widgets[extkey]+1] = {widget_ID = DATA.widgets[extkey_src][i].widget_ID} end
        end
      end
      
      if params.moveup then 
        extkey = params.moveup
        widg_to_shift = {}
        for i = 1, #DATA.widgets[extkey] do
          if DATA.widgets[extkey][i].selected == true then widg_to_shift[DATA.widgets[extkey][i].widget_ID] = true end
        end 
        for widgID in pairs(widg_to_shift) do
          for i = 1, #DATA.widgets[extkey] do
            if DATA.widgets[extkey][i].widget_ID == widgID and i~=1 then 
              local temp = CopyTable(DATA.widgets[extkey][i])
              table.remove(DATA.widgets[extkey], i) 
              table.insert(DATA.widgets[extkey], i-1, temp)
              break 
            end
          end
        end
      end
      
      if params.movedown then 
        extkey = params.movedown
        widg_to_shift = {}
        for i = 1, #DATA.widgets[extkey] do
          if DATA.widgets[extkey][i].selected == true then widg_to_shift[DATA.widgets[extkey][i].widget_ID] = true end
        end 
        for widgID in pairs(widg_to_shift) do
          for i = 1, #DATA.widgets[extkey] do
            if DATA.widgets[extkey][i].widget_ID == widgID and i~=#DATA.widgets[extkey] then 
              local temp = CopyTable(DATA.widgets[extkey][i])
              table.remove(DATA.widgets[extkey], i) 
              table.insert(DATA.widgets[extkey], i+1, temp)
              break 
            end
          end
        end
      end
      
      if params.printext then 
        extkey = params.printext
      end
      
    -- write string back
      if extkey then 
        local out_str = ''
        for i = 1, #DATA.widgets[extkey] do
          local widget_ID = DATA.widgets[extkey][i].widget_ID
          local widget_flags = DATA.widgets[extkey][i].widget_flags or 0
          out_str = out_str..'#'..widget_ID..widget_flags..' '
        end
        EXT[extkey] = out_str
        EXT:save()
        DATA:ParseWidgetsOrder()
        
        -- revert selection
        if widg_to_shift and (params.moveup or params.movedown)then 
          for widgID in pairs(widg_to_shift) do
            for i = 1, #DATA.widgets[extkey] do
              if DATA.widgets[extkey][i].widget_ID == widgID then DATA.widgets[extkey][i].selected = true end
            end
          end
        end
      end
      
  end
  
  ---------------------------------------------------
  function DATA:_CollectData_GetContext()
    DATA.context = ''
    
    local context_definitions = {
      Item = function ()
              local item = GetSelectedMediaItem(-1,0)
              if item then return true end
            end
      ,
      Track = function ()
              local tr = GetSelectedTrack(-1,0)
              if tr then return true end
            end
      ,  
      MIDIEditor = function ()
              local ME = MIDIEditor_GetActive()
              if ME then return true end
            end
      ,  
      Envelope = function ()
              local env = GetSelectedEnvelope( -1 )
              if env then return true end
            end
      ,  
      FX = function ()
              local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 1 )
              if retval then return true end
            end
      ,
      SpecEdit = function ()return DATA:_CollectData_GetContext_SEcheck() end
      ,
      
    }
    
    for i = 1, #DATA.widgets.CONF_contextpriority do
      local contextID = DATA.widgets.CONF_contextpriority[i].widget_ID
      if contextID and context_definitions[contextID] then 
        local ret, params = context_definitions[contextID]()
        if ret == true then 
          DATA.context = contextID
          return
        end
      end
    end
    
  end  
  
  ---------------------------------------------------
  function DATA:_CollectData_GetContext_SEcheck()
    local item = GetSelectedMediaItem(-1,0)
    if not item then return end
    local take = GetActiveTake(item)
    if not take then return end 
    local IP_SPECEDITCNT = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:CNT' )
    if IP_SPECEDITCNT == 0 then return end 
    for i=1, IP_SPECEDITCNT do
      local SELECTED = GetMediaItemTakeInfo_Value( take, 'B_SPECEDIT:'..(i-1)..':SELECTED' )
      if SELECTED == 1 then return true end
    end
  end
  ---------------------------------------------------
  function Utils_SplitValues(buf) 
    local t = {full_val = buf}
    buf = tostring(buf)
    t.div = buf:reverse():match('[%p]') or ''
    t.num = {}
    for num in buf:gmatch('[%d]+') do t.num[#t.num+1] = num:format('%02d') end
    if #t.num == 0 then t.num[1]=buf end 
    if buf:match('%-') then t.is_negative = true end
    return t
  end
  --------------------------------------------------------------------------------   
  function Utils_formatdecstr(val, params)
    local prec = 2
    if params and params.prec then prec = params.prec end
    local val_q = math.floor(val*(10^prec))/(10^prec)
    local val_format = string.format('%.0'..prec..'f',val_q)
    return val_format 
  end
  --------------------------------------------------------------------------------  
  function Utils_parsedecstr(val_format_t_new, params)  
    
    local prec = 2
    if params and params.prec then prec = params.prec end
    
    local int = tonumber(val_format_t_new.num[1])
    local sign = 1
    if val_format_t_new.is_negative then sign = -1 end
    local float = val_format_t_new.num[2]*(10^(-prec))
    local out_val = sign * (int + float)
    return out_val
  end
  -------------------------------------------------------------------------------   
  function Utils_formatpanstr(pan_val)
    local pan_str = 'undefined'
    if pan_val > 0 then 
      pan_str = math.floor((pan_val*100))..'% R'
     elseif pan_val < 0 then
      pan_str = math.floor(math.abs(pan_val*100))..'% L'
     elseif pan_val == 0 then
      pan_str = 'Center'
    end
    return pan_str
  end
  --------------------------------------------------------------------------------  
  function Utils_parsepanstr(val_format)    
    if val_format:lower():match('c') then return 0 end
    local mult = 1
    if val_format:lower():match('l') then mult = -1 end
    if val_format:lower():match('%-') then mult = -1 end 
    local val = val_format:match('[%d%.]+')
    if val and tonumber(val) then return mult * tonumber(val)/100 end
  end
  --------------------------------------------------------------------------------   
  function Utils_formatvolumestr(val)
    local val_format = WDL_VAL2DB(val, true)
    return val_format 
  end
  --------------------------------------------------------------------------------  
  function Utils_parsevolumestr(val_format_t_new, params)   
    local int = tonumber(val_format_t_new.num[1])
    local sign = 1
    if val_format_t_new.is_negative then sign = -1 end
    local float = val_format_t_new.num[2]*0.01
    local out_val_dB = sign * (int + float)
    out_val_dB = lim(out_val_dB, -150, 12)
    local out_val = WDL_DB2VAL(out_val_dB)
    return out_val
  end
  --------------------------------------------------------------------------------   
  function Utils_formattimestr(val, buf, format)
    local val_format = format_timestr_pos(val, buf, format )
    if format == 6 then val_format = tostring(math.floor(val*DATA.CurState.Project.FR)) end -- frames
    if val < 0 then 
      val_format = '-'..format_timestr_pos( math.abs(val), '', format ) -- fix for #itemsourceoffset 
      if format == 6 then val_format = '-'..tostring(math.floor(val*DATA.CurState.Project.FR)) end -- frames
    end
    return val_format 
  end
  --------------------------------------------------------------------------------   
  function Utils_formattimestr_len( val, buf, start, format )
    local FR  = 30
    if DATA.CurState and DATA.CurState.Project and DATA.CurState.Project.FR  then  FR= DATA.CurState.Project.FR end
    local out_val_str = format_timestr_len( val, buf, start, format )
    if format == 6 then 
       out_val_str_time = format_timestr_len( val, buf, start, 3 )
      out_val_str_time = tonumber(out_val_str_time)*FR
      return tostring(math.floor(out_val_str_time))
    end
    return out_val_str
  end
  --------------------------------------------------------------------------------   
  function Utils_parsetimestr(values_t, params)
    local rul_format = params.rul_format or  DATA.upd_last_rulerformat 
    if EXT.CONF_widg_time_formatoverride ~= -1 then rul_format = EXT.CONF_widg_time_formatoverride end
    local values = values_t.num
    local is_negative = values_t.is_negative
    
    -- Measures.Beats
      if rul_format == 2 then 
        local beats_fine = values[3]*0.01 
        local offs = 1
        if params.format_offset then offs = 0 end -- for #itemlength widget
        local beats = values[2]-offs
        local measures = values[1] -offs
        local outsec =  TimeMap2_beatsToTime(-1, beats + beats_fine, measures)
        if is_negative then 
          outsec =  -TimeMap2_beatsToTime(-1, beats + beats_fine, measures)
        end -- fix for #itemsourceoffset
        if not params.allow_negative then return math.max(0,outsec) else return outsec end
      end
      
    -- Seconds
      if rul_format == 3 then 
        local ms = values[2]*0.001
        local s = values[1]
        local outsec = math.abs(s) + ms
        if is_negative then outsec = -outsec end -- fix for #itemsourceoffset
        if not params.allow_negative then return math.max(0,outsec) else return outsec end
      end
      
    -- Samples
      if rul_format == 4 then 
        local outsec = values[1]/DATA.CurState.Project.SR
        if is_negative then outsec = -outsec end -- fix for #itemsourceoffset
        return math.max(0,outsec)
      end      
      
    -- HH:MM:SS:frame
      if rul_format == 5 then 
        local frame =   values[4]/DATA.CurState.Project.FR
        local s =       values[3]
        local m =       values[2]*60
        local h =       math.max(0,values[1]*3600 ) 
        local outsec = frame + s + m +h
        if is_negative then outsec = -outsec end -- fix for #itemsourceoffset
        if not params.allow_negative then return math.max(0,outsec) else return outsec end
      end
      
    -- frames
      if rul_format == 6 then 
        local outsec =   values[1]/DATA.CurState.Project.FR
        if is_negative then outsec = -outsec end -- fix for #itemsourceoffset
        if not params.allow_negative then return math.max(0,outsec) else return outsec end
      end 
      
  end
  --------------------------------------------------------------------------------   
  function UI.widgetBuild_value_ReverseFormatting(params,val_format_t_new)
    local val_new,val_format_new
    if params.is_dec_widget == true then
      val_new = Utils_parsedecstr(val_format_t_new, params)   
      val_format_new = Utils_formatdecstr(val_new, params)  
     elseif params.is_volume_widget == true then
      val_new = Utils_parsevolumestr(val_format_t_new, params)   
      val_format_new = Utils_formatvolumestr(val_new, params)  
     else
      val_new= Utils_parsetimestr(val_format_t_new, params) 
      local sys_rulformat = EXT.CONF_widg_time_formatoverride if params.rul_format then sys_rulformat = params.rul_format end
      val_format_new = Utils_formattimestr( val_new, '', sys_rulformat ) 
      if params.format_offset then val_format_new = Utils_formattimestr_len( val_new, '', params.format_offset, sys_rulformat ) end
    end
    return val_new,val_format_new
  end  
  
  -----------------------------------------------------------------------------------------  
  function DATA:ParseWidgetsOrder()
    DATA.widgets = {}
    for extkey in pairs(EXT) do
      if extkey:match('CONF_widgets') or extkey:match('CONF_availablewidgets') or extkey:match('CONF_contextpriority') then
        if not DATA.widgets[extkey] then DATA.widgets[extkey] = {} end
        local t = DATA.widgets[extkey]
        local line = EXT[extkey]
        local line_w, line_b = '',''
        if line:match('buttons=') then 
          line_w, line_b = line:match('(.*) buttons=(.*)')
         else
          line_w = line:match('.*')
        end
        local has_buttons
        for widget in line_w:gmatch('[^%s]+') do 
          if widget:match('#[%a]+') then 
            i = #t+1
            local widget_ID = widget:gsub('%s',''):match('#([%a]+)')
            local widget_flags = widget:match('[%d]+')
            t[i] = {widget_ID = widget_ID, widget_flags = tonumber(widget_flags) or 0}
            if widget=='#buttons' then has_buttons = i end 
          end
        end
        if line_b and has_buttons then
          t[has_buttons].isbuttons = true
          
          for but in line_b:gmatch('[^%s]+') do 
            if but:match('#[%a]+') then 
              t[has_buttons][#t[has_buttons]+1] = {butID =but:gsub('%s',''):match('#([%a]+)')}
            end
          end
          
        end
      end
      
    end
  end  
  ------------------------------------------------------------------------------------------------------------------  
  function DATA:_DefineWidgets()
    DATA.widget_def = {}
    
    -- persistent
    DATA.widget_def['pwswing'] = {
      collectdata_func = 'CollectData_Project_Grid',
      name = 'Swing',
      }
    DATA.widget_def['pwgrid'] = {
      collectdata_func = 'CollectData_Project_Grid',
      name = 'Grid',
      widget_W = 78*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwtimesellen'] = {
      collectdata_func = 'CollectData_Project_TimeSel',
      name = 'TS Len',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwtimeselend'] = {
      collectdata_func = 'CollectData_Project_TimeSel',
      name = 'TS End',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwtimeselstart'] = {
      collectdata_func = 'CollectData_Project_TimeSel',
      name = 'TS Pos',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwtimeselLeftEdge'] = {
      collectdata_func = 'CollectData_Project_TimeSel',
      name = 'TS L edge',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwlasttouchfx'] = {
      collectdata_func = 'CollectData_Project_LTFX',
      name = 'Last touched FX',
      widget_W = 180*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwtransport'] = {
      collectdata_func = 'CollectData_Project_Transport',
      widget_W = UI.widget_default_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwrepeatstate'] = {
      collectdata_func = 'CollectData_Project_Transport',
      widget_W = UI.widget_default_W*EXT.theming_float_fontscaling,
      }  
    DATA.widget_def['pwbpm'] = {
      collectdata_func = 'CollectData_Project_Tempo',
      widget_W = UI.widget_default_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwclock'] = {
      collectdata_func = 'CollectData_Project_Transport',
      widget_W = 200*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwmastermeter'] = {
      collectdata_func = 'CollectData_Project_Master',
      widget_W = 150*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwmasterscope'] = {
      collectdata_func = 'CollectData_Project_Master',
      widget_W = UI.widget_masterscopeW,
      }
    DATA.widget_def['pwtaptempo'] = {
      collectdata_func = 'CollectData_Project_Tempo',
      widget_W = UI.widget_default_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwmchanmeter'] = {
      collectdata_func = 'CollectData_Project_Master',
      widget_W = UI.widget_default_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['pwmasterswapmono'] = {
      collectdata_func = 'CollectData_Project_Master',
      widget_W = 60*EXT.theming_float_fontscaling,
      }
    
    
    -- item
    DATA.widget_def['itemname'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultname_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemcolor'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultcolor_W,
      }
    DATA.widget_def['itemlock'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling,
      }
   DATA.widget_def['itempreservepitch'] = {
     collectdata_func = 'CollectData_Item',
     widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling,
     } 
    DATA.widget_def['itemloop'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling,
      }
     DATA.widget_def['itemmute'] = {
       collectdata_func = 'CollectData_Item',
       widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling,
       }
    DATA.widget_def['itemchanmode'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemreverse'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itembwfsrc'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemtimebase'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemposition'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemsnap'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemleftedge'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemrightedge'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemlength'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemsourceoffset'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemfadein'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemfadeout'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemcomlen'] = {
      collectdata_func = 'CollectData_Item_Multiple',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemvol'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itempitch'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itemrate'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['itempan'] = {
      collectdata_func = 'CollectData_Item',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
      
      
    -- track
    DATA.widget_def['trackname'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaultname_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['trackcolor'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaultcolor_W,
      }
    DATA.widget_def['trackvol'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['trackpan'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['trackfxlist'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = 140*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['trackdelay'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['trackfreeze'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling*2,
      }
    DATA.widget_def['trackpolarity'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['trackparentsend'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling+5,
      }
    DATA.widget_def['trackmediaoffs'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['trackrecin'] = {
      collectdata_func = 'CollectData_Track',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    
    -- Envelope
    DATA.widget_def['envname'] = {
      collectdata_func = 'CollectData_Envelope',
      widget_W = UI.widget_defaultname_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['envfx'] = {
      collectdata_func = 'CollectData_Envelope',
      widget_W = UI.widget_defaultname_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['envpointpos'] = {
      collectdata_func = 'CollectData_Envelope',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['envpointval'] = {
      collectdata_func = 'CollectData_Envelope',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['envAIlooplen'] = {
      collectdata_func = 'CollectData_Envelope',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['envmarksame'] = {
      collectdata_func = 'CollectData_Envelope',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling,
      }
    
    -- MIDIEditor 
    DATA.widget_def['metakename'] = {
      collectdata_func = 'CollectData_MIDIEditor',
      widget_W = UI.widget_defaultname_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['meevtposition'] = {
      collectdata_func = 'CollectData_MIDIEditor',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['menotelen'] = {
      collectdata_func = 'CollectData_MIDIEditor',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['meCCval'] = {
      collectdata_func = 'CollectData_MIDIEditor',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['menotepitch'] = {
      collectdata_func = 'CollectData_MIDIEditor',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['menotevel'] = {
      collectdata_func = 'CollectData_MIDIEditor',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['meevtchan'] = {
      collectdata_func = 'CollectData_MIDIEditor',
      widget_W = UI.widget_defaultfloat_W*EXT.theming_float_fontscaling,
      }
        
      
    -- FX
    DATA.widget_def['fxoversample'] = {
      collectdata_func = 'CollectData_FX',
      widget_W = UI.widget_defaulttiming_W*EXT.theming_float_fontscaling,
      }
    DATA.widget_def['fxautobypass'] = {
      collectdata_func = 'CollectData_FX',
      widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling+10,
      }
    
    -- SE
      DATA.widget_def['sebypass'] = {
        collectdata_func = 'CollectData_SpecEdit',
        widget_W = UI.widget_defaultbut_W*EXT.theming_float_fontscaling+10,
        }
    
  end
  -------------------------------------------------------------------------------   
  function UI.widget_sebypass(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.SpecEdit then return end
    
    local widg_show_name = 'Bypass'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.SpecEdit.FLAGS&1~=1 then colstate = UI.widget_active_col end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_SpecEdit( {toggle_bypass = true}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  -------------------------------------------------------------------------------   
  function UI.widget_fxautobypass(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.FX then return end
    
    local widg_show_name = 'Auto\nbypass'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.FX.force_auto_bypass&1==1 then colstate = UI.widget_active_col end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_FX( {toggle_force_auto_bypass = true}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_fxoversample(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.FX then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      UI.widgetBuild_name(widget_ID, 'Oversampling')
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.FX.chain_oversample_format,
        val = DATA.CurState.FX.chain_oversample,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_FX( {set_CHOS = outputval}) end,
        --setoutputformatted_func = function(buf)  end,
        setoutput_func_reset = function() 
          DATA:WriteData_FX( {set_CHOS = 0}) 
        end, 
        mousedy_drag_ratio = 0.05,
        mousedy_wheel_ratio = 1,
      })
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_meevtchan(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Channel'
    if not (DATA.CurState.MIDIEditor and DATA.CurState.MIDIEditor.sel_evt and DATA.CurState.MIDIEditor.sel_evt.is3byte == true) then return end
    
    
    local widgW = UI.widget_default_W*EXT.theming_float_fontscaling
    if DATA.widget_def[widget_ID] and DATA.widget_def[widget_ID].widget_W then widgW = DATA.widget_def[widget_ID].widget_W end
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      UI.widgetBuild_name(widget_ID, widget_name)
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.MIDIEditor.sel_evt.CHAN_format,
        val = DATA.CurState.MIDIEditor.sel_evt.CHAN,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_MIDIEditor( {modify_evts = true, set_CHAN = outputval}) end,
        onrelease = function() DATA:WriteData_MIDIEditor( {confirm_changes = true}) end,
        setoutputformatted_func = function(buf) 
          if buf:lower():match('all') then buf = 0 end
          buf = tonumber(buf)
          if buf then 
            DATA:WriteData_MIDIEditor( {modify_evts = true, set_CHAN = buf}) 
            DATA:WriteData_MIDIEditor( {confirm_changes = true})
          end
        end,
        setoutput_func_reset = function() 
          DATA:WriteData_MIDIEditor( {modify_evts = true, set_CHAN = 0}) 
          DATA:WriteData_MIDIEditor( {confirm_changes = true})
        end, 
        mousedy_drag_ratio = 0.1,
        mousedy_wheel_ratio = 1,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_menotevel(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Velocity'
    if not (DATA.CurState.MIDIEditor and DATA.CurState.MIDIEditor.sel_evt and DATA.CurState.MIDIEditor.sel_evt.int_type == 0x9) then return end
    
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      UI.widgetBuild_name(widget_ID, widget_name)
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.MIDIEditor.sel_evt.VEL_format,
        val = DATA.CurState.MIDIEditor.sel_evt.VEL,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_MIDIEditor( {modify_evts = true, set_VEL = outputval}) end,
        onrelease = function() DATA:WriteData_MIDIEditor( {confirm_changes = true}) end,
        setoutputformatted_func = function(buf) 
          buf = tonumber(buf)
          if buf then 
            DATA:WriteData_MIDIEditor( {modify_evts = true, set_VEL = buf}) 
            DATA:WriteData_MIDIEditor( {confirm_changes = true})
          end
        end,
        setoutput_func_reset = function() 
          DATA:WriteData_MIDIEditor( {modify_evts = true, set_VEL = 120}) 
          DATA:WriteData_MIDIEditor( {confirm_changes = true})
        end, 
        mousedy_drag_ratio = 0.1,
        mousedy_wheel_ratio = 1,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_menotepitch(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Pitch'
    if not (DATA.CurState.MIDIEditor and DATA.CurState.MIDIEditor.sel_evt and DATA.CurState.MIDIEditor.sel_evt.int_type == 0x9) then return end
    
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      UI.widgetBuild_name(widget_ID, widget_name)
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.MIDIEditor.sel_evt.PITCH_format,
        val = DATA.CurState.MIDIEditor.sel_evt.PITCH,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_MIDIEditor( {modify_evts = true, set_PITCH = outputval}) end,
        onrelease = function() DATA:WriteData_MIDIEditor( {confirm_changes = true}) end,
        setoutputformatted_func = function(buf) 
          buf = tonumber(buf)
          if buf then 
            DATA:WriteData_MIDIEditor( {modify_evts = true, set_PITCH = buf}) 
            DATA:WriteData_MIDIEditor( {confirm_changes = true})
          end
        end,
        setoutput_func_reset = function() 
          DATA:WriteData_MIDIEditor( {modify_evts = true, set_PITCH = 36}) 
          DATA:WriteData_MIDIEditor( {confirm_changes = true})
        end, 
        mousedy_drag_ratio = 0.1,
        mousedy_wheel_ratio = 1,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_meCCval(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'CC val'
    if not (DATA.CurState.MIDIEditor and DATA.CurState.MIDIEditor.sel_evt and DATA.CurState.MIDIEditor.sel_evt.int_type == 0xB) then return end
    
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      UI.widgetBuild_name(widget_ID, widget_name)
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.MIDIEditor.sel_evt.CCVAL_format,
        val = DATA.CurState.MIDIEditor.sel_evt.CCVAL,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_MIDIEditor( {modify_evts = true, set_CCVAL = outputval}) end,
        onrelease = function() DATA:WriteData_MIDIEditor( {confirm_changes = true}) end,
        setoutputformatted_func = function(buf) 
          buf = tonumber(buf)
          if buf then 
            DATA:WriteData_MIDIEditor( {modify_evts = true, set_CCVAL = buf}) 
            DATA:WriteData_MIDIEditor( {confirm_changes = true})
          end
        end,
        setoutput_func_reset = function() 
          DATA:WriteData_MIDIEditor( {modify_evts = true, set_CCVAL = 0}) 
          DATA:WriteData_MIDIEditor( {confirm_changes = true})
        end, 
        mousedy_drag_ratio = 0.1,
        mousedy_wheel_ratio = 1,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  -------------------------------------------------------------------------------   
  function UI.widget_menotelen(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Length'
    
    if not (DATA.CurState.MIDIEditor and DATA.CurState.MIDIEditor.sel_evt and DATA.CurState.MIDIEditor.sel_evt.int_type == 0x9) then return end
    
    test = widget_t
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.MIDIEditor.sel_evt.D_LENGTH_format,
        val_format_t = DATA.CurState.MIDIEditor.sel_evt.D_LENGTH_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_MIDIEditor( {modify_evts = true, set_len = outputval}) end,
        onrelease = function() DATA:WriteData_MIDIEditor( {confirm_changes = true}) end,
        format_offset = DATA.CurState.MIDIEditor.sel_evt.start_pos,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_meevtposition(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Position'
    if not (DATA.CurState.MIDIEditor and DATA.CurState.MIDIEditor.sel_evt )  then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.MIDIEditor.sel_evt.D_POSITION_format,
        val_format_t = DATA.CurState.MIDIEditor.sel_evt.D_POSITION_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_MIDIEditor( {modify_evts = true, set_pos = outputval}) end,
        onrelease = function() DATA:WriteData_MIDIEditor( {confirm_changes = true}) end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_metakename(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not (DATA.CurState.MIDIEditor and DATA.CurState.MIDIEditor.take_name) then return end
    local widget_name = 'MIDI'
    if DATA.CurState.Item and DATA.CurState.Item.type_str then widget_name = DATA.CurState.Item.type_str end
    if DATA.CurState.MIDIEditor.sel_evt and DATA.CurState.MIDIEditor.sel_evt.str_type  then 
      widget_name = widget_name ..' / '..DATA.CurState.MIDIEditor.sel_evt.str_type 
    end
    
    local tk_name = DATA.CurState.MIDIEditor.take_name
    
    local widgW = DATA.widget_def[widget_ID].widget_W
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      UI.widgetBuild_value_single(widget_ID, {
        val_format = tk_name,
        val_available = true,
        setoutputformatted_func = function(buf) 
          if buf then 
            DATA:WriteData_MIDIEditor( {set_name = buf})
          end
        end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_envmarksame(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Envelope then return end
    
    local widg_show_name = 'Mark\nSame'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Envelope( {mark_same = true}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  -------------------------------------------------------------------------------   
  function UI.widget_envAIlooplen(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'AI pool len'
    if not (DATA.CurState.Envelope and DATA.CurState.Envelope.autoitem and DATA.CurState.Envelope.autoitem_idx~= -1 ) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Envelope.autoitem.D_POOL_LEN_format,
        val_format_t = DATA.CurState.Envelope.autoitem.D_POOL_LEN_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Envelope( {set_AIpoollen = outputval}) end,
        format_offset = DATA.CurState.Envelope.autoitem.D_POSITION,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_envpointval(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Value'
    if not (DATA.CurState.Envelope and DATA.CurState.Envelope.sel_point and DATA.CurState.Envelope.sel_point.D_POSITION ) then return end
    
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      UI.widgetBuild_name(widget_ID, widget_name)
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'envpointvalSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_envpointval()  
      local curvalue_format if DATA.CurState.Envelope.volume_mode~=true and EXT.CONF_widg_envpointval_usebrutforce&1==1 then curvalue_format = DATA.CurState.Envelope.curvalue_format end
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.Envelope.sel_point.D_VAL_format,
        val = DATA.CurState.Envelope.sel_point.D_VAL,
        val_available = true,
        atclick_func = function() DATA:WriteData_Envelope({set_val_printstate = true}) end,
        setoutput_func = function(outputval)  DATA:WriteData_Envelope({set_val = outputval}) end,
        setoutputformatted_func = function(buf) 
          buf = tonumber(buf)
          if buf then  DATA:WriteData_Envelope({set_val_format = buf}) end
        end,
        setoutput_func_reset = function()  DATA:WriteData_Envelope({set_val = 0})  end, 
        curvalue_format = curvalue_format ,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------  
  function UI.draw_settings_envpointval()    
    ImGui.PushFont(ctx, DATA.font, 14)
    local x, y = reaper.ImGui_GetMousePos( ctx )
    ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize( ctx, 0, 100, ImGui.Cond_Always)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
    if ImGui.BeginPopup( ctx, 'envpointvalSettings_page', ImGui.PopupFlags_None ) then 
      ImGui.SeparatorText(ctx, '#envpointval settings')
      if ImGui.Checkbox( ctx, 'Apply relative to selected point values', EXT.CONF_widg_envpointval_apprelative&1==1 ) then EXT.CONF_widg_envpointval_apprelative = EXT.CONF_widg_envpointval_apprelative ~1 EXT:save() end
      if ImGui.Checkbox( ctx, 'Use deductive brutforce for non-volume parameters', EXT.CONF_widg_envpointval_usebrutforce&1==1 ) then EXT.CONF_widg_envpointval_usebrutforce = EXT.CONF_widg_envpointval_usebrutforce ~1 EXT:save() end
      ImGui.EndPopup( ctx )
    end
    ImGui.PopStyleVar(ctx,2)
    ImGui.PopFont(ctx)
  end
  --------------------------------------------------------------------------------   
  function UI.widget_envpointpos(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Position'
    
    if not (DATA.CurState.Envelope and DATA.CurState.Envelope.sel_point and DATA.CurState.Envelope.sel_point.D_POSITION ) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Envelope.sel_point.D_POSITION_format,
        val_format_t = DATA.CurState.Envelope.sel_point.D_POSITION_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Envelope( {set_pos = outputval}) end, 
        atclick_func = function() DATA:WriteData_Envelope({set_val_printstate = true}) end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_envfx(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not (DATA.CurState.Envelope and DATA.CurState.Envelope.fxid) then return end
    
    local widg_show_name = DATA.CurState.Envelope.fxname 
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.Envelope.FXbypstate == true then 
        colstate = UI.widget_active_col 
      end
      
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##fx'..widget_ID,-1,-1, colstate) then 
        if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Shift()) then 
          DATA:WriteData_Envelope( {toggle_FXbypass = true}) 
         else
          DATA:WriteData_Envelope( {toggle_FXfloat = true}) 
        end
      end
      ImGui.PopFont(ctx) 
      
        
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_envname(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not (DATA.CurState.Envelope and DATA.CurState.Envelope.name) then return end
    local widget_name = DATA.CurState.Envelope.name
    
    local widgW = DATA.widget_def[widget_ID].widget_W
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.Envelope.srcUIname,
        val_available = false,
        setoutputformatted_func = function(buf) 
          if buf then 
            DATA:WriteData_Envelope( {set_name = buf})
          end
        end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_trackrecin(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Track then return end
    
    local widg_show_name = '[rec input]' 
    if DATA.CurState.Track.RECINPUT_states[DATA.CurState.Track.I_RECINPUT] then widg_show_name = DATA.CurState.Track.RECINPUT_states[DATA.CurState.Track.I_RECINPUT] end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.Track.I_RECINPUT~=-1 then 
        colstate = UI.widget_active_col 
        if DATA.CurState.Track.I_RECINPUT&4096==4096 then colstate = UI.widget_active_col2 end
      end
      
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Track( {set_trackrecin_reset = true}) end
      ImGui.PopFont(ctx) 
      
      -- whell scroll
      local vertical, horizontal = UI.vertical, UI.horizontal--reaper.ImGui_GetMouseWheel( ctx )
      if reaper.ImGui_IsItemHovered(ctx) then 
        if vertical > 0 then 
          DATA:WriteData_Track( {set_trackrecin_next = true}) 
         elseif vertical < 0 then 
          DATA:WriteData_Track( {set_trackrecin_prev = true}) 
        end
      end
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_trackmediaoffs(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Offset'
    if not DATA.CurState.Track then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.Track.D_PLAY_OFFSET_format,
        val = DATA.CurState.Track.D_PLAY_OFFSET,
        val_available = DATA.CurState.Track.I_PLAY_OFFSET_FLAG&1~=1,
        setoutput_func = function(outputval) 
          DATA:WriteData_Track( {set_offset = outputval})
        end,
        setoutputformatted_func = function(buf) 
          buf = tonumber(buf)
          if buf then 
            DATA:WriteData_Track( {set_offset = buf})
          end
        end,
        setoutput_func_reset = function() DATA:WriteData_Track( {set_offset = 0}) end, 
        mousedy_wheel_ratio = 0.001,
        mousedy_drag_ratio = 0.001,
      }) 
      
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_trackparentsend(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Track then return end
    
    local widg_show_name = 'Parent'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.Track.B_MAINSEND&1==1 then colstate = UI.widget_active_col end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Track( {toggle_parent = DATA.CurState.Track.B_MAINSEND~1}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_trackpolarity(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Track then return end
    
    local widg_show_name = 'Ø'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling+3) 
      local colstate
      if DATA.CurState.Track.B_PHASE&1==1 then colstate = UI.widget_active_col end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Track( {toggle_phase = true}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_trackfreeze(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Track then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      local butH = UI.widget_name_H*EXT.theming_float_fontscaling
      local widg_show_name = ''
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      
      if ImGui.Button(ctx,'Freeze##'..widget_ID,-1,butH) then DATA:WriteData_Track( {freeze = true}) end
      
      
      local colstate = 0x505050FF
      if DATA.CurState.Track.I_FREEZECOUNT>0 then colstate = UI.widget_active_col_red&0xFFFFFF00 end
      if ImGui.Custom_ColoredButton( ctx,'Unfreeze '..math.floor(DATA.CurState.Track.I_FREEZECOUNT)..'##'..widget_ID, -1,-1, colstate)then DATA:WriteData_Track( {unfreeze = true}) end
      
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_trackdelay(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Delay'
    if not DATA.CurState.Track then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.Track.DELAY_format,
        val = DATA.CurState.Track.DELAY,
        val_available = DATA.CurState.Track.DELAY_pos~=nil,
        setoutput_func = function(outputval) 
          DATA:WriteData_Track( {set_delay = outputval})
        end,
        setoutputformatted_func = function(buf) 
          buf = tonumber(buf)
          if buf then 
            DATA:WriteData_Track( {set_delay = buf})
          end
        end,
        setoutput_func_reset = function() DATA:WriteData_Track( {set_delay = 0}) end, 
        mousedy_wheel_ratio = 1,
        mousedy_drag_ratio = 1,
      }) 
      
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
    function UI.widget_trackfxlist(widget_t)
      if not widget_t then return end 
      local widget_ID = widget_t.widget_ID
      local widget_name = ''
      if not DATA.CurState.Track then return end
      if DATA.CurState.Track.FX and DATA.CurState.Track.FX.list and #DATA.CurState.Track.FX.list == 0 then return end
      
      local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
      local widgH = UI.widgetBuild_handleHstretch() 
      UI.widgetBuild_pushstyling() 
      if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
        if DATA.CurState.Track.FX.count == 0 then
          local ret = UI.widgetBuild_name(widget_ID,'FX list') 
          local ret2 = ImGui.InvisibleButton(ctx, '##val'..widget_ID,-1,-1)
          if ret or ret2 then Main_OnCommandEx(40271,0,-1) end
        end
        
        local xav, yav = ImGui.GetContentRegionAvail(ctx)
        local xpos, ypos = ImGui.GetCursorPos(ctx)
        local cur_fx = math.max(1,DATA.CurState.Track.FX.INTTOOLBAR_TRFXID)-1
        
        ImGui.PushFont(ctx, DATA.font, UI.font_fxlist)  
        if cur_fx ==0  then 
          ImGui.SetCursorPosY(ctx, ypos +  0.5*(yav  - UI.widget_name_H*EXT.theming_float_fontscaling) )
         else
          ImGui.SetCursorPosY(ctx, ypos +  0.5*(yav  - UI.widget_name_H*EXT.theming_float_fontscaling) - UI.widget_name_H*EXT.theming_float_fontscaling)
        end
        
        for i = cur_fx,  cur_fx + 3 do
          if DATA.CurState.Track.FX.list[i] then 
            local fx_name = DATA.CurState.Track.FX.list[i].name_reduced -- i..'/'..DATA.CurState.Track.FX.count..' '..
            
            local txtcol = UI.widget_name_col
            if DATA.CurState.Track.FX.list[i].bypstate ~= true then txtcol = UI.widget_val_col_disabled end
            ImGui.PushStyleColor(ctx, ImGui.Col_Text,txtcol)
            ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,0x505050FF)
            local ret = ImGui.Button(ctx, fx_name..'##but'..widget_ID..'fx'..i,-1, UI.widget_name_H*EXT.theming_float_fontscaling)
            
            -- toggle bypass
            if ret then  
              if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Ctrl()) then 
                DATA:WriteData_Track( {set_fxfloatchain = i-1})  
               elseif reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Shift()) then 
                DATA:WriteData_Track( {set_fxtogglebypass = i-1})  
               elseif reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Alt()) then 
                DATA:WriteData_Track( {set_fxremove = i-1})  
               else
                DATA:WriteData_Track( {set_fxfloat = i-1})  
              end
            end
            
            -- whell scroll
            local vertical, horizontal = UI.vertical, UI.horizontal--reaper.ImGui_GetMouseWheel( ctx )
            if reaper.ImGui_IsItemHovered(ctx) then 
              if vertical > 0 then 
                DATA:WriteData_Track( {set_fxlistactivefx = lim(DATA.CurState.Track.FX.INTTOOLBAR_TRFXID - 1,1, DATA.CurState.Track.FX.count)}) 
               elseif vertical < 0 then 
                DATA:WriteData_Track( {set_fxlistactivefx = lim(DATA.CurState.Track.FX.INTTOOLBAR_TRFXID + 1,1, DATA.CurState.Track.FX.count)}) 
              end
            end
            
            
            --if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then retR = true end 
            ImGui.PopStyleColor(ctx,2)
          end
        end
        
        ImGui.PopFont(ctx)
        ImGui.Dummy(ctx,0,0)
        ImGui.EndChild( ctx )
      end
      UI.widgetBuild_popstyling()
      return widgW
    end
    --------------------------------------------------------------------------------   
      function UI.widget_trackpan(widget_t)
        if not widget_t then return end 
        local widget_ID = widget_t.widget_ID
        local widget_name = 'Pan'
        if not DATA.CurState.Track then return end
        
        local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
        local widgH = UI.widgetBuild_handleHstretch() 
        UI.widgetBuild_pushstyling() 
        if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
          UI.widgetBuild_name(widget_ID,widget_name) 
          
          
          UI.widgetBuild_value_single(widget_ID, {
            val_format = DATA.CurState.Track.D_PAN_format,
            val = DATA.CurState.Track.D_PAN,
            val_available = true,
            setoutput_func = function(outputval) DATA:WriteData_Track( {set_pan = outputval}) end,
            setoutputformatted_func = function(buf) 
              if buf then 
                local outputval = Utils_parsepanstr(buf)   
                DATA:WriteData_Track( {set_pan = outputval})
              end
            end,
            setoutput_func_reset = function(outputval) DATA:WriteData_Track( {set_pan = 0}) end, 
          }) 
          
          
          ImGui.EndChild( ctx )
        end
        UI.widgetBuild_popstyling()
        return widgW
      end
  --------------------------------------------------------------------------------   
  function UI.widget_trackvol(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Volume'
    if not DATA.CurState.Track then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Track.D_VOL_format,
        val_format_t = DATA.CurState.Track.D_VOL_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Track( {set_vol = outputval}) end,
        minimalblock_W = UI.widget_defaulttiming_W_minimalblock_volume,
        is_volume_widget = true,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_trackcolor(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Track then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      local color = DATA.CurState.Track.I_CUSTOMCOLOR
      local color_used = color & 0x1000000==0x1000000
      local colorImGui = (ImGui.ColorConvertNative(color&0xFFFFFF) <<8)|0xFF
      local colorImGui_but = colorImGui
      if colorImGui_but == 0xFF then colorImGui_but = 0x5050502F end
      if DATA.CurState.Track.I_CUSTOMCOLOR == 16576 then colorImGui_but = 0x505050F0 end
      --ImGui.Dummy(ctx,0,1) ImGui.SameLine(ctx)
      if ImGui.Custom_ColoredButton(ctx, '##'..widget_ID, widgW, -1, colorImGui_but) then ImGui.OpenPopup(ctx, '##pickerPU'..widget_ID) end
      if ImGui.BeginPopup(ctx, '##pickerPU'..widget_ID) then
        -- is enabled
        if ImGui.Checkbox(ctx, 'Use custom color',color_used) then 
          local out_color = color ~ 0x1000000 
          DATA:WriteData_Track( {set_color = out_color})
        end
        -- set
        local ret, colRGBA =  ImGui.ColorPicker4(ctx, '##picker'..widget_ID, colorImGui, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs|ImGui.ColorEditFlags_NoSidePreview) 
        if ret then
          EXT.CONF_widg_trackcolor_lastcolRGBA = colRGBA 
          EXT:save()
          local colRGB = (colRGBA>>8)&0xFFFFFF
          local r, g, b = (colRGB>>16)&0xFF, (colRGB>>8)&0xFF, (colRGB>>0)&0xFF
          local out_color = ColorToNative( r, g, b )
          DATA:WriteData_Track( {set_color = out_color|0x1000000}) 
          
        end 
        -- recent
        ImGui.SeparatorText(ctx, 'Recent color')
        if ImGui.ColorButton(ctx, '##'..widget_ID,EXT.CONF_widg_trackcolor_lastcolRGBA ) then 
          local colRGBA = EXT.CONF_widg_trackcolor_lastcolRGBA
          local colRGB = (colRGBA>>8)&0xFFFFFF
          local r, g, b = (colRGB>>16)&0xFF, (colRGB>>8)&0xFF, (colRGB>>0)&0xFF
          local out_color = ColorToNative( r, g, b )
          DATA:WriteData_Track( {set_color = out_color|0x1000000})  
        end
        
        ImGui.EndPopup(ctx);
      end
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_trackname(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Track then return end
    local widget_name = DATA.CurState.Track.type_str
    local name = DATA.CurState.Track.name
    
    local widgW = DATA.widget_def[widget_ID].widget_W
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      UI.widgetBuild_value_single(widget_ID, {
        val_format = name,
        val_available = true,
        setoutputformatted_func = function(buf) 
          if buf then 
            DATA:WriteData_Track( {set_name = buf})
          end
        end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
--------------------------------------------------------------------------------   
  function UI.widget_itempan(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Pan'
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      
      
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.Item.D_PAN_format,
        val = DATA.CurState.Item.D_PAN,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_pan = outputval}) end,
        setoutputformatted_func = function(buf) 
          if buf then 
            local outputval = Utils_parsepanstr(buf)   
            DATA:WriteData_Item( {set_pan = outputval})
          end
        end,
        setoutput_func_reset = function(outputval) DATA:WriteData_Item( {set_pan = 0}) end, 
      }) 
      
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itemrate(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Playrate'
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      
      UI.widgetBuild_value_single(widget_ID, {
        val_format = DATA.CurState.Item.D_PLAYRATE_format,
        val = DATA.CurState.Item.D_PLAYRATE,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_rate = outputval}) end,
        setoutputformatted_func = function(buf)  if buf and tonumber(buf) then  DATA:WriteData_Item( {set_rate = tonumber(buf)}) end end,
        setoutput_func_reset = function(outputval) DATA:WriteData_Item( {set_rate = 1}) end, 
      }) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itempitch(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Pitch'
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_PITCH_format,
        val_format_t = DATA.CurState.Item.D_PITCH_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_pitch = outputval}) end,
        minimalblock_W = UI.widget_defaulttiming_W_minimalblock_volume,
        is_dec_widget = true,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itemvol(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Volume'
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_VOL_format,
        val_format_t = DATA.CurState.Item.D_VOL_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_vol = outputval}) end,
        minimalblock_W = UI.widget_defaulttiming_W_minimalblock_volume,
        is_volume_widget = true,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_itemfadeout(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Fade out'
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_FADEOUTLEN_format,
        val_format_t = DATA.CurState.Item.D_FADEOUTLEN_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_fadeout = outputval}) end,
        format_offset = DATA.CurState.Item.D_END-DATA.CurState.Item.D_FADEOUTLEN,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_itemfadein(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Fade in'
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_FADEINLEN_format,
        val_format_t = DATA.CurState.Item.D_FADEINLEN_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_fadein = outputval}) end,
        format_offset = DATA.CurState.Item.D_POSITION,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_itemsourceoffset(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Offset'
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets()
      local minimalblock_W, rul_format
      if DATA.CurState.Project.CountTempoTimeSigMarkers > 2 then 
        minimalblock_W = UI.widget_defaulttiming_W_minimalblock_ruler3 
        rul_format = 3
      end
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_STARTOFFS_format,
        val_format_t = DATA.CurState.Item.D_STARTOFFS_format_t,
        val_available = true,--DATA.CurState.Project.CountTempoTimeSigMarkers < 2 ,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_offset = outputval}) end,
        allow_negative = true,
        minimalblock_W = minimalblock_W,
        rul_format = rul_format,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  -------------------------------------------------------------------------------   
  function UI.widget_itemlength(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Length'
    if not (DATA.CurState.Item ) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_LENGTH_format,
        val_format_t = DATA.CurState.Item.D_LENGTH_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_length = outputval}) end,
        format_offset = DATA.CurState.Item.D_POSITION,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_itemrightedge(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'R edge'
    if not (DATA.CurState.Item ) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_END_format,
        val_format_t = DATA.CurState.Item.D_END_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_redge = outputval}) end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_itemleftedge(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'L edge'
    if not (DATA.CurState.Item ) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_POSITION_format,
        val_format_t = DATA.CurState.Item.D_POSITION_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_ledge = outputval}) end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_itemsnap(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Snap'
    if not (DATA.CurState.Item ) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_SNAPOFFSET_format,
        val_format_t = DATA.CurState.Item.D_SNAPOFFSET_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_snap = outputval}) end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_itemposition(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'Position'
    if not DATA.CurState.Item then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Item.D_POSITION_format,
        val_format_t = DATA.CurState.Item.D_POSITION_format_t,
        val_available = true,
        setoutput_func = function(outputval) DATA:WriteData_Item( {set_pos = outputval}) end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_itemtimebase(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'TimeBase'
    if not DATA.CurState.Item then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      
      
      local val_format = '-'
      if DATA.CurState.Item.C_BEATATTACHMODE == -1 then val_format = 'Default' end
      if DATA.CurState.Item.C_BEATATTACHMODE == 1 and DATA.CurState.Item.C_AUTOSTRETCH == 1 then val_format = 'Beats / Auto' end
      if DATA.CurState.Item.C_BEATATTACHMODE == 1 and DATA.CurState.Item.C_AUTOSTRETCH == 0 then val_format = 'Beats / All' end
      if DATA.CurState.Item.C_BEATATTACHMODE == 2 then val_format = 'Beats / Pos' end
      if DATA.CurState.Item.C_BEATATTACHMODE == 0 then val_format = 'Time' end
      UI.widgetBuild_value_single(widget_ID, {
        val_format = val_format,
        val_available = true,
      }) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Left) then reaper.ImGui_OpenPopup(ctx,'itemtimebaseSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_itemtimebase()  
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  
  --------------------------------------------------------------------------------  
    function UI.draw_settings_itemtimebase()    
      ImGui.PushFont(ctx, DATA.font, 14)
      local x, y = reaper.ImGui_GetMousePos( ctx )
      ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
      ImGui.SetNextWindowSize( ctx, 200, 0, ImGui.Cond_Always)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
      if ImGui.BeginPopup( ctx, 'itemtimebaseSettings_page', ImGui.PopupFlags_None ) then   
          
            local modes = {
              [0]='Default',
              [1]='Beats / Auto',
              [2]='Beats / All',
              [3]='Beats / Pos',
              [4]='Time',
            }
            
            local val = 0
            if DATA.CurState.Item.C_BEATATTACHMODE == 1 and DATA.CurState.Item.C_AUTOSTRETCH == 1 then val = 1 end
            if DATA.CurState.Item.C_BEATATTACHMODE == 1 and DATA.CurState.Item.C_AUTOSTRETCH == 0  then val = 2 end
            if DATA.CurState.Item.C_BEATATTACHMODE == 2 then val = 3 end
            if DATA.CurState.Item.C_BEATATTACHMODE == 0 then val = 4 end
            
            preview_value = modes[val] or ''
            if ImGui.BeginListBox( ctx, '##itemtimebaselist',0,0) then
              for mode in spairs(modes) do
                if ImGui.Selectable(ctx, modes[mode], mode==val) then 
                  DATA:WriteData_Item( {set_timebase = mode}) 
                  reaper.ImGui_CloseCurrentPopup(ctx)
                end
              end
              ImGui.EndListBox(ctx)
            end
            
        ImGui.EndPopup( ctx )
      end
      ImGui.PopStyleVar(ctx,2)
      ImGui.PopFont(ctx)
    end
  --------------------------------------------------------------------------------   
  function UI.widget_itembwfsrc(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widg_show_name = 'BWF'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1) then Main_OnCommandEx(40299,0,-1) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itemreverse(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widg_show_name = 'Rev'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.Item.Reverse&1==1 then colstate = UI.widget_active_col end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Item( {toggle_reverse = DATA.CurState.Item.Reverse~1}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itemchanmode(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = 'ChanMode'
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      
      local val_format = '-'
      if DATA.CurState.Item.I_CHANMODE == 0 then val_format = 'Normal' end
      if DATA.CurState.Item.I_CHANMODE == 1 then val_format = 'Reverse' end
      if DATA.CurState.Item.I_CHANMODE == 2 then val_format = 'Downmix' end
      if DATA.CurState.Item.I_CHANMODE == 3 then val_format = 'Left' end
      if DATA.CurState.Item.I_CHANMODE == 4 then val_format = 'Right' end
      UI.widgetBuild_value_single(widget_ID, {
        val_format = val_format,
        val_available = true,
      }) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Left) then reaper.ImGui_OpenPopup(ctx,'itemchanmodeSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_itemchanmode()  
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------  
    function UI.draw_settings_itemchanmode()    
      ImGui.PushFont(ctx, DATA.font, 14)
      local x, y = reaper.ImGui_GetMousePos( ctx )
      ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
      ImGui.SetNextWindowSize( ctx, 200, 0, ImGui.Cond_Always)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
      if ImGui.BeginPopup( ctx, 'itemchanmodeSettings_page', ImGui.PopupFlags_None ) then  
        
            local modes = {
              [0]='Normal',
              [1]='Reverse',
              [2]='Downmix',
              [3]='Left',
              [4]='Right',
            }
            
            preview_value = modes[DATA.CurState.Item.I_CHANMODE] or ''
            if ImGui.BeginListBox( ctx, 'Channel mode##chanmode',0,0) then--, size_wIn, size_hIn )
            --if ImGui.BeginCombo( ctx, 'Channel mode##chanmode', preview_value, ImGui.ComboFlags_HeightLargest ) then
              for mode in spairs(modes) do
                if ImGui.Selectable(ctx, modes[mode], mode==DATA.CurState.Item.I_CHANMODE) then 
                  DATA:WriteData_Item( {set_chanmode = mode})
                  reaper.ImGui_CloseCurrentPopup(ctx)
                end
              end
              --ImGui.EndCombo(ctx)
              ImGui.EndListBox(ctx)
            end
            
        ImGui.EndPopup( ctx )
      end
      ImGui.PopStyleVar(ctx,2)
      ImGui.PopFont(ctx)
    end
  --------------------------------------------------------------------------------   
  function UI.widget_itemmute(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widg_show_name = 'Mute'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.Item.B_MUTE&1==1 then colstate = UI.widget_active_col_red end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Item( {toggle_mute = DATA.CurState.Item.B_MUTE~1}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  -------------------------------------------------------------------------------   
  function UI.widget_itemloop(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Item then return end
    
    local widg_show_name = 'Loop'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.Item.B_LOOPSRC&1==1 then colstate = UI.widget_active_col end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Item( {toggle_loop = DATA.CurState.Item.B_LOOPSRC~1}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itemlock(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Item then return end
    
    local widg_show_name = 'Lock'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then  
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate 
      if DATA.CurState.Item.C_LOCK&1==1 then colstate = UI.widget_active_col_red end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Item( {toggle_lock = DATA.CurState.Item.C_LOCK~1}) end
      ImGui.PopFont(ctx)  
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itempreservepitch(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widg_show_name = 'Pres\npitch'
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colstate
      if DATA.CurState.Item.B_PPITCH&1==1 then colstate = UI.widget_active_col end
      if ImGui.Custom_InvisibleButton(ctx,widg_show_name..'##items'..widget_ID,-1,-1, colstate) then DATA:WriteData_Item( {toggle_preservepitch = DATA.CurState.Item.B_PPITCH~1}) end
      ImGui.PopFont(ctx) 
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itemcolor(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not (DATA.CurState.Item and DATA.CurState.Item.tk_ptr) then return end
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      local color = DATA.CurState.Item.I_CUSTOMCOLOR
      local color_used = color & 0x1000000==0x1000000
      local colorImGui = (ImGui.ColorConvertNative(color&0xFFFFFF) <<8)|0xFF
      local colorImGui_but = colorImGui
      if colorImGui_but == 0xFF then colorImGui_but = 0x5050502F end
      --ImGui.Dummy(ctx,0,1) ImGui.SameLine(ctx)
      if ImGui.Custom_ColoredButton(ctx, '##'..widget_ID, widgW, -1, colorImGui_but) then ImGui.OpenPopup(ctx, '##pickerPU'..widget_ID) end
      if ImGui.BeginPopup(ctx, '##pickerPU'..widget_ID) then
        -- is enabled
        if ImGui.Checkbox(ctx, 'Use custom color',color_used) then 
          local out_color = color ~ 0x1000000 
          DATA:WriteData_Item( {set_color = out_color})
        end
        -- set
        local ret, colRGBA =  ImGui.ColorPicker4(ctx, '##picker'..widget_ID, colorImGui, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs|ImGui.ColorEditFlags_NoSidePreview) 
        if ret then
          EXT.CONF_widg_itemcolor_lastcolRGBA = colRGBA EXT:save()
          local colRGB = (colRGBA>>8)&0xFFFFFF
          local r, g, b = (colRGB>>16)&0xFF, (colRGB>>8)&0xFF, (colRGB>>0)&0xFF
          local out_color = ColorToNative( r, g, b )
          DATA:WriteData_Item( {set_color = out_color|0x1000000}) 
          
        end 
        -- recent
        ImGui.SeparatorText(ctx, 'Recent color')
        if ImGui.ColorButton(ctx, '##'..widget_ID,EXT.CONF_widg_itemcolor_lastcolRGBA ) then 
          local colRGBA = EXT.CONF_widg_itemcolor_lastcolRGBA
          local colRGB = (colRGBA>>8)&0xFFFFFF
          local r, g, b = (colRGB>>16)&0xFF, (colRGB>>8)&0xFF, (colRGB>>0)&0xFF
          local out_color = ColorToNative( r, g, b )
          DATA:WriteData_Item( {set_color = out_color|0x1000000})  
        end
        
        ImGui.EndPopup(ctx);
      end
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_itemname(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    if not DATA.CurState.Item then return end
    
    widget_name = DATA.CurState.Item.type_str
    local tk_name = DATA.CurState.Item.tk_name
    
    local widgW = DATA.widget_def[widget_ID].widget_W
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      UI.widgetBuild_value_single(widget_ID, {
        val_format = tk_name,
        val_available = true,
        setoutputformatted_func = function(buf) 
          if buf then 
            DATA:WriteData_Item( {set_name = buf})
          end
        end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_pwmasterswapmono(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name 
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    if not DATA.CurState.Master then return widgW end
    
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      local str = DATA.CurState.Master.chancntformat
      ImGui.PushFont(ctx, DATA.font, UI.font_widgbut*EXT.theming_float_fontscaling) 
      local colSwap,colMono
      if DATA.CurState.Master.Swap == true then colSwap = UI.widget_active_col end
      if DATA.CurState.Master.MONO == true then colMono = UI.widget_active_col end
      if ImGui.Custom_InvisibleButton(ctx,'Swap LR##masterswapmono1'..widget_ID,-1,UI.widget_default_H*EXT.theming_float_fontscaling*0.5-UI.spacingY*2, colSwap) then DATA:CollectData_Project_Master(true, {swap = true}) end
      ImGui.Dummy(ctx,0,1)
      if ImGui.Custom_InvisibleButton(ctx,'Mono##masterswapmono2'..widget_ID,-1,-1, colMono)  then DATA:CollectData_Project_Master(true, {togglemono = true}) end
      ImGui.PopFont(ctx) 
      ImGui.PopStyleVar(ctx,1)
      ImGui.EndChild( ctx ) 

    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwmchanmeter(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    if not DATA.CurState.Master then return widgW end
    
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      local str = DATA.CurState.Master.chancntformat
      ImGui.PushFont(ctx, DATA.font, UI.font_widgname*EXT.theming_float_fontscaling) 
      ImGui.Custom_InvisibleButton(ctx,str..'##mchanmeter'..widget_ID,-1,-1)
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'mchanmeterSettings_page',ImGui.PopupFlags_None) end
      UI.draw_settings_mchanmeter() 
      UI.HelpMarker(DATA.CurState.Master.MCpeaks_tooltip_conc)
      
      -- draw peaks
      local x,y  =ImGui_GetItemRectMin(ctx)
      local w,h  =ImGui_GetItemRectSize(ctx)
      local chancnt = DATA.CurState.Master.chancnt
      local binW = w/chancnt
      for i = 1, chancnt do
        local peak = DATA.CurState.Master.MCpeaks[i]
        if peak > 0 then 
          local p_min_x = x + binW * (i-1)
          local p_min_y = y+h-h*peak
          local p_max_x= p_min_x + binW
          local p_max_y = y+h 
          local col_normal = UI.widget_col_peaksnormal
          local col_loud = UI.widget_col_peaksloud 
          local col_peaks = col_normal
          if peak > 1 then peak = 1 col_peaks = col_loud end
          ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, col_peaks, 1, ImGui.DrawFlags_None )
        end
      end
      
      
      ImGui.PopFont(ctx) 
      ImGui.PopStyleVar(ctx,1)
      ImGui.EndChild( ctx )
      
  
    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwtaptempo(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    if not DATA.CurState.Master then return widgW end
    
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      local bpm = DATA.taptempo.output
      if EXT.CONF_widg_taptempo_quantize&1==1 then bpm = DATA.taptempo.output_q end
      local str = bpm or 'Tap'
      ImGui.PushFont(ctx, DATA.font, UI.font_widgname*EXT.theming_float_fontscaling) 
      if ImGui.Custom_InvisibleButton(ctx,str..'##taptempo'..widget_ID,-1,-1) then 
        DATA:Actions_Tap()
      end 
      if DATA.taptempo.output then 
        if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'taptempoSettings_page',ImGui.PopupFlags_None) end
      end
      UI.draw_settings_taptempo() 
      ImGui.PopFont(ctx) 
      ImGui.PopStyleVar(ctx,1)
      ImGui.EndChild( ctx )
    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwmasterscope(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    if not DATA.CurState.Master then return widgW end
    
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      
      local x1,y1 = ImGui.GetCursorScreenPos(ctx)
      local xav, yav = ImGui.GetContentRegionAvail(ctx)
      local lx,ly,lx2,ly2 = x1, y1, x1 + xav, y1+yav/2-1
      local rx,ry,rx2,ry2 = x1, y1+yav/2, x1 + xav, y1+yav
      local hsz = (ly2 - ly)*0.5
        local col_normal = UI.widget_col_peaksnormal
        local col_loud = UI.widget_col_peaksloud
      
      --ImGui.DrawList_AddRectFilled( UI.draw_list, lx,ly,lx2,ly2, 0xFFFFFF3F,2, ImGui.DrawFlags_None )
      --ImGui.DrawList_AddRectFilled( UI.draw_list, rx,ry,rx2,ry2, 0x0FFFFF3F,2, ImGui.DrawFlags_None )
      local peaks_cnt = UI.widget_masterscopeW
      for i = 1, peaks_cnt do
        local peakL = DATA.CurState.Master.peakL[i] or 0
        local col_peaks = col_normal
        if peakL > 1 then peakL = 1 col_peaks = col_loud end
        ImGui.DrawList_AddLine( UI.draw_list, lx2 - i, ly+hsz - peakL*hsz , lx2 - i, ly+hsz + peakL*hsz, col_peaks, 1 )
        
        local peakR = DATA.CurState.Master.peakR[i] or 0
        local col_peaks = col_normal
        if peakR > 1 then peakR = 1 col_peaks = col_loud end
        ImGui.DrawList_AddLine( UI.draw_list, rx2 - i, ry+hsz - peakR*hsz , rx2 - i, ry+hsz + peakR*hsz, col_peaks, 1 )
        
      end
      
      ImGui.PopStyleVar(ctx,1)
      ImGui.EndChild( ctx )
    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwmastermeter(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    if not DATA.CurState.Master then return widgW end
    
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      ImGui.PushStyleColor(ctx, ImGui.Col_Text,             EXT.theming_rgba_valtxt)
      local fontclock = UI.font_widgclock*EXT.theming_float_fontscaling 
      ImGui.PushFont(ctx, DATA.font, fontclock) 
      ImGui.Custom_InvisibleButton(ctx,DATA.CurState.Master.loudness..'##masterloudness'..widget_ID,-1,-1)
      if reaper.ImGui_IsItemHovered(ctx) then 
        local pos_x, pos_y = ImGui.GetItemRectMin(ctx) 
        local pos_x2, pos_y2 = ImGui.GetItemRectMax(ctx) 
        ImGui.DrawList_AddTextEx( UI.draw_list, DATA.font, 11, pos_x, pos_y2-11, 0x50F0509F, DATA.CurState.Master.VU_mode_format )
      end 
      ImGui.PopFont(ctx) 
      ImGui.PopStyleVar(ctx,1)
      ImGui.PopStyleColor(ctx,1)
      ImGui.EndChild( ctx )
    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwclock(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      ImGui.PushStyleColor(ctx, ImGui.Col_Text,             EXT.theming_rgba_valtxt)
      local fontclock = UI.font_widgclock*EXT.theming_float_fontscaling
      local  h = -1
      if EXT.CONF_widg_clock_formatoverride2 ~= -2 then h = 0 fontclock = 15 end 
      ImGui.PushFont(ctx, DATA.font, fontclock) 
      ImGui.Custom_InvisibleButton(ctx,DATA.CurState.PostCalc.editcurpos_format..'##cl0'..widget_ID,-1,h)
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'BigClockSettings_page',ImGui.PopupFlags_None) end
      if EXT.CONF_widg_clock_formatoverride2 ~= -2 then 
        ImGui.Custom_InvisibleButton(ctx,DATA.CurState.PostCalc.editcurpos_format2..'##cl1'..widget_ID,-1,-1)
      end
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'BigClockSettings_page',ImGui.PopupFlags_None) end 
      UI.draw_settings_BigClock() 
      --
      ImGui.PopFont(ctx) 
      ImGui.PopStyleVar(ctx,1)
      ImGui.PopStyleColor(ctx,1)
      ImGui.EndChild( ctx )
    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwbpm(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    if not DATA.CurState.Tempo then return widgW end
    
    
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      ImGui.PushFont(ctx, DATA.font, UI.font_widgname*EXT.theming_float_fontscaling) 
      -- bpm
        reaper.ImGui_SetNextItemWidth(ctx,-1)
        local retval, buf = ImGui.InputText( ctx, '##but'..widget_ID, DATA.CurState.Tempo.TempoMarker_bpm_format, ImGui.InputTextFlags_AutoSelectAll )
        if ImGui_IsItemDeactivatedAfterEdit(ctx) then DATA:CollectData_Project_Tempo(true,{settempo = buf})  end 
      -- wheel
        local vertical, horizontal = UI.vertical, UI.horizontal--reaper.ImGui_GetMouseWheel( ctx )
        if reaper.ImGui_IsItemHovered(ctx) and vertical ~= 0 then
          DATA:CollectData_Project_Tempo(true,{changetempo = vertical})
        end 
      -- timesig
        reaper.ImGui_SetNextItemWidth(ctx,-1)
        local retval, buf = ImGui.InputText( ctx, '##but2'..widget_ID, DATA.CurState.Tempo.TempoMarker_timesig_format, ImGui.InputTextFlags_AutoSelectAll )
        if ImGui_IsItemDeactivatedAfterEdit(ctx) then DATA:CollectData_Project_Tempo(true,{settimesig = buf})  end
      ImGui.PopFont(ctx) 
      ImGui.PopStyleVar(ctx,1)
      ImGui.EndChild( ctx )
    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end   
  --------------------------------------------------------------------------------   
  function UI.widget_pwrepeatstate(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    if not DATA.CurState.Transport then return widgW end
    
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      local xav, yav = ImGui.GetContentRegionAvail(ctx)
      local ctrl = ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl)
      if ImGui.Button(ctx, '##transport_repeat',-1,-1) then
        DATA:CollectData_Project_Transport(true,{repeat2 = true})
      end
      
      local tint_col_rgbaIn = 0xA0A0A09F
      if DATA.CurState and DATA.CurState.Transport and DATA.CurState.Transport.repeat_state and DATA.CurState.Transport.repeat_state == 1 then tint_col_rgbaIn =0x50BF50CF end
      local img = UI.image_repeat
      if img and reaper.ImGui_ValidatePtr(img, 'ImGui_Image*') then 
        local p_min_x, p_min_y = reaper.ImGui_GetItemRectMin(ctx)
        local p_max_x, p_max_y = reaper.ImGui_GetItemRectMax(ctx)
        local wsz, hsz = reaper.ImGui_GetItemRectSize(ctx)
        local w, h = reaper.ImGui_Image_GetSize(img )
        local scale = 0.7*( math.min(wsz, hsz)-UI.spacingX) /  math.min(w,h) 
        local xpos = p_min_x +0.5*( wsz-w*scale) 
        local ypos = p_min_y +0.5*( hsz-h*scale) 
        local uv_min_xIn, uv_min_yIn, uv_max_xIn, uv_max_yIn = nil,nil,nil,nil
        ImGui.DrawList_AddImage( UI.draw_list, img, xpos, ypos,  xpos+w*scale,  ypos+h*scale, uv_min_xIn, uv_min_yIn, uv_max_xIn, uv_max_yIn, tint_col_rgbaIn )
      end
      ImGui.PopStyleVar(ctx,1)
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwtransport(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID 
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    if not DATA.CurState.Transport then return widgW end
    
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY)  
      local xav, yav = ImGui.GetContentRegionAvail(ctx)
      local ctrl = ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl)
      if ImGui.Button(ctx, '##transport',-1,-1) then
        if DATA.CurState.Transport.play == true then 
          if ctrl then 
            DATA:CollectData_Project_Transport(true,{setrecord=true}) 
           else
            DATA:CollectData_Project_Transport(true,{setstop=true})  
          end
         else 
          if ctrl then   
            DATA:CollectData_Project_Transport(true,{setplay=true})   
            DATA:CollectData_Project_Transport(true,{setrecord=true}) 
           else 
            DATA:CollectData_Project_Transport(true,{setplay=true}) 
          end
        end
      end
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TransportSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_Transport()
      
      local x,y = ImGui.GetItemRectMin(ctx)
      local w,h = ImGui.GetItemRectSize(ctx)
      local tr_sz = 10
      local round = 2 
      local flickA = 0xFF
      local flickA_play = flickA
      if EXT.CONF_widg_transport_flicker&1==1 and DATA.CurState.PostCalc.play_flicker then 
        flickA_play = math.floor(lim(DATA.CurState.PostCalc.play_flicker)*255) 
      end
      local colplay0 = 0x50BF5000
      local colrec0 = 0xDF505000
      local col_play = colplay0|flickA_play
      local col_rec =  colrec0|flickA_play
      local col_stop = 0xA0A0A000|flickA
      local col_progress = 0 
      if DATA.CurState.Transport.record == true then
        ImGui.DrawList_AddCircleFilled( UI.draw_list, x+0.5*w, y+0.5*h, tr_sz, col_rec, 0 )
        col_progress = colrec0|flickA
       elseif DATA.CurState.Transport.pause == true then
        col_progress = col_stop
         ImGui.DrawList_AddRectFilled( UI.draw_list, 
           x+0.5*w-tr_sz, y+0.5*h-tr_sz, 
           x+0.5*w-round, y+0.5*h+tr_sz, 
           col_stop,
           round)
         ImGui.DrawList_AddRectFilled( UI.draw_list, 
           x+0.5*w+round, y+0.5*h-tr_sz, 
           x+0.5*w+tr_sz, y+0.5*h+tr_sz, 
           col_stop,
           round)           
       elseif DATA.CurState.Transport.play == true then
        col_progress = colplay0|flickA
        ImGui.DrawList_AddTriangleFilled( UI.draw_list, 
          x+0.5*w-tr_sz, y+0.5*h-tr_sz, 
          x+0.5*w+tr_sz, y+0.5*h, 
          x+0.5*w-tr_sz, y+0.5*h+tr_sz, 
          col_play )
       else
        col_progress = col_stop
         ImGui.DrawList_AddRectFilled( UI.draw_list, 
           x+0.5*w-tr_sz, y+0.5*h-tr_sz, 
           x+0.5*w+tr_sz, y+0.5*h+tr_sz, 
           col_stop,
           round)
      end 
      if DATA.CurState.PostCalc.editcursor_pos_rel and DATA.CurState.PostCalc.editcursor_pos_rel~=0 then
        ImGui.DrawList_AddRectFilled( UI.draw_list, 
          x,y+h-2,
          x+w*DATA.CurState.PostCalc.editcursor_pos_rel,y+h,
          col_progress,
          1)
      end
      ImGui.PopStyleVar(ctx,1)
      ImGui.EndChild( ctx )
    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwlasttouchfx(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling)
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX|ImGui.ChildFlags_FrameStyle,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,UI.spacingY*2) 
      if DATA.CurState.LTFX and DATA.CurState.LTFX.exist==true then widget_name = DATA.CurState.LTFX_fxname end
      UI.widgetBuild_name(widget_ID,widget_name) 
      if  reaper.ImGui_IsItemClicked(ctx, reaper.ImGui_MouseButton_Right()) then  reaper.Main_OnCommandEx(41142,0,-1)   end
      
      if DATA.temp_inputmode[widget_ID] ~= true then 
        if DATA.CurState.LTFX_istoggle ~= true then
          -- slider
          if DATA.CurState.LTFX_val_format then 
            ImGui.SetNextItemWidth(ctx,-1) 
            local retval, v = ImGui.SliderDouble( ctx, '##slider'..widget_ID, DATA.CurState.LTFX_val, 0, 1, DATA.CurState.LTFX_parname..': '..DATA.CurState.LTFX_val_format, reaper.ImGui_SliderFlags_None()|reaper.ImGui_SliderFlags_NoInput() ) 
            local doubleclicked = reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left())
            -- set value
            if retval then DATA:CollectData_Project_LTFX(true,{set_fxparam=v}) end 
            -- right click to input
            if reaper.ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then DATA.temp_inputmode[widget_ID] = true end
            
          end
         else
          local state = DATA.CurState.LTFX_val ==1
          if DATA.CurState.LTFX_istoggle_inverted == true then state = not state end
          if ImGui.Checkbox(ctx, DATA.CurState.LTFX_parname..'##toggle'..widget_ID,state ) then
            DATA:CollectData_Project_LTFX(true,{set_fxparam=DATA.CurState.LTFX_val~1})
          end
        end
      end
      
      if DATA.temp_inputmode[widget_ID] == true  then
        ImGui.SetNextItemWidth(ctx, -1)
        local retval, buf = ImGui.InputText( ctx, '##slidertxtin'..widget_ID, DATA.CurState.LTFX_val_format, ImGui.InputFlags_None)
        ImGui.SetKeyboardFocusHere(ctx,-1) 
        if reaper.ImGui_IsItemDeactivated(ctx) then
          DATA:CollectData_Project_LTFX(true,{set_fxparam_formatted=buf})
          DATA.temp_inputmode[widget_ID] = nil
        end
      end
      
      ImGui.PopStyleVar(ctx,1)
      ImGui.EndChild( ctx )
    end
    ImGui.PopFont(ctx)
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwtimeselLeftEdge(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets()  
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Project.TS_st_format,
        val_format_t = DATA.CurState.Project.TS_st_format_t,
        val = DATA.CurState.Project.TS_st,
        val_available = true,
        setoutput_func = function(outputval) 
          DATA:CollectData_Project_TimeSel(true, {set_tsledge = outputval}) 
        end,
        setoutputformatted_func = function(buf) 
          if buf then 
            DATA:CollectData_Project_TimeSel(true, {set_tsledge_format = buf})
          end
        end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwtimeselstart(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Project.TS_st_format,
        val_format_t = DATA.CurState.Project.TS_st_format_t,
        val = DATA.CurState.Project.TS_st,
        val_available = true,
        setoutput_func = function(outputval) 
          DATA:CollectData_Project_TimeSel(true, {set_tsst = outputval}) 
        end,
        setoutputformatted_func = function(buf) 
          if buf then 
            DATA:CollectData_Project_TimeSel(true, {set_tsst_format = buf})
          end
        end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwtimeselend(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then 
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Project.TS_end_format,
        val_format_t = DATA.CurState.Project.TS_end_format_t,
        val = DATA.CurState.Project.TS_end,
        val_available = true,
        setoutput_func = function(outputval) 
          DATA:CollectData_Project_TimeSel(true, {set_tsend = outputval}) 
        end,
        setoutputformatted_func = function(buf) 
          if buf then 
            DATA:CollectData_Project_TimeSel(true, {set_tsend_format = buf})
          end
        end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwtimesellen(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      UI.widgetBuild_name(widget_ID,widget_name) 
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then reaper.ImGui_OpenPopup(ctx,'TimeWidgetsSettings_page',ImGui.PopupFlags_None) end UI.draw_settings_TimeWidgets() 
      UI.widgetBuild_value_multi(widget_ID, {
        val_format = DATA.CurState.Project.TS_len_format,
        val_format_t = DATA.CurState.Project.TS_len_format_t,
        val = DATA.CurState.Project.TS_len,
        val_available = true,
        setoutput_func = function(output) 
          DATA:CollectData_Project_TimeSel(true, {set_tslen = output}) 
        end,
        setoutputformatted_func = function(buf) 
          if buf then 
            DATA:CollectData_Project_TimeSel(true, {set_tslen_format = buf})
          end
        end,
      }) 
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end 
  --------------------------------------------------------------------------------   
  function UI.widget_pwswing(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch() 
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
      if DATA.CurState.Project.swingmode then 
      if UI.widgetBuild_name(widget_ID, widget_name) then DATA:CollectData_Project_Grid(true, {toggleswing = true}) end  
        
        
        UI.widgetBuild_value_single(widget_ID, {
          val_format = DATA.CurState.Project.swingamt_format,
          val = DATA.CurState.Project.swingamt,
          val_available = DATA.CurState.Project.swingmode&1==1,
          setoutput_func = function(outputval) 
            DATA:CollectData_Project_Grid(true, {setswing = outputval})
          end,
          setoutputformatted_func = function(buf) 
            buf = tonumber(buf)
            if buf then 
              DATA:CollectData_Project_Grid(true, {setswing_format = buf})
            end
          end,
          setoutput_func_reset = function() DATA:CollectData_Project_Grid(true, {setswing = 0}) end, 
        }) 
        
        
      end
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  --------------------------------------------------------------------------------   
  function UI.widget_pwgrid(widget_t)
    if not widget_t then return end 
    local widget_ID = widget_t.widget_ID
    local widget_name = DATA.widget_def[widget_ID].name
    
    local widgW = DATA.widget_def[widget_ID].widget_W  or UI.widget_default_W*EXT.theming_float_fontscaling
    local widgH = UI.widgetBuild_handleHstretch()  
    UI.widgetBuild_pushstyling() 
    if  ImGui.BeginChild( ctx, widget_ID, widgW, widgH,  ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeX,  ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollWithMouse|ImGui.WindowFlags_NoScrollbar ) then
       
      local retL, retR = UI.widgetBuild_name(widget_ID, widget_name)
      if retL then DATA:CollectData_Project_Grid(true, {togglegrid = true}) end
      if retR then Main_OnCommand(40071, 0) end
      
      UI.widgetBuild_value_single(widget_ID, {
        width = 40,
        val_format = DATA.CurState.Project.grid_format,
        val = DATA.CurState.Project.grid_denom_pow,
        val_available = DATA.CurState.Project.grid_enabled==true,
        mousedy_drag_ratio = -0.05,
        mousedy_wheel_ratio = -1,
        setoutput_func = function(outputval)
          DATA:CollectData_Project_Grid(true, {setgrid = outputval})
        end,
      }) 
      
      
      ImGui.PushFont(ctx, DATA.font, UI.font_widgval*EXT.theming_float_fontscaling) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX*2,UI.spacingY )
      -- triplet
      ImGui.SameLine(ctx) 
      local col = 0
      if DATA.CurState.Project.grid_istriplet == true and DATA.CurState.Project.grid_enabled==true then col=UI.widget_active_col end
      local valcol = EXT.theming_rgba_valtxt 
      if DATA.CurState.Project.grid_enabled~=true then valcol = EXT.theming_rgba_valtxt_unavailable end 
      if ImGui.Custom_InvisibleButton(ctx, 'T##'..widget_ID..'tip',0,-1, col, valcol) then DATA:CollectData_Project_Grid(true, {toggeltriplet = true}) end
      
      -- rel
      ImGui.SameLine(ctx) 
      local col = 0
      if DATA.CurState.Project.grid_relative == true and DATA.CurState.Project.grid_enabled==true then col=UI.widget_active_col end
      local valcol = EXT.theming_rgba_valtxt 
      if DATA.CurState.Project.grid_enabled~=true then valcol = EXT.theming_rgba_valtxt_unavailable end 
      if ImGui.Custom_InvisibleButton(ctx, 'R##'..widget_ID..'rel',0,-1, col, valcol) then DATA:CollectData_Project_Grid(true, {togglegridrel = true}) end
      ImGui.PopStyleVar(ctx)
      ImGui.PopFont(ctx)
      
      ImGui.EndChild( ctx )
    end
    UI.widgetBuild_popstyling()
    return widgW
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_settings_BigClock()    
    ImGui.PushFont(ctx, DATA.font, 14)
    local x, y = reaper.ImGui_GetMousePos( ctx )
    ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize( ctx, 500, 100, ImGui.Cond_Always)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
    if ImGui.BeginPopup( ctx, 'BigClockSettings_page', ImGui.PopupFlags_None ) then 
      ImGui.SeparatorText(ctx, 'Big clock settings')
      
          local modes = {
            [-1]='Project default',
            [0]='Time',
            [2]='Measures.beats',
            [3]='Seconds',
            [4]='Samples',
            [5]='H:M:S:F',
          }
          preview_value = modes[EXT.CONF_widg_clock_formatoverride] or ''
          if ImGui.BeginCombo( ctx, 'Big clock format##CONF_widg_clock_formatoverride', preview_value, ImGui.ComboFlags_HeightLargest ) then
            for mode in spairs(modes) do
              if ImGui.Selectable(ctx, modes[mode], mode==EXT.CONF_widg_clock_formatoverride) then 
                EXT.CONF_widg_clock_formatoverride = mode 
                EXT:save() 
                DATA:CollectData_Project_TimeSel()
              end
            end
            ImGui.EndCombo(ctx)
          end
          modes[-2]='Off'
          preview_value = modes[EXT.CONF_widg_clock_formatoverride2] or ''
          if ImGui.BeginCombo( ctx, 'Big clock format2##CONF_widg_clock_formatoverride2', preview_value, ImGui.ComboFlags_HeightLargest ) then
            for mode in spairs(modes) do
              if ImGui.Selectable(ctx, modes[mode], mode==EXT.CONF_widg_clock_formatoverride2) then 
                EXT.CONF_widg_clock_formatoverride2 = mode 
                EXT:save() 
                DATA:CollectData_Project_TimeSel()
              end
            end
            ImGui.EndCombo(ctx)
          end
          
      ImGui.EndPopup( ctx )
    end
    ImGui.PopStyleVar(ctx,2)
    ImGui.PopFont(ctx)
  end
  --------------------------------------------------------------------------------  
  function UI.draw_settings_TimeWidgets()    
    ImGui.PushFont(ctx, DATA.font, 14)
    local x, y = reaper.ImGui_GetMousePos( ctx )
    ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize( ctx, 0, 100, ImGui.Cond_Always)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
    if ImGui.BeginPopup( ctx, 'TimeWidgetsSettings_page', ImGui.PopupFlags_None ) then 
      ImGui.SeparatorText(ctx, 'Time widgets settings')
          local modes = {
            [-1]='Project default',
            [0]='Time',
            [2]='Measures.beats',
            [3]='Seconds',
            [4]='Samples',
            [5]='H:M:S:F',
            [6]='Frames',
          }
          local preview_value = modes[EXT.CONF_widg_time_formatoverride] or ''
          if ImGui.BeginCombo( ctx, 'Time widgets format##CONF_widg_time_formatoverride', preview_value, ImGui.ComboFlags_HeightLargest ) then
            for mode in spairs(modes) do
              if ImGui.Selectable(ctx, modes[mode], mode==EXT.CONF_widg_time_formatoverride) then 
                EXT.CONF_widg_time_formatoverride = mode 
                EXT:save() 
                --DATA:CollectData_Project_TimeSel()
                --DATA:CollectData_AtStateChange()
                --DATA:CollectData_Always() 
                DATA:CollectData_RefreshTimeWidgetsSizing() 
              end
            end
            ImGui.EndCombo(ctx)
          end
          
          
          if ImGui.Checkbox( ctx, 'Snap time selection widgets to grid on edit',  EXT.CONF_widg_time_snaptogrid&1==1 ) then EXT.CONF_widg_time_snaptogrid=EXT.CONF_widg_time_snaptogrid~1 EXT:save() end
          
      ImGui.EndPopup( ctx )
    end
    ImGui.PopStyleVar(ctx,2)
    ImGui.PopFont(ctx)
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_settings_Transport()    
    ImGui.PushFont(ctx, DATA.font, 14)
    local x, y = reaper.ImGui_GetMousePos( ctx )
    ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize( ctx, 500, 100, ImGui.Cond_Always)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
    if ImGui.BeginPopup( ctx, 'TransportSettings_page', ImGui.PopupFlags_None ) then 
      ImGui.SeparatorText(ctx, 'Transport settings')
      if ImGui.Checkbox( ctx, 'Transport flickering',  EXT.CONF_widg_transport_flicker&1==1 ) then EXT.CONF_widg_transport_flicker=EXT.CONF_widg_transport_flicker~1 EXT:save()  end
      ImGui.EndPopup( ctx )
    end
    ImGui.PopStyleVar(ctx,2)
    ImGui.PopFont(ctx)
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_settings_taptempo()    
    ImGui.PushFont(ctx, DATA.font, 14)
    local x, y = reaper.ImGui_GetMousePos( ctx )
    ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize( ctx, 300, 500, ImGui.Cond_Always)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
    if ImGui.BeginPopup( ctx, 'taptempoSettings_page', ImGui.PopupFlags_None ) then 
      if DATA.taptempo.output then 
        local bpm = DATA.taptempo.output
        if EXT.CONF_widg_taptempo_quantize&1==1 then bpm = DATA.taptempo.output_q end 
        local freq = 60/bpm 
        ImGui.TextColored(ctx, 0x50F050FF, bpm )
        if ImGui.Checkbox(ctx,'Quantize tempo', EXT.CONF_widg_taptempo_quantize&1==1) then EXT.CONF_widg_taptempo_quantize=EXT.CONF_widg_taptempo_quantize~1 EXT:save() end
        --if not DATA.taptempo.output then ImGui.BeginDisabled(ctx, true) end
        if ImGui.Selectable(ctx, 'Apply as new project tempo / last marker')    then DATA:CollectData_Project_Tempo(true,{settempo=bpm}) end
        if ImGui.Selectable(ctx, 'Apply as new tempo marker')    then DATA:CollectData_Project_Tempo(true,{addtempomarker=bpm}) end
        if ImGui.Selectable(ctx, 'Stretch selected item')    then DATA:CollectData_Project_Tempo(true,{stretchitem=bpm}) end
        
        local form = '%.3f'
        local s_info =  'Frequency: '..freq..'Hz\n\n'..
                        
                        ' 1/2:  '..string.format(form,        1000        * 120/bpm)..'ms\n'..
                        ' 1/2T:  '..string.format(form,       1000 * 2/3  * 120/bpm)..'ms\n'..
                        ' 1/2 dotted:  '..string.format(form, 1000 * 3/2  * 120/bpm)..'ms\n'..
                        ' 1/2 cycle: '..string.format(form,   1/(           120/bpm))..'Hz\n\n'..
                                                                         
                        ' 1/4:  '..string.format(form,        1000        * 60/bpm)..'ms\n'..
                        ' 1/4T:  '..string.format(form,       1000 * 2/3  * 60/bpm)..'ms\n'..
                        ' 1/4 dotted:  '..string.format(form, 1000 * 3/2  * 60/bpm)..'ms\n'..
                        ' 1/4 cycle: '..string.format(form,   1/(           60/bpm))..'Hz\n\n'..
                        
                        ' 1/8:  '..string.format(form,        1000        * 30/bpm)..'ms\n'..
                        ' 1/8T:  '..string.format(form,       1000 * 2/3  * 30/bpm)..'ms\n'..
                        ' 1/8 dotted:  '..string.format(form, 1000 * 3/2  * 30/bpm)..'ms\n'..                                                                 
                        ' 1/8 cycle: '..string.format(form,   1/(           30/bpm))..'Hz\n\n'..
                        
                        ' 1/16:  '..string.format(form,        1000        * 15/bpm)..'ms\n'..
                        ' 1/16T:  '..string.format(form,       1000 * 2/3  * 15/bpm)..'ms\n'..
                        ' 1/16 dotted:  '..string.format(form, 1000 * 3/2  * 15/bpm)..'ms\n'..
                        ' 1/16 cycle: '..string.format(form,   1/(           15/bpm))..'Hz\n\n'
                        
        ImGui.SeparatorText(ctx, 'Delay times')
        ImGui.PushFont(ctx, DATA.font, 13)                
        ImGui.TextWrapped(ctx, s_info)
        ImGui.PopFont(ctx)
        --if not DATA.taptempo.output then ImGui.EndDisabled(ctx) end
      end
      ImGui.EndPopup( ctx )
    end
    ImGui.PopStyleVar(ctx,2)
    ImGui.PopFont(ctx)
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_settings_mchanmeter()    
    ImGui.PushFont(ctx, DATA.font, 14)
    local x, y = reaper.ImGui_GetMousePos( ctx )
    ImGui.SetNextWindowPos( ctx, x+UI.popupmouseoffs, y+UI.popupmouseoffs, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize( ctx, 300, 50, ImGui.Cond_Always)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
    if ImGui.BeginPopup( ctx, 'mchanmeterSettings_page', ImGui.PopupFlags_None ) then 
      
      local trch = {}
      for trchID = 2, 64,2 do
        trch[trchID] = trchID..' channels'
      end 
      
      preview_value = DATA.CurState.Master.chancnt..' channels'
      ImGui.Text(ctx,'Set master parent channels to ')
      if ImGui.BeginCombo( ctx, '##mchanmeter', preview_value, ImGui.ComboFlags_HeightLargest ) then
        for trchID in spairs(trch) do
          if ImGui.Selectable(ctx, trch[trchID], trchID==DATA.CurState.Master.chancnt) then DATA:CollectData_Project_Master(true, {setchancnt=trchID}) end
        end
        ImGui.EndCombo(ctx)
      end
      
      ImGui.EndPopup( ctx )
    end
    ImGui.PopStyleVar(ctx,2)
    ImGui.PopFont(ctx)
  end
  -----------------------------------------------------------------------------------------  
  function _main() 
    --main_LoadExternalLibs()
    DATA:_DefineWidgets() 
    EXT.defaults = CopyTable(EXT) 
    EXT:load() 
    EXT.CONF_availablewidgets = EXT.defaults.CONF_availablewidgets -- overwrite available widgets 
    UI.MAIN_definecontext() 
    DATA:CollectData_AtStateChange() -- init refresh
    DATA:CollectData_Always() 
  end     
  -----------------------------------------------------------------------------------------      
  _main()
    