-- @description RS5k manager
-- @version 3.0beta15
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic5000 data on group of connected tracks
-- @provides
--    mpl_RS5k manager_MacroControls.jsfx
-- @changelog
--    # Sample: fix oneshot/loop selector
--    + Sampler: onshot deactivates obey note-off [https://forum.cockos.com/showpost.php?p=2601997&postcount=340]
--    + Sampler: click on peaks trigger note
--    + Device: doubleclick on pan reset pan
--    # Device: correctly reset visual values on doubleclick


--[[ 
3.0beta15 13.10.2022
--    # Sample: fix oneshot/loop selector
--    + Sampler: onshot deactivates obey note-off [https://forum.cockos.com/showpost.php?p=2601997&postcount=340]
--    + Sampler: click on peaks trigger note
--    + Device: doubleclick on pan reset pan
--    # Device: correctly reset visual values on doubleclick

3.0beta14 12.10.2022
--    # DrumRack: fix mute/solo/showME errors
--    # Sample: decrease resolution
--    + Sampler: add drive knob
--    # Sampler: fix error on empty drive knob

3.0beta12 07.10.202
--    + Write version to parent, children, MIDI bus for further developement and removing backward compatibility errors
--    + DrumRack: rename pads
--    + When drop FX, rename its newly created track to short name if possible
--    + Device: solo layers
--    + Device: mute layers
--    # Device: use track name as layer name
--    + Guess params: add 'att,dec,sus,rel,tun'
--    + Guess params: rename params on UI if guessed

3.0beta11 06.10.2022
--    # refresh peaks follow sampler refresh / at note input if enabled
--    + Allow to enter params even for external plugins by right click

3.0beta10 05.10.2022
--    # Defaults: use play button is off by default
--    # fix error on empty readout
--    + Sampler: add pitch offset
--    + Sampler: look up for pitch offset for plugin parameter
--    # Sampler: fix error on drop sample onto peaks
--    # DrumRack: another fix for not updating pads when input note is triggered

3.0alpha8/9 03.10.2022
--    # fix error at empty rack on click pad
--    # fix update DrumRack when 'Incoming note trigger active pad' enabled
--    # Structure: validate note by ext state, this will potentially allow to move intrument track whenever in the rack chain
--    # Structure: validate instrument by ext state FXGUID, this will potentially allow to use custom plugins before main instrument
--    + Add support for nonRS5k instruments (drop from FX browser, require REAPER6.68+dev1003)
--    + Lookup plugin parameters for adsr envelope controls, gain
--    + Add stock midi filter with pre-set incoming MIDI note limits for nonRS5k instruments
--    # Fix error on clear pad
--    + Clear pad select parent track

3.0alpha6/7 02.10.2022
--    + Settings: click on pad select track, enabled by default
--    + Settings: incoming note on trigger active pad, disabled by default
--    + Sampler: draw 3 signs after point
--    + DrumRack: show device name
--    + Structure: take device name as device track
--    # Properly solo/mute pads depending on device state

3.0alpha5 02.10.2022
--    # Structure: write parent GUID as track ext variable
--    # Structure: write MIDI bus state as track ext variable, this will allow to name MIDI bus whatever you want
--    # Structure: write child state as track ext variable, this will allow to name MIDI bus whatever you want
--    + Sampler: show active layer
--    + Device: support multiple layers per device
--    + Device: show active note + formatted note
--    + Device: internal structure changes
--    # Device: draw pan correctly
--    # MIDI bus: fix error on add

3.0alpha4 02.10.2022
--    + Sampler: add loop offset control, unlike REAPER native knob, properly limit to boundary start/end offset edges
--    # Sampler: cache item length into track external state for better control loop length (which is fixed internally to 30sec)
--    # Sampler: limit attack, decay and release to sample length
--    + Sampler: add voices control
--    + Sampler: add filter section
--    + Sampler: on tweak any filter control, add ReaEq on current sample track
--    + Sampler: initialize ReaEq hidden
--    + Sampler: initialize ReaEq with opened lowpass filter
--    + Sampler: drop sample on peaks window replace sample
--    # Sampler: change width to 8 controls for now
--    + Device: drop on layer change sample at current layer
--    + Settings: allow to enable/disable 'obey note off' on sample add
--    + Settings: allow to not update UI by incoming played notes
--    + Settings: allow to hide play button from DrumRack, use pad name instead
--    + Settings: allow to add custom FX chain when adding child
--    + DrumRack: set MIDI note names for MIDI bus on RS5k adding
--    + DrumRack: show playing notes
--    # DrumRack: refresh internal data on dropping pad
--    # Setting: clear blit layer correctly
--    # Setting: clear blit layer on project state change
--    # MIDI bus: set record mode to 'record output'
--    # fix error when play notes without active track
--    # UI: tweak font size ratios a bit
--    # Always add RS5k to the start of chain
--    # Whaen adding track with external template, hide chain and all floating FX in this chain

3.0alpha2 01.10.2022
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

3.0alpha1 25.09.2022
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
    DATA.extstate.version = '3.0beta15'
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
                          CONF_onadd_float = 0,
                          CONF_onadd_obeynoteoff = 1,
                          CONF_onadd_customtemplate = '',
                          
                          -- midi bus
                          CONF_midiinput = 63, -- 63 all 62 midi kb
                          
                          -- drum rack
                          UI_useplaybutton = 0, -- 0 == click on play trigger note
                          
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          UI_processoninit = 0,
                          UI_donotupdateonplay = 0,
                          UI_clickonpadselecttrack = 1,
                          UI_incomingnoteselectpad = 0,
                          
                          
                          }
    
    DATA2.custom_sampler_bandtypemap = {
            [3] = 'Low pass' ,
            [0] = 'Low shelf',
            [1] = 'Hi shelf' ,
            [8] = 'Band' ,
            [4] = 'Hi pass' ,
            [5] = 'All pass' ,
            [6] = 'Notch' ,
            [7] = 'Band pass' ,
            [10] = 'Parallel BP' ,
            [9] = 'Band alt' ,
            [2] = 'Band alt2' ,
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
    GetSetMediaTrackInfo_String( DATA2.tr_ptr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.extstate.version, true)
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
  function DATA2:ValidateWS(track, pos)
    local retval, buf1 = reaper.TrackFX_GetParamName( track, pos, 0 )
    if buf1:match'Distortion' then return true end
  end
  ---------------------------------------------------------------------  
  function DATA2:ValidateReaEQ(track, reaeq_pos)
    local retval, buf1 = reaper.TrackFX_GetParamName( track, reaeq_pos, 0 )
    local retval, buf2 = reaper.TrackFX_GetParamName( track, reaeq_pos, 1 )
    if buf1:match'Freq' and buf2:match'Gain' then return true end
  end
  ---------------------------------------------------------------------  
  function DATA2:ValidateRS5k(track, instrument_pos)
    if not instrument_pos then return end
    local retval, buf = reaper.TrackFX_GetParamName( track, instrument_pos, 2 )
    if buf == 'Gain for minimum velocity' then return true end
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_GetTrackParams(track)
    if not track then return end
    -- handle track parameters
    local tr_vol = GetMediaTrackInfo_Value( track, 'D_VOL' )
    local tr_vol_format = WDL_VAL2DB(tr_vol,2) ..'dB'
    local tr_pan = GetMediaTrackInfo_Value( track, 'D_PAN' )
    local tr_pan_format = DATA2:FormatPan(tr_pan)
    local tr_mute = GetMediaTrackInfo_Value( track, 'B_MUTE' )
    local tr_solo = GetMediaTrackInfo_Value( track, 'I_SOLO' )
    
    
    return {
      tr_ptr = track,
      tr_vol=tr_vol,
      tr_vol_format=tr_vol_format,
      tr_pan=tr_pan,
      tr_pan_format=tr_pan_format,
      tr_mute=tr_mute,
      tr_solo=tr_solo,
      }
  end
  ---------------------------------------------------------------------  
  function DATA2:FormatPan(tr_pan)
    local tr_pan_format = 'C'
    if tr_pan > 0 then 
      tr_pan_format = math.floor(math.abs(tr_pan*100))..'R'
     elseif tr_pan < 0 then 
      tr_pan_format = math.floor(math.abs(tr_pan*100))..'L'
    end
    return tr_pan_format
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_GetPluginParams_GuessByName(track, fxid, param_names, str_t )  
    local id
    for strid = 1, #str_t do
      local str = str_t[strid]
      for i = 1, #param_names do if param_names[i]:lower():match(str:lower()) then id = i break end end
      if id then 
        local param_val = TrackFX_GetParamNormalized( track, fxid, id-1 ) 
        local ret, param_val_format = TrackFX_GetFormattedParamValue( track, fxid, id-1 )
        local retval, param_name = reaper.TrackFX_GetParamName( track, fxid, id-1 )
        return param_val,param_val_format,id-1,param_name
      end
    end
    
    
  end 
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_GetPluginParams(track, fxid, note,layer)
    if not fxid then return end
    local retval, fxname = reaper.TrackFX_GetFXName( track, fxid )
    
    local param_names = {}
    for param = 1,  TrackFX_GetNumParams( track, fxid ) do
      local retval, buf = TrackFX_GetParamName( track, fxid, param-1 )
      param_names[#param_names+1] = buf
    end
    
    local vol,vol_format,vol_id,vol_name =                   DATA2:TrackDataRead_GetChildrens_GetPluginParams_GuessByName(track, fxid, param_names, {'general level','amp gain','gain','vol'})  
    local attack,attack_format,attack_id,attack_name =          DATA2:TrackDataRead_GetChildrens_GetPluginParams_GuessByName(track, fxid, param_names, {'vca attack','amp attack','attack', 'att'}) 
    local decay,decay_format,decay_id,decay_name =             DATA2:TrackDataRead_GetChildrens_GetPluginParams_GuessByName(track, fxid, param_names, {'vca decay','amp decay','decay', 'dec'})  
    local sustain,sustain_format,sustain_id,sustain_name =       DATA2:TrackDataRead_GetChildrens_GetPluginParams_GuessByName(track, fxid, param_names, {'vca sustain','amp sustain','sustain', 'sus'})    
    local release,release_format,release_id,release_name =       DATA2:TrackDataRead_GetChildrens_GetPluginParams_GuessByName(track, fxid, param_names, {'vca release','amp release','release','rel'})    
    local pitchoffs,pitchoffs_format,pitchoffs_id,pitchoffs_name = DATA2:TrackDataRead_GetChildrens_GetPluginParams_GuessByName(track, fxid, param_names, {'tune','tuning', 'detune', 'pitch', 'tun'})    
    
    --[[local notest = TrackFX_GetParamNormalized( track, fxid, 3 ) -- note range start
    local pan = TrackFX_GetParamNormalized( track, fxid, 1 ) 
    local loop = TrackFX_GetParamNormalized( track, fxid, 12 ) 
    local samplestoffs = TrackFX_GetParamNormalized( track, fxid, 13 ) 
    local sampleendoffs = TrackFX_GetParamNormalized( track, fxid, 14 ) 
    local loopoffs = TrackFX_GetParamNormalized( track, fxid, 23 ) 
    local maxvoices = TrackFX_GetParamNormalized( track, fxid, 8 ) 
    
    
    local ret, pan_format = TrackFX_GetFormattedParamValue( track, fxid, 1 ) 
    local samplestoffs_format = math.floor(samplestoffs*1000)/10..'%'
    local sampleendoffs_format = math.floor(sampleendoffs*1000)/10..'%'
    local loopoffs_format = math.floor(loopoffs *30*10000)/10..'ms'
    local maxvoices_format = math.floor(maxvoices*64)]]
     
    local enabled = TrackFX_GetEnabled( track, fxid )
    
    if not DATA2.notes[note] then DATA2.notes[note] = {layers = {}} end
     
    local reaeq_valid, reaeq_pos, reaeq_enabledband1, reaeq_bandtype, reaeq_cut, reaeq_gain, reaeq_bw, reaeq_cut_format,reaeq_gain_format,reaeq_bw_format, reaeq_bandtype_format = DATA2:TrackDataRead_GetChildrens_GetSampleDataParams_reaEQ(track)
    
    local name = VF_ReduceFXname(fxname) if name == '' then  name = fxname end
    local sampledata = { ISPLUGIN = true,
                         filepath = filepath,
                         filepath_short = filepath_short,
                         name = name,
                         tr_ptr = track,
                         instrument_pos = fxid,
                         
                         cached_len = cached_len,
                         
                         params_vol = vol,
                         params_vol_format = vol_format,
                         params_vol_id = vol_id,
                         params_vol_name = vol_name,
                         
                         params_attack=attack,
                         params_attack_format  =attack_format,
                         params_attack_id  =attack_id,
                         params_attack_name  =attack_name,
                         
                         params_decay=decay,
                         params_decay_format  =decay_format,
                         params_decay_id  =decay_id,
                         params_decay_name  =decay_name,
                         
                         params_sustain=sustain,
                         params_sustain_format  =sustain_format,
                         params_sustain_id  =sustain_id,
                         params_sustain_name  =sustain_name,
                         
                         params_release=release,
                         params_release_format  =release_format,
                         params_release_id  =release_id,                         
                         params_release_name  =release_name,                         
                         
                         params_pitchoffs=pitchoffs,
                         params_pitchoffs_format  =pitchoffs_format,
                         params_pitchoffs_id  =pitchoffs_id,
                         params_pitchoffs_name  =pitchoffs_name,
                         
                         --[[params_pan = pan,
                         params_pan_format = pan_format,
                         params_loop = loop,
                         params_samplestoffs = samplestoffs,
                         params_sampleendoffs = sampleendoffs,
                         params_loopoffs = loopoffs,
                         params_maxvoices =  maxvoices,
                         
                         
                         params_samplestoffs_format =  samplestoffs_format,
                         params_sampleendoffs_format =  sampleendoffs_format,
                         params_loopoffs_format =  loopoffs_format,
                         params_maxvoices_format =  maxvoices_format,]]
                         
                         
                         
                         reaeq_valid = reaeq_valid,
                         reaeq_pos = reaeq_pos,
                         reaeq_enabledband1 = reaeq_enabledband1,
                         reaeq_bandtype = reaeq_bandtype,
                         reaeq_cut = reaeq_cut,
                         reaeq_gain = reaeq_gain,
                         reaeq_bw = reaeq_bw,
                         reaeq_bandtype_format = reaeq_bandtype_format,
                         reaeq_cut_format = reaeq_cut_format,
                         reaeq_gain_format = reaeq_gain_format,
                         reaeq_bw_format = reaeq_bw_format,
                         
                         enabled = enabled,
                        }
                        
    local tr_data = DATA2:TrackDataRead_GetChildrens_GetTrackParams(track)
    for key in pairs(tr_data) do sampledata[key] = tr_data[key] end
    
    if not DATA2.notes[note] then DATA2.notes[note] = {} end
    if not DATA2.notes[note].layers then DATA2.notes[note].layers = {} end
    if layer == -1 then layer = #DATA2.notes[note].layers + 1 end
    if not DATA2.notes[note].layers[layer] then DATA2.notes[note].layers[layer] = {} end
    DATA2.notes[note].layers[layer]=sampledata
    return name
  end
  ---------------------------------------------------------------------  
  
  function DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(track, fxid, note,layer)
    
    local rs5k_valid = DATA2:ValidateRS5k(track, fxid)
    if not (rs5k_valid and rs5k_valid == true) then return DATA2:TrackDataRead_GetChildrens_GetPluginParams(track, fxid, note, layer) end
     
    if not fxid then return end
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
    local loopoffs = TrackFX_GetParamNormalized( track, fxid, 23 ) 
    local maxvoices = TrackFX_GetParamNormalized( track, fxid, 8 ) 
    local pitchoffs = TrackFX_GetParamNormalized( track, fxid, 15 ) 
    
    local ret, vol_format = TrackFX_GetFormattedParamValue( track, fxid, 0 )
    vol_format=vol_format..'dB'
    local ret, pan_format = TrackFX_GetFormattedParamValue( track, fxid, 1 ) 
    local ret, attack_format = TrackFX_GetFormattedParamValue( track, fxid, 9 ) 
    local ret, decay_format = TrackFX_GetFormattedParamValue( track, fxid, 24 ) 
    local ret, sustain_format = TrackFX_GetFormattedParamValue( track, fxid, 25 ) 
    local ret, release_format = TrackFX_GetFormattedParamValue( track, fxid, 10 ) 
    local ret, pitchoffs_format = TrackFX_GetFormattedParamValue( track, fxid, 15 ) 
    local samplestoffs_format = math.floor(samplestoffs*1000)/10
    local sampleendoffs_format = math.floor(sampleendoffs*1000)/10
    local loopoffs_format = math.floor(loopoffs *30*10000)/10
    local maxvoices_format = math.floor(maxvoices*64)
     
    local ret, filepath = TrackFX_GetNamedConfigParm(  track, fxid, 'FILE0') 
    local enabled = TrackFX_GetEnabled( track, fxid )
    
    --local note = math.floor(128*notest)
    local filepath_short = GetShortSmplName(filepath)
    if filepath_short and filepath_short:match('(.*)%.[%a]+') then filepath_short = filepath_short:match('(.*)%.[%a]+') end
    if not DATA2.notes[note] then DATA2.notes[note] = {layers = {}} end
    
    local ret,cached_len = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_SAMPLELEN', '', false) 
    if cached_len then cached_len = tonumber(cached_len) end
    
    
    local reaeq_valid, reaeq_pos, reaeq_enabledband1, reaeq_bandtype, reaeq_cut, reaeq_gain, reaeq_bw, reaeq_cut_format,reaeq_gain_format,reaeq_bw_format, reaeq_bandtype_format = DATA2:TrackDataRead_GetChildrens_GetSampleDataParams_reaEQ(track)
    local ws_valid, ws_pos, ws_drive, ws_drive_format = DATA2:TrackDataRead_GetChildrens_GetSampleDataParams_WS(track)
    
    local ret, trname = GetTrackName( track )
    local sampledata = { filepath = filepath,
                         filepath_short = filepath_short,
                         name = trname or '',--filepath_short,
                         tr_ptr = track,
                         instrument_pos = fxid,
                         
                         cached_len = cached_len,
                         
                         params_vol = vol,
                         params_pan = pan,
                         params_vol_format = vol_format,
                         params_pan_format = pan_format,
                         params_loop = loop,
                         params_attack=attack,
                         params_decay=decay,
                         params_sustain=sustain,
                         params_release=release,
                         params_samplestoffs = samplestoffs,
                         params_sampleendoffs = sampleendoffs,
                         params_loopoffs = loopoffs,
                         params_maxvoices =  maxvoices,
                         params_pitchoffs =  pitchoffs,
                         
                         params_attack_format  =attack_format..'ms',
                         params_decay_format  =decay_format..'ms',
                         params_sustain_format  =sustain_format..'dB',
                         params_release_format  =release_format..'ms',
                         params_samplestoffs_format =  samplestoffs_format..'%',
                         params_sampleendoffs_format =  sampleendoffs_format..'%',
                         params_loopoffs_format =  loopoffs_format..'ms',
                         params_maxvoices_format =  maxvoices_format,
                         params_pitchoffs_format =  pitchoffs_format,
                         
                         reaeq_valid = reaeq_valid,
                         reaeq_pos = reaeq_pos,
                         reaeq_enabledband1 = reaeq_enabledband1,
                         reaeq_bandtype = reaeq_bandtype,
                         reaeq_cut = reaeq_cut,
                         reaeq_gain = reaeq_gain,
                         reaeq_bw = reaeq_bw,
                         reaeq_bandtype_format = reaeq_bandtype_format,
                         reaeq_cut_format = reaeq_cut_format,
                         reaeq_gain_format = reaeq_gain_format,
                         reaeq_bw_format = reaeq_bw_format,
                         
                         ws_valid = ws_valid,
                         ws_pos = ws_pos,
                         ws_drive = ws_drive,
                         ws_drive_format =ws_drive_format ,
                         enabled = enabled,
                        }
                        
    local tr_data = DATA2:TrackDataRead_GetChildrens_GetTrackParams(track)
    for key in pairs(tr_data) do sampledata[key] = tr_data[key] end
    
    if not DATA2.notes[note] then DATA2.notes[note] = {} end
    if not DATA2.notes[note].layers then DATA2.notes[note].layers = {} end
    if layer == -1 then layer = #DATA2.notes[note].layers + 1 end
    if not DATA2.notes[note].layers[layer] then DATA2.notes[note].layers[layer] = {} end
    DATA2.notes[note].layers[layer]=sampledata
    return filepath_short
  end 
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_GetSampleDataParams_WS(track)
    for fxid = 1,  TrackFX_GetCount( track ) do
      if DATA2:ValidateWS(track, fxid-1) then
        local drive = TrackFX_GetParamNormalized( track, fxid-1, 0 )
        local drive_form = (math.floor(1000*drive)/10)..'%'
        return true, fxid-1, drive, drive_form
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_GetSampleDataParams_reaEQ(track)
    for fxid = 1,  TrackFX_GetCount( track ) do
      if DATA2:ValidateReaEQ(track, fxid-1) then 
        local cut = TrackFX_GetParamNormalized( track, fxid-1, 0 )
        local gain = TrackFX_GetParamNormalized( track, fxid-1, 1)
        local bw = TrackFX_GetParamNormalized( track, fxid-1, 2 )
        local retval, reaeq_cut_format = TrackFX_GetFormattedParamValue( track, fxid-1, 0 )
        local retval, reaeq_gain_format = TrackFX_GetFormattedParamValue( track, fxid-1, 1 )
        local retval, reaeq_bw_format = TrackFX_GetFormattedParamValue( track, fxid-1, 2 )
        local retval, enabled = TrackFX_GetNamedConfigParm( track, fxid-1, 'BANDENABLED0' )
        local retval, bandtype = TrackFX_GetNamedConfigParm( track, fxid-1, 'BANDTYPE0' )
        bandtype = tonumber(bandtype)
        local reaeq_bandtype_format = ''
        if DATA2.custom_sampler_bandtypemap and DATA2.custom_sampler_bandtypemap[bandtype] then reaeq_bandtype_format = DATA2.custom_sampler_bandtypemap[bandtype] end
        return true, fxid-1, tonumber(enabled), bandtype, cut, gain, bw , reaeq_cut_format..'Hz', reaeq_gain_format..'dB' , reaeq_bw_format, reaeq_bandtype_format 
      end
    end
  end
  ---------------------------------------------------------------------   
  function DATA2:TrackDataRead_GetChildrens_Device(track, note0) 
    local ret, note_ext = DATA2:TrackDataRead_IsDevice(track) 
    local note = note_ext
    if note0 then note = note0 end
    if not DATA2.notes[note] then DATA2.notes[note] = {} end
    DATA2.notes[note].device_isdevice = true
    DATA2.notes[note].device_trID =  CSurf_TrackToID( track, false )
    DATA2.notes[note].device_ptr =  track
    DATA2.notes[note].device_GUID =  GetTrackGUID(track)
    ret , DATA2.notes[note].device_name =  GetTrackName( track )
    
    local tr_data = DATA2:TrackDataRead_GetChildrens_GetTrackParams(track)
    for key in pairs(tr_data) do DATA2.notes[note][key] = tr_data[key] end
  end
  ---------------------------------------------------------------------   
  function DATA2:TrackDataRead_GetChildrens_GetChild(track, isregularchild)
    local note, fxid = DATA2:TrackDataRead_GetNote(track)
    if not note and fxid then return end
    local layer = -1
    if isregularchild then layer = 1 end
    local notename = DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(track, fxid, note, layer )
    if isregularchild and notename and not DATA2.notes[note].name then DATA2.notes[note].name = notename end
    if isregularchild and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_ptr then DATA2.notes[note].tr_ptr = DATA2.notes[note].layers[1].tr_ptr end
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
  function DATA2:TrackDataWrite_MarkParentFolder() 
    SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERDEPTH',1 )
    GetSetMediaTrackInfo_String( DATA2.tr_ptr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.extstate.version, true)
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
    SetMediaTrackInfo_Value( new_tr, 'I_RECMODE', 0 ) -- record MIDI out
    local channel,physical_input = 0, DATA.extstate.CONF_midiinput
    SetMediaTrackInfo_Value( new_tr, 'I_RECINPUT', 4096 + channel + (physical_input<<5)) -- set input to all MIDI
    DATA2:TrackDataWrite_MarkChildIsMIDIBus(new_tr)    
    DATA2:TrackDataRead_InitMIDIBus(new_tr)
    
    -- 
    local cnt = 0
    for key in pairs(DATA2.notes) do cnt = cnt+ 1 end
    if cnt == 0 then SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH',-1 ) end
    
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_IsMIDIBus(track)   
    local ret, isMIDIbus = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_MIDIBUS', 0, false)
    return (tonumber(isMIDIbus) or 0)==1
  end  
  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_IsDevice(track)  
    local ret, isDev = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_DEVICE_ISDEVICE', 0, false)
    local ret, note = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_DEVICE_NOTE',0, false)
    return (tonumber(isDev) or 0)==1, tonumber(note)
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_GetNote(track)  
    local ret, note = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_NOTE', 0, false)
    local ret, fxGUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_FXGUID', 0, false)
    local fxid = -1
    if fxGUID then ret, tr, fxid =  VF_GetFXByGUID(fxGUID, track) end
    return tonumber(note), fxid
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_IsRegularChild(track)   
    local ret, isRegChild = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_ISCHILD', 0, false)
    return (tonumber(isRegChild) or 0)==1
  end  
  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_IsDeviceChild(track)   
    local ret, isDevChild = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_DEVICE_ISDEVICECHILD', 0, false)
    return (tonumber(isDevChild) or 0)==1
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_IsChildAppendsToCurrentParent(track)   
    local ret, parGUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', '', false)
    if DATA2.tr_GUID and parGUID == DATA2.tr_GUID then ret = true end 
    return ret, parGUID
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataWrite_MarkChildIsMIDIBus(tr)   
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_MIDIBUS', 1, true)
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.extstate.version, true)
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataWrite_MarkTrackAsDevice(devicetr, note)    
    GetSetMediaTrackInfo_String( devicetr, 'P_EXT:MPLRS5KMAN_DEVICE_ISDEVICE', 1, true)
    GetSetMediaTrackInfo_String( devicetr, 'P_EXT:MPLRS5KMAN_DEVICE_NOTE',note, true)
    GetSetMediaTrackInfo_String( devicetr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.extstate.version, true)
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataWrite_UnMarkChild(tr)   
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_ISCHILD', 0, true)
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataWrite_MarkChild(tr, device_isdevice_child, deviceGUID) 
    if not device_isdevice_child then 
      GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_ISCHILD', 1, true)
     else
     
      GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_ISCHILD', 0, true)
      GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_DEVICE_ISDEVICECHILD', 1, true)
      GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_DEVICEGUID', deviceGUID, true)
      GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.extstate.version, true)
    end
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataWrite_MarkChildAppendsToNote(tr, note, instrumentGUID)   
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_NOTE', note, true)
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FXGUID', instrumentGUID, true)
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataWrite_MarkChildAppendsToCurrentParent(tr)   
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', DATA2.tr_GUID, true)
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_InitMIDIBus(track)
    DATA2.MIDIbus = {ptr = track, ID = CSurf_TrackToID( track, false )}
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens()
  
    local partrack, partrack_name
    for i = DATA2.tr_ID+1, CountTracks(0) do
      local track = GetTrack(0,i-1)
      
      -- validate childen
      if DATA2:TrackDataRead_IsChildAppendsToCurrentParent(track) == true  then
        if      DATA2:TrackDataRead_IsMIDIBus(track) then DATA2:TrackDataRead_InitMIDIBus(track)          
         elseif DATA2:TrackDataRead_IsRegularChild(track) then  DATA2:TrackDataRead_GetChildrens_GetChild(track, true) -- msg('TrackDataRead_GetChildrens_RegularChild')
         elseif DATA2:TrackDataRead_IsDevice(track) then        DATA2:TrackDataRead_GetChildrens_Device(track) --msg('TrackDataRead_GetChildrens_Device')
         elseif DATA2:TrackDataRead_IsDeviceChild(track)   then DATA2:TrackDataRead_GetChildrens_GetChild(track) --msg('TrackDataRead_GetChildrens_DeviceChild')
           
        end 
       else
        break
      end
    end
    
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
      local ret, parGUID = DATA2:TrackDataRead_IsChildAppendsToCurrentParent(parenttrack)   
      if ret and parGUID then parenttrack = VF_GetTrackByGUID(parGUID) end 
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
    
    DATA.GUI.Settings_open = 0
    GUI_MODULE_SETTINGS(DATA)
      
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
      DATA.GUI.custom_padrackW = DATA.GUI.custom_modulew--DATA.GUI.custom_offset2
      DATA.GUI.custom_offset_pads = DATA.GUI.custom_offset2
      DATA.GUI.custom_padstxtsz = 14
      DATA.GUI.custom_padsctrltxtsz = 10
      DATA.GUI.custom_arcr = math.floor(DATA.GUI.custom_padsideX*0.1)
      DATA.GUI.custom_controlbut_h = DATA.GUI.custom_padsideY/2
      DATA.GUI.custom_controltxt_sz = math.floor(DATA.GUI.custom_controlbut_h*0.6- DATA.GUI.custom_offset2*2)
      
      -- device
      DATA.GUI.custom_devicew = math.floor(DATA.GUI.custom_moduleh*1.5)
      DATA.GUI.custom_deviceh = gfx_h - DATA.GUI.custom_infoh-DATA.GUI.custom_offset -- DEVICE H
      DATA.GUI.custom_deviceentryh = math.floor(18 * DATA.GUI.default_scale)
      DATA.GUI.custom_devicectrl_txtsz = 13 * DATA.GUI.default_scale
      
      -- sampler
      --DATA.GUI.custom_samplerW = math.floor(DATA.GUI.custom_modulew*1.5)
      DATA.GUI.custom_sampler_showbutw = 50 * DATA.GUI.default_scale
      DATA.GUI.custom_samplerH = DATA.GUI.custom_moduleh
      DATA.GUI.custom_spl_areah = math.floor(DATA.GUI.custom_deviceh * 0.5)
      DATA.GUI.custom_spl_modew = math.floor(DATA.GUI.custom_spl_areah/2)
      DATA.GUI.custom_samplerW = (DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2) * 8
      DATA.GUI.custom_sampler_namebutw = DATA.GUI.custom_samplerW-DATA.GUI.custom_sampler_showbutw
      DATA.GUI.custom_spl_modeh =DATA.GUI.custom_spl_modew+1
      DATA.GUI.custom_splctrl_h = math.floor(DATA.GUI.custom_spl_areah*0.15)
      DATA.GUI.custom_splknob_h = DATA.GUI.custom_samplerH - DATA.GUI.custom_splctrl_h*2 - DATA.GUI.custom_spl_areah - DATA.GUI.custom_offset2*2-DATA.GUI.custom_offset
      DATA.GUI.custom_splknob_txtsz = DATA.GUI.custom_splctrl_h - DATA.GUI.custom_offset2*2
      DATA.GUI.custom_splgridtxtsz = DATA.GUI.custom_splknob_txtsz--12 * DATA.GUI.default_scale
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
                            
      if not DATA.GUI.Settings_open then DATA.GUI.Settings_open = 0  end
      if DATA.GUI.Settings_open ==0 then  
        if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 0
        --if DATA2.tr_valid ==true and DATA2.tr_extparams_showstates then 
          GUI_RESERVED_init_settingbut(DATA)
          GUI_MODULE_MACRO(DATA) 
          GUI_MODULE_PADOVERVIEW(DATA)
          GUI_MODULE_DRUMRACKPAD(DATA)
          GUI_MODULE_DEVICE(DATA)  
          GUI_MODULE_SAMPLER(DATA) 
          GUI_MODULE_SETTINGS(DATA)
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
    
    if DATA.GUI.Settings_open == 0 then 
      if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 0
      return 
    end
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
    
    local customtemplate = DATA.extstate.CONF_onadd_customtemplate
    local  t = 
    { 
      {str = 'On sample add:' ,                                 group = 1, itype = 'sep'},
        {str = 'Float RS5k instance',                           group = 1, itype = 'check', confkey = 'CONF_onadd_float', level = 1},
        {str = 'Set obey notes-off',                            group = 1, itype = 'check', confkey = 'CONF_onadd_obeynoteoff', level = 1},
        {str = 'Custom track template: '..customtemplate,       group = 1, itype = 'button', confkey = 'CONF_onadd_customtemplate', level = 1, val_isstring = true, func_onrelease = function() local retval, fp = GetUserFileNameForRead('', 'FX chain for newly dragged samples', 'RTrackTemplate') if retval then DATA.extstate.CONF_onadd_customtemplate=  fp GUI_MODULE_SETTINGS(DATA) end end},
        {str = 'Custom track template [clear]',                  group = 1, itype = 'button', confkey = 'CONF_onadd_customtemplate', level = 1, val_isstring = true, func_onrelease = function() DATA.extstate.CONF_onadd_customtemplate=  '' GUI_MODULE_SETTINGS(DATA) end},
      {str = 'MIDI bus',                                        group = 2, itype = 'sep'}, 
        {str = 'MIDI bus default input',                        group = 2, itype = 'readout', confkey = 'CONF_midiinput', level = 1, menu = {[63]='All inputs',[62]='Virtual keyboard'},readoutw_extw = readoutw_extw},
      {str = 'UI',                                              group = 3, itype = 'sep'},
        {str = 'Do not update UI from played notes',            group = 3, itype = 'check', confkey = 'UI_donotupdateonplay', level = 1},
      {str = 'DrumRack',                                        group = 4, itype = 'sep'},  
        {str = 'Use play button',                               group = 4, itype = 'check', confkey = 'UI_useplaybutton', level = 1}, 
        {str = 'Click on pad select track',                     group = 4, itype = 'check', confkey = 'UI_clickonpadselecttrack', level = 1},
        {str = 'Incoming notes activate pads',                  group = 4, itype = 'check', confkey = 'UI_incomingnoteselectpad', level = 1},
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
                        --ignoremouse = true,
                        frame_a = 0,
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
                        onmousereleaseR = function()
                                local retval, new_val = GetUserInputs( 'Set values', 1, '', t.val_format )
                                if not (retval and new_val~='' ) then return end 
                                local new_val = VF_BFpluginparam(new_val, t.src_t.tr_ptr, t.src_t.instrument_pos, t.paramid)  
                                --msg(new_val)
                                DATA2:TrackData_SetRS5kParams(t.src_t, t.paramid, new_val)
                                DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(t.src_t.tr_ptr, t.src_t.instrument_pos, note,layer)
                                DATA.GUI.buttons['sampler_'..t.key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
                                DATA.GUI.buttons['sampler_'..t.key..'val'].refresh = true
                        end, 
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
  function DATA2:Stuff_NoteOn(note, vel)
    StuffMIDIMessage( 0, 0x90, note, vel or 120 ) 
    DATA.ontrignoteTS = os.clock() 
    DATA.ontrignote = note 
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
                            w=DATA.GUI.custom_padrackW-DATA.GUI.custom_offset2,
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
      if DATA2.notes[note] and DATA2.notes[note].device_isdevice and DATA2.notes[note].device_isdevice == true and DATA2.notes[note].device_name then txt ='[D] '..DATA2.notes[note].device_name end
      
      DATA.GUI.buttons['drumrackpad_pad'..padID0] = { x=DATA.GUI.buttons.drumrackpad.x+(padID0%4)*DATA.GUI.custom_padsideX+1,
                              y=DATA.GUI.buttons.drumrackpad.y+DATA.GUI.buttons.drumrackpad.h-DATA.GUI.custom_padsideY*(math.floor(padID0/4)+1)+DATA.GUI.custom_offset_pads,
                              w=DATA.GUI.custom_padsideX-DATA.GUI.custom_offset_pads,
                              h=DATA.GUI.custom_padsideY-DATA.GUI.custom_offset_pads-1,
                              ignoremouse = true,
                              txt='',
                              frame_a = frame_a,
                              frame_arcborder = true,
                              frame_arcborderr = DATA.GUI.custom_arcr,
                              frame_arcborderflags = 1|2,
                              onmouseclick = function() end, 
                              refresh = true,
                              }
                              
      local padx= DATA.GUI.buttons.drumrackpad.x+(padID0%4)*DATA.GUI.custom_padsideX+1
      local pady = DATA.GUI.buttons.drumrackpad.y+DATA.GUI.buttons.drumrackpad.h-DATA.GUI.custom_padsideY*(math.floor(padID0/4)+1)+DATA.GUI.custom_offset_pads
      local controlbut_h2 = DATA.GUI.custom_padsideY/2-DATA.GUI.custom_offset_pads
      local controlbut_w = math.floor(DATA.GUI.custom_padsideX / 4)
      if DATA.extstate.UI_useplaybutton == 0 then controlbut_w = math.floor(DATA.GUI.custom_padsideX / 3) end
      local frame_actrl =0
      local txt_actrl = 0.2
      local txt_a 
      if not DATA2.notes[note] then txt_a = 0.1 end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] = { x=padx,
                              y=pady,
                              w=DATA.GUI.custom_padsideX-DATA.GUI.custom_offset_pads,
                              h=DATA.GUI.custom_controlbut_h,
                              txt=txt,
                              txt_a = txt_a,
                              txt_fontsz =DATA.GUI.custom_controltxt_sz,
                              frame_a = 0,
                              frame_asel = 0.1,
                              backgr_fill = 0 ,
                              back_sela = 0.1 ,
                              frame_arcborder = true,
                              frame_arcborderr = DATA.GUI.custom_arcr,
                              frame_arcborderflags = 1|2,
                              --prevent_matchrefresh = true,
                              onmouseclick = function() 
                                if DATA.extstate.UI_clickonpadselecttrack == 1 then
                                  if DATA2.notes[note] then
                                    if DATA2.notes[note].device_isdevice ~= true then 
                                      SetOnlyTrackSelected( DATA2.notes[note].layers[1].tr_ptr ) 
                                     else 
                                      SetOnlyTrackSelected(DATA2.notes[note].device_ptr) 
                                    end
                                  end
                                end
                                if DATA.extstate.UI_useplaybutton == 0 then  DATA2:Stuff_NoteOn(note)  end
                                
                                if DATA.GUI.Ctrl == true then DATA2:ActiveNoteLayer_ShowRS5k(note, 1) 
                                 else
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
                              onmouserelease =  function() if DATA.extstate.UI_useplaybutton == 0 then  StuffMIDIMessage( 0, 0x80, note, 0 ) DATA.ontrignoteTS =  nil end end,
                              }     
      --local txt_a,txt_col= txt_actrl if DATA2.notes[note] and DATA2.notes[note].partrack_mute and DATA2.notes[note].partrack_mute == 1 then txt_col = '#A55034' txt_a = 1 end
      local backgr_fill,txt_a= 0,txt_actrl if DATA2.notes[note] and DATA2.notes[note].layers[1].tr_mute and DATA2.notes[note].layers[1].tr_mute >0 then backgr_fill = 0.2 txt_a = nil end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'mute'] = { x=padx,
                              y=pady+DATA.GUI.custom_controlbut_h,
                              w=controlbut_w,
                              h=controlbut_h2-1,
                              txt='M',
                              txt_col=txt_col,
                              txt_a = txt_a,
                              txt_fontsz = DATA.GUI.custom_controltxt_sz,
                              frame_a = frame_actrl,
                              prevent_matchrefresh = true,
                              backgr_fill = backgr_fill,
                              backgr_col = DATA.GUI.custom_backcol2,
                              onmouseclick = function() DATA2:PAD_mute(note) end,
                              } 
                              
      if DATA.extstate.UI_useplaybutton == 1 then
        local backgr_fill2,frame_actrl0=nil,frame_actrl if DATA2.playingnote_pitch and DATA2.playingnote_pitch == note  then backgr_fill2 = 0.8 frame_actrl0 = 1 end
        DATA.GUI.buttons['drumrackpad_pad'..padID0..'play'] = { x=padx+controlbut_w,
                                y=pady+DATA.GUI.custom_controlbut_h,
                                w=controlbut_w,
                                h=controlbut_h2-1,
                                txt='>',
                                txt_fontsz = DATA.GUI.custom_controltxt_sz,
                                txt_a = txt_actrl,
                                prevent_matchrefresh = true,
                                frame_a = frame_actrl0,
                                backgr_fill = backgr_fill2 ,
                                onmouseclick =    function() DATA2:Stuff_NoteOn(note, vel) end,
                                onmouserelease =  function() StuffMIDIMessage( 0, 0x80, note, 0 ) DATA.ontrignoteTS =  nil end,
                                refresh = true,
                                }   
      end
      local backgr_fill,txt_a= 0,txt_actrl if DATA2.notes[note] and DATA2.notes[note].layers[1].tr_solo and DATA2.notes[note].layers[1].tr_solo >0 then backgr_fill = 0.2 txt_a = nil end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'solo'] = { x=padx+controlbut_w*2,
                              y=pady+DATA.GUI.custom_controlbut_h,
                              w=controlbut_w,
                              h=controlbut_h2-1,
                              --txt_col=txt_col,
                              txt_a = txt_a,
                              txt='S',
                              txt_fontsz = DATA.GUI.custom_controltxt_sz,
                              frame_a = frame_actrl,
                              prevent_matchrefresh = true,
                              backgr_fill = backgr_fill,
                              backgr_col = DATA.GUI.custom_backcol2,
                              onmouseclick = function() DATA2:PAD_solo(note) end,
                              }    
      if DATA.extstate.UI_useplaybutton == 0 then DATA.GUI.buttons['drumrackpad_pad'..padID0..'solo'].x=padx+controlbut_w end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'show'] = { x=padx+controlbut_w*3,
                              y=pady+DATA.GUI.custom_controlbut_h,
                              w=controlbut_w-1,
                              h=controlbut_h2-1,
                              txt_a = txt_actrl,
                              txt='ME',
                              txt_fontsz = DATA.GUI.custom_controltxt_sz,
                              frame_a = 0,
                              backgr_fill = 0,
                              --frame_arcborder = true,
                              --frame_arcborderr = DATA.GUI.custom_arcr,
                              --frame_arcborderflags = 4,
                              onmouseclick = function() DATA2:PAD_showinME(note) end,
                              } 
      if DATA.extstate.UI_useplaybutton == 0 then DATA.GUI.buttons['drumrackpad_pad'..padID0..'show'].x=padx+controlbut_w*2 end
      padID0 = padID0 + 1
    end
  end
  ----------------------------------------------------------------------- 
  function DATA2:PAD_mute(note, layer) 
    if not DATA2.notes[note] then return end
    if not layer then 
      if DATA2.notes[note].device_isdevice == true then t = DATA2.notes[note] else t = DATA2.notes[note].layers[1] end       -- do stuff on device or first layer only
     else t = DATA2.notes[note].layers[layer] -- do stuff on defined layer 
    end
    if not (t and t.tr_ptr) then return end
    
    local state = t.tr_mute > 0
    if state then state = 0 else state =2 end 
    SetMediaTrackInfo_Value( t.tr_ptr, 'B_MUTE', state )
    t.tr_mute = state
    GUI_MODULE_DRUMRACKPAD(DATA)  
    GUI_MODULE_DEVICE(DATA)  
  end
  -----------------------------------------------------------------------  
  function DATA2:PAD_showinME(note, layer)
    if not DATA2.notes[note] then return end
    if not layer then 
      t = DATA2.notes[note].layers[1]       -- do stuff on device/instrument or first layer only
     else 
      t = DATA2.notes[note].layers[layer] -- do stuff on defined layer 
    end
    if not (t and t.tr_ptr) then return end
    
    if not t.filepath then return end
    local filepath= DATA2.notes[note].layers[1].filepath
    OpenMediaExplorer( filepath, false )
  end
  ----------------------------------------------------------------------- 
  function DATA2:PAD_solo(note,layer)
    if not DATA2.notes[note] then return end
    if not layer then 
      if DATA2.notes[note].device_isdevice == true then t = DATA2.notes[note] else t = DATA2.notes[note].layers[1] end       -- do stuff on device or first layer only
     else t = DATA2.notes[note].layers[layer] -- do stuff on defined layer 
    end
    if not (t and t.tr_ptr) then return end
    
    --if (DATA2.notes[note] and DATA2.notes[note].tr_ptr and ValidatePtr2(0,DATA2.notes[note].tr_ptr, 'MediaTrack*')) then t = DATA2.notes[note] end
    --if not t and (DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_ptr and ValidatePtr2(0,DATA2.notes[note].layers[1].tr_ptr, 'MediaTrack*')) then t = DATA2.notes[note].layers[1] end
    
    
    local state = t.tr_solo > 0
    if state then state = 0 else state =2 end 
    SetMediaTrackInfo_Value( t.tr_ptr, 'I_SOLO', state )
    t.tr_solo = state
    GUI_MODULE_DRUMRACKPAD(DATA)  
    GUI_MODULE_DEVICE(DATA)  
      
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
  --------------------------------------------------------------------- 
  function DATA2:PAD_onfiledrop_AddChildTrack(ID_spec) 
    local ID = DATA2.tr_ID
    if ID_spec then ID = ID_spec end
    InsertTrackAtIndex( ID, false )
    local new_tr = CSurf_TrackFromID(ID+1,false)
    
    if DATA.extstate.CONF_onadd_customtemplate ~= '' then 
      local f = io.open(DATA.extstate.CONF_onadd_customtemplate,'rb')
      local content
      if f then 
        content = f:read('a')
        f:close()
      end
      local GUID = GetTrackGUID( new_tr )
      content = content:gsub('TRACK ', 'TRACK '..GUID)
      SetTrackStateChunk( new_tr, content, false )
      TrackFX_Show( new_tr, 0, 0 ) -- hide chain
      for fxid = 1,  TrackFX_GetCount( new_tr ) do
        TrackFX_Show( new_tr,fxid-1, 2 ) -- hide chain
      end
    end
    
    DATA2:TrackDataWrite_MarkChildAppendsToCurrentParent(new_tr)  
    DATA2:TrackDataWrite_MarkChild(new_tr)  
     
    return new_tr
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onfiledrop_ExportFXasDeviceInstrument(new_tr, filepath,note)
    local fx_dll = filepath:match('@fx%:(.*)'):gsub('\\','/')
    local fx_dll_sh = GetShortSmplName(fx_dll)
    --local fx_dll_sh_noext = fx_dll:match('(.*)%.(.*)')
    local instrument_pos = TrackFX_AddByName( new_tr, fx_dll_sh, false, 1 ) 
    if instrument_pos == -1 then return end
    local retval, fxname = TrackFX_GetFXName( new_tr, instrument_pos )
    local fxname_settrname =  VF_ReduceFXname(fxname) or fxname
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', fxname_settrname, true )
    local instrumentGUID = TrackFX_GetFXGUID( new_tr, instrument_pos)
    DATA2:TrackDataWrite_MarkChildAppendsToNote(new_tr, note, instrumentGUID)   
    
    local midifilt_pos = TrackFX_AddByName( new_tr, 'midi_note_filter', false, -1000 ) 
    TrackFX_SetParamNormalized( new_tr, midifilt_pos, 0, note/128)
    TrackFX_SetParamNormalized( new_tr, midifilt_pos, 1, note/128)
    TrackFX_Show( new_tr, midifilt_pos, 2 )
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onfiledrop_ExportToRS5k(new_tr, filepath,note,filepath_sh)
    if filepath:match('@fx') then
      DATA2:PAD_onfiledrop_ExportFXasDeviceInstrument(new_tr, filepath,note)
      return
    end
    if not filepath_sh then return end
    local instrument_pos = TrackFX_AddByName( new_tr, 'ReaSamplomatic5000', false, 0 ) 
    if instrument_pos == -1 then instrument_pos = TrackFX_AddByName( new_tr, 'ReaSamplomatic5000', false, -1000 ) end 
    if DATA.extstate.CONF_onadd_float == 0 then TrackFX_SetOpen( new_tr, instrument_pos, false ) end
    TrackFX_SetNamedConfigParm(  new_tr, instrument_pos, 'FILE0', filepath)
    TrackFX_SetNamedConfigParm(  new_tr, instrument_pos, 'DONE', '')      
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 2, 0) -- gain for min vel
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 3, (note)/127 ) -- note range start
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 4, (note)/127 ) -- note range end
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 5, 0.5 ) -- pitch for start
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 6, 0.5 ) -- pitch for end
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 8, 0 ) -- max voices = 0
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 9, 0 ) -- attack
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 11, DATA.extstate.CONF_onadd_obeynoteoff) -- obey note offs
    
    -- set parent track name
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', filepath_sh, true )
    
    -- store external data
    local src = PCM_Source_CreateFromFile( filepath )
    if src then 
      local it_len =  GetMediaSourceLength( src )
      GetSetMediaTrackInfo_String( new_tr, 'P_EXT:MPLRS5KMAN_SAMPLELEN', it_len, true)
      local instrumentGUID = TrackFX_GetFXGUID( new_tr, instrument_pos)
      DATA2:TrackDataWrite_MarkChildAppendsToNote(new_tr, note, instrumentGUID)   
    end
    
    -- set MIDI bus note name
    SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, filepath_sh)
    
    
    
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_ClearPad(note)
    if not DATA2.notes[note] then return end
    DeleteTrack( DATA2.notes[note].tr_ptr )
    DATA2.FORCEONPROJCHANGE = true
    SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, '')
    reaper.SetOnlyTrackSelected( DATA2.tr_ptr )
  end 
  -----------------------------------------------------------------------
  function DATA2:PAD_RenamePad(note,layer)
    if not layer then 
      if DATA2.notes[note].device_isdevice == true then t = DATA2.notes[note] else t = DATA2.notes[note].layers[1] end       -- do stuff on device or first layer only
     else t = DATA2.notes[note].layers[layer] -- do stuff on defined layer 
    end
    if not (t and t.tr_ptr) then return end
    
    
    local tr = t.tr_ptr
    DATA2.FORCEONPROJCHANGE = true
    local curname = t.name
    if not curname and DATA2.notes[note].device_isdevice == true then curname = t.device_name end
    local retval, retvals_csv = reaper.GetUserInputs( 'Rename pad', 1, ',extrawidth=200', curname )
    if retval then 
      GetSetMediaTrackInfo_String( tr, 'P_NAME', retvals_csv, true )
    end
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onrightclick(note)
    if not DATA2.tr_valid then return end
    local t = { 
      {str='Rename pad',
        func=function() DATA2:PAD_RenamePad(note) end },  
      {str='Clear pad',
        func=function() DATA2:PAD_ClearPad(note) end },  
      {str='Export selected items to pads, starting this pad',
        func=function() DATA2:PAD_ExportSelectedItems(note) end },
     
         
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
  function DATA2:PAD_onfiledrop_ConvertChildToDevice(note) 
  
    -- add device track
    local ID_curchild =  CSurf_TrackToID( DATA2.notes[note].layers[1].tr_ptr, false )-1
    local devicetr = DATA2:PAD_onfiledrop_AddChildTrack(ID_curchild) 
    DATA2:TrackDataWrite_MarkTrackAsDevice(devicetr, note) 
    DATA2:TrackDataWrite_UnMarkChild(devicetr)  
    DATA2:TrackDataWrite_MarkChildAppendsToCurrentParent(devicetr)   
    SetMediaTrackInfo_Value( devicetr, 'I_FOLDERDEPTH', 1 ) -- make device track folder 
    local ID_devicetr =  CSurf_TrackToID(devicetr, false ) 
    local deviceGUID =  GetTrackGUID( devicetr )
    GetSetMediaTrackInfo_String( devicetr, 'P_NAME', 'Note '..note, 1 )
    DATA2:TrackDataRead_GetChildrens_Device(devicetr, note0) 
    --[[DATA2.notes[note].device_isdevice = 1
    DATA2.notes[note].device_trID =  CSurf_TrackToID( devicetr, false )
    DATA2.notes[note].device_ptr =  devicetr
    DATA2.notes[note].device_GUID =  GetTrackGUID(devicetr)]]
    
    
    -- set layer 1 as a device child
    local layer1_ptr = DATA2.notes[note].layers[1].tr_ptr
    DATA2:TrackDataWrite_MarkChild(layer1_ptr, true, deviceGUID) 
    SetMediaTrackInfo_Value( layer1_ptr, 'I_FOLDERDEPTH',- 1 ) 
    
  end
  ----------------------------------------------------------------------- 
  function DATA2:PAD_onfiledrop_ReplaceLayer(note,layer0,filepath)
    local layer = layer0 or 1
    local new_tr = DATA2.notes[note].layers[layer].tr_ptr
    local instrument_pos = DATA2:GetFirstRS5k(new_tr)
    TrackFX_SetNamedConfigParm(  DATA2.notes[note].layers[layer].tr_ptr, DATA2.notes[note].layers[layer].instrument_pos, 'FILE0', filepath)
    TrackFX_SetNamedConfigParm(  DATA2.notes[note].layers[layer].tr_ptr, DATA2.notes[note].layers[layer].instrument_pos, 'DONE', '') 
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
    DATA2:TrackDataWrite_MarkParentFolder()  -- make sure folder is parent
    DATA2:TrackDataRead_ValidateMIDIbus()
    
    if not DATA2.notes[note] then 
    
      -- add new non-device child
      SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERDEPTH', 1 ) -- make sure parent folder get parent ono adding first child
      local new_tr = DATA2:PAD_onfiledrop_AddChildTrack() 
      DATA2:PAD_onfiledrop_ExportToRS5k(new_tr, filepath,note,filepath_sh) 
      DATA2:PAD_onfiledrop_AddMIDISend(new_tr)
      
     elseif DATA2.notes[note] and DATA2.notes[note].device_isdevice ~= true  and layer == 1 then 
      DATA2:PAD_onfiledrop_ReplaceLayer(note,1, filepath) -- replace existing sample into 1st layer 
      
     elseif DATA2.notes[note] and DATA2.notes[note].device_isdevice ~= true and layer ~= 1 then -- create device / move first layer to a device
      DATA2:PAD_onfiledrop_ConvertChildToDevice(note) 
      local device_trID = DATA2.notes[note].device_trID
      local new_tr = DATA2:PAD_onfiledrop_AddChildTrack(device_trID) 
      DATA2:PAD_onfiledrop_ExportToRS5k(new_tr, filepath,note,filepath_sh) 
      DATA2:PAD_onfiledrop_AddMIDISend(new_tr)
      DATA2:TrackDataWrite_MarkChild(new_tr, true, DATA2.notes[note].device_GUID)
      
     elseif DATA2.notes[note] and DATA2.notes[note].device_isdevice == true and DATA2.notes[note].layers[layer] then 
      DATA2:PAD_onfiledrop_ReplaceLayer(note,layer,filepath) -- replace existing sample into 1st layer -- replace sample in specific layer
      -- reserved
     elseif DATA2.notes[note] and DATA2.notes[note].device_isdevice == true and not DATA2.notes[note].layers[layer] then 
      local device_trID = DATA2.notes[note].device_trID
      local new_tr = DATA2:PAD_onfiledrop_AddChildTrack(device_trID) 
      DATA2:PAD_onfiledrop_ExportToRS5k(new_tr, filepath,note,filepath_sh) 
      DATA2:PAD_onfiledrop_AddMIDISend(new_tr)
      DATA2:TrackDataWrite_MarkChild(new_tr, true, DATA2.notes[note].device_GUID)
      
    end
  end
  -----------------------------------------------------------------------
  function DATA2:PAD_onfiledrop(note, layer, filepath0)
    if not DATA2.tr_valid then return end
    
    
    -- validate additional stuff
    DATA2:TrackDataRead_ValidateMIDIbus()
    SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERCOMPACT',1 ) -- folder compacted state (only valid on folders), 0=normal, 1=small, 2=tiny children
    DATA2:TrackDataRead(DATA2.tr_ptr)
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
      DATA_RESERVED_ONPROJCHANGE(DATA)
      --GUI_MODULE_DRUMRACKPAD(DATA)  
      --GUI_MODULE_SAMPLER(DATA)
  end
  ----------------------------------------------------------------------- 
    
  function DATA2:TrackData_SetTrackParams(src_t, parmname, newvalue)
    local track = src_t.tr_ptr
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
    local w_layername = DATA.GUI.buttons.devicestuff_frame.w - w_vol - w_pan - w_ctr*3 
    local ctrl_txtsz = DATA.GUI.custom_devicectrl_txtsz
    local frame_a = 0--DATA.GUI.custom_framea
    --local tr_extparams_note_active_layer = DATA2.tr_extparams_note_active_layer
    --if not tr_extparams_note_active_layer then tr_extparams_note_active_layer = 1 end
    local backgr_col=DATA.GUI.custom_backcol2
    local backgr_fill_param = 0.2
    --[[local backgr_fill =0 
    local backgr_fill_param = 0.2
    if tr_extparams_note_active_layer == layer then backgr_fill = DATA.GUI.custom_backfill2 end-- backgr_col = '#b6d7a8']]
    
    local backgr_fill_name = 0
    if DATA2.tr_extparams_note_active_layer and DATA2.tr_extparams_note_active_layer == layer then 
      backgr_fill_name = DATA.GUI.custom_backfill2 
    end
    -- name
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'name'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_layername-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        --ignoremouse = DATA2.tr_extparams_showstates&2==0,
                        txt = DATA2.notes[note].layers[layer].name,
                        txt_fontsz = ctrl_txtsz,
                        frame_a = frame_a,
                        backgr_fill = backgr_fill_name,
                        backgr_col =backgr_col,
                        onmouseclick = function() 
                          DATA2.tr_extparams_note_active_layer = layer 
                          GUI_MODULE_SAMPLER(DATA)
                          GUI_MODULE_DEVICE(DATA) 
                        end,
                        onmousefiledrop = function() DATA2:PAD_onfiledrop(note,layer) end,
                        }
    -- vol
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'] = { 
                        x=x_offs+w_layername,
                        y=y_offs,
                        w=w_vol-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        val = DATA2.notes[note].layers[layer].tr_vol/2,
                        val_res = -0.1,
                        val_xaxis = true,
                        txt = DATA2.notes[note].layers[layer].tr_vol_format,
                        txt_fontsz = ctrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        onmousedrag = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].val
                              DATA2:TrackData_SetTrackParams(src_t, 'D_VOL', new_val*2)
                              DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].txt = DATA2.notes[note].layers[layer].tr_vol_format
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].refresh = true
                              DATA2.ONPARAMDRAG = true
                            end,
                        onmouserelease = function()
                              if not DATA2.ONDOUBLECLICK then
                                DATA2.ONPARAMDRAG = nil
                                local src_t = DATA2.notes[note].layers[layer]
                                local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].val
                                DATA2:TrackData_SetTrackParams(src_t, 'D_VOL', new_val*2)
                                DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].txt = DATA2.notes[note].layers[layer].tr_vol_format
                                DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].refresh = true
                               else
                                DATA2.ONDOUBLECLICK = nil
                              end
                        end,
                        onmousedoubleclick = function() 
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = 1
                              DATA2:TrackData_SetTrackParams(src_t, 'D_VOL', new_val)
                              DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer) 
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].txt = DATA2.notes[note].layers[layer].tr_vol_format
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].refresh = true
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].val = 0.5
                              DATA2.ONDOUBLECLICK = true
                            end,
                        }   
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'] = { 
                        x=x_offs+w_layername+w_vol,
                        y=y_offs,
                        w=w_pan-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        val = DATA2.notes[note].layers[layer].tr_pan,
                        val_res = -0.6,
                        val_xaxis = true,
                        val_centered = true,
                        val_min = -1,
                        val_max = 1,
                        txt = DATA2.notes[note].layers[layer].tr_pan_format,
                        txt_fontsz = ctrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        onmousedrag = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].val
                              DATA2:TrackData_SetTrackParams(src_t, 'D_PAN', new_val)
                              DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = DATA2:FormatPan(new_val)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                              DATA2.ONPARAMDRAG = true
                            end,
                        onmouserelease = function()
                            if not DATA2.ONDOUBLECLICK then
                              DATA2.ONPARAMDRAG = nil
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].val
                              DATA2:TrackData_SetTrackParams(src_t, 'D_PAN', new_val)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = DATA2:FormatPan(new_val)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                             else
                              DATA2.ONDOUBLECLICK = nil
                            end
                        end,
                        onmousedoubleclick = function() 
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = 0
                              DATA2:TrackData_SetTrackParams(src_t, 'D_PAN', new_val)
                              DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer) 
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = DATA2:FormatPan(new_val)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].val = new_val
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                              DATA2.ONDOUBLECLICK = true
                            end,}   
                        
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
                              DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
                            end,
                        }     
                        
    local backgr_fill_param_en
    if DATA2.notes[note].layers[layer].tr_solo >0 then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'solo'] = { 
                        x=x_offs+w_layername+w_vol+w_pan+w_ctr*2,
                        y=y_offs,
                        w=w_ctr-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        txt = 'S',
                        txt_fontsz = ctrl_txtsz,
                        onmouserelease = function()DATA2:PAD_solo(note,layer) end,
                        }   
    local backgr_fill_param_en
    if DATA2.notes[note].layers[layer].tr_mute >0 then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'mute'] = { 
                        x=x_offs+w_layername+w_vol+w_pan+w_ctr,
                        y=y_offs,
                        w=w_ctr-reduce,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        txt = 'M',
                        txt_fontsz = ctrl_txtsz,
                        onmouserelease = function()DATA2:PAD_mute(note,layer) end,
                        }                         
  end
  ----------------------------------------------------------------------------- 
  function GUI_MODULE_DEVICE(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('devicestuff') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.tr_extparams_showstates or ( DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&2==0) then return end
    if not (DATA2.tr_extparams_note_active and DATA2.tr_extparams_note_active~=-1 and DATA2.notes[DATA2.tr_extparams_note_active] ) then return end
    local layers_cnt = 0
    if DATA2.notes[DATA2.tr_extparams_note_active].layers then 
      layers_cnt = #DATA2.notes[DATA2.tr_extparams_note_active].layers
    end
    
    local name = '' 
    if DATA2.tr_extparams_note_active and DATA2.notes[DATA2.tr_extparams_note_active] and DATA2.notes[DATA2.tr_extparams_note_active].name and not DATA2.notes[DATA2.tr_extparams_note_active].device_isdevice  then 
      name = '[Note '..DATA2.tr_extparams_note_active..' / '..DATA2:FormatMIDIPitch(DATA2.tr_extparams_note_active)..'] '..DATA2.notes[DATA2.tr_extparams_note_active].name 
     elseif DATA2.tr_extparams_note_active and DATA2.notes[DATA2.tr_extparams_note_active]  and DATA2.notes[DATA2.tr_extparams_note_active].device_isdevice ==true then
      name = '[Device '..DATA2.tr_extparams_note_active..' / '..DATA2:FormatMIDIPitch(DATA2.tr_extparams_note_active)..'] '..(DATA2.notes[DATA2.tr_extparams_note_active].device_name or '')
    end
    local x_offs = DATA.GUI.custom_offset +DATA.GUI.custom_settingsbut_w
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&16==16 then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&8==8 then x_offs = x_offs + DATA.GUI.custom_padgridw + DATA.GUI.custom_offset end -- pad view
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&1==1 then x_offs = x_offs + DATA.GUI.custom_padrackW + DATA.GUI.custom_offset end -- drrack
    
    local device_y = DATA.GUI.custom_infoh+DATA.GUI.custom_offset2
    
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
                          y=device_y,
                          w=DATA.GUI.custom_devicew+1,
                          h=DATA.GUI.custom_deviceh+DATA.GUI.custom_offset2,
                          ignoremouse = true,
                          frame_a =1,
                          frame_col = '#333333',
                          backgr_fill = 0,
                          }  
                          
    local y_offs = DATA.GUI.buttons.devicestuff_frame.y+ DATA.GUI.custom_offset2
    local w_dev = DATA.GUI.buttons.devicestuff_frame.w
    if DATA2.notes and DATA2.notes[tr_extparams_note_active] and DATA2.notes[tr_extparams_note_active].layers then 
      for layer = 1, #DATA2.notes[tr_extparams_note_active].layers do
        GUI_MODULE_DEVICE_stuff(DATA, tr_extparams_note_active, layer, y_offs)  
        y_offs = y_offs + DATA.GUI.custom_deviceentryh
      end
    end
    
    DATA.GUI.buttons.devicestuff_frame_fillactive = { x=x_offs,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_offset2,
                          w=DATA.GUI.custom_devicew,
                          h=y_offs - device_y,--DATA.GUI.custom_deviceh-DATA.GUI.custom_offset+DATA.GUI.custom_offset2,
                          ignoremouse = true,
                          frame_a =1,
                          frame_col = '#333333',
                          }
    DATA.GUI.buttons.devicestuff_droparea = { x=x_offs+1,
                          y=y_offs+DATA.GUI.custom_offset2,
                          w=DATA.GUI.custom_devicew-1,
                          h=DATA.GUI.custom_deviceh-(y_offs-device_y)-DATA.GUI.custom_offset2,
                          --ignoremouse = true,
                          txt = 'Drop new instrument here',
                          --frame_a =0.1,
                          --frame_col = '#333333',
                          onmousefiledrop = function() DATA2:PAD_onfiledrop(DATA2.tr_extparams_note_active, layers_cnt+1) end,
                          }                           
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_PADOVERVIEW_generategrid(DATA)
    if not DATA.GUI.buttons.padgrid then return end
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
    if DATA2.tr_extparams_showstates and DATA2.tr_extparams_showstates&16==16 and skip_grid~=true then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
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
    if DATA2.notes[note].layers[layer].ISPLUGIN then return end
    local offs_start = DATA2.notes[note].layers[layer].params_samplestoffs
    local offs_end = DATA2.notes[note].layers[layer].params_sampleendoffs
    local loopoffs = DATA2.notes[note].layers[layer].params_loopoffs
    local cached_len = DATA2.notes[note].layers[layer].cached_len
    
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
    local a_peaks_out = 0.05
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
        gfx.drawstr(VF_math_Qdec(pos,3))
        gfx.line(x1,y0+hgrid,x1,y0)
       else 
        gfx.line(x1,y0+hgrid2,x1,y0)
      end 
    end
    
    -- draw loop
    gfx.set(1,1,1,0.05)
    if not (offs_start<0.001 and offs_end>0.999) then
      local loopoffs_ms = loopoffs*30 + cached_len * offs_start
      local loopoffs_ratio = loopoffs_ms / cached_len
      local loop_st = x0+w*loopoffs_ratio
      local loop_end = x0+w*offs_end
      gfx.rect(loop_st,y0,loop_end-loop_st,h,1)
    end
  end  
  -----------------------------------------------------------------------  
  function DATA2:TrackData_SetRS5kParams(t, param, value)
    if not value then return end
    local track = t.tr_ptr
    if not (track  and ValidatePtr2(0,track,'MediaTrack*')) then return end
    local instrument_pos= t.instrument_pos
    if type(param)=='number' then
      TrackFX_SetParamNormalized( track, instrument_pos, param, value ) 
     else
      if type(param)=='string'then 
        if param == 'enabled' then reaper.TrackFX_SetEnabled( track, instrument_pos, value ) end
      end
    end
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_Loopstate_set(DATA,spl_t, note, layer, val)
    if not (spl_t and note and layer ) then return end
    if val then
      DATA2:TrackData_SetRS5kParams(spl_t, 12, val) -- set loop on 
      if val == 0 then 
        DATA2:TrackData_SetRS5kParams(spl_t, 11, 0) -- set obey note off OFF
      end
      DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(spl_t.tr_ptr, spl_t.instrument_pos, note,layer)
      GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
      return 
    end
    --[[local backgr_col,backgr_fill
    if spl_t.params_loop == 1 then 
      backgr_col = DATA.GUI.custom_backcol2 backgr_fill=DATA.GUI.custom_backfill2
      DATA.GUI.buttons.sampler_mode1.backgr_col=backgr_col
      DATA.GUI.buttons.sampler_mode1.backgr_fill=backgr_fill
     else
      backgr_col = DATA.GUI.custom_backcol2 backgr_fill=DATA.GUI.custom_backfill2
      DATA.GUI.buttons.sampler_mode2.backgr_col=backgr_col
      DATA.GUI.buttons.sampler_mode2.backgr_fill=backgr_fill
    end]]
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
    local spl_t, note, layer = DATA2:ActiveNoteLayer_GetTable()
    if not (spl_t and not spl_t.ISPLUGIN) then return end
    if not DATA.GUI.buttons.sampler_frame then return end
    local backgr_fill = 0
    local backgr_col = 0
    if DATA2.notes[note].layers[layer].params_loop == 1 then backgr_fill = 0.2 end
    DATA.GUI.buttons.sampler_mode1 = { x= DATA.GUI.buttons.sampler_frame.x ,
                        y=DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset2,
                        w=DATA.GUI.custom_spl_modew,
                        h=DATA.GUI.custom_spl_modeh-1,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = 'Loop',
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        onmouseclick = function() GUI_MODULE_SAMPLER_Section_Loopstate_set(DATA,spl_t, note, layer, 1) end,
                        } 
    local backgr_fill = 0
    local backgr_col = 0
    if DATA2.notes[note].layers[layer].params_loop == 0 then backgr_fill = 0.2 end
    DATA.GUI.buttons.sampler_mode2 = { x= DATA.GUI.buttons.sampler_frame.x,
                        y=DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_modeh+ DATA.GUI.custom_offset2+1 ,
                        w=DATA.GUI.custom_spl_modew,
                        h=DATA.GUI.custom_spl_modeh-2,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        txt = '1-shot',
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        onmouseclick = function() GUI_MODULE_SAMPLER_Section_Loopstate_set(DATA,spl_t, note, layer, 0) end,
                        } 
  end
  ----------------------------------------------------------------------
  function DATA2:ActiveNoteLayer_ShowRS5k(note, layer)
    if not (DATA2.notes and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[layer]) then MB('Sampler not found', '', 0) return end
    
    local track  = DATA2.notes[note].layers[layer].tr_ptr
    local rs5kpos = DATA2.notes[note].layers[layer].instrument_pos
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
      name = '[Layer '..layer..'] '..(spl_t.name or '')
      DATA.GUI.buttons.sampler_frame = { x=x_offs,
                            y=DATA.GUI.custom_infoh+DATA.GUI.custom_offset2,
                            w=DATA.GUI.custom_samplerW,
                            h=DATA.GUI.custom_deviceh-DATA.GUI.custom_offset+DATA.GUI.custom_offset2,
                            ignoremouse = true,
                            frame_a =1,
                            frame_col = '#333333',
                            } 
      DATA.GUI.buttons.sampler_name = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_sampler_namebutw-DATA.GUI.custom_offset2,
                           h=DATA.GUI.custom_infoh,
                           txt = name,
                           }
      DATA.GUI.buttons.sampler_show = { x=x_offs+DATA.GUI.custom_sampler_namebutw,
                           y=0,
                           w=DATA.GUI.custom_sampler_showbutw-1,
                           h=DATA.GUI.custom_infoh,
                           txt = 'Show',
                           onmouserelease = function() DATA2:ActiveNoteLayer_ShowRS5k(note, layer) end,
                           }                     
                          
    if not spl_t.ISPLUGIN then GUI_MODULE_SAMPLER_Section_SplPeakFrame(DATA) end
    GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
    GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) 
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs(DATA) 
    GUI_MODULE_SAMPLER_Section_FilterKnobs(DATA) 
    DATA2:SAMPLER_GetPeaks() 
    --GUI_MODULE_SAMPLER_peaks()
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_SplPeakFrame(DATA)  
    if not tr_ptr_last or (tr_ptr_last and tr_ptr_last ~= DATA2.tr_ptr) then
      DATA.GUI.buttons.sampler_framepeaks = { x= DATA.GUI.buttons.sampler_frame.x + DATA.GUI.custom_offset2+DATA.GUI.custom_spl_modew,
                          y=DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset2,
                          w=DATA.GUI.custom_sampler_peaksw,
                          h=DATA.GUI.custom_spl_areah,
                          --ignoremouse = true,
                          frame_a = DATA.GUI.custom_framea,
                          data = {['datatype'] = 'samplepeaks'},
                          onmousefiledrop = function() if DATA2.tr_extparams_note_active then DATA2:PAD_onfiledrop(DATA2.tr_extparams_note_active) end end,
                          onmouseclick = function() DATA2:Stuff_NoteOn(DATA2.tr_extparams_note_active)  end,
                          refresh = true,
                          }
    end
  end  
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) 
    local src_t, note, layer = DATA2:ActiveNoteLayer_GetTable()
    
    local val_res = 0.03
    local woffs= DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2
    local xoffs= DATA.GUI.buttons.sampler_frame.x
    local yoffs= DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_areah+DATA.GUI.custom_offset2*2
    
    xoffs = xoffs + 0
    local paramid = 0
    if src_t.params_vol_id then paramid = src_t.params_vol_id  end
    local ctrlname = 'Gain'
    if src_t.params_vol_name then ctrlname =src_t.params_vol_name end
    GUI_CTRL_Readout(DATA,
      {
        key = 'spl_gain',
        ctrlname = ctrlname,
        val_format_key = 'params_vol_format',
        val = src_t.params_vol,
        paramid = paramid,
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
    local paramid = 15
    if src_t.params_pitchoffs_id then paramid = src_t.params_pitchoffs_id  end
    local ctrlname = 'Tune'
    if src_t.params_pitchoffs_name then ctrlname =src_t.params_pitchoffs_name end
    GUI_CTRL_Readout(DATA,
      {
        key = 'spl_pitchoffs',
        ctrlname = ctrlname,
        val_format_key = 'params_pitchoffs_format',
        val = src_t.params_pitchoffs,
        paramid = paramid,
        val_default = 0.5,
        val_iscentered = true,
        val_res = val_res,
        src_t = src_t,
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_spl_modew,
        h = DATA.GUI.custom_splctrl_h*2,
        note =note,
        layer=layer
      } )    
    
    
    
    if src_t.ISPLUGIN then return end
    
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
    
    

    local st_s = DATA2.notes[note].layers[layer].params_samplestoffs * DATA2.notes[note].layers[layer].cached_len
    local end_s = DATA2.notes[note].layers[layer].params_sampleendoffs * DATA2.notes[note].layers[layer].cached_len
    local max_offs_s = (end_s - st_s) / 30
    
    xoffs = xoffs + woffs
    GUI_CTRL_Readout(DATA,
      {
        key = 'spl_loopoffs',
        ctrlname = 'Loop offs',
        val_format_key = 'params_loopoffs_format',
        val = src_t.params_loopoffs,
        val_min = 0,
        val_max = max_offs_s,
        paramid = 23,
        val_default = 0,
        
        val_res = 0.05,
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
          key = 'spl_maxvoices',
          ctrlname = 'Voices',
          val_format_key = 'params_maxvoices_format',
          val = src_t.params_maxvoices,
          paramid = 8,
          val_default = 0,
          
          val_res = 0.05,
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
  function GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_app(DATA, prefix,key,paramid,src_t,note,layer,val_format_key, val_default,new_val)  
    if not new_val then return end
    DATA2:TrackData_SetRS5kParams(src_t, paramid, new_val)
    DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
    DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
    DATA.GUI.buttons[prefix..key..'val'].refresh = true
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,xoffs,val_default, val_max)
    local prefix = 'sampler_'
    GUI_CTRL_Knob(DATA,
      {
        prefix = prefix,
        key = key,
        ctrlname = ctrlname,
        paramid=paramid,
        val = src_t[param_val],
        val_res = 0.2,
        val_format = DATA2.notes[note].layers[layer][val_format_key],
        val_min = 0,
        val_max = val_max,
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
          GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_app(DATA, prefix,key,paramid,src_t,note,layer,val_format_key, val_default,new_val)  
          DATA2.ONPARAMDRAG = true
        end  ,
        f_release= function()    
          if not DATA2.ONDOUBLECLICK then
            local new_val = DATA.GUI.buttons[prefix..key..'knob'].val
            GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_app(DATA, prefix,key,paramid,src_t,note,layer,val_format_key, val_default,new_val)  
            DATA2.ONPARAMDRAG = nil
           else
            DATA2.ONDOUBLECLICK = nil
          end
        end  ,        
        f_double= function() 
          local new_val = val_default
          GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_app(DATA, prefix,key,paramid,src_t,note,layer,val_format_key, val_default,new_val)  
          DATA2.ONDOUBLECLICK = true
        end  ,
      } )
    end
  -----------------------------------------------------------------------  
  function DATA2:TrackData_ValidateReaEQ(track)
    local reaeq_pos = TrackFX_AddByName( track, 'ReaEQ', 0, 1 )
    TrackFX_Show( track, reaeq_pos, 2 )
    TrackFX_SetNamedConfigParm( track, reaeq_pos, 'BANDTYPE0',3 )
    TrackFX_SetParamNormalized( track, reaeq_pos, 0, 1 ) 
    return reaeq_pos
  end
  -----------------------------------------------------------------------  
  function DATA2:TrackData_ValidateWS(track)
    local ws_pos = TrackFX_AddByName( track, 'waveShapingDstr', 0, 1 )
    TrackFX_Show( track, ws_pos, 2 )
    TrackFX_SetParamNormalized( track, ws_pos, 0, 0 ) 
    return ws_pos
  end 
  -----------------------------------------------------------------------  
  function DATA2:TrackData_SetDriveParams(t, param, value)
    local track = t.tr_ptr
    if not (track  and ValidatePtr2(0,track,'MediaTrack*')) then return end
    
    local reaeq_pos 
    if not t.ws_valid then ws_pos = DATA2:TrackData_ValidateWS(track)  else  ws_pos= t.ws_pos end
    
    TrackFX_SetParamNormalized( track, ws_pos, param, value ) 
  end  
  -----------------------------------------------------------------------  
  function DATA2:TrackData_SetReaEQParams(t, param, value)
    local track = t.tr_ptr
    if not (track  and ValidatePtr2(0,track,'MediaTrack*')) then return end
    
    local reaeq_pos 
    if not t.reaeq_valid then reaeq_pos = DATA2:TrackData_ValidateReaEQ(track)  else  reaeq_pos= t.reaeq_pos end
    
    if type(param)=='number' then
      TrackFX_SetParamNormalized( track, reaeq_pos, param, value ) 
     else
      if type(param)=='string'then 
        if param == 'enabled' then TrackFX_SetNamedConfigParm( track, reaeq_pos, 'BANDENABLED0',value )
         elseif param == 'bandtype' then TrackFX_SetNamedConfigParm( track, reaeq_pos, 'BANDTYPE0',value ) 
        end
      end
    end
  end    
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_FilterKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,xoffs,val_default, val_max)
    if not src_t then return end
    local prefix = 'sampler_'
    GUI_CTRL_Knob(DATA,
      {
        prefix = prefix,
        key = key,
        ctrlname = ctrlname,
        val = src_t[param_val],
        val_res = 0.1,
        val_format = DATA2.notes[note].layers[layer][val_format_key] ,
        val_min = 0,
        val_max = val_max,
        paramid=paramid,
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
          if not new_val then DATA2:TrackData_SetReaEQParams(src_t, -1, -1) return end
          DATA2:TrackData_SetReaEQParams(src_t, paramid, new_val)
          DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
          DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
          DATA.GUI.buttons[prefix..key..'val'].refresh = true   
          DATA2.ONPARAMDRAG = true
        end  ,
        f_release= function()    
          if not DATA2.ONDOUBLECLICK then
            local new_val = DATA.GUI.buttons[prefix..key..'knob'].val
            if not new_val then return end
            DATA2:TrackData_SetReaEQParams(src_t, paramid, new_val)
            DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
            DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
            DATA.GUI.buttons[prefix..key..'val'].refresh = true   
            DATA2.ONPARAMDRAG = nil
           else
            DATA2.ONDOUBLECLICK = nil
          end
        end  ,  
      } )
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_FilterKnobs(DATA)   
    local src_t, note, layer = DATA2:ActiveNoteLayer_GetTable()
    
    local key = 'spl_reaeq_cut'
    local val_format_key = 'reaeq_cut_format'
    local param_val = 'reaeq_cut'
    local ctrlname = 'Freq'
    local val_default = 0 
    local prefix = 'sampler_'
    local paramid = 0
    GUI_MODULE_SAMPLER_Section_FilterKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val, (DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*1, val_default, val_max)
    
    local key = 'spl_reaeq_gain'
    local val_format_key = 'reaeq_gain_format'
    local param_val = 'reaeq_gain'
    local ctrlname = 'Gain'
    local val_default = 0 
    local prefix = 'sampler_'
    local paramid = 1
    GUI_MODULE_SAMPLER_Section_FilterKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val, (DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*2, val_default, val_max)
    --[[
    local key = 'spl_reaeq_bw'
    local val_format_key = 'reaeq_bw_format'
    local param_val = 'reaeq_bw'
    local ctrlname = 'BW'
    local val_default = 0 
    local prefix = 'sampler_'
    local paramid = 2
    GUI_MODULE_SAMPLER_Section_FilterKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val, (DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*3, val_default, val_max)]]
    
    DATA.GUI.buttons.sampler_spl_reaeq_toggle = { 
                        x = DATA.GUI.buttons.sampler_frame.x,
                        y=DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_areah+DATA.GUI.custom_offset2*3+DATA.GUI.custom_splctrl_h*2,
                        w = DATA.GUI.custom_splctrl_h,
                        h = DATA.GUI.custom_splctrl_h,
                        --ignoremouse = true,
                        txt = '',
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        --frame_a =DATA.GUI.custom_framea,
                        state = DATA2.notes[note].layers[layer].reaeq_enabledband1==1,
                        onmouserelease = function() 
                          local cur = 0
                          if DATA2.notes[note].layers[layer].reaeq_enabledband1 then cur = DATA2.notes[note].layers[layer].reaeq_enabledband1 end
                          local out = math.abs(1-cur)
                          DATA2:TrackData_SetReaEQParams(src_t, 'enabled', out) 
                          DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
                          DATA.GUI.buttons.sampler_spl_reaeq_toggle.refresh = true
                          GUI_MODULE_SAMPLER_Section_FilterKnobs(DATA)  
                        end
                        } 
                        
    DATA.GUI.buttons.sampler_spl_reaeq_togglename = { 
                        x = DATA.GUI.buttons.sampler_frame.x+DATA.GUI.custom_splctrl_h+DATA.GUI.custom_offset2,
                        y=DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_areah+DATA.GUI.custom_offset2*3+DATA.GUI.custom_splctrl_h*2,
                        w = DATA.GUI.custom_spl_modew-DATA.GUI.custom_splctrl_h-DATA.GUI.custom_offset2,
                        h = DATA.GUI.custom_splctrl_h,
                        ignoremouse = true,
                        txt = 'Filter',
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        --frame_a =DATA.GUI.custom_framea, 
                        } 
    DATA.GUI.buttons.sampler_spl_reaeq_bandtype = { 
                        x = DATA.GUI.buttons.sampler_frame.x,
                        y=DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_areah+DATA.GUI.custom_offset2*4+DATA.GUI.custom_splctrl_h*3,
                        w = DATA.GUI.custom_spl_modew,
                        h = DATA.GUI.custom_splctrl_h,
                        --ignoremouse = true,
                        txt = DATA2.notes[note].layers[layer].reaeq_bandtype_format,
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        onmouserelease = function() 
                          local function GUI_MODULE_SAMPLER_Section_FilterKnobs_addknob_setband(src_t,note,layer,out)
                            DATA2:TrackData_SetReaEQParams(src_t, 'bandtype', out) 
                            DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
                            DATA.GUI.buttons.sampler_spl_reaeq_bandtype.refresh = true
                            GUI_MODULE_SAMPLER_Section_FilterKnobs(DATA)
                          end
                          local t = {}
                          for key in pairs(DATA2.custom_sampler_bandtypemap) do
                            t[#t+1] = {str = DATA2.custom_sampler_bandtypemap[key],
                                        func = function() GUI_MODULE_SAMPLER_Section_FilterKnobs_addknob_setband(src_t,note,layer,key) end
                                      }
                          end
                          DATA:GUImenu(t)
                        end
                        }  
                        
    local key = 'spl_ws_drive'
    local val_format_key = 'ws_drive_format'
    local param_val = 'ws_drive'
    local ctrlname = 'Drive'
    local val_default = 0 
    local prefix = 'sampler_'
    local paramid = 0 
    if not src_t then return end
    local prefix = 'sampler_'
    GUI_CTRL_Knob(DATA,
      {
        prefix = prefix,
        key = key,
        ctrlname = ctrlname,
        val = src_t[param_val],
        val_res = 0.1,
        val_format = DATA2.notes[note].layers[layer][val_format_key] ,
        val_min = 0,
        val_max = val_max,
        paramid=paramid,
        --val_res = 0.05,
        src_t = src_t,
        x = DATA.GUI.buttons.sampler_frame.x+((DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*3 or 0 ),
        y=DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_spl_areah+DATA.GUI.custom_offset2*3+DATA.GUI.custom_splctrl_h*2,
        w = DATA.GUI.custom_spl_modew,
        h = DATA.GUI.custom_splknob_h,
        note =note,
        layer=layer,
        frame_arcborder=true,
        f= function()     
          local new_val = DATA.GUI.buttons[prefix..key..'knob'].val
          if not new_val then DATA2:TrackData_SetDriveParams(src_t, 0, 0) return end
          DATA2:TrackData_SetDriveParams(src_t, paramid, new_val)
          DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
          DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
          DATA.GUI.buttons[prefix..key..'val'].refresh = true   
          DATA2.ONPARAMDRAG = true
        end  ,
        f_release= function()    
          if not DATA2.ONDOUBLECLICK then
            local new_val = DATA.GUI.buttons[prefix..key..'knob'].val
            if not new_val then return end
            DATA2:TrackData_SetDriveParams(src_t, paramid, new_val)
            DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(src_t.tr_ptr, src_t.instrument_pos, note,layer)
            DATA.GUI.buttons[prefix..key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
            DATA.GUI.buttons[prefix..key..'val'].refresh = true   
            DATA2.ONPARAMDRAG = nil
           else
            DATA2.ONDOUBLECLICK = nil
          end
        end  ,  
      } )
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_EnvelopeKnobs(DATA)   
    local src_t, note, layer = DATA2:ActiveNoteLayer_GetTable()
    
    local paramid = 9
    if src_t.params_attack_id then paramid = src_t.params_attack_id  end
    local key = 'spl_attack'
    local val_format_key = 'params_attack_format'
    local param_val = 'params_attack'
    local ctrlname = 'Attack'
    if src_t.params_attack_name then ctrlname =src_t.params_attack_name end
    local val_default = 0 
    local val_max = 1
    if not src_t.ISPLUGIN then 
      val_max = DATA2.notes[note].layers[layer].cached_len/2
    end
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val, (DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*4, val_default, val_max)
    
    local paramid = 24
    if src_t.params_decay_id then paramid = src_t.params_decay_id end
    local key = 'spl_decay'
    local val_format_key = 'params_decay_format'
    local param_val = 'params_decay'
    local ctrlname = 'Decay'
    if src_t.params_decay_name then ctrlname =src_t.params_decay_name end
    local val_default = 0.016010673716664
    local val_max = 1
    if not src_t.ISPLUGIN then 
      val_max = DATA2.notes[note].layers[layer].cached_len/15
    end
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,(DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*5, val_default, val_max)
    
    local paramid = 25
    if src_t.params_sustain_id then paramid = src_t.params_sustain_id end
    local key = 'spl_sustain'
    local val_format_key = 'params_sustain_format'
    local param_val = 'params_sustain'
    local ctrlname = 'Sustain'
    if src_t.params_sustain_name then ctrlname =src_t.params_sustain_name end
    local val_default = 0.5
    local val_max = 1
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,(DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*6, val_default, val_max)
    
    local paramid = 10
    if src_t.params_release_id then paramid = src_t.params_release_id end
    local key = 'spl_release'
    local val_format_key = 'params_release_format'
    local param_val = 'params_release'
    local ctrlname = 'Release'
    if src_t.params_release_name then ctrlname =src_t.params_release_name end
    local val_default = 0.0005
    local val_max = 1
    if not src_t.ISPLUGIN then 
      val_max = DATA2.notes[note].layers[layer].cached_len/2
    end
    GUI_MODULE_SAMPLER_Section_EnvelopeKnobs_addknob(DATA, key,ctrlname,paramid,src_t,note,layer,val_format_key,param_val,(DATA.GUI.custom_spl_modew+DATA.GUI.custom_offset2)*7, val_default, val_max)
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
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
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
                        txt_fontsz = DATA.GUI.custom_splknob_txtsz,
                        onmousedoubleclick = function() 
                                if t.val_default then 
                                  DATA2:TrackData_SetRS5kParams(t.src_t, t.paramid, t.val_default)
                                  DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(t.src_t.tr_ptr, t.src_t.instrument_pos, note,layer)
                                  DATA.GUI.buttons['sampler_'..t.key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
                                  DATA.GUI.buttons['sampler_'..t.key..'val'].refresh = true
                                  DATA2.ONDOUBLECLICK = true
                                end
                              end,
                        onmousedrag = function()
                              DATA2.ONPARAMDRAG = true
                              local new_val = DATA.GUI.buttons['sampler_'..t.key..'val'].val
                              DATA2:TrackData_SetRS5kParams(t.src_t, t.paramid, new_val)
                              DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(t.src_t.tr_ptr, t.src_t.instrument_pos, note,layer)
                              DATA.GUI.buttons['sampler_'..t.key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
                              DATA.GUI.buttons['sampler_'..t.key..'val'].refresh = true
                            end,
                        onmouserelease = function()
                              if not DATA2.ONDOUBLECLICK then
                                local new_val = DATA.GUI.buttons['sampler_'..t.key..'val'].val
                                DATA2:TrackData_SetRS5kParams(t.src_t, t.paramid, new_val)
                                DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(t.src_t.tr_ptr, t.src_t.instrument_pos, note,layer)
                                DATA.GUI.buttons['sampler_'..t.key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
                                DATA.GUI.buttons['sampler_'..t.key..'val'].refresh = true
                                DATA2.ONPARAMDRAG = false
                               else
                                DATA2.ONDOUBLECLICK = nil
                              end
                        end,
                        onmousereleaseR = function()
                                local retval, new_val = GetUserInputs( 'Set values', 1, '', DATA2.notes[note].layers[layer][val_format_key] )
                                if not (retval and new_val~='' ) then return end 
                                local new_val = VF_BFpluginparam(new_val,t.src_t.tr_ptr, t.src_t.instrument_pos, t.paramid)  
                                --msg(new_val)
                                DATA2:TrackData_SetRS5kParams(t.src_t, t.paramid, new_val)
                                DATA2:TrackDataRead_GetChildrens_GetSampleDataParams(t.src_t.tr_ptr, t.src_t.instrument_pos, note,layer)
                                DATA.GUI.buttons['sampler_'..t.key..'val'].txt = DATA2.notes[note].layers[layer][val_format_key]
                                DATA.GUI.buttons['sampler_'..t.key..'val'].refresh = true
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
    
    if DATA2.recentmsg_trig == true and DATA.extstate.UI_donotupdateonplay == 0 then  
      DATA2.tr_extparams_note_active = DATA2.playingnote_pitch 
      DATA2.tr_extparams_note_active_layer = 1 
      DATA2:TrackDataWrite() 
      GUI_MODULE_PADOVERVIEW_generategrid(DATA) -- refresh pad
      GUI_MODULE_DRUMRACKPAD(DATA)  
    end
    
    if DATA2.recentmsg_trig == true and DATA2.recentmsg_isNoteOn == true and DATA.extstate.UI_incomingnoteselectpad == 1 then 
      DATA2.tr_extparams_note_active = DATA2.playingnote_pitch 
      DATA2.tr_extparams_note_active_layer = 1 
      DATA2:TrackDataWrite() 
      GUI_MODULE_DRUMRACKPAD(DATA)  
      GUI_MODULE_DEVICE(DATA)  
      GUI_MODULE_SAMPLER(DATA)
    end
    
    
    if DATA2.FORCEONPROJCHANGE == true then DATA_RESERVED_ONPROJCHANGE(DATA) DATA2.FORCEONPROJCHANGE = nil end
  end
  
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end
  
  
  
  --[[
    ---------------------------------------------------
    function v2 ExtState_Def()
  
              -- various
              draggedfile_fxchain = '',
              --copy_src_media = 0,
              
               -- Pads
              keymode = 0,  -- 0-keys
              oct_shift = -1, -- note names
              key_names2 = '#midipitch #keycsharp |#notename #samplecount |#samplename' ,
              
              

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
                       if    note%12 == 1 
                         or  note%12 == 3 
                         or  note%12 == 6 
                         or  note%12 == 8 
                         or  note%12 == 10 
                         then obj['keys_p'..note].txt_col = 'black' 
                       end
                         
                         
                   end
                 end
               
                 
    
               
               
               
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
                   
           
             
             { str = 'Allow pads drag to copy/move|<',  
               state = conf.allow_dragpads&1==1,
               func =  function() 
                         conf.allow_dragpads = math.abs(1-conf.allow_dragpads)
                       end },      

      ]]