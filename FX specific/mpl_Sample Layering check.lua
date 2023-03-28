-- @description Sample Layering check
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Share samples into selected track, use selected MIDI item as destination for step sequencer
-- @changelog
--    + Init


 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  -- config defaults
  DATA2 = { 
    scenes = {
      rows = {}
      }, 
          }
  ---------------------------------------------------------------------  
  function DATA2:WriteData_RS5kCheck_GetInstance(tr, scene, row) 
    local des_name = 'SPLCHECK_SC'..scene..'_R'..row
    local fx_out
    local fxcount = TrackFX_GetCount( tr )
    for fxid =1 , fxcount do
      local retval, fx_name = TrackFX_GetNamedConfigParm( tr, fxid-1, 'renamed_name' )
      if fx_name == des_name then 
        return fxid-1
      end
    end
    
    if not fx_out then 
      fx_out = TrackFX_AddByName( tr, 'ReaSamplOmatic5000', false, -1 )
      TrackFX_SetNamedConfigParm( tr, fx_out, 'renamed_name', des_name )
      for step= 1, 16 do
        TrackFX_SetNamedConfigParm( tr, fx_out, 'FILE'..(step-1), ' ') 
      end
      TrackFX_SetNamedConfigParm( tr, fx_out, 'DONE', '' )
      local channel = scene/16
      TrackFX_SetParamNormalized(tr, fx_out, 7, channel )
      TrackFX_SetParamNormalized(tr, fx_out, 18, 16/128 ) -- max velocity
      TrackFX_SetParamNormalized(tr, fx_out, 3, row/128 ) -- noterange st
      TrackFX_SetParamNormalized(tr, fx_out, 4, row/128  ) -- noterange en
      reaper.TrackFX_Show( tr, fx_out,2 )
      return fx_out
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:WriteData_RS5kCheck(tr)  
    for scene in pairs(DATA2.scenes) do
    
      if DATA2.scenes[scene].rows then 
        for row in pairs(DATA2.scenes[scene].rows) do 
          if DATA2.scenes[scene].rows[row].steps then 
            for step in pairs(DATA2.scenes[scene].rows[row].steps) do
              if DATA2.scenes[scene].rows[row].steps[step].fp then
                local fx_SCENE_ROW = DATA2:WriteData_RS5kCheck_GetInstance(tr, scene, row) 
                if fx_SCENE_ROW and fx_SCENE_ROW >=0 then
                  local retval, fp = TrackFX_GetNamedConfigParm( tr, fx_SCENE_ROW, 'FILE'..(step-1))
                  if fp ~= DATA2.scenes[scene].rows[row].steps[step].fp then
                    TrackFX_SetNamedConfigParm( tr, fx_SCENE_ROW, 'FILE'..(step-1), DATA2.scenes[scene].rows[row].steps[step].fp )
                    TrackFX_SetNamedConfigParm( tr, fx_SCENE_ROW, 'DONE', '' )
                  end
                end
              end
            end 
          end 
        end 
      end 
    end
  end          
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '1.0alpha1'
    DATA.extstate.extstatesection = 'MPL_SplCheck'
    DATA.extstate.mb_title = 'Spl Layering check'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  500,
                          wind_h =  500,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, 
                          
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
    DATA2:ReadTrack()  
    DATA:GUIinit()
    RUN()
  end
  ---------------------------------------------------------------------  
  function GUI_BuildUI(DATA)
    GUI_MODULE_scenes(DATA)
    GUI_MODULE_clips(DATA)
    DATA.GUI.layers_refresh[2]=true -- update buttons
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_scenes(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('gridscenes') then DATA.GUI.buttons[key] = nil end end
    DATA.GUI.buttons.gridscenes_scenesinfo = { x=DATA.GUI.custom_generalxoffs,
                          y=DATA.GUI.custom_generalyoffs,
                          w=DATA.GUI.custom_cellW*2-1,
                          h=DATA.GUI.custom_butinfoh-1,
                          txt = 'Scenes',
                          txt_fontsz = DATA.GUI.custom_txtsz1,
                          frame_a = 0,
                          ignoremouse = true,
                          onmouseclick = function()
                          end,
                          } 
    for scene = 1, 16 do
      local frame_a = DATA.GUI.custom_step_frameaoff
      local backgr_fill = DATA.GUI.custom_step_filloff
      local backgr_col = '#333333'
      if DATA2.scenes[scene] and DATA2.scenes[scene].selected == 1 then frame_a = DATA.GUI.custom_step_frameaon end
      if DATA2.scenes[scene] then backgr_fill = DATA.GUI.custom_step_fillon backgr_col=DATA.GUI.custom_step_colon end
      DATA.GUI.buttons['gridscenes_scene'..scene] = { x=DATA.GUI.custom_generalxoffs + DATA.GUI.custom_cellW*(scene-1),
                            y=DATA.GUI.custom_generalyoffs+DATA.GUI.custom_butinfoh,
                            w=DATA.GUI.custom_cellW-DATA.GUI.custom_offset,
                            h=DATA.GUI.custom_cellH-DATA.GUI.custom_offset,
                            txt = scene,
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            frame_a = frame_a,
                            backgr_fill=backgr_fill,
                            backgr_col=backgr_col,
                            onmouseclick = function()
                              if not DATA2.scenes[scene] then DATA2.scenes[scene] = {} end
                              for scene in pairs(DATA2.scenes) do if DATA2.scenes[scene].selected then DATA2.scenes[scene].selected = 0 end end
                              DATA2.scenes[scene].selected = 1
                              DATA2:WriteData()
                              GUI_BuildUI(DATA)
                            end,
                            } 
    end
  end
  ----------------------------------------------------------------------
  function DATA2:GetSelectedScene(DATA)
    for scene in pairs(DATA2.scenes) do if DATA2.scenes[scene].selected and DATA2.scenes[scene].selected == 1 then return scene end end
    return 1
  end
  ----------------------------------------------------------------------
  function DATA2:SetStep(activescene, row, step, set, toggle)
    if not DATA2.scenes[activescene] then DATA2.scenes[activescene] = {} end
    if not DATA2.scenes[activescene].rows then DATA2.scenes[activescene].rows = {} end
    if not DATA2.scenes[activescene].rows[row] then DATA2.scenes[activescene].rows[row] = {} end
    if not DATA2.scenes[activescene].rows[row].steps then DATA2.scenes[activescene].rows[row].steps = {} end
    if not DATA2.scenes[activescene].rows[row].steps[step] then DATA2.scenes[activescene].rows[row].steps[step] = {state = 0} end
    
    local outval = 0 
    if set then outval = set end
    if toggle then outval = DATA2.scenes[activescene].rows[row].steps[step].state~1 end 
    DATA2.scenes[activescene].rows[row].steps[step].state = outval
    if outval == 1 then
      local row_group = (row-1)%3
      for row_ch = 1, 9 do
        if (row_ch-1)%3 == row_group and row_ch ~= row then DATA2:SetStep(activescene, row_ch, step, 0) end
      end
    end 
  end
  ----------------------------------------------------------------------
  function GUI_MODULE_clips(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('gridclips') then DATA.GUI.buttons[key] = nil end end
    local yoffs = DATA.GUI.custom_generalyoffs+DATA.GUI.custom_butinfoh+DATA.GUI.custom_cellH
    DATA.GUI.buttons.clipinfo = { x=DATA.GUI.custom_generalxoffs,
                          y=yoffs,
                          w=DATA.GUI.custom_cellW*2-1,
                          h=DATA.GUI.custom_butinfoh-1,
                          txt = 'Steps',
                          txt_fontsz = DATA.GUI.custom_txtsz1,
                          frame_a = 0,
                          ignoremouse = true,
                          onmouseclick = function()
                          end,
                          } 
    local rowoffs = 0
    local activescene = DATA2:GetSelectedScene(DATA)
    for row = 1, 9 do
      rowoffs = math.floor((row-1)/3) * DATA.GUI.custom_cellspace
      for step = 1, 16 do
        local frame_a = DATA.GUI.custom_step_frameaoff
        local backgr_fill = DATA.GUI.custom_step_filloff
        local backgr_col = '#333333'
        local frame_col = '#5F5F5F'
        local name = ''
        if  
          DATA2.scenes[activescene] and
          DATA2.scenes[activescene].rows and 
          DATA2.scenes[activescene].rows[row] and 
          DATA2.scenes[activescene].rows[row].steps and 
          DATA2.scenes[activescene].rows[row].steps[step] then 
          if DATA2.scenes[activescene].rows[row].steps[step].state and DATA2.scenes[activescene].rows[row].steps[step].state ==1 then frame_col = '#BFBFBF' end
          if DATA2.scenes[activescene].rows[row].steps[step].fp and DATA2.scenes[activescene].rows[row].steps[step].fp ~='' then name = VF_GetShortSmplName(DATA2.scenes[activescene].rows[row].steps[step].fp) end
        end
        --if DATA2.scenes[scene] then backgr_fill = DATA.GUI.custom_step_fillon backgr_col=DATA.GUI.custom_step_colon end
        DATA.GUI.buttons['gridclips_row'..row..'step'..step] = { x=DATA.GUI.custom_generalxoffs + DATA.GUI.custom_cellW*(step-1),
                              y=yoffs+DATA.GUI.custom_butinfoh+rowoffs+(row-1)*DATA.GUI.custom_cellH,
                              w=DATA.GUI.custom_cellW-DATA.GUI.custom_offset,
                              h=DATA.GUI.custom_cellH-DATA.GUI.custom_offset,
                              txt = name,
                              txt_fontsz = DATA.GUI.custom_stepfontsz,
                              frame_a = 1,
                              frame_asel = 0.8,
                              frame_col = frame_col,
                              onmouseclick = function()
                                ClearConsole()
                                local activescene = DATA2:GetSelectedScene(DATA)
                                DATA2:SetStep(activescene, row, step, nil, true) 
                                DATA2:WriteData()
                                GUI_BuildUI(DATA)
                              end,
                              onmousefiledrop = function() 
                                local activescene = DATA2:GetSelectedScene(DATA)
                                DATA2:SetStep(activescene, row, step)
                                DATA2.scenes[activescene].rows[row].steps[step].fp = DATA.GUI.droppedfiles.files[0]
                                DATA2:WriteData(true)
                                GUI_BuildUI(DATA)
                              end
                              } 
      end
    end
    
    DATA.GUI.buttons.gridclips_Zstepback1 = { x=DATA.GUI.custom_generalxoffs-1,
                          y=yoffs+DATA.GUI.custom_butinfoh-1,
                          w=DATA.GUI.custom_cellW*4 - DATA.GUI.custom_offset+2,
                          h=DATA.GUI.custom_cellH*10,
                          txt_fontsz = DATA.GUI.custom_txtsz1,
                          frame_a = 0,
                          backgr_fill = 0.35,
                          backgr_col = '#FFFFFF',
                          ignoremouse = true,
                          } 
                          
    DATA.GUI.buttons.gridclips_Zstepback2 = { x=DATA.GUI.custom_generalxoffs+DATA.GUI.custom_cellW*8-1,
                          y=yoffs+DATA.GUI.custom_butinfoh-1,
                          w=DATA.GUI.custom_cellW*4 - DATA.GUI.custom_offset+2,
                          h=DATA.GUI.custom_cellH*10,
                          txt_fontsz = DATA.GUI.custom_txtsz1,
                          frame_a = 0,
                          backgr_fill = 0.35,
                          backgr_col = '#FFFFFF',
                          ignoremouse = true,
                          }                           
  end
  ----------------------------------------------------------------------
  function GUI_RESERVED_init(DATA)
    DATA.GUI.buttons = {} 
    -- get globals
      local gfx_h = math.floor(gfx.h/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
      local gfx_w = math.floor(gfx.w/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
      DATA.GUI.custom_gfx_wreal = gfx_w
      DATA.GUI.custom_gfx_hreal = gfx_h 
      DATA.GUI.custom_referenceH = 250
      DATA.GUI.custom_Yrelation = math.max(gfx_h/DATA.GUI.custom_referenceH, 0.5) -- global W
      DATA.GUI.custom_Yrelation = math.min(DATA.GUI.custom_Yrelation, 1) -- global W
      DATA.GUI.custom_offset =  math.floor(6 * DATA.GUI.custom_Yrelation)
      --DATA.GUI.default_scale = 1
    
    -- UI stuff
      DATA.GUI.custom_step_frameaoff = 0.4
      DATA.GUI.custom_step_frameaon = 0.8
      DATA.GUI.custom_step_filloff = 0.5
      DATA.GUI.custom_step_fillon = 0.4
      DATA.GUI.custom_step_coloff =  '#333333'
      DATA.GUI.custom_step_colon =  '#FFFFFF' 
      DATA.GUI.custom_stepfontsz = math.floor(13 * DATA.GUI.custom_Yrelation)
      
      DATA.GUI.custom_generalxoffs = DATA.GUI.custom_offset
      DATA.GUI.custom_generalyoffs = DATA.GUI.custom_offset
      
      DATA.GUI.custom_butinfow = math.floor(100 * DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_butinfoh = math.floor(25 * DATA.GUI.custom_Yrelation)
        
      DATA.GUI.custom_cellW = math.floor((DATA.GUI.custom_gfx_wreal-DATA.GUI.custom_generalxoffs*2)/16)
      DATA.GUI.custom_cellH = math.floor((DATA.GUI.custom_gfx_hreal-DATA.GUI.custom_generalyoffs*2-DATA.GUI.custom_butinfoh*2)/11)
      DATA.GUI.custom_cellspace = math.floor(DATA.GUI.custom_cellH/2)
      
      
    GUI_BuildUI(DATA)
    
    --[[ grid
      DATA.GUI.custom_gridw = DATA.GUI.custom_gfx_wreal - DATA.GUI.custom_offset*2
      DATA.GUI.custom_gridcell_w = math.floor(DATA.GUI.custom_gridw/(DATA.extstate.CONF_counttracksUI + 1))
      DATA.GUI.custom_gridcell_h = math.floor(25*DATA.GUI.custom_Yrelation) 
      DATA.GUI.custom_gridh = DATA.GUI.custom_gfx_hreal - DATA.GUI.custom_offset*3 - DATA.GUI.custom_gridcell_h 
      DATA.GUI.custom_txtsz_grid = math.floor(14*DATA.GUI.custom_Yrelation) -- grid cells
      DATA.GUI.custom_grid_x_offs = DATA.GUI.custom_offset 
      DATA.GUI.custom_grid_y_offs = DATA.GUI.custom_gridcell_h + DATA.GUI.custom_offset*2
      DATA.GUI.custom_gridcell_framea_inactive = 0.1
      DATA.GUI.custom_gridcell_framea_selcontrols = 0.3
      DATA.GUI.custom_gridcell_backgr_fillscenes = 0.1
      DATA.GUI.custom_gridcell_recttxta = 0.9
      DATA.GUI.custom_gridcell_controlw = math.floor(13*DATA.GUI.custom_Yrelation) 
      
    -- init button stuff
      DATA.GUI.custom_infobuth = DATA.GUI.custom_gridcell_h
      DATA.GUI.custom_infobut_w = DATA.GUI.custom_gridcell_w
      DATA.GUI.custom_txtsz1 = math.floor(15*DATA.GUI.custom_Yrelation) -- menu
      DATA.GUI.custom_txta = 1
      DATA.GUI.custom_txta_disabled = 0.3
      
      
      
    -- settings
      if not DATA.GUI.Settings_open then DATA.GUI.Settings_open = 0  end
      local x_offs = DATA.GUI.custom_offset
      DATA.GUI.buttons.settings = { x=x_offs,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_infobut_w-2,
                            h=DATA.GUI.custom_infobuth-1,
                            txt = '>',
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            --frame_a = 1,
                            onmouseclick = function()
                              if DATA.GUI.Settings_open then DATA.GUI.Settings_open = math.abs(1-DATA.GUI.Settings_open) else DATA.GUI.Settings_open = 1 end 
                              DATA.UPD.onGUIinit = true
                            end,
                            }
      x_offs = x_offs + DATA.GUI.custom_infobut_w
      DATA.GUI.buttons.actions = { x=x_offs,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_infobut_w-2,
                            h=DATA.GUI.custom_infobuth-1,
                            txt = 'Actions',
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            --frame_a = 1,
                            onmouseclick = function()
                              DATA:GUImenu(DATA2:Actions_Menu())
                              
                            end,
                            } 
      x_offs = x_offs + DATA.GUI.custom_infobut_w
      DATA.GUI.buttons.onstop = { x=x_offs,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_infobut_w-2,
                            h=DATA.GUI.custom_infobuth-1,
                            txt = 'Stop',
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            --frame_a = 1,
                            onmouseclick = function()
                              DATA2:Scenes_Transport_OnStop()
                            end,
                            }                              
                               
    GUI_BuildUI(DATA)
    ]]
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ---------------------------------------------------------------------  
  function DATA_RESERVED_ONPROJCHANGE(DATA) 
    DATA2:ReadTrack() 
    GUI_BuildUI(DATA)
  end
  ---------------------------------------------------------------------  
  function DATA2:ReadTrack()
    local tr = GetSelectedTrack(0,0)
    if not tr then return end 
    DATA2.trptr = tr
    local retval, scenes_str = GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLSPLCHECK', '', false )
    local scenes = table_str_load( scenes_str )
    DATA2.scenes = {}
    if scenes then DATA2.scenes = scenes end
  end
  ---------------------------------------------------------------------  
  function DATA2:WriteData_Item(it)
    local activescene = DATA2:GetSelectedScene(DATA)
    GetSetMediaItemInfo_String( it, 'P_EXT:MPLSPLCHECK_ACTSCENE', activescene, true )
    
    local stepmult = 0.25
    local itpos = GetMediaItemInfo_Value( it, 'D_POSITION' )
    local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, itpos )
     
    local take = GetActiveTake(it)
    if not (take and ValidatePtr(take,'MediaTake*') and TakeIsMIDI( take )) then return end
    
    -- clear notes
    local retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts( take )
    for noteidx = notecnt, 1, -1 do MIDI_DeleteNote( take, noteidx-1 ) end
    
    -- add notes
    if not DATA2.scenes[activescene] then return end
    if not DATA2.scenes[activescene].rows then return end
    for row in pairs(DATA2.scenes[activescene].rows) do
      for step in pairs(DATA2.scenes[activescene].rows[row].steps) do
        if DATA2.scenes[activescene].rows[row].steps[step].state == 1 then 
          local steppos = fullbeats + (step-1)*stepmult
          steppos = TimeMap2_beatsToTime( 0, steppos, 0 )
          steppos = MIDI_GetPPQPosFromProjTime( take, steppos )
          
          local stepend = fullbeats + step    *stepmult
          stepend = TimeMap2_beatsToTime( 0, stepend, 0 )
          stepend = MIDI_GetPPQPosFromProjTime( take, stepend )
          
          MIDI_InsertNote( take, false, false, steppos, stepend, activescene-1, row, step, true )
        end
      end
    end
    MIDI_Sort( take )
  end
  ---------------------------------------------------------------------  
  function DATA2:WriteData(refresh_rs5k) 
    -- write track ext state
      local tr = DATA2.trptr
      if (tr and ValidatePtr(tr,'MediaTrack*')) then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLSPLCHECK', table_str_save(DATA2.scenes), true ) 
        if refresh_rs5k then DATA2:WriteData_RS5kCheck(tr)  end
      end
    -- write midi to item
      local it = GetSelectedMediaItem(0,0)
      if (it and ValidatePtr(it,'MediaItem*')) then DATA2:WriteData_Item(it) end
  end
  -----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
  local function exportstring( s ) return string.format("%q", s) end 
  -----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
  function table_str_save(  tbl )
    local charS,charE = "   ","\n"
    local str_out=''
    
    -- initiate variables for save procedure
    local tables,lookup = { tbl },{ [tbl] = 1 }
    str_out=str_out..'\n'.."return {"..charE 
    
          for idx,t in ipairs( tables ) do
             str_out=str_out..'\n'.. "-- Table: {"..idx.."}"..charE 
             str_out=str_out..'\n'.."{"..charE
             local thandled = {}
    
             for i,v in ipairs( t ) do
                thandled[i] = true
                local stype = type( v )
                -- only handle value
                if stype == "table" then
                   if not lookup[v] then
                      table.insert( tables, v )
                      lookup[v] = #tables
                   end
                   str_out=str_out..'\n'..charS.."{"..lookup[v].."},"..charE 
                elseif stype == "string" then
                   str_out=str_out..'\n'..charS..exportstring( v )..","..charE 
                elseif stype == "number" then
                   str_out=str_out..'\n'..charS..tostring( v )..","..charE 
                end
             end
    
             for i,v in pairs( t ) do
                -- escape handled values
                if (not thandled[i]) then
                
                   local str = ""
                   local stype = type( i )
                   -- handle index
                   if stype == "table" then
                      if not lookup[i] then
                         table.insert( tables,i )
                         lookup[i] = #tables
                      end
                      str = charS.."[{"..lookup[i].."}]="
                   elseif stype == "string" then
                      str = charS.."["..exportstring( i ).."]="
                   elseif stype == "number" then
                      str = charS.."["..tostring( i ).."]="
                   end
                
                   if str ~= "" then
                      stype = type( v )
                      -- handle value
                      if stype == "table" then
                         if not lookup[v] then
                            table.insert( tables,v )
                            lookup[v] = #tables
                         end
                         str_out=str_out..'\n'..str.."{"..lookup[v].."},"..charE 
                      elseif stype == "string" then
                         str_out=str_out..'\n'..str..exportstring( v )..","..charE 
                      elseif stype == "number" then
                         str_out=str_out..'\n'..str..tostring( v )..","..charE 
                      end
                   end
                end
             end
             str_out=str_out..'\n'.. "},"..charE 
          end
          str_out=str_out..'\n'.. "}" 
          return str_out
       end
  -----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
  function table_str_load( str )
    if not (str and str ~= '' ) then return end
    local ftables = load( str )
    if not ftables then return end
    local tables = ftables()
    if not tables then return end
          for idx = 1,#tables do
             local tolinki = {}
             for i,v in pairs( tables[idx] ) do
                if type( v ) == "table" then
                   tables[idx][i] = tables[v[1]]
                end
                if type( i ) == "table" and tables[i[1]] then
                   table.insert( tolinki,{ i,tables[i[1]] } )
                end
             end
             -- link indices
             for _,v in ipairs( tolinki ) do
                tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
             end
          end
          return tables[1]
       end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end
