-- @description MappingPanel
-- @version 3.03
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Script for link parameters across tracks
-- @changelog
--    # fix error at reset macro name
--    # remove controls from slave mode



-- to do 
--[[ 
  formula control
  remove master jsfx
  remove all slave jsfx
  when store variation ask for name
  edit offset/scale 
  remove mapping from current track 
]]

-- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN
  
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
  
  DATA2 = { }
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '3.03'
    DATA.extstate.extstatesection = 'MPL_MappingPanel'
    DATA.extstate.mb_title = 'Mapping Panel'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  640,
                          wind_h =  480,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          CONF_setslaveparamtomaster = 1,
                          CONF_randstrength = 1,
                          CONF_randpreventrandfromlimits = 1,
                          CONF_mode = 0,
                          CONF_addlinkrenameflags = 1|2, -- &1 rename &2 only if default name
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,  
                          
                          UI_showvarlist = 0,  
                          UI_showgraph = 1,  
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
    DATA_RESERVED_ONPROJCHANGE(DATA)
    RUN()
  end
  ---------------------------------------------------------------------  
  function DATA2:Macro_Random()
    if not DATA2.masterJSFX_sliders then return end
    for i = 1, #DATA2.masterJSFX_sliders do
      local outval = DATA2.masterJSFX_sliders[i].val
      if DATA.extstate.CONF_randstrength == 1 then outval = math.random() else outval  = VF_lim(DATA2.masterJSFX_sliders[i].val+(math.random()-0.5)*DATA.extstate.CONF_randstrength) end
      if DATA.extstate.CONF_randpreventrandfromlimits == 1 and  (DATA2.masterJSFX_sliders[i].val == 0 or DATA2.masterJSFX_sliders[i].val == 1) then outval = DATA2.masterJSFX_sliders[i].val end
      
      if DATA2.masterJSFX_sliders[i].flags&1~=1 then -- exclude from rand flag
        DATA2.masterJSFX_sliders[i].val = outval
      end
    end
    DATA2:MasterJSFX_WriteSliders()
    GUI_Upd_Macro(DATA)
  end
  ---------------------------------------------------------------------  
  function DATA2:Macro_Reset()
    for i = 1, #DATA2.masterJSFX_sliders do
      DATA2.masterJSFX_sliders[i].val = 0
    end
    DATA2:MasterJSFX_WriteSliders()
  end
  ---------------------------------------------------------------------  
  function GUI_MainButtons(DATA) 
    local but_h = math.floor(DATA.GUI.custom_mainbuth/3)
      DATA.GUI.buttons.app = {
                                    x=DATA.GUI.custom_offset,
                                    y=DATA.GUI.custom_offset,
                                    w=DATA.GUI.custom_mainbutw,
                                    h=but_h-DATA.GUI.custom_offset-1,
                                    txt = 'Menu',
                                    txt_fontsz = DATA.GUI.custom_mainbuttxtsz,
                                    onmouseclick =    function() end,
                                    onmouserelease  = function()
                                      DATA.GUI.Settings_open =DATA.GUI.Settings_open~1
                                      GUI_RESERVED_init(DATA)
                                    end
                                  }
                            
     DATA.GUI.buttons.random = {  x=DATA.GUI.custom_offset,
                                   y=but_h,
                                   w=DATA.GUI.custom_mainbutw,
                                   h=but_h-1,
                                   txt = 'Rand',
                                   txt_fontsz = DATA.GUI.custom_mainbuttxtsz,
                                   onmouserelease  = function() 
                                      DATA2:Macro_Random()
                                   end
                               }
     DATA.GUI.buttons.var = {     x=DATA.GUI.custom_offset,
                                  y=but_h*2,
                                  w=DATA.GUI.custom_mainbutw,
                                  h=but_h,
                                  txt = 'VariList',
                                  txt_fontsz = DATA.GUI.custom_mainbuttxtsz,
                                  onmouserelease  = function()  
                                    DATA.extstate.UI_showvarlist =DATA.extstate.UI_showvarlist~1
                                    DATA.UPD.onconfchange =  true
                                    GUI_RESERVED_init(DATA)
                                  end
                               }                               
      DATA.GUI.buttons.addlink = {  x=DATA.GUI.custom_offset,
                                    y=DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth,
                                    w=DATA.GUI.custom_mainbutw,
                                    h=DATA.GUI.custom_mainbuth,
                                    txt = 'Link\nlast\ntouched\nparam',
                                    txt_fontsz = DATA.GUI.custom_mainbuttxtsz,
                                    onmouserelease  = function() 
                                      local sel_knob = DATA2:GetSelectedKnob()
                                      if sel_knob == 0 then 
                                        local knobid = 1
                                        DATA2.masterJSFX_slselectionmask = 2^(knobid-1) 
                                        DATA2:MasterJSFX_WriteSliders(knobid)
                                      end
                                      DATA2:Link_add() 
                                      DATA2:SlaveJSFX_Read()
                                      GUI_Links(DATA) 
                                    end
                                }   
      if DATA.GUI.custom_compactmode > 0 then DATA.GUI.buttons.addlink.txt = 'Link' end
  end
  ------------------------------------------------------------------
  function DATA2:SlaveJSFX_Validate(tr) 
    for fx = 1, TrackFX_GetCount(tr) do
      local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
      if fxname:match('MappingPanel_slave') then return fx-1 end
    end
    
    -- add if not found
    reaper.PreventUIRefresh( 1 )
    local fx_new =  TrackFX_AddByName( tr, 'JS:MappingPanel_slave.jsfx', false, -1000 ) 
    reaper.TrackFX_Show( tr, fx_new, 2 ) -- add and hide
    reaper.PreventUIRefresh( -1 )
    return fx_new
  end
  ----------------------------------------------------------------------------------
  function DATA2:Link_add(ignorelasttouched, tr_pass, fxnumber_pass, paramnumber_pass)
    if DATA.extstate.CONF_mode == 0 then
      if not (DATA2.masterJSFX_isvalid == true) then 
        DATA2:MasterJSFX_Validate_Add()
        DATA2:MasterJSFX_Validate_Find()
      end 
      if not (DATA2.masterJSFX_isvalid == true) then 
        MB('Error loading master JSFX', DATA.extstate.mb_title, 0) 
        return
      end
    end
    
    local sel_knob = DATA2:GetSelectedKnob()
          
    -- get last touched param
    local retval, tracknumber, fxnumber, paramnumber, tr
    
    if not ignorelasttouched then 
      retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
      if not retval then return end 
      local trid = tracknumber&0xFFFF 
       tr = GetTrack(0,trid-1) if trid==0 then tr = GetMasterTrack(0) end
      if DATA.extstate.CONF_mode == 1 and tr ~= GetSelectedTrack(DATA2.ReaProj,0)then  MB('You are in "slave JSFX per track" mode, only inside track links supported"', DATA.extstate.mb_title, 0)  return end
      local itid = (tracknumber>>16)&0xFFFF
      if itid ~= 0 then MB('Item FX is not supported yet', DATA.extstate.mb_title, 0) return end 
      
    end
    -- NOT lasttouched
    if ignorelasttouched == true then
      tr, fxnumber, paramnumber = tr_pass, fxnumber_pass, paramnumber_pass
    end
    
    --
      if paramnumber == -1 then return end
    
    -- prevent utilities from link
      local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fxnumber, 'original_name' )
      if fxname:match('MappingPanel') then  MB('Last touched FX should not be Mapping Panel utility', DATA.extstate.mb_title, 0) return end
    
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
      if DATA2.masterJSFX_tr == tr and DATA2.masterJSFX_FXid == fxnumber then return end 
    -- get slave fx/add
      local slavefx_id = DATA2:SlaveJSFX_Validate(tr) 
      if not slavefx_id then MB('Link is not added. Can`t find Mapping Panel slave JSFX.', DATA.extstate.mb_title, 0) return  end   
    -- refresh last touched fx after slave jsfx possible adding 
      if not ignorelasttouched then
        retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX() 
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
            if DATA.extstate.CONF_mode == 1 then paramSrc = sel_knob-1 end
            linkfill[paramSrc]=1
            ::nextparam::
          end
        end
      end  
      
      local freeslider 
      if DATA.extstate.CONF_mode == 0 then 
        for segmid = 0, 3 do 
          for i = 0, 15 do 
            local test_param = i+segmid*64 
            if not linkfill[test_param] then freeslider = test_param goto skipcheck end 
          end 
        end 
        ::skipcheck::
        if not freeslider then MB('Can`t find free available slider', DATA.extstate.mb_title, 0) return  end
      end
      
      if DATA.extstate.CONF_mode == 1 then freeslider = sel_knob-1 end
    -- link to that slider
      local prelinkedparamvalue = TrackFX_GetParamNormalized( tr, fxnumber, paramnumber)
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.active', 1 )
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.effect', slavefx_id )
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.plink.param', freeslider )
     
    -- link slider to selected knob
      
      
      if DATA.extstate.CONF_mode == 0 then
        TrackFX_SetParam( tr, slavefx_id, freeslider+16, sel_knob )
        DATA2.masterJSFX_sliders[sel_knob].scroll = 1
        if DATA.extstate.CONF_setslaveparamtomaster == 1 then DATA2.masterJSFX_sliders[sel_knob].val = prelinkedparamvalue end
        DATA2:MasterJSFX_WriteSliders(sel_knob)
        GUI_Upd_Macro(DATA,sel_knob) 
       elseif DATA.extstate.CONF_mode == 1 then
        TrackFX_SetParam( tr, slavefx_id, freeslider+16, 0 )
      end
      
      if DATA.extstate.CONF_addlinkrenameflags > 0 then
        local param_name = ({ TrackFX_GetParamName( tr,  fxnumber, paramnumber, '' )})[2]
        local cur_name = DATA2.masterJSFX_sliders[sel_knob].name
        if DATA.extstate.CONF_addlinkrenameflags&1==1 or (DATA.extstate.CONF_addlinkrenameflags&2==2 and cur_name:match('Macro%s%d+')) then
          DATA2.masterJSFX_sliders[sel_knob].name = param_name
          DATA2:MasterJSFX_WriteSliders(sel_knob)
        end
      end
      
      
    -- store to extstate
      local slave_trGUID = reaper.GetTrackGUID( tr )
      local slave_fxGUID = reaper.TrackFX_GetFXGUID( tr, fxnumber )
      if not DATA2.links_extstate then DATA2.links_extstate = {} end
      DATA2.links_extstate[#DATA2.links_extstate+1] = 
        { macroID = sel_knob,
          slave_trGUID = slave_trGUID,
          slave_fxGUID = slave_fxGUID,
          slave_paramnumber = paramnumber,
        }
      DATA2:Link_Extstate_Set()
  end
  ----------------------------------------------------------------------------------
  function DATA2:Link_Extstate_Set()
    local s = ''
    for i =1, #DATA2.links_extstate do s = s..'MACROLINK '..DATA2.links_extstate[i].macroID..' '..DATA2.links_extstate[i].slave_trGUID..' '..DATA2.links_extstate[i].slave_fxGUID..' '..DATA2.links_extstate[i].slave_paramnumber..' "'..(DATA2.links_extstate[i].comment or '')..'"'..'|' end
    if DATA2.masterJSFX_tr then GetSetMediaTrackInfo_String( DATA2.masterJSFX_tr, 'P_EXT:MPLMAPPAN_MACROLINKEXTREF', s, true ) end
  end
  ----------------------------------------------------------------------------------
  function DATA2:Link_Extstate_Validate() 
    local slot_remove = {}
    for i = 1, #DATA2.links_extstate do
      local slave_trGUID = DATA2.links_extstate[i].slave_trGUID
      local slave_fxGUID = DATA2.links_extstate[i].slave_fxGUID
      local slave_paramnumber = DATA2.links_extstate[i].slave_paramnumber
      local tr = VF_GetTrackByGUID(slave_trGUID, DATA2.ReaProj)
      if not tr then slot_remove[i] = true goto nextslot end
      local ret, tr, fx = VF_GetFXByGUID(slave_fxGUID, tr, DATA2.ReaProj)
      if not fx then slot_remove[i] = true goto nextslot end
      local retval, active = reaper.TrackFX_GetNamedConfigParm( tr, fx, 'param.'..slave_paramnumber..'.plink.active' )
      if not (retval== true and tonumber(active) == 1) then slot_remove[i] = true goto nextslot end
      ::nextslot::
    end
    
    for i = #DATA2.links_extstate, 1 , -1 do if slot_remove[i] then table.remove(DATA2.links_extstate, i) end end
  end
  ----------------------------------------------------------------------------------
  function DATA2:Link_Extstate_Get()
    DATA2.links_extstate = {}
    
    -- define source track
      local extstate_tr = GetMasterTrack(DATA2.ReaProj) 
      if DATA.extstate.CONF_mode == 1 then 
        extstate_tr = GetSelectedTrack(DATA2.ReaProj,0) 
      end
      if not extstate_tr then return end
      
    local retval, chunk = GetSetMediaTrackInfo_String(  extstate_tr , 'P_EXT:MPLMAPPAN_MACROLINKEXTREF', '', false )
    for block in chunk:gmatch('[^|]+') do 
      local macroID, slave_trGUID, slave_fxGUID, slave_paramnumber, comment = block:match('MACROLINK%s(%d+)%s(%{.-%})%s(%{.-%})%s(%d+)%s%"(.-)%"')
      DATA2.links_extstate[#DATA2.links_extstate+1]=
        {
          macroID = tonumber(macroID),
          slave_trGUID = slave_trGUID,
          slave_fxGUID = slave_fxGUID,
          slave_paramnumber = tonumber(slave_paramnumber),
          comment = comment or "",
        }
    end
    
  end
  ----------------------------------------------------------------------------------
  function GUI_RESERVED_init(DATA)
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
      
    --DATA.GUI.default_scale = 2
      
    -- init main stuff
      local gfxw_min = DATA.GUI.default_scale * 640  if gfx.w < gfxw_min then gfx.w = gfxw_min end -- minimum w
      local gfxh_min = DATA.GUI.default_scale * 80  if gfx.h < gfxh_min then gfx.h = gfxh_min end -- minimum h
      DATA.GUI.custom_compactmode = 0 
      DATA.GUI.custom_gfxw = gfx.w/DATA.GUI.default_scale 
      if gfx.h/DATA.GUI.default_scale <  300   then DATA.GUI.custom_compactmode = 1 end
      if gfx.h/DATA.GUI.default_scale < 150   then DATA.GUI.custom_compactmode = 2 end
      if not DATA.GUI.custom_varlist then DATA.GUI.custom_varlist = 0 end
      
    -- mainbut definitions
      DATA.GUI.custom_offset = math.floor(5*DATA.GUI.default_scale)
      if DATA.GUI.custom_compactmode == 2 then DATA.GUI.custom_offset  =1 end
      DATA.GUI.custom_varlistw = math.floor(150*DATA.GUI.default_scale)
      if DATA.extstate.UI_showvarlist == 0 then DATA.GUI.custom_varlistw = 0 end
      DATA.GUI.custom_mainbutw = math.floor((gfx.w/DATA.GUI.default_scale- DATA.GUI.custom_offset-DATA.GUI.custom_varlistw)/9  - DATA.GUI.custom_offset)
      DATA.GUI.custom_mainbuth = math.floor(0.25*gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_offset)
      DATA.GUI.custom_mainbuttxtsz = 16
      if DATA.GUI.custom_compactmode > 0 then DATA.GUI.custom_mainbuth = math.floor(0.5*gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_offset) end
      DATA.GUI.custom_framea_1 = 0.8
      DATA.GUI.custom_framea_2 = 0.8
      
    -- knob
      DATA.GUI.custom_knobh = math.floor(0.25*gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_offset)
      if DATA.GUI.custom_compactmode > 0 then DATA.GUI.custom_knobh = math.floor(0.5*gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_offset) end
      DATA.GUI.custom_knobframea = 0.4
      DATA.GUI.custom_knobreadout_h = math.floor(DATA.GUI.custom_knobh * 0.2)
      DATA.GUI.custom_knobnametxtsz = math.min(math.max(math.floor(DATA.GUI.custom_knobreadout_h*0.7),14),17)
    -- graph
      DATA.GUI.custom_rectside = math.floor(10*DATA.GUI.default_scale)
    -- scroll
      DATA.GUI.custom_layer_scrollw = 12*DATA.GUI.default_scale
      DATA.GUI.custom_layer_scrollx = gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_offset - DATA.GUI.custom_layer_scrollw
      DATA.GUI.custom_layer_scrollh = gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_offset*3 - DATA.GUI.custom_knobh*2
      DATA.GUI.custom_layer_scrolly = gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_layer_scrollh- DATA.GUI.custom_offset
    
    -- link
      DATA.GUI.custom_linksegmw = DATA.GUI.custom_mainbutw
      DATA.GUI.custom_linkknobwratio = 0.85
      DATA.GUI.custom_linkknobw = math.floor(DATA.GUI.custom_linksegmw*DATA.GUI.custom_linkknobwratio)
      DATA.GUI.custom_linkh = 60*DATA.GUI.default_scale
      DATA.GUI.custom_linky = math.floor(DATA.GUI.custom_mainbuth*2) + DATA.GUI.custom_offset *2
      DATA.GUI.custom_linkh_frame = gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_linky
      DATA.GUI.custom_linknamew = 3*DATA.GUI.custom_linksegmw+DATA.GUI.custom_offset*2
      DATA.GUI.custom_linknameh = math.floor(DATA.GUI.custom_linkh/4)
      DATA.GUI.custom_linkfxw = math.floor(1.5*DATA.GUI.custom_mainbutw)
      DATA.GUI.custom_linkparamw = math.floor(1.5*DATA.GUI.custom_mainbutw)
      DATA.GUI.custom_linktxtsz = math.floor(DATA.GUI.custom_linknameh)
      
    -- buttons
      DATA.GUI.buttons = {} 
      GUI_MainButtons(DATA)
      GUI_RESERVED_initstuff(DATA)
    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end
  ----------------------------------------------------------------------------- 
  function GUI_RESERVED_draw_data(DATA, b)
    if b.data and b.data.isknoblimits == true then GUI_RESERVED_draw_data_knoblimits(DATA, b) end
    if b.data and b.data.limitsgraph then GUI_RESERVED_draw_data_graph(DATA, b) end
  end
  ----------------------------------------------------------------------------- 
  function GUI_RESERVED_draw_data_graph(DATA, b)
    local hext = b.data.limitsgraph
    local knobID = hext.knob
    local val_src = DATA2.masterJSFX_sliders[knobID].val
    local x,y,w,h =b.x,b.y,b.w,b.h
    
    local hexarray_lim_min = hext.hexarray_lim_min
    local hexarray_lim_max = 1-hext.hexarray_lim_max
    local hexarray_scale_min = hext.hexarray_scale_min
    local hexarray_scale_max = 1-hext.hexarray_scale_max
    local flags_tension = hext.flags_tension
    local flags_mute = hext.flags_mute
    local Slave_param = hext.destfx_param
    local y_glass_low = y+h
      
    local pow_float = 1
    flags_tension = math.floor(flags_tension*15)
    local  tens_mapt = {1, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 2, 3, 4, 5, 6, 7, 8, 10}
    if tens_mapt[flags_tension+1] then pow_float = tens_mapt[flags_tension+1]  end
    local slope 
    if hexarray_lim_max == hexarray_lim_min then slope = 0 else slope = (hexarray_scale_max - hexarray_scale_min) / (hexarray_lim_max-hexarray_lim_min)end
   
    gfx.a = 0.15
      for i_x = x, x+w do
        local val
        local progr_x = lim((i_x-x) / w)
        if progr_x < hexarray_lim_min then 
          val = hexarray_scale_min 
         elseif progr_x > hexarray_lim_max then 
          val = hexarray_scale_max 
         else
          val = hexarray_scale_min +  ((  (progr_x-hexarray_lim_min)/(hexarray_lim_max - hexarray_lim_min)  )^pow_float)*(hexarray_scale_max - hexarray_scale_min)
        end 
        gfx.line(i_x, y_glass_low, i_x, math.ceil(y_glass_low - val*h))--obj.glass_h
      end 
    
    local circ_x = math.floor(x+w*val_src)
    local circ_y = math.floor(y_glass_low - h*Slave_param-2 )+2--obj.glass_h
    local r = 2
    gfx.a = 0.4
    gfx.circle(circ_x,circ_y, r, 1)
    --gfx.line(circ_x+math.floor(r/2)-1, circ_y-2*r, circ_x+math.floor(r/2)-1, circ_y+2*r)
    --gfx.line(circ_x-r*3, circ_y, circ_x+r*3, circ_y)
    
  end
  ----------------------------------------------------------------------------- 
  function GUI_RESERVED_draw_data_knoblimits(DATA, b)
    local t = b.data.t
    local x,y,w,h,val =b.x,b.y,b.w,b.h, b.val
    --[[local knob_col,knob_a, knob_arca = 
                            b.knob_col or DATA.GUI.default_knob_col,
                            b.knob_a or DATA.GUI.default_knob_a,
                            b.knob_arca or DATA.GUI.default_knob_arca]]
    x,y,w,h = --scale
              x*DATA.GUI.default_scale,
              y*DATA.GUI.default_scale,
              w*DATA.GUI.default_scale,
              h*DATA.GUI.default_scale
    local knob_minside = b.knob_minside
    local x_shift = w/2
    local thickness = 1
    local y = y + b.knob_minside * 0.08
    DATA:GUIhex2rgb(knob_col, true)
    
    local ang_lim = 120
    local ang_gr = 120
    
    -- source val range   
      local arc_rsrc = math.floor(b.knob_arcR*(1/DATA.GUI.custom_linkknobwratio))
      local knob_val1 = t.hexarray_lim_min
      local knob_val2 = 1-t.hexarray_lim_max
      local knob_val0 if knob_val2<knob_val1 then knob_val0 = knob_val2 knob_val2 =knob_val1 knob_val1 = knob_val0 end -- prevent arc from ccw direction
      
      local ang_val = math.rad(-ang_gr+ang_gr*2*knob_val2)
      local ang = math.rad(ang_gr) 
      local knobvalmin_deg = -ang_lim + ang_lim*knob_val1*2
      local knobvalmax_deg = ang_lim - ang_lim*(1-knob_val2)*2
      gfx.a = 0.3
      for i = 0, thickness, 0.5 do DATA:GUIdraw_arc(math.floor(x+x_shift),math.floor(y+h/2),arc_rsrc-i, knobvalmin_deg, knobvalmax_deg, ang_lim) end 
    
    -- macro val
      local cur_macro = DATA2:GetSelectedKnob()
      local cur_macro_val = DATA2.masterJSFX_sliders[cur_macro].val or 0
      cur_macro_val = VF_lim(cur_macro_val, t.hexarray_lim_min,1-t.hexarray_lim_max)
      local knobval_deg = ang_lim - ang_lim*cur_macro_val*2
      local xpoint = math.floor(x+x_shift - arc_rsrc * math.sin(math.pi * 2 * knobval_deg / 360));
      local ypoint = math.floor(y+h/2 - arc_rsrc * math.cos(math.pi * 2 * knobval_deg / 360))+2
      gfx.a = 1
      gfx.circle(xpoint,ypoint, 2, 1)
      
    -- dest val range  
      local arc_rdest = math.floor(arc_rsrc*0.75)
      local knob_val1 = t.hexarray_scale_min
      local knob_val2 = 1-t.hexarray_scale_max
      local ang_val = math.rad(-ang_gr+ang_gr*2*knob_val2)
      local ang = math.rad(ang_gr)
      local knobvalmin_deg = math.floor(-ang_lim + ang_lim*knob_val1*2)
      local knobvalmax_deg = math.floor(ang_lim - ang_lim*(1-knob_val2)*2)
      gfx.a = 0.3
      for i = 0, thickness, 0.5 do DATA:GUIdraw_arc(math.floor(x+x_shift),math.floor(y+h/2),arc_rdest-i, knobvalmin_deg, knobvalmax_deg, ang_lim) end       
      
    -- slave val
      local cur_macro_val = t.slave_jsfx_param 
      cur_macro_val = VF_lim(cur_macro_val, t.hexarray_scale_min,1-t.hexarray_scale_max)
      local knobval_deg = ang_lim - ang_lim*cur_macro_val*2
      local xpoint = math.floor(x+x_shift - arc_rdest * math.sin(math.pi * 2 * knobval_deg / 360));
      local ypoint = math.floor(y+h/2 - arc_rdest * math.cos(math.pi * 2 * knobval_deg / 360))+2
      gfx.a = 1
      gfx.circle(xpoint,ypoint, 2, 1)
    
  end
  ----------------------------------------------------------------------------------
  function GUI_RESERVED_initstuff(DATA)
    if not DATA.GUI.Settings_open then DATA.GUI.Settings_open = 0  end
    if DATA.GUI.Settings_open ==0 then  
      if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 0 
      for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end  
      GUI_Macro_MainLoop(DATA) 
      GUI_Links(DATA) 
      GUI_Varlist(DATA) 
     elseif DATA.GUI.Settings_open and DATA.GUI.Settings_open == 1 then  
      if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 1
      for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
      DATA.GUI.buttons.Rsettings = { x=DATA.GUI.custom_mainbutw+DATA.GUI.custom_offset*2,
                               y=0,
                               w=gfx.w/DATA.GUI.default_scale-(DATA.GUI.custom_mainbutw+DATA.GUI.custom_offset*2),
                               h=gfx.h/DATA.GUI.default_scale,
                               txt = 'Settings',
                               --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                               frame_a = 0,
                               offsetframe = DATA.GUI.custom_offset,
                               offsetframe_a = 0.1,
                               ignoremouse = true,
                               refresh = true,
                               }
      DATA:GUIBuildSettings()  
      DATA.UPD.onGUIinit = true
    end
  end
  ----------------------------------------------------------------------------------
  function GUI_Varlist(DATA) 
    for key in pairs(DATA.GUI.buttons) do if key:match('varlist_') then DATA.GUI.buttons[key] = nil end end -- clear all stuff
    if DATA.extstate.UI_showvarlist == 0 then return end
    if not DATA2.masterJSFX_variations_list then return end
    -- frame
    local b_key = 'varlist_'
    local framex = DATA.GUI.custom_mainbutw+DATA.GUI.custom_offset*2
    local framey = DATA.GUI.custom_offset
    local framew = DATA.GUI.custom_varlistw-DATA.GUI.custom_offset
    local frameh = DATA.GUI.custom_mainbuth*2
    
    local itemh = (frameh/8)
    local getsetw = math.floor(framew*0.4)
    local getw = math.floor(getsetw/2)
    local namew = framew - getsetw
    
    DATA.GUI.buttons[b_key..'_frame'] = { x=framex ,
                        y=framey ,
                        w=framew,
                        h=frameh,
                        --hide=true,
                        ignoremouse=true,
                        frame_a= 0.3,
                        }
                        
    for varID = 1, 8 do
      -- refresh color
      local back_col = "#333333"
      local back_fill = 1 
      local frame_a = back_fill
      if DATA2.masterJSFX_variations_list[varID] and DATA2.masterJSFX_variations_list[varID].issel==1 then 
        back_col = '#FFFFFF'
        back_fill = 0.1
        frame_a = 0
      end 
      
      local yoffs = framey+ itemh*(varID-1)
      DATA.GUI.buttons[b_key..'_varID'..varID..'get'] = { x= framex,
                          y=math.floor(yoffs),
                          w=getw,
                          h=itemh-1,
                          txt = 'rec',
                          backgr_col=back_col,
                          backgr_fill=back_fill,
                          frame_a = 0,
                          onmouserelease = function()
                            for i = 1, 16 do DATA2.masterJSFX_variations_list[varID].macrolist[i] = DATA2.masterJSFX_sliders[i].val end -- print current values to variation
                            DATA2:MasterJSFX_WriteSliders()
                          end
                          } 
      local name = ''
      if DATA2.masterJSFX_variations_list[varID] and DATA2.masterJSFX_variations_list[varID].name then name = DATA2.masterJSFX_variations_list[varID].name end
      DATA.GUI.buttons[b_key..'_varID'..varID..'name'] = { x= framex+getw,
                          y=math.floor(yoffs),
                          w=namew,
                          h=itemh-1,
                          backgr_col=back_col,
                          backgr_fill=back_fill,
                          txt = name,
                          frame_a = 0,
                          onmouserelease = function()
                            for i = 1, 8 do DATA2.masterJSFX_variations_list[i].issel = 0 if varID == i then DATA2.masterJSFX_variations_list[i].issel = 1 end end -- set selected
                            DATA2:MasterJSFX_WriteSliders()
                          end,
                          onmousereleaseR = function()
                             GUI_ContextMenu_Variation(varID)
                          end
                          }
      DATA.GUI.buttons[b_key..'_varID'..varID..'set'] = { x= framex+getw+namew,
                          y=math.floor(yoffs),
                          w=getw,
                          h=itemh-1,
                          backgr_col=back_col,
                          backgr_fill=back_fill,
                          frame_a = 0,
                          txt = '>',
                          onmouserelease = function()
                            for i = 1, 8 do DATA2.masterJSFX_variations_list[i].issel = 0 if varID == i then DATA2.masterJSFX_variations_list[i].issel = 1 end end -- set selected
                            for i = 1, 16 do 
                              if DATA2.masterJSFX_sliders[i].flags&2~=2 then -- exclude from var flag
                                DATA2.masterJSFX_sliders[i].val = DATA2.masterJSFX_variations_list[varID].macrolist[i] 
                              end
                            end -- set macro values
                            DATA2:MasterJSFX_WriteSliders()
                          end
                          }                          
    end
    
  end
  -------------------------------------------------------------------------------  
  function GUI_Macro_MainLoop(DATA) 
    for key in pairs(DATA.GUI.buttons) do if key:match('macro_') then DATA.GUI.buttons[key] = nil end end -- clear all stuff
    --if not DATA2.masterJSFX_isvalid or (DATA2.masterJSFX_isvalid and DATA2.masterJSFX_isvalid == false)then return end
    -- build macros
    for i = 1, 16 do
      local x = math.floor((DATA.GUI.custom_mainbutw+DATA.GUI.custom_offset)*(1+(i-1)%8)+DATA.GUI.custom_offset)
      local t = {
        x=x+DATA.GUI.custom_varlistw,
        y=DATA.GUI.custom_offset + DATA.GUI.custom_knobh * math.modf(i/9),
        w=DATA.GUI.custom_mainbutw,
        h=DATA.GUI.custom_knobh-DATA.GUI.custom_offset * (1-math.modf(i/9)),
        id=i
      }
      GUI_Macro(DATA,t) 
    end
                                          
  end
  -------------------------------------------------------------------------------- 
  function GUI_Links_Control(DATA) 
    for key in pairs(DATA.GUI.buttons) do if key:match('macrolinks_') then DATA.GUI.buttons[key] = nil end end -- clear all stuff
    if DATA.GUI.custom_compactmode > 0 then return end
    
    local maxcntslotsperframe=math.floor(DATA.GUI.custom_linkh_frame / DATA.GUI.custom_linkh) -1
    
    local y_offset_max = DATA.GUI.custom_linkh*(#DATA2.slaveJSFXlinks-maxcntslotsperframe) -- DATA.GUI.custom_linkh_frame  --DATA.GUI.custom_linkh
    if #DATA2.slaveJSFXlinks * DATA.GUI.custom_linkh < DATA.GUI.custom_linkh_frame then y_offset_max =  0 end
    local selectedknob = DATA2:GetSelectedKnob()
    local y_offset_scroll = DATA2.masterJSFX_sliders[selectedknob].scroll * y_offset_max
    --y_offset_scroll = (math.floor( y_offset_scroll /DATA.GUI.custom_linkh  ))*DATA.GUI.custom_linkh -- quantize scroll
    
    for link = 1, #DATA2.slaveJSFXlinks do 
      local y = DATA.GUI.custom_linky+(link-1)*DATA.GUI.custom_linkh-y_offset_scroll
      local t = {
        data = DATA2.slaveJSFXlinks[link],
        id = link,
        x = DATA.GUI.custom_offset,--DATA.GUI.custom_mainbutw + 
        y=y,
        w=DATA.GUI.custom_gfxw-DATA.GUI.custom_offset*4-DATA.GUI.custom_layer_scrollw,-- - DATA.GUI.custom_mainbutw
        h=DATA.GUI.custom_linkh, 
        hide = y < DATA.GUI.custom_linky,
      }
      GUI_Links_Control_Params(DATA,t) 
    end 
    GUI_Upd_Links(DATA)
  end
  -------------------------------------------------------------------------------- 
  function GUI_Upd_Links(DATA)
    for link = 1, #DATA2.slaveJSFXlinks do 
      local t = {data = DATA2.slaveJSFXlinks[link],
                 id = link,
                }
                
        -- param val
        local b_key = 'macrolinks_'..t.id
        local val = t.data.destfx_param 
        local paramformat = t.data.destfx_paramformatted 
        if not DATA.GUI.buttons[b_key..'_knob'] then goto skipnextlink end
        
        DATA.GUI.buttons[b_key..'_knob'].val = val
        DATA.GUI.buttons[b_key..'_paramformat'].txt = '  '..paramformat
        
        -- hex
        
        if DATA.extstate.UI_showgraph == 0 then 
          --local val = 1-t.data.hexarray_lim_max
          DATA.GUI.buttons[b_key..'limmax'].txt = 'src max'--'SrcMax:'..GUIf_NormToPercent(val) 
          --local val = t.data.hexarray_lim_min
          DATA.GUI.buttons[b_key..'limmin'].txt = 'src min'--'SrcMin:'..GUIf_NormToPercent(val) 
          --local val = 1-t.data.hexarray_scale_max
          DATA.GUI.buttons[b_key..'scalemax'].txt = 'dest max'--''DestMax:'..GUIf_NormToPercent(val) 
          --local val = t.data.hexarray_scale_min
          DATA.GUI.buttons[b_key..'scalemin'].txt = 'dest min'--'DestMin:'..GUIf_NormToPercent(val) 
          --local val = t.data.flags_tension
        end
        if DATA.extstate.CONF_mode == 0 then 
          DATA.GUI.buttons[b_key..'tension'].txt = 'tension'
          DATA.GUI.buttons[b_key..'mute'].txt = '[mute]'
        end
        
        DATA.GUI.buttons[b_key..'_knob']. txt = '^'
        if t.data.flags_mute == 1 then DATA.GUI.buttons[b_key..'_knob'].txt = ''end
      ::skipnextlink::
    end
  end
  -------------------------------------------------------------------------------- 
  function GUI_Links_Control_Params_01names(DATA,t)
    -- frame
    --track - fx - param - graph - scale - mute - remove
    local b_key = 'macrolinks_'..t.id
    local frame_a=0
    local frame_asel=0.3
    local txt_flags=4
    local xoffs = 0
    -- frame
    DATA.GUI.buttons[b_key..'_frame'] = { x= t.x,
                        y=t.y ,
                        w=t.w,
                        h=t.h,
                        --hide=true,
                        ignoremouse=true,
                        frame_a= 0.2,
                        }
    ----------------- NAMES -----------------
    -- track
    local trname = '['..t.id..'] '..t.data.slave_jsfx_trname
    DATA.GUI.buttons[b_key..'_tracks'] = { x=t.x,
                        y=t.y ,
                        w=DATA.GUI.custom_linknamew,
                        h=DATA.GUI.custom_linknameh-1,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt = trname,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = txt_flags,
                        ignoremouse = true,
                        onmouserelease = function() --DATA2:Link_FloatFX(t.data) 
                                          end,
                        }    
    -- fx
    local fxname = t.data.destfx_FXname_full
    DATA.GUI.buttons[b_key..'_fx'] = {x=t.x,
                        y=t.y+DATA.GUI.custom_linknameh ,
                        w=DATA.GUI.custom_linknamew,
                        h=DATA.GUI.custom_linknameh-1,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt = '  '..fxname,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = txt_flags,
                        onmouserelease = function() DATA2:Link_FloatFX(t.data) end,
                        onmousereleaseR = function() GUI_ContextMenu_FXName(t.data)
                                          end,
                                          
                        }  
                        
    -- param
    local paramname = t.data.destfx_paramname
    DATA.GUI.buttons[b_key..'_param'] = { x=t.x,
                        y=t.y+DATA.GUI.custom_linknameh*2 ,
                        w=DATA.GUI.custom_linknamew,
                        h=DATA.GUI.custom_linknameh-1,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt = '  '..paramname,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = txt_flags,
                        onmousereleaseR = function() GUI_ContextMenu_ParamName(t.data)
                                          end,
                        } 
    -- param val
    DATA.GUI.buttons[b_key..'_paramformat'] = { x=t.x,
                        y=t.y+DATA.GUI.custom_linknameh*3 ,
                        w=DATA.GUI.custom_linknamew,
                        h=DATA.GUI.custom_linknameh-1,
                        frame_a=frame_a,
                        frame_asel=frame_asel, 
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = txt_flags,
                        ignoremouse = true,
                        onmouserelease = function() --DATA2:Link_FloatFX(t.data) 
                                          end,
                        } 
  end
  -------------------------------------------------------------------------------- 
  function GUI_Links_Control_Params_03hexvalues(DATA,t)
    if DATA.extstate.CONF_mode == 1 then return end
    GUI_Links_Control_Params_03hexvalues_ViewA(DATA,t)
    GUI_Links_Control_Params_03hexvalues_ViewB(DATA,t)
  end
    -------------------------------------------------------------------------------- 
  function GUI_Links_Control_Params_03hexvalues_ViewB(DATA,t)  
    if DATA.extstate.UI_showgraph == 0 then return end
    
    local b_key = 'macrolinks_'..t.id
    local frame_a=0.1
    local frame_asel=0.1
    local hexoffsx = t.x+DATA.GUI.custom_linknamew+DATA.GUI.custom_offset--+DATA.GUI.custom_linksegmw
    local hextxt_flags = 1
    local txt_a = 0.6
    local val_res= 0.1
    local val_res= 0.15
    local backgr_col2 = '#FFFFFF'
    local backgr_fill2 = 0
    
    local areax,areay,areaw,areah = 
          hexoffsx,
          t.y+1,
          DATA.GUI.custom_linksegmw*2+DATA.GUI.custom_offset,
          t.h-2
    -- area
    DATA.GUI.buttons[b_key..'graph'] = { 
      x=areax,
      y=areay,
      w=areaw,
      h=areah,
      frame_a=frame_a,
      frame_asel=frame_asel,
      ignoremouse = true,
      data = {limitsgraph=t.data},
    }
    -- points
    -- areduce area
    local areax,areay,areaw,areah = areax+DATA.GUI.custom_rectside /2,areay+DATA.GUI.custom_rectside /2,areaw-DATA.GUI.custom_rectside,areah-DATA.GUI.custom_rectside
          
    hext = t.data
    local hexarray_lim_min = hext.hexarray_lim_min
    local hexarray_lim_max = hext.hexarray_lim_max
    local hexarray_scale_min = hext.hexarray_scale_min
    local hexarray_scale_max = hext.hexarray_scale_max
    local glass_y = areay
    local p1_x = areax-math.floor(DATA.GUI.custom_rectside /2) + areaw* hexarray_lim_min
    local p1_y = glass_y-math.floor(DATA.GUI.custom_rectside /2) + areah*(1-hexarray_scale_min)
    DATA.GUI.buttons[b_key..'graph_P1'] = { 
                      x = p1_x,
                      y = p1_y,
                      w = DATA.GUI.custom_rectside,
                      h = DATA.GUI.custom_rectside,
                      
    onmouseclick =function () DATA.mouselatch_t = { x = DATA.GUI.buttons[b_key..'graph_P1'].x, xval = hexarray_lim_min, y = DATA.GUI.buttons[b_key..'graph_P1'].y, yval = hexarray_scale_min} end,
    onmouserelease = function()  DATA.mouselatch_t = nil DATA.ondraganything = nil  end,
    onmousedrag = 
      function()
        if not DATA.GUI.mouse_ismoving then return end
        if not DATA.mouselatch_t then return end
        DATA.ondraganything=true
        local latch = DATA.mouselatch_t
        local mult = 1 if DATA.GUI.Ctrl == true then mult = 0.01 end
        local out_val1 = lim(latch.xval + mult*DATA.GUI.dx/areaw)
        local out_val2 = lim(latch.yval - mult*DATA.GUI.dy/areah)
        if out_val1 >= 1- hexarray_lim_max then out_val1 = 1- hexarray_lim_max-0.01 end
        DATA.GUI.buttons[b_key..'graph_P1'].x = areax -math.floor(DATA.GUI.custom_rectside/2)+ areaw* out_val1
        DATA.GUI.buttons[b_key..'graph_P1'].y = glass_y -math.floor(DATA.GUI.custom_rectside/2)+ areah *(1-out_val2)
        
        t.data.hexarray_lim_min = out_val1
        t.data.hexarray_scale_min = out_val2
        DATA2:SlaveJSFX_Write(t.data)
        DATA2:SlaveJSFX_UpdateParameters() 
        GUI_Upd_Links(DATA,t)
        GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob()) 
      end,
    onmouseclickR = function()
      local retval, retvals_csv = GetUserInputs( DATA.extstate.mb_title, 2, 'X1,Y1,extrawidth=100', hexarray_lim_min..','..hexarray_scale_min )
      if not retval or (retvals_csv and retvals_csv == '')then return end
      local out = {}
      for val in retvals_csv:gmatch('[^%,]+') do if tonumber(val) then out[#out+1] = lim(tonumber(val)) end end
      if #out ~= 2 then return end
      t.data.hexarray_lim_min = out[1]
      t.data.hexarray_scale_min = out[2]
      DATA2:SlaveJSFX_Write(t.data)
      DATA2:SlaveJSFX_UpdateParameters() 
      GUI_Upd_Links(DATA,t)
      GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob())      
    end,                     
                    }
    

    local p2_x = areax-math.floor(DATA.GUI.custom_rectside/2) + areaw*  (1-hext.hexarray_lim_max)
    local p2_y = glass_y-math.floor(DATA.GUI.custom_rectside/2) + areah *hext.hexarray_scale_max
    DATA.GUI.buttons[b_key..'graph_P2'] = {
      x = p2_x,
      y = p2_y,
      w = DATA.GUI.custom_rectside,
      h = DATA.GUI.custom_rectside,
      onmouseclick =function () DATA.mouselatch_t = { x = DATA.GUI.buttons[b_key..'graph_P2'].x, xval = hexarray_lim_max, y = DATA.GUI.buttons[b_key..'graph_P2'].y, yval = hexarray_scale_max} end,
      onmouserelease = function()  DATA.mouselatch_t = nil DATA.ondraganything = nil  end,
      onmousedrag = 
        function()
          if not DATA.GUI.mouse_ismoving then return end
          if not DATA.mouselatch_t then return end
          DATA.ondraganything=true
          local latch = DATA.mouselatch_t
          local mult = 1 if DATA.GUI.Ctrl == true then mult = 0.01 end
          local out_val1 = lim(latch.xval - mult*DATA.GUI.dx/areaw)
          local out_val2 = lim(latch.yval + mult*DATA.GUI.dy/areah)
          if (1-out_val1)<= hexarray_lim_min then out_val1 = 1- hexarray_lim_min-0.01 end 
          DATA.GUI.buttons[b_key..'graph_P2'].x= areax-math.floor(DATA.GUI.custom_rectside/2) + areaw*  (1-out_val1)
          DATA.GUI.buttons[b_key..'graph_P2'].y  = glass_y-math.floor(DATA.GUI.custom_rectside/2) + areah *out_val2 
          t.data.hexarray_lim_max = out_val1
          t.data.hexarray_scale_max = out_val2
          DATA2:SlaveJSFX_Write(t.data)
          DATA2:SlaveJSFX_UpdateParameters() 
          GUI_Upd_Links(DATA,t)
          GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob()) 
        end,
    onmouseclickR = function()
      local retval, retvals_csv = GetUserInputs( DATA.extstate.mb_title, 2, 'X2,Y2,extrawidth=100', hexarray_lim_max..','..hexarray_scale_max )
      if not retval or (retvals_csv and retvals_csv == '')then return end
      local out = {}
      for val in retvals_csv:gmatch('[^%,]+') do if tonumber(val) then out[#out+1] = lim(tonumber(val)) end end
      if #out ~= 2 then return end
      t.data.hexarray_lim_max = out[1]
      t.data.hexarray_scale_max = out[2]
      DATA2:SlaveJSFX_Write(t.data)
      DATA2:SlaveJSFX_UpdateParameters() 
      GUI_Upd_Links(DATA,t)
      GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob())      
    end, }               
  end
    -------------------------------------------------------------------------------- 
  function GUI_Links_Control_Params_03hexvalues_ViewA(DATA,t)
    if DATA.extstate.UI_showgraph == 1 then return end
    
    local b_key = 'macrolinks_'..t.id
    local frame_a=0
    local frame_asel=0.1
    -------------------- HEX -----------------
    local hexoffsx = t.x+DATA.GUI.custom_linknamew+DATA.GUI.custom_offset*2+DATA.GUI.custom_linksegmw
    local hextxt_flags = 1
    local txt_a = 0.6
    local val_res= 0.3
    local backgr_col2 = '#FFFFFF'
    local backgr_fill2 = 0.2
    -- limmax
    local val = 1-t.data.hexarray_lim_max
      DATA.GUI.buttons[b_key..'limmax'] = { x=hexoffsx,
                          y=t.y ,
                          w=DATA.GUI.custom_linksegmw,
                          h=DATA.GUI.custom_linknameh-1,
                          val = val,
                          val_res=-val_res,
                          val_max=1,
                          val_min=t.data.hexarray_lim_min,
                          val_xaxis = true,
                          backgr_fill2 = backgr_fill2,
                          backgr_col2 = backgr_col2,
                          backgr_usevalue = true,
                          frame_a=frame_a,
                          frame_asel=frame_asel,
                          txt_fontsz = DATA.GUI.custom_linktxtsz,
                          txt_flags = hextxt_flags,
                          txt_a = txt_a,
                          onmousedrag = function()
                                          if not DATA.GUI.mouse_ismoving then return end
                                          DATA.ondraganything=true
                                          t.data.hexarray_lim_max = 1-DATA.GUI.buttons[b_key..'limmax'].val
                                          DATA2:SlaveJSFX_Write(t.data)
                                          DATA2:SlaveJSFX_UpdateParameters() 
                                          GUI_Upd_Links(DATA,t)
                                          GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob()) 
                                        end,
                          onmouserelease = function() DATA.ondraganything = nil end,
                          }  
    -- limmin
    local val = t.data.hexarray_lim_min
    DATA.GUI.buttons[b_key..'limmin'] = { x=hexoffsx,
                        y=t.y+DATA.GUI.custom_linknameh ,
                        w=DATA.GUI.custom_linksegmw,
                        h=DATA.GUI.custom_linknameh-1,
                        val = val,
                        val_res=-val_res,
                        val_xaxis = true,
                        backgr_fill2 = backgr_fill2,
                        backgr_col2 = backgr_col2,
                        backgr_usevalue = true,
                        val_max=1-t.data.hexarray_lim_max,
                        val_min=0,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = hextxt_flags,
                        txt_a = txt_a,
                        onmousedrag = function()
                                        if not DATA.GUI.mouse_ismoving then return end
                                        DATA.ondraganything=true
                                        t.data.hexarray_lim_min = DATA.GUI.buttons[b_key..'limmin'].val
                                        DATA2:SlaveJSFX_Write(t.data)
                                        DATA2:SlaveJSFX_UpdateParameters() 
                                        GUI_Upd_Links(DATA,t)
                                        GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob()) 
                                      end,
                        onmouserelease = function() DATA.ondraganything = nil end,
                        }    
    -- scalemax
    local val = 1-t.data.hexarray_scale_max
    DATA.GUI.buttons[b_key..'scalemax'] = { x=hexoffsx,
                        y=t.y +DATA.GUI.custom_linknameh*2,
                        w=DATA.GUI.custom_linksegmw,
                        h=DATA.GUI.custom_linknameh-1,
                        val = val,
                        val_res=-val_res,
                        val_xaxis = true,
                        val_max=1,
                        val_min=0,--t.data.hexarray_scale_min,
                        backgr_fill2 = backgr_fill2,
                        backgr_col2 = backgr_col2,
                        backgr_usevalue = true,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = hextxt_flags,
                        txt_a = txt_a,
                        onmousedrag = function()
                                        if not DATA.GUI.mouse_ismoving then return end
                                        DATA.ondraganything=true
                                        t.data.hexarray_scale_max = 1-DATA.GUI.buttons[b_key..'scalemax'].val
                                        DATA2:SlaveJSFX_Write(t.data)
                                        DATA2:SlaveJSFX_UpdateParameters() 
                                        GUI_Upd_Links(DATA,t)
                                        GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob()) 
                                      end,
                        onmouserelease = function() DATA.ondraganything = nil end,
                        }  
    -- scalemax
    local val = t.data.hexarray_scale_min
    DATA.GUI.buttons[b_key..'scalemin'] = { x=hexoffsx,
                        y=t.y+DATA.GUI.custom_linknameh*3 ,
                        w=DATA.GUI.custom_linksegmw,
                        h=DATA.GUI.custom_linknameh-1,
                        val = val,
                        val_res=-val_res,
                        val_max=1,--t.data.hexarray_scale_max,
                        val_min=0,
                        val_xaxis = true,
                        backgr_fill2 = backgr_fill2,
                        backgr_col2 = backgr_col2,
                        backgr_usevalue = true,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = hextxt_flags,
                        txt_a = txt_a,
                        onmousedrag = function()
                                        if not DATA.GUI.mouse_ismoving then return end
                                        DATA.ondraganything=true
                                        t.data.hexarray_scale_min = DATA.GUI.buttons[b_key..'scalemin'].val
                                        DATA2:SlaveJSFX_Write(t.data)
                                        DATA2:SlaveJSFX_UpdateParameters() 
                                        GUI_Upd_Links(DATA,t)
                                        GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob()) 
                                      end,
                        onmouserelease = function() DATA.ondraganything = nil end,
                        } 
  end
    --------------------------------------------------------------------------------
  function GUI_Links_Control_Params_04hexflags(DATA,t)   
    local b_key = 'macrolinks_'..t.id
    local frame_a=0
    local frame_asel=0.1
    local hexoffsx = t.x+DATA.GUI.custom_linknamew+DATA.GUI.custom_offset*3+DATA.GUI.custom_linksegmw*2
    local hextxt_flags = 1
    local txt_a = 0.6
    local val_res= 0.1
    local val_res= 0.15
    local backgr_col2 = '#FFFFFF'
    local backgr_fill2 = 0.2
    if DATA.extstate.CONF_mode == 0 then 
    -- tension
    local val = t.data.flags_tension
    DATA.GUI.buttons[b_key..'tension'] = { x=hexoffsx,
                        y=t.y ,--+DATA.GUI.custom_linknameh*2,
                        w=DATA.GUI.custom_linksegmw,
                        h=DATA.GUI.custom_linknameh-1,
                        val = val,
                        val_res=-val_res,
                        val_xaxis = true,
                        backgr_fill2 = backgr_fill2,
                        backgr_col2 = backgr_col2,
                        backgr_usevalue = true,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = hextxt_flags,
                        txt_a = txt_a,
                        onmousedrag = function()
                                        if not DATA.GUI.mouse_ismoving then return end
                                        DATA.ondraganything=true
                                        t.data.flags_tension = DATA.GUI.buttons[b_key..'tension'].val
                                        DATA2:SlaveJSFX_Write(t.data)
                                        DATA2:SlaveJSFX_UpdateParameters() 
                                        GUI_Upd_Links(DATA,t)
                                        GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob()) 
                                      end,
                        onmouserelease = function() DATA.ondraganything = nil end,
                        }
    -- mute
    local val = t.data.flags_mute
    DATA.GUI.buttons[b_key..'mute'] = { x=hexoffsx,
                        y=t.y+DATA.GUI.custom_linknameh,
                        w=DATA.GUI.custom_linksegmw,
                        h=DATA.GUI.custom_linknameh-1,
                        backgr_fill2 = backgr_fill2,
                        backgr_col2 = backgr_col2,
                        backgr_usevalue = true,
                        val=val,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = hextxt_flags,
                        --txt_a = txt_a,
                        onmouserelease = function()
                                        t.data.flags_mute = t.data.flags_mute~1
                                        DATA.GUI.buttons[b_key..'mute'].val=t.data.flags_mute 
                                        DATA2:SlaveJSFX_Write(t.data)
                                        DATA2:SlaveJSFX_UpdateParameters() 
                                        GUI_Upd_Links(DATA,t)
                                        GUI_Upd_Macro(DATA,DATA2:GetSelectedKnob()) 
                                      end,
                        }
    end
    -- remove
    DATA.GUI.buttons[b_key..'remove'] = { x=hexoffsx,
                        y=t.y+DATA.GUI.custom_linknameh*2,
                        w=DATA.GUI.custom_linksegmw,
                        h=DATA.GUI.custom_linknameh-1,
                        backgr_fill2 = 0,
                        backgr_col2 = backgr_col2,
                        backgr_usevalue = true,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        txt_fontsz = DATA.GUI.custom_linktxtsz,
                        txt_flags = hextxt_flags,
                        --txt_a = txt_a,
                        txt = '[remove]',
                        onmouserelease = function()
                                        local ret = MB('Remove link?', DATA.extstate.mb_title, 4)
                                        if ret == 6 then 
                                          DATA2:Link_remove(t.data)
                                          DATA2:SlaveJSFX_Read() 
                                          GUI_Links(DATA) 
                                          DATA.UPD.onGUIinit = true
                                        end
                                      end,
                        }                        
                        
  end
  ----------------------------------------------------------------------------------
  function DATA2:Link_mapsame(t)  
    for i = 0, CountSelectedTracks(DATA2.ReaProj) do
      local tr = GetSelectedTrack(DATA2.ReaProj,i-1)
      if i==0 then tr = GetMasterTrack(DATA2.ReaProj) end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end 
        local fxGUID = reaper.TrackFX_GetFXGUID( tr, fx-1 )
        local fxname_full = ({ TrackFX_GetFXName( tr, fx-1, '' )})[2]
        if fxGUID ~= t.destfx_FXGUID and fxname_full == t.destfx_FXname_full then
          DATA2:Link_add(true, tr, fx-1, t.destfx_paramID)
        end
      end
    end
    
  end
  ----------------------------------------------------------------------------------
  function DATA2:Link_FloatFX(t)
    local tr = t.slave_jsfx_tr
    local fx = t.destfx_FXID
    local open = TrackFX_GetOpen( tr, fx )
    if open == true then TrackFX_Show( tr, fx, 2 ) else TrackFX_Show( tr, fx, 3 ) end
  end
  --------------------------------------------------------------------------------
  function DATA2:Link_remove(t)
    local tr = t.slave_jsfx_tr
    local fxnumber = t.destfx_FXID
    local paramnumber = t.destfx_paramID
    local parmname = 'param.'..paramnumber..'.plink.active'
    TrackFX_SetNamedConfigParm( tr, fxnumber, parmname, 0 ) 
    DATA2:Link_Extstate_Validate()
    DATA2:Link_Extstate_Set()
  end
  --------------------------------------------------------------------------------
  function GUI_Links_Control_Params_02knob(DATA,t)  
    local b_key = 'macrolinks_'..t.id
    local val = t.data.destfx_param
    local frame_a=0
    local frame_asel=0
    local val = t.data.slave_jsfx_param
    DATA.GUI.buttons[b_key..'_knob'] = { x=t.x+DATA.GUI.custom_linknamew+DATA.GUI.custom_offset+math.floor((DATA.GUI.custom_linksegmw-DATA.GUI.custom_linkknobw)/2),
                        y=t.y,
                        w=DATA.GUI.custom_linkknobw-1,
                        h=DATA.GUI.custom_linkh-1,
                        frame_a=frame_a,
                        frame_asel=frame_asel,
                        val = val,
                        val_res=val_res,
                        ignoremouse = (t.data.flags_mute == 0) or DATA.extstate.UI_showgraph == 1,
                        hide = DATA.extstate.UI_showgraph == 1,
                        back_sela = 0,
                        knob_isknob = true,
                        data={t = t.data, isknoblimits = true},
                        onmousedrag = function() 
                                        if not DATA.GUI.mouse_ismoving or t.data.flags_mute == 0 then return end
                                        DATA.ondraganything = true
                                        t.data.slave_jsfx_param = DATA.GUI.buttons[b_key..'_knob'].val
                                        DATA2:SlaveJSFX_Write(t.data)
                                        DATA2:SlaveJSFX_UpdateParameters() 
                                      end,
                        onmouserelease = function() DATA.ondraganything = nil end,
                        }  
  end
    --------------------------------------------------------------------------------
  function GUI_Links_Control_Params(DATA,t)    
    if t.hide == true then return end
    GUI_Links_Control_Params_01names(DATA,t) 
    GUI_Links_Control_Params_02knob(DATA,t)
    GUI_Links_Control_Params_03hexvalues(DATA,t) 
    GUI_Links_Control_Params_04hexflags(DATA,t)
  end
  -------------------------------------------------------------------------------- 
  function DATA2:GetSelectedKnob()
    local selectedknob = 1
    if not DATA2.masterJSFX_slselectionmask then DATA2.masterJSFX_slselectionmask = 1 end
    for i = 1, 16 do if DATA2.masterJSFX_slselectionmask&(1<<(i-1))==(1<<(i-1)) then selectedknob = i break end end
    return selectedknob
  end
  -------------------------------------------------------------------------------- 
  function GUI_Links_ScrollBar(DATA) 
    DATA.GUI.buttons.macro_scroll = {} -- reset
    if DATA.GUI.custom_compactmode > 0 then return end
    -- links scroll
    local selectedknob = DATA2:GetSelectedKnob()
    local initval = DATA2.masterJSFX_sliders[selectedknob].scroll
    DATA.GUI.buttons.macro_scroll = 
      { x=DATA.GUI.custom_layer_scrollx,
        y=DATA.GUI.custom_layer_scrolly,
        w=DATA.GUI.custom_layer_scrollw,
        h=DATA.GUI.custom_layer_scrollh,
        slider_isslider = true,
        ignoreboundarylimit = true,
        val =initval,
        val_res = -1,
        onmousedrag =  function() 
                          -- perform [update UI at drag then freeze if there aren`t any movements more than X seconds]
                            if not DATA.GUI.mouse_ismoving then
                              local freezetimer_sec = 0.5
                              if not DATA.ts_mousefreeze then DATA.ts_mousefreeze = os.clock() end
                              if os.clock() - DATA.ts_mousefreeze > freezetimer_sec then 
                                return
                              end
                             else
                              DATA.ts_mousefreeze = nil
                            end 
                            
                          local out = DATA.GUI.buttons.macro_scroll.val
                          DATA2.masterJSFX_sliders[selectedknob].scroll = out
                          DATA2:MasterJSFX_WriteSliders(selectedknob)
                          GUI_Links_Control(DATA) 
                        end,
        onmouserelease =  function() DATA.ts_mousefreeze = nil end,
                        } 
  end
  -------------------------------------------------------------------------------- 
  function GUI_Links(DATA)  
    if not DATA2.masterJSFX_isvalid or (DATA2.masterJSFX_isvalid and DATA2.masterJSFX_isvalid == false)then return end
    if DATA.GUI.custom_compactmode > 0 then return end
    GUI_Links_ScrollBar(DATA) 
    GUI_Links_Control(DATA) 
  end   
  
  -------------------------------------------------------------------------------
  function GUI_Upd_MacroSelection(DATA)
    -- refresh selection
    for knobid = 1, 16 do
      local cntlinks = 0
      for i = 1, #DATA2.links_extstate do if DATA2.links_extstate[i].macroID == knobid then cntlinks = cntlinks+ 1 end end
      local b_key = 'macro_'..knobid
      if DATA.GUI.buttons[b_key..'_frame'] then 
        local frame_a = 0.5
        local txt = '['..cntlinks..']'
        if cntlinks == 0 then  txt = '' end
        if DATA2.masterJSFX_slselectionmask&(1<<(knobid-1))==(1<<(knobid-1)) then
          frame_a = 0.8
          txt = 'v'
        end
        DATA.GUI.buttons[b_key..'_frame'].frame_a = frame_a
        DATA.GUI.buttons[b_key..'_frame'].frame_asel = frame_a
        if DATA.GUI.custom_compactmode ~= 2  then DATA.GUI.buttons[b_key..'_knob'].txt=txt end
      end
    end
  end
  ------------------------------------------------------------------------------- 
  function GUIf_NormToPercent(val)
    if not val then return end
    local perc = math.floor(val*100)--(math.floor(val*10000)/100)
    if perc%1==0.0 then perc = math.floor(perc) end -- clean up float to integer case 0.0% 100.0%
    return perc..'%'
  end
  ------------------------------------------------------------------------------- 
  function GUI_Upd_Macro(DATA,id0) 
    if not id0 then return end
    local i_st = 1
    local cnt=15
    if id0 then i_st = id0 cnt = 0 end
    for knobid = i_st, i_st+cnt do 
      local b_key = 'macro_'..knobid
      local val = DATA.GUI.buttons[b_key..'_frame'].val
      -- refresh data
      DATA2.masterJSFX_sliders[knobid].val = val 
      -- refresh value
      if DATA.GUI.buttons[b_key..'_val'] then 
        DATA.GUI.buttons[b_key..'_val'].txt = GUIf_NormToPercent(val) 
        --if DATA.ondraganything ~= true then DATA.GUI.buttons[b_key..'_val'].txt = 1 end
      end
      -- refresh knob
      DATA.GUI.buttons[b_key..'_knobarc'].val = val
      -- refresh name
      DATA.GUI.buttons[b_key..'_name'].txt = DATA2.masterJSFX_sliders[knobid].name 
      
      -- refresh color
      local back_col = "#333333"
      local back_fill = 1 
      local frame_a = back_fill
      if DATA2.masterJSFX_sliders[knobid].col then 
        back_col = DATA2.masterJSFX_sliders[knobid].col 
        back_fill = 1 
        frame_a = 0
      end 
      local frame_col = back_col
      if DATA.GUI.custom_compactmode == 2 then frame_a=1 frame_col = '#333333'end
      DATA.GUI.buttons[b_key..'_frame'].backgr_col = back_col 
      DATA.GUI.buttons[b_key..'_frame'].backgr_fill = back_fill
      --DATA.GUI.buttons[b_key..'_frame'].frame_a = frame_a
      --DATA.GUI.buttons[b_key..'_frame'].frame_col = frame_col
      
      DATA.GUI.buttons[b_key..'_name'].frame_a = frame_a
      DATA.GUI.buttons[b_key..'_name'].frame_col = frame_col
      DATA.GUI.buttons[b_key..'_name'].backgr_fill =back_fill
      if DATA.GUI.custom_compactmode == 2 then DATA.GUI.buttons[b_key..'_name'].backgr_fill =0 end
      DATA.GUI.buttons[b_key..'_name'].backgr_col = back_col
      
      DATA.GUI.buttons[b_key..'_knob'].frame_a = frame_a
      DATA.GUI.buttons[b_key..'_knob'].frame_asel = frame_a
      DATA.GUI.buttons[b_key..'_knob'].frame_col = frame_col
      DATA.GUI.buttons[b_key..'_knob'].backgr_fill =back_fill
      DATA.GUI.buttons[b_key..'_knob'].backgr_col = back_col
      DATA.GUI.buttons[b_key..'_knobarc'].frame_a = 0
      DATA.GUI.buttons[b_key..'_knobarc'].frame_col = frame_col
      DATA.GUI.buttons[b_key..'_knobarc'].backgr_fill =0
      DATA.GUI.buttons[b_key..'_knobarc'].backgr_col = back_col
      
      if DATA.GUI.buttons[b_key..'_val'] then
        DATA.GUI.buttons[b_key..'_val'].frame_a = frame_a
        DATA.GUI.buttons[b_key..'_val'].frame_col = frame_col
        DATA.GUI.buttons[b_key..'_val'].backgr_fill =back_fill
        DATA.GUI.buttons[b_key..'_val'].backgr_col = back_col
      end  
    end
    
    
  end
  ------------------------------------------------------------------------------ 
  function  GUI_ContextMenu_Variation(varID)
    local t = { 
      {str= 'Set variation name',
       func = function()
                local retval, retvals_csv = reaper.GetUserInputs( DATA.extstate.mb_title, 1, ',extwidth=100',DATA2.masterJSFX_variations_list[varID].name )
                if retval == true and not (retvals_csv:match('Macro %d+') and retvals_csv:match('Macro %d+') == retvals_csv)then 
                  DATA2.masterJSFX_variations_list[varID].name = retvals_csv:gsub('|','')
                  DATA2:MasterJSFX_WriteSliders(knobid)
                end 
              end},
      }
    DATA:GUImenu(t)
  end
  ------------------------------------------------------------------------------ 
  function  GUI_ContextMenu_FXName(t)
    local t = { 
      {str= '#'..t.destfx_FXname},
      {str= 'Remove all links from current FX',
       func = function() 
                local tr = t.slave_jsfx_tr
                local fx = t.destfx_FXID
                local slavefx_id = t.slave_jsfx_ID
                for param = 1, TrackFX_GetNumParams( tr, fx ) do
                  local retval, effect = TrackFX_GetNamedConfigParm( tr, fx, 'param.'..(param-1)..'.plink.effect')
                  if (retval == true and tonumber(effect) ==  slavefx_id) then 
                    TrackFX_SetNamedConfigParm( tr, fx, 'param.'..(param-1)..'.plink.active',0 )
                  end 
                end
              end},
      }
    DATA:GUImenu(t)
    DATA.UPD.onprojstatechange = true
  end
  ------------------------------------------------------------------------------ 
  function GUI_ContextMenu_ParamName(t)
    local t = { 
      {str= '#'..t.destfx_paramname},
      {str= 'Link same parameter on the FX at selected tracks',
       func = function() DATA2:Link_mapsame(t) DATA2:SlaveJSFX_Read()  end},
      }
    DATA:GUImenu(t)
  end
  ------------------------------------------------------------------------------- 
  function GUI_ContextMenu_Macro(DATA,knobid) 
    local t = { 
      {str= '#Macro '..knobid},
      {str= '|Set macro name',
       func = function()
                local retval, retvals_csv = reaper.GetUserInputs( DATA.extstate.mb_title, 1, ',extwidth=100', DATA2.masterJSFX_sliders[knobid].name )
                if retval == true and not (retvals_csv:match('Macro %d+') and retvals_csv:match('Macro %d+') == retvals_csv)then
                  DATA2.masterJSFX_sliders[knobid].name = retvals_csv:gsub('|','')
                  DATA2:MasterJSFX_WriteSliders(knobid)
                end 
              end},
      {str= 'Reset macro name',
       func = function()
                DATA2.masterJSFX_sliders[knobid].name = 'Macro '..knobid
                DATA2:MasterJSFX_WriteSliders(knobid)
              end},
      {str= 'Set macro color',
       func = function()
                local retval, color = reaper.GR_SelectColor()
                if not retval then return end
                local r, g, b = reaper.ColorFromNative( color )
                local outhex = '#'..string.format("%06X",  ColorToNative( b, g, r ))  
                DATA2.masterJSFX_sliders[knobid].col = outhex
                DATA2:MasterJSFX_WriteSliders(knobid)
              end}, 
      {str= 'Reset macro color',
       func = function()
                DATA2.masterJSFX_sliders[knobid].col = nil
                DATA2:MasterJSFX_WriteSliders(knobid)
              end}, 
      { str='Exclude from randomization',
        state = DATA2.masterJSFX_sliders[knobid].flags&1==1,
        func = function()
                  DATA2.masterJSFX_sliders[knobid].flags = DATA2.masterJSFX_sliders[knobid].flags~1
                  DATA2:MasterJSFX_WriteSliders(knobid)
                end
      },   
      { str='Exclude from variation',
        state = DATA2.masterJSFX_sliders[knobid].flags&2==2,
        func = function()
                  DATA2.masterJSFX_sliders[knobid].flags = DATA2.masterJSFX_sliders[knobid].flags~2
                  DATA2:MasterJSFX_WriteSliders(knobid)
                end
      },       
      { str='|Show/hide track envelope for this macro',
        func = function()
                  if not (DATA2.masterJSFX_isvalid and DATA2.masterJSFX_isvalid  == true) then return end
                  local track = DATA2.masterJSFX_tr
                  SetMixerScroll( track )
                  TrackFX_EndParamEdit( track, DATA2.masterJSFX_FXid, knobid-1 )
                  Action(41142)--FX: Show/hide track envelope for last touched FX parameter
                end
      },
      { str='Arm track envelope for this macro',
        func = function()
                  if not (DATA2.masterJSFX_isvalid and DATA2.masterJSFX_isvalid  == true) then return end
                  local track = DATA2.masterJSFX_tr
                  TrackFX_EndParamEdit( track, DATA2.masterJSFX_FXid, knobid-1 )
                  Action(41984) --FX: Arm track envelope for last touched FX parameter
                end
      },      
      { str='Activate/bypass track envelope for this macro',
        func = function()
                  if not (DATA2.masterJSFX_isvalid and DATA2.masterJSFX_isvalid  == true) then return end
                  local track = DATA2.masterJSFX_tr
                  TrackFX_EndParamEdit( track, DATA2.masterJSFX_FXid, knobid-1 )
                  Action(41983) --FX: Activate/bypass track envelope for last touched FX parameter
                end
      },          
      { str='Set MIDI learn for this macro',
        func = function()
                  if not (DATA2.masterJSFX_isvalid and DATA2.masterJSFX_isvalid  == true) then return end
                  local track = DATA2.masterJSFX_tr
                  TrackFX_EndParamEdit( track, DATA2.masterJSFX_FXid, knobid-1 )
                  Action(41144) --FX: Set MIDI learn for last touched FX parameter
                end
      },   
      { str='Show parameter modulation/link for this macro',
        func = function()
                  if not (DATA2.masterJSFX_isvalid and DATA2.masterJSFX_isvalid  == true) then return end
                  local track = DATA2.masterJSFX_tr
                  TrackFX_EndParamEdit( track, DATA2.masterJSFX_FXid, knobid-1 )
                  Action(41143) --FX: Show parameter modulation/link for last touched FX parameter
                end
      },  
      { str='|Remove all links from this macro',
        func = function()
                  for i = #DATA2.slaveJSFXlinks,1,-1 do DATA2:Link_remove(DATA2.slaveJSFXlinks[i]) end 
                end
      }, 
      
      
    }
  
    DATA:GUImenu(t)
    GUI_Upd_Macro(DATA,knobid) 
    GUI_Upd_Links(DATA,t)
  end
  ------------------------------------------------------------------------------- 
  function GUI_Macro(DATA,t) 
    if not DATA2.masterJSFX_sliders then return end
    local knobid = t.id
    local b_key = 'macro_'..knobid
    -- frame
    DATA.GUI.buttons[b_key..'_frame'] = {
                        x=t.x,
                        y=t.y,
                        w=t.w,
                        h=t.h,
                        frame_a =DATA.GUI.custom_knobframea,
                        txt_a =1,
                        txt_flags =1|2|4,
                        txt_col ='#FFFFFF',
                        val = DATA2.masterJSFX_sliders[knobid].val or 0,
                        val_res = 0.5,
                        val_min = 0,
                        val_max = 1,
                        onmouseclick = function()
                                        DATA2.masterJSFX_slselectionmask = 2^(knobid-1) 
                                        DATA2:MasterJSFX_WriteSliders(knobid)
                                        DATA2:SlaveJSFX_Read()
                                        GUI_Links_Control(DATA) -- refresh
                                        DATA.GUI.firstloop = 1
                                        GUI_Upd_MacroSelection(DATA) 
                                      end,
                        onmousedrag = function()
                                        -- perform [update UI at drag then freeze if there aren`t any movements more than X seconds]
                                          if not DATA.GUI.mouse_ismoving then
                                            local freezetimer_sec = 0.5
                                            if not DATA.ts_mousefreeze then DATA.ts_mousefreeze = os.clock() end
                                            if os.clock() - DATA.ts_mousefreeze > freezetimer_sec then 
                                              return
                                            end
                                           else
                                            DATA.ts_mousefreeze = nil
                                          end 
                                        
                                        DATA.ondraganything = true
                                        DATA2:MasterJSFX_WriteSliders(knobid) 
                                        DATA2:SlaveJSFX_UpdateParameters() 
                                        GUI_Upd_Macro(DATA,knobid) 
                                        GUI_Upd_Links(DATA,t)
                                      end,
                        onmouserelease = function()
                                        DATA2:MasterJSFX_WriteSliders(knobid) 
                                        DATA2:SlaveJSFX_UpdateParameters() 
                                        GUI_Upd_Macro(DATA,knobid) 
                                        GUI_Upd_Links(DATA,t)
                                        GUI_Upd_MacroSelection(DATA) 
                                        DATA.ondraganything = nil
                                        DATA.ts_mousefreeze = nil
                                      end,
                        onmousereleaseR = function()
                                        --refresh data
                                        DATA2.masterJSFX_slselectionmask = 2^(knobid-1) 
                                        DATA2:MasterJSFX_WriteSliders(knobid)
                                        DATA2:SlaveJSFX_Read()
                                        
                                        GUI_ContextMenu_Macro(DATA,knobid) 
                                        DATA.ondraganything = nil
                                      end
                        } 
    DATA.GUI.buttons[b_key..'_name'] = { x= t.x+1,
                      y=t.y+1,
                      w=t.w-2,
                      h=DATA.GUI.custom_knobreadout_h-2,
                      ignoremouse = true,
                      txt_a = 1,
                      txt_fontsz =  DATA.GUI.custom_knobnametxtsz,
                      
                      }
    DATA.GUI.buttons[b_key..'_knob'] = { x= t.x+1,
                      y=t.y+DATA.GUI.custom_knobreadout_h,
                      w=t.w-2,
                      h=t.h-DATA.GUI.custom_knobreadout_h*2-1,
                      ignore_mouse = true,
                      --knob_isknob = true,
                      }     
    DATA.GUI.buttons[b_key..'_knobarc'] = { x= t.x+DATA.GUI.custom_offset,
                      y=t.y+DATA.GUI.custom_knobreadout_h,
                      w=t.w-DATA.GUI.custom_offset*2,
                      h=t.h-DATA.GUI.custom_knobreadout_h*2-1,
                      ignoremouse = true,
                      knob_isknob = true,
                      }                       
    if DATA.GUI.custom_compactmode == 2 then 
      DATA.GUI.buttons[b_key..'_knob'].y=t.y+1
      DATA.GUI.buttons[b_key..'_name'].h=t.h-1 
      DATA.GUI.buttons[b_key..'_knob'].h=t.h -1
      DATA.GUI.buttons[b_key..'_knobarc'].x= t.x
      DATA.GUI.buttons[b_key..'_knobarc'].y= t.y
      DATA.GUI.buttons[b_key..'_knobarc'].w= t.w
      DATA.GUI.buttons[b_key..'_knobarc'].h= t.h
    end
    if DATA.GUI.custom_compactmode ~= 2 then
      DATA.GUI.buttons[b_key..'_val'] = { x= t.x+1,
                      y=t.y+t.h-DATA.GUI.custom_knobreadout_h,
                      w=t.w-2,
                      h=DATA.GUI.custom_knobreadout_h-1,
                      ignoremouse = true,
                      --txt_fontsz =  DATA.GUI.custom_sampler_ctrl_txtsz,
                      }  
    end
    GUI_Upd_Macro(DATA,knobid) 
    GUI_Upd_MacroSelection(DATA) 
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE()
  
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
        
    local  t = 
    { 
      {str = 'General' ,                            group = 1, itype = 'sep'}, 
        {str = 'Mode' ,                             group = 1, itype = 'readout', level = 1,  confkey = 'CONF_mode', menu = { [0]='Master JSFX', [1]='Slave JSFX per track'},readoutw_extw=120},
        {str = 'Show graph for limits/scale' ,      group = 1, itype = 'check', level = 1,  confkey = 'UI_showgraph'},
        {str = 'Restore defaults',                  group = 1, itype = 'button', level = 1, func_onrelease = function ()
                    DATA:ExtStateRestoreDefaults(nil,true) 
                    DATA.UPD.onconfchange = true 
                    DATA:GUIBuildSettings()
        end},
      {str = 'Add link' ,                           group = 2, itype = 'sep'}, 
        {str = 'When add link, port slave value to master knob', group = 2, itype = 'check',level = 1,  confkey = 'CONF_setslaveparamtomaster'}, 
        {str = 'Rename macro from last touched parameter', group = 2, itype = 'check',level = 1,confkeybyte=0,  confkey = 'CONF_addlinkrenameflags'}, 
          {str = 'Only when default name', group = 2, itype = 'check',level = 2,confkeybyte=1,  confkey = 'CONF_addlinkrenameflags',hide=DATA.extstate.CONF_addlinkrenameflags&1~=1}, 
      {str = 'Random' ,                             group = 3, itype = 'sep'}, 
        {str = 'Do not random 0 and 1 values',      group = 3, itype = 'check',level = 1,  confkey = 'CONF_randpreventrandfromlimits'}, 
        {str = 'Random strength' ,                  group = 3, itype = 'readout', confkey = 'CONF_randstrength', level = 1, val_min = 0, val_max = 1, val_res = 0.05, val_format = function(x) return (VF_math_Qdec(x,3)*100)..'%' end},--, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end},
        
      {str = 'Actions' ,                            group = 1, itype = 'sep'},  
        {str = 'Toggle dock',                       group = 1, itype = 'button', confkey = 'dock',  level = 1, func_onrelease = function () GUIf_dock(DATA) end}, 
        {str = 'Reset all knobs',                   group = 1, itype = 'button', confkey = 'dock',  level = 1, func_onrelease = function () DATA2:Macro_Reset() end},

    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function GUIf_dock(DATA)  
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
    
    
  end
  ---------------------------------------------------------------------  
  function DATA_RESERVED_ONPROJCHANGE(DATA)
    -- data
    local ReaProj, projfn = reaper.EnumProjects( -1 )
    DATA2.ReaProj = ReaProj 
    local ret,forceUIinit = DATA2:MasterJSFX_Validate()
    if not ret then return end
    DATA2:MasterJSFX_ReadSliders()
    DATA2:SlaveJSFX_Read()
    DATA2:Link_Extstate_Get()
    DATA2:Link_Extstate_Validate() 
    
    -- UI
    if not (DATA.ondraganything and DATA.ondraganything == true) and DATA.GUI.buttons then GUI_RESERVED_initstuff(DATA) DATA.GUI.firstloop = 1 end 
    
  end 
  ------------------------------------------------------------------
  function DATA2:SlaveJSFX_UpdateParameters() 
    for link = 1, #DATA2.slaveJSFXlinks do
      local tr = DATA2.slaveJSFXlinks[link].slave_jsfx_tr
      if ValidatePtr2(DATA2.ReaProj,tr,'MediaTrack*') then
        DATA2.slaveJSFXlinks[link].destfx_param = TrackFX_GetParamNormalized( tr, DATA2.slaveJSFXlinks[link].destfx_FXID, DATA2.slaveJSFXlinks[link].destfx_paramID )
        DATA2.slaveJSFXlinks[link].destfx_paramformatted = ({TrackFX_GetFormattedParamValue(tr, DATA2.slaveJSFXlinks[link].destfx_FXID, DATA2.slaveJSFXlinks[link].destfx_paramID,'' )})[2]
        
        DATA2.slaveJSFXlinks[link].slave_jsfx_param = TrackFX_GetParamNormalized( tr, DATA2.slaveJSFXlinks[link].slave_jsfx_ID, DATA2.slaveJSFXlinks[link].slave_jsfx_paramID )
        
        --[[
        local flags = TrackFX_GetParam( tr, slavefx_id, slider_flag-1) 
        local hexarray = TrackFX_GetParam( tr, slavefx_id, slider_hex-1) 
        flags = flags,
        flags_mute = flags&1==1,
        flags_tension = ((flags>>1)&0xF)/15,
        hexarray = hexarray,
        hexarray16 = string.format("%X", hexarray),
        hexarray_lim_min = (hexarray&0xFF)/255,
        hexarray_lim_max = ((hexarray>>8)&0xFF)/255,
        hexarray_scale_min = ((hexarray>>16)&0xFF)/255,
        hexarray_scale_max = ((hexarray>>24)&0xFF)/255,
        hexarray_tension = ((hexarray>>32)&0xFF)/255,
        ]]
      end
    end
  end 
  ------------------------------------------------------------------
  function DATA2:SlaveJSFX_Read() 
    DATA2.slaveJSFXlinks = {}
    local selectedknob = DATA2:GetSelectedKnob() 
    
    if DATA.extstate.CONF_mode == 0 then
      for i = 1, CountTracks(DATA2.ReaProj) do
        local tr = GetTrack(DATA2.ReaProj,i-1)
        for fx = 1, TrackFX_GetCount(tr) do
          local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
          if fxname:match('MappingPanel_slave') then DATA2:SlaveJSFX_Read_Routing(DATA2.ReaProj, tr, fx-1, selectedknob,i-1) break end
        end
      end
    end
    
    if DATA.extstate.CONF_mode ==1 then
      local tr = GetSelectedTrack(DATA2.ReaProj,0)
      if not tr then return end
      for fx = 1, TrackFX_GetCount(tr) do
        local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
        if fxname:match('MappingPanel_slave') then DATA2:SlaveJSFX_Read_Routing(DATA2.ReaProj, tr, fx-1, selectedknob) break end
      end
    end
  end
  ------------------------------------------------------------------
  function DATA2:SlaveJSFX_Write(t)
    if not t then return end
    local tr = t.slave_jsfx_tr
    local cur_hex = t.hexarray
    local out_hex = math.floor(t.hexarray_lim_min*255) + 
              (math.floor(t.hexarray_lim_max*255)<<8) + 
              (math.floor(t.hexarray_scale_min*255)<<16) + 
              (math.floor(t.hexarray_scale_max*255)<<24)
    local out_flags = 0
    out_flags =out_flags + t.flags_mute
    out_flags =out_flags + (math.floor(t.flags_tension * 15) <<1)
    out_flags =out_flags + (math.floor(t.hexarray_scale_max*255)<<9) 
    TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID+16*2, out_flags)
    TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID+16*3, out_hex)
    if t.flags_mute == 1 then TrackFX_SetParam( tr, t.slave_jsfx_ID, t.slave_jsfx_paramID, t.slave_jsfx_param) end
  end
  ------------------------------------------------------------------
  function DATA2:SlaveJSFX_Read_Routing(proj, tr, slavefx_id,selectedknob,trid)
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
          
          local slider = tonumber(paramSrc)+1 -- 1based
          local slider_macrolink = slider+16 -- 1based
          local slider_flag = slider+32 -- 1based
          local slider_hex = slider+48 -- 1based
          
          local masterlink = TrackFX_GetParam( tr, slavefx_id, slider_macrolink-1)  
          if DATA.extstate.CONF_mode == 0 then if masterlink ~= selectedknob  then goto nextparam end end-- related to selected knob
          if DATA.extstate.CONF_mode == 1 then if slider ~= selectedknob  then goto nextparam end end-- related to selected knob
          
          local flags = TrackFX_GetParam( tr, slavefx_id, slider_flag-1) 
          local hexarray = TrackFX_GetParam( tr, slavefx_id, slider_hex-1) 
          
          local fxname_full = ({ TrackFX_GetFXName( tr, fx-1, '' )})[2]
          local fxname = VF_ReduceFXname(fxname_full)
          local param_name = ({ TrackFX_GetParamName( tr,  fx-1, param-1, '' )})[2]
          DATA2.slaveJSFXlinks[#DATA2.slaveJSFXlinks+1] = 
                { 
                  knob = selectedknob,
                  slave_jsfx_trGUID = GetTrackGUID( tr ),
                  slave_jsfx_tr = tr,
                  slave_jsfx_trname = ({GetTrackName(tr)})[2],
                  slave_jsfx_ID = slavefx_id,
                  slave_jsfx_fxGUID = TrackFX_GetFXGUID( tr, slavefx_id ),
                  slave_jsfx_paramID = paramSrc,
                  slave_jsfx_param = TrackFX_GetParamNormalized( tr, slavefx_id, paramSrc ),
                  slave_jsfx_tridmark = trid,
                  
                  destfx_FXGUID =  TrackFX_GetFXGUID( tr, fx-1 ),
                  destfx_FXname =fxname,
                  destfx_FXname_full =fxname_full,
                  destfx_FXID =fx-1,
                  destfx_paramID =param-1,
                  destfx_paramname = param_name,
                  destfx_param = TrackFX_GetParamNormalized( tr, fx-1, param-1 ),
                  destfx_paramformatted = ({TrackFX_GetFormattedParamValue( tr, fx-1, param-1 ,'' )})[2],
                  
                  flags = flags,
                  flags_mute = flags&1,--==1,
                  flags_tension = ((flags>>1)&0xF)/15,
                  
                  hexarray = hexarray,
                  hexarray16 = string.format("%X", hexarray),
                  hexarray_lim_min = (hexarray&0xFF)/255,
                  hexarray_lim_max = ((hexarray>>8)&0xFF)/255,
                  hexarray_scale_min = ((hexarray>>16)&0xFF)/255,
                  hexarray_scale_max = ((hexarray>>24)&0xFF)/255,
                }
                
          ::nextparam::
        end
      end
    end
  end
  ------------------------------------------------------------------
  function DATA2:MasterJSFX_ReadSliders()
    -- define source track
      local extstate_tr = GetMasterTrack(DATA2.ReaProj) 
      if DATA.extstate.CONF_mode == 1 then 
        extstate_tr = GetSelectedTrack(DATA2.ReaProj,0) 
      end
            
      if not extstate_tr then return end
    
    -- selection mask
      DATA2.masterJSFX_slselectionmask = 1
      local retval, val = GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_SLSELMASK', '', false )
      if retval==true and tonumber(val) then DATA2.masterJSFX_slselectionmask = tonumber(val) end
    
    -- sliders info 
      DATA2.masterJSFX_sliders = {}
      for i = 1, 16 do
        local name = 'Macro '..i
        local scroll = 0
        local col
        local flags = 0
        
        local retval, chunk = GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_MACRO'..i, '', false )
        if retval==true then 
          local t = {}
          for val in chunk:gmatch('[^%|]+') do t[#t+1] = val end
          name=t[1] or 'Macro '..i
          scroll=tonumber(t[2])
          flags=tonumber(t[3])
          col=t[4]
        end 
        
        local val = 0--gmem_read(i)
        if DATA2.masterJSFX_FXid then val = TrackFX_GetParamNormalized( extstate_tr, DATA2.masterJSFX_FXid, i-1 ) end
        if val == -1 then val = 0 end
        DATA2.masterJSFX_sliders[i] = {val = val, name = name,col=col,scroll=scroll,flags=flags}
      end
      
    -- variations list
      DATA2.masterJSFX_variations_list = {}
      local retval, chunk = GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_VARLIST', '', false )
      if retval==true then
        local varID = 1
        for block in chunk:gmatch('[^%;]+') do
          --number|name|color|list_of_parameters
          local t = {}
          for val in block:gmatch('[^%|]+') do t[#t+1] = val end
          local macrolist = {}
          for macroval in (t[3]):gmatch('[^%s]+') do macrolist[#macrolist+1] = tonumber(macroval) end
          DATA2.masterJSFX_variations_list[varID] = {
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
  function DATA2:MasterJSFX_WriteSliders(id0)
    local extstate_tr = GetMasterTrack(DATA2.ReaProj) 
    if DATA.extstate.CONF_mode == 1 then extstate_tr = GetSelectedTrack(DATA2.ReaProj,0) end
    if not extstate_tr then return end
    
    
    gmem_write(100,1 )
    local i_st = 1
    local cnt=15
    if id0 then i_st = id0 cnt = 0 end
    for id = i_st, i_st+cnt do 
      if DATA.extstate.CONF_mode == 1 and DATA2.masterJSFX_FXid then TrackFX_SetParam( extstate_tr, DATA2.masterJSFX_FXid, id+16-1, 0 ) end
      --if DATA.extstate.CONF_mode == 0 and DATA2.masterJSFX_FXid then TrackFX_SetParam( extstate_tr, DATA2.masterJSFX_FXid, id+16-1, id0 ) end
      if DATA2.masterJSFX_FXid then TrackFX_SetParamNormalized( extstate_tr, DATA2.masterJSFX_FXid, id-1, DATA2.masterJSFX_sliders[id].val )   end
      local col = DATA2.masterJSFX_sliders[id].col if not col then col = '' end
      if DATA2.masterJSFX_sliders[id] then GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_MACRO'..id, DATA2.masterJSFX_sliders[id].name..'|'..DATA2.masterJSFX_sliders[id].scroll..'|'..DATA2.masterJSFX_sliders[id].flags..'|'..col, true )  end
    end 
    
    GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_SLSELMASK', DATA2.masterJSFX_slselectionmask, true )
    
    if not DATA2.masterJSFX_variations_list then DATA2.masterJSFX_variations_list = {} end
    local outchunk = ''
    for i = 1, 8 do
      if not DATA2.masterJSFX_variations_list[i] then 
        DATA2.masterJSFX_variations_list[i] = {
          name='Variation'..i,
          col = 0,
          macrolist = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
          issel = 0
          } 
      end
      local name = DATA2.masterJSFX_variations_list[i].name or ''
      local col = DATA2.masterJSFX_variations_list[i].col or ''
      local issel = DATA2.masterJSFX_variations_list[i].issel or 0
      local macrolist = ''
      if DATA2.masterJSFX_variations_list[i].macrolist then macrolist = table.concat(DATA2.masterJSFX_variations_list[i].macrolist, ' ') end
      outchunk = outchunk..name..'|'..col..'|'..macrolist..'|'..issel..';'
    end
    GetSetMediaTrackInfo_String( extstate_tr, 'P_EXT:MPLMAPPAN_VARLIST', outchunk, true )
  end 
  ------------------------------------------------------------------
  function DATA2:MasterJSFX_Validate_Add()
    local ret = MB("MappingPanel master JSFX not found in current project. Add it to master track?", DATA.extstate.mb_title, 4)
    if ret == 6 then 
      local tr = GetMasterTrack(DATA2.ReaProj,0)
      if tr then  
        reaper.PreventUIRefresh( 1 ) 
        local fx_new =  TrackFX_AddByName( tr, 'JS:MappingPanel_master.jsfx', false, -1000 ) 
        reaper.TrackFX_Show( tr, fx_new, 2 ) -- add and hide
        reaper.PreventUIRefresh( -1 )
        DATA2:MasterJSFX_Validate_Find()
        return true
      end
    end 
  end
  ------------------------------------------------------------------
  function DATA2:MasterJSFX_Validate_Find()
    if DATA.extstate.CONF_mode == 0 then 
      for i = 0, CountTracks(DATA2.ReaProj) do
        local tr = GetTrack(DATA2.ReaProj,i-1)
        if i==0 then tr = GetMasterTrack(DATA2.ReaProj) end
        for fx = 1,  TrackFX_GetCount( tr ) do
          local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
          if fxname:match('MappingPanel_master') then
            DATA2.masterJSFX_isvalid = true
            DATA2.masterJSFX_trGUID = GetTrackGUID( tr )
            DATA2.masterJSFX_tr = tr
            DATA2.masterJSFX_FXid = fx-1
            return true
          end
        end
      end
    end
    
    if DATA.extstate.CONF_mode == 1 then
      local tr = GetSelectedTrack(DATA2.ReaProj,0)
      if not tr then return end
      for fx = 1,  TrackFX_GetCount( tr ) do
        local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr,  fx-1, 'original_name' )
        if fxname:match('MappingPanel_slave') then
          DATA2.masterJSFX_isvalid = true
          DATA2.masterJSFX_trGUID = GetTrackGUID( tr )
          DATA2.masterJSFX_tr = tr
          DATA2.masterJSFX_FXid = fx-1
          return true
        end
      end
    end
  end
  ------------------------------------------------------------------
  function DATA2:MasterJSFX_Validate()
    local forceUIinit
    -- if not exist // add if not exist
      if not DATA2.masterJSFX_tr then
        local ret = DATA2:MasterJSFX_Validate_Find()  
        --if ret ~= true then DATA2:MasterJSFX_Validate_Add() end 
      end
     
    -- if defined -------------
      if DATA2.masterJSFX_isvalid == true and DATA2.masterJSFX_tr and DATA2.masterJSFX_FXid then 
        if reaper.ValidatePtr2( DATA2.ReaProj, DATA2.masterJSFX_tr, 'MediaTrack*') ~= true then 
          local ret = DATA2:MasterJSFX_Validate_Find()
          --[[if ret ~= true then DATA2:MasterJSFX_Validate_Add() else 
            forceUIinit = true
            return true, forceUIinit
          end ]]
          return ret 
        end
      end
    
    return true
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.62) if ret then local ret2 = VF_CheckReaperVrs(6.74,true) if ret2 then reaper.gmem_attach('MappingPanel' ) main() end end
