-- @description Align Takes
-- @version 2.04
-- @author MPL
-- @about Script for matching RMS of audio takes and stratch them using stretch markers
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # improve settings scroll



  --[[
    * Changelog: 
      * v2.0 (01.2022)
      * v1.00 (2016-02-11) Public release
      * v0.23 (2016-01-25) Split from Warping tool
      * v0.01 (2015-09-01) Alignment / Warping / Tempomatching tool idea
    --]]
    
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  -- per item mod
  -- zero crossing  
  -- get existed stretch markers as points
  -- preserve transients (guard)
  -- manual remove points 
  -- use eel for CPU hungry stuff 
  -- obey pitch data
  -- align pitch data
  -- big data limit
  
  local DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 2.04
    DATA.extstate.extstatesection = 'AlignTakes2'
    DATA.extstate.mb_title = 'AlignTakes'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  200,
                          wind_h =  150,
                          dock =    0,
                          
                          FPRESET1 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gUGlja2VkIGd1aXRhcgpDT05GX2FwcGF0Y2hhbmdlPTEKQ09ORl9hdWRpb19ic19hMT0wCkNPTkZfYXVkaW9fYnNfYTI9MQpDT05GX2F1ZGlvX2JzX2EzPTAKQ09ORl9hdWRpb19ic19hND0xCkNPTkZfYXVkaW9fYnNfZjE9MjAwCkNPTkZfYXVkaW9fYnNfZjI9MjAwMApDT05GX2F1ZGlvX2JzX2YzPTUwMDAKQ09ORl9hdWRpb19saW09MQpDT05GX2F1ZGlvZG9zcXVhcmVyb290PTEuMApDT05GX2NsZWFubWFya2R1Yj0xCkNPTkZfY29tcGVuc2F0ZW92ZXJsYXA9MQpDT05GX2VuYWJsZXNob3J0Y3V0cz0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2luaXRmbGFncz0zCkNPTkZfbWFya2dlbl9STVNwb2ludHM9NQpDT05GX21hcmtnZW5fZW52ZWxvcGVyaXNlZmFsbD0yCkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHM9MTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDg3NQpDT05GX21hcmtnZW5fdGhyZXNob2xkPTEKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MwpDT05GX21hdGNoX2lnbm9yZXplcm9zPTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0wCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MApDT05GX3dpbmRvdz0wLjAxNwpDT05GX3dpbmRvd19vdmVybGFwPTE=',
                          FPRESET2 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gRGlzdG9ydGVkIGd1aXRhcgpDT05GX2FwcGF0Y2hhbmdlPTEKQ09ORl9hdWRpb19ic19hMT0wCkNPTkZfYXVkaW9fYnNfYTI9MQpDT05GX2F1ZGlvX2JzX2EzPTAKQ09ORl9hdWRpb19ic19hND0wCkNPTkZfYXVkaW9fYnNfZjE9ODMKQ09ORl9hdWRpb19ic19mMj0xMjUwCkNPTkZfYXVkaW9fYnNfZjM9NTAwMApDT05GX2F1ZGlvX2xpbT0xCkNPTkZfYXVkaW9kb3NxdWFyZXJvb3Q9MS4wCkNPTkZfY2xlYW5tYXJrZHViPTEKQ09ORl9jb21wZW5zYXRlb3ZlcmxhcD0xCkNPTkZfZW5hYmxlc2hvcnRjdXRzPTAKQ09ORl9pbml0YXRtb3VzZXBvcz0wCkNPTkZfaW5pdGZsYWdzPTMKQ09ORl9tYXJrZ2VuX1JNU3BvaW50cz01CkNPTkZfbWFya2dlbl9lbnZlbG9wZXJpc2VmYWxsPTEKQ09ORl9tYXJrZ2VuX2ZpbHRlcnBvaW50cz0xMQpDT05GX21hcmtnZW5fbWluaW1hbGFyZWFSTVM9MC4wODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQ9MQpDT05GX21hdGNoX2Jsb2NrYXJlYT0xCkNPTkZfbWF0Y2hfaWdub3JlemVyb3M9MApDT05GX21hdGNoX3N0cmV0Y2hkdWJhcnJheT0xCkNPTkZfb2J0aW1lc2VsPTAKQ09ORl9wb3N0X3BvczBtYXJrPTEKQ09ORl9wb3N0X3BzaGlmdD0tMQpDT05GX3Bvc3RfcHNoaWZ0c3ViPTAKQ09ORl9wb3N0X3NtbW9kZT0yCkNPTkZfcG9zdF9zdHJtYXJrZmRzaXplPTAuMDExMQpDT05GX3Ntb290aD0wCkNPTkZfd2luZG93PTAuMDE3CkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
                          CONF_NAME = 'default',
                          CONF_initflags = 3, -- &1 init ref &2 init dub
                          CONF_appatchange = 1,
                          CONF_cleanmarkdub = 1,
                          CONF_obtimesel = 0,
                          CONF_enableshortcuts = 0,
                          CONF_initatmousepos = 0,
                          
                          CONF_window = 0.15,
                          CONF_window_overlap = 2,
                          
                          CONF_audiodosquareroot = 0.5,
                          
                          CONF_audio_bs_f1 = 200,
                          CONF_audio_bs_f2 = 2000,
                          CONF_audio_bs_f3 = 5000,
                          CONF_audio_bs_a1 = 0.5,
                          CONF_audio_bs_a2 = 1,
                          CONF_audio_bs_a3 = 1,
                          CONF_audio_bs_a4 = 0.5,
                          CONF_audio_lim = 1,
                          CONF_smooth = 2, 
                          CONF_compensateoverlap = 1, 
                          
                          CONF_markgen_enveloperisefall = 1, -- ==1 at fall ==2 at rise
                          CONF_markgen_filterpoints = 10, 
                          CONF_markgen_RMSpoints = 10, 
                          CONF_markgen_minimalareaRMS = 0.1,
                          CONF_markgen_threshold = 1,
                          
                          CONF_match_blockarea = 5, 
                          CONF_match_stretchdubarray = 1,
                          CONF_match_ignorezeros = 0,
                          
                          CONF_post_pshift = -1,
                          CONF_post_pshiftsub = 0,
                          CONF_post_strmarkfdsize = 0.0025,
                          CONF_post_smmode = 0,
                          CONF_post_pos0mark = 1,
                          }
                          
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets()  
    if DATA.extstate.CONF_initatmousepos&1==1 then
      local w = DATA.extstate.wind_w
      local h = DATA.extstate.wind_h 
      local x, y = GetMousePosition()
      DATA.extstate.wind_x = x-w/2
      DATA.extstate.wind_y = y-h/2
    end
    GUI:init()
    GUI_RESERVED_initbuttons(GUI)
    if DATA.extstate.CONF_initflags&1==1 or GUI.compactmode == 1 then DATA2:GetRefAudioData() end 
    if DATA.extstate.CONF_initflags&2==2 or GUI.compactmode == 1 then DATA2:GetDubAudioData(  (DATA.extstate.CONF_initflags&1==1 or GUI.compactmode == 1 )) end 
    RUN()
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_shortcuts(GUI)
    -- left/right arrow move main knob
    -- G/g get ref/dub
    -- R/r get ref
    -- D/d get dub
    
    if GUI.char <= 0 or DATA.extstate.CONF_enableshortcuts == 0 then return end
    
    if GUI.char == 32 then -- space
      VF_Action(40044)
    end
    if GUI.char == 71 or GUI.char == 103 then -- G/g
      DATA2:GetRefAudioData()
      DATA2:GetDubAudioData(true)
    end

    if GUI.char == 82 or GUI.char == 114 then -- R/r
      DATA2:GetRefAudioData()
    end
    
    if GUI.char == 68 or GUI.char == 100 then -- D/d
      DATA2:GetDubAudioData()
    end
    
    if GUI.char == 1919379572 or GUI.char == 1818584692 then -- left/right arrow
      local mult = 1
      local step = 0.1
      if GUI.char == 1818584692 then mult = -1 end
      if GUI.compactmode == 0 then 
        GUI.buttons.knob.val = VF_lim(GUI.buttons.knob.val+mult*step)
        GUI.buttons.knob.onmousedrag()  
        GUI.buttons.knob.refresh = true
       else
        GUI.buttons.knobCOMPACT.val = VF_lim(GUI.buttons.knob.val+mult*step)
        GUI.buttons.knobCOMPACT.onmousedrag()  
        GUI.buttons.knobCOMPACT.refresh = true
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:gettruewindow()
    local wind = DATA.extstate.CONF_window/DATA.extstate.CONF_window_overlap
    if DATA.extstate.CONF_compensateoverlap == 1 then wind = DATA.extstate.CONF_window end
    return wind
  end
  --------------------------------------------------------------------- 
  function DATA2:ApplyOutput(is_major) 
    if not DATA2.dubdata then return end
    
    for dubdataID = 1, #DATA2.dubdata do
      -- get table data
        local take_dubdata = DATA2.dubdata[dubdataID]
        if not take_dubdata then goto skipdubtake2 end 
      -- vars
        local data_pointsSRCDEST = take_dubdata.data_pointsSRCDEST
        local take =      take_dubdata.take
        local takeoffs =  take_dubdata.take_offs
        local takerate =  take_dubdata.take_rate
        local item =      take_dubdata.item
        local item_pos =  take_dubdata.item_pos
        local item_len =  take_dubdata.item_len
        local item_srclen =  take_dubdata.item_srclen
      -- validate take
        if not ValidatePtr2( 0, take, 'MediaItem_Take*' )  then goto skipdubtake2 end    
      -- clean markers
        DATA2:CleanDubMarkers(take, DATA2.refdata.edge_start,DATA2.refdata.edge_end, item, item_pos, takerate)   
      -- get true window
        local wind = DATA2:gettruewindow()
      -- validate data_pointsSRCDEST
        if not data_pointsSRCDEST then goto skipdubtake2 end
      -- get value
        local val = GUI.buttons.knob.val or 1
        if GUI.compactmode == 1 then val =  GUI.buttons.knobCOMPACT.val or 1 end
      -- add markers      
        local last_src_pos
        local last_set_pos
        
        if DATA.extstate.CONF_post_pos0mark == 1 then SetTakeStretchMarker(take, -1, 0) end
        
        for i = 1, #data_pointsSRCDEST do 
        
          local tpair = data_pointsSRCDEST[i]
          local srcpos = ((tpair.src-1) * wind)
          local pos = ((tpair.dest-1) * wind)
          
          local set_pos = pos-(item_pos-DATA2.refdata.edge_start)
          local src_pos = (srcpos-(item_pos-DATA2.refdata.edge_start) + takeoffs)--* takerate
          set_pos = (src_pos - takeoffs - ((src_pos - takeoffs) - set_pos)*val) --* takerate
          if last_src_pos ~= nil and last_set_pos ~= nil then
            -- check for negative stretch markers
            if (src_pos - last_src_pos) / (set_pos - last_set_pos ) > 0 then
              SetTakeStretchMarker(take, -1, set_pos,src_pos)
              last_src_pos = src_pos
              last_set_pos = set_pos
            end
           else
            SetTakeStretchMarker(take, -1, set_pos,src_pos)             
            last_src_pos = src_pos
            last_set_pos = set_pos
          end
          
        end
      if is_major == true then
        if DATA.extstate.CONF_post_pshift >= 0 then pshift = DATA.extstate.CONF_post_pshift end
        if DATA.extstate.CONF_post_pshift >= 0 and  DATA.extstate.CONF_post_pshiftsub >= 0 then  pshiftsub = DATA.extstate.CONF_post_pshiftsub end
        if DATA.extstate.CONF_post_pshift >= 0 or DATA.extstate.CONF_post_strmarkfdsize ~= 0.0025 then 
            VF_SetTimeShiftPitchChange(item, false, (DATA.extstate.CONF_post_pshift<<16) + DATA.extstate.CONF_post_pshiftsub, DATA.extstate.CONF_post_smmode, DATA.extstate.CONF_post_strmarkfdsize) 
        end
        
      end
      UpdateItemInProject( item )
      ::skipdubtake2::
    end
  end
  ---------------------------------------------------------------------  
  function GUI_initbuttons_definecompactmode(GUI, w0, h0)
    local w,h = gfx.w,gfx.h
    GUI.compactmode = 0
    GUI.compactmodelimh = 200
    GUI.compactmodelimw = 500
    if w < GUI.compactmodelimw*GUI.default_scale or h < GUI.compactmodelimh*GUI.default_scale then GUI.compactmode = 1 end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_initbuttons(GUI)
    if not GUI.layers then GUI.layers = {} end
    --GUI.default_scale = 2
    
    GUI.custom_mainbuth = 30
    GUI.custom_texthdef = 23
    GUI.custom_offset = math.floor(GUI.default_scale*GUI.default_txt_fontsz/2)
    GUI.custom_mainsepx = 400*GUI.default_scale--(gfx.w/ 2)/GUI.default_scale
    GUI.custom_mainbutw = ((gfx.w/GUI.default_scale - GUI.custom_mainsepx)-GUI.custom_offset*4) / 3
    GUI.custom_scrollw = 10
    GUI.custom_frameascroll = 0.05
    GUI.custom_default_framea_normal = 0.1
    GUI.custom_spectralw = GUI.custom_mainbutw*3 + GUI.custom_offset*2
    GUI.custom_layerset= 21
    GUI.custom_datah = (gfx.h/GUI.default_scale-GUI.custom_mainbuth-GUI.custom_offset*3) 
    
    GUI_initbuttons_definecompactmode(GUI)
    
    GUI.buttons = {} 
    -- main buttons
      GUI.buttons.getreference = { x=GUI.custom_offset,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = 'Get Ref',
                            txt_short = 'REF',
                            txt_fontsz = GUI.custom_texthdef,
                            onmouseclick =  function() DATA2:GetRefAudioData() end,
                            hide = GUI.compactmode==1,
                            ignoremouse = GUI.compactmode==1,
                            } 
      GUI.buttons.getdub = { x=GUI.custom_offset*2+GUI.custom_mainbutw,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = 'Get Dub',
                            txt_short = 'DUB',
                            txt_fontsz = GUI.custom_texthdef,
                            hide = GUI.compactmode==1,
                            ignoremouse = GUI.compactmode==1,
                            onmouseclick =  function() DATA2:GetDubAudioData() end}  
      GUI.buttons.preset = { x=GUI.custom_offset*5+GUI.custom_mainbutw*3,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainsepx-GUI.custom_offset*2,
                            h=GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_fontsz = GUI.custom_texthdef,
                            hide = GUI.compactmode==1,
                            ignoremouse = GUI.compactmode==1,
                            onmouseclick =  function() 
                                              -- form presets menu    
                                                local presets_t = {
                                                  {str = 'Reset all settings to default',
                                                    func = function() 
                                                              DATA.extstate.current_preset = nil
                                                              GUI.buttons.preset.txt = 'Preset: default'
                                                              DATA:ExtStateRestoreDefaults() 
                                                              GUI.firstloop = 1 
                                                              DATA.UPD.onconfchange = true 
                                                              GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                            end},
                                                  {str = 'Save current preset',
                                                  func = function() 
                                                            local id 
                                                            if DATA.extstate.current_preset then id = DATA.extstate.current_preset end
                                                            local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                                                            if not retval then return end
                                                            if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                                                            DATA:ExtStateStorePreset(id) 
                                                            DATA:ExtStateGetPresets()
                                                            GUI.buttons.preset.refresh = true 
                                                            GUI.firstloop = 1 
                                                            DATA.UPD.onconfchange = true 
                                                            GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                          end
                                                  }, 
                                                  {str = 'Rename current preset',
                                                  func = function() 
                                                            local id 
                                                            if not DATA.extstate.current_preset then return else id = DATA.extstate.current_preset end
                                                            local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                                                            if not retval then return end
                                                            if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                                                            DATA:ExtStateStorePreset(id) 
                                                            DATA:ExtStateGetPresets()
                                                            GUI.buttons.preset.refresh = true 
                                                            GUI.buttons.preset.txt = 'Preset: '..(DATA.extstate.CONF_NAME or '')
                                                            GUI.firstloop = 1 
                                                            DATA.UPD.onconfchange = true 
                                                            GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                          end
                                                  },                                                   
                                                  {str = 'Save current preset as new',
                                                  func = function() 
                                                            local id 
                                                            local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                                                            if not retval then return end
                                                            if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                                                            DATA:ExtStateStorePreset() 
                                                            DATA:ExtStateGetPresets()
                                                            GUI.buttons.preset.refresh = true 
                                                            GUI.firstloop = 1 
                                                            DATA.UPD.onconfchange = true 
                                                            GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                          end
                                                  },     
                                                  {str = 'Remove current preset',
                                                  func = function()
                                                            if DATA.extstate.current_preset then 
                                                              DATA:ExtStatePresetRemove(DATA.extstate.current_preset)
                                                              DATA.extstate.presets[DATA.extstate.current_preset] = nil
                                                              DATA.extstate.current_preset = nil
                                                            end
                                                            local id 
                                                            DATA:ExtStateGetPresets()
                                                            GUI.buttons.preset.refresh = true 
                                                            GUI.firstloop = 1 
                                                            DATA.UPD.onconfchange = true 
                                                            GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                          end
                                                  },                                                    
                                                  {str = ''},
                                                  {str = '#Preset list'},
                                                                  }
                                              -- add preset list    
                                                for i = 1, #DATA.extstate.presets do
                                                  local state = DATA.extstate.current_preset and DATA.extstate.current_preset == i
                                                  
                                                  presets_t[#presets_t+1] = { str = DATA.extstate.presets[i].CONF_NAME or '[no name]',
                                                                              func = function()  
                                                                                        DATA:ExtStateApplyPreset(DATA.extstate.presets[i]) 
                                                                                        DATA.extstate.current_preset = i
                                                                                        GUI.buttons.preset.refresh = true 
                                                                                        GUI.buttons.preset.txt = 'Preset: '..(DATA.extstate.CONF_NAME or '')
                                                                                        GUI.firstloop = 1 
                                                                                        DATA.UPD.onconfchange = true 
                                                                                        GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                                                      end,
                                                                              state = state,
                                                  
                                                    
                                                                              }
                                                end
                                              -- form table
                                                GUI:menu(presets_t)  
                                            end} 
                                            
      GUI.buttons.knob = { x=GUI.custom_offset*3 + GUI.custom_mainbutw*2 ,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = '',
                            txt_fontsz = GUI.custom_texthdef,
                            knob_isknob = true,
                            val_res = 0.25,
                            val = 0,
                            frame_a = GUI.default_framea_normal,
                            frame_asel = GUI.default_framea_normal,
                            back_sela = 0,
                            hide = GUI.compactmode==1,
                            ignoremouse = GUI.compactmode==1,
                            onmousedrag =  function() DATA2:ApplyOutput() end,
                            onmouserelease  =  function() 
                                                  DATA2:ApplyOutput(true)
                                                  Undo_OnStateChange2( 0, 'Align Takes' ) 
                                                end
                                            
                                            }   

      GUI.buttons.knobCOMPACT = { x=0 ,
                            y=0,
                            w=gfx.w/GUI.default_scale,
                            h=gfx.h/GUI.default_scale,
                            txt = '',
                            txt_fontsz = GUI.custom_texthdef,
                            knob_isknob = true,
                            --val_res = 0.25,
                            val = 0,
                            frame_a = GUI.default_framea_normal,
                            frame_asel = GUI.default_framea_normal,
                            back_sela = 0,
                            hide = GUI.compactmode~=1,
                            ignoremouse = GUI.compactmode~=1,
                            onmousedrag =  function()  DATA2:ApplyOutput() end,
                            onmouserelease  = GUI.buttons.knob.onmouserelease }                            
    -- settings
      GUI.buttons.settings = { x=gfx.w/GUI.default_scale - GUI.custom_mainsepx,
                            y=GUI.custom_mainbuth + GUI.custom_offset,
                            w=GUI.custom_mainsepx,
                            h=gfx.h/GUI.default_scale-GUI.custom_mainbuth - GUI.custom_offset,
                            txt = 'Settings',
                            txt_fontsz = GUI.custom_texthdef,
                            offsetframe = GUI.custom_offset,
                            frame_a = GUI.custom_default_framea_normal,
                            ignoremouse = true,
                            hide = GUI.compactmode==1,
                            }
  
      local offs = GUI.custom_offset
      GUI.buttons.settingslist = { x=GUI.buttons.settings.x +offs*2,
                            y=GUI.buttons.settings.y+offs*2,
                            w=GUI.buttons.settings.w-offs*5-GUI.custom_scrollw,
                            h=GUI.buttons.settings.h-offs*4  , 
                            txt = 'list',
                            frame_a = 1,
                            layer = GUI.custom_layerset,
                            hide = true,
                            ignoremouse = true,}  
      GUI.buttons.settingslist_mouse = { x=GUI.buttons.settings.x +offs*2, -- for scrolling
                            y=GUI.buttons.settings.y+offs*2,
                            w=GUI.buttons.settings.w-offs*5-GUI.custom_scrollw,
                            h=GUI.buttons.settings.h-offs*4  , 
                            txt = 'list',
                            frame_a = 1,
                            --layer = GUI.custom_layerset,
                            hide = true,
                            --ignoremouse = true,
                            onwheeltrig = function() 
                                            local dir = 1
                                            local layer= GUI.custom_layerset
                                            if GUI.wheel_dir then dir = -1 end
                                            GUI.layers[layer].scrollval = VF_lim(GUI.layers[layer].scrollval - 0.1 * dir)
                                            --GUI.buttons[key].refresh = true
                                            if GUI.buttons.settings_scroll then 
                                              GUI.buttons.settings_scroll.refresh = true
                                              GUI.buttons.settings_scroll.val = GUI.layers[layer].scrollval
                                            end
                                          end,}                               
      GUI:quantizeXYWH(GUI.buttons.settingslist)
      
      if not GUI.layers[GUI.custom_layerset] then GUI.layers[GUI.custom_layerset] = {} end
      GUI.layers[GUI.custom_layerset].scrollval=0
      
      GUI.buttons.settings_scroll = { x=GUI.buttons.settings.x+GUI.buttons.settings.w-GUI.custom_scrollw-offs*2,
                            y=GUI.buttons.settings.y+offs*2,
                            w=GUI.custom_scrollw,
                            h=GUI.buttons.settings.h-offs*4,
                            frame_a = GUI.custom_frameascroll,
                            frame_asel = GUI.custom_frameascroll,
                            val = 0,
                            val_res = -1,
                            slider_isslider = true,
                            hide = GUI.compactmode==1,
                            ignoremouse = GUI.compactmode==1,
                            onmousedrag = function() GUI.layers[GUI.custom_layerset].scrollval = GUI.buttons.settings_scroll.val end
                            }
                            
                            
      GUI.layers[GUI.custom_layerset].a=1
      GUI.layers[GUI.custom_layerset].hide = GUI.compactmode==1
      GUI.layers[GUI.custom_layerset].layer_x = GUI.buttons.settingslist.x
      GUI.layers[GUI.custom_layerset].layer_y = GUI.buttons.settingslist.y
      GUI.layers[GUI.custom_layerset].layer_yshift = 0
      GUI.layers[GUI.custom_layerset].layer_w = GUI.buttons.settingslist.w+1
      GUI.layers[GUI.custom_layerset].layer_h = GUI.buttons.settingslist.h
      if GUI.compactmode==0 then GUI.layers[GUI.custom_layerset].layer_hmeasured = GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) end
 
      GUI_initdata(GUI)
      
    
    for but in pairs(GUI.buttons) do GUI.buttons[but].key = but end
  end
  ---------------------------------------------------------------------  
  function GUI_initdata(GUI) 
    local cntdub = 0
    if DATA2.dubdata then cntdub  = #DATA2.dubdata end
    local cnt_data = cntdub + 1
    local data_h_t = GUI.custom_datah / cnt_data
    local data_h_t_mod = data_h_t -2 
    
    -- reference data
      local layerref= 22
      local val_data,  val_data_adv , val_data_adv2
      if DATA2.refdata then
        if DATA2.refdata.data then val_data= DATA2.refdata.data  end
        if DATA2.refdata.data_points then val_data_adv= DATA2.refdata.data_points end
      end 
      GUI.buttons.refdata = { x=0, -- link to GUI.buttons.getreference
                            y=0,
                            w=GUI.custom_spectralw ,
                            h=data_h_t_mod,
                            ignoremouse = true,
                            val_data = val_data,
                            val_data_adv = val_data_adv,
                            layer = layerref,
                            hide = GUI.compactmode==1,
                            refresh = true,
                            frame_a = 0
                            } 
      GUI:quantizeXYWH(GUI.buttons.refdata)
      if not GUI.layers[layerref] then GUI.layers[layerref] = {} end
      GUI.layers[layerref].a=1
      GUI.layers[layerref].hide = GUI.compactmode==1
      GUI.layers[layerref].layer_x = GUI.custom_offset
      GUI.layers[layerref].layer_y = GUI.custom_offset*2+GUI.custom_mainbuth
      GUI.layers[layerref].layer_w = GUI.buttons.refdata.w+1
      GUI.layers[layerref].layer_h = GUI.custom_datah
      GUI.layers[layerref].layer_yshift = 0
    
    -- dub data
      if not DATA2.dubdata then return end
      for i = 1, 1000 do GUI.buttons['dubdata'..i] = nil end
      for i = 1, #DATA2.dubdata do
        local dubdata = DATA2.dubdata[i]
        local val_data, val_data_adv, val_data_adv2,data_pointsSRCDEST
        if dubdata.data then val_data= dubdata.data end
        if dubdata.data_points then val_data_adv= dubdata.data_points end
        if dubdata.data_points_match then val_data_adv2= dubdata.data_points_match end
        if dubdata.data_pointsSRCDEST then data_pointsSRCDEST= dubdata.data_pointsSRCDEST end
          
        GUI.buttons['dubdata'..i] = { x=0, -- link to GUI.buttons.getreference
                                  y=data_h_t*i,
                                  w=GUI.custom_spectralw ,
                                  h=data_h_t_mod,
                                  ignoremouse = true,
                                  val_data = val_data,
                                  val_data_adv = val_data_adv,
                                  val_data_adv2 = val_data_adv2,
                                  val_data_com = data_pointsSRCDEST,
                                  layer = layerref,
                                  hide = GUI.compactmode==1,
                                  refresh = true,
                                  frame_a = 0
                                  }  
      end
  end
  ---------------------------------------------------------------------  
  function GUI_settingst(GUI, DATA, boundaryobj, scrollobj) 
  
    local function GUI_settingst_confirmval(GUI, DATA, key,txt,confkey, val, major_confirm, ignoreCONF_appatchange) 
      if key and GUI.buttons[key] then GUI.buttons[key].txt = txt GUI.buttons[key].refresh = true  end
      if confkey then DATA.extstate[confkey] = val end 
      boundaryobj.refresh = true 
      if major_confirm then 
        GUI:generatelisttable( GUI_settingst(GUI, DATA, boundaryobj) )
        DATA.UPD.onconfchange = true
        boundaryobj.refresh = true 
        if DATA.extstate.CONF_appatchange&1==1 and not ignoreCONF_appatchange then 
          DATA2:GetRefAudioData()
          DATA2:GetDubAudioData(true)
        end
      end
    end
    
    
    --CONF_post_strmarkfdsize
    --
    -- get true window
      local wind = DATA2:gettruewindow()
    -- get pitch shift mode
      local pitch_shift_t = {
        {str = '[default]', func = function()  local val = -1 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_pshift', val,true, nil  ) end, true}  }
      local pshift_txt = '[default]'  
      for mode=0, 32 do
        local retval, modename = reaper.EnumPitchShiftModes( mode )
        if mode == DATA.extstate.CONF_post_pshift then pshift_txt = modename end
        if retval and modename and modename ~= '' then pitch_shift_t[#pitch_shift_t+1] = {str = modename, func = function()  local val = mode GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_pshift', val,true, nil  ) end, true}   end
      end
    -- get pitch shift sub mode
      local pitch_shift_tsub = {
        {str = '[default]', func = function()  local val = -1 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_pshiftsub', val,true, nil  ) end, true}  }
      local pshiftsub_txt = '[default]'  
      local mode = 0
      if DATA.extstate.CONF_post_pshift >=0 then mode = DATA.extstate.CONF_post_pshift end
      for submode=0, 32 do
        local modename = EnumPitchShiftSubModes( mode, submode )
        if submode == DATA.extstate.CONF_post_pshiftsub then pshiftsub_txt = modename end
        if modename and modename ~= '' then pitch_shift_tsub[#pitch_shift_tsub+1] = {str = modename, func = function()  local val = submode GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_pshiftsub', val,true, nil  ) end, true} end
      end    
    -- form sm mod table
      local smmode = {
        {str = 'default', TEMPval = 0,  func = function()  local val = 0 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_smmode', val,true, nil  ) end, true}  ,       
        {str = 'Balanced',  TEMPval = 1,  func = function()  local val = 1 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_smmode', val,true, nil  ) end, true}  ,                      
        {str = 'Tonal optimized',  TEMPval = 2,  func = function()  local val = 2 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_smmode', val,true, nil  ) end, true}  ,  
        {str = 'Transient optimized',  TEMPval = 4,  func = function()  local val = 4 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_smmode', val,true, nil  ) end, true }  ,   
        {str = 'No pre echo reduction',  TEMPval = 5,  func = function()  local val = 5 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_post_smmode', val,true, nil  ) end, true } 
                              }
            
      local smmode_txt = ''
      for i = 1, #smmode do
        if smmode[i].TEMPval ==  DATA.extstate.CONF_post_smmode then smmode_txt = smmode[i].str end
      end
      
      
    local  t = 
    {
      { str = 'Global' ,
        issep = true
      }, 
      { str = 'Get reference take at initialization',
        level = 1,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_initflags', DATA.extstate.CONF_initflags~1 , true, true )  end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_initflags') GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_initflags', DATA.extstate.CONF_initflags~1 , true, true )  end,                          
        ischeck = true,
        state = DATA.extstate.CONF_initflags&1==1,
      },
      { str = 'Get dub take at initialization',
        level = 1,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_initflags', DATA.extstate.CONF_initflags~2, true, true   ) end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_initflags')  GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_initflags', DATA.extstate.CONF_initflags~2, true, true   ) end,                          
        ischeck = true,
        state = DATA.extstate.CONF_initflags&2==2,
      },            
      { str = 'Apply settings at config change',
        level = 1,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_appatchange', DATA.extstate.CONF_appatchange~1, true, true   ) end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_initflags')  GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_appatchange', DATA.extstate.CONF_appatchange~1, true, true   ) end,                          
        ischeck = true,
        state = DATA.extstate.CONF_appatchange&1==1,
      },     
      { str = 'Clean dub markers at initialization',
         level = 1,
         onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_cleanmarkdub', DATA.extstate.CONF_cleanmarkdub~1, true, true   ) end, 
         onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_cleanmarkdub') GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_cleanmarkdub', DATA.extstate.CONF_cleanmarkdub~1, true, true   ) end, 
         ischeck = true,
         state = DATA.extstate.CONF_cleanmarkdub&1==1,
       },   
      { str = 'Obey time selection',
         level = 1,
         onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_obtimesel', DATA.extstate.CONF_obtimesel~1, true, true   ) end, 
         onmousereleaseR = function() DATA:ExtStateRestoreDefaults(CONF_obtimesel) GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_obtimesel', DATA.extstate.CONF_obtimesel~1, true, true   ) end, 
         ischeck = true,
         state = DATA.extstate.CONF_obtimesel&1==1,
         active = VF_isregist&2==2,
         ignoremouse = VF_isregist&2~=2,
       },  
      { str = 'Enable shortcuts',
         level = 1,
         onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_enableshortcuts', DATA.extstate.CONF_enableshortcuts~1, true, true   ) end, 
         onmousereleaseR = function() DATA:ExtStateRestoreDefaults(CONF_enableshortcuts) GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_enableshortcuts', DATA.extstate.CONF_enableshortcuts~1, true, true   ) end, 
         ischeck = true,
         state = DATA.extstate.CONF_enableshortcuts&1==1,
       },   
      { str = 'Init UI at mouse position',
         level = 1,
         onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_initatmousepos', DATA.extstate.CONF_initatmousepos~1, true, true   ) end, 
         onmousereleaseR = function() DATA:ExtStateRestoreDefaults(CONF_initatmousepos) GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_initatmousepos', DATA.extstate.CONF_initatmousepos~1, true, true   ) end, 
         ischeck = true,
         state = DATA.extstate.CONF_initatmousepos&1==1,
       },         
       
      {str = 'Audio data',
       issep = true
      }, 
      { customkey = 'settings_bsf1',
        str = 'BandSplitter Freq 1',
        level = 1,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_audio_bs_f1, 20, DATA.extstate.CONF_audio_bs_f2),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_audio_bs_f1..'Hz',
        onmousedrag = function() 
                        local min = 20
                        local max = DATA.extstate.CONF_audio_bs_f2
                        local Fout = VF_NormToFormatValue(GUI.buttons['settings_bsf1val'].val,min,max,-1)
                        GUI_settingst_confirmval(GUI, DATA, 'settings_bsf1val',Fout ..'Hz', 'CONF_audio_bs_f1', Fout, nil, nil  )
                      end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_audio_bs_f1') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      },     
      { customkey = 'settings_bsf2',
        str = 'BandSplitter Freq 2',
        level = 1,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_audio_bs_f2, DATA.extstate.CONF_audio_bs_f1, DATA.extstate.CONF_audio_bs_f3),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_audio_bs_f2..'Hz',
        onmousedrag = function() 
                        local min = DATA.extstate.CONF_audio_bs_f1
                        local max = DATA.extstate.CONF_audio_bs_f3
                        local Fout = VF_NormToFormatValue(GUI.buttons['settings_bsf2val'].val,min,max,-1)
                        GUI_settingst_confirmval(GUI, DATA, 'settings_bsf2val',Fout ..'Hz', 'CONF_audio_bs_f2', Fout, nil, nil  )
                      end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_audio_bs_f2') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      },   
      { customkey = 'settings_bsf3',
        str = 'BandSplitter Freq 3',
        level = 1,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_audio_bs_f3, DATA.extstate.CONF_audio_bs_f2, 10000),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_audio_bs_f3..'Hz',
        onmousedrag = function() 
                        local min = DATA.extstate.CONF_audio_bs_f2
                        local max = 10000
                        local Fout = VF_NormToFormatValue(GUI.buttons['settings_bsf3val'].val,min,max,-1)
                        GUI_settingst_confirmval(GUI, DATA, 'settings_bsf3val',Fout ..'Hz', 'CONF_audio_bs_f3', Fout, nil, nil  )
                      end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_audio_bs_f3') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      },  
      { customkey = 'settings_bsa1',
        str = 'BandSplitter Band 1',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_audio_bs_a1,
        val_res = 0.1,
        valtxt =  VF_NormToFormatValue(DATA.extstate.CONF_audio_bs_a1, 0,100)..'%',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_bsa1val',VF_NormToFormatValue(GUI.buttons['settings_bsa1val'].val, 0,100)..'%', 'CONF_audio_bs_a1', GUI.buttons['settings_bsa1val'].val, nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_audio_bs_a1') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },   
      { customkey = 'settings_bsa2',
        str = 'BandSplitter Band 2',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_audio_bs_a2,
        val_res = 0.1,
        valtxt =  VF_NormToFormatValue(DATA.extstate.CONF_audio_bs_a2, 0,100)..'%',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_bsa2val',VF_NormToFormatValue(GUI.buttons['settings_bsa2val'].val, 0,100)..'%', 'CONF_audio_bs_a2', GUI.buttons['settings_bsa2val'].val, nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_audio_bs_a2') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },     
      { customkey = 'settings_bsa3',
        str = 'BandSplitter Band 3',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_audio_bs_a3,
        val_res = 0.1,
        valtxt =  VF_NormToFormatValue(DATA.extstate.CONF_audio_bs_a3, 0,100)..'%',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_bsa3val',VF_NormToFormatValue(GUI.buttons['settings_bsa3val'].val, 0,100)..'%', 'CONF_audio_bs_a3', GUI.buttons['settings_bsa3val'].val , nil, nil ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function()DATA:ExtStateRestoreDefaults('CONF_audio_bs_a3')  GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },      
      { customkey = 'settings_bsa4',
        str = 'BandSplitter Band 4',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_audio_bs_a4,
        val_res = 0.1,
        valtxt =  VF_NormToFormatValue(DATA.extstate.CONF_audio_bs_a4, 0,100)..'%',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_bsa4val',VF_NormToFormatValue(GUI.buttons['settings_bsa4val'].val, 0,100)..'%', 'CONF_audio_bs_a4', GUI.buttons['settings_bsa4val'].val, nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_audio_bs_a4') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },     
      { customkey = 'settings_aulimit',
        str = 'Limit',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_audio_lim,
        val_res = 0.1,
        valtxt =  VF_NormToFormatValue(DATA.extstate.CONF_audio_lim, 0,100)..'%',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_aulimitval',VF_NormToFormatValue(GUI.buttons['settings_aulimitval'].val, 0,100)..'%', 'CONF_audio_lim', GUI.buttons['settings_aulimitval'].val, nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_audio_lim') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },      
       
      
      {str = 'Peak follower',
       issep = true
      },       
      { customkey = 'settings_wind',
        str = 'Window',
        level = 1,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_window, 0.01, 0.4),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_window..'s',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_windval',VF_NormToFormatValue(GUI.buttons['settings_windval'].val, 0.01, 0.4, 3)..'s' , 'CONF_window', VF_NormToFormatValue(GUI.buttons['settings_windval'].val, 0.01, 0.4, 3), nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_window') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },
      { str = 'Overlap divider',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_window_overlap,
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_window_overlap,
        menu = {
                  {str = '1', func = function()  local val = 1 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_window_overlap', val,true, nil  ) end}  ,                      
                  {str = '2', func = function()  local val = 2 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_window_overlap', val,true, nil  ) end }  ,                      
                  {str = '4', func = function()  local val = 4 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_window_overlap', val,true, nil  ) end }  ,                      
                  {str = '8', func = function()  local val = 8 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_window_overlap', val,true, nil  ) end }  ,   
                },
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_window_overlap') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      },  
      { customkey = 'settings_audiodosqrt',
        str = 'val^y (scaling)',
        level = 1,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_audiodosquareroot, 0.1, 2, 1),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_audiodosquareroot,
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_audiodosqrtval',   
        VF_NormToFormatValue(GUI.buttons['settings_audiodosqrtval'].val, 0.1, 2, 1), 
        'CONF_audiodosquareroot', 
        VF_NormToFormatValue(GUI.buttons['settings_audiodosqrtval'].val, 0.1, 2, 1)
        ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_audiodosquareroot') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      }, 
      { str = 'Smooth envelope',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_smooth,
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_smooth..'x',
        menu = {
                  {str = '0x', func = function()  local val = 0 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_smooth', val,true, nil  ) end, true}  ,       
                  {str = '1x', func = function()  local val = 1 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_smooth', val,true, nil  ) end, true}  ,                      
                  {str = '2x', func = function()  local val = 2 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_smooth', val,true, nil  ) end, true}  ,                      
                  {str = '4x', func = function()  local val = 4 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_smooth', val,true, nil  ) end, true }  ,                      
                  {str = '8x', func = function()  local val = 8 GUI_settingst_confirmval(GUI, DATA, nil,nil, 'CONF_smooth', val,true, nil  ) end, true }  ,   
                },
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_smooth') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      },  
      { str = 'Compensate overlap / Reduce points',
        level = 1,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_compensateoverlap', DATA.extstate.CONF_compensateoverlap~1 , true, nil )  end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_compensateoverlap') GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_compensateoverlap', DATA.extstate.CONF_compensateoverlap~1 , true, nil )  end,                          
        ischeck = true,
        state = DATA.extstate.CONF_compensateoverlap&1==1,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      }, 
      
      
      {str = 'Source markers generator',
       txt_col = GUI.default_data_col_adv,
       issep = true
      },
      { str = 'Set at envelope fall',
        level = 1,
        txt_col = GUI.default_data_col_adv,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_markgen_enveloperisefall', 1 , true, nil )  end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_markgen_enveloperisefall') GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_markgen_enveloperisefall', 1 , true, nil )  end,                          
        ischeck = true,
        state = DATA.extstate.CONF_markgen_enveloperisefall==1,
      },
      { str = 'Set at envelope rise',
        level = 1,
        txt_col = GUI.default_data_col_adv,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_markgen_enveloperisefall', 2 , true, nil )  end,                
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_markgen_enveloperisefall') GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_markgen_enveloperisefall', 2 , true, nil )  end,                
        ischeck = true,
        state = DATA.extstate.CONF_markgen_enveloperisefall==2,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      }, 
      { customkey = 'settings_mark_block',
        str = 'Minimum points distance',
        level = 1,
        txt_col = GUI.default_data_col_adv,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_markgen_filterpoints, 5, 30, -1),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_markgen_filterpoints*wind..'s',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_mark_blockval',DATA.extstate.CONF_markgen_filterpoints*wind..'s' , 'CONF_markgen_filterpoints', VF_NormToFormatValue(GUI.buttons['settings_mark_blockval'].val, 5, 30, -1), nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_markgen_filterpoints') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      }, 
      { customkey = 'settings_mark_blockRMS',
        str = 'area_RMS length',
        txt_col = GUI.default_data_col_adv,
        level = 1,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_markgen_RMSpoints, 5, 30, -1),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_markgen_RMSpoints*wind..'s',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_mark_blockRMSval',DATA.extstate.CONF_markgen_RMSpoints*wind..'s' , 'CONF_markgen_RMSpoints', VF_NormToFormatValue(GUI.buttons['settings_mark_blockRMSval'].val, 5, 30, -1), nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_markgen_RMSpoints') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },       
      
      
      { customkey = 'settings_arearms',
        str = 'minimum of [value/abs(area_RMS-value)]',
        level = 1,
        txt_col = GUI.default_data_col_adv,
        isvalue = true,
        val = DATA.extstate.CONF_markgen_minimalareaRMS,
        val_res = 0.1,
        valtxt =  VF_NormToFormatValue(DATA.extstate.CONF_markgen_minimalareaRMS, 0,50)..'%',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_arearmsval',VF_NormToFormatValue(GUI.buttons['settings_arearmsval'].val, 0,50)..'%', 'CONF_markgen_minimalareaRMS', GUI.buttons['settings_arearmsval'].val, nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_markgen_minimalareaRMS') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      }, 
      { customkey = 'settings_levthres',
        str = 'Level threshold',
        level = 1,
        isvalue = true,
        txt_col = GUI.default_data_col_adv,
        val = DATA.extstate.CONF_markgen_threshold,
        val_res = 0.1,
        valtxt =  VF_NormToFormatValue(DATA.extstate.CONF_markgen_threshold, 0,100)..'%',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_levthresval',VF_NormToFormatValue(GUI.buttons['settings_levthresval'].val, 0,100)..'%', 'CONF_markgen_threshold', GUI.buttons['settings_levthresval'].val, nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_markgen_threshold') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      },   
      
      
      
      {str = 'Audio match algorithm',
      txt_col = GUI.default_data_col_adv2,
       issep = true
      },
      { customkey = 'settings_algosearch',
        str = 'Brutforce search area',
        level = 1,
        txt_col = GUI.default_data_col_adv2,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_match_blockarea, 1, 50, -1),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_match_blockarea*wind..'s',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_algosearchval',DATA.extstate.CONF_match_blockarea *wind..'s', 'CONF_match_blockarea', VF_NormToFormatValue(GUI.buttons['settings_algosearchval'].val, 1, 50, -1), nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_match_blockarea') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },    
      { str = 'Stretch dub array on the fly',
        level = 1,
        txt_col = GUI.default_data_col_adv2,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_match_stretchdubarray', 1 , true, nil )  end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_match_stretchdubarray') GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_match_stretchdubarray', 1 , true, nil )  end,                          
        ischeck = true,
        state = DATA.extstate.CONF_match_stretchdubarray==1,
      },          
      { str = 'Ignore zero values difference check',
        level = 1,
        txt_col = GUI.default_data_col_adv2,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_match_ignorezeros', 1 , true, nil )  end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_match_ignorezeros') GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_match_ignorezeros', 1 , true, nil )  end,                          
        ischeck = true,
        state = DATA.extstate.CONF_match_ignorezeros==1,
      },      
      
      
      {str = 'Take output',
       issep = true
      },  
      { str = 'Pitch shift mode',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_post_pshift,
        valtxt =  pshift_txt,
        valtxtw_mult = 8,
        menu = { table.unpack( pitch_shift_t )}, 
       },
       { str = 'Pitch shift submode',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_post_pshiftsub,
        valtxt =  pshiftsub_txt,
        valtxtw_mult = 8,
        menu = { table.unpack( pitch_shift_tsub )}, 
       },
      { str = 'Stretch marker mode',
        level = 1,
        isvalue = true,
        val_res = 0.1,
        valtxt =  smmode_txt,
        valtxtw_mult = 8,
        menu = {table.unpack(smmode)},
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_post_smmode') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        
      },       
      { customkey = 'settings_postmarksz',
        str = 'Stretch marker fade size',
        level = 1,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_post_strmarkfdsize, 0.0025, 0.05),
        val_res = 0.05,
        valtxt =  DATA.extstate.CONF_post_strmarkfdsize..'s',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_postmarkszval',VF_NormToFormatValue(GUI.buttons['settings_postmarkszval'].val, 0.0025, 0.05, 4)..'s' , 'CONF_post_strmarkfdsize', VF_NormToFormatValue(GUI.buttons['settings_postmarkszval'].val,0.0025, 0.05,4), nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_post_strmarkfdsize') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        active = VF_isregist&2==2,
        ignoremouse = VF_isregist&2~=2,
      }, 
      { str = 'Add 0 pos marker',
        level = 1,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_post_pos0mark', DATA.extstate.CONF_post_pos0mark~1, true, nil )  end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_post_pos0mark') GUI_settingst_confirmval(GUI, DATA, nil,nil,'CONF_post_pos0mark', DATA.extstate.CONF_post_pos0mark~1 , true, nil )  end,                          
        ischeck = true,
        state = DATA.extstate.CONF_post_pos0mark==1,
      },
      
 
    }
    
    return 
    {
    t=t, 
    boundaryobj = boundaryobj,
    tablename = 'settings',
    layer = boundaryobj.layer,
    scrollobj = scrollobj
    }
    
  end
  ---------------------------------------------------------------------
  function DATA2:GetAudioData_BandSplit(buf, srate) -- 4-Band Splitter ported from JSFX -- desc:4-Band Splitter
    local sz = #buf--.get_alloc()
    local extstate = DATA.extstate or {}
    
    -- frequency 
    local slider1 = extstate.CONF_audio_bs_f1 or 200
    local slider2 = extstate.CONF_audio_bs_f2 or 2000
    local slider3 = extstate.CONF_audio_bs_f3 or 5000
    
    -- init
    local cDenorm=10^-30;
    
    local freqHI = math.max(math.min(slider3,srate),slider2);
    local xHI = math.exp(-2.0*math.pi*freqHI/srate);
    local a0HI = 1.0-xHI;
    local b1HI = -xHI;
    
    local freqMID = math.max(math.min(math.min(slider2,srate),slider3),slider1);
    local xMID = math.exp(-2.0*math.pi*freqMID/srate);
    local a0MID = 1.0-xMID;
    local b1MID = -xMID;
    
    local freqLOW = math.min(math.min(slider1,srate),slider2);
    local xLOW = math.exp(-2.0*math.pi*freqLOW/srate);
    local a0LOW = 1.0-xLOW;
    local b1LOW = -xLOW;
    
    local tmplMID = 0
    local tmplLOW = 0
    local tmplHI = 0 
    local low0,hi0,spl0,spl2,spl4,spl6, s0
    
    for i = 1, sz do  
      s0 = buf[i]; 
      tmplMID = a0MID*s0 - b1MID*tmplMID + cDenorm
      low0 = tmplMID; 
      tmplLOW = a0LOW*low0 - b1LOW*tmplLOW + cDenorm
      spl0 = tmplLOW; -- band1 
      spl2 = low0 - spl0; -- band2 
      hi0 = s0 - low0; 
      tmplHI = a0HI*hi0 - b1HI*tmplHI + cDenorm
      spl4 = tmplHI; -- band3 
      spl6 = hi0 - spl4; -- band4
      
      local bandsum = 
        math.abs(spl0) * extstate.CONF_audio_bs_a1 + 
        math.abs(spl2) * extstate.CONF_audio_bs_a2 + 
        math.abs(spl4) * extstate.CONF_audio_bs_a3 + 
        math.abs(spl6) * extstate.CONF_audio_bs_a4
      buf[i] = bandsum
      
    end
    
  end
  ---------------------------------------------------------------------
  function DATA2:GetAudioData_GetTable(parent_track, edge_start, edge_end) 
    -- init 
      local accessor = CreateTrackAudioAccessor( parent_track )
      local data = {}
      local id = 0
      local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
      local window_sec = DATA.extstate.CONF_window
      local bufsz = math.ceil(window_sec * SR_spls)
    -- loop stuff 
      local overlap = DATA.extstate.CONF_window_overlap
      for pos = edge_start, edge_end, window_sec/overlap do 
        local samplebuffer = new_array(bufsz);
        GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
        local samplebuffer_t = samplebuffer.table()
        samplebuffer.clear()
        DATA2:GetAudioData_BandSplit(samplebuffer_t, SR_spls)
        local sum = 0 for i = 1, bufsz do sum = sum + math.abs(samplebuffer_t[i]) end
        
        id = id + 1
        data[id] = sum / bufsz
      end
      DestroyAudioAccessor( accessor )
      
      local max_val = 0
      for i = 1, #data do data[i] = math.abs(data[i]) max_val = math.max(max_val, data[i]) end -- abs all values
      for i = 1, #data do data[i] = math.min(DATA.extstate.CONF_audio_lim, data[i] /DATA.extstate.CONF_audio_lim) end -- limit 
      for i = 1, #data do data[i] = (data[i]/max_val) ^DATA.extstate.CONF_audiodosquareroot end -- normalize  / scale
      
      
      local lastval = 0
      for smooth = 1, DATA.extstate.CONF_smooth do
        for i = 1, #data do  
          data[i] = (lastval + data[i] ) /2
          lastval = data[i]
        end
      end
      
      local reduceddata = {}
      for i = 1, #data do if i%overlap == 1 then reduceddata[#reduceddata+1] = data[i] end end
      if DATA.extstate.CONF_compensateoverlap==1 and overlap ~= 1 then return reduceddata else return data end
  end 
  ---------------------------------------------------------------------
  function DATA2:CleanDubMarkers(take, edge_start,edge_end, item, item_pos, takerate) 
    if not take then return end
    local approx = 10^-12
    SetTakeStretchMarker( take, -1, takerate* (edge_start-item_pos) )
    SetTakeStretchMarker( take, -1, takerate* (edge_end-item_pos ) )
    for idx =  GetTakeNumStretchMarkers( take ), 1, -1 do
      local retval, pos, srcpos = GetTakeStretchMarker( take, idx-1 )
      if pos*takerate+item_pos>edge_start+approx and pos*takerate+item_pos < edge_end-approx then DeleteTakeStretchMarkers( take, idx-1 ) end
    end
    UpdateItemInProject( item )
  end
  ---------------------------------------------------------------------
  function DATA2:GetDubAudioData(takefromsecondtake)
    if not DATA2.refdata then return end
    local reftrack = VF_GetTrackByGUID(DATA2.refdata.parent_trackGUID) 
    if not reftrack then return end
    DATA2.dubdata = {}
    
    local dubdataId = 1
    local st = 1
    if takefromsecondtake == true then st = 2 end
    for i = st, CountSelectedMediaItems( 0 ) do
      local item = GetSelectedMediaItem(0,i-1)
      local take = GetActiveTake(item)
      if TakeIsMIDI(take) then  goto skipnextdub end 
      local parent_track = GetMediaItem_Track( item ) 
      if parent_track == reftrack then goto skipnextdub end 
      if not take or (take and TakeIsMIDI(take)) then  goto skipnextdub end
      local takeGUID = VF_GetTakeGUID(take)
      local take_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE')
      local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local item_len= GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local src =  GetMediaItemTake_Source( take )
      local item_srclen, lengthIsQN = GetMediaSourceLength( src )
      if DATA.extstate.CONF_cleanmarkdub&1==1 then  DATA2:CleanDubMarkers(take, DATA2.refdata.edge_start, DATA2.refdata.edge_end, item, item_pos, take_rate) end
      
      DATA2.dubdata[dubdataId] = {takeGUID = takeGUID,
                        take = take,
                        item = item,
                        item_pos = item_pos,
                        item_len=item_len,
                        take_rate = take_rate,
                        item_srclen=item_srclen,
                        take_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS')}
      
      DATA2.dubdata[dubdataId].data = DATA2:GetAudioData_GetTable(parent_track, DATA2.refdata.edge_start, DATA2.refdata.edge_end)
      DATA2.dubdata[dubdataId].data = DATA2:GetAudioData_CorrentSource(DATA2.dubdata[dubdataId].data, DATA2.refdata.edge_start, DATA2.refdata.edge_end, item_pos, item_pos+item_len)
      DATA2.dubdata[dubdataId].data_points = DATA2:GeneratePoints(DATA2.dubdata[dubdataId].data)
      DATA2.dubdata[dubdataId].data_points_match, DATA2.dubdata[dubdataId].data_pointsSRCDEST = DATA2:ApplyMatch(DATA2.dubdata[dubdataId]) 
      dubdataId = dubdataId + 1
      ::skipnextdub::
    end
    
    
    GUI_initdata(GUI) 
  end
  ---------------------------------------------------------------------
  function DATA2:GetAudioData_CorrentSource(t, edge_start, edge_end, item_pos, item_end)
    local ovlap = DATA.extstate.CONF_window_overlap
    if DATA.extstate.CONF_compensateoverlap==1 and overlap ~= 1 then ovlap = 1 end
    local sz = #t
    local blockms =  DATA.extstate.CONF_window/ovlap
    local blockdestroy_start = -1
    local blockdestroy_end =sz+1
    if item_pos> edge_start then blockdestroy_start = (item_pos - edge_start) / blockms end
    if item_end< edge_end then blockdestroy_end = sz - (edge_end - item_end) / blockms end
    for i = 1, sz do 
      if i < blockdestroy_start then t[i] = 0 end
      if i > blockdestroy_end then t[i] = 0 end
    end
    return t
  end
  ---------------------------------------------------------------------
  function DATA2:GetRefAudioData()
    local parent_track
    local edge_start,edge_end = math.huge, 0
    for i = 1, CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem(0,i-1)
      local take = GetActiveTake(item)
      if not take or TakeIsMIDI(take) then goto skipnextref end 
      local track = GetMediaItem_Track( item ) 
      if not parent_track then parent_track = track end
      if parent_track and parent_track ==  track then
        local pos =  reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
        local len =  reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
        edge_start = math.min(pos,edge_start)
        edge_end = math.max(pos+len,edge_end)
      end
      ::skipnextref::
    end
    
    if DATA.extstate.CONF_obtimesel == 1 then edge_start,edge_end = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false ) end
    if not parent_track or edge_start > edge_end then return end 
    
    DATA2.refdata = {}
    DATA2.refdata.data = DATA2:GetAudioData_GetTable(parent_track, edge_start, edge_end)
    DATA2.refdata.parent_trackGUID = GetTrackGUID(parent_track)
    DATA2.refdata.edge_start = edge_start
    DATA2.refdata.edge_end = edge_end
    
    GUI_initdata(GUI)
    
  end
  ---------------------------------------------------------------------
  function DATA2:GeneratePoints(t0)
    local t = {}
    local block_area = DATA.extstate.CONF_markgen_filterpoints 
    local block_RMSarea = DATA.extstate.CONF_markgen_RMSpoints 
    -- get src points
      for i = 1,#t0 do 
        t[i] = 0
        local prev_val = t0[i-1]
        local curr_val = t0[i]
        local next_val = t0[i+1]
        if prev_val and next_val and (   (DATA.extstate.CONF_markgen_enveloperisefall==1 and curr_val<prev_val and next_val>curr_val)  or  (DATA.extstate.CONF_markgen_enveloperisefall==2 and curr_val>prev_val and next_val<curr_val)    ) then t[i] = 1 end
      end
    
    -- filter closer points
      local last_pointID = 0
      for i = 1, #t do
        if t[i] == 1 then
          local last_pointID_fol = i
          if i - last_pointID < block_area then 
            if t0[i] and t0[last_pointID] then 
              if (t0[i] < t0[last_pointID] and DATA.extstate.CONF_markgen_enveloperisefall==1) or (t0[i] > t0[last_pointID] and DATA.extstate.CONF_markgen_enveloperisefall==2) then 
                t[last_pointID] = 0 
                last_pointID_fol = i
               else
                t[i] = 0 
                last_pointID_fol = last_pointID
              end  
            end
          end
          last_pointID = last_pointID_fol
        end
      end
    
    -- how deep/high point in block_area
    for i = 1, #t do
      if t[i] == 1 then
        local rms = 0
        local cnt = 0
        local min_area = i-block_RMSarea
        local max_area = i+block_RMSarea
        for j = min_area,max_area do
          if t0[j] then 
            cnt = cnt + 1
            rms = rms + t0[j]
          end 
        end
        rms = rms / cnt
        local extremum_diff_ratio = t0[i] / math.abs(rms - t0[i]) 
        if t0[i] > math.abs(rms - t0[i]) then extremum_diff_ratio = math.abs(rms - t0[i]) / t0[i] end
        if extremum_diff_ratio < DATA.extstate.CONF_markgen_minimalareaRMS then t[i] = 0 end
      end
    end
    
    -- level filter
    for i = 1, #t do
      if t[i] == 1 then    
        if t0[i] > DATA.extstate.CONF_markgen_threshold then t[i] = 0 end
      end
    end
    
    return t
  end    
  ---------------------------------------------------------------------
  function DATA2:ApplyMatch_GetTableDifference(t1,t2,block_st,block_end) 
    local diff = 0 
    for block = block_st, block_end do  
      if t1[block] and t2[block] then
        if DATA.extstate.CONF_match_ignorezeros == 1 or (DATA.extstate.CONF_match_ignorezeros == 0 and t1[block] ~= 0 and t2[block] ~= 0) then
          diff = diff + math.abs(t1[block]-t2[block]) 
        end
      end
    end 
    return diff 
  end
  ---------------------------------------------------------------------
  function DATA2:ApplyMatch_Find(t1,t2,block_st,block_src,block_end)
    if not (block_st and block_src and block_end) then return block_src end
    local block_search = DATA.extstate.CONF_match_blockarea
    
    -- init edges for searches
       local block_mid_search_min = math.max(block_st + 1, block_src - block_search)
       local block_mid_search_max = math.min(block_end - 1, block_src + block_search) 
    
    -- loop through difference block
      local refdub_diffence = math.huge
      local bestblock
      for midblock = block_mid_search_min, block_mid_search_max do
        local t2_stretched = DATA2:ApplyMatch_StretchT(t2, block_st, block_end, block_src, midblock) 
        local tablediff = DATA2:ApplyMatch_GetTableDifference(t1,t2_stretched,block_st,block_end)
        if tablediff < refdub_diffence then
          bestblock = midblock
          refdub_diffence = tablediff
        end
      end
    
    if bestblock then return bestblock else return block_src end
  end
  ---------------------------------------------------------------------
  function DATA2:ApplyMatch_StretchT(t, block_st, block_end, block_src, block_dest) 
    local tout = {}
    local ratio1 = (block_src - block_st) / (block_dest - block_st)
    local ratio2 = (block_end - block_src) / (block_end - block_dest)
    for i = 1, block_st-1 do tout[i] = t[i] end for i = block_end+1, #t do tout[i] = t[i] end -- copy src table
    for i = block_st, block_end do
      if i <= block_dest then
        local stri = math.min(math.floor(block_st + (i-block_st)*ratio1), block_src)
        tout[i] = t[stri] 
       else
        local stri = block_src + math.floor((i-block_dest+1)*ratio2 )
        tout[i] = t[stri] 
      end
    end 
    return tout
  end
  ---------------------------------------------------------------------
  function DATA2:ApplyMatch(t)
    local t_out = {}
    local t1 = DATA2.refdata.data
    local t2 = t.data
    local t2pts = t.data_points
    
    -- collect src point
    local pointsID = {[1]=1}
    for i = 1, #t2pts do if t2pts[i] == 1 then pointsID[#pointsID+1] = i end end
    pointsID[#pointsID+1] = #t2pts
    
    local pointsID2 = { --[1]     = {src= 1, dest = 1} -- create edges
                        --[t_out] = {src= 1, dest = 1}
                        }
                        
    for i = 2, #pointsID-1 do
      local block_st = pointsID[i-1]
      local block_mid = pointsID[i]
      local block_end = pointsID[i+1]
      pointsID[i] = DATA2:ApplyMatch_Find(t1,t2,block_st,block_mid,block_end)
      pointsID2[#pointsID2 + 1] = {src = block_mid, dest = pointsID[i]}
      if DATA.extstate.CONF_match_stretchdubarray&1==1 then DATA2:ApplyMatch_StretchT(t2, block_st, block_end, block_mid, pointsID[i]) end
    end
    
    table.insert(pointsID2, 1,{src= 1, dest = 1}  ) -- fill start marker
    --table.insert(pointsID2, #pointsID+1, {src= pointsID[#pointsID], dest = pointsID[#pointsID]}  )-- fill end marker
    
    for i = 1, #pointsID do t_out[pointsID[i]] = 1  end -- force output
    for i = 1, #t2pts do if not t_out[i] then t_out[i] = 0 end end
    t_out[1] = 0 t_out[pointsID[#pointsID]] =0 -- clean edges
    return t_out, pointsID2
  end    
      
  -----------------------------------------------------------------------------  
    function GUI_RESERVED_draw_data(GUI, b)
      if not b.val_data then return end
      local x,y,w,h, backgr_col, frame_a, frame_asel, back_sela,val =  
                              b.x or 0,
                              b.y or 0,
                              b.w or 100,
                              b.h or 100,
                              b.backgr_col or '#333333',
                              b.frame_a or GUI.default_framea_normal,
                              b.frame_asel or GUI.default_framea_selected,
                              b.back_sela or GUI.default_back_sela,
                              b.val or 0
  
      x,y,w,h = 
                x*GUI.default_scale,
                y*GUI.default_scale,           
                w*GUI.default_scale,            
                h*GUI.default_scale
      local t = b.val_data
      local t0 = b.val_data_adv
      local t1 = b.val_data_adv2
      local dataw = w/#t
      local datax = 0
      local last_datax,last_datay= datax,y+h
      gfx.x,gfx.y = x, y+h
      
      for i = 1, #t do
        --if t[i] == 0 then goto skipdataentry end
        datax = x+math.floor(dataw * (i-1))
        if last_datax ~= datax then
          local datay = math.floor(y+h-h*t[i])
          gfx.x = gfx.x + 1
          local x0 = gfx.x
          local y0 = gfx.y
          
          if  t and t[i] and t[i] ~= 0 then
            if t[i-1] and t[i-1] == 0 then last_datax = datax end
            GUI:hex2rgb(GUI.default_data_col, true)
            gfx.a = GUI.default_data_a
            gfx.line(last_datax,last_datay-1,datax,datay-1)
            gfx.line(datax,y+h,datax,datay) 
          end 
          
          
          if  t0 and t0[i] and t0[i] ~= 0 then
            GUI:hex2rgb(GUI.default_data_col_adv, true)
            gfx.a = GUI.default_data_a1
            --gfx.line(datax,y0,datax,datay) 
            gfx.rect(datax,y+1,2,h-2,1,1) 
          end 
          
          if  t1 and t1[i] and t1[i] ~= 0 then
            GUI:hex2rgb(GUI.default_data_col_adv2, true)
            gfx.a = GUI.default_data_a2
            --gfx.line(datax,y0,datax,datay)  
            gfx.rect(datax,y+1,2,h-2,1,1) 
          end 
          last_datay = datay
        end
        last_datax= datax
        ::skipdataentry::
      end
      
      GUI:hex2rgb(GUI.default_data_col_adv, true)
      local srcR, srcG, srcB = gfx.r,gfx.g,gfx.b
      GUI:hex2rgb(GUI.default_data_col_adv2, true)
      local destR, destG, destB = gfx.r,gfx.g,gfx.b
      
      gfx.a = 0.2
      if b.val_data_com then 
        local gradt = b.val_data_com
        for i = 1, #gradt do 
          local blmin, blmax, dir = gradt[i].src, gradt[i].dest,- 1
          if gradt[i].src > gradt[i].dest then dir = 1 end
          for block = blmax, blmin, dir/dataw do
            local progress = (block-blmin) / (blmax - blmin)
            datax = x+math.floor(dataw * (block-1))
            gfx.r,gfx.g,gfx.b = srcR + progress * (destR - srcR),
                                srcG + progress * (destG - srcG),
                                srcB + progress * (destB - srcB)
            gfx.rect(datax,y,2,y+h-10,1,1) 
          end
        end
      end
    end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.80) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end
  
