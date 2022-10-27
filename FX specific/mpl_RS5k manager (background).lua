-- @description RS5k manager
-- @version 3.0beta31
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic5000 data on group of connected tracks
-- @provides
--    mpl_RS5k manager_MacroControls.jsfx
-- @changelog
--    # fix nil parent track


--[[ 
3.0beta25 17.10.2022 
--    # Pad Overview: fix incorrect view at some scales
--    # Sampler: fix doubleclick on filter / drive section
--    # Settings: remove "Do not update on play"
--    # Settings: move and rename 'Incoming note activate pad' to UI/'Active note follow incoming note'

3.0beta24 16.10.2022 
--    + Pad Overview: drop on pad overview add sample(s) to first available note starting this area

3.0beta23 15.10.2022 
--    + Sampler: Actions menu by click on actions button or rightclick peaks
--    + Sample/Actions: set start offset to loudest peak
--    + Sample/Actions: crop start/end offset to item boundaries
--    + Settings: allow to set threshold for crop start/end item boundaries
--    # GUI: various retina/scaling mode tweaks
--    # fix header (properly added Macro JSFX)
--    # Cleanup GUI variables, hopefully fix various retina problems
--    # Sampler: fix corner case error on trigger note via peaks
--    # Sampler: turn Attack control powered by y=x^2
--    # DrumRack: fix  clear device

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
    DATA.extstate.version = '3.0beta31'
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
                          
                          -- Actions
                          CONF_cropthreshold = -60, -- db
                          
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          UI_processoninit = 0,
                          --UI_donotupdateonplay = 0,
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
  function DATA2:Actions_Help(page)
    if page == 0 then  -- drumrack
      MB(
[[
Controls:
  M = mute
  S = solo
  > = play
  MediaExp = show current note sample in browser
   
Pads:
  Click on pad name = set current note active
  Drag to other pad = Move/Replace pad content
  Ctrl+drag to other pad = Copy pad (unavailable for existing pads, not supposed to work for devices)
]]
      ,'RS5k manager: drumrack',0)
    
    elseif page == 1 then  -- device
      MB(
[[
Controls:
  slider1 = Child track volume
  slider2 = Child track pan
  On = Bypass instrument FX
  S = solo
  M = mute
  MediaExp = show current note sample in browser
   
Device childs:
  Click on child name = set current layer active
  Drop to area = Add child to device
]]
      ,'RS5k manager: device',0)
        
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataWrite(tr, t)
    
    -- parent 
    local master_set if t.master_set then                                                     master_set = true           tr = DATA2.tr_ptr end 
    local master_upd if t.master_upd then                                                     master_upd = true           tr = DATA2.tr_ptr end
     
    
    
    --[[
    master_set
    master_upd
    MACRO_GUID
    
    setchild
    setnote_ID
    set_currentparentforchild
    setmidifilt_FXGUID
    setinstr_FXGUID
    is_rs5k
    FX_REAEQ_GUID
    FX_WS_GUID
    INSTR_PARAM_VOL/TUNE/ADSR
    
    setdevice
    
    setmidibus
    
    set_devicechild_deviceGUID
    ]]
    
    
    if not ValidatePtr2(0,tr,'MediaTrack*') then return end
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.extstate.version, true)
    
    -- master stuff ----------------------------------------
      if t.master_set then
        SetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH',1 )
        return
      end 
      if t.master_upd then  
        if DATA2.tr_valid == false or not DATA2.PARENT_LASTACTIVENOTE then return end 
        local extstr = 
          'PARENT_ACTIVEPAD '..DATA2.PARENT_ACTIVEPAD..'\n'.. 
          'PARENT_LASTACTIVENOTE '..DATA2.PARENT_LASTACTIVENOTE..'\n'.. 
          'PARENT_TABSTATEFLAGS '..DATA2.PARENT_TABSTATEFLAGS..'\n'.. 
          'PARENT_MACROCNT '..DATA2.PARENT_MACROCNT..'\n' 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN', extstr, true)  
        return 
      end
      if t.MACRO_GUID then
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_MACRO_GUID', t.MACRO_GUID, true) 
      end
      
    -- all children ---------------------------------------- 
      if t.set_currentparentforchild then  
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', DATA2.tr_GUID, true)
        return
      end  
      if t.setchild then
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', 1, true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', '', true) 
        return
      end
      if t.setnote_ID then
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_NOTE', t.setnote_ID, true) 
        return
      end
      if t.setinstr_FXGUID then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_FXGUID', t.setinstr_FXGUID, true)
        return
      end
      if t.is_rs5k then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_ISRS5K', 1, true)
        return
      end      
      if t.setmidifilt_FXGUID then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_MIDIFILTGUID', t.setmidifilt_FXGUID, true)
        return
      end
      if t.FX_REAEQ_GUID then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FX_REAEQ_GUID', t.FX_REAEQ_GUID, true) 
        return
      end      
      if t.FX_WS_GUID then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FX_WS_GUID', t.FX_WS_GUID, true)
        return
      end      
      if t.INSTR_PARAM_CACHE then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_CACHE', t.INSTR_PARAM_CACHE, true) return end
      if t.INSTR_PARAM_VOL then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_VOL', t.INSTR_PARAM_VOL, true) return end
      if t.INSTR_PARAM_TUNE then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_TUNE', t.INSTR_PARAM_TUNE, true) return end
      if t.INSTR_PARAM_ATT then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_ATT', t.INSTR_PARAM_ATT, true) return end
      if t.INSTR_PARAM_DEC then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_DEC', t.INSTR_PARAM_DEC, true) return end
      if t.INSTR_PARAM_SUS then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_SUS', t.INSTR_PARAM_SUS, true) return end
      if t.INSTR_PARAM_REL then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_REL', t.INSTR_PARAM_REL, true) return end
      
    -- device ----------------------------------------
      if t.setdevice then
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE', 1, true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', '', true)
        return
      end
    
    -- MIDI bus  ----------------------------------------
      if t.setmidibus then
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_MIDIBUS', 1, true)
        return
      end
      
    -- device childs  ----------------------------------------   
      if t.set_devicechild_deviceGUID then
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', 1, true) 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', '', true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD_PARENTDEVICEGUID', t.set_devicechild_deviceGUID, true) 
        return
      end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetParent_ParseExt(track)
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
  function DATA2:TrackDataRead_GetChildrens_TrackParams(note_layer_t)
    if not note_layer_t then return end
    if not note_layer_t.tr_ptr then return end
    local track = note_layer_t.tr_ptr 
    if not track then return end
    -- handle track parameters
    local tr_vol = GetMediaTrackInfo_Value( track, 'D_VOL' )
    local tr_vol_format = WDL_VAL2DB(tr_vol,2) ..'dB'
    local tr_pan = GetMediaTrackInfo_Value( track, 'D_PAN' )
    local tr_pan_format = DATA2:internal_FormatPan(tr_pan)
    local tr_mute = GetMediaTrackInfo_Value( track, 'B_MUTE' )
    local tr_solo = GetMediaTrackInfo_Value( track, 'I_SOLO' )
    local tr_col = GetMediaTrackInfo_Value( track, 'I_CUSTOMCOLOR' )
    local retval, tr_name = GetTrackName( track )
    if tr_col&0x1000000==0x1000000 then tr_col = tr_col-0x1000000 end
    if tr_col==16576 then tr_col = nil end
    if tr_col==0 then tr_col = nil end
    if tr_col then 
      r, g, b = reaper.ColorFromNative( tr_col )
      tr_col = ColorToNative( b, g, r )
    end
    
    note_layer_t.tr_vol = tr_vol
    note_layer_t.tr_vol_format = tr_vol_format
    note_layer_t.tr_pan = tr_pan
    note_layer_t.tr_pan_format = tr_pan_format
    note_layer_t.tr_mute = tr_mute
    note_layer_t.tr_solo = tr_solo
    note_layer_t.tr_col = tr_col
    note_layer_t.tr_name = tr_name
  end
  ---------------------------------------------------------------------  
  function DATA2:internal_FormatPan(tr_pan) 
    local tr_pan_format = 'C'
    if tr_pan > 0 then 
      tr_pan_format = math.floor(math.abs(tr_pan*100))..'R'
     elseif tr_pan < 0 then 
      tr_pan_format = math.floor(math.abs(tr_pan*100))..'L'
    end
    return tr_pan_format
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_FXParams(note_layer_t)  
  
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
        note_layer_t.fx_reaeq_cut_format = ({TrackFX_GetFormattedParamValue( track, reaeqpos, 0 )})[2]..'Hz'
        note_layer_t.fx_reaeq_gain_format = ({TrackFX_GetFormattedParamValue( track, reaeqpos, 1 )})[2]..'dB'
        note_layer_t.fx_reaeq_bw_format = ({TrackFX_GetFormattedParamValue( track, reaeqpos, 2 )})[2]
        note_layer_t.fx_reaeq_bandenabled = ({TrackFX_GetNamedConfigParm( track, reaeqpos, 'BANDENABLED0' )})[2]=='1'
        note_layer_t.fx_reaeq_bandtype = tonumber(({TrackFX_GetNamedConfigParm( track, reaeqpos, 'BANDTYPE0' )})[2])
        local reaeq_bandtype_format = ''
        if DATA2.custom_sampler_bandtypemap and DATA2.custom_sampler_bandtypemap[note_layer_t.fx_reaeq_bandtype] then reaeq_bandtype_format = DATA2.custom_sampler_bandtypemap[note_layer_t.fx_reaeq_bandtype] end
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
  function DATA2:TrackDataRead_ValidateMIDIbus() 
    if (DATA2.MIDIbus and DATA2.MIDIbus.ptr and ValidatePtr2(0,DATA2.MIDIbus.ptr,'MediaTrack*')) then return end 
    
    InsertTrackAtIndex( DATA2.tr_ID, false )
    local new_tr = CSurf_TrackFromID( DATA2.tr_ID+1,false)
    DATA2:TrackDataWrite(new_tr, {set_currentparentforchild = true})  
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', 'MIDI bus', 1 )
    SetMediaTrackInfo_Value( new_tr, 'I_RECMON', 1 )
    SetMediaTrackInfo_Value( new_tr, 'I_RECARM', 1 )
    SetMediaTrackInfo_Value( new_tr, 'I_RECMODE', 0 ) -- record MIDI out
    local channel,physical_input = 0, DATA.extstate.CONF_midiinput
    SetMediaTrackInfo_Value( new_tr, 'I_RECINPUT', 4096 + channel + (physical_input<<5)) -- set input to all MIDI
    DATA2:TrackDataWrite(new_tr, {setmidibus=true})  
    DATA2:TrackDataRead()
    
    
    -- 
    local cnt = 0
    for key in pairs(DATA2.notes) do cnt = cnt+ 1 end
    if cnt == 0 then SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH',-1 ) end
    
  end

  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_IsChildAppendsToCurrentParent(track)   
    local ret, parGUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', '', false)
    if DATA2.tr_GUID and parGUID == DATA2.tr_GUID then ret = true end 
    return ret, parGUID
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_ExtState(track) 
    if DATA2:TrackDataRead_IsChildAppendsToCurrentParent(track) ~= true  then return end
    
    -- handle MIDI bus --------------------------
      local _, isMIDIbus = GetSetMediaTrackInfo_String      ( track, 'P_EXT:MPLRS5KMAN_MIDIBUS', 0, false) isMIDIbus = (tonumber(isMIDIbus) or 0)==1  
      if isMIDIbus then  DATA2.MIDIbus = { ptr = track, ID = CSurf_TrackToID( track, false ) } return  end 
    
    local ret, note = GetSetMediaTrackInfo_String         ( track, 'P_EXT:MPLRS5KMAN_NOTE',0, false) note = tonumber(note) local layer = 1
    
    local ret, TYPE_REGCHILD = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', 0, false) TYPE_REGCHILD = (tonumber(TYPE_REGCHILD) or 0)==1   if not TYPE_REGCHILD then TYPE_REGCHILD = nil end
    local ret, INSTR_FXGUID = GetSetMediaTrackInfo_String  ( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_FXGUID', 0, false)   if INSTR_FXGUID == '' then INSTR_FXGUID = nil end
    local ret, MIDIFILTGUID = GetSetMediaTrackInfo_String  ( track, 'P_EXT:MPLRS5KMAN_CHILD_MIDIFILTGUID', 0, false)  if MIDIFILTGUID == '' then MIDIFILTGUID = nil end
         
    local ret, TYPE_DEVICECHILD = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', 0, false) TYPE_DEVICECHILD = (tonumber(TYPE_DEVICECHILD) or 0)==1 if not TYPE_DEVICECHILD then TYPE_DEVICECHILD = nil end
    local ret, TYPE_DEVICE = GetSetMediaTrackInfo_String        ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE', 0, false) TYPE_DEVICE =  (tonumber(TYPE_DEVICE) or 0)==1   if not TYPE_DEVICE then TYPE_DEVICE = nil end
    local ret, TYPE_DEVICECHILD_PARENTDEVICEGUID = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD_PARENTDEVICEGUID', 0, false) if TYPE_DEVICECHILD_PARENTDEVICEGUID == '' then TYPE_DEVICECHILD_PARENTDEVICEGUID = nil end
    
         
    local ret, ISRS5K = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_CHILD_ISRS5K', 0, false) ISRS5K = (tonumber(ISRS5K) or 0)==1  
    local ret, SAMPLELEN = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_SAMPLELEN', '', false)  SAMPLELEN = tonumber(SAMPLELEN) or 0
    
    local ret, FX_REAEQ_GUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_FX_REAEQ_GUID', '', false) if FX_REAEQ_GUID == '' then FX_REAEQ_GUID = nil end 
    local ret, FX_WS_GUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_FX_WS_GUID', '', false) if FX_WS_GUID == '' then FX_WS_GUID = nil end 
    local ret, INSTR_PARAM_CACHE = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_CACHE', '', false) INSTR_PARAM_CACHE = tonumber(INSTR_PARAM_CACHE) or nil
    local ret, INSTR_PARAM_VOL = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_VOL', '', false) INSTR_PARAM_VOL = tonumber(INSTR_PARAM_VOL) or nil
    local ret, INSTR_PARAM_TUNE = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_TUNE', '', false) INSTR_PARAM_TUNE = tonumber(INSTR_PARAM_TUNE) or nil
    local ret, INSTR_PARAM_ATT = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_ATT', '', false) INSTR_PARAM_ATT = tonumber(INSTR_PARAM_ATT) or nil
    local ret, INSTR_PARAM_DEC = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_DEC', '', false) INSTR_PARAM_DEC = tonumber(INSTR_PARAM_DEC) or nil
    local ret, INSTR_PARAM_SUS = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_SUS', '', false) INSTR_PARAM_SUS = tonumber(INSTR_PARAM_SUS) or nil
    local ret, INSTR_PARAM_REL = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_REL', '', false) INSTR_PARAM_REL = tonumber(INSTR_PARAM_REL) or nil
    
    if TYPE_DEVICECHILD and TYPE_DEVICECHILD_PARENTDEVICEGUID then 
      local devicetr = VF_GetTrackByGUID(TYPE_DEVICECHILD_PARENTDEVICEGUID)
      if devicetr then
        local ret, note_device = GetSetMediaTrackInfo_String         ( track, 'P_EXT:MPLRS5KMAN_NOTE',0, false) note_device = tonumber(note_device)
        if note_device then 
          note = note_device 
          GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_NOTE',note, true) -- refresh device child note 
        end
      end
    end
    
    local trGUID =  GetTrackGUID( track )
    if note and not DATA2.notes[note] then DATA2.notes[note] = {layers = {}} end 
    if note then 
      if TYPE_DEVICECHILD or TYPE_REGCHILD then 
        layer = #DATA2.notes[note].layers +1 
        DATA2.notes[note].layers[layer] = { INSTR_FXGUID=INSTR_FXGUID, 
                                          MIDIFILTGUID=MIDIFILTGUID,
                                          ISRS5K=ISRS5K,
                                          TYPE_REGCHILD=TYPE_REGCHILD, 
                                          TYPE_DEVICECHILD=TYPE_DEVICECHILD,
                                          TYPE_DEVICECHILD_PARENTDEVICEGUID=TYPE_DEVICECHILD_PARENTDEVICEGUID,
                                          tr_ptr = track,
                                          TR_GUID =  trGUID,
                                          SAMPLELEN = SAMPLELEN,
                                          FX_REAEQ_GUID = FX_REAEQ_GUID,
                                          FX_WS_GUID=FX_WS_GUID,
                                          INSTR_PARAM_CACHE=INSTR_PARAM_CACHE,
                                          INSTR_PARAM_VOL=INSTR_PARAM_VOL,
                                          INSTR_PARAM_TUNE=INSTR_PARAM_TUNE,
                                          INSTR_PARAM_ATT=INSTR_PARAM_ATT,
                                          INSTR_PARAM_DEC=INSTR_PARAM_DEC,
                                          INSTR_PARAM_SUS=INSTR_PARAM_SUS,
                                          INSTR_PARAM_REL=INSTR_PARAM_REL,
                                          }
      end
      
      if TYPE_DEVICE then 
        DATA2.notes[note].TYPE_DEVICE = TYPE_DEVICE
        DATA2.notes[note].tr_ptr = track
        DATA2.notes[note].tr_GUID = trGUID
        DATA2.notes[note].devicetr_ID = CSurf_TrackToID(track, false ) 
      end
    end
    
      
  end
  ---------------------------------------------------------------------    
  function DATA2:TrackDataRead_GetChildrens() 
    if not DATA2.tr_valid then return end
    -- get external states
    local partrack, partrack_name
    for i = DATA2.tr_ID+1, CountTracks(0) do
      local track = GetTrack(0,i-1)  
      DATA2:TrackDataRead_GetChildrens_ExtState(track)
    end
    
    -- read FX data
    for note in pairs(DATA2.notes) do
      DATA2:TrackDataRead_GetChildrens_TrackParams(DATA2.notes[note]) 
      if DATA2.notes[note].layers then 
        for layer in pairs(DATA2.notes[note].layers) do
          DATA2:TrackDataRead_GetChildrens_TrackParams(DATA2.notes[note].layers[layer])  
          DATA2:TrackDataRead_GetChildrens_InstrumentParams(DATA2.notes[note].layers[layer])  
          DATA2:TrackDataRead_GetChildrens_FXParams(DATA2.notes[note].layers[layer])  
          if not DATA2.notes[note].name then DATA2.notes[note].name = DATA2.notes[note].layers[layer].tr_name end -- take note name from first layer track
          if not DATA2.notes[note].layers[layer].name then DATA2.notes[note].layers[layer].name = DATA2.notes[note].layers[layer].tr_name end -- take layers name from layer track
        end
      end
    end 
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_InstrumentParams_3rdPartyStuff(note_layer_t, p_names, extparamkey, outval_key, outvalform_key, str_t) 
    if not note_layer_t[extparamkey] then  -- lookup params for netter match
      for strid = 1, #str_t do 
        local str = str_t[strid] 
        for i = 1, #p_names do 
          if p_names[i]:lower():match(str:lower()) then 
            DATA2:TrackDataWrite(note_layer_t.tr_ptr, {[extparamkey]=i-1}) 
            note_layer_t[extparamkey] = i-1
            break
          end 
        end  
      end
     end
     
    note_layer_t[outval_key] = TrackFX_GetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t[extparamkey] ) 
    note_layer_t[outvalform_key]=math.floor(({TrackFX_GetFormattedParamValue( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t[extparamkey] )})[2]*100)..'%'
    
  end
  ---------------------------------------------------------------------  
  
  function DATA2:TrackDataRead_GetChildrens_InstrumentParams(note_layer_t)
    if not note_layer_t then return end
    if not note_layer_t.tr_ptr then return end
    local track = note_layer_t.tr_ptr 
    if not track then return end
    
    local ret, tr, instrument_pos = VF_GetFXByGUID(note_layer_t.INSTR_FXGUID, track)
    if not ret then return end
    note_layer_t.instrument_pos=instrument_pos
    note_layer_t.instrument_enabled = TrackFX_GetEnabled( track, instrument_pos )
    
    if note_layer_t.ISRS5K then
      note_layer_t.instrument_vol = TrackFX_GetParamNormalized( track, instrument_pos, 0 ) 
      note_layer_t.instrument_vol_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, 0 )})[2]..'dB'
      note_layer_t.instrument_pan = TrackFX_GetParamNormalized( track, instrument_pos, 1 ) 
      note_layer_t.instrument_pan_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, 1 )})[2]
      note_layer_t.instrument_attack = TrackFX_GetParamNormalized( track, instrument_pos, 9 ) 
      note_layer_t.instrument_attack_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, 9 )})[2]..'ms'
      note_layer_t.instrument_decay = TrackFX_GetParamNormalized( track, instrument_pos, 24 ) 
      note_layer_t.instrument_decay_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, 24 )})[2]..'ms'
      note_layer_t.instrument_sustain = TrackFX_GetParamNormalized( track, instrument_pos, 25 ) 
      note_layer_t.instrument_sustain_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, 25 )})[2]..'dB'
      note_layer_t.instrument_release = TrackFX_GetParamNormalized( track, instrument_pos, 10 ) 
      note_layer_t.instrument_release_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, 10 )})[2]..'ms'
      note_layer_t.instrument_loop = TrackFX_GetParamNormalized( track, instrument_pos, 12 )
      note_layer_t.instrument_samplestoffs = TrackFX_GetParamNormalized( track, instrument_pos, 13 ) 
      note_layer_t.instrument_samplestoffs_format = (math.floor(note_layer_t.instrument_samplestoffs*1000)/10)..'%'
      note_layer_t.instrument_sampleendoffs = TrackFX_GetParamNormalized( track, instrument_pos, 14 ) 
      note_layer_t.instrument_sampleendoffs_format = (math.floor(note_layer_t.instrument_sampleendoffs*1000)/10)..'%'
      note_layer_t.instrument_loopoffs = TrackFX_GetParamNormalized( track, instrument_pos, 23 ) 
      note_layer_t.instrument_loopoffs_format = math.floor(note_layer_t.instrument_loopoffs *30*10000)/10
      note_layer_t.instrument_maxvoices = TrackFX_GetParamNormalized( track, instrument_pos, 8 ) 
      note_layer_t.instrument_maxvoices_format = math.floor(note_layer_t.instrument_maxvoices*64)
      note_layer_t.instrument_tune = TrackFX_GetParamNormalized( track, instrument_pos, 15 ) 
      note_layer_t.instrument_tune_format = ({TrackFX_GetFormattedParamValue( track, instrument_pos, 15 )})[2]..'st'
      note_layer_t.instrument_filepath = ({TrackFX_GetNamedConfigParm(  track, instrument_pos, 'FILE0') })[2]
      local filepath_short = GetShortSmplName(note_layer_t.instrument_filepath) if filepath_short and filepath_short:match('(.*)%.[%a]+') then filepath_short = filepath_short:match('(.*)%.[%a]+') end
      note_layer_t.instrument_filepath_short = filepath_short 
     else
      note_layer_t.instrument_fxname = ({TrackFX_GetFXName( track, instrument_pos )})[2]
      note_layer_t.instrument_fxname_reduced = VF_ReduceFXname(note_layer_t.instrument_fxname)
      local ret,tr, midifilt_pos = VF_GetFXByGUID(note_layer_t.MIDIFILTGUID, track)
      note_layer_t.midifilt_pos = midifilt_pos
      
      local p_names = {} 
      if note_layer_t.INSTR_PARAM_CACHE ~= 1 then
        for param = 1,  TrackFX_GetNumParams( note_layer_t.tr_ptr, note_layer_t.instrument_pos ) do local retval, buf = TrackFX_GetParamName( note_layer_t.tr_ptr, note_layer_t.instrument_pos, param-1 ) p_names[#p_names+1] = buf end
        DATA2:TrackDataWrite(note_layer_t.tr_ptr, {INSTR_PARAM_CACHE=1})
      end
      DATA2:TrackDataRead_GetChildrens_InstrumentParams_3rdPartyStuff(note_layer_t, p_names, 'INSTR_PARAM_VOL','instrument_vol','instrument_vol_format', {'general level','amp gain','gain','vol'})
      DATA2:TrackDataRead_GetChildrens_InstrumentParams_3rdPartyStuff(note_layer_t, p_names, 'INSTR_PARAM_TUNE','instrument_tune','instrument_tune_format', {'tune','tuning', 'detune', 'pitch', 'tun'})
      DATA2:TrackDataRead_GetChildrens_InstrumentParams_3rdPartyStuff(note_layer_t, p_names, 'INSTR_PARAM_ATT','instrument_attack','instrument_attack_format', {'vca attack','amp attack','attack', 'att'})
      DATA2:TrackDataRead_GetChildrens_InstrumentParams_3rdPartyStuff(note_layer_t, p_names, 'INSTR_PARAM_DEC','instrument_decay','instrument_decay_format', {'vca decay','amp decay','decay', 'dec'})
      DATA2:TrackDataRead_GetChildrens_InstrumentParams_3rdPartyStuff(note_layer_t, p_names, 'INSTR_PARAM_SUS','instrument_sustain','instrument_sustain_format',{'vca sustain','amp sustain','sustain', 'sus'})
      DATA2:TrackDataRead_GetChildrens_InstrumentParams_3rdPartyStuff(note_layer_t, p_names, 'INSTR_PARAM_REL','instrument_release','instrument_release_format', {'vca release','amp release','release','rel'})
      
    end
    
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
    
    -- remove 3.0beta30 backward compatibility
    local _, VERSION = GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_VERSION', 0, false) if VERSION == '' then VERSION = nil end  
    if  VERSION then 
      DATA2.VERSION = VERSION
      vrs_maj = tonumber(VERSION:match('[%d%p]+'))
      vrs_alpha = tonumber(VERSION:match('alpha([%d%p]+)')) or 0
      vrs_beta = tonumber(VERSION:match('beta([%d%p]+)')) or 0
      vrs = vrs_maj + vrs_beta * 0.000001 + vrs_alpha * 0.000000001
      if vrs < 3.00003 then DATA2.tr_valid = false MB('This version require new rack. Rack was created in unsupported beta of RS5k manager','Error', 0) return end
    end
    
    DATA2.PARENT_ACTIVEPAD = 3
    DATA2.PARENT_MACROCNT = 16
    DATA2.PARENT_TABSTATEFLAGS=1|2|4|8--|16 -- 1=drumrack   2=device  4=sampler 8=padview 16=macro
    DATA2.PARENT_LASTACTIVENOTE = -1
    
    DATA2.Macro = {sliders = {}} 
    DATA2:TrackDataRead_GetParent_Macro()
    
  end
  --------------------------------------------------------------------- 
  function DATA2:TrackDataRead_GetParent_Macro()
    if not DATA2.tr_ptr then return end
    DATA2.Macro.isvalid = false
    local _, MACRO_GUID = GetSetMediaTrackInfo_String ( DATA2.tr_ptr, 'P_EXT:MPLRS5KMAN_MACRO_GUID', 0, false) if MACRO_GUID == '' then MACRO_GUID = nil end 
    if MACRO_GUID then 
      local ret,tr, macropos = VF_GetFXByGUID(MACRO_GUID, DATA2.tr_ptr)
      if ret and macropos and macropos ~= -1 then   
        DATA2.Macro.isvalid = true 
        DATA2.Macro.pos = macropos 
        for i = 1, 16 do
          if not DATA2.Macro.sliders[i] then DATA2.Macro.sliders[i] = {} end
          local param_val = TrackFX_GetParamNormalized( DATA2.tr_ptr, macropos, i-1 )
          DATA2.Macro.sliders[i].macroval = param_val
          DATA2.Macro.sliders[i].macroval_format = math.floor(param_val*1000/10)..'%'
          DATA2.Macro.sliders[i].tr_ptr = DATA2.tr_ptr
          DATA2.Macro.sliders[i].macro_pos = macropos
        end
      end
    end 
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
    DATA2:TrackDataRead_GetParent_ParseExt(parenttrack)
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
        GUI_MODULE_TABS(DATA)  
        GUI_MODULE_PADOVERVIEW(DATA)
        GUI_MODULE_DRUMRACKPAD(DATA)
        GUI_MODULE_DEVICE(DATA)  
        GUI_MODULE_MACRO(DATA)    
        GUI_MODULE_SAMPLER(DATA)
      end
    
    if not DATA.GUI.layers_refresh  then DATA.GUI.layers_refresh = {} end
    DATA.GUI.layers_refresh[2]=true 
    
    DATA2.tr_ptr_last = DATA2.tr_ptr 
    
    DATA.GUI.Settings_open = 0
    GUI_MODULE_SETTINGS(DATA)
      
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_TABS(DATA)  
    local txt_a_unabled = 0.25
    local txt_a 
    local frame_a = 1
    local frame_asel = 1
    local frame_col = '#333333'
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==0 then txt_a = txt_a_unabled end
    DATA.GUI.buttons.showhide_macroglob = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_tab_h*0 ,
                          w=DATA.GUI.custom_tab_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_tab_h-1,
                          txt = 'Macro',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_tabnames_txtsz,
                          frame_a = frame_a,
                          frame_asel = frame_asel,
                          frame_col = frame_col,
                          onmouseclick = function()
                            if DATA2.PARENT_TABSTATEFLAGS then 
                              DATA2.PARENT_TABSTATEFLAGS = DATA2.PARENT_TABSTATEFLAGS ~ 16
                              if DATA2.PARENT_TABSTATEFLAGS&16==16 then DATA2:TrackData_InitMacro() end
                              DATA2:TrackDataWrite(_, {master_upd=true})
                              DATA.UPD.onGUIinit = true
                            end
                          end,
                          } 
    local txt_a
    local txt_a_unabled = 0.25
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&8==0 then txt_a = txt_a_unabled end
    
    DATA.GUI.buttons.showhide_pad = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_tab_h*1 ,
                          w=DATA.GUI.custom_tab_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_tab_h-1,
                          txt = 'Pad overview',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_tabnames_txtsz,
                          frame_a = frame_a,
                          frame_asel = frame_asel,
                          frame_col = frame_col,
                          onmouseclick = function()
                            if DATA2.PARENT_TABSTATEFLAGS then 
                              DATA2.PARENT_TABSTATEFLAGS = DATA2.PARENT_TABSTATEFLAGS ~ 8
                              DATA2:TrackDataWrite(_, {master_upd=true})
                              DATA.UPD.onGUIinit = true
                            end
                          end,
                          }                          
    local txt_a 
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&1==0 then txt_a = txt_a_unabled end
    DATA.GUI.buttons.showhide_drrack = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_tab_h*2 ,
                          w=DATA.GUI.custom_tab_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_tab_h-1,
                          txt = 'Drum Rack',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_tabnames_txtsz,
                          frame_a = frame_a,
                          frame_asel = frame_asel,
                          frame_col = frame_col,
                          onmouseclick = function()
                            if DATA2.PARENT_TABSTATEFLAGS then 
                              DATA2.PARENT_TABSTATEFLAGS = DATA2.PARENT_TABSTATEFLAGS ~ 1
                              DATA2:TrackDataWrite(_, {master_upd=true})
                              DATA.UPD.onGUIinit = true
                            end
                          end,
                          }
    local txt_a
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&2==0 then txt_a = txt_a_unabled end 
    DATA.GUI.buttons.showhide_device = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_tab_h*3 ,
                          w=DATA.GUI.custom_tab_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_tab_h-1,
                          txt = 'Device',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_tabnames_txtsz,
                          frame_a = frame_a,
                          frame_asel = frame_asel,
                          frame_col = frame_col,
                          onmouseclick = function()
                            if DATA2.PARENT_TABSTATEFLAGS then 
                              DATA2.PARENT_TABSTATEFLAGS = DATA2.PARENT_TABSTATEFLAGS ~ 2
                              DATA2:TrackDataWrite(_,{master_upd=true})
                              DATA.UPD.onGUIinit = true
                            end
                          end
                          }      
    local txt_a
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&4==0 then txt_a = txt_a_unabled end 
    DATA.GUI.buttons.showhide_sampler = { x=0,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_tab_h*4 ,
                          w=DATA.GUI.custom_tab_w,-- - DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_tab_h,
                          txt = 'Sampler',
                          txt_a = txt_a,
                          txt_fontsz=DATA.GUI.custom_tabnames_txtsz,
                          frame_a = frame_a,
                          frame_asel = frame_asel,
                          frame_col = frame_col,
                          onmouseclick = function()
                            if DATA2.PARENT_TABSTATEFLAGS then 
                              DATA2.PARENT_TABSTATEFLAGS = DATA2.PARENT_TABSTATEFLAGS ~ 4
                              DATA2:TrackDataWrite(_,{master_upd=true})
                              DATA.UPD.onGUIinit = true
                            end
                          end
                          }                          
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    -- get globals
      local gfx_h = math.floor(gfx.h/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
      local gfx_w = math.floor(gfx.w/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
    --DATA.GUI.default_scale = 1
      
    -- init main stuff
      DATA.GUI.custom_Yrelation = math.max(gfx_h/300, 0.5) -- global W
      DATA.GUI.custom_offset =  3 * DATA.GUI.custom_Yrelation
      DATA.GUI.custom_infoh = math.floor(gfx_h*0.1)
      DATA.GUI.custom_moduleH = gfx_h - DATA.GUI.custom_infoh-DATA.GUI.custom_offset -- global H
      DATA.GUI.custom_moduleW = math.floor(DATA.GUI.custom_moduleH*1.5) -- global W
      
      DATA.GUI.custom_framea = 0.1 -- greyed drum rack pads
      DATA.GUI.custom_backcol2 = '#f3f6f4' -- grey back  -- device selection
      DATA.GUI.custom_backfill2 = 0.1-- device selection
      
    -- settings / tabs
      DATA.GUI.custom_tab_w = math.floor(DATA.GUI.custom_moduleW*0.25)
      DATA.GUI.custom_tab_h = (gfx_h - DATA.GUI.custom_infoh)/5
      DATA.GUI.custom_tabnames_txtsz = 16*DATA.GUI.custom_Yrelation--*DATA.GUI.default_scale
      
    -- modules
      DATA.GUI.custom_module_startoffsx = DATA.GUI.custom_tab_w + DATA.GUI.custom_offset -- first mod offset
      DATA.GUI.custom_module_ctrlreadout_h = math.floor(DATA.GUI.custom_moduleH * 0.1) 
      
    -- macro 
      DATA.GUI.custom_macroY = DATA.GUI.custom_infoh--+ DATA.GUI.custom_offset
      DATA.GUI.custom_macroW = math.floor(DATA.GUI.custom_moduleW*1.3)
      DATA.GUI.custom_macroH = DATA.GUI.custom_moduleH--DATA.GUI.custom_offset
      local knobcol = 2
      DATA.GUI.custom_macro_knobH = math.floor(DATA.GUI.custom_macroH/knobcol)
      local knobrow = 8
      DATA.GUI.custom_macro_knobW =  math.floor((DATA.GUI.custom_macroW - (knobrow-1)*DATA.GUI.custom_offset)/knobrow)
      DATA.GUI.custom_macroW = DATA.GUI.custom_macro_knobW*(knobrow)+DATA.GUI.custom_offset
      DATA.GUI.custom_macro_knobtxtsz= 15* DATA.GUI.custom_Yrelation
      
    -- pad overview
      DATA.GUI.custom_padgridy = 0
      DATA.GUI.custom_padgridh = gfx_h-DATA.GUI.custom_offset -- - DATA.GUI.custom_infoh-DATA.GUI.custom_offset 
      DATA.GUI.custom_padgridblockh = math.floor(DATA.GUI.custom_padgridh/8)
      DATA.GUI.custom_padgridw = DATA.GUI.custom_padgridblockh 
       
    -- drrack 
      DATA.GUI.custom_drrack_sideY = math.floor(DATA.GUI.custom_moduleH/4)
      DATA.GUI.custom_drrack_sideX = DATA.GUI.custom_drrack_sideY*1.5
      DATA.GUI.custom_drrack_sideW = DATA.GUI.custom_moduleW--DATA.GUI.custom_offset
      DATA.GUI.custom_drrack_pad_txtsz = 15* DATA.GUI.custom_Yrelation--0.5*(DATA.GUI.custom_drrack_sideY/2-DATA.GUI.custom_offset*2)
      DATA.GUI.custom_drrack_arcr = math.floor(DATA.GUI.custom_drrack_sideX*0.1) 
      DATA.GUI.custom_drrack_sideW = DATA.GUI.custom_drrack_sideX*4 -- reset to 4 pads
      DATA.GUI.custom_drrackH = DATA.GUI.custom_drrack_sideY*4
      DATA.GUI.custom_drrack_ctrlbut_h = DATA.GUI.custom_drrack_sideY/2
      
    -- device
      DATA.GUI.custom_device_droptxtsz =  20* DATA.GUI.custom_Yrelation
      DATA.GUI.custom_devicew = math.floor(DATA.GUI.custom_moduleW*1.3)
      DATA.GUI.custom_deviceh = gfx_h - DATA.GUI.custom_infoh-DATA.GUI.custom_offset -- DEVICE H
      DATA.GUI.custom_deviceentryh = 25 * DATA.GUI.custom_Yrelation
      DATA.GUI.custom_devicectrl_txtsz = 15 *DATA.GUI.custom_Yrelation   
      
      
    -- sampler  
      DATA.GUI.custom_sampler_showbutw = 70 *DATA.GUI.custom_Yrelation  
      DATA.GUI.custom_sampler_peakareah = math.floor(DATA.GUI.custom_moduleH * 0.4) 
      DATA.GUI.custom_sampler_modew = math.floor(DATA.GUI.custom_sampler_peakareah/2) 
      DATA.GUI.custom_samplerW = (DATA.GUI.custom_sampler_modew+DATA.GUI.custom_offset) * 8
      DATA.GUI.custom_sampler_namebutw = DATA.GUI.custom_samplerW-DATA.GUI.custom_sampler_showbutw*2 
      DATA.GUI.custom_sampler_readouth =DATA.GUI.custom_sampler_modew+1 
      DATA.GUI.custom_sampler_knob_h = DATA.GUI.custom_moduleH - DATA.GUI.custom_module_ctrlreadout_h*2 - DATA.GUI.custom_sampler_peakareah - DATA.GUI.custom_offset*4-DATA.GUI.custom_offset 
      DATA.GUI.custom_sampler_ctrl_txtsz = 13 *DATA.GUI.custom_Yrelation  
      DATA.GUI.custom_sampler_peaksw = DATA.GUI.custom_samplerW-DATA.GUI.custom_offset-DATA.GUI.custom_sampler_modew-1
      
      
      
      
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
                            w=DATA.GUI.custom_tab_w,-- - DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_infoh-1,
                            txt = '>',
                            txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                            --frame_a = 1,
                            onmouseclick = function()
                              if DATA.GUI.Settings_open then DATA.GUI.Settings_open = math.abs(1-DATA.GUI.Settings_open) else DATA.GUI.Settings_open = 1 end 
                              DATA.UPD.onGUIinit = true
                            end,
                            }
                            
      if not DATA.GUI.Settings_open then DATA.GUI.Settings_open = 0  end
      if DATA.GUI.Settings_open ==0 then  
        if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 0
        --if DATA2.tr_valid ==true and DATA2.PARENT_TABSTATEFLAGS then 
          GUI_MODULE_TABS(DATA)
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
        {str = 'Active note follow incoming note',              group = 3, itype = 'check', confkey = 'UI_incomingnoteselectpad', level = 1},
      {str = 'DrumRack',                                        group = 4, itype = 'sep'},  
        {str = 'Click on pad select track',                     group = 4, itype = 'check', confkey = 'UI_clickonpadselecttrack', level = 1},
      {str = 'Sample actions',                                  group = 5, itype = 'sep'},    
        {str = 'Crop threshold',                                group = 5, itype = 'readout', confkey = 'CONF_cropthreshold', level = 1, menu = {[-80]='-80dB',[-60]='-60dB', [-40]='-40dB',[-30]='-30dB'},readoutw_extw = readoutw_extw},

    } 
    return t
    
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO(DATA)    
    for key in pairs(DATA.GUI.buttons) do if key:match('macroglob_') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==0) then return end
    local x_offs= DATA.GUI.custom_module_startoffsx
    
    DATA.GUI.buttons.macroglob_actionframe = { x=x_offs,
                          y=0,
                          w=DATA.GUI.custom_macroW,
                          h=DATA.GUI.custom_infoh-1,
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
                          
    -- controls 
    for ctrlid = 1, 16 do
      local xshift = DATA.GUI.custom_macro_knobW*(ctrlid-1)
      local yshift = DATA.GUI.custom_macro_knobH * math.floor((ctrlid/9))
      if ctrlid>=9 then  xshift = DATA.GUI.custom_macro_knobW*(ctrlid-9) end 
      local src_t = DATA2.Macro.sliders[ctrlid]
      GUI_CTRL(DATA,
        {
          butkey = 'macroglob_knob'..ctrlid,
          
          x = x_offs+xshift+DATA.GUI.custom_offset,
          y=  DATA.GUI.custom_infoh + DATA.GUI.custom_offset + yshift,
          w = DATA.GUI.custom_macro_knobW-DATA.GUI.custom_offset,
          h = DATA.GUI.custom_macro_knobH-DATA.GUI.custom_offset,
          
          ctrlname = 'Macro \n'..ctrlid,
          ctrlval_key = 'macroval',
          ctrlval_format_key = 'macroval_format',
          ctrlval_src_t = DATA2.Macro.sliders[ctrlid],
          ctrlval_res = 0.5,
          ctrlval_default = 0,
          func_app =            function(new_val) 
                                  TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.macro_pos, ctrlid-1, new_val )
                                end,
          func_refresh =        function() 
                                  DATA2:TrackDataRead_GetParent_Macro() 
                                end,
          func_formatreverse =  function(str_ret)
                                  local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.macro_pos, ctrlid-1) 
                                  return new_val
                                end
         } )    
         
    end
                          
  end
  -----------------------------------------------------------------------------  
  function DATA2:Actions_StuffNoteOn(note, vel)
   if not note then return end
    StuffMIDIMessage( 0, 0x90, note, vel or 120 ) 
    DATA.ontrignoteTS = os.clock() 
    DATA.ontrignote = note 
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_DRUMRACKPAD(DATA) 
    for key in pairs(DATA.GUI.buttons) do if key:match('drumrack') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&1==0) then return end
    
    local trname = DATA2.tr_name or '[no data]'      
    local x_offs= DATA.GUI.custom_module_startoffsx
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==16 then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&8==8 then x_offs = x_offs + DATA.GUI.custom_offset +  DATA.GUI.custom_padgridw end -- pad view
     
       -- dr rack
       DATA.GUI.buttons.drumrack_trackname = { x=x_offs,
                            y=0,
                            w=DATA.GUI.custom_drrack_sideW-DATA.GUI.custom_sampler_showbutw-DATA.GUI.custom_offset*2-DATA.GUI.custom_infoh,
                            h=DATA.GUI.custom_infoh-1,
                            txt = trname,
                            txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                            }
       DATA.GUI.buttons.drumrackpad = { x=x_offs,
                             y=DATA.GUI.custom_infoh,
                             w=DATA.GUI.custom_drrack_sideW,
                             h=DATA.GUI.custom_drrackH,
                             ignoremouse = true,
                             frame_a = 0,
                             }
      DATA.GUI.buttons.drumrack_showME = { x=x_offs+DATA.GUI.custom_drrack_sideW-DATA.GUI.custom_offset-DATA.GUI.custom_sampler_showbutw-DATA.GUI.custom_infoh,
                           y=0,
                           w=DATA.GUI.custom_sampler_showbutw,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'MediaExp',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() if DATA2.PARENT_LASTACTIVENOTE then  DATA2:Actions_PadShowME(DATA2.PARENT_LASTACTIVENOTE, DATA2.PARENT_LASTACTIVENOTE_layer or 1) end  end,
                           }                                 
      DATA.GUI.buttons.drumrack_help = { x=x_offs+DATA.GUI.custom_drrack_sideW-DATA.GUI.custom_infoh,
                           y=0,
                           w=DATA.GUI.custom_infoh-1,
                           h=DATA.GUI.custom_infoh-1,
                           txt = '?',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() 
                                              DATA2:Actions_Help(0)
                                            end,
                           }                              
                             
    local padactiveshift = 116 
    if DATA2.PARENT_ACTIVEPAD == 8 then padactiveshift = 116 end
    if DATA2.PARENT_ACTIVEPAD == 7 then padactiveshift = 100 end
    if DATA2.PARENT_ACTIVEPAD == 6 then padactiveshift = 84 end
    if DATA2.PARENT_ACTIVEPAD == 5 then padactiveshift = 68 end
    if DATA2.PARENT_ACTIVEPAD == 4 then padactiveshift = 52 end
    if DATA2.PARENT_ACTIVEPAD == 3 then padactiveshift = 36 end
    if DATA2.PARENT_ACTIVEPAD == 2 then padactiveshift = 20 end
    if DATA2.PARENT_ACTIVEPAD == 1 then padactiveshift = 4 end
    if DATA2.PARENT_ACTIVEPAD == 0 then padactiveshift = 0 end
    
    for padID0 =0 , 16 do
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] = nil
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'mute'] = nil
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'solo'] = nil
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'play'] = nil
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'show'] = nil
    end
    
    local padID0 = 0
    for note = 0+padactiveshift, 15+padactiveshift do
      local txt = DATA2:internal_FormatMIDIPitch(note) 
      if note > 127 then break end
      if DATA2.notes[note] and DATA2.notes[note].name then txt = DATA2.notes[note].name end
      if DATA2.notes[note] and DATA2.notes[note].TYPE_DEVICE and DATA2.notes[note].TYPE_DEVICE == true and DATA2.notes[note].tr_name then txt ='[D] '..DATA2.notes[note].tr_name end
      local col 
      if DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_col then 
        col = DATA2.notes[note].layers[1].tr_col 
        col = string.format("#%06X", col);
      end
      DATA.GUI.buttons['drumrackpad_pad'..padID0] = { x=DATA.GUI.buttons.drumrackpad.x+(padID0%4)*DATA.GUI.custom_drrack_sideX+1,
                              y=DATA.GUI.custom_infoh+DATA.GUI.custom_drrackH-DATA.GUI.custom_drrack_sideY*(math.floor(padID0/4)+1)+DATA.GUI.custom_offset,
                              w=DATA.GUI.custom_drrack_sideX-DATA.GUI.custom_offset,
                              h=DATA.GUI.custom_drrack_sideY-DATA.GUI.custom_offset-1,
                              ignoremouse = true,
                              txt='',
                              frame_a = frame_a,
                              frame_col = col,
                              frame_arcborder = true,
                              frame_arcborderr = DATA.GUI.custom_drrack_arcr,
                              frame_arcborderflags = 1|2,
                              onmouseclick = function() end, 
                              refresh = true,
                              }
      -- mark active
      local frame_a = DATA.GUI.custom_framea 
      if DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE == note then frame_a = 0.7 end
      DATA.GUI.buttons['drumrackpad_pad'..padID0].frame_a=frame_a
      
      local padx= DATA.GUI.buttons.drumrackpad.x+(padID0%4)*DATA.GUI.custom_drrack_sideX+1
      local pady = DATA.GUI.buttons.drumrackpad.y+DATA.GUI.buttons.drumrackpad.h-DATA.GUI.custom_drrack_sideY*(math.floor(padID0/4)+1)+DATA.GUI.custom_offset
      local controlbut_h2 = DATA.GUI.custom_drrack_sideY/2-DATA.GUI.custom_offset
      local controlbut_w = math.floor((DATA.GUI.custom_drrack_sideX -DATA.GUI.custom_offset)/ 3)
      local frame_actrl =0
      local txt_actrl = 0.2
      local txt_a 
      if not DATA2.notes[note] then txt_a = 0.1 end
      
      
      local frame_a = 0
        
      --msg(col)
      
      local backgr_col =DATA.GUI.custom_backcol2-- '#33FF45'
      backgr_col = col
      --[[if col then 
        frame_a = 0.1
        backgr_col =col     
        frame_col = col
      end]]
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] = { x=padx,
                              y=pady,
                              w=DATA.GUI.custom_drrack_sideX-DATA.GUI.custom_offset,
                              h=DATA.GUI.custom_drrack_ctrlbut_h,
                              txt=txt,
                              txt_a = txt_a,
                              txt_fontsz =DATA.GUI.custom_drrack_pad_txtsz,
                              txt_col = backgr_col,
                              frame_a = frame_a,
                              frame_asel = 0.1,
                              frame_col = backgr_col,--DATA.GUI.custom_backcol2,
                              backgr_fill = 0 ,
                              --backgr_col = backgr_col,
                              back_sela = 0.1 ,
                              frame_arcborder = true,
                              frame_arcborderr = DATA.GUI.custom_drrack_arcr,
                              frame_arcborderflags = 1|2,
                              --prevent_matchrefresh = true,
                              onmousedrag = function() 
                                              DATA2.PAD_HOLD = note
                                              DATA2.ONPARAMDRAG = true
                                            end,
                                            
                              onmouseclick = function() 
                              
                                -- click select track
                                if DATA.extstate.UI_clickonpadselecttrack == 1 then
                                  if DATA2.notes[note] then
                                    if DATA2.notes[note].TYPE_DEVICE ~= true then 
                                      SetOnlyTrackSelected( DATA2.notes[note].layers[1].tr_ptr ) 
                                     else 
                                      SetOnlyTrackSelected(DATA2.notes[note].tr_ptr)  
                                    end
                                  end
                                end
                                
                                --if DATA.GUI.Ctrl == true then DATA2:Actions_ShowInstrument(note, 1) 
                                 --else
                                DATA2.PARENT_LASTACTIVENOTE = note 
                                DATA2.PARENT_LASTACTIVENOTE_layer = 1 
                                DATA2:TrackDataWrite(_,{master_upd=true}) 
                                --GUI_MODULE_DRUMRACKPAD(DATA)  
                                if DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] then DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].refresh = true end
                                DATA2.PARENT_LASTACTIVENOTE_layer = layer 
                                GUI_MODULE_DEVICE(DATA)  
                                GUI_MODULE_SAMPLER(DATA)
                                --end
                              end,
                              onmouseclickR = function() DATA2:Actions_PadMenu(note) end,
                              onmousefiledrop = function() DATA2:Actions_PadOnFileDrop(note) end,
                              onmouserelease =  function()  
                                                    if not DATA2.ONDOUBLECLICK then
                                                      DATA2.PARENT_LASTACTIVENOTE = note 
                                                      GUI_MODULE_DRUMRACKPAD(DATA) 
                                                      DATA2.ONPARAMDRAG = false
                                                     else
                                                      DATA2.ONDOUBLECLICK = nil
                                                    end
                                                end,
                              onmousedrop =  function()  
                                              
                                              DATA2.PAD_DROP_HOLD = nil  
                                              if DATA2.PAD_HOLD then 
                                                local padsrc = DATA2.PAD_HOLD
                                                local paddest = note
                                                DATA2:Actions_PadCopyMove(padsrc,paddest, DATA.GUI.Ctrl) 
                                              end 
                                            end,
                              onmousedoubleclick = function() 
                                                    DATA2.ONDOUBLECLICK = true
                                                  end
                              }  
                              
                              
      --local txt_a,txt_col= txt_actrl if DATA2.notes[note] and DATA2.notes[note].partrack_mute and DATA2.notes[note].partrack_mute == 1 then txt_col = '#A55034' txt_a = 1 end
     local backgr_fill,txt_a= 0,txt_actrl if DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_mute and DATA2.notes[note].layers[1].tr_mute >0 then backgr_fill = 0.2 txt_a = nil end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'mute'] = { x=padx,
                              y=pady+DATA.GUI.custom_drrack_ctrlbut_h,
                              w=controlbut_w,
                              h=controlbut_h2-1,
                              txt='M',
                              txt_col = backgr_col,
                              txt_a = txt_a,
                              txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                              frame_a = frame_actrl,
                              prevent_matchrefresh = true,
                              backgr_fill = backgr_fill,
                              backgr_col = DATA.GUI.custom_backcol2,
                              onmouseclick = function() DATA2:Actions_PadSoloMute(note,_,_, true) end,
                              } 
                              
      
      local backgr_fill2,frame_actrl0=nil,frame_actrl if DATA2.playingnote_pitch and DATA2.playingnote_pitch == note  then backgr_fill2 = 0.8 frame_actrl0 = 1 end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'play'] = { x=padx+controlbut_w,
                              y=pady+DATA.GUI.custom_drrack_ctrlbut_h+1,
                              w=controlbut_w,
                              h=controlbut_h2-2,
                              txt='>',
                              txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                              txt_a = txt_actrl,
                              txt_col = backgr_col,
                              prevent_matchrefresh = true,
                              frame_a = frame_actrl0,
                              backgr_fill = 0.2 ,
                              onmouseclick =    function() DATA2:Actions_StuffNoteOn(note, vel) end,
                              onmouserelease =  function() StuffMIDIMessage( 0, 0x80, note, 0 ) DATA.ontrignoteTS =  nil end,
                              refresh = true,
                              }   
                                
      local backgr_fill,txt_a= 0,txt_actrl if DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_solo and DATA2.notes[note].layers[1].tr_solo >0 then backgr_fill = 0.2 txt_a = nil end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'solo'] = { x=padx+controlbut_w*2,
                              y=pady+DATA.GUI.custom_drrack_ctrlbut_h,
                              w=controlbut_w,
                              h=controlbut_h2-1,
                              --txt_col=txt_col,
                              txt_a = txt_a,
                              txt='S',
                              txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                              txt_col = backgr_col,
                              frame_a = frame_actrl,
                              prevent_matchrefresh = true,
                              backgr_fill = backgr_fill,
                              backgr_col = DATA.GUI.custom_backcol2,
                              onmouseclick = function() DATA2:Actions_PadSoloMute(note,_,true) end,
                              }    
                              
      padID0 = padID0 + 1
    end
  end
  -----------------------------------------------------------------------  
  function DATA2:Actions_PadShowME(note, layer) 
    if not DATA2.notes[note] then return end
    if not layer then 
      t = DATA2.notes[note].layers[1]       -- do stuff on device/instrument or first layer only
     else 
      t = DATA2.notes[note].layers[layer] -- do stuff on defined layer 
    end
    if not (t and t.tr_ptr) then return end 
    if not t.instrument_filepath then return end
    local filepath= DATA2.notes[note].layers[1].instrument_filepath
    OpenMediaExplorer( filepath, false )
  end

  ----------------------------------------------------------------------- 
  function DATA2:Actions_PadSoloMute(note,layer,solo, mute)
    if not DATA2.notes[note] then return end
    if not layer then 
      if DATA2.notes[note].TYPE_DEVICE == true then t = DATA2.notes[note] else t = DATA2.notes[note].layers[1] end       -- do stuff on device or first layer only
     else t = DATA2.notes[note].layers[layer] -- do stuff on defined layer 
    end
    if not (t and t.tr_ptr) then return end
    
    
    if mute then 
      local state = t.tr_mute > 0
      if state then state = 0 else state =2 end 
      SetMediaTrackInfo_Value( t.tr_ptr, 'B_MUTE', state )
      t.tr_mute = state
    end
    
    if solo then 
      local state = t.tr_solo > 0
      if state then state = 0 else state =2 end 
      SetMediaTrackInfo_Value( t.tr_ptr, 'I_SOLO', state )
      t.tr_solo = state
    end
    
    GUI_MODULE_DRUMRACKPAD(DATA)  
    GUI_MODULE_DEVICE(DATA)  
      
  end  
  ----------------------------------------------------------------------- 
  function DATA2:internal_FormatMIDIPitch(note) 
    local val = math.floor(note)
    local oct = math.floor(note / 12)
    local note = math.fmod(note,  12)
    local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
    if note and oct and key_names[note+1] then return key_names[note+1]..oct-2 end
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadOnFileDrop_AddMIDISend(new_tr) 
    -- make sure MIDI bus exist
    if not new_tr then return end
    DATA2:TrackDataRead_ValidateMIDIbus()
      
    local sendidx = CreateTrackSend( DATA2.MIDIbus.ptr, new_tr )
    SetTrackSendInfo_Value( DATA2.MIDIbus.ptr, 0, sendidx, 'I_SRCCHAN',-1 )
    SetTrackSendInfo_Value( DATA2.MIDIbus.ptr, 0, sendidx, 'I_MIDIFLAGS',0 )
  end
  --------------------------------------------------------------------- 
  function DATA2:Actions_PadOnFileDrop_AddChildTrack(ID_spec) 
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
    
    DATA2:TrackDataWrite(new_tr, {set_currentparentforchild = true})  
    DATA2:TrackDataWrite(new_tr, {setchild = true}) 
    
     
    return new_tr
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadOnFileDrop_ExportFXasDeviceInstrument(new_tr, filepath,note)
    local fx_dll = filepath:match('@fx%:(.*)'):gsub('\\','/')
    local fx_dll_sh = GetShortSmplName(fx_dll)
    --local fx_dll_sh_noext = fx_dll:match('(.*)%.(.*)')
    local instrument_pos = TrackFX_AddByName( new_tr, fx_dll_sh, false, 1 ) 
    if instrument_pos == -1 then return end
    local retval, fxname = TrackFX_GetFXName( new_tr, instrument_pos )
    local fxname_settrname =  VF_ReduceFXname(fxname) or fxname
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', fxname_settrname, true )
    local instrumentGUID = TrackFX_GetFXGUID( new_tr, instrument_pos)
    local midifilt_pos = TrackFX_AddByName( new_tr, 'midi_note_filter', false, -1000 ) 
    local midifilt_GUID = TrackFX_GetFXGUID( new_tr, midifilt_pos)
    DATA2:TrackDataWrite(new_tr, {setmidifilt_FXGUID = midifilt_GUID})
    DATA2:TrackDataWrite(new_tr, {setnote_ID = note})
    DATA2:TrackDataWrite(new_tr, {setinstr_FXGUID = instrumentGUID})
    
    TrackFX_Show( new_tr, midifilt_pos, 2 )      
    DATA2:Actions_PadOnFileDrop_setnote_ID(new_tr, instrument_pos, note, midifilt_pos)
    return midifilt_pos
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadOnFileDrop_setnote_ID(tr, instrument_pos, note, midifilt_pos)
    if not midifilt_pos then 
      TrackFX_SetParamNormalized( tr, instrument_pos, 3, (note)/127 ) -- note range start
      TrackFX_SetParamNormalized( tr, instrument_pos, 4, (note)/127 ) -- note range end
     else 
      TrackFX_SetParamNormalized( tr, midifilt_pos, 0, note/128)
      TrackFX_SetParamNormalized( tr, midifilt_pos, 1, note/128)
    end
  end
  -----------------------------------------------------------------------  
  function DATA2:Actions_PadOnFileDrop_ExportToRS5k(new_tr, filepath,note)
    if filepath:match('@fx') then
      DATA2:Actions_PadOnFileDrop_ExportFXasDeviceInstrument(new_tr, filepath,note)
      return
    end
    local instrument_pos = TrackFX_AddByName( new_tr, 'ReaSamplomatic5000', false, 0 ) 
    if instrument_pos == -1 then instrument_pos = TrackFX_AddByName( new_tr, 'ReaSamplomatic5000', false, -1000 ) end 
    if DATA.extstate.CONF_onadd_float == 0 then TrackFX_SetOpen( new_tr, instrument_pos, false ) end
    TrackFX_SetNamedConfigParm( new_tr, instrument_pos, 'FILE0', filepath)
    TrackFX_SetNamedConfigParm( new_tr, instrument_pos, 'DONE', '')      
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 2, 0) -- gain for min vel
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 5, 0.5 ) -- pitch for start
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 6, 0.5 ) -- pitch for end
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 8, 0 ) -- max voices = 0
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 9, 0 ) -- attack
    TrackFX_SetParamNormalized( new_tr, instrument_pos, 11, DATA.extstate.CONF_onadd_obeynoteoff) -- obey note offs
    DATA2:Actions_PadOnFileDrop_setnote_ID(new_tr, instrument_pos, note)
    
    
    -- store external data
    local src = PCM_Source_CreateFromFile( filepath )
    if src then 
      local it_len =  GetMediaSourceLength( src )
      GetSetMediaTrackInfo_String( new_tr, 'P_EXT:MPLRS5KMAN_SAMPLELEN', it_len, true)
      local instrumentGUID = TrackFX_GetFXGUID( new_tr, instrument_pos)
      DATA2:TrackDataWrite(new_tr, {setinstr_FXGUID = instrumentGUID})
      DATA2:TrackDataWrite(new_tr, {setnote_ID=note})
      DATA2:TrackDataWrite(new_tr, {is_rs5k=true})
    end 
    
    
    -- handle track name 
      filepath_sh = GetShortSmplName(filepath)
      if filepath_sh:match('(.*)%.[%a]+') then filepath_sh = filepath_sh:match('(.*)%.[%a]+') end
      GetSetMediaTrackInfo_String( new_tr, 'P_NAME', filepath_sh, true ) 
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadClear(note)  
    if not DATA2.notes[note] then return end 
    
    local  tr_ptr
    if DATA2.notes[note].TYPE_DEVICE then 
      -- remove device with layers
      if DATA2.notes[note].layers then 
        for layer = 1, #DATA2.notes[note].layers do
          tr_ptr = DATA2.notes[note].layers[layer].tr_ptr 
          if tr_ptr and ValidatePtr2(0,tr_ptr, 'MediaTrack*')then DeleteTrack( tr_ptr) end
        end
      end
      tr_ptr = DATA2.notes[note].tr_ptr 
      if tr_ptr and ValidatePtr2(0,tr_ptr, 'MediaTrack*')then DeleteTrack( tr_ptr) end
      
     else 
     
      -- remove regular child
      tr_ptr = DATA2.notes[note].layers[1].tr_ptr 
      if tr_ptr and ValidatePtr2(0,tr_ptr, 'MediaTrack*')then DeleteTrack( tr_ptr) end
      
    end
    
    -- clear note names
    DATA2.FORCEONPROJCHANGE = true
    SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, '')
    -- set parent track selected
    reaper.SetOnlyTrackSelected( DATA2.tr_ptr )
  end 
  -----------------------------------------------------------------------
  function DATA2:Actions_PadUpdateNote(note, newnote)
    if not DATA2.notes[note] then return end
    if DATA2.notes[note].TYPE_DEVICE then 
      local devicetr = DATA2.notes[note].tr_ptr
      DATA2:TrackDataWrite(devicetr, {setnote_ID = newnote}) 
      for layer = 1, #DATA2.notes[note].layers do
        local child_tr = DATA2.notes[note].layers[layer].tr_ptr
        DATA2:TrackDataWrite( child_tr, {setnote_ID = newnote})
        DATA2:Actions_PadOnFileDrop_setnote_ID(child_tr, DATA2.notes[note].layers[layer].instrument_pos, newnote, DATA2.notes[note].layers[layer].midifilt_pos)
      end
      
     else
      DATA2:TrackDataWrite(DATA2.notes[note].layers[1].tr_ptr, {setnote_ID = newnote})
      DATA2:Actions_PadOnFileDrop_setnote_ID(DATA2.notes[note].layers[1].tr_ptr, DATA2.notes[note].layers[1].instrument_pos, newnote, DATA2.notes[note].layers[1].midifilt_pos)
    end
    if DATA2.cursplpeaks.note == note then DATA2.cursplpeaks.note = newnote end
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadCopyMove(padsrc,paddest, iscopy) 
    if not (padsrc and paddest) then return end
    if padsrc == paddest then return end
    
    if not iscopy then 
    -- remove old pad
      DATA2:Actions_PadClear(paddest)
    -- refresh external states
      DATA2:Actions_PadUpdateNote(padsrc, paddest) 
      DATA2.PARENT_LASTACTIVENOTE = paddest 
      DATA2:TrackDataWrite(_,{master_upd=true})
    end
    
    if iscopy and DATA2.notes[padsrc].TYPE_DEVICE ~= true then
      local tr_src = DATA2.notes[padsrc].layers[1].tr_ptr 
      SetOnlyTrackSelected( tr_src )
      local id =  CSurf_TrackToID( tr_src, false )
      GetSetMediaTrackInfo_String( tr_src, 'P_EXT:MPLRS5KMAN_TEMPCOPY', '1', true)  
      Action(40062) -- Track: Duplicate tracks 
      for i = id+1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        if ({GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_TEMPCOPY', '', false)})[2]  == '1' then  
          GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_TEMPCOPY', '', true)  
          DATA2:TrackDataWrite(track, {setnote_ID = paddest})
          local instrument_pos = DATA2.notes[padsrc].layers[1].instrument_pos
          DATA2:Actions_PadOnFileDrop_setnote_ID(track, instrument_pos, paddest, DATA2.notes[padsrc].layers[1].midifilt_pos)
          local instrumentGUID = TrackFX_GetFXGUID( track , instrument_pos)
          DATA2:TrackDataWrite(track , {setinstr_FXGUID = instrumentGUID})
          DATA2.PARENT_LASTACTIVENOTE = paddest 
          break
        end
      end 
    end
     
    DATA2:TrackDataRead()
    GUI_MODULE_DRUMRACKPAD(DATA) 
    
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadRename(note,layer) 
    if not layer then 
      if DATA2.notes[note].TYPE_DEVICE == true then t = DATA2.notes[note] else t = DATA2.notes[note].layers[1] end       -- do stuff on device or first layer only
     else t = DATA2.notes[note].layers[layer] -- do stuff on defined layer 
    end
    if not (t and t.tr_ptr) then return end
    
    
    local tr = t.tr_ptr
    DATA2.FORCEONPROJCHANGE = true
    local curname = t.name
    if not curname and DATA2.notes[note].TYPE_DEVICE == true then curname = t.device_name end
    local retval, retvals_csv = reaper.GetUserInputs( 'Rename pad', 1, ',extrawidth=200', curname )
    if retval then 
      GetSetMediaTrackInfo_String( tr, 'P_NAME', retvals_csv, true )
    end
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadMenu(note) 
    if not DATA2.tr_valid then return end
    local t = { 
      {str='Rename pad',
        func=function() DATA2:Actions_PadRename(note) end },  
      {str='Clear pad',
        func=function() DATA2:Actions_PadClear(note) end },  
      {str='Import selected items to pads, starting this pad',
        func=function() DATA2:Actions_ImportSelectedItems(note) end },
     
         
                }
              
    DATA:GUImenu(t)
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_ImportSelectedItems(note) 
    local cnt = CountSelectedMediaItems(0)
    local max_items = 8
    if cnt > max_items then
      local ret = MB('There are more than '..max_items..' items to import, continue?', '',3 )
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
          DATA2:Actions_PadOnFileDrop(note+i-1, layer, filenamebuf)
          DeleteTrackMediaItem(  reaper.GetMediaItemTrack( it ), it )
        end
      end
    end
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadOnFileDrop_ConvertChildToDevice(note) 
  
    -- add device track
    local ID_curchild =  CSurf_TrackToID( DATA2.notes[note].layers[1].tr_ptr, false )-1
    local devicetr = DATA2:Actions_PadOnFileDrop_AddChildTrack(ID_curchild) 
    SetMediaTrackInfo_Value( devicetr, 'I_FOLDERDEPTH', 1 ) -- make device track folder 
    local ID_devicetr =  CSurf_TrackToID(devicetr, false ) 
    local deviceGUID =  GetTrackGUID( devicetr )
    GetSetMediaTrackInfo_String( devicetr, 'P_NAME', 'Note '..note, 1 )
    DATA2:TrackDataWrite(devicetr, {setdevice=true})
    DATA2:TrackDataWrite(devicetr, {setnote_ID = note}) 
    DATA2:TrackDataWrite(devicetr, {set_currentparentforchild = true})  
    DATA2:TrackDataRead() -- refresh device ptr / ID
    
    -- set layer 1 as a device child
    local layer1_ptr = DATA2.notes[note].layers[1].tr_ptr
    DATA2:TrackDataWrite(layer1_ptr,{set_devicechild_deviceGUID=deviceGUID}) 
    SetMediaTrackInfo_Value( layer1_ptr, 'I_FOLDERDEPTH',- 1 ) 
    
  end
  ----------------------------------------------------------------------- 
  function DATA2:Actions_PadOnFileDrop_ReplaceRS5kSample(note,layer0,filepath) 
    local layer = layer0 or 1
    local new_tr = DATA2.notes[note].layers[layer].tr_ptr
    local instrument_pos = DATA2.notes[note].layers[layer].instrument_pos
    TrackFX_SetNamedConfigParm(  DATA2.notes[note].layers[layer].tr_ptr, DATA2.notes[note].layers[layer].instrument_pos, 'FILE0', filepath)
    TrackFX_SetNamedConfigParm(  DATA2.notes[note].layers[layer].tr_ptr, DATA2.notes[note].layers[layer].instrument_pos, 'DONE', '') 
    -- store external data
    local src = PCM_Source_CreateFromFile( filepath )
    if src then 
      local it_len =  GetMediaSourceLength( src )
      GetSetMediaTrackInfo_String( new_tr, 'P_EXT:MPLRS5KMAN_SAMPLELEN', it_len, true)
    end
    
    -- handle track name 
      filepath_sh = GetShortSmplName(filepath)
      if filepath_sh:match('(.*)%.[%a]+') then filepath_sh = filepath_sh:match('(.*)%.[%a]+') end
      GetSetMediaTrackInfo_String( DATA2.notes[note].layers[layer].tr_ptr, 'P_NAME', filepath_sh, true ) 
      
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadOnFileDrop_Sub(note, layer, filepath)
    --[[
    master_set
    master_upd
    setchild
    setnote
    setnote_ID
    set_currentparentforchild 
    setmidifilt
    setmidifilt_FXGUID
    setinstr
    setinstr_FXGUID
    setdevice
    setmidibus
    set_devicechild
    ]]
    
    
      

    if not layer then layer =1 end
    DATA2:TrackDataWrite(_,{master_set=true})  -- make sure folder is parent
    DATA2:TrackDataRead_ValidateMIDIbus()
    
      -- add new non-device child
    if not DATA2.notes[note] then
      SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERDEPTH', 1 ) -- make sure parent folder get parent ono adding first child
      local new_tr = DATA2:Actions_PadOnFileDrop_AddChildTrack()  -- set_currentparentforchild / setchild
      DATA2:Actions_PadOnFileDrop_ExportToRS5k(new_tr, filepath,note) 
      DATA2:Actions_PadOnFileDrop_AddMIDISend(new_tr)
      DATA2:TrackDataWrite(new_tr, {setnote_ID=note})
      DATA2:TrackDataRead_GetChildrens() 
      DATA_RESERVED_ONPROJCHANGE(DATA)
      local filepath_sh = GetShortSmplName(filepath) if filepath_sh:match('(.*)%.[%a]+') then filepath_sh = filepath_sh:match('(.*)%.[%a]+') end SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, filepath_sh)  
      return
    end
    
    -- replace existing sample into 1st layer 
    if DATA2.notes[note] and DATA2.notes[note].layers[1].TYPE_REGCHILD==true and layer == 1 then
      DATA2:Actions_PadOnFileDrop_ReplaceRS5kSample(note, 1, filepath) 
      DATA2:TrackDataRead_GetChildrens() 
      DATA_RESERVED_ONPROJCHANGE(DATA)
      local filepath_sh = GetShortSmplName(filepath) if filepath_sh:match('(.*)%.[%a]+') then filepath_sh = filepath_sh:match('(.*)%.[%a]+') end SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, filepath_sh)  
      return
    end
    
    -- create device / move first layer to a device
    if DATA2.notes[note] and not DATA2.notes[note].TYPE_DEVICE and layer ~= 1 then
      DATA2:Actions_PadOnFileDrop_ConvertChildToDevice(note)  
      SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, 'Note '..note)  
      local new_tr = DATA2:Actions_PadOnFileDrop_AddChildTrack(DATA2.notes[note].devicetr_ID) 
      if new_tr then 
        DATA2:Actions_PadOnFileDrop_ExportToRS5k(new_tr, filepath, note) 
        DATA2:Actions_PadOnFileDrop_AddMIDISend(new_tr)
        DATA2:TrackDataWrite(new_tr, {set_devicechild_deviceGUID=DATA2.notes[note].tr_GUID})
        DATA2:TrackDataWrite(new_tr, {setnote_ID=note})
      end
      DATA2:TrackDataRead_GetChildrens() 
      DATA_RESERVED_ONPROJCHANGE(DATA)
      return
    end
    
    -- replace device existing sample in specific layer
    if DATA2.notes[note] and DATA2.notes[note].TYPE_DEVICE == true and DATA2.notes[note].layers and DATA2.notes[note].layers[layer] then 
      DATA2:Actions_PadOnFileDrop_ReplaceRS5kSample(note,layer,filepath)
      DATA2:TrackDataRead_GetChildrens() 
      DATA_RESERVED_ONPROJCHANGE(DATA)
      return
    end      
    
    -- add  new layer to device
    if DATA2.notes[note] and DATA2.notes[note].TYPE_DEVICE == true and DATA2.notes[note].layers and not DATA2.notes[note].layers[layer] then 
      local devicetr_ID = DATA2.notes[note].devicetr_ID
      local new_tr = DATA2:Actions_PadOnFileDrop_AddChildTrack(devicetr_ID) 
      if new_tr then
        DATA2:Actions_PadOnFileDrop_ExportToRS5k(new_tr, filepath,note) 
        DATA2:Actions_PadOnFileDrop_AddMIDISend(new_tr)
        DATA2:TrackDataWrite(new_tr, {set_devicechild_deviceGUID=DATA2.notes[note].tr_GUID})
      end
    end
    
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadOnFileDrop(note, layer, filepath0) 
    if not DATA2.tr_valid then return end
    
    -- validate additional stuff
    DATA2:TrackDataRead_ValidateMIDIbus()
    SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERCOMPACT',1 ) -- folder compacted state (only valid on folders), 0=normal, 1=small, 2=tiny children
    DATA2:TrackDataRead(DATA2.tr_ptr)
    -- get fp
      if filepath0 then 
        DATA2:Actions_PadOnFileDrop_Sub(note, layer, filepath)
       else
        for i =1, #DATA.GUI.droppedfiles.files+1 do
          local filepath = DATA.GUI.droppedfiles.files[i-1]
          DATA2:Actions_PadOnFileDrop_Sub(note+i-1, layer, filepath)
        end
      end
      
    -- refresh data
      DATA2:TrackDataRead(DATA2.tr_ptr)
      DATA2.PARENT_LASTACTIVENOTE = note
      DATA2.PARENT_LASTACTIVENOTE_layer = layer
      DATA2:TrackDataWrite(_,{master_upd=true})
      DATA_RESERVED_ONPROJCHANGE(DATA)
      --GUI_MODULE_DRUMRACKPAD(DATA)  
      --GUI_MODULE_SAMPLER(DATA)
  end
  -----------------------------------------------------------------------------  
  
  function GUI_MODULE_DEVICE_stuff(DATA, note, layer, y_offs) 
    local x_offs = DATA.GUI.buttons.devicestuff_frame.x
    local w_layername = math.floor(DATA.GUI.buttons.devicestuff_frame.w*0.55)
    local w_ctrls = DATA.GUI.buttons.devicestuff_frame.w - w_layername-DATA.GUI.custom_offset
    local w_ctrls_single = (w_ctrls / 10)
    local reduce = 1
    local frame_a = 0
    local backgr_col=DATA.GUI.custom_backcol2
    local backgr_fill_param = 0.2 
    local backgr_fill_name = 0
    if DATA2.PARENT_LASTACTIVENOTE_layer and DATA2.PARENT_LASTACTIVENOTE_layer == layer then 
      backgr_fill_name = DATA.GUI.custom_backfill2 
    end
    -- name
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'name'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_layername,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        --ignoremouse = DATA2.PARENT_TABSTATEFLAGS&2==0,
                        txt = DATA2.notes[note].layers[layer].name,
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        frame_a = frame_a,
                        backgr_fill = backgr_fill_name,
                        backgr_col =backgr_col,
                        onmouseclick = function() 
                          DATA2.PARENT_LASTACTIVENOTE_layer = layer 
                          GUI_MODULE_SAMPLER(DATA)
                          GUI_MODULE_DEVICE(DATA) 
                        end,
                        onmousefiledrop = function() DATA2:Actions_PadOnFileDrop(note,layer) end, 
                        }
    -- vol
    local val 
    if DATA2.notes[note].layers[layer].tr_vol then val= DATA2.notes[note].layers[layer].tr_vol/2 end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'] = { 
                        x=x_offs+w_layername+DATA.GUI.custom_offset,
                        y=y_offs,
                        w=w_ctrls_single*4-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        val = val,
                        val_res = -0.1,
                        val_xaxis = true,
                        txt = DATA2.notes[note].layers[layer].tr_vol_format,
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        onmousedrag = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].val
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_VOL', new_val*2 )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].txt = DATA2.notes[note].layers[layer].tr_vol_format
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].refresh = true
                              DATA2.ONPARAMDRAG = true
                            end,
                        onmouserelease = function()
                              if not DATA2.ONDOUBLECLICK then
                                DATA2.ONPARAMDRAG = nil
                                local src_t = DATA2.notes[note].layers[layer]
                                local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].val
                                SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_VOL', new_val*2 )
                                DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                                DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].txt = DATA2.notes[note].layers[layer].tr_vol_format
                                DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].refresh = true
                               else
                                DATA2.ONDOUBLECLICK = nil
                              end
                        end,
                        onmousedoubleclick = function() 
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = 1
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_VOL', new_val )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].txt = DATA2.notes[note].layers[layer].tr_vol_format
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].refresh = true
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'].val = 0.5
                              DATA2.ONDOUBLECLICK = true
                            end,
                        }   
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'] = { 
                        x=x_offs+w_layername+w_ctrls_single*4+DATA.GUI.custom_offset,
                        y=y_offs,
                        w=w_ctrls_single*3-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        val = DATA2.notes[note].layers[layer].tr_pan,
                        val_res = -0.6,
                        val_xaxis = true,
                        val_centered = true,
                        val_min = -1,
                        val_max = 1,
                        txt = DATA2.notes[note].layers[layer].tr_pan_format,
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        onmousedrag = function()
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].val
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_PAN', new_val )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = DATA2:internal_FormatPan(new_val)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                              DATA2.ONPARAMDRAG = true
                            end,
                        onmouserelease = function()
                            if not DATA2.ONDOUBLECLICK then
                              DATA2.ONPARAMDRAG = nil
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].val
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_PAN', new_val )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = DATA2:internal_FormatPan(new_val)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                             else
                              DATA2.ONDOUBLECLICK = nil
                            end
                        end,
                        onmousedoubleclick = function() 
                              local src_t = DATA2.notes[note].layers[layer]
                              local new_val = 0
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_PAN', new_val )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].txt = DATA2:internal_FormatPan(new_val)
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].val = new_val
                              DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'].refresh = true
                              DATA2.ONDOUBLECLICK = true
                            end,}   
                        
    local backgr_fill_param_en
    if DATA2.notes[note].layers[layer].instrument_enabled == true then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'enable'] = { 
                        x=x_offs+w_layername+w_ctrls_single*7+DATA.GUI.custom_offset,
                        y=y_offs,
                        w=w_ctrls_single-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        txt = 'On',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        onmouserelease = function()
                              local src_t = DATA2.notes[note].layers[layer] 
                              local newval = 1 if src_t.instrument_enabled == true then newval = 0 end
                              reaper.TrackFX_SetEnabled( src_t.tr_ptr, src_t.instrument_pos, newval )
                              DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
                            end,
                        }     
                        
    local backgr_fill_param_en
    if DATA2.notes and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[layer].tr_solo and DATA2.notes[note].layers[layer].tr_solo >0 then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'solo'] = { 
                        x=x_offs+w_layername+w_ctrls_single*8+DATA.GUI.custom_offset,
                        y=y_offs,
                        w=w_ctrls_single-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        txt = 'S',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        onmouserelease = function()DATA2:Actions_PadSoloMute(note,layer,true) end,
                        }   
    local backgr_fill_param_en
    if DATA2.notes and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[layer].tr_mute and DATA2.notes[note].layers[layer].tr_mute >0 then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'mute'] = { 
                        x=x_offs+w_layername+w_ctrls_single*9+DATA.GUI.custom_offset,
                        y=y_offs,
                        w=w_ctrls_single-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh-reduce,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        txt = 'M',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        onmouserelease = function() DATA2:Actions_PadSoloMute(note,layer,_, true)end,
                        }                         
  end
  ----------------------------------------------------------------------------- 
  function GUI_MODULE_DEVICE(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('devicestuff') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&2==0) then return end
    if not (DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE~=-1 and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE] ) then return end
    local layers_cnt = 0
    if DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].layers then 
      layers_cnt = #DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].layers
    end
    
    local name = '' 
    if DATA2.PARENT_LASTACTIVENOTE and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE] and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].name and not DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].TYPE_DEVICE  then 
      name = '[Note '..DATA2.PARENT_LASTACTIVENOTE..' / '..DATA2:internal_FormatMIDIPitch(DATA2.PARENT_LASTACTIVENOTE)..'] '..DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].name 
     elseif DATA2.PARENT_LASTACTIVENOTE and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE]  and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].TYPE_DEVICE ==true then
      name = '[Device '..DATA2.PARENT_LASTACTIVENOTE..' / '..DATA2:internal_FormatMIDIPitch(DATA2.PARENT_LASTACTIVENOTE)..'] '..(DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].device_name or '')
    end
    local x_offs = DATA.GUI.custom_offset +DATA.GUI.custom_tab_w
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==16 then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&8==8 then x_offs = x_offs + DATA.GUI.custom_padgridw + DATA.GUI.custom_offset end -- pad view
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&1==1 then x_offs = x_offs + DATA.GUI.custom_drrack_sideW + DATA.GUI.custom_offset end -- drrack
    
    local device_y = DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    
    DATA.GUI.buttons.devicestuff_name = { x=x_offs,
                         y=0,
                         w=DATA.GUI.custom_devicew-DATA.GUI.custom_infoh-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = name,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() DATA2:Actions_PadMenu(DATA2.PARENT_LASTACTIVENOTE) end
                         }
      DATA.GUI.buttons.devicestuff_help = { x=x_offs+DATA.GUI.custom_devicew-DATA.GUI.custom_infoh,
                           y=0,
                           w=DATA.GUI.custom_infoh-1,
                           h=DATA.GUI.custom_infoh-1,
                           txt = '?',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() 
                                              DATA2:Actions_Help(1)
                                            end,
                           }         
        
        
    if not DATA2.PARENT_LASTACTIVENOTE then return end
    local PARENT_LASTACTIVENOTE = DATA2.PARENT_LASTACTIVENOTE
    if not DATA2.notes[PARENT_LASTACTIVENOTE] then return end
                          
    DATA.GUI.buttons.devicestuff_frame = { x=x_offs,
                          y=device_y,
                          w=DATA.GUI.custom_devicew+1,
                          h=DATA.GUI.custom_deviceh+DATA.GUI.custom_offset,
                          ignoremouse = true,
                          frame_a =1,
                          frame_col = '#333333',
                          backgr_fill = 0,
                          }  
                          
    local y_offs = DATA.GUI.buttons.devicestuff_frame.y+ DATA.GUI.custom_offset
    local w_dev = DATA.GUI.buttons.devicestuff_frame.w
    if DATA2.notes and DATA2.notes[PARENT_LASTACTIVENOTE] and DATA2.notes[PARENT_LASTACTIVENOTE].layers then 
      for layer = 1, #DATA2.notes[PARENT_LASTACTIVENOTE].layers do
        GUI_MODULE_DEVICE_stuff(DATA, PARENT_LASTACTIVENOTE, layer, y_offs)  
        y_offs = y_offs + DATA.GUI.custom_deviceentryh
      end
    end
    
    DATA.GUI.buttons.devicestuff_frame_fillactive = { x=x_offs,
                          y=DATA.GUI.custom_infoh+DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_devicew,
                          h=y_offs - device_y,--DATA.GUI.custom_deviceh-DATA.GUI.custom_offset+DATA.GUI.custom_offset,
                          ignoremouse = true,
                          frame_a =1,
                          frame_col = '#333333',
                          }
    DATA.GUI.buttons.devicestuff_droparea = { x=x_offs+1,
                          y=y_offs+DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_devicew-1,
                          h=DATA.GUI.custom_deviceh-(y_offs-device_y)-DATA.GUI.custom_offset*2,
                          --ignoremouse = true,
                          txt = 'Drop new instrument here',
                          txt_fontsz = DATA.GUI.custom_device_droptxtsz,
                          --frame_a =0.1,
                          --frame_col = '#333333',
                          onmousefiledrop = function() DATA2:Actions_PadOnFileDrop(DATA2.PARENT_LASTACTIVENOTE, layers_cnt+1) end,
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
                          y=DATA.GUI.custom_padgridy+DATA.GUI.custom_padgridh - cellside*(1+(math.floor(note/4))),
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
    
    
    if DATA2.PARENT_ACTIVEPAD then
      local padactiveshift = 0
      if DATA2.PARENT_ACTIVEPAD == 7 then padactiveshift = cellside * (4*1-1) end
      if DATA2.PARENT_ACTIVEPAD == 6 then padactiveshift = cellside * (4*2-1) end
      if DATA2.PARENT_ACTIVEPAD == 5 then padactiveshift = cellside * (4*3-1) end
      if DATA2.PARENT_ACTIVEPAD == 4 then padactiveshift = cellside * (4*4-1) end
      if DATA2.PARENT_ACTIVEPAD == 3 then padactiveshift = cellside * (4*5-1) end
      if DATA2.PARENT_ACTIVEPAD == 2 then padactiveshift = cellside * (4*6-1) end
      if DATA2.PARENT_ACTIVEPAD == 1 then padactiveshift = cellside * (4*7-1) end
      if DATA2.PARENT_ACTIVEPAD == 0 then padactiveshift = cellside * (4*7) end
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
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&8==0) then return end
    
    local x_offs= DATA.GUI.custom_module_startoffsx
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==16 and skip_grid~=true then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    DATA.GUI.buttons.padgrid = { x=math.floor(x_offs),
                          y=math.floor(DATA.GUI.custom_padgridy),
                          w=math.floor(DATA.GUI.custom_padgridw),
                          h=math.floor(DATA.GUI.custom_padgridh),
                          txt = '',
                          
                          val = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          backgr_fill = 0,
                          onmouseclick =  function() 
                                            DATA2.PARENT_ACTIVEPAD = VF_lim(math.floor((1-DATA.GUI.buttons.padgrid.val_abs)*9) ,0,9) 
                                            DATA.GUI.buttons.padgrid_activerect.refresh = true
                                            GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                            GUI_MODULE_DRUMRACKPAD(DATA)  
                                          end,
                          onmousedrag =   function() 
                                            if DATA.GUI.buttons.padgrid.val_abs then 
                                              local new = VF_lim(math.floor((1-DATA.GUI.buttons.padgrid.val_abs)*9) ,0,9) 
                                              if new ~= DATA2.PARENT_ACTIVEPAD then 
                                                DATA2.PARENT_ACTIVEPAD = new 
                                                DATA.GUI.buttons.padgrid_activerect.refresh = true
                                                GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                                GUI_MODULE_DRUMRACKPAD(DATA)  
                                              end
                                            end
                                          end,
                          onmouserelease = function() 
                                            DATA2.PARENT_ACTIVEPAD = VF_lim(math.floor((1-DATA.GUI.buttons.padgrid.val_abs)*9) ,0,9) 
                                            DATA.GUI.buttons.padgrid_activerect.refresh = true
                                            GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                            GUI_MODULE_DRUMRACKPAD(DATA)  
                                            DATA2:TrackDataWrite(_,{master_upd=true}) 
                                          end,
                          onmousefiledrop = function() 
                            local note = 0
                            if DATA2.PARENT_ACTIVEPAD == 0 then note = 0
                             elseif DATA2.PARENT_ACTIVEPAD == 1 then note = 4
                             elseif DATA2.PARENT_ACTIVEPAD == 2 then note = 20
                             elseif DATA2.PARENT_ACTIVEPAD == 3 then note = 36
                             elseif DATA2.PARENT_ACTIVEPAD == 4 then note = 52
                             elseif DATA2.PARENT_ACTIVEPAD == 5 then note = 68
                             elseif DATA2.PARENT_ACTIVEPAD == 6 then note = 84
                             elseif DATA2.PARENT_ACTIVEPAD == 7 then note = 100
                             elseif DATA2.PARENT_ACTIVEPAD == 8 then note = 116
                            end
                            
                            for i = note, 127 do
                              if not DATA2.notes[i] then note = i break end
                            end
                            DATA2:Actions_PadOnFileDrop(note) 
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
  function DATA2:internal_GetActiveNoteLayerTable()
  
    local layer =  DATA2.PARENT_LASTACTIVENOTE_layer or 1 
    local note if not DATA2.PARENT_LASTACTIVENOTE  then return else note =DATA2.PARENT_LASTACTIVENOTE end
    if DATA2.notes[note] 
      and DATA2.notes[note].layers 
      and DATA2.notes[note].layers[layer] then  
      return DATA2.notes[note].layers[layer],note,layer
    end
  end
  ---------------------------------------------------------------------------------------------------------------------
  function DATA2:internal_GetPeaks()
    local t, note, layer = DATA2:internal_GetActiveNoteLayerTable()
    if not (t and t.instrument_filepath) then return end 
    filepath = t.instrument_filepath
    
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
  function DATA2:Actions_SamplerMenu_SetStartToLoudestPeak() 
    local note = DATA2.PARENT_LASTACTIVENOTE
    local layer = DATA2.PARENT_LASTACTIVENOTE_layer or 1
    if not note then return end 
    if not (DATA2.cursplpeaks and DATA2.cursplpeaks.peaks)then return end  
    
    local cnt_peaks = #DATA2.cursplpeaks.peaks
    for i = 1, cnt_peaks do if math.abs(DATA2.cursplpeaks.peaks[i]) ==1 then loopst = i/cnt_peaks break end end
    local src_t = DATA2.notes[note].layers[layer]
    TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 13, loopst ) 
  end    
  ----------------------------------------------------------------------
  function DATA2:Actions_SamplerMenu_CropToAudibleBoundaries()
    local note = DATA2.PARENT_LASTACTIVENOTE
    local layer = DATA2.PARENT_LASTACTIVENOTE_layer or 1
    if not note then return end 
    if not (DATA2.cursplpeaks and DATA2.cursplpeaks.peaks)then return end
    
    -- threshold
    local threshold_lin = WDL_DB2VAL(DATA.extstate.CONF_cropthreshold)
    local cnt_peaks = #DATA2.cursplpeaks.peaks
    local loopst = 0
    local loopend = 1
    for i = 1, cnt_peaks do if math.abs(DATA2.cursplpeaks.peaks[i]) > threshold_lin then loopst = i/cnt_peaks break end end
    for i = cnt_peaks, 1, -1 do if math.abs(DATA2.cursplpeaks.peaks[i]) > threshold_lin then loopend = i/cnt_peaks break end end
    
    local src_t = DATA2.notes[note].layers[layer]
    TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 13, loopst ) 
    TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 14, loopend ) 
  end
  ----------------------------------------------------------------------
  function  DATA2:Actions_SamplerMenu()  
    local t = {
              
  {str = '#Actions'},
  {str = 'Crop sample to audible boundaries, threshold '..DATA.extstate.CONF_cropthreshold..'dB',
   func = function() DATA2:Actions_SamplerMenu_CropToAudibleBoundaries()   end},

  {str = 'Set start offset to a loudest peak',
   func = function() DATA2:Actions_SamplerMenu_SetStartToLoudestPeak()   end},
   
  
              }
    DATA:GUImenu(t)
  end 
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_peaks()
    if not (DATA2.cursplpeaks and DATA2.cursplpeaks.peaks) then return end
    local note, layer = DATA2.cursplpeaks.note,DATA2.cursplpeaks.layer
    if DATA2.notes[note].layers[layer].ISPLUGIN then return end
    local offs_start = DATA2.notes[note].layers[layer].instrument_samplestoffs
    local offs_end = DATA2.notes[note].layers[layer].instrument_sampleendoffs 
    local loopoffs = DATA2.notes[note].layers[layer].instrument_loopoffs
    local SAMPLELEN = DATA2.notes[note].layers[layer].SAMPLELEN
    
    if not offs_start then return end
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
    local txt_fontsz_out = DATA.GUI.custom_sampler_ctrl_txtsz
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
      local loopoffs_ms = loopoffs*30 + SAMPLELEN * offs_start
      local loopoffs_ratio = loopoffs_ms / SAMPLELEN
      local loop_st = x0+w*loopoffs_ratio
      local loop_end = x0+w*offs_end
      gfx.rect(loop_st,y0,loop_end-loop_st,h,1)
    end
  end  
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
    local spl_t = DATA2:internal_GetActiveNoteLayerTable()
    --if not (spl_t and spl_t.ISRS5K) then return end
    if not DATA.GUI.buttons.sampler_frame then return end
    
    local backgr_fill = 0
    local backgr_col = DATA.GUI.custom_backcol2
    if spl_t.instrument_loop == 1 then backgr_fill = 0.2 end
    local txt = 'Loop' if not spl_t.ISRS5K then txt = '' end
    DATA.GUI.buttons.sampler_mode1 = { x= DATA.GUI.buttons.sampler_frame.x ,
                        y=DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset,
                        w=DATA.GUI.custom_sampler_modew,
                        h=DATA.GUI.custom_sampler_readouth-1,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = txt,
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouseclick = function() 
                          TrackFX_SetParamNormalized( spl_t.tr_ptr, spl_t.instrument_pos, 12, 1 ) 
                          DATA2:TrackDataRead_GetChildrens_InstrumentParams(spl_t) -- refresh state
                          GUI_MODULE_SAMPLER_Section_Loopstate(DATA) 
                        end,
                        } 
    local backgr_fill = 0
    local backgr_col = DATA.GUI.custom_backcol2
    if spl_t.instrument_loop == 0 then backgr_fill = 0.2 end
    local txt = '1-shot' if not spl_t.ISRS5K then txt = '' end
    DATA.GUI.buttons.sampler_mode2 = { x= DATA.GUI.buttons.sampler_frame.x,
                        y=DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_sampler_readouth+ DATA.GUI.custom_offset+1 ,
                        w=DATA.GUI.custom_sampler_modew,
                        h=DATA.GUI.custom_sampler_readouth-2,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        txt = txt,
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        onmouseclick = function() 
                          TrackFX_SetParamNormalized( spl_t.tr_ptr, spl_t.instrument_pos, 12, 0 ) 
                          DATA2:TrackDataRead_GetChildrens_InstrumentParams(spl_t) -- refresh state
                          GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
                        end,
                        } 
  end
  ----------------------------------------------------------------------
  function DATA2:Actions_ShowInstrument(note, layer0) 
    local layer = layer0 or 1
    local spl_t = DATA2:internal_GetActiveNoteLayerTable()
    --    if not (DATA2.notes and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[layer]) then MB('Sampler not found', '', 0) return end
    local track  = DATA2.notes[note].layers[layer].tr_ptr
    reaper.TrackFX_Show( track, spl_t.instrument_pos , 3 )
  end
  ---------------------------------------------------------------------- 
  function GUI_MODULE_SAMPLER(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('sampler_') and key~=sampler_framepeaks then DATA.GUI.buttons[key] = nil end end
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&4==0) then return end
    
    local x_offs = DATA.GUI.custom_module_startoffsx
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==16 then x_offs = x_offs + DATA.GUI.custom_offset+  DATA.GUI.custom_macroW end -- macro
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&8==8 then x_offs = x_offs + DATA.GUI.custom_padgridw + DATA.GUI.custom_offset end -- pad view
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&1==1 then x_offs = x_offs + DATA.GUI.custom_drrack_sideW + DATA.GUI.custom_offset end -- drrack
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&2==2 then x_offs = x_offs + DATA.GUI.custom_devicew + DATA.GUI.custom_offset end -- device
    
    -- sample name  
    
      local spl_t, note, layer = DATA2:internal_GetActiveNoteLayerTable()
      if not spl_t then return end 
      name = '[Layer '..layer..'] '..(spl_t.name or '')
      DATA.GUI.buttons.sampler_frame = { x=x_offs,
                            y=DATA.GUI.custom_infoh+DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_samplerW,
                            h=DATA.GUI.custom_deviceh-DATA.GUI.custom_offset+DATA.GUI.custom_offset,
                            ignoremouse = true,
                            frame_a =1,
                            frame_col = '#333333',
                            } 
      DATA.GUI.buttons.sampler_name = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_sampler_namebutw-DATA.GUI.custom_offset*2,
                           h=DATA.GUI.custom_infoh-1,
                           txt = name,
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           }
                            
      DATA.GUI.buttons.Actions_SamplerMenu = { x=x_offs+DATA.GUI.custom_sampler_namebutw-DATA.GUI.custom_offset,
                           y=0,
                           w=DATA.GUI.custom_sampler_showbutw-1,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'Actions',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function()  DATA2:Actions_SamplerMenu()  end,
                           }                             
      DATA.GUI.buttons.sampler_show = { x=x_offs+DATA.GUI.custom_sampler_namebutw+DATA.GUI.custom_sampler_showbutw,
                           y=0,
                           w=DATA.GUI.custom_sampler_showbutw-1,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'Show',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() DATA2:Actions_ShowInstrument(note, layer) end,
                           }                     
    local txt = ''
    if not spl_t.ISRS5K then txt = '['..spl_t.instrument_fxname..']' end
    DATA.GUI.buttons.sampler_framepeaks = { x= DATA.GUI.buttons.sampler_frame.x + DATA.GUI.custom_offset+DATA.GUI.custom_sampler_modew,
                            y=DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_sampler_peaksw,
                            h=DATA.GUI.custom_sampler_peakareah,
                            --ignoremouse = true,
                            txt = txt,
                            frame_a = DATA.GUI.custom_framea,
                            data = {['datatype'] = 'samplepeaks'},
                            onmousefiledrop = function() if DATA2.PARENT_LASTACTIVENOTE then DATA2:Actions_PadOnFileDrop(DATA2.PARENT_LASTACTIVENOTE) end end,
                            onmouseclick = function() if DATA2.PARENT_LASTACTIVENOTE then DATA2:Actions_StuffNoteOn(DATA2.PARENT_LASTACTIVENOTE) end  end,
                            onmouseclickR = function() DATA2:Actions_SamplerMenu()  end,
                            refresh = true,
                            }
    
    GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
    GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) 
    GUI_MODULE_SAMPLER_Section_FilterSection(DATA) 
    GUI_MODULE_SAMPLER_Section_EnvelopeSection(DATA)  
    if spl_t.ISRS5K then DATA2:internal_GetPeaks()  end
    --GUI_MODULE_SAMPLER_peaks()
  end
  ---------------------------------------------------------------------- 
  function GUI_CTRL(DATA, params_t) 
  
    local t = params_t
    local src_t = t.ctrlval_src_t 
    if not (src_t and t.ctrlval_key and src_t[t.ctrlval_key]) then return end
    -- frame
    DATA.GUI.buttons[t.butkey..'frame'] = { x= t.x,
                        y=t.y ,
                        w=t.w,
                        h=t.h,
                        --ignoremouse = true,
                        frame_a =DATA.GUI.custom_framea,
                        --frame_col = '#333333',
                        backgr_col = '#333333',
                        backgr_fill = 1,
                        back_sela = 0,
                        
                        frame_arcborder = true,
                        frame_arcborderr = math.floor(DATA.GUI.custom_offset*2),
                        frame_arcborderflags = 1|2|4|8,
                        
                        val = src_t[t.ctrlval_key],
                        val_res = t.ctrlval_res,
                        val_min = t.ctrlval_min,
                        val_max = t.ctrlval_max,
                        onmouseclick = function() 
                                          local new_val = DATA.GUI.buttons[t.butkey..'frame'].val
                                          if params_t.func_atclick then params_t.func_atclick(new_val) end
                                        end,
                        onmousedrag = function()
                              DATA2.ONPARAMDRAG = true
                              local new_val = DATA.GUI.buttons[t.butkey..'frame'].val
                              params_t.func_app(new_val)
                              params_t.func_refresh()
                              DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                              if DATA.GUI.buttons[t.butkey..'knob'] then 
                                local val_norm = src_t[t.ctrlval_key] 
                                if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                DATA.GUI.buttons[t.butkey..'knob'].val = val_norm
                              end
                              DATA.GUI.buttons[t.butkey..'val'].refresh = true
                            end,
                        onmousedoubleclick = function() 
                                if not t.ctrlval_default then return end
                                params_t.func_app(t.ctrlval_default)
                                params_t.func_refresh()
                                DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                                DATA.GUI.buttons[t.butkey..'val'].refresh = true
                                if DATA.GUI.buttons[t.butkey..'knob'] then 
                                  local val_norm = src_t[t.ctrlval_key] 
                                  if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                  DATA.GUI.buttons[t.butkey..'knob'].val = val_norm
                                end
                                DATA2.ONDOUBLECLICK = true
                              end,                            
                        onmouserelease = function()
                              if not DATA2.ONDOUBLECLICK then
                                local new_val = DATA.GUI.buttons[t.butkey..'frame'].val
                                params_t.func_app(new_val)
                                params_t.func_refresh()
                                DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                                DATA.GUI.buttons[t.butkey..'val'].refresh = true
                                DATA.GUI.buttons[t.butkey..'val'].val = src_t[t.ctrlval_key]
                                if DATA.GUI.buttons[t.butkey..'knob'] then 
                                  local val_norm = src_t[t.ctrlval_key] 
                                  if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                  DATA.GUI.buttons[t.butkey..'knob'].val = val_norm
                                end
                                DATA2.ONPARAMDRAG = false
                               else
                                DATA2.ONDOUBLECLICK = nil
                              end
                        end,
                        
                        onmousereleaseR = function()
                                if not params_t.func_formatreverse then return end
                                local retval, str = GetUserInputs( 'Set values', 1, '', src_t[t.ctrlval_format_key] )
                                if not (retval and str ~='' ) then return end  
                                new_val = params_t.func_formatreverse(str )
                                if not new_val then return end
                                params_t.func_app(new_val)
                                params_t.func_refresh()
                                DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                                DATA.GUI.buttons[t.butkey..'val'].refresh = true
                                if DATA.GUI.buttons[t.butkey..'knob'] then 
                                  local val_norm = src_t[t.ctrlval_key] 
                                  if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                  DATA.GUI.buttons[t.butkey..'knob'].val = val_norm
                                end
                        end,  
                        } 
                                          
    DATA.GUI.buttons[t.butkey..'name'] = { x= t.x+1+DATA.GUI.custom_offset*2,
                        y=t.y+1 ,
                        w=t.w-2-DATA.GUI.custom_offset*4,
                        h=DATA.GUI.custom_module_ctrlreadout_h,
                        ignoremouse = true,
                        frame_a = 1,
                        frame_col = '#333333',
                        txt = t.ctrlname,
                        txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                        }  
    DATA.GUI.buttons[t.butkey..'val'] = { x= t.x+1+DATA.GUI.custom_offset*2,
                        y=t.y+t.h-DATA.GUI.custom_module_ctrlreadout_h -1,
                        w=t.w-2-DATA.GUI.custom_offset*4,
                        h=DATA.GUI.custom_module_ctrlreadout_h,
                        ignoremouse = true,
                        frame_a = 1,
                        frame_col = '#333333',
                        txt = src_t[t.ctrlval_format_key],
                        txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                        }                         
    
    if DATA.GUI.custom_module_ctrlreadout_h * 3 > t.h then return end
    
    local val_norm = src_t[t.ctrlval_key] 
    if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
    DATA.GUI.buttons[t.butkey..'knob'] = { x= t.x+DATA.GUI.custom_offset+1,--+arc_shift,
                        y=t.y+DATA.GUI.custom_module_ctrlreadout_h+DATA.GUI.custom_offset-1,
                        w=t.w-2-DATA.GUI.custom_offset*2,---arc_shift*2,
                        h=t.h-DATA.GUI.custom_module_ctrlreadout_h*2-DATA.GUI.custom_offset*2+2,
                        ignoremouse = true,
                        frame_a =1,
                        frame_col = '#333333',
                        knob_isknob = true,
                        val = val_norm,
                        }
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) 
    local src_t = DATA2:internal_GetActiveNoteLayerTable()
    
    local val_res = 0.03
    local woffs= DATA.GUI.custom_sampler_modew+DATA.GUI.custom_offset
    local xoffs= DATA.GUI.buttons.sampler_frame.x
    local yoffs= DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_sampler_peakareah+DATA.GUI.custom_offset*2
    
    xoffs = xoffs + 0 
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_gain',
        
        x = DATA.GUI.buttons.sampler_frame.x,
        y= yoffs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_module_ctrlreadout_h*2,
        
        ctrlname = 'Gain',
        ctrlval_key = 'instrument_vol',
        ctrlval_format_key = 'instrument_vol_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.1,
        ctrlval_default = 0.5,
        
        func_app =            function(new_val) TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 0, new_val ) end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, 0) 
                                return new_val
                              end
       } )
       
    xoffs = xoffs + woffs 
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_tune',
        
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_module_ctrlreadout_h*2,
        
        ctrlname = 'Tune',
        ctrlval_key = 'instrument_tune',
        ctrlval_format_key = 'instrument_tune_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.01,
        ctrlval_default = 0.5,
        func_atclick   =        function(new_val) 
                                  local new_val_quant = math.floor(new_val*160)/160 
                                  DATA2.TEMPnew_val_diff = new_val - new_val_quant
                                end,
        func_app =            function(new_val) 
                                if DATA.GUI.Ctrl then
                                  TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, new_val ) 
                                 else
                                  local new_val_quant = math.floor(new_val*160)/160 
                                  TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, new_val_quant + DATA2.TEMPnew_val_diff) 
                                end
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, 15) 
                                return new_val
                              end
       } )       

    xoffs = xoffs + woffs 
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_samplestoffs',
        
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_module_ctrlreadout_h*2,
        
        ctrlname = 'Start',
        ctrlval_key = 'instrument_samplestoffs',
        ctrlval_format_key = 'instrument_samplestoffs_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.1,
        ctrlval_default = 0,
        
        func_app =            function(new_val) TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 13, new_val ) end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, 13) 
                                return new_val
                              end
       } )        

    xoffs = xoffs + woffs 
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_sampleendoffs',
        
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_module_ctrlreadout_h*2,
        
        ctrlname = 'End',
        ctrlval_key = 'instrument_sampleendoffs',
        ctrlval_format_key = 'instrument_sampleendoffs_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.1,
        ctrlval_default = 1,
        
        func_app =            function(new_val) TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 14, new_val ) end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, 14) 
                                return new_val
                              end
       } ) 
    if not src_t.instrument_samplestoffs then return end
    local st_s = src_t.instrument_samplestoffs * src_t.SAMPLELEN
    local end_s = src_t.instrument_sampleendoffs * src_t.SAMPLELEN
    local max_offs_s = (end_s - st_s) / 30 
    xoffs = xoffs + woffs 
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_loopoffs',
        
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_module_ctrlreadout_h*2,
        
        ctrlname = 'Loop',
        ctrlval_key = 'instrument_loopoffs',
        ctrlval_format_key = 'instrument_loopoffs_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.1,
        ctrlval_default = 0,
        ctrlval_min = 0,
        ctrlval_max = max_offs_s,
        
        func_app =            function(new_val) TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 23, new_val ) end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, 23) 
                                return new_val
                              end
       } )    
       
    xoffs = xoffs + woffs 
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_maxvoices',
        
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_module_ctrlreadout_h*2,
        
        ctrlname = 'Voices',
        ctrlval_key = 'instrument_maxvoices',
        ctrlval_format_key = 'instrument_maxvoices_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.1,
        ctrlval_default = 0,
        
        func_app =            function(new_val) TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 8, new_val ) end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, 8) 
                                return new_val
                              end
       } )        
    do return end

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
          w = DATA.GUI.custom_sampler_modew-1,
          h = DATA.GUI.custom_module_ctrlreadout_h*2,
          note =note,
          layer=layer
        } )  
      
  end
  -----------------------------------------------------------------------  
  function DATA2:TrackData_InitMacro()
    local fxname = 'mpl_RS5k manager_MacroControls.jsfx'
    local macroJSFX_pos =  TrackFX_AddByName( DATA2.tr_ptr, fxname, false, 1 ) 
    if macroJSFX_pos ~= -1 then
      local macroJSFX_fxGUID = reaper.TrackFX_GetFXGUID( DATA2.tr_ptr, macroJSFX_pos ) 
      DATA2:TrackDataWrite(DATA2.tr_ptr, {MACRO_GUID=macroJSFX_fxGUID})
      TrackFX_Show( DATA2.tr_ptr, macroJSFX_pos, 0|2 ) 
     else
      MB('RS5k manager_MacroControls JSFX is missing. Make sure you installed it correctly via ReaPack.', '', 0)
    end
  end
  -----------------------------------------------------------------------  
  function DATA2:TrackData_InitFilterDrive(note_layer_t) 
    local track = note_layer_t.tr_ptr
    local reaeq_pos = TrackFX_AddByName( track, 'ReaEQ', 0, 1 )
    if reaeq_pos ~= -1 then 
      TrackFX_Show( track, reaeq_pos, 2 )
      TrackFX_SetNamedConfigParm( track, reaeq_pos, 'BANDTYPE0',3 )
      TrackFX_SetParamNormalized( track, reaeq_pos, 0, 1 )
      local GUID = reaper.TrackFX_GetFXGUID( track, reaeq_pos )
      DATA2:TrackDataWrite(track, {FX_REAEQ_GUID = GUID}) 
    end
     
    local ws_pos = TrackFX_AddByName( track, 'waveShapingDstr', 0, 1 )
    if ws_pos ~= -1 then
      TrackFX_Show( track, ws_pos, 2 )
      TrackFX_SetParamNormalized( track, ws_pos, 0, 0 )
      local GUID = reaper.TrackFX_GetFXGUID( track, ws_pos )
      DATA2:TrackDataWrite(track, {FX_WS_GUID = GUID}) 
    end
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_FilterSection(DATA)   
    local src_t = DATA2:internal_GetActiveNoteLayerTable()
    local filt_rect_h = math.floor(DATA.GUI.custom_sampler_knob_h / 3)
    local y_offs = DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_sampler_peakareah+DATA.GUI.custom_offset*3+DATA.GUI.custom_module_ctrlreadout_h*2
    local x_offs= DATA.GUI.buttons.sampler_frame.x
    DATA.GUI.buttons.sampler_spl_reaeq_togglename = { 
                        x = x_offs,
                        y=y_offs,
                        w = DATA.GUI.custom_sampler_modew,
                        h = filt_rect_h-DATA.GUI.custom_offset,
                        ignoremouse = true,
                        txt = 'Filter',
                        frame_arcborder = true,
                        frame_arcborderflags = 1,
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        frame_a =DATA.GUI.custom_framea, 
                        }
    local reaeqstate,reaeqstate_a = 'Off',0.3 if src_t.fx_reaeq_bandenabled then reaeqstate = 'On' reaeqstate_a = nil end
    DATA.GUI.buttons.sampler_spl_reaeq_toggle = { 
                        x = x_offs,
                        y= y_offs+filt_rect_h,
                        w = DATA.GUI.custom_module_ctrlreadout_h*2,
                        h = filt_rect_h-DATA.GUI.custom_offset,
                        --ignoremouse = true,
                        txt = reaeqstate,
                        txt_a = reaeqstate_a,
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        frame_a =DATA.GUI.custom_framea,
                        --state = src_t.fx_reaeq_bandenabled,
                        onmouserelease = function() 
                          if not src_t.fx_reaeq_isvalid then 
                            DATA2:TrackData_InitFilterDrive(src_t) 
                            DATA2:TrackDataRead_GetChildrens_FXParams(src_t)
                            GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                          end 
                          if not src_t.fx_reaeq_isvalid then return end -- if reaeq insertion failed
                          
                          local val = 0
                          if not src_t.fx_reaeq_bandenabled then val = 1 end
                          TrackFX_SetNamedConfigParm( src_t.tr_ptr, src_t.fx_reaeq_pos, 'BANDENABLED0', val )
                          DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  
                          GUI_MODULE_SAMPLER_Section_FilterSection(DATA)
                        end
                        }  
    DATA.GUI.buttons.sampler_spl_reaeq_bandtype = { 
                        x =x_offs,
                        y= y_offs+filt_rect_h*2,
                        w = DATA.GUI.custom_sampler_modew,
                        h = filt_rect_h,
                        frame_a =DATA.GUI.custom_framea,
                        --ignoremouse = true,
                        txt = src_t.fx_reaeq_bandtype_format,
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouserelease = function() 
                          local t = {}
                          for key in pairs(DATA2.custom_sampler_bandtypemap) do
                            t[#t+1] = { str = DATA2.custom_sampler_bandtypemap[key],
                                        func =  function() 
                                                  if not src_t.fx_reaeq_isvalid then 
                                                    DATA2:TrackData_InitFilterDrive(src_t) 
                                                    DATA2:TrackDataRead_GetChildrens_FXParams(src_t) 
                                                    GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                                                  end
                                                  if not src_t.fx_reaeq_isvalid then return end -- if reaeq insertion failed
                                                  
                                                  TrackFX_SetNamedConfigParm( src_t.tr_ptr, src_t.fx_reaeq_pos, 'BANDTYPE0', key ) 
                                                  DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  
                                                  GUI_MODULE_SAMPLER_Section_FilterSection(DATA) 
                                                end
                                      }
                          end
                          DATA:GUImenu(t)
                        end
                        }   
    x_offs = x_offs + DATA.GUI.custom_sampler_modew + DATA.GUI.custom_offset
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_fx_reaeq_cut',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_sampler_knob_h,
        
        ctrlname = 'Freq',
        ctrlval_key = 'fx_reaeq_cut',
        ctrlval_format_key = 'fx_reaeq_cut_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default = 0.95,
        
        func_app =            function(new_val) 
                                if not src_t.fx_reaeq_isvalid then 
                                  DATA2:TrackData_InitFilterDrive(src_t) 
                                  DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  
                                  GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                                end 
                                if not src_t.fx_reaeq_isvalid then return end -- if reaeq insertion failed
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.fx_reaeq_pos, 0, new_val ) 
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_FXParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.fx_reaeq_pos, 0) 
                                return new_val
                              end
       } )    

    x_offs = x_offs + DATA.GUI.custom_sampler_modew + DATA.GUI.custom_offset
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_fx_reaeq_gain',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_sampler_knob_h,
        
        ctrlname = 'Gain',
        ctrlval_key = 'fx_reaeq_gain',
        ctrlval_format_key = 'fx_reaeq_gain_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default = 0.5,
        
        func_app =            function(new_val) 
                                if not src_t.fx_reaeq_isvalid then 
                                  DATA2:TrackData_InitFilterDrive(src_t) 
                                  DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  
                                  GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                                end 
                                if not src_t.fx_reaeq_isvalid then return end -- if reaeq insertion failed
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.fx_reaeq_pos, 1, new_val ) 
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_FXParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.fx_reaeq_pos, 1) 
                                return new_val
                              end
       } )   

    x_offs = x_offs + DATA.GUI.custom_sampler_modew + DATA.GUI.custom_offset
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_fx_wa_drive',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_sampler_knob_h,
        
        ctrlname = 'Drive',
        ctrlval_key = 'fx_ws_drive',
        ctrlval_format_key = 'fx_ws_drive_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default = 0,
        
        func_app =            function(new_val) 
                                if not src_t.fx_ws_isvalid then 
                                  DATA2:TrackData_InitFilterDrive(src_t) 
                                  DATA2:TrackDataRead_GetChildrens_FXParams(src_t) 
                                  GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                                end 
                                if not src_t.fx_ws_isvalid then return end -- if reaeq insertion failed
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.fx_ws_pos, 0, new_val )
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_FXParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.fx_ws_pos, 0) 
                                return new_val
                              end
       } ) 
       
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_EnvelopeSection(DATA)   
    local src_t, note, layer = DATA2:internal_GetActiveNoteLayerTable()
    local x_offs= DATA.GUI.buttons.sampler_frame.x + (DATA.GUI.custom_sampler_modew+DATA.GUI.custom_offset) * 4
    local y_offs = DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_sampler_peakareah+DATA.GUI.custom_offset*3+DATA.GUI.custom_module_ctrlreadout_h*2
    
    local attackmax = 1 if src_t.SAMPLELEN and src_t.SAMPLELEN ~= 0 then attackmax = math.min(1,src_t.SAMPLELEN/2) end
    local ctrl_paramid = 9 if src_t.INSTR_PARAM_ATT then ctrl_paramid = src_t.INSTR_PARAM_ATT end
    local ctrlname = 'Attack' if src_t.instrument_attack_extname then ctrlname =src_t.instrument_attack_extname end
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_instrument_attack',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_sampler_knob_h,
        ctrlname = ctrlname,
        ctrlval_key = 'instrument_attack',
        ctrlval_format_key = 'instrument_attack_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default =0,
        ctrlval_max =attackmax,
        ctrlval_min =0,
        
        func_app =            function(new_val) 
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, ctrl_paramid, new_val ) 
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, ctrl_paramid) 
                                return new_val
                              end
       } ) 
       
    local x_offs= x_offs + DATA.GUI.custom_sampler_modew+DATA.GUI.custom_offset
    local decaymax = 1 if src_t.SAMPLELEN and src_t.SAMPLELEN ~= 0 then decaymax = math.min(1,src_t.SAMPLELEN/15) end
    local ctrl_paramid = 24 if src_t.INSTR_PARAM_DEC then ctrl_paramid = src_t.INSTR_PARAM_DEC end
    local ctrlname = 'Decay' if src_t.instrument_decay_extname then ctrlname =src_t.instrument_decay_extname end
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_instrument_decay',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_sampler_knob_h,
        ctrlname = ctrlname,
        ctrlval_key = 'instrument_decay',
        ctrlval_format_key = 'instrument_decay_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default =0.016010673716664,
        ctrlval_max =decaymax,
        ctrlval_min =0,
        
        func_app =            function(new_val) 
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, ctrl_paramid, new_val ) 
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, ctrl_paramid) 
                                return new_val
                              end
       } ) 

    local x_offs= x_offs + DATA.GUI.custom_sampler_modew+DATA.GUI.custom_offset
    local ctrl_paramid = 25 if src_t.INSTR_PARAM_SUS then ctrl_paramid = src_t.INSTR_PARAM_SUS end
    local ctrlname = 'Sustain' if src_t.instrument_sustain_extname then ctrlname =src_t.instrument_sustain_extname end
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_instrument_sustain',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_sampler_knob_h,
        ctrlname = ctrlname,
        ctrlval_key = 'instrument_sustain',
        ctrlval_format_key = 'instrument_sustain_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default =0.5,
        
        func_app =            function(new_val) 
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, ctrl_paramid, new_val ) 
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, ctrl_paramid) 
                                return new_val
                              end
       } )   
       
    local x_offs= x_offs + DATA.GUI.custom_sampler_modew+DATA.GUI.custom_offset
    local releasemax = 1 if src_t.SAMPLELEN and src_t.SAMPLELEN ~= 0 then releasemax = math.min(1,src_t.SAMPLELEN/2) end
    local ctrlname = 'Release' if src_t.instrument_release_extname then ctrlname =src_t.instrument_release_extname end
    local ctrl_paramid = 10 if src_t.INSTR_PARAM_REL then ctrl_paramid = src_t.INSTR_PARAM_REL end
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_instrument_release',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_sampler_modew,
        h = DATA.GUI.custom_sampler_knob_h,
        ctrlname = ctrlname,
        ctrlval_key = 'instrument_release',
        ctrlval_format_key = 'instrument_release_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default =0.0005,
        ctrlval_max =releasemax,
        ctrlval_min =0,
        
        func_app =            function(new_val) 
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, ctrl_paramid,new_val ) 
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, ctrl_paramid) 
                                return new_val
                              end
       } ) 
       
  end
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
    
    if DATA2.recentmsg_trig == true and DATA2.recentmsg_isNoteOn == true and DATA.extstate.UI_incomingnoteselectpad == 1 then 
      DATA2.PARENT_LASTACTIVENOTE = DATA2.playingnote_pitch 
      DATA2.PARENT_LASTACTIVENOTE_layer = 1 
      DATA2:TrackDataWrite(_,{master_upd=true}) 
      GUI_MODULE_PADOVERVIEW_generategrid(DATA) -- refresh pad
      GUI_MODULE_DRUMRACKPAD(DATA)  
      GUI_MODULE_DEVICE(DATA)  
      GUI_MODULE_SAMPLER(DATA)
    end
    
    
    if DATA2.FORCEONPROJCHANGE == true then DATA_RESERVED_ONPROJCHANGE(DATA) DATA2.FORCEONPROJCHANGE = nil end
  end
  
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.45) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end
  
  
  
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