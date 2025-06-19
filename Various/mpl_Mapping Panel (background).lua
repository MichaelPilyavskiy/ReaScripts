-- @description MappingPanel
-- @version 4.21
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Script for link parameters across tracks
-- @provides
--    [jsfx] mpl_MappingPanel_master.jsfx 
--    [jsfx] mpl_MappingPanel_slave.jsfx
-- @changelog
--    + Add description for slave JSFX per track mode
--    # Variation: fix error on empty data




  local vrs = 4.21

  --[[ gmem map: 
  Master
  [slider / gmem] 1-16: knob values
  [gmem] 100: value changed from script
  
  Slave
  [slider] 1-16 [float] knob values
  [slider] 17-32 [int] to which master knob linked
  [slider] 33-48 [int] &1 mute, then 8 bytes tension, then 16 bytes scale max
  [slider] 49-64 [int] 16 bytes lim min, then 16bytes lim max, then 16 bytes scale min   
  ]]
 
  --[[
    -- script for assign last touched parameter to macro
    macro_id = 3
    reaper.gmem_attach('MappingPanel')
    reaper.gmem_write(1024, 1)
    reaper.gmem_write(1025, macro_id)
  ]]
  
   --------------------------------------------------------------------------------  init globals
     for key in pairs(reaper) do _G[key]=reaper[key] end
     app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
     if app_vrs < 7.06 then return reaper.MB('This script require REAPER 7.06+','',0) end
     local ImGui
     
     if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
     package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
     ImGui = require 'imgui' '0.9.3.2'
     
     
     
   -------------------------------------------------------------------------------- init external defaults 
   EXT = {
           viewport_posX = 10,
           viewport_posY = 10,
           viewport_posW = 640,
           viewport_posH = 400, 
           
           CONF_setslaveparamtomaster = 1,
           CONF_randstrength = 1,
           CONF_randstrength2 = 1,
           CONF_randpreventrandfromlimits = 0,
           CONF_mode = 0,
           CONF_addlinkrenameflags = 1|2, -- &1 rename &2 only if default name
           
         }
   -------------------------------------------------------------------------------- INIT data
   DATA = {
           ES_key = 'MPL_MappingPanel',
           UI_name = 'Mapping panel', 
           upd = true, 
           activetab = 0, -- !=1 knobs  1 menu  2 varilist 3 links 4 actions  
           knobscollapsed = 0, 
           LTP={}, 
           touchstate = false,
           snapback = {},
           }
           
   -------------------------------------------------------------------------------- UI init variables
   
   --local ctx
     UI = {    popups = {},
     
             -- font
               font='Arial',
               font1sz=15,
               font2sz=12,
             -- mouse
               hoverdelay = 0.8,
               hoverdelayshort = 0.8,
               
             -- size / offset
               spacingX = 4,
               spacingY = 3,
               linkbutsz = 8 ,
               linkH = 100,
               
             -- colors / alpha
               main_col = 0x7F7F7F, -- grey
               textcol = 0xFFFFFF,
               textcol_a_enabled = 1,
               textcol_a_disabled = 0.5,
               but_hovered = 0x878787,
               windowBg = 0x303030,
               
             --[[ size
               main_butw = 80,
               main_buth = 50,
               main_knobtxth = 36,]]
           }
      
      
      
   
      
  ------------------------------------------------------------------
  function DATA:SlaveJSFX_Write(t)
    if not t then return end
    local tr = t.slave_jsfx_tr
    
    
    
    if EXT.CONF_mode == 0 then
      --1-16 [float] knob values  
        --if t.flags_mute == 1 then TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID, t.slave_jsfx_param) end
        
      --17-32 [int] to which master knob linked
        --TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID+16, t.slave_jsfx_paramID)
        
      --33-48 [int] &1 mute, then 8 bytes tension, then 16 bytes scale max
        local out_hex1 = 0
        out_hex1 =out_hex1 + t.flags_mute
        out_hex1 =out_hex1 + (math.floor(t.flags_tension * 15) <<1)
        out_hex1 =out_hex1 + (math.floor(t.hexarray_scale_max*255)<<9) 
        TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID+16*2, out_hex1)
        
      --49-64 [int] 16 bytes lim min, then 16bytes lim max, then 16 bytes scale min
        local out_hex2 = math.floor(t.hexarray_lim_min*255) + 
                  (math.floor(t.hexarray_lim_max*255)<<8) + 
                  (math.floor(t.hexarray_scale_min*255)<<16) + 
                  (math.floor(t.hexarray_scale_max*255)<<24)
        TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID+16*3, out_hex2) 
        --TrackFX_SetNamedConfigParm( tr, t.destfx_FXID, 'param.'..t.destfx_paramID..'.mod.baseline',0 )
    end
    
    -- reset slider link parameters (after it was changed in slave mode)
    if EXT.CONF_mode == 0 then
      if t.plink_offset~= 0 then TrackFX_SetNamedConfigParm( tr, t.destfx_FXID, 'param.'..t.destfx_paramID..'.plink.offset',0 )end
      if t.plink_scale~= 1 then TrackFX_SetNamedConfigParm( tr, t.destfx_FXID, 'param.'..t.destfx_paramID..'.plink.scale',1 )end
      if t.plink_baseline~= 0 then TrackFX_SetNamedConfigParm( tr, t.destfx_FXID, 'param.'..t.destfx_paramID..'.plink.baseline',0 )end
    end
    
    if EXT.CONF_mode == 1 then
      --1-16 [float] knob values  
        --if t.flags_mute == 1 then TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID, t.slave_jsfx_param) end 
        
      local slaveJSFXlinksID = t.slaveJSFXlinksID

      if t.set_offs then
        TrackFX_SetNamedConfigParm( tr, t.destfx_FXID, 'param.'..t.destfx_paramID..'.plink.offset', t.set_offs )
      end
      if t.set_base then
        TrackFX_SetNamedConfigParm( tr, t.destfx_FXID, 'param.'..t.destfx_paramID..'.mod.baseline', t.set_base )
      end
      if t.set_scale then
        TrackFX_SetNamedConfigParm( tr, t.destfx_FXID, 'param.'..t.destfx_paramID..'.plink.scale', t.set_scale )
      end 
        
      --17-32 [int] to which master knob linked
        TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID+16, 0)
    end
    
    
  end  
  ----------------------------------------------------------------------------------
  function DATA:Link_FloatFX(t)
    local tr = t.slave_jsfx_tr
    local fx = t.destfx_FXID
    local open = TrackFX_GetOpen( tr, fx )
    if open == true then TrackFX_Show( tr, fx, 2 ) else TrackFX_Show( tr, fx, 3 ) end
  end
  --------------------------------------------------------------------------------
  function DATA:Link_togglemute(t)
    local tr = t.slave_jsfx_tr
    local fxnumber = t.destfx_FXID
    local paramnumber = t.destfx_paramID
    local parmname = 'param.'..paramnumber..'.plink.active'
    if t.flags_mute_link == true then 
      TrackFX_SetNamedConfigParm( tr, fxnumber, parmname, 1 ) 
     else
      TrackFX_SetNamedConfigParm( tr, fxnumber, parmname, 0 ) 
    end
  end
    --------------------------------------------------------------------------------
  function DATA:Link_remove(t)
    local tr = t.slave_jsfx_tr
    local fxnumber = t.destfx_FXID
    local paramnumber = t.destfx_paramID
    local parmname = 'param.'..paramnumber..'.plink.active'
    TrackFX_SetNamedConfigParm( tr, fxnumber, parmname, 0 ) 
    local parmname = 'param.'..paramnumber..'.plink.effect'
    TrackFX_SetNamedConfigParm( tr, fxnumber, parmname, -1 ) 
    DATA:Link_Extstate_Validate()
    DATA:Link_Extstate_Set()
  end 
  ------------------------------------------------------------------
  function DATA:SlaveJSFX_UpdateParameters() 
    for link = 1, #DATA.slaveJSFXlinks do
      local tr = DATA.slaveJSFXlinks[link].slave_jsfx_tr
      if ValidatePtr2(DATA.ReaProj,tr,'MediaTrack*') then
        local destfx_paramformatted = ({TrackFX_GetFormattedParamValue(tr, DATA.slaveJSFXlinks[link].destfx_FXID, DATA.slaveJSFXlinks[link].destfx_paramID,'' )})[2] 
        DATA.slaveJSFXlinks[link].destfx_param = TrackFX_GetParamNormalized( tr, DATA.slaveJSFXlinks[link].destfx_FXID, DATA.slaveJSFXlinks[link].destfx_paramID )
        DATA.slaveJSFXlinks[link].destfx_paramformatted = destfx_paramformatted
        DATA.slaveJSFXlinks[link].slave_jsfx_param = TrackFX_GetParamNormalized( tr, DATA.slaveJSFXlinks[link].slave_jsfx_ID, DATA.slaveJSFXlinks[link].slave_jsfx_paramID )  
        if DATA.slaveJSFXlinks[link].slaveJSFXlinksID == 1 and DATA.slaveJSFXlinks[link].knob then 
          DATA.masterJSFX_sliders[DATA.slaveJSFXlinks[link].knob].destfx_paramformatted = destfx_paramformatted
        end
        
      end
    end
  end 
  ----------------------------------------------------------------------------------
  function DATA:Link_Extstate_Set()
    local s = ''
    for i =1, #DATA.links_extstate do s = s..'MACROLINK '..DATA.links_extstate[i].macroID..' '..DATA.links_extstate[i].slave_trGUID..' '..DATA.links_extstate[i].slave_fxGUID..' '..DATA.links_extstate[i].slave_paramnumber..' "'..(DATA.links_extstate[i].comment or '')..'"'..'|' end
    if DATA.masterJSFX_tr then GetSetMediaTrackInfo_String( DATA.masterJSFX_tr, 'P_EXT:MPLMAPPAN_MACROLINKEXTREF', s, true ) end
  end
  ------------------------------------------------------------------
  function DATA:SlaveJSFX_Validate(tr) 
    for fx = 1, TrackFX_GetCount(tr) do
      local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
      if fxname:match('mpl_MappingPanel_slave') then return fx-1 end
    end 
    -- add if not found
    reaper.PreventUIRefresh( 1 )
    local fx_new =  TrackFX_AddByName( tr, 'JS:mpl_MappingPanel_slave.jsfx', false, -1000 ) 
    reaper.TrackFX_Show( tr, fx_new, 2 ) -- add and hide
    reaper.PreventUIRefresh( -1 )
    return fx_new
  end 
  ------------------------------------------------------------------
  function DATA:MasterJSFX_Validate_Add() 
    if EXT.CONF_mode == 0 then
      local tr = GetMasterTrack(DATA.ReaProj,0)
      if tr then  
        reaper.PreventUIRefresh( 1 ) 
        local fx_new =  TrackFX_AddByName( tr, 'JS:mpl_MappingPanel_master.jsfx', false, -1000 ) 
        reaper.TrackFX_Show( tr, fx_new, 2 ) -- add and hide
        reaper.PreventUIRefresh( -1 ) 
      end
    end
    
    if EXT.CONF_mode == 1 then
      local tr = GetSelectedTrack(DATA.ReaProj,0)
      if tr then  
        reaper.PreventUIRefresh( 1 ) 
        local fx_new =  TrackFX_AddByName( tr, 'JS:mpl_MappingPanel_slave.jsfx', false, -1000 ) 
        reaper.TrackFX_Show( tr, fx_new, 2 ) -- add and hide
        reaper.PreventUIRefresh( -1 ) 
      end
    end
  end 
  ----------------------------------------------------------------------------------
  function DATA:Link_add_getexposedcontainernumber(tr, fxnumber,paramnumber)
    local last_fxnumber_container = fxnumber
    local last_paramnumber_container, ret, fxnumber_container,paramnumber_container 
    for i = 1, 10 do -- maximum container levels
      ret, fxnumber_container = reaper.TrackFX_GetNamedConfigParm( tr, last_fxnumber_container, 'parent_container' )
      if fxnumber_container ~= '' then 
        ret, paramnumber_container = reaper.TrackFX_GetNamedConfigParm( tr, fxnumber_container, 'container_map.add.'..fxnumber..'.'..paramnumber )
        last_fxnumber_container = fxnumber_container
        last_paramnumber_container = paramnumber_container
       elseif last_fxnumber_container and last_paramnumber_container then
        return true, last_fxnumber_container, last_paramnumber_container
      end
    end
  end
  ----------------------------------------------------------------------------------
  function DATA:Link_add(ignorelasttouched, tr_pass, fxnumber_pass, paramnumber_pass) local tr
    if DATA.masterJSFX_isvalid ~= true  then 
      DATA:MasterJSFX_Validate()
      if DATA.masterJSFX_isvalid ~= true then 
        DATA:MasterJSFX_Validate_Add() 
        DATA:CollectData()
      end 
    end
    
    if DATA.masterJSFX_isvalid ~= true then return end
    
    --local sel_knob = DATA:GetSelectedKnob() 
    local sel_knob = DATA.sel_knob
    if not sel_knob then return end
    
    -- get last touched param
    local retval, tracknumber, itemidx, takeidx, fxnumber, paramnumber, tr 
    if not ignorelasttouched then 
      retval, tracknumber, itemidx, takeidx, fxnumber, paramnumber = reaper.GetTouchedOrFocusedFX( 0 )
      if not retval then return end 
      local trid = tracknumber
      tr = GetTrack(DATA.ReaProj,trid) 
      if trid==-1 then tr = GetMasterTrack(DATA.ReaProj) end
      if EXT.CONF_mode == 1 and tr ~= GetSelectedTrack(DATA.ReaProj,0)then   
        UI.popups['Error_link'] = {
          mode = 0,
          trig = true,
          captions_csv = 'It`s not possible to link from different track in slave-per-track mode',
          func_setval = function(retval, retvals_csv)end
          }
        return 
      end
      local itid = itemidx
      if itid ~= -1 then return end
    end
    
    -- NOT lasttouched
    if ignorelasttouched == true then
      tr, fxnumber, paramnumber = tr_pass, fxnumber_pass, paramnumber_pass
    end
    
    
    
    
    --
      if paramnumber == -1 then return end
    
    -- prevent utilities from link
      local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fxnumber, 'original_name' )
      if fxname:match('mpl_MappingPanel') then return end
    
    
    -- check if parameter already linked
      local retval, active = TrackFX_GetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.active' )
      if (retval== true and tonumber(active) == 1) then return end
    -- check if parameter already mapped to LFO
      local retval, active = TrackFX_GetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.lfo' )
      if (retval== true and tonumber(active) == 1) then return end   
    -- check if parameter already mapped to LFO
      local retval, active = TrackFX_GetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.acs' )
      if (retval== true and tonumber(active) == 1) then return end        
    -- prevent map master fx as last touched 
      if DATA.masterJSFX_tr == tr and DATA.masterJSFX_FXid == fxnumber then return end 
      
      
    -- get slave fx/add
      local slavefx_id = DATA:SlaveJSFX_Validate(tr) 
      if not slavefx_id then  return  end   
    -- refresh last touched fx after slave jsfx possible adding 
      if not ignorelasttouched then
        retval, tracknumber, itemidx, takeidx, fxnumber, paramnumber = reaper.GetTouchedOrFocusedFX( 0 )
        --retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX() 
        if fxnumber == slavefx_id then return end  -- prevent map slave fx as last touched
      end
    
    
    
    -- get first free slave slider
      local linkfill = {} -- table for knowing which slots are already linked
      local fxcnt_main = TrackFX_GetCount( tr )
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr )
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end
        if fx-1 ~=slavefx_id then
          for param = 1, TrackFX_GetNumParams( tr, fx-1 ) do
            local retval, active = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.plink.active' )
            if not (retval== true and tonumber(active) == 1) then goto nextparam end
            local retval, effect = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.plink.effect' )
            if not (retval == true and tonumber(effect) ==  slavefx_id) then goto nextparam end
            local retval, paramSrc = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.plink.param' )
            if not (retval == true and tonumber(paramSrc) ) then goto nextparam end
            paramSrc = tonumber(paramSrc)
            if EXT.CONF_mode == 1 then paramSrc = sel_knob-1 end
            linkfill[paramSrc]=1
            ::nextparam::
          end
        end
      end  
      
      local freeslider 
      if EXT.CONF_mode == 0 then 
        for segmid = 0, 3 do 
          for i = 0, 15 do 
            local test_param = i+segmid*64 
            if not linkfill[test_param] then freeslider = test_param goto skipcheck end 
          end 
        end 
        ::skipcheck::
        if not freeslider then 
          UI.popups['Error_link'] = {
            mode = 0,
            trig = true,
            captions_csv = 'Can`t find available slider',
            func_setval = function(retval, retvals_csv)  
              
            end
            }
          return  
        end
      end
      
      if EXT.CONF_mode == 1 then 
        freeslider = sel_knob-1 
      end
      
    -- link to that slider
      local prelinkedparamvalue = TrackFX_GetParamNormalized( tr, fxnumber, paramnumber)
      local retval, minval, maxval = TrackFX_GetParam( tr, fxnumber, paramnumber)
      if fxnumber&0x2000000 == 0x2000000 then -- containter 
        
        local ret, fxnumber_container, paramnumber_container = DATA:Link_add_getexposedcontainernumber(tr, fxnumber,paramnumber)
        if ret then 
          TrackFX_SetNamedConfigParm( tr, fxnumber_container, 'param.'..paramnumber_container..'.plink.active', 1 )
          TrackFX_SetNamedConfigParm( tr, fxnumber_container, 'param.'..paramnumber_container..'.plink.effect', slavefx_id )
          TrackFX_SetNamedConfigParm( tr, fxnumber_container, 'param.'..paramnumber_container..'.plink.param', freeslider ) 
          TrackFX_SetNamedConfigParm( tr, fxnumber_container, 'param.'..paramnumber_container..'.mod.baseline', minval )
        end
       else
        
        TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.active', 1 )
        TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.effect', slavefx_id )
        TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.param', freeslider )
        TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.mod.baseline', minval )
      end
      
      -- set base
      
     
    -- link slider to selected knob
      
      if EXT.CONF_mode == 0 then
        TrackFX_SetParam( tr, slavefx_id, freeslider+16, sel_knob )
        DATA.masterJSFX_sliders[sel_knob].scroll = 1
        if EXT.CONF_setslaveparamtomaster == 1 then DATA.masterJSFX_sliders[sel_knob].val = prelinkedparamvalue end
        DATA:MasterJSFX_WriteSliders(sel_knob)
       elseif EXT.CONF_mode == 1 then
        TrackFX_SetParam( tr, slavefx_id, freeslider+16, 0 )
      end
      
      if EXT.CONF_addlinkrenameflags > 0 then
        local param_name = ({ TrackFX_GetParamName( tr,  fxnumber, paramnumber, '' )})[2]
        local cur_name = DATA.masterJSFX_sliders[sel_knob].name
        if EXT.CONF_addlinkrenameflags&1==1 then
          if EXT.CONF_addlinkrenameflags&2~=2 or (EXT.CONF_addlinkrenameflags&2==2 and cur_name:match('Macro%s%d+')) then
            DATA.masterJSFX_sliders[sel_knob].name = param_name
            DATA:MasterJSFX_WriteSliders(sel_knob)
          end
        end
      end
      
      
    -- store to extstate
      local slave_trGUID = reaper.GetTrackGUID( tr )
      local slave_fxGUID = reaper.TrackFX_GetFXGUID( tr, fxnumber )
      if not DATA.links_extstate then DATA.links_extstate = {} end
      DATA.links_extstate[#DATA.links_extstate+1] = 
        { macroID = sel_knob,
          slave_trGUID = slave_trGUID,
          slave_fxGUID = slave_fxGUID,
          slave_paramnumber = paramnumber,
        }
      DATA:Link_Extstate_Set()
      
      
    DATA:CollectData()
  end
  ------------------------------------------------------------------
  function DATA:MasterJSFX_WriteSliders(id0)
    local extstate_tr = GetMasterTrack(DATA.ReaProj) 
    if EXT.CONF_mode == 1 then extstate_tr = GetSelectedTrack(DATA.ReaProj,0) end
    if not extstate_tr then return end
    
    
    gmem_write(100,1 )
    local i_st = 1
    local cnt=15
    if id0 then i_st = id0 cnt = 0 end
    for id = i_st, i_st+cnt do 
      if EXT.CONF_mode == 1 and DATA.masterJSFX_FXid then TrackFX_SetParam( extstate_tr, DATA.masterJSFX_FXid, id+16-1, 0 ) end
      --if EXT.CONF_mode == 0 and DATA.masterJSFX_FXid then TrackFX_SetParam( extstate_tr, DATA.masterJSFX_FXid, id+16-1, id0 ) end
      if DATA.masterJSFX_FXid then TrackFX_SetParamNormalized( extstate_tr, DATA.masterJSFX_FXid, id-1, DATA.masterJSFX_sliders[id].val )   end
      local col = DATA.masterJSFX_sliders[id].col if not col then col = '' end
      

      local outstr = 
        DATA.masterJSFX_sliders[id].name..'|'..
        DATA.masterJSFX_sliders[id].scroll..'|'..
        DATA.masterJSFX_sliders[id].flags..'|'..
        (DATA.masterJSFX_sliders[id].col or -1)..'|'..
        (DATA.masterJSFX_sliders[id].ext_snapback_use or 0)..'|'..
        (DATA.masterJSFX_sliders[id].ext_snapback_val or 0)..'|'..
        (DATA.masterJSFX_sliders[id].ext_snapback_time or 0)
        
      if DATA.masterJSFX_sliders[id] then GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_MACRO'..id, outstr, true )  end
    end 
    
    GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_SLSELMASK', DATA.masterJSFX_slselectionmask, true )
    
    if not DATA.masterJSFX_variations_list then DATA.masterJSFX_variations_list = {} end
    local outchunk = ''
    for i = 1, 8 do
      if not DATA.masterJSFX_variations_list[i] then 
        DATA.masterJSFX_variations_list[i] = {
          name='Variation'..i,
          col = 0,
          macrolist = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
          issel = 0
          } 
      end
      local name = DATA.masterJSFX_variations_list[i].name or ''
      local col = DATA.masterJSFX_variations_list[i].col or ''
      local issel = DATA.masterJSFX_variations_list[i].issel or 0
      local macrolist = ''
      if DATA.masterJSFX_variations_list[i].macrolist then macrolist = table.concat(DATA.masterJSFX_variations_list[i].macrolist, ' ') end
      outchunk = outchunk..name..'|'..col..'|'..macrolist..'|'..issel..';'
    end
    GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_VARLIST', outchunk, true )
  end 
  ----------------------------------------------------------------------------------
  function DATA:Link_Extstate_Validate() 
    local slot_remove = {}
    for i = 1, #DATA.links_extstate do
      local slave_trGUID = DATA.links_extstate[i].slave_trGUID
      local slave_fxGUID = DATA.links_extstate[i].slave_fxGUID
      local slave_paramnumber = DATA.links_extstate[i].slave_paramnumber
      local tr = VF_GetTrackByGUID(slave_trGUID, DATA.ReaProj)
      if not tr then slot_remove[i] = true goto nextslot end
      local ret, tr, fx = VF_GetFXByGUID(slave_fxGUID, tr, DATA.ReaProj)
      if not fx then slot_remove[i] = true goto nextslot end
      local retval, active = reaper.TrackFX_GetNamedConfigParm( tr, fx, 'param.'..slave_paramnumber..'.plink.active' )
      if not (retval== true and tonumber(active) == 1) then slot_remove[i] = true goto nextslot end
      ::nextslot::
    end
    
    for i = #DATA.links_extstate, 1 , -1 do if slot_remove[i] then table.remove(DATA.links_extstate, i) end end
  end
    ----------------------------------------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  ---------------------------------------------------
  function VF_GetFXByGUID(GUID, tr, proj)
    if not GUID then return end
    local pat = '[%p]+'
    if not tr then
      for trid = 1, CountTracks(proj or 0) do
        local tr = GetTrack(DATA.ReaProj,trid-1)
        local fxcnt_main = TrackFX_GetCount( tr ) 
        local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
        for fx = 1, fxcnt do
          local fx_dest = fx
          if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
          if TrackFX_GetFXGUID( tr, fx-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx-1 end 
        end
      end  
     else
      if not (ValidatePtr2(proj or 0, tr, 'MediaTrack*')) then return end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
        if TrackFX_GetFXGUID( tr, fx_dest-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_dest-1 end 
      end
    end    
  end
  ----------------------------------------------------------------------------------
  function DATA:Link_Extstate_Get()
    DATA.links_extstate = {}
    
    -- define source track
      local extstate_tr = GetMasterTrack(DATA.ReaProj) 
      if EXT.CONF_mode == 1 then extstate_tr = GetSelectedTrack(DATA.ReaProj,0)  end
      if not extstate_tr then return end
      
    local retval, chunk = GetSetMediaTrackInfo_String(  extstate_tr , 'P_EXT:MPLMAPPAN_MACROLINKEXTREF', '', false )
    for block in chunk:gmatch('[^|]+') do 
      local macroID, slave_trGUID, slave_fxGUID, slave_paramnumber, comment = block:match('MACROLINK%s(%d+)%s(%{.-%})%s(%{.-%})%s(%d+)%s%"(.-)%"')
      DATA.links_extstate[#DATA.links_extstate+1]=
        {
          macroID = tonumber(macroID),
          slave_trGUID = slave_trGUID,
          slave_fxGUID = slave_fxGUID,
          slave_paramnumber = tonumber(slave_paramnumber),
          comment = comment or "",
        }
    end
    
  end
  ------------------------------------------------------------------
  function DATA:MasterJSFX_Remove()
    local tr = GetMasterTrack(DATA.ReaProj) 
    for fx = 1,  TrackFX_GetCount( tr ) do
      local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
      if fxname:match('mpl_MappingPanel_master') then
        TrackFX_Delete( tr, fx-1 )
        return true
      end
    end 
  end
  ------------------------------------------------------------------
  function DATA:MasterJSFX_Validate()
    
    DATA.masterJSFX_isvalid = false
    
    if EXT.CONF_mode == 0 then 
      for i = 0, CountTracks(DATA.ReaProj) do
        local tr = GetTrack(DATA.ReaProj,i-1)
        if i==0 then tr = GetMasterTrack(DATA.ReaProj) end 
        for fx = 1,  TrackFX_GetCount( tr ) do
          local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
          if fxname:match('mpl_MappingPanel_master') then
            DATA.masterJSFX_trGUID = GetTrackGUID( tr )
            DATA.masterJSFX_tr = tr
            DATA.masterJSFX_FXid = fx-1 
            DATA.masterJSFX_isvalid = true 
            return
          end
        end
      end
    end
    
    if EXT.CONF_mode == 1 then 
      local tr = GetSelectedTrack(DATA.ReaProj,0)
      if not tr then return end
      for fx = 1,  TrackFX_GetCount( tr ) do
        local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
        if fxname:match('mpl_MappingPanel_slave') then
          DATA.masterJSFX_trGUID = GetTrackGUID( tr )
          DATA.masterJSFX_tr = tr
          DATA.masterJSFX_FXid = fx-1 
          DATA.masterJSFX_isvalid = true
          return
        end
      end
    end
  end
  ------------------------------------------------------------------
  function DATA:MasterJSFX_ReadSliders()
    -- define source track
      local extstate_tr = GetMasterTrack(DATA.ReaProj) 
      if EXT.CONF_mode == 1 then extstate_tr = GetSelectedTrack(DATA.ReaProj,0)  end 
      if not extstate_tr then return end
    
    -- selection mask
      DATA.masterJSFX_slselectionmask = 1
      local retval, val = GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_SLSELMASK', '', false )
      if retval==true and tonumber(val) then DATA.masterJSFX_slselectionmask = tonumber(val) end
    
    -- sliders info 
      DATA.masterJSFX_sliders = {}
      for i = 1, 16 do
        local name = 'Macro '..i
        local scroll = 0
        local col = -1
        local flags = 0
        local ext_snapback_use = 0
        local ext_snapback_val = 0
        local ext_snapback_time = 0
        
        local retval, chunk = GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_MACRO'..i, '', false )
        if retval==true then 
          local t = {}
          for val in chunk:gmatch('[^%|]+') do t[#t+1] = val end
          name=t[1] or 'Macro '..i
          scroll=tonumber(t[2])
          flags=tonumber(t[3])
          col=t[4]
          ext_snapback_use=tonumber(t[5]) or 0
          ext_snapback_val=tonumber(t[6]) or 0
          ext_snapback_time=tonumber(t[7]) or 0
        end 
        
        local val = 0--gmem_read(i)
        local  ret, midi1, midi2
        if DATA.masterJSFX_FXid then 
          val = TrackFX_GetParamNormalized( extstate_tr, DATA.masterJSFX_FXid, i-1 ) 
          
          ret, midi1 = TrackFX_GetNamedConfigParm( extstate_tr, DATA.masterJSFX_FXid, 'param.'..(i-1)..'.learn.midi1')
          ret, midi2 = TrackFX_GetNamedConfigParm( extstate_tr, DATA.masterJSFX_FXid, 'param.'..(i-1)..'.learn.midi2')
          
        end
        if val == -1 then val = 0 end
        DATA.masterJSFX_sliders[i] = {
          val = val, 
          name = name,
          col=col,
          scroll=scroll,
          flags=flags,
          
          ext_snapback_use = ext_snapback_use,
          ext_snapback_val = ext_snapback_val,
          ext_snapback_time = ext_snapback_time,
          
          midi1=tonumber(midi1),
          midi2=tonumber(midi2),
          }
      end
      
    -- variations list
      DATA.masterJSFX_variations_list = {}
      local retval, chunk = GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_VARLIST', '', false )
      if retval==true then
        local varID = 1
        for block in chunk:gmatch('[^%;]+') do
          --number|name|color|list_of_parameters
          local t = {}
          for val in block:gmatch('[^%|]+') do t[#t+1] = val end
          local macrolist = {}
          for macroval in (t[3]):gmatch('[^%s]+') do macrolist[#macrolist+1] = tonumber(macroval) end
          DATA.masterJSFX_variations_list[varID] = {
            name = t[1],
            col = t[2],
            macrolist = macrolist,
            issel = tonumber(t[4]) or 0,
          }
          varID = varID + 1
        end
      end
  end
  ------------------------------------------------------------------
  function DATA:SlaveJSFX_Read_Routing(proj, tr, slavefx_id,selectedknob,trid)
    local fxcnt_main = TrackFX_GetCount( tr ) 
    local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
    for fx = 1, fxcnt do
      local fx_dest = fx
      if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end 
      if fx-1 ~=slavefx_id then  
        for param = 1, TrackFX_GetNumParams( tr, fx-1 ) do
          local retval, active = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.plink.active' )
          --if not (retval== true and tonumber(active) == 1) then goto nextparam end
          local flags_mute_link = tonumber(active) == 0
          local retval, effect = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.plink.effect' )
          if not (retval == true and tonumber(effect) ==  slavefx_id) then goto nextparam end
          local retval, paramSrc = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.plink.param' )
          if not (retval == true and tonumber(paramSrc) ) then goto nextparam end
          paramSrc = tonumber(paramSrc)
          
          local slider = tonumber(paramSrc)+1 -- 1based
          local slider_macrolink = slider+16 -- 1based
          local slider_flag = slider+32 -- 1based
          local slider_hex = slider+48 -- 1based
          
          local masterlink = TrackFX_GetParam( tr, slavefx_id, slider_macrolink-1)  
          if EXT.CONF_mode == 0 then if masterlink ~= selectedknob  then goto nextparam end end-- related to selected knob
          if EXT.CONF_mode == 1 then if slider ~= selectedknob  then goto nextparam end end-- related to selected knob
          
          local flags = TrackFX_GetParam( tr, slavefx_id, slider_flag-1) 
          local hexarray = TrackFX_GetParam( tr, slavefx_id, slider_hex-1) 
          
          local fxname_full = ({ TrackFX_GetFXName( tr, fx-1, '' )})[2]
          local fxname = VF_ReduceFXname(fxname_full)
          local param_name = ({ TrackFX_GetParamName( tr,  fx-1, param-1, '' )})[2]
          local slaveJSFXlinksID = #DATA.slaveJSFXlinks+1
          local destfx_paramformatted = ({TrackFX_GetFormattedParamValue( tr, fx-1, param-1 ,'' )})[2]
          
          
          DATA.slaveJSFXlinks[slaveJSFXlinksID] = 
                { 
                  slaveJSFXlinksID = slaveJSFXlinksID,
                  knob = selectedknob,
                  slave_jsfx_trGUID = GetTrackGUID( tr ),
                  slave_jsfx_tr = tr,
                  slave_jsfx_trname = ({GetTrackName(tr)})[2],
                  slave_jsfx_ID = slavefx_id,
                  slave_jsfx_fxGUID = TrackFX_GetFXGUID( tr, slavefx_id ),
                  slave_jsfx_paramID = paramSrc,
                  slave_jsfx_param = TrackFX_GetParamNormalized( tr, slavefx_id, paramSrc ),
                  slave_jsfx_trID = trid,
                  
                  destfx_FXGUID =  TrackFX_GetFXGUID( tr, fx-1 ),
                  destfx_FXname =fxname,
                  destfx_FXname_full =fxname_full,
                  destfx_FXID =fx-1,
                  destfx_paramID =param-1,
                  destfx_paramname = param_name,
                  destfx_param = TrackFX_GetParamNormalized( tr, fx-1, param-1 ),
                  destfx_paramformatted = destfx_paramformatted ,
                  
                  flags = flags,
                  flags_mute = flags&1,--==1,
                  flags_tension = ((flags>>1)&0xF)/15,
                  flags_mute_link = flags_mute_link,
                  
                  hexarray = hexarray,
                  hexarray16 = string.format("%X", hexarray),
                  hexarray_lim_min = (hexarray&0xFF)/255,
                  hexarray_lim_max = ((hexarray>>8)&0xFF)/255,
                  hexarray_scale_min = ((hexarray>>16)&0xFF)/255,
                  hexarray_scale_max = ((hexarray>>24)&0xFF)/255,
                }

          
          local retval, offset = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.plink.offset' )
          if not (retval == true and tonumber(offset) ) then offset = 0 else offset = tonumber(offset) end
          local retval, scale = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.plink.scale' )
          if not (retval == true and tonumber(scale) ) then scale = 1 else scale = tonumber(scale) end
          local retval, baseline = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'param.'..(param-1)..'.mod.baseline' )
          if not (retval == true and tonumber(baseline) ) then baseline = 0 else baseline = tonumber(baseline) end
          
          DATA.slaveJSFXlinks[slaveJSFXlinksID].plink_offset = offset
          DATA.slaveJSFXlinks[slaveJSFXlinksID].plink_scale = scale
          DATA.slaveJSFXlinks[slaveJSFXlinksID].plink_baseline = baseline
          
          -- handle graph values
          if EXT.CONF_mode == 1 then
            
            local lim_min = 0
            local lim_max = 1
            local scale_min = offset*scale + baseline
            local scale_max = (1+offset)*scale + baseline 
            if scale_min < 0 then
              lim_min =  math.abs(scale_min) / math.tan(math.rad(45*math.abs(scale)))
              scale_min = 0 
            end 
            if scale_min > 1 then
              lim_min = -(1-scale_min) / math.tan(math.rad(45*math.abs(scale)))
              scale_min = 1 
            end 
            if scale_max < 0 then
              lim_max =  1-math.abs(scale_max) * math.tan(math.rad(45*math.abs(scale)))
              scale_max = 0 
            end 
            if scale_max > 1 then
              lim_max = ((1-scale_max) / math.tan(math.rad(45*math.abs(scale)))) + 1
              scale_max = 1 
            end 
            DATA.slaveJSFXlinks[slaveJSFXlinksID].hexarray_lim_min = VF_lim(lim_min,0,lim_max)
            DATA.slaveJSFXlinks[slaveJSFXlinksID].hexarray_lim_max = VF_lim(1-lim_max)
            DATA.slaveJSFXlinks[slaveJSFXlinksID].hexarray_scale_min = scale_min
            DATA.slaveJSFXlinks[slaveJSFXlinksID].hexarray_scale_max = VF_lim(1-scale_max) 
          end
          
          ::nextparam::
        end
      end
    end
  end
    ------------------------------------------------------------------
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
  ------------------------------------------------------------------
  function DATA:SlaveJSFX_Read() 
    DATA.slaveJSFXlinks = {}
    local selectedknob = DATA:GetSelectedKnob() 
    --local selectedknob = DATA.sel_knob -- do not use, doesn`t refreshes immediately
    if not selectedknob then return end
    if EXT.CONF_mode == 0 then
      for i = 1, CountTracks(DATA.ReaProj) do
        local tr = GetTrack(DATA.ReaProj,i-1)
        for fx = 1, TrackFX_GetCount(tr) do
          local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
          if fxname:match('mpl_MappingPanel_slave') then DATA:SlaveJSFX_Read_Routing(DATA.ReaProj, tr, fx-1, selectedknob,i-1) break end
        end
      end
    end
    
    if EXT.CONF_mode ==1 then
      local tr = GetSelectedTrack(DATA.ReaProj,0)
      if not tr then return end
      for fx = 1, TrackFX_GetCount(tr) do
        local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
        if fxname:match('mpl_MappingPanel_slave') then DATA:SlaveJSFX_Read_Routing(DATA.ReaProj, tr, fx-1, selectedknob) break end
      end
    end
  end
  -------------------------------------------------------------------------------- 
  function DATA:GetSelectedKnob()
    local selectedknob = 1
    if not DATA.masterJSFX_slselectionmask then DATA.masterJSFX_slselectionmask = 1 end
    for i = 1, 16 do if DATA.masterJSFX_slselectionmask&(1<<(i-1))==(1<<(i-1)) then selectedknob = i break end end
    return selectedknob
  end
  -------------------------------------------------------------------------------- 
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  -------------------------------------------------------------------------------- 
  function ImGui.PushStyle(key, value, value2)  
    if not (ctx and key and value) then return end
    local iscol = key:match('Col_')~=nil
    local keyid = ImGui[key]
    if not iscol then 
      ImGui.PushStyleVar(ctx, keyid, value, value2)
      if not UI.pushcnt_var then UI.pushcnt_var = 0 end
      UI.pushcnt_var = UI.pushcnt_var + 1
    else 
      if not value2 then
        ReaScriptError( key ) 
       else
        ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
        if not UI.pushcnt_col then UI.pushcnt_col = 0 end
        UI.pushcnt_col = UI.pushcnt_col + 1
      end
    end 
  end
  -------------------------------------------------------------------------------- 
  function ImGui.PopStyle_var()  
    if not (ctx) then return end
    ImGui.PopStyleVar(ctx, UI.pushcnt_var)
    UI.pushcnt_var = 0
  end
  -------------------------------------------------------------------------------- 
  function ImGui.PopStyle_col()  
    if not (ctx) then return end
    ImGui.PopStyleColor(ctx, UI.pushcnt_col)
    UI.pushcnt_col = 0
  end 
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
    
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
      --window_flags = window_flags | ImGui.WindowFlags_NoMove()
      --window_flags = window_flags | ImGui.WindowFlags_NoResize
      window_flags = window_flags | ImGui.WindowFlags_NoCollapse
      --window_flags = window_flags | ImGui.WindowFlags_NoNav()
      --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
      --window_flags = window_flags | ImGui.WindowFlags_NoDocking
      window_flags = window_flags | ImGui.WindowFlags_TopMost
      window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      --window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings()
      --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
      --open = false -- disable the close button
    
    
      -- rounding
        ImGui.PushStyle('StyleVar_FrameRounding',5)   
        ImGui.PushStyle('StyleVar_GrabRounding',3)  
        ImGui.PushStyle('StyleVar_WindowRounding',10)  
        ImGui.PushStyle('StyleVar_ChildRounding',5)  
        ImGui.PushStyle('StyleVar_PopupRounding',0)  
        ImGui.PushStyle('StyleVar_ScrollbarRounding',9)  
        ImGui.PushStyle('StyleVar_TabRounding',4)   
      -- Borders
        ImGui.PushStyle('StyleVar_WindowBorderSize',0)  
        ImGui.PushStyle('StyleVar_FrameBorderSize',0) 
      -- spacing
        ImGui.PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
        ImGui.PushStyle('StyleVar_FramePadding',5,UI.spacingY) 
        ImGui.PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
        ImGui.PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
        ImGui.PushStyle('StyleVar_ItemInnerSpacing',4,0)
        ImGui.PushStyle('StyleVar_IndentSpacing',20)
        ImGui.PushStyle('StyleVar_ScrollbarSize',10)
      -- size
        ImGui.PushStyle('StyleVar_GrabMinSize',20)
        --ImGui.PushStyle('StyleVar_WindowMinSize',UI.main_butw*9,(UI.main_buth*2 + UI.spacingY)*2 + UI.font1sz*2)
        ImGui.PushStyle('StyleVar_WindowMinSize',600,200)
      -- align
        ImGui.PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
        ImGui.PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      -- alpha
        ImGui.PushStyle('StyleVar_Alpha',0.98)
        ImGui.PushStyle('Col_Border',UI.main_col, 0.3)
      -- colors
        ImGui.PushStyle('Col_Button',UI.main_col, 0.2) --0.3
        ImGui.PushStyle('Col_ButtonActive',UI.main_col, 1) 
        ImGui.PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
        ImGui.PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
        ImGui.PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
        ImGui.PushStyle('Col_FrameBgActive',UI.main_col, .6)
        ImGui.PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
        ImGui.PushStyle('Col_Header',UI.main_col, 0.5) 
        ImGui.PushStyle('Col_HeaderActive',UI.main_col, 1) 
        ImGui.PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
        ImGui.PushStyle('Col_PopupBg',0x303030, 0.9) 
        ImGui.PushStyle('Col_ResizeGrip',UI.main_col, 1) 
        ImGui.PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
        ImGui.PushStyle('Col_SliderGrab',UI.butBg_green, 0.4) 
        ImGui.PushStyle('Col_Tab',UI.main_col, 0.37) 
        ImGui.PushStyle('Col_TabHovered',UI.main_col, 0.8) 
        ImGui.PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
        ImGui.PushStyle('Col_TitleBg',UI.main_col, 0.7) 
        ImGui.PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
        ImGui.PushStyle('Col_WindowBg',UI.windowBg, 1)
        ImGui.PushStyle('Col_PlotHistogram',0xF0FFF0, 0.12)
      
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      --ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font1) 
      local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) --..' '..vrs..'##'..DATA.UI_name
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
        
        UI.main_butw = (DATA.display_w_region- UI.spacingX*10) / 9
        UI.main_buth = (DATA.display_h_region- UI.calc_itemH-UI.spacingY*5) / 4
        UI.main_knobtxth = UI.main_buth*0.6
        
        UI.calc_knobW = math.ceil((DATA.display_w_region - UI.main_butw - UI.spacingX*11)/8)
        UI.calc_knobH = UI.main_buth*2 + UI.spacingY
        UI.calc_knobcollapsedW = UI.calc_knobW*2 + UI.spacingX 
        UI.calc_knobcollapsedH = math.floor((UI.calc_knobH - UI.spacingY*3)/4) 
        
      -- draw stuff
        UI.MAIN_drawstuff()
        ImGui.Dummy(ctx,0,0) 
        ImGui.PopStyle_var() 
        ImGui.PopStyle_col() 
        ImGui.End(ctx)
       else
        ImGui.PopStyle_var() 
        ImGui.PopStyle_col() 
      end 
      ImGui.PopFont( ctx )
      
    
      return open
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_shortcuts()
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then 
      for key in pairs(UI.popups) do UI.popups[key].draw = false end
      ImGui.CloseCurrentPopup( ctx ) 
    end
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then  VF_Action(40044) end
  end
  ------------------------------------------------------------------------------------------------------
  function VF_Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end  
  ---------------------------------------------------------------------  
  function DATA:CollectData_LTP()    
    DATA.LTP = {
      visualout = '[Last touched parameter]'
      }
    local retval, trackidx, itemidx, takeidx, fxID, paramID = GetTouchedOrFocusedFX( 0 )
    if not retval then return end
    
    DATA.LTP.trackidx=trackidx
    local track = GetTrack(-1,trackidx)
    if trackidx==-1 then track = reaper.GetMasterTrack(-1) end 
    DATA.LTP.tr_ptr = track
    
    if itemidx ~= -1 then
      DATA.LTP.str_plug = '[take FX is not supported]'
      return 
    end
    
    if fxID&0x1000000 == 0x1000000 then
      DATA.LTP.str_plug = '[Input FX is not supported]'
      return 
    end
    
    if fxID&0x2000000 == 0x2000000 then -- containter
      --DATA.LTP.str_plug = '[Container FX is not supported]'
      --return 
    end
    
    local retval, paramname = TrackFX_GetParamName( track, fxID, paramID )
    local retval, fxname = TrackFX_GetFXName( track, fxID )
    
     
    
    if fxname:match('Mapping') then
      return 
    end
    
    
    DATA.LTP.fxID = fxID
    DATA.LTP.fxname = fxname
    DATA.LTP.fxname_short = VF_ReduceFXname(fxname)
    DATA.LTP.paramID = paramID
    DATA.LTP.paramname = paramname
    
    DATA.LTP.visualout = '['..(trackidx+1)..'] '..DATA.LTP.fxname_short..' / '..paramname
    
    DATA.LTP.valid = true
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData()
    local ReaProj, projfn = reaper.EnumProjects( -1 )
    DATA.ReaProj = ReaProj 
    
    DATA:MasterJSFX_Validate()
    
    DATA:CollectData_LTP()    
    DATA:MasterJSFX_ReadSliders()
    DATA:SlaveJSFX_Read()
    DATA:Link_Extstate_Get()
    DATA:Link_Extstate_Validate() 
    
    DATA:SlaveJSFX_UpdateParameters() 
    
    DATA.sel_knob = DATA:GetSelectedKnob()
  end 
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Always() 
    if not DATA.masterJSFX_FXid then return end
    local retval1, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
    if retval1 ~= 0 and rawmsg and rawmsg:byte(1)&0xB0==0xB0 then 
      DATA.last_inc_MIDI1 = rawmsg:byte(1)
      DATA.last_inc_MIDI2 = rawmsg:byte(2)
      
      if rawmsg:byte(1)&0xB0==0xB0 then 
        local id = rawmsg:byte(2)
        local chan = rawmsg:byte(1)&0x0F
        DATA.last_inc_MIDI1_str = 'CC '..id..' Chan '..chan
      end
    end
    
    -- refresh slider values
    if not DATA.touchstate then 
      local extstate_tr = GetMasterTrack(DATA.ReaProj) 
      if EXT.CONF_mode == 1 then extstate_tr = GetSelectedTrack(DATA.ReaProj,0)  end 
      if not extstate_tr then return end
      for i = 1, #DATA.masterJSFX_sliders do 
        local val = TrackFX_GetParamNormalized( extstate_tr, DATA.masterJSFX_FXid, i-1 ) 
        if val ~= DATA.masterJSFX_sliders[i].val then
          DATA.masterJSFX_sliders[i].val = val 
          DATA:SlaveJSFX_UpdateParameters() 
        end
      end
    end
    
    -- handle snapback
      for sliderID in pairs(DATA.snapback) do
        local TS = DATA.snapback[sliderID].TS
        local time_transition = DATA.masterJSFX_sliders[sliderID].ext_snapback_time / 1000
        local srcval = DATA.snapback[sliderID].init_val
        local destval = DATA.masterJSFX_sliders[sliderID].ext_snapback_val
        
        local cur_time = time_precise()
        local time_ratio = (cur_time - TS) / time_transition
        if time_ratio > 1 then 
          DATA.snapback[sliderID] = nil
          time_ratio = 1
        end
        local val = srcval + (destval - srcval) * time_ratio
        
        local extstate_tr = GetMasterTrack(DATA.ReaProj) 
        if EXT.CONF_mode == 1 then extstate_tr = GetSelectedTrack(DATA.ReaProj,0) end
        if extstate_tr then 
          gmem_write(100,1 )
          if DATA.masterJSFX_FXid then TrackFX_SetParamNormalized( extstate_tr, DATA.masterJSFX_FXid, sliderID-1, val ) end
        end
      end
      
    -- ext actions
      if gmem_read(1024) > 0 then
        DATA.sel_knob = gmem_read(1025)
        DATA:Link_add()
        gmem_write(1024,0 )
        DATA.upd = true
      end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_UIloop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
    
    if DATA.upd == true then DATA:CollectData() end 
    DATA:CollectData_Always()
    DATA.upd = false
    
    -- refresh at losing context
    if not reaper.ImGui_ValidatePtr(ctx,'ImGui_Context*') then return end --ctx = ImGui.CreateContext(DATA.UI_name)  end
    
    -- draw UI
    UI.open = UI.MAIN_styledefinition(true)  
    UI.MAIN_shortcuts()
    
    -- handle xy
    DATA:handleViewportXYWH()
    
    -- data
    if UI.open then defer(UI.MAIN_UIloop) end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_definecontext()
    
    EXT:load() 
    
    -- imgUI init
    ctx = ImGui.CreateContext(DATA.UI_name) 
    -- fonts
    DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
    DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
    --DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
    -- config
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
    
    DATA.DPI = ImGui.GetWindowDpiScale( ctx )
    
    if EXT.CONF_mode == 0 then
      DATA:MasterJSFX_Validate()
      if DATA.masterJSFX_isvalid ~= true then DATA:MasterJSFX_Validate_Add() end 
    end
    
    -- run loop
    defer(UI.MAIN_UIloop)
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
  function UI.draw_knob(sliderID, sliderW,  sliderH, paramval, app_func_onmouseclick, app_func_onmousedrag, app_func_header, iscollapsed, selected, name, col) 
   
    if not (paramval and sliderID ) then return end
    local sliderID_key = sliderID..'##sl'..sliderID
    local posx_abs, posy_abs = ImGui.GetCursorScreenPos( ctx )
    if DATA.masterJSFX_sliders and DATA.masterJSFX_sliders[sliderID] then 
      if DATA.masterJSFX_sliders[sliderID].flags&1==1 then name = name..'[R]' end
      if DATA.masterJSFX_sliders[sliderID].flags&2==2 then name = name..'[V]' end
    end
    
    
    local mindim = math.min(sliderW,sliderH - UI.main_knobtxth)
    local namew= sliderW
    local nameh= UI.main_knobtxth
    local childW = sliderW
    local vsliderw = sliderW
    local vsliderh = sliderH-UI.main_knobtxth-UI.spacingY
    if iscollapsed then 
      namew= math.floor(sliderW*0.8) 
      childW = sliderW
      nameh = sliderH
      vsliderw = math.min(sliderW - namew, sliderH)
      vsliderh = sliderH
    end
    
    if ImGui.BeginChild( ctx, '##ch'..sliderID, childW,  sliderH, ImGui.ChildFlags_None, ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar ) then 
      
      -- background
      --local draw_list = ImGui.GetForegroundDrawList(ctx) 
      local draw_list = ImGui.GetWindowDrawList( ctx )
      
      local slcol
      if col and col ~= -1 then
        slcol = col:gsub('%#','')
        slcol = tonumber(slcol,16)
      end
      if slcol and slcol ~= -1  then 
        slcol = slcol<<8|0xCF
       else
        slcol  = 0xFFFFFF0F
      end
      local round = 5
      if iscollapsed == false then round = 0 end
      ImGui.DrawList_AddRectFilled(draw_list, posx_abs, posy_abs, posx_abs+sliderW, posy_abs+sliderH, slcol, round, ImGui.DrawFlags_None)
      if not iscollapsed then ImGui.DrawList_AddRectFilled(draw_list, posx_abs, posy_abs, posx_abs+sliderW, posy_abs+UI.main_knobtxth, 0xFFFFFF2F, 5, ImGui.DrawFlags_RoundCornersTopRight) end
      if selected then 
        local selcolframe = 0xFFFFFF4F
        if not iscollapsed then ImGui.DrawList_AddRect(draw_list, posx_abs, posy_abs, posx_abs+sliderW-1, posy_abs+UI.main_knobtxth, selcolframe, 5, ImGui.DrawFlags_RoundCornersTopRight) 
          else                  ImGui.DrawList_AddRect(draw_list, posx_abs, posy_abs, posx_abs+sliderW, posy_abs+sliderH, selcolframe, 5)--, ImGui.DrawFlags_RoundCornersTop) 
        end
      end
      
      -- macro name / handle context menu
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 1,1)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x00000000)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0x00000000)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xFFFFFF2F) 
        if iscollapsed==true then 
          ImGui.Button(ctx, name..'##name'..sliderID, namew, nameh) 
         else 
          local x1, y1 = ImGui.GetCursorPos( ctx )
          ImGui.SetCursorPos( ctx, x1+2, y1+2)
          ImGui.TextWrapped( ctx, name )
          ImGui.SetCursorPos( ctx, x1, y1) 
          ImGui.Button(ctx, '##name'..sliderID, namew, nameh)
        end 
        if ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None ) then
        
          if iscollapsed == true then
            if ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Left, 1 ) then
              DATA:Macro_Select(sliderID) 
             elseif ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Right, 1 ) then
              DATA:Macro_Select(sliderID) 
              ImGui.OpenPopup( ctx, 'ppupmacro')
            end
           else
            if ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Left, 1 ) then
             DATA:Macro_Select(sliderID) 
             ImGui.OpenPopup( ctx, 'ppupmacro')
            end
          end
          
        end
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopStyleVar(ctx,1)
        
      -- context menu
        ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg, 0x2F2F2FFF)
        if ImGui.BeginPopup(ctx, 'ppupmacro') then
          UI.MAIN_drawstuff_contextmenu_macro() 
          ImGui.EndPopup(ctx)
        end
        ImGui.PopStyleColor(ctx, 1)
       
      -- slider: draw
        if iscollapsed then ImGui.SameLine(ctx) end
        ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, 0x00000000)
        ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, 0x00000000) 
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x00000000)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0x00000000)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x00000000)
        
        if DATA.masterJSFX_isvalid == true then
          local retval, v = ImGui.VSliderDouble( ctx, '##vsl'..sliderID,  vsliderw, vsliderh , paramval, 0, 1, '' )
        end
        ImGui.PopStyleColor(ctx,5)
        
          
      -- slider: handle mouse state
        if DATA.masterJSFX_isvalid == true then
          if not temp then temp = {} end
          if not temp[sliderID] then temp[sliderID] = {} end 
          if  ImGui.IsItemActivated( ctx ) then 
            temp[sliderID].latchstate = paramval 
            app_func_onmouseclick(sliderID)
            DATA.touchstate = true
            goto drawknob 
          end 
          if  ImGui.IsItemActive( ctx ) and temp[sliderID].latchstate then
            
            local x, y = ImGui.GetMouseDragDelta( ctx )
            local outval = temp[sliderID].latchstate - y/500
            outval = math.max(0,math.min(outval,1))
            local dx, dy = ImGui.GetMouseDelta( ctx )
            if dy~=0 and app_func_onmousedrag then 
              app_func_onmousedrag(sliderID, outval) 
            end
           else
          end
          if ImGui_IsItemDeactivated( ctx ) then
            local x, y = ImGui.GetMouseDragDelta( ctx )
            local outval = temp[sliderID].latchstate - y/500
            outval = math.max(0,math.min(outval,1))
            app_func_onmousedrag(sliderID, outval, true)
            
            DATA.touchstate = false
            if DATA.masterJSFX_sliders[sliderID].ext_snapback_use == 1 then
              DATA.snapback[sliderID] = 
                {init_val = outval,
                TS = time_precise()}
            end
          end
        end
        
      ::drawknob::
          
        if DATA.masterJSFX_isvalid == true then
          -- draw stuff vars
            local knob_handle = 0xc8edfa 
            local col_rgba = 0xF0F0F0FF 
            local thicknessIn = 3
            local roundingIn = 0
            local radius = math.floor(mindim/2)
            local radius_draw = math.floor(0.85 * radius) 
            local center_x = posx_abs + sliderW/2
            local center_y = posy_abs + UI.main_knobtxth + vsliderh/2--((sliderH - UI.main_knobtxth)/2)
            local handlethickness = 2
            if iscollapsed then 
              radius = math.floor(vsliderw / 2)
              radius_draw = math.floor(0.8 * radius) 
              center_x = posx_abs + namew + radius
              center_y = posy_abs + vsliderh/2-1
            end
            local ang_min = -210
            local ang_max = 30
            local ang_val = ang_min + math.floor((ang_max - ang_min)*paramval)
            local radiusshift_y = (radius_draw- radius)
            local radius_draw2 = radius_draw-math.floor(0.1 * radius)
            local radius_draw3 = radius_draw-math.floor(mindim*0.2)
            if iscollapsed then 
               radius_draw3 = radius_draw-math.floor(0.7 * radius)
               radiusshift_y = -math.floor(0.3 * radius)
            end
          -- arc
            ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
            ImGui.DrawList_PathStroke(draw_list, knob_handle<<8|0x2F,  ImGui.DrawFlags_None,thicknessIn)
            ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
            if paramval > 0 then ImGui.DrawList_PathStroke(draw_list, knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2) end
          -- handle
            ImGui.DrawList_PathClear(draw_list)
            ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
            ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
            ImGui.DrawList_PathStroke(draw_list, knob_handle<<8|0xFF,  ImGui.DrawFlags_None, handlethickness)
          
        end
        
        -- draw val
        if not iscollapsed and DATA.masterJSFX_sliders[sliderID].destfx_paramformatted then
          ImGui.PushStyleColor(ctx, ImGui.Col_Button,0)
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,0)
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,0)
          ImGui.SetCursorScreenPos( ctx,posx_abs,  posy_abs+sliderH-UI.calc_itemH )
          ImGui.Button(ctx, DATA.masterJSFX_sliders[sliderID].destfx_paramformatted,-1)
          ImGui.PopStyleColor(ctx,3)
        end
      
      ImGui.EndChild( ctx )
      
      
    end
    
    
    
  end
  -------------------------------------------------------------------------------- 
  function DATA:handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
    local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
    local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
  end
  --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff()  
    local local_pos_x, local_pos_y = ImGui.GetCursorPos( ctx )
    
    
    
    --Menu
    if ImGui.Button(ctx, 'Menu',UI.main_butw,UI.main_buth) then 
      if DATA.activetab == 1 then 
        DATA.activetab = 0 
        DATA.knobscollapsed = 0 
       else 
        DATA.activetab = 1 
      end
    end
    
    --Rand
    if ImGui.Button(ctx, 'Actions',UI.main_butw,UI.main_buth) then 
      if DATA.activetab == 4 then 
        DATA.activetab = 0 
        DATA.knobscollapsed = 0 
       else 
        DATA.activetab = 4 
        DATA.knobscollapsed = 1 
      end
    end
    
    --VariList
    if ImGui.Button(ctx, 'VariList',UI.main_butw,UI.main_buth) then 
      if DATA.activetab == 2 then 
        DATA.activetab = 0 
        DATA.knobscollapsed = 0 
       else 
        DATA.activetab = 2 
        DATA.knobscollapsed = 1 
      end
    end
    
    --Links
    if ImGui.Button(ctx, 'Links',UI.main_butw,UI.main_buth) then 
      if DATA.activetab == 3 then 
        DATA.activetab = 0 
        DATA.knobscollapsed = 0 
       else 
        DATA.activetab = 3 
        DATA.knobscollapsed = 1 
      end
    end
    
    -- childs
    if DATA.activetab ~= 1 and DATA.masterJSFX_isvalid == true then UI.MAIN_drawstuff_knobs(local_pos_x, local_pos_y) end
    if DATA.activetab == 1 then UI.MAIN_drawstuff_menu(local_pos_x, local_pos_y) end
    if DATA.activetab == 2 and DATA.masterJSFX_isvalid == true then UI.MAIN_drawstuff_varlist(local_pos_x, local_pos_y) end
    if DATA.activetab == 3 and DATA.masterJSFX_isvalid == true then UI.MAIN_drawstuff_links(local_pos_x, local_pos_y) end
    if DATA.activetab == 4 and DATA.masterJSFX_isvalid == true then UI.MAIN_drawstuff_actions(local_pos_x, local_pos_y) end
    
    if DATA.masterJSFX_isvalid ~= true and DATA.activetab ~= 1 then
      ImGui.SetCursorPos( ctx,local_pos_x + UI.calc_knobW+ UI.spacingX, local_pos_y+ UI.spacingY) 
      ImGui.TextDisabled(ctx, 'You are in [Slave JSFX per track] mode. Select track and click:')
      ImGui.SetCursorPosX( ctx,local_pos_x + UI.calc_knobW+ UI.spacingX)
      if ImGui.Button(ctx, 'Instantiate') then DATA:MasterJSFX_Validate_Add()  end
      ImGui.SetCursorPosX( ctx,local_pos_x + UI.calc_knobW+ UI.spacingX)
      
      ImGui.BeginDisabled(ctx, true)
      ImGui.TextWrapped( ctx, 'Otherwise if you want master JSXF control all instances. go to Menu/General and select [Master JSFX] mode')
      ImGui.EndDisabled(ctx)
      
      return 
    end
    
    -- popups
    for key in pairs(UI.popups) do
      -- trig
      if UI.popups[key] and UI.popups[key].trig == true then
        UI.popups[key].trig = false
        UI.popups[key].draw = true
        ImGui.OpenPopup( ctx, key, ImGui.PopupFlags_NoOpenOverExistingPopup )
      end
      -- draw
      if UI.popups[key] and UI.popups[key].draw == true then UI.GetUserInputMB_replica(UI.popups[key].mode or 1, key, DATA.UI_name, 1, UI.popups[key].captions_csv, UI.popups[key].func_getval, UI.popups[key].func_setval) end 
    end
    
    
  end
  --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff_links(local_pos_x, local_pos_y) 
    ImGui.SetCursorPos( ctx, local_pos_x + UI.main_butw + UI.spacingX , local_pos_y)
    
    local sel_knob = DATA.sel_knob
    if not sel_knob  then return end
    
    local masterJSFX_isvalid = DATA.masterJSFX_isvalid and DATA.masterJSFX_isvalid == true
    
    -- add link
    ImGui.BeginDisabled(ctx, true)
    ltpname = DATA.LTP.visualout or ''
    ImGui.Button(ctx, ltpname,UI.calc_knobcollapsedW*1.5-UI.spacingX,UI.calc_knobcollapsedH)
    ImGui.EndDisabled(ctx) 
    
    ImGui.SameLine(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xFA000050)
    if ImGui.Button(ctx, 'Link',UI.main_butw,UI.calc_knobcollapsedH) then 
      if sel_knob == 0 then 
        local sliderID = 1
        DATA.masterJSFX_slselectionmask = 2^(sliderID-1) 
        DATA:MasterJSFX_WriteSliders(sliderID)
      end
      DATA:Link_add() 
      DATA:SlaveJSFX_Read()
    end
    ImGui.PopStyleColor(ctx, 1)
    
    -- existing links
    ImGui.SetCursorPos( ctx, local_pos_x + UI.main_butw + UI.spacingX , local_pos_y + UI.calc_knobcollapsedH+ UI.spacingY) 
    
      
      
    ImGui.PushFont(ctx, DATA.font2) 
    if ImGui.BeginChild(ctx, 'links', UI.calc_knobcollapsedW*2+ UI.spacingX, UI.calc_knobcollapsedH*7 + UI.spacingY*6, ImGui.ChildFlags_Border, ImGui.WindowFlags_NoScrollbar) then  
      -- context menu
        ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg, 0x2F2F2FFF)
        if ImGui.BeginPopup(ctx, 'ppuplink') then
          UI.MAIN_drawstuff_contextmenu_link() 
          ImGui.EndPopup(ctx)
        end
        ImGui.PopStyleColor(ctx, 1)
      -- links
        for slavelinkID = 1, #DATA.slaveJSFXlinks do UI.MAIN_drawstuff_links_sub(DATA.slaveJSFXlinks[slavelinkID]) end
      ImGui.Dummy(ctx,0,0)
      ImGui.EndChild(ctx)
    end
    ImGui.PopFont(ctx) 
    
  end
  
  --------------------------------------------------------------------------------  
  function DATA:Action_RemoveLinkFromFX(linkt)
    Undo_BeginBlock2( DATA.ReaProj )
    local tr = linkt.slave_jsfx_tr
    local fx = linkt.destfx_FXID
    local slavefx_id = linkt.slave_jsfx_ID
    for param = 1, TrackFX_GetNumParams( tr, fx ) do
      local retval, effect = TrackFX_GetNamedConfigParm( tr, fx, 'param.'..(param-1)..'.plink.effect')
      if (retval == true and tonumber(effect) ==  slavefx_id) then 
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..(param-1)..'.plink.active',0 )
      end 
    end
    Undo_EndBlock2( DATA.ReaProj, 'Remove all links from current FX', 0xFFFFFF )
  end
  --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff_contextmenu_link()   
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 1)
    
    local sliderid = DATA.sel_knob
    if not sliderid then return end
    local t = DATA.slaveJSFXlinks
    local linkID = DATA:Link_GetSelect(t) 
    if not linkID then return end
    ImGui.SeparatorText(ctx,'Macro '..sliderid..' Link '..linkID) 
    local linkt = t[linkID]
    
    if ImGui.Selectable(ctx, 'Remove all links from current FX') then DATA:Action_RemoveLinkFromFX(linkt) end
    if ImGui.Selectable(ctx, 'Link same parameter for same FX at selected tracks') then DATA:Action_LinkSameParams(linkt) end
    
    
    
    ImGui.PopStyleVar(ctx, 1)
  end
  ------------------------------------------------------------------------------ 
  function DATA:Action_LinkSameParams(linkt)
    for i = 0, CountSelectedTracks(DATA.ReaProj) do
      local tr = GetSelectedTrack(DATA.ReaProj,i-1)
      if i==0 then tr = GetMasterTrack(DATA.ReaProj) end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end 
        local fxGUID = reaper.TrackFX_GetFXGUID( tr, fx-1 )
        local fxname_full = ({ TrackFX_GetFXName( tr, fx-1, '' )})[2]
        if fxGUID ~= linkt.destfx_FXGUID and fxname_full == linkt.destfx_FXname_full then
          DATA:Link_add(true, tr, fx-1, linkt.destfx_paramID)
        end
      end
    end
    
    DATA:SlaveJSFX_Read()
  end
  --------------------------------------------------------------------------------  
  function DATA:Link_SetSelect(t) 
    for i =1, #DATA.slaveJSFXlinks do DATA.slaveJSFXlinks[i].selected = false end
    t.selected = true
  end
  --------------------------------------------------------------------------------  
  function DATA:Link_GetSelect(t) 
    for i =1, #DATA.slaveJSFXlinks do if DATA.slaveJSFXlinks[i].selected == true then return i end end
  end
  --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff_links_sub(t) 
    if not t then return end
    local posx_abs0, posy_abs0 = ImGui.GetCursorScreenPos( ctx )
    
    -- track / fx / param / value
      local trname = ''
      local indent = ''
      if t.slave_jsfx_trID then 
        indent= '   '
        trname = '['..(t.slave_jsfx_trID+1)..'] '..t.slave_jsfx_trname..'\n' 
      end
      local fxname = indent..t.destfx_FXname
      local paramname = indent..t.destfx_paramname
      local paramformat = indent..t.destfx_paramformatted
      local but_name = trname..fxname..'\n'..paramname..'\n'..paramformat
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 3,2)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign, 0,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
      ImGui.Button(ctx, but_name, UI.calc_knobcollapsedW-UI.calc_knobcollapsedH, UI.linkH)
      ImGui.PopStyleVar(ctx,3)
      if ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None ) then
        if ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Left, 1 ) then
          DATA:Link_FloatFX(t) 
          DATA:Link_SetSelect(t) 
         elseif ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Right, 1 ) then 
          DATA:Link_SetSelect(t) 
          ImGui.OpenPopup( ctx, 'ppuplink')
        end
      end
    
    
    -- mute / remove buttons pos reference
      ImGui.SameLine(ctx)
      local posX, posY = ImGui.GetCursorPos( ctx)
      local posx_abs, posy_abs = ImGui.GetCursorScreenPos( ctx )
     
    
    -- mute
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0,0)
      --local mutestate = t.flags_mute == 1
      local mutestate = t.flags_mute_link == true
      if mutestate == true then 
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xFA000070) 
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xFA000090) 
      end
      if ImGui.Button(ctx, 'M##linkmut'..t.slaveJSFXlinksID, UI.calc_knobcollapsedH, UI.linkH/2-UI.spacingY) then
        --t.flags_mute = t.flags_mute~1
        --t.flags_mute_link = not t.flags_mute_link
        DATA:Link_togglemute(t) 
        DATA:SlaveJSFX_Read() 
      end
      ImGui.SetCursorPos( ctx, posX, posY  +UI.linkH/2) 
      if mutestate == true then ImGui.PopStyleColor(ctx, 2) end
    
    
    -- remove
      if ImGui.Button(ctx, 'X##linkrem'..t.slaveJSFXlinksID, UI.calc_knobcollapsedH, UI.linkH/2) then
        DATA:Link_remove(t)
        DATA:SlaveJSFX_Read() 
      end
      
      
      ImGui.PopStyleVar(ctx,1) -- StyleVar_FramePadding
    
    UI.MAIN_drawstuff_links_sub_graph(t, posx_abs + UI.calc_knobcollapsedH + UI.spacingX, posy_abs-UI.spacingY)
    UI.MAIN_drawstuff_links_sub_SlaveModeSliders(t, posx_abs0, posy_abs )
    local ctrlsliderh = 0
    if EXT.CONF_mode ==1 then ctrlsliderh = UI.calc_itemH end
    ImGui.SetCursorScreenPos( ctx, posx_abs0, posy_abs0  + UI.linkH+ UI.spacingY*2+ctrlsliderh)
  end
  ---------------------------------------------------------------------
  function UI.MAIN_drawstuff_links_sub_SlaveModeSliders(t, posx_abs, posy_abs0 )
    local posy_abs = posy_abs0 + UI.linkH  + UI.spacingY
    local sliderID  = DATA.sel_knob
    local spaceX = 15
    -- slave per track sliders
    if EXT.CONF_mode == 1 then
      ImGui.SetCursorScreenPos( ctx,posx_abs,posy_abs )
      ImGui.Dummy(ctx,spaceX,0)
      ImGui.SameLine(ctx)
      
      -- offs
      ImGui.SetNextItemWidth( ctx, 50 ) 
      local retval, v = ImGui.SliderDouble( ctx, '##offs'..sliderID..t.slaveJSFXlinksID, t.plink_offset, -1, 1, '', ImGui.SliderFlags_None )
      if retval then t.set_offs = v DATA:SlaveJSFX_Write(t)DATA:SlaveJSFX_UpdateParameters()  end
      ImGui.SameLine(ctx) ImGui.Text(ctx,'Offset')
      if ImGui.IsItemClicked( ctx, ImGui.HoveredFlags_None ) then t.set_offs = 0 DATA:SlaveJSFX_Write(t)DATA:SlaveJSFX_UpdateParameters()  end -- ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui.IsMouseDoubleClicked( ctx, ImGui.MouseButton_Left )
      
      -- scale
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx,spaceX,0)
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth( ctx, 50 ) 
      local retval, v = ImGui.SliderDouble( ctx, '##scale'..sliderID..t.slaveJSFXlinksID, t.plink_scale, -1, 1, '', ImGui.SliderFlags_None )
      if retval then t.set_scale = v DATA:SlaveJSFX_Write(t)DATA:SlaveJSFX_UpdateParameters()  end
      ImGui.SameLine(ctx) ImGui.Text(ctx,'Scale')
      if ImGui.IsItemClicked( ctx, ImGui.HoveredFlags_None ) then t.set_scale = 1 DATA:SlaveJSFX_Write(t)DATA:SlaveJSFX_UpdateParameters()  end
      
      -- baseline
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx,spaceX,0)
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth( ctx, 50 ) 
      local retval, v = ImGui.SliderDouble( ctx, '##base'..sliderID..t.slaveJSFXlinksID, t.plink_baseline, 0, 1, '', ImGui.SliderFlags_None )
      if retval then t.set_base = v DATA:SlaveJSFX_Write(t)DATA:SlaveJSFX_UpdateParameters()  end
      ImGui.SameLine(ctx) ImGui.Text(ctx,'Baseline')
      if ImGui.IsItemClicked( ctx, ImGui.HoveredFlags_None ) then t.set_base = 0 DATA:SlaveJSFX_Write(t)DATA:SlaveJSFX_UpdateParameters()  end
      
    end
  end
  ---------------------------------------------------------------------
  function UI.MAIN_drawstuff_links_sub_graph(t, posx_abs0, posy_abs0 )
  
    --col 
      local framecol  = 0xFFFFFF0F 
      local maincurvecol  = 0xF0FFF05F
      local boundcurvecol  = maincurvecol--0xFFFFFF2F
      local slavecircle  = 0x0FFF0FFF
    
    -- val
      local sliderID  = DATA.sel_knob
      if not sliderID  then return end
      local val_master = DATA.masterJSFX_sliders[sliderID].val
      local hexarray_scale_min = t.hexarray_scale_min
      local hexarray_scale_max = 1-t.hexarray_scale_max
      local hexarray_lim_min = t.hexarray_lim_min
      local hexarray_lim_max = 1-t.hexarray_lim_max
      local val_slave = t.destfx_param 
      local flags_tension = math.floor(t.flags_tension*15)
    
    -- boundary
      local but_sz = UI.linkbutsz 
      local offbut = math.floor(but_sz/2)
      local rect_w = UI.calc_knobcollapsedW-UI.spacingX*3-but_sz
      local rect_h = UI.linkH
    
    
    --draw stuff
      local draw_list = ImGui.GetWindowDrawList( ctx )
      -- frame
      --ImGui.DrawList_AddRect(draw_list, posx_abs, posy_abs, posx_abs+rect_w, posy_abs+rect_h, framecol, 2, ImGui.DrawFlags_None) 
    
    -- curve 
      local posx_abs = posx_abs0+offbut
      local posy_abs = posy_abs0+offbut
      local curve_posx = posx_abs+rect_w*hexarray_lim_min
      local curve_posx3 = posx_abs+rect_w - rect_w*(1-hexarray_lim_max)
      local curve_posx2 = curve_posx+(curve_posx3-curve_posx)/2 
      local curve_posy = posy_abs+rect_h- hexarray_scale_min*rect_h
      local curve_posy3 = posy_abs+ (1-hexarray_scale_max)*rect_h
      local curve_posy2 = curve_posy+(curve_posy3-curve_posy)/2 
      ImGui.DrawList_AddBezierQuadratic( draw_list, curve_posx, curve_posy, curve_posx2, curve_posy2, curve_posx3, curve_posy3,maincurvecol, 2)
    
    -- boundary lines
      ImGui.DrawList_AddLine(draw_list, posx_abs, curve_posy, curve_posx, curve_posy, boundcurvecol, 2)
      ImGui.DrawList_AddLine(draw_list, curve_posx3, curve_posy3, posx_abs+rect_w, curve_posy3, boundcurvecol, 2)
    
    -- slave value
      local center_x = posx_abs + val_master * rect_w
      local center_y=  posy_abs + rect_h - val_slave * rect_h
      ImGui.DrawList_AddCircleFilled(draw_list, center_x, center_y, 3, slavecircle, 0)
    
    -- buttons
      ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xFFFFFF9F)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0xFFFFFFFF)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xFFFFFFBF)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
      
      ImGui.SetCursorScreenPos( ctx,curve_posx-offbut, curve_posy-offbut)
      if EXT.CONF_mode == 0 then 
        ImGui.Button(ctx,'##p1'..sliderID..t.slaveJSFXlinksID,but_sz,but_sz )
        if ImGui.IsItemActive( ctx ) then
          local x, y = ImGui.GetMouseDelta( ctx )
          if x ~= 0 or y ~= 0 then
            absx, absy = ImGui.GetMousePos( ctx )
            out_val1 = VF_lim((absx-posx_abs)/rect_w)
            out_val2 = VF_lim((absy-posy_abs)/rect_h)
            t.hexarray_lim_min = out_val1
            t.hexarray_scale_min =1- out_val2
            DATA:SlaveJSFX_Write(t)
            DATA:SlaveJSFX_UpdateParameters() 
          end
        end
      end
      
      ImGui.SetCursorScreenPos( ctx,curve_posx3-offbut, curve_posy3-offbut)
      if EXT.CONF_mode == 0 then 
        ImGui.Button(ctx,'##p3'..sliderID..t.slaveJSFXlinksID,but_sz,but_sz )
        if ImGui.IsItemActive( ctx ) then
          local x, y = ImGui.GetMouseDelta( ctx )
          if x ~= 0 or y ~= 0 then
            absx, absy = ImGui.GetMousePos( ctx )
            out_val1 = VF_lim((absx-posx_abs)/rect_w)
            out_val2 = VF_lim((absy-posy_abs)/rect_h)
            t.hexarray_lim_max = 1-out_val1
            t.hexarray_scale_max = out_val2
            DATA:SlaveJSFX_Write(t)
            DATA:SlaveJSFX_UpdateParameters() 
          end
        end
      end
      
      if EXT.CONF_mode == 0 then
        local but_tensionw = 8
        local but_tensionh = 4
        ImGui.SetCursorScreenPos( ctx,curve_posx2-but_tensionw/2, curve_posy2-but_tensionh/2)
        ImGui.Button(ctx,'##p2'..sliderID..t.slaveJSFXlinksID,but_tensionw,but_tensionh )
        if ImGui.IsItemActive( ctx ) then
          local x, y = ImGui.GetMouseDelta( ctx )
          if y ~= 0 then
            absx, absy = ImGui.GetMousePos( ctx )
            out_val2 = VF_lim((absy-posy_abs)/rect_h)
            t.flags_tension = 1-out_val2
            DATA:SlaveJSFX_Write(t)
            DATA:SlaveJSFX_UpdateParameters()  
          end
        end
      end
      
      
      --[[if EXT.CONF_mode == 1 then
        local midx = posx_abs + rect_w/2
        local but_ctrlw = 8
        local but_ctrlh = 8
        ImGui.SetCursorScreenPos( ctx,midx-but_ctrlw*1.5, curve_posy2-but_ctrlh/2)
        ImGui.Button(ctx,'##p2offs'..sliderID..t.slaveJSFXlinksID,but_ctrlw-1,but_ctrlh )
        if ImGui.IsItemActive( ctx ) then
          local x, y = ImGui.GetMouseDelta( ctx )
          if y ~= 0 then
            absx, absy = ImGui.GetMousePos( ctx )
            out_val2 = VF_lim((absy-posy_abs)/rect_h, -1, 1)
            t.set_offs = -out_val2
            DATA:SlaveJSFX_Write(t)
            DATA:SlaveJSFX_UpdateParameters()  
          end
        end
        
        ImGui.SetCursorScreenPos( ctx,midx-but_ctrlw*0.5, curve_posy2-but_ctrlh/2)
        ImGui.Button(ctx,'##p2scale'..sliderID..t.slaveJSFXlinksID,but_ctrlw-1,but_ctrlh )
        if ImGui.IsItemActive( ctx ) then
          local x, y = ImGui.GetMouseDelta( ctx )
          if y ~= 0 then
            absx, absy = ImGui.GetMousePos( ctx )
            out_val2 = VF_lim(  (absy-posy_abs)/rect_h, -1, 1)
            t.set_scale = -out_val2
            DATA:SlaveJSFX_Write(t)
            DATA:SlaveJSFX_UpdateParameters()  
          end
        end
        
        ImGui.SetCursorScreenPos( ctx,midx+but_ctrlw*0.5, curve_posy2-but_ctrlh/2)
        ImGui.Button(ctx,'##p2base'..sliderID..t.slaveJSFXlinksID,but_ctrlw-1,but_ctrlh )
        if ImGui.IsItemActive( ctx ) then
          local x, y = ImGui.GetMouseDelta( ctx )
          if y ~= 0 then
            absx, absy = ImGui.GetMousePos( ctx )
            out_val2 = VF_lim((absy-posy_abs)/rect_h,-1,1)
            t.set_base = -out_val2
            DATA:SlaveJSFX_Write(t)
            DATA:SlaveJSFX_UpdateParameters()  
          end
        end
        
      end]]
      
      
      ImGui.PopStyleColor(ctx, 3)
      ImGui.PopStyleVar(ctx, 1)
    
    -- draw histogram 
      ImGui.SetCursorScreenPos( ctx,posx_abs0+offbut, posy_abs0+offbut )
      
        local arr = reaper.new_array(rect_w) 
        local pow_float = 1
        if EXT.CONF_mode == 0 then  -- ignore tension for slave per jsfx mode
          local  tens_mapt = {1, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 2, 3, 4, 5, 6, 7, 8, 10}
          if tens_mapt[flags_tension+1] then pow_float = tens_mapt[flags_tension+1]  end
        end
        local slope 
        if hexarray_lim_max == hexarray_lim_min then slope = 0 else slope = (hexarray_scale_max - hexarray_scale_min) / (hexarray_lim_max-hexarray_lim_min)end 
        local val
        for i = 1, rect_w do
          val= 0
          local progr_x = VF_lim(i / rect_w)
          if progr_x < hexarray_lim_min then 
            val = hexarray_scale_min 
           elseif progr_x > hexarray_lim_max then 
            val = hexarray_scale_max 
           else
            val = hexarray_scale_min +  ((  (progr_x-hexarray_lim_min)/(hexarray_lim_max - hexarray_lim_min)  )^pow_float)*(hexarray_scale_max - hexarray_scale_min)
          end
          arr[i] = val
        end 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0,0)
        if ImGui.BeginDisabled(ctx,true) then 
          ImGui.PlotHistogram(ctx, '##hist'..sliderID..t.slaveJSFXlinksID, arr, 0, nil, 0, 1, rect_w, rect_h)
          ImGui.EndDisabled(ctx)
        end
        ImGui.PopStyleVar(ctx,1)
  end
  
  ---------------------------------------------------------------------  
  function DATA:Macro_Select(sliderID)
    if EXT.CONF_mode == 1 then
      DATA:MasterJSFX_Validate()
      if DATA.masterJSFX_isvalid ~= true then DATA:MasterJSFX_Validate_Add() end 
    end
    
    local out = 2^(sliderID-1)
    if DATA.masterJSFX_slselectionmask ~= out then 
      DATA.masterJSFX_slselectionmask =  out
      
      
      if DATA.masterJSFX_isvalid == true then
        DATA:MasterJSFX_WriteSliders(sliderID)
        DATA:SlaveJSFX_Read()
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA.Action_SetMIDILearn(clear) -- set las touched control to last touched param
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    if not retval then return end
    
    local trid = tracknumber&0xFFFF
    local itid = (tracknumber>>16)&0xFFFF
    if itid > 0 then return end -- ignore item FX
    local tr
    if trid==0 then tr = GetMasterTrack(0) else tr = GetTrack(0,trid-1) end
    if not tr then return end
    
    if clear == true then
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.learn.midi1', 0)
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.learn.midi2', 0)
      return true
    end
    
    local retval1, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
    if retval1 == 0 then return end
    midi2 = rawmsg:byte(2)
    midi1 = rawmsg:byte(1)
    
    TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.learn.midi1', midi1)
    TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.learn.midi2', midi2)
    
    return true
  end
  ---------------------------------------------------------------------  
  function DATA:Macro_Reset()
    for i = 1, #DATA.masterJSFX_sliders do DATA.masterJSFX_sliders[i].val = 0 end
    DATA:MasterJSFX_WriteSliders()
  end
    --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff_actions(local_pos_x, local_pos_y) 
    ImGui.SetCursorPos( ctx, local_pos_x , local_pos_y)
    ImGui.Indent( ctx, UI.main_butw + UI.spacingX)
      if ImGui.Button(ctx, 'Random all knobs',UI.calc_knobcollapsedW,UI.calc_knobcollapsedH) then DATA:Macro_Random() end
      ImGui.SameLine(ctx) UI.draw_flow_SLIDER({['key']='Strength',                                 ['extstr'] = 'CONF_randstrength',           ['format']='%.1f%%',  ['percent'] = true,})
      
      if ImGui.Button(ctx, 'Random selected knob',UI.calc_knobcollapsedW,UI.calc_knobcollapsedH) then DATA:Macro_Random(true) end
      ImGui.SameLine(ctx) UI.draw_flow_SLIDER({['key']='Strength',                                 ['extstr'] = 'CONF_randstrength2',           ['format']='%.1f%%',  ['percent'] = true,})
      
      
      if ImGui.Button(ctx, 'Reset all knobs',UI.calc_knobcollapsedW,UI.calc_knobcollapsedH) then DATA:Macro_Reset() end
    ImGui.Unindent( ctx, UI.main_butw + UI.spacingX)
    
    
    
  end 
    --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff_varlist(local_pos_x, local_pos_y) 
    if not DATA.masterJSFX_variations_list then return end
    ImGui.SetCursorPos( ctx, local_pos_x , local_pos_y)
    ImGui.Indent( ctx, UI.main_butw + UI.spacingX)
    
    local but_rec_w = UI.calc_knobcollapsedH*2 
    local but_varplay_w = UI.calc_knobcollapsedH
    local but_var_w = UI.calc_knobcollapsedW*2-but_rec_w-but_varplay_w-UI.spacingY
    
    for varID = 1, 8 do
      -- print
      local name = 'Variation '..varID
      if ImGui.Button(ctx, 'rec##rec'..varID,but_rec_w,UI.calc_knobcollapsedH) then  DATA:Vari_Rec(varID)   end 
      ImGui.SameLine(ctx) 
      
      -- name
      if DATA.masterJSFX_variations_list[varID] and DATA.masterJSFX_variations_list[varID].name then name = DATA.masterJSFX_variations_list[varID].name end
      ImGui.PushItemWidth( ctx, but_var_w )
      local retval, buf = ImGui.InputText( ctx, '##varname'..varID, name, ImGui.InputTextFlags_EnterReturnsTrue )
      if retval == true then 
        DATA.masterJSFX_variations_list[varID].name = buf
        DATA:MasterJSFX_WriteSliders()
      end
      ImGui.SameLine(ctx) 
      
      -- play
      local selected = DATA.masterJSFX_variations_list[varID] and DATA.masterJSFX_variations_list[varID].issel == 1 
      if selected  == true  then ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xFFFFFF3F) end
      ImGui.PushItemWidth( ctx, but_varplay_w )
      if ImGui.ArrowButton( ctx, '##vdir'..varID, ImGui.Dir_Right ) then DATA:Vari_Play(varID) end
      if selected == true then ImGui.PopStyleColor(ctx) end
    end
    
      
    ImGui.Unindent( ctx, UI.main_butw + UI.spacingX)
  end 
  ---------------------------------------------------------------------  
  function DATA:Vari_Rec(varID)  
    for i = 1, 16 do DATA.masterJSFX_variations_list[varID].macrolist[i] = DATA.masterJSFX_sliders[i].val end -- print current values to variation
    DATA:MasterJSFX_WriteSliders()
  end
  ---------------------------------------------------------------------  
  function DATA:Vari_Play(varID)  
    if not DATA.masterJSFX_variations_list then return end
    -- set selected
      for i = 1, 8 do DATA.masterJSFX_variations_list[i].issel = 0 end 
      DATA.masterJSFX_variations_list[varID].issel = 1
     -- set macro values
      for i = 1, 16 do 
        if DATA.masterJSFX_sliders[i].flags&2~=2 then -- exclude from var flag
          DATA.masterJSFX_sliders[i].val = DATA.masterJSFX_variations_list[varID].macrolist[i] 
        end
      end
    -- upodate sliders
      DATA:MasterJSFX_WriteSliders()
  end
  
  
  -------------------------------------------------------------------------------- 
  function UI.GetUserInputMB_replica(mode, key, title, num_inputs, captions_csv, retvals_csv_returnfunc, retvals_csv_setfunc) 
    local round = 4
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, round)
    
      -- draw content
      -- (from reaimgui demo) Always center this window when appearing
      local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
      ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing, 0.5, 0.5)
      if ImGui.BeginPopupModal(ctx, key, nil, ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Border) then
      
        -- MB replika
        if mode == 0 then
          ImGui.Text(ctx, captions_csv)
          ImGui.Separator(ctx) 
        
          if ImGui.Button(ctx, 'OK', 0, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end
          
          --[[ImGui.SetItemDefaultFocus(ctx)
          ImGui.SameLine(ctx)
          if ImGui.Button(ctx, 'Cancel', 120, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end]]
        end
        
        -- GetUserInput replika
        if mode == 1 then
          ImGui.SameLine(ctx)
          ImGui.SetKeyboardFocusHere( ctx )
          local retval, buf = ImGui.InputText( ctx, captions_csv, retvals_csv_returnfunc(), ImGui.InputTextFlags_EnterReturnsTrue ) 
          if retval then
            retvals_csv_setfunc(retval, buf)
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end 
        end
        
        ImGui.EndPopup(ctx)
      end 
    
    
    ImGui.PopStyleVar(ctx, 4)
  end 
  
  --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff_contextmenu_macro()  
  
    
    
    -- local sliderID = DATA,sel_knob  -- do not use because it doesn refresh knob immediately
    local sliderID = DATA:GetSelectedKnob() 
    if not sliderID then return end
    local valid = DATA.masterJSFX_isvalid and DATA.masterJSFX_isvalid  == true-- or (EXT.CONF_mode == 1 and DATA.masterJSFX_tr and ValidatePtr(DATA.masterJSFX_tr,'MediaTrack*'))
    local flagdis = ImGui.SelectableFlags_Disabled
    if valid == true then flagdis = ImGui.SelectableFlags_None end
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 1)
    ImGui.SeparatorText(ctx,'Macro '.. sliderID) 
    
    if ImGui.Selectable(ctx, 'Link last touched parameter') then  
      DATA:Link_add()
    end
    
    ImGui.SeparatorText(ctx, 'Macro parameters')
    
    if ImGui.Selectable(ctx, 'Set macro name') then  
      UI.popups['Set macro name'] = {
        trig = true,
        captions_csv = 'New macro name',
        func_getval = function()  
          local sliderID = DATA:GetSelectedKnob() 
          if not (sliderID and DATA.masterJSFX_sliders[sliderID] and DATA.masterJSFX_sliders[sliderID].name) then return '' end
          return DATA.masterJSFX_sliders[sliderID].name
        end,
        
        func_setval = function(retval, retvals_csv)  
          local sliderID = DATA:GetSelectedKnob() 
          if retval == true and not (retvals_csv:match('Macro %d+') and retvals_csv:match('Macro %d+') == retvals_csv)then
            DATA.masterJSFX_sliders[sliderID].name = retvals_csv:gsub('|','')
            DATA:MasterJSFX_WriteSliders(sliderID)
          end
        end
        }
    end 
    
    if ImGui.Selectable(ctx, 'Reset macro name') then 
      local sliderID = DATA:GetSelectedKnob() 
      DATA.masterJSFX_sliders[sliderID].name = 'Macro '..sliderID
      DATA:MasterJSFX_WriteSliders(sliderID)
    end
    
    local col_RRGGBB = 0--0x1000000
    if DATA.masterJSFX_sliders[sliderID] and DATA.masterJSFX_sliders[sliderID].col then
      local col = DATA.masterJSFX_sliders[sliderID].col
      if type(col) == 'string' then
        local str = col:gsub('#','')
        local col = tonumber(str,16)
        local b, g, r = ColorFromNative( col ) 
        col_RRGGBB = (r<<16)|(g<<8)|b
      end
    end 
    
    local flags = ImGui.ColorEditFlags_None | ImGui.ColorEditFlags_NoOptions | ImGui.ColorEditFlags_NoSidePreview|ImGui.ColorEditFlags_NoLabel|ImGui.ColorEditFlags_NoInputs
    ImGui.SetNextItemWidth( ctx, 150 )
    local retval, col_rgba = ImGui.ColorPicker4( ctx, '##Set macro color', (col_RRGGBB<<8)|0xFF, flags  )
    if retval then
      local sliderID = DATA:GetSelectedKnob() 
      local outhex = '#'..string.format("%06X", (col_rgba&0xFFFFFF00)>>8)  
      DATA.masterJSFX_sliders[sliderID].col = outhex
      DATA:MasterJSFX_WriteSliders(sliderID)
    end
    
    if ImGui.Selectable(ctx, 'Reset macro color') then 
      local sliderID = DATA:GetSelectedKnob() 
      DATA.masterJSFX_sliders[sliderID].col = -1
      DATA:MasterJSFX_WriteSliders(sliderID)
    end
    
    ImGui.SeparatorText(ctx,'Options') 
    
    local exclrand = DATA.masterJSFX_sliders[sliderID].flags&1==1
    if ImGui.Checkbox( ctx, 'Exclude from randomization', exclrand ) then 
      DATA.masterJSFX_sliders[sliderID].flags = DATA.masterJSFX_sliders[sliderID].flags~1
      DATA:MasterJSFX_WriteSliders(sliderID)
    end
    
    local exclvar = DATA.masterJSFX_sliders[sliderID].flags&2==2
    if ImGui.Checkbox( ctx, 'Exclude from variation', exclvar ) then 
      DATA.masterJSFX_sliders[sliderID].flags = DATA.masterJSFX_sliders[sliderID].flags~2
      DATA:MasterJSFX_WriteSliders(sliderID)
    end
    
    local ext_snapback_use = DATA.masterJSFX_sliders[sliderID].ext_snapback_use  == 1
    if ImGui.Checkbox( ctx, 'Use snapback', ext_snapback_use ) then 
      DATA.masterJSFX_sliders[sliderID].ext_snapback_use = DATA.masterJSFX_sliders[sliderID].ext_snapback_use~1
      DATA:MasterJSFX_WriteSliders(sliderID)
    end    
    
    if DATA.masterJSFX_sliders[sliderID].ext_snapback_use == 1 then
      ImGui.SetNextItemWidth( ctx, 100 )
      local retval, v = ImGui.SliderDouble( ctx, 'Snapback value##snapbackval'..sliderID, DATA.masterJSFX_sliders[sliderID].ext_snapback_val, 0, 1, '%.3f', ImGui.SliderFlags_None )
      if retval then 
        DATA.masterJSFX_sliders[sliderID].ext_snapback_val = v
        DATA:MasterJSFX_WriteSliders(sliderID)
      end 
      if ImGui.Button(ctx, 'Use current value##snapbackvalcur'..sliderID) then
        DATA.masterJSFX_sliders[sliderID].ext_snapback_val = DATA.masterJSFX_sliders[sliderID].val
        DATA:MasterJSFX_WriteSliders(sliderID)
      end
      ImGui.SetNextItemWidth( ctx, 100 )
      local retval, v = ImGui.SliderDouble( ctx, 'Snapback time##snapbacktime'..sliderID, DATA.masterJSFX_sliders[sliderID].ext_snapback_time, 0, 500, '%.0fms', ImGui.SliderFlags_None )
      if retval then 
        DATA.masterJSFX_sliders[sliderID].ext_snapback_time = v
        DATA:MasterJSFX_WriteSliders(sliderID)
      end 
    end

    
    
    ImGui.SeparatorText(ctx,'Actions') 
    if ImGui.Selectable(ctx, 'Show/hide track envelope',nil,flagdis) and valid == true then 
      local track = DATA.masterJSFX_tr
      SetMixerScroll( track )
      TrackFX_EndParamEdit( track, DATA.masterJSFX_FXid, sliderID-1 )
      VF_Action(41142)--FX: Show/hide track envelope for last touched FX parameter
    end
    
    if ImGui.Selectable(ctx, 'Arm track envelope',nil,flagdis)and valid == true then 
      local track = DATA.masterJSFX_tr
      TrackFX_EndParamEdit( track, DATA.masterJSFX_FXid, sliderID-1 )
      VF_Action(41984) --FX: Arm track envelope for last touched FX parameter
    end

    if ImGui.Selectable(ctx, 'Toggle activate/bypass track envelope',nil,flagdis) and valid == true then 
      local track = DATA.masterJSFX_tr
      TrackFX_EndParamEdit( track, DATA.masterJSFX_FXid, sliderID-1 )
      VF_Action(41983) --FX: Activate/bypass track envelope for last touched FX parameter
    end
    
    local control = '[no control touched]'
    if DATA.last_inc_MIDI1_str then control = DATA.last_inc_MIDI1_str end 
    if ImGui.Selectable(ctx, 'Set MIDI learn to: '..control,nil,flagdis) and valid == true then 
      local track = DATA.masterJSFX_tr
      TrackFX_EndParamEdit( track, DATA.masterJSFX_FXid, sliderID-1 )
      --VF_Action(41144) --FX: Set MIDI learn for last touched FX parameter]]
      DATA.Action_SetMIDILearn()
    end
    
    local control  
    if DATA.masterJSFX_sliders[sliderID] and DATA.masterJSFX_sliders[sliderID].midi1 and DATA.masterJSFX_sliders[sliderID].midi2 then 
      if DATA.masterJSFX_sliders[sliderID].midi1&0xB0==0xB0 then 
        local id = DATA.masterJSFX_sliders[sliderID].midi2
        local chan = DATA.masterJSFX_sliders[sliderID].midi1&0x0F
        control = 'Remove MIDI learn: '..'CC '..id..' Chan '..chan
      end
    end 
    if control then
      if ImGui.Selectable(ctx, control,nil,flagdis) and valid == true then 
        local track = DATA.masterJSFX_tr
        TrackFX_EndParamEdit( track, DATA.masterJSFX_FXid, sliderID-1 )
        --VF_Action(41144) --FX: Set MIDI learn for last touched FX parameter]]
        DATA.Action_SetMIDILearn(true)
      end
    end
    
    if ImGui.Selectable(ctx, 'Show parameter modulation/link',nil,flagdis) and valid == true then 
      local track = DATA.masterJSFX_tr  
      TrackFX_EndParamEdit( track, DATA.masterJSFX_FXid, sliderID-1 )
      VF_Action(41143) --FX: Show parameter modulation/link for last touched FX parameter
    end
    
    if ImGui.Selectable(ctx, 'Remove all links from this macro',nil,flagdis) then 
      for i = #DATA.slaveJSFXlinks,1,-1 do DATA:Link_remove(DATA.slaveJSFXlinks[i]) DATA:SlaveJSFX_Read()  end 
    end
    
    
    ImGui.PopStyleVar(ctx, 1)
  end
  --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff_knobs(local_pos_x, local_pos_y)  
    
    
    local app_func_onmouseclick = function(sliderID) 
                                    DATA:Macro_Select(sliderID) 
                                  end
    local app_func_onmousedrag =  function(sliderID, outval, ismajor) 
                                    DATA.masterJSFX_sliders[sliderID].val = outval
                                    DATA:MasterJSFX_WriteSliders(sliderID) 
                                    DATA:SlaveJSFX_UpdateParameters() 
                                  end
    
    
    local knobW = UI.calc_knobW
    local knobH = UI.calc_knobH
    if DATA.knobscollapsed == 1 then
      knobW = UI.calc_knobcollapsedW
      knobH = UI.calc_knobcollapsedH
    end
    
    local paramval, col, row, curposX, curposY, name
    
    for sliderID = 1, 16 do
      name = 'Macro '..sliderID
      if DATA.masterJSFX_sliders and DATA.masterJSFX_sliders[sliderID] and DATA.masterJSFX_sliders[sliderID].name then name = DATA.masterJSFX_sliders[sliderID].name end
      row = math.floor((sliderID-1)/8)
      col = ((sliderID-1)%8)
      curposX = local_pos_x + UI.main_butw + UI.spacingX * (col+1) + UI.calc_knobW*col
      curposY = local_pos_y  + UI.calc_knobH * row + UI.spacingY * row 
      if DATA.knobscollapsed == 1 then
        col = math.floor((sliderID-1)/8)
        row = ((sliderID-1)%8)
        --curposX = local_pos_x + UI.main_butw*5  + UI.calc_knobcollapsedW *col+UI.spacingX*col
        curposX = local_pos_x + UI.main_butw + UI.spacingX*2 + UI.calc_knobcollapsedW*2 + UI.spacingX + UI.calc_knobcollapsedW *col+UI.spacingX*col
        curposY = local_pos_y  + UI.calc_knobcollapsedH * row + UI.spacingY * row
      end
      ImGui.SetCursorPos( ctx, curposX, curposY)
      paramval = 0
      if DATA.masterJSFX_sliders and DATA.masterJSFX_sliders[sliderID] and DATA.masterJSFX_sliders[sliderID].val  then paramval = DATA.masterJSFX_sliders[sliderID].val end
      local selected = DATA.masterJSFX_slselectionmask and DATA.masterJSFX_slselectionmask&(1<<(sliderID-1)) == (1<<(sliderID-1))
      
      local col
      if DATA.masterJSFX_sliders and DATA.masterJSFX_sliders[sliderID] and DATA.masterJSFX_sliders[sliderID].col then
        col = DATA.masterJSFX_sliders[sliderID].col
      end
      UI.draw_knob(sliderID, knobW, knobH, paramval, app_func_onmouseclick, app_func_onmousedrag, app_func_header, DATA.knobscollapsed == 1, selected, name, col) 
    end
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
  function UI.draw_flow_COMBO(t)
    local preview_value = t.values[EXT[t.extstr]]
    ImGui.SetNextItemWidth( ctx, 200 )
    if ImGui.BeginCombo( ctx, t.key, preview_value ) then
      for id in spairs(t.values) do
        if ImGui.Selectable( ctx, t.values[id], id==EXT[t.extstr]) then
          EXT[t.extstr] = id
          EXT:save()
          if t.appfunc then t.appfunc() end
        end
      end
      ImGui.EndCombo(ctx)
    end
    
    -- reset
    if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
      DATA.PRESET_RestoreDefaults(t.extstr)
    end 
    
    if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_flow_CHECK(t)
    if t and t.hide then return end
    local byte = t.confkeybyte or 0
    if reaper.ImGui_Checkbox( ctx, t.key, EXT[t.extstr]&(1<<byte)==(1<<byte) ) then 
      EXT[t.extstr] = EXT[t.extstr]~(1<<byte) 
      EXT:save() 
    end
    -- reset
    if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
      DATA.PRESET_RestoreDefaults(t.extstr)
    end
    
    if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
    
  end
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
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  --------------------------------------------------------------------- 
  function DATA:Macro_Random(selected)
    if not DATA.masterJSFX_sliders then return end
    
    local i_st = 1
    local i_end =  #DATA.masterJSFX_sliders 
    if selected == true then
      if not DATA.sel_knob then return end
      i_st = DATA.sel_knob
      i_end = DATA.sel_knob
    end
    for i =i_st,i_end do
      local outval = DATA.masterJSFX_sliders[i].val
      if EXT.CONF_randstrength == 1 then 
        outval = math.random() 
       else 
        outval  = VF_lim(DATA.masterJSFX_sliders[i].val+(math.random()-0.5)*EXT.CONF_randstrength) 
        if selected == true then 
          outval  = VF_lim(DATA.masterJSFX_sliders[i].val+(math.random()-0.5)*EXT.CONF_randstrength2) 
        end
      end
      if EXT.CONF_randpreventrandfromlimits == 1 and  (DATA.masterJSFX_sliders[i].val == 0 or DATA.masterJSFX_sliders[i].val == 1) then 
        outval = DATA.masterJSFX_sliders[i].val 
      end
      
      if DATA.masterJSFX_sliders[i].flags&1~=1 then -- exclude from rand flag
        DATA.masterJSFX_sliders[i].val = outval
      end
    end
    DATA:MasterJSFX_WriteSliders()
  end
  --------------------------------------------------------------------------------  
  function UI.draw_flow_SLIDER(t) 
      ImGui.SetNextItemWidth( ctx, 100 )
      local retval, v
      if t.int then
        local format = t.format
        retval, v = reaper.ImGui_SliderInt ( ctx, t.key..'##'..t.extstr, math.floor(EXT[t.extstr]), t.min, t.max, format )
       elseif t.percent then
        retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr]*100, t.percent_min or 0, t.percent_max or 100, t.format or '%.1f%%' )
       else  
        retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr], t.min, t.max, t.format )
      end
      
      
      if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
        DATA.PRESET_RestoreDefaults(t.extstr)
       else
        if retval then 
          if t.percent then EXT[t.extstr] = v /100 else EXT[t.extstr] = v  end
          EXT:save() 
        end
      end
    
      if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
      
  end
  --------------------------------------------------------------------------------  
  function UI.MAIN_drawstuff_menu(local_pos_x, local_pos_y) 
    local indent = 30
    ImGui.SetCursorPos( ctx, local_pos_x + UI.main_butw + UI.spacingX , local_pos_y)
    if ImGui.BeginChild( ctx, '##settings', 0, 0, ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then
      
      ImGui.BeginDisabled(ctx,true)
      ImGui.Text(ctx,'Mapping panel version '..vrs)
      ImGui.EndDisabled(ctx)
      ImGui.SeparatorText(ctx,'General / UI')
      UI.draw_flow_COMBO({['key']='Mode',                                             ['extstr'] = 'CONF_mode',                   ['values'] = {[0]='Master JSFX', [1]='Slave JSFX per track'}, appfunc =
        function() 
          if EXT.CONF_mode == 1 then -- if turned into slave mode
            DATA:MasterJSFX_Remove()
            DATA:MasterJSFX_Validate()
            if DATA.masterJSFX_isvalid ~= true then DATA:MasterJSFX_Validate_Add() end 
          elseif EXT.CONF_mode == 0 then-- if turned into master mode
            DATA:MasterJSFX_Validate()
            if DATA.masterJSFX_isvalid ~= true then DATA:MasterJSFX_Validate_Add() end 
          end  
        end
        
        }) 
      
      ImGui.SameLine(ctx)
      ImGui.SeparatorText(ctx,'Random')
      UI.draw_flow_CHECK({['key']='Do not random 0 and 1 values',                     ['extstr'] = 'CONF_randpreventrandfromlimits',  })
      
      ImGui.SeparatorText(ctx,'Links')
      UI.draw_flow_CHECK({['key']='When add link, port slave value to master knob',   ['extstr'] = 'CONF_setslaveparamtomaster',  })
      UI.draw_flow_CHECK({['key']='Rename macro knob from last touched parameter',    ['extstr'] = 'CONF_addlinkrenameflags',     confkeybyte=0})
      ImGui.Indent(ctx, indent)  
      UI.draw_flow_CHECK({['key']='Only when default name',                           ['extstr'] = 'CONF_addlinkrenameflags',     confkeybyte=1, hide = EXT.CONF_addlinkrenameflags&1~=1}) ImGui.Unindent(ctx, indent)
      
      ImGui.EndChild( ctx)
    end
  end
  ---------------------------------------------------
  function VF_CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[VF_CopyTable(orig_key)] = VF_CopyTable(orig_value)
          end
          setmetatable(copy, VF_CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end
  ----------------------------------------------------------------------------------------- 
  function main()  
    reaper.gmem_attach('MappingPanel' )
    EXT_defaults = VF_CopyTable(EXT)
    UI.MAIN_definecontext() 
  end  
  -----------------------------------------------------------------------------------------
  main()