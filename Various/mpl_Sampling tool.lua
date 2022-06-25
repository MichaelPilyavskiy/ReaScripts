-- @description Sampling tool
-- @version 1.01
-- @author MPL
-- @about Sample instrument to a rs5k sampler
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Due to REAPER crashes while adding a lot rs5k instances at short time, added schedule mode
--    + AddRs5k/Shedule mode: add option to change schedule pause
--    + AddRs5k: add option to hide new instances
--    + AddRs5k/Rename: add option to rename new instances
--    + AddRs5k/Rename: allow wildcards
--    + AddRs5k/Rename: add #note wildcard
--    # do not allow to set notes boundary negative crossing each other
--    # fix non - integer internal values for menu readout fields

    
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  
  local DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 1.01
    DATA.extstate.extstatesection = 'SamplingTool'
    DATA.extstate.mb_title = 'MPL Sampling tool'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  400,
                          wind_h =  600,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          -- genarate midi
                          CONF_notelen_beats = 4,
                          CONF_notetail_beats = 8,
                          CONF_notestart = 60,
                          CONF_noteend = 72,
                          CONF_itempos_beats = 0,
                          
                          CONF_schedmode = 1,
                          CONF_schedmode_s = 1, 
                          CONF_showflag = 2,
                          CONF_rename = 0,
                          CONF_rename_wildcard = 'RS5k #note',
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          
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
      DATA.GUI.custom_mainbutw = (gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*3) --(gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*3
      DATA.GUI.custom_mainbutw2 = 0.5*(gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*3) --(gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*3
      DATA.GUI.custom_scrollw = 10
      DATA.GUI.custom_frameascroll = 0.05
      DATA.GUI.custom_default_framea_normal = 0.1
      DATA.GUI.custom_spectralw = DATA.GUI.custom_mainbutw*3 + DATA.GUI.custom_offset*2
      DATA.GUI.custom_datah = (gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset*3) 
    
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    
    -- buttons
      DATA.GUI.buttons = {} 
      DATA.GUI.buttons.app = {  x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset+(DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*0,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = '1. Generate MIDI',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              Undo_BeginBlock()
                                              DATA2:Process_GenerateMIDI()
                                              Undo_EndBlock( DATA.extstate.mb_title..' - generate MIDI', 4 )
                                            end} 
      DATA.GUI.buttons.app2 = {  x=DATA.GUI.custom_offset,--*2 + DATA.GUI.custom_mainbutw,
                            y=DATA.GUI.custom_offset+(DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*1,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = '2. Apply FX to take',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              local applyfxtail = VF_spk77_getinivalue( get_ini_file(), 'REAPER', 'applyfxtail')
                                              if applyfxtail ~= 0 then
                                                MB('Preferences/Media/Tail length when using Apply FX is not zero',DATA.extstate.mb_title,0 )
                                                return
                                              end
                                              Action(40209)--Item: Apply track/take FX to items 
                                            end}                                            
      DATA.GUI.buttons.app3 = {  x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset+(DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*2,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = '3. Split audio',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              Undo_BeginBlock()
                                              DATA2:Process_Split()
                                              Undo_EndBlock( DATA.extstate.mb_title..' - split', 4 )
                                            end}                                             
      DATA.GUI.buttons.app4 = {  x=DATA.GUI.custom_offset,--*2 + DATA.GUI.custom_mainbutw,
                            y=DATA.GUI.custom_offset+(DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*3,
                            w=DATA.GUI.custom_mainbutw2-DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_mainbuth,
                            txt = '4. Perform sampling',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              Undo_BeginBlock()
                                              DATA2:Process_PerformSampling()
                                              Undo_EndBlock( DATA.extstate.mb_title..' - sample FX', 4 )
                                            end}    
      DATA.GUI.buttons.app4s = {  x=DATA.GUI.custom_offset+DATA.GUI.custom_mainbutw2,
                            y=DATA.GUI.custom_offset+(DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*3,
                            w=DATA.GUI.custom_mainbutw2,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Stop sampling',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              DATA.perform_quere_sheduled  = nil
                                            end}                                             
                                                                                     
      DATA.GUI.buttons.preset = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset+(DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*4,
                            w=DATA.GUI.custom_mainbutw,--*2+DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_short = (DATA.extstate.CONF_NAME or '[untitled]'),
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA:GUIbut_preset() end}                  
      DATA.GUI.buttons.Rsettings = { x=gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx,
                            y=(DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*5,
                            w=DATA.GUI.custom_mainsepx,
                            h=gfx.h/DATA.GUI.default_scale-(DATA.GUI.custom_mainbuth + DATA.GUI.custom_offset)*5,
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
  ----------------------------------------------------------------------
  function DATA2:Process_GenerateMIDI()
      
    -- preset
      local notecnt_start = DATA.extstate.CONF_notestart
      local notecnt_end = DATA.extstate.CONF_noteend
      local notecnt = notecnt_end-notecnt_start
      local noteoff_compensation = 0.01 -- seconds cut 
      local len = DATA.extstate.CONF_notelen_beats
      local tail = DATA.extstate.CONF_notetail_beats
    
    -- form edges
      local item_pos_beats = DATA.extstate.CONF_itempos_beats
      local item_len_beats = (len+tail)*(notecnt+1)
      local item_pos_sec = TimeMap2_beatsToTime( 0, item_pos_beats, 0 )
      local item_len_sec = TimeMap2_beatsToTime( 0, item_len_beats, 0 )
      
    -- init
      local track = GetSelectedTrack(0,0)
      if not track then return end
      local it = reaper.CreateNewMIDIItemInProj( track, item_pos_sec, item_pos_sec+item_len_sec, false )
      if not it then return end
      local take = GetActiveTake(it)    
    
    -- add notes
      for pitch = notecnt_start, notecnt_end do
        local chan = 0
        local vel = 120
        local init_pos_beats = (len+tail)*(pitch-notecnt_start)
        local pos_sec = TimeMap2_beatsToTime( 0, init_pos_beats, 0 )
        local pos2_sec = TimeMap2_beatsToTime( 0, init_pos_beats+len, 0 )
        local startppqpos =   MIDI_GetPPQPosFromProjTime( take, pos_sec )
        local endppqpos = MIDI_GetPPQPosFromProjTime( take, pos2_sec-noteoff_compensation )
        reaper.MIDI_InsertNote( take, false, false, startppqpos, endppqpos, chan, pitch, vel, true )
      end
      reaper.MIDI_Sort( take ) 
    
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_Split() 
    local item = GetSelectedMediaItem(0,0)
    if not item then 
      MB('Item is not selected',DATA.extstate.mb_title,0 )
      return 
    end
    
    local notecnt_start = DATA.extstate.CONF_notestart
    local notecnt_end = DATA.extstate.CONF_noteend
    local notecnt = notecnt_end-notecnt_start
    local noteoff_compensation = 0.01 -- seconds cut
    local len = DATA.extstate.CONF_notelen_beats
    local tail = DATA.extstate.CONF_notetail_beats
    
    local right_item = item
    for pitch = notecnt_start+1, notecnt_end do
      local init_pos_beats = (len+tail)*(pitch-notecnt_start)
      local pos_sec = TimeMap2_beatsToTime( 0, init_pos_beats, 0 )
      right_item = SplitMediaItem( right_item, pos_sec )
    end
    UpdateArrange()
  end
  ----------------------------------------------------------------------
  function DATA2:Process_PerformSampling()
    local item = GetSelectedMediaItem(0,0)
    if not item then 
      MB('Item is not selected',DATA.extstate.mb_title,0 )
      return 
    end
    
    local take = GetActiveTake(item)
    local source =  GetMediaItemTake_Source( take )
    local filename = GetMediaSourceFileName( source )
    
    local par_track = GetMediaItemTrack( item )
    local ID = reaper.GetMediaTrackInfo_Value( par_track, 'IP_TRACKNUMBER' )
    -- add sampling track
      reaper.InsertTrackAtIndex( ID, false )
      local tr =  reaper.GetTrack( 0, ID )
      GetSetMediaTrackInfo_String( tr, 'P_NAME' , 'Sampler track', 1 )
      if not tr then return end
      
   -- add rs5k
    local notecnt_start = DATA.extstate.CONF_notestart
    local notecnt_end = DATA.extstate.CONF_noteend
    local notecnt = notecnt_end-notecnt_start + 1
    
    if DATA.extstate.CONF_schedmode==1 then DATA.perform_quere_sheduled = {} end
    for pitch = notecnt_start, notecnt_end do
      local function add_rs5k()
        local fx = reaper.TrackFX_AddByName( tr, 'ReaSamplOmatic5000 (Cockos)', false, -1 )
        TrackFX_SetNamedConfigParm( tr, fx, 'FILE0', filename )
        TrackFX_SetParamNormalized( tr, fx, 21, 1 )-- filter played notes
        local rs5k_note_norm = pitch/127
        local rs5k_offset = (pitch-notecnt_start)/notecnt
        TrackFX_SetParamNormalized( tr, fx, 3, rs5k_note_norm )-- start range
        TrackFX_SetParamNormalized( tr, fx, 4, rs5k_note_norm )-- end range
        TrackFX_SetParamNormalized( tr, fx, 5, rs5k_note_norm )-- start note
        TrackFX_SetParamNormalized( tr, fx, 6, rs5k_note_norm )-- end note
        
        TrackFX_SetParamNormalized( tr, fx, 13, rs5k_offset )-- offset start
        TrackFX_SetParamNormalized( tr, fx, 14, rs5k_offset + 1/notecnt)-- offset end]]
        
        if DATA.extstate.CONF_showflag ~= -1 then TrackFX_Show( tr, fx, DATA.extstate.CONF_showflag )  else
          TrackFX_Show( tr, fx, 1 )
          TrackFX_Show( tr, fx, 2 )
        end
        
        if DATA.extstate.CONF_rename == 1 then
          local new_name = DATA.extstate.CONF_rename_wildcard
          new_name = new_name:gsub('#note', pitch)
          SetFXName(tr, fx, new_name)
        end
        
      end
      if DATA.extstate.CONF_schedmode==1 then table.insert(DATA.perform_quere_sheduled,add_rs5k) else add_rs5k() end
    end
    
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE(DATA)
    if not DATA.perform_quere_sheduledTS then DATA.perform_quere_sheduledTS = 0 end
    if not DATA.perform_quere_sheduled or (DATA.perform_quere_sheduled and #DATA.perform_quere_sheduled==0) then return end
    local f= DATA.perform_quere_sheduled[1]
    if f and os.clock()-DATA.perform_quere_sheduledTS > DATA.extstate.CONF_schedmode_s then
      f()
      table.remove(DATA.perform_quere_sheduled,1)
      DATA.perform_quere_sheduledTS = os.clock()
    end
  end
  ----------------------------------------------------------------------
  function DATA2:ProcessAtChange(DATA)
  
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 200
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset

    local  t = 
    { 
      {str = 'Generate MIDI item' ,        group = 1, itype = 'sep'},  
        {str = 'Note length, beats' ,                           group = 1, itype = 'readout', confkey = 'CONF_notelen_beats', level = 1, 
        val_res = 0.05, 
        val_min = 1, 
        val_max = 64, 
        val_isinteger = true,
        val_format = function(x) return math.floor(x) end, 
        val_format_rev = function(x) if not tonumber(x) then return end return math.floor(x) end, 
        },
        {str = 'Note tail, beats' ,                           group = 1, itype = 'readout', confkey = 'CONF_notetail_beats', level = 1, 
        val_res = 0.05, 
        val_min = 1, 
        val_max = 64, 
        val_isinteger = true,
        val_format = function(x) return math.floor(x) end, 
        val_format_rev = function(x) if not tonumber(x) then return end return math.floor(x) end, 
        },
        {str = 'Note start' ,                           group = 1, itype = 'readout', confkey = 'CONF_notestart', level = 1, 
        val_res = 0.05, 
        val_min = 0, 
        val_max = DATA.extstate.CONF_noteend, 
        val_isinteger = true,
        val_format = function(x) return math.floor(x) end, 
        val_format_rev = function(x) if not tonumber(x) then return end return math.floor(x) end, 
        },        
        {str = 'Note end' ,                           group = 1, itype = 'readout', confkey = 'CONF_noteend', level = 1, 
        val_res = 0.05, 
        val_min = DATA.extstate.CONF_notestart, 
        val_max = 127, 
        val_isinteger = true,
        val_format = function(x) return math.floor(x) end, 
        val_format_rev = function(x) if not tonumber(x) then return end return math.floor(x) end, 
        },  
      
      {str = 'Adding RS5k instances' ,                group = 2, itype = 'sep'},    
        {str = 'Schedule mode',                      group = 2, itype = 'check', confkey = 'CONF_schedmode', level = 1}, 
        {str = 'Pause between adding new instances' , group = 2, itype = 'readout', confkey = 'CONF_schedmode_s', level = 1,
        val_res = 0.05, 
        val_min = 0.5, 
        val_max = 3, 
        val_format = function(x) return math.floor(x*100)/100 end, 
        val_format_rev = function(x) if not tonumber(x) then return end return math.floor(x) end, 
        hide =  DATA.extstate.CONF_schedmode ~= 1
        }, 
        {str = 'Show FX' ,                         group = 2, itype = 'readout', level = 1,  confkey = 'CONF_showflag', menu = {[-1]='Show chain, hide floating', [1]='Show FX chain', [2]='Hide floating window', [3]='Show floating window'},readoutw_extw=readoutw_extw},
        {str = 'Rename',                           group = 2, itype = 'check', confkey = 'CONF_rename', level = 1}, 
          {str = 'Wildcards' ,                     group = 2, itype = 'readout', level = 2,  confkey = 'CONF_rename_wildcard',val_isstring=true,readoutw_extw=readoutw_extw,hide =  DATA.extstate.CONF_rename ~= 1},
          {str = 'Clear' ,                         group = 2, itype = 'button', level = 3, func_onrelease = function() DATA.extstate.CONF_rename_wildcard = 'RS5k' DATA.UPD.onconfchange = true DATA.UPD.onGUIinit = true end,hide =  DATA.extstate.CONF_rename ~= 1},
          {str = '#note' ,                         group = 2, itype = 'button', level = 3, func_onrelease = function() DATA.extstate.CONF_rename_wildcard = DATA.extstate.CONF_rename_wildcard..' #note' DATA.UPD.onconfchange = true DATA.UPD.onGUIinit = true end,hide =  DATA.extstate.CONF_rename ~= 1},
        
        
    } 
    return t
    
  end        
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
          hide=DATA.extstate.CONF_FFTsz==-1 or  DATA.extstate.CONF_mode==2
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
          --[[{str = 'Minimum value difference' ,     group = 6, itype = 'readout', confkey = 'CONF_reducesamevalues_mindiff', 
            val_format = function(x) return (math.floor(x*1000)/1000)..'dB' end, 
            val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end,
            level = 2, val_res = 0.05, val_min = 0, val_max = 5, func_onrelease = function() DATA2:ProcessAtChange(DATA) end,hide=DATA.extstate.CONF_reducesamevalues~=1}, 
        {str = 'Reset boundary edges',          group = 6, itype = 'check', confkey = 'CONF_zeroboundary', level = 1, func_onrelease = function()DATA2:ProcessAtChange(DATA)  end},
      {str = 'UI options' ,                     group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,             group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse' ,             group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        --{str = 'Show tootips' ,               group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        {str = 'Process on settings change',    group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
        {str = 'Process on initialization',     group = 5, itype = 'check', confkey = 'UI_processoninit', level = 1},]]

  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.21) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end