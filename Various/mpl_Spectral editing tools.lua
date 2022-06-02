-- @description Spectral editing tools
-- @version 1.0
-- @author MPL
-- @about Various tools for spectral editing
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + port Script: mpl_Add spectral edit at specified frequency.lua
--    # improved parsing item chunk

    
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  --[[
  Script: mpl_Copy selected item spectral edits.lua
  Script: mpl_Explode and solo selected item spectral edits.lua
  Script: mpl_Explode selected item spectrally at 3 bands.lua
  Script: mpl_Paste and replace spectral edits to selected item.lua
  Script: mpl_Port focused ReaEQ bands to spectral edits on selected items.lua
  Script: mpl_Remove all spectral edits from selected items active takes.lua
  Script: mpl_Remove all spectral edits from selected items.lua
  Script: mpl_Toggle bypass all spectral edits in selected items active takes.lua
  Script: mpl_Toggle bypass all spectral edits in selected items.lua
  
  -- pencil
  -- add pattern
  -- analyzer + clever artefacts remove
  ]]
  
  local DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 1.0
    DATA.extstate.extstatesection = 'SETools'
    DATA.extstate.mb_title = 'Spectral editing tools'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  500,
                          wind_h =  500,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          -- mode
                          CONF_action = 2, -- init
                            -- 2 == add SE at specified frequency
                          
                          -- CONF_action = 2 add at spec freq
                          CONF_ASF_Fbase = 10000,
                          CONF_ASF_Farea = 1000,
                          CONF_ASF_Gaindb = -10,
                          
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          UI_processoninit = 0,
                          
                          }
                          
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets()  
    if DATA.extstate.UI_initatmouse&1==1 then
      local w = DATA.extstate.wind_w
      local h = DATA.extstate.wind_h 
      local x, y = GetMousePosition()
      DATA.extstate.wind_x = x-w/2
      DATA.extstate.wind_y = y-h/2
    end
    
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    --DATA.GUI.default_scale = 2
    
    -- init main stuff
      DATA.GUI.custom_mainbuth = 30*DATA.GUI.default_scale
      DATA.GUI.custom_texthdef = 23
      DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
      DATA.GUI.custom_mainsepx = gfx.w/DATA.GUI.default_scale--(gfx.w/DATA.GUI.default_scale)*0.4-- *DATA.GUI.default_scale--400*DATA.GUI.default_scale--
      DATA.GUI.custom_mainbutw = gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*2 --(gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*3
      DATA.GUI.custom_scrollw = 10
      DATA.GUI.custom_frameascroll = 0.05
      DATA.GUI.custom_default_framea_normal = 0.1
      DATA.GUI.custom_spectralw = DATA.GUI.custom_mainbutw*3 + DATA.GUI.custom_offset*2
      DATA.GUI.custom_datah = (gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset*3) 
    
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    
    -- buttons
      local txt = ''
      local t_map = {
        [1] = '#Action',
        [2]='Add spectral edit at specific frequency',
        }
      for i = 1, #t_map do
        if DATA.extstate.CONF_action == i then txt = t_map[i]  end
      end
      DATA.GUI.buttons = {} 
      DATA.GUI.buttons.app = {  x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = txt,
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              local mt = {}
                                              for i = 1, #t_map do
                                                mt[#mt+1] = {str=t_map[i],
                                                             func = function() DATA.extstate.CONF_action = i DATA.UPD.onconfchange = true DATA.UPD.onGUIinit = true end}
                                              end
                                              DATA:GUImenu(mt)
                                            end} 
      DATA.GUI.buttons.preset = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_short = (DATA.extstate.CONF_NAME or '[untitled]'),
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA:GUIbut_preset() end}                                             
      DATA.GUI.buttons.exec = {  x=DATA.GUI.custom_offset,
                            y=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_offset*5,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Run',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              DATA2:Process()
                                            end}                        
      DATA.GUI.buttons.Rsettings = { x=gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx,
                            y=2*DATA.GUI.custom_mainbuth + DATA.GUI.custom_offset*2,
                            w=DATA.GUI.custom_mainsepx,
                            h=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth*3 - DATA.GUI.custom_offset*3,
                            txt = 'Settings',
                            --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            frame_a = 0,
                            offsetframe = DATA.GUI.custom_offset,
                            offsetframe_a = 0.1,
                            ignoremouse = true,
                            }
      DATA:GUIBuildSettings()
      
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_refresh()
    DATA.custom = {valid = false, items = {}}
    DATA.custom.loopS, DATA.custom.loopE = GetSet_LoopTimeRange2( 0, false, 0, -1, -1, false )
    for i = 1, CountSelectedMediaItems(0) do 
      local item = GetSelectedMediaItem(0,i-1)
      local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local tk = GetActiveTake( item )
      local src =  GetMediaItemTake_Source( tk )
      local SR = GetMediaSourceSampleRate( src )
      local tk_id = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
      local ret, SEdata = DATA2:Process_GetSpectralData(item)    
      DATA.custom.items[i] = {item_ptr = item,
                              item_pos = item_pos,
                              item_len = item_len,
                              tk_ptr = tk,
                              tk_src = src,
                              tk_SR = SR,
                              tk_id = tk_id,
                              SEdata = SEdata
                              }
    end
    DATA.custom.valid = true
  end
  -------------------------------------------------------
  function DATA2:Process_AddSpectralEditIntoTable(it_table)
    local SEdata = it_table.SEdata
    local tk_id = it_table.tk_id
    local SR = it_table.tk_SR
    local item_pos = it_table.item_pos
    local item_len = it_table.item_len
    local loopS = DATA.custom.loopS
    local loopE = DATA.custom.loopE
    
    local F_base = DATA.extstate.CONF_ASF_Fbase
    local F_Area = DATA.extstate.CONF_ASF_Farea
    local gain_dB = DATA.extstate.CONF_ASF_Gaindb
                              
    
    if not SEdata.takes[tk_id+1] then return end
    if not SEdata.takes[tk_id+1].SE then SEdata.takes[tk_id+1].SE = {} end
    
      
    -- obey time selection
    local pos, len = 0, item_len
    if loopE - loopS > 0.001 then 
      if loopS >= item_pos and loopS <= item_pos + item_len then pos = loopS- item_pos end
      if loopE >= item_pos and loopE <= item_pos + item_len then 
        len = loopE - loopS 
       else
        len = item_pos + item_len - loopS
      end
    end
    local freq_L = math.max(0, F_base-F_Area)
    local freq_H = math.min(SR, F_base+F_Area)
    
    
    SEdata.takes[tk_id+1].SE [ #SEdata.takes[tk_id+1].SE + 1] = 
      {pos = pos,
       len = len,
       gain = 10^(gain_dB/20),
       fadeinout_horiz = 0,
       fadeinout_vert = 0,
       freq_low = freq_L,
       freq_high = freq_H,
       chan = -1, -- -1 all 0 L 1 R
       bypass = 0, -- bypass&1 solo&2
       gate_threshold = 0,
       gate_floor = 0,
       compress_threshold = 1,
       compress_ratio = 1,
       unknown1 = 1,
       unknown2 = 1,
       fadeinout_horiz2 = 0, 
       fadeinout_vert2 = 0}
  end
  ---------------------------------------------------------------------  
  function DATA2:Process()
    
    if DATA.extstate.CONF_action == 2 then -- Add spectral edit at specific frequency
      DATA2:Process_refresh()
      if not DATA.custom.valid then return end
      Undo_BeginBlock() 
      for i = 1, #DATA.custom.items do
        DATA2:Process_AddSpectralEditIntoTable(DATA.custom.items[i]) 
        DATA2:Process_SetSpectralData(DATA.custom.items[i])  
      end
      Undo_EndBlock( 'Add spectral edit at specific frequency', 0xFFFFFFFF )
    end
    
  end      
    
    
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 200
    local SR_spls = 22050--tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    
    

                          
    local  t = 
    {    
        {str = 'Frequency center' ,                 group = 1, itype = 'readout', confkey = 'CONF_ASF_Fbase',
          val_res = 0.05, 
          val_min = 0, 
          val_max = SR_spls, 
          val_format = function(x) return math.floor(x)..'Hz' end,
          hide=DATA.extstate.CONF_action~=2
          },
        {str = 'Frequency area' ,                   group = 1, itype = 'readout', confkey = 'CONF_ASF_Farea', 
          val_res = 0.05, 
          val_min = 10, 
          val_max = 5000, 
          val_format = function(x) return math.floor(x)..'Hz' end,
          hide=DATA.extstate.CONF_action~=2
          },
        {str = 'Gain' ,                      group = 1, itype = 'readout', confkey = 'CONF_ASF_Gaindb',
          val_res = 0.05, 
          val_min = -80, 
          val_max = 2, 
          val_format = function(x) return math.floor(x)..'dB' end,
          hide=DATA.extstate.CONF_action~=2
          },
          
          
      --[[{str = 'Global' ,                       group = 1, itype = 'sep'}, 
        {str = 'Bypass',                      group = 1, itype = 'check', confkey = 'CONF_bypass', level = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Mode' ,                       group = 1, itype = 'readout', level = 1,  confkey = 'CONF_mode', menu = { 
          [0]='Peak follower', 
          [1]='Gate', 
          [2] = 'Compressor (by ashcat_lt & SaulT)',
          [4] = 'Peak fol. difference',
          --[3] = 'Deesser (by Liteon)', 
          },readoutw_extw=readoutw_extw, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Boundaries' ,                 group = 1, itype = 'readout', level = 1,  confkey = 'CONF_boundary', menu = { [0]='Item edges', [1]='Time selection'},readoutw_extw=readoutw_extw, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
      {str = 'Audio data reader' ,            group = 3, itype = 'sep'},
        {str = 'Clear take volume envelope before' ,             group = 3, itype = 'check', confkey = 'CONF_removetkenvvol', level = 1}, 
        {str = 'FFT size' ,                   group = 3, itype = 'readout', level = 1,  confkey = 'CONF_FFTsz', func_onrelease = function() DATA2:ProcessAtChange(DATA) end, menu = { 
          [-1]='[disabled]', 
          [1024]='1024', 
          [2048] ='2048'},
          hide=DATA.extstate.CONF_mode==2
        },
        {str = 'FFT min freq' ,                 group = 3, itype = 'readout', confkey = 'CONF_FFT_min', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return math.floor(x*SR_spls/2)..'Hz' end, 
          val_format_rev = function(x) return VF_lim(x/(SR_spls/2),0,SR_spls) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          hide=DATA.extstate.CONF_action~=2
          }, 
        {str = 'FFT max freq' ,                 group = 3, itype = 'readout', confkey = 'CONF_FFT_max', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return math.floor(x*SR_spls/2)..'Hz' end, 
          val_format_rev = function(x) return VF_lim(x/(SR_spls/2),0,SR_spls) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          hide=DATA.extstate.CONF_FFTsz==-1 or  DATA.extstate.CONF_mode==2
          },        
        {str = 'RMS Window' ,                 group = 3, itype = 'readout', confkey = 'CONF_window', level = 1, 
          val_min = 0.001, 
          val_max = 0.4, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(x*1000)/1000)..'s' end, 
          val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          hide=DATA.extstate.CONF_mode==2,--  or DATA.extstate.CONF_FFTsz~=-1
          },
       {str = 'Window overlap' ,                 group = 3, itype = 'readout', confkey = 'CONF_windowoverlap', level = 1, val_isinteger = true,
         val_min = 1, 
         val_max = 16, 
         val_res = 0.05, 
         val_format = function(x) return x..'x' end, 
         val_format_rev = function(x) return VF_lim(math.floor(tonumber(x) or 1), 1,16) end, 
         func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
         hide=DATA.extstate.CONF_mode==2,--  or DATA.extstate.CONF_FFTsz~=-1
         },         
          
        {str = 'Normalize envelope' ,          group = 3, itype = 'check', confkey = 'CONF_normalize', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode==2,}, 
        {str = 'Scale envelope x^[0.5...4]' ,              group = 3, itype = 'readout', val_min = 0.5, val_max = 4, val_res = 0.05, confkey = 'CONF_scale', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode==2,
          val_format = function(x) return math.floor(x*1000)/1000 end, 
          val_format_rev = function(x) return tonumber(x) end, }, 
        {str = 'Offset' ,              group = 3, itype = 'readout', val_min = -1, val_max = 1, val_res = 0.05, confkey = 'CONF_offset', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode==2,
          val_format = function(x) return math.floor(x*1000)/1000 end, 
          val_format_rev = function(x) return tonumber(x) end, },    
        {str = 'Smooth' ,              group = 3, itype = 'readout', val_min = 1, val_max = 15, val_res = 0.05, confkey = 'CONF_smoothblock', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode==2, val_isinteger = true,
          val_format = function(x) return (math.floor(1000*x*DATA.extstate.CONF_window/DATA.extstate.CONF_windowoverlap)/1000)..'s' end, 
          val_format_rev = function(x) return math.floor(tonumber(x/(DATA.extstate.CONF_window/DATA.extstate.CONF_windowoverlap))) end, },             
  
                    
          
      {str = 'Mode parameters' ,     group = 2, itype = 'sep'},
      
        -- gate 
        {str = 'Threshold' ,             group = 2, itype = 'readout', confkey = 'CONF_gate_threshold', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(SLIDER2DB((x*1000))*10)/10)..'dB' end, 
          val_format_rev = function(x) return VF_lim(DB2SLIDER(x)/1000, 0,1000) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=1},
          
        -- compressor
        {str = 'Threshold' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_threshold', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(SLIDER2DB((x*1000))*10)/10)..'dB' end, 
          val_format_rev = function(x) return VF_lim(DB2SLIDER(x)/1000, 0,1000) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},   
        {str = 'Lookahead / delay' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_lookahead', level = 1, 
          val_res = 0.05, 
          val_min = -0.05,
          val_max = 0.05,
          val_format = function(x) return (math.floor(x*10000)/10)..'ms' end, 
          val_format_rev = function(x) return VF_lim((tonumber(x) or 0)/1000, -0.05,0.05) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},           
        {str = 'Attack' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_attack', level = 1, 
          val_res = 0.05, 
          val_min = 0,
          val_max = 0.5,
          val_format = function(x) return (math.floor(x*10000)/10)..'ms' end, 
          val_format_rev = function(x) return VF_lim((tonumber(x) or 0), 0,500)/1000 end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},             
        {str = 'Release' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_release', level = 1, 
          val_res = 0.05, 
          val_min = 0,
          val_max = 5,
          val_format = function(x) return (math.floor(x*10000)/10)..'ms' end, 
          val_format_rev = function(x) return VF_lim((tonumber(x) or 0), 0,500)/1000 end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},             
        {str = 'Ratio' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_Ratio', level = 1, 
          val_res = 0.05, 
          val_min = 1,
          val_max = 41,
          val_format = function(x) if x == 41 then return '-inf' else return (math.floor(x*10)/10)..' : 1' end end ,
          val_format_rev = function(x) 
            local y= x:match('[%d%.]+')
            if not y then return 2 end
            y = tonumber(y)
            if y then return VF_lim(y, 1,21) end 
          end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},            
        {str = 'Knee' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_knee', level = 1, 
          val_res = 0.05, 
          val_min = 0,
          val_max = 20,
          val_format = function(x) return (math.floor(x*10)/10)..'dB' end, 
          val_format_rev = function(x) return VF_lim(      math.floor((tonumber(x) or 0)*10)/10      , 0,20) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},        
        {str = 'RMS Window' ,                 group = 3, itype = 'readout', confkey = 'CONF_window', level = 1, 
          val_min = 0.002, 
          val_max = 0.4, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(x*1000))..'ms' end, 
          val_format_rev = function(x) return tonumber(x:match('[%d%.]+')/1000) end,
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          hide=DATA.extstate.CONF_mode~=2
          },          
          
          
      {str = 'Destination' ,                    group = 4, itype = 'sep'},
        {str = 'Track volume env AI' ,          group = 4, itype = 'check', confkey = 'CONF_dest', level = 1, isset = 0, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Take volume env' ,              group = 4, itype = 'check', confkey = 'CONF_dest', level = 1, isset = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
      {str = 'Output' ,                         group = 6, itype = 'sep'},
        {str = 'Reduce points with same values',group = 6, itype = 'check', confkey = 'CONF_reducesamevalues', level = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Invert points',                 group = 6, itype = 'check', confkey = 'CONF_out_invert', level = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Scale x*[0...1]' ,              group = 3, itype = 'readout', val_min = 0, val_max = 1, val_res = 0.05, confkey = 'CONF_out_scale', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
            val_format = function(x) return math.floor(x*1000)/1000 end, 
            val_format_rev = function(x) return tonumber(x) end, },    
        {str = 'Offset' ,              group = 3, itype = 'readout', val_min = -1, val_max = 1, val_res = 0.05, confkey = 'CONF_out_offs', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          val_format = function(x) return math.floor(x*1000)/1000 end, 
          val_format_rev = function(x) return tonumber(x) end, },          

        {str = 'Reset boundary edges',          group = 6, itype = 'check', confkey = 'CONF_zeroboundary', level = 1, func_onrelease = function()DATA2:ProcessAtChange(DATA)  end},
      {str = 'UI options' ,                     group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,             group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse' ,             group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        --{str = 'Show tootips' ,               group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        {str = 'Process on settings change',    group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
        {str = 'Process on initialization',     group = 5, itype = 'check', confkey = 'UI_processoninit', level = 1},]]
    } 
    return t
    
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Process_GetSpectralData(item)
    if not item then return end
    local chunksrc = ({GetItemStateChunk( item, '', false )})[2]
    local chunk = 'TAKE\n'..chunksrc:match('NAME.*'):gsub('TAKE[%s-]','ENDTAKE\nTAKE '):sub(0,-3)..'ENDTAKE'
    local pat = '([%d%.]+%s[%d%.]+)' -- pattern for free draw
    local pat2 = '([%d%.]+)%s([%d%.]+)' -- pattern for free draw extract
    local data  = {itemchunk = chunksrc:match('(.-)NAME'), takes = {}}
    for takeblock in chunk:gmatch('TAKE(.-)ENDTAKE') do 
      local tkid = #data.takes+1
      data.takes[tkid] = {}
      if takeblock:match('%sSEL%s') then data.takes[tkid].selected = true end
      takeblock = takeblock:gsub('%sSEL%s','') 
      data.takes[tkid].chunk=takeblock 
      local FFT_sz = takeblock:match('SPECTRAL_CONFIG ([%d]+)')
      if FFT_sz then data.takes[tkid].FFT_sz = tonumber(FFT_sz) end
      
      local take = GetMediaItemTake( item, tkid-1 )
      local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS'  )
      local rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE'  ) 
      data.takes[tkid].rate = rate
      data.takes[tkid].s_offs = s_offs
      
      data.takes[tkid].SE = {}
      local SEid = 0
      for line in takeblock:gmatch('[^\r\n]+') do
        if not line:match('SPECTRAL_EDIT') then  goto nextline end
        if line:match('SPECTRAL_EDIT%s') then 
          SEid = SEid + 1 
          local tnum = {} for num in line:gmatch('[^%s]+') do if tonumber(num) then tnum[#tnum+1] = tonumber(num) end end
          data.takes[tkid].SE[SEid] =       
                                {pos = (tnum[1] - s_offs)/rate,
                                 len = tnum[2]/rate,
                                 gain = tnum[3],
                                 fadeinout_horiz = tnum[4], -- knobleft/2 + knobright/2
                                 fadeinout_vert = tnum[5], -- knoblower/2 + knobupper/2
                                 freq_low = tnum[6],
                                 freq_high = tnum[7],
                                 chan = tnum[8], -- -1 all 0 L 1 R
                                 bypass = tnum[9], -- bypass&1 solo&2
                                 gate_threshold = tnum[10],
                                 gate_floor = tnum[11],
                                 compress_threshold = tnum[12],
                                 compress_ratio = tnum[13],
                                 unknown1 = tnum[14],
                                 unknown2 = tnum[15],
                                 fadeinout_horiz2 = tnum[16],  -- knobright - knobleft
                                 fadeinout_vert2 = tnum[17],
                                 freedrawT = {},
                                 freedrawB = {}} -- knobupper - knoblower      
        end
        if line:match('SPECTRAL_EDIT_T') and SEid > 0 then local tpairs = {}  for pair in line:gmatch(pat) do  local v1,v2 = pair:match(pat2) table.insert(data.takes[tkid].SE[SEid].freedrawT, {ptpos = tonumber(v1), ptval = tonumber(v2)})  end end
        if line:match('SPECTRAL_EDIT_B') and SEid > 0 then local tpairs = {}  for pair in line:gmatch(pat) do  local v1,v2 = pair:match(pat2) table.insert(data.takes[tkid].SE[SEid].freedrawB, {ptpos = tonumber(v1), ptval = tonumber(v2)}) end end
        ::nextline::
      end
    end
    return true, data
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Process_SetSpectralData(item_t)
    local data = item_t.SEdata
    local item = item_t.item_ptr
    if not (data and item) then return end
    local out_chunk = data.itemchunk
    for tkid = 1, #data.takes do
      -- add basic take data
      local tkchunksrc = data.takes[tkid].chunk:gsub('SPECTRAL_.-[\r\n]','')
      local issel = '' if tkid > 1 and data.takes[tkid].selected then  issel = ' SEL' end
      local head = 'TAKE'..issel..'\n'
      if tkid == 1 then head = '' end
      out_chunk = out_chunk..'\n\n'..head..tkchunksrc
      
      -- add spectral edits
      out_chunk = out_chunk..'SPECTRAL_CONFIG '..(data.takes[tkid].FFT_sz or 1024)..'\n'
      for SEid = 1, #data.takes[tkid].SE do
        out_chunk = out_chunk..'SPECTRAL_EDIT '
                ..data.takes[tkid].SE[SEid].pos*data.takes[tkid].rate + data.takes[tkid].s_offs..' '
                ..data.takes[tkid].SE[SEid].len*data.takes[tkid].rate..' '
                ..data.takes[tkid].SE[SEid].gain..' '
                ..data.takes[tkid].SE[SEid].fadeinout_horiz..' '
                ..data.takes[tkid].SE[SEid].fadeinout_vert..' '
                ..data.takes[tkid].SE[SEid].freq_low..' '
                ..data.takes[tkid].SE[SEid].freq_high..' '
                ..data.takes[tkid].SE[SEid].chan..' '
                ..data.takes[tkid].SE[SEid].bypass..' '
                ..data.takes[tkid].SE[SEid].gate_threshold..' '
                ..data.takes[tkid].SE[SEid].gate_floor..' '
                ..data.takes[tkid].SE[SEid].compress_threshold..' '
                ..data.takes[tkid].SE[SEid].compress_ratio..' '
                ..data.takes[tkid].SE[SEid].unknown1..' '
                ..data.takes[tkid].SE[SEid].unknown2..' '
                ..data.takes[tkid].SE[SEid].fadeinout_horiz2..' '
                ..data.takes[tkid].SE[SEid].fadeinout_vert2..' '
                ..'\n'
                
                
        local dropnextline = 8        
        if data.takes[tkid].SE[SEid].freedrawT and #data.takes[tkid].SE[SEid].freedrawT > 2 then 
          local freedrawTstr = 'SPECTRAL_EDIT_T '
          for freedrawT_ID = 2, #data.takes[tkid].SE[SEid].freedrawT, 2 do
            if freedrawT_ID%dropnextline==0 then
              freedrawTstr = freedrawTstr:sub(0,-3)
              freedrawTstr = freedrawTstr..'\nSPECTRAL_EDIT_T '
            end
            freedrawTstr = freedrawTstr
              ..data.takes[tkid].SE[SEid].freedrawT[freedrawT_ID-1].ptpos..' '..data.takes[tkid].SE[SEid].freedrawT[freedrawT_ID-1].ptval..' + '
              ..data.takes[tkid].SE[SEid].freedrawT[freedrawT_ID].ptpos..' '..data.takes[tkid].SE[SEid].freedrawT[freedrawT_ID].ptval..' + '
          end
          freedrawTstr = freedrawTstr:sub(0,-3)
          out_chunk = out_chunk..freedrawTstr..'\n'
        end
  
        if data.takes[tkid].SE[SEid].freedrawB and #data.takes[tkid].SE[SEid].freedrawB > 2 then 
          local freedrawBstr = 'SPECTRAL_EDIT_B '
          for freedrawB_ID = 2, #data.takes[tkid].SE[SEid].freedrawB, 2 do
            if freedrawB_ID%dropnextline==0 then
              freedrawBstr = freedrawBstr:sub(0,-3)
              freedrawBstr = freedrawBstr..'\nSPECTRAL_EDIT_B '
            end
            freedrawBstr = freedrawBstr
              ..data.takes[tkid].SE[SEid].freedrawB[freedrawB_ID-1].ptpos..' '..data.takes[tkid].SE[SEid].freedrawB[freedrawB_ID-1].ptval..' + '
              ..data.takes[tkid].SE[SEid].freedrawB[freedrawB_ID].ptpos..' '..data.takes[tkid].SE[SEid].freedrawB[freedrawB_ID].ptval..' + '
          end
          freedrawBstr = freedrawBstr:sub(0,-3)
          out_chunk = out_chunk..freedrawBstr..'\n'
        end
        
        
        
      end
      
    end
    out_chunk = out_chunk..'\n>'
    
    
  
    --ClearConsole()
    --msg(out_chunk)
    SetItemStateChunk( item, out_chunk, false )
    UpdateItemInProject( item )
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.12) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end