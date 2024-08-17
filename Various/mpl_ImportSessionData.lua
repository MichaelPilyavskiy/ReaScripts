-- @description ImportSessionData
-- @version 2.27
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=233358
-- @about This script allow to import tracks, items, FX etc from defined RPP project file
-- @changelog
--    # free matched track at set source destination to none





  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 2.27
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
                          UI_hidesrchiddentracks = 1,
                          
                          UI_trfilter = '',
                          UI_lastsrcproj = '',
                          UI_ignoretracklistselection = 1,
                          
                          -- track params
                          CONF_tr_name = 1,
                          CONF_tr_VOL = 1,
                          CONF_tr_PAN = 1,
                          CONF_tr_FX = 1, -- &2 clear existed
                          CONF_tr_it = 1, -- &2 clear existed &4relink files to full paths &4 edit cur offs &8 try fix relative path
                          CONF_tr_PHASE = 1,
                          CONF_tr_RECINPUT = 1,
                          CONF_tr_MAINSEND = 1,
                          CONF_tr_CUSTOMCOLOR = 1,
                          CONF_tr_LAYOUTS = 0,
                          CONF_tr_LAYOUTS = 0,
                          CONF_tr_GROUPMEMBERSHIP = 0, -- &1 import &2 try to not replace current project groups
                          --CONF_sendlogic_flags = 0, 
                          --CONF_sendlogic_flags_matched = 0, 
                          CONF_sendlogic_flags2 = 0,
                            --[[
                              0 - ignored
                            ]]
                          
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
    DATA2.destproj.fp_dir = GetParentFolder(projfn )
    DATA2.destproj.TRACK = {}
    local folderlev = 0
    
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local GUID = GetTrackGUID( tr )
      local tr_col =  GetTrackColor( tr )
      local folderd = GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' )
      
      local is_visible = GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP' ) --& GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER' )
      
      DATA2.destproj.TRACK[i] = {tr_name =  ({GetTrackName( tr )})[2],
                              GUID = GUID,
                              tr_col=tr_col,
                              folderd=folderd,
                              folderlev=folderlev,
                              }
      
      folderlev = folderlev + folderd                            
    end
    
    -- define free groups
    DATA2.destproj.usedtrackgroups = {}
    local t = {
    'MEDIA_EDIT_LEAD',
    'MEDIA_EDIT_FOLLOW',
    'VOLUME_LEAD',
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
    
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      for keyid = 1, #t do
        local groupname = t[keyid]
        local flags = reaper.GetSetTrackGroupMembership( tr, groupname, 0, 0 )
        local flags32 = reaper.GetSetTrackGroupMembershipHigh( tr, groupname, 0, 0 )
        for groupID = 1, 32 do
          local bitset = 1<<(groupID-1)
          if not DATA2.destproj.usedtrackgroups[groupID] and flags ~= 0 and flags&bitset == bitset then DATA2.destproj.usedtrackgroups[groupID] = true end
          if not DATA2.destproj.usedtrackgroups[groupID+32] and flags32 ~= 0 and flags32&bitset == bitset then DATA2.destproj.usedtrackgroups[groupID+32] = true end
        end
      end
    end
    
    DATA2.destproj.usedtrackgroups_map = {}
    local skip = 0
    for groupID = 1, 64 do
      if DATA2.destproj.usedtrackgroups[groupID] then skip = skip + 1 end
      if DATA2.destproj.usedtrackgroups[groupID + skip] then skip = skip + 1 end
      if groupID + skip <= 64 then DATA2.destproj.usedtrackgroups_map[groupID] = groupID + skip end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:VisibleCondition(trname)
    return (DATA.extstate.UI_trfilter == '' or not trname or (trname and DATA.extstate.UI_trfilter ~= '' and tostring(trname):lower():match(DATA.extstate.UI_trfilter)))
  end
  ---------------------------------------------------------------------  
  function DATA2:Get_DestProject_ValidateSameSources()    -- clean up source mapping if destination has multiple sources
    local dest_GUID_used = {}
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
  --[[-------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_DestMenu_Sendlogic(DATA,trid,set_flags) 
    local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA,trid) 
    if cnt_selection <= 1 then
      --if not DATA2.srcproj.TRACK[trid].sendlogic_flags then DATA2.srcproj.TRACK[trid].sendlogic_flags = DATA.extstate.CONF_sendlogic_flags end
      DATA2.srcproj.TRACK[trid].sendlogic_flags = set_flags--DATA2.srcproj.TRACK[trid].sendlogic_flags~togglestate
      GUI_RESERVED_BuildLayer(DATA)  
     else
      for trid0 = 1, #DATA2.srcproj.TRACK do 
        if DATA2.srcproj.TRACK[trid0].sel_isselected == true then 
          --if not DATA2.srcproj.TRACK[trid0].sendlogic_flags then DATA2.srcproj.TRACK[trid0].sendlogic_flags = DATA.extstate.CONF_sendlogic_flags end
          DATA2.srcproj.TRACK[trid0].sendlogic_flags = set_flags--DATA2.srcproj.TRACK[trid0].sendlogic_flags~togglestate 
        end 
      end
      GUI_RESERVED_BuildLayer(DATA)  
    end  
  
  end]]
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,mode,submode) 
    local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
    local tr_ids = {}
    
    -- if menu at track + no selection
      if cnt_selection == 0 then
        tr_ids[#tr_ids+1] = trid
      end
      
    -- if menu at track + selection + track is selected
      if cnt_selection > 0 and DATA2.srcproj.TRACK[trid].sel_isselected == true then
        for i = 1, #DATA2.srcproj.TRACK do
          if DATA2.srcproj.TRACK[i].sel_isselected == true then
            tr_ids[#tr_ids+1] = i
          end
        end
      end
      
    -- if menu at track + selection + track is not selected
      if cnt_selection > 0 and DATA2.srcproj.TRACK[trid].sel_isselected ~= true then
        tr_ids[#tr_ids+1] = trid
      end
  
     
    for i = 1,#tr_ids do
      local trid = tr_ids[i]
      DATA2.srcproj.TRACK[trid].destmode = mode
      if mode ==2  then DATA2.srcproj.TRACK[trid].destmode_submode = submode  end
      if mode ==0 or mode ==1 or mode ==3 then DATA2:Tracks_SetDestination(trid0, mode) end
      if mode ==2  then DATA2:MatchTrack(trid)  end
      if mode ==2 or mode ==3 then  DATA2:Get_DestProject_ValidateSameSources()  end 
      if mode ==0 then
        DATA2.srcproj.TRACK[trid].dest_track_GUID = nil
      end 
    end
    GUI_RESERVED_BuildLayer(DATA)  
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_DestMenu(DATA,trid) 
    DATA2:Get_DestProject()
    DATA2:Get_DestProject_ValidateSameSources()   
    
    -- form list of destination tracks
    local tracks = {}
    tracks[#tracks+1] = { str='Set destiination project track number',
                          func = function()  
                                    local retval, retvals_csv = reaper.GetUserInputs( 'Set destiination project track number', 1, '', '' )
                                    if not retval then return end
                                    if not tonumber(retvals_csv) then return end
                                    local i = tonumber(retvals_csv)
                                    if not DATA2.destproj.TRACK[i] then return end
                                    
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
                          
    for i= 1, #DATA2.destproj.TRACK do
      tracks[#tracks+1] = { str='['..i..'] '..DATA2.destproj.TRACK[i].tr_name,
                            hidden = DATA2:Tracks_IsDestinationUsed(i),
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
              func =  function() GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,0)  end}   ,
            {str='['..DATA.GUI.custom_intname1..']',
              state = DATA2.srcproj.TRACK[trid].destmode == 1 ,
              func =  function() GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,1)  end}   ,
            {str='['..DATA.GUI.custom_intname2..']',
              state = DATA2.srcproj.TRACK[trid].destmode == 3 ,
              func =  function() GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,3)  end}   ,                
            {str='Match by name: replace',
              state = DATA2.srcproj.TRACK[trid].destmode==2 and (not DATA2.srcproj.TRACK[trid].destmode_submode or (DATA2.srcproj.TRACK[trid].destmode_submode and DATA2.srcproj.TRACK[trid].destmode_submode==0)),
              func =  function() GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,2)  end}   , 
            {str='Match by name: place under matched track',
              state = DATA2.srcproj.TRACK[trid].destmode==2 and DATA2.srcproj.TRACK[trid].destmode_submode == 1, 
              func =  function() GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,2,1)  end}   , 
            {str='Match by name: place under matched track as child',
              state = DATA2.srcproj.TRACK[trid].destmode==2 and DATA2.srcproj.TRACK[trid].destmode_submode == 2,
              func =  function() GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,2,2)  end}   , 
            {str='Match by name: mark only|',
              state = DATA2.srcproj.TRACK[trid].destmode==2 and DATA2.srcproj.TRACK[trid].destmode_submode == 4,
              func =  function() GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,2,4)  end}   ,               
            --[[{str='Match by name: do not import, only mark for sends remap|',
              state = DATA2.srcproj.TRACK[trid].destmode==2 and DATA2.srcproj.TRACK[trid].destmode_submode == 3 ,
              func =  function() GUI_RESERVED_BuildLayer_DestMenu_Setmode(DATA,trid,2,3)  end}   , ]]
            --[[{str='#Handling sends'},
            {str='Import sends: off', state = DATA2.srcproj.TRACK[trid].sendlogic_flags&1== 0 , func = function() GUI_RESERVED_BuildLayer_DestMenu_Sendlogic(DATA,trid,0) end},                 
            {str='Import sends: enable|', state = DATA2.srcproj.TRACK[trid].sendlogic_flags&1== 1 , func = function() GUI_RESERVED_BuildLayer_DestMenu_Sendlogic(DATA,trid,1) end},             ]]    
            {str='#Destination project tracks'},
            table.unpack(tracks)
            }
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildLayer_Selection_Get(DATA,trid) 
    if not (DATA2.srcproj and DATA2.srcproj.TRACK) then return end
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
      if DATA.extstate.UI_hidesrchiddentracks==1 and not (DATA2.srcproj.TRACK[trid].SHOWINMIX[1] == 1 and DATA2.srcproj.TRACK[trid].SHOWINMIX[4] == 1 ) then goto skip_track end
      
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
        if DATA2.srcproj.TRACK[trid].destmode_submode == nil then dest = dest..' [replace]' end
        if DATA2.srcproj.TRACK[trid].destmode_submode == 1 then dest = dest..' [under]' end
        if DATA2.srcproj.TRACK[trid].destmode_submode == 2 then dest = dest..' [under, as child]' end
        if DATA2.srcproj.TRACK[trid].destmode_submode == 4 then dest = dest..' [mark only]' end
        --if DATA2.srcproj.TRACK[trid].sendlogic_flags&1==1 then dest = dest..' [sends]' end
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
      'SHOWINMIX',
      --'LAYOUTS',
                  }
    
    for tr_idx = 1, #DATA2.srcproj.TRACK do
      local chunk = DATA2.srcproj.TRACK[tr_idx].chunk
      DATA2.srcproj.TRACK[tr_idx].chunk_full = chunk -- used for raw data import 
      DATA2.srcproj.TRACK[tr_idx].GUID = chunk:match('(%{.-%})'):upper()
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
        --DATA2.srcproj.TRACK[tr_idx].GUID = DATA2.srcproj.TRACK[tr_idx].TRACK[1] 
        DATA2.srcproj.TRACK[tr_idx].TRACK = nil
        local name = DATA2.srcproj.TRACK[tr_idx].NAME[1] 
        DATA2.srcproj.TRACK[tr_idx].NAME = name
        local PEAKCOL = DATA2.srcproj.TRACK[tr_idx].PEAKCOL[1] 
        DATA2.srcproj.TRACK[tr_idx].PEAKCOL = PEAKCOL
        if not (DATA2.srcproj.TRACK[tr_idx].SHOWINMIX and DATA2.srcproj.TRACK[tr_idx].SHOWINMIX[4]) then DATA2.srcproj.TRACK[tr_idx].SHOWINMIX[4]= 1 end
        
      -- handle folder level
        local cur_fold_state = DATA2.srcproj.TRACK[tr_idx].ISBUS[2] or 0
        DATA2.srcproj.TRACK[tr_idx].CUST_foldlev = foldlev
        foldlev = foldlev + cur_fold_state
        DATA2.srcproj.TRACK[tr_idx].sendlogic_flags = DATA.extstate.CONF_sendlogic_flags
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
          local timesig = tonumber(valt[5]) or 0
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
          DATA2.srcproj.GROUPNAMES[groupid] = name:match('"(.*)"') or name
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
        end

        if not is_region_flags then 
          id, pos_sec, name, is_region_flags = line:match('MARKER ([%d]+) ([%d%p]+) (.-) ([%d]+)')
        end
        
        id = tonumber(id)
        pos_sec = tonumber(pos_sec)
        is_region_flags = tonumber(is_region_flags)
        col = tonumber(col)
        
        
        if not is_region_flags then goto skipnextmarkerentry end
        
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
      
      ::skipnextmarkerentry::
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
      if mode == 2 then DATA2.srcproj.TRACK[srctrack_id].sendlogic_flags = DATA.extstate.CONF_sendlogic_flags_matched end
      if DATA2.srcproj.TRACK[srctrack_id].dest_track_GUID then
        local desttrack_id = DATA2:Tracks_GetDestinationbyGUID( DATA2.srcproj.TRACK[srctrack_id].dest_track_GUID)
        if desttrack_id and DATA2.destproj.TRACK[desttrack_id] then 
          DATA2.destproj.TRACK[desttrack_id].has_source =false 
        end
      end
      DATA2.srcproj.TRACK[srctrack_id].dest_track_GUID = nil
    end
    
    -- set for all tracks
      if srctrack_id == -1 and mode&2 ~= 2 then 
        for i = 1, #DATA2.srcproj.TRACK do 
          if DATA2.srcproj.TRACK[i].dest_track_GUID then
            local desttrack_id = DATA2:Tracks_GetDestinationbyGUID( DATA2.srcproj.TRACK[i].dest_track_GUID)
            if desttrack_id and DATA2.destproj.TRACK[desttrack_id] then  
              DATA2.destproj.TRACK[desttrack_id].has_source =false 
            end
          end
          DATA2.srcproj.TRACK[i].dest_track_GUID = nil
          DATA2.srcproj.TRACK[i].destmode = mode  
        end 
      end
      
    -- set specific track
      if mode&2==2 and desttrack_id and not DATA2.destproj.TRACK[desttrack_id].has_source then
        if mode == 2 then DATA2.srcproj.TRACK[srctrack_id].sendlogic_flags = DATA.extstate.CONF_sendlogic_flags_matched end
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
    
    -- specific track match
    if specificid and DATA2.srcproj.TRACK[specificid] then 
      local tr_name = DATA2.srcproj.TRACK[specificid].NAME 
      DATA2:MatchTrack_Sub(tr_name, specificid) 
      return 
    end
    
    -- no specificid
    if not specificid then
      local cnt_selection = 0 
      for trid0 = 1, #DATA2.srcproj.TRACK do  
        if DATA2.srcproj.TRACK[trid0].sel_isselected == true then cnt_selection = cnt_selection + 1 end 
      end
      
      for i = 1, #DATA2.srcproj.TRACK do 
        if cnt_selection == 0 or (cnt_selection > 0 and DATA2.srcproj.TRACK[i].sel_isselected == true) then
          local tr_name = DATA2.srcproj.TRACK[i].NAME
          DATA2:MatchTrack_Sub(tr_name, i) 
        end
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
  function DATA2:Tracks_GetSourcebyGUID(GUID) 
    for j = 1, #DATA2.srcproj.TRACK do 
      --if GUID:gsub('[%s%p]+') == DATA2.srcproj.TRACK[j].GUID:gsub('[%s%p]+') then return j end 
      if GUID == DATA2.srcproj.TRACK[j].GUID then return j end 
    end 
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Tracks_AddSend(tr,dest)
    local exist
    for sendidx = 1, GetTrackNumSends( tr, 0 )do 
      local desttr = reaper.GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
      if desttr == dest then exist = true break end
    end 
    if not exist then CreateTrackSend( tr,dest) end
  end
  ----------------------------------------------------------------------
  function DATA2:Tracks_HasDestinationAim(GUID)
    if not GUID then return end
    for i = 1, #DATA2.srcproj.TRACK do
      if GUID == DATA2.srcproj.TRACK[i].GUID and 
        (
          (DATA2.srcproj.TRACK[i].destmode and DATA2.srcproj.TRACK[i].destmode&1==1) or 
          (DATA2.srcproj.TRACK[i].destmode and DATA2.srcproj.TRACK[i].destmode==2 and DATA2.srcproj.TRACK[i].dest_track_GUID)
        ) then return true,DATA2.srcproj.TRACK[i] end
    end
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Tracks_CheckExistingSend( tr,dest_tr)
    if not (tr and dest_tr) then return end
    for sendidx = 1,reaper.GetTrackNumSends( tr, 0 ) do
      local dest = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
      if dest == dest_tr then return true end
    end
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Tracks_ImportReceives_sub(srct)  
    
    if DATA.extstate.CONF_sendlogic_flags2&1==0 then return end
    local tr = VF_GetMediaTrackByGUID(0,srct.dest_track_GUID)
    if not tr then return end 
    
    if not srct.SENDS or (srct.SENDS and #srct.SENDS == 0) then return end
    
    for sendid = 1, #srct.SENDS do
      local receivetrackGUID = srct.SENDS[sendid].AUXRECV_DEST_GUID
      local ret, destt = DATA2:Tracks_HasDestinationAim(receivetrackGUID)
      if ret then -- receive tracks was imported 
      
        -- recreate send links
        if DATA.extstate.CONF_sendlogic_flags2&2==2 then
          local dest_tr = VF_GetMediaTrackByGUID(0,destt.dest_track_GUID)
          if not DATA2:Import2_Tracks_CheckExistingSend( tr,dest_tr) then
            local sendidx = CreateTrackSend( tr,dest_tr)
            DATA2:Import2_Tracks_ImportReceives_params(tr, sendidx, srct.SENDS[sendid]) 
          end
        end 
        
        -- add receive even if alread matched
        if DATA.extstate.CONF_sendlogic_flags2&4==4 then
          local receiveID = DATA2:Tracks_GetSourcebyGUID(receivetrackGUID) 
          local new_tr_rec = DATA2:Import_CreateNewTrack(false, DATA2.srcproj.TRACK[receiveID]) 
          local dest_tr = DATA2:Import_CreateNewTrack(true)
          DATA2:Import_TransferTrackData(new_tr_rec, dest_tr)
          DATA2.srcproj.TRACK[receiveID].dest_track_GUID = GetTrackGUID( dest_tr ) 
          local sendidx = CreateTrackSend( tr,dest_tr)
          DATA2:Import2_Tracks_ImportReceives_params(tr, sendidx, srct.SENDS[sendid]) 
        end
        
       else --  receive tracks was NOT imported  
       
        -- add receive / transfer parameters
        local receiveID = DATA2:Tracks_GetSourcebyGUID(receivetrackGUID) 
        local new_tr_rec = DATA2:Import_CreateNewTrack(false, DATA2.srcproj.TRACK[receiveID]) 
        local dest_tr = DATA2:Import_CreateNewTrack(true)
        DATA2:Import_TransferTrackData(new_tr_rec, dest_tr)
        DATA2.srcproj.TRACK[receiveID].dest_track_GUID = GetTrackGUID( dest_tr ) 
        local sendidx = CreateTrackSend( tr,dest_tr)
        DATA2:Import2_Tracks_ImportReceives_params(tr, sendidx, srct.SENDS[sendid]) 
        
      end
    end
    
    
    
    
    --[[local tr 
    if srct.dest_track_GUID then tr = VF_GetMediaTrackByGUID(0,srct.dest_track_GUID) end
    if not tr then return end
    
    
    if srct.destmode == 2 and srct.sendlogic_flags&2==2 then -- matched track / clear detination track receives
      for sendidx = GetTrackNumSends( tr, -1 ),1,-1 do RemoveTrackSend( tr, -1, sendidx-1 ) end
    end 
    
    if srct.destmode == 2 and srct.sendlogic_flags&4==4 then -- matched track / clear detination track sends
      for sendidx = GetTrackNumSends( tr, 0 ),1,-1 do RemoveTrackSend( tr, 0, sendidx-1 ) end
    end 
    
    for sendID = 1, #srct.SENDS do
      if srct.sendlogic_flags&8==8 then
        local dest_GUID = srct.SENDS[sendID].AUXRECV_DEST_GUID
        if not dest_GUID then goto nextsend end
        for trsrcid = 1, #DATA2.srcproj.TRACK do
          if DATA2.srcproj.TRACK[trsrcid].GUID and DATA2.srcproj.TRACK[trsrcid].GUID == dest_GUID and DATA2.srcproj.TRACK[trsrcid].destmode == 2 and DATA2.srcproj.TRACK[trsrcid].dest_track_GUID then -- send destination exist and imported
            local dest = VF_GetMediaTrackByGUID(0,DATA2.srcproj.TRACK[trsrcid].dest_track_GUID) 
            DATA2:Import2_Tracks_AddSend(tr, dest)
          end
        end
      end
      ::nextsend::
    end]]
    
    
    
    
    --[[
    for sendID = 1, #srct.SENDS do
    end
      
      if srct.destmode == 1 then end-- new track
      if srct.destmode == 2 and srct.dest_track_GUID then end -- matched track
      -- new tracks
        -- if there is no send imported, auto add it as new track
        -- if there is no receive imported, auto add it as new track
        -- clean/replace existing routing
        
      -- matched tracks
        -- if there is no send imported, auto add it as new track
        -- if there is no receive imported, auto add it as new track
        -- clean/replace existing routing
        
      --[[local destination_GUID = srct.SENDS[sendID].AUXRECV_DEST_GUID
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
      end]]
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Tracks_ImportReceives()  
    for tr_id = 1, #DATA2.srcproj.TRACK do
      local srct = DATA2.srcproj.TRACK[tr_id] 
      --if not (srct.sendlogic_flags and srct.sendlogic_flags&1==1 and srct.SENDS) then goto skiptr end
      DATA2:Import2_Tracks_ImportReceives_sub(srct)   
      ::skiptr::
    end
  end
  ----------------------------------------------------------------------
  function DATA2:Import2_Tracks() 
    local cnt_selection = GUI_RESERVED_BuildLayer_Selection_Get(DATA) 
    --local ret_conflict = DATA2:Import2_Tracks_ValidateDestinationConflicts() 
    --if ret_conflict then msg('fffuu') return end
    
    for i = 1, #DATA2.srcproj.TRACK do
      local srct = DATA2.srcproj.TRACK[i]
      if not DATA2:VisibleCondition(DATA2.srcproj.TRACK[i].NAME) 
        or (DATA.extstate.UI_ignoretracklistselection == 0 and cnt_selection > 0 and not DATA2.srcproj.TRACK[i].sel_isselected) then 
        goto importnexttrack 
      end
      
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
        if not (srct.destmode_submode and srct.destmode_submode == 3) then
          
          local new_tr_src = DATA2:Import_CreateNewTrack(false, srct)
          local dest_tr 
          local srcpos_tr = VF_GetTrackByGUID(srct.dest_track_GUID)
          
          if not srct.destmode_submode then
            dest_tr = srcpos_tr
           elseif srct.destmode_submode == 1 or srct.destmode_submode ==2 then
            dest_tr = DATA2:Import_CreateNewTrack(true)
          end 
          DATA2:Import_TransferTrackData(new_tr_src, dest_tr) 
          --srct.dest_track_GUID = GetTrackGUID( dest_tr )
          
          if srct.destmode_submode == 1 or srct.destmode_submode ==2 then
            SetOnlyTrackSelected( dest_tr )
            makePrevFolder = 0
            if srct.destmode_submode ==2 then makePrevFolder = 1 end
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
        local idx = AddProjectMarker2( 0, false, pos_sec+offs, -1, DATA2.srcproj.MARKERS[i].name, DATA2.srcproj.MARKERS[i].id, DATA2.srcproj.MARKERS[i].col )
      end
    
      -- add regions from table
      if DATA2.srcproj.MARKERS[i].is_region==true and DATA.extstate.CONF_head_markers&4 == 4 then
        local pos_sec=TimeMap2_beatsToTime( 0, DATA2.srcproj.MARKERS[i].pos )
        local end_sec=TimeMap2_beatsToTime( 0, DATA2.srcproj.MARKERS[i].rgnend or DATA2.srcproj.MARKERS[i].pos )
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
    
    if DATA.extstate.CONF_head_tempo&4 == 4 then -- clear
      for markerindex = CountTempoTimeSigMarkers( 0 ), 1, -1 do DeleteTempoTimeSigMarker( 0, markerindex-1 ) end
    end
    
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
    
    if DATA.extstate.CONF_head_rendconf == 1 and DATA2.srcproj.HEADER_renderconf then GetSetProjectInfo_String( 0, 'RENDER_FORMAT', DATA2.srcproj.HEADER_renderconf, 1 )  end
    
    DATA2:Get_DestProject()
    UpdateArrange()
    TrackList_AdjustWindows( false )
  end
    -------------------------------------------------------------------- 
  function CopyFile(old_path, new_path) 
    local old_file = io.open(old_path, "rb")
    if not old_file then return end
    local new_file = io.open(new_path, "wb")
    if not new_file then return end
    
    local content = old_file:read('a')
    new_file:write(content)
    
    old_file:close()
    new_file:close()
  end
  -------------------------------------------------------------------- 
  function DATA2:Import_TransferTrackData_Items_handlesources(chunk)  
    if not (DATA.extstate.CONF_tr_it&16 == 16 or DATA.extstate.CONF_tr_it&32 == 32) then return chunk end
    -- cache chunk
    local t = {}
    for line in chunk:gmatch('[^\r\n]+') do t[#t+1]=line end
    -- search for paths 
      for i = 1, #t do
        local line = t[i]
        if line:match('FILE ') then  
          line = line:match('FILE (.*)')
          if DATA2.destproj.fp_dir then line = line:gsub(literalize(DATA2.destproj.fp_dir)..'[%\\%/]', '') end
          if line:match('%"(.-)%"') then line = line:match('%"(.-)%"') end
          
          if not file_exists( line ) then
            local src_projpath = DATA2.srcproj.path..'/' 
            local test = src_projpath..line 
            if reaper.GetOS():lower():match('win') then test = test:gsub('/','\\') end
            
            if file_exists( test ) then  
              local output_file = test
              local proj_path = GetParentFolder(DATA2.destproj.fp)
              if DATA.extstate.CONF_tr_it&32 == 32 and proj_path then
                local srcfp = test
                local destfp = proj_path..'/'..line
                output_file = destfp
                CopyFile(srcfp,destfp)
              end  
              if reaper.GetOS():lower():match('win') then output_file = output_file:gsub('/','\\') end
              t[i] = 'FILE "'..output_file..'" 1'
            end
          end
            
        end
      end
    
    chunk = table.concat(t,'\n')
    return chunk
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
        chunk = DATA2:Import_TransferTrackData_Items_handlesources(chunk)  
        
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
    if not dest_tr then return end
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
  -------------------------------------------------------------------- 
  function DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, key)
    if not dest_tr then return end
    if key=='GROUPMEMBERSHIP'  then 
      local t = {
      'MEDIA_EDIT_FOLLOW',
      'MEDIA_EDIT_LEAD',
      'VOLUME_LEAD',
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
        -- bits 1-32
        local flags = GetSetTrackGroupMembership( src_tr,  t[i], 0, 0 ) 
        local flags32 = GetSetTrackGroupMembershipHigh( src_tr,  t[i], 0, 0 )
        local ouflags = flags
        local ouflags32 = flags32
        
        if DATA.extstate.CONF_tr_GROUPMEMBERSHIP&2==2 then 
          ouflags = 0 
          ouflags32= 0
          for i = 1, 32  do 
            local bitset = 1<<(i-1)
            local outgroup = DATA2.destproj.usedtrackgroups_map[i] 
            local outbit = 1<<(outgroup-1)
            if flags&bitset == bitset then ouflags = ouflags|outbit end
            
            local bitset32 = 1<<(i-1)
            local outgroup32 = DATA2.destproj.usedtrackgroups_map[i+32] 
            if outgroup32 then
              local outbit32 = 1<<(outgroup32-1)
              if flags32&bitset32 == bitset32 then ouflags32 = ouflags32|outbit32 end
            end
          end
         --[[else
          ouflags = flags
          ouflags32 = flags32]]
        end
        GetSetTrackGroupMembership( dest_tr,  t[i], ouflags, 0xFFFFFFFF )
        GetSetTrackGroupMembershipHigh( dest_tr,  t[i], ouflags32, 0xFFFFFFFF ) 
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
    if DATA.extstate.CONF_tr_GROUPMEMBERSHIP&1== 1 then   DATA2:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'GROUPMEMBERSHIP') end
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
    
    return new_tr,gGUID
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
        {str = 'Group flags' ,                            group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_GROUPMEMBERSHIP',confkeybyte = 0},
          {str = 'Try to not touch current groups' ,      group = 1, itype = 'check', level = 2, confkey = 'CONF_tr_GROUPMEMBERSHIP',confkeybyte = 1, hide= DATA.extstate.CONF_tr_GROUPMEMBERSHIP&1~=1},
        --{str = 'Folder depth' ,                         group = 1, itype = 'check', level = 1, confkey = 'CONF_tr_FOLDERDEPTH', hide= DATA.extstate.CONF_resetfoldlevel==1},
        
        
      {str = 'Track items' ,                              group = 3, itype = 'sep'},
        {str = 'Import track items' ,                     group = 3, itype = 'check', level = 1, confkey = 'CONF_tr_it',confkeybyte = 0}, 
          {str = 'Try fixing relative paths (experimental)' ,            group = 3, itype = 'check', level = 2, confkey = 'CONF_tr_it',confkeybyte = 4, hide=DATA.extstate.CONF_tr_it&1~=1},
          {str = 'Copy files (experimental)' ,                           group = 3, itype = 'check', level = 2, confkey = 'CONF_tr_it',confkeybyte = 5, hide=DATA.extstate.CONF_tr_it&1~=1},
        {str = 'Clear destination track existing items' , group = 3, itype = 'check', level = 1, confkey = 'CONF_tr_it',confkeybyte = 1},
        {str = 'Offset at edit cursor' ,                  group = 3, itype = 'check', level = 1, confkey = 'CONF_tr_it',confkeybyte = 2}, 
        {str = 'Build any missing peaks' ,                group = 3, itype = 'check', level = 1, confkey = 'CONF_it_buildpeaks'},
       
      {str = 'Track FX chain' ,                           group = 4, itype = 'sep'},   
        {str = 'Import track FX chain' ,                  group = 4, itype = 'check', level = 1, confkey = 'CONF_tr_FX',confkeybyte = 0},
          {str = 'FX envelopes' ,                         group = 4, itype = 'check', level = 2, confkey = 'CONF_tr_FX',confkeybyte = 2, hide= DATA.extstate.CONF_tr_FX&1~=1},
        {str = 'Clear destination track existing FX' ,    group = 4, itype = 'check', level = 1, confkey = 'CONF_tr_FX',confkeybyte = 1},
        
      {str = 'Send/receive import logic defaults',        group = 2, itype = 'sep'}, 
        {str = 'Import send/receives' ,                  group = 2, itype = 'check', level = 1, confkey = 'CONF_sendlogic_flags2',confkeybyte = 0}, 
          {str = 'Create links if receive tracks presented' ,group = 2, itype = 'check', level = 1, confkey = 'CONF_sendlogic_flags2',confkeybyte = 1, hide= DATA.extstate.CONF_sendlogic_flags2&1~=1},
          {str = 'Import receive tracks in whatever case' ,group = 2, itype = 'check', level = 1, confkey = 'CONF_sendlogic_flags2',confkeybyte = 2, hide= DATA.extstate.CONF_sendlogic_flags2&1~=1},
      
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
          {str = 'Clear existing envelope' ,              group = 6, itype = 'check', level = 2, confkey = 'CONF_head_tempo',confkeybyte = 2, hide= DATA.extstate.CONF_head_tempo&1~=1},
        {str = 'Track group names' ,                      group = 6, itype = 'check', level = 1, confkey = 'CONF_head_groupnames',confkeybyte = 0}, 
        {str = 'Render format configuration' ,            group = 6, itype = 'check', level = 1, confkey = 'CONF_head_rendconf',confkeybyte = 0}, 
        
      {str = 'UI options' ,                               group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,                       group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse position' ,              group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        {str = 'Show tootips' ,                           group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        {str = 'Ignore tracklist selection at import' ,   group = 5, itype = 'check', confkey = 'UI_ignoretracklistselection', level = 1},
        {str = 'Process on settings change',              group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
        {str = 'Parse source project at initialization',  group = 5, itype = 'check', confkey = 'UI_appatinit', level = 1,confkeybyte = 0},
          {str = 'Match source project tracks at init',   group = 5, itype = 'check', confkey = 'UI_appatinit', level = 2,confkeybyte = 1},
        {str = 'Match tracks on setting source',          group = 5, itype = 'check', confkey = 'UI_matchatsettingsrc', level = 1},
        {str = 'Match algorithm' ,                        group = 5, itype = 'readout', readoutw_extw=readoutw_extw, menu = {[1] = 'Exact match', [2] = 'At least one word match'}, level = 1, confkey = 'CONF_tr_matchmode'},
        
        {str = 'Hide src proj hidden tracks in list' ,        group = 5, itype = 'check', confkey = 'UI_hidesrchiddentracks', level = 1},
        
      
    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.34) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end