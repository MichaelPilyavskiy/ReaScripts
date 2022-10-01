-- @description RS5k manager
-- @version 3.0alpha3
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic5000 data on group of connected tracks
-- @provides
--    mpl_RS5k manager_MacroControls.jsfx
-- @changelog
--    # Macro: fix release macro error

--[[ 
3.0alpha2
--    # Do not update GUI if currently dragging any control in the script UI
--    + DrumRack: clear/refresh rack at child delete
--    + DrumRack: on drop show device chain and sample of recent dropped sample
--    + DrumRack: support multiple samples drop incrementally at pads
--    + DrumRack: rightclick on pad name open pad menu
--    + DrumRack/Menu: add action for export selected items
--    + DrumRack/Menu: add action for export selected items
--    + DrumRack/Menu: link to device name menu
--    + DrumRack: click on pad open RS5k window
--    # DrumRack: more carefully validate MIDI bus pointer
--    + Macro: add Macro section with 16 knobs
--    + Macro: add Macro JSFX to a script package
--    + Macro: instantiate Macro JSFX when clicking macro section for the first time (JSFX is packed with RS5k manager)
--    + Macro: hide Macro JSFX when instantiate
--    + Sampler: add show button to float active RS5k instance
--    + Sampler: add start/end offset control, show it visually on waveform
--    + Sampler: fix hdpi scaling
--    + Sampler: click on controls reset them fo default (defaults initiated from hardcoded values but can be changed in the future)
--    + Defaults: when creating new drum rack hide macro section for the first time
--    # Add MIDI bus after parant track
--    # Add MIDI bus with small foldercompact state
--    # Add child always after MIDI bus
--    # Add child with small foldercompact state
--    # Validate childrens by their external state rather than depth
--    # Reset MIDI bus on track change
--    # prepare external chunk for further reading multiple parameters
--    - pattern editing stuff removed for now

3.0alpha1
--    + GUI: use MPL library
--    + Replace all 3rd party APIs by native solutions
--    + ParentTrack: catch parent track even if child selected (write data to extstate per track)
--    + PadView: basic Ableton DrumRack port
--    + PadView: store/load with track
--    + PadView: show played notes
--    + PadView: show active notes
--    + DrumRack: basic Ableton DrumRack port
--    + DrumRack: mute pads (layer bus if multilayer mode)
--    + DrumRack: solo pads (layer bus if multilayer mode)
--    + DrumRack: preview pads
--    + DrumRack: show first layer sample in MediaExplorer
--    + DrumRack: add MIDI bus to folder
--    + DrumRack: on drop sample replace by default 1st layer 
--    + DrumRack: on drop sample add new child if need 
--    + DrumRack: on drop sample convert channel to multisampler mode if drop at 2+layer
--    + Device: show child track sampler parameters, multiple samples if in multilayer mode
--    + Device: show volume/pan/enabled from parent track controls
--    + Sampler: show waveform
--    + Sampler: show loop-oneshot buttons
--    + Sampler: add gain control
--    + Sampler: add ADSR control
--    + Setting: separate settings from main window
]]


 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  -- config defaults
  DATA2 = { notes={}, 
            }
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '3.0alpha3'
    DATA.extstate.extstatesection = 'MPL_RS5K manager'
    DATA.extstate.mb_title = 'RS5K manager'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  500,
                          wind_h =  500,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          -- rs5k
                          CONF_floatonadding = 0,
                          
                          -- midi bus
                          CONF_midiinput = 63, -- 63 all 62 midi kb
                          
                          
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
    DATA2:TrackDataRead(track)
    DATA:GUIinit()
    
    RUN()
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataWrite()
    if DATA2.tr_valid == false or not DATA2.tr_extparams_note_active then return end 
    local extstr = 
      'tr_extparams_activepad '..DATA2.tr_extparams_activepad..'\n'..
      'tr_extparams_note_active '..DATA2.tr_extparams_note_active..'\n'..
      'tr_extparams_showstates '..DATA2.tr_extparams_showstates..'\n'..
      'tr_extparams_macrocnt '..DATA2.tr_extparams_macrocnt..'\n'..
      'vrs '..DATA.extstate.version
      
    GetSetMediaTrackInfo_String( DATA2.tr_ptr, 'P_EXT:MPLRS5KMAN', extstr, true) 
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_ParseExt(track)
    if not track then return end
    local retval, chunk = reaper.GetSetMediaTrackInfo_String(track, 'P_EXT:MPLRS5KMAN', '', false )
    if not retval or chunk == '' then return end
    
    for line in chunk:gmatch('[^\r\n]+') do
      local key,value = line:match('([%p%a%d]+)%s([%p%a%d]+)')
      if key and value then 
        DATA2[key] = tonumber(value) or value
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:GetFirstRS5k(track)
    for fxid = 1,  TrackFX_GetCount( track ) do
      if DATA2:ValidateRS5k(track, fxid-1) then return fxid-1 end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:ValidateRS5k(track, rs5k_pos)
    local retval, buf = reaper.TrackFX_GetParamName( track, rs5k_pos, 2 )
    if buf == 'Gain for minimum velocity' then return true end
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_GetTrackParams(track)
    -- handle parent track parameters
    for note in pairs(DATA2.notes) do
      if DATA2.notes[note].partrack_ptr and ValidatePtr2(0,DATA2.notes[note].partrack_ptr, 'MediaTrack*')then
        DATA2.notes[note].partrack_mute = GetMediaTrackInfo_Value( DATA2.notes[note].partrack_ptr, 'B_MUTE' )
        DATA2.notes[note].partrack_solo = GetMediaTrackInfo_Value( DATA2.notes[note].partrack_ptr, 'I_SOLO' )
      end
    end
  end
  ---------------------------------------------------------------------   
  function DATA2:TrackDataRead_GetChildrens_GetRS5kParams(track, fxid, note,layer)
    local notest = TrackFX_GetParamNormalized( track, fxid, 3 ) -- note range start
    local vol = TrackFX_GetParamNormalized( track, fxid, 0 ) 
    local pan = TrackFX_GetParamNormalized( track, fxid, 1 ) 
    local attack = TrackFX_GetParamNormalized( track, fxid, 9 ) 
    local decay = TrackFX_GetParamNormalized( track, fxid, 24 ) 
    local sustain = TrackFX_GetParamNormalized( track, fxid, 25 ) 
    local release = TrackFX_GetParamNormalized( track, fxid, 10 ) 
    local loop = TrackFX_GetParamNormalized( track, fxid, 12 ) 
    local samplestoffs = TrackFX_GetParamNormalized( track, fxid, 13 ) 
    local sampleendoffs = TrackFX_GetParamNormalized( track, fxid, 14 ) 
    
    local ret, vol_format = TrackFX_GetFormattedParamValue( track, fxid, 0 ) 
    local ret, pan_format = TrackFX_GetFormattedParamValue( track, fxid, 1 ) 
    local ret, attack_format = TrackFX_GetFormattedParamValue( track, fxid, 9 ) 
    local ret, decay_format = TrackFX_GetFormattedParamValue( track, fxid, 24 ) 
    local ret, sustain_format = TrackFX_GetFormattedParamValue( track, fxid, 25 ) 
    local ret, release_format = TrackFX_GetFormattedParamValue( track, fxid, 10 ) 
    local samplestoffs_format = math.floor(samplestoffs*1000)/10
    local sampleendoffs_format = math.floor(sampleendoffs*1000)/10
    
    local ret, filepath = TrackFX_GetNamedConfigParm(  track, fxid, 'FILE0') 
    local enabled = TrackFX_GetEnabled( track, fxid )
    
    local note = math.floor(128*notest)
    local filepath_short = GetShortSmplName(filepath)
    if filepath_short and filepath_short:match('(.*)%.[%a]+') then filepath_short = filepath_short:match('(.*)%.[%a]+') end
    if not DATA2.notes[note] then DATA2.notes[note] = {layers = {}} end
    local dev_vol = GetMediaTrackInfo_Value( track, 'D_VOL' )
    local dev_vol_format = WDL_VAL2DB(dev_vol,2)          
    local dev_pan = GetMediaTrackInfo_Value( track, 'D_PAN' )
    local sampledata = { filepath = filepath,
                         filepath_short = filepath_short,
                         name = filepath_short,
                         trackptr = track,
                         rs5k_pos = fxid,
                         dev_vol = dev_vol,
                         dev_pan = dev_pan,
                         dev_vol_format = dev_vol_format..'dB',
                         
                         params_vol = vol,
                         params_pan = pan,
                         params_vol_format = vol_format..'dB',
                         params_pan_format = pan_format,
                         params_loop = loop,
                         params_attack=attack,
                         params_decay=decay,
                         params_sustain=sustain,
                         params_release=release,
                         params_samplestoffs = samplestoffs,
                         params_sampleendoffs = sampleendoffs,
                         
                         params_attack_format  =attack_format..'ms',
                         params_decay_format  =decay_format..'ms',
                         params_sustain_format  =sustain_format..'dB',
                         params_release_format  =release_format..'ms',
                         params_samplestoffs_format =  samplestoffs_format..'%',
                         params_sampleendoffs_format =  sampleendoffs_format..'%',
                         
                         enabled = enabled
                        }
    if not DATA2.notes[note] then DATA2.notes[note] = {} end
    if not DATA2.notes[note].layers then DATA2.notes[note].layers = {} end
    if not DATA2.notes[note].layers[layer] then DATA2.notes[note].layers[layer] = {} end
    DATA2.notes[note].layers[layer]=sampledata
    return note,filepath_short
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_pertrack(track,curdepth,depth)
    for fxid = 1,  TrackFX_GetCount( track ) do
      if DATA2:ValidateRS5k(track, fxid-1) then 
        
        if (curdepth==1 and depth ==0) or (curdepth==0 and depth ==-1) then  -- regular child
          local note,filepath_short = DATA2:TrackDataRead_GetChildrens_GetRS5kParams(track, fxid-1, note, 1)
          if not DATA2.notes[note].partrack_ptr then 
            DATA2.notes[note].partrack_ptr = track 
            DATA2.notes[note].partrack_ID =   CSurf_TrackToID( track, false) 
            DATA2.notes[note].partrack_curdepth =   curdepth
          end
          if not DATA2.notes[note].name then DATA2.notes[note].name = filepath_short end
         elseif curdepth >= 1 and depth <=0 then
          if DATA2.notes[note] and DATA2.notes[note].layers then 
            local note,filepath_short = DATA2:TrackDataRead_GetChildrens_GetRS5kParams(track, fxid-1, note, #DATA2.notes[note].layers+1)
            DATA2.notes[note].is_device = true
            DATA2.notes[note].partrack_ptr = partrack
            DATA2.notes[note].name = partrack_name
            DATA2.notes[note].partrack_ID =   CSurf_TrackToID( partrack, false) 
          end
        end
        
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_MacroJSFX_Validate(instantiate) 
    DATA2.Macro = {isvalid = false,sliders = {}}
    if not (DATA2.tr_ID and DATA2.tr_ptr) then return end
    local fxname = 'mpl_RS5k manager_MacroControls.jsfx'
    local macroJSFX_fxID =  TrackFX_AddByName( DATA2.tr_ptr, fxname, false, instantiate or 0 ) 
    if instantiate and instantiate == 1 then 
      if macroJSFX_fxID ~= -1 then
        TrackFX_Show( DATA2.tr_ptr, macroJSFX_fxID, 0|2 ) 
       else
        MB('RS5k manager_MacroControls JSFX is missing. Make sure you installed it correctly via ReaPack.', '', 0)
        return
      end
    end
    
    DATA2.Macro.isvalid = true 
    DATA2.Macro.macroJSFX_fxID = macroJSFX_fxID
    DATA2.Macro.macroJSFX_fxGUID = reaper.TrackFX_GetFXGUID( DATA2.tr_ptr, macroJSFX_fxID )
                    
    for i = 1, 16 do
      local param_val = TrackFX_GetParamNormalized( DATA2.tr_ptr, macroJSFX_fxID, i-1 )
      DATA2.Macro.sliders[i] = {val = param_val}
    end
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataWrite_MarkParentFolder(tr) 
    SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERDEPTH',1 )
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_ValidateMIDIbus() 
    if (DATA2.MIDIbus and DATA2.MIDIbus.ptr and ValidatePtr2(0,DATA2.MIDIbus.ptr,'MediaTrack*')) then return end
    
    InsertTrackAtIndex( DATA2.tr_ID, false )
    local new_tr = CSurf_TrackFromID( DATA2.tr_ID+1,false)
    DATA2:TrackDataWrite_MarkChildAppendsToCurrentParent(new_tr)  
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', 'MIDI bus', 1 )
    SetMediaTrackInfo_Value( new_tr, 'I_RECMON', 1 )
    SetMediaTrackInfo_Value( new_tr, 'I_RECARM', 1 )
    local channel,physical_input = 0, DATA.CONF_midiinput
    SetMediaTrackInfo_Value( new_tr, 'I_RECINPUT', 4096 + channel + (physical_input<<5)) -- set input to all MIDI
    
    DATA2.MIDIbus = {ptr = new_tr,ID = CSurf_TrackToID( new_tr, false )}
    
    if DATA2.tr_children_count ==0 then  -- MIDI bus is added before first child added
      DATA2:TrackDataWrite_MarkParentFolder(tr) 
      DATA2.enclose_trPtr = DATA2.MIDIbus.ptr
      DATA2.enclose_trID = CSurf_TrackToID(DATA2.MIDIbus.ptr,false) 
      SetMediaTrackInfo_Value( DATA2.MIDIbus.ptr, 'I_FOLDERDEPTH',-1 ) -- enclose folder
    end
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_IsChildAppendsToCurrentParent(track)   
    local ext_t = {}
    local ret, ext = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD', '', false)
    if ext ~= '' then
      for line in ext:gmatch('[^\r\n]+') do
        local key,val = line:match('([%a%p]+) (.*)')
        if key and val then 
          ext_t[key]=tonumber(val) or val
        end
      end
    end
    
    local ret = nil
    if DATA2.tr_GUID and ext_t.par_tr_GUID == DATA2.tr_GUID then ret = true end
    
    return ret, ext_t
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataWrite_MarkChildAppendsToCurrentParent(tr)   
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD', 'par_tr_GUID '..DATA2.tr_GUID, true)
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens()
  
    local curdepth = 1
    local children_count = 0
    local partrack, partrack_name
    for i = DATA2.tr_ID+1, CountTracks(0) do
      local track = GetTrack(0,i-1)
      
      -- validate childen
      if DATA2:TrackDataRead_IsChildAppendsToCurrentParent(track) == true  then
        local isMIDIbus = false
        
        -- read depth
          local depth = GetMediaTrackInfo_Value( track, 'I_FOLDERDEPTH' )
          curdepth = curdepth + depth
        
        -- validate midi tr by name
          local ret, trname = GetSetMediaTrackInfo_String( track, 'P_NAME', '', false )
          if trname == 'MIDI bus' then 
            isMIDIbus = true
            DATA2.MIDIbus = {ptr = track, ID = CSurf_TrackToID( track, false )}  
          end
          
        -- 
          if not isMIDIbus then 
            DATA2:TrackDataRead_GetChildrens_pertrack(track,curdepth,depth)
          end
          
          DATA2.enclose_trID = CSurf_TrackToID(track,false) 
          DATA2.enclose_trPtr = track 
          children_count = children_count + 1
              
       else
        break
      end
    end
    DATA2.tr_children_count = children_count
    DATA2:TrackDataRead_GetChildrens_GetTrackParams(track)
  end
  --------------------------------------------------------------------- 
  function DATA2:TrackDataRead_MacroJSFX_ReadExtLinks() 
    if not DATA2.Macro.isvalid then return end
    
  end
  --------------------------------------------------------------------- 
  function DATA2:TrackDataRead_GetParent(track)
    local retval, trname = reaper.GetTrackName( track )
    local GUID = reaper.GetTrackGUID( track) 
    DATA2.tr_valid = true
    DATA2.tr_ptr = track 
    DATA2.tr_name =  trname
    DATA2.tr_GUID =  GetTrackGUID( track )
    DATA2.tr_ID = CSurf_TrackToID( track, false) 
    DATA2.enclose_trID = DATA2.tr_ID
    DATA2.tr_children_count = 0
     
    DATA2.tr_extparams_activepad = 3
    DATA2.tr_extparams_macrocnt = 16
    DATA2.tr_extparams_showstates=1|2|4|8--|16 -- 1=drumrack   2=device  4=sampler 8=padview 16=macro
    DATA2.tr_extparams_note_active = -1
    
    DATA2:TrackDataRead_MacroJSFX_Validate(0) 
    DATA2:TrackDataRead_MacroJSFX_ReadExtLinks() 
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead(track0)
    DATA2.tr_valid = false
    DATA2.tr_name = nil
    DATA2.notes = {} -- clear
    DATA2.MIDIbus = nil
    local parenttrack = track0
    if not parenttrack then parenttrack = GetSelectedTrack(0,0) end
    
    -- catch parent by childen
    if parenttrack then 
      local ret, ext = DATA2:TrackDataRead_IsChildAppendsToCurrentParent(parenttrack)   
      if ext.par_tr_GUID then parenttrack = VF_GetTrackByGUID(ext.par_tr_GUID) end 
    end
    
    if parenttrack then
      DATA2:TrackDataRead_GetParent(parenttrack) 
      DATA2:TrackDataRead_GetChildrens(parenttrack)
    end
    DATA2:TrackDataRead_ParseExt(parenttrack)
  end
  ---------------------------------------------------------------------  
  function DATA_RESERVED_ONPROJCHANGE(DATA)
  
    DATA2.tr_valid = false
    local tr_ptr_last = DATA2.tr_ptr_last
    if DATA.GUI.buttons.info then DATA.GUI.buttons.info.txt = '[no data]' end
    local track = GetSelectedTrack(0,0)
    DATA2:TrackDataRead(track) 
    
    -- visual refresh
      --GUI_RESERVED_init(DATA)
      for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
      
      if DATA2.ONPARAMDRAG ~= true then 
        GUI_RESERVED_init_settingbut(DATA)  
        GUI_MODULE_PADOVERVIEW(DATA)
        GUI_MODULE_DRUMRACKPAD(DATA)
        GUI_MODULE_DEVICE(DATA)  
        GUI_MODULE_MACRO(DATA)    
        --if not tr_ptr_last or (tr_ptr_last and tr_ptr_last ~= DATA2.tr_ptr) then  -- minor refresh only if parent is changed
          GUI_MODULE_SAMPLER(DATA) 
        --end 
        GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
      end
    
    if not DATA.GUI.layers_refresh  then DATA.GUI.layers_refresh = {} end
    DATA.GUI.layers_refresh[2]=true 
    
    DATA2.tr_ptr_last = DATA2.tr_ptr 
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init_settingbut(DATA) 
    local txt_a_unabled = 0.25
    local txt_a 
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&16==0 then txt_a = txt_a_unabled end
    DATA.GUI.buttons.showhide_macroglob = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_settingsbut_h*0 ,
                          w=DATA.GUI.custom_settingsbut_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_settingsbut_h-1,
                          txt = 'Macro',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_settingsbut_txtsz,
                          frame_a = 1,
                          frame_col = '#333333',
                          onmouseclick = function()
                            if DATA2.tr_extparams_showstates then 
                              DATA2.tr_extparams_showstates = DATA2.tr_extparams_showstates ~ 16
                              if DATA2.tr_extparams_showstates&16==16 then DATA2:TrackDataRead_MacroJSFX_Validate(1) end
                              DATA2:TrackDataWrite()
                              DATA.UPD.onGUIinit = true
                            end
                          end,
                          } 
    local txt_a
    local txt_a_unabled = 0.25
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&8==0 then txt_a = txt_a_unabled end
    DATA.GUI.buttons.showhide_pad = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_settingsbut_h*1 ,
                          w=DATA.GUI.custom_settingsbut_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_settingsbut_h-1,
                          txt = 'Pad overview',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_settingsbut_txtsz,
                          frame_a = 1,
                          frame_col = '#333333',
                          onmouseclick = function()
                            if DATA2.tr_extparams_showstates then 
                              DATA2.tr_extparams_showstates = DATA2.tr_extparams_showstates ~ 8
                              DATA2:TrackDataWrite()
                              DATA.UPD.onGUIinit = true
                            end
                          end,
                          }                          
    local txt_a 
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&1==0 then txt_a = txt_a_unabled end
    DATA.GUI.buttons.showhide_drrack = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_settingsbut_h*2 ,
                          w=DATA.GUI.custom_settingsbut_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_settingsbut_h-1,
                          txt = 'Drum Rack',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_settingsbut_txtsz,
                          frame_a = 1,
                          frame_col = '#333333',
                          onmouseclick = function()
                            if DATA2.tr_extparams_showstates then 
                              DATA2.tr_extparams_showstates = DATA2.tr_extparams_showstates ~ 1
                              DATA2:TrackDataWrite()
                              DATA.UPD.onGUIinit = true
                            end
                          end,
                          }
    local txt_a
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&2==0 then txt_a = txt_a_unabled end 
    DATA.GUI.buttons.showhide_device = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_settingsbut_h*3 ,
                          w=DATA.GUI.custom_settingsbut_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_settingsbut_h-1,
                          txt = 'Device',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_settingsbut_txtsz,
                          frame_a = 1,
                          frame_col = '#333333',
                          onmouseclick = function()
                            if DATA2.tr_extparams_showstates then 
                              DATA2.tr_extparams_showstates = DATA2.tr_extparams_showstates ~ 2
                              DATA2:TrackDataWrite()
                              DATA.UPD.onGUIinit = true
                            end
                          end
                          }      
    local txt_a
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&4==0 then txt_a = txt_a_unabled end 
    DATA.GUI.buttons.showhide_sampler = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_settingsbut_h*4 ,
                          w=DATA.GUI.custom_settingsbut_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_settingsbut_h,
                          txt = 'Sampler',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_settingsbut_txtsz,
                          frame_a = 1,
                          frame_col = '#333333',
                          onmouseclick = function()
                            if DATA2.tr_extparams_showstates then 
                              DATA2.tr_extparams_showstates = DATA2.tr_extparams_showstates ~ 4
                              DATA2:TrackDataWrite()
                              DATA.UPD.onGUIinit = true
                            end
                          end
                          }                          
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    -- init h
      local gfx_h = gfx.h/DATA.GUI.default_scale--math.max(250,gfx.h/DATA.GUI.default_scale)
      local gfx_w = gfx.w/DATA.GUI.default_scale--math.max(250,gfx.h/DATA.GUI.default_scale)
    --DATA.GUI.default_scale = 2
    -- init main stuff
      DATA.GUI.custom_mainbuth = 30*DATA.GUI.default_scale
      DATA.GUI.custom_texthdef = 23
      DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
      DATA.GUI.custom_mainsepx = gfx_w--(gfx.w/DATA.GUI.default_scale)*0.4-- *DATA.GUI.default_scale--400*DATA.GUI.default_scale--
      DATA.GUI.custom_mainbutw = gfx_w-DATA.GUI.custom_offset*2 --(gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*3
      DATA.GUI.custom_scrollw = 10
      DATA.GUI.custom_frameascroll = 0.05
      DATA.GUI.custom_default_framea_normal = 0.1
      DATA.GUI.custom_spectralw = DATA.GUI.custom_mainbutw*3 + DATA.GUI.custom_offset*2
      DATA.GUI.custom_datah = (gfx_h-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset*3) 
      DATA.GUI.custom_offset2 =  3 * DATA.GUI.default_scale
      DATA.GUI.custom_backcol2 = '#f3f6f4' -- grey back 
      DATA.GUI.custom_backfill2 = 0.1
      DATA.GUI.custom_framea = 0.1
      
      DATA.GUI.custom_infoh = 25 * DATA.GUI.default_scale
      DATA.GUI.custom_settingsbut_w = 70 * DATA.GUI.default_scale
      DATA.GUI.custom_settingsbut_h = 15 * DATA.GUI.default_scale
      DATA.GUI.custom_settingsbut_yoffs = DATA.GUI.custom_offset2
      DATA.GUI.custom_settingsbut_txtsz = 12 * DATA.GUI.default_scale
      
      DATA.GUI.custom_moduleh = gfx_h - DATA.GUI.custom_infoh-DATA.GUI.custom_offset -- global H
      DATA.GUI.custom_modulew = math.floor(DATA.GUI.custom_moduleh*1.5) -- global W
      DATA.GUI.custom_modulex = DATA.GUI.custom_settingsbut_w + DATA.GUI.custom_offset -- first mod offset
      
      -- macro 
      DATA.GUI.custom_macroW = math.floor(DATA.GUI.custom_modulew*1.3)
      DATA.GUI.custom_macroY = DATA.GUI.custom_infoh+ DATA.GUI.custom_offset
      DATA.GUI.custom_macroH = DATA.GUI.custom_moduleh--DATA.GUI.custom_offset
      DATA.GUI.custom_macro_knobH = math.floor(DATA.GUI.custom_macroH/2-DATA.GUI.custom_offset2)
      DATA.GUI.custom_macro_knobW =  math.floor(DATA.GUI.custom_macroW/8)
      DATA.GUI.custom_macroW = DATA.GUI.custom_macro_knobW*8 --DATA.GUI.custom_offset2+1
      
      -- pad overview
      DATA.GUI.custom_padgridy = 0--DATA.GUI.custom_infoh
      DATA.GUI.custom_padgridh = gfx_h-DATA.GUI.custom_offset -- - DATA.GUI.custom_infoh-DATA.GUI.custom_offset 
      DATA.GUI.custom_padgridblockh = math.floor(DATA.GUI.custom_padgridh/8)
      DATA.GUI.custom_padgridw = DATA.GUI.custom_padgridblockh
      
       -- dr rack pads
      DATA.GUI.custom_padrackY = DATA.GUI.custom_infoh+ DATA.GUI.custom_offset2
      DATA.GUI.custom_padsideY = math.floor(DATA.GUI.custom_moduleh/4)
      DATA.GUI.custom_padsideX = DATA.GUI.custom_padsideY*1.5
      DATA.GUI.custom_padrackW = DATA.GUI.custom_modulew
      DATA.GUI.custom_offset_pads = DATA.GUI.custom_offset2
      DATA.GUI.custom_padstxtsz = 14
      DATA.GUI.custom_padsctrltxtsz = 10
      DATA.GUI.custom_arcr = math.floor(DATA.GUI.custom_padsideX*0.1)
      
      
      -- device
      DATA.GUI.custom_devicew = math.floor(DATA.GUI.custom_moduleh*1.5)
      DATA.GUI.custom_deviceh = gfx_h - DATA.GUI.custom_infoh-DATA.GUI.custom_offset -- DEVICE H
      DATA.GUI.custom_deviceentryh = math.floor(18 * DATA.GUI.default_scale)
      DATA.GUI.custom_devicectrl_txtsz = 13 * DATA.GUI.default_scale
      
      -- sampler
      DATA.GUI.custom_samplerW = math.floor(DATA.GUI.custom_modulew*1.5)
      DATA.GUI.custom_sampler_showbutw = 50 * DATA.GUI.default_scale
      DATA.GUI.custom_sampler_namebutw = DATA.GUI.custom_samplerW-DATA.GUI.custom_sampler_showbutw
      DATA.GUI.custom_samplerH = DATA.GUI.custom_moduleh
      DATA.GUI.custom_splgridtxtsz = 12 * DATA.GUI.default_scale
      DATA.GUI.custom_spl_areah = math.floor(DATA.GUI.custom_deviceh * 0.5)
      DATA.GUI.custom_spl_modew = math.floor(DATA.GUI.custom_spl_areah/2)
      DATA.GUI.custom_spl_modeh =DATA.GUI.custom_spl_modew+1
      DATA.GUI.custom_splctrl_w = 60 * DATA.GUI.default_scale
      DATA.GUI.custom_splctrl_h = 15 * DATA.GUI.default_scale
      DATA.GUI.custom_splknob_h = DATA.GUI.custom_samplerH - DATA.GUI.custom_splctrl_h*2 - DATA.GUI.custom_spl_areah - DATA.GUI.custom_offset2*2-DATA.GUI.custom_offset
      DATA.GUI.custom_splknob_txtsz = 13 * DATA.GUI.default_scale
      DATA.GUI.custom_sampler_peaksw = DATA.GUI.custom_samplerW-DATA.GUI.custom_offset2-DATA.GUI.custom_spl_modew-1
      if not DATA.GUI.layers then DATA.GUI.layers = {} end 
      DATA.GUI.layers[23]={
        ['a']=1,
        ['layer_w'] = DATA.GUI.custom_sampler_peaksw}
      
        
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play 
      DATA.GUI.buttons = {} 
    
    -- settings
      DATA.GUI.buttons.settings = { x=0,
                            y=0,
                            w=DATA.GUI.custom_settingsbut_w,-- - DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_infoh-1,
                            txt = '>',
                            --frame_a = 1,
                            onmouseclick = function()
                              if DATA.GUI.Settings_open then DATA.GUI.Settings_open = math.abs(1-DATA.GUI.Settings_open) else DATA.GUI.Settings_open = 1 end 
                              DATA.UPD.onGUIinit = true
                            end,
                            }
                            
      if not DATA.GUI.Settings_open or (DATA.GUI.Settings_open and DATA.GUI.Settings_open ==0) then  
        for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
        if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 0
        --if DATA2.tr_valid ==true and DATA2.tr_extparams_showstates then 
          GUI_RESERVED_init_settingbut(DATA)
          GUI_MODULE_MACRO(DATA) 
          GUI_MODULE_PADOVERVIEW(DATA)
          GUI_MODULE_DRUMRACKPAD(DATA)
          GUI_MODULE_DEVICE(DATA)  
          GUI_MODULE_SAMPLER(DATA) 
        --end
       elseif DATA.GUI.Settings_open and DATA.GUI.Settings_open == 1 then 
        GUI_MODULE_SETTINGS(DATA)
      end
    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ---------------------------------------------------------------------  
  function GUI_MODULE_SETTINGS(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
    if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 1
    DATA.GUI.buttons.Rsettings = { x=0,
                          y=DATA.GUI.custom_infoh + DATA.GUI.custom_offset,
                          w=gfx.w/DATA.GUI.default_scale,
                          h=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_infoh-DATA.GUI.custom_offset,
                          txt = 'Settings',
                          frame_a = 0,
                          offsetframe = DATA.GUI.custom_offset,
                          offsetframe_a = 0.1,
                          ignoremouse = true,
                          refresh = true,
                          }
    DATA:GUIBuildSettings()
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
    local  t = 
    { 
      {str = 'On sample add:' ,                                    group = 1, itype = 'sep'},
        {str = 'Float RS5k at adding',                          group = 1, itype = 'check', confkey = 'CONF_floatonadding', level = 1},
      {str = 'MIDI bus',                                        group = 2, itype = 'sep'},
        {str = 'MIDI bus default input',                        group = 2, itype = 'readout', confkey = 'CONF_midiinput', level = 1, menu = {[63]='All inputs',[62]='Virtual keyboard'},readoutw_extw = readoutw_extw},
      
    } 
    return t
    
  end
  ---------------------------------------------------------------------- 
  function GUI_CTRL_Knob(DATA, params_t) 
    local t = params_t
    local arc_shift = math.floor(t.w*DATA.GUI.default_button_framew_arcratio)
    local note = t.note
    local layer = t.layer
    local val_format_key = t.val_format_key 
    local prefix = t.prefix
    local val_format = t.val_format
    local f = t.f
    local f_double = t.f_double
    local f_release = t.f_release
    
    local txt_line_ratio = t.txt_line_ratio or 1
    DATA.GUI.buttons[prefix..t.key..'frame'] = { x= t.x,
                        y=t.y ,
                        w=t.w,
                        h=t.h,
                        ignoremouse = true,
                        --frame_a =DATA.GUI.custom_framea,
                        --frame_col = '#333333',
                        frame_arcborder = t.frame_arcborder,
                        frame_arcborderr = t.frame_arcborderr,
                        frame_arcborderflags = t.frame_arcborderflags,
                        } 
    DATA.GUI.buttons[prefix..t.key..'name'] = { x= t.x+arc_shift ,
                        y=t.y+1 ,
                        w=t.w-arc_shift*2,
                        h=DATA.GUI.custom_splctrl_h*txt_line_ratio,
                        ignoremouse = true,
                        frame_a = 1,
                        frame_col = '#333333',
                        txt = t.ctrlname,
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        } 
    DATA.GUI.buttons[prefix..t.key..'val'] = { x= t.x+arc_shift ,
                        y=t.y+t.h-DATA.GUI.custom_splctrl_h ,
                        w=t.w-arc_shift*2,
                        h=DATA.GUI.custom_splctrl_h-1,
                        ignoremouse = true,
                        frame_a = 1,
                        --backgr_fill = 0,
                        frame_col = '#333333',
                        txt = val_format,
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        } 
    DATA.GUI.buttons[prefix..t.key..'knob'] = { x= t.x+arc_shift,
                        y=t.y+DATA.GUI.custom_splctrl_h*txt_line_ratio ,
                        w=t.w-arc_shift*2,
                        h=t.h-DATA.GUI.custom_splctrl_h*(txt_line_ratio+1)-1,
                        --ignoremouse = true,
                        frame_a =1,
                        frame_col = '#333333',
                        knob_isknob = true,
                        val = t.val,
                        val_res = t.val_res,
                        val_max = t.val_max,
                        val_min = t.val_min,
                        txt = '',
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        onmousedoubleclick = function() f_double() end,
                        onmouseclick = function() end,
                        onmousedrag = function() f()  end,
                        onmouserelease = function() if f_release then f_release() else f() end end,
                        } 
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_MACRO_stuff_Knobs_app(DATA, prefix,key,ctrlid, val)--paramid,src_t,note,layer,val_format_key)  
    local new_val = DATA.GUI.buttons[prefix..key..'knob'].val
    if val then new_val = val end
    if not new_val then return end
    TrackFX_SetParamNormalized( DATA2.tr_ptr, DATA2.Macro.macroJSFX_fxID, ctrlid-1,new_val )
    DATA.GUI.buttons[prefix..key..'val'].txt = math.floor(new_val*100)..'%'
    DATA.GUI.buttons[prefix..key..'val'].refresh = true
  end 
  ------------------------------------------------------------------------
  function GUI_MODULE_MACRO_stuff_knob_preset(DATA, key, ctrlid)--,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,xoffs)
    local prefix = 'macroglob_'
    
    local xshift = DATA.GUI.custom_macro_knobW*(ctrlid-1)
    local yshift = DATA.GUI.custom_macro_knobH * math.floor((ctrlid/9))
    if ctrlid>=9 then 
      xshift = DATA.GUI.custom_macro_knobW*(ctrlid-9)
    end
    
    local key = 'macroknob_'..ctrlid
    local ctrlname = 'Macro \n'..ctrlid
      GUI_CTRL_Knob(DATA,
        {
          prefix = prefix,
          key = key,
          ctrlname = ctrlname,
          val = DATA2.Macro.sliders[ctrlid].val,
          val_format = math.floor(DATA2.Macro.sliders[ctrlid].val*100)..'%',
          val_res = 0.2,
          x = math.floor(DATA.GUI.buttons.macroglob_frame.x+xshift)+1,
          y = math.floor(DATA.GUI.buttons.macroglob_frame.y+yshift)+1,
          w = DATA.GUI.custom_macro_knobW-DATA.GUI.custom_offset2,
          h = DATA.GUI.custom_macro_knobH-DATA.GUI.custom_offset2,
          frame_arcborder = true,
          txt_line_ratio = 2,
          f= function() GUI_MODULE_MACRO_stuff_Knobs_app(DATA, prefix, key, ctrlid) end,--,key,paramid,src_t,note,layer,val_format_key)   end  ,
          f_double= function() GUI_MODULE_MACRO_stuff_Knobs_app(DATA, prefix, key, ctrlid, val_default) end--,key,paramid,src_t,note,layer,val_format_key)   end  ,
          
        } )
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO_stuff(DATA)  
    for ctrlid = 1, 16 do
      key = 'macroknob_'..ctrlid 
      GUI_MODULE_MACRO_stuff_knob_preset(DATA, key, ctrlid)--,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO(DATA)    
    for key in pairs(DATA.GUI.buttons) do if key:match('macroglob_') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.tr_extparams_showstates or ( DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&16==0) then return end
    local x_offs= DATA.GUI.custom_modulex
    
    DATA.GUI.buttons.macroglob_actionframe = { x=x_offs,
                          y=0,
                          w=DATA.GUI.custom_macroW,
                          h=DATA.GUI.custom_infoh,
                          txt = '',
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() end}
    DATA.GUI.buttons.macroglob_frame = { x=x_offs,
                          y=DATA.GUI.custom_macroY,
                          w=DATA.GUI.custom_macroW,
                          h=DATA.GUI.custom_macroH,
                          txt = '',
                          val = 0,
                          frame_a = 0,--0.3,
                          frame_asel = 0.3,
                          --backgr_fill = 0,
                          ignoremouse = true,
                          onmouseclick =  function() end}
    GUI_MODULE_MACRO_stuff(DATA) 
                          
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_DRUMRACKPAD(DATA) 
    for key in pairs(DATA.GUI.buttons) do if key:match('drumrack') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.tr_extparams_showstates or ( DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&1==0) then return end
    
    local trname = DATA2.tr_name or '[no data]'      
    local x_offs= DATA.GUI.custom_modulex
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&16==16 then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&8==8 then x_offs = x_offs + DATA.GUI.custom_offset +  DATA.GUI.custom_padgridw end -- pad view
       
       -- dr rack
       DATA.GUI.buttons.drumrack_trackname = { x=x_offs,
                            y=0,
                            w=DATA.GUI.custom_padrackW,
                            h=DATA.GUI.custom_infoh,
                            txt = trname,
                            }
       DATA.GUI.buttons.drumrackpad = { x=x_offs,
                             y=DATA.GUI.custom_padrackY,
                             w=DATA.GUI.custom_padrackW,
                             h=DATA.GUI.custom_deviceh,
                             ignoremouse = true,
                             frame_a = 0,
                             }
                             
                             
                             
    local padactiveshift = 116 
    if DATA2.tr_extparams_activepad == 8 then padactiveshift = 116 end
    if DATA2.tr_extparams_activepad == 7 then padactiveshift = 100 end
    if DATA2.tr_extparams_activepad == 6 then padactiveshift = 84 end
    if DATA2.tr_extparams_activepad == 5 then padactiveshift = 68 end
    if DATA2.tr_extparams_activepad == 4 then padactiveshift = 52 end
    if DATA2.tr_extparams_activepad == 3 then padactiveshift = 36 end
    if DATA2.tr_extparams_activepad == 2 then padactiveshift = 20 end
    if DATA2.tr_extparams_activepad == 1 then padactiveshift = 4 end
    if DATA2.tr_extparams_activepad == 0 then padactiveshift = 0 end
    
    for padID0 =0 , 16 do
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] = nil
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'mute'] = nil
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'solo'] = nil
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'play'] = nil
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'show'] = nil
    end
    
    local padID0 = 0
    for note = 0+padactiveshift, 15+padactiveshift do
      local txt = DATA2:FormatMIDIPitch(note) 
      if note > 127 then break end
      local frame_a = DATA.GUI.custom_framea if DATA2.tr_extparams_note_active and DATA2.tr_extparams_note_active == note then frame_a = 0.7 end
      if DATA2.notes[note] and DATA2.notes[note].name then txt = DATA2.notes[note].name end
      DATA.GUI.buttons['drumrackpad_pad'..padID0] = { x=DATA.GUI.buttons.drumrackpad.x+(padID0%4)*DATA.GUI.custom_padsideX+1,
                              y=DATA.GUI.buttons.drumrackpad.y+DATA.GUI.buttons.drumrackpad.h-DATA.GUI.custom_padsideY*(math.floor(padID0/4)+1)+DATA.GUI.custom_offset_pads,
                              w=DATA.GUI.custom_padsideX-DATA.GUI.custom_offset_pads,
                              h=DATA.GUI.custom_padsideY-DATA.GUI.custom_offset_pads-1,
                              ignoremouse = true,
                              txt='',
                              frame_a = frame_a,
                              frame_arcborder = true,
                              frame_arcborderr = DATA.GUI.custom_arcr,
                              frame_arcborderflags = 1|2|4,
                              onmouseclick = function() end, 
                              }
                              
      local padx= DATA.GUI.buttons.drumrackpad.x+(padID0%4)*DATA.GUI.custom_padsideX+1
      local pady = DATA.GUI.buttons.drumrackpad.y+DATA.GUI.buttons.drumrackpad.h-DATA.GUI.custom_padsideY*(math.floor(padID0/4)+1)+DATA.GUI.custom_offset_pads
      local controlbut_h = DATA.GUI.custom_padsideY/2
      local controlbut_h2 = DATA.GUI.custom_padsideY/2-DATA.GUI.custom_offset_pads
      local controlbut_w = math.floor(DATA.GUI.custom_padsideX / 4)
      local frame_actrl =0
      local txt_actrl = 0.2
      local txt_a
      if not DATA2.notes[note] then txt_a = 0.1 end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] = { x=padx,
                              y=pady,
                              w=DATA.GUI.custom_padsideX-DATA.GUI.custom_offset_pads,
                              h=controlbut_h,
                              txt=txt,
                              txt_a = txt_a,
                              txt_fontsz = DATA.GUI.custom_padstxtsz,
                              frame_a = 0,
                              frame_asel = 0,
                              backgr_fill = 0 ,
                              back_sela = 0 ,
                              --prevent_matchrefresh = true,
                              onmouseclick = function() 
                                if DATA.GUI.Ctrl == true then DATA2:ActiveNoteLayer_ShowRS5k(note, 1) else
                                  DATA2.tr_extparams_note_active = note 
                                  DATA2.tr_extparams_note_active_layer = 1 
                                  DATA2:TrackDataWrite() 
                                  GUI_MODULE_DRUMRACKPAD(DATA)  
                                  DATA2.tr_extparams_note_active_layer = layer 
                                  GUI_MODULE_DEVICE(DATA)  
                                  GUI_MODULE_SAMPLER(DATA)
                                end
                              end,
                              onmouseclickR = function() DATA2:PAD_onrightclick(note) end,
                              onmousefiledrop = function() DATA2:PAD_onfiledrop(note) end,
                              }     
      --local txt_a,txt_col= txt_actrl if DATA2.notes[note] and DATA2.notes[note].partrack_mute and DATA2.notes[note].partrack_mute == 1 then txt_col = '#A55034' txt_a = 1 end
      local backgr_fill,txt_a= 0,txt_actrl if DATA2.notes[note] and DATA2.notes[note].partrack_mute and DATA2.notes[note].partrack_mute ==1 then backgr_fill = 0.2 txt_a = nil end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'mute'] = { x=padx,
                              y=pady+controlbut_h,
                              w=controlbut_w,
                              h=controlbut_h2-1,
                              txt='M',
                              txt_col=txt_col,
                              txt_a = txt_a,
                              txt_fontsz = DATA.GUI.custom_padsctrltxtsz,
                              frame_a = frame_actrl,
                              prevent_matchrefresh = true,
                              backgr_fill = backgr_fill,
                              backgr_col = DATA.GUI.custom_backcol2,
                              onmouseclick = function() DATA2:PAD_mute(note) end,
                              } 
      local backgr_fill2 if DATA2.playingnote_pitch and DATA2.playingnote_pitch == note  then backgr_fill2 = 0.3 end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'play'] = { x=padx+controlbut_w,
                              y=pady+controlbut_h,
                              w=controlbut_w,
                              h=controlbut_h2-1,
                              txt='>',
                              txt_fontsz = DATA.GUI.custom_padsctrltxtsz,
                              txt_a = txt_actrl,
                              prevent_matchrefresh = true,
                              frame_a = frame_actrl,
                              backgr_fill = backgr_fill2 ,
                              onmouseclick =    function() StuffMIDIMessage( 0, 0x90, note, 120 ) DATA.ontrignoteTS = os.clock() DATA.ontrignote = note end,
                              onmouserelease =  function() StuffMIDIMessage( 0, 0x80, note, 0 ) DATA.ontrignoteTS =  nil end,
                              }   
      local backgr_fill,txt_a= 0,txt_actrl if DATA2.notes[note] and DATA2.notes[note].partrack_solo and DATA2.notes[note].partrack_solo >0 then backgr_fill = 0.2 txt_a = nil end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'solo'] = { x=padx+controlbut_w*2,
                              y=pady+controlbut_h,
                              w=controlbut_w,
                              h=controlbut_h2-1,
                              --txt_col=txt_col,
                              txt_a = txt_a,
                              txt='S',
                              txt_fontsz = DATA.GUI.custom_padsctrltxtsz,
                              frame_a = frame_actrl,
                              prevent_matchrefresh = true,
                              backgr_fill = backgr_fill,
                              backgr_col = DATA.GUI.custom_backcol2,
                              onmouseclick = function() DATA2:PAD_solo(note) end,
                              }    
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'show'] = { x=padx+controlbut_w*3,
                              y=pady+controlbut_h,
                              w=controlbut_w-1,
                              h=controlbut_h2-1,
                              txt_a = txt_actrl,
                              txt='ME',
                              txt_fontsz = DATA.GUI.custom_padsctrltxtsz,
                              frame_a = 0,
                              backgr_fill = 0,
                              frame_arcborder = true,
                              frame_arcborderr = DATA.GUI.custom_arcr,
                              frame_arcborderflags = 4,
                              onmouseclick = function() DATA2:PAD_showinME(note) end,
                              }                               
      padID0 = padID0 + 1
    end
  end
  ----------------------------------------------------------------------- 
  function DATA2:PAD_mute(note)
    if not (DATA2.notes[note] and DATA2.notes[note].partrack_ptr and DATA2.notes[note].partrack_mute) then return end 
    local state = DATA2.notes[note].partrack_mute > 0
    if state then state = 0 else state =1 end 
    SetMediaTrackInfo_Value( DATA2.notes[note].partrack_ptr, 'B_MUTE', state )
    DATA2.notes[note].partrack_mute = state
    GUI_MODULE_DRUMRACKPAD(DATA)  
  end
  ----------------------------------------------------------------------- 
  
  function DATA2:PAD_showinME(note)
    if not (DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1]) then return end 
    local filepath= DATA2.notes[note].layers[1].filepath
    OpenMediaExplorer( filepath, false )
  end
  ----------------------------------------------------------------------- 
  function DATA2:PAD_solo(note)
    if not (DATA2.notes[note] and DATA2.notes[note].partrack_ptr and ValidatePtr2(0,DATA2.notes[note].partrack_ptr, 'MediaTrack*')) then return end 
    local state = DATA2.notes[note].partrack_solo > 0
    if state then state = 0 else state =2 end 
    SetMediaTrackInfo_Value( DATA2.notes[note].partrack_ptr, 'I_SOLO', state )
    DATA2.notes[note].partrack_solo = state
    GUI_MODULE_DRUMRACKPAD(DATA)  
  end  
  ----------------------------------------------------------------------- 
  function DATA2:FormatMIDIPitch(note)
    local val = math.floor(note)
    local oct = math.floor(note / 12)
    local note = math.fmod(note,  12)
    local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
    if note and oct and key_names[note+1] then return key_names[note+1]..oct-2 end
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onfiledrop_AddMIDISend(new_tr) 
    -- make sure MIDI bus exist
    if not new_tr then return end
    DATA2:TrackDataRead_ValidateMIDIbus()
      
    local sendidx = CreateTrackSend( DATA2.MIDIbus.ptr, new_tr )
    SetTrackSendInfo_Value( DATA2.MIDIbus.ptr, 0, sendidx, 'I_SRCCHAN',-1 )
    SetTrackSendInfo_Value( DATA2.MIDIbus.ptr, 0, sendidx, 'I_MIDIFLAGS',0 )
  end
  -----------------------------------------------------------------------   
  function DATA2:PAD_onfiledrop_AddChildTrack() 
    --local ID = DATA2.MIDIbus.ID
    local ID = DATA2.enclose_trID
    InsertTrackAtIndex( ID, false )
    local new_tr = CSurf_TrackFromID(ID+1,false) 
    DATA2:TrackDataWrite_MarkChildAppendsToCurrentParent(new_tr)  
    SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH',-1 ) -- enclose folder
    if DATA2.enclose_trPtr ~= DATA2.tr_ptr then
      local depth = GetMediaTrackInfo_Value( DATA2.enclose_trPtr, 'I_FOLDERDEPTH')
      if depth == -1 then 
        SetMediaTrackInfo_Value( DATA2.enclose_trPtr, 'I_FOLDERDEPTH',0)
       elseif depth == -2 then -- multilayer
        SetMediaTrackInfo_Value( DATA2.enclose_trPtr, 'I_FOLDERDEPTH',-1)
      end
    end
    DATA2.enclose_trPtr = new_tr
    DATA2.enclose_trID = CSurf_TrackToID(new_tr,false) 
    return new_tr
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onfiledrop_ExportToRS5k(new_tr, filepath,note,filepath_sh)
    if not filepath_sh then return end
    local rs5k_pos = TrackFX_AddByName( new_tr, 'ReaSamplomatic5000', false, 1 ) 
    if DATA.extstate.CONF_floatonadding == 0 then TrackFX_SetOpen( new_tr, rs5k_pos, false ) end
    TrackFX_SetNamedConfigParm(  new_tr, rs5k_pos, 'FILE0', filepath)
    TrackFX_SetNamedConfigParm(  new_tr, rs5k_pos, 'DONE', '')      
    TrackFX_SetParamNormalized( new_tr, rs5k_pos, 2, 0) -- gain for min vel
    TrackFX_SetParamNormalized( new_tr, rs5k_pos, 3, (note)/127 ) -- note range start
    TrackFX_SetParamNormalized( new_tr, rs5k_pos, 4, (note)/127 ) -- note range end
    TrackFX_SetParamNormalized( new_tr, rs5k_pos, 5, 0.5 ) -- pitch for start
    TrackFX_SetParamNormalized( new_tr, rs5k_pos, 6, 0.5 ) -- pitch for end
    TrackFX_SetParamNormalized( new_tr, rs5k_pos, 8, 0 ) -- max voices = 0
    TrackFX_SetParamNormalized( new_tr, rs5k_pos, 9, 0 ) -- attack
    TrackFX_SetParamNormalized( new_tr, rs5k_pos, 11, 1) -- obey note offs
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', filepath_sh, true )
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_ClearPad(note)
    if not DATA2.notes[note] then return end
    DeleteTrack( DATA2.notes[note].partrack_ptr )
    DATA2.FORCEONPROJCHANGE = true
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onrightclick(note)
    if not DATA2.tr_valid then return end
    local t = { 
    
      {str='Export selected items to pads, starting this pad',
       func=function() DATA2:PAD_ExportSelectedItems(note) end },
      {str='Clear pad',
       func=function() DATA2:PAD_ClearPad(note) end },       
       
                }
              
    DATA:GUImenu(t)
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_ExportSelectedItems(note)
    local cnt = CountSelectedMediaItems(0)
    local max_items = 8
    if cnt > max_items then
      local ret = MB('There are more than '..max_items..' items to export, continue?', '',3 )
      if ret~=6 then return end
    end
    
    local itt = {}
    for selitem = 1, cnt do itt[#itt+1] = GetSelectedMediaItem( 0, selitem -1) end
    for i =1, #itt do
      local it = itt[i]
      local tk = GetActiveTake( it )
      if tk and not TakeIsMIDI( tk ) then
        local src = GetMediaItemTake_Source( tk)
        if src then 
          local filenamebuf = GetMediaSourceFileName( src )
          local layer = 1
          DATA2:PAD_onfiledrop(note+i-1, layer, filenamebuf)
          DeleteTrackMediaItem(  reaper.GetMediaItemTrack( it ), it )
        end
      end
    end
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onfiledrop_sub(note, layer, filepath)
      local filepath_sh, it_len
      if filepath ~= '' then 
        filepath_sh = GetShortSmplName(filepath)
        if filepath_sh:match('(.*)%.[%a]+') then filepath_sh = filepath_sh:match('(.*)%.[%a]+') end
        local tk_src = PCM_Source_CreateFromFile( filepath )
        it_len =  GetMediaSourceLength( tk_src )
      end
    
    -- handle multilayer mode
    if not layer then layer =1 end
    if not DATA2.notes[note] then -- add new non-device child
      SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERDEPTH', 1 ) -- make sure parent folder get parent ono adding first child
      local new_tr = DATA2:PAD_onfiledrop_AddChildTrack() 
      DATA2:PAD_onfiledrop_ExportToRS5k(new_tr, filepath,note,filepath_sh)
      DATA2:PAD_onfiledrop_AddMIDISend(new_tr) 
     elseif DATA2.notes[note] and not DATA2.notes[note].is_device and layer == 1 then -- replace existing sample into 1st layer
      local new_tr = DATA2.notes[note].layers[1].trackptr
      local rs5k_pos = DATA2:GetFirstRS5k(new_tr)
      TrackFX_SetNamedConfigParm(  DATA2.notes[note].layers[layer].trackptr, DATA2.notes[note].layers[layer].rs5k_pos, 'FILE0', filepath)
      TrackFX_SetNamedConfigParm(  DATA2.notes[note].layers[layer].trackptr, DATA2.notes[note].layers[layer].rs5k_pos, 'DONE', '') 
     elseif DATA2.notes[note] and not DATA2.notes[note].is_device and layer ~= 1 then -- convert child to a device + add new instance and 
      --[[local ID_curchild =  CSurf_TrackToID( DATA2.notes[note].layers[1].trackptr, false )-1
      local devicetr = DATA2:PAD_onfiledrop_AddChildTrack(ID_curchild) 
      --SetMediaTrackInfo_Value( devicetr, 'I_FOLDERDEPTH', 1 ) -- make device track folder
      GetSetMediaTrackInfo_String( devicetr, 'P_NAME', DATA2.notes[note].name, true )
      --SetMediaTrackInfo_Value( DATA2.notes[note].layers[1].trackptr, 'I_FOLDERDEPTH', -1 ) -- make prev track enclose device
      
      local ID_devicetr =  CSurf_TrackToID(devicetr, false ) 
      local new_tr = DATA2:PAD_onfiledrop_AddChildTrack(ID_devicetr) 
      DATA2:PAD_onfiledrop_ExportToRS5k(new_tr, filepath, note,filepath_sh)
      DATA2:PAD_onfiledrop_AddMIDISend(new_tr)]]
     elseif DATA2.notes[note] and DATA2.notes[note].is_device ==true and DATA2.notes[note].layers[layer] then -- replace sample in specific layer
      -- reserved
     elseif DATA2.notes[note] and DATA2.notes[note].is_device ==true and not DATA2.notes[note].layers[layer] then -- add new layer to device
      -- reserved
      
      
    end
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onfiledrop(note, layer, filepath0)
    if not DATA2.tr_valid then return end
    
    -- validate additional stuff
    DATA2:TrackDataRead_ValidateMIDIbus()
    SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERCOMPACT',1 ) -- folder compacted state (only valid on folders), 0=normal, 1=small, 2=tiny children
    
    -- get fp
      if filepath0 then 
        DATA2:PAD_onfiledrop_sub(note, layer, filepath)
       else
        for i =1, #DATA.GUI.droppedfiles.files+1 do
          local filepath = DATA.GUI.droppedfiles.files[i-1]
          DATA2:PAD_onfiledrop_sub(note+i-1, layer, filepath)
        end
      end
    
    -- refresh data
      DATA2:TrackDataRead(DATA2.tr_ptr)
      DATA2.tr_extparams_note_active = note
      DATA2.tr_extparams_note_active_layer = layer
      DATA2:TrackDataWrite()
      --DATA_RESERVED_ONPROJCHANGE(DATA)
      --GUI_MODULE_DRUMRACKPAD(DATA)  
      --GUI_MODULE_SAMPLER(DATA)
  end
  ----------------------------------------------------------------------- 
    
  function DATA2:TrackData_SetTrackParams(src_t, parmname, newvalue)
    local track = src_t.trackptr
    if not (track  and ValidatePtr2(0,track,'MediaTrack*')) then return end
    SetMediaTrackInfo_Value( track, parmname, newvalue )
  end
  -----------------------------------------------------------------------------  
  
  function GUI_MODULE_DEVICE_stuff(DATA, note, layer, y_offs)  
    local x_offs = DATA.GUI.buttons.devicestuff_frame.x
    local w_ctr = 20
    local w_vol = w_ctr*3
    local w_pan = w_ctr*3
    local reduce = 3
    local w_layername = DATA.GUI.buttons.devicestuff_frame.w - w_vol - w_pan - w_ctr + reduce--*2 
    local ctrl_txtsz = DATA.GUI.custom_devicectrl_txtsz
    local frame_a = 0
    local tr_extparams_note_active_layer = DATA2.tr_extparams_note_active_layer
    if not tr_extparams_note_active_layer then tr_extparams_note_active_layer = 1 end
    local backgr_col=DATA.GUI.custom_backcol2
    local backgr_fill =0 
    local backgr_fill_param = 0.2
    if tr_extparams_note_active_layer == layer then backgr_fill = DATA.GUI.custom_backfill2 end-- backgr_col = '#b6d7a8'
    
    -- name
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'name'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_layername-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        --ignoremouse = DATA2.tr_extparams_showstates&2==0,
                        txt = DATA2.notes[note].layers[layer].filepath_short,
                        txt_fontsz = ctrl_txtsz,
                        frame_a = frame_a,
                        backgr_fill = backgr_fill,
                        backgr_col =backgr_col,
                        prevent_matchrefresh = true,
                        onmouseclick = function() 
                          DATA2.tr_extparams_note_active_layer = layer 
                          GUI_MODULE_SAMPLER(DATA)
                        end,
                        }
    -- vol
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'] = { 
                        x=x_offs+w_layername,
                        y=y_offs,
                        w=w_vol-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        val = DATA2.notes[note].layers[layer].dev_vol/2,
                        val_res = -0.1,
                        val_xaxis = true,
                        txt = DATA2.notes[note].layers[layer].dev_vol_format,
                        txt_fontsz = ctrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        onmousedrag = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].val
                              DATA2:TrackData_SetTrackParams(src_t, 'D_VOL', new_val*2)
                              DATA2:TrackDataRead_GetChildrens_GetRS5kParams(src_t.trackptr, src_t.rs5k_pos, note,layer)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].txt = DATA2.notes[note].layers[layer].dev_vol_format
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].refresh = true
                            end,
                        onmouserelease = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].val
                              DATA2:TrackData_SetTrackParams(src_t, 'D_VOL', new_val*2)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].txt = DATA2.notes[note].layers[layer].dev_vol_format
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].refresh = true
                        end,
                        }   
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'] = { 
                        x=x_offs+w_layername+w_vol,
                        y=y_offs,
                        w=w_pan-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        val = DATA2.notes[note].layers[layer].dev_pan,
                        val_res = -0.6,
                        val_xaxis = true,
                        txt = VF_math_Qdec(DATA2.notes[note].layers[layer].dev_pan,3),
                        txt_fontsz = ctrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        onmousedrag = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].val
                              DATA2:TrackData_SetTrackParams(src_t, 'D_PAN', new_val)
                              DATA2:TrackDataRead_GetChildrens_GetRS5kParams(src_t.trackptr, src_t.rs5k_pos, note,layer)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = VF_math_Qdec(DATA2.notes[note].layers[layer].dev_pan,3)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                            end,
                        onmouserelease = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].val
                              DATA2:TrackData_SetTrackParams(src_t, 'D_PAN', new_val)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = VF_math_Qdec(DATA2.notes[note].layers[layer].dev_pan,3)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                        end,
                        }   
                        
    local backgr_fill_param_en
    if DATA2.notes[note].layers[layer].enabled == true then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'enable'] = { 
                        x=x_offs+w_layername+w_vol+w_pan,
                        y=y_offs,
                        w=w_ctr-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        txt = 'On',
                        txt_fontsz = ctrl_txtsz,
                        onmouserelease = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local newval = 1 if src_t.enabled == true then newval = 0 end
                              DATA2:TrackData_SetRS5kParams(src_t, 'enabled', newval)
                              DATA2:TrackDataRead_GetChildrens_GetRS5kParams(src_t.trackptr, src_t.rs5k_pos, note,layer)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = VF_math_Qdec(DATA2.notes[note].layers[layer].dev_pan,3)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                            end,
                        }            
    --[[DATA.GUI.buttons['devicestuff_'..'layer'..layer..'solo'] = { 
                        x=x_offs+w_layername+w_vol+w_pan+w_ctr,
                        y=y_offs,
                        w=w_ctr-reduce+1,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        ignoremouse = true,
                        txt = 'S',
                        txt_fontsz = ctrl_txtsz,
                        frame_a = frame_a,
                        backgr_col =backgr_col,
                        backgr_fill = backgr_fill,
                        }  ]]                       
  end
  ----------------------------------------------------------------------------- 
  function GUI_MODULE_DEVICE(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('devicestuff') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.tr_extparams_showstates or ( DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&2==0) then return end
    if not (DATA2.tr_extparams_note_active and DATA2.tr_extparams_note_active~=-1) then return end
    
    local name = '' 
    if DATA2.tr_extparams_note_active and DATA2.notes[DATA2.tr_extparams_note_active] and DATA2.notes[DATA2.tr_extparams_note_active].name then name = '['..DATA2.tr_extparams_note_active..'] '..DATA2.notes[DATA2.tr_extparams_note_active].name end
    local x_offs = DATA.GUI.custom_offset +DATA.GUI.custom_settingsbut_w
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&16==16 then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&8==8 then x_offs = x_offs + DATA.GUI.custom_padgridw + DATA.GUI.custom_offset end -- pad view
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&1==1 then x_offs = x_offs + DATA.GUI.custom_padrackW + DATA.GUI.custom_offset end -- drrack
    DATA.GUI.buttons.devicestuff_name = { x=x_offs,
                         y=0,
                         w=DATA.GUI.custom_devicew,
                         h=DATA.GUI.custom_infoh,
                         txt = name,
                         onmouseclick = function() DATA2:PAD_onrightclick(DATA2.tr_extparams_note_active) end
                         }
        
    if not DATA2.tr_extparams_note_active then return end
    local tr_extparams_note_active = DATA2.tr_extparams_note_active
    if not DATA2.notes[tr_extparams_note_active] then return end
    
    DATA.GUI.buttons.devicestuff_frame = { x=x_offs,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_offset2,
                          w=DATA.GUI.custom_devicew,
                          h=DATA.GUI.custom_deviceh-DATA.GUI.custom_offset+DATA.GUI.custom_offset2,
                          ignoremouse = true,
                          frame_a =1,
                          frame_col = '#333333',
                          }  
                          
    local y_offs = DATA.GUI.buttons.devicestuff_frame.y+ DATA.GUI.custom_offset2
    local w_dev = DATA.GUI.buttons.devicestuff_frame.w
    for layer = 1, #DATA2.notes[tr_extparams_note_active].layers do
      GUI_MODULE_DEVICE_stuff(DATA, tr_extparams_note_active, layer, y_offs)  
      y_offs = y_offs + DATA.GUI.custom_deviceentryh
    end
    
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_PADOVERVIEW_generategrid(DATA)
    -- draw notes
    local cellside = math.floor(DATA.GUI.custom_padgridw / 4)
    local refnote = 127
    for note = 0, 127 do
      local blockcol = '#757575'
      if 
        (note >=0 and note<=3)or
        (note >=20 and note<=35)or
        (note >=52 and note<=67)or
        (note >=84 and note<=99)or
        (note >=116 and note<=127)
      
      then blockcol ='#D5D5D5' end
      
      
      local backgr_fill2 = 0.4 
      if DATA2.notes[note] then backgr_fill2 = 0.8  blockcol = '#f3f6f4' end
      if DATA2.playingnote_pitch and DATA2.playingnote_pitch == note  then blockcol = '#ffe494' backgr_fill2 = 0.7 end
      
      DATA.GUI.buttons['padgrid_but'..note] = { x=    DATA.GUI.buttons.padgrid.x+math.floor(cellside*(note%4)),
                          y=DATA.GUI.custom_padgridy+DATA.GUI.custom_padgridh - cellside*(math.floor(note/4))-cellside,
                          w=cellside,
                          h=cellside,
                          ignoremouse = true,
                          --txt = note,
                          backgr_col2 = blockcol,
                          frame_a = 0,
                          txt_fontsz = 10,
                          backgr_fill2 = backgr_fill2,
                          --onmouseclick =  function() end,
                          refresh = true
                          }
    end
    
    
    if DATA2.tr_extparams_activepad then
      local padactiveshift = 0
      if DATA2.tr_extparams_activepad == 7 then padactiveshift = cellside * (4*1-1) end
      if DATA2.tr_extparams_activepad == 6 then padactiveshift = cellside * (4*2-1) end
      if DATA2.tr_extparams_activepad == 5 then padactiveshift = cellside * (4*3-1) end
      if DATA2.tr_extparams_activepad == 4 then padactiveshift = cellside * (4*4-1) end
      if DATA2.tr_extparams_activepad == 3 then padactiveshift = cellside * (4*5-1) end
      if DATA2.tr_extparams_activepad == 2 then padactiveshift = cellside * (4*6-1) end
      if DATA2.tr_extparams_activepad == 1 then padactiveshift = cellside * (4*7-1) end
      if DATA2.tr_extparams_activepad == 0 then padactiveshift = cellside * (4*7) end
      local top = DATA.GUI.buttons['padgrid_but'..refnote].y
      local sideX = DATA.GUI.buttons['padgrid_but'..refnote].x+DATA.GUI.buttons['padgrid_but'..refnote].w-DATA.GUI.buttons['padgrid_but'..refnote-3].x
      local sideY = DATA.GUI.buttons['padgrid_but'..111].y-DATA.GUI.buttons['padgrid_but'..127].y
      
      DATA.GUI.buttons.padgrid_activerect = { x=DATA.GUI.buttons.padgrid.x,
                            y=top+padactiveshift,
                            w=sideX,
                            h=sideY,
                            --txt = note,
                            ignoremouse = true,
                            backgr_col2 = blockcol,
                            frame_a = 0.9,
                            txt_fontsz = 10,
                            backgr_fill2 = 0.7,
                            onmouseclick =  function() end,
                            }
      
    end
  end
  ----------------------------------------------------------------------------- 
    
  function GUI_MODULE_PADOVERVIEW (DATA,xoffs)
    for key in pairs(DATA.GUI.buttons) do if key:match('padgrid') then DATA.GUI.buttons[key] = nil end end
    for key in pairs(DATA.GUI.buttons) do if key:match('padgrid_but') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.tr_extparams_showstates or ( DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&8==0) then return end
    
    local x_offs= DATA.GUI.custom_modulex
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&16==16 then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    DATA.GUI.buttons.padgrid = { x=x_offs,
                          y=DATA.GUI.custom_padgridy,
                          w=DATA.GUI.custom_padgridw,
                          h=DATA.GUI.custom_padgridh,
                          txt = '',
                          val = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          backgr_fill = 0,
                          onmouseclick =  function() 
                                            DATA2.tr_extparams_activepad = VF_lim(math.floor((1-DATA.GUI.buttons.padgrid.val_abs)*9) ,0,9) 
                                            DATA.GUI.buttons.padgrid_activerect.refresh = true
                                            GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                            GUI_MODULE_DRUMRACKPAD(DATA)  
                                          end,
                          onmousedrag =   function() 
                                            if DATA.GUI.buttons.padgrid.val_abs then 
                                              local new = VF_lim(math.floor((1-DATA.GUI.buttons.padgrid.val_abs)*9) ,0,9) 
                                              if new ~= DATA2.tr_extparams_activepad then 
                                                DATA2.tr_extparams_activepad = new 
                                                DATA.GUI.buttons.padgrid_activerect.refresh = true
                                                GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                                GUI_MODULE_DRUMRACKPAD(DATA)  
                                              end
                                            end
                                          end,
                          onmouserelease = function() 
                                            DATA2.tr_extparams_activepad = VF_lim(math.floor((1-DATA.GUI.buttons.padgrid.val_abs)*9) ,0,9) 
                                            DATA.GUI.buttons.padgrid_activerect.refresh = true
                                            GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                            GUI_MODULE_DRUMRACKPAD(DATA)  
                                            DATA2:TrackDataWrite() 
                                          end,
                          }
    GUI_MODULE_PADOVERVIEW_generategrid(DATA)
  end
  -----------------------------------------------------------------------------  
  function GUI_RESERVED_draw_data(DATA, b)
    if not b.data then return end
    if b.data.datatype and b.data.datatype == 'samplepeaks' then GUI_MODULE_SAMPLER_peaks(DATA) end
  end  
  ---------------------------------------------------------------------------------------------------------------------
  function DATA2:ActiveNoteLayer_GetTable()
    local layerspl =  DATA2.tr_extparams_note_active_layer or 1 
    if DATA2.tr_extparams_note_active 
    and DATA2.notes[DATA2.tr_extparams_note_active] 
    and DATA2.notes[DATA2.tr_extparams_note_active].layers 
    and DATA2.notes[DATA2.tr_extparams_note_active].layers[layerspl] then  
    return DATA2.notes[DATA2.tr_extparams_note_active].layers[layerspl],DATA2.tr_extparams_note_active,layerspl end
  end
  ---------------------------------------------------------------------------------------------------------------------
  function DATA2:SAMPLER_GetPeaks()
    local t,note, layer = DATA2:ActiveNoteLayer_GetTable()
    if not (t and t.filepath) then return end
    filepath = t.filepath
    
    local src = PCM_Source_CreateFromFileEx( filepath, true )
    if not src then return end
    
    
    local peakrate = 5000--reaper.GetMediaSourceSampleRate( src )
    local src_len =  GetMediaSourceLength( src )
    if src_len > 15 then return end
    
    local n_spls = math.floor(src_len*peakrate)
    if n_spls < 10 then return end 
    local n_ch = 1
    local want_extra_type = 0--115  -- 's' char
    local buf = new_array(n_spls * n_ch * 2) -- min, max, spectral each chan(but now mono only)
    
    
    local retval =  PCM_Source_GetPeaks(    src, 
                                        peakrate, 
                                        0,--starttime, 
                                        n_ch,--numchannels, 
                                        n_spls, 
                                        want_extra_type, 
                                        buf )
      local spl_cnt  = (retval & 0xfffff)        -- sample_count
      local peaks = {}
      for i=1, spl_cnt, 2 do  peaks[#peaks+1] = buf[i] end --(math.abs(buf[i])+buf[i+1])/2  end
      buf.clear()
      PCM_Source_Destroy( src )
      VF2_NormalizeT(peaks)
      --for i =1, #peaks do peaks[i] = peaks[i]^0.8 end
      
    DATA2.cursplpeaks = {peaks=peaks,
                        src_len=src_len,
                        note=note,
                        layer=layer}
  end 
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_peaks()
    if not (DATA2.cursplpeaks and DATA2.cursplpeaks.peaks) then return end
    
    local note, layer = DATA2.cursplpeaks.note,DATA2.cursplpeaks.layer
    local offs_start = DATA2.notes[note].layers[layer].params_samplestoffs
    local offs_end = DATA2.notes[note].layers[layer].params_sampleendoffs
    
    --msg('GUI_MODULE_SAMPLER_peaks')
    local scaling = DATA.GUI.default_scale
    local x0 = DATA.GUI.buttons.sampler_framepeaks.x*scaling
    local y0 = DATA.GUI.buttons.sampler_framepeaks.y*scaling
    local w = DATA.GUI.buttons.sampler_framepeaks.w*scaling
    local h = DATA.GUI.buttons.sampler_framepeaks.h*scaling
    local peaks = DATA2.cursplpeaks.peaks
    local cnt = #peaks
    local bot = y0+h
    
    -- draw peaks
    local x_dest,y, val,xrel
    gfx.set(1,1,1)
    
    gfx.x = x0
    gfx.y = y0+h/2
    local a_peaks_active = 0.45
    local a_peaks_out = 0.08
    for x = 0, w-1 do 
      xrel = x/w
      if xrel >= offs_start and xrel <=offs_end then gfx.a = a_peaks_active else gfx.a = a_peaks_out end
      x_dest = x0+x
      i = math.floor(VF_lim(cnt * x/w ,1,cnt))
      val = peaks[i]
      gfx.y = y0+h - math.abs(math.floor(val*h))
      --gfx.rect(x_dest,y,1,hrect)
      gfx.lineto(x_dest, y0+h)
    end 
    
    -- draw grid
    local src_len = DATA2.cursplpeaks.src_len
    local txt_font = DATA.GUI.default_txt_font
    local txt_fontsz_out = DATA.GUI.custom_splgridtxtsz
    local txt_fontflags= 0
    local txt_col = '#ffffff'
    local txt_a = 0.7
    local cnt_gridval = 15
    local hgrid = 15
    local hgrid2 = 2
    local calibrated_txt_fontsz = DATA:GUIdraw_txtCalibrateFont(txt_font, txt_fontsz_out, txt_fontflags)
    local step = src_len/cnt_gridval
    local idx = 0
    for pos = 0, src_len-step, step do
      idx = idx + 1
      gfx.setfont(1,txt_font, calibrated_txt_fontsz, txt_fontflags )
      DATA:GUIhex2rgb(txt_col, true)
      local x1 = x0 + math.floor(w*(pos/src_len))
      gfx.a = txt_a
      gfx.x = x1+3
      gfx.y = y0 + gfx.texth*0.5--*1.5
      if idx%4==1 then
        gfx.drawstr(VF_math_Qdec(pos,2))
        gfx.line(x1,y0+hgrid,x1,y0)
       else 
        gfx.line(x1,y0+hgrid2,x1,y0)
      end
      
    end
  end  
  -----------------------------------------------------------------------  
  function DATA2:TrackData_SetRS5kParams(t, param, value)
    local track = t.trackptr
    if not (track  and ValidatePtr2(0,track,'MediaTrack*')) then return end
    local rs5k_pos= t.rs5k_pos
    if type(param)=='number' then
      TrackFX_SetParamNormalized( track, rs5k_pos, param, value ) 
     else
      if type(param)=='string'then 
        if param == 'enabled' then reaper.TrackFX_SetEnabled( track, rs5k_pos, value ) end
      end
    end
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_Loopstate_set(DATA,val)
    local spl_t, note, layer = DATA2:ActiveNoteLayer_GetTable()
    if not spl_t then return end
    if val then
      DATA2:TrackData_SetRS5kParams(spl_t, 12, val) -- set loop on 
      DATA2:TrackDataRead_GetChildrens_GetRS5kParams(spl_t.trackptr, spl_t.rs5k_pos, note,layer)
      GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
      return 
    end
    local backgr_col,backgr_fill
    if spl_t.params_loop == 1 then 
      backgr_col = DATA.GUI.custom_backcol2 backgr_fill=DATA.GUI.custom_backfill2
      DATA.GUI.buttons.sampler_mode1.backgr_col=backgr_col
      DATA.GUI.buttons.sampler_mode1.backgr_fill=backgr_fill
     else
      backgr_col = DATA.GUI.custom_backcol2 backgr_fill=DATA.GUI.custom_backfill2
      DATA.GUI.buttons.sampler_mode2.backgr_col=backgr_col
      DATA.GUI.buttons.sampler_mode2.backgr_fill=backgr_fill
    end
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
    if not DATA.GUI.buttons.sampler_frame then return end
    DATA.GUI.buttons.sampler_mode1 = { x= DATA.GUI.buttons.sampler_frame.x ,
                        y=DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset2,
                        w=DATA.GUI.custom_spl_modew,
                        h=DATA.GUI.custom_spl_modeh-1,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = 'Loop',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        onmouseclick = function() GUI_MODULE_SAMPLER_Section_Loopstate_set(DATA,1) end,
                        } 
    DATA.GUI.buttons.sampler_mode2 = { x= DATA.GUI.buttons.sampler_frame.x,
                        y=DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_modeh+ DATA.GUI.custom_offset2+1 ,
                        w=DATA.GUI.custom_spl_modew,
                        h=DATA.GUI.custom_spl_modeh-2,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        txt = '1-shot',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        onmouseclick = function() GUI_MODULE_SAMPLER_Section_Loopstate_set(DATA,0) end,
                        } 
    GUI_MODULE_SAMPLER_Section_Loopstate_set(DATA)
  end
  ----------------------------------------------------------------------
  function DATA2:ActiveNoteLayer_ShowRS5k(note, layer)
    if not (DATA2.notes and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[layer]) then MB('Sampler not found', '', 0) return end
    
    local track  = DATA2.notes[note].layers[layer].trackptr
    local rs5kpos = DATA2.notes[note].layers[layer].rs5k_pos
    reaper.TrackFX_Show( track, rs5kpos , 3 )
  end
  ----------------------------------------------------------------------
  
  function GUI_MODULE_SAMPLER(DATA)
    
    for key in pairs(DATA.GUI.buttons) do if key:match('sampler_') and key~=sampler_framepeaks then DATA.GUI.buttons[key] = nil end end
    if not DATA2.tr_extparams_showstates or ( DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&4==0) then return end
    
    local x_offs = DATA.GUI.custom_modulex
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&16==16 then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&8==8 then x_offs = x_offs + DATA.GUI.custom_padgridw + DATA.GUI.custom_offset end -- pad view
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&1==1 then x_offs = x_offs + DATA.GUI.custom_padrackW + DATA.GUI.custom_offset end -- drrack
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&2==2 then x_offs = x_offs + DATA.GUI.custom_devicew + DATA.GUI.custom_offset end -- device
    
    -- sample name  
    
      local spl_t, note, layer = DATA2:ActiveNoteLayer_GetTable()
      if not spl_t then return end 
      name = '['..layer..'] '..spl_t.name
     
      DATA.GUI.buttons.sampler_name = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_sampler_namebutw-DATA.GUI.custom_offset2,
                           h=DATA.GUI.custom_infoh,
                           txt = name,
                           }
      DATA.GUI.buttons.sampler_show = { x=x_offs+DATA.GUI.custom_sampler_namebutw,
                           y=0,
                           w=DATA.GUI.custom_sampler_showbutw,
                           h=DATA.GUI.custom_infoh,
                           txt = 'Show',
                           onmouserelease = function() DATA2:ActiveNoteLayer_ShowRS5k(note, layer) end,
                           }                     
                          
      DATA.GUI.buttons.sampler_frame = { x=x_offs,
                            y=DATA.GUI.custom_infoh+DATA.GUI.custom_offset2,
                            w=DATA.GUI.custom_samplerW,
                            h=DATA.GUI.custom_deviceh-DATA.GUI.custom_offset+DATA.GUI.custom_offset2,
                            ignoremouse = true,
                            frame_a =1,
                            frame_col = '#333333',
                            }  
      if not tr_ptr_last or (tr_ptr_last and tr_ptr_last ~= DATA2.tr_ptr) then
        DATA.GUI.buttons.sampler_framepeaks = { x= DATA.GUI.buttons.sampler_frame.x + DATA.GUI.custom_offset2+DATA.GUI.custom_spl_modew,
                            y=DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset2,
                            w=DATA.GUI.custom_sampler_peaksw,
                            h=DATA.GUI.custom_spl_areah,
                            ignoremouse = true,
                            frame_a = DATA.GUI.custom_framea,
                            data = {['datatype'] = 'samplepeaks'},
                            }
      end
    GUI_MODULE_SAMPLER_Section_Loopstate(DATA) 
    GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) 
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs(DATA) 
    DATA2:SAMPLER_GetPeaks() 
  end
  ----------------------------------------------------------------------
  
  function GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) 
    local src_t, note, layer = DATA2:ActiveNoteLayer_GetTable()
    local val_res = 0.03
    local woffs= DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2
    local xoffs= DATA.GUI.buttons.sampler_frame.x
    local yoffs= DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_areah+DATA.GUI.custom_offset2*2
    
    xoffs = xoffs + 0
    GUI_CTRL_Readout(DATA,
      {
        key = 'spl_gain',
        ctrlname = 'Gain',
        val_format_key = 'params_vol_format',
        val = src_t.params_vol,
        paramid = 0,
        val_default = 0.5,
        
        val_res = val_res,
        src_t = src_t,
        x = DATA.GUI.buttons.sampler_frame.x,
        y= yoffs,
        w = DATA.GUI.custom_spl_modew,
        h = DATA.GUI.custom_splctrl_h*2,
        note =note,
        layer=layer
      } )
      
    xoffs = xoffs + woffs
    GUI_CTRL_Readout(DATA,
      {
        key = 'spl_samplestoffs',
        ctrlname = 'Start',
        val_format_key = 'params_samplestoffs_format',
        val = src_t.params_samplestoffs,
        val_max = src_t.params_sampleendoffs,
        val_min = 0,
        paramid = 13,
        val_default = 0,
        
        val_res = val_res,
        src_t = src_t,
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_spl_modew-1,
        h = DATA.GUI.custom_splctrl_h*2,
        note =note,
        layer=layer
      } )  
      
    xoffs = xoffs + woffs
    GUI_CTRL_Readout(DATA,
      {
        key = 'spl_sampleendoffs',
        ctrlname = 'End',
        val_format_key = 'params_sampleendoffs_format',
        val = src_t.params_sampleendoffs,
        val_min = src_t.params_samplestoffs,
        val_max = 1,
        paramid = 14,
        val_default = 1,
        
        val_res = val_res,
        src_t = src_t,
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_spl_modew-1,
        h = DATA.GUI.custom_splctrl_h*2,
        note =note,
        layer=layer
      } )        
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_app(DATA, prefix,key,paramid,src_t,note,layer,val_format_key, val_default)  
    local new_val = DATA.GUI.buttons[prefix..key..'knob'].val
    if val_default then new_val = val_default end
    if not new_val then return end
    DATA2:TrackData_SetRS5kParams(src_t, paramid, new_val)
    DATA2:TrackDataRead_GetChildrens_GetRS5kParams(src_t.trackptr, src_t.rs5k_pos, note,layer)
    DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
    DATA.GUI.buttons[prefix..key..'val'].refresh = true
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,xoffs,val_default)
    local prefix = 'sampler_'
    GUI_CTRL_Knob(DATA,
      {
        prefix = prefix,
        key = key,
        ctrlname = ctrlname,
        val = src_t[param_val],
        val_res = 0.1,
        val_format = DATA2.notes[note].layers[layer][val_format_key],
        --val_res = 0.05,
        src_t = src_t,
        x = DATA.GUI.buttons.sampler_frame.x+(xoffs or 0 ),
        y=DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_areah+DATA.GUI.custom_offset2*3+DATA.GUI.custom_splctrl_h*2,
        w = DATA.GUI.custom_spl_modew,
        h = DATA.GUI.custom_splknob_h,
        note =note,
        layer=layer,
        frame_arcborder=true,
        f= function()     
          local new_val = DATA.GUI.buttons[prefix..key..'knob'].val
          if not new_val then return end
          DATA2:TrackData_SetRS5kParams(src_t, paramid, new_val)
          DATA2:TrackDataRead_GetChildrens_GetRS5kParams(src_t.trackptr, src_t.rs5k_pos, note,layer)
          DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
          DATA.GUI.buttons[prefix..key..'val'].refresh = true   
          DATA2.ONPARAMDRAG = true
        end  ,
        f_release= function()    
          if not DATA2.ONDOUBLECLICK then
            local new_val = DATA.GUI.buttons[prefix..key..'knob'].val
            if not new_val then return end
            DATA2:TrackData_SetRS5kParams(src_t, paramid, new_val)
            DATA2:TrackDataRead_GetChildrens_GetRS5kParams(src_t.trackptr, src_t.rs5k_pos, note,layer)
            DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
            DATA.GUI.buttons[prefix..key..'val'].refresh = true   
            DATA2.ONPARAMDRAG = nil
           else
            DATA2.ONDOUBLECLICK = nil
          end
        end  ,        
        f_double= function() 
          local new_val = val_default
          if not new_val then return end
          DATA2:TrackData_SetRS5kParams(src_t, paramid, new_val)
          DATA2:TrackDataRead_GetChildrens_GetRS5kParams(src_t.trackptr, src_t.rs5k_pos, note,layer)
          DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
          DATA.GUI.buttons[prefix..key..'val'].refresh = true
          DATA2.ONDOUBLECLICK = true
        end  ,
      } )
    end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_EnvelopeKnobs(DATA)   
    local src_t, note, layer = DATA2:ActiveNoteLayer_GetTable()
    
    local paramid = 9
    local key = 'spl_attack'
    local val_format_key = 'params_attack_format'
    local param_val = 'params_attack'
    local ctrlname = 'Attack'
    local val_default = 0 
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val, _, val_default)
    
    local paramid = 24
    local key = 'spl_decay'
    local val_format_key = 'params_decay_format'
    local param_val = 'params_decay'
    local ctrlname = 'Decay'
    local val_default = 0.016010673716664
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2, val_default)
    
    local paramid = 25
    local key = 'spl_sustain'
    local val_format_key = 'params_sustain_format'
    local param_val = 'params_sustain'
    local ctrlname = 'Sustain'
    local val_default = 0.5
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,(DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*2, val_default)
    
    local paramid = 10
    local key = 'spl_release'
    local val_format_key = 'params_release_format'
    local param_val = 'params_release'
    local ctrlname = 'Release'
    local val_default = 0.0005
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,(DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*3, val_default)
  end
  ---------------------------------------------------------------------- 
  
  function GUI_CTRL_Readout(DATA, params_t) 
    local t = params_t
    local note = t.note
    local layer = t.layer
    local val_format_key = t.val_format_key
    DATA.GUI.buttons['sampler_'..t.key..'frame'] = { x= t.x ,
                        y=t.y ,
                        w=t.w,
                        h=t.h,
                        ignoremouse = true,
                        frame_a =DATA.GUI.custom_framea,
                        
                        } 
    DATA.GUI.buttons['sampler_'..t.key..'name'] = { x= t.x+1 ,
                        y=t.y+1 ,
                        w=t.w-2,
                        h=t.h/2,
                        ignoremouse = true,
                        frame_a = 1,
                        frame_col = '#333333',
                        txt = t.ctrlname,
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        } 
    
    DATA.GUI.buttons['sampler_'..t.key..'val'] = { x= t.x +1,
                        y=t.y+t.h/2+1 ,
                        w=t.w-2,
                        h=t.h/2-2,
                        --ignoremouse = true,
                        frame_a = 1,
                        frame_col = '#333333',
                        val = t.val,
                        val_max = t.val_max,
                        val_min = t.val_min,
                        val_res = t.val_res,
                        txt = DATA2.notes[note].layers[layer][val_format_key],
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        onmousedoubleclick = function() 
                                if t.val_default then 
                                  DATA2:TrackData_SetRS5kParams(t.src_t, t.paramid, t.val_default)
                                  DATA2:TrackDataRead_GetChildrens_GetRS5kParams(t.src_t.trackptr, t.src_t.rs5k_pos, note,layer)
                                  DATA.GUI.buttons['sampler_'..t.key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
                                  DATA.GUI.buttons['sampler_'..t.key..'val'].refresh = true
                                  DATA2.ONDOUBLECLICK = true
                                end
                              end,
                        onmousedrag = function()
                              DATA2.ONPARAMDRAG = true
                              local new_val = DATA.GUI.buttons['sampler_'..t.key..'val'].val
                              DATA2:TrackData_SetRS5kParams(t.src_t, t.paramid, new_val)
                              DATA2:TrackDataRead_GetChildrens_GetRS5kParams(t.src_t.trackptr, t.src_t.rs5k_pos, note,layer)
                              DATA.GUI.buttons['sampler_'..t.key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
                              DATA.GUI.buttons['sampler_'..t.key..'val'].refresh = true
                            end,
                        onmouserelease = function()
                              if not DATA2.ONDOUBLECLICK then
                                local new_val = DATA.GUI.buttons['sampler_'..t.key..'val'].val
                                DATA2:TrackData_SetRS5kParams(t.src_t, t.paramid, new_val)
                                DATA2:TrackDataRead_GetChildrens_GetRS5kParams(t.src_t.trackptr, t.src_t.rs5k_pos, note,layer)
                                DATA.GUI.buttons['sampler_'..t.key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
                                DATA.GUI.buttons['sampler_'..t.key..'val'].refresh = true
                                DATA2.ONPARAMDRAG = false
                               else
                                DATA2.ONDOUBLECLICK = nil
                              end
                        end,
                        } 
  end
  --[[local knobw = (DATA.GUI.custom_mainbutw)---DATA.GUI.custom_offset /2  
  if not DATA2.val1 then DATA2.val1 = 0 end
  DATA.GUI.buttons.knob = { x=DATA.GUI.custom_offset*2 + DATA.GUI.custom_mainbutw ,
                        y=DATA.GUI.custom_offset*5 + DATA.GUI.custom_mainbuth*2+DATA.GUI.custom_datah*2,
                        w=knobw,
                        h=DATA.GUI.custom_mainbuth,
                        txt = VF_math_Qdec(DATA2.val1*100,2)..'%',
                        --txt_fontsz = DATA.GUI.default_txt_fontsz,
                        knob_isknob = true,
                        knob_showvalueright = true,
                        val_res = 0.25,
                        val = 0,
                        frame_a = DATA.GUI.default_framea_normal,
                        frame_asel = DATA.GUI.default_framea_normal,
                        back_sela = 0,
                        --hide = DATA.GUI.compactmode==1,
                        --ignoremouse = DATA.GUI.compactmode==1,
                        onmouseclick =    function() DATA2:Quantize() end,
                        onmousedrag =     function() 
                            DATA.GUI.buttons.knob.txt = VF_math_Qdec(DATA2.val1*100,2)..'%'
                            DATA2.val1 = DATA.GUI.buttons.knob.val 
                            if DATA.extstate.CONF_act_appbuttoexecute ==0 then 
                              DATA2:Execute()
                            end 
                          end,
                        onmouserelease  = function() 
                            DATA.GUI.buttons.knob.txt = VF_math_Qdec(DATA2.val1*100,2)..'%'
                            DATA2.val1 = DATA.GUI.buttons.knob.val 
                            if DATA.extstate.CONF_act_appbuttoexecute ==0 then 
                              DATA2:Execute() 
                              Undo_OnStateChange2( 0, 'QuantizeTool' )  
                            end 
                            DATA.GUI.buttons.knob.refresh = true
                          end,
                        onmousereleaseR  = function() 
                          if not DATA2.val1 then DATA2.val1 = 0 end
                          local retval, retvals_csv = GetUserInputs('Align percent', 1, '', VF_math_Qdec(DATA2.val1*100,2)..'%')
                          if not retval then return end
                          retvals_csv = tonumber(retvals_csv)
                          if not retvals_csv then return end
                          
                          DATA2.val1 = VF_lim(retvals_csv/100) 
                          DATA.GUI.buttons.knob.val = DATA2.val1
                          DATA.GUI.buttons.knob.txt = VF_math_Qdec(DATA2.val1*100,2)..'%'
                          if DATA.extstate.CONF_act_appbuttoexecute ==1 then return end
                          DATA2:Execute() 
                          Undo_OnStateChange2( 0, 'QuantizeTool' )  
                        end ,
                        onwheeltrig = function() 
                                        local mult = 0
                                        if not DATA.GUI.wheel_trig then return end
                                        if DATA.GUI.wheel_dir then mult =1 else mult = -1 end
                                        if not DATA2.Quantize_state then DATA2:Quantize()   end
                                        DATA2.val1 = VF_lim(DATA2.val1 - 0.01*mult, 0,1)
                                        DATA.GUI.buttons.knob.txt = 100*VF_math_Qdec(DATA2.val1,2)..'%'
                                        DATA.GUI.buttons.knob.val  = DATA2.val1
                                        if DATA.extstate.CONF_act_appbuttoexecute ==0 then 
                                          DATA2:Execute() 
                                          Undo_OnStateChange2( 0, 'QuantizeTool' )  
                                        end 
                                        DATA.GUI.buttons.knob.refresh = true
                                        
                                      end
                      }]]
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE()
    if DATA.ontrignoteTS and  os.clock() - DATA.ontrignoteTS >3 then StuffMIDIMessage( 0, 0x80, DATA.ontrignote, 0 ) DATA.ontrignoteTS = nil end
    
    -- handle incoming note
    DATA2.recentmsg_trig = false 
    local retval, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
    DATA2.recentmsg = rawmsg
    if DATA2.recentmsg_last and DATA2.recentmsg_last ~= DATA2.recentmsg then 
      DATA2.recentmsg_isNoteOn = rawmsg:byte(1)>>4 == 0x9 
      DATA2.recentmsg_isNoteOff = rawmsg:byte(1)>>4 == 0x8 
      if DATA2.recentmsg_isNoteOn == true then 
        local pitch = rawmsg:byte(2) 
        local vel = rawmsg:byte(3)
        DATA2.playingnote_pitch = pitch
        DATA2.playingnote_vel = vel 
        DATA2.recentmsg_trig = true 
       elseif DATA2.recentmsg_isNoteOff == true then 
        DATA2.playingnote_pitch = nil
        DATA2.recentmsg_trig = true 
      end
    end
    DATA2.recentmsg_last = rawmsg
    
    if DATA2.recentmsg_trig == true  then 
      GUI_MODULE_PADOVERVIEW_generategrid(DATA) -- refresh pad
      GUI_MODULE_DRUMRACKPAD(DATA)  
    end
    
    if DATA2.FORCEONPROJCHANGE == true then DATA_RESERVED_ONPROJCHANGE(DATA) DATA2.FORCEONPROJCHANGE = nil end
  end
  
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.39) if ret then local ret2 = VF_CheckReaperVrs(6.64,true) if ret2 then main() end end
  
  
  
  --[[
    ---------------------------------------------------
    function v2 ExtState_Def()
  
              -- various
              prepareMIDI3 = 0, -->Prepare selected track MIDI input
              pintrack = 0,
              dontaskforcreatingrouting = 0,
              obeynoteoff_default = 1,
              dragtonewtracks = 0,
              draggedfile_fxchain = '',
              --copy_src_media = 0,
              sendnoteoffonrelease = 1,
              closefloat = 0,
              
              -- GUI
              tab = 0,  -- 0-sample browser
              GUI_padfontsz = GUI_fontsz2,
              GUI_splfontsz = GUI_fontsz3,
              GUI_ctrlscale = 1,
              show_wf = 1,
              separate_spl_peak = 0,
              allow_track_notes = 0, -- tracking note with JSFX
              GUIback_R = 1,
              GUIback_G = 1,
              GUIback_B = 1,
              GUIback_A = 0.72,
              
              -- GUI control
              mouse_wheel_res = 960,
              invert_release = 0,
              MM_reset_val = 1, -- &1 double click to reset &2 alt click to reset
              allow_dragpads = 0,
              
              -- Samples
              allow_multiple_spls_per_pad = 0,
              
              -- Pads
              keymode = 0,  -- 0-keys
              keypreview = 1, -- send MIDI by clicking on keys
              oct_shift = -1, -- note names
              start_oct_shift = 2, -- scroll
              key_names2 = '#midipitch #keycsharp |#notename #samplecount |#samplename' ,
              key_names_mixer = '#midipitch #keycsharp |#notename ' ,
              key_names_pat = '#midipitch #keycsharp  #notename ',
              FX_buttons = 255, -- buttons flags
              
              
              -- patterns
              def_steps = 16,
              def_swing = 0,
              patctrl_mode = 0, -- 0 selected 1 all
              randgateprob = 0.5, -- probability
              randvel1=0,
              randvel2 = 1,
              key_width_override = 0,
              def_velocity = 120,
              
              }
      return t
    end  
    
        ---------------------------------------------------   
        func tion v2MOUSE_dragndrop(conf, obj, data, refresh, mouse)
          if not (obj[ mouse.context ] and obj[ mouse.context ].linked_note) then return end
          local note = obj[ mouse.context ].linked_note
          for i = 0, 127-note do
            local DRret, DRstr = gfx.getdropfile(i)
            if DRret == 0 then return end
            if not (IsMediaExtension( DRstr:match('.*%.(.*)'), false ) and not DRstr:lower():match('%.rpp')) then goto skip_spl end
            
            if conf.dragtonewtracks  == 0 then -- force build new track  MIDI send routing
              --if conf.copy_src_media == 1 then DRstr = MoveSourceMedia(DRstr) end
              ExportItemToRS5K(data,conf,refresh,note+i,DRstr)
             else
              --if conf.copy_src_media == 1 then DRstr = MoveSourceMedia(DRstr) end
              local last_spl = ExportItemToRS5K(data,conf,refresh,note+i,DRstr)
              Data_Update(conf, obj, data, refresh, mouse)
              local new_tr = ShowRS5kChain(data, conf, note+i, last_spl)
              if conf.draggedfile_fxchain ~= '' then AddFXChainToTrack(new_tr, conf.draggedfile_fxchain) end
            end 
                      
            ::skip_spl::
          end
          refresh.GUI = true
          refresh.GUI_WF = true
          refresh.data = true  
        end   
        
        ------------------------------------------------------------------------------------------------------
        fu nction v2MOUSE_droppad(conf, obj, data, refresh, mouse)   
              if data.activedroppedpad and conf.tab == 0 then
                if mouse.context_latch:match('keys_p%d+') and data.activedroppedpad:match('keys_p%d+') then
                  local src_note = mouse.context_latch:match('keys_p(%d+)')
                  local dest_note = data.activedroppedpad:match('keys_p(%d+)')
                  if src_note and tonumber(src_note) and dest_note and tonumber(dest_note) then
                    src_note = tonumber(src_note)
                    dest_note = tonumber(dest_note)
                    if data[src_note] then
                      if not mouse.Ctrl_state then
                        for id_spl = 1, #data[src_note] do
                          data[src_note][id_spl].MIDIpitch_normal = dest_note/127
                          SetRS5kData(data, conf, data[src_note][id_spl].src_track, src_note, id_spl)
                        end
                       else
                        for id_spl = 1, #data[src_note] do
                          data[src_note][id_spl].MIDIpitch_normal = dest_note/127
                          SetRS5kData(data, conf, data[src_note][id_spl].src_track, src_note, id_spl, true)
                        end
                      end 
                    end 
                    obj.current_WFkey = dest_note
                    refresh.GUI_WF = true
                  end         
                end
                refresh.data = true  
                data.activedroppedpad = nil
              end       
          end
           fu nction v2MoveSourceMedia(DRstr)
             local buf = reaper.GetProjectPathEx( 0, '' )
             if GetOS():lower():match('win') then
               local spl_name = GetShortSmplName(DRstr) 
               local cmd = 'copy "'..DRstr..'" "'..buf..'/RS5k_samples/'..spl_name..'"'
               cmd = cmd:gsub('\\', '/')
               os.execute(cmd)
               msg(cmd)
               return buf..'/RS5k_samples/'..spl_name
             end
             return DRstr
           end
           ---------------------------------------------------
           func tion v2Choke_Save(conf, data)
             local str = ''
             for i = 1, 127 do
               if not data.choke_t[i] then val = 0 else val = data.choke_t[i] end
               str = str..','..val
             end
             SetProjExtState( 0, conf.ES_key, 'CHOKE', str )
           end
           ---------------------------------------------------
           fun ction v2Choke_Load(conf, data)
             data.choke_t = {}
             local ret, str = GetProjExtState( 0, conf.ES_key, 'CHOKE','') 
             if ret < 1 then 
               for i = 1, 127 do data.choke_t[i] = 0  end
              else
               local i = 0
               for val in str:gmatch('[^,]+') do i = i + 1 data.choke_t[i] = tonumber(val ) end
             end
           end
           ---------------------------------------------------
           fu nction v2Choke_Apply(conf, obj, data, refresh, mouse, pat)
             if not data.jsfxtrack_exist or not data.validate_params then return end
             local max_cnt = 8
             
             -- reset
             for cnt = 0, max_cnt-1 do
               TrackFX_SetParamNormalized( data.parent_track, 0, 1+cnt*2, 0  )
               TrackFX_SetParamNormalized( data.parent_track, 0, 2+cnt*2, 0  )
             end
             
             cnt  = 0
             for i = 1, 127 do
               if cnt+1 >max_cnt then break end
               if data.choke_t[i] > 0 then 
                 TrackFX_SetParamNormalized( data.parent_track, 0, 1+cnt*2, i/128  )
                 TrackFX_SetParamNormalized( data.parent_track, 0, 2+cnt*2, data.choke_t[i] /128  )
                 cnt = cnt + 1
               end
             end
           end
           ---------------------------------------------------
           fu nction v2GetRS5kData(data, tr) 
             local MIDIpitch_lowest
             for fxid = 1,  TrackFX_GetCount( tr ) do
               -- validate RS5k by param names
               local retval, p3 = TrackFX_GetParamName( tr, fxid-1, 3, '' )
               local retval, p4 = TrackFX_GetParamName( tr, fxid-1, 4, '' )
               local isRS5k = retval and p3:match('range')~= nil and p4:match('range')~= nil
               if not isRS5k then goto skipFX end
               data.hasanydata = true
               local MIDIpitch = math.floor(TrackFX_GetParamNormalized( tr, fxid-1, 3)*128) 
               local retval, fn = TrackFX_GetNamedConfigParm( tr, fxid-1, 'FILE' )
               --msg(TrackFX_GetParamNormalized( tr, fxid-1, 3)*128)
               if not data[MIDIpitch] then data[MIDIpitch] = {} end
               local int_col = GetTrackColor( tr )
               if int_col == 0 then int_col = nil end
               local MIDI_name = GetTrackMIDINoteNameEx( 0, tr, MIDIpitch, 0)
               local attack_ms = ({TrackFX_GetFormattedParamValue( tr, fxid-1, 9, '' )})[2]
               if tonumber(attack_ms) >= 1000 then 
                 attack_ms = string.format('%.0f', attack_ms)
                else
                 attack_ms = string.format('%.1f', attack_ms)
               end
               local delay_pos, del, del_ms = TrackFX_AddByName( tr, 'time_adjustment', false, 0 )
               if delay_pos >=0 then  
                 del = TrackFX_GetParamNormalized( tr, delay_pos, 0) 
                 local ms_val = ((del -0.5)*200)
                 if ms_val >= 50 then
                   del_ms = string.format('%.0f',ms_val)..'ms'
                  else
                   del_ms = string.format('%.1f',ms_val)..'ms'
                 end
                else 
                 del = 0.5
                 del_ms = 0
               end
               
               local sample_short = GetShortSmplName(fn)
               local pat_reduceext = '(.*)%.[%a]+'
               if sample_short and sample_short:match(pat_reduceext) then 
                 sample_short = sample_short:match(pat_reduceext) 
                else
                 sample_short = fn
               end      
               if not MIDIpitch_lowest then data.MIDIpitch_lowest = MIDIpitch end
               data[MIDIpitch] [#data[MIDIpitch]+1] = {rs5k_pos = fxid-1,
                                 pitch    =math.floor(({TrackFX_GetFormattedParamValue( tr, fxid-1, 3, '' )})[2]),
                                 MIDIpitch_normal =        TrackFX_GetParamNormalized( tr, fxid-1, 3),
                                 pitch_semitones =    ({TrackFX_GetFormattedParamValue( tr, fxid-1, 15, '' )})[2],
                                 pitch_offset =        TrackFX_GetParamNormalized( tr, fxid-1, 15),
                                 gain=                 TrackFX_GetParamNormalized( tr, fxid-1, 0),
                                 gain_dB =           ({TrackFX_GetFormattedParamValue( tr, fxid-1, 0, '' )})[2],
                                 trackGUID =           GetTrackGUID( tr ),
                                 tr_ptr = tr,
                                 pan=                  TrackFX_GetParamNormalized( tr, fxid-1,1),
                                 attack =              TrackFX_GetParamNormalized( tr, fxid-1,9),
                                 attack_ms =         attack_ms,
                                 decay =              TrackFX_GetParamNormalized( tr, fxid-1,24),
                                 decay_ms =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 24, '' )})[2],  
                                 sust =              TrackFX_GetParamNormalized( tr, fxid-1,25),
                                 sust_dB =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 25, '' )})[2],
                                 rel =              TrackFX_GetParamNormalized( tr, fxid-1,10),
                                 rel_ms =         ({TrackFX_GetFormattedParamValue( tr, fxid-1, 10, '' )})[2],   
                                 sample = fn ,
                                 sample_short =    sample_short,
                                 GUID =            TrackFX_GetFXGUID( tr, fxid-1 ) ,
                                 src_track = tr  ,
                                 src_track_col = int_col,
                                 offset_start =      TrackFX_GetParamNormalized( tr, fxid-1, 13)   ,      
                                 offset_end =      TrackFX_GetParamNormalized( tr, fxid-1, 14)   ,    
                                 bypass_state =    TrackFX_GetEnabled(tr, fxid-1)   , 
                                 MIDI_name =        MIDI_name  ,
                                 obeynoteoff =     TrackFX_GetParamNormalized( tr, fxid-1,11),
                                 del = del,
                                 del_ms = del_ms,
                                 delay_pos=delay_pos,
                                 }
               ::skipFX::
             end  
             
             -- get solo state
             local glob_bypass_state_cnt = 0
             local glob_sol, keys_active_cnt = nil, 0
             for MIDIpitch =0, 128 do
               if data[MIDIpitch] then 
                 keys_active_cnt = keys_active_cnt + 1
                 if data[MIDIpitch][1] and data[MIDIpitch][1].bypass_state == true then
                   glob_bypass_state_cnt  = glob_bypass_state_cnt+1
                   glob_sol = MIDIpitch
                 end        
                 
                 local bypass_state_cnt = 0
                 local sol_spl
                 for spl = 1, #data[MIDIpitch] do
                   if data[MIDIpitch][spl].bypass_state == true then 
                     bypass_state_cnt  = bypass_state_cnt+1
                     sol_spl = spl
                   end
                 end
                 if bypass_state_cnt == 1 and sol_spl and #data[MIDIpitch] > 1 then
                   data[MIDIpitch][sol_spl].solo_state = true
                 end
               end
             end
             if glob_bypass_state_cnt == 1 and glob_sol and keys_active_cnt > 1 then  data[glob_sol].solo_state = true end
             
             -- get common gain
             for MIDIpitch =0, 128 do
               if data[MIDIpitch] then  
                 local com_gain,com_pan = 0  ,0 
                 for spl = 1, #data[MIDIpitch] do
                   com_gain = com_gain + data[MIDIpitch][spl].gain
                   com_pan = com_pan + data[MIDIpitch][spl].pan
                 end
                 data[MIDIpitch].com_gain = lim(com_gain/#data[MIDIpitch],0,2)
                 data[MIDIpitch].com_pan = lim(com_pan/#data[MIDIpitch],0,1)
               end
             end      
             
             --collect FX data
             local FXChaindata = GetRS5kData_FX(tr)
             for note in pairs(data) do
               if tonumber(note) then
                 for spl in pairs(data[note]) do
                   if tonumber(spl) then
                     if data[note][spl].tr_ptr == tr then
                       data[note].FXChaindata = FXChaindata -- forced to note levelinstead of data[note][spl]
                     end
                   end
                 end
               end    
             end
           end
           ---------------------------------------------------
           ---------------------------------------------------
           fu nction v2SearchSample(fn, dir_next )
             fn = fn:gsub('\\', '/')
             local path = fn:reverse():match('[%/]+.*'):reverse():sub(0,-2)
             local cur_file =     fn:reverse():match('.-[%/]'):reverse():sub(2)
             -- get files list
               local files = {}
               local i = 0
               repeat
               local file = reaper.EnumerateFiles( path, i )
               if file then
                 if IsMediaExtension( file:match('.*%.(.*)'), false ) and not file:lower():match('%.rpp') then files[#files+1] = file end
               end
               i = i+1
               until file == nil
               
             -- search file list
               local trig_file
               if #files < 2 then return fn end
               local i_st, i_end, i_step, i_coeff, i_ret
               if dir_next then 
               i_st = 2
               i_end = #files
               i_step = 1
               i_coeff = -1
               i_ret = 1
               else
               i_st = #files-1
               i_end = 1
               i_step = -1
               i_coeff = 1
               i_ret = #files
               end
               for i = i_st,i_end,i_step   do
                 if files[i+1*i_coeff] == cur_file then 
                   trig_file = path..'/'..files[i] 
                   break 
                  elseif i == i_end then trig_file = path..'/'..files[i_ret] 
                 end
               end  
             return trig_file
           end
           ---------------------------------------------------
           f nction v2SetRS5kData(data, conf, track, note, spl_id, add_new_data_entry, force_delay) 
             if not spl_id then spl_id = 1 end
             if data[note][spl_id] then 
                 local rs5k_pos = data[note][spl_id].rs5k_pos
                 if add_new_data_entry then 
                   rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )  
                 end              
                 TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', data[note][spl_id].sample)
                 TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')  
                 TrackFX_SetParamNormalized( track, rs5k_pos, 0, lim(data[note][spl_id].gain,0,2)) -- gain
                 TrackFX_SetParamNormalized( track, rs5k_pos, 1, data[note][spl_id].pan) -- pan
                 
                 TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
                 TrackFX_SetParamNormalized( track, rs5k_pos, 4, data[note][spl_id].MIDIpitch_normal) -- note range start
                 TrackFX_SetParamNormalized( track, rs5k_pos, 3, data[note][spl_id].MIDIpitch_normal) -- note range end
                 TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
                 TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
                 TrackFX_SetParamNormalized( track, rs5k_pos, 15, data[note][spl_id].pitch_offset)
                 
                 TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
                 TrackFX_SetParamNormalized( track, rs5k_pos, 11, data[note][spl_id].obeynoteoff ) -- obey note offs
                         
                 TrackFX_SetParamNormalized( track, rs5k_pos, 9, data[note][spl_id].attack ) -- adsr
                 TrackFX_SetParamNormalized( track, rs5k_pos, 24, data[note][spl_id].decay )
                 TrackFX_SetParamNormalized( track, rs5k_pos, 25, data[note][spl_id].sust )
                 TrackFX_SetParamNormalized( track, rs5k_pos, 10, data[note][spl_id].rel )
                 
                 TrackFX_SetParamNormalized( track, rs5k_pos, 13, lim(data[note][spl_id].offset_start, 0, data[note][spl_id].offset_end ) )
                 TrackFX_SetParamNormalized( track, rs5k_pos, 14, lim(data[note][spl_id].offset_end,   data[note][spl_id].offset_start, 1 )  )
                 TrackFX_SetEnabled(track, rs5k_pos, data[note][spl_id].bypass_state)
                 
                 if force_delay == true and track ~= data.parent_track then  
                   local delay_pos = TrackFX_AddByName( track, 'time_adjustment', false, 1 )
                   if delay_pos >=0 then 
                     data[note][spl_id].delay_pos = delay_pos
                     local del_val = 0.5
                     if data[note][spl_id].del then del_val = data[note][spl_id].del end
                     TrackFX_SetParamNormalized( track, delay_pos, 0, del_val)
                   end
                 end
               end
           end  
           ---------------------------------------------------
           fun ction v2MIDI_prepare(data, conf, mode_override)
             local tr = GetSelectedTrack(0,0)
             if not tr then return end
             if mode_override == 0  then -- VK
               SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+(62<<5) )-- VK
              else
               SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+(63<<5) ) -- all 
             end
             SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
             SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track 
             SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
           end
           ------------------------------------------------------------------------
           fun ction v2ExplodeRS5K_Extract_rs5k_tChunks(tr)
             local _, chunk = GetTrackStateChunk(tr, '', false)
             local t = {}
             for fx_chunk in chunk:gmatch('BYPASS(.-)WAK') do 
               if fx_chunk:match('<(.*)') and fx_chunk:match('<(.*)'):match('reasamplomatic.dll') then 
                 t[#t+1] = 'BYPASS 0 0 0\n<'..fx_chunk:match('<(.*)') ..'WAK 0'
               end
             end
             return t
           end
             ------------------------------------------------------------------------  
             fu nction v2ExplodeRS5K_AddChunkToTrack(tr, chunk) -- add empty fx chain chunk if not exists
               local _, chunk_ch = GetTrackStateChunk(tr, '', false)
               -- add fxchain if not exists
               if not chunk_ch:match('FXCHAIN') then 
                 chunk_ch = chunk_ch:sub(0,-3)..[=[
           <FXCHAIN
           SHOW 0
           LASTSEL 0
           DOCKED 0
           >
           >]=]
               end
               if chunk then chunk_ch = chunk_ch:gsub('DOCKED %d', chunk) end
               SetTrackStateChunk(tr, chunk_ch, false)
             end
             ------------------------------------------------------------------------  
             f unction v2ExplodeRS5K_RenameTrAsFirstInstance(track)
               if not track then return end
               local fx_count =  TrackFX_GetCount(track)
               if fx_count >= 1 then
                 local retval, fx_name =  TrackFX_GetFXName(track, 0, '')      
                 local fx_name_cut = fx_name:match(': (.*)')
                 if fx_name_cut then fx_name = fx_name_cut end
                 GetSetMediaTrackInfo_String(track, 'P_NAME', fx_name, true)
               end
             end
           ------------------------------------------------------------------------  
           fu nction v2ExplodeRS5K_main(tr)
             if tr then 
               local tr_id = CSurf_TrackToID( tr,false )
               SetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH', 1 )
               Undo_BeginBlock2( 0 )      
               local ch = ExplodeRS5K_Extract_rs5k_tChunks(tr)
               if ch and #ch > 0 then 
                 for i = #ch, 1, -1 do 
                   InsertTrackAtIndex( tr_id, false )
                   local child_tr = GetTrack(0,tr_id)
                   ExplodeRS5K_AddChunkToTrack(child_tr, ch[i])
                   ExplodeRS5K_RenameTrAsFirstInstance(child_tr)
                   local ch_depth if i == #ch then ch_depth = -1 else ch_depth = 0 end
                   SetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH', ch_depth )
                   SetMediaTrackInfo_Value( child_tr, 'I_FOLDERCOMPACT', 1 ) 
                 end
               end
               SetOnlyTrackSelected( tr )
               Main_OnCommand(40535,0 ) -- Track: Set all FX offline for selected tracks
               Undo_EndBlock2( 0, 'Explode selected track RS5k instances to new tracks', 0 )
             end
           end     
           -----------------------------------------------------------------------
           fu nction v2SetFXName(track, fx, new_name)
             if not new_name then return end
             local edited_line,edited_line_id, segm
             -- get ref guid
               if not track or not tonumber(fx) then return end
               local FX_GUID = reaper.TrackFX_GetFXGUID( track, fx )
               if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
               local plug_type = reaper.TrackFX_GetIOSize( track, fx )
             -- get chunk t
               local _, chunk = reaper.GetTrackStateChunk( track, '', false )
               local t = {} for line in chunk:gmatch("[^\r\n]+") do t[#t+1] = line end
             -- find edit line
               local search
               for i = #t, 1, -1 do
                 local t_check = t[i]:gsub('-','')
                 if t_check:find(FX_GUID) then search = true  end
                 if t[i]:find('<') and search and not t[i]:find('JS_SER') then
                   edited_line = t[i]:sub(2)
                   edited_line_id = i
                   break
                 end
               end
             -- parse line
               if not edited_line then return end
               local t1 = {}
               for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
               local t2 = {}
               for i = 1, #t1 do
                 segm = t1[i]
                 if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
                 if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
               end
           
               if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
               if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST
           
               local out_line = table.concat(t2,' ')
               t[edited_line_id] = '<'..out_line
               local out_chunk = table.concat(t,'\n')
               --msg(out_chunk)
               reaper.SetTrackStateChunk( track, out_chunk, false )
               reaper.UpdateArrange()
           end
         
           ---------------------------------------------------
           f unction v2ExportItemToRS5K(data,conf,refresh,note,filepath, start_offs, end_offs)
             if not data.parent_track or not note or not filepath then return end
             local track = data.parent_track
             local val
             
             if data[note] and data[note][1] then 
               track = data[note][1].src_track
               if conf.allow_multiple_spls_per_pad == 0 then
                 TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'FILE0', filepath)
                 TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'DONE', '')
                 val= 1
                 goto rename_note 
                else
                 ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)  
                 val= #data[note]+1
                 goto rename_note               
               end
              else
                ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
                val= 1
                goto rename_note
             end
             
             ::rename_note::
             -- rename note in ME
               local MIDI_notename = GetShortSmplName(filepath)
               if MIDI_notename and MIDI_notename ~= '' and track then
                 MIDI_notename = MIDI_notename:match('(.*)%.')
                   SetTrackMIDINoteNameEx( 0, track, note, 0, MIDI_notename)
                   SetTrackMIDINoteNameEx( 0,track, note, 0, MIDI_notename)
               end
             
             return val
             
           end
           ----------------------------------------------------------------------- 
           fu nction v2ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
             local last_inst
             for fx = 1, TrackFX_GetCount( track ) do
               local retval, buf = TrackFX_GetFXName( track, fx-1, '' )
               if buf:match('RS5K') or buf:match('ReaSamplomatic5000') then
                 last_inst = fx-1
               end
             end
             local rs5k_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
             if conf.closefloat == 1 then reaper.TrackFX_Show( track, rs5k_pos, -2 ) end
             if last_inst then 
               TrackFX_CopyToTrack( track, rs5k_pos, track, last_inst+1,true )
               rs5k_pos = last_inst+1
             end
             TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', filepath)
             TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')      
             TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
             TrackFX_SetParamNormalized( track, rs5k_pos, 3, note/127 ) -- note range start
             TrackFX_SetParamNormalized( track, rs5k_pos, 4, note/127 ) -- note range end
             TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
             TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
             TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
             TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
             TrackFX_SetParamNormalized( track, rs5k_pos, 11, conf.obeynoteoff_default ) -- obey note offs
             if start_offs and end_offs then
               TrackFX_SetParamNormalized( track, rs5k_pos, 13, start_offs ) -- attack
               TrackFX_SetParamNormalized( track, rs5k_pos, 14, end_offs )   
             end  
           end
           -- --------------------------------------------------------------------- 
           fun ction v2ShowRS5kChain(data, conf, note, spl)
             if not data[note] or not data[note][1] then return end
             if not spl then spl = 1 end
             if not data[note][spl] then return end
             if data[note][spl].src_track == data.parent_track then
               local ret_com
               if conf.dontaskforcreatingrouting == 1 then 
                 ret_com = true 
                else
                 local ret = MB('Create MIDI send routing for this sample?', conf.scr_title, 4)
                 if ret == 6  then ret_com = true  end
               end
               if ret_com then
                 Undo_BeginBlock()                          
                   local tr_id = CSurf_TrackToID( data.parent_track, false )
                   InsertTrackAtIndex( tr_id, true)
                   local new_tr = CSurf_TrackFromID( tr_id+1, false )
                   local send_id = CreateTrackSend( data.parent_track, new_tr)
                   SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_SRCCHAN' , -1 )
                   SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_DSTCHAN' , 0 )
                   SetTrackSendInfo_Value( data.parent_track, 0, send_id, 'I_MIDIFLAGS' , 0 )
                   SNM_MoveOrRemoveTrackFX( data.parent_track, data[note][spl].rs5k_pos, 0 )
                   SetRS5kData(data, conf, new_tr, note, spl, true)
                   GetSetMediaTrackInfo_String( new_tr, 'P_NAME', data[note][spl].sample_short, 1 )
                   TrackList_AdjustWindows( false )
                   TrackFX_Show( new_tr, 0, 1 )
                 Undo_EndBlock( 'Build RS5k MIDI routing for note '..note..' sample '..spl, 0 )
                 return new_tr
                 
               end
              else
               TrackFX_Show( data[note][spl].src_track, 0, 1 )
             end
           end
           
           ----------------------------------------------------------------------- 
           
           fu nction v2AddFXChainToTrack_ExtractBlock(str)
             local s = ''
             local count = 1
             count_lines = 0
             for line in str:gmatch('[^\n]+') do
               count_lines = count_lines + 1
               s = s..'\n'..line
               if line:find('<') then count = count +1 end
               if line:find('>') then count = count -1 end 
               if count == 1 then return s, count_lines end     
             end
           end   
           f unction v2AddFXChainToTrack(track, chain_fp)
             -- get some chain file, ex. from GetUserFileForRead()
               local file = io.open(chain_fp)
               if not file then return end
               local external_FX_chain_content = file:read('a')
               file:close()  
         
             -- get track chunk
               local chunk = eugen27771_GetObjStateChunk(track) 
               if not chunk then return end   
             -- split chunk by lines into table
               local t = {} 
               for line in chunk:gmatch('[^\n]+') do       if line:find('<FXCHAIN') then fx_chain_id0 = #t end       t[#t+1] = line     end 
             --  find size of FX chain and where it placed
               local _, cnt_lines = AddFXChainToTrack_ExtractBlock(chunk:match('<FXCHAIN.*'))
               local fx_chain_id1 = fx_chain_id0 + cnt_lines -1
             -- insert FX chain
               local new_chunk = table.concat(t,'\n',  1, fx_chain_id1)..'\n'..
                         external_FX_chain_content..
                         table.concat(t,'\n',  fx_chain_id1)     
             -- apply new chunk                
               SetTrackStateChunk(track, new_chunk, false) 
           end
             
             
           
             ---------------------------------------------------
               unction v2BuildKeyName(conf, data, note, str)
               if not str then return "" end
               --------
               str = str:gsub('#midipitch', note)
               --------
               local ntname = GetNoteStr(conf, note, 0)
               if not ntname then ntname = '' end
               str = str:gsub('#keycsharp ', ntname)
               local ntname2 = GetNoteStr(conf, note, 7)
               if not ntname2 then ntname2 = '' end
               str = str:gsub('#keycsharpRU ', ntname2)
               --------
               if data[note] and data[note][1] and data[note][1].MIDI_name and data[note][1].MIDI_name ~= '' then 
                 str = str:gsub('#notename', data[note][1].MIDI_name) 
                else 
                 str = str:gsub('#notename', '')
               end
               --------
               if data[note] then 
                 str = str:gsub('#samplecount', '('..#data[note]..')') else str = str:gsub('#samplecount', '')
               end 
               --------
               local spls = ''
               if data[note] and #data[note] >= 1 then
                 for spl = 1, #data[note] do
                   spls = spls..data[note][spl].sample_short..'\n'
                 end
               end
               str = str:gsub('#samplename', spls)
               --------
               str = str:gsub('|  |', '|')
               str = str:gsub('|', '\n')
               --------
           
               
               return str
           
               
             end
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
               ---------------------------------------------------
               f unction v2OBJ_GenKeys(conf, obj, data, refresh, mouse) 
                 local shifts,w_div ,h_div = OBJ_Layouts(conf, obj, data, refresh, mouse)
                 local WF_shift = 0
                 if conf.show_wf == 1 and conf.separate_spl_peak == 1 then WF_shift = obj.WF_h end
                 local key_area_h = gfx.h -obj.kn_h-obj.samplename_h-WF_shift
                 local key_w = math.ceil((gfx.w-3*obj.offs-obj.keycntrlarea_w)/w_div)
                 local key_h = math.ceil((1/h_div)*(key_area_h)) 
                 obj.h_div = h_div
                 for i = 1, #shifts do
                   local id = i-1+conf.oct_shift*12
                   local start_oct_shift = conf.start_oct_shift
                   if conf.keymode == 8 or conf.keymode == 9 then start_oct_shift = 0 end
                   local note = (i-1)+12*conf.oct_shift+start_oct_shift*12
                   local col = 'white'
                   local colint, colint0
                   
                   local alpha_back
                   if  data[note] and data[note][1] then 
                     alpha_back = 0.6       
                     col = 'green'
                     if data[note][1].src_track_col then colint = data[note][1].src_track_col  end    
                    else
                     alpha_back = 0.15 
                   end
           
                     local txt = BuildKeyName(conf, data, note, conf.key_names2)
                     
                     if  key_w < obj.fx_rect_side*2.5 or key_h < obj.fx_rect_side*2.8 then txt = note end
                     if  key_w < obj.fx_rect_side*1.5 or key_h < obj.fx_rect_side*1.5 then txt = '' end
                     if note >= 0 and note <= 127 then
                       local key_xpos = obj.keycntrlarea_w + shifts[i][1]*key_w  + 2
                       local key_ypos = gfx.h-key_area_h+ shifts[i][2]*key_h
                       OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, note, key_xpos, key_ypos, key_w, key_h )
                       -------------------------
                       -- keys
                       local draw_drop_line if data.activedroppedpad and data.activedroppedpad == 'keys_p'..note then draw_drop_line = true end
                       local a_frame,selection_tri = 0.05 
                       if obj.current_WFkey and note == obj.current_WFkey then
                         a_frame =obj.sel_key_frame
                         selection_tri = true
                       end
                       obj['keys_p'..note] = 
                                 { clear = true,
                                   draw_drop_line = draw_drop_line,
                                   drop_line_text = data.activedroppedpad_action,
                                   x = key_xpos,
                                   y = key_ypos,
                                   w = key_w-1,
                                   h = key_h,
                                   col = col,
                                   colint = colint,
                                   state = 0,
                                   txt= txt,
                                   limtxtw = obj.fx_rect_side,
                                   is_step = true,
                                   --vertical_txt = fn,
                                   linked_note = note,
                                   show = true,
                                   is_but = true,
                                   alpha_back = alpha_back,
                                   selection_tri=selection_tri,
                                   a_frame = a_frame,
                                   aligh_txt = 5,
                                   fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,
                                   func =  function() 
                                             SetProjExtState( 0, 'MPLRS5KMANAGEFUNC', 'LASTNOTERS5KMAN', note )
                                             if not data.hasanydata then return end
                                             data.current_spl_peaks = nil
                                             if conf.keypreview == 1 then  msg(1)StuffMIDIMessage( 0, '0x9'..string.format("%x", 0), note,100) end                                  
                                             if obj.current_WFkey ~= note then 
                                               obj.current_WFspl = 1                                   
                                               obj.current_WFkey = note
                                             end
                                             
                                             refresh.GUI_WF = true  
                                             refresh.GUI = true     
                                           end,
                                   func_R =  function ()
                                               if not data[note] then return end
                                               Menu(mouse, { { str =   'Float linked FX',
                                                               func =  function()
                                                                         if data[note] then
                                                                           for spl = 1, #data[note] do
                                                                             -- TrackFX_SetOpen(  data[note][1].src_track, data[note][1].rs5k_pos, true )
                                                                             TrackFX_Show( data[note][spl].src_track, data[note][spl].rs5k_pos,3 )
                                                                           end
                                                                         end
                                                                       end},
                                                               { str =   'Show linked FX chain',
                                                               func =  function()
                                                                         if data[note] then
                                                                           for spl = 1, #data[note] do
                                                                             -- TrackFX_SetOpen(  data[note][1].src_track, data[note][1].rs5k_pos, true )
                                                                             TrackFX_Show( data[note][spl].src_track, data[note][spl].rs5k_pos,1 )
                                                                           end
                                                                         end
                                                                       end},                                                            
                                                             { str =   'Rename linked MIDI note',
                                                               func =  function()
                                                                         local MIDI_name = GetTrackMIDINoteNameEx( 0, data[note][1].src_track, note, 1)
                                                                         local ret, MIDI_name_ret = reaper.GetUserInputs( conf.scr_title, 1, 'Rename MIDI note,extrawidth=200', MIDI_name )
                                                                         if ret then
                                                                           SetTrackMIDINoteNameEx( 0, data[note][1].src_track, note, 0, MIDI_name_ret)
                                                                           SetTrackMIDINoteNameEx( 0, data.parent_track, note, 0, MIDI_name_ret)
                                                                         end
                                                                       end},
                                                             { str =   'Remove pad content',
                                                               func =  function()
                                                                         for spl = #data[note], 1, -1 do
                                                                           SNM_MoveOrRemoveTrackFX( data[note][spl].src_track, data[note][spl].rs5k_pos, 0 )
                                                                         end
                                                                       end},                                                            
                                                           
                                                           })
                                               obj.current_WFkey = nil
                                               obj.current_WFspl = nil
                                               refresh.GUI_WF = true  
                                               refresh.GUI = true  
                                               refresh.data = true                                  
                                             end,
                                   func_DC = function()
                                               
                                             end,
                                            
                                           } 
                       if    note%12 == 1 
                         or  note%12 == 3 
                         or  note%12 == 6 
                         or  note%12 == 8 
                         or  note%12 == 10 
                         then obj['keys_p'..note].txt_col = 'black' 
                       end
                         
                         
                   end
                 end
               
                 
               end
             ---------------------------------------------------------
             fu nction v2OBJ_Menu(conf, obj, data, refresh, mouse)
               local fx_per_pad if conf.allow_multiple_spls_per_pad == 1 then fx_per_pad = '#' else fx_per_pad = '' end
               -- ask pinned tr
                 local ret, trGUID = GetProjExtState( 0, 'MPLRS5KMANAGE', 'PINNEDTR' )
                 local pinnedtr = BR_GetMediaTrackByGUID( 0, trGUID )
                 local pinnedtr_str = '(none)' 
                 if pinnedtr then 
                   _, pinnedtr_str = GetTrackName( pinnedtr, '' )
                 end
                 
               -- 
                 local wf_active = conf.show_wf == 0  
                 if wf_active then wf_active = '#' else wf_active = '' end
                 
                 local tr_extparams_note_active = gmem_attach
                 if tr_extparams_note_active then tr_extparams_note_active = '' else tr_extparams_note_active = '#' end
                 
                   obj.menu = { clear = true,
                               x = 0,
                               y = 0,
                               w = obj.keycntrlarea_w,
                               h = obj.kn_h+obj.samplename_h-1,
                               col = 'white',
                               state = fale,
                               txt= '>',
                               show = true,
                               is_but = true,
                               mouse_overlay = true,
                               fontsz = obj.GUI_fontsz,
                               alpha_back = obj.it_alpha5,
                               a_frame = 0,
                               func =  function() 
                                         Menu(mouse,               
           {
             { str = conf.scr_title..' '..conf.vrs,
               hidden = true
             },
             { str = '|#Links / Info'},
             { str = 'Donate to MPL',
               func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
             { str = 'Cockos Forum thread',
               func = function() Open_URL('http://forum.cockos.com/showthread.php?t=207971') end  } , 
             { str = 'YouTube overview by Jon Tidey (REAPER Blog)|',
               func = function() Open_URL('http://www.youtube.com/watch?v=clucnX0WWXc') end  } ,     
               
             { str = '#Options'},    
             
             
               
             { str = '>Key options',  
               menu_inc = true},
             { str = '>Key controls', menu_inc = true},
             { str = fx_per_pad..'FX',  
               state = conf.FX_buttons&(1<<2) == (1<<2),
               func =  function() 
                         local ret = BinaryCheck(conf.FX_buttons, 2)
                         conf.FX_buttons = ret
                       end ,
             },
             { str = 'Solo (bypass all except current)',  
               state = conf.FX_buttons&(1<<4) == (1<<4),
               func =  function() 
                         local ret = BinaryCheck(conf.FX_buttons, 4)
                         conf.FX_buttons = ret
                       end ,
             },
             { str = 'Mute (bypass)|<',  
               state = conf.FX_buttons&(1<<3) == (1<<3),
               func =  function() 
                         local ret = BinaryCheck(conf.FX_buttons, 3)
                         conf.FX_buttons = ret
                       end ,
             },
             { str = '>Key names'},  
             { str = 'Reset to defaults',
               func = function() 
                         conf.key_names2 = '#midipitch #keycsharp |#notename #samplecount |#samplename'  
                         conf.key_names_mixer = '#midipitch #keycsharp |#notename '  
                         conf.key_names_pat   = '#midipitch #keycsharp  #notename '      
                       end},  
             { str = 'Edit keyname hashtags (pads)',
               func = function() 
                         local ret = GetInput( conf, 'Keyname hashtags', conf.key_names2, _, 400, true) 
                         if ret then  
                           conf.key_names2 = ret 
                         end             
                       end},  
             { str = 'Edit keyname hashtags (mixer)',
               func = function() 
                         local ret = GetInput( conf, 'Mixer keyname hashtags', conf.key_names_mixer, _, 400, true) 
                         if ret then  
                           conf.key_names_mixer = ret 
                         end             
                       end},  
             { str = 'Edit keyname hashtags (pattern)',
               func = function() 
                         local ret = GetInput( conf, 'Pattern keyname hashtags', conf.key_names_pat, _, 400, true) 
                         if ret then  
                           conf.key_names_pat = ret 
                         end             
                       end},             
                                   
             { str = 'Keyname hashtag reference',
               func = function() 
                         msg([[
           List of available hashtags:
           
           #midipitch
           #keycsharp - formatted as C#5
           #keycsharpRU
           #notename - note name in MIDI Editor
           #samplecount - return count of samples linked to current note in parentheses
           #samplename - return sample names linked to current note, separated by new line
           | - new line
           ] ]
            )       
                       end},                       
             { str = '|Visual octave shift: '..conf.oct_shift..'oct|<',
               func = function() 
                         ret = GetInput( conf, 'Visual octave shift', conf.oct_shift,true) 
                         if ret then  conf.oct_shift = ret  end end,
             } ,
             
             { str = '>Layouts'},
             { str = 'Chromatic Keys',
               func = function() conf.keymode = 0 end ,
               state = conf.keymode == 0},
             { str = 'Chromatic Keys (2 oct)',
               func = function() conf.keymode = 1 end ,
               state = conf.keymode == 1},
             { str = 'Korg NanoPad (8x2)',
               func = function() conf.keymode = 2 end ,
               state = conf.keymode == 2},
             { str = 'Ableton Live Drum Rack / S1 Impact (4x4)',
               func = function() conf.keymode = 3 end ,
               state = conf.keymode == 3 or conf.keymode == 4},
             { str = 'Ableton Push (8x8)',
               func = function() conf.keymode = 5 end ,
               state = conf.keymode == 5},    
               { str = '8x8 segmented',
                 func = function() conf.keymode = 6 end ,
                 state = conf.keymode == 6}, 
               { str = '8x8 vertical',
                 func = function() conf.keymode = 7 end ,
                 state = conf.keymode == 7},   
               { str = 'All keys from bottom to the top',
                 func = function() conf.keymode = 9 end ,
                 state = conf.keymode == 9},           
               { str = 'All keys from top to the bottom|<|',
                 func = function() conf.keymode = 8 end ,
                 state = conf.keymode == 8},       
                   
             { str = 'Send MIDI by clicking on keys',
               func = function() conf.keypreview = math.abs(1-conf.keypreview)  end ,
               state = conf.keypreview == 1},  
             { str = 'Send MIDI noteoff on mouse release (leave notes unclosed!)|<',
               func = function() conf.sendnoteoffonrelease = math.abs(1-conf.sendnoteoffonrelease)  end ,
               state = conf.sendnoteoffonrelease == 1},      
                
           
           
             { str = '>RS5k controls'},
             { str = 'Invert mouse for release',  
               state = conf.invert_release == 1,
               func =  function() conf.invert_release = math.abs(1-conf.invert_release)  end ,
             },  
             { str = 'Obey noteOff enabled by default|<',  
               state = conf.obeynoteoff_default == 1,
               func =  function() conf.obeynoteoff_default = math.abs(1-conf.obeynoteoff_default)  end ,
             },    
             
             
           
             { str = '>Mouse Modifiers'},
             { str = 'Doubleclick reset value (Pad and Mixer tabs only)',  
               state = conf.MM_reset_val&(1<<0) == (1<<0),
               func =  function() 
                         local ret = BinaryCheck(conf.MM_reset_val, 0)
                         conf.MM_reset_val = ret
                       end ,},   
             { str = 'Alt+Click reset value',  
               state = conf.MM_reset_val&(1<<1) == (1<<1),
               func =  function() 
                         local ret = BinaryCheck(conf.MM_reset_val, 1)
                         conf.MM_reset_val = ret
                       end }, 
             { str = 'Allow pads drag to copy/move|<',  
               state = conf.allow_dragpads&1==1,
               func =  function() 
                         conf.allow_dragpads = math.abs(1-conf.allow_dragpads)
                       end },             
                       
             
           

             { str = 'Use custom FX chain for newly dragged samples '..conf.draggedfile_fxchain..'|<',
               func =  function() 
                         if conf.draggedfile_fxchain ~= '' then conf.draggedfile_fxchain = '' return end
                         local retval, fp = GetUserFileNameForRead('', 'FX chain for newly dragged samples', 'RfxChain')
                         if retval then 
                           conf.draggedfile_fxchain =  fp
                         end
                       end,
               state = conf.draggedfile_fxchain ~= '',
             } ,   


               

      ]]