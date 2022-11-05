-- @description RS5k manager
-- @version 3.0beta42
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic5000 data on group of connected tracks
-- @provides
--    mpl_RS5k_manager_MacroControls.jsfx 
--    mpl_RS5K_manager_MIDIBUS_choke.jsfx
-- @changelog
--    + Add MIDI choke JSFX
--    # fix error when not MIDI octave shift defined in REAPER.ini



--[[ 
v3.0beta41 by MPL November 05 2022
  + DrumRack: add FX button to show parent FX chain
  + Settings: option to copy files into project directory
  # DrumRack use octave offset from REAPER preferences
  + Setting: add option to use custom note names
  
v3.0beta40 by MPL November 05 2022
  + Add MIDI/OSC learn section
  + Sampler: add tune cents/semitones/octave buttons
  
v3.0beta37 by MPL November 03 2022
  + Device: add Fx button (show FX chain for device track)
  + Sampler: add Fx button (show FX chain for sampler track)
  + Settings: allow to set MIDI bus default input channel
  # keep layer ID between triggering pads / incoming notes
  + Tabs: rightclick on tab toggle only this tab and all tabs
  
v3.0beta36 by MPL November 03 2022
  + fix typo
  
v3.0beta35 by MPL November 03 2022
  + Undo copy/move pads
  + Undo remove note/layers
  + Device: allow to remove layers
  + Settings: add option to rename track
  + Improve incoming notes catching
  + Small UI tweaks
  
v3.0beta34 by MPL November 03 2022
  # DrumRack: moving pad to existed swap them
  + DrumRack: indicate dragging pad
  # Sampler: swap prev/next sample buttons
  # Sampler: fix EQ enabled toggle
  # Sampler: fix distortion validation
  - Sampler: for now disable smart tweak for tune control
  + Settings: allow to change default tabs
  # Defaults: remove device tab from defaults
  # GUI: add module separators
  + Database map: add database map section
  + Database map: load/save database from parent track chunk
  + Database map: allow to store specific pad name when using database
  + Database map: pressing "new kit" generate new kit from mapped databases
  + Database map: allow to save kit globally or per parent track
  
  
v3.0beta33 by MPL  October 28 2022
  + Sampler: add sample search actions
  + Macro: add link section
  + Macro: add offset link
  + Macro: add scale link
  + Macro: add disable link button
  # for now reduce macro knobs count to 8 in the GUI
  
v3.0beta30 by MPL October 26 2022
  # NO BACKWARD COMPATIBILITY for 3.0beta1-25 versions
  # Internal code clean up, change names of external states
  # GUI: use single control form for readouts/knobs
  # GUI: tweak area is whole frame, not only value field
  # When drop to replace sample, also rename track and note names
  # fix and properly handle device / regular child states
  + 3rd party instrument: cache param IDs
  + DrumRack: left drag move/replace pads content (single sample/devices)
  + DrumRack: ctrl drag copy pad content (only non-device is available)
  + DrumRack: draw frame / names as track colors
  # DrumRack: remove ME button, use MediaExp button for show active note/layer sampler in MediaExplorer
  + Sampler/Tune: quantize values, use Ctrl+Drag for fine tune
  + Sampler/Tune: obey fraction/quantized difference on regular drag
  + Add help tips at modules
  
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
    DATA.extstate.version = '3.0beta42'
    DATA.extstate.extstatesection = 'MPL_RS5K manager'
    DATA.extstate.mb_title = 'RS5K manager'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  700,
                          wind_h =  400,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          -- rs5k 
                          CONF_onadd_float = 0,
                          CONF_onadd_obeynoteoff = 1,
                          CONF_onadd_customtemplate = '',
                          CONF_onadd_renametrack = 1,
                          CONF_onadd_copytoprojectpath = 0,
                          
                          -- midi bus
                          CONF_midiinput = 63, -- 63 all 62 midi kb
                          CONF_midichannel = 0, -- 0 == all channels
                          
                          -- drum rack
                          
                          -- Actions
                          CONF_cropthreshold = -60, -- db
                          
                          -- db
                          CONF_database_map_default = '',
                          CONF_database_map1 = '', 
                          CONF_database_map2 = '',
                          CONF_database_map3 = '',
                          CONF_database_map4 = '',
                          
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
                          UI_defaulttabsflags = 1|4|8, --1=drumrack   2=device  4=sampler 8=padview 16=macro 32=database 64=midi map 128=children chain
                          UI_keyformat_mode = 0 ,
                          
                          
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
    DATA2:internal_parseREAPER_Settings()        
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets()  
    --DATA2:Database_Load(DATA.extstate.CONF_database_base64) 
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
  -----------------------------------------------------------------------------  
  function DATA2:internal_parseREAPER_Settings()
    DATA2.REAPERini = VF_LIP_load( reaper.get_ini_file())
  end
  --------------------------------------------------------------------- 
  function DATA2:Actions_Help(page)
  
  
  
if page == 0 then  -- drumrack
MB(
[[
Actions panel:
  Explore = show current note sample in browser

Controls:
  M = mute
  S = solo
  > = play
   
Pads:
  Click on pad name = set current note active
  Drag to other pad = Move/Replace pad content
  Ctrl+drag to other pad = Copy pad (unavailable for existing pads, not supposed to work for devices)
]]
,'RS5k manager: drumrack',0)
    
    
    
    
elseif page == 1 then  -- device
MB(
[[
Actions panel:
  FX = show FX chain for current device
  
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
      
       
      
elseif page == 2 then  -- database
MB(
[[
Actions panel:
  New kit = Set samples for pads based on defined databases per sample
Database map parameters:
  Pad name: overwrites pad name
  Lock = prevent pad from replacing sample
]]
,'RS5k manager: database',0)       
      
      
      
      
      
      
elseif page == 3 then  -- pad overview
MB(
[[

]]
,'RS5k manager: overview',0)   
      
      
elseif page == 4 then  --  sampler
MB(
[[
Actions panel:
  Actions button opens list of available actions
  FX: show RS5k instance in FX chain
  
Peaks area:
  Loop: set loop ON if available
  1-shot: set loop OFF if available
  Prev spl: list previous sample in current sample directory
  Next spl: list next sample in current sample directory
  Rand spl: list random sample in current sample directory
  
Sampler readouts:
  Various readouts if available. rightclick for manually enter value, doubleclick to reset, ctrl for fine tweak
  
Sampler knobs:
  Various knobs if available. rightclick for manually enter value, doubleclick to reset, ctrl for fine tweak
  Filter Cut/Q: add ReaEQ after Rs5k instance and link controls to it
  Drive: add Waveshaper JSFX after Rs5k instance and link control to it
  
]]
,'RS5k manager: sampler',0)   
            
      
      
elseif page == 5 then  -- midi lear
MB(
[[
Actions panel:
  Learn: perform action 'FX: Set MIDI learn for last touched FX parameter'
]]
,'RS5k manager: learn',0)         
      
      
      
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
    CHOKE_GUID
    
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
          'PARENT_MACROCNT '..DATA2.PARENT_MACROCNT..'\n'.. 
          'PARENT_LASTACTIVEMACRO '..DATA2.PARENT_LASTACTIVEMACRO..'\n'..
          'PARENT_DATABASEMAP ' ..DATA2:Database_Save()
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN', extstr, true)  
        return 
      end
      if t.MACRO_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_MACRO_GUID', t.MACRO_GUID, true)  end
      if t.CHOKE_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHOKE_GUID', t.CHOKE_GUID, true)  end
      
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
  function DATA2:TrackDataRead_GetParent_ParseExt()
    if not (DATA2.tr_ptr and ValidatePtr2(0,DATA2.tr_ptr,'MediaTrack*') )then return end
    local track = DATA2.tr_ptr
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
    local GUID = reaper.GetTrackGUID( track )
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
    note_layer_t.TR_GUID = GUID
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
    DATA2.MIDIbus.ptr = new_tr
    DATA2:TrackDataWrite(new_tr, {set_currentparentforchild = true})  
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', 'MIDI bus', 1 )
    SetMediaTrackInfo_Value( new_tr, 'I_RECMON', 1 )
    SetMediaTrackInfo_Value( new_tr, 'I_RECARM', 1 )
    SetMediaTrackInfo_Value( new_tr, 'I_RECMODE', 0 ) -- record MIDI out
    local channel,physical_input = DATA.extstate.CONF_midichannel, DATA.extstate.CONF_midiinput
    SetMediaTrackInfo_Value( new_tr, 'I_RECINPUT', 4096 + channel + (physical_input<<5)) -- set input to all MIDI
    DATA2:TrackDataWrite(new_tr, {setmidibus=true})  
    DATA2:TrackDataRead()
    -- 
    local cnt = 0
    for key in pairs(DATA2.notes) do cnt = cnt+ 1 end
    if cnt == 0 then SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH',-1 ) end
    
    DATA2:TrackData_InitChoke()
    
  end
  -----------------------------------------------------------------------  
  function DATA2:TrackData_InitChoke()
    if not DATA2.MIDIbus.ptr then return end
    if DATA2.Choke.isvalid == true then return end 
    local fxname = 'mpl_RS5K_manager_MIDIBUS_choke.jsfx' 
    local chokeJSFX_pos =  TrackFX_AddByName( DATA2.MIDIbus.ptr, fxname, false, 0 )
    if chokeJSFX_pos == -1 then
      chokeJSFX_pos =  TrackFX_AddByName( DATA2.MIDIbus.ptr, fxname, false, -1000 ) 
      local chokeJSFX_fxGUID = reaper.TrackFX_GetFXGUID( DATA2.MIDIbus.ptr, chokeJSFX_pos ) 
      DATA2:TrackDataWrite(DATA2.MIDIbus.ptr, {CHOKE_GUID=chokeJSFX_fxGUID}) 
      TrackFX_Show( DATA2.MIDIbus.ptr, chokeJSFX_pos, 0|2 )
      --for i = 1, 16 do TrackFX_SetParamNormalized( DATA2.tr_ptr, chokeJSFX_pos, 33+i, i/1024 ) end -- ini source gmem IDs
    end
    if chokeJSFX_pos == -1 then MB('mpl_RS5K_manager_MIDIBUS_choke JSFX is missing. Make sure you installed it correctly via ReaPack.', '', 0) end
    return chokeJSFX_pos
    
  end
  ---------------------------------------------------------------------
  function DATA2:TrackDataRead_IsChildAppendsToCurrentParent(track)   
    local ret, parGUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', '', false)
    if DATA2.tr_GUID and parGUID == DATA2.tr_GUID then ret = true end 
    return ret, parGUID
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetParent_MacroLinks(note_layer_t)
    if not note_layer_t then return end
    if not note_layer_t.tr_ptr then return end
    for fxid = 1,  TrackFX_GetCount( note_layer_t.tr_ptr ) do
      if fxid ~= note_layer_t.macro_pos then
        for paramnumber = 0, TrackFX_GetNumParams( note_layer_t.tr_ptr, fxid-1 )-1 do
          local isactive = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.active')})[2] isactive = tonumber(isactive) 
          if isactive and isactive ==1 then
            local src_fx = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.effect')})[2] src_fx = tonumber(src_fx) 
            local src_param = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.param')})[2] src_param = tonumber(src_param) 
            if src_fx and src_fx == note_layer_t.macro_pos then
              local retval, pname = reaper.TrackFX_GetParamName( note_layer_t.tr_ptr, fxid-1,paramnumber)
              local macroID = src_param  
              if DATA2.Macro.sliders[macroID] then 
                if not DATA2.Macro.sliders[macroID].links then DATA2.Macro.sliders[macroID].links = {} end
                local linkID = #DATA2.Macro.sliders[macroID].links+1
                local plink_offset = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.offset')})[2] plink_offset = tonumber(plink_offset) 
                local plink_scale = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.scale')})[2] plink_scale = tonumber(plink_scale) 
                local plink_offset_format = math.floor(plink_offset*100)..'%'
                local plink_scale_format = math.floor(plink_scale*100)..'%'
                DATA2.Macro.sliders[macroID].links[linkID] = {
                    param_name = pname,
                    plink_offset = plink_offset,
                    plink_offset_format = plink_offset_format,
                    plink_scale = plink_scale,
                    plink_scale_format = plink_scale_format,
                    src_t = note_layer_t,
                    fx_dest = fxid-1,
                    param_dest = paramnumber,
                  }
                  
              end 
            end
          end
        end
      end
    end 
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetChildrens_ExtState(track) 
    if DATA2:TrackDataRead_IsChildAppendsToCurrentParent(track) ~= true  then return end
    
    -- handle MIDI bus --------------------------
      local _, isMIDIbus = GetSetMediaTrackInfo_String      ( track, 'P_EXT:MPLRS5KMAN_MIDIBUS', 0, false) isMIDIbus = (tonumber(isMIDIbus) or 0)==1   
      local _, CHOKE_GUID = GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_CHOKE_GUID', 0, false) if CHOKE_GUID == '' then CHOKE_GUID = nil end 
      local  ret, tr, choke_pos
      if CHOKE_GUID then ret, tr, choke_pos = VF_GetFXByGUID(CHOKE_GUID:gsub('[%{%}]',''),track) end
      if not choke_pos then CHOKE_GUID = nil  end
      if isMIDIbus then  DATA2.MIDIbus = { ptr = track, 
                                            ID = CSurf_TrackToID( track, false ),
                                            CHOKE_GUID = CHOKE_GUID,
                                            choke_pos = choke_pos} return  end  
      
      
      
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
    
    local _, MACRO_GUID = GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_MACRO_GUID', 0, false) if MACRO_GUID == '' then MACRO_GUID = nil end 
    local  ret, tr, macro_pos, macro_links
    if MACRO_GUID then ret, tr, macro_pos = VF_GetFXByGUID(MACRO_GUID:gsub('[%{%}]',''),track) end
    if not macro_pos then MACRO_GUID = nil  end
    
    
    if FX_WS_GUID then 
      local ret, tr, wspos = VF_GetFXByGUID(FX_WS_GUID:gsub('[%{%}]',''),track) 
      if not wspos then FX_WS_GUID=nil end
    end
    
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
                                          noteID = note,
                                          layerID = layer,
                                          MACRO_GUID = MACRO_GUID,
                                          macro_pos = macro_pos,
                                          }
      end
      
      if TYPE_DEVICE then 
        DATA2.notes[note].TYPE_DEVICE = TYPE_DEVICE
        DATA2.notes[note].tr_ptr = track
        DATA2.notes[note].tr_GUID = trGUID
        DATA2.notes[note].devicetr_ID = CSurf_TrackToID(track, false ) 
        DATA2.notes[note].MACRO_GUID = MACRO_GUID
        DATA2.notes[note].noteID = note
        DATA2.notes[note].nmacro_pos =macro_pos
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
      note_layer_t.instrument_maxvoicesID = 8
      note_layer_t.instrument_maxvoices = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_maxvoicesID ) 
      note_layer_t.instrument_maxvoices_format = math.floor(note_layer_t.instrument_maxvoices*64)
      note_layer_t.instrument_tuneID = 15
      note_layer_t.instrument_tune = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_tuneID ) 
      note_layer_t.instrument_tune_format = ({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_tuneID )})[2]..'st'
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
      note_layer_t.instrument_volID = note_layer_t.INSTR_PARAM_VOL
      note_layer_t.instrument_tuneID = note_layer_t.INSTR_PARAM_TUNE
      note_layer_t.instrument_attackID = note_layer_t.INSTR_PARAM_ATT
      note_layer_t.instrument_decayID = note_layer_t.INSTR_PARAM_DEC
      note_layer_t.instrument_sustainID = note_layer_t.INSTR_PARAM_SUS
      note_layer_t.instrument_releaseID = note_layer_t.INSTR_PARAM_REL
    end
    --[[
    for key in pairs(note_layer_t) do
      if key:match('instrument_(.-)ID') and type(note_layer_t[key]) ~= 'boolean' then
        local key_src = key:match('(instrument_.-)ID')
        local retval1, learn_midi1 = reaper.TrackFX_GetNamedConfigParm(track, instrument_pos, 'param.'..note_layer_t[key]..'.learn.midi1')
        if retval1 then note_layer_t[key_src..'_learn_midi1'] = tonumber(learn_midi1) or nil end
        local retval2, learn_midi2 = reaper.TrackFX_GetNamedConfigParm(track, instrument_pos, 'param.'..note_layer_t[key]..'.learn.midi2')
        if retval2 then note_layer_t[key_src..'_learn_midi2'] = tonumber(learn_midi2) or nil end
        local retval3, learn_osc = reaper.TrackFX_GetNamedConfigParm(track, instrument_pos, 'param.'..note_layer_t[key]..'.learn.osc')
        if retval3 then note_layer_t[key_src..'_learn_osc'] = learn_osc end
        note_layer_t[key_src..'_learn_exist'] = retval1 or retval2 or retval3
      end
    end]]
    
    --[[param.X.learn.[midi1,midi2,osc] : first two bytes of MIDI message, or OSC string if set
    param.X.learn.mode : absolution/relative mode flag (0: Absolute, 1: 127=-1,1=+1, 2: 63=-1, 65=+1, 3: 65=-1, 1=+1, 4: toggle if nonzero)
    param.X.learn.flags : &1=selected track only, &2=soft takeover, &4=focused FX only, &8=LFO retrigger, &16=visible FX only]]
  end 
  --------------------------------------------------------------------- 
  function DATA2:TrackDataRead_GetParent(track)
    local retval, trname = reaper.GetTrackName( track )
    local GUID = reaper.GetTrackGUID( track)  
    DATA2.tr_valid = true
    DATA2.tr_isparent = true
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
    DATA2.PARENT_TABSTATEFLAGS=DATA.extstate.UI_defaulttabsflags
    DATA2.PARENT_LASTACTIVENOTE = -1
    DATA2.PARENT_LASTACTIVEMACRO = -1
    DATA2.PARENT_DATABASEMAP = ''
    
    DATA2.Macro = {sliders = {}}   
    DATA2.tr_GUIDlast = DATA2.tr_GUID 
    
  end
  --------------------------------------------------------------------- 
  function DATA2:TrackDataRead_GetParent_Macro(donotupdatelinks)
    if not (DATA2.tr_ptr and ValidatePtr2(0,DATA2.tr_ptr,'MediaTrack*') )then return end
    DATA2.Macro.isvalid = false
    local _, MACRO_GUID = GetSetMediaTrackInfo_String ( DATA2.tr_ptr, 'P_EXT:MPLRS5KMAN_MACRO_GUID', 0, false) if MACRO_GUID == '' then MACRO_GUID = nil end 
    if MACRO_GUID then 
      local ret,tr, macro_pos = VF_GetFXByGUID(MACRO_GUID, DATA2.tr_ptr)
      if ret and macro_pos and macro_pos ~= -1 then   
        DATA2.Macro.isvalid = true 
        DATA2.Macro.macro_pos = macro_pos 
        DATA2.Macro.MACRO_GUID = MACRO_GUID 
        for i = 1, 16 do
          if not DATA2.Macro.sliders[i] then DATA2.Macro.sliders[i] = {} end
          local param_val = TrackFX_GetParamNormalized( DATA2.tr_ptr, macro_pos, i )
          --[[
          local retval1, learn_midi1 = reaper.TrackFX_GetNamedConfigParm(DATA2.tr_ptr, macro_pos, 'param.'..i..'.learn.midi1')
          if retval1 then DATA2.Macro.sliders[i].learn_midi1 = tonumber(learn_midi1) or nil end
          local retval2, learn_midi2 = reaper.TrackFX_GetNamedConfigParm(DATA2.tr_ptr, macro_pos, 'param.'..i..'.learn.midi2')
          if retval2 then DATA2.Macro.sliders[i].learn_midi2 = tonumber(learn_midi2) or nil end
          local retval3, learn_osc = reaper.TrackFX_GetNamedConfigParm(DATA2.tr_ptr, macro_pos, 'param.'..i..'.learn.osc')
          if retval3 then DATA2.Macro.sliders[i].learn_osc = learn_osc end
          DATA2.Macro.sliders[i].learn_exist = retval1 or retval2 or retval3]]
          --[[param.X.learn.[midi1,midi2,osc] : first two bytes of MIDI message, or OSC string if set
          param.X.learn.mode : absolution/relative mode flag (0: Absolute, 1: 127=-1,1=+1, 2: 63=-1, 65=+1, 3: 65=-1, 1=+1, 4: toggle if nonzero)
          param.X.learn.flags : &1=selected track only, &2=soft takeover, &4=focused FX only, &8=LFO retrigger, &16=visible FX only]]
          
          DATA2.Macro.sliders[i].macroval = param_val
          DATA2.Macro.sliders[i].macroval_format = math.floor(param_val*1000/10)..'%'
          DATA2.Macro.sliders[i].tr_ptr = DATA2.tr_ptr
          DATA2.Macro.sliders[i].macro_pos = macro_pos
        end
      end
    end 
    
    -- get links
    if not donotupdatelinks then
      for macroID = 1, 16 do if DATA2.Macro.sliders[macroID] then DATA2.Macro.sliders[macroID].links = nil end end       -- clear links
      for note in pairs(DATA2.notes) do
        DATA2:TrackDataRead_GetParent_MacroLinks(DATA2.notes[note])
        if DATA2.notes[note] and DATA2.notes[note].layers then 
          for layer in pairs(DATA2.notes[note].layers) do
            DATA2:TrackDataRead_GetParent_MacroLinks(DATA2.notes[note].layers[layer])
          end
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetMIDIOSC_bindings()
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&64==0) then return end -- do not catch data if midi tab not active 
    if DATA2.MIDIOSC_lastcall and os.clock() - DATA2.MIDIOSC_lastcall < 1 then return end -- minimum update rate is 1sec since it is a big loop
    DATA2.MIDIOSC = {map = {}}
    DATA2.MIDIOSC_lastcall = os.clock()
    
    
    DATA2:TrackDataRead_GetMIDIOSC_bindings_sub(DATA2) -- parent
    for note in pairs(DATA2.notes) do
      if DATA2.notes[note].TYPE_DEVICE == true then DATA2:TrackDataRead_GetMIDIOSC_bindings_sub(DATA2.notes[note]) end
      if DATA2.notes[note].layers then for layer in pairs(DATA2.notes[note].layers) do DATA2:TrackDataRead_GetMIDIOSC_bindings_sub(DATA2.notes[note].layers[layer]) end end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:TrackDataRead_GetMIDIOSC_bindings_sub(src_t)
    if src_t then track = src_t.tr_ptr end
    if not track and ValidatePtr2(0,track,'MediaTrack*')then return end
    
    for fx = 0,  TrackFX_GetCount( track )-1 do
      local pcount = reaper.TrackFX_GetNumParams( track, fx )
      for param = 0,  pcount-1 do
        local retval1, learn_midi1 = reaper.TrackFX_GetNamedConfigParm(track, fx, 'param.'..param..'.learn.midi1')
        local retval2, learn_midi2 = reaper.TrackFX_GetNamedConfigParm(track, fx, 'param.'..param..'.learn.midi2') 
        local retval3, learn_osc = reaper.TrackFX_GetNamedConfigParm(track, fx, 'param.'..param..'.learn.osc') 
        
        local validOSC = retval3 and learn_osc and learn_osc~= ''
        local validMIDI = retval1 and retval2 and ((learn_midi1>>4)& 0x0F ) ~= 0
         
        if validOSC or validMIDI then
          local retval, fxname = reaper.TrackFX_GetFXName( track, fx )
          fxname = VF_ReduceFXname(fxname)
          fxname = fxname:gsub('\\','/')
          if fxname:match('%/(.*)') then fxname = fxname:match('%/(.*)') end
          if fxname:match('MacroControls') then fxname = '[Macro]' end
          local retval, paramname = reaper.TrackFX_GetParamName( track, fx, param )
          local mapID = #DATA2.MIDIOSC.map+1
          DATA2.MIDIOSC.map[mapID] = {tr_ptr = track,
                                      fx= fx,
                                      fxname= fxname,
                                      paramname= paramname,
                                      param = param,
                                      format_oscname = '[empty]',
                                      format_midiname = '[empty]',
                                      }
          -- handle OSC                            
          if validOSC then DATA2.MIDIOSC.map[mapID].format_oscname = learn_osc end 
          -- handle MIDI                           
          if validMIDI then
            local msgtypes_t = {[11]='CC'}
            local msgtype_int = (learn_midi1>>4)& 0x0F
            local msgtype = msgtype_int
            if msgtypes_t[msgtype_int] then msgtype = msgtypes_t[msgtype_int] end
            DATA2.MIDIOSC.map[mapID].format_midiname = 
            'Ch '..((learn_midi1 & 0x0F)+1 )..' '..--MIDI 
            msgtype..' '..learn_midi2
          end
          format_ctrlnameID = ''
          if src_t.tr_isparent then format_ctrlnameID = '[Parent]' end
          if src_t.TYPE_DEVICE == true then format_ctrlnameID = '[D]'..src_t.noteID  end
          if not src_t.TYPE_DEVICE and src_t.layerID then format_ctrlnameID = 'N'..src_t.noteID..' L'..src_t.layerID end
          DATA2.MIDIOSC.map[mapID].format_ctrlnameID = format_ctrlnameID
        end
         --[[   if src_t and src_t.name then 
              if  then
                format_ctrlname = '[D] '..src_t.name  -- device / note
               else
                format_ctrlname = '[N]'..src_t.noteID..' [L]'..src_t.layerID..' '..src_t.name
              end
             elseif src_t.tr_isparent then
              format_ctrlname = '[Parent]'
            end
            
            local format_midiname = ''
            if DATA2.MIDIOSC.map[mapID].format_channel then format_midiname = 'MIDI Ch '..(DATA2.MIDIOSC.map[mapID].format_channel) end
            
            if msgtypes[DATA2.MIDIOSC.map[mapID].format_msgtype_int] then  end
            
            DATA2.MIDIOSC.map[mapID].format_ctrlname = format_ctrlname
            DATA2.MIDIOSC.map[mapID].format_midiname = format_midiname
          end
          ]]
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
    DATA2:TrackDataRead_GetParent_ParseExt()
    DATA2:TrackDataRead_GetParent_Macro()
    DATA2:Database_Load() 
    DATA2:TrackDataRead_GetMIDIOSC_bindings()
  end
  ---------------------------------------------------------------------  
  function DATA2:Database_ParseREAPER_DB()   
    local reaperini = get_ini_file()
    local backend = VF_LIP_load(reaperini)
    local exp_section = backend.reaper_explorer
    if not exp_section then return end 
    local reaperDB = {}
    for key in pairs(exp_section) do
      if key:match('Shortcut') then 
        if tostring(exp_section[key]) and tostring(exp_section[key]):lower():match('reaperfilelist') then 
          local db_key = key:gsub('Shortcut','ShortcutT')
          if exp_section[db_key] then 
            reaperDB[exp_section[db_key]] = exp_section[key]
          end
        end
      end
    end
    return reaperDB
  end
  ---------------------------------------------------------------------  
  function DATA2:Database_Cache()
    for note in pairs(DATA2.database_map.map)  do
      local list_fp = DATA2.database_map.map[note].dbflist
      if list_fp then samples = DATA2:Actions_Pad_InitSamplesFromDB_ParseList(list_fp)
        DATA2.database_map.map[note].samples = samples
      end
    end
    DATA2.database_map.cached = true
  end 
  ---------------------------------------------------------------------  
  function DATA2:Database_Load(parseonly)
    if not parseonly then DATA2.database_map = {} end
    
    local content_b64 = DATA2.PARENT_DATABASEMAP
    if parseonly then content_b64 = parseonly end
    if not content_b64 then return end 
    local content = VF_decBase64(content_b64)
    if content == '' then 
      if DATA.extstate.CONF_database_map_default == '' then return else content = VF_decBase64(DATA.extstate.CONF_database_map_default) end
      if content == '' then return end 
    end
    
    -- parse map
    local map = {}
    local dbname = 'Untitled'
    for line in content:gmatch('[^\r\n]+') do 
      if line:match('NOTE(%d+)') then 
        local note = line:match('NOTE(%d+)')
        if note then note =  tonumber(note) end
        if note then
          local params = {}
          for param in line:gmatch('%<.-%>.-%<%/.-%>') do 
            local key = param:match('%<(.-)%>')
            local val = param:match('%<.-%>(.-)%<%/.-%>')
            params[key] = tonumber(val ) or val
          end
          map[note] = params
        end
      end
      
      if line:match('DBNAME (.*)') then dbname = line:match('DBNAME (.*)') end
    end
    local t = {valid = true, map=map, dbname = dbname, parenttrGUID = DATA2.tr_GUID}
    if not parseonly then DATA2.database_map = t  end
    if parseonly then return t end
  end
  ---------------------------------------------------------------------  
  function DATA2:Database_Save()  
    if not (DATA2.database_map and DATA2.database_map.valid) then return '' end 
    local s = 'DBNAME '..DATA2.database_map.dbname..'\n'
    if not DATA2.database_map.map then return '' end
    for note in pairs(DATA2.database_map.map) do
      s = s..'NOTE'..note
      for param in pairs(DATA2.database_map.map[note]) do 
        local tp =  type(DATA2.database_map.map[note][param]) 
        if tp == 'string' or tp == 'number' then 
          s = s ..' <'..param..'>'..DATA2.database_map.map[note][param]..'</'..param..'>' 
        end
      end
      s = s..'\n'
    end
    return VF_encBase64(s)
  end
  ---------------------------------------------------------------------  
  function DATA_RESERVED_ONPROJCHANGE(DATA)
    DATA2.tr_valid = false
    if DATA.GUI.buttons.info then DATA.GUI.buttons.info.txt = '[no data]' end
    local track = GetSelectedTrack(0,0)
    DATA2:TrackDataRead(track)
    
    -- visual refresh
      for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
      
      if DATA2.ONPARAMDRAG ~= true then 
        --[[GUI_MODULE_TABS(DATA)  
        GUI_MODULE_PADOVERVIEW(DATA)
        GUI_MODULE_DRUMRACK(DATA)
        GUI_MODULE_DEVICE(DATA)  
        GUI_MODULE_MACRO(DATA)    
        GUI_MODULE_SAMPLER(DATA)]]
        GUI_RESERVED_initmacroXoffs(DATA)
        GUI_RESERVED_init_tabs(DATA)
      end
    
    if not DATA.GUI.layers_refresh  then DATA.GUI.layers_refresh = {} end
    DATA.GUI.layers_refresh[2]=true  
    
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
    local y_offs = DATA.GUI.custom_infoh
    
    for i = 1, #DATA.GUI.custom_tabs do
      local byte = DATA.GUI.custom_tabs[i].byte
      local keyname = DATA.GUI.custom_tabs[i].keyname
      local str = DATA.GUI.custom_tabs[i].str 
      local txt_a_unabled,txt_a = 0.25
      if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&byte==0 then txt_a = txt_a_unabled end
      
      DATA.GUI.buttons['showhide_'..keyname] = { x=0,
                            y=y_offs ,
                            w=DATA.GUI.custom_tab_w,-- - DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_tab_h-1,
                            txt = str,
                            txt_a = txt_a,
                            txt_fontsz=DATA.GUI.custom_tabnames_txtsz,
                            frame_a = frame_a,
                            frame_asel = frame_asel,
                            frame_col = frame_col,
                            onmouseclick = function()
                              if DATA2.PARENT_TABSTATEFLAGS then 
                                DATA2.PARENT_TABSTATEFLAGS = DATA2.PARENT_TABSTATEFLAGS ~ byte
                                if byte == 16 then if DATA2.PARENT_TABSTATEFLAGS&byte==byte then DATA2:TrackData_InitMacro() end end
                                if byte == 64 then if DATA2.PARENT_TABSTATEFLAGS&byte==byte then DATA2:TrackDataRead_GetMIDIOSC_bindings() end end
                                DATA2:TrackDataWrite(_, {master_upd=true})
                                DATA.UPD.onGUIinit = true
                              end
                            end,
                            onmouseclickR = function()
                              if DATA2.PARENT_TABSTATEFLAGS then 
                                if DATA2.PARENT_TABSTATEFLAGS&byte==byte and DATA2.PARENT_TABSTATEFLAGS~= byte then -- tab is on but not only this tab
                                  DATA2.PARENT_TABSTATEFLAGS = byte -- set to only this tab
                                 elseif DATA2.PARENT_TABSTATEFLAGS == byte then
                                  DATA2.PARENT_TABSTATEFLAGS = DATA.extstate.UI_defaulttabsflags-- -1
                                 elseif DATA2.PARENT_TABSTATEFLAGS ~= byte then
                                  DATA2.PARENT_TABSTATEFLAGS = byte -- set to only this tab
                                end
                                if byte == 16 then if DATA2.PARENT_TABSTATEFLAGS&byte==byte then DATA2:TrackData_InitMacro() end end
                                if byte == 64 then if DATA2.PARENT_TABSTATEFLAGS&byte==byte then DATA2:TrackDataRead_GetMIDIOSC_bindings() end end
                                DATA2:TrackDataWrite(_, {master_upd=true})
                                DATA.UPD.onGUIinit = true
                              end
                            end,
                            } 
      y_offs = y_offs + DATA.GUI.custom_tab_h
                            
    end
                         
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_initmacroXoffs(DATA)
    -- modules offs
      local validnote = DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE~=-1 and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE]
      DATA.GUI.custom_moduleseparatorw = 7*DATA.GUI.custom_Yrelation  
      local mod_xoffs = DATA.GUI.custom_module_startoffsx--+DATA.GUI.custom_moduleseparatorw  -- --1=drumrack   2=device  4=sampler 8=padview 16=macro 32=database
      
      DATA.GUI.custom_module_xoffs_macro = mod_xoffs--+DATA.GUI.custom_moduleseparatorw  
      if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==16 then mod_xoffs = mod_xoffs + DATA.GUI.custom_offset*2 +  DATA.GUI.custom_macroW +DATA.GUI.custom_moduleseparatorw end -- macro
      
      DATA.GUI.custom_module_xoffs_midi = mod_xoffs--+DATA.GUI.custom_moduleseparatorw  
      if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&64==64 then mod_xoffs = mod_xoffs + DATA.GUI.custom_offset*2 +  DATA.GUI.custom_midiW +DATA.GUI.custom_moduleseparatorw end -- midi
      
      DATA.GUI.custom_module_xoffs_padoverview = mod_xoffs  
      if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&8==8 then mod_xoffs = mod_xoffs +  DATA.GUI.custom_padgridw +DATA.GUI.custom_moduleseparatorw + DATA.GUI.custom_offset*2 end -- pad view 
      
      DATA.GUI.custom_module_xoffs_drumrack = mod_xoffs
      if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&1==1 then mod_xoffs = mod_xoffs + DATA.GUI.custom_drrack_sideW + DATA.GUI.custom_offset*2 +DATA.GUI.custom_moduleseparatorw end -- drrack 
      
      DATA.GUI.custom_module_xoffs_database = mod_xoffs
      if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&32==32 then mod_xoffs = mod_xoffs + DATA.GUI.custom_offset*2+  DATA.GUI.custom_databasew +DATA.GUI.custom_moduleseparatorw end -- database
      
      DATA.GUI.custom_module_xoffs_childchain = mod_xoffs
      if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&128==128 then mod_xoffs = mod_xoffs + DATA.GUI.custom_offset*2+  DATA.GUI.custom_childchainw +DATA.GUI.custom_moduleseparatorw end -- childchain
      
      
      DATA.GUI.custom_module_xoffs_device = mod_xoffs
      if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&2==2 and validnote then mod_xoffs = mod_xoffs + DATA.GUI.custom_devicew + DATA.GUI.custom_offset*2 +DATA.GUI.custom_moduleseparatorw end -- device
      
      DATA.GUI.custom_module_xoffs_sampler = mod_xoffs
      
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init(DATA)
    -- get globals
      local gfx_h = math.floor(gfx.h/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
      local gfx_w = math.floor(gfx.w/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
    --DATA.GUI.default_scale = 1
      
    -- init main stuff
      DATA.GUI.custom_Yrelation = math.max(gfx_h/300, 0.5) -- global W
      DATA.GUI.custom_offset =  math.floor(3 * DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_infoh = math.floor(gfx_h*0.1)
      DATA.GUI.custom_moduleH = gfx_h - DATA.GUI.custom_infoh-DATA.GUI.custom_offset -- global H
      DATA.GUI.custom_moduleW = math.floor(DATA.GUI.custom_moduleH*1.5) -- global W 
      DATA.GUI.custom_knob_button_w = math.floor(DATA.GUI.custom_moduleH * 0.2) 
      DATA.GUI.custom_separator_w = math.floor(10*DATA.GUI.custom_Yrelation)
      
      DATA.GUI.custom_framea = 0.1 -- greyed drum rack pads
      DATA.GUI.custom_backcol2 = '#f3f6f4' -- grey back  -- device selection
      DATA.GUI.custom_backfill2 = 0.1-- device selection
      
    -- settings / tabs
      local txtdb = 'Database map' if DATA2.database_map and DATA2.database_map.valid == true then txtdb = txtdb..'\n[Active]' end
      DATA.GUI.custom_tabs = {
        {keyname = 'macroglob',byte = 16,str = 'Macro'},
        {keyname = 'midiosclearn',byte = 64,str = 'MIDI/OSC'},
        {keyname = 'padoverview',byte = 8,str = 'Pad overview'},
        {keyname = 'drrack',byte = 1,str = 'Drum Rack'},
        {keyname = 'dbmap',byte = 32,str = txtdb},
        {keyname = 'childchain',byte = 128,str = 'Children chain'},
        {keyname = 'device',byte = 2,str = 'Device'},
        {keyname = 'sampler',byte = 4,str = 'Sampler'},
      
      }
      DATA.GUI.custom_tab_w = math.floor(DATA.GUI.custom_moduleW*0.25)
      DATA.GUI.custom_tab_h = (gfx_h - DATA.GUI.custom_infoh)/#DATA.GUI.custom_tabs
      
    -- modules
      DATA.GUI.custom_module_startoffsx = DATA.GUI.custom_tab_w + DATA.GUI.custom_offset -- first mod offset
      DATA.GUI.custom_module_ctrlreadout_h = math.floor(DATA.GUI.custom_moduleH * 0.1) 
      DATA.GUI.custom_tabnames_txtsz = 15*DATA.GUI.custom_Yrelation--*DATA.GUI.default_scale
      
    -- macro 
      DATA.GUI.custom_macroY = DATA.GUI.custom_infoh--+ DATA.GUI.custom_offset
      DATA.GUI.custom_macroH = DATA.GUI.custom_moduleH--DATA.GUI.custom_offset
      DATA.GUI.custom_macro_knobH = math.floor(DATA.GUI.custom_macroH)
      DATA.GUI.custom_macroW = DATA.GUI.custom_knob_button_w*8--+DATA.GUI.custom_offset
      DATA.GUI.custom_macro_knobtxtsz= math.floor(15* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_macro_linkentryh = math.floor(25 * DATA.GUI.custom_Yrelation  )
      DATA.GUI.custom_macro_link_txtsz= math.floor(14* DATA.GUI.custom_Yrelation)
    -- midiosc
      DATA.GUI.custom_midiY = DATA.GUI.custom_infoh
      DATA.GUI.custom_midiH = DATA.GUI.custom_moduleH
      DATA.GUI.custom_midiW = math.floor(DATA.GUI.custom_moduleW*1.25)
      DATA.GUI.custom_midi_entryh = math.floor(25 * DATA.GUI.custom_Yrelation  )
      DATA.GUI.custom_midi_txtsz= math.floor(14* DATA.GUI.custom_Yrelation)
    -- pad overview
      DATA.GUI.custom_padgridy = 0
      DATA.GUI.custom_padgridh = gfx_h-DATA.GUI.custom_offset--DATA.GUI.custom_infoh -- - -DATA.GUI.custom_offset 
      DATA.GUI.custom_padgridblockh = math.floor(DATA.GUI.custom_padgridh/8)
      DATA.GUI.custom_padgridw = DATA.GUI.custom_padgridblockh 
       
    -- drrack 
      DATA.GUI.custom_drrack_sideY = math.floor(DATA.GUI.custom_moduleH/4)
      DATA.GUI.custom_drrack_sideX = DATA.GUI.custom_drrack_sideY*1.5
      DATA.GUI.custom_drrack_sideW = DATA.GUI.custom_moduleW--DATA.GUI.custom_offset
      DATA.GUI.custom_drrack_pad_txtsz = 13* DATA.GUI.custom_Yrelation--0.5*(DATA.GUI.custom_drrack_sideY/2-DATA.GUI.custom_offset*2)
      DATA.GUI.custom_drrack_arcr = math.floor(DATA.GUI.custom_drrack_sideX*0.1) 
      DATA.GUI.custom_drrack_sideW = DATA.GUI.custom_drrack_sideX*4 -- reset to 4 pads
      DATA.GUI.custom_drrackH = DATA.GUI.custom_drrack_sideY*4
      DATA.GUI.custom_drrack_ctrlbut_h = DATA.GUI.custom_drrack_sideY/2
      
    -- device
      DATA.GUI.custom_device_droptxtsz =  math.floor(20* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_devicew = math.floor(DATA.GUI.custom_moduleW)
      DATA.GUI.custom_deviceh = gfx_h - DATA.GUI.custom_infoh-DATA.GUI.custom_offset -- DEVICE H
      DATA.GUI.custom_deviceentryh = math.floor(25 * DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_devicectrl_txtsz = math.floor(14 *DATA.GUI.custom_Yrelation   )
      
    -- database
      DATA.GUI.custom_databasew = math.floor(DATA.GUI.custom_moduleW*0.6)
      
    -- childchain
      DATA.GUI.custom_childchainw = math.floor(DATA.GUI.custom_moduleW)      
      DATA.GUI.custom_childchain_entryh = math.floor(25 * DATA.GUI.custom_Yrelation  )
      
    -- sampler  
      DATA.GUI.custom_sampler_peakareah = math.floor(DATA.GUI.custom_moduleH * 0.4)  
      DATA.GUI.custom_samplerW = (DATA.GUI.custom_knob_button_w+DATA.GUI.custom_offset) * 8
      DATA.GUI.custom_sampler_namebutw = DATA.GUI.custom_samplerW-(DATA.GUI.custom_knob_button_w)*2 -DATA.GUI.custom_infoh
      DATA.GUI.custom_sampler_readouth =DATA.GUI.custom_knob_button_w+1 
      DATA.GUI.custom_sampler_knob_h = DATA.GUI.custom_moduleH - DATA.GUI.custom_module_ctrlreadout_h*2 - DATA.GUI.custom_sampler_peakareah - DATA.GUI.custom_offset*4-DATA.GUI.custom_offset 
      DATA.GUI.custom_sampler_ctrl_txtsz = math.floor(13 *DATA.GUI.custom_Yrelation  )
      DATA.GUI.custom_sampler_peaksw = DATA.GUI.custom_samplerW-DATA.GUI.custom_offset-DATA.GUI.custom_knob_button_w-1
      
    -- global
      DATA.GUI.custom_knob_button_h =DATA.GUI.custom_sampler_knob_h 
      GUI_RESERVED_initmacroXoffs(DATA)
      
      
      
      
      
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
        GUI_RESERVED_init_tabs(DATA)
        --end
       elseif DATA.GUI.Settings_open and DATA.GUI.Settings_open == 1 then 
        GUI_MODULE_SETTINGS(DATA)
      end
    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init_tabs(DATA)
    GUI_MODULE_TABS(DATA)
    GUI_MODULE_MACRO(DATA) 
    GUI_MODULE_PADOVERVIEW(DATA)
    GUI_MODULE_DRUMRACK(DATA)
    GUI_MODULE_DEVICE(DATA)  
    GUI_MODULE_SAMPLER(DATA) 
    GUI_MODULE_SETTINGS(DATA)
    GUI_MODULE_DATABASE(DATA)
    GUI_MODULE_MIDI(DATA) 
    GUI_MODULE_CHILDCHAIN(DATA)
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
        {str = 'Rename track',                                  group = 1, itype = 'check', confkey = 'CONF_onadd_renametrack', level = 1},
        {str = 'Copy samples to project path',                  group = 1, itype = 'check', confkey = 'CONF_onadd_copytoprojectpath', level = 1},
        {str = 'Custom track template: '..customtemplate,       group = 1, itype = 'button', confkey = 'CONF_onadd_customtemplate', level = 1, val_isstring = true, func_onrelease = function() local retval, fp = GetUserFileNameForRead('', 'FX chain for newly dragged samples', 'RTrackTemplate') if retval then DATA.extstate.CONF_onadd_customtemplate=  fp GUI_MODULE_SETTINGS(DATA) end end},
        {str = 'Custom track template [clear]',                  group = 1, itype = 'button', confkey = 'CONF_onadd_customtemplate', level = 1, val_isstring = true, func_onrelease = function() DATA.extstate.CONF_onadd_customtemplate=  '' GUI_MODULE_SETTINGS(DATA) end},
      {str = 'MIDI bus',                                        group = 2, itype = 'sep'}, 
        {str = 'MIDI bus default input',                        group = 2, itype = 'readout', confkey = 'CONF_midiinput', level = 1, menu = {[63]='All inputs',[62]='Virtual keyboard'},readoutw_extw = readoutw_extw},
        {str = 'MIDI bus channel',                        group = 2, itype = 'readout', confkey = 'CONF_midichannel', level = 1, menu = {[0]='All channels',[1]='Channel 1',[2]='Channel 2',[3]='Channel 3',[4]='Channel 4',[5]='Channel 5',[6]='Channel 6',[7]='Channel 7',[8]='Channel 8',[9]='Channel 9',[10]='Channel 10',
        [11]='Channel 11',[12]='Channel 12',[13]='Channel 13',[14]='Channel 14',[15]='Channel 15',[16]='Channel 16'},readoutw_extw = readoutw_extw},
      {str = 'UI',                                              group = 3, itype = 'sep'},
        {str = 'Active note follow incoming note',              group = 3, itype = 'check', confkey = 'UI_incomingnoteselectpad', level = 1},
        {str = 'Key format',                                    group = 3, itype = 'readout', confkey = 'UI_keyformat_mode', level = 1,menu = {[0]='C-C#-D',[2]='Do-Do#-Re',[7]='Russian'}},
      {str = 'Tab defaults',                                    group = 6, itype = 'sep'},
        {str = 'Drumrack',                                      group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 0},
        {str = 'Device',                                        group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 1},
        {str = 'Sampler',                                       group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 2},
        {str = 'Padview',                                       group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 3},
        --{str = 'Tab defaults: macro',                           group = 3, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 4},
        {str = 'Database',                                      group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 5},
        {str = 'MIDI / OSC learn',                              group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 6},
      {str = 'DrumRack',                                        group = 4, itype = 'sep'},  
        {str = 'Click on pad select track',                     group = 4, itype = 'check', confkey = 'UI_clickonpadselecttrack', level = 1},
      {str = 'Sample actions',                                  group = 5, itype = 'sep'},    
        {str = 'Crop threshold',                                group = 5, itype = 'readout', confkey = 'CONF_cropthreshold', level = 1, menu = {[-80]='-80dB',[-60]='-60dB', [-40]='-40dB',[-30]='-30dB'},readoutw_extw = readoutw_extw},

    } 
    return t
    
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO_links(DATA) 
    if not DATA2.PARENT_LASTACTIVEMACRO then return end
    local macroID = DATA2.PARENT_LASTACTIVEMACRO
    local x_offs = DATA.GUI.buttons.macroglob_Aframe.x+DATA.GUI.custom_offset
    local y_offs = DATA.GUI.custom_macroY+DATA.GUI.custom_knob_button_h+DATA.GUI.custom_offset
    local h_frame = DATA.GUI.custom_macroH-DATA.GUI.custom_knob_button_h-DATA.GUI.custom_offset*2
    DATA.GUI.buttons.macroglob_linksframe = { x=x_offs,
                          y=y_offs,
                          w=DATA.GUI.custom_macroW-DATA.GUI.custom_offset*2,
                          h=h_frame,
                          txt = '',
                          frame_a = 1,
                          frame_col = '#333333',
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          ignoremouse = true,
                          onmouseclick =  function() end}
    DATA.GUI.buttons.macroglob_t_addbut = { x=x_offs,
                          y=y_offs,
                          w=DATA.GUI.custom_macroW-DATA.GUI.custom_offset*2,
                          h=DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
                          txt = 'Add link for last touched parameter in the rack child',
                          txt_fontsz = DATA.GUI.custom_macro_link_txtsz,
                          --frame_a = 1,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          --ignoremouse = true,
                          onmouseclick =  function() 
                                            DATA2:Actions_Macro_AddLink()
                                          end}  
    y_offs = y_offs + DATA.GUI.custom_macro_linkentryh              
    if not (DATA2.Macro.sliders[macroID] and DATA2.Macro.sliders[macroID].links) then return end
    
    local w_layername = math.floor(DATA.GUI.buttons.macroglob_Aframe.w*0.55)
    local w_ctrls = DATA.GUI.buttons.macroglob_Aframe.w - w_layername-DATA.GUI.custom_offset
    local w_ctrls_single = (w_ctrls / 3)
    local backgr_col=DATA.GUI.custom_backcol2
    local backgr_fill_param = 0.2 
    local backgr_fill_name = 0
    
    for linkID = 1, #DATA2.Macro.sliders[macroID].links do
      local t = DATA2.Macro.sliders[macroID].links[linkID]
      DATA.GUI.buttons['macroglob_'..'macroID'..macroID..'link'..linkID] = { 
                          x=x_offs,
                          y=y_offs,
                          w=w_layername-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
                          txt = DATA2.Macro.sliders[macroID].links[linkID].param_name,
                          txt_fontsz = DATA.GUI.custom_macro_link_txtsz,
                          frame_a =DATA.GUI.custom_framea,
                          frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,
                          onmouseclick = function() 
                            --DATA2.PARENT_LASTACTIVENOTE_layer = layer 
                            GUI_MODULE_SAMPLER(DATA)
                            GUI_MODULE_DEVICE(DATA) 
                          end,
                          onmousefiledrop = function() DATA2:Actions_PadOnFileDrop(note,layer) end, 
                          } 
      GUI_CTRL(DATA,
        {
          butkey = 'macroglob_'..'macroID'..macroID..'offs'..linkID,
          
          x = x_offs+w_layername,
          y= y_offs,
          w = w_ctrls_single-DATA.GUI.custom_offset,
          h = DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
          
          ctrlname = 'Offs',
          ctrlval_key = 'plink_offset',
          ctrlval_format_key = 'plink_offset_format',
          ctrlval_src_t = t,
          ctrlval_res = 0.1,
          ctrlval_default =0,
          ctrlval_min =-1,
          ctrlval_max =1,
          func_atrelease =      function()      GUI_MODULE_MACRO(DATA)  end,
          func_app =            function(new_val) 
                                  TrackFX_SetNamedConfigParm(t.src_t.tr_ptr, t.fx_dest, 'param.'..t.param_dest..'plink.offset', new_val)  
                                end,
          func_refresh =        function() 
                                  DATA2:TrackDataRead_GetParent_Macro()
                                end,
          func_formatreverse =  function(str_ret)
                                  local ret = DATA2:internal_ParsePercent(str_ret) if ret then return ret end
                                end
         } )
      GUI_CTRL(DATA,
        {
          butkey = 'macroglob_'..'macroID'..macroID..'scale'..linkID,
          
          x = x_offs+w_layername+w_ctrls_single,
          y= y_offs,
          w = w_ctrls_single-DATA.GUI.custom_offset,
          h = DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
          
          ctrlname = 'offs',
          ctrlval_key = 'plink_scale',
          ctrlval_format_key = 'plink_scale_format',
          ctrlval_src_t = t,
          ctrlval_res = 0.1,
          ctrlval_default =0,
          func_atrelease =      function() GUI_MODULE_MACRO(DATA) end,          
          func_app =            function(new_val) 
                                  TrackFX_SetNamedConfigParm(t.src_t.tr_ptr, t.fx_dest, 'param.'..t.param_dest..'plink.scale', new_val) 
                                end,
          func_refresh =        function() 
                                  DATA2:TrackDataRead_GetParent_Macro()
                                end,
          func_formatreverse =  function(str_ret)
                                  local ret = DATA2:internal_ParsePercent(str_ret) if ret then return ret end
                                end
         } ) 
      DATA.GUI.buttons['macroglob_'..'macroID'..macroID..'linkremove'..linkID] = { 
                          x=x_offs+w_layername+w_ctrls_single*2,
                          y=y_offs,
                          w=w_ctrls_single-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
                          txt = 'X',
                          txt_fontsz = DATA.GUI.custom_macro_link_txtsz,
                          frame_a =DATA.GUI.custom_framea,
                          --frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,
                          onmouserelease = function() 
                            TrackFX_SetNamedConfigParm(t.src_t.tr_ptr, t.fx_dest, 'param.'..t.param_dest..'plink.active', 0) 
                            DATA2:TrackDataRead_GetParent_Macro()
                            GUI_MODULE_MACRO(DATA) 
                          end,
                          }          
      y_offs = y_offs + DATA.GUI.custom_macro_linkentryh 
    end
  end 
  -----------------------------------------------------------------------------  
  function DATA2:internal_ConfirLTPisChild()
    local t = VF2_GetLTP()
    --[[
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
            ]]
    if not t then return end
    local note_out, layer_out
    local lt_tr_GUID = t.trGUID
    for note in pairs(DATA2.notes) do
      if DATA2.notes[note].TR_GUID then 
        if DATA2.notes[note].TR_GUID == lt_tr_GUID then 
          return true, DATA2.notes[note], t.fxnumber, t.paramnumber
        end
      end
      if DATA2.notes[note].layers then
        for layer in pairs(DATA2.notes[note].layers) do
          if DATA2.notes[note].layers[layer].TR_GUID and DATA2.notes[note].layers[layer].TR_GUID == lt_tr_GUID then
            return true, DATA2.notes[note].layers[layer], t.fxnumber, t.paramnumber
          end
        end
      end
    end
  end
  -----------------------------------------------------------------------------  
  function DATA2:Actions_Macro_AddLink()
    if not DATA2.PARENT_LASTACTIVEMACRO then return end 
    if DATA2.PARENT_LASTACTIVEMACRO == -1 then return end
    local ret, srct, fxnumber, paramnumber = DATA2:internal_ConfirLTPisChild()
    if not ret then return end
    
    -- init child macro
      if not srct.macro_pos then 
        DATA2:TrackData_InitMacro(true, srct)
        fxnumber=fxnumber+1
      end
      
    -- link
      local param_src = tonumber(DATA2.PARENT_LASTACTIVEMACRO)
      local fx_src = tonumber(srct.macro_pos)
      
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.active', 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.scale', 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.offset', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.effect',fx_src)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.param', param_src)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_bus', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_chan', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_msg', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_msg2', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.mod.active', 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.mod.visible', 0)
      
      --[[
      boolean retval, string buf = reaper.TrackFX_GetNamedConfigParm(MediaTrack track, integer fx, string parmname)
      
      gets plug-in specific named configuration value (returns true on success). Special values:
      pdc returns PDC latency.
      in_pin_X returns name of input pin X (if available).
      out_pin_X returns name of output pin X (if available).
      fx_type returns type string.
      fx_ident returns type-specific identifier.
      fx_name returns pre-aliased name.
      vst_chunk and vst_chunk_program can be used for supported VST plug-ins to get/set base64-encoded VST-specific chunk.
      param.X.lfo.[active,dir,phase,speed,strength,temposync,free,shape]
      param.X.acs.[active,dir,strength,attack,release,dblo,dbhi,chan,stereo]
      param.X.plink.[active,scale,offset,effect,param,midi_bus,midi_chan,midi_msg,midi_msg2] - set effect=-100 to support midi_*
      param.X.mod.[active,baseline,visible]]
    
    DATA2:TrackDataRead_GetParent_Macro()
    GUI_MODULE_MACRO(DATA)   
    
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_separator(DATA, key, xoffs)   
    DATA.GUI.buttons[key] = { x=xoffs,
                          y=0,
                          w=DATA.GUI.custom_moduleseparatorw-1,
                          h=gfx.h/DATA.GUI.default_scale,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          backgr_fill = 0.5,
                          backgr_col = '#FFFFFF',
                          onmouseclick =  function() end}
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_CHILDCHAIN(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('childchain_') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&128==0) then return end
    local x_offs0= math.floor(DATA.GUI.custom_module_xoffs_childchain+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    GUI_MODULE_separator(DATA, 'childchain_sep', DATA.GUI.custom_module_xoffs_childchain) 
    
    local nameframe_w  = DATA.GUI.custom_childchainw
      -- DATA.GUI.custom_knob_button_w - DATA.GUI.custom_infoh
    local y_offs = DATA.GUI.custom_infoh + DATA.GUI.custom_offset
    DATA.GUI.buttons.childchain_actionframe = { x=x_offs0,
                          y=0,
                          w=nameframe_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'Children chain',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() end}
    local notenamesw = math.floor(DATA.GUI.custom_childchainw*0.3)
    for note in pairs(DATA2.notes) do
      local x_offs = x_offs0
      DATA.GUI.buttons['childchain_'..'note'..note..'name'] = { 
                          x=x_offs,
                          y=y_offs,
                          w=notenamesw-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_childchain_entryh-DATA.GUI.custom_offset,
                          txt = DATA2.notes[note].name,
                          txt_fontsz = DATA.GUI.custom_midi_txtsz,
                          onmouseclick = function() 
                          end,
                          } 
      x_offs = x_offs + notenamesw
      y_offs = y_offs + DATA.GUI.custom_childchain_entryh
    end
                          
  end
  
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MIDI(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('midiosclearn_') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&64==0) then return end
    
    local x_offs0= math.floor(DATA.GUI.custom_module_xoffs_midi+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    GUI_MODULE_separator(DATA, 'midiosclearn_sep', DATA.GUI.custom_module_xoffs_midi) 
    local nameframe_w  = DATA.GUI.custom_midiW - DATA.GUI.custom_knob_button_w - DATA.GUI.custom_infoh
    local x_offs = x_offs0
    DATA.GUI.buttons.midiosclearn_actionframe = { x=x_offs0,
                          y=0,
                          w=nameframe_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'MIDI / OSC map',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() end}
    x_offs0 = x_offs0 + nameframe_w
    DATA.GUI.buttons.midiosclearn_actionframe_actions = { x=x_offs0,
                          y=0,
                          w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'Learn',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() Action(41144) end}    
    x_offs0 = x_offs0 + DATA.GUI.custom_knob_button_w
    DATA.GUI.buttons.midiosclearn_actionframe_help = { x=x_offs0,
                          y=0,
                          w=DATA.GUI.custom_infoh-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = '?',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() DATA2:Actions_Help(5) end}                              
    DATA.GUI.buttons.midiosclearn_Aframe = { x=x_offs, 
                          y=DATA.GUI.custom_midiY+DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_midiW-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_midiH-DATA.GUI.custom_offset*2,
                          txt = '',
                          hide = true,
                          frame_a = 0,--0.3,
                          frame_asel = 0.3,
                          --backgr_fill = 0,
                          ignoremouse = true,
                          onmouseclick =  function() end}
                          
    if not (DATA2.MIDIOSC and DATA2.MIDIOSC.map) then return end 
    local y_offs = DATA.GUI.buttons.midiosclearn_Aframe.y
    local name_fx_paramW = math.floor(DATA.GUI.custom_midiW*0.6)
    local name_fx_paramW_single = math.floor(name_fx_paramW/2)
    local colw = math.floor((DATA.GUI.custom_midiW-name_fx_paramW-DATA.GUI.custom_midi_entryh-DATA.GUI.custom_knob_button_w)/2)
    for mapID = 1, #DATA2.MIDIOSC.map do
      local mapt = DATA2.MIDIOSC.map[mapID]
      local x_offs = DATA.GUI.buttons.midiosclearn_Aframe.x--+DATA.GUI.custom_offset
      
      
      DATA.GUI.buttons['midiosclearn_'..'mapID'..mapID..'remove'] = { 
                          x=x_offs,
                          y=y_offs,
                          w=DATA.GUI.custom_midi_entryh-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_midi_entryh-DATA.GUI.custom_offset,
                          txt = 'X',
                          txt_fontsz = DATA.GUI.custom_midi_txtsz,
                          --[[frame_a =0,
                          frame_asel =0,
                          frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,]]
                          onmouseclick = function() 
                            TrackFX_SetNamedConfigParm(mapt.tr_ptr, mapt.fx, 'param.'..mapt.param..'.learn.midi1', '')
                            TrackFX_SetNamedConfigParm(mapt.tr_ptr, mapt.fx, 'param.'..mapt.param..'.learn.midi2', '')
                            TrackFX_SetNamedConfigParm(mapt.tr_ptr, mapt.fx, 'param.'..mapt.param..'.learn.osc', '')
                            TrackFX_SetNamedConfigParm(mapt.tr_ptr, mapt.fx, 'param.'..mapt.param..'.learn', '')
                            DATA_RESERVED_ONPROJCHANGE(DATA)
                          end,
                          }     
      x_offs = x_offs + DATA.GUI.custom_midi_entryh
      DATA.GUI.buttons['midiosclearn_'..'mapID'..mapID] = { 
                          x=x_offs,
                          y=y_offs,
                          w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_midi_entryh-DATA.GUI.custom_offset,
                          txt = DATA2.MIDIOSC.map[mapID].format_ctrlnameID,
                          txt_fontsz = DATA.GUI.custom_midi_txtsz,
                          --[[frame_a =0,
                          frame_asel =0,
                          frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,]]
                          onmouseclick = function() 
                          end,
                          }
      x_offs = x_offs + DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons['midiosclearn_'..'mapID'..mapID..'fxname'] = { 
                          x=x_offs,
                          y=y_offs,
                          w=name_fx_paramW_single-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_midi_entryh-DATA.GUI.custom_offset,
                          txt = DATA2.MIDIOSC.map[mapID].fxname,
                          txt_fontsz = DATA.GUI.custom_midi_txtsz,
                          --[[frame_a =0,
                          frame_asel =0,
                          frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,]]
                          onmouseclick = function() 
                          end,
                          }
      x_offs = x_offs + name_fx_paramW_single
      DATA.GUI.buttons['midiosclearn_'..'mapID'..mapID..'paramname'] = { 
                          x=x_offs,
                          y=y_offs,
                          w=name_fx_paramW_single-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_midi_entryh-DATA.GUI.custom_offset,
                          txt = DATA2.MIDIOSC.map[mapID].paramname,
                          txt_fontsz = DATA.GUI.custom_midi_txtsz,
                          --[[frame_a =0,
                          frame_asel =0,
                          frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,]]
                          onmouseclick = function() 
                          end,
                          }
      x_offs = x_offs + name_fx_paramW_single
      DATA.GUI.buttons['midiosclearn_'..'mapID'..mapID..'midi'] = { 
                          x=x_offs,
                          y=y_offs,
                          w=colw-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_midi_entryh-DATA.GUI.custom_offset,
                          txt = DATA2.MIDIOSC.map[mapID].format_midiname,
                          txt_fontsz = DATA.GUI.custom_midi_txtsz,
                          --[[frame_a =0,
                          frame_asel =0,
                          frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,]]
                          onmouseclick = function() 
                          end,
                          } 
      x_offs = x_offs + colw
      DATA.GUI.buttons['midiosclearn_'..'mapID'..mapID..'osc'] = { 
                          x=x_offs,
                          y=y_offs,
                          w=colw-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_midi_entryh-DATA.GUI.custom_offset,
                          txt = DATA2.MIDIOSC.map[mapID].format_oscname,
                          txt_fontsz = DATA.GUI.custom_midi_txtsz,
                          --[[frame_a =0,
                          frame_asel =0,
                          frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,]]
                          onmouseclick = function() 
                          end,
                          }                           
      y_offs = y_offs + DATA.GUI.custom_midi_entryh
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO(DATA)    
    for key in pairs(DATA.GUI.buttons) do if key:match('macroglob_') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==0) then return end
    
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_macro+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    GUI_MODULE_separator(DATA, 'macroglob_sep', DATA.GUI.custom_module_xoffs_macro) 
    
    DATA.GUI.buttons.macroglob_actionframe = { x=x_offs,
                          y=0,
                          w=DATA.GUI.custom_macroW-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'Macro',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() end}
    DATA.GUI.buttons.macroglob_Aframe = { x=x_offs, 
                          y=DATA.GUI.custom_macroY,
                          w=DATA.GUI.custom_macroW,
                          h=DATA.GUI.custom_macroH,
                          txt = '',
                          
                          
                          frame_a = 0,--0.3,
                          frame_asel = 0.3,
                          --backgr_fill = 0,
                          ignoremouse = true,
                          onmouseclick =  function() end}
                          
    -- controls 
    for ctrlid = 1, 16 do
      local frame_a
      if DATA2.PARENT_LASTACTIVEMACRO and ctrlid == DATA2.PARENT_LASTACTIVEMACRO then 
        frame_a = 1
       else
        frame_a = nil
      end
      local xshift = DATA.GUI.custom_knob_button_w*(ctrlid-1)+1
      local yshift = DATA.GUI.custom_macro_knobH * math.floor((ctrlid/9))
      if ctrlid>=9 then  xshift = DATA.GUI.custom_knob_button_w*(ctrlid-9) end 
      local src_t = DATA2.Macro.sliders[ctrlid]
      GUI_CTRL(DATA,
        {
          butkey = 'macroglob_knob'..ctrlid,
          
          x = x_offs+xshift,
          y=  DATA.GUI.custom_infoh + DATA.GUI.custom_offset + yshift,
          w = DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
          h = DATA.GUI.custom_knob_button_h-DATA.GUI.custom_offset,
          frame_a = frame_a,
          
          ctrlname = 'Macro \n'..ctrlid,
          ctrlval_key = 'macroval',
          ctrlval_format_key = 'macroval_format',
          ctrlval_src_t = DATA2.Macro.sliders[ctrlid],
          ctrlval_res = 0.5,
          ctrlval_default = 0,
          func_atrelease =      function() 
                                  DATA2.PARENT_LASTACTIVEMACRO = ctrlid
                                  DATA2:TrackDataWrite(_,{master_upd=true})
                                  GUI_MODULE_MACRO(DATA)    
                                end,
          func_app =            function(new_val) 
                                  TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.macro_pos, ctrlid, new_val ) 
                                end,
          func_refresh =        function() 
                                  DATA2:TrackDataRead_GetParent_Macro(true) 
                                  local note_layer_t = DATA2:internal_GetActiveNoteLayerTable()
                                  DATA2:TrackDataRead_GetChildrens_InstrumentParams(note_layer_t)
                                  DATA2:TrackDataRead_GetChildrens_FXParams(note_layer_t)  
                                  GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) 
                                  GUI_MODULE_SAMPLER_Section_FilterSection(DATA)   
                                  GUI_MODULE_SAMPLER_Section_EnvelopeSection(DATA)  
                                end,
          func_formatreverse =  function(str_ret)
                                  local ret = DATA2:internal_ParsePercent(str_ret)
                                  if ret then 
                                    local new_val = VF_BFpluginparam(ret, src_t.tr_ptr, src_t.macro_pos, ctrlid) 
                                    return new_val
                                  end
                                end
         } )    
         
    end
    GUI_MODULE_MACRO_links(DATA)                       
  end
  -----------------------------------------------------------------------------  
  function DATA2:internal_ParsePercent(str_ret)
    if not str_ret then return end
    str_ret = str_ret:match('[%d%p]+') 
    if not str_ret then return end
    str_ret = tonumber(str_ret)
    if not str_ret then return end
    str_ret = tostring(str_ret / 99.9)
    return str_ret
  end
  -----------------------------------------------------------------------------  
  function DATA2:Actions_Sampler_NextPrevSample(spl_t, mode)
    if not mode then mode = 0 end
    if not spl_t.ISRS5K then return end
    fn = spl_t.instrument_filepath:gsub('\\', '/') 
    path = fn:reverse():match('[%/]+.*'):reverse():sub(0,-2)
    cur_file =     fn:reverse():match('.-[%/]'):reverse():sub(2)
    
    -- get files list
      local files = {}
      local i = 0
      repeat
      local file = reaper.EnumerateFiles( path, i )
      if file and reaper.IsMediaExtension(file:gsub('.+%.', ''), false) then
        files[#files+1] = file
      end
      i = i+1
      until file == nil
      table.sort(files, function(a,b) return a<b end )
    
    
    local trig_file
    if mode == 0  then    -- search file list nex
      if #files < 2 then return end
      for i = 2, #files do
        if files[i-1] == cur_file then 
          trig_file = path..'/'..files[i] 
          break 
         elseif i == #files then trig_file = path..'/'..files[1] 
        end 
      end
    end
    
    if mode ==1 then     -- search file list prev
      if #files < 2 then return end
      for i = #files-1, 1, -1 do
        if files[i+1] == cur_file then 
          trig_file = path..'/'..files[i] 
          break 
         elseif i ==1 then trig_file = path..'/'..files[#files] 
        end
      end
    end
      
    if mode ==2 then        -- search file list random
      if #files < 2 then return end
      trig_id = math.floor(math.random(#files-1))+1
      trig_file = path..'/'..files[trig_id] 
    end    
    
    if trig_file then 
      DATA2:Actions_PadOnFileDrop_Sub(spl_t.noteID, spl_t.layerID, trig_file)
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
  function GUI_RESERVED_drawDYN(DATA)
    if not (DATA2.PAD_HOLD and DATA2.notes[DATA2.PAD_HOLD] ) then return end
    local mousex = DATA.GUI.x
    local mousey = DATA.GUI.y
    local txt = 'Drag pad #'..DATA2.PAD_HOLD..'\n'..DATA2.notes[DATA2.PAD_HOLD].name
    local b =  {            x=mousex,
                            y=mousey,
                            w=DATA.GUI.custom_drrack_sideX,
                            h=DATA.GUI.custom_drrack_sideY,
                            txt = txt,
                            txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                            frame_arcborder = true,
                            frame_arcborderr = DATA.GUI.custom_drrack_arcr,
                            frame_arcborderflags = 1|2,
                            }
    DATA:GUIdraw_Button(b)
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_DRUMRACK(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('drumrack') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&1==0) then return end
    
    local trname = DATA2.tr_name or '[no data]'   
    local drracvname_w = DATA.GUI.custom_drrack_sideW-DATA.GUI.custom_knob_button_w*2-DATA.GUI.custom_infoh
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_drumrack+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    GUI_MODULE_separator(DATA, 'drumrack_sep', DATA.GUI.custom_module_xoffs_drumrack) 
       -- dr rack
       DATA.GUI.buttons.drumrack_trackname = { x=x_offs,
                            y=0,
                            w=drracvname_w-DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_infoh-1,
                            txt = trname,
                            txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                            }
       DATA.GUI.buttons.drumrackpad = { x=x_offs,
                             y=DATA.GUI.custom_infoh,
                             w=DATA.GUI.custom_drrack_sideW+1,
                             h=DATA.GUI.custom_drrackH,
                             ignoremouse = true,
                             frame_a = 0,
                             }
     x_offs = x_offs + drracvname_w    
     DATA.GUI.buttons.drumrack_FX = { x=x_offs,
                          y=0,
                          w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'FX',
                          txt_a=txt_a,
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          onmouseclick = function() TrackFX_Show( DATA2.tr_ptr, -1, 1 ) end
                          } 
      x_offs = x_offs + DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons.drumrack_showME = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'Explore',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() if DATA2.PARENT_LASTACTIVENOTE then  DATA2:Actions_Pad_ShowME(DATA2.PARENT_LASTACTIVENOTE, DATA2.PARENT_LASTACTIVENOTE_layer or 1) end  end,
                           } 
      x_offs = x_offs + DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons.drumrack_help = { x=x_offs,
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
      if note > 127 then break end
      
      -- handle names
        local txt = DATA2:internal_FormatMIDIPitch(note)..' ['..note..']'
        local txt2 = ''
        if DATA2.notes[note] and DATA2.notes[note].name then txt2 = DATA2.notes[note].name end 
        if DATA2.notes[note] and DATA2.notes[note].TYPE_DEVICE and DATA2.notes[note].TYPE_DEVICE == true and DATA2.notes[note].tr_name then 
          txt =txt..' [Device]' 
          txt2 = DATA2.notes[note].tr_name
        end 
        if DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[note]  then 
          txt = '[DB '..note..'] '..(DATA2.database_map.map[note].notename  or '[empty]')
          if DATA2.database_map.map[note].lock == 1 then txt = '[DB '..note..'] [L] '..(DATA2.database_map.map[note].notename  or '[empty]')  end
        end
      
      -- handle col
        local col 
        if DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_col then 
          col = DATA2.notes[note].layers[1].tr_col 
          col = string.format("#%06X", col);
        end
      
      DATA.GUI.buttons['drumrackpad_pad'..padID0] = { x=math.floor(DATA.GUI.buttons.drumrackpad.x+(padID0%4)*DATA.GUI.custom_drrack_sideX)+1,
                              y=DATA.GUI.custom_infoh+DATA.GUI.custom_drrackH-DATA.GUI.custom_drrack_sideY*(math.floor(padID0/4)+1)+DATA.GUI.custom_offset,
                              w=DATA.GUI.custom_drrack_sideX-DATA.GUI.custom_offset,
                              h=DATA.GUI.custom_drrack_sideY-DATA.GUI.custom_offset-1,
                              ignoremouse = true,
                              txt='',
                              frame_a = frame_a,
                              frame_col = col,
                              --[[frame_arcborder = true,
                              frame_arcborderr = DATA.GUI.custom_drrack_arcr,
                              frame_arcborderflags = 1|2,]]
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
      local controlbut_w = ((DATA.GUI.custom_drrack_sideX -DATA.GUI.custom_offset)/ 3)--math.floor
      local frame_actrl =0
      local txt_actrl = 0.2
      local txt_a 
      if not DATA2.notes[note] then txt_a = 0.1 end
      
      
      local frame_a = 0
        
      --msg(col)
      
      local backgr_col =DATA.GUI.custom_backcol2-- '#33FF45'
      backgr_col = col
      local nameh = math.floor(DATA.GUI.custom_drrack_ctrlbut_h/2)
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] = { x=padx,
                              y=pady,
                              w=DATA.GUI.custom_drrack_sideX-DATA.GUI.custom_offset,
                              h=nameh,
                              txt=txt,
                              txt_a = txt_a,
                              txt_fontsz =DATA.GUI.custom_drrack_pad_txtsz,
                              txt_col = backgr_col,
                              frame_a = frame_a,
                              frame_asel = frame_a,
                              frame_col = backgr_col,--DATA.GUI.custom_backcol2,
                              backgr_fill = 0 ,
                              --backgr_col = backgr_col,
                              back_sela = 0 ,
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
                                --DATA2.PARENT_LASTACTIVENOTE_layer = 1 
                                DATA2:TrackDataWrite(_,{master_upd=true}) 
                                --GUI_MODULE_DRUMRACK(DATA)  
                                if DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] then DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].refresh = true end
                                --DATA2.PARENT_LASTACTIVENOTE_layer = layer 
                                GUI_MODULE_DEVICE(DATA)  
                                GUI_MODULE_SAMPLER(DATA)
                                GUI_MODULE_DATABASE(DATA)  
                                --end
                              end,
                              onmouseclickR = function() DATA2:Actions_Pad_Menu(note) end,
                              onmousefiledrop = function() DATA2:Actions_PadOnFileDrop(note) end,
                              onmouserelease =  function()  
                                                  DATA2.PAD_HOLD = nil
                                                    if not DATA2.ONDOUBLECLICK then
                                                      DATA2.PARENT_LASTACTIVENOTE = note 
                                                      GUI_MODULE_DRUMRACK(DATA) 
                                                      DATA2.ONPARAMDRAG = false
                                                     else
                                                      DATA2.ONDOUBLECLICK = nil
                                                    end
                                                end,
                              onmousedrop =  function()  
                                              
                                              if DATA2.PAD_HOLD then 
                                                local padsrc = DATA2.PAD_HOLD
                                                local paddest = note
                                                DATA2:Actions_Pad_CopyMove(padsrc,paddest, DATA.GUI.Ctrl) 
                                                DATA2.PAD_HOLD = nil
                                              end 
                                            end,
                              onmousedoubleclick = function() 
                                                    DATA2.ONDOUBLECLICK = true
                                                  end
                              }  
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'name2'] = { x=padx,
                              y=pady+nameh,
                              w=DATA.GUI.custom_drrack_sideX-DATA.GUI.custom_offset,
                              h=nameh,
                              txt=txt2,
                              txt_a = txt_a,
                              txt_fontsz =DATA.GUI.custom_drrack_pad_txtsz,
                              txt_col = backgr_col,
                              frame_a = frame_a,
                              frame_asel = frame_a,
                              frame_col = backgr_col,--DATA.GUI.custom_backcol2,
                              backgr_fill = 0 ,
                              --backgr_col = backgr_col,
                              back_sela = 0 ,
                              onmousedrag = DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].onmousedrag, 
                              onmouseclick = DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].onmouseclick,
                              onmouseclickR = DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].onmouseclickR,
                              onmousefiledrop = DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].onmousefiledrop,
                              onmouserelease =  DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].onmouserelease,
                              onmousedrop =  DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].onmousedrop,
                              onmousedoubleclick = DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].onmousedoubleclick,
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
                              onmouseclick = function() DATA2:Actions_Pad_SoloMute(note,_,_, true) end,
                              } 
                              
      
      local backgr_fill2,frame_actrl0=nil,frame_actrl if DATA2.playingnote_pitch and DATA2.playingnote_pitch == note and DATA.extstate.UI_incomingnoteselectpad == 0  then backgr_fill2 = 0.8 frame_actrl0 = 1 end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'play'] = { x=padx+controlbut_w,
                              y=pady+DATA.GUI.custom_drrack_ctrlbut_h+1,
                              w=controlbut_w,
                              h=controlbut_h2-2,
                              txt='>',
                              txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                              txt_a = txt_actrl,
                              txt_col = backgr_col,
                              prevent_matchrefresh = true,
                              frame_a = 0,
                              backgr_fill = 0.2 ,
                              onmouseclick =    function() DATA2:Actions_StuffNoteOn(note, vel) end,
                              onmouserelease =  function() StuffMIDIMessage( 0, 0x80, note, 0 ) DATA.ontrignoteTS =  nil end,
                              refresh = true,
                              --hide = DATA.extstate.UI_incomingnoteselectpad ==1,
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
                              onmouseclick = function() DATA2:Actions_Pad_SoloMute(note,_,true) end,
                              }    
                              
      padID0 = padID0 + 1
    end
  end
  -----------------------------------------------------------------------  
  function DATA2:Actions_Pad_ShowME(note, layer) 
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
  function DATA2:Actions_Pad_SoloMute(note,layer,solo, mute)
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
    
    GUI_MODULE_DRUMRACK(DATA)  
    GUI_MODULE_DEVICE(DATA)  
      
  end  
  ----------------------------------------------------------------------- 
  function DATA2:internal_FormatMIDIPitch(note) 
    do return VF_GetNoteStr(note-(DATA2.REAPERini.REAPER.midioctoffs or 0 )*2+4,DATA.extstate.UI_keyformat_mode) end
    --[[local val = math.floor(note)
    local oct = math.floor(note / 12)
    local note = math.fmod(note,  12)
    local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
    if note and oct and key_names[note+1] then return key_names[note+1]..oct-2 end]]
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadOnFileDrop_AddMIDISend(new_tr) 
    -- make sure MIDI bus exist
    if not new_tr then return end
    DATA2:TrackDataRead_ValidateMIDIbus()
    
    if DATA2.MIDIbus.ptr then 
      local sendidx = CreateTrackSend( DATA2.MIDIbus.ptr, new_tr )
      SetTrackSendInfo_Value( DATA2.MIDIbus.ptr, 0, sendidx, 'I_SRCCHAN',-1 )
      SetTrackSendInfo_Value( DATA2.MIDIbus.ptr, 0, sendidx, 'I_MIDIFLAGS',0 )
    end
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
  function DATA2:Actions_PadOnFileDrop_ExportToRS5k_CopySrc(filepath)
    local prpath = reaper.GetProjectPathEx( 0 )
    local filepath_path = GetParentFolder(filepath)
    local filepath_name = VF_GetShortSmplName(filepath)
    if prpath and filepath_path and filepath_name then
      prpath = prpath..'/RS5kmanager_samples/'
      RecursiveCreateDirectory( prpath, 0 )
      local src = filepath
      local dest = prpath..filepath_name
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
    return filepath
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
    if DATA.extstate.CONF_onadd_copytoprojectpath == 1 then 
      filepath = DATA2:Actions_PadOnFileDrop_ExportToRS5k_CopySrc(filepath)
    end 
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
      if DATA.extstate.CONF_onadd_renametrack==1 then GetSetMediaTrackInfo_String( new_tr, 'P_NAME', filepath_sh, true ) end
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_Pad_InitSamplesFromDB_ParseList(list_fp)
    local t = {}
    local fullfp =  reaper.GetResourcePath()..'/MediaDB/'..list_fp
    if  not  file_exists( fullfp ) then return end
    local f =io.open(fullfp,'rb')
    local content = ''
    if f then  content = f:read('a') end f:close()
    
    for line in content:gmatch('[^\r\n]+') do
      if line:match('FILE %"(.-)%"') then
        t [#t+1] = line:match('FILE %"(.-)%"')
      end 
    end
    
    return t
    
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_Pad_InitSamplesFromDB()
    if not DATA2.tr_valid then return end
    if not (DATA2.database_map and DATA2.database_map.valid and DATA2.database_map.map) then return end
    for note in pairs(DATA2.database_map.map)  do
      local lock = DATA2.database_map.map [note].lock or 0
      if lock~= 1 then
        local samples_t = DATA2.database_map.map[note].samples
        if samples_t and #samples_t > 0 then
          local randID = VF_lim(math.floor(math.random()*#samples_t),1,#samples_t)
          local new_sample = samples_t[randID]
          DATA2:Actions_PadOnFileDrop_Sub(note,1,new_sample)
        end
      end
    end
    -- 
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_Pad_Clear(note, layer)  
    if not DATA2.notes[note] then return end 
    
    reaper.Undo_BeginBlock2( 0)
    local  tr_ptr
    if DATA2.notes[note].TYPE_DEVICE then 
      -- remove device with layers
      if DATA2.notes[note].layers then 
        for layerID = 1, #DATA2.notes[note].layers do
          if not layer or (layer and layer==layerID) then
            tr_ptr = DATA2.notes[note].layers[layerID].tr_ptr 
            if tr_ptr and ValidatePtr2(0,tr_ptr, 'MediaTrack*')then DeleteTrack( tr_ptr) end
          end
        end
      end
      if not layer then 
        tr_ptr = DATA2.notes[note].tr_ptr 
        if tr_ptr and ValidatePtr2(0,tr_ptr, 'MediaTrack*')then DeleteTrack( tr_ptr) end
      end
     else 
     
      -- remove regular child
      tr_ptr = DATA2.notes[note].layers[1].tr_ptr 
      if tr_ptr and ValidatePtr2(0,tr_ptr, 'MediaTrack*')then DeleteTrack( tr_ptr) end
      
    end
    
    -- clear note names
    DATA2.FORCEONPROJCHANGE = true
    if not layer then 
      SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, '')
      -- set parent track selected
      reaper.SetOnlyTrackSelected( DATA2.tr_ptr )
    end
    reaper.Undo_EndBlock2( 0, 'RS5k manager: clear layer', 0xFFFFFFFF ) --reaper.Undo_BeginBlock2( 0)
  end 
  -----------------------------------------------------------------------
  function DATA2:Actions_Pad_UpdateNote(note, newnote)
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
  function DATA2:Actions_Pad_CopyMove(padsrc,paddest, iscopy) 
    if not (padsrc and paddest) then return end 
    if padsrc == paddest then return end
    
    reaper.Undo_BeginBlock2( 0)
    if not iscopy then 
      if DATA2.notes[paddest] then DATA2:Actions_Pad_UpdateNote(paddest, padsrc) end
    --[[ remove old pad
      DATA2:Actions_Pad_Clear(paddest)]]
    -- refresh external states
      DATA2:Actions_Pad_UpdateNote(padsrc, paddest) 
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
    GUI_MODULE_DRUMRACK(DATA) 
    reaper.Undo_EndBlock2( 0, 'RS5k manager: copy/move layer', 0xFFFFFFFF ) --reaper.Undo_BeginBlock2( 0)
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_Pad_Rename(note,layer) 
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
  function DATA2:Actions_Pad_Menu(note) 
    if not DATA2.tr_valid then return end
    local t = { 
      {str='Rename pad',
        func=function() DATA2:Actions_Pad_Rename(note) end },  
      {str='Clear pad',
        func=function() DATA2:Actions_Pad_Clear(note) end },  
      {str='|Import selected items to pads, starting this pad',
        func=function() DATA2:Actions_ImportSelectedItems(note) end },      
      {str='Move pad to last recent incoming note',
        func=function() 
                local notedest = DATA2.playingnote_pitch
                if not notedest then return end
                DATA2:Actions_Pad_CopyMove(note,notedest) 
                
              end },
     
         
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
    if not DATA2.tr_valid == true then return end
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
      local filepath_sh = GetShortSmplName(filepath) if filepath_sh:match('(.*)%.[%a]+') then filepath_sh = filepath_sh:match('(.*)%.[%a]+') end 
        SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, filepath_sh)  
        SetTrackMIDINoteNameEx( 0,new_tr, note, -1, filepath_sh)  
        
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
      --GUI_MODULE_DRUMRACK(DATA)  
      --GUI_MODULE_SAMPLER(DATA)
  end
  -----------------------------------------------------------------------------  
  
  function GUI_MODULE_DEVICE_stuff(DATA, note, layer, y_offs) 
    local x_offs = DATA.GUI.buttons.devicestuff_frame.x--+DATA.GUI.custom_offset
    local w_layername = math.floor(DATA.GUI.buttons.devicestuff_frame.w*0.5)
    local w_ctrls = DATA.GUI.buttons.devicestuff_frame.w - w_layername
    local w_ctrls_single = (w_ctrls / 9)
    local w_ctrls_single_q = math.floor(w_ctrls / 9)
    local frame_a = 0
    local backgr_col=DATA.GUI.custom_backcol2
    local backgr_fill_param = 0.2 
    local backgr_fill_name = 0
    
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'close'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_ctrls_single,
                        h=DATA.GUI.custom_deviceentryh,
                        --ignoremouse = DATA2.PARENT_TABSTATEFLAGS&2==0,
                        txt = 'X',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        frame_a = DATA.GUI.custom_framea,
                        onmouseclick = function() 
                          DATA2:Actions_Pad_Clear(note, layer) 
                        end,
                        }
                        
    if DATA2.PARENT_LASTACTIVENOTE_layer and DATA2.PARENT_LASTACTIVENOTE_layer == layer then 
      backgr_fill_name = DATA.GUI.custom_backfill2 
    end
    -- name
    x_offs = x_offs + w_ctrls_single
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'name'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_layername,
                        h=DATA.GUI.custom_deviceentryh,
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
    x_offs = x_offs + w_layername
    if DATA2.notes[note].layers[layer].tr_vol then val= DATA2.notes[note].layers[layer].tr_vol/2 end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'vol'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_ctrls_single*3-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh,
                        val = val,
                        val_res = -0.1,
                        val_xaxis = true,
                        txt = DATA2.notes[note].layers[layer].tr_vol_format,
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        frame_a = DATA.GUI.custom_framea,
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
    x_offs = x_offs + w_ctrls_single*3
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'pan'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_ctrls_single*2-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh,
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
                        frame_a = DATA.GUI.custom_framea,
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
    x_offs = x_offs + w_ctrls_single*2                  
    local backgr_fill_param_en
    if DATA2.notes[note].layers[layer].instrument_enabled == true then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'enable'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_ctrls_single-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        frame_a = DATA.GUI.custom_framea,
                        txt = 'On',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        onmouserelease = function()
                              local src_t = DATA2.notes[note].layers[layer] 
                              local newval = 1 if src_t.instrument_enabled == true then newval = 0 end
                              reaper.TrackFX_SetEnabled( src_t.tr_ptr, src_t.instrument_pos, newval )
                              DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
                            end,
                        }     
    x_offs = x_offs + w_ctrls_single                    
    local backgr_fill_param_en
    if DATA2.notes and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[layer].tr_solo and DATA2.notes[note].layers[layer].tr_solo >0 then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'solo'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_ctrls_single-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_deviceentryh,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        frame_a = DATA.GUI.custom_framea,
                        txt = 'S',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        onmouserelease = function()DATA2:Actions_Pad_SoloMute(note,layer,true) end,
                        }   
    local backgr_fill_param_en
    x_offs = x_offs + w_ctrls_single
    if DATA2.notes and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[layer].tr_mute and DATA2.notes[note].layers[layer].tr_mute >0 then backgr_fill_param_en = backgr_fill_param end
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'mute'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_ctrls_single,
                        h=DATA.GUI.custom_deviceentryh,
                        backgr_fill2 = backgr_fill_param_en,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        frame_a = DATA.GUI.custom_framea,
                        txt = 'M',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        onmouserelease = function() DATA2:Actions_Pad_SoloMute(note,layer,_, true)end,
                        }                         
  end
  ----------------------------------------------------------------------------- 
  function GUI_MODULE_DATABASE_Menu(DATA)
    local name1, t1 = '[empty]', DATA2:Database_Load(DATA.extstate.CONF_database_map1) if t1 and t1.dbname then name1 = t1.dbname end
    local name2, t2 = '[empty]', DATA2:Database_Load(DATA.extstate.CONF_database_map2) if t2 and t2.dbname then name2 = t2.dbname end
    local name3, t3 = '[empty]', DATA2:Database_Load(DATA.extstate.CONF_database_map3) if t3 and t3.dbname then name3 = t3.dbname end
    local name4, t4 = '[empty]', DATA2:Database_Load(DATA.extstate.CONF_database_map4) if t4 and t4.dbname then name4 = t4.dbname end
    
    
    
    DATA:GUImenu({
    
    {str = 'Clear current database map',
     func = function() 
              DATA2.database_map = {}
              DATA2:TrackDataWrite(_, {master_upd=true})
              DATA.UPD.onGUIinit = true
            end},
    {str = '|Save current database map to slot1',
     func = function() 
              local retval, retname = GetUserInputs('Database map name', 1, '', DATA2.database_map.dbname or '' )
              if retval then 
                DATA2.database_map.dbname = retname
                DATA.extstate.CONF_database_map1 = DATA2:Database_Save()
                DATA.UPD.onconfchange = true
              end
            end},          
    {str = 'Save current database map to slot2',
     func = function() 
              local retval, retname = GetUserInputs('Database map name', 1, '', DATA2.database_map.dbname or '' )
              if retval then 
                DATA2.database_map.dbname = retname
                DATA.extstate.CONF_database_map2 = DATA2:Database_Save()
                DATA.UPD.onconfchange = true
              end
            end},  
    {str = 'Save current database map to slot3',
     func = function() 
              local retval, retname = GetUserInputs('Database map name', 1, '', DATA2.database_map.dbname or '' )
              if retval then 
                DATA2.database_map.dbname = retname
                DATA.extstate.CONF_database_map3 = DATA2:Database_Save()
                DATA.UPD.onconfchange = true
              end
            end},  
    {str = 'Save current database map to slot4',
     func = function() 
              local retval, retname = GetUserInputs('Database map name', 1, '', DATA2.database_map.dbname or '' )
              if retval then 
                DATA2.database_map.dbname = retname
                DATA.extstate.CONF_database_map4 = DATA2:Database_Save()
                DATA.UPD.onconfchange = true
              end
            end}, 
    {str = '|Save current database map as default',
     func = function() 
              DATA.extstate.CONF_database_map_default = DATA2:Database_Save()
              DATA.UPD.onconfchange = true
            end},             
    {str = 'Clear default database map',
     func = function() 
              DATA.extstate.CONF_database_map_default = ''
              DATA.UPD.onconfchange = true
            end},
            
    {str = '|#Load database map slot:'},         
    {str = name1,
     func = function() 
              DATA2.PARENT_DATABASEMAP = DATA.extstate.CONF_database_map1
              DATA2:Database_Load()
              DATA2:TrackDataWrite(_, {master_upd=true})
              DATA2:TrackDataRead()
              DATA.UPD.onGUIinit = true
            end},       
    {str = name2,
     func = function() 
              DATA2.PARENT_DATABASEMAP = DATA.extstate.CONF_database_map2
              DATA2:Database_Load()
              DATA2:TrackDataWrite(_, {master_upd=true})
              DATA2:TrackDataRead()
              DATA.UPD.onGUIinit = true
            end},     
    {str = name3,
     func = function() 
              DATA2.PARENT_DATABASEMAP = DATA.extstate.CONF_database_map3
              DATA2:Database_Load()
              DATA2:TrackDataWrite(_, {master_upd=true})
              DATA2:TrackDataRead()
              DATA.UPD.onGUIinit = true
            end},  
    {str = name4,
     func = function() 
              DATA2.PARENT_DATABASEMAP = DATA.extstate.CONF_database_map4
              DATA2:Database_Load()
              DATA2:TrackDataWrite(_, {master_upd=true})
              DATA2:TrackDataRead()
              DATA.UPD.onGUIinit = true
            end},              
    })
    
    
  end
  ----------------------------------------------------------------------------- 
  function GUI_MODULE_DATABASE(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('databasestuff') then DATA.GUI.buttons[key] = nil end end
    local device_y = DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&32==0) then return end
    
    
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_database+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    local x_offs_padctrls= x_offs
    local dbname_w = DATA.GUI.custom_databasew-DATA.GUI.custom_infoh-DATA.GUI.custom_knob_button_w
    GUI_MODULE_separator(DATA, 'databasestuff_sep', DATA.GUI.custom_module_xoffs_database) 
     
    if not (DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE ~=-1) then return end   
    
    local dbname_global = '[not loaded]'
    if DATA2.database_map and DATA2.database_map.dbname then dbname_global = DATA2.database_map.dbname end
    
    
    
    DATA.GUI.buttons.databasestuff_newkit = { x=x_offs,
                         y=0,
                         w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'New kit',
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function()  
                                          if not DATA2.database_map.cached then DATA2:Database_Cache() end
                                          DATA2:Actions_Pad_InitSamplesFromDB() 
                                        end
                         }
    x_offs = x_offs + DATA.GUI.custom_knob_button_w
    DATA.GUI.buttons.databasestuff_name = { x=x_offs,
                         y=0,
                         w=dbname_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = dbname_global,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() GUI_MODULE_DATABASE_Menu(DATA)  end
                         }
    x_offs = x_offs + dbname_w
    DATA.GUI.buttons.databasestuff_help = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_infoh-1,
                           h=DATA.GUI.custom_infoh-1,
                           txt = '?',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() DATA2:Actions_Help(2) end,
                           }  
    
    
    
    
    -- pad ctrls
    local y_offs = DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    local ctrl_w = math.floor(DATA.GUI.custom_databasew/2) 
    local x_offs = x_offs_padctrls
    DATA.GUI.buttons.databasestuff_padname = { x=x_offs,
                         y=y_offs,
                         w=ctrl_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'Pad '..DATA2.PARENT_LASTACTIVENOTE..' name',
                         frame_a = 1,
                         frame_asel = 1,
                         frame_col = '#333333',
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() end
                         }
    local name = ''
    if DATA2.PARENT_LASTACTIVENOTE and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] then name = DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].notename end
    DATA.GUI.buttons.databasestuff_padname_name = { x=x_offs+ ctrl_w,
                         y=y_offs,
                         w=ctrl_w,
                         h=DATA.GUI.custom_infoh-1,
                         txt = name,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() 
                         
                          if not DATA2.database_map then DATA2.database_map = {} end
                          DATA2.database_map.valid = true
                          if not DATA2.database_map.map then DATA2.database_map.map = {} end
                          if not DATA2.database_map.dbname then DATA2.database_map.dbname = 'Untitled' end
                          if not DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] then DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] = {} end 
                          
                          local retval, retname = GetUserInputs( 'Pad '..DATA2.PARENT_LASTACTIVENOTE..' name', 1, '', DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].notename or '' )
                          if not (retval and retname ~='' ) then return end  
                          DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].notename = retname
                          DATA2:TrackDataWrite(_, {master_upd=true})
                          DATA2:TrackDataRead()
                          DATA.UPD.onGUIinit = true
                          
                         end
                         }  
    y_offs = y_offs  + DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    DATA.GUI.buttons.databasestuff_dbname = { x=x_offs,
                         y=y_offs,
                         w=ctrl_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'DB name',
                         frame_a = 1,
                         frame_asel = 1,
                         frame_col = '#333333',
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() end
                         }
    local dbname = ''
    if DATA2.PARENT_LASTACTIVENOTE and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] then dbname = DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].dbname end
    DATA.GUI.buttons.databasestuff_dbname_name = { x=x_offs+ctrl_w,
                         y=y_offs,
                         w=ctrl_w,
                         h=DATA.GUI.custom_infoh-1,
                         txt = dbname,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() 
                         
                          if not DATA2.database_map then DATA2.database_map = {} end
                          DATA2.database_map.valid = true
                          if not DATA2.database_map.map then DATA2.database_map.map = {} end
                          if not DATA2.database_map.dbname then DATA2.database_map.dbname = 'Untitled' end
                          if not DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] then DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] = {} end 
                          
                          local reaperDB = DATA2:Database_ParseREAPER_DB()  
                          if not reaperDB then 
                            DATA:GUImenu({
                                            {str = '[not found]'}
                                          })
                            else
                             local t = {}
                             for key in pairs(reaperDB) do
                              t[#t+1] = {
                                          str = key,
                                          func = function() 
                                                    DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].dbname = key
                                                    DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].dbflist = reaperDB[key]
                                                    DATA2:TrackDataWrite(_, {master_upd=true})
                                                    DATA2:TrackDataRead()
                                                    DATA2:Database_Load(DATA2.PARENT_DATABASEMAP, true) 
                                                    DATA.UPD.onGUIinit = true
                                            
                                          end,
                                          }
                             end
                             DATA:GUImenu(t)
                             
                          end
                         end
                         }
    y_offs = y_offs  + DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    DATA.GUI.buttons.databasestuff_lock = { x=x_offs,
                         y=y_offs,
                         w=ctrl_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'Lock',
                         frame_a = 1,
                         frame_asel = 1,
                         frame_col = '#333333',
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() end
                         }
    local lockstatename = 'Off'
    if DATA2.PARENT_LASTACTIVENOTE and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].lock and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].lock  == 1 then lockstatename = 'On' end
    DATA.GUI.buttons.databasestuff_lock_state = { x=x_offs+ctrl_w,
                         y=y_offs,
                         w=ctrl_w,
                         h=DATA.GUI.custom_infoh-1,
                         txt = lockstatename,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() 
                          if not DATA2.database_map then DATA2.database_map = {} end
                          DATA2.database_map.valid = true
                          if not DATA2.database_map.map then DATA2.database_map.map = {} end
                          if not DATA2.database_map.dbname then DATA2.database_map.dbname = 'Untitled' end
                          if not DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] then DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] = {} end 
                          
                          local lockstate = DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].lock or 0
                          DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].lock = lockstate~1
                          DATA2:TrackDataWrite(_, {master_upd=true})
                          DATA2:TrackDataRead()
                          DATA.UPD.onGUIinit = true
                         end
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
    
    
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_device+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    local x_offs_ctrls = x_offs
    local devname_w = DATA.GUI.custom_devicew-DATA.GUI.custom_infoh-DATA.GUI.custom_knob_button_w
    GUI_MODULE_separator(DATA, 'devicestuff_sep', DATA.GUI.custom_module_xoffs_device) 
    local device_y = DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    
    DATA.GUI.buttons.devicestuff_name = { x=x_offs,
                         y=0,
                         w=devname_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = name,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() DATA2:Actions_Pad_Menu(DATA2.PARENT_LASTACTIVENOTE) end
                         }
    x_offs = x_offs + devname_w    
    local txt_a = nil
    if DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].TYPE_DEVICE ~= true then txt_a = DATA.GUI.custom_framea end
    DATA.GUI.buttons.devicestuff_showtrack = { x=x_offs,
                         y=0,
                         w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'FX',
                         txt_a=txt_a,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function()
                                          if DATA2.notes[DATA2.PARENT_LASTACTIVENOTE] and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].tr_ptr then
                                            TrackFX_Show( DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].tr_ptr, -1, 1 )
                                          end
                                        end
                         }                         
                         
                         
                         
      x_offs = x_offs + DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons.devicestuff_help = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_infoh,
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
    
                     
    local x_offs = x_offs_ctrls
    DATA.GUI.buttons.devicestuff_frame = { x=x_offs,
                          y=device_y,
                          w=DATA.GUI.custom_devicew,
                          h=DATA.GUI.custom_deviceh+DATA.GUI.custom_offset,
                          ignoremouse = true,
                          frame_a =1,
                          frame_col = '#333333',
                          backgr_fill = 0,
                          hide=true,
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
    DATA.GUI.buttons.devicestuff_droparea = { x=x_offs,
                          y=y_offs+DATA.GUI.custom_offset*2,
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
    
      -- handle col
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
      
      
      if note%4 == 0 then x_offs = math.floor(DATA.GUI.buttons.padgrid.x) end
      local reduce = 1
      if cellside < 20 then reduce =0 end
      DATA.GUI.buttons['padgrid_but'..note] = { x=  x_offs,
                          y=math.floor(DATA.GUI.custom_padgridy+DATA.GUI.custom_padgridh - cellside*(1+(math.floor(note/4)))),
                          w=cellside-reduce,
                          h=cellside-reduce,
                          ignoremouse = true,
                          --txt = note,
                          backgr_col2 = blockcol,
                          frame_a = 0.1,
                          frame_col = blockcol,
                          txt_fontsz = 10,
                          backgr_fill2 = backgr_fill2,
                          --onmouseclick =  function() end,
                          refresh = true
                          }
      x_offs = x_offs + cellside
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
    
  function GUI_MODULE_PADOVERVIEW (DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('padgrid') then DATA.GUI.buttons[key] = nil end end
    for key in pairs(DATA.GUI.buttons) do if key:match('padgrid_but') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&8==0) then return end
    
    
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_padoverview+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    GUI_MODULE_separator(DATA, 'padgrid_sep', DATA.GUI.custom_module_xoffs_padoverview) 
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
                                            GUI_MODULE_DRUMRACK(DATA)  
                                          end,
                          onmousedrag =   function() 
                                            if DATA.GUI.buttons.padgrid.val_abs then 
                                              local new = VF_lim(math.floor((1-DATA.GUI.buttons.padgrid.val_abs)*9) ,0,9) 
                                              if new ~= DATA2.PARENT_ACTIVEPAD then 
                                                DATA2.PARENT_ACTIVEPAD = new 
                                                DATA.GUI.buttons.padgrid_activerect.refresh = true
                                                GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                                GUI_MODULE_DRUMRACK(DATA)  
                                              end
                                            end
                                          end,
                          onmouserelease = function() 
                                            DATA2.PARENT_ACTIVEPAD = VF_lim(math.floor((1-DATA.GUI.buttons.padgrid.val_abs)*9) ,0,9) 
                                            DATA.GUI.buttons.padgrid_activerect.refresh = true
                                            GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                            GUI_MODULE_DRUMRACK(DATA)  
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
     --[[ DATA.GUI.buttons.padgrid_help = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_padgridw-1,
                           h=DATA.GUI.custom_infoh-1,
                           txt = '?',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() 
                                              DATA2:Actions_Help(3)
                                            end,
                           }   ]]                       
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
  function DATA2:Actions_Sampler_Menu_SetStartToLoudestPeak() 
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
  function DATA2:Actions_Sampler_Menu_CropToAudibleBoundaries()
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
  function  DATA2:Actions_Sampler_Menu()  
    local t = {
              
  {str = '#Actions'},
  {str = 'Crop sample to audible boundaries, threshold '..DATA.extstate.CONF_cropthreshold..'dB',
   func = function() DATA2:Actions_Sampler_Menu_CropToAudibleBoundaries()   end},

  {str = 'Set start offset to a loudest peak',
   func = function() DATA2:Actions_Sampler_Menu_SetStartToLoudestPeak()   end},
   
  
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
      gfx.y = y0+h - math.abs(math.floor(val*h))-1
      --gfx.rect(x_dest,y,1,hrect)
      gfx.lineto(x_dest, y0+h-1)
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
  function GUI_MODULE_SAMPLER_Section_Actions(DATA)  
    local actions_cnt = 3
    local action_h = math.floor(DATA.GUI.custom_sampler_peakareah / actions_cnt)
    local x_offs = DATA.GUI.buttons.sampler_frame.x +DATA.GUI.custom_samplerW-DATA.GUI.custom_knob_button_w
    local y_offs = DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset
    local src_t = DATA2:internal_GetActiveNoteLayerTable()
    if not src_t then return end
    DATA.GUI.buttons.sampler_prevspl = { x=x_offs ,
                        y=y_offs,
                        w=DATA.GUI.custom_knob_button_w,
                        h=action_h-DATA.GUI.custom_offset,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = 'Prev spl',
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouseclick = function() DATA2:Actions_Sampler_NextPrevSample(src_t, 1)  end,
                        }  
    y_offs = y_offs + action_h 
    DATA.GUI.buttons.sampler_nextspl = { x=x_offs ,
                        y=y_offs,
                        w=DATA.GUI.custom_knob_button_w,
                        h=action_h-DATA.GUI.custom_offset,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = 'Next spl',
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouseclick = function() DATA2:Actions_Sampler_NextPrevSample(src_t)  end,
                        }                          
    y_offs = y_offs + action_h
    DATA.GUI.buttons.sampler_randspl = { x=x_offs ,
                        y=y_offs,
                        w=DATA.GUI.custom_knob_button_w,
                        h=action_h,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = 'Rand spl',
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouseclick = function() DATA2:Actions_Sampler_NextPrevSample(src_t, 2)  end,
                        }                         
                        
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
                        w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
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
                        w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
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
    
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_sampler+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    GUI_MODULE_separator(DATA, 'sampler_sep', DATA.GUI.custom_module_xoffs_sampler) 
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
                           w=DATA.GUI.custom_sampler_namebutw-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = name,
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           }
      x_offs = x_offs+DATA.GUI.custom_sampler_namebutw                   
      DATA.GUI.buttons.Actions_Sampler_Menu = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'Actions',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function()  DATA2:Actions_Sampler_Menu()  end,
                           }  
      x_offs = x_offs+DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons.sampler_show = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'FX',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() 
                                              --DATA2:Actions_ShowInstrument(note, layer) 
                                              TrackFX_Show( spl_t.tr_ptr, spl_t.instrument_pos, 1 ) 
                                            end,
                           }
      x_offs = x_offs+DATA.GUI.custom_knob_button_w--DATA.GUI.custom_infoh
      DATA.GUI.buttons.sampler_help = { x=x_offs,
                           y=0,
                           w=DATA.GUI.custom_infoh,
                           h=DATA.GUI.custom_infoh-1,
                           txt = '?',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() 
                                              DATA2:Actions_Help(4)
                                            end,
                           }                           
                           
                           
                           
    local txt = ''
    if not spl_t.ISRS5K then txt = '['..spl_t.instrument_fxname..']' end
    DATA.GUI.buttons.sampler_framepeaks = { x= DATA.GUI.buttons.sampler_frame.x + DATA.GUI.custom_knob_button_w,
                            y=DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_samplerW - DATA.GUI.custom_knob_button_w*2-DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_sampler_peakareah,
                            --ignoremouse = true,
                            txt = txt,
                            frame_a = DATA.GUI.custom_framea,
                            data = {['datatype'] = 'samplepeaks'},
                            onmousefiledrop = function() if DATA2.PARENT_LASTACTIVENOTE then DATA2:Actions_PadOnFileDrop(DATA2.PARENT_LASTACTIVENOTE) end end,
                            onmouseclick = function() if DATA2.PARENT_LASTACTIVENOTE then DATA2:Actions_StuffNoteOn(DATA2.PARENT_LASTACTIVENOTE) end  end,
                            onmouseclickR = function() DATA2:Actions_Sampler_Menu()  end,
                            refresh = true,
                            }
    
    GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
    GUI_MODULE_SAMPLER_Section_Actions(DATA)
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
                        frame_a =t.frame_a or DATA.GUI.custom_framea,
                        --frame_col = '#333333',
                        backgr_col = '#333333',
                        backgr_fill = 1,
                        back_sela = 0,
                        
                        frame_arcborder = true,
                        frame_arcborderr = math.floor(DATA.GUI.custom_offset*2),
                        frame_arcborderflags = t.frame_arcborderflags or 1|2|4|8,
                        
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
                                if params_t.func_atrelease then params_t.func_atrelease() end
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
                                if params_t.func_atrelease then params_t.func_atrelease() end
                        end,  
                        } 
    if t.h > DATA.GUI.custom_module_ctrlreadout_h * 1.9  then                               
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
    end
    
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
    if t.h < DATA.GUI.custom_module_ctrlreadout_h * 1.9   then 
      DATA.GUI.buttons[t.butkey..'val'].y = t.y +1
      DATA.GUI.buttons[t.butkey..'val'].h = t.h-2
    end
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
    if not DATA.GUI.buttons.sampler_frame then return end
    local src_t = DATA2:internal_GetActiveNoteLayerTable()
    
    local val_res = 0.03
    local woffs= DATA.GUI.custom_knob_button_w+DATA.GUI.custom_offset
    local xoffs= DATA.GUI.buttons.sampler_frame.x
    local yoffs= DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_sampler_peakareah+DATA.GUI.custom_offset*2
    local w_tune_single = math.floor(woffs/3)
    local h_tune_single = math.floor(DATA.GUI.custom_module_ctrlreadout_h*2/3)
    xoffs = xoffs + 0 
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_gain',
        
        x = DATA.GUI.buttons.sampler_frame.x,
        y= yoffs,
        w = DATA.GUI.custom_knob_button_w,
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
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_module_ctrlreadout_h*2,
        
        ctrlname = 'Tune',
        ctrlval_key = 'instrument_tune',
        ctrlval_format_key = 'instrument_tune_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.01,
        ctrlval_default = 0.5,
        frame_arcborderflags = 1|8,
        
        func_atclick   =        function(new_val) 
                                  local new_val_quant = math.floor(new_val*160)/160 
                                  DATA2.TEMPnew_val_diff = new_val - new_val_quant
                                end,
        func_app =            function(new_val) 
                                --if not DATA.GUI.Ctrl then
                                  TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, new_val ) 
                                 --[[else
                                  local new_val_quant = math.floor(new_val*160)/160 
                                  local val = new_val
                                  if DATA2.TEMPnew_val_diff then val = new_val_quant + DATA2.TEMPnew_val_diff end
                                  TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, val ) 
                                  
                                --end]]
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t) end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.instrument_pos, 15) 
                                return new_val
                              end
       } )   
       
    if src_t.ISRS5K then   
      --xoffs = xoffs + woffs   
      DATA.GUI.buttons['sampler_tune_centup'] = { x= xoffs+woffs,--+arc_shift,
                          y=yoffs,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = '+',
                          frame_a = DATA.GUI.custom_framea,
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          onmouserelease = function()
                            local inc = 0.05
                            local tunenorm = src_t.instrument_tune
                            local tunereal = tunenorm * 160 - 80
                            tunereal = tunereal +inc
                            tunenorm = (tunereal+80) / 160
                            TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, tunenorm )
                            DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
                          end
                          }
      DATA.GUI.buttons['sampler_tune_centval'] = { x= xoffs+woffs,--+arc_shift,
                          y=yoffs+h_tune_single,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = '.05',
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          frame_a = 0,
                          }
      DATA.GUI.buttons['sampler_tune_centdown'] = { x= xoffs+woffs,--+arc_shift,
                          y=yoffs+h_tune_single*2,
                          w=w_tune_single-1,
                          h=h_tune_single+1,
                          frame_a = DATA.GUI.custom_framea,
                          txt = '-',
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          onmouserelease = function()
                            local inc = -0.05
                            local tunenorm = src_t.instrument_tune
                            local tunereal = tunenorm * 160 - 80
                            tunereal = tunereal +inc
                            tunenorm = (tunereal+80) / 160
                            TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, tunenorm )
                            DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
                          end
                          }                        
      DATA.GUI.buttons['sampler_tune_stup'] = { x= xoffs+woffs+w_tune_single,--+arc_shift,
                          y=yoffs,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = '+',
                          frame_a = DATA.GUI.custom_framea,
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          onmouserelease = function()
                            local inc = 1
                            local tunenorm = src_t.instrument_tune
                            local tunereal = tunenorm * 160 - 80
                            tunereal = tunereal +inc
                            tunenorm = (tunereal+80) / 160
                            TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, tunenorm )
                            DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
                          end
                          }
      DATA.GUI.buttons['sampler_tune_stval'] = { x= xoffs+woffs+w_tune_single,--+arc_shift,
                          y=yoffs+h_tune_single,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = 'st',
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          frame_a = 0,
                          }
      DATA.GUI.buttons['sampler_tune_stdown'] = { x= xoffs+woffs+w_tune_single,--+arc_shift,
                          y=yoffs+h_tune_single*2,
                          w=w_tune_single-1,
                          h=h_tune_single+1,
                          frame_a = DATA.GUI.custom_framea,
                          txt = '-',
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          onmouserelease = function()
                            local inc = -1
                            local tunenorm = src_t.instrument_tune
                            local tunereal = tunenorm * 160 - 80
                            tunereal = tunereal +inc
                            tunenorm = (tunereal+80) / 160
                            TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, tunenorm )
                            DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
                          end
                          }                         
      DATA.GUI.buttons['sampler_tune_octup'] = { x= xoffs+woffs+w_tune_single*2,
                          y=yoffs,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = '+',
                          frame_a = DATA.GUI.custom_framea,
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          onmouserelease = function()
                            local inc = 12
                            local tunenorm = src_t.instrument_tune
                            local tunereal = tunenorm * 160 - 80
                            tunereal = tunereal +inc
                            tunenorm = (tunereal+80) / 160
                            TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, tunenorm )
                            DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
                          end
                          }
      DATA.GUI.buttons['sampler_tune_octval'] = { x= xoffs+woffs+w_tune_single*2,
                          y=yoffs+h_tune_single,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = 'oct',
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          frame_a = 0,
                          }
      DATA.GUI.buttons['sampler_tune_octdown'] = { x= xoffs+woffs+w_tune_single*2,
                          y=yoffs+h_tune_single*2,
                          w=w_tune_single-1,
                          h=h_tune_single+1,
                          frame_a = DATA.GUI.custom_framea,
                          txt = '-',
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          onmouserelease = function()
                            local inc = -12
                            local tunenorm = src_t.instrument_tune
                            local tunereal = tunenorm * 160 - 80
                            tunereal = tunereal +inc
                            tunenorm = (tunereal+80) / 160
                            TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, tunenorm )
                            DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
                          end
                          }
                          
    end
    xoffs = xoffs + woffs*2
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_samplestoffs',
        
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_knob_button_w,
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
                                local ret = DATA2:internal_ParsePercent(str_ret)
                                if ret then 
                                  local new_val = VF_BFpluginparam(ret, src_t.tr_ptr, src_t.instrument_pos, 13) 
                                  return new_val
                                end
                                
                              end
       } )        

    xoffs = xoffs + woffs 
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_sampleendoffs',
        
        x = xoffs,
        y= yoffs,
        w = DATA.GUI.custom_knob_button_w,
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
                                local ret = DATA2:internal_ParsePercent(str_ret)
                                if ret then 
                                  local new_val = VF_BFpluginparam(ret, src_t.tr_ptr, src_t.instrument_pos, 14) 
                                  return new_val
                                end
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
        w = DATA.GUI.custom_knob_button_w,
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
        w = DATA.GUI.custom_knob_button_w,
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
      
  end
  -----------------------------------------------------------------------  
  function DATA2:TrackData_InitMacro(is_child_slave, srct)
    if DATA2.Macro.isvalid == true and not is_child_slave then return end
    
    local fxname = 'mpl_RS5k_manager_MacroControls.jsfx'
    
    if not is_child_slave then
      local macroJSFX_pos =  TrackFX_AddByName( DATA2.tr_ptr, fxname, false, 0 )
      if macroJSFX_pos == -1 then
        macroJSFX_pos =  TrackFX_AddByName( DATA2.tr_ptr, fxname, false, -1000 ) 
        local macroJSFX_fxGUID = reaper.TrackFX_GetFXGUID( DATA2.tr_ptr, macroJSFX_pos ) 
        DATA2:TrackDataWrite(DATA2.tr_ptr, {MACRO_GUID=macroJSFX_fxGUID}) 
        TrackFX_Show( DATA2.tr_ptr, macroJSFX_pos, 0|2 )
        for i = 1, 16 do TrackFX_SetParamNormalized( DATA2.tr_ptr, macroJSFX_pos, 33+i, i/1024 ) end -- ini source gmem IDs
      end
      if macroJSFX_pos == -1 then MB('RS5k manager_MacroControls JSFX is missing. Make sure you installed it correctly via ReaPack.', '', 0) end
      return macroJSFX_pos
    end
    
    
    -- child_mode
    if not srct then return end
    if not srct.macro_pos then
      macroJSFX_pos =  TrackFX_AddByName( srct.tr_ptr, fxname, false, -1000 )
      if macroJSFX_pos == -1 then MB('RS5k manager_MacroControls JSFX is missing. Make sure you installed it correctly via ReaPack.', '', 0) end
      local macroJSFX_fxGUID = reaper.TrackFX_GetFXGUID( srct.tr_ptr, macroJSFX_pos )  
      TrackFX_Show( srct.tr_ptr, macroJSFX_pos, 0|2 )
      TrackFX_SetParamNormalized( srct.tr_ptr, macroJSFX_pos, 0, 1 ) -- set mode to slave
      for i = 1, 16 do TrackFX_SetParamNormalized( srct.tr_ptr, macroJSFX_pos, 17+i, i/1024 ) end -- ini source gmem IDs
      DATA2:TrackDataWrite(srct.tr_ptr, {MACRO_GUID=macroJSFX_fxGUID})
      srct.macro_pos = macroJSFX_pos
      return macroJSFX_pos
    end
    
  end
  -----------------------------------------------------------------------  
  function DATA2:TrackData_InitFilterDrive(note_layer_t) 
    local track = note_layer_t.tr_ptr
    if not note_layer_t.fx_reaeq_isvalid then 
      local reaeq_pos = TrackFX_AddByName( track, 'ReaEQ', 0, 1 )
      TrackFX_Show( track, reaeq_pos, 2 )
      TrackFX_SetNamedConfigParm( track, reaeq_pos, 'BANDTYPE0',3 )
      TrackFX_SetParamNormalized( track, reaeq_pos, 0, 1 )
      local GUID = reaper.TrackFX_GetFXGUID( track, reaeq_pos )
      DATA2:TrackDataWrite(track, {FX_REAEQ_GUID = GUID}) 
      DATA2:TrackDataRead()
      GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
    end
     
    if not note_layer_t.fx_ws_isvalid then
      local ws_pos = TrackFX_AddByName( track, 'waveShapingDstr', 0, 1 )--'Distortion\\waveShapingDstr'
      TrackFX_Show( track, ws_pos, 2 )
      TrackFX_SetParamNormalized( track, ws_pos, 0, 0 )
      local GUID = reaper.TrackFX_GetFXGUID( track, ws_pos )
      DATA2:TrackDataWrite(track, {FX_WS_GUID = GUID}) 
      DATA2:TrackDataRead()
      GUI_MODULE_SAMPLER_Section_FilterSection(DATA)
    end
  end
  ------------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
    if not DATA.GUI.buttons.sampler_frame then return end
    local src_t = DATA2:internal_GetActiveNoteLayerTable()
    local filt_rect_h = (DATA.GUI.custom_sampler_knob_h / 3)
    local y_offs = DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_sampler_peakareah+DATA.GUI.custom_offset*3+DATA.GUI.custom_module_ctrlreadout_h*2
    local x_offs= DATA.GUI.buttons.sampler_frame.x
    DATA.GUI.buttons.sampler_spl_reaeq_togglename = { 
                        x = x_offs,
                        y=y_offs,
                        w = DATA.GUI.custom_knob_button_w,
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
                        w = DATA.GUI.custom_knob_button_w,
                        h = filt_rect_h-DATA.GUI.custom_offset,
                        --ignoremouse = true,
                        txt = reaeqstate,
                        txt_a = reaeqstate_a,
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        frame_a =DATA.GUI.custom_framea,
                        --state = src_t.fx_reaeq_bandenabled,
                        onmouserelease = function() 
                          if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then 
                            DATA2:TrackData_InitFilterDrive(src_t) 
                            DATA2:TrackDataRead_GetChildrens_FXParams(src_t)
                            GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                          end 
                          if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then return end -- if reaeq insertion failed
                          
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
                        w = DATA.GUI.custom_knob_button_w,
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
                                                  if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then 
                                                    DATA2:TrackData_InitFilterDrive(src_t) 
                                                    DATA2:TrackDataRead_GetChildrens_FXParams(src_t) 
                                                    GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                                                  end
                                                  if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then return end -- if reaeq insertion failed
                                                  
                                                  TrackFX_SetNamedConfigParm( src_t.tr_ptr, src_t.fx_reaeq_pos, 'BANDTYPE0', key ) 
                                                  DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  
                                                  GUI_MODULE_SAMPLER_Section_FilterSection(DATA) 
                                                end
                                      }
                          end
                          DATA:GUImenu(t)
                        end
                        }   
    x_offs = x_offs + DATA.GUI.custom_knob_button_w + DATA.GUI.custom_offset
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_fx_reaeq_cut',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_sampler_knob_h,
        
        ctrlname = 'Freq',
        ctrlval_key = 'fx_reaeq_cut',
        ctrlval_format_key = 'fx_reaeq_cut_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default = 0.95,
        
        func_app =            function(new_val) 
                                if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then 
                                  DATA2:TrackData_InitFilterDrive(src_t) 
                                  DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  
                                  GUI_MODULE_SAMPLER_Section_FilterSection(DATA) 
                                end 
                                --if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then return end -- if reaeq insertion failed
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.fx_reaeq_pos, 0, new_val ) 
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.fx_reaeq_pos, 0) 
                                return new_val
                              end
       } )    

    x_offs = x_offs + DATA.GUI.custom_knob_button_w + DATA.GUI.custom_offset
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_fx_reaeq_gain',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_sampler_knob_h,
        
        ctrlname = 'Gain',
        ctrlval_key = 'fx_reaeq_gain',
        ctrlval_format_key = 'fx_reaeq_gain_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default = 0.5,
        
        func_app =            function(new_val) 
                                if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then 
                                  DATA2:TrackData_InitFilterDrive(src_t) 
                                  DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  
                                  --GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                                end 
                                if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then return end -- if reaeq insertion failed
                                TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.fx_reaeq_pos, 1, new_val ) 
                              end,
        func_refresh =        function() DATA2:TrackDataRead_GetChildrens_FXParams(src_t)  end,
        func_formatreverse =  function(str_ret)
                                local new_val = VF_BFpluginparam(str_ret, src_t.tr_ptr, src_t.fx_reaeq_pos, 1) 
                                return new_val
                              end
       } ) 
       
    x_offs = x_offs + DATA.GUI.custom_knob_button_w + DATA.GUI.custom_offset
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_fx_ws_drive',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_knob_button_w,
        h = DATA.GUI.custom_sampler_knob_h,
        
        ctrlname = 'Drive',
        ctrlval_key = 'fx_ws_drive',
        ctrlval_format_key = 'fx_ws_drive_format',
        ctrlval_src_t = src_t,
        ctrlval_res = 0.5,
        ctrlval_default = 0,
        
        func_app =            function(new_val) 
                                if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then 
                                  DATA2:TrackData_InitFilterDrive(src_t)
                                  DATA2:TrackDataRead_GetChildrens_FXParams(src_t) 
                                  GUI_MODULE_SAMPLER_Section_FilterSection(DATA)  
                                end 
                                if not (src_t.fx_reaeq_isvalid and src_t.fx_ws_isvalid) then return end -- if reaeq insertion failed
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
    if not DATA.GUI.buttons.sampler_frame then return end
    local src_t, note, layer = DATA2:internal_GetActiveNoteLayerTable()
    local x_offs= DATA.GUI.buttons.sampler_frame.x + (DATA.GUI.custom_knob_button_w+DATA.GUI.custom_offset) * 4
    local y_offs = DATA.GUI.buttons.sampler_frame.y+DATA.GUI.custom_sampler_peakareah+DATA.GUI.custom_offset*3+DATA.GUI.custom_module_ctrlreadout_h*2
    
    local attackmax = 1 if src_t.SAMPLELEN and src_t.SAMPLELEN ~= 0 then attackmax = math.min(1,src_t.SAMPLELEN/2) end
    local ctrl_paramid = 9 if src_t.INSTR_PARAM_ATT then ctrl_paramid = src_t.INSTR_PARAM_ATT end
    local ctrlname = 'Attack' if src_t.instrument_attack_extname then ctrlname =src_t.instrument_attack_extname end
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_instrument_attack',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_knob_button_w,
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
       
    local x_offs= x_offs + DATA.GUI.custom_knob_button_w+DATA.GUI.custom_offset
    local decaymax = 1 if src_t.SAMPLELEN and src_t.SAMPLELEN ~= 0 then decaymax = math.min(1,src_t.SAMPLELEN/15) end
    local ctrl_paramid = 24 if src_t.INSTR_PARAM_DEC then ctrl_paramid = src_t.INSTR_PARAM_DEC end
    local ctrlname = 'Decay' if src_t.instrument_decay_extname then ctrlname =src_t.instrument_decay_extname end
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_instrument_decay',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_knob_button_w,
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

    local x_offs= x_offs + DATA.GUI.custom_knob_button_w+DATA.GUI.custom_offset
    local ctrl_paramid = 25 if src_t.INSTR_PARAM_SUS then ctrl_paramid = src_t.INSTR_PARAM_SUS end
    local ctrlname = 'Sustain' if src_t.instrument_sustain_extname then ctrlname =src_t.instrument_sustain_extname end
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_instrument_sustain',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_knob_button_w,
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
       
    local x_offs= x_offs + DATA.GUI.custom_knob_button_w+DATA.GUI.custom_offset
    local releasemax = 1 if src_t.SAMPLELEN and src_t.SAMPLELEN ~= 0 then releasemax = math.min(1,src_t.SAMPLELEN/2) end
    local ctrlname = 'Release' if src_t.instrument_release_extname then ctrlname =src_t.instrument_release_extname end
    local ctrl_paramid = 10 if src_t.INSTR_PARAM_REL then ctrl_paramid = src_t.INSTR_PARAM_REL end
    GUI_CTRL(DATA,
      {
        butkey = 'sampler_instrument_release',
        
        x = x_offs,
        y=  y_offs,
        w = DATA.GUI.custom_knob_button_w,
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
    local retval, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
    DATA2.playingnote_trig = false 
    if retval and retval ~= 0 then
      DATA2.playingnote_rawmsg = rawmsg
      DATA2.playingnote_isNoteOn = rawmsg:byte(1)>>4 == 0x9  
      DATA2.playingnote_isNoteOff = rawmsg:byte(1)>>4 == 0x8 
      if DATA2.playingnote_isNoteOn == true then 
        local pitch = rawmsg:byte(2) 
        local vel = rawmsg:byte(3)
        DATA2.playingnote_pitch = pitch
        DATA2.playingnote_vel = vel 
        DATA2.playingnote_trig = true 
       elseif DATA2.playingnote_isNoteOff == true then 
        --DATA2.playingnote_pitch = nil
        DATA2.playingnote_trig = true 
      end
    end
    
    if DATA2.playingnote_trig == true and DATA2.playingnote_isNoteOn == true then 
      if  DATA.extstate.UI_incomingnoteselectpad == 1 then
        DATA2.PARENT_LASTACTIVENOTE = DATA2.playingnote_pitch 
        --DATA2.PARENT_LASTACTIVENOTE_layer = 1 
        DATA2:TrackDataWrite(_,{master_upd=true}) 
        GUI_MODULE_DEVICE(DATA)  
        GUI_MODULE_SAMPLER(DATA)
      end
      GUI_MODULE_PADOVERVIEW_generategrid(DATA) -- refresh pad
      GUI_MODULE_DRUMRACK(DATA)  
    end
    
    
    if DATA2.FORCEONPROJCHANGE == true then DATA_RESERVED_ONPROJCHANGE(DATA) DATA2.FORCEONPROJCHANGE = nil end
    
  end
  
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.48) if ret then local ret2 = VF_CheckReaperVrs(6.69,true) if ret2 then  main() end end
  
  
  
  --[[
              
              
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

      ]]


