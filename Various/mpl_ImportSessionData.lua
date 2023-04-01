-- @description ImportSessionData
-- @version 2.11
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=233358
-- @about This script allow to import tracks, items, FX etc from defined RPP project file
-- @changelog
--    # support track template
--    # fix parsing track parameters




  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 2.11
    DATA.extstate.extstatesection = 'ImportSessionData'
    DATA.extstate.mb_title = 'Import Session Data'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  800,
                          wind_h =  600,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, -- show/hide setting flags
                          UI_appatchange = 1, 
                          UI_appatinit = 1,
                          UI_matchatsettingsrc = 1,
                          
                          UI_trfilter = '',
                          UI_lastsrcproj = '',
                          
                          -- track params
                          CONF_tr_name = 1,
                          CONF_tr_VOL = 1,
                          CONF_tr_PAN = 1,
                          CONF_tr_FX = 1, -- &2 clear existed
                          CONF_tr_it = 1, -- &2 clear existed &4relink files to full paths --&4 edit cur offs
                          CONF_tr_PHASE = 1,
                          CONF_tr_RECINPUT = 1,
                          CONF_tr_MAINSEND = 1,
                          CONF_tr_CUSTOMCOLOR = 1,
                          CONF_tr_LAYOUTS = 0,
                          CONF_tr_LAYOUTS = 0,
                          CONF_tr_GROUPMEMBERSHIP = 0, 
                          --CONF_tr_SEND = 0,
                          --CONF_tr_FOLDERDEPTH = 1,
                          
                          -- master
                          CONF_head_mast_FX = 0,
                          CONF_head_markers = 0, --&1 mark &2 replace mark &4 reg &8 replace reg &16 edit cur offs
                          CONF_head_tempo = 0,--&2 edit cur offs
                          CONF_head_groupnames = 0,
                          CONF_head_rendconf = 0,
                          
                          -- tr options
                          CONF_resetfoldlevel = 1,
                          CONF_it_buildpeaks = 1,
                          
                          -- match algo
                          CONF_tr_matchmode = 1, -- &1==1 full match
                          
                          --CONF_tr_destset = 0, -- 0 replace if destination is used -- 1 not allow to replace
                          --CONF_tr_importwholechunk = 0, -- 0 import chunk 1 import stuff separately
                          --CONF_importinvisibletracks = 0, 
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
    
    if DATA.extstate.UI_appatinit&1==1 then 
      DATA2:ParseSourceProject(DATA.extstate.UI_lastsrcproj) 
      
      if DATA.extstate.UI_appatinit&2==2 then
        DATA2:Tracks_SetDestination(-1, 0, nil) 
        DATA2:MatchTrack() 
        --GUI_RESERVED_BuildLayer(DATA) 
      end
                                                  
    end
    DATA2:Get_DestProject()
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init_shortcuts(DATA)
    if DATA.extstate.UI_enableshortcuts == 0 then return end
    
    DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    
  end
  --------------------------------------------------------------------  
  function DATA2:Get_DestProject()
    local  retval, projfn = EnumProjects( -1 )
    if projfn =='' then projfn = '[current / untitled]' end
    DATA2.destproj = {}
    DATA2.destproj.fp = projfn 
    DATA2.destproj.TRACK = {}
    local folderlev = 0
    
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local GUID = GetTrackGUID( tr )
      local tr_col =  GetTrackColor( tr )
      local folderd = GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' )
      DATA2.destproj.TRACK[i] = {tr_name =  ({GetTrackName( tr )})[2],
                            GUID = GUID,
                            tr_col=tr_col,
                            folderd=folderd,
                            folderlev=folderlev
                            }
      folderlev = folderlev + folderd                            
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:VisibleCondition(trname)
    return (DATA.extstate.UI_trfilter == '' or not trname or (trname and DATA.extstate.UI_trfilter ~= '' and tostring(trname):lower():match(DATA.extstate.UI_trfilter)))
  end
  ---------------------------------------------------------------------  
  function DATA2:Get_DestProject_ValidateSameSources()    -- clean up source mapping if destination has multiple sources
    dest_GUID_used = {}
    for i= 1, #DATA2.srcproj.TRACK do
      local GUIDsrc=DATA2.srcproj.TRACK[i].GUID 
      if GUIDsrc then
        if DATA2.srcproj.TRACK[i].destmode ==2 and DATA2.srcproj.TRACK[i].dest_track_GUID then 
          if dest_GUID_used[DATA2.srcproj.TRACK[i].dest_track_GUID]  then 
             DATA2.srcproj.TRACK[i].destmode = 0
             DATA2.srcproj.TRACK[i].dest_track_GUID = nil
           else 
            dest_GUID_used[DATA2.srcproj.TRACK[i].dest_track_GUID] = GUIDsrc 
            DATA2.srcproj.TRACK[i].has_source = true
          end
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_DestMenu_Sendlogic(DATA,trid,togglestate) 
    local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA,trid) 
    if cnt_selection <= 1 then
      if not DATA2.srcproj.TRACK[trid].sendlogic_flags then DATA2.srcproj.TRACK[trid].sendlogic_flags = 0 end
      DATA2.srcproj.TRACK[trid].sendlogic_flags = DATA2.srcproj.TRACK[trid].sendlogic_flags~togglestate
      GUI_RESERVED_BuildLayer(DATA)  
     else
      for trid0 = 1, #DATA2.srcproj.TRACK do 
        if DATA2.srcproj.TRACK[trid0].sel_isselected == true then 
          if not DATA2.srcproj.TRACK[trid0].sendlogic_flags then DATA2.srcproj.TRACK[trid0].sendlogic_flags = 0 end
          DATA2.srcproj.TRACK[trid0].sendlogic_flags = DATA2.srcproj.TRACK[trid0].sendlogic_flags~togglestate 
        end 
      end
      GUI_RESERVED_BuildLayer(DATA)  
    end  
  
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_DestMenu(DATA,trid) 
    DATA2:Get_DestProject()
    DATA2:Get_DestProject_ValidateSameSources()   
    
    -- form list of destination tracks
    local tracks = {}
    for i= 1, #DATA2.destproj.TRACK do
      tracks[#tracks+1] = { str='['..i..'] '..DATA2.destproj.TRACK[i].tr_name,
                            hidden = DATA2.destproj.TRACK[i].has_source==true,
                            func = function()  
                                      local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
                                      if cnt_selection <= 1 then
                                        DATA2:Tracks_SetDestination(trid, 2, i) 
                                        DATA2:Get_DestProject_ValidateSameSources()
                                        GUI_RESERVED_BuildLayer(DATA)  
                                       else
                                        for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected then DATA2:Tracks_SetDestination(trid0, 2, i) end end
                                        DATA2:Get_DestProject_ValidateSameSources()
                                        GUI_RESERVED_BuildLayer(DATA)  
                                      end
                                  end
                            }
    end
    return {  
            {str='#Destination modes:'},
            {str='['..DATA.GUI.custom_intname0..']',
              state = DATA2.srcproj.TRACK[trid].destmode == 0 ,
              func =  function() 
                        local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
                        if cnt_selection <= 1 then
                          DATA2:Tracks_SetDestination(trid, 0) 
                          GUI_RESERVED_BuildLayer(DATA)  
                         else
                          for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected then DATA2:Tracks_SetDestination(trid0, 0) end end
                          GUI_RESERVED_BuildLayer(DATA)  
                        end
                      end}   ,
            {str='['..DATA.GUI.custom_intname1..']',
              state = DATA2.srcproj.TRACK[trid].destmode == 1 ,
              func = function() 
                        local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
                        if cnt_selection <= 1 then
                          DATA2:Tracks_SetDestination(trid, 1) 
                          GUI_RESERVED_BuildLayer(DATA)  
                         else
                          for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then DATA2:Tracks_SetDestination(trid0, 1) end end
                          GUI_RESERVED_BuildLayer(DATA)  
                        end
                      end},
            {str='['..DATA.GUI.custom_intname2..']',
              state = DATA2.srcproj.TRACK[trid].destmode == 3 ,
              func = function() 
                        local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
                        if cnt_selection <= 1 then
                          DATA2:Tracks_SetDestination(trid, 3) 
                          DATA2:Get_DestProject_ValidateSameSources()
                          GUI_RESERVED_BuildLayer(DATA)  
                         else
                          for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then DATA2:Tracks_SetDestination(trid0, 3) end end
                          DATA2:Get_DestProject_ValidateSameSources()
                          GUI_RESERVED_BuildLayer(DATA)  
                        end
                      end},                      
            {str='Match by name',
              state = DATA2.srcproj.TRACK[trid].destmode == 2 and DATA2.srcproj.TRACK[trid].destmode_flags ~= 3,
              func = function() 
                        local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
                        if cnt_selection <= 1 then
                          DATA2:MatchTrack(trid) 
                          DATA2:Get_DestProject_ValidateSameSources()
                          GUI_RESERVED_BuildLayer(DATA)  
                         else
                          for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then DATA2:MatchTrack(trid0)  end end
                          DATA2:Get_DestProject_ValidateSameSources()
                          GUI_RESERVED_BuildLayer(DATA)  
                        end
                      end},  
            {str='Do not import, only mark for sends remap|',
              state = DATA2.srcproj.TRACK[trid].destmode_flags == 3 ,
              func = function() 
                        local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
                        if cnt_selection <= 1 then
                          DATA2.srcproj.TRACK[trid].destmode_flags = 3
                          GUI_RESERVED_BuildLayer(DATA)  
                         else
                          for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then 
                            DATA2.srcproj.TRACK[trid0].destmode_flags = 3
                          end end
                          GUI_RESERVED_BuildLayer(DATA)  
                        end
                      end},                       
            {str='#Matched track placement'},
            {str='Replace',
              state = not DATA2.srcproj.TRACK[trid].destmode_flags,
              func = function() 
                        local setstate = nil
                        if DATA2.srcproj.TRACK[trid].destmode_flags then setstate = nil end 
                        local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA,trid) 
                        if cnt_selection <= 1 then
                          DATA2.srcproj.TRACK[trid].destmode_flags = setstate
                          GUI_RESERVED_BuildLayer(DATA)  
                         else
                          for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then DATA2.srcproj.TRACK[trid0].destmode_flags = setstate end end
                          GUI_RESERVED_BuildLayer(DATA)  
                        end
                      end},             
            {str='Place under matched track',
              state = DATA2.srcproj.TRACK[trid].destmode_flags == 1,
              func = function() 
                        local setstate = 1
                        if DATA2.srcproj.TRACK[trid].destmode_flags and DATA2.srcproj.TRACK[trid].destmode_flags&1 == 1 then setstate = nil end 
                        local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA,trid) 
                        if cnt_selection <= 1 then
                          DATA2.srcproj.TRACK[trid].destmode_flags = setstate
                          GUI_RESERVED_BuildLayer(DATA)  
                         else
                          for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then DATA2.srcproj.TRACK[trid0].destmode_flags = setstate end end
                          GUI_RESERVED_BuildLayer(DATA)  
                        end
                      end}, 
            {str='Place under matched track as child|',
              state = DATA2.srcproj.TRACK[trid].destmode_flags == 2,
              func = function() 
                        local setstate = 2
                        if DATA2.srcproj.TRACK[trid].destmode_flags and DATA2.srcproj.TRACK[trid].destmode_flags == 2 then setstate = nil end 
                        local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA,trid) 
                        if cnt_selection <= 1 then
                          DATA2.srcproj.TRACK[trid].destmode_flags = setstate
                          GUI_RESERVED_BuildLayer(DATA)  
                         else
                          for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then DATA2.srcproj.TRACK[trid0].destmode_flags = setstate end end
                          GUI_RESERVED_BuildLayer(DATA)  
                        end
                      end},        
            {str='#Handling sends'},
            {str='Import sends|',
              state = DATA2.srcproj.TRACK[trid].sendlogic_flags and DATA2.srcproj.TRACK[trid].sendlogic_flags&1== 1 ,
              func = function() GUI_RESERVED_BuildLayer_DestMenu_Sendlogic(DATA,trid,1) end},  
           --[[{str='Remap routing if receive is imported|',
              state = DATA2.srcproj.TRACK[trid].sendlogic_flags and DATA2.srcproj.TRACK[trid].sendlogic_flags&2 == 2,
              func = function() GUI_RESERVED_BuildLayer_DestMenu_Sendlogic(DATA,trid,2) end},    ]]                   
            {str='#Current project tracks'},
            table.unpack(tracks)
            }
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_Selection_Get(DATA,trid) 
    --DATA.GUI.buttons['tracksrc'..trid].sel_isselected = true
    --if trid then DATA2.srcproj.TRACK[trid].sel_isselected = true end
    local cnt_selection = 0
    local min_id, max_id = math.huge,-1
    for trid0 = 1, #DATA2.srcproj.TRACK do
      --if DATA.GUI.buttons['tracksrc'..trid0].sel_isselected == true then 
      if DATA2.srcproj.TRACK[trid0].sel_isselected == true then 
        cnt_selection = cnt_selection + 1
        min_id = math.min(min_id, trid0)
        max_id = math.max(max_id, trid0)
      end
    end
    return cnt_selection, min_id, max_id
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_Selection_Set(DATA,trid) 
    -- collect/handle selection
      if DATA.GUI.Shift == true then 
        local cnt_selection, min_id, max_id = GUI_RESERVED_BuildLayer_Selection_Get(DATA,trid) 
        if cnt_selection == 1 then 
          if trid > min_id then 
            for i = min_id, trid do DATA2.srcproj.TRACK[i].sel_isselected = true end
           elseif trid < min_id then 
            for i = trid, min_id do DATA2.srcproj.TRACK[i].sel_isselected = true end
          end
         elseif cnt_selection > 1 then 
          if min_id < trid then
            --for i = min_id, trid do DATA.GUI.buttons['tracksrc'..i].sel_isselected = true end
            for i = min_id, trid do DATA2.srcproj.TRACK[i].sel_isselected = true end
           elseif min_id >= trid and max_id > trid then
            --for i = trid, max_id do DATA.GUI.buttons['tracksrc'..i].sel_isselected = true end
            for i = trid, max_id do DATA2.srcproj.TRACK[i].sel_isselected = true end
          end
        end
        DATA.GUI.buttons.Rlayer.refresh = true 
        GUI_RESERVED_BuildLayer(DATA) 
        return
      end 
      
    -- toggle current track state
      if DATA.GUI.Ctrl == true then
        --DATA.GUI.buttons['tracksrc'..trid].sel_isselected = not DATA.GUI.buttons['tracksrc'..trid].sel_isselected  
        DATA2.srcproj.TRACK[trid].sel_isselected = not DATA2.srcproj.TRACK[trid].sel_isselected  
        DATA.GUI.buttons.Rlayer.refresh = true 
       else -- click to reset selection and set current track to ON
        GUI_RESERVED_BuildLayer_Selection_Reset(DATA)  
        --DATA.GUI.buttons['tracksrc'..trid].sel_isselected = true
        DATA2.srcproj.TRACK[trid].sel_isselected = true
        DATA.GUI.buttons.Rlayer.refresh = true 
      end 
      
      GUI_RESERVED_BuildLayer(DATA) 
      
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_Selection_Reset(DATA)     
    --for trid0 = 1, #DATA2.srcproj.TRACK do DATA.GUI.buttons['tracksrc'..trid0].sel_isselected = false end
    for trid0 = 1, #DATA2.srcproj.TRACK do DATA2.srcproj.TRACK[trid0].sel_isselected = false end
    DATA.GUI.buttons.Rlayer.refresh = true 
    GUI_RESERVED_BuildLayer(DATA) 
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer(DATA) 
    local boundary = DATA.GUI.buttons.Rlayer
    DATA.GUI.buttons.Rlayer.refresh = true 
    
    local layerid = DATA.GUI.custom_layerset2
    if not (DATA2.srcproj and DATA2.srcproj.TRACK) then return end
    -- clean table
    for key in spairs(DATA.GUI.buttons) do if key:match('tracksrc') or key:match('trackdest') then DATA.GUI.buttons[key] = nil end end
    
    
    local frame_a = 0.2
    local tr_h = 25
    local y_out0 = 0--boundary.y
    local y_out = y_out0
    local level_indent = 10
    for trid = 1, #DATA2.srcproj.TRACK do
      if not DATA2.srcproj.TRACK[trid].NAME then goto skip_track end
      -- src
      local txt = '['..trid..'] '..DATA2.srcproj.TRACK[trid].NAME
      local level = DATA2.srcproj.TRACK[trid].CUST_foldlev or 0
      -- dest 
      local dest = '[none]'
      local destcol
      local dest_bfill
      if DATA2.srcproj.TRACK[trid].destmode == 1 then 
        dest = '['..DATA.GUI.custom_intname1..']' 
       elseif DATA2.srcproj.TRACK[trid].destmode == 3 then 
        dest = '['..DATA.GUI.custom_intname2..']' 
       elseif DATA2.srcproj.TRACK[trid].destmode == 2 and DATA2.srcproj.TRACK[trid].dest_track_GUID then  
        local desttrid = DATA2:Tracks_GetDestinationbyGUID(DATA2.srcproj.TRACK[trid].dest_track_GUID)
        if desttrid then  
          dest = '['..desttrid..'] ' ..DATA2.destproj.TRACK[desttrid].tr_name 
          destcol = DATA2.destproj.TRACK[desttrid].tr_col
          if destcol ~= 0 then
            local r, g, b = reaper.ColorFromNative( destcol )
            destcol = string.format("#%02X%02X%02X", r, g, b)
            dest_bfill = 0.5
          end
        end
        if DATA2.srcproj.TRACK[trid].destmode_flags == nil then dest = dest..' [replace]' end
        if DATA2.srcproj.TRACK[trid].destmode_flags == 1 then dest = dest..' [under]' end
        if DATA2.srcproj.TRACK[trid].destmode_flags == 2 then dest = dest..' [under, as child]' end
        if DATA2.srcproj.TRACK[trid].destmode_flags == 3 then dest = dest..' [mark only]' end
      end
      if txt=='[%s]+' or txt == '' then txt = '[track'..trid..']' end
      
      local showcond = DATA2:VisibleCondition(DATA2.srcproj.TRACK[trid].NAME)
      local PEAKCOL = DATA2.srcproj.TRACK[trid].PEAKCOL
      if PEAKCOL == 16576 then 
        PEAKCOL = nil 
       else
        local r, g, b = reaper.ColorFromNative( PEAKCOL )
        PEAKCOL = string.format("#%02X%02X%02X", r, g, b)
      end
      if not showcond then goto skip_track end
      
      
      DATA.GUI.buttons['tracksrc'..trid] = 
      {
        x = boundary.x + level_indent*level,
        y = y_out,
        w = DATA.GUI.custom_setposx/2-DATA.GUI.custom_offset-level_indent*level,
        h = math.floor(tr_h),
        layer = layerid,
        txt = txt,
        txt_flags=4 ,
        frame_a=frame_a,
        backgr_col2= PEAKCOL,
        backgr_fill = 0.5,
        backgr_fill2 = 0.5,
        back_sela = 0.1,
        back_sel_recta = 0.6,
        onmouserelease = function() GUI_RESERVED_BuildLayer_Selection_Set(DATA,trid) end,
        onmousereleaseR = function() GUI_RESERVED_BuildLayer_Selection_Reset(DATA,trid) end,
        sel_allow = true,
        sel_isselected = DATA2.srcproj.TRACK[trid].sel_isselected,
      } 
      DATA.GUI.buttons['trackdest'..trid] = 
      {
        x = boundary.x + DATA.GUI.custom_setposx/2,
        y = y_out,
        w = DATA.GUI.custom_setposx/2-DATA.GUI.custom_offset*2-DATA.GUI.custom_scrollw-2,
        h = tr_h-1,
        layer = layerid,
        txt = dest,
        txt_flags=4 ,
        backgr_col2= destcol,
        backgr_fill = dest_bfill,
        backgr_fill2 = dest_bfill,
        back_sela = 0.1,
        back_sel_recta = 0.6,
        frame_a=frame_a,
        onmouserelease = function() DATA:GUImenu(GUI_RESERVED_BuildLayer_DestMenu(DATA, trid) ) end,
      } 
      y_out = math.floor(y_out + tr_h)
      ::skip_track::
    end
    y_out = y_out + tr_h
    
    return y_out-y_out0
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    GUI_RESERVED_init_shortcuts(DATA)
    DATA.GUI.buttons = {} 
    
    DATA.GUI.custom_scrollw = 10
    DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
    DATA.GUI.custom_mainsepx = (gfx.w/DATA.GUI.default_scale)*0.4
    DATA.GUI.custom_mainsepxupd = 150
    DATA.GUI.custom_setposx = gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx
    DATA.GUI.custom_mainbuth = 30
    DATA.GUI.custom_setposy = (DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*3
    DATA.GUI.custom_tracklistw = (gfx.w/DATA.GUI.default_scale- DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset
    DATA.GUI.custom_tracklisty = DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth
    DATA.GUI.custom_tracklisth = gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_tracklisty-DATA.GUI.custom_offset
    DATA.GUI.custom_matchmenu = 30--*DATA.GUI.default_scale
    
    DATA.GUI.custom_intname0 = 'none'
    DATA.GUI.custom_intname1 = 'new track at the end of tracklist'
    DATA.GUI.custom_intname2 = 'new track at the end of tracklist, obey structure'
    DATA.GUI.custom_srcdestnames_w_limit = 250
    
    DATA.GUI.buttons.Rlayer = { x=DATA.GUI.custom_offset,
                           y=DATA.GUI.custom_tracklisty,
                           w=DATA.GUI.custom_tracklistw,
                           h=DATA.GUI.custom_tracklisth,
                           frame_a = 0,
                           layer = DATA.GUI.custom_layerset2,
                           ignoremouse = true,
                           hide = true,
                           }
    DATA:GUIBuildLayer()
    
    local srcprojfp = '[not defined]' 
    if DATA2.srcproj and DATA2.srcproj.fp then srcprojfp = DATA2.srcproj.fp end 
    
    DATA.GUI.buttons.proj_src = { x=DATA.GUI.custom_setposx+DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset*2,
                          h=DATA.GUI.custom_mainbuth,
                          txt = 'Source RPP:\n'..srcprojfp,
                          txt_allowreduce = true,
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function () 
                            local retval, filenameNeed4096 = reaper.GetUserFileNameForRead(DATA.extstate.UI_lastsrcproj, 'Import RPP session data', '' )
                            if retval then  
                              DATA.extstate.UI_lastsrcproj=filenameNeed4096
                              DATA2:ParseSourceProject(filenameNeed4096)
                              DATA.UPD.onconfchange = true  
                              DATA.UPD.onGUIinit = true   
                              
                              if DATA.extstate.UI_matchatsettingsrc==1 then
                                DATA2:Tracks_SetDestination(-1, 0, nil) 
                                DATA2:MatchTrack() 
                                --GUI_RESERVED_BuildLayer(DATA) 
                              end
                              
                            end
                          end,
                          }
    local destprojname = DATA2.destproj.fp
    DATA.GUI.buttons.proj_dest = { x=DATA.GUI.custom_setposx+DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth,
                          w=DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset*2,
                          h=DATA.GUI.custom_mainbuth,
                          txt = 'Dest RPP:\n'..destprojname,
                          txt_allowreduce = true,
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function ()  end,
                          } 
    DATA.GUI.buttons.preset = { x=DATA.GUI.custom_setposx+DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset*3+DATA.GUI.custom_mainbuth*2,
                            w=DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset*2,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            onmouseclick =  function() DATA:GUIbut_preset() end}                           
    DATA.GUI.buttons.import = { x=DATA.GUI.custom_setposx+DATA.GUI.custom_offset,
                          y=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset*2,
                          h=DATA.GUI.custom_mainbuth,
                          txt = 'Import',
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function () 
                            Undo_BeginBlock2( 0 )
                            reaper.PreventUIRefresh( -1 )
                            DATA2:Import2()  
                            reaper.PreventUIRefresh( 1 )
                            Undo_EndBlock2( 0, 'Import session data', 0xFFFFFFFF )
                          end,
                          }                           
    DATA.GUI.buttons.filter = { x=DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset,
                          w=DATA.GUI.custom_setposx/2-DATA.GUI.custom_offset,
                          h=DATA.GUI.custom_mainbuth,
                          txt = 'Filter:'..DATA.extstate.UI_trfilter,
                          txt_short = DATA.extstate.UI_trfilter,
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function () 
                            local retval, retvals_csv = GetUserInputs('Set filter for tracklist', 1, '', DATA.extstate.UI_trfilter )
                            if retval then 
                              DATA.extstate.UI_trfilter = retvals_csv 
                              DATA.UPD.onconfchange = true  
                              DATA.UPD.onGUIinit = true   
                            end
                          end,
                          } 
    local dest_block_x = DATA.GUI.custom_offset+DATA.GUI.custom_setposx/2
    local dest_block_w = math.floor((DATA.GUI.custom_setposx/2-DATA.GUI.custom_offset)/3)
    DATA.GUI.buttons.match = { x=dest_block_x,
                          y=DATA.GUI.custom_offset,
                          w=dest_block_w,
                          h=DATA.GUI.custom_mainbuth,
                          txt = 'Match',
                          txt_short = DATA.extstate.UI_trfilter,
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function () 
                                            DATA2:Tracks_SetDestination(-1, 0, nil) 
                                            DATA2:MatchTrack() 
                                            GUI_RESERVED_BuildLayer(DATA) 
                                          end,
                          }  
    DATA.GUI.buttons.newtrack = { x=DATA.GUI.buttons.match.x+DATA.GUI.buttons.match.w+1,--+DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset,
                          w=dest_block_w,
                          h=DATA.GUI.custom_mainbuth,
                          txt = 'New track',
                          txt_short = DATA.extstate.UI_trfilter,
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function ()  
                                            local cnt_selection = 0 for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then cnt_selection = cnt_selection + 1 end end
                                            for i = 1, #DATA2.srcproj.TRACK do 
                                              if cnt_selection == 0 or (cnt_selection > 0 and DATA2.srcproj.TRACK[i].sel_isselected == true) then
                                                DATA2:Tracks_SetDestination(i, 1)
                                              end
                                            end 
                                            GUI_RESERVED_BuildLayer(DATA)  
                                          end,
                          }                             
    DATA.GUI.buttons.reset = { x=DATA.GUI.buttons.newtrack.x+DATA.GUI.buttons.newtrack.w+1,--+DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset,
                          w=dest_block_w,
                          h=DATA.GUI.custom_mainbuth,
                          txt = 'Reset',
                          txt_short = DATA.extstate.UI_trfilter,
                          txt_fontsz = DATA.GUI.default_txt_fontsz3,
                          onmouseclick =  function()    local cnt_selection = 0 for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then cnt_selection = cnt_selection + 1 end end
                                                        for i = 1, #DATA2.srcproj.TRACK do 
                                                          if cnt_selection == 0 or (cnt_selection > 0 and DATA2.srcproj.TRACK[i].sel_isselected == true) then
                                                            DATA2:Tracks_SetDestination(i, 0)
                                                          end
                                                        end 
                                                        GUI_RESERVED_BuildLayer(DATA)  end,
                          }                                
    DATA.GUI.buttons.Rsettings = { x=DATA.GUI.custom_setposx,
                           y=DATA.GUI.custom_setposy,
                           w=DATA.GUI.custom_mainsepx,
                           h=gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_setposy-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset,
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
  function DATA2:ParseSourceProject_ExplodeTrackData()
    if not DATA2.srcproj.TRACK then return end
    local foldlev = 0 
    local trparams = {
      'NAME',
      'ISBUS',
      'TRACK',
      'PEAKCOL',
      --'LAYOUTS',
                  }
    
    for tr_idx = 1, #DATA2.srcproj.TRACK do
      local chunk = DATA2.srcproj.TRACK[tr_idx].chunk
      DATA2.srcproj.TRACK[tr_idx].chunk_full = chunk -- used for raw data import 
      
      -- extract items
        DATA2.srcproj.TRACK[tr_idx].ITEM = {}
        local it_id = 0
        local item_pat = '[\n\r]+    <(ITEM.-)[\n\r]+    >'
        for item_block in chunk:gmatch(item_pat) do
          it_id = it_id + 1
          DATA2.srcproj.TRACK[tr_idx].ITEM [it_id] = {chunk=item_block}
        end
        chunk = chunk:gsub(item_pat,'') -- clear track chunk from items 
        DATA2.srcproj.TRACK[tr_idx].chunk = chunk -- update chunk
        
      -- extract fx chain
        local fx_pat = '[\n\r]+    <(FXCHAIN.-)[\n\r]+    >'
        local fxchunk = chunk:match(fx_pat)
        if fxchunk then
          local fx_id = 0
          DATA2.srcproj.TRACK[tr_idx].FXCHAIN = {['chunk'] = fxchunk}
          for fx_block in fxchunk:gmatch('(BYPASS.-WAK.-[\n\r]+)') do
            fx_id = fx_id + 1
            DATA2.srcproj.TRACK[tr_idx].FXCHAIN [fx_id] = fx_block
          end
          chunk = chunk:gsub(fx_pat,'') -- clear track chunk from fx_pat
          DATA2.srcproj.TRACK[tr_idx].chunk = chunk -- update chunk
        end
        
      -- extract track params
        for line in chunk:gmatch('[^\r\n]+') do
          if line:match('AUXRECV') then
            if not DATA2.srcproj.TRACK[tr_idx].RECEIVES then DATA2.srcproj.TRACK[tr_idx].RECEIVES = {} end
            local out_valt = DATA2:ParseSourceProject_GetValues(line, true)
            local tmap = {
              {id=1,key='src_tr_id'},--field 1, int, source track index (zero based)
              {id=2,key='mode'},--0 = Post Fader (Post Pan) //    1 = Pre FX //    3 = Pre Fader (Post FX)
              {id=3,key='vol'},
              {id=4,key='pan'},
              {id=5,key='mute'},--field 5, int (bool), mute
              {id=6,key='monosum'},--//  field 6, int (bool), mono sum
              {id=7,key='phase'},--//  field 7, int (bool), invert phase
              {id=8,key='src_chan'},--//  field 8, int, source audio channels //    -1 = none, 0 = 1+2, 1 = 2+3, 2 = 3+4 etc.
              {id=9,key='dest_chan'},--//  field 9, int, dest audio channels (as source but no -1)
              {id=10,key='panlaw'},--//  field 9, int, dest audio channels (as source but no -1)
              {id=11,key='midi_chan'},--//  field 11, int, midi channels //    source = val & 0x1F (0=None), dest = floor(val / 32)
              {id=12,key='automode'},--//  field 12, int, automation mode (-1 = use track mode)
              {id=13,key='unknown_str'},
                        }
            for i=1, #tmap do out_valt[tmap[i].key] = out_valt[tmap[i].id] out_valt[tmap[i].id] = nil end
            DATA2.srcproj.TRACK[tr_idx].RECEIVES[#DATA2.srcproj.TRACK[tr_idx].RECEIVES+1] = out_valt
            
          end
          
          for param = 1, #trparams do
            local param_str = trparams[param]
            if line:match(' '..param_str) then
              local out_valt = DATA2:ParseSourceProject_GetValues(line, true)
              if not DATA2.srcproj.TRACK[tr_idx][param_str] then DATA2.srcproj.TRACK[tr_idx][param_str] = CopyTable(out_valt) end
              --DATA2.srcproj.TRACK[tr_idx][param_str] = CopyTable(out_valt)
            end
          end 
        end
      
      -- handle parameters map
        DATA2.srcproj.TRACK[tr_idx].GUID = DATA2.srcproj.TRACK[tr_idx].TRACK[1] 
        DATA2.srcproj.TRACK[tr_idx].TRACK = nil
        local name = DATA2.srcproj.TRACK[tr_idx].NAME[1] 
        DATA2.srcproj.TRACK[tr_idx].NAME = name
        local PEAKCOL = DATA2.srcproj.TRACK[tr_idx].PEAKCOL[1] 
        DATA2.srcproj.TRACK[tr_idx].PEAKCOL = PEAKCOL
        
      -- handle folder level
        local cur_fold_state = DATA2.srcproj.TRACK[tr_idx].ISBUS[2] or 0
        DATA2.srcproj.TRACK[tr_idx].CUST_foldlev = foldlev
        foldlev = foldlev + cur_fold_state
        
    end
    
    -- handle sends
    for tr_idx = 1, #DATA2.srcproj.TRACK do
      if DATA2.srcproj.TRACK[tr_idx].RECEIVES then
        for recid = 1, #DATA2.srcproj.TRACK[tr_idx].RECEIVES do
          local src_id = DATA2.srcproj.TRACK[tr_idx].RECEIVES[recid].src_tr_id
          if DATA2.srcproj.TRACK[src_id+1] then 
            if not DATA2.srcproj.TRACK[src_id+1].SENDS then DATA2.srcproj.TRACK[src_id+1].SENDS = {} end
            local id = #DATA2.srcproj.TRACK[src_id+1].SENDS+1
            DATA2.srcproj.TRACK[src_id+1].SENDS [id] = CopyTable(DATA2.srcproj.TRACK[tr_idx].RECEIVES[recid])
            DATA2.srcproj.TRACK[src_id+1].SENDS [id].dest_tr_id = tr_idx
            
            DATA2.srcproj.TRACK[tr_idx].RECEIVES[recid].AUXRECV_SRC_GUID = DATA2.srcproj.TRACK[src_id+1].GUID
            DATA2.srcproj.TRACK[src_id+1].SENDS [id].AUXRECV_DEST_GUID = DATA2.srcproj.TRACK[tr_idx].GUID
          end
        end
      end
    end
    
  end
  ----------------------------------------------------------------------
  function DATA2:ParseSourceProject(fp)
    if not fp then return end
    -- init
    DATA2.srcproj = {}
    DATA2.srcproj.fp = fp
    DATA2.srcproj.path = GetParentFolder(fp)
    -- read file
    local f = io.open(fp, 'rb')
    if not f then return end
    local content = f:read('a')
    f:close()
    
    -- get chunks
      DATA2.srcproj.is_tracktemplatemode = false if fp:lower():match('rtracktemplate') then DATA2.srcproj.is_tracktemplatemode = true end
      DATA2:ParseSourceProject_ExtractChunks(content, 'TRACK', nil, DATA2.srcproj.is_tracktemplatemode)
      DATA2:ParseSourceProject_ExplodeTrackData()
      DATA2:ParseSourceProject_ExtractChunks(content, 'EXTENSIONS')
      DATA2:ParseSourceProject_ExplodeHeaderData(content)
  end
  ----------------------------------------------------------------------
  function DATA2:ParseSourceProject_ExtractTempo(content)
    local chunk = content:match('<TEMPOENVEX(.-)>')
    if not chunk then return end
    
    DATA2.srcproj.TEMPOMAP = {}
    for line in chunk:gmatch('[^\r\n]+') do
      if line:match('PT %d+') then
        local valt = {} for val in line:gmatch('[^%s]+') do valt[#valt+1] = val end
        local timepos = tonumber(valt[2])
        local bpm = tonumber(valt[3])
        local lineartempochange = tonumber(valt[4])&1==0
        local timesig_num, timesig_denom
        if valt[5] then
          local timesig = valt[5]
          timesig_num = timesig&0xFFFF
          timesig_denom = (timesig>>16)&0xFFFF
        end
        DATA2.srcproj.TEMPOMAP[#DATA2.srcproj.TEMPOMAP+1] = {timepos=timepos,
                  bpm=bpm,
                  lineartempochange=lineartempochange,
                  timesig_num=timesig_num,
                  timesig_denom=timesig_denom}
      end
    end
  end
  
  ----------------------------------------------------------------------
  function DATA2:ParseSourceProject_ExtractMarkers_parse(line, pat)
    local t = {} 
    local temp
    for val in line:gmatch("%S+") do         -- based on https://stackoverflow.com/a/39757839
      if temp then
        if val:sub(#val, #val) == pat or '"' then
          print(temp.." "..val)
          temp = nil
        else
          temp = temp.." "..val
        end
      elseif val:sub(1,1) == '"' then
        temp = val
      else
        t[#t+1] = tonumber(val) or val
      end
    end
    table.remove(t,1)
    return t
  end
  ----------------------------------------------------------------------
  function DATA2:ParseSourceProject_ExtractGroupNames(content)
    DATA2.srcproj.GROUPNAMES = {}
    for line in content:gmatch('[^\r\n]+') do
      if line:match('GROUP_NAME') then
        local groupid, name = line:match('GROUP_NAME (%d+) (.*)')
        if groupid and name then 
          DATA2.srcproj.GROUPNAMES[groupid] = name
        end
      end
    end
  end
  ----------------------------------------------------------------------
  function DATA2:ParseSourceProject_ExtractMarkers(content)
    DATA2.srcproj.MARKERS = {}
    local reg_open
    for line in content:gmatch('[^\r\n]+') do
      if line:match('MARKER') then
        local id, pos_sec, name, is_region_flags, col, val6, val7, GUID = line:match('MARKER ([%d]+) ([%d%p]+) (.-) ([%d]+) ([%d%p]+) ([%d%p]+) ([%a]+) {(.-)}')
        id = tonumber(id)
        pos_sec = tonumber(pos_sec)
        is_region_flags = tonumber(is_region_flags)
        col = tonumber(col)
        val6 = tonumber(val6)
        
        if not is_region_flags then -- region end
          id, pos_sec, name, is_region_flags, col = line:match('MARKER ([%d]+) ([%d%p]+) (.-) ([%d]+) ([%d%p]+)')
          id = tonumber(id)
          pos_sec = tonumber(pos_sec)
          is_region_flags = tonumber(is_region_flags)
          col = tonumber(col)
          val6 = tonumber(val6)
        end
        
        if not is_region_flags then 
          id, pos_sec, name, is_region_flags, col = line:match('MARKER ([%d]+) ([%d%p]+) (.-) ([%d]+) ([%d%p]+) ([%d%p]+) ([%a]+)')
        end
        if not is_region_flags then return end
        
        local is_region = is_region_flags&1==1 
        local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos_sec)
        DATA2.srcproj.MARKERS[#DATA2.srcproj.MARKERS+1] = 
            { id = id,
              pos = fullbeats,
              name = name,
              is_region = is_region,
              is_region_flags = is_region_flags,
              col = col,
              val6 = val6,
              val7 = val7,
              GUID = GUID, 
            }
        if is_region and not GUID then
          local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos_sec  )
          DATA2.srcproj.MARKERS[#DATA2.srcproj.MARKERS-1].rgnend = fullbeats 
          DATA2.srcproj.MARKERS[#DATA2.srcproj.MARKERS] = nil
        end  
      end
    end 
  end
  ----------------------------------------------------------------------
  function DATA2:ParseSourceProject_ExplodeHeaderData(content)
    DATA2.srcproj.HEADER = content:match('(REAPER_PROJECT.-)<TRACK')
    DATA2:ParseSourceProject_ExtractChunks(content, 'MASTERFXLIST', DATA2.srcproj.HEADER_MASTERFXLIST)
    DATA2:ParseSourceProject_ExtractMarkers(content)
    DATA2:ParseSourceProject_ExtractTempo(content)
    DATA2:ParseSourceProject_ExtractGroupNames(content)
    
    local HEADER_renderconf = content:match('<RENDER_CFG(.-)>')
    if HEADER_renderconf then DATA2.srcproj.HEADER_renderconf = HEADER_renderconf:gsub('%s','') end
    
  end
  ----------------------------------------------------------------------
  function DATA2:ParseSourceProject_GetValues(str, ignorefirst)
    local t = {}
     tout = {}
    local brack = 0
    local temp_t = {}
    for sign in str:gmatch('.') do 
      if not (sign=='"' or (sign == ' ' and brack ==0)) then temp_t[#temp_t+1] = sign end
      if sign=='"' and brack == 0 then 
        brack = brack +1 
       elseif sign=='"' and brack > 0 then 
        brack = brack -1 
      end
      if sign == ' ' and brack == 0 and #temp_t>0 then 
        tout[#tout+1] = table.concat(temp_t)
        temp_t = {}
      end
    end
    tout[#tout+1] = table.concat(temp_t)
    --[[
    for val in str:gmatch('[^%s]+') do t[#t+1] = val end
    local tout = {}
    for i = 1, #t do
      if t[i]:sub(0,1) == '"' then
        local cntpar = 0 for char in t[i]:gmatch('%"') do cntpar = cntpar + 1 end
        if cntpar%2 == 0 then
          tout[#tout+1] = t[i] 
         else
          if t[i+1] then t[i+1] = t[i]..' '..t[i+1] end
        end
       else
        tout[#tout+1] = t[i] 
      end
    end
    for i = 1, #tout do local val = tout[i] if val:sub(0,1) == '"' and val:sub(-1) == '"'  then tout[i] = tout[i]:match('%"(.*)%"' ) end end 
    ]]
    
    if ignorefirst then table.remove(tout,1) end 
    for i = 1, #tout do  tout[i] = tonumber(tout[i]) or tout[i] end -- convert to numbers if possible
    if #tout > 0 then return tout end
  end
  ----------------------------------------------------------------------
  function DATA2:ParseSourceProject_ExtractChunks(content, key, output_t, tracktemplatemode)
    local t = {}
    local sep = '  '
    for block in content:gmatch('[\n\r]+'..sep..'<('..key..'.-'..')[\n\r]'..sep..'>') do t[#t +1] = {chunk=block } end
    
    if tracktemplatemode ==true  then t[#t +1] = {chunk=content:match('<(.*)>') }end
    
    if output_t then output_t = CopyTable(t) else DATA2.srcproj[key] = CopyTable(t) end
  end 
  ----------------------------------------------------------------------
  function DATA2:Tracks_GetDestinationbyGUID(GUID) for j = 1, #DATA2.destproj.TRACK do if GUID == DATA2.destproj.TRACK[j].GUID then return j end end end
  ----------------------------------------------------------------------
  function DATA2:Tracks_IsDestinationUsed(desttrack_id)
    local destGUID = DATA2.destproj.TRACK[desttrack_id].GUID 
    for j = 1, #DATA2.srcproj.TRACK do
      if DATA2.srcproj.TRACK[j].dest_track_GUID == destGUID then
        return true
      end
    end
  end
  ----------------------------------------------------------------------
  function DATA2:Tracks_SetDestination(srctrack_id, mode, desttrack_id)
    local output_error_code = 0
    if not ( DATA2.srcproj and DATA2.srcproj.TRACK and mode) then return end
    if DATA2.srcproj.TRACK[srctrack_id] then 
      DATA2.srcproj.TRACK[srctrack_id].destmode = mode 
      if DATA2.srcproj.TRACK[srctrack_id].dest_track_GUID then
        local desttrack_id = DATA2:Tracks_GetDestinationbyGUID( DATA2.srcproj.TRACK[srctrack_id].dest_track_GUID)
        if desttrack_id and DATA2.destproj.TRACK[desttrack_id] then DATA2.destproj.TRACK[desttrack_id].has_source =false end
      end
      DATA2.srcproj.TRACK[srctrack_id].dest_track_GUID = nil
    end
    
    -- set for all tracks
      if srctrack_id == -1 and mode&2 ~= 2 then 
        for i = 1, #DATA2.srcproj.TRACK do 
          if DATA2.srcproj.TRACK[i].dest_track_GUID then
            local desttrack_id = DATA2:Tracks_GetDestinationbyGUID( DATA2.srcproj.TRACK[i].dest_track_GUID)
            if desttrack_id and DATA2.destproj.TRACK[desttrack_id] then DATA2.destproj.TRACK[desttrack_id].has_source =false end
          end
          DATA2.srcproj.TRACK[i].dest_track_GUID = nil
          DATA2.srcproj.TRACK[i].destmode = mode 
        end 
      end
      
    -- set specific track
      if mode&2==2 and desttrack_id and not DATA2.destproj.TRACK[desttrack_id].has_source then
        local destGUID = DATA2.destproj.TRACK[desttrack_id].GUID        -- check for already set up destination from somwwhere
        DATA2.srcproj.TRACK[srctrack_id].destmode = 2
        DATA2.srcproj.TRACK[srctrack_id].dest_track_GUID = DATA2.destproj.TRACK[desttrack_id].GUID
        DATA2.destproj.TRACK[desttrack_id].has_source =true
      end
      
    return output_error_code -- 0 success 1 -- destination is moved 
  end      
  --------------------------------------------------- 
  function DATA2:Import_ResetFolderLevel(dest_tr, last_folder_level, last_dest_tr) 
    if not dest_tr then return end
    if DATA.extstate.CONF_resetfoldlevel==1 and dest_tr then  
      local folder_level = reaper.GetMediaTrackInfo_Value(dest_tr, 'I_FOLDERDEPTH') 
      if folder_level == 1 and last_folder_level == 1 and last_dest_tr then SetMediaTrackInfo_Value( last_dest_tr, 'I_FOLDERDEPTH', 0) end 
      return true, folder_level
    end  
  end
  ----------------------------------------------------------------------
  function DATA2:MatchTrack(specificid)
    if not DATA2.srcproj.TRACK then return end
    DATA2:Get_DestProject()
    local cnt_selection = 0 for trid0 = 1, #DATA2.srcproj.TRACK do if DATA2.srcproj.TRACK[trid0].sel_isselected == true then cnt_selection = cnt_selection + 1 end end
    
    -- specific track match
    if specificid and DATA2.srcproj.TRACK[specificid] then 
      local tr_name = DATA2.srcproj.TRACK[specificid].NAME 
      DATA2:MatchTrack_Sub(tr_name, specificid) return 
    end
    
    for i = 1, #DATA2.srcproj.TRACK do 
      if cnt_selection == 0 or (cnt_selection > 0 and DATA2.srcproj.TRACK[i].sel_isselected == true) then
        local tr_name = DATA2.srcproj.TRACK[i].NAME
        DATA2:MatchTrack_Sub(tr_name, i) 
      end
    end  
  end
  -------------------------------------------------------------------- 
  function DATA2:MatchTrack_Sub(tr_name, id_src) 
    if not tr_name then return end
    if tr_name == '' then return end
    tr_name = tostring(tr_name)
    tr_name = tr_name:lower()
    if tr_name:match('track %d+') then return end
    
    -- check for exact match
    for trid = 1,  #DATA2.destproj.TRACK do 
      local tr_name_CUR =  DATA2.destproj.TRACK[trid].tr_name:lower()
      if tr_name:match(literalize(tr_name_CUR)) and tr_name:match(literalize(tr_name_CUR)):len() == tr_name:len() then
        DATA2:Tracks_SetDestination(id_src, 2, trid)
        return
      end
    end
    
    local t = {}
    local cnt_match0, cnt_match, last_biggestmatch = 0, 0 
    for word in tr_name:gmatch('[^%s]+') do t[#t+1] = literalize(word:lower():gsub('%s+','')) end  
    for trid = 1,  #DATA2.destproj.TRACK do 
      local tr_name_CUR =  DATA2.destproj.TRACK[trid].tr_name:lower()
      if tr_name_CUR ~= '' and not tr_name_CUR:match('track %d+') then
        cnt_match0 = 0
        for i = 1, #t do if tr_name_CUR:match(t[i]) then cnt_match0 = cnt_match0 + 1 end end
        if cnt_match0 == #t then DATA2:Tracks_SetDestination(id_src, 2, desttrack_id) return end
        if cnt_match0 > cnt_match then last_biggestmatch = trid end 
        cnt_match = cnt_match0
      end
    end 
    DATA2:Tracks_SetDestination(id_src, 2, last_biggestmatch)--msg(last_biggestmatch)
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Tracks_ValidateDestinationConflicts() 
    local dest_t = {}
    for i = 1, #DATA2.srcproj.TRACK do
      local srct = DATA2.srcproj.TRACK[i]
      if srct.destmode == 2 and srct.dest_track_GUID then 
        if dest_t[srct.dest_track_GUID] then 
          dest_t[srct.dest_track_GUID] = true 
          return true
        end
      end
    end
  end
  -------------------------------------------------------------------- 
  function DATA2:Import2_Tracks_ImportReceives_params(new_tr, sendidx,auxt)  
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_VOL', auxt.vol )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_MUTE', auxt.mute )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_PHASE', auxt.phase )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_MONO', auxt.monosum )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_PAN', auxt.pan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_PANLAW', tonumber(auxt.panlaw) or -1 )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_SENDMODE', auxt.mode )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_SRCCHAN', auxt.src_chan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_DSTCHAN', auxt.dest_chan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_AUTOMODE', auxt.automode )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_MIDIFLAGS', auxt.midi_chan )
  end
  ----------------------------------------------------------------------
  function DATA2:Tracks_GetSourcebyGUID(GUID) for j = 1, #DATA2.srcproj.TRACK do if GUID == DATA2.srcproj.TRACK[j].GUID then return j end end end
  ----------------------------------------------------------------------
  function DATA2:Import2_Tracks_ImportReceives()  
    for tr_id = 1, #DATA2.srcproj.TRACK do
      local srct = DATA2.srcproj.TRACK[tr_id] 
      if srct.sendlogic_flags and srct.sendlogic_flags > 0 and srct.SENDS then 
        
        for sendID = 1, #srct.SENDS do
          local destination_GUID = srct.SENDS[sendID].AUXRECV_DEST_GUID
          if destination_GUID then
            local dest_id = DATA2:Tracks_GetSourcebyGUID(destination_GUID)
            local has_imported_destination = false 
            if DATA2.srcproj.TRACK[dest_id] and DATA2.srcproj.TRACK[dest_id].dest_track_GUID then has_imported_destination = true end -- receive is already imported
            
            if has_imported_destination ==true then
              local src_tr = VF_GetTrackByGUID(srct.dest_track_GUID)
              local dest_tr = VF_GetTrackByGUID(DATA2.srcproj.TRACK[dest_id].dest_track_GUID)
              if src_tr and dest_tr then 
                local sendidx = CreateTrackSend( src_tr, dest_tr )
                DATA2:Import2_Tracks_ImportReceives_params(src_tr,sendidx,srct.SENDS[sendID])  
              end
            end
            
          end
        end
        
      end
    end
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Tracks() 
    local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
    --local ret_conflict = DATA2:Import2_Tracks_ValidateDestinationConflicts() 
    --if ret_conflict then msg('fffuu') return end
    
    for i = 1, #DATA2.srcproj.TRACK do
      local srct = DATA2.srcproj.TRACK[i]
      if not DATA2:VisibleCondition(DATA2.srcproj.TRACK[i].NAME) or (cnt_selection > 0 and not DATA2.srcproj.TRACK[i].sel_isselected) then goto importnexttrack end
      
      local mode = srct.destmode or 0 
      
      if mode == 1 then -- at the end 
        local new_tr_src = DATA2:Import_CreateNewTrack(false, srct) 
        local dest_tr = DATA2:Import_CreateNewTrack(true)
        DATA2:Import_TransferTrackData(new_tr_src, dest_tr)
        srct.dest_track_GUID = GetTrackGUID( dest_tr )
      end
      
      if mode == 3 then -- at the end, obey structure
        local new_tr_src = DATA2:Import_CreateNewTrack(false, srct) 
        local dest_tr = DATA2:Import_CreateNewTrack(true)
        DATA2:Import_TransferTrackData(new_tr_src, dest_tr, true)
        srct.dest_track_GUID = GetTrackGUID( dest_tr )
      end 
      
      if mode == 2 and srct.dest_track_GUID then -- replace specific track
        if not (srct.destmode_flags and srct.destmode_flags == 3) then
          local new_tr_src = DATA2:Import_CreateNewTrack(false, srct)
          local dest_tr 
          local srcpos_tr = VF_GetTrackByGUID(srct.dest_track_GUID)
          if not srct.destmode_flags then
            dest_tr = srcpos_tr
           elseif srct.destmode_flags == 1 or srct.destmode_flags ==2 then
            dest_tr = DATA2:Import_CreateNewTrack(true)
          end 
          DATA2:Import_TransferTrackData(new_tr_src, dest_tr) 
          if srct.destmode_flags == 1 or srct.destmode_flags ==2 then
            SetOnlyTrackSelected( dest_tr )
            makePrevFolder = 0
            if srct.destmode_flags ==2 then makePrevFolder = 1 end
            ReorderSelectedTracks(  CSurf_TrackToID( srcpos_tr, false ), makePrevFolder )
          end
        end
      end
      
      
      ::importnexttrack::
    end
    DATA2:Import2_Tracks_ImportReceives()  
    if DATA.extstate.CONF_buildpeaks == 1 then Action(40047) end -- Peaks: Build any missing peaks
  end
  ---------------------------------------------------------------------
  function DATA2:Import2_Header_MasterFX_AddChunkToTrack(tr, chunk) -- add empty fx chain chunk if not exists
    local _, chunk_ch = reaper.GetTrackStateChunk(tr, '', false)
    if not chunk_ch:match('FXCHAIN') then chunk_ch = chunk_ch:sub(0,-3)..'<FXCHAIN\nSHOW 0\nLASTSEL 0\n DOCKED 0\n>\n>\n' end
    if chunk then chunk_ch = chunk_ch:gsub('DOCKED %d', chunk) end
    reaper.SetTrackStateChunk(tr, chunk_ch, false)
  end 
  ----------------------------------------------------------------------
  function DATA2:Import2_Header_MasterFX()
    if DATA.extstate.CONF_head_mast_FX == 0 then return end  
    if #DATA2.srcproj.MASTERFXLIST == 0  then return end  
    local master_tr = GetMasterTrack( 0 )
    local retval, cur_chunk = reaper.GetTrackStateChunk( master_tr, '', false )
    if not (DATA2.srcproj.MASTERFXLIST[1] and DATA2.srcproj.MASTERFXLIST[1].chunk) then return end
    local src_chunk = DATA2.srcproj.MASTERFXLIST[1].chunk:gsub('MASTERFXLIST', '') 
    DATA2:Import2_Header_MasterFX_AddChunkToTrack(master_tr,src_chunk)
    
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Header_Markers()   
    if not DATA2.srcproj.MARKERS then return end
    
    --[[  &1 markers
          &2 markersreplace
          &4 regions
          &8 regionsreplace 
          ]]
          
    -- handle replace / aka remove old regions markers
    if DATA.extstate.CONF_head_markers&1==1 or DATA.extstate.CONF_head_markers&4==4 then -- import markers or regions
      local retval, num_markers, num_regions = CountProjectMarkers( 0 )
      for i = num_markers+num_regions, 1,-1 do 
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i-1 )
        if (DATA.extstate.CONF_head_markers&2 ==2 and isrgn ==false) or (DATA.extstate.CONF_head_markers&8 ==8 and isrgn ==true) then DeleteProjectMarkerByIndex( 0, i-1 ) end
      end
    end 
     
    -- handle cursor
      local offs = 0
      if DATA.extstate.CONF_head_markers&16==16 then offs = GetCursorPosition() end
    
    -- add markers from table
    for i = 1, #DATA2.srcproj.MARKERS do
      if DATA2.srcproj.MARKERS[i].is_region==false and DATA.extstate.CONF_head_markers&1 == 1 then
        local pos_sec=TimeMap2_beatsToTime( 0, DATA2.srcproj.MARKERS[i].pos )
        local idx = AddProjectMarker( 0, false, pos_sec+offs, -1, DATA2.srcproj.MARKERS[i].name, DATA2.srcproj.MARKERS[i].id, DATA2.srcproj.MARKERS[i].col )
      end
    
      -- add regions from table
      if DATA2.srcproj.MARKERS[i].is_region==true and DATA.extstate.CONF_head_markers&4 == 4 then
        local pos_sec=TimeMap2_beatsToTime( 0, DATA2.srcproj.MARKERS[i].pos )
        local end_sec=TimeMap2_beatsToTime( 0, DATA2.srcproj.MARKERS[i].rgnend )
        local idx = AddProjectMarker2( 0, true, pos_sec+offs, end_sec+offs, DATA2.srcproj.MARKERS[i].name, DATA2.srcproj.MARKERS[i].id, DATA2.srcproj.MARKERS[i].col )
      end
      
    end 
    reaper.UpdateTimeline()
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Header_Groupnames()
    if DATA.extstate.CONF_head_groupnames&1 ~= 1 then return end
    if not DATA2.srcproj.GROUPNAMES then return end  
    for groupID in pairs(DATA2.srcproj.GROUPNAMES) do
      GetSetProjectInfo_String( 0, 'TRACK_GROUP_NAME:'..(groupID+1), DATA2.srcproj.GROUPNAMES[groupID], true )
    end
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Header_Tempo()
    if DATA.extstate.CONF_head_tempo&1 ~= 1 then return end
    if not DATA2.srcproj.TEMPOMAP then return end
    
    for markerindex = CountTempoTimeSigMarkers( 0 ), 1, -1 do DeleteTempoTimeSigMarker( 0, markerindex-1 ) end
    
    -- handle cursor
      local offs = 0
      if DATA.extstate.CONF_head_tempo&2==2 then offs = GetCursorPosition() end
      
    for i = 1, #DATA2.srcproj.TEMPOMAP do
      local timesig_num = 0
      local timesig_denom = 0
      local lineartempo = false
      if DATA2.srcproj.TEMPOMAP[i].timesig_num and DATA2.srcproj.TEMPOMAP[i].timesig_denom then 
        timesig_num = DATA2.srcproj.TEMPOMAP[i].timesig_num
        timesig_denom = DATA2.srcproj.TEMPOMAP[i].timesig_denom
      end
      if DATA2.srcproj.TEMPOMAP[i].lineartempochange and DATA2.srcproj.TEMPOMAP[i].lineartempochange==true then lineartempo = DATA2.srcproj.TEMPOMAP[i].lineartempochange end
      reaper.SetTempoTimeSigMarker( 0, -1, DATA2.srcproj.TEMPOMAP[i].timepos + offs, -1, -1, DATA2.srcproj.TEMPOMAP[i].bpm, timesig_num, timesig_denom, lineartempo )
    end
    
  end
  ----------------------------------------------------------------------
  function DATA2:Import2() 
    DATA2:Import2_Tracks() 
    DATA2:Import2_Header_MasterFX()
    DATA2:Import2_Header_Markers()
    DATA2:Import2_Header_Tempo()
    DATA2:Import2_Header_Groupnames()
    
    if DATA.extstate.CONF_head_rendconf == 1 and DATA2.srcproj.HEADER_renderconf then
      GetSetProjectInfo_String( 0, 'RENDER_FORMAT', DATA2.srcproj.HEADER_renderconf, 1 ) 
    end
  end
  -------------------------------------------------------------------- 
  function DATA2:Import_TransferTrackData_Items(src_tr, dest_tr) 
    local curpos = GetCursorPosition() 
    
    if DATA.extstate.CONF_tr_it&2 == 2 then -- remove dest tr items
      for itemidx = CountTrackMediaItems( dest_tr ), 1, -1 do 
        local item = GetTrackMediaItem( dest_tr, itemidx-1 )
        DeleteTrackMediaItem(  dest_tr, item) 
      end
    end
    
    if DATA.extstate.CONF_tr_it&1 == 1 then -- import tr items / replace GUID
      for itemidx = 1,  CountTrackMediaItems( src_tr ) do
        local item = GetTrackMediaItem( src_tr, itemidx-1 )
        local retval, chunk = reaper.GetItemStateChunk( item, '', false ) 
        local gGUID = genGuid('' ) 
        chunk = chunk:gsub('GUID (%{.-%})\n', 'GUID '..gGUID..'\n')
        
        --[[local tk_data = {}
        for takeidx = 1,  CountTakes( item ) do
          local take =  GetTake( item, takeidx-1 )
          local source=  GetMediaItemTake_Source( take )
          local filename = reaper.GetMediaSourceFileName( source, '' )
          tk_data[takeidx] = {filename = filename}
        end]]
        
        local new_it = AddMediaItemToTrack( dest_tr )
        SetItemStateChunk( new_it, chunk, false ) 
        
        if DATA.extstate.CONF_tr_it&4 == 4 then -- shift by edit cur
          local it_pos = GetMediaItemInfo_Value( new_it, 'D_POSITION' )
          SetMediaItemInfo_Value( new_it, 'D_POSITION', it_pos+curpos )
        end
        
      end
    end
    
    --[[ relink files to full paths
    if DATA2.srcproj.path then
      for itemidx = 1,  #item_data do
        local it = AddMediaItemToTrack( dest_tr )
        local item_data0 = item_data[itemidx]
        SetItemStateChunk( it, item_data0.chunk, false )
        for takeidx = 1,  #item_data0.tk_data do
          local take =  GetTake( it, takeidx-1 )
          if not TakeIsMIDI( take ) then
            local fn = item_data0.tk_data[takeidx].filename
            if not fn:match('[%/%\\]') and DATA.extstate.CONF_tr_it&4==4 then
              fn = DATA2.srcproj.path..'/'..fn
              local  pcmsrc = PCM_Source_CreateFromFile( fn )
              if pcmsrc then SetMediaItemTake_Source( take, pcmsrc ) end
              --PCM_Source_Destroy( pcmsrc )
            end
          end
        end
      end
    end
    ]]
    
  end
  -------------------------------------------------------------------- 
  function DATA2:Import_TransferTrackData_FXchain_Envelopes(src_tr, dest_tr,dest_cnt,src_fx)
    for envidx = 1, reaper.CountTrackEnvelopes( src_tr ) do
      local env = reaper.GetTrackEnvelope( src_tr, envidx-1 )
      local retval, fxindex, paramindex = reaper.Envelope_GetParentTrack( env )   
      if fxindex == src_fx-1 then
        local retval, chunk = reaper.GetEnvelopeStateChunk( env, '', false )
        local dest_env = reaper.GetFXEnvelope( dest_tr, dest_cnt + src_fx-1, paramindex, true )
        if dest_env then  reaper.SetEnvelopeStateChunk( dest_env, chunk, false ) end
      end
    end
  end
  -------------------------------------------------------------------- 
  function DATA2:Import_TransferTrackData_FXchain(src_tr, dest_tr)
    local dest_cnt = TrackFX_GetCount( dest_tr )
    
    if DATA.extstate.CONF_tr_FX&2==2 then -- clear existed
      for dest_fx = dest_cnt, 1, -1 do   TrackFX_Delete( dest_tr, dest_fx-1 )  end 
      dest_cnt = 0
    end
    
    if DATA.extstate.CONF_tr_FX&1==1 then
      for src_fx = 1, TrackFX_GetCount( src_tr ) do 
        TrackFX_CopyToTrack( src_tr, src_fx-1, dest_tr, dest_cnt + src_fx-1, false )  
        if DATA.extstate.CONF_tr_FX&4==4 then DATA2:Import_TransferTrackData_FXchain_Envelopes(src_tr, dest_tr,dest_cnt,src_fx) end  
      end
    end
    
  end
  --[[
  -------------------------------------------------------------------- 
  function Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, new_tr, sendidx, auxt)
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_VOL', auxt.vol )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_MUTE', auxt.mute )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_PHASE', auxt.phaseinv )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_MONO', auxt.monosum )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_PAN', auxt.pan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_PANLAW', auxt.panlaw )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_SENDMODE', auxt.mode )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_SRCCHAN', auxt.srcchan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_DSTCHAN', auxt.destchan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_AUTOMODE', auxt.automode )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_MIDIFLAGS', auxt.midichan )
  end
  --------------------------------------------------------------------  
  function Data_ImportTracks_Send(conf, obj, data, refresh, mouse, strategy) 
    --if strategy.trsend&1 == 0 then return end
    for i = 1, #data.tr_chunks do
      if data.tr_chunks[i].dest~= '' and #data.tr_chunks[i].AUXRECV > 0 then
        for auxid = 1,#data.tr_chunks[i].AUXRECV do
          local tr_chunks_id = data.tr_chunks[i].AUXRECV[auxid].src_id+1
          if tr_chunks_id and data.tr_chunks[tr_chunks_id] then
            
            if data.tr_chunks[tr_chunks_id].dest == '' and strategy.trsend&2 ==2 then -- src track not added
            
                data.tr_chunks[tr_chunks_id].dest = -1
                local paste_send_at_ID = CountTracks( 0 )
                local new_tr = Data_ImportTracks_NewTrack(data, tr_chunks_id, paste_send_at_ID,strategy)
                local imported_dst_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID) 
                local has_send = false 
                if strategy.trsend&16 ~=16 then
                  for sendidx =1,  GetTrackNumSends( imported_dst_tr, 0 ) do
                    local srctr0 = GetTrackSendInfo_Value( imported_dst_tr, 0, sendidx-1, 'P_SRCTRACK' )
                    if GetTrackGUID(srctr0) == GetTrackGUID(new_tr) then has_send = true end
                  end
                end 
                if not has_send then
                  local sendidx = CreateTrackSend( new_tr, imported_dst_tr )
                  Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, new_tr, sendidx, data.tr_chunks[i].AUXRECV[auxid])
                end
              
             elseif strategy.trsend&4 ==4 and type(data.tr_chunks[tr_chunks_id].dest) == 'string'   then -- if source track is imported to matched track--and type(data.tr_chunks[tr_chunks_id].dest) =='string'
             
               local imported_src_tr = VF_GetTrackByGUID(data.tr_chunks[tr_chunks_id].destGUID)
               local imported_dst_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID) 
               if imported_src_tr and imported_dst_tr then
                 local has_send = false 
                 if strategy.trsend&16 ~=16 then
                   for sendidx =1,  GetTrackNumSends( imported_dst_tr, -1 ) do
                     local srctr0 = GetTrackSendInfo_Value( imported_dst_tr, -1, sendidx-1, 'P_SRCTRACK' )
                     if GetTrackGUID(srctr0 ) == GetTrackGUID(imported_src_tr ) then has_send = true end
                   end
                 end 
                 if not has_send then
                  local sendidx = CreateTrackSend( imported_src_tr, imported_dst_tr )
                  Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, imported_src_tr, sendidx, data.tr_chunks[i].AUXRECV[auxid])
                 end
                end
                
             elseif strategy.trsend&8 ==8 and  data.tr_chunks[tr_chunks_id].dest == -1 then -- if source track is imported as a new track
             
               local imported_src_tr = VF_GetTrackByGUID(data.tr_chunks[tr_chunks_id].destGUID)
               --reaper.SetTrackColor( imported_src_tr, 0 )
               local imported_dst_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID)
               local has_send = false 
               if strategy.trsend&16 ~=16 then
                 for sendidx =1,  GetTrackNumSends( imported_dst_tr, -1 ) do
                   local srctr0 = GetTrackSendInfo_Value( imported_dst_tr, -1, sendidx-1, 'P_SRCTRACK' )
                   if GetTrackGUID(srctr0 ) == GetTrackGUID(imported_src_tr ) then has_send = true end
                 end
                end
               if not has_send then
                local sendidx = CreateTrackSend( imported_src_tr, imported_dst_tr )
                Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, imported_src_tr, sendidx, data.tr_chunks[i].AUXRECV[auxid])
               end              
               
             elseif data.tr_chunks[tr_chunks_id].dest == -2 and data.tr_chunks[tr_chunks_id].destGUID then -- if source track is only mark as source for send
                
               local imported_src_tr = VF_GetTrackByGUID(data.tr_chunks[tr_chunks_id].destGUID)
               local imported_dst_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID)
               local has_send = false
               if strategy.trsend&16 ~=16 then
                 for sendidx =1,  GetTrackNumSends( imported_dst_tr, -1 ) do
                   local srctr0 = GetTrackSendInfo_Value( imported_dst_tr, -1, sendidx-1, 'P_SRCTRACK' )
                   if GetTrackGUID(srctr0 ) == GetTrackGUID(imported_src_tr ) then has_send = true end
                 end
               end
               if not has_send then
                local sendidx = CreateTrackSend( imported_src_tr, imported_dst_tr )
                Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, imported_src_tr, sendidx, data.tr_chunks[i].AUXRECV[auxid])
               end                
            end             
          end
        end
      end
    end
  end
  ]]
  -------------------------------------------------------------------- 
  function DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, key)
    if key=='GROUPMEMBERSHIP'  then 
      local t = {'VOLUME_LEAD',
      'VOLUME_FOLLOW',
      'VOLUME_VCA_LEAD',
      'VOLUME_VCA_FOLLOW',
      'PAN_LEAD',
      'PAN_FOLLOW',
      'WIDTH_LEAD',
      'WIDTH_FOLLOW',
      'MUTE_LEAD',
      'MUTE_FOLLOW',
      'SOLO_LEAD',
      'SOLO_FOLLOW',
      'RECARM_LEAD',
      'RECARM_FOLLOW',
      'POLARITY_LEAD',
      'POLARITY_FOLLOW',
      'AUTOMODE_LEAD',
      'AUTOMODE_FOLLOW',
      'VOLUME_REVERSE',
      'PAN_REVERSE',
      'WIDTH_REVERSE',
      'NO_LEAD_WHEN_FOLLOW',
      'VOLUME_VCA_FOLLOW_ISPREFX'}
      local reapervrs = GetAppVersion():match('[%d%.]+')
      if reapervrs then reapervrs = tonumber(reapervrs) end 
      if reapervrs and reapervrs <= 6.11 then for i = 1, #t do t[i] = t[i]:gsub('LEAD', 'MASTER'):gsub('FOLLOW', 'SLAVE') end end
      
      for i = 1, #t do 
        local flags = GetSetTrackGroupMembership( src_tr,  t[i], 0, 0 )
        GetSetTrackGroupMembership( dest_tr,  t[i], flags, 0xFFFFFFFF )
        local flagshigh = GetSetTrackGroupMembershipHigh( src_tr,  t[i], 0, 0 )
        GetSetTrackGroupMembershipHigh( dest_tr,  t[i], flagshigh, 0xFFFFFFFF )
      end
      
     elseif (key=='P_NAME'  or  key=='P_TCP_LAYOUT'  or  key=='P_MCP_LAYOUT' ) then
      local retval, stringNeedBig = GetSetMediaTrackInfo_String( src_tr, key, '', 0 )
      GetSetMediaTrackInfo_String( dest_tr, key, stringNeedBig, 1 )
      if DATA2.srcproj.is_tracktemplatemode == true then
        GetSetMediaTrackInfo_String( dest_tr, key, DATA2.srcproj.TRACK[1].NAME, 1 )
      end
     else 
      local val = GetMediaTrackInfo_Value( src_tr,key )
      SetMediaTrackInfo_Value( dest_tr, key, val )  
    end
  end
  -------------------------------------------------------------------- 
  function DATA2:Import_TransferTrackData(src_tr, dest_tr, obeystructure) -- AND remove track
    if not src_tr and dest_tr then return end
    if DATA.extstate.CONF_tr_name == 1 then         DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'P_NAME') end
    if DATA.extstate.CONF_tr_VOL == 1 then          DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_VOL') end
    if DATA.extstate.CONF_tr_PAN == 1 then 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_PAN') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_WIDTH') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_DUALPANL') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_DUALPANR') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_PANMODE') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_PANLAW') 
    end
    if DATA.extstate.CONF_tr_PHASE== 1 then         DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'B_PHASE') end
    if DATA.extstate.CONF_tr_CUSTOMCOLOR== 1 then   DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_CUSTOMCOLOR') end
    if DATA.extstate.CONF_tr_GROUPMEMBERSHIP== 1 then   DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'GROUPMEMBERSHIP') end
    if DATA.extstate.CONF_tr_LAYOUTS== 1 then   DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'P_MCP_LAYOUT') 
                                                DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'P_TCP_LAYOUT') end
    if obeystructure then   DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_FOLDERDEPTH') end
    if DATA.extstate.CONF_tr_RECINPUT  == 1 then    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_RECINPUT') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_RECMODE') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_RECMON') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_RECMONITEMS') 
    end
    if DATA.extstate.CONF_tr_MAINSEND  == 1 then    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'B_MAINSEND') 
                                                    DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'C_MAINSEND_OFFS') 
    end
    if DATA.extstate.CONF_tr_FX> 0 then             DATA2:Import_TransferTrackData_FXchain(src_tr, dest_tr) end
    if DATA.extstate.CONF_tr_it> 0 then             DATA2:Import_TransferTrackData_Items(src_tr, dest_tr) end
    --if DATA.extstate.CONF_tr_SEND> 0 then           DATA2:Import_TransferTrackData_Send(src_tr, dest_tr) end
    
    DeleteTrack( src_tr ) -- remove temporary
  end 
  -------------------------------------------------------------------- 
  function DATA2:Import_CreateNewTrack(needblank, srct)
    InsertTrackAtIndex( CountTracks( 0 ), false )
    local new_tr = GetTrack(0, CountTracks( 0 )-1)
    if needblank then return new_tr end
    local new_chunk = srct.chunk_full
    local gGUID = genGuid('' ) 
    new_chunk = new_chunk:gsub('TRACK[%s]+.-\n', 'TRACK '..gGUID..'\n')
    new_chunk = new_chunk:gsub('AUXRECV .-\n', '\n')
    SetTrackStateChunk( new_tr, new_chunk, false )
    return new_tr
  end
  ---------------------------------------------------------------------  
  function DATA2:ProcessAtChange() 
  
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
        
    local  t = 
    { 
      {str = 'Track properties' ,                         group = 1, itype = 'sep'}, 
        {str = 'Name' ,                                   group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_name'},
        {str = 'Volume' ,                                 group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_VOL'},
        {str = 'Pan / Width / Pan Law / Pan mode' ,       group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_PAN'},
        {str = 'Phase' ,                                  group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_PHASE'},
        {str = 'Record input / Monitoring' ,              group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_RECINPUT'},
        {str = 'Parent send / channels' ,                 group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_MAINSEND'},
        {str = 'Color' ,                                  group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_CUSTOMCOLOR'},
        {str = 'Layout' ,                                 group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_LAYOUTS'},
        {str = 'Group flags' ,                            group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_GROUPMEMBERSHIP'},
        --{str = 'Folder depth' ,                         group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_FOLDERDEPTH', hide= DATA.extstate.CONF_resetfoldlevel==1},
        
        
      {str = 'Track items' ,                              group = 3, itype = 'sep'},
        {str = 'Import track items' ,                     group = 3, itype = 'check', level = 1, confkey = 'CONF_tr_it',confkeybyte = 0},
        {str = 'Clear destination track existing items' , group = 3, itype = 'check', level = 1, confkey = 'CONF_tr_it',confkeybyte = 1},
        {str = 'Offset at edit cursor' ,                  group = 3, itype = 'check', level = 1, confkey = 'CONF_tr_it',confkeybyte = 2},
          --{str = 'Relink files paths to absolute' ,     group = 1, itype = 'check', level = 2, confkey = 'CONF_tr_it',confkeybyte = 2, hide=DATA.extstate.CONF_tr_it&1~=1},
       
      {str = 'Track FX chain' ,                           group = 4, itype = 'sep'},   
        {str = 'Import track FX chain' ,                  group = 4, itype = 'check', level = 1, confkey = 'CONF_tr_FX',confkeybyte = 0},
          {str = 'FX envelopes' ,                         group = 4, itype = 'check', level = 2, confkey = 'CONF_tr_FX',confkeybyte = 2, hide= DATA.extstate.CONF_tr_FX&1~=1},
        {str = 'Clear destination track existing FX' ,    group = 4, itype = 'check', level = 1, confkey = 'CONF_tr_FX',confkeybyte = 1},
        
      {str = 'Track import options' ,                     group = 2, itype = 'sep'}, 
        {str = 'Build any missing peaks' ,                group = 2, itype = 'check', level = 1, confkey = 'CONF_it_buildpeaks'},
        --{str = 'Reset folder level' ,                   group = 2, itype = 'check', level = 1, confkey = 'CONF_resetfoldlevel'},
        --{str = 'Import invisible filtered out tracks' , group = 2, itype = 'check', level = 1, confkey = 'CONF_importinvisibletracks'},
        --{str = 'Set dest. track',                       group = 2, itype = 'readout', readoutw_extw=readoutw_extw, menu = {[0] = 'Replace if used', [1] = 'Not allow to replace'},confkey = 'CONF_tr_destset', level = 1},CONF_tr_destset = 0,
        --{str = 'Sends' ,                                  group = 2, itype = 'check', level = 1, confkey = 'CONF_tr_SEND'},
      
      {str = 'Project header' ,                           group = 6, itype = 'sep'}, 
        {str = 'Master FX' ,                              group = 6, itype = 'check', level = 1, confkey = 'CONF_head_mast_FX'},
        {str = 'Markers / Regions' ,                      group = 6, itype = 'button', level = 1}, 
          {str = 'Offset at edit cursor' ,                group = 6, itype = 'check', level = 2, confkey = 'CONF_head_markers',confkeybyte = 4},
          {str = 'Markers' ,                              group = 6, itype = 'check', level = 2, confkey = 'CONF_head_markers',confkeybyte=0},
            {str = 'Clear existing markers' ,             group = 6, itype = 'check', level = 3, confkey = 'CONF_head_markers',confkeybyte=1, hide= DATA.extstate.CONF_head_markers&1~=1},
          {str = 'Regions' ,                              group = 6, itype = 'check', level = 2, confkey = 'CONF_head_markers',confkeybyte=2},
            {str = 'Clear existing regions' ,             group = 6, itype = 'check', level = 3, confkey = 'CONF_head_markers',confkeybyte=3, hide= DATA.extstate.CONF_head_markers&4~=4},
        {str = 'Tempo / time signature' ,                 group = 6, itype = 'check', level = 1, confkey = 'CONF_head_tempo',confkeybyte = 0}, 
          {str = 'Offset at edit cursor' ,                group = 6, itype = 'check', level = 2, confkey = 'CONF_head_tempo',confkeybyte = 1, hide= DATA.extstate.CONF_head_tempo&1~=1},
        {str = 'Track group names' ,                      group = 6, itype = 'check', level = 1, confkey = 'CONF_head_groupnames',confkeybyte = 0}, 
        {str = 'Render format configuration' ,            group = 6, itype = 'check', level = 1, confkey = 'CONF_head_rendconf',confkeybyte = 0}, 
        
      {str = 'UI options' ,                               group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,                       group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse position' ,              group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        {str = 'Show tootips' ,                           group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        {str = 'Process on settings change',              group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
        {str = 'Parse source project at initialization',  group = 5, itype = 'check', confkey = 'UI_appatinit', level = 1,confkeybyte = 0},
          {str = 'Match source project tracks at init',   group = 5, itype = 'check', confkey = 'UI_appatinit', level = 2,confkeybyte = 1},
        {str = 'Match tracks on setting source',          group = 5, itype = 'check', confkey = 'UI_matchatsettingsrc', level = 1},
        {str = 'Match algorithm' ,                        group = 2, itype = 'readout', readoutw_extw=readoutw_extw, menu = {[1] = 'Exact match', [2] = 'At least one word match'}, level = 1, confkey = 'CONF_tr_matchmode'},
        
      
    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.34) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end