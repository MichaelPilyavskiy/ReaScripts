-- @description RS5k manager
-- @version 3.10
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic5000 data on group of connected tracks
-- @provides
--    [main] mpl_RS5k_manager_Database_NewSample.lua 
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
--    + Database map: try reaper_sexplorer section if reaper_explorer not available




 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  -- config defaults
  DATA2 = { notes={}, 
            }
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '3.10'
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
                          
                          -- pad pverview
                          
                          -- sampler
                          CONF_cropthreshold = -60, -- db
                          
                          -- db
                          CONF_database_map_default = '',
                          CONF_database_map1 = '', 
                          CONF_database_map2 = '',
                          CONF_database_map3 = '',
                          CONF_database_map4 = '',
                          
                          -- child chain
                          CONF_chokegr_limit = 4,
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          UI_processoninit = 0,
                          UI_addundototabclicks = 0,
                          --UI_donotupdateonplay = 0,
                          UI_clickonpadselecttrack = 1,
                          UI_incomingnoteselectpad = 0,
                          UI_defaulttabsflags = 1|4|8, --1=drumrack   2=device  4=sampler 8=padview 16=macro 32=database 64=midi map 128=children chain
                          UI_keyformat_mode = 0 ,
                          UI_po_quantizemode = 0,--0 default 1=8pads 2=4pads
                          
                          
                          }
                          
    DATA2.PADselection = {}
    DATA2.CHILDRENFX_scroll = 0 
    DATA2.MACRO_scroll = 0 
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
  New sample = Set sample for current pad based on defined database
Database map parameters:
  Pad name: overwrites pad name
  DB name: database (list is taken from REAPER Media Explorer)
  Lock = prevent pad from replacing sample
]]
,'RS5k manager: database',0)       
      
      
      
      
      
      
--[[elseif page == 3 then  -- pad overview
MB(
[[

] ]
,'RS5k manager: overview',0)   ]]
      
      
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
  DB check: when listing samples takes array from database rather than sample path
  
Sampler readouts:
  Various readouts if available. rightclick for manually enter value, doubleclick to reset, ctrl for fine tweak
  
Sampler knobs:
  Various knobs if available. rightclick for manually enter value, doubleclick to reset, ctrl for fine tweak
  Filter Cut/Q: add ReaEQ after Rs5k instance and link controls to it
  Drive: add Waveshaper JSFX after Rs5k instance and link control to it
  
]]
,'RS5k manager: sampler',0)   
            
      
      
elseif page == 5 then  -- midi learo
MB(
[[
Actions panel:
  Learn: perform action 'FX: Set MIDI learn for last touched FX parameter'
]]
,'RS5k manager: learn',0)         
      
 
elseif page == 6 then  -- childchain
MB(
[[
List:
  - volume for parent tracks. If track is device, then it shows device track volume
  - pan for parent tracks. If track is device, then it shows device track pan
  - choke group. This is linked to choke JSFX typically placed at MIDI bus track
]]
,'RS5k manager: children chain',0)          
      
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
          'PARENT_DRRACKSHIFT '..DATA2.PARENT_DRRACKSHIFT..'\n'.. 
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
      if t.set_currentparentforchild then  GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', DATA2.tr_GUID, true) return end  
      if t.setchild then
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', 1, true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', '', true) 
        return
      end
      if t.setnote_ID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_NOTE', t.setnote_ID, true) return end
      if t.setinstr_FXGUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_FXGUID', t.setinstr_FXGUID, true) return end
      if t.is_rs5k then  GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_ISRS5K', 1, true) return end      
      if t.setmidifilt_FXGUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_MIDIFILTGUID', t.setmidifilt_FXGUID, true) return end
      if t.FX_REAEQ_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FX_REAEQ_GUID', t.FX_REAEQ_GUID, true) return end      
      if t.FX_WS_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FX_WS_GUID', t.FX_WS_GUID, true) return end      
      if t.SPLLISTDB then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB', t.SPLLISTDB, true) return end      
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
    local tr_folddepth = GetMediaTrackInfo_Value( track, 'I_FOLDERDEPTH' )
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
    note_layer_t.tr_folddepth = tr_folddepth
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
    
    if not (DATA2.MIDIbus and DATA2.MIDIbus.ptr) then DATA2.MIDIbus = { ptr =  new_tr}  end   -- reinitialise
    DATA2:TrackData_InitChoke()
    
    for note in pairs(DATA2.notes) do
      if DATA2.notes[note].layers then
        for layer in pairs(DATA2.notes[note].layers) do
          if DATA2.notes[note].layers[layer] and DATA2.notes[note].layers[layer].tr_ptr then DATA2:Actions_PadOnFileDrop_AddMIDISend(DATA2.notes[note].layers[layer].tr_ptr) end 
        end
      end
    end
  end
  -----------------------------------------------------------------------  
  function DATA2:TrackData_InitChoke()
    if not DATA2.MIDIbus.ptr then return end
    if DATA2.MIDIbus.choke_valid == true then return end 
    local fxname = 'mpl_RS5K_manager_MIDIBUS_choke.jsfx' 
    local chokeJSFX_pos =  TrackFX_AddByName( DATA2.MIDIbus.ptr, fxname, false, 0 )
    if chokeJSFX_pos == -1 then
      DATA2.MIDIbus.choke_valid = true
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
                    linkID=linkID,
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
      local  ret, tr, choke_pos, choke_valid
      if CHOKE_GUID then ret, tr, choke_pos = VF_GetFXByGUID(CHOKE_GUID:gsub('[%{%}]',''),track) end
      if not choke_pos then CHOKE_GUID = nil else choke_valid = true end
      if isMIDIbus then  DATA2.MIDIbus = { ptr = track, 
                                            ID = CSurf_TrackToID( track, false ),
                                            CHOKE_GUID = CHOKE_GUID,
                                            choke_valid = choke_valid,
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
    local ret, SPLLISTDB = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB', '', false) SPLLISTDB = tonumber(SPLLISTDB) or 0
    
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
                                          SPLLISTDB=SPLLISTDB, -- list samples in path or database
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
    DATA2.active_notes_cnt = 0
    for note in pairs(DATA2.notes) do
      DATA2:TrackDataRead_GetChildrens_TrackParams(DATA2.notes[note]) 
      if DATA2.notes[note].layers then 
        if #DATA2.notes[note].layers > 0 then DATA2.active_notes_cnt=DATA2.active_notes_cnt+1 end
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
    
    if note_layer_t[extparamkey] then
      note_layer_t[outval_key] = TrackFX_GetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t[extparamkey] ) 
      note_layer_t[outvalform_key]=math.floor(({TrackFX_GetFormattedParamValue( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t[extparamkey] )})[2]*100)..'%'
    end
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
      note_layer_t.instrument_noteoffID = 11
      note_layer_t.instrument_noteoff = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_noteoffID ) 
      note_layer_t.instrument_noteoff_format = math.floor(note_layer_t.instrument_noteoff)
      
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
      --if vrs < 3.00003 then DATA2.tr_valid = false MB('This version require new rack. Rack was created in unsupported beta of RS5k manager','Error', 0) return end -- 3.0beta30
      -- removed after 3.0 initial release
    end
    
    DATA2.PARENT_DRRACKSHIFT = 36
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
    if not DATA2.Macro then return end
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
    if not (track and ValidatePtr2(0,track,'MediaTrack*'))then return end
    
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
    --DATA2:Database_Load() 
    DATA2:Database_Load(_,true) 
    DATA2:TrackDataRead_GetMIDIOSC_bindings()
    DATA2:TrackDataRead_ReadChoke()
  end
  --------------------------------------------------------------------- 
  function DATA2:Actions_UpdateChoke()
    if not (DATA2.MIDIbus.choke_valid and DATA2.MIDIbus.chokeflags ) then return end 
    local tr = DATA2.MIDIbus.ptr
    local fx = DATA2.MIDIbus.choke_pos
    -- write group flags
    for slider = 0, 63 do
      local noteID1 = slider*2
      local noteID2 = slider*2+1
      local flags1 = DATA2.MIDIbus.chokeflags[noteID1]
      local flags2 = DATA2.MIDIbus.chokeflags[noteID2]
      local out_mixed = (flags2<<8) + flags1
      --[[if out_mixed ~= 0 then 
        msg('=')
        msg('out_mixed '..out_mixed) 
        msg('slider '..slider) 
        msg('flags1 '..flags1) 
        msg('noteID1 '..noteID1) 
        msg('flags2 '..flags2) 
        msg('noteID2 '..noteID2) 
      end]]
      TrackFX_SetParamNormalized( tr, fx, slider, out_mixed/65535 )
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:TrackDataRead_ReadChoke()
    if not (DATA2.MIDIbus and DATA2.MIDIbus.choke_valid) then return end
    
    local tr = DATA2.MIDIbus.ptr
    local fx = DATA2.MIDIbus.choke_pos
    DATA2.MIDIbus.chokeflags = {}
    -- read group flags
    for slider = 0, 63 do
      local flags = TrackFX_GetParamNormalized( tr, fx, slider )
      flags = math.floor(flags*65535)
      local noteID1 = slider*2
      local noteID2 = slider*2+1
      DATA2.MIDIbus.chokeflags[noteID1] = flags&0xFF
      DATA2.MIDIbus.chokeflags[noteID2] = (flags>>8)&0xFF 
    end
  end 
  ---------------------------------------------------------------------  
  function DATA2:Database_ParseREAPER_DB()   
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
            reaperDB[exp_section[db_key]] = exp_section[key]
          end
        end
      end
    end
    return reaperDB
  end
  --------------------------------------------------------------------- 
  function DATA2:Database_Load(chunk, forceload)
    
    if chunk then
      local content_b64 = chunk
      if not content_b64 then return end 
      local content = VF_decBase64(content_b64)
      if content == '' then return end 
      
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
      return {  valid = true, 
                map=map, 
                dbname = dbname, 
                parenttrGUID = DATA2.tr_GUID}
    end
    
    
      -------------------------------------------------
    if not DATA2.database_map then DATA2.database_map = {} end
    if DATA2.database_map.parenttrGUID and DATA2.database_map.parenttrGUID == DATA2.tr_GUID and not forceload then return end
    
    local content_b64 = DATA2.PARENT_DATABASEMAP
    if parseonly then content_b64 = parseonly end
    if not content_b64 then return end 
    local content = VF_decBase64(content_b64)
    if content == '' then -- if nothing
      if DATA.extstate.CONF_database_map_default~= '' then content = VF_decBase64(DATA.extstate.CONF_database_map_default) end
      if content == '' then return end 
    end
    DATA2.database_map.load_content = content
    
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
      end 
      DATA2.database_map.map = map
      DATA2.database_map.dbname = dbname
      
    -- cache samples
      for note in pairs(DATA2.database_map.map)  do
        if not DATA2.database_map.map[note].cached or (DATA2.database_map.map[note].cached and DATA2.database_map.map[note].cached==false)then
          local list_fp = DATA2.database_map.map[note].dbflist
          if list_fp then samples = DATA2:Actions_DB_InitRandSamples_ParseList(list_fp) DATA2.database_map.map[note].samples = samples end
          DATA2.database_map.map[note].cached = true
        end
      end
      
    -- valid
      DATA2.database_map.valid = true
      DATA2.database_map.parenttrGUID = DATA2.tr_GUID
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
        GUI_RESERVED_initmacroXYoffs(DATA)
        GUI_RESERVED_init_tabs(DATA)
      end
    
    if not DATA.GUI.layers_refresh  then DATA.GUI.layers_refresh = {} end
    DATA.GUI.layers_refresh[2]=true  
    
    DATA.GUI.Settings_open = 0
    GUI_MODULE_SETTINGS(DATA)
    
  end
  ----------------------------------------------------------------------------- 
  function GUI_MODULE_INITFALED(DATA)
    local help_text =
[[
Quick tips
-
Parent track: 
firstly, select some track, 
It will be parent track for drum rack
-
Drop sample to pads
While track is selected, drop file from browsr or MediaExplorer to pad,
this will create dedicated track for a sample.
-
Using tabs
leftclick them to toggle show-hide 
rightclick them to hide all but active.

]]
    local w_rep = 0.5*(DATA.GUI.custom_gfx_wreal-DATA.GUI.custom_tab_w)
    local h_rep = 0.8*(DATA.GUI.custom_gfx_hreal)
    DATA.GUI.buttons['initfalse'] = { 
                          x=1+DATA.GUI.custom_tab_w+(DATA.GUI.custom_gfx_wreal-DATA.GUI.custom_tab_w)/2-w_rep/2,
                          y=DATA.GUI.custom_gfx_hreal/2-h_rep/2,
                          w=w_rep,
                          h=h_rep,
                          txt = help_text,
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          --frame_a =DATA.GUI.custom_framea,
                          --frame_col = '#333333',
                          onmouseclick = function() 
                          
                          end,
                          } 
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
                                local f=function()
                                  DATA2.PARENT_TABSTATEFLAGS = DATA2.PARENT_TABSTATEFLAGS ~ byte
                                  if byte == 16 then if DATA2.PARENT_TABSTATEFLAGS&byte==byte then DATA2:TrackData_InitMacro() end end
                                  if byte == 64 then if DATA2.PARENT_TABSTATEFLAGS&byte==byte then DATA2:TrackDataRead_GetMIDIOSC_bindings() end end
                                  DATA2:TrackDataWrite(_, {master_upd=true})
                                end
                                if DATA.extstate.UI_addundototabclicks == 1 then DATA2:ProcessUndoBlock(f, 'RS5k manager / Tab state')  else f() end
                                DATA.UPD.onGUIinit = true
                              end
                            end,
                            onmouseclickR = function()
                              if DATA2.PARENT_TABSTATEFLAGS then 
                                local f=function()
                                  if DATA2.PARENT_TABSTATEFLAGS&byte==byte and DATA2.PARENT_TABSTATEFLAGS~= byte then -- tab is on but not only this tab
                                    DATA2.PARENT_TABSTATEFLAGS_LAST = DATA2.PARENT_TABSTATEFLAGS
                                    DATA2.PARENT_TABSTATEFLAGS = byte -- set to only this tab
                                   elseif DATA2.PARENT_TABSTATEFLAGS == byte then
                                    DATA2.PARENT_TABSTATEFLAGS = DATA2.PARENT_TABSTATEFLAGS_LAST or DATA.extstate.UI_defaulttabsflags-- -1
                                   elseif DATA2.PARENT_TABSTATEFLAGS ~= byte then
                                    DATA2.PARENT_TABSTATEFLAGS_LAST = DATA2.PARENT_TABSTATEFLAGS
                                    DATA2.PARENT_TABSTATEFLAGS = byte -- set to only this tab
                                  end
                                  if byte == 16 then if DATA2.PARENT_TABSTATEFLAGS&byte==byte then DATA2:TrackData_InitMacro() end end
                                  if byte == 64 then if DATA2.PARENT_TABSTATEFLAGS&byte==byte then DATA2:TrackDataRead_GetMIDIOSC_bindings() end end
                                  DATA2:TrackDataWrite(_, {master_upd=true})
                                end
                                if DATA.extstate.UI_addundototabclicks == 1 then DATA2:ProcessUndoBlock(f, 'RS5k manager / Tab state')  else f() end
                                DATA.UPD.onGUIinit = true
                              end
                            end,
                            } 
      y_offs = y_offs + DATA.GUI.custom_tab_h
                            
    end
                         
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, tabflag, modulew, modulexkey,moduleykey ) 
    local sepshift = DATA.GUI.custom_offset*2+DATA.GUI.custom_moduleseparatorw
    if DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&tabflag==tabflag then -- midi
      if DATA.GUI.custom_availableforhorizontalseparation == true and mod_xoffs + modulew > DATA.GUI.custom_gfx_wreal then 
        mod_xoffs = DATA.GUI.custom_module_startoffsx
        mod_yoffs = mod_yoffs + DATA.GUI.custom_moduleH +DATA.GUI.custom_offset
        DATA.GUI[modulexkey] = mod_xoffs
        DATA.GUI[moduleykey] = mod_yoffs
        mod_xoffs = mod_xoffs + modulew + sepshift
       else
        DATA.GUI[modulexkey] = mod_xoffs
        DATA.GUI[moduleykey] = mod_yoffs
        mod_xoffs = mod_xoffs + modulew + sepshift
      end
    end
    return mod_xoffs,mod_yoffs
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_initmacroXYoffs(DATA) 
    -- modules offs
      --local validnote = DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE~=-1 and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE]
      local validnote = true
      DATA.GUI.custom_moduleseparatorw = 7*DATA.GUI.custom_Yrelation  
      local mod_xoffs = DATA.GUI.custom_module_startoffsx--+DATA.GUI.custom_moduleseparatorw  -- --1=drumrack   2=device  4=sampler 8=padview 16=macro 32=database
      local mod_yoffs = 0
      
      mod_xoffs,mod_yoffs = GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, 16,DATA.GUI.custom_macroW,'custom_module_xoffs_macro','custom_module_yoffs_macro') -- macro
      mod_xoffs,mod_yoffs = GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, 64,DATA.GUI.custom_midiW,'custom_module_xoffs_midi','custom_module_yoffs_midi') -- midi
      mod_xoffs,mod_yoffs = GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, 8,DATA.GUI.custom_padgridw,'custom_module_xoffs_padoverview','custom_module_yoffs_padoverview')-- pad view 
      mod_xoffs,mod_yoffs = GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, 1,DATA.GUI.custom_drrack_sideW,'custom_module_xoffs_drumrack','custom_module_yoffs_drumrack')-- drrack 
      mod_xoffs,mod_yoffs = GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, 32,DATA.GUI.custom_databasew,'custom_module_xoffs_database','custom_module_yoffs_database')-- database 
      mod_xoffs,mod_yoffs = GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, 128,DATA.GUI.custom_childchainw,'custom_module_xoffs_childchain','custom_module_yoffs_childchain')-- childchain 
      mod_xoffs,mod_yoffs = GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, 2,DATA.GUI.custom_devicew,'custom_module_xoffs_device','custom_module_yoffs_device')-- device 
      mod_xoffs,mod_yoffs = GUI_RESERVED_initmacroXYoffs_sub(DATA,mod_xoffs,mod_yoffs, 4,DATA.GUI.custom_samplerW,'custom_module_xoffs_sampler','custom_module_yoffs_sampler')-- sampler 
      
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init(DATA)
    -- get globals
      local gfx_h = math.floor(gfx.h/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
      local gfx_w = math.floor(gfx.w/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
    --DATA.GUI.default_scale = 1
      
    -- init main stuff
      DATA.GUI.custom_referenceH = 300
      DATA.GUI.custom_Yrelation = math.max(gfx_h/DATA.GUI.custom_referenceH, 0.5) -- global W
      DATA.GUI.custom_Yrelation = math.min(DATA.GUI.custom_Yrelation, 1.1) -- global W
      DATA.GUI.custom_availableforhorizontalseparation = gfx_h / (DATA.GUI.custom_referenceH* DATA.GUI.custom_Yrelation) > 1.5
      DATA.GUI.custom_gfx_wreal = gfx_w
      DATA.GUI.custom_gfx_hreal = gfx_h
      DATA.GUI.custom_anavailableparamtxta = 0.3
      
      DATA.GUI.custom_offset =  math.floor(3 * DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_infoh = math.floor(DATA.GUI.custom_referenceH* DATA.GUI.custom_Yrelation*0.1)
      DATA.GUI.custom_moduleH = DATA.GUI.custom_referenceH* DATA.GUI.custom_Yrelation-DATA.GUI.custom_offset-- - DATA.GUI.custom_infoh -- global H
      DATA.GUI.custom_moduleW = math.floor(DATA.GUI.custom_moduleH*1.5) -- global W 
      DATA.GUI.custom_knob_button_w = math.floor(DATA.GUI.custom_moduleH * 0.2) 
      DATA.GUI.custom_knob_button_h =math.floor(DATA.GUI.custom_moduleH * 0.35) 
      DATA.GUI.custom_separator_w = math.floor(10*DATA.GUI.custom_Yrelation)
      
      DATA.GUI.custom_framea = 0.1 -- greyed drum rack pads
      DATA.GUI.custom_framea2 = 0.5 -- slider controls
      DATA.GUI.custom_backcol2 = '#f3f6f4' -- grey back  -- device selection
      DATA.GUI.custom_backfill2 = 0.1-- device selection
      
      DATA.GUI.custom_layer_scrollw = 10
      
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
      DATA.GUI.custom_module_startoffsx = DATA.GUI.custom_tab_w + DATA.GUI.custom_offset -- first mod offset-
      DATA.GUI.custom_module_ctrlreadout_h = math.floor(DATA.GUI.custom_moduleH * 0.1) 
      DATA.GUI.custom_tabnames_txtsz = 15*DATA.GUI.custom_Yrelation--*DATA.GUI.default_scale
      
    -- macro 
      DATA.GUI.custom_macroH = DATA.GUI.custom_moduleH--DATA.GUI.custom_offset
      --DATA.GUI.custom_macro_knobH = math.floor(DATA.GUI.custom_macroH)
      DATA.GUI.custom_macroW = DATA.GUI.custom_knob_button_w*8--+DATA.GUI.custom_offset
      DATA.GUI.custom_macro_knobtxtsz= math.floor(15* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_macro_linkentryh = math.floor(25 * DATA.GUI.custom_Yrelation  )
      DATA.GUI.custom_macro_link_txtsz= math.floor(14* DATA.GUI.custom_Yrelation)
    -- midiosc
      DATA.GUI.custom_midiH = DATA.GUI.custom_moduleH
      DATA.GUI.custom_midiW = math.floor(DATA.GUI.custom_moduleW*1.25)
      DATA.GUI.custom_midi_entryh = math.floor(25 * DATA.GUI.custom_Yrelation  )
      DATA.GUI.custom_midi_txtsz= math.floor(14* DATA.GUI.custom_Yrelation)
    -- pad overview
      DATA.GUI.custom_padgridblockh = math.floor(DATA.GUI.custom_moduleH/8)
      DATA.GUI.custom_padgridw = DATA.GUI.custom_padgridblockh 
       
    -- drrack 
      --DATA.GUI.custom_drrack_sideY = math.floor(DATA.GUI.custom_moduleH/4)
      --DATA.GUI.custom_drrack_sideX = DATA.GUI.custom_drrack_sideY*1.5
      DATA.GUI.custom_drrack_sideW = DATA.GUI.custom_macroW--DATA.GUI.custom_moduleW--DATA.GUI.custom_offset
      DATA.GUI.custom_drrack_pad_txtsz = 13* DATA.GUI.custom_Yrelation--0.5*(DATA.GUI.custom_drrack_sideY/2-DATA.GUI.custom_offset*2)
      --DATA.GUI.custom_drrack_arcr = math.floor(DATA.GUI.custom_drrack_sideX*0.1) 
      --DATA.GUI.custom_drrack_sideW = DATA.GUI.custom_drrack_sideX*4 -- reset to 4 pads
      --DATA.GUI.custom_drrackH = DATA.GUI.custom_moduleH-DATA.GUI.custom_infoh--DATA.GUI.custom_offset--DATA.GUI.custom_drrack_sideY*4
      --DATA.GUI.custom_drrack_ctrlbut_h = DATA.GUI.custom_drrack_sideY/2
      
    -- device
      DATA.GUI.custom_device_droptxtsz =  math.floor(20* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_devicew = math.floor(DATA.GUI.custom_moduleW)
      DATA.GUI.custom_deviceh = DATA.GUI.custom_moduleH
      DATA.GUI.custom_deviceentryh = math.floor(25 * DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_devicectrl_txtsz = math.floor(14 *DATA.GUI.custom_Yrelation   )
      
    -- database
      DATA.GUI.custom_databasew = math.floor(DATA.GUI.custom_moduleW*0.6)
      DATA.GUI.custom_database_text= math.floor(14* DATA.GUI.custom_Yrelation)
    -- childchain
      DATA.GUI.custom_childchainw = math.floor(DATA.GUI.custom_moduleW)      
      DATA.GUI.custom_childchain_entryh = math.floor(25 * DATA.GUI.custom_Yrelation  )
      DATA.GUI.custom_childchain_txtsz = math.floor(13 *DATA.GUI.custom_Yrelation   )
    -- sampler   
      DATA.GUI.custom_samplerW = (DATA.GUI.custom_knob_button_w+DATA.GUI.custom_offset) * 8
      DATA.GUI.custom_sampler_namebutw = DATA.GUI.custom_samplerW-(DATA.GUI.custom_knob_button_w)*2 -DATA.GUI.custom_infoh
      DATA.GUI.custom_sampler_knob_h = DATA.GUI.custom_knob_button_h--DATA.GUI.custom_moduleH - DATA.GUI.custom_module_ctrlreadout_h*3 - DATA.GUI.custom_sampler_peakareah - DATA.GUI.custom_offset*4-DATA.GUI.custom_offset 
      DATA.GUI.custom_sampler_peakareah = DATA.GUI.custom_moduleH-DATA.GUI.custom_infoh-DATA.GUI.custom_knob_button_h-DATA.GUI.custom_module_ctrlreadout_h*2-DATA.GUI.custom_offset*5 --math.floor(DATA.GUI.custom_moduleH * 0.3) 
      
      DATA.GUI.custom_sampler_ctrl_txtsz = math.floor(13 *DATA.GUI.custom_Yrelation  )
      DATA.GUI.custom_sampler_peaksw = DATA.GUI.custom_samplerW-DATA.GUI.custom_offset-DATA.GUI.custom_knob_button_w-1
      
    -- global 
      GUI_RESERVED_initmacroXYoffs(DATA)
      
      
      
      
      
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
        GUI_RESERVED_initmacroXYoffs(DATA)
        GUI_RESERVED_init_tabs(DATA)
        --end
        if DATA2.tr_valid ~=true then 
          GUI_MODULE_INITFALED(DATA)
        end
       elseif DATA.GUI.Settings_open and DATA.GUI.Settings_open == 1 then 
        GUI_MODULE_SETTINGS(DATA)
      end
    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init_tabs(DATA)
    DATA.GUI.buttons['initfalse'] = nil
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
        {str = 'Initialize MIDI bus',                           group = 2, itype = 'button', level = 1, func_onrelease = function() DATA2:TrackDataRead_ValidateMIDIbus() end},
        
      {str = 'UI',                                              group = 3, itype = 'sep'},
        {str = 'Active note follow incoming note',              group = 3, itype = 'check', confkey = 'UI_incomingnoteselectpad', level = 1},
        {str = 'Key format',                                    group = 3, itype = 'readout', confkey = 'UI_keyformat_mode', level = 1,menu = {[0]='C-C#-D',[2]='Do-Do#-Re',[7]='Russian'}},
        {str = 'Pad overview quantize',                         group = 3, itype = 'readout', confkey = 'UI_po_quantizemode', level = 1, menu = {[0]='Default',[1]='8 pads', [2]='4 pads'},readoutw_extw = readoutw_extw}, 
        {str = 'Undo tab state change',                         group = 3, itype = 'check', confkey = 'UI_addundototabclicks', level = 1,}, 
        {str = 'Drumrack: Click on pad select track',           group = 3, itype = 'check', confkey = 'UI_clickonpadselecttrack', level = 1},
        {str = 'Dock / undock',                                 group = 3, itype = 'button', confkey = 'dock',  level = 1, func_onrelease = 
          function()  
            local state = gfx.dock(-1)
            if state&1==1 then
              state = 0
             else
              state = DATA.extstate.dock 
              if state == 0 then state = 1 end
            end
            local title = DATA.extstate.mb_title or ''
            if DATA.extstate.version then title = title..' '..DATA.extstate.version end
            gfx.quit()
            gfx.init( title,
                      DATA.extstate.wind_w or 100,
                      DATA.extstate.wind_h or 100,
                      state, 
                      DATA.extstate.wind_x or 100, 
                      DATA.extstate.wind_y or 100)
            
            
          end},
      
      {str = 'Tab defaults',                                    group = 6, itype = 'sep'},
        {str = 'Drumrack',                                      group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 0},
        {str = 'Device',                                        group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 1},
        {str = 'Sampler',                                       group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 2},
        {str = 'Padview',                                       group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 3},
        --{str = 'Tab defaults: macro',                           group = 3, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 4},
        {str = 'Database',                                      group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 5},
        {str = 'MIDI / OSC learn',                              group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 6},
        {str = 'Children chain',                                group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 7},
      
      {str = 'Various',                                         group = 5, itype = 'sep'},    
        {str = 'Sampler: Crop threshold',                       group = 5, itype = 'readout', confkey = 'CONF_cropthreshold', level = 1, menu = {[-80]='-80dB',[-60]='-60dB', [-40]='-40dB',[-30]='-30dB'},readoutw_extw = readoutw_extw},
        

        
    } 
    return t
    
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO_links(DATA) 
    if not DATA2.PARENT_LASTACTIVEMACRO then return end
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==0) then return end
    for key in pairs(DATA.GUI.buttons) do if key:match('macroglob_macrolink') then DATA.GUI.buttons[key] = nil end end 
    local y_offs = DATA.GUI.buttons.macroglob_frame.y--DATA.GUI.custom_module_yoffs_macro+DATA.GUI.custom_infoh + DATA.GUI.custom_offset
    
    local macroID = DATA2.PARENT_LASTACTIVEMACRO
    local linkscnt = 0
    if not DATA2.Macro.sliders[macroID] then return end
    if  DATA2.Macro.sliders[macroID].links then linkscnt = #DATA2.Macro.sliders[macroID].links end
    local macroframeH = DATA.GUI.buttons.macroglob_frame.h--DATA.GUI.custom_moduleH-DATA.GUI.custom_infoh-DATA.GUI.custom_offset*2
    local comh = linkscnt*DATA.GUI.custom_macro_linkentryh
    if comh > macroframeH then comh = comh - DATA.GUI.custom_macro_linkentryh end
    
    local y_offs_list = y_offs - (DATA2.MACRO_scroll*comh)
    if comh < macroframeH then  y_offs_list = y_offs end 
    local x_offs0= DATA.GUI.buttons.macroglob_frame.x--math.floor(DATA.GUI.custom_module_xoffs_childchain+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    if not DATA2.Macro.sliders[macroID].links then return end
    for linkID = 1, #DATA2.Macro.sliders[macroID].links do 
      local x_offs = x_offs0
      if not (y_offs_list < y_offs or y_offs_list + DATA.GUI.custom_macro_linkentryh > y_offs + macroframeH) then  GUI_MODULE_MACRO_links_sub(DATA, DATA2.Macro.sliders[macroID].links[linkID], x_offs, y_offs_list)   end                     
      y_offs_list = y_offs_list + DATA.GUI.custom_macro_linkentryh 
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO_links_sub(DATA,link_t,x_offs0, y_offs ) 
    local w_layername = math.floor(DATA.GUI.buttons.macroglob_frame.w*0.55)
    local w_ctrls = DATA.GUI.buttons.macroglob_frame.w - w_layername-DATA.GUI.custom_offset
    local w_ctrls_single = (w_ctrls / 3)
    local backgr_col=DATA.GUI.custom_backcol2
    local backgr_fill_param = 0.2 
    local backgr_fill_name = 0
    local x_offs = x_offs0
    y_offs = y_offs + 1
    local macroID = DATA2.PARENT_LASTACTIVEMACRO
    local t = link_t
    local src_t = t.src_t
    local id_note = src_t.noteID
    local id_layer = src_t.layerID
    local param_name = ''
    if id_note and DATA2.notes and DATA2.notes[id_note] and DATA2.notes[id_note].name then param_name = '[N'..DATA2.notes[id_note].name..'] ' end
    --if id_layer then param_name = param_name .. '[L'..id_layer..'] ' end
    param_name = param_name ..t.param_name
    local valres = 0.3
    DATA.GUI.buttons['macroglob_macrolink'..macroID..'link_name'..link_t.linkID] = { 
                          x=x_offs0+1,
                          y=y_offs,
                          w=w_layername-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
                          txt = param_name,
                          txt_fontsz = DATA.GUI.custom_macro_link_txtsz,
                          frame_a =DATA.GUI.custom_framea,
                          frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,
                          onmouseclick = function() 
                          end,
                          } 
      GUI_CTRL(DATA,
        {
          butkey = 'macroglob_macrolink'..macroID..'offs'..link_t.linkID,
          
          x = x_offs+w_layername,
          y= y_offs,
          w = w_ctrls_single-DATA.GUI.custom_offset,
          h = DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
          
          ctrlname = 'Offs',
          ctrlval_key = 'plink_offset',
          ctrlval_format_key = 'plink_offset_format',
          ctrlval_src_t = link_t,
          ctrlval_res = valres,
          ctrlval_default =0,
          ctrlval_min =-1,
          ctrlval_max =1,
          func_atrelease =      function()      GUI_MODULE_MACRO(DATA)  end,
          func_app =            function(new_val) 
                                  TrackFX_SetNamedConfigParm(t.src_t.tr_ptr, t.fx_dest, 'param.'..t.param_dest..'plink.offset', new_val)  
                                  link_t.plink_offset_format = math.floor(new_val*100)..'%'
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
          butkey = 'macroglob_macrolink'..macroID..'scale'..link_t.linkID,
          
          x = x_offs+w_layername+w_ctrls_single,
          y= y_offs,
          w = w_ctrls_single-DATA.GUI.custom_offset,
          h = DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
          
          ctrlname = 'offs',
          ctrlval_key = 'plink_scale',
          ctrlval_format_key = 'plink_scale_format',
          ctrlval_src_t = link_t,
          ctrlval_res = valres,
          ctrlval_default =0,
          func_atrelease =      function() GUI_MODULE_MACRO(DATA)end,          
          func_app =            function(new_val) 
                                  TrackFX_SetNamedConfigParm(t.src_t.tr_ptr, t.fx_dest, 'param.'..t.param_dest..'plink.scale', new_val) 
                                  link_t.plink_scale_format = math.floor(new_val*100)..'%'
                                end,
          func_refresh =        function() 
                                  DATA2:TrackDataRead_GetParent_Macro() 
                                  
                                end,
          func_formatreverse =  function(str_ret)
                                  local ret = DATA2:internal_ParsePercent(str_ret) if ret then return ret end
                                end
         } ) 
      DATA.GUI.buttons['macroglob_macrolink'..macroID..'linkremove'..link_t.linkID] = { 
                          x=x_offs+w_layername+w_ctrls_single*2,
                          y=y_offs,
                          w=w_ctrls_single,
                          h=DATA.GUI.custom_macro_linkentryh-DATA.GUI.custom_offset,
                          txt = 'X',
                          txt_fontsz = DATA.GUI.custom_macro_link_txtsz,
                          frame_a =DATA.GUI.custom_framea,
                          --frame_col = '#333333',
                          backgr_fill = backgr_fill_name,
                          backgr_col =backgr_col,
                          onmouserelease = function() 
                            local f = function(t,tr_ptr) TrackFX_SetNamedConfigParm(t.src_t.tr_ptr, t.fx_dest, 'param.'..t.param_dest..'plink.active', 0)   end
                            DATA2:ProcessUndoBlock(f, 'RS5k manager / Macro / Remove link', t,tr_ptr) 
                            DATA2:TrackDataRead_GetParent_Macro()
                            GUI_MODULE_MACRO(DATA) 
                          end,
                          }          
  end 
  -----------------------------------------------------------------------------  
  function DATA2:internal_ConfirmLTPisChild()
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
  function DATA2:Actions_Macro_AddLink(srct0,fxnumber0,paramnumber0, offset0, scale0)
    if not DATA2.PARENT_LASTACTIVEMACRO then return end 
    if DATA2.PARENT_LASTACTIVEMACRO == -1 then return end
    
    local ret, srct, fxnumber, paramnumber = DATA2:internal_ConfirmLTPisChild()
    if not ret and not srct0 then return elseif (srct0 and fxnumber0 and paramnumber0) then
      srct, fxnumber, paramnumber = srct0, fxnumber0, paramnumber0
    end 
    
    -- init child macro
      if not srct.macro_pos then DATA2:TrackData_InitMacro(true, srct) fxnumber=fxnumber+1 end 
      
    -- link
      local param_src = tonumber(DATA2.PARENT_LASTACTIVEMACRO)
      local fx_src = tonumber(srct.macro_pos)
      
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
  function GUI_MODULE_separator(DATA, key, xoffs,yoffs)   
    DATA.GUI.buttons[key] = { x=xoffs,
                          y=yoffs or 0,
                          w=DATA.GUI.custom_moduleseparatorw-1,
                          h=DATA.GUI.custom_moduleH-1,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          ignoreboundarylimit=true,
                          backgr_fill = 0.5,
                          backgr_col = '#FFFFFF',
                          onmouseclick =  function() end}
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_CHILDCHAIN_childs_sub(DATA, note, x_offs, y_offs)  
    local notenamesw = math.floor(DATA.GUI.custom_childchainw-DATA.GUI.custom_layer_scrollw-DATA.GUI.custom_offset- DATA.GUI.custom_knob_button_w*3)---*3)-- )
    
    -- mark active
      local frame_a = .3--DATA.GUI.custom_framea 
      if DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE == note then frame_a = 0.7 end 
    -- handle col
      local col 
      if DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_col then 
        col = DATA2.notes[note].layers[1].tr_col 
        col = string.format("#%06X", col);
        frame_a = .7--DATA.GUI.custom_framea 
        if DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE == note then frame_a = 1 end
      end 
      local backgr_fill_pad, backgr_col_pad
    -- handle selection
      if DATA2.PADselection and DATA2.PADselection[note] then 
        backgr_fill_pad = 0.4
        backgr_col_pad = '#FFFFFF'
      end
      local childname = DATA2.notes[note].name
      if DATA2.notes[note].TYPE_DEVICE == true then 
        childname = '[D'..note..'] '..childname
       else
        childname = '[N'..note..'] '..childname
      end
      DATA.GUI.buttons['childchain_note'..note..'name'] = { 
                              x=x_offs,
                              y=y_offs,
                              w=notenamesw-DATA.GUI.custom_offset,
                              h=DATA.GUI.custom_childchain_entryh-DATA.GUI.custom_offset,
                              txt = childname,
                              txt_fontsz = DATA.GUI.custom_childchain_txtsz,
                              frame_a = 0,
                              frame_col = col,
                              backgr_fill = backgr_fill_pad,
                              backgr_col = backgr_col_pad,
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
                                
    
                                
                                 if not DATA.GUI.Ctrl and not DATA.GUI.Shift then
                                    DATA2.PADselection = {} -- clear selection
                                    DATA2.PADselection[note] = true
                                   elseif DATA.GUI.Ctrl then
                                    if not DATA2.PADselection[note] then DATA2.PADselection[note] = true else DATA2.PADselection[note] = not DATA2.PADselection[note]  end
                                   elseif DATA.GUI.Shift and DATA2.PARENT_LASTACTIVENOTE then
                                    for note2 = math.min(note, DATA2.PARENT_LASTACTIVENOTE), math.max(note, DATA2.PARENT_LASTACTIVENOTE) do
                                      DATA2.PADselection[note2] = true
                                    end
                                 end
                                 DATA2.PARENT_LASTACTIVENOTE = note 
                                   DATA2:TrackDataWrite(_,{master_upd=true}) 
                                GUI_MODULE_DEVICE(DATA)  
                                 GUI_MODULE_SAMPLER(DATA)
                                 GUI_MODULE_DATABASE(DATA)
                                 GUI_MODULE_CHILDCHAIN_childs(DATA)  
                              end,
                              onmouseclickR = function() DATA2:Menu_DrumRack_Actions(note) end,
                              onmousefiledrop = function() DATA2:Actions_PadOnFileDrop(note) end,
                              onmouserelease =  function()  
                                                  if not DATA2.ONDOUBLECLICK then
                                                    DATA2.PARENT_LASTACTIVENOTE = note 
                                                    GUI_MODULE_DRUMRACK(DATA)
                                                    GUI_MODULE_CHILDCHAIN_childs(DATA)  
                                                   else
                                                    DATA2.ONDOUBLECLICK = nil
                                                  end
                                                end,
                              onmousedoubleclick = function() 
                                                    DATA2.ONDOUBLECLICK = true
                                                  end
                              } 
    x_offs = x_offs + notenamesw
    local frame_a = 0
    local backgr_col=DATA.GUI.custom_backcol2
    local backgr_fill_param = 0.2 
    local backgr_fill_name = 0
    -- vol
    local val , val_format, actvol_t
    if DATA2.notes[note].TYPE_DEVICE == true then 
      val= DATA2.notes[note].tr_vol/2 
      val_format= DATA2.notes[note].tr_vol_format 
      actvol_t = DATA2.notes[note]
     else
      val= DATA2.notes[note].layers[1].tr_vol/2 
      val_format= DATA2.notes[note].layers[1].tr_vol_format 
      actvol_t = DATA2.notes[note].layers[1]
    end
    DATA.GUI.buttons['childchain_note'..note..'vol'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_childchain_entryh-DATA.GUI.custom_offset,
                        val = val,
                        val_res = -0.3,
                        val_xaxis = true,
                        txt = val_format,
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        frame_a = DATA.GUI.custom_framea2,
                        onmousedrag = function()
                              local src_t = actvol_t
                              local new_val = DATA.GUI.buttons['childchain_note'..note..'vol'].val
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_VOL', new_val*2 )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['childchain_note'..note..'vol'].txt = actvol_t.tr_vol_format
                              DATA.GUI.buttons['childchain_note'..note..'vol'].refresh = true
                              DATA2.ONPARAMDRAG = true
                            end,
                        onmouserelease = function()
                              if not DATA2.ONDOUBLECLICK then
                                DATA2.ONPARAMDRAG = nil
                                local src_t = actvol_t
                                local new_val = DATA.GUI.buttons['childchain_note'..note..'vol'].val
                                SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_VOL', new_val*2 )
                                DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                                DATA.GUI.buttons['childchain_note'..note..'vol'].txt = actvol_t.tr_vol_format
                                DATA.GUI.buttons['childchain_note'..note..'vol'].refresh = true
                               else
                                DATA2.ONDOUBLECLICK = nil
                              end
                        end,
                        onmousedoubleclick = function() 
                              local src_t = actvol_t
                              local new_val = 1
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_VOL', new_val )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['childchain_note'..note..'vol'].txt = actvol_t.tr_vol_format
                              DATA.GUI.buttons['childchain_note'..note..'vol'].refresh = true
                              DATA.GUI.buttons['childchain_note'..note..'vol'].val = 0.5
                              DATA2.ONDOUBLECLICK = true
                            end,                     
                        }  
    -- pan
    x_offs = x_offs + DATA.GUI.custom_knob_button_w
    local val , val_format, actpan_t
    if DATA2.notes[note].TYPE_DEVICE == true then 
      val= DATA2.notes[note].tr_pan
      val_format= DATA2.notes[note].tr_pan_format 
      actpan_t = DATA2.notes[note]
     else
      val= DATA2.notes[note].layers[1].tr_pan 
      val_format= DATA2.notes[note].layers[1].tr_pan_format 
      actpan_t = DATA2.notes[note].layers[1]
    end
    DATA.GUI.buttons['childchain_note'..note..'pan'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_childchain_entryh-DATA.GUI.custom_offset,
                        val = val,
                        val_res = -0.6,
                        val_xaxis = true,
                        val_centered = true,
                        val_min = -1,
                        val_max = 1,
                        txt = val_format,
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        backgr_fill2 = backgr_fill_param,
                        backgr_col2 =backgr_col,
                        backgr_usevalue = true,
                        frame_a = DATA.GUI.custom_framea2,
                        onmousedrag = function()
                              local src_t = actpan_t
                              local new_val = DATA.GUI.buttons['childchain_note'..note..'pan'].val
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_PAN', new_val )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['childchain_note'..note..'pan'].txt = actpan_t.tr_pan_format
                              DATA.GUI.buttons['childchain_note'..note..'pan'].refresh = true
                              DATA2.ONPARAMDRAG = true
                            end,
                        onmouserelease = function()
                              if not DATA2.ONDOUBLECLICK then
                                DATA2.ONPARAMDRAG = nil
                                local src_t = actpan_t
                                local new_val = DATA.GUI.buttons['childchain_note'..note..'pan'].val
                                SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_PAN', new_val )
                                DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                                DATA.GUI.buttons['childchain_note'..note..'pan'].txt = actpan_t.tr_pan_format
                                DATA.GUI.buttons['childchain_note'..note..'pan'].refresh = true
                               else
                                DATA2.ONDOUBLECLICK = nil
                              end
                        end,
                        onmousedoubleclick = function() 
                              local src_t = actpan_t
                              local new_val = 0
                              SetMediaTrackInfo_Value( src_t.tr_ptr, 'D_PAN', new_val )
                              DATA2:TrackDataRead_GetChildrens_TrackParams(src_t)
                              DATA.GUI.buttons['childchain_note'..note..'pan'].txt = actpan_t.tr_pan_format
                              DATA.GUI.buttons['childchain_note'..note..'pan'].refresh = true
                              DATA.GUI.buttons['childchain_note'..note..'pan'].val = 0
                              DATA2.ONDOUBLECLICK = true
                            end,                     
                        }                          
    x_offs = x_offs + DATA.GUI.custom_knob_button_w
    local gr_name = 'None'
    if DATA2.MIDIbus.chokeflags and DATA2.MIDIbus.chokeflags[note] then
      local flags = DATA2.MIDIbus.chokeflags[note]
      if flags ~= 0 then
        gr_name = ''
        for groupID = 1, DATA.extstate.CONF_chokegr_limit do
          local byte = 1<<(groupID-1)
          if DATA2.MIDIbus.chokeflags[note]&byte==byte then 
            if gr_name~='' then gr_name = gr_name..' '..groupID  else gr_name = gr_name..''..groupID end
          end
        end
      end
    end
    DATA.GUI.buttons['childchain_note'..note..'choke'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                        h=DATA.GUI.custom_childchain_entryh-DATA.GUI.custom_offset,
                        val_res = -0.3,
                        val_xaxis = true,
                        txt = gr_name,
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        --backgr_fill2 = backgr_fill_param,
                        --backgr_col2 =backgr_col,
                       -- backgr_usevalue = true,
                        frame_a = DATA.GUI.custom_framea2,
                        onmouserelease = function()
                          DATA2:Menu_ChildrenChain_Actions(note)
                        end,
                        }                          
  end
  ----------------------------------------------------------------------------- 
  function DATA2:Menu_ChildrenChain_Actions(note)
    if not DATA2.MIDIbus.chokeflags then return end
    local t = {}
    local loop_t = {}
    local cntsel = 0 for note in pairs(DATA2.PADselection) do cntsel = cntsel + 1 end
    if cntsel >= 2 then 
      for note in pairs(DATA2.PADselection) do loop_t[#loop_t+1]= note end
     else--if DATA2.PARENT_LASTACTIVENOTE then
      loop_t[1] = note--DATA2.PARENT_LASTACTIVENOTE
    end
    
    if not note then note = loop_t[1] end 
    if note then 
      for groupID = 0, DATA.extstate.CONF_chokegr_limit do
        local byte = 1<<(groupID-1)
        local active = ''
        if DATA2.MIDIbus.chokeflags[note]&byte==byte then active = '!' end
        local name = active..'Set choke group to '..groupID
        if groupID == 0 then name = 'Clear choke group' end
        if groupID == 1 then name = '|'..name end
        t[#t+1] = { str= name,
                    func = function() 
                      -- handle selection
                        local loop_t = {}
                        local cntsel = 0 for note in pairs(DATA2.PADselection) do cntsel = cntsel + 1 end
                        if cntsel >= 2 then 
                          for note in pairs(DATA2.PADselection) do loop_t[#loop_t+1]= note end
                         else--if DATA2.PARENT_LASTACTIVENOTE then
                          loop_t[1] = note--DATA2.PARENT_LASTACTIVENOTE
                        end
                        
                      -- handle flags
                        for i = 1, #loop_t do
                          local note = loop_t[i]
                          if groupID == 0 then 
                            DATA2.MIDIbus.chokeflags[note] = 0 
                           else 
                            DATA2.MIDIbus.chokeflags[note] = DATA2.MIDIbus.chokeflags[note] ~byte
                          end 
                        end
                        
                      -- do stuff
                        DATA2:Actions_UpdateChoke()
                        GUI_MODULE_CHILDCHAIN_childs(DATA)
                    end
                  }
      end
     else
      t[#t+1] = { str= 'none'}
    end
    
    -- common actions
      t[#t+1] = { str= '|Clear all group flags',
                  func = function()
                            if not (DATA2.MIDIbus and DATA2.MIDIbus.chokeflags) then return end
                            for note=0,127 do DATA2.MIDIbus.chokeflags[note] = 0 end
                            DATA2:Actions_UpdateChoke()
                            GUI_MODULE_CHILDCHAIN_childs(DATA)
                          end
                }
    
    DATA:GUImenu(t)
    
  end
  ----------------------------------------------------------------------------- 
  function GUI_MODULE_CHILDCHAIN_childs(DATA)  
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&128==0) then return end
    for key in pairs(DATA.GUI.buttons) do if key:match('childchain_note') then DATA.GUI.buttons[key] = nil end end 
    local y_offs = DATA.GUI.custom_module_yoffs_childchain+DATA.GUI.custom_infoh + DATA.GUI.custom_offset
    
    local chainframeH = DATA.GUI.custom_moduleH-DATA.GUI.custom_infoh-DATA.GUI.custom_offset*2
    local comh = (DATA2.active_notes_cnt or 0 )*DATA.GUI.custom_childchain_entryh
    if comh > chainframeH*2 then comh = comh -DATA.GUI.custom_childchain_entryh end
    local y_offs_list = y_offs - (DATA2.CHILDRENFX_scroll*comh)
    if comh < chainframeH then  y_offs_list = y_offs end
    local x_offs0= math.floor(DATA.GUI.custom_module_xoffs_childchain+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    for note in spairs(DATA2.notes) do 
      local x_offs = x_offs0
      if not (y_offs_list < y_offs or y_offs_list + DATA.GUI.custom_childchain_entryh > y_offs + chainframeH) then  GUI_MODULE_CHILDCHAIN_childs_sub(DATA, note, x_offs, y_offs_list)   end                     
      y_offs_list = y_offs_list + DATA.GUI.custom_childchain_entryh 
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_CHILDCHAIN(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('childchain_') then DATA.GUI.buttons[key] = nil end end 
    local parentlistID = 30
    gfx.setimgdim(parentlistID, -1, -1)  
    --gfx.setimgdim(parentlistID, gfx.w, gfx.h) 
    
    
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&128==0) then return end
    local x_offs0= math.floor(DATA.GUI.custom_module_xoffs_childchain+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    local x_offs = x_offs0
    local y_offs0= DATA.GUI.custom_module_yoffs_childchain
    GUI_MODULE_separator(DATA, 'childchain_sep', DATA.GUI.custom_module_xoffs_childchain,DATA.GUI.custom_module_yoffs_childchain) 
    
    local nameframe_w  = DATA.GUI.custom_childchainw - DATA.GUI.custom_knob_button_w-DATA.GUI.custom_infoh
      -- DATA.GUI.custom_knob_button_w - DATA.GUI.custom_infoh
    local y_offs = y_offs0+DATA.GUI.custom_infoh + DATA.GUI.custom_offset
    local chainframeH = DATA.GUI.custom_moduleH-DATA.GUI.custom_infoh-DATA.GUI.custom_offset*2
    DATA.GUI.buttons.childchain_actionframe = { x=x_offs,
                          y=y_offs0,
                          w=nameframe_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'Children chain',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() end}
    x_offs = x_offs + nameframe_w
    DATA.GUI.buttons.childchain_action = { x=x_offs,
                          y=y_offs0,
                          w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'Actions',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() DATA2:Menu_ChildrenChain_Actions()   end}     
    x_offs = x_offs + DATA.GUI.custom_knob_button_w
    DATA.GUI.buttons.childchain_help = { x=x_offs,
                          y=y_offs0,
                          w=DATA.GUI.custom_infoh ,
                          h=DATA.GUI.custom_infoh-1,
                          txt = '?',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          val = 0,
                          frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function()DATA2:Actions_Help(6)   end}                               
                          
    DATA.GUI.buttons.childchain_frame = { x=x_offs0,
                          y=y_offs0+DATA.GUI.custom_infoh+DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_childchainw-DATA.GUI.custom_layer_scrollw-DATA.GUI.custom_offset,---DATA.GUI.custom_offset,
                          h=chainframeH,
                          ignoreboundarylimit = true,
                          frame = 0,
                          back_sela = 0,
                          hide=true,
                          onwheeltrig =  function() 
                                            local mult = -1
                                            if DATA.GUI.wheel_dir then mult = 1 end
                                            DATA2.CHILDRENFX_scroll = VF_lim(DATA2.CHILDRENFX_scroll + 0.1 * mult)
                                            DATA.GUI.buttons.childchain_scroll.val = DATA2.CHILDRENFX_scroll
                                            GUI_MODULE_CHILDCHAIN_childs(DATA) 
                                          end 
                                          }                     
                          
    DATA.GUI.buttons.childchain_scroll = { x=x_offs0+DATA.GUI.custom_childchainw-DATA.GUI.custom_layer_scrollw,
                          y=y_offs0+DATA.GUI.custom_infoh+DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_layer_scrollw,---DATA.GUI.custom_offset, 
                          h=DATA.GUI.custom_moduleH-DATA.GUI.custom_infoh-DATA.GUI.custom_offset*2,
                          slider_isslider = true,
                          ignoreboundarylimit = true,
                          val = DATA2.CHILDRENFX_scroll,
                          val_res = -1,
                          onmousedrag =  function() 
                                            DATA2.CHILDRENFX_scroll = DATA.GUI.buttons.childchain_scroll.val
                                            GUI_MODULE_CHILDCHAIN_childs(DATA)  
                                          end}                      
                                                        
    GUI_MODULE_CHILDCHAIN_childs(DATA)                       
                          
  end
  
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MIDI(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('midiosclearn_') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&64==0) then return end
    
    local x_offs0= math.floor(DATA.GUI.custom_module_xoffs_midi+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    local y_offs= DATA.GUI.custom_module_yoffs_midi
    GUI_MODULE_separator(DATA, 'midiosclearn_sep', DATA.GUI.custom_module_xoffs_midi,DATA.GUI.custom_module_yoffs_midi) 
    local nameframe_w  = DATA.GUI.custom_midiW - DATA.GUI.custom_knob_button_w - DATA.GUI.custom_infoh
    local x_offs = x_offs0
    DATA.GUI.buttons.midiosclearn_actionframe = { x=x_offs0,
                          y=y_offs,
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
                          y=y_offs,
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
                          y=y_offs,
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
                          y=y_offs + DATA.GUI.custom_infoh+DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_midiW-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_midiH-DATA.GUI.custom_offset*2,
                          ignoreboundarylimit= true,
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
  function DATA2:Menu_Macro_Actions()  
    if not DATA2.PARENT_LASTACTIVEMACRO or (DATA2.PARENT_LASTACTIVEMACRO and DATA2.PARENT_LASTACTIVEMACRO == -1) then  
      DATA:GUImenu({
        {str= '# [Macro not selected]',
         func = function() end
        },
      })
      return
    end
    
    local macroID = DATA2.PARENT_LASTACTIVEMACRO
    local t = {
          {str= 'Add selected/all RS5k samplers pitch, obey_offsets',
           func = function() 
                    local cnt_selection = 0 
                    if DATA2.PADselection then for keynote in pairs(DATA2.PADselection) do if DATA2.PADselection[keynote] then cnt_selection = cnt_selection + 1 end end end
                    
                    local f = function(macroID)
                      local macro_t = DATA2.Macro.sliders[macroID]
                      local notest = {}
                      if cnt_selection == 0 then 
                        for note in pairs(DATA2.notes) do notest[#notest+1] = note end -- all
                       else
                        for keynote in pairs(DATA2.PADselection) do notest[#notest+1] = keynote end -- selected only
                      end
                      
                      for notestID = 1, #notest do
                        local note = notest[notestID]
                        if DATA2.notes[note] and DATA2.notes[note].layers then 
                          for layer in pairs(DATA2.notes[note].layers) do
                            local srct = DATA2.notes[note].layers[layer]
                            if srct.ISRS5K then
                              local instrpos = srct.instrument_pos
                              local initparam = srct.instrument_tune
                              local scale = 1
                              local offs = initparam-0.5
                              DATA2:Actions_Macro_AddLink(srct,instrpos,15, offs,scale)-- tune
                            end
                          end
                        end
                      end
                      TrackFX_SetParamNormalized( macro_t.tr_ptr, macro_t.macro_pos, macroID, 0.5 )
                    end
                    DATA2:ProcessUndoBlock(f, 'RS5k manager / Macro / Add tune links',macroID) 
                  end
          },
          {str= 'Add selected/all RS5k samplers gain, obey_offsets',
           func = function() 
                    local cnt_selection = 0 
                    if DATA2.PADselection then for keynote in pairs(DATA2.PADselection) do if DATA2.PADselection[keynote] then cnt_selection = cnt_selection + 1 end end end
                    
                    local f = function(macroID)
                      local macro_t = DATA2.Macro.sliders[macroID]
                      local notest = {}
                      if cnt_selection == 0 then 
                        for note in pairs(DATA2.notes) do notest[#notest+1] = note end -- all
                       else
                        for keynote in pairs(DATA2.PADselection) do notest[#notest+1] = keynote end -- selected only
                      end
                      
                      for notestID = 1, #notest do
                        local note = notest[notestID]
                        if DATA2.notes[note] and DATA2.notes[note].layers then 
                          for layer in pairs(DATA2.notes[note].layers) do
                            local srct = DATA2.notes[note].layers[layer]
                            if srct.ISRS5K then
                              local instrpos = srct.instrument_pos
                              local initparam = srct.instrument_vol
                              local scale = 1
                              local offs = initparam-0.5
                              DATA2:Actions_Macro_AddLink(srct,instrpos,0, offs,scale)
                            end
                          end
                        end
                      end
                      TrackFX_SetParamNormalized( macro_t.tr_ptr, macro_t.macro_pos, macroID, 0.5 )
                    end
                    DATA2:ProcessUndoBlock(f, 'RS5k manager / Macro / Add gain links',macroID) 
                  end
          },          
          {str= 'Clear links',
           func = function() 
                    local f = function(macroID) 
                      if not DATA2.Macro.sliders[macroID].links then return end
                      for link = #DATA2.Macro.sliders[macroID].links, 1, -1 do
                        local tmacro = DATA2.Macro.sliders[macroID].links[link]
                        TrackFX_SetNamedConfigParm(tmacro.src_t.tr_ptr, tmacro.fx_dest, 'param.'..tmacro.param_dest..'plink.active', 0) 
                      end
                    end
                    DATA2:ProcessUndoBlock(f, 'RS5k manager / Macro / Clear current macro links',macroID) 
                    DATA2:TrackDataRead_GetParent_Macro()
                    GUI_MODULE_MACRO(DATA) 
                  end
          },
        }
    DATA:GUImenu(t)
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO_ctrls(DATA) 
    -- controls 
    local ctrls_cnt = 8
    for ctrlid = 1, ctrls_cnt do
      local frame_a
      if DATA2.PARENT_LASTACTIVEMACRO and ctrlid == DATA2.PARENT_LASTACTIVEMACRO then 
        frame_a = 1
       else
        frame_a = nil
      end
      local xshift = DATA.GUI.custom_knob_button_w*(ctrlid-1)
      local yshift = DATA.GUI.custom_module_yoffs_macro--DATA.GUI.custom_macro_knobH * math.floor((ctrlid/9))
      if ctrlid>=9 then  xshift = DATA.GUI.custom_knob_button_w*(ctrlid-9) end 
      local wreduce = DATA.GUI.custom_offset
      if ctrlid==ctrls_cnt then 
      wreduce = 1
      end
      if not DATA2.Macro then return end
      local src_t = DATA2.Macro.sliders[ctrlid]
      local txt_a = DATA.GUI.custom_anavailableparamtxta
      if DATA2.Macro.sliders[ctrlid] and DATA2.Macro.sliders[ctrlid].links and #DATA2.Macro.sliders[ctrlid].links > 0 then 
        txt_a = 1
      end
      local x_offs = DATA.GUI.custom_macro_ctrls_x_offs
      local y_offs = DATA.GUI.custom_macro_ctrls_y_offs
      GUI_CTRL(DATA,
        {
          butkey = 'macroglob_knob'..ctrlid,
          
          x = x_offs+xshift,
          y=  y_offs+1,
          w = DATA.GUI.custom_knob_button_w-wreduce,
          h = DATA.GUI.custom_knob_button_h-DATA.GUI.custom_offset,
          frame_a = frame_a,
          txt_a = txt_a,
          
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
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_MACRO(DATA)    
    local parentlistID = 31 -- reset list blit
    gfx.setimgdim(parentlistID, -1, -1) 
    for key in pairs(DATA.GUI.buttons) do if key:match('macroglob_') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&16==0) then return end
    
    local x_offs0= math.floor(DATA.GUI.custom_module_xoffs_macro+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    local x_offs= x_offs0
    local y_offs0= DATA.GUI.custom_module_yoffs_macro
    local y_offs= y_offs0
    GUI_MODULE_separator(DATA, 'macroglob_sep', DATA.GUI.custom_module_xoffs_macro,DATA.GUI.custom_module_yoffs_macro) 
    local act_framew = DATA.GUI.custom_macroW-DATA.GUI.custom_knob_button_w*2
    DATA.GUI.buttons.macroglob_actionframe = { x=x_offs,
                          y=y_offs,
                          w=act_framew-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'Macro',
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          --frame_a = 0.3,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          onmouseclick =  function() end}

    x_offs = x_offs + act_framew                         
    DATA.GUI.buttons.macroglob_t_addbut = { x=x_offs,
                          y=y_offs,
                          w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'Add link',
                          txt_fontsz = DATA.GUI.custom_macro_link_txtsz,
                          --frame_a = 1,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          --ignoremouse = true,
                          onmouseclick =  function() 
                                            local f = function() DATA2:Actions_Macro_AddLink() end
                                            DATA2:ProcessUndoBlock(f, 'RS5k manager / Macro / Add link')                                     
                                          end}   
    x_offs = x_offs + DATA.GUI.custom_knob_button_w   
    DATA.GUI.buttons.macroglob_t_addbut_actions = { x=x_offs,
                          y=y_offs,
                          w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'Actions',
                          txt_fontsz = DATA.GUI.custom_macro_link_txtsz,
                          --frame_a = 1,
                          --frame_asel = 0.3,
                          --backgr_fill = 0,
                          --ignoremouse = true,
                          onmouseclick =  function() DATA2:Menu_Macro_Actions() end}                                             
    local x_offs= x_offs0
    DATA.GUI.buttons.macroglob_Aknobback = { x=x_offs-1, 
                          y=DATA.GUI.custom_module_yoffs_macro+DATA.GUI.custom_infoh+DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_macroW+1,---DATA.GUI.custom_layer_scrollw,
                          h=DATA.GUI.custom_knob_button_h,--DATA.GUI.custom_macroH-DATA.GUI.custom_infoh-DATA.GUI.custom_offset,
                          txt = '',
                          ignoreboundarylimit = true,
                          frame_a = 0,--0.3,
                          --frame_asel = 0,
                          --backgr_fill = 0,
                          ignoremouse = true,
                          --hide=true,
                          onmouseclick =  function() end}
    y_offs = y_offs +   DATA.GUI.custom_infoh + DATA.GUI.custom_offset  
    DATA.GUI.custom_macro_ctrls_x_offs = x_offs
    DATA.GUI.custom_macro_ctrls_y_offs = y_offs
    GUI_MODULE_MACRO_ctrls(DATA) 
    local x_offs= x_offs0
    y_offs = y_offs + DATA.GUI.custom_knob_button_h+DATA.GUI.custom_offset
    local addlink_w = DATA.GUI.custom_macroW-DATA.GUI.custom_knob_button_w
 
 
    --y_offs = y_offs + DATA.GUI.custom_macro_linkentryh
    local macrolinks_h = (y_offs0 + DATA.GUI.custom_moduleH)-y_offs-DATA.GUI.custom_offset
    DATA.GUI.buttons.macroglob_frame = { x=x_offs0+1,
                          y=y_offs-1,
                          w=DATA.GUI.custom_macroW-DATA.GUI.custom_layer_scrollw-DATA.GUI.custom_offset,---DATA.GUI.custom_offset,
                          h=macrolinks_h,
                          ignoreboundarylimit = true,
                          --hide = true,ignorempuse=true,
                          frame_a = 0,
                          frame_asel = 0,
                          back_sela = 0,
                          onwheeltrig =  function() 
                                            local mult = -1
                                            if DATA.GUI.wheel_dir then mult = 1 end
                                            DATA2.MACRO_scroll = VF_lim(DATA2.MACRO_scroll + 0.1 * mult)
                                            DATA.GUI.buttons.macroglob_scroll.val = DATA2.MACRO_scroll
                                            GUI_MODULE_MACRO_links(DATA) 
                                          end} 
    DATA.GUI.buttons.macroglob_scroll = { x=x_offs0+DATA.GUI.custom_macroW-DATA.GUI.custom_layer_scrollw,
                          y=y_offs,--+DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_layer_scrollw,---DATA.GUI.custom_offset, 
                          h=macrolinks_h,
                          slider_isslider = true,
                          ignoreboundarylimit = true,
                          val = DATA2.MACRO_scroll,
                          val_res = -1,
                          onmousedrag =  function() 
                                            DATA2.MACRO_scroll = DATA.GUI.buttons.macroglob_scroll.val
                                            GUI_MODULE_MACRO_links(DATA) 
                                          end}                                             
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
  function DATA2:Actions_Sampler_NextPrevSample(spl_t, mode, extfiles)
    if not mode then mode = 0 end
    if not spl_t.ISRS5K then return end
    fn = spl_t.instrument_filepath:gsub('\\', '/') 
    path = fn:reverse():match('[%/]+.*'):reverse():sub(0,-2)
    cur_file =     fn:reverse():match('.-[%/]'):reverse():sub(2)
    
    
    -- get files list
      local files = {}
      local pathsep = '/'
      if extfiles then files = extfiles path = '' pathsep = '' cur_file = spl_t.instrument_filepath else
        local i = 0
        repeat
        local file = reaper.EnumerateFiles( path, i )
        if file and reaper.IsMediaExtension(file:gsub('.+%.', ''), false) then
          files[#files+1] = file
        end
        i = i+1
        until file == nil
        table.sort(files, function(a,b) return a<b end )
      end
      
    local trig_file
    if mode == 0  then    -- search file list nex
      if #files < 2 then return end
      for i = 2, #files do
        if files[i-1] == cur_file then 
          trig_file = path..pathsep..files[i] 
          break 
         elseif i == #files then trig_file = path..pathsep..files[1] 
        end 
      end
    end
    
    if mode ==1 then     -- search file list prev
      if #files < 2 then return end
      for i = #files-1, 1, -1 do
        if files[i+1] == cur_file then 
          trig_file = path..pathsep..files[i] 
          break 
         elseif i ==1 then trig_file = path..pathsep..files[#files] 
        end
      end
    end
      
    if mode ==2 then        -- search file list random
      if #files < 2 then return end
      trig_id = math.floor(math.random(#files-1))+1
      trig_file = path..pathsep..files[trig_id] 
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
    local custom_drrack_sideY = 100* DATA.GUI.custom_Yrelation
    if mousey + custom_drrack_sideY/2 > gfx.h/DATA.GUI.default_scale then mousey =gfx.h/DATA.GUI.default_scale - custom_drrack_sideY/2 end
    local txt = 'Drag pad #'..DATA2.PAD_HOLD..'\n'..DATA2.notes[DATA2.PAD_HOLD].name
    local b =  {            x=mousex,
                            y=mousey,
                            w=custom_drrack_sideX,
                            h=custom_drrack_sideY/2,
                            txt = txt,
                            txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                            frame_arcborder = true,
                            frame_arcborderr = DATA.GUI.custom_drrack_arcr,
                            frame_arcborderflags = 1|2,
                            ignoreboundarylimit=true,
                            }
    DATA:GUIdraw_Button(b)
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_DRUMRACK_drawlayout(DATA)  
    --[[local padactiveshift = 116 
    -- handle pad overview shifts
    if DATA2.PARENT_DRRACKSHIFT == 8 then padactiveshift = 116 end
    if DATA2.PARENT_DRRACKSHIFT == 7 then padactiveshift = 100 end
    if DATA2.PARENT_DRRACKSHIFT == 6 then padactiveshift = 84 end
    if DATA2.PARENT_DRRACKSHIFT == 5 then padactiveshift = 68 end
    if DATA2.PARENT_DRRACKSHIFT == 4 then padactiveshift = 52 end
    if DATA2.PARENT_DRRACKSHIFT == 3 then padactiveshift = 36 end
    if DATA2.PARENT_DRRACKSHIFT == 2 then padactiveshift = 20 end
    if DATA2.PARENT_DRRACKSHIFT == 1 then padactiveshift = 4 end
    if DATA2.PARENT_DRRACKSHIFT == 0 then padactiveshift = 0 end
    ]]
    -- clear stuff
    for key in pairs(DATA.GUI.buttons) do if key:match('drumrackpad_pad(%d+)') then DATA.GUI.buttons[key] = nil end end
    
    
    local layout_mode = 0
    
    
    if layout_mode == 0 then
      local layout_pads_cnt = 16
      local padw = math.floor(DATA.GUI.custom_drrack_sideW / 4)
      local padh = math.floor((DATA.GUI.custom_moduleH-DATA.GUI.custom_infoh-DATA.GUI.custom_offset*2) / 4)
      local xoffs0 = DATA.GUI.custom_module_xoffs_drumrack + DATA.GUI.custom_moduleseparatorw+DATA.GUI.custom_offset
      local yoffs = DATA.GUI.custom_module_yoffs_drumrack+ DATA.GUI.custom_moduleH - padh-DATA.GUI.custom_offset
      local xoffs= xoffs0
      local padID0 = 0
      for note = 0+DATA2.PARENT_DRRACKSHIFT, layout_pads_cnt-1+DATA2.PARENT_DRRACKSHIFT do
        GUI_MODULE_DRUMRACK_drawlayout_pad(DATA, padID0, note, xoffs, yoffs, padw, padh)
        xoffs = xoffs + padw
        if padID0%4==3 then 
          xoffs = xoffs0
          yoffs = yoffs - padh
        end
        padID0 = padID0 + 1
      end
    end
    
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_DRUMRACK_drawlayout_pad_refreshplay(DATA)
    if not DATA2.playingnote then return end
    for key in pairs(DATA.GUI.buttons) do 
      if key:match('drumrackpad_pad(%d+)play') then
        local backgr_fill,txt_a1= 0,0.3
        if DATA.GUI.buttons[key].temp_playnote and DATA2.playingnote == DATA.GUI.buttons[key].temp_playnote then
          backgr_fill = 0.1 txt_a1 = nil
        end
        DATA.GUI.buttons[key].txt_a = txt_a1
        DATA.GUI.buttons[key].backgr_fill = backgr_fill
      end
    end
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_DRUMRACK_drawlayout_pad(DATA, padID0, note, xoffs, yoffs, padw, padh)   
    if not (DATA2:internal_FormatMIDIPitch(note)  and note ) then return end
    local ctrlw = math.floor(padw/3)
    local nameh = math.floor(padh/3)
    local txt_actrl = 0.1
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
      
    -- mark active
      local frame_a = .3--DATA.GUI.custom_framea 
      if DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE == note then frame_a = 0.7 end
        
    -- handle col
      local col 
      if DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_col then 
        col = DATA2.notes[note].layers[1].tr_col 
        col = string.format("#%06X", col);
        frame_a = .7--DATA.GUI.custom_framea 
        if DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE == note then frame_a = 1 end
       else
      end 
      
      
    -- handle availabler note
      local txt_a=1  if not DATA2.notes[note] then txt_a = DATA.GUI.custom_anavailableparamtxta end
      
    -- frame
      
      local backgr_fill_pad, backgr_col_pad
      if DATA2.PADselection and DATA2.PADselection[note] then 
        backgr_fill_pad = 0.4
        backgr_col_pad = '#FFFFFF'
      end
      DATA.GUI.buttons['drumrackpad_pad'..padID0..'frame'] = { 
          x=xoffs,--math.floor(x_offs0+(padID0%4)*DATA.GUI.custom_drrack_sideX)+1,
          y=yoffs,--y_offs + DATA.GUI.custom_infoh+DATA.GUI.custom_drrackH-DATA.GUI.custom_drrack_sideY*(math.floor(padID0/4)+1)+DATA.GUI.custom_offset,
          w=padw-DATA.GUI.custom_offset,--DATA.GUI.custom_drrack_sideX-DATA.GUI.custom_offset,
          h=padh-DATA.GUI.custom_offset,--DATA.GUI.custom_drrack_sideY-DATA.GUI.custom_offset-1,
          ignoremouse = true,
          txt='',
          frame_a = frame_a,
          frame_col = col,
          backgr_fill = backgr_fill_pad,
          backgr_col = backgr_col_pad,
          --[[frame_arcborder = true,
          frame_arcborderr = DATA.GUI.custom_drrack_arcr,
          frame_arcborderflags = 1|2,]]
          onmouseclick = function() end, 
          refresh = true,
      }    
      
    -- name
       local backgr_col =DATA.GUI.custom_backcol2-- '#33FF45'
       backgr_col = col
       DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] = { 
                              custom_note = note,
                              x=xoffs,
                               y=yoffs,
                               w=padw,
                               h=nameh,
                               txt=txt,
                               txt_a = txt_a,
                               txt_fontsz =DATA.GUI.custom_drrack_pad_txtsz,
                               txt_col = backgr_col,
                               frame_a = 0,
                               frame_asel = 0,
                               frame_col = backgr_col,--DATA.GUI.custom_backcol2,
                               backgr_fill = 0 ,
                               --backgr_col = backgr_col,
                               back_sela = 0 ,
                               --[[frame_arcborder = true,
                               frame_arcborderr = DATA.GUI.custom_drrack_arcr,
                               frame_arcborderflags = 1|2,]]
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
                                 
                                 if DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'] then DATA.GUI.buttons['drumrackpad_pad'..padID0..'name'].refresh = true end
                                 
                                 if not DATA.GUI.Ctrl and not DATA.GUI.Shift then
                                    DATA2.PADselection = {} -- clear selection
                                    DATA2.PADselection[note] = true
                                   elseif DATA.GUI.Ctrl then
                                    if not DATA2.PADselection[note] then DATA2.PADselection[note] = true else DATA2.PADselection[note] = not DATA2.PADselection[note]  end
                                   elseif DATA.GUI.Shift and DATA2.PARENT_LASTACTIVENOTE then
                                    for note2 = math.min(note, DATA2.PARENT_LASTACTIVENOTE), math.max(note, DATA2.PARENT_LASTACTIVENOTE) do
                                      DATA2.PADselection[note2] = true
                                    end
                                 end
                                 DATA2.PARENT_LASTACTIVENOTE = note 
                                 DATA2:TrackDataWrite(_,{master_upd=true}) 
                                 GUI_MODULE_DEVICE(DATA)  
                                 GUI_MODULE_SAMPLER(DATA)
                                 GUI_MODULE_DATABASE(DATA)
                                 GUI_MODULE_CHILDCHAIN_childs(DATA) 
                               end,
                               onmouseclickR = function() DATA2:Menu_DrumRack_Actions(note) end,
                               onmousefiledrop = function() 
                                                    local f = function () DATA2:Actions_PadOnFileDrop(note) end
                                                    DATA2:ProcessUndoBlock(f, 'RS5k manager / Pad / Drop file', note)  
                                                  end,
                               onmouserelease =  function()  
                                                   if not DATA2.ONDOUBLECLICK then
                                                   
                                                      -- copy/move
                                                      if DATA2.PAD_HOLD then 
                                                        local f = function()
                                                          local padsrc = DATA2.PAD_HOLD
                                                          for i = 1, #DATA.GUI.mouse_match do
                                                            if DATA.GUI.buttons[DATA.GUI.mouse_match[i]] and DATA.GUI.buttons[DATA.GUI.mouse_match[i]].custom_note then
                                                              paddest = DATA.GUI.buttons[DATA.GUI.mouse_match[i]].custom_note
                                                              DATA2:Actions_Pad_CopyMove(padsrc,paddest, DATA.GUI.Ctrl)  
                                                              DATA2.PADselection = {} -- clear selection
                                                              DATA2.PADselection[paddest] = true
                                                              DATA2:ProcessUndoBlock(f, 'RS5k manager / Pad / Copy_Move') 
                                                            end
                                                          end
                                                        end
                                                        DATA2.PAD_HOLD = nil
                                                      end
                                                    
                                                     DATA2.PARENT_LASTACTIVENOTE = note 
                                                     GUI_MODULE_DRUMRACK(DATA)
                                                     GUI_MODULE_CHILDCHAIN_childs(DATA)  
                                                     DATA2.ONPARAMDRAG = false
                                                    else
                                                     DATA2.ONDOUBLECLICK = nil
                                                   end
                                                 end,
                               onmousedoubleclick = function() 
                                                     DATA2.ONDOUBLECLICK = true
                                                   end
                               }  
    -- name secondary    
       DATA.GUI.buttons['drumrackpad_pad'..padID0..'name2'] = { 
                              x=xoffs,
                               y=yoffs+nameh,
                               w=padw,
                               h=nameh,
                               txt=txt2,
                               txt_a = txt_a,
                               txt_fontsz =DATA.GUI.custom_drrack_pad_txtsz,
                               txt_col = backgr_col,
                               frame_a = 0,
                               frame_asel = 0,
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
    -- mute
      local backgr_fill,txt_a= 0,txt_a if DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_mute and DATA2.notes[note].layers[1].tr_mute >0 then backgr_fill = 0.2 txt_a = nil end
       DATA.GUI.buttons['drumrackpad_pad'..padID0..'mute'] = { 
                                x=xoffs,
                               y=yoffs+nameh*2,
                               w=ctrlw,
                               h=nameh-DATA.GUI.custom_offset,
                               txt='M',
                               txt_col = backgr_col,
                               txt_a = txt_a,
                               txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                               frame_a = 0,
                               frame_asel = 0,
                               prevent_matchrefresh = true,
                               backgr_fill = backgr_fill,
                               backgr_col = DATA.GUI.custom_backcol2,
                               onmouseclick = function() DATA2:Actions_Pad_SoloMute(note,_,_, true) end,
                               }   
    -- play
       --[[local backgr_fill2,frame_actrl0=nil,txt_a 
       ]]--if DATA2.playingnote and DATA2.playingnote == note and DATA.extstate.UI_incomingnoteselectpad == 0  then backgr_fill2 = 0.8 frame_actrl0 = 1 end
       local backgr_fill,txt_a1= 0,txt_a --if DATA2.playingnote == note and DATA.extstate.UI_incomingnoteselectpad == 0 then backgr_fill = 0.1 txt_a1 = nil end
       DATA.GUI.buttons['drumrackpad_pad'..padID0..'play'] = { 
                              temp_playnote = note,
                                x=xoffs+ctrlw, 
                               y=yoffs+nameh*2,
                               w=ctrlw,
                               h=nameh-DATA.GUI.custom_offset,
                               txt='>',
                               txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                               txt_a = txt_a1,
                               txt_col = backgr_col,
                               --prevent_matchrefresh = true,
                               frame_a = 0,
                               --frame_asel = 0,
                               backgr_fill = backgr_fill ,
                               backgr_col ='#FFFFFF',
                               onmouseclick =    function() DATA2:Actions_StuffNoteOn(note, vel) end,
                               onmouserelease =  function() StuffMIDIMessage( 0, 0x80, note, 0 ) DATA.ontrignoteTS =  nil end,
                               --refresh = true,
                               --hide = DATA.extstate.UI_incomingnoteselectpad ==1,
                               }   
      
                        --solo
       local backgr_fill,txt_a= 0,txt_a if DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[1] and DATA2.notes[note].layers[1].tr_solo and DATA2.notes[note].layers[1].tr_solo >0 then backgr_fill = 0.2 txt_a = nil end
       DATA.GUI.buttons['drumrackpad_pad'..padID0..'solo'] = { 
                                x=xoffs+ctrlw*2,
                               y=yoffs+nameh*2,
                               w=ctrlw,
                               h=nameh-DATA.GUI.custom_offset,
                               --txt_col=txt_col,
                               txt_a = txt_a,
                               txt='S',
                               txt_fontsz = DATA.GUI.custom_drrack_pad_txtsz,
                               txt_col = backgr_col,
                               frame_a = 0,
                               frame_asel = 0,
                               prevent_matchrefresh = true,
                               backgr_fill = backgr_fill,
                               backgr_col = DATA.GUI.custom_backcol2,
                               onmouseclick = function() DATA2:Actions_Pad_SoloMute(note,_,true) end,
                               }  
  end  
  -----------------------------------------------------------------------------  
  function GUI_MODULE_DRUMRACK(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('drumrack') then DATA.GUI.buttons[key] = nil end end 
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&1==0) then return end
    
    local trname = DATA2.tr_name or '[no data]'   
    local drracvname_w = DATA.GUI.custom_drrack_sideW-DATA.GUI.custom_knob_button_w*3-DATA.GUI.custom_infoh
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_drumrack+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    local x_offs0=x_offs
    local y_offs= DATA.GUI.custom_module_yoffs_drumrack 
    GUI_MODULE_separator(DATA, 'drumrack_sep', DATA.GUI.custom_module_xoffs_drumrack,DATA.GUI.custom_module_yoffs_drumrack) 
       -- dr rack
       DATA.GUI.buttons.drumrack_trackname = { x=x_offs,
                            y=y_offs,
                            w=drracvname_w-DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_infoh-1,
                            txt = trname,
                            txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                            }
      --[[ DATA.GUI.buttons.drumrackpad = { x=x_offs-1,
                             y=y_offs+DATA.GUI.custom_infoh,
                             w=DATA.GUI.custom_drrack_sideW+1,
                             h=DATA.GUI.custom_drrackH,
                             ignoreboundarylimit=true,
                             ignoremouse = true,
                             frame_a = 0,
                             }]]
     x_offs = x_offs + drracvname_w    
     DATA.GUI.buttons.drumrack_FX = { x=x_offs,
                          y=y_offs,
                          w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_infoh-1,
                          txt = 'FX',
                          txt_a=txt_a,
                          txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                          onmouseclick = function() TrackFX_Show( DATA2.tr_ptr, -1, 1 ) end
                          } 
      x_offs = x_offs + DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons.drumrack_showME = { x=x_offs,
                           y=y_offs,
                           w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'Explore',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() if DATA2.PARENT_LASTACTIVENOTE then  DATA2:Actions_Pad_ShowME(DATA2.PARENT_LASTACTIVENOTE, DATA2.PARENT_LASTACTIVENOTE_layer or 1) end  end,
                           } 
      x_offs = x_offs + DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons.drumrack_actions = { x=x_offs,
                           y=y_offs,
                           w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'Actions',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() DATA2:Menu_DrumRack_Actions()  end,
                           }                            
      x_offs = x_offs + DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons.drumrack_help = { x=x_offs,
                           y=y_offs,
                           w=DATA.GUI.custom_infoh-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = '?',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() 
                                              DATA2:Actions_Help(0)
                                            end,
                           }  
    GUI_MODULE_DRUMRACK_drawlayout(DATA) 
 
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
    local offs = 0
    if DATA2.REAPERini and DATA2.REAPERini.REAPER and DATA2.REAPERini.REAPER.midioctoffs then offs = DATA2.REAPERini.REAPER.midioctoffs end
    do return VF_GetNoteStr(note+(offs-2)*12,DATA.extstate.UI_keyformat_mode) end
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
    --if not remap then DATA2:TrackDataRead_ValidateMIDIbus() end
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
    if not midifilt_pos  then 
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
  function DATA2:Actions_PadOnFileDrop_ExportToRS5k(new_tr, filepath,note,section_data)
    if not (filepath and filepath~='')  then return end
    if filepath:match('@fx') then 
      DATA2:Actions_PadOnFileDrop_ExportFXasDeviceInstrument(new_tr, filepath,note)
      return
    end
    local instrument_pos = TrackFX_AddByName( new_tr, 'ReaSamplomatic5000', false, 0 ) 
    if instrument_pos == -1 then instrument_pos = TrackFX_AddByName( new_tr, 'ReaSamplomatic5000', false, -1000 ) end 
    if not instrument_pos then MB('Error adding RS5k', 'Rs5k manager',0) end
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
    if section_data and section_data.src and section_data.offs and section_data.len then
      --[[msg(section_data.src_len)
      msg(section_data.offs)
      msg(section_data.len)]]
      TrackFX_SetParamNormalized( new_tr, instrument_pos, 13, section_data.offs / section_data.src_len )
      TrackFX_SetParamNormalized( new_tr, instrument_pos, 14, (section_data.offs+section_data.len) / section_data.src_len )
    end
    
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
  function DATA2:Actions_DB_InitRandSamples_ParseList(list_fp)
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
  function DATA2:Actions_DB_InitRandSamples(spec_note)
    if not DATA2.tr_valid then return end
    if not (DATA2.database_map and DATA2.database_map.valid and DATA2.database_map.map) then return end
    
    -- https://stackoverflow.com/questions/18199844/lua-math-random-not-working
      math.randomseed(os.time())
      math.random(); math.random(); math.random()
    
    for note in pairs(DATA2.database_map.map)  do
      if not spec_note or (spec_note and spec_note == note) then
        local lock = DATA2.database_map.map [note].lock or 0
        if lock==0 or ( lock ~= 0 and spec_note) then
          local samples_t = DATA2.database_map.map[note].samples
          if samples_t and #samples_t > 0 then
            local randomnum = math.floor(math.random()*#samples_t)
            local randID = VF_lim(randomnum,1,#samples_t)
            local new_sample = samples_t[randID]
            DATA2:Actions_PadOnFileDrop_Sub(note,1,new_sample)
          end
        end 
      end
    end
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_Pad_Clear(note, layer)  
    if not DATA2.notes[note] then return end 
    
    local  tr_ptr
    if DATA2.notes[note].TYPE_DEVICE then 
      -- remove device with layers
      if DATA2.notes[note].layers then 
        for layerID = 1, #DATA2.notes[note].layers do
          if not layer or (layer and layer==layerID) then
            tr_ptr = DATA2.notes[note].layers[layerID].tr_ptr 
            if tr_ptr and ValidatePtr2(0,tr_ptr, 'MediaTrack*')then 
            
              if layerID> 1 and DATA2.notes[note].layers[layerID].tr_folddepth == -1 then -- 2+ last
                DeleteTrack( tr_ptr) 
                if DATA2.notes[note].layers[layerID-1] and DATA2.notes[note].layers[layerID-1].tr_ptr and ValidatePtr2(0,DATA2.notes[note].layers[layerID-1].tr_ptr, 'MediaTrack*') then  SetMediaTrackInfo_Value(DATA2.notes[note].layers[layerID-1].tr_ptr,'I_FOLDERDEPTH',-1) end
               elseif layerID == 1 and #DATA2.notes[note].layers == 1 then -- single left layer in the device
                DeleteTrack( tr_ptr)
                SetMediaTrackInfo_Value(DATA2.notes[note].tr_ptr,'I_FOLDERDEPTH',0)
               elseif (layerID == 1 and #DATA2.notes[note].layers > 1) or (layer>1 and layer<#DATA2.notes[note].layers) then
                DeleteTrack( tr_ptr)
              end
            end
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
    end
    -- set parent track selected
    reaper.SetOnlyTrackSelected( DATA2.tr_ptr )
  end 
  -----------------------------------------------------------------------
  function DATA2:Actions_Pad_UpdateNote(note, newnote)
    if not DATA2.notes[note] then return end
    if DATA2.notes[note].TYPE_DEVICE then 
      local devicetr = DATA2.notes[note].tr_ptr
      DATA2:TrackDataWrite(devicetr, {setnote_ID = newnote}) 
      for layer = 1, #DATA2.notes[note].layers do
        local child_tr = DATA2.notes[note].layers[layer].tr_ptr
        if DATA2.notes[note].layers[layer].instrument_pos then
          DATA2:TrackDataWrite( child_tr, {setnote_ID = newnote})
          DATA2:Actions_PadOnFileDrop_setnote_ID(child_tr, DATA2.notes[note].layers[layer].instrument_pos, newnote, DATA2.notes[note].layers[layer].midifilt_pos)
        end
      end
      
     else
      DATA2:TrackDataWrite(DATA2.notes[note].layers[1].tr_ptr, {setnote_ID = newnote})
      DATA2:Actions_PadOnFileDrop_setnote_ID(DATA2.notes[note].layers[1].tr_ptr, DATA2.notes[note].layers[1].instrument_pos, newnote, DATA2.notes[note].layers[1].midifilt_pos)
    end
    if DATA2.cursplpeaks and DATA2.cursplpeaks.note == note then DATA2.cursplpeaks.note = newnote end
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_Pad_CopyMove(padsrc,paddest, iscopy) 
    if not (padsrc and paddest) then return end 
    if padsrc == paddest then return end
    
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
      SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, retvals_csv)  
      SetTrackMIDINoteNameEx( 0,tr, note, -1, retvals_csv) 
    end
  end
  -----------------------------------------------------------------------
  function DATA2:Menu_DrumRack_Actions(note)  
    if not DATA2.tr_valid then return end
    
    if note then 
      local t = { 
        {str='Rename pad',
          func=function() 
                  local f = function() DATA2:Actions_Pad_Rename(note)  end
                  DATA2:ProcessUndoBlock(f, 'RS5k manager / Pad / Rename',note)   
                end },  
        {str='Clear pad',
          func=function() 
                  local f = function() DATA2:Actions_Pad_Clear(note)  end
                  DATA2:ProcessUndoBlock(f, 'RS5k manager / Pad / Clear',note)   
                end },  
        {str='|Select all pads',
          func=function() 
                  for i = 0, 127 do DATA2.PADselection[i] = true end
                  GUI_MODULE_DRUMRACK(DATA) 
                end },                 
        {str='Unselect all pads',
          func=function() 
                  DATA2.PADselection = {}
                  GUI_MODULE_DRUMRACK(DATA) 
                end },                  
                
        {str='|Import selected items to pads, starting this pad',
          func=function() 
                  local f = function(note) DATA2:Actions_ImportSelectedItems(note)  end
                  DATA2:ProcessUndoBlock(f, 'RS5k manager / Import selected items',note) 
                end },      
        {str='Move pad to last recent incoming note',
          func=function() 
                  local notedest = DATA2.playingnote
                  if not notedest then return end 
                  local f = function(note,notedest) DATA2:Actions_Pad_CopyMove(note,notedest)   end
                  DATA2:ProcessUndoBlock(f, 'RS5k manager / Pad / Add to recent note',note,notedest)  
                end },
       
           
                  }
                
      DATA:GUImenu(t)
      return
    end
    
    -- common
    local t = { 
      {str='Clear rack',
        func=function() 
                local ret =  reaper.MB( 'Are you sure you want to REMOVE all DrumRack tracks', 'RS5k manager', 3 )
                if ret == 6 then 
                  local f = function() for note in pairs(DATA2.notes) do DATA2:Actions_Pad_Clear(note)  end end
                  DATA2:ProcessUndoBlock(f, 'RS5k manager / Clear rack') 
                end
              end },  
        {str='|Select all pads',
          func=function() 
                  for i = 0, 127 do DATA2.PADselection[i] = true end
                  GUI_MODULE_DRUMRACK(DATA) 
                end },  
        {str='Unselect all pads',
          func=function() 
                  DATA2.PADselection = {}
                  GUI_MODULE_DRUMRACK(DATA) 
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
        local section_data = {}
        if parent_src and GetMediaSourceType( src ) == 'SECTION' then 
          local retval, offs, len, rev = reaper.PCM_Source_GetSectionInfo( src )
          section_data.offs =offs
          section_data.len =len
          section_data.src =src
          section_data.src_len =src_len
        end
        
                
        
        if parent_src then 
          local filenamebuf = GetMediaSourceFileName( parent_src )
          if filenamebuf then 
            filenamebuf = filenamebuf:gsub('\\','/')
            local layer = 1 
            DATA2:Actions_PadOnFileDrop(note+i-1, layer, filenamebuf,section_data)
            DeleteTrackMediaItem(  reaper.GetMediaItemTrack( it ), it )
          end
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
  function DATA2:Actions_PadOnFileDrop_Sub(note, layer, filepath,section_data)
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
      DATA2:Actions_PadOnFileDrop_ExportToRS5k(new_tr, filepath,note,section_data) 
      DATA2:Actions_PadOnFileDrop_AddMIDISend(new_tr)
      DATA2:TrackDataWrite(new_tr, {setnote_ID=note})
      DATA2:TrackDataRead_GetChildrens() 
      DATA_RESERVED_ONPROJCHANGE(DATA)
      local filepath_sh = GetShortSmplName(filepath) 
      if filepath_sh and filepath_sh:match('(.*)%.[%a]+') then filepath_sh = filepath_sh:match('(.*)%.[%a]+') end 
      if filepath_sh then 
        SetTrackMIDINoteNameEx( 0,DATA2.MIDIbus.ptr, note, -1, filepath_sh) 
        SetTrackMIDINoteNameEx( 0,new_tr, note, -1, filepath_sh)
      end
      return
    end
    
    -- replace existing sample into 1st layer 
    if DATA2.notes[note] and not DATA2.notes[note].TYPE_DEVICE and DATA2.notes[note].layers[1] and layer == 1 then
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
        DATA2:Actions_PadOnFileDrop_ExportToRS5k(new_tr, filepath, note,section_data) 
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
        DATA2:Actions_PadOnFileDrop_ExportToRS5k(new_tr, filepath,note,section_data) 
        DATA2:Actions_PadOnFileDrop_AddMIDISend(new_tr)
        DATA2:TrackDataWrite(new_tr, {set_devicechild_deviceGUID=DATA2.notes[note].tr_GUID})
      end
      if layer == 1 and #DATA2.notes[note].layers == 0 then
        SetMediaTrackInfo_Value( DATA2.notes[note].tr_ptr, 'I_FOLDERDEPTH',1 )
        SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH',-1 )
      end
    end
    
  end
  -----------------------------------------------------------------------
  function DATA2:Actions_PadOnFileDrop(note, layer, filepath0,section_data0) 
    if not DATA2.tr_valid then return end
    -- validate additional stuff
    DATA2:TrackDataRead_ValidateMIDIbus()
    SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_FOLDERCOMPACT',1 ) -- folder compacted state (only valid on folders), 0=normal, 1=small, 2=tiny children
    DATA2:TrackDataRead(DATA2.tr_ptr)
    
    -- get fp
      if filepath0 then 
        DATA2:Actions_PadOnFileDrop_Sub(note, layer, filepath0,section_data0)
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
  
  function GUI_MODULE_DEVICE_stuff(DATA, note, layer, x_offs, y_offs) 
    local w_layername = math.floor(DATA.GUI.custom_devicew*0.5)
    local w_ctrls = DATA.GUI.custom_devicew - w_layername
    local w_ctrls_single = (w_ctrls / 9)
    local w_ctrls_single_q = math.floor(w_ctrls / 9)
    local frame_a = 0
    local backgr_col=DATA.GUI.custom_backcol2
    local backgr_fill_param = 0.2 
    local backgr_fill_name = 0
    
    DATA.GUI.buttons['devicestuff_'..'layer'..layer..'clear'] = { 
                        x=x_offs,
                        y=y_offs,
                        w=w_ctrls_single,
                        h=DATA.GUI.custom_deviceentryh,
                        --ignoremouse = DATA2.PARENT_TABSTATEFLAGS&2==0,
                        txt = 'X',
                        txt_fontsz = DATA.GUI.custom_devicectrl_txtsz,
                        frame_a = DATA.GUI.custom_framea,
                        onmouserelease = function() 
                          DATA2:Actions_Pad_Clear(note,layer) 
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
  function DATA2:Menu_Database_Actions(DATA)
    local name1, t1 = '[empty]', DATA2:Database_Load(DATA.extstate.CONF_database_map1) if t1 and t1.dbname then name1 = t1.dbname end
    local name2, t2 = '[empty]', DATA2:Database_Load(DATA.extstate.CONF_database_map2) if t2 and t2.dbname then name2 = t2.dbname end
    local name3, t3 = '[empty]', DATA2:Database_Load(DATA.extstate.CONF_database_map3) if t3 and t3.dbname then name3 = t3.dbname end
    local name4, t4 = '[empty]', DATA2:Database_Load(DATA.extstate.CONF_database_map4) if t4 and t4.dbname then name4 = t4.dbname end
    
    
    
    DATA:GUImenu({
    
    {str = 'Clear current database map',
     func = function()  
              local f = function()
                DATA2.database_map = {}
                DATA2:TrackDataWrite(_, {master_upd=true})
              end
              DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Clear') 
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
              local f = function()
                DATA2.PARENT_DATABASEMAP = DATA.extstate.CONF_database_map1
                DATA2.database_map = {}
                DATA2:Database_Load()
                DATA2:TrackDataWrite(_, {master_upd=true})
                DATA2:TrackDataRead()
              end
              DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Load from slot 1') 
              DATA.UPD.onGUIinit = true
            end},       
    {str = name2,
     func = function() 
              local f = function()
                DATA2.PARENT_DATABASEMAP = DATA.extstate.CONF_database_map2
                DATA2.database_map = {}
                DATA2:Database_Load()
                DATA2:TrackDataWrite(_, {master_upd=true})
                DATA2:TrackDataRead()
              end
              DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Load from slot 2') 
              DATA.UPD.onGUIinit = true
            end},     
    {str = name3,
     func = function() 
              local f = function()
                DATA2.PARENT_DATABASEMAP = DATA.extstate.CONF_database_map3
                DATA2.database_map = {}
                DATA2:Database_Load()
                DATA2:TrackDataWrite(_, {master_upd=true})
                DATA2:TrackDataRead()
              end
              DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Load from slot 3') 
              DATA.UPD.onGUIinit = true
            end},  
    {str = name4,
     func = function() 
              local f = function()
                DATA2.PARENT_DATABASEMAP = DATA.extstate.CONF_database_map4
                DATA2.database_map = {}
                DATA2:Database_Load()
                DATA2:TrackDataWrite(_, {master_upd=true})
                DATA2:TrackDataRead()
              end
              DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Load from slot 4') 
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
    local y_offs= DATA.GUI.custom_module_yoffs_database
    local x_offs_padctrls= x_offs
    local dbname_w = DATA.GUI.custom_databasew-DATA.GUI.custom_infoh-DATA.GUI.custom_knob_button_w
    GUI_MODULE_separator(DATA, 'databasestuff_sep', DATA.GUI.custom_module_xoffs_database,DATA.GUI.custom_module_yoffs_database) 
     
    if not (DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE ~=-1) then return end   
    
    local dbname_global = '[not loaded]'
    if DATA2.database_map and DATA2.database_map.dbname then dbname_global = DATA2.database_map.dbname end
    
    
    
    DATA.GUI.buttons.databasestuff_newkit = { x=x_offs,
                         y=y_offs,
                         w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'New kit',
                         txt_fontsz = DATA.GUI.custom_database_text,
                         onmouseclick = function()  
                                          local f = function() DATA2:Actions_DB_InitRandSamples()   end
                                          DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / New kit')  
                                        end
                         }
    x_offs = x_offs + DATA.GUI.custom_knob_button_w
    DATA.GUI.buttons.databasestuff_name = { x=x_offs,
                         y=y_offs,
                         w=dbname_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = dbname_global,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() DATA2:Menu_Database_Actions(DATA)  end  
                         }
    x_offs = x_offs + dbname_w
    DATA.GUI.buttons.databasestuff_help = { x=x_offs,
                           y=y_offs,
                           w=DATA.GUI.custom_infoh-1,
                           h=DATA.GUI.custom_infoh-1,
                           txt = '?',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() DATA2:Actions_Help(2) end,
                           }  
    
    
    
    
    -- pad ctrls
    local y_offs0 = y_offs + DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    local ctrl_w = math.floor(DATA.GUI.custom_databasew/2) 
    local x_offs = x_offs_padctrls
    DATA.GUI.buttons.databasestuff_padname = { x=x_offs,
                         y=y_offs0,
                         w=ctrl_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'Pad '..DATA2.PARENT_LASTACTIVENOTE..' name',
                         frame_a = 1,
                         frame_asel = 1,
                         frame_col = '#333333',
                         txt_fontsz =DATA.GUI.custom_database_text,
                         onmouseclick = function() end
                         }
    local name = ''
    if DATA2.PARENT_LASTACTIVENOTE and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] then name = DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].notename end
    DATA.GUI.buttons.databasestuff_padname_name = { x=x_offs+ ctrl_w,
                         y=y_offs0,
                         w=ctrl_w,
                         h=DATA.GUI.custom_infoh-1,
                         txt = name,
                         txt_fontsz = DATA.GUI.custom_database_text,
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
    y_offs0 = y_offs0  + DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    DATA.GUI.buttons.databasestuff_dbname = { x=x_offs,
                         y=y_offs0,
                         w=ctrl_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'DB name',
                         frame_a = 1,
                         frame_asel = 1,
                         frame_col = '#333333',
                         txt_fontsz = DATA.GUI.custom_database_text,
                         onmouseclick = function() end
                         }
    local dbname = ''
    if DATA2.PARENT_LASTACTIVENOTE and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] then dbname = DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].dbname end
    DATA.GUI.buttons.databasestuff_dbname_name = { x=x_offs+ctrl_w,
                         y=y_offs0,
                         w=ctrl_w,
                         h=DATA.GUI.custom_infoh-1,
                         txt = dbname,
                         txt_fontsz = DATA.GUI.custom_database_text,
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
                                                    local f = function()
                                                      DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].dbname = key
                                                      DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].dbflist = reaperDB[key]
                                                      DATA2:TrackDataWrite(_, {master_upd=true})
                                                      DATA2:TrackDataRead()
                                                      DATA2:Database_Load(_,true) 
                                                    end
                                                    DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Attach')  
                                                    
                                                    DATA.UPD.onGUIinit = true
                                            
                                          end,
                                          }
                                                                                                      
                             end
                             t[#t+1] = {
                                         str = '|Clear current pad',
                                         func = function() 
                                                  local f = function()
                                                   DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] = nil
                                                   DATA2:TrackDataWrite(_, {master_upd=true})
                                                   DATA2:TrackDataRead()
                                                   DATA2:Database_Load(_,true) 
                                                 end
                                                 DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Clear current')  
                                                 DATA.UPD.onGUIinit = true
                                               end}
                             DATA:GUImenu(t)
                             
                          end
                         end
                         }
    y_offs0 = y_offs0  + DATA.GUI.custom_infoh+DATA.GUI.custom_offset
    DATA.GUI.buttons.databasestuff_lock = { x=x_offs,
                         y=y_offs0,
                         w=ctrl_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'Lock',
                         frame_a = 1,
                         frame_asel = 1,
                         frame_col = '#333333',
                         txt_fontsz = DATA.GUI.custom_database_text,
                         onmouseclick = function() end
                         }
    local lockstatename = 'Off'
    if DATA2.PARENT_LASTACTIVENOTE and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE] and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].lock and DATA2.database_map.map[DATA2.PARENT_LASTACTIVENOTE].lock  == 1 then lockstatename = 'On' end
    DATA.GUI.buttons.databasestuff_lock_state = { x=x_offs+ctrl_w,
                         y=y_offs0,
                         w=ctrl_w,
                         h=DATA.GUI.custom_infoh-1,
                         txt = lockstatename,
                         txt_fontsz = DATA.GUI.custom_database_text,
                         onmouseclick = function() 
                          local f = function()  DATA2:Actions_DB_lock(DATA2.PARENT_LASTACTIVENOTE)  end
                          DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Lock')  
                         end
                         }  
    y_offs0 = y_offs0  + DATA.GUI.custom_infoh*2+DATA.GUI.custom_offset
    DATA.GUI.buttons.databasestuff_randcurrent = { x=x_offs,
                         y=y_offs0,
                         w=DATA.GUI.custom_databasew,
                         h=DATA.GUI.custom_infoh-1,
                         txt = 'New sample',
                         txt_fontsz = DATA.GUI.custom_database_text,
                         onmouseclick = function() 
                          local f = function() DATA2:Actions_DB_InitRandSamples(DATA2.PARENT_LASTACTIVENOTE)    end
                          DATA2:ProcessUndoBlock(f, 'RS5k manager / Database /  New sample')  
                         end}                       
    
  end
  ------------------------------------------------------------------------------   
  function DATA2:Actions_DB_lock(note)
    if not DATA2.database_map then DATA2.database_map = {} end
    DATA2.database_map.valid = true
    if not DATA2.database_map.map then DATA2.database_map.map = {} end
    if not DATA2.database_map.dbname then DATA2.database_map.dbname = 'Untitled' end
    if not DATA2.database_map.map[note] then DATA2.database_map.map[note] = {} end  
    local lockstate = DATA2.database_map.map[note].lock or 0
    DATA2.database_map.map[note].lock = lockstate~1
    DATA2:TrackDataWrite(_, {master_upd=true})
    DATA2:TrackDataRead()
    DATA.UPD.onGUIinit = true
  end
  ------------------------------------------------------------------------------   
  function GUI_MODULE_DEVICE(DATA)  
    for key in pairs(DATA.GUI.buttons) do if key:match('devicestuff_') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.PARENT_TABSTATEFLAGS or ( DATA2.PARENT_TABSTATEFLAGS and DATA2.PARENT_TABSTATEFLAGS&2==0) then return end
    
    GUI_MODULE_separator(DATA, 'devicestuff_sep', DATA.GUI.custom_module_xoffs_device,DATA.GUI.custom_module_yoffs_device) 
    
    if not (DATA2.PARENT_LASTACTIVENOTE and DATA2.PARENT_LASTACTIVENOTE~=-1 and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE] ) then return end
    local layers_cnt = 0
    if DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].layers then  layers_cnt = #DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].layers end
    local name = '' 
    if DATA2.PARENT_LASTACTIVENOTE and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE] and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].name and not DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].TYPE_DEVICE  then 
      name = '[Note '..DATA2.PARENT_LASTACTIVENOTE..' / '..DATA2:internal_FormatMIDIPitch(DATA2.PARENT_LASTACTIVENOTE)..'] '..DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].name 
     elseif DATA2.PARENT_LASTACTIVENOTE and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE]  and DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].TYPE_DEVICE ==true then
      name = '[Device '..DATA2.PARENT_LASTACTIVENOTE..' / '..DATA2:internal_FormatMIDIPitch(DATA2.PARENT_LASTACTIVENOTE)..'] '..(DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].device_name or '')
    end
    
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_device+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    local y_offs= DATA.GUI.custom_module_yoffs_device
    local x_offs_ctrls = x_offs
    local devname_w = DATA.GUI.custom_devicew-DATA.GUI.custom_infoh-DATA.GUI.custom_knob_button_w
    
    
    DATA.GUI.buttons.devicestuff_name = { x=x_offs,
                         y=y_offs,
                         w=devname_w-DATA.GUI.custom_offset,
                         h=DATA.GUI.custom_infoh-1,
                         txt = name,
                         txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                         onmouseclick = function() DATA2:Menu_DrumRack_Actions(DATA2.PARENT_LASTACTIVENOTE) end
                         }
    x_offs = x_offs + devname_w    
    local txt_a = nil
    if DATA2.notes[DATA2.PARENT_LASTACTIVENOTE].TYPE_DEVICE ~= true then txt_a = DATA.GUI.custom_framea end
    DATA.GUI.buttons.devicestuff_showtrack = { x=x_offs,
                         y=y_offs,
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
                           y=y_offs,
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
    
                     
    y_offs = y_offs + DATA.GUI.custom_infoh + DATA.GUI.custom_offset
    y_offs_list = y_offs
    local x_offs= math.floor(DATA.GUI.custom_module_xoffs_device+DATA.GUI.custom_moduleseparatorw)+DATA.GUI.custom_offset
    if DATA2.notes and DATA2.notes[PARENT_LASTACTIVENOTE] and DATA2.notes[PARENT_LASTACTIVENOTE].layers then 
      for layer = 1, #DATA2.notes[PARENT_LASTACTIVENOTE].layers do
        GUI_MODULE_DEVICE_stuff(DATA, PARENT_LASTACTIVENOTE, layer, x_offs, y_offs)  
        y_offs = y_offs + DATA.GUI.custom_deviceentryh 
      end
    end  
    local listh = y_offs - y_offs_list
    DATA.GUI.buttons.devicestuff_frame_fillactive = { x=x_offs,
                          y=y_offs_list,
                          w=DATA.GUI.custom_devicew,
                          h=listh,
                          ignoremouse = true,
                          frame_a =1,
                          frame_col = '#333333',
                          }
                          
                          
    y_offs = y_offs_list + listh+DATA.GUI.custom_offset
    DATA.GUI.buttons.devicestuff_droparea = { x=x_offs,
                          y=y_offs,
                          w=DATA.GUI.custom_devicew-1,
                          h=DATA.GUI.custom_moduleH-listh-DATA.GUI.custom_infoh-DATA.GUI.custom_offset*3,--DATA.GUI.custom_deviceh-y_offs_list+ ,
                          --ignoremouse = true,
                          txt = 'Drop new instrument here',
                          txt_fontsz = DATA.GUI.custom_device_droptxtsz,
                          --frame_a =0.1,
                          --frame_col = '#333333',
                          onmousefiledrop = function() DATA2:Actions_PadOnFileDrop(DATA2.PARENT_LASTACTIVENOTE, layers_cnt+1) end,
                          ignoreboundarylimit = true,
                          }  
                         
  end
  -----------------------------------------------------------------------------  
  function GUI_MODULE_PADOVERVIEW_generategrid(DATA)
    if not DATA.GUI.buttons.padgrid then return end
    -- draw notes
    --local cellside = math.floor(DATA.GUI.custom_padgridw / 4)
    local cellside = math.floor((DATA.GUI.custom_moduleH-DATA.GUI.custom_offset) /31)
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
      if DATA2.playingnote and DATA2.playingnote == note  then blockcol = '#ffe494' backgr_fill2 = 0.7 end
      
      
      if note%4 == 0 then x_offs = math.floor(DATA.GUI.buttons.padgrid.x) end
      local reduce = 1
      if cellside < 20 then reduce =0 end
      DATA.GUI.buttons['padgrid_but'..note] = { x=  x_offs,
                          y=math.floor(DATA.GUI.custom_module_yoffs_padoverview+DATA.GUI.custom_moduleH - cellside*(1+(math.floor(note/4)))),
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
    
    
    if DATA2.PARENT_DRRACKSHIFT then
      local row_cnt = math.floor(127/4)
      local activerow = DATA2.PARENT_DRRACKSHIFT  / 4
      DATA.GUI.buttons.padgrid_activerect = { x=DATA.GUI.buttons.padgrid.x,
                            y=DATA.GUI.buttons.padgrid.y+DATA.GUI.buttons.padgrid.h-DATA.GUI.buttons.padgrid.w-cellside*(activerow),
                            w=DATA.GUI.buttons.padgrid.w,
                            h=DATA.GUI.buttons.padgrid.w,
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
    local y_offs= DATA.GUI.custom_module_yoffs_padoverview
    GUI_MODULE_separator(DATA, 'padgrid_sep', DATA.GUI.custom_module_xoffs_padoverview,DATA.GUI.custom_module_yoffs_padoverview) 
    DATA.GUI.buttons.padgrid = { x=math.floor(x_offs),
                          y=y_offs,
                          w=math.floor(DATA.GUI.custom_padgridw),
                          h=DATA.GUI.custom_moduleH,
                          txt = '',
                          
                          val = 0,
                          frame_a = 0,
                          frame_asel = 0,
                          backgr_fill = 0,
                          onmousedrag =   function() 
                                            if not DATA.GUI.buttons.padgrid.val_abs then return end
                                            local offs = VF_lim(DATA.GUI.buttons.padgrid.val_abs)
                                            local row_cnt = math.floor(127/4)
                                            local activerow = math.floor((1-offs)*row_cnt)
                                            
                                            -- handle quantize
                                            if DATA.extstate.UI_po_quantizemode == 0 then 
                                              local qblock = 4
                                              if activerow < 1 then activerow = 0 end
                                              for block = 0, 6 do if activerow >=block*4+1 and activerow <(block*4)+4+1 then activerow =block*4+1 end end
                                              activerow = math.min(activerow, 28)
                                             elseif DATA.extstate.UI_po_quantizemode == 1 then 
                                              for block = 0, 13 do if activerow >=block*2+1 and activerow <(block*2)+2+1 then activerow = block*2+1 end end
                                              activerow = math.min(activerow, 28)         
                                             elseif DATA.extstate.UI_po_quantizemode == 2 then 
                                              
                                              activerow = math.min(activerow, 28)                                                 
                                            end
                                            local out_offs = math.floor(activerow*4)
                                            if out_offs ~= DATA2.PARENT_DRRACKSHIFT then 
                                              DATA2.PARENT_DRRACKSHIFT = out_offs
                                              GUI_MODULE_PADOVERVIEW_generategrid(DATA)
                                              GUI_MODULE_DRUMRACK(DATA)  
                                              DATA2:TrackDataWrite(_, {master_upd=true})
                                            end
                                          end,
                          onmousefiledrop = function() 
                          
                            local note = DATA2.PARENT_DRRACKSHIFT
                            for i = note, 128 do if not DATA2.notes[i] then note = i break end end -- serach for free note
                            if note ~= 128 then  DATA2:Actions_PadOnFileDrop(note)  end
                          end,
                          }
    DATA.GUI.buttons.padgrid.onmouseclick = DATA.GUI.buttons.padgrid.onmousedrag
    DATA.GUI.buttons.padgrid.onmouserelease = DATA.GUI.buttons.padgrid.onmousedrag
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
  function DATA2:Menu_Sampler_Actions_SetStartToLoudestPeak() 
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
  function DATA2:Menu_Sampler_Actions_CropToAudibleBoundaries()
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
  function  DATA2:Menu_Sampler_Actions()   
    local t = {
              
  {str = '#Actions'},
  {str = 'Crop sample to audible boundaries, threshold '..DATA.extstate.CONF_cropthreshold..'dB',
   func = function() DATA2:Menu_Sampler_Actions_CropToAudibleBoundaries()   end},

  {str = 'Set start offset to a loudest peak',
   func = function() DATA2:Menu_Sampler_Actions_SetStartToLoudestPeak()   end},
   
  
              }
    DATA:GUImenu(t)
  end 
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_peaks()
    if not (DATA2.cursplpeaks and DATA2.cursplpeaks.peaks) then return end
    local note, layer = DATA2.cursplpeaks.note,DATA2.cursplpeaks.layer
    if not (DATA2.notes and DATA2.notes[note] and DATA2.notes[note].layers and DATA2.notes[note].layers[layer]) then return end
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
    local actions_cnt = 4
    local action_h = math.floor(DATA.GUI.custom_sampler_peakareah / actions_cnt)
    local x_offs = DATA.GUI.buttons.sampler_frame.x +DATA.GUI.custom_samplerW-DATA.GUI.custom_knob_button_w
    local y_offs = DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset
    local src_t, note = DATA2:internal_GetActiveNoteLayerTable()
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
                        onmouseclick = function() 
                                          local f = function(src_t)                          
                                            if src_t.SPLLISTDB == 1 and ( src_t.noteID and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[src_t.noteID] and DATA2.database_map.map[src_t.noteID].samples) then 
                                              DATA2:Actions_Sampler_NextPrevSample(src_t, 1, DATA2.database_map.map[src_t.noteID].samples)  
                                             else
                                              DATA2:Actions_Sampler_NextPrevSample(src_t, 1)
                                            end
                                          end
                                          DATA2:ProcessUndoBlock(f, 'RS5k manager / Sampler / Prev sample',src_t) 
                                        end
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
                        onmouseclick = function() 
                                          local f = function(src_t)
                                            if src_t.SPLLISTDB == 1 and ( src_t.noteID and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[src_t.noteID] and DATA2.database_map.map[src_t.noteID].samples) then 
                                              DATA2:Actions_Sampler_NextPrevSample(src_t, nil, DATA2.database_map.map[src_t.noteID].samples)  
                                             else
                                              DATA2:Actions_Sampler_NextPrevSample(src_t, nil)
                                            end
                                          end
                                          DATA2:ProcessUndoBlock(f, 'RS5k manager / Sampler / Next sample',src_t) 
                                        end
                        }                          
    y_offs = y_offs + action_h
    DATA.GUI.buttons.sampler_randspl = { x=x_offs ,
                        y=y_offs,
                        w=DATA.GUI.custom_knob_button_w,
                        h=action_h-DATA.GUI.custom_offset,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = 'Rand spl',
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouseclick = function() 
                                          local f = function(src_t)
                                            if src_t.SPLLISTDB == 1 and ( src_t.noteID and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[src_t.noteID] and DATA2.database_map.map[src_t.noteID].samples) then 
                                                                                        DATA2:Actions_Sampler_NextPrevSample(src_t,2, DATA2.database_map.map[src_t.noteID].samples)  
                                                                                       else
                                                                                        DATA2:Actions_Sampler_NextPrevSample(src_t, 2)
                                                                                      end
                                          end
                                          DATA2:ProcessUndoBlock(f, 'RS5k manager / Sampler / Rand sample',src_t)  
                                        end
                        }  
    y_offs = y_offs + action_h
    local st_w = 20
    DATA.GUI.buttons.sampler_sdbstate = { x=x_offs ,
                        y=y_offs,
                        w=action_h,--DATA.GUI.custom_knob_button_w,
                        h=action_h,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        --txt = 'Rand spl',
                        state = src_t.SPLLISTDB and src_t.SPLLISTDB == 1,
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouseclick = function()  
                                          src_t.SPLLISTDB=src_t.SPLLISTDB~1--math.abs(1-src_t.SPLLISTDB
                                          DATA2:TrackDataWrite(src_t.tr_ptr, {SPLLISTDB=src_t.SPLLISTDB}) GUI_MODULE_SAMPLER_Section_Actions(DATA)   end,}
    local txt_a
    if not( note and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[note] and DATA2.database_map.map[note].samples) then txt_a = DATA.GUI.custom_anavailableparamtxta end
    DATA.GUI.buttons.sampler_sdbstate_name = { x=x_offs +st_w+DATA.GUI.custom_offset*3,
                        y=y_offs,
                        w=DATA.GUI.custom_knob_button_w-st_w-DATA.GUI.custom_offset*3,
                        h=action_h,
                        txt_a = txt_a,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = 'DB',
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouseclick = function()  
                                        end,                        
                        }                        
                        
  end
  
  ----------------------------------------------------------------------
  function DATA2:ProcessUndoBlock(f, name, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10) 
    Undo_BeginBlock2( 0)
    defer(f(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10))
    Undo_EndBlock2( 0, name, 0xFFFFFFFF )
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
    local modeh = math.floor(DATA.GUI.custom_sampler_peakareah/3)
    local  x_offs = DATA.GUI.buttons.sampler_frame.x
    local y_offs = DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset
    local wbut = DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset
    DATA.GUI.buttons.sampler_mode1 = { x= x_offs,
                        y=y_offs,
                        w=wbut,
                        h=modeh-1,
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
    y_offs=y_offs+modeh
    DATA.GUI.buttons.sampler_mode2 = { x= x_offs,
                        y=y_offs,
                        w=wbut,
                        h=modeh-1,
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
    y_offs=y_offs+modeh
    local backgr_fill = 0
    local backgr_col = DATA.GUI.custom_backcol2
    if spl_t.instrument_noteoff == 1 then backgr_fill = 0.2 end
    DATA.GUI.buttons.sampler_mode3_name = { x=x_offs,
                        y=y_offs,
                        w=wbut,---DATA.GUI.custom_offset,
                        h=modeh,
                        --txt_a =DATA.GUI.custom_anavailableparamtxta,
                        --ignoremouse = true,
                        frame_a = DATA.GUI.custom_framea,
                        backgr_col=backgr_col,
                        backgr_fill=backgr_fill,
                        txt = 'NoteOff',
                        txt_fontsz = DATA.GUI.custom_sampler_ctrl_txtsz,
                        onmouseclick = function()  
                                          spl_t.instrument_noteoff=spl_t.instrument_noteoff~1
                                          TrackFX_SetParamNormalized( spl_t.tr_ptr, spl_t.instrument_pos, 11, spl_t.instrument_noteoff ) 
                                          DATA2:TrackDataRead_GetChildrens_InstrumentParams(spl_t) -- refresh state
                                          GUI_MODULE_SAMPLER_Section_Loopstate(DATA)
                                        end                      
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
    local y_offs= DATA.GUI.custom_module_yoffs_sampler--
    GUI_MODULE_separator(DATA, 'sampler_sep', DATA.GUI.custom_module_xoffs_sampler,DATA.GUI.custom_module_yoffs_sampler) 
    -- sample name  
    
      local spl_t, note, layer = DATA2:internal_GetActiveNoteLayerTable()
      if not spl_t then return end 
      name = '[Layer '..layer..'] '..(spl_t.name or '')
      DATA.GUI.buttons.sampler_frame = { x=x_offs,
                            y=y_offs+DATA.GUI.custom_infoh+DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_samplerW,
                            h=DATA.GUI.custom_deviceh-DATA.GUI.custom_offset+DATA.GUI.custom_offset,
                            ignoremouse = true,
                            frame_a =1,
                            frame_col = '#333333',
                            ignoreboundarylimit = true,
                            } 
      DATA.GUI.buttons.sampler_name = { x=x_offs,
                           y=y_offs,
                           w=DATA.GUI.custom_sampler_namebutw-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = name,
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           }
      x_offs = x_offs+DATA.GUI.custom_sampler_namebutw                   
      DATA.GUI.buttons.Menu_Sampler_Actions = { x=x_offs,
                           y=y_offs,
                           w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'Actions',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function()  DATA2:Menu_Sampler_Actions()  end,
                           }  
      x_offs = x_offs+DATA.GUI.custom_knob_button_w
      DATA.GUI.buttons.sampler_show = { x=x_offs,
                           y=y_offs,
                           w=DATA.GUI.custom_knob_button_w-DATA.GUI.custom_offset,
                           h=DATA.GUI.custom_infoh-1,
                           txt = 'FX',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() 
                                              if spl_t.instrument_pos then
                                              --DATA2:Actions_ShowInstrument(note, layer) 
                                                TrackFX_Show( spl_t.tr_ptr, spl_t.instrument_pos, 1 ) 
                                              end
                                            end,
                           }
      x_offs = x_offs+DATA.GUI.custom_knob_button_w--DATA.GUI.custom_infoh
      DATA.GUI.buttons.sampler_help = { x=x_offs,
                           y=y_offs,
                           w=DATA.GUI.custom_infoh,
                           h=DATA.GUI.custom_infoh-1,
                           txt = '?',
                           txt_fontsz = DATA.GUI.custom_tabnames_txtsz,
                           onmouserelease = function() 
                                              DATA2:Actions_Help(4)
                                            end,
                           }                           
                           
                           
                           
    local txt = ''
    if not spl_t.ISRS5K and spl_t.instrument_fxname then txt = '['..spl_t.instrument_fxname..']' end
    DATA.GUI.buttons.sampler_framepeaks = { x= DATA.GUI.buttons.sampler_frame.x + DATA.GUI.custom_knob_button_w,
                            y=DATA.GUI.buttons.sampler_frame.y + DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_samplerW - DATA.GUI.custom_knob_button_w*2-DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_sampler_peakareah,
                            --ignoremouse = true,
                            txt = txt,
                            frame_a = DATA.GUI.custom_framea,
                            data = {['datatype'] = 'samplepeaks'},
                            onmousefiledrop = function() if DATA2.PARENT_LASTACTIVENOTE then 
                              reaper.Undo_BeginBlock2( 0)
                              DATA2:Actions_PadOnFileDrop(DATA2.PARENT_LASTACTIVENOTE) 
                              reaper.Undo_EndBlock2( 0, 'RS5k manager / Sampler / Drop file', 0xFFFFFFFF )--                                          
                              end end,
                            onmouseclick = function() if DATA2.PARENT_LASTACTIVENOTE then DATA2:Actions_StuffNoteOn(DATA2.PARENT_LASTACTIVENOTE) end  end,
                            onmouseclickR = function() DATA2:Menu_Sampler_Actions()  end,
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
                                          if not (t.butkey and DATA.GUI.buttons[t.butkey..'frame'] and DATA.GUI.buttons[t.butkey..'frame'].val) then return end
                                          local new_val = DATA.GUI.buttons[t.butkey..'frame'].val
                                          if params_t.func_atclick then params_t.func_atclick(new_val) end
                                        end,
                        onmousedrag = function()
                              DATA2.ONPARAMDRAG = true
                              if not (t.butkey and DATA.GUI.buttons[t.butkey..'frame'] and DATA.GUI.buttons[t.butkey..'frame'].val) then return end
                              local new_val = DATA.GUI.buttons[t.butkey..'frame'].val
                              params_t.func_app(new_val)
                              params_t.func_refresh()
                              DATA.GUI.buttons[t.butkey..'val'].txt = src_t[t.ctrlval_format_key]
                                local val_norm = src_t[t.ctrlval_key] 
                                if t.ctrlval_max and t.ctrlval_min then val_norm = (val_norm - t.ctrlval_min) / (t.ctrlval_max - t.ctrlval_min) end
                                if DATA.GUI.buttons[t.butkey..'knob'] then DATA.GUI.buttons[t.butkey..'knob'].val = val_norm end
                              DATA.GUI.buttons[t.butkey..'val'].refresh = true
                            end,
                        onmousedoubleclick = function() 
                                if not t.ctrlval_default then return end
                                params_t.func_app(t.ctrlval_default)
                                params_t.func_refresh()
                                if not (t.butkey and DATA.GUI.buttons[t.butkey..'val'] and DATA.GUI.buttons[t.butkey..'val'].txt) then return end
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
                                if not (t.butkey and DATA.GUI.buttons[t.butkey..'frame'] and DATA.GUI.buttons[t.butkey..'frame'].val) then return end
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
                          txt_a = t.txt_a,
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
                        txt_a = t.txt_a,
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
  function GUI_MODULE_SAMPLER_Section_SplReadouts_applytune(DATA, src_t, inc) 
    local tunenorm = src_t.instrument_tune
    local tunenorm0 = tunenorm
    local tunereal = tunenorm * 160 - 80
    tunereal = tunereal +inc
    tunenorm = (tunereal+80) / 160
    local tunenorm_diff = tunenorm - tunenorm0
    local cnt_selection = 0 for keynote in pairs(DATA2.PADselection) do if DATA2.PADselection[keynote] then cnt_selection = cnt_selection + 1 end end
    if cnt_selection <2 then TrackFX_SetParamNormalized( src_t.tr_ptr, src_t.instrument_pos, 15, tunenorm ) return end
    for keynote in pairs(DATA2.PADselection) do
      if DATA2.PADselection[keynote]  then 
        if DATA2.notes[keynote].layers then
          for layer in pairs(DATA2.notes[keynote].layers) do
            local tunenorm = TrackFX_GetParamNormalized( DATA2.notes[keynote].layers[layer].tr_ptr,  DATA2.notes[keynote].layers[layer].instrument_pos, 15 )
            TrackFX_SetParamNormalized(  DATA2.notes[keynote].layers[layer].tr_ptr,  DATA2.notes[keynote].layers[layer].instrument_pos, 15 , tunenorm + tunenorm_diff)
            
          end
        end
      end
    end
    
    DATA2:TrackDataRead_GetChildrens_InstrumentParams(src_t)
    GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) -- referesjh readouts
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_SAMPLER_Section_SplReadouts(DATA) 
    if not DATA.GUI.buttons.sampler_frame then return end
    local src_t, note = DATA2:internal_GetActiveNoteLayerTable()
    
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
                          onmouserelease = function()GUI_MODULE_SAMPLER_Section_SplReadouts_applytune(DATA, src_t, 0.05)  end
                          }
      DATA.GUI.buttons['sampler_tune_centval'] = { x= xoffs+woffs,--+arc_shift,
                          y=yoffs+h_tune_single,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = '.05',
                          ignoremouse = true,
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
                          onmouserelease = function()GUI_MODULE_SAMPLER_Section_SplReadouts_applytune(DATA, src_t, -0.05) end
                          }                        
      DATA.GUI.buttons['sampler_tune_stup'] = { x= xoffs+woffs+w_tune_single,--+arc_shift,
                          y=yoffs,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = '+',
                          frame_a = DATA.GUI.custom_framea,
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          onmouserelease = function()GUI_MODULE_SAMPLER_Section_SplReadouts_applytune(DATA, src_t, 1) end
                          }
      DATA.GUI.buttons['sampler_tune_stval'] = { x= xoffs+woffs+w_tune_single,--+arc_shift,
                          y=yoffs+h_tune_single,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          ignoremouse = true,
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
                          onmouserelease = function()GUI_MODULE_SAMPLER_Section_SplReadouts_applytune(DATA, src_t,-1) end
                          }                         
      DATA.GUI.buttons['sampler_tune_octup'] = { x= xoffs+woffs+w_tune_single*2,
                          y=yoffs,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          txt = '+',
                          frame_a = DATA.GUI.custom_framea,
                          txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                          onmouserelease = function()GUI_MODULE_SAMPLER_Section_SplReadouts_applytune(DATA, src_t, 12) end
                          }
      DATA.GUI.buttons['sampler_tune_octval'] = { x= xoffs+woffs+w_tune_single*2,
                          y=yoffs+h_tune_single,
                          w=w_tune_single-1,
                          h=h_tune_single,
                          ignoremouse = true,
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
                          onmouserelease = function()GUI_MODULE_SAMPLER_Section_SplReadouts_applytune(DATA, src_t, -12) end
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
    local reaeqstate,reaeqstate_a = 'Off',DATA.GUI.custom_anavailableparamtxta if src_t.fx_reaeq_bandenabled then reaeqstate = 'On' reaeqstate_a = nil end
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
    if DATA.ontrignoteTS and  os.clock() - DATA.ontrignoteTS >1 then StuffMIDIMessage( 0, 0x80, DATA.ontrignote, 0 ) DATA.ontrignoteTS = nil end
    
    DATA2.playingnote_trig = false
    
    local t_recent = {}
    local idx = 0
    local evt_id = 0
    while true do
      retvalr, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(idx)
      if retvalr == 0 then break end -- stop if return null sequence
      idx = idx + 1 
      if (devIdx & 0x10000) == 0 or devIdx == 0x1003e then -- should works without this after REAPER6.39rc2, so thats just in case
        local isNoteOn = rawmsg:byte(1)>>4 == 0x9
        local isNoteOff = rawmsg:byte(1)>>4 == 0x8
        if isNoteOn or isNoteOff then
          evt_id = evt_id + 1 
          t_recent[evt_id] = {retval=retval, rawmsg=rawmsg, tsval=tsval, devIdx=devIdx, projPos=projPos, projLoopCnt=projLoopCnt,playingnote = rawmsg:byte(2) }
        end
      end
    end 
    
    if t_recent and t_recent[1] then
      DATA2.playingnote = t_recent[1].playingnote
      if not DATA2.last_playingnote or (DATA2.last_playingnote and DATA2.playingnote ~= DATA2.last_playingnote) then
        DATA2.playingnote_trig = true
        DATA2.last_playingnote = DATA2.playingnote
      end 
    end
    
    if DATA2.playingnote_trig == true then 
       if  DATA.extstate.UI_incomingnoteselectpad == 1 then
        DATA2.PARENT_LASTACTIVENOTE = DATA2.playingnote
        DATA2:TrackDataWrite(_,{master_upd=true}) 
        GUI_MODULE_DEVICE(DATA)  
        GUI_MODULE_SAMPLER(DATA)
        GUI_MODULE_DRUMRACK(DATA) 
      end
      GUI_MODULE_PADOVERVIEW_generategrid(DATA) -- refresh pad
      GUI_MODULE_DRUMRACK_drawlayout_pad_refreshplay(DATA)
    end
    
    
    if DATA2.FORCEONPROJCHANGE == true then DATA_RESERVED_ONPROJCHANGE(DATA) DATA2.FORCEONPROJCHANGE = nil end
    DATA_RESERVED_DYNUPDATE_ExtActions()
    
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE_ExtActions()
    local actions = gmem_read(1025)
    if actions == 0 then return end
    if actions == 1 then 
      local f = function() DATA2:Actions_DB_InitRandSamples()  end
      DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / New kit') 
    end -- Device / New kit
    
    if actions == 2 then   -- prev sample
      local f = function()
        local src_t = DATA2:internal_GetActiveNoteLayerTable()
        if src_t.SPLLISTDB == 1 and ( src_t.noteID and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[src_t.noteID] and DATA2.database_map.map[src_t.noteID].samples) then 
          DATA2:Actions_Sampler_NextPrevSample(src_t,1, DATA2.database_map.map[src_t.noteID].samples)  
         else
          DATA2:Actions_Sampler_NextPrevSample(src_t, 1)
        end
      end
      DATA2:ProcessUndoBlock(f, 'RS5k manager / Sampler / Prev sample')  
    end
    
    if actions == 3 then   -- next sample
      local f = function()
        local src_t = DATA2:internal_GetActiveNoteLayerTable()
        if src_t.SPLLISTDB == 1 and ( src_t.noteID and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[src_t.noteID] and DATA2.database_map.map[src_t.noteID].samples) then 
          DATA2:Actions_Sampler_NextPrevSample(src_t,0, DATA2.database_map.map[src_t.noteID].samples)  
         else
          DATA2:Actions_Sampler_NextPrevSample(src_t, 0)
        end
      end
      DATA2:ProcessUndoBlock(f, 'RS5k manager / Sampler / Next sample')  
    end
    
    if actions == 4 then   -- rand sample
      local f = function()
        local src_t = DATA2:internal_GetActiveNoteLayerTable()
        if src_t.SPLLISTDB == 1 and ( src_t.noteID and DATA2.database_map and DATA2.database_map.map and DATA2.database_map.map[src_t.noteID] and DATA2.database_map.map[src_t.noteID].samples) then 
          DATA2:Actions_Sampler_NextPrevSample(src_t,2, DATA2.database_map.map[src_t.noteID].samples)  
         else
          DATA2:Actions_Sampler_NextPrevSample(src_t, 2)
        end
      end
      DATA2:ProcessUndoBlock(f, 'RS5k manager / Sampler / Rand sample')  
    end
    
    if actions == 5 then   -- rand database sample
      local f = function() DATA2:Actions_DB_InitRandSamples(DATA2.PARENT_LASTACTIVENOTE)  end
      DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Rand sample') 
    end

    if actions == 6 then   -- lock active note database changes 
      local f = function() DATA2:Actions_DB_lock(DATA2.PARENT_LASTACTIVENOTE)  end 
      DATA2:ProcessUndoBlock(f, 'RS5k manager / Database / Lock active note') 
    end
    
    if actions == 7 then   -- drumrack solo
      local f = function() DATA2:Actions_Pad_SoloMute(DATA2.PARENT_LASTACTIVENOTE,_,true)  end 
      DATA2:ProcessUndoBlock(f, 'RS5k manager / DrumRack / Solo active note') 
    end
    
    if actions == 8 then   -- drumrack mute
      local f = function() DATA2:Actions_Pad_SoloMute(DATA2.PARENT_LASTACTIVENOTE,_,_,true)  end 
      DATA2:ProcessUndoBlock(f, 'RS5k manager / DrumRack / Mute active note') 
    end

    if actions == 9 then   -- drumrack clear
      local f = function() DATA2:Actions_Pad_Clear(note, DATA2.PARENT_LASTACTIVENOTE)  end 
      DATA2:ProcessUndoBlock(f, 'RS5k manager / DrumRack / Clear active note') 
    end
    
    
    gmem_write(1025,0 )
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) if ret then local ret2 = VF_CheckReaperVrs(6.69,true) if ret2 then  
    gmem_attach('RS5K_manager')
    main() 
  end end
  
  
  
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