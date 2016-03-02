--[[
   * ReaScript Name: mpl Mapping Panel
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.24
  ]]

  local vrs = 1.24
  local changelog =
[===[ 
02.03.2016  1.24
            + Developer mode: bezier curves
17.02.2016  1.23
            # Potential error with #1009
            + vca() for basic mode - beta
14.01.2016  1.20
            # FL issues
11.01.2016  1.19
            + Basic functions examples in expert mode
            + DoubleClick on knob open first connection setup
            + GUI: Shortcut for Routing matrix
            + GUI: Shortcut for FixedLearn
            # FixedLearn data storing to global extstate by default
            + Actions: FixedLearn/Use exclusive learn for current instance
            + Actions: FixedLearn/Slider/Clear learn
            # Lowest value limited to 0.0000001 (this fix issues with -inf Freq params in ReaEQ)
            # Small performance improvements
            # Fixed Led state
            # Improved FixedLearn indication for sliders
09.01.2016  1.12
            # Caching function improvements. Still need testing. Any feedback welcome.
            + Expert mode for editing formula as Lua code
            + Expert mode / Formula templates / Condition (triangle)
            + Expert mode / Formula templates / Mouse
            + Expert mode / Formula templates / LFO
            + Expert mode / Formula templates / Cycle
            + Expert mode / Formula templates / Track Vol (0...2)
            + Expert mode / Formula templates / Track Pan (-1...+1)
            + Expert mode / Formula templates / Track Peak (Meter value)(0...2)
            + Expert mode / Formula templates / MasterRate
            + Add last touched to bottom info and to every empty slider
            # Fixed FixedLearn indicator not shown in slider when bypass not defined
            # Config for new version erased only if version <= 1.11            
08.01.2016  1.07
            # Fixed error when get last touched from renamed FX instamce
            # AutoRemove VST/AU/JS prefixes when get last touched
            # Show last touched in slider menu
            + Developer mode
07.01.2016  1.02
            # Show FixedLearn on empty sliders if FixedLearn is active
            # Slider/Clear slider also delete learn from linked parameter
            # Improved curve resolution
06.01.2016  1.0
            Official release
06.01.2016  0.68
            + Actions: RoutingSetup/Formula templates/match(x,curve)
            # OSX font issues
            # Blitted graph
            # Fixed wrong slider menu items
05.01.2016  0.66
            + Actions: RoutingSetup/Formula templates/scaleto(x,min,max)
            + Actions: RoutingSetup/Formula templates/power(x)
            + Actions: Slider/Change color
            + Actions: Maps/Clean duplicated sliders in all maps
            # Close when change project
            # Fixed run_docked issues
            # Tablet mode removed
            # Formula parsed to userinput
            # Removed Actions: Slider/Clear all duplicated sliders 
            # Save window width and height with script data
04.01.2016  0.6
            + Actions: Map/Bypass FixedLearn on current map
            + Actions: Slider/Routing
            + Actions: Slider/Clear all duplicated sliders 
            + Actions: RoutingSetup/Formula templates
            # Brackets for formula in chunk
            # GUI: Circle for showing current value on graph
            # Limit graph to 0...1  
03.01.2016  0.56
            + FixedLearn: MIDI Soft takeover check
            + FixedLearn: OSC
            + External: Change map by MIDICC/OSC - http://github.com/MichaelPilyavskiy/ReaScript_Test/tree/master/Beta
            + Caching formula functions, thanks to Xenakios
            + Actions: Slider/Remove all input wires from slider
            + Actions: Slider/Remove all output wires from slider
            + Actions: Slider/Remove all wires from slider
            + Actions: FixedLearn/AutoLearn MIDI CC
            + Actions: FixedLearn/Clean MIDI Learn
            + Actions: FixedLearn/Clean OSC Learn
            + Actions: FixedLearn/Clean MIDI and OSC Learn
            + GUI: FixedLearn color for midi/osc lists
            + GUI: FixedLearn if botton info
            # Improved map switching
            # Apply FixedLearn when get last touched
            # Fixed FixedLearn doesn`t work when maps changed from links/external control
            # Allow feedback for routing
30.12.2015  0.5
            + FixedLearn: MIDI
            + Routing: current map white rect
            + GUI: linked maps red rect
29.12.2015  0.44
            + Action: Map FX link actions
            + Action: Map track link actions
            + Action: Routing/Clear all routing configurations
            + Action: Routing/Clear current routing configuration
            + Action: Main/Run docked            
            + Slider count increased up to 16, fixed related issues
            # Improved routing graphics
            # Fixed store multiple routing configurations            
28.12.2015  0.41
            + Routing engine
            + Map slider
            + Routing config slider
            + Check for non-existing routing links when return from extstate            
            # Almost all stuff is rebuilded for better structure/performance/GUI 
20.12.2015  0.40
            + Routing: improved GUI, osc style knobs, master/slave imitation connections
            + Routing: store/parsing to/from data chunk
            + Support for mousewheel on sliders/knobs
            # Slider info always on bottom, trigger by click
            # Different GUI improvements
            # Defaults: maps quantity decreased down to 8            
17.12.2015  0.36
            + Action: Main/Routing matrix
            + Get last touched param support for master track
            + Pass through space key to Transport: Play/Stop
            # GUI: Calibri font
            # GUI: OSX font issues
            # Map selector packed to submenu
            # Fixed save/restore tablet mode
            # ENDSL for end slider chunk
            # Defaults: maps quantity decreased down to 10
            # Performance improvements
            # GUI improvements
16.12.2015  0.35
            + Alt & left click set slider to 0.5
            + Action: Map/Link current map to last touched track
            + Action: Map/Clear current map link to track
            + Action: Map/Clear all maps links to tracks
            # Defaults: relative slider tracking on
            # Removed empty line below the map name from ext data string
            # Removed empty sliders from ext data string
            # Removed confirm slider remove
            # Fixed first run slider mode error
16.12.2015  0.30 -- first public beta
            + GUI: 'About' window
            + Action: Main/Tablet mode
            + Action: Main/Store script data to external file
            + Action: Main/Load script data from external file
            + Action: Main/Relative slider mouse tracking mode
            + Tablet mode store/return from script data 
            # Defaults: maps quantity increased up to 16
            # Fixed change maps quantity for existing data
            # Fixed free slider after mouse release
            # GUI: floatin slider info improvements
15.12.2015  0.24 
            # GUI: proper slider menu sort            
            # GUI: slider GUI improvements
            + GUI: main menu button
            + Support for Ctrl + mouseclick on slider
            + Action: Slider/Set value to 0.5 
            + Action: Slider/Parameter modulation
            + Action: Slider/Float related FX
14.12.2015  0.22
            + Action: clear broken sliders
            + Sliders mouse tracking
            + tablet_optimised = true runs gui with imitation of rightclick buttons
            + GUI: project tab
            # GUI: get buttons moved to slider menu           
            # GUI: cutting long slider names
            + GUI: led indicates project is dirty (need to save with stored script data)
            + GUI: led help message
            + GUI: slider info under cursor
12.12.2015  0.14
            + Store last map  
            + GUI: sliders
            + Action: clear current map
            + Action: clear all maps
            # fixed return to extstate
11.12.2015  0.11
            + sending/parsing projextstate values    
10.12.2015  0.1
            + GUI: select map button
04.12.2015  0.01 - need REAPER 5.03+ SWS 2.8.1+
            + idea

]===]
  
  function fdebug(str)
    if data.dev_mode ~= nil and data.dev_mode == 1 then msg(os.date()..' '..str) end
  end  
 -----------------------------------------------------------------------   
 ----------------------------------------------------------------------- 
 -- formula functions
  function vca() end 
  function lim(x, lim_s, lim_e) if x ~= nil then return F_limit(x,lim_s,lim_e) end end
  function scaleto(x, lim_s, lim_e) if x ~= nil then return x*(math.abs(lim_s-lim_e))+ lim_s end end
  function wrap(x) if x ~= nil then return x % 1 end end
  function sqr(x) if x ~= nil then return math.sqrt(x) end end
  function sin(x) if x ~= nil then return math.sin(x) end end
  function abs(x) if x ~= nil then return math.abs(x) end end
  
  function match(x, curve1)
    local t, num, num1, num2
    if curve1 == nil or curve1 == '' then return x
      else 
        t = {}
        for num in curve1:gmatch('[%d%p]+ [%d%p]+') do 
          num1 = tonumber(num:match('[%d%p]+ '))
          num2 = tonumber(num:match(' [%d%p]+'))
          table.insert(t, {num1,num2}) 
        end
        
        for i = 1, #t-1 do
          if x >= t[i][1] and x <= t[i+1][1] then 
            pos_x  = (x - t[i][1]) / (t[i+1][1] - t[i][1])
            out_val = t[i][2] + (t[i+1][2]-t[i][2])*1 * pos_x
            out_val = F_limit(out_val, 0 , 1)
            return out_val
          end
        end
    end
    return 0
  end
  
  function lfo(per) 
    ret = (time % per) / per
    if ret > 0.5 then ret = 1 - ret end
    ret = ret * 2
    return ret
  end
  
  function cycle(per) 
    ret = (time % per) / per
    return ret
  end
  
  function track_vol(m,sl)
    --msg(m)
    --msg(sl)
    if data.map[m] == nil or data.map[m][sl] == nil then return 0.1 end
    local guid = data.map[m][sl].track_guid
    local track = reaper.BR_GetMediaTrackByGUID(0, guid)
    track_vol_ret = reaper.GetMediaTrackInfo_Value(track, 'D_VOL')
    return track_vol_ret
  end
  
  function track_pan(m,sl)
    --msg(m)
    --msg(sl)
    if data.map[m] == nil or data.map[m][sl] == nil then return 0.1 end
    local guid = data.map[m][sl].track_guid
    local track = reaper.BR_GetMediaTrackByGUID(0, guid)
    local track_pan_ret = reaper.GetMediaTrackInfo_Value(track, 'D_PAN')
    return track_pan_ret
  end

  function track_peak(m,sl)
    --msg(m)
    --msg(sl)
    if data.map[m] == nil or data.map[m][sl] == nil then return 0.1 end
    local guid = data.map[m][sl].track_guid
    local track = reaper.BR_GetMediaTrackByGUID(0, guid)
    local peak_ret = (reaper.Track_GetPeakInfo(track, 1) + reaper.Track_GetPeakInfo(track, 1))  /2 
    return peak_ret
  end  
  
  function master_rate()
    return reaper.Master_GetPlayRate(0)
  end
  

 -----------------------------------------------------------------------         
 -----------------------------------------------------------------------   
 function msg(str)
    if type(str) == 'boolean' then 
      if str then str = 'true' else str = 'false' end
    end
    if str ~= nil then 
      reaper.ShowConsoleMsg(tostring(str)..'\n') 
      if str == "" then reaper.ShowConsoleMsg("") end
     else
      reaper.ShowConsoleMsg('nil')
    end    
  end

  
-----------------------------------------------------------------------    
  function F_open_URL(url)    
    if OS=="OSX32" or OS=="OSX64" then
      os.execute("open ".. url)
     else
      os.execute("start ".. url)
    end
  end

-----------------------------------------------------------------------  
  function F_get_beetween(str,pat1,pat2,ret_nil) local temp_s,return_str_st,str_c1,return_str_end,return_str
    _, return_str_st = str:find(pat1)
    if return_str_st == nil then return nil end
    str_c1 = str:sub(return_str_st+2)
    return_str_end = str_c1:find(pat2)
    if return_str_end ==  nil then return nil end
    return_str = str_c1:sub(0,return_str_end-1)
    if return_str == '' then return nil end
    return return_str
  end
    
-----------------------------------------------------------------------  
  function F_wrap_text(str, max_w)
    words_t = {}
    for word in string.gmatch(str..' test', '[^%s]+') do table.insert(words_t, word) end
    out_str = ''
    k = 1
    for i = 1, #words_t-1 do
      if gfx.measurestr(table.concat(words_t, ' ',k,i+1)) > max_w then
        out_str = out_str..' '..'\n'..words_t[i]         
        k = i
       else
        out_str = out_str..' '..words_t[i]
      end
    end
    return out_str:sub(2)--..' '..words_t[#words_t] 
  end

-----------------------------------------------------------------------
  function F_limit(val,min,max,retnil)
    if val == nil or min == nil or max == nil then return 0 end
    local val_out = val 
    if val == nil then val = 0 end
    if val < min then 
      val_out = min 
      if retnil then return nil end
    end
    if val > max then 
      val_out = max 
      if retnil then return nil end
    end
    return val_out
  end 

-----------------------------------------------------------------------  
  function F_SetCol(s,ret255)    
    local t = {}
    for i in s:gmatch("%d+") do t[#t+1] = i end
    if ret255 ~= nil and ret255 then 
      return tonumber(t[1]),tonumber(t[2]),tonumber(t[3])
    end
    return t[1]/255,t[2]/255,t[3]/255
  end

-----------------------------------------------------------------------  
  function F_form_learnstr(slider_id) local state, flags
    --fdebug('F_form_learnstr')
    -- nothing
      if data.learn == nil and 
         data.learn[slider_id].midicc == nil and
         data.learn[slider_id].midich == nil and
         data.learn[slider_id].flags == nil and
         data.learn[slider_id].osc == nil then
         data.learn[slider_id].outstr = nil 
         return
      end
      
    -- midi osc
      if data.learn[slider_id] ~= nil then
        
        if -- midi
         data.learn[slider_id].osc == nil and
         tonumber(data.learn[slider_id].midicc) ~= nil and
         tonumber(data.learn[slider_id].midich) ~= nil and
         tonumber(data.learn[slider_id].flags) ~= nil then state = 1 end
         
        if -- midi osc
         tonumber(data.learn[slider_id].midicc) ~= nil and
         tonumber(data.learn[slider_id].midich) ~= nil and
         tonumber(data.learn[slider_id].flags) ~= nil and
         data.learn[slider_id].osc ~= nil then state = 2 end
         
        if -- osc
         tonumber(data.learn[slider_id].midicc) == nil and
         tonumber(data.learn[slider_id].midich) == nil and
         tonumber(data.learn[slider_id].flags) == nil and
         data.learn[slider_id].osc ~= nil then state = 3 end        
      --fdebug('state'..state)
        if state == 1 then
          data.learn[slider_id].outstr = 
          ((tonumber(data.learn[slider_id].midicc) << 8) | 0xB0 + tonumber(data.learn[slider_id].midich)-1)
            data.learn[slider_id].outstr = data.learn[slider_id].outstr..' '..data.learn[slider_id].flags 
        end
        if state == 2 then 
          data.learn[slider_id].outstr = 
          ((tonumber(data.learn[slider_id].midicc) << 8) | 0xB0 + tonumber(data.learn[slider_id].midich)-1)
            ..' '..data.learn[slider_id].flags..' '..data.learn[slider_id].osc end    
            
        if state == 3 then 
          data.learn[slider_id].outstr = '0 0 '..data.learn[slider_id].osc end
          
        if state == nil then data.learn[slider_id].outstr = nil end
      end
    
  end
  
-----------------------------------------------------------------------
  function F_extract_table(table,use) local a,b,c,d
    if table ~= nil then
      a = table[1]
      b = table[2]
      c = table[3]
      d = table[4]
    end  
    return a,b,c,d
  end  
  
-----------------------------------------------------------------------    
  function DEFINE_dynamic_variables2()
  local dy
    dy = 0
    time = os.clock()
    if last_time == nil then last_time = time end
    timediff = time - last_time
    local slow = 1
    time_gfx = (time % slow) / slow
    
    _, _, _, lt_fxname, lt_param_name, _ = ENGINE_Get_last_touched_value()
    
    -- values to compare
      values = ENGINE_GetSet_values(false)    
        if last_values == nil then 
          last_touched_map, last_touched_slider = nil,nil 
         else
          if #last_values ~= #values then 
            last_touched_map, last_touched_slider = nil,nil 
           else
            for i = 1, #values do
              if values[i][1] ~= last_values[i][1] then 
                last_touched_map = values[i][2] 
                last_touched_slider = values[i][3]
                dy = (values[i][1] - last_values[i][1])
                update_gfx_minor = true
                break
              end
            end
          end
        end 
    -- apply routing from last touched
    if data.expert_mode == 0 then
      ENGINE_apply_routing(last_touched_map,last_touched_slider,dy)
     else
      for i = 1, data.map_count do
        for k = 1, data.slider_count do
          ENGINE_apply_routing(i,k,dy)
        end
      end
    end
    
    -- apply learn to current map
      if set_learn and data.use_learn == 1 then ENGINE_set_learn() set_learn = false end      
      
    -- get last touched track
      local last_touched_track = reaper.GetLastTouchedTrack()
      if last_touched_track ~= nil then last_touched_track_guid = reaper.GetTrackGUID(last_touched_track) end  
    
    -- get last touched fx
      local retval, tracknumber, fxnumber, paramnumber
      _, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
      if tracknumber == nil or fxnumber == nil or paramnumber == nil then LT_id = 1000 
        else LT_id = tracknumber + fxnumber + paramnumber end
      if tracknumber == 0 then track = reaper.GetMasterTrack(0) else track = reaper.GetTrack(0,tracknumber-1) end
      if track ~= nil then last_touched_fx = reaper.TrackFX_GetFXGUID(track, fxnumber) end
      
      
      if LT_id ~= nil then 
        if last_LT_id == nil then last_LT_id = LT_id update_gfx_minor = true update_gfx = true  end
        if last_LT_id ~= LT_id then update_gfx_minor = true update_gfx = true  end
        last_LT_id = LT_id         
      end
      
      
    if last_last_touched_fx == nil then last_last_touched_fx = last_touched_fx end
    if last_last_touched_track_guid == nil then last_last_touched_track_guid = last_touched_track_guid end    
    if last_touched_fx ~= last_last_touched_fx or last_touched_track_guid ~= last_last_touched_track_guid then
      -- check for track links
        for i = 1, data.map_count do
            if data.map[i]~= nil then
            
              if data.map[i].fx_link ~= nil then
                if data.map[i].fx_link == last_touched_fx then 
                  data.current_map = i  
                  ENGINE_return_data_to_projextstate2(false)               
                  break
                end
              end
                          
              if data.map[i].track_link ~= nil then
                if data.map[i].track_link == last_touched_track_guid then 
                  data.current_map = i 
                  ENGINE_return_data_to_projextstate2(false)
                  break
                end
              end
              
            end
        end
      end
      
    --update_gfx_minor = true
    
    if last_dirty_state == nil then last_dirty_state = dirty_state update_gfx_minor = true update_gfx = true end
    dirty_state = reaper.IsProjectDirty(0)
    if last_dirty_state ~= dirty_state then update_gfx_minor = true update_gfx = true end
    
    StateChangeCount = reaper.GetProjectStateChangeCount(0)
    
    ReaProject = reaper.EnumProjects(-1,'')
    if last_ReaProject == nil then last_ReaProject = ReaProject end
    if last_ReaProject ~=  ReaProject then MAIN_exit() end
    
    data.project_name = ENGINE_Get_project_name()
    char = gfx.getchar()
    
    --if data.run_docked == 1 then
      if last_w == nil then last_w = gfx.w end
      if last_h == nil then last_h = gfx.h end
      if last_w ~= main_xywh[3] or last_h ~= main_xywh[4] then
        main_xywh[3] = gfx.w
        main_xywh[4] = gfx.h
        update_gfx = true
        ENGINE_return_data_to_projextstate2(false)
      end
      
      if main_xywh[3] < 150 then main_xywh[3] = 150 end
      if main_xywh[4] < 600 then main_xywh[4] = 600 end
    --end
    if data.current_window == 1 then update_gfx_minor = true end
  end
  
-----------------------------------------------------------------------     
  function DEFINE_dynamic_variables_ext_state()
    if data.use_ext_actions == 1 then
      map_ext = reaper.GetExtState('MPL_PANEL_MAPPINGS', 'MAP')
      if map_ext ~= nil and map_ext ~= '' and math.floor(tonumber( map_ext)) > 0 and 
        math.floor(tonumber( map_ext)) <= data.map_count then 
        data.current_map = tonumber(map_ext) 
      end
    end
  end
  
-----------------------------------------------------------------------   
  function DEFINE_dynamic_variables2_defer_release()
    last_ReaProject = ReaProject
    
    last_w = gfx.w
    last_h = gfx.h
    
    if last_current_map == nil or last_current_map ~= data.current_map then 
      if data.use_learn == 1 then set_learn = true end
      ENGINE_return_data_to_projextstate2(false)
      update_gfx = true
    end
    
    last_dirty_state = dirty_state
    data.last_use_learn = data.use_learn
    last_time = time
    last_current_map = data.current_map
    last_last_touched_track_guid = last_touched_track_guid
    last_last_touched_fx = last_touched_fx
    last_w = gfx.w
    last_h = gfx.h
    last_values = values
    last_touched_map, last_touched_slider = nil,nil 
    last_StateChangeCount = StateChangeCount
    last_dirty_state = dirty_state
  end

----------------------------------------------------------------------- 
  function ENGINE_GetSetParamValue(i,k, is_set, in_value)
    local track, fx_count,fx_guid,fx_guid_act_id,value, ret, trackname, 
      fxname  ,param_name,out_value, value
    local empty = -1
    local not_found = -2
    local max_len = 40
    
    if data.map[i] == nil then return empty end
    if data.map[i][k] == nil then return empty end
    
    if data.map[i][k].track_guid == nil then return empty end
    if data.map[i][k].fx_guid == nil then return empty end
    if data.map[i][k].paramnumber == nil then return empty end
    
    track = reaper.BR_GetMediaTrackByGUID(0, data.map[i][k].track_guid)
    if track == nil then return not_found end
    _, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    if trackname == "" then 
      trackname = '<Untitled track '..reaper.CSurf_TrackToID(track, false)..'>' 
    end
    if trackname == '<Untitled track 0>' then trackname = '<Master track>' end
    
    fx_count = reaper.TrackFX_GetCount(track)
    if fx_count == 0 then return not_found else 
      for fx_id = 1, fx_count do
        fx_guid = reaper.TrackFX_GetFXGUID(track, fx_id-1)
        if fx_guid == data.map[i][k].fx_guid then fx_guid_act_id = fx_id-1 break end
      end
      if fx_guid_act_id == nil then return not_found end
    end
    
    _, fxname = reaper.TrackFX_GetFXName(track, fx_guid_act_id, '')
    if string.len(fxname) > max_len then fxname = fxname:sub(0,max_len)..'...' end
    
    _, param_name = reaper.TrackFX_GetParamName(track, fx_guid_act_id,data.map[i][k].paramnumber, '')
    
    out_value = reaper.TrackFX_GetParamNormalized(track, fx_guid_act_id, data.map[i][k].paramnumber)
    
    if is_set then       
      if in_value == nil then fdebug('Set param value not found') value = 0 end
      value = F_limit(in_value , 0.0000001, 1)
      ret = reaper.TrackFX_SetParamNormalized(track, fx_guid_act_id, data.map[i][k].paramnumber, value)
      return ret
     else
      return 
        out_value,
        trackname,
        fxname,
        param_name,
        track,
        fx_guid_act_id
    end
  end    
  
-----------------------------------------------------------------------  
  function ENGINE_GetSet_values()   
    --fdebug('GET_values')    
    local val = {}    
    for i = 1, data.map_count do
      for k = 1, data.slider_count do
        if data.map[i] ~= nil and data.map[i][k] ~= nil then 
          data.map[i][k].value = ENGINE_GetSetParamValue(i,k, false) 
          table.insert(val, {data.map[i][k].value, i, k})
        end
      end
    end
    return val
  end  

-----------------------------------------------------------------------
  
  
 function ENGINE_GetSetMIDIOSCLearn(track_in, fx_index, param_id, is_set, string_midiosc)
   -- is_set == 0 - get
   -- is_set == -1 - remove all learn from pointed parameter
   
   -- return midichan,midicc, osclearn
   -- if in_chan == -1 then remove learn for current param
   if fx_index == nil then return end
   fx_index = fx_index+1 -- 0-based    
                 --param_id 0-based
                 
   local out_midi_num, chunk,exists, guid_id,chunk_t,i,fx_chunks_t,fx_count,
     fx_guid,param_count,active_fx_chunk,active_fx_chunk_old,active_fx_chunk_t,
     out_t,midiChannel,midiCC,insert_begin,insert_end,active_fx_chunk_new,main_chunk,temp_s
     
   if track_in == nil then reaper.ReaScriptError('MediaTrack not found') return end
   _, chunk = reaper.GetTrackStateChunk(track, '')      
   --reaper.ShowConsoleMsg(chunk)
   if reaper.TrackFX_GetCount(track) == 0 then reaper.ReaScriptError('There is no FX on track') return end
   if fx_index > reaper.TrackFX_GetCount(track) then reaper.ReaScriptError('FX index > Number of FX') return end
   -- get com table
     main_chunk = {}
     for line in chunk:gmatch("[^\n]+") do 
       table.insert(main_chunk, line)
     end
     
   -- get fx chunks
     chunk_t= {}
     temp_s = nil
     i = 1
     for line in chunk:gmatch("[^\n]+") do 
       if temp_s ~= nil then temp_s = temp_s..'\n'..line end
       if line:find('BYPASS') ~= nil then
         temp_s = i..'\n'..line
       end
       if line:find('WAK') ~= nil then  
         table.insert(chunk_t, temp_s..'\n'..i)  
         temp_s = nil 
       end
       i = i +1
     end
   
   -- filter fx chain, ignore rec/item
     fx_chunks_t = {}
     fx_count = reaper.TrackFX_GetCount(track)
     for i = 1, fx_count do
       fx_guid = reaper.TrackFX_GetFXGUID(track, i-1)
       for k = 1, #chunk_t do
         if chunk_t[k]:find(fx_guid:sub(-2)) ~= nil then table.insert(fx_chunks_t, chunk_t[k]) end
       end
     end
     if #fx_chunks_t ~= fx_count then return nil end
     if fx_index > fx_count then reaper.ReaScriptError('FX index > Number of FX')  return end
     
     param_count = reaper.TrackFX_GetNumParams(track, fx_index-1)
     if param_id+1 > param_count then reaper.ReaScriptError('Parameter index > Number of parameters') return end
     
   -- filter active chunk
     active_fx_chunk = fx_chunks_t[fx_index]
     active_fx_chunk_old = active_fx_chunk
     
   -- extract table
     active_fx_chunk_t = {}
     for line in active_fx_chunk:gmatch("[^\n]+") do table.insert(active_fx_chunk_t, line) end
 
   -- get first param
     for i = 1, #active_fx_chunk_t do
       if active_fx_chunk_t[i]:find('PARMLEARN '..param_id..' ') then exists = i break end
     end 
      
     --------------------------      
     if is_set == 0 then -- GET 
       if exists == nil then reaper.ReaScriptError('There is no learn for current parameter') return end
       -- form out table
         out_t = {}
         for word in active_fx_chunk_t[exists]:gsub('PARMLEARN ', ''):gmatch('[^%s]+') do
           table.insert(out_t, word)
         end
       -- convert
         midiChannel = out_t[2] & 0x0F
         midiCC = out_t[2] >> 8    
         
       return midiChannel + 1, midiCC, out_t[4] 
     end
     
     --------------------------
     if is_set == 1 then -- SET  midi
       if string_midiosc ~= nil and string_midiosc ~= '' then
       
           -- add to active_fx_chunk_t
             for i = 1, #active_fx_chunk_t do
               if active_fx_chunk_t[i]:find('FXID ') then guid_id = i break end
             end
             
             table.insert(active_fx_chunk_t, guid_id+1,
               'PARMLEARN '..param_id..' '..string_midiosc)
       end 
     end
       
       
     --------------------------  
     if is_set == -1 then -- remove current parameters learn
         for i = 1, #active_fx_chunk_t do
           if active_fx_chunk_t[i]:find('PARMLEARN '..param_id..' ') then 
             active_fx_chunk_t[i] = ''
           end
         end       
     end
     --------------------------   
           
     if is_set == -1 or is_set == 1 then
       -- return fx chunk table to chunk
         insert_begin = active_fx_chunk_t[1]
         insert_end = active_fx_chunk_t[#active_fx_chunk_t]
         active_fx_chunk_new = table.concat(active_fx_chunk_t, '\n', 2, #active_fx_chunk_t-1)
         
         
       -- delete_chunk lines
         for i = insert_begin, insert_end do
           table.remove(main_chunk, insert_begin)
         end
       
       -- insert new fx chunk
         table.insert(main_chunk, insert_begin, active_fx_chunk_new)
         
       -- clean chunk table from empty lines
         out_chunk = table.concat(main_chunk, '\n')
         out_chunk_clean = out_chunk:gsub('\n\n', '')
         --reaper.ShowConsoleMsg(out_chunk_clean)
         reaper.SetTrackStateChunk(track, table.concat(main_chunk, '\n')) 
     end
 end
  
-----------------------------------------------------------------------
  function DEFINE_GUI_objects()
    if update_gfx then
      --fdebug('DEFINE_GUI_objects')
      x_offset = 5  
      y_offset = 5  
      local obj_w = main_xywh[3] - x_offset*2
      obj_w2 = 30
      --obj_w2 = 
      local obj_h = 25

      b_close_xywh = {x_offset + obj_w - obj_w2, y_offset, obj_w2, obj_h}
      b_top_full_xywh = {x_offset,y_offset, obj_w, obj_h}     
      b_1_xywh = {x_offset,y_offset, obj_w-obj_w2*data.tablet_optimised, obj_h}
      b_1_fix_xywh = {x_offset,y_offset, obj_w-obj_w2, obj_h}
      b_2_xywh = {x_offset,y_offset*2 + obj_h , obj_w-obj_w2*data.tablet_optimised, obj_h} -- map slider 
      b_2_1_xywh = {x_offset+obj_w-obj_w2*data.tablet_optimised,y_offset*2 + obj_h , obj_w2, obj_h}
      b_2_fix_xywh = {x_offset,y_offset*2 + obj_h , obj_w-obj_w2, obj_h}
      b_2_1_fix_xywh = {x_offset+obj_w-obj_w2,y_offset*2 + obj_h , obj_w2, obj_h}
      b_2_midisetup = {b_2_xywh[1],b_2_xywh[2],b_2_xywh[3]/2,b_2_xywh[4]}
      b_2_oscsetup = {b_2_xywh[1]+b_2_xywh[3]/2,b_2_xywh[2],b_2_xywh[3]/2,b_2_xywh[4]}
      control_area_xywh = {x_offset,y_offset*3.2+obj_h*2,obj_w-obj_w2*data.tablet_optimised, obj_h * data.slider_count / (600 / main_xywh[4])  }
      lamp_xywh = {x_offset,y_offset,10,obj_h}
      
      b_new_proj = {x_offset, y_offset, obj_w -  obj_w2*3, obj_h}
      b_new_shcut_rout = {x_offset + obj_w-obj_w2*3, y_offset, obj_w2, obj_h}
      b_new_shcut_flearn = {x_offset + obj_w-obj_w2*2, y_offset, obj_w2, obj_h}
      
      local bigknob_w = 70
      bigknob1_xywh = {(main_xywh[3]-bigknob_w)/2,
                      70,
                      bigknob_w,
                      bigknob_w}
                       
      graph_rect = {    x_offset*4, 
                      bigknob1_xywh[2]+bigknob1_xywh[4]+30+y_offset,
                      main_xywh[3]-8*x_offset,
                      main_xywh[3]-8*x_offset}  
                      
      bigknob2_xywh = {(main_xywh[3]-bigknob_w)/2,
                       graph_rect[2] + graph_rect[4]+35,
                       bigknob_w,
                       bigknob_w}    
                       
      form_text_h = 25                                          
    end
  end
  
------------- --------------------------------------------
          function GUI_knob2(xywh, map, sl, val, state)
            --fdebug('GUI_knob2')
            -- state 0 send / state 1 receive
            x,y,w,h = F_extract_table(xywh)
            x= x+w/2
            --gfx.rect(x,y,w,h)
            
            
             if data.map[map] ~= nil 
               and data.map[map][sl] ~= nil 
               and data.map[map][sl].color ~= nil  then
                color = data.map[map][sl].color
                local t = {}
                for num in color:gmatch('[^%s]+') do table.insert(t, tonumber(num)) end
                c_r = t[1]
                c_g = t[2]
                c_b = t[3]
            end
            
            
            -- arrow
              if state ~= nil then
                local heigh_arrow = 20
                local wide_arrow = 15
                local length_arrow = 60
                local arr_tri_length = 20
                local arr_tri_h = 12
                local arr_tri_w = 22
                local arr_x_offs = 10
                gfx.a = 0.45
                gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
                
                -- if send
                  if state == 0 then
                    gfx.rect(x-wide_arrow/2+1,y+h/2,wide_arrow,heigh_arrow,aa)
                    gfx.a = 0.35
                    gfx.triangle(x-arr_tri_w/2,y+h/2+heigh_arrow,
                                 x+arr_tri_w/2,y+h/2+heigh_arrow,
                                 x,            y+h/2+heigh_arrow+arr_tri_h)
                  end
                  
                -- if receive
                  if state == 1 then
                    gfx.rect(x-wide_arrow/2+1,y+h/2+arr_tri_h+1,wide_arrow,heigh_arrow,aa)
                    gfx.a = 0.35
                    gfx.triangle(x-arr_tri_w/2,y+h/2+arr_tri_h,
                                 x+arr_tri_w/2,y+h/2+arr_tri_h,
                                 x,             y+h/2)
                  end
                end
                
                          
            -- outarc
              gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
              local outarc_angle = 50
              gfx.a = 0.2
              for i = 1, 3,0.1 do
                gfx.arc(x, y+h/2,
                  w/2-i+2, math.rad(-180 + outarc_angle), math.rad((360-outarc_angle*2)-180+outarc_angle),aa)                
              end 
                
            -- arc val          
              if val >= 0 then
                gfx.a = 0.25
                
                  if c_r ~= nil and  c_g ~= nil and c_b ~= nil then
                    gfx.r, gfx.g, gfx.b = c_r,c_g,c_b
                   else
                    gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
                  end
                                  for i = 1, 10,0.1 do
                  gfx.arc(x, y+h/2,
                  w/2-1-i, math.rad(-180 + outarc_angle), math.rad(val*(360-outarc_angle*2)-180+outarc_angle),aa)
                end 
              end 
              
              
            -- blur
              --gfx.x,gfx.y = x-w/2,y-h/2
             -- gfx.blurto(x+w/2,y+h/2) 
              
            -- mapsl
              gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
              gfx.setfont(1, data.fontname, button_fontsize)  
              local str = 'Map '..map..' Slider '..sl          
              gfx.x,gfx.y = x-gfx.measurestr(str)/2+1,y+h
              gfx.a = 0.8 
              gfx.drawstr(str)
              
            -- gfxname
              gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
              gfx.setfont(1, data.fontname, button_fontsize)  
              local str = data.map[map][sl].gfx_name  
              gfx.x,gfx.y = x-gfx.measurestr(str)/2+1,y+h+15
              gfx.a = 0.8 
              gfx.drawstr(str)
              
            -- graph val
              gfx.a = 0.9
              gfx.r, gfx.g, gfx.b = F_SetCol(color_t['red']) 
              val = data.map[last_routing_config_map][last_routing_config_sl].value
              if func ~= nil then
                val2 = F_limit(func(val),0,1)
                if val2 == nil then val2 = 0 end
                gfx.circle(graph_rect[1]+graph_rect[3]*val,
                          graph_rect[2]+graph_rect[4]-graph_rect[4]*val2, 5 , 1 ,aa)  
              end
             
              
          end
          
--vv--------------------------------------------------------------------
            function GUI_button(xywh, name,compensated, alpha) local x,y,w,h,measurestrname, x0, y0
              gfx.y,gfx.x = 0,0
              x,y,w,h = F_extract_table(xywh, 'xywh')
             
              --fill background
                  gfx.r, gfx.g, gfx.b= F_SetCol(color_t['white'])
                  gfx.a  = buttons_back_alpha
                  if data.dev_mode == 1 then
                    gfx.rect(x,y,w,h,0)
                   else
                    gfx.rect(x,y,w,h,1)
                  end
              if compensated == 1 then w = w + obj_w2 end   
              --if compensated == 2 then w = 10 end
              --text
                gfx.a = button_text_alpha
                if alpha ~= nil then gfx.a = alpha end
                gfx.setfont(1, data.fontname, button_fontsize)
                F_SetCol(color_t['white'])  
                measurestrname = gfx.measurestr(name)
                x0 = x + (w - measurestrname)/2
                y0 = y + (h - button_fontsize)/2
                gfx.x, gfx.y = x0,y0 
                gfx.drawstr(name)      
            end            

            
-----------------------------------------------------------------------
            function GUI_slider(n, val) -- text, color,alpha) 
              local x,y,w,h,text,color,midi_offs
              
             -- if val == nil then val = 0 end
              x = 0
              y = (n-1) * control_area_xywh[4]/data.slider_count
              w = control_area_xywh[3]
              h = control_area_xywh[4]/data.slider_count - 2
              gfx.x,gfx.y = 0,0
              
              -- draw fixedlearn ind
              if data.use_learn == 1 then
                if data.map[data.current_map] ~= nil then
                  if data.map[data.current_map].bypass_learn ~= nil and data.map[data.current_map].bypass_learn == 1 then
                   else 
                    if data.learn ~= nil then
                      if data.learn[n] ~= nil then
                        midi_offs = 0
                        if data.learn[n].midich ~= nil then
                          gfx.a = 0.8
                          gfx.r, gfx.g, gfx.b = F_SetCol(color_t['blue'])
                          gfx.rect(x,y,5,h)
                          midi_offs = 7
                        end
                        if data.learn[n].osc ~= nil then
                          gfx.a = 0.8
                          gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
                          gfx.rect(x+midi_offs,y,5,h)
                        end                      
                      end
                    end
                  end
                end
              end
              
              --rect 
                gfx.a = 0.4
                gfx.r, gfx.g, gfx.b = F_SetCol(color_t['back2'])
                gfx.rect(x,y,w,h,1)   
                
              -- gradient
                gfx.a = 1
                gfx.blit(3, 1, 0, 
                         0,0,300,50,
                         x,y+1,w*val,h-2,
                         0,0)    
                         
              --name
                if data.map[data.current_map] ~= nil and 
                  data.map[data.current_map][n] ~= nil and
                  data.map[data.current_map][n]['gfx_name'] then
                    text = data.map[data.current_map][n]['gfx_name']
                end
                
             if data.map[data.current_map] ~= nil 
               and data.map[data.current_map][n] ~= nil 
               and data.map[data.current_map][n].color ~= nil 
               and data.map[data.current_map][n].color ~= ''  then
                color = data.map[data.current_map][n].color                
                local t = {}
                for num in color:gmatch('[^%s]+') do table.insert(t, tonumber(num)) end
                c_r = t[1]
                c_g = t[2]
                c_b = t[3]
              end                   
                   
                if val == -1 then 
                  gfx.a = 0.2
                  if lt_fxname ~= nil and lt_param_name ~= nil then
                    text = lt_fxname..' / '.. lt_param_name
                   else
                    text = 'empty'
                  end
                  gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
                 elseif val == -2 then 
                  text = 'Not found' 
                  gfx.a = 1
                  gfx.r, gfx.g, gfx.b = F_SetCol(color_t['red'])
                 else
                  gfx.a = 1
                  if c_r ~= nil and c_g ~= nil and c_g ~= nil then
                    gfx.r, gfx.g, gfx.b = c_r,c_g,c_b
                   else
                    gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
                  end
                end
                
                if OS == "OSX32" or OS == "OSX64" then  
                  gfx.setfont(1, data.fontname, data.slider_fontsize-3)  
                 else
                  gfx.setfont(1, data.fontname, data.slider_fontsize)
                end
                text_len = gfx.measurestr(text)
                gfx.x = (w+obj_w2*data.tablet_optimised-text_len)/2
                gfx.y = y + (h - button_fontsize)/2 - 1 
                gfx.drawstr(text)
              
            end  

----------------------------------------------------------------------
            function GUI_lamp(xywh, state)
              if state == 0 then 
                gfx.r,gfx.g,gfx.b = F_SetCol(color_t['green'])
               else
                gfx.r,gfx.g,gfx.b = F_SetCol(color_t['red'])
              end
              gfx.a,gfx.x,gfx.y = 0.7,0,0                
              x,y,w,h = F_extract_table(xywh)
              gfx.rect(x,y,w,h, true)
            end

----------------------------------------------------------------
          function GUI_knob(map, sl, val) local color
            local x = (map-1)*(control_area_xywh[3])/data.map_count 
            local y = (sl-1)*control_area_xywh[4]/data.slider_count 
            local w = (control_area_xywh[3]+obj_w2*math.abs(data.tablet_optimised-1))/data.map_count - 2
            local h = control_area_xywh[4]/(data.slider_count )
                
                --gfx.rect(x,y+1,w-2,h-2)
            
             if data.map[map] ~= nil 
               and data.map[map][sl] ~= nil 
               and data.map[map][sl].color ~= nil  then
                color = data.map[map][sl].color
                local t = {}
                for num in color:gmatch('[^%s]+') do table.insert(t, tonumber(num)) end
                c_r = t[1]
                c_g = t[2]
                c_b = t[3]
            end
            
            
            -- outarc
              local outarc_angle = 50
              if val >= 0 then
                gfx.a = 1
                
                  if c_r ~= nil and  c_g ~= nil and c_b ~= nil then
                    gfx.r, gfx.g, gfx.b = c_r,c_g,c_b
                   else
                    gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
                  end
                min_dim = math.min(
                control_area_xywh[3]/data.map_count,
                control_area_xywh[4]/data.slider_count)
                for i = 1, 4,0.3 do
                  gfx.arc(x+w/2-1, y+h/2,
                  min_dim/2-i-1, math.rad(-180 + outarc_angle), math.rad(val*(360-outarc_angle*2)-180+outarc_angle),aa)
                end 
              end 
            
              gfx.x,gfx.y = x,y
              gfx.blurto(x+w,y+h) 
                     
            -- center circle
              if val >= 0 then
                gfx.a = 0.8
                
                  if c_r ~= nil and  c_g ~= nil and c_b ~= nil then
                    gfx.r, gfx.g, gfx.b = c_r,c_g,c_b
                   else
                    gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
                  end
                                  gfx.circle(x+w/2-1, y+h/2, 3,  1, aa) 
               else
                gfx.a = 0.4
                gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
                gfx.circle(x+w/2-1, y+h/2, 2,  1, aa) 
              end    
              
              --gfx.rect(x,y,w,h, 0)
          end
                                  
-----------------------------------------------------------------------
  function DEFINE_GUI_buffers()   
    if update_gfx_minor or update_gfx then
      --msg('test')
      local mapname, val, text_len, bottom_info_h,text_offset, x,y,w,h, val,obj_w, x1,y1,x2,y2,text, flags,
      map, slider,str0,lrn_alpha
      --fdebug('DEFINE_GUI_buffers')
            
      --------------------------------------------       
      -- reset buffers
      
        -- 1 backgr
        -- 2 main window buttons
        -- 3 slider gradient
        -- 4 sliders
        -- 5 bottom info
        -- 6 about
        -- 7 routing buttons
        -- 8 routing back
        -- 9 knob matrix
        -- 10 routing wires
        -- 11 midi learn setup
        -- 12 control area back
        -- 13 routing config
        -- 14 graph
        
        -- current_window
        -- 0 main window
        -- 1 about 
        -- 2 routing
        -- 3 fixedlearn
        -- 4 routing edit config
        
         
        if update_gfx then      
          -- buf1 background
            gfx.dest = 1     
            gfx.setimgdim(1, -1, -1)  
            gfx.setimgdim(1, main_xywh[3], main_xywh[4]) 
            gfx.r, gfx.g, gfx.b = F_SetCol(color_t['back'])
            local x,y,w,h = F_extract_table(main_xywh,'xywh')
            gfx.a = 1
            gfx.rect(x,y,w,h,true) 

        --  buf12 control area back
            gfx.dest = 12
            gfx.setimgdim(12, -1, -1)  
            gfx.setimgdim(12, control_area_xywh[3], control_area_xywh[4])  

            -- gradient                   
               gfx.a = 1
                local r,g,b,a = 0.9,0.9,1,0.15
                gfx.x, gfx.y = 0,0
                local drdx = 0.0002
                local drdy = 0
                local dgdx = 0.0002
                local dgdy = 0.009     
                local dbdx = 0.004
                local dbdy = 0
                local dadx = 0.00005
                local dady = 0.00002       
               gfx.gradrect(0,0,control_area_xywh[3], control_area_xywh[4], 
                             r,g,b,a, 
                             drdx, dgdx, dbdx, dadx, 
                             drdy, dgdy, dbdy, dady)
            -- frame
              gfx.a = 0.05
              gfx.rect(0,0,control_area_xywh[3], control_area_xywh[4],false)
              gfx.a = 0.3
              gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
              gfx.rect(0,0,control_area_xywh[3], control_area_xywh[4], true)
          end
      
       --------------------------------------------  
       --------------------------------------------  
           -- main window
      if data.current_window == 0 then 
            if update_gfx then
            -- buf2 main window buttons
              gfx.dest = 2    
              gfx.setimgdim(2, -1, -1)  
              gfx.setimgdim(2, main_xywh[3], main_xywh[4]) 
                --main
                  if data.project_name == '' then data.project_name = 'Untitled' end
                  GUI_button(b_new_proj, 'Project: '..data.project_name:sub(0,20),1)   
                  --GUI_button(b_1_fix_xywh, 'Last: '..lt_fxname..' / '.. lt_param_name ,1)
                  GUI_button(b_new_shcut_rout, 'R') 
                  if data.use_learn == 1 or data.use_learn == 2    then 
                    lrn_alpha = button_text_alpha
                   else
                    lrn_alpha = 0.4
                  end
                    GUI_button(b_new_shcut_flearn, 'FL',0,lrn_alpha)
                  GUI_lamp(lamp_xywh, dirty_state)
                  GUI_button(b_close_xywh, '>')
                --map
                  if data.map ~= nil and data.map[data.current_map] ~= nil and data.map[data.current_map].map_name ~= nil then 
                   mapname = ' '..data.map[data.current_map].map_name else mapname = '' end
                  GUI_button(b_2_xywh, 'Map #'..data.current_map..mapname,data.tablet_optimised)
                --map cur
                  gfx.a = 0.5
                  gfx.rect(b_2_xywh[1]+(data.current_map-1) * b_2_xywh[3]/(data.map_count),
                            b_2_xywh[2],
                            b_2_xywh[3]/data.map_count,
                            b_2_xywh[4],true)
                -- linked maps
                  for i = 1, data.map_count do
                    if data.map[i] ~= nil and data.map[i].track_link ~= nil or
                      data.map[i] ~= nil and data.map[i].fx_link ~= nil then
                        gfx.a = 0.6
                        gfx.r, gfx.g, gfx.b = F_SetCol(color_t['red'])
                        gfx.rect(b_2_xywh[1]+(i-1) * b_2_xywh[3]/(data.map_count),
                                                    b_2_xywh[2],
                                                    b_2_xywh[3]/data.map_count,
                                                    b_2_xywh[4],0)
                    end
                      
                  end
                          
                if data.tablet_optimised == 1 then 
                  -- map
                    GUI_button(b_2_1_xywh, '>') 
                  -- sliders
                    for k =1, data.slider_count do
                      local b_01_xywh = {control_area_xywh[1]+control_area_xywh[3], 
                                        control_area_xywh[2]+ (k-1) * control_area_xywh[4]/data.slider_count + 1, 
                                        obj_w2, 
                                        control_area_xywh[4]/data.slider_count - y_offset -2}
                      GUI_button(b_01_xywh, '>')
                    end
                end
              end
              
                        
          --------------------------------------------
          
            if update_gfx then
            -- buf3 slider    gradient
              gfx.dest = 3
              gfx.setimgdim(3, -1, -1)  
              gfx.setimgdim(3, 300, 100) 
               local r,g,b,a = 1,1,1,0.08
               gfx.x, gfx.y = 0,0
               local drdx = 0
               local drdy = 0
               local dgdx = 0.001
               local dgdy = 0.008   
               local dbdx = 0.0005
               local dbdy = 0
               local dadx = 0.0020
               local dady = 0.00001       
               gfx.gradrect(0,0,300,100, 
                            r,g,b,a, 
                            drdx, dgdx, dbdx, dadx, 
                            drdy, dgdy, dbdy, dady)
            end
        
        --------------------------------------------
        
          if update_gfx_minor then                       
          -- buf4 sliders
            gfx.dest = 4 
            gfx.setimgdim(4, -1, -1)  
            gfx.setimgdim(4, control_area_xywh[3], control_area_xywh[4]) 
            gfx.a = 1
            for k = 1, data.slider_count do
              if data.map[data.current_map] == nil or data.map[data.current_map][k] == nil then val = -1 
               else val = data.map[data.current_map][k].value end
              GUI_slider(k, val)
            end
          end
        
          

      end -- define buffers for main_window
      
       --------------------------------------------  
       --------------------------------------------  
       
       -- buf5 bottom info
          bottom_info_h = main_xywh[4] - (control_area_xywh[2]+control_area_xywh[4]+ 2 *y_offset)
          gfx.dest = 5
          obj_w = main_xywh[3]-2*x_offset
          gfx.setfont(1, data.fontname, button_fontsize)
          local text_offset = gfx.texth
        if update_gfx_minor and 
          (data.current_window == 0 or data.current_window == 2 or data.current_window == 3) then
          gfx.setimgdim(5, -1, -1)  
          gfx.setimgdim(5, obj_w,bottom_info_h)
          gfx.a = 0.4
          gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
          -- back
            gfx.rect(0,0,obj_w, bottom_info_h, true)
          -- info 
            if data.bottom_info_map ~= nil and data.bottom_info_slider ~= nil then
              val, trackname, fxname, param_name = ENGINE_GetSetParamValue(data.bottom_info_map,data.bottom_info_slider, false)            
              if val >= 0 and val <= 1 then
                gfx.a = 0.85
                gfx.x, gfx.y = x_offset,0
                -- id
                  gfx.drawstr('Map '..data.bottom_info_map..' Slider '..data.bottom_info_slider)
                -- slidername
                  gfx.x, gfx.y = x_offset,text_offset
                  gfx.drawstr(data.map[data.bottom_info_map][data.bottom_info_slider].gfx_name)                
                -- value
                  gfx.x, gfx.y = x_offset,text_offset*2
                  gfx.drawstr(val)
                -- track
                  gfx.x, gfx.y = x_offset,text_offset*3
                  gfx.drawstr(trackname)
                -- fxname
                  gfx.x, gfx.y = x_offset,text_offset*4
                  gfx.drawstr(fxname)                
                -- paramname
                  gfx.x, gfx.y = x_offset,text_offset*5
                  gfx.drawstr(param_name)  
                -- midi
                  if data.learn ~= nil and data.use_learn == 1 and data.learn[data.bottom_info_slider] ~= nil then
                    
                    if data.learn[data.bottom_info_slider].midich ~= nil 
                      and data.learn[data.bottom_info_slider].midicc ~= nil 
                      and data.learn[data.bottom_info_slider].flags ~= nil then
                      if data.learn[data.bottom_info_slider].flags == 2 then 
                        flags = ' (soft takeover)]' else flags = ']' end
                        midi = '[MIDI: Ch '..data.learn[data.bottom_info_slider].midich..
                      ' CC '..data.learn[data.bottom_info_slider].midicc..flags..' '
                     else 
                      midi = ''  
                    end
                    
                      if data.learn[data.bottom_info_slider].osc ~= nil then 
                        osc = '[OSC: '..data.learn[data.bottom_info_slider].osc..']' else osc = '' end
                    gfx.x, gfx.y = x_offset,text_offset*6
                    gfx.drawstr(midi..osc)       
                  end             
                else
                 -- slidername
                   gfx.a = 0.4
                   gfx.x, gfx.y = x_offset,0
                   gfx.drawstr('Map '..data.bottom_info_map..' Slider '..data.bottom_info_slider..'\nEmpty')
                 -- LT
                   if lt_fxname ~= nil and lt_param_name ~= nil then
                     gfx.a = 0.4
                     gfx.x, gfx.y = x_offset,text_offset*2
                     gfx.drawstr('Last touched: '..lt_fxname..' / '.. lt_param_name)
                    end
                  -- midi
                    if data.learn ~= nil and data.use_learn == 1 and data.learn[data.bottom_info_slider] ~= nil then
                      
                      if data.learn[data.bottom_info_slider].midich ~= nil 
                        and data.learn[data.bottom_info_slider].midicc ~= nil 
                        and data.learn[data.bottom_info_slider].flags ~= nil then
                        if data.learn[data.bottom_info_slider].flags == 2 then 
                          flags = ' (soft takeover)]' else flags = ']' end
                          midi = '[MIDI: Ch '..data.learn[data.bottom_info_slider].midich..
                        ' CC '..data.learn[data.bottom_info_slider].midicc..flags..' '
                       else 
                        midi = ''  
                      end
                      
                        if data.learn[data.bottom_info_slider].osc ~= nil then 
                          osc = '[OSC: '..data.learn[data.bottom_info_slider].osc..']' else osc = '' end
                      gfx.x, gfx.y = x_offset,text_offset*3
                      gfx.drawstr(midi..osc)       
                    end                 
              end
            end
        end
    
      --------------------------------------------  
      -------------------------------------------- 
      
      if data.current_window == 1 then  -- about
         
         gfx.dest = 6
         gfx.setimgdim(6, -1, -1)  
         gfx.setimgdim(6, main_xywh[3], main_xywh[4])
         
         GUI_button(b_1_fix_xywh, 'About',1)
         GUI_button(b_close_xywh, 'X')
          
         -- main about
           gfx.a = 0.8
           gfx.setfont(1, data.fontname, button_fontsize+2)
           gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
           
           text_offset = gfx.texth
           
           gfx.x, gfx.y = x_offset+2,text_offset*2
           gfx.drawstr('Mapping panel'..'\n'..
                           'Lua script for Cockos REAPER'..'\n'..
                           'Written by Michael Pilyavskiy (Russia)'..'\n'..
                           'Version '..vrs)
                           
          local b_0_xywh = b_top_full_xywh 
                                     
         -- contacts
           b_0_xywh[2] = text_offset*7
                             
           GUI_button(b_0_xywh, 'Contacts')
           gfx.setfont(1, data.fontname, button_fontsize+2) 
           gfx.x, gfx.y = x_offset+2,text_offset*9
           
           gfx.drawstr( 'Soundcloud'..'\n'..
                        'PromoDJ'..'\n'..
                        'GitHub'..'\n'..
                        'VK'    )
         -- Support
           b_0_xywh[2] = text_offset*14
                             
           GUI_button(b_0_xywh, 'Support')         
           gfx.x, gfx.y = x_offset+2,text_offset*16
           gfx.setfont(1, data.fontname, button_fontsize+2) 
           gfx.drawstr('Cockos Forum thread'..'\n'..
                        'RMM thread')--..'\n'
                        --..'Cockos Wiki help')
                        
         -- Donation
           b_0_xywh[2] = text_offset*20
                             
          GUI_button(b_0_xywh, 'Donation')         
          gfx.x, gfx.y = x_offset+2,text_offset*22
          gfx.setfont(1, data.fontname, button_fontsize+2) 
          gfx.drawstr( 'Donate via PayPal')
          
         if active_about_link ~= nil and active_about_link ~= -100 then 
           gfx.a = 0.5
           gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
           gfx.rect(x_offset,active_about_link,control_area_xywh[3], text_offset, true)
         end 
        
           
      end  -- end if about
                  
      --------------------------------------------  
      -------------------------------------------- 
      
      if data.current_window == 2 then 
          -- buf7 routing buttons
          if update_gfx then
              gfx.dest = 7
              gfx.setimgdim(7, -1, -1)  
              gfx.setimgdim(7, main_xywh[3], main_xywh[4])
              
              GUI_button(b_1_fix_xywh, 'Routing', 1)
              GUI_button(b_close_xywh, 'X')
              
              GUI_button(b_2_xywh, 'Config # '..data.current_routing.. ' (Ctrl - write mode)')
              if data.tablet_optimised == 1 then GUI_button(b_2_1_xywh, '>',2) end
              
              gfx.a = 0.5
              gfx.rect(b_2_xywh[1]+(data.current_routing-1) * b_2_xywh[3]/(data.routing_count),
                                        b_2_xywh[2],
                                        b_2_xywh[3]/data.routing_count,
                                        b_2_xywh[4],true)
             if data.tablet_optimised == 1 then
              for k =1, data.slider_count do
                local b_01_xywh = {control_area_xywh[1]+control_area_xywh[3], 
                                  control_area_xywh[2]+ (k-1) * control_area_xywh[4]/data.slider_count , 
                                  obj_w2, 
                                  control_area_xywh[4]/data.slider_count}
                GUI_button(b_01_xywh, '>')
              end
            end
        end
        
        --------------------------------------------            
        --  buf8 routing back
          if update_gfx then  
            gfx.dest = 8
            gfx.setimgdim(8, -1, -1)  
            gfx.setimgdim(8, control_area_xywh[3], control_area_xywh[4])  

            -- edit mode frame
              if data.routing_mode == 1 then
                gfx.a = 0.8
                gfx.r, gfx.g, gfx.b = F_SetCol(color_t['red'])
                gfx.rect(0,0,control_area_xywh[3], control_area_xywh[4], 0)
              end
              
            -- current map rect
              gfx.rect((data.current_map-1)*(control_area_xywh[3]/ data.map_count),
                        0, 
                        control_area_xywh[3]/ data.map_count,
                        control_area_xywh[4]
                      )
            
          end
        
        
          
        --------------------------------------------          
        -- buf9 knob matrix
           if update_gfx_minor then
            gfx.dest = 9
            gfx.setimgdim(9, -1, -1)  
            gfx.setimgdim(9, control_area_xywh[3], control_area_xywh[4])
            for i = 1, data.map_count do
              for k = 1, data.slider_count do
                if data.map[i] == nil or data.map[i][k] == nil then val = -1 
                 else val = data.map[i][k].value end
                GUI_knob(i,k, val)
              end
            end
          end
        
          
          
        --------------------------------------------          
        -- buf10 wires
          if update_gfx_minor then
            gfx.dest = 10
            gfx.setimgdim(10, -1, -1)  
            gfx.setimgdim(10, control_area_xywh[3], control_area_xywh[4]) 
              gfx.a = 1
              gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
              x = 0
              y = 0
              w = control_area_xywh[3]
              h = control_area_xywh[4]
              -----------------------------------
                  function F_get_xy_by_ids(map0,sl0)
                    local x = (map0-0.5) * control_area_xywh[3]/data.map_count 
                    local y = (sl0-0.5) * control_area_xywh[4]/data.slider_count
                    return x,y
                  end
               -----------------------------------   
                  function F_wire_arrow(x1,y1,x2,y2)                    
                    x1 = x1 +0.5
                    x2 = x2 +0.5
                    y1 = y1
                    y2 = y2+ 0.5
                    for i = 0.5, 1, 0.1 do
                      gfx.line(x1+i, y1,
                              x1 + (x2-x1)*time_gfx,
                              y1 + (y2-y1)*time_gfx,aa)
                      gfx.line(x1-i, y1,
                              x1 + (x2-x1)*time_gfx,
                              y1 + (y2-y1)*time_gfx,aa)
                    end
                  end  
               -----------------------------------   
                  function F_wire_arrow2(r,g,b,a,x1,y1,x3,y3) 
                 
                    x1 = x1 +0.5
                    x3 = x3 +0.5
                    y1 = y1
                    y3 = y3+ 0.5
                    
                    x2 = (x3 - x1)/2      
                    y2 = y1 - (y3 - y1)/2
                    
                    function draw_curve(x_table, y_table)
                      order = #x_table
                      ----------------------------
                      function fact(n) if n == 0 then return 1 else return n * fact(n-1) end end
                      ----------------------------
                      function bezier_eq(n, tab_xy, dt)
                        local B = 0
                        for i = 0, n-1 do
                          B = B + 
                            ( fact(n) / ( fact(i) * fact(n-i) ) ) 
                            *  (1-dt)^(n-i)  
                            * dt ^ i
                            * tab_xy[i+1]
                        end 
                        return B
                      end  
                     
                      for t = 0, 1, 0.001 do
                        x_point = bezier_eq(order, x_table, t)+ t^order*x_table[order]
                        y_point = bezier_eq(order, y_table, t)+ t^order*y_table[order] 
                        gfx.x = x_point
                        gfx.y = y_point
                        gfx.a = a
                        gfx.setpixel(r,g,b)
                      end    
                    end
                    
                    draw_curve({x1,x2,x3},{y1,y2,y3})
                  end                    
               ----------------------------------- 
              if data.routing[data.current_routing] ~= nil then
                for i = 1, #data.routing[data.current_routing] do                    
                  
                  local out_link = {}
                  for num in data.routing[data.current_routing][i].str:gmatch('[%d]+') do
                    table.insert(out_link,num)
                  end
    
         
                  if out_link[1] ~= nil and out_link[2] ~= nil  then 
                    x1, y1 = F_get_xy_by_ids(out_link[1],out_link[2])
                    x2, y2 = F_get_xy_by_ids(out_link[3],out_link[4])
                    
                    gfx.a = 0.7
                    gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white']) 
                    
                    if tonumber(out_link[1]) == data.bottom_info_map and tonumber(out_link[2]) == data.bottom_info_slider then
                      local alp= 0.15
                      gfx.a = alp
                      if data.dev_mode ~= nil and data.dev_mode == 1 then
                        r,g,b = F_SetCol(color_t['green'])
                        F_wire_arrow2(r,g,b,0.3, x1,y1,x2,y2)
                       else
                        gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
                        F_wire_arrow(x1,y1,x2,y2)
                      end
                    end
                                        
                    if tonumber(out_link[3]) == data.bottom_info_map and tonumber(out_link[4]) == data.bottom_info_slider then
                      local alp= 0.3
                      gfx.a = alp
                      if data.dev_mode ~= nil and data.dev_mode == 1 then
                        r,g,b = F_SetCol(color_t['blue'])
                        F_wire_arrow2(r,g,b,0.8, x1,y1,x2,y2)
                       else
                          gfx.r, gfx.g, gfx.b = F_SetCol(color_t['blue'])
                          F_wire_arrow(x1,y1,x2,y2)
                      end
                    end                    
                    
                    gfx.a = 0.1
                    gfx.r, gfx.g, gfx.b = F_SetCol(color_t['back2']) 
                    if data.dev_mode ~= nil and data.dev_mode == 0 then
                      gfx.line(x1+0.5,y1,x2+0.5,y2,aa)
                    end
                    
                    
                  end
                end
              end
              -----------------------------------
              if r_map_out ~= nil and r_slider_out~= nil then
                gfx.a = 1
                gfx.r, gfx.g, gfx.b = F_SetCol(color_t['red'])
                x,y = F_get_xy_by_ids(r_map_out,r_slider_out)
                gfx.line(x,y,mouse.mx - control_area_xywh[1],mouse.my - control_area_xywh[2],aa)
              end
             
              
            end  -- if minor for buf10
            
      end       -- routing   
      -------------------------------------------- 
      -------------------------------------------- 
        
    -- if midiosc setup
      if data.current_window == 3 then
      -----------------------------------------------------
        if update_gfx then
          -- buttons and midi/osc selector
            gfx.dest = 11
            gfx.setimgdim(11, -1, -1)  
            gfx.setimgdim(11, main_xywh[3], main_xywh[4]) 
              local md
              if data.use_learn == 1 then md = ' (Global)' end
              if data.use_learn == 2 then md = ' (Local)' end
              GUI_button(b_1_fix_xywh, 'FixedLearn settings'..md,1)
              GUI_button(b_close_xywh, 'X') 
              GUI_button(b_2_midisetup, 'MIDI') 
              GUI_button(b_2_oscsetup, 'OSC')
            
            -- draw midi/osc selector
                 gfx.a = 0.5
                 gfx.rect(b_2_midisetup[1]+ b_2_midisetup[3] * data.current_fixedlearn,
                           b_2_midisetup[2],
                           b_2_midisetup[3],
                           b_2_midisetup[4],true)
            
            -- draw midi settings
              if data.current_fixedlearn == 0 then
                for i = 1, data.slider_count do
                  gfx.a = 0.5
                  text = 'Slider '..i..' : [not defined]'
                  if data.learn ~= nil and data.learn[i] ~= nil and data.learn[i].midicc ~= nil and data.learn[i].midich ~= nil then
                    if data.learn[i].flags == 2 then flags = ' /Soft Takeover' else flags = '' end
                    text = 'Slider '..i..' : Channel '..data.learn[i].midich..
                      ' CC '..data.learn[i].midicc..
                      flags
                    gfx.a = 0.85
                  end -- if midilearn record exists]]
                  
                  gfx.r, gfx.g, gfx.b = F_SetCol(color_t['blue'])
                  gfx.setfont(1, data.fontname, data.slider_fontsize)
                  local text_len = gfx.measurestr(text)
                  gfx.x = (control_area_xywh[3]-text_len)/2
                  gfx.y = control_area_xywh[2] + (i-1) * control_area_xywh[4]/data.slider_count
                  gfx.drawstr(text)
                end --loop
              end -- if midi learn
        
            -- draw osc settings
              if data.current_fixedlearn == 1 then 
                for i = 1, data.slider_count do
                  gfx.a = 0.5
                  text = 'Slider '..i..' : [not defined]'
                  if data.learn ~= nil and data.learn[i] ~= nil and data.learn[i].osc ~= nil then
                    text = 'Slider '..i..' : '..data.learn[i].osc
                    gfx.a = 0.85
                  end -- if midilearn record exists]]
                  
                  gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
                  gfx.setfont(1, data.fontname, data.slider_fontsize)
                  local text_len = gfx.measurestr(text)
                  gfx.x = (control_area_xywh[3]-text_len)/2
                  gfx.y = control_area_xywh[2] + (i-1) * control_area_xywh[4]/data.slider_count
                  gfx.drawstr(text)
                end --loop
              end -- if midi learn              
              
        end -- if update_gfx
      end        
    
      -------------------------------------------- 
      -------------------------------------------- 
        
    -- routing setup
      if data.current_window == 4 then
      -----------------------------------------------------
        if update_gfx then
          gfx.dest = 14
          gfx.setimgdim(14, -1, -1)  
          gfx.setimgdim(14, main_xywh[3], main_xywh[4])
          -- draw graph   
            gfx.a = 0.4
            gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])  
     
            gfx.rect(graph_rect[1], graph_rect[2],graph_rect[3],graph_rect[4],0)
            
          --backgr grad
            gfx.a = 2
              gfx.blit(12, 1, 0, 
                  0,0,control_area_xywh[3],control_area_xywh[4],
                  graph_rect[1],graph_rect[2],
                  graph_rect[3],graph_rect[4], 0,0)
            
                                       
          -- graph formula
            gfx.a = 0.4
            gfx.r, gfx.g, gfx.b = F_SetCol(color_t['green'])
            gfx.x = graph_rect[1]
            gfx.y = graph_rect[2]+graph_rect[4]
            func = data.routing[data.current_routing][rout_id].func
            
            for x = 0, 1, 0.001 do
              if func ~= nil then
                k = F_limit(func(x),0,1)
                if k == nil then k = 0 end
                gfx.lineto(graph_rect[1]+graph_rect[3]*x, 
                  graph_rect[2]+graph_rect[4] - k*graph_rect[4])
              end
            end

          -- graph grid
            gfx.a = 0.15
            gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
            -- hor
              for gr2 = 0.25, 0.75, 0.25 do
                gfx.line(graph_rect[1],graph_rect[2]+graph_rect[4]*gr2,
                        graph_rect[1]+graph_rect[3],graph_rect[2]+graph_rect[4]*gr2)
              end
            -- vert
              for gr2 = 0.25, 0.75, 0.25 do
                gfx.line(graph_rect[1]+graph_rect[3]*gr2,graph_rect[2],
                        graph_rect[1]+graph_rect[3]*gr2,graph_rect[2]+graph_rect[4])
              end        
                        
      
        end
        
 -----------------------------------------------------       
        
        if update_gfx_minor then
          -- routing setup
            gfx.dest = 13
            gfx.setimgdim(13, -1, -1)  
            gfx.setimgdim(13, main_xywh[3], main_xywh[4])
            gfx.a = 1
              GUI_button(b_1_fix_xywh, 'Routing setup',1)
              GUI_button(b_close_xywh, 'X') 
              GUI_button(b_2_xywh, 'Templates >')
            gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white']) 
            
            last_routing_config = data.routing[data.current_routing][rout_id].str
            
            local t={}
            for word in last_routing_config:gmatch('[^%s]+') do 
              if tonumber(word) ~= nil then word = tonumber(word) end
              table.insert(t, word) 
            end
            if last_routing_config_map == t[1] and last_routing_config_sl == t[2] then
              last_routing_config_state = 0 -- send
              last_routing_config_map2 = t[3] last_routing_config_sl2 = t[4]
            end
            if last_routing_config_map == t[3] and last_routing_config_sl == t[4] then
              last_routing_config_state = 1 -- receive
              last_routing_config_map2 = t[1] last_routing_config_sl2 = t[2]
            end
            
            --[[gfx.drawstr(last_routing_config)  
            gfx.drawstr(last_routing_config_map)  
            gfx.drawstr(last_routing_config_sl) ]] 
            
            -- local
            --last_routing_config
            --last_routing_config_map
            --last_routing_config_sl
            --last_routing_config_state
            
            
          ---------------------------------
                         
              GUI_knob2(bigknob1_xywh,
                          last_routing_config_map, 
                          last_routing_config_sl, 
                          data.map[last_routing_config_map][last_routing_config_sl].value,
                          last_routing_config_state)
                          
              GUI_knob2(bigknob2_xywh,
                          last_routing_config_map2, 
                          last_routing_config_sl2, 
                          data.map[last_routing_config_map2][last_routing_config_sl2].value,
                          _)
                    
          local val_y_offs = -y_offset
          local val_x_offs = x_offset  
                  
          -- backgr val
            gfx.a = 0.4
            gfx.r, gfx.g, gfx.b = F_SetCol(color_t['black'])
            gfx.rect(graph_rect[1]+val_x_offs,
                      graph_rect[2]- val_y_offs,
                      55,
                      32,1)
            
            
          -- draw val
            gfx.x = graph_rect[1] + x_offset+val_x_offs
            gfx.y = graph_rect[2]-val_y_offs
            gfx.a = 1
            gfx.r, gfx.g, gfx.b = F_SetCol(color_t['blue'])
            local val1 = data.map[last_routing_config_map][last_routing_config_sl].value
            val1 = math.floor(val1*1000)/1000
            --val1 = tostring(val1):sub(1,7)            
            gfx.drawstr(val1)
            gfx.x = graph_rect[1] + x_offset+val_x_offs
            gfx.y = graph_rect[2]-val_y_offs+15
            local val2 = data.map[last_routing_config_map2][last_routing_config_sl2].value
            val2 = math.floor(val2*1000)/1000
            --val2 = tostring(val2):sub(1,7)
            gfx.drawstr(val2)
            
          -- formula
            gfx.a = 2
              gfx.blit(12, 1, 0, 
                  0,0,control_area_xywh[3],control_area_xywh[4],
                  graph_rect[1],graph_rect[2]+graph_rect[4]+y_offset,
                  graph_rect[3],form_text_h, 0,0)
              gfx.a = 0.2
              gfx.rect(graph_rect[1],graph_rect[2]+graph_rect[4]+y_offset,
                  graph_rect[3],form_text_h,0) 
                  
          -- formula text
            if data.expert_mode ~= nil and data.expert_mode == 1 then
              gfx.r, gfx.g, gfx.b = F_SetCol(color_t['red'])
              str0 = ''
             else
              str0 = 'Formula: '
              gfx.r, gfx.g, gfx.b = F_SetCol(color_t['white'])
            end
                
                gfx.setfont(1, data.fontname, button_fontsize+2)  
                local str = str0..data.routing[data.current_routing][rout_id].form
                gfx.x = graph_rect[1]+(graph_rect[3]-gfx.measurestr(str))/2+1
                gfx.y = graph_rect[2] + graph_rect[4] + form_text_h/3
                gfx.a = 0.8 
                gfx.drawstr(str)
        end
      end -- if routing setup
      
      -------------------------------------------- 
      --------------------------------------------
      
      -- buf20 common
        gfx.dest = 20     
        gfx.setimgdim(20, main_xywh[3], main_xywh[4]) 
        
        
        -- main window
          if data.current_window == 0 then
            gfx.a = 1
            gfx.blit(1, 1, 0, --backgr
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)              
            gfx.blit(2, 1, 0, --main window buttons
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)   
            gfx.blit(4, 1, math.rad(0), --main window sliders
                0,0,control_area_xywh[3],control_area_xywh[4],
                control_area_xywh[1],control_area_xywh[2],control_area_xywh[3],control_area_xywh[4], 0,0)
            gfx.blit(5, 1, math.rad(0), --bottom info
                  0,0,obj_w,bottom_info_h,
                  control_area_xywh[1],control_area_xywh[2]+control_area_xywh[4]+y_offset,
                  obj_w,bottom_info_h,0,0)
           end 
           
        -- about 
          if data.current_window == 1 then
            gfx.a = 1
            gfx.blit(1, 1, 0, --backgr
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)
            gfx.blit(6, 1, 0, --about
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)                
          end
          
        -- routing 
          if data.current_window == 2 then 
            gfx.a = 1
            gfx.blit(1, 1, 0, --backgr
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0) 
            gfx.blit(7, 1, 0, --rout buttons
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)  
            gfx.blit(12, 1, 0, --backgr grad
                0,0,control_area_xywh[3],control_area_xywh[4],
                control_area_xywh[1],control_area_xywh[2],
                control_area_xywh[3],control_area_xywh[4], 0,0)                             
            gfx.blit(5, 1, math.rad(0), --bottom info
                0,0,obj_w,bottom_info_h,
                control_area_xywh[1],control_area_xywh[2]+control_area_xywh[4]+y_offset,
                obj_w,bottom_info_h,0,0)
            gfx.blit(8, 1, 0, --matix back
                0,0,control_area_xywh[3],control_area_xywh[4],
                control_area_xywh[1],control_area_xywh[2],
                control_area_xywh[3],control_area_xywh[4], 0,0)                   
            gfx.blit(10, 1, 0, --wires
                0,0,control_area_xywh[3],control_area_xywh[4],
                control_area_xywh[1],control_area_xywh[2],
                control_area_xywh[3],control_area_xywh[4], 0,0)
            gfx.blit(9, 1, 0, --matix knobs
                0,0,control_area_xywh[3],control_area_xywh[4],
                control_area_xywh[1],control_area_xywh[2],
                control_area_xywh[3],control_area_xywh[4], 0,0) 
          end      
          
        -- fixlearn 
          if data.current_window == 3 then
            gfx.a = 1
            gfx.blit(1, 1, 0, --backgr
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)
            gfx.blit(11, 1, 0, --fixedlearn buttons
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)
            gfx.a = 0.5
            gfx.blit(12, 1, 0, --backgr grad
                0,0,control_area_xywh[3],control_area_xywh[4],
                control_area_xywh[1],control_area_xywh[2],
                control_area_xywh[3],control_area_xywh[4], 0,0)
            gfx.a = 1
            gfx.blit(5, 1, math.rad(0), --bottom info
                0,0,obj_w,bottom_info_h,
                control_area_xywh[1],control_area_xywh[2]+control_area_xywh[4]+y_offset,
                obj_w,bottom_info_h,0,0)                                                  
          end 
        
        -- routing config
          if data.current_window == 4 then
            gfx.a = 1
            gfx.blit(1, 1, 0, --backgr
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)
            gfx.blit(14, 1, 0, --graph
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)                 
            gfx.blit(13, 1, 0, --knobs
                0,0,main_xywh[3],main_xywh[4],
                0,0,main_xywh[3],main_xywh[4], 0,0)                         
          end            
          
      --------------------------------------------
      --------------------------------------------
      
      update_gfx = false
      update_gfx_minor = false
    end
  end

-----------------------------------------------------------------------       
  function GUI_routing_menu()
    gfx.x,gfx.y = mouse.mx, mouse.my
    local config_actions = 
          'Clear current routing configuration'..
          '|Clear all routing configurations'
          
    local ret_main_act = gfx.showmenu(config_actions)
    
    if ret_main_act == 1 then --Clear current routing
      data.routing[data.current_routing] = nil
      ENGINE_return_data_to_projextstate2(false)
    end
    
    if ret_main_act == 2 then --Clear all routing configs / clear when expert mode switch
      local ret = reaper.MB('Clear all routing configurations?','mpl Mapping Panel',4)
      if ret == 6 then 
        for i = 1, data.routing_count do
          data.routing[i] = nil
          ENGINE_return_data_to_projextstate2(false)
        end
      end
    end    
  end
  
-----------------------------------------------------------------------    
  function GUI_main_menu()
    gfx.x,gfx.y = mouse.mx, mouse.my
    local menu_switch = {}
    if data.tablet_optimised == 1 then menu_switch['tablet'] = "!" else menu_switch['tablet']="" end
    if data.slider_mode == 1 then menu_switch['slider_mode'] = "!" else menu_switch['slider_mode']="" end
    if data.run_docked == 1 then menu_switch['run_docked'] = "!" else menu_switch['run_docked']="" end
    if data.use_learn == 1 or data.use_learn == 2 then menu_switch['use_learn'] = "!" else menu_switch['use_learn']="" end
    if data.use_learn == 0 then menu_switch['use_learn_setup'] = "#" else menu_switch['use_learn_setup']="" end
    if data.use_ext_actions == 1 then menu_switch['use_ext_actions'] = "!" else menu_switch['use_ext_actions']="" end
    if data.dev_mode == 1 then menu_switch['dev_mode'] = "!" else menu_switch['dev_mode']="" end
    if data.expert_mode == 1 then menu_switch['expert_mode'] = "!" else menu_switch['expert_mode']="" end
    
    local main_actions = 
      'Routing matrix'..
      '|'..menu_switch['use_learn_setup']..'FixedLearn settings'..
      '|About'..
      '||'..menu_switch['use_learn']..'Enable FixedLearn'..      
      --'|'..menu_switch['tablet']..'Enable Tablet mode'..
      '|'..menu_switch['slider_mode']..'Enable Relative slider mouse tracking'..
      '|'..menu_switch['run_docked']..'Run docked'..
      '||Save config to external file'..
      '|Load config from external file'..
      '||'..menu_switch['use_ext_actions']..'Use external actions'..
      '||'..menu_switch['dev_mode']..'Developer mode'..
      '|'..menu_switch['expert_mode']..'Expert mode'
      
      
    local ret_main_act = gfx.showmenu(main_actions)
    
    ------------
    -- separator 
    ------------
    -- routing
      if ret_main_act == 1 then 
        data.current_window = 2
        ENGINE_return_data_to_projextstate2(false)
      end
      
    -- midiosc setup
      if ret_main_act == 2 then 
        data.current_window = 3
        ENGINE_return_data_to_projextstate2(false)
      end
                
    -- about
      if ret_main_act == 3 then 
        data.current_window = 1
        update_gfx = true
        update_gfx_minor = true
      end
      
    -- use_learn
      if ret_main_act == 4 then 
        if data.use_learn == 0 then 
          data.use_learn = 1 
          ENGINE_return_data_to_projextstate2(false, false)
          ENGINE_get_params_from_ext_state(false) 
          return end
        if data.use_learn == 1 or data.use_learn == 2 then 
          data.use_learn = 0 
          ENGINE_return_data_to_projextstate2(false, false)
        end
        
      end 
            
    --[[ run with table optimised
      if ret_main_act == 5 then 
        data.tablet_optimised = math.floor(math.abs(data.tablet_optimised-1))
        ENGINE_return_data_to_projextstate2(false)
      end  ]]  
      
    -- slider mode
      if ret_main_act == 5 then 
        data.slider_mode = math.floor(math.abs(data.slider_mode-1))
        ENGINE_return_data_to_projextstate2(false)
      end   
       
    -- run_docked
      if ret_main_act == 6 then 
        data.run_docked = math.floor(math.abs(data.run_docked-1))
        ENGINE_return_data_to_projextstate2(false)
        MAIN_exit() 
      end    

                
    ------------  
    -- separator 
    ------------
    
    -- store to external file
      if ret_main_act == 7 then 
        ENGINE_return_data_to_projextstate2(true)
        reaper.MB('Stored to '..config_path,'Save config to external file',0)
      end
    
    -- load from external file
      if ret_main_act == 8 then 
        local ret_load = ENGINE_get_params_from_ext_state(true)
        if ret_load == 1 then   
          local ret = reaper.MB('Load config from '..config_path,'mpl Mapping Panel',4)
          if ret == 6 then ENGINE_return_data_to_projextstate2(false) end
         else
          reaper.MB('Error load config from external file: '..config_path..' not exists','mpl Mapping Panel',0)
        end
      end 
      
    ------------  
    -- separator 
    ------------
          
    -- use_ext_actions
      if ret_main_act == 9 then 
        data.use_ext_actions = math.floor(math.abs(data.use_ext_actions-1))
        ENGINE_return_data_to_projextstate2(false)
      end    
      
    ------------  
    -- separator 
    ------------
          
    -- dev_mode
      if ret_main_act == 10 then 
        data.dev_mode = math.floor(math.abs(data.dev_mode-1))
        ENGINE_return_data_to_projextstate2(false)
      end   
      
    -- expert mode
      if ret_main_act == 11 then 
        ret = reaper.MB('This also erase existing routing configs','Switch expert mode',1)
        if ret == 1 then 
          data.expert_mode = math.floor(math.abs(data.expert_mode-1))
          data.routing = {}
          ENGINE_return_data_to_projextstate2(false)
        end
      end           
                
  end
  
-----------------------------------------------------------------------    
  function GUI_map_menu() 
    local ret_map_act,map_name,newname,ret_clear, 
      tr_link, found_fx,track, found_fx_tr,fx_guid,found_fx_tr_id,linked_track,
      fx_guid, paramnumber
    gfx.x,gfx.y = mouse.mx, mouse.my
        
    if data.map[data.current_map] ~= nil and  data.map[data.current_map].track_link ~= nil then
      linked_track = reaper.BR_GetMediaTrackByGUID(0, data.map[data.current_map].track_link)
      if linked_track ~= nil then 
        _,track_link_name = reaper.GetSetMediaTrackInfo_String(linked_track, 'P_NAME', '', false)
        if track_link_name == '' then track_link_name = 'Track '..reaper.CSurf_TrackToID(linked_track, false) end
       else
        track_link_name = 'Not found'
      end 
     else
      track_link_name = '[none]'
    end
    
    
    if data.map[data.current_map] ~= nil and data.map[data.current_map].fx_link ~= nil then
      for i = 1, reaper.CountTracks(0) do
        track = reaper.GetTrack(0,i-1)
        if track ~= nil then
          for k =1 , reaper.TrackFX_GetCount(track) do
            fx_guid = reaper.TrackFX_GetFXGUID(track, k-1)
            if data.map[data.current_map].fx_link == fx_guid then 
              found_fx = k-1
              found_fx_tr_id = i-1
            end
          end
        end
      end
      found_fx_tr = reaper.GetTrack(0,found_fx_tr_id)
      if found_fx ~= nil then  _, fx_link_name = reaper.TrackFX_GetFXName(found_fx_tr, found_fx,'') 
       else fx_link_name = 'Not found' end  
     else -- if not exists
      fx_link_name = '[none]'
    end
    
    local menu_switch = {}
        if found_fx_tr == nil then menu_switch['fx_link'] = "#" else menu_switch['fx_link']="" end
        if linked_track == nil then menu_switch['track_link'] = "#" else menu_switch['track_link']="" end
        if data.map[data.current_map] ~= nil and data.map[data.current_map].bypass_learn == 1 then menu_switch['byp_learn'] = "!" else menu_switch['byp_learn']="" end
        
    map_actions = 
      "Rename current map"..
      '|Current map: Clear all sliders'..
      '|Current map: Clear broken sliders'..
      '||All maps: Clear all sliders'..
      '|All maps: Clear broken sliders'..
      '|All maps: Clear duplicated sliders'..
      '|All maps: Clear FX links'..
      '|All maps: Clear track links'..
      '||#FX link: '..fx_link_name..      
      '|Current map: Link to last touched fx'..
      '|'..menu_switch['fx_link']..'Current map: Clear FX link'..
      '|'..menu_switch['fx_link']..'Current map: Float linked FX'..
      '||#Track link: '..track_link_name..      
      '|Current map: Link to last touched track'..
      '|'..menu_switch['track_link']..'Current map: Clear track link'..
      '|'..menu_switch['track_link']..'Current map: Select / scroll to linked track'..
      '||'..menu_switch['byp_learn']..'Current map: Bypass FixedLearn'
      
      
    -- DRAW MENU --
     
    ret_map_act = gfx.showmenu(map_actions)
      --msg(ret_map_act)
      -- if rename map
        if ret_map_act == 1 then           
          if data.map[data.current_map] ~= nil then 
            map_name = data.map[data.current_map]['map_name']
            if map_name == nil then map_name = '' end
            _, newname = reaper.GetUserInputs('Rename current map', 1, 'New name', map_name)
           else
            data.map[data.current_map] = {}
            _, newname = reaper.GetUserInputs('Rename current map', 1, 'New name', '')
          end
          data.map[data.current_map].map_name = newname
          ENGINE_return_data_to_projextstate2(false)
        end
      
      -- if clear
        if ret_map_act == 2 then
          ret_clear = reaper.MB('Clear current map?', 'mpl Mapping Panel', 4)
          if ret_clear == 6 then
            data.map[data.current_map] = nil
            ENGINE_return_data_to_projextstate2(false)
          end
        end
      
      -- Clear broken sliders in current map
        if ret_map_act == 3 then
          for k = 1, data.slider_count do
            val = ENGINE_GetSetParamValue(data.current_map, k, false)
            if val == -2 then 
              data.map[data.current_map][k] = nil
            end
          end
          ENGINE_return_data_to_projextstate2(false)
          ENGINE_get_params_from_ext_state(false) 
        end
                
      -- if clear all maps
        if ret_map_act == 4 then
          ret_clear = reaper.MB('Clear all maps?', 'mpl Mapping Panel', 4)
          if ret_clear == 6 then
            data.map = {}
            ENGINE_return_data_to_projextstate2(false)
            ENGINE_get_params_from_ext_state(false) 
          end
        end
        
      -- Clear broken sliders in all maps
        if ret_map_act == 5 then
          for i = 1, data.map_count do
            for k = 1, data.slider_count do
              val = ENGINE_GetSetParamValue(i, k, false)
              if val == -2 then 
                data.map[i][k] = nil
              end
            end
          end          
          ENGINE_return_data_to_projextstate2(false)
          ENGINE_get_params_from_ext_state(false) 
        end  
        
      -- clear duplicated
        if ret_map_act == 6 then
          local t = {}
          for i = 1, data.map_count do
            for k = 1, data.slider_count do
              if data.map[i] ~= nil and data.map[i][k] ~= nil then
                  fx_guid = data.map[i][k].fx_guid
                  paramnumber = data.map[i][k].paramnumber
                  
                  -- check for duplicates
                  for m = 1, data.map_count do
                    for n = 1, data.slider_count do
                      if data.map[m] ~= nil and data.map[m][n] ~= nil then
                        fx_guid1 = data.map[m][n].fx_guid
                        paramnumber1 = data.map[m][n].paramnumber
                        if fx_guid1 == fx_guid and paramnumber1 == paramnumber then
                          if m == i and n == k then
                            
                           else 
                            data.map[m][n] = nil
                          end
                        end
                      end
                    end
                  end  
              end
            end
          end
            ENGINE_return_data_to_projextstate2(false)
            ENGINE_get_params_from_ext_state(false)
        end
        
      
          
        
        
                
      -- Clear FX link from all maps
        if ret_map_act == 7 then
          ret_clear = reaper.MB('Clear FX links from all maps?', 'mpl Mapping Panel', 4)
          if ret_clear == 6 then
            for i = 1, data.map_count do
              if data.map[i] ~= nil then 
                data.map[i].fx_link = nil
                ENGINE_return_data_to_projextstate2(false)
              end
            end
          end
        end  
        
      -- Clear track links from all maps
        if ret_map_act == 8 then
          ret_clear = reaper.MB('Clear track links from all maps?', 'mpl Mapping Panel', 4)
          if ret_clear == 6 then
            for i = 1, data.map_count do
              if data.map[i] ~= nil then 
                data.map[i].track_link = nil
                ENGINE_return_data_to_projextstate2(false)
              end
            end
          end
        end         
        
        
            ---------------------- FX LINK --------------  
              
      -- Link current map to last touched fx     
        if ret_map_act == 10 then
          if last_touched_fx ~= nil then 
            data.map[data.current_map].fx_link = last_touched_fx
            ENGINE_return_data_to_projextstate2(false)
          end
        end
        
      -- Clear FX link from current map
        if ret_map_act == 11 then
          data.map[data.current_map].fx_link = nil
          ENGINE_return_data_to_projextstate2(false)
        end
      
      -- Float linked FX
        if  ret_map_act == 12 then 
          if found_fx_tr ~= nil then      
            reaper.TrackFX_SetOpen(found_fx_tr, found_fx, true)
          end
        end

              ---------------------- track LINK --------------  
              
      -- Link current map to last touched track    
        if ret_map_act == 14 then
          if last_touched_track_guid ~= nil then 
            if data.map[data.current_map] == nil then 
              data.map[data.current_map] = {} end
            data.map[data.current_map].track_link = last_touched_track_guid
            ENGINE_return_data_to_projextstate2(false)
          end
        end
        
      -- Clear tracklink from current map
        if ret_map_act == 15 then
          data.map[data.current_map].track_link = nil
          ENGINE_return_data_to_projextstate2(false)
        end
      
      -- select/scroll to linked track
        if  ret_map_act == 16 then 
          if linked_track ~= nil then
            reaper.SetMixerScroll(linked_track)
            reaper.SetOnlyTrackSelected(linked_track)
          end
        end  
        
      -- bypass fixed learn for cur map
        if ret_map_act == 17 then 
          data.map[data.current_map].bypass_learn = math.abs(data.map[data.current_map].bypass_learn-1)
          ENGINE_set_learn()
          ENGINE_return_data_to_projextstate2(false)
        end
                        
  end            
  
-----------------------------------------------------------------------    
  function GUI_formula_menu() local ret
    gfx.x,gfx.y = mouse.mx, mouse.my

      local basic_formula_actions = 
        'Basic Formula templates'..
        '||Default'..
        '|sin(x*a)'..
        '|lim(x,limit_min,limit_max)'..
        '|wrap(x)'..
        '|sqr(x)'..
        '|invert(x)'..
        '|abs(x)'..
        '|scaleto(x,limit_min,limit_max)'..
        '|x^a'..
        '|match(x,curve)'..
        '|<vca()'
        
                   
    if data.expert_mode == 0 then
      formula_actions ='#'.. basic_formula_actions
     else
      formula_actions = 
       '#Expert Formula templates'..
       '|Default'..
       '|Triangle'..
       '|Mouse'..
       '|LFO(period)'..
       '|Cycle(period)'..
       '|track_vol(map,slider)'..
       '|track_pan(map,slider)'..
       '|track_peak(map,slider)'..
       '|Master playrate'..
       '||>'..basic_formula_actions..'||Lua Math'
    end
      
      ------------------------------
      function F_set_formula(form, conf_id,id)  local test_func
        test_func = load("local x = ... return "..form)
        if data.expert_mode == 1 then
          data.routing[conf_id][id].form = form
          ENGINE_return_data_to_projextstate2(false)
          ENGINE_dump_functions_to_routing_table()
        end
        if test_func ~= nil and data.expert_mode == 0 then
          if form == '' then form = 'x' end
          data.routing[conf_id][id].form = form
          ENGINE_return_data_to_projextstate2(false)
          ENGINE_dump_functions_to_routing_table()
        end
      end
      ------------------------------
        
    -- draw
      ret_formula_act = gfx.showmenu(formula_actions)  
    if data.expert_mode == 1 then
    
      local t = {}
      for num in data.routing[data.current_routing][rout_id].str:gmatch('[%d]+') do
        table.insert(t, tonumber(num)) end
      local m = t[1]
      local sl = t[2]
      
      -- def
        if ret_formula_act == 2 then F_set_formula('y = x', data.current_routing, rout_id)  end      
      -- tri
        if ret_formula_act == 3 then F_set_formula('if x < 0.5 then y = x else y = 1-x end', data.current_routing, rout_id) end
      -- mouse
        if ret_formula_act == 4 then  F_set_formula('y = mouse.mx/1000', data.current_routing, rout_id) end   
      -- lfo
        if ret_formula_act == 5 then F_set_formula('y = lfo(5)', data.current_routing, rout_id) end       
      -- cycle
        if ret_formula_act == 6 then F_set_formula('y = cycle(5)', data.current_routing, rout_id) end                 
      -- track vol        
        if ret_formula_act == 7 then  F_set_formula('y = track_vol('..m..','..sl..')', data.current_routing, rout_id)  end 
      -- track pan        
        if ret_formula_act == 8 then F_set_formula('y = track_pan('..m..','..sl..')', data.current_routing, rout_id)  end     
      -- track peak        
        if ret_formula_act == 9 then F_set_formula('y = track_peak('..m..','..sl..')', data.current_routing, rout_id) end 
      -- master rate      
        if ret_formula_act == 10 then F_set_formula('y = master_rate()', data.current_routing, rout_id) end                                
      -- basic templates 
        if ret_formula_act == 11 then F_set_formula('y = x', data.current_routing, rout_id) end 
        if ret_formula_act == 12 then F_set_formula('y = math.sin(x)', data.current_routing, rout_id) end 
        if ret_formula_act == 13 then F_set_formula('y = lim(x, 0, 1)', data.current_routing, rout_id) end 
        if ret_formula_act == 14 then F_set_formula('y = x % 1', data.current_routing, rout_id) end 
        if ret_formula_act == 15 then F_set_formula('y = math.sqrt(x)', data.current_routing, rout_id) end 
        if ret_formula_act == 16 then F_set_formula('y = 1-x', data.current_routing, rout_id) end 
        if ret_formula_act == 17 then F_set_formula('y = math.abs(x)', data.current_routing, rout_id) end 
        if ret_formula_act == 18 then F_set_formula('y = scaleto(x, 0, 1)', data.current_routing, rout_id) end 
        if ret_formula_act == 19 then F_set_formula('y = x ^ 1', data.current_routing, rout_id) end 
        if ret_formula_act == 20 then F_set_formula('y = match(x, curve)', data.current_routing, rout_id) end 
        if ret_formula_act == 21 then F_open_URL('http://lua-users.org/wiki/MathLibraryTutorial') end
    end
    
    if data.expert_mode == 0 then       
      if ret_formula_act ~= nil and ret_formula_act ~= 0 then
      
        current_form = data.routing[data.current_routing][rout_id].form
        
      -- default
        if ret_formula_act == 2 then F_set_formula('x',data.current_routing,rout_id) end    
        
      -- sin      
        if ret_formula_act == 3 then 
          ret, ret_str = reaper.GetUserInputs('Set x coeff.', 1, '','1')
          if ret ~= nil and ret_str ~= '' and tonumber(ret_str) ~= nil then 
            F_set_formula('sin(('..current_form..')*'..ret_str..')*0.5+0.5',data.current_routing,rout_id) 
          end
        end
        
      -- lim   
        if ret_formula_act == 4 then 
          ret, ret_str = reaper.GetUserInputs('Set limits', 3, 'Min Limit,Max Limit,Func','0,1,'..current_form)
          if ret ~= nil and ret_str ~= '' then 
            local lim_str_t = {}
            for value in ret_str:gmatch('[^%,]+') do
              if tonumber(value) ~= nil then value = tonumber(value) end
              table.insert(lim_str_t, value)
            end
          
            if lim_str_t[1] ~= nil and lim_str_t[2] ~= nil then          
              F_set_formula('lim('..lim_str_t[3]..','..lim_str_t[1]..','..lim_str_t[2]..')',
                data.current_routing,rout_id) 
            end
          end
        end
        
      -- wrap        
        if ret_formula_act == 5 then 
          ret, ret_str = reaper.GetUserInputs('Type funct for wrap', 1, '', current_form)
          if ret ~= nil and ret_str ~= '' then 
            F_set_formula('wrap('..ret_str..')',data.current_routing,rout_id) 
          end
        end
        
      -- sqr
        if ret_formula_act == 6 then F_set_formula('sqr('..current_form..')',data.current_routing,rout_id) end
        
      -- inv
        if ret_formula_act == 7 then 
          ret, ret_str = reaper.GetUserInputs('Type func for invert', 1, '', current_form)
          if ret ~= nil and ret_str ~= '' then 
            F_set_formula('1-('..ret_str..')',data.current_routing,rout_id)
          end
        end
        
      -- abs
        if ret_formula_act == 8 then 
          ret, ret_str = reaper.GetUserInputs('Type func for take absolute', 1, '', current_form)
          if ret ~= nil and ret_str ~= '' then 
            F_set_formula('abs('..ret_str..')',data.current_routing,rout_id)
          end
        end      
          
      -- scaleto   
        if ret_formula_act == 9 then 
          ret, ret_str = reaper.GetUserInputs('Set scale', 3, 'Min scale limit,Max scale limit,Func','0,1,'..current_form)
          if ret ~= nil and ret_str ~= '' then 
            local lim_str_t = {}
            for value in ret_str:gmatch('[^%,]+') do
              if tonumber(value) ~= nil then value = tonumber(value) end
              table.insert(lim_str_t, value)
            end
            local lim_min = lim_str_t[1]
            local lim_max = lim_str_t[2]
            if lim_min ~= nil and lim_max ~= nil then          
              F_set_formula('scaleto('..lim_str_t[3]..','..lim_min..','..lim_max..')',data.current_routing,rout_id) 
            end
          end
        end        
        
      -- pow   
        if ret_formula_act == 10 then 
          ret, ret_str = reaper.GetUserInputs('Set scale', 2, 'pow,Func','1,'..current_form)
          if ret ~= nil and ret_str ~= '' then 
            local str_t = {}
            for value in ret_str:gmatch('[^%,]+') do
              if tonumber(value) ~= nil then value = tonumber(value) end
              table.insert(str_t, value)
            end
            local deg = str_t[1]
            local fun = str_t[2]
            if deg ~= nil and fun ~= nil then          
              F_set_formula('('..fun..')^'..deg, data.current_routing,rout_id) 
            end
          end
        end 
        
      -- match   
        if ret_formula_act == 11 then 
          F_set_formula('match(x,curve)',data.current_routing,rout_id) 
        end         

      -- match   
        if ret_formula_act == 12 then 
          F_set_formula('vca()',data.current_routing,rout_id) 
        end  
                       
      end 
    end        
    
  
  end
  
-----------------------------------------------------------------------   
  function GUI_fixedlearn_menu() local s1,flags,ret_flearn_act
    gfx.x,gfx.y = mouse.mx, mouse.my
    local ret_flearn_act
    gfx.x,gfx.y = mouse.mx, mouse.my
    local menu_switch = {}
    if data.use_learn == 2 then menu_switch['use_learn'] = "!" else menu_switch['use_learn']="" end
        
    fixedlearn_actions = 
      'AutoLearn MIDI CC'..
      '||Clean MIDI Learn'..
      '|Clean OSC Learn'..
      '|Clean all Learn'..
      '||'..menu_switch['use_learn']..'Use exclusive learn for current instance'
      
    -- draw
      ret_flearn_act = gfx.showmenu(fixedlearn_actions)
      
    -- auto learn 
      if ret_flearn_act == 1 then
        _, s1 = reaper.GetUserInputs('MIDI Learn for slider '..data.bottom_info_slider,
                  4, 'Channel,First CC number,Last CC number,Soft takeover(Y/N)', '')
        
        local s1_t = {}
        for value in s1:gmatch('[^%,]+') do
          if tonumber(value) ~= nil then value = tonumber(value) end
          table.insert(s1_t, value)
        end
        
        if #s1_t == 4 then
          if s1_t[1] == nil or s1_t[1] < 1 or s1_t[1] > 16 then return end
          if s1_t[2] == nil or s1_t[2] < 0 or s1_t[2] > 127 then return end
          if s1_t[3] == nil or s1_t[3] < 0 or tonumber(s1_t[3]) > 127 then return end
          if s1_t[4]:lower() == 'y' then flags = 2 else flags = 0 end
          
          if data.learn == nil then data.learn = {} end
          for i = 1, s1_t[3] - s1_t[2] + 1 do
            if data.learn[i] == nil then data.learn[i] = {} end
            data.learn[i].midicc = s1_t[2] + i - 1
            data.learn[i].midich = s1_t[1]
            data.learn[i].flags = tonumber(flags)
          end
          ENGINE_return_data_to_projextstate2(false)
          set_learn = true 
        end
      end
    
    -- clean midi
      if ret_flearn_act == 2 then
        for i = 1, data.slider_count do
          if data.learn ~= nil and 
            data.learn[i] ~= nil then
            data.learn[i].midicc = nil
            data.learn[i].midich = nil
            data.learn[i].flags = nil
          end
        end
        ENGINE_return_data_to_projextstate2(false)
        set_learn = true 
      end

    -- clean osc
      if ret_flearn_act == 3 then
        for i = 1, data.slider_count do
          if data.learn ~= nil and 
            data.learn[i] ~= nil then
            data.learn[i].osc = nil
          end
        end
        ENGINE_return_data_to_projextstate2(false)
        set_learn = true 
      end

    -- clean all
      if ret_flearn_act == 4 then        
        for i = 1, data.slider_count do
          if data.learn ~= nil and 
            data.learn[i] ~= nil then
            data.learn[i].midicc = nil
            data.learn[i].midich = nil
            data.learn[i].flags = nil            
            data.learn[i].osc = nil
          end
        end
        ENGINE_return_data_to_projextstate2(false)
        set_learn = true 
      end
    
    -- Use exclusive learn for this instance
      if ret_flearn_act == 5 then   
        if data.use_learn == 1 then 
          data.use_learn = 2 
          ENGINE_return_data_to_projextstate2(false)
          return 
        end
        if data.use_learn == 2 then 
          data.use_learn = 1 
          ENGINE_return_data_to_projextstate2(false)
          return 
        end
      end     
  end

-----------------------------------------------------------------------    
  function F_build_slider_routing_menu(map_id, slider_id) local rout
    local table_menu={} -- menu table 
    
    if data.routing ~= nil 
      and data.routing[data.current_routing] ~= nil then
      for i = 1, #data.routing[data.current_routing] do
        -- receive
          if data.routing[data.current_routing][i].str:match('[%d]+ [%d]+ '..map_id..' '..slider_id) ~= nil then
            local out_link = {}
            for num in data.routing[data.current_routing][i].str:gmatch('[^%s]+') do table.insert(out_link,num) end
            table.insert(table_menu, {i,1,
              data.map[tonumber(out_link[1])][tonumber(out_link[2])].gfx_name..', Map'..
                out_link[1]..' Slider'..out_link[2]..', Formula y='..data.routing[data.current_routing][i].form})
          end
        -- receive
          if data.routing[data.current_routing][i].str:match(map_id..' '..slider_id..' [%d]+ [%d]+') ~= nil then
            local out_link = {}
            for num in data.routing[data.current_routing][i].str:gmatch('[^%s]+') do table.insert(out_link,num) end
            table.insert(table_menu, {i,0,
              data.map[tonumber(out_link[3])][tonumber(out_link[4])].gfx_name..', Map'..
                out_link[3]..' Slider'..out_link[4]..', Formula y='..data.routing[data.current_routing][i].form})
          end        
      end
    end
    
    
    if table_menu ~= nil and #table_menu > 0 then 
      rout = '||#Routing'
      for i = 1, #table_menu do
        if table_menu[i][2] == 0 then dir = 'Send to: ' else dir = 'Receive from: ' end
        rout = rout..'|'..dir..table_menu[i][3]
      end
     else 
      rout = ''
    end
    
    return rout, table_menu
  end

-----------------------------------------------------------------------   
  function ENGINE_Get_last_touched_value()
    _, trackid, fxid, paramid = reaper.GetLastTouchedFX()
    if trackid == nil or fxid == nil or paramid == nil then return end
    -- get track
      if trackid == 0 then track = reaper.GetMasterTrack(0) 
        else track = reaper.GetTrack(0,trackid-1) end
      if track == nil then return end
      track_guid = reaper.GetTrackGUID(track)
      
    -- get FX
      FX_guid = reaper.TrackFX_GetFXGUID(track, fxid)
      if FX_guid == nil then return end
      
    -- get param name
      _, fxname = reaper.TrackFX_GetFXName(track, fxid, '')
      _, param_name = reaper.TrackFX_GetParamName(track, fxid, paramid, '')
          
    -- form gfx name
      gfx_name = fxname:gsub('[%p ]','')..' / '..param_name:gsub('[%p ]','')
      gfx_name = gfx_name:gsub('VST', '')
      gfx_name = gfx_name:gsub('AU', '')
      gfx_name = gfx_name:gsub('JS', '')
      
    return track_guid, FX_guid, paramid, fxname, param_name, gfx_name
  end
  
  
-----------------------------------------------------------------------  
  function GUI_slider_menu(map, slider) --local remove_t,rout_actions_count
    local slider_actions,ret_rb_slider,newname,fx_name,fx_name_out,gfx_name,
      par_name_out,par_name,colorOut,r,g,b, state
    gfx.x,gfx.y = mouse.mx, mouse.my
    gfx.setfont(1, data.fontname, data.slider_fontsize)
    
    routing_slider_actions, menu_table = F_build_slider_routing_menu(map, slider)
    rout_actions_count = 11
    if data.map[map] ~= nil and data.map[map][slider] ~= nil then 
      state = 0
      slider_actions = 
        'Get last touched parameter' ..
        '||Rename slider'..
        '|Clear slider'..
        '|Change color'..
        '||Parameter modulation'..
        '|Float related FX'..
        '||Remove all input wires from slider'..
        '|Remove all output wires from slider'..
        '|Remove all wires from slider'..
        routing_slider_actions
        
        
        --'||MIDI OSC learn/test'
     else
      state = 1
      track_guid, FX_guid, paramid, fxname, param_name, gfx_name = ENGINE_Get_last_touched_value()
      if fxname ~= nil and param_name ~= nil then
        slider_actions = 
          '#Last: '..fxname..' / '..param_name..
          '|Get last touched parameter'
       else
        slider_actions = '#There is no last touched parameter'
      end
        
    end
    
    ret_rb_slider = gfx.showmenu(slider_actions)  
    
    -- get last touched
      if ret_rb_slider == 1 and state == 0 
        or ret_rb_slider == 2 and state == 1  then 
  
        track_guid, FX_guid, paramid, fxname, param_name, gfx_name = ENGINE_Get_last_touched_value()
        if gfx_name ~= nil then
          if data.map[map] == nil then data.map[map] = {} end
          if data.map[map][slider] == nil then data.map[map][slider] = {} end
                    
          data.map[map][slider]['track_guid'] = track_guid
          data.map[map][slider]['fx_guid'] = FX_guid
          data.map[map][slider]['paramnumber'] = paramid
          data.map[map][slider]['gfx_name'] = gfx_name
          r,g,b = F_SetCol(color_t.green)
          data.map[map][slider].color = r..' '..g..' '..b..' ' 
           
          if data.use_learn == 1 then set_learn = true end
          ENGINE_return_data_to_projextstate2(false)     
        end   
      end
 
 -- ====== separator ===========  
   if state == 0 then
    -- rename
      if ret_rb_slider == 2 then
        _, newname = reaper.GetUserInputs('Rename slider '..slider, 
                    1, 'New name', data.map[map][slider]['gfx_name'])
          
        data.map[map][slider]['gfx_name'] = newname
        ENGINE_return_data_to_projextstate2(false) 
      end
      
    -- remove
      if ret_rb_slider == 3 then
        
        _,_,_,_, track, fx_guid_act_id = ENGINE_GetSetParamValue(map, slider, false)
        ENGINE_GetSetMIDIOSCLearn(track, fx_guid_act_id, 
          data.map[map][slider].paramnumber, -1)
        data.map[map][slider] = nil
        ENGINE_return_data_to_projextstate2(false)
        ENGINE_get_params_from_ext_state(false) 
      end
      
    -- change color
      if ret_rb_slider == 4 then
        _, colorOut = reaper.GR_SelectColor()
        r,g,b = reaper.ColorFromNative(colorOut)
        data.map[map][slider].color = (r/255)..' '..(g/255)..' '..(b/255)
        ENGINE_return_data_to_projextstate2(false)
        ENGINE_get_params_from_ext_state(false)
        update_gfx = true
      end      
 -- ====== separator =========== 
        
    -- modulation
      if ret_rb_slider == 5 then -- parameter modulation 
        val = ENGINE_GetSetParamValue(map, slider, false)
        ENGINE_GetSetParamValue(map, slider, true,val-0.1) 
        ENGINE_GetSetParamValue(map, slider, true,val)   
        reaper.Main_OnCommand(41143,0)
      end   
      
    -- float fx 
      if ret_rb_slider == 6 then -- float FX
        _,_,_,_, track, fx_guid_act_id = ENGINE_GetSetParamValue(map, slider, false)
        reaper.TrackFX_SetOpen(track, fx_guid_act_id, true)
      end
      
 -- ====== separator ===========  
      
    -- routing
      if ret_rb_slider >= 7 and ret_rb_slider <= 9 then  -- clear wires from slider
        if data.routing[data.current_routing] ~= nil then
          remove_t = {}
          for i = 1, #data.routing[data.current_routing] do   
                   
            if ret_rb_slider == 7 then
              if data.routing[data.current_routing][i].str:
                  match('[%d]+ [%d]+ '..map..' '..slider) ~= nil then            
                table.insert(remove_t, i) 
              end
            end

            if ret_rb_slider == 8 then
              if data.routing[data.current_routing][i].str:
                match(map..' '..slider..' [%d]+ [%d]+') ~= nil then            
                table.insert(remove_t, i) 
              end
            end         
            
            if ret_rb_slider == 9 then 
              if data.routing[data.current_routing][i].str:
                  match(map..' '..slider..' [%d]+ [%d]+') ~= nil or 
                data.routing[data.current_routing][i].str:
                  match('[%d]+ [%d]+ '..map..' '..slider) ~= nil
               then            
                table.insert(remove_t, i) 
              end
            end
                        
          end
          
          if remove_t ~= nil and #remove_t > 0 then
            i2= 0
            for i = 1, #remove_t do
              table.remove(data.routing[data.current_routing], remove_t[i]-i2)
              i2 = i2 + 1
            end
          end
          
          ENGINE_return_data_to_projextstate2(false)
        end
      end      
 -- ====== separator =========== 
 
      if ret_rb_slider >= rout_actions_count and 
        ret_rb_slider <= rout_actions_count + #menu_table then
          rout_id = menu_table[ret_rb_slider-rout_actions_count+1][1]
          --msg(data.routing[data.current_routing][rout_id].str  )
          last_routing_config_map = map
          last_routing_config_sl = slider
          data.current_window = 4
          update_gfx = true
      end

    --[[ midi osc learn
      if ret_rb_slider == 6 then -- parameter modulation 
        val = ENGINE_GetSetParamValue(map, slider, false)
        ENGINE_GetSetParamValue(map, slider, true,val-0.1) 
        ENGINE_GetSetParamValue(map, slider, true,val)   
        reaper.Main_OnCommand(41144,0)
      end  ]]
    end
  end      
  
  -----------------------------------------------------------------------  
  function F_GetSet_curve(in_str) local exists, t5, curve_table
    if in_str == nil then in_str = '' end
    curve_table= {}
    for num in in_str:gmatch('[%d%p]+ [%d%p]+') do 
      num1 = tonumber(num:match('[%d%p]+ '))
      num2 = tonumber(num:match(' [%d%p]+'))
      table.insert(curve_table, {num1,num2}) 
    end
    
    resolutionx = 25
    resolutiony = 50
        
    local loc_x,int, fract, x
    loc_x = (mouse.mx - graph_rect[1])/graph_rect[3] * resolutionx
    int, fract = math.modf(loc_x)
    if fract < 0.5 then loc_x = math.floor(loc_x) else loc_x = math.ceil(loc_x) end
    x = loc_x/resolutionx
    
    local loc_y,int, fract, y
    loc_y = (mouse.my - graph_rect[2])/graph_rect[4] * resolutiony
    int, fract = math.modf(loc_y)
    if fract < 0.5 then loc_y = math.floor(loc_y) else loc_y = math.ceil(loc_y) end
    y = 1-loc_y/resolutiony
    
    
    
    for i = 1, #curve_table do
      if curve_table[i][1] == x then
        exists = i
        curve_table[i] = {x,y} 
      end
    end
    
    if exists == nil then 
      if x ==1 then x = 1.0 end
      table.insert(curve_table, {x,y})
    end
    
    table.sort(curve_table, function(a,b) return a[1]<b[1] end)
    
    curve_table_s = ''
    for i = 1 , #curve_table do
      curve_table_s = curve_table_s..curve_table[i][1]..' '..curve_table[i][2]..' '
    end
    
    return curve_table_s
  end
  
  -----------------------------------------------------------------------
  function GUI_DRAW2()
    gfx.dest = -1
    
    -- common buffer
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      gfx.blit(20, 1, 0, 
        0,0,main_xywh[3],main_xywh[4],
        0,0,main_xywh[3],main_xywh[4], 0,0)
        
    -- tooltip
      if tooltip ~= nil then
        local x,y,w,h
        w = main_xywh[3]/1.5
        h = 100
        x, y = mouse.mx, mouse.my
        x = x + 10
        y = y + 10
        if y + h > main_xywh[4] then 
          y = y- h-10 
          if y > main_xywh[4] - h then y = main_xywh[4] - h end      
        end
        if x + w > main_xywh[3] then 
          x = x- w - 10 
          if x > main_xywh[3] - w then x = main_xywh[3] - w end      
        end
        if y < 0 then y = 0 end
        if x < 0 then x = 0 end
        
        gfx.x,gfx.y = x+10,y+10
        
        -- frame
          gfx.a = 0.7
          gfx.r, gfx.g, gfx.b = 0.05,0,0    
          gfx.rect(x,y,w,h,true)
          gfx.r, gfx.g, gfx.b = 1,1,1
          gfx.setfont(1, data.fontname, fontsize)
          gfx.drawstr(tooltip)
          
      end
      
      if data.dev_mode ~= nil and data.dev_mode == 1 then
        gfx.x, gfx.y = 10,10
        gfx.r, gfx.g, gfx.b, gfx.a = 1,1,1,0.7
        gfx.rect(10,10,200,100,true)
        gfx.r, gfx.g, gfx.b, gfx.a = 0,0,0,0.8
        if extst_len == nil then extst_len = 0 end
        gfx.drawstr('DevMode:\n'..
          'defer_time '..timediff..'\n'..
          'extstate_len '..extst_len)
        
      end
      --x,y,w,h = F_extract_table(bigknob1_xywh)
      --gfx.rect(x,y,w,h)
      
    gfx.update()
  end
  
  
  
  -----------------------------------------------------------------------  
  function ENGINE_get_params_from_ext_state(from_ext_file)  local temp_map_s, temp_learn_s, temp_learn_s2,flags
  
     if from_ext_file == nil or not from_ext_file then
       retval, extstate_s = reaper.GetProjExtState(0, 'MPL_PANEL_MAPPINGS', 'MPL_PM_DATA')
       fdebug('\nGET\n'..extstate_s)
      else -- if from external file
       file = io.open(config_path, 'r')
       if file ~= nil then
          retval = 1
          extstate_s = file:read('*all')
          file:close()
        else
         return nil
       end
     end -- if from projextstate
       if retval ~= nil and extstate_s ~= '' then
       
          data.tablet_optimised = tonumber(F_get_beetween(extstate_s,"tablet_optimised",'\n'))
          data.project_name = F_get_beetween(extstate_s,"project_name",'\n')
          if data.project_name == '' then data.project_name = '(Untitled)' end
          data.current_map = tonumber(F_get_beetween(extstate_s,"current_map",'\n'))
          data.slider_mode = tonumber(F_get_beetween(extstate_s,"slider_mode",'\n'))
          data.fontname = F_get_beetween(extstate_s,"fontname",'\n')
          data.fontsize = tonumber(F_get_beetween(extstate_s,"fontsize",'\n'))
          data.slider_fontsize = tonumber(F_get_beetween(extstate_s,"slider_fontsize",'\n'))
          data.current_window = tonumber(F_get_beetween(extstate_s,"current_window",'\n'))
          data.run_docked = tonumber(F_get_beetween(extstate_s,"run_docked",'\n'))
          data.wheel_coeff = tonumber(F_get_beetween(extstate_s,"wheel_coeff",'\n'))
          data.ctrl_coeff = tonumber(F_get_beetween(extstate_s,"ctrl_coeff",'\n'))
          data.routing_count = tonumber(F_get_beetween(extstate_s,"routing_count",'\n'))
          data.current_routing = tonumber(F_get_beetween(extstate_s,"current_routing",'\n'))
          data.use_learn = tonumber(F_get_beetween(extstate_s,"use_learn",'\n'))
          data.current_fixedlearn = tonumber(F_get_beetween(extstate_s,"current_fixedlearn",'\n'))
          data.use_ext_actions = tonumber(F_get_beetween(extstate_s,"use_ext_actions",'\n'))
          main_xywh[3] = tonumber(F_get_beetween(extstate_s,"window_w",'\n'))
          main_xywh[4] = tonumber(F_get_beetween(extstate_s,"window_h",'\n'))
          data.dev_mode = tonumber(F_get_beetween(extstate_s,"dev_mode",'\n'))
          data.expert_mode = tonumber(F_get_beetween(extstate_s,"expert_mode",'\n'))
          
          
          if data.current_window ==4 then data.current_window = 2 end  
          
          -- extract maps --
          data.map = {}
          for i = 1, data.map_count do 
            temp_map_s = F_get_beetween(extstate_s,"<MAP"..i..' ','ENDMAP>')
            if temp_map_s ~= nil then
              data.map[i] = {}         
              data.map[i].map_name = F_get_beetween(temp_map_s,"map_name",'\n',true)
              data.map[i].track_link = F_get_beetween(temp_map_s,"track_link",'\n',true)
              data.map[i].fx_link = F_get_beetween(temp_map_s,"fx_link",'\n',true)
              data.map[i].bypass_learn = tonumber(F_get_beetween(temp_map_s,"bypass_learn",'\n',true))
              if data.map[i].bypass_learn == nil then data.map[i].bypass_learn = 0 end
              
              for k = 1, data.slider_count do
                if  temp_map_s:find("<SL"..k..' ') ~= nil then
                  data.map[i][k] = {}
                  local temp_sl_s = F_get_beetween(temp_map_s,"<SL"..k..' ','ENDSL>')
                  local temp_sl_s_t = {}
                  for line in temp_sl_s:gmatch("[^\r\n]+") do  table.insert(temp_sl_s_t, line) end
                  local ind_len = 3
                  data.map[i][k]['gfx_name'] = temp_sl_s_t[1]:sub(ind_len)
                  data.map[i][k]['track_guid'] = temp_sl_s_t[2]:sub(ind_len)
                  data.map[i][k]['fx_guid'] = temp_sl_s_t[3]:sub(ind_len)
                  data.map[i][k]['paramnumber'] = temp_sl_s_t[4]:sub(ind_len)
                  data.map[i][k]['color'] = temp_sl_s_t[5]:sub(ind_len)
                end -- if slider exists
              end -- slider loop
            end -- if map exists
          end-- maps loop
          
          
          -- routing
          data.routing = {}
          for m = 1, data.routing_count do
            local cur_config = F_get_beetween(extstate_s, '<R_CONF_'..m, 'ENDR_CONF>', true)
            if cur_config ~= nil then
              
              data.routing[m] = {}
              for line in cur_config:gmatch("[^\r\n]+") do
                if line ~= nil and line ~= '' then
                  -- extract map slider
                    t = {}
                    for num in line:gmatch("[%d]+") do table.insert(t, tonumber(num)) end
                    t1 = {}
                    --msg(line)
                    for str in line:gmatch("%[(.-)%]") do table.insert(t1, str) end
                    m1 = t[1]
                    sl1 = t[2]
                    m2 = t[3]
                    sl2 = t[4]
                    --msg('test'..table.concat(t, ','))
                    if data.map[m1] ~= nil and data.map[m1][sl1] ~= nil and
                       data.map[m2] ~= nil and data.map[m2][sl2] ~= nil then
                       
                       rout_ids = m1..' '..sl1..' '..m2..' '..sl2
                       
                       if t1[1] == nil or t1[2] == nil then t1 = {'x','0 0'} end
                       
                       table.insert(data.routing[m], 
                          {['str'] = rout_ids, 
                           ['form'] = t1[1],--:sub(2,-2)
                           ['curve'] = t1[2]}) 
                    end
                end
              end
            end
          end
          
          ENGINE_dump_functions_to_routing_table()
          
          
          function ENGINE_get_learn_from_extstate(extstate_s1)
            -- learn          
              temp_learn_s = F_get_beetween(extstate_s1,"LEARNSTR",'ENDLEARNSTR>',true) 
              if temp_learn_s ~= nil then
                for line in temp_learn_s:gmatch("[^\n]+") do
                  local t = {}
                  for word in line:gmatch('[^%s]+') do table.insert(t, word) end
                  sl_id = tonumber(t[1])
                  midinum = tonumber(t[2])
                  flags = tonumber(t[3])
                  osc = t[4]                
                  if data.learn == nil then data.learn = {} end                
                  if data.learn[sl_id] == nil then data.learn[sl_id] = {} end                
                  if midinum == 0 and flags == 0 then 
                    data.learn[sl_id].midich = nil
                    data.learn[sl_id].midicc = nil
                   else
                    data.learn[sl_id].midich = (midinum & 0x0F) + 1
                    data.learn[sl_id].midicc = midinum >> 8
                    data.learn[sl_id].flags = flags
                  end                
                  if osc ~= nil then data.learn[sl_id].osc = osc end                
                  F_form_learnstr(sl_id)                
                end              
              end
          end
          
          if data.use_learn == 1 then 
            extstate_glob = reaper.GetExtState('MPL_PANEL_MAPPINGS', 'FIXEDLEARN')
            --msg(extstate_glob)
            if extstate_glob ~= nil and extstate_glob ~= '' then
              ENGINE_get_learn_from_extstate(extstate_glob) 
            end
          end             
          if data.use_learn == 2 then ENGINE_get_learn_from_extstate(extstate_s) end
          
            
            
       end -- if retval ~= nil
       return retval
      
  end
  
-----------------------------------------------------------------------    
  function ENGINE_dump_functions_to_routing_table()
    --msg('ENGINE_dump_functions_to_routing_table')
    if data.routing ~= nil then
      for i = 1 , data.routing_count do
        if data.routing[i] ~= nil then
          for k = 1, #data.routing[i] do
            if data.routing[i][k] ~= nil then
              data.routing[i][k].func = nil        
              codestring = data.routing[i][k].form
              if data.routing[i][k].form ~= 'vca()' then
                if data.routing[i][k].curve == nil then data.routing[i][k].curve = '' end
                curve = data.routing[i][k].curve 
                codestring = codestring:gsub('curve','"'..curve..'"')
                
                if data.expert_mode == nil or data.expert_mode == 0 then
                  -- check for other variables
                    local t = {}
                    for let in codestring:gmatch('[%a]+') do
                      if let:len() == 1 and let ~= 'x' then table.insert(t, let) end
                    end
                    if #t > 0 then 
                      codestring = 'x' 
                      clear = 1 
                    end
                end
                
                if data.expert_mode == nil or data.expert_mode == 0 then
                  
                    data.routing[i][k].func = load
                      (' local x = ... val = ... y='..codestring..' return y')
                    else
                    data.routing[i][k].func = load
                      ('local x = ... m = ... sl = ... val = ...  '..codestring..' return y')
                  
                end
               
                
                -- clear if bad
                  if clear == 1 then data.routing[i][k].form = 'x' end
              end
                
            end
          end
        end
      end
    end
  end
  
-----------------------------------------------------------------------     
  function ENGINE_apply_routing(map,sl,dy)
    if dy == nil then dy = 0 end
    if map ~= nil and sl ~= nil then
      if data.routing[data.current_routing] ~= nil then
        for i = 1, #data.routing[data.current_routing] do
          t2 = {}
          for num in data.routing[data.current_routing][i].str:gmatch('[^%s]+') do
            table.insert(t2, num)
          end
          
          if tonumber(t2[1]) == map and tonumber(t2[2]) == sl then
            x = ENGINE_GetSetParamValue(tonumber(t2[1]),tonumber(t2[2]), false)
            val = ENGINE_GetSetParamValue(tonumber(t2[3]),tonumber(t2[4]), false)
            local func = data.routing[data.current_routing][i].func            
            if data.routing[data.current_routing][i].form:find('vca()') ~= nil then
              local m = tonumber(t2[3])
              local sl = tonumber(t2[4])
              ENGINE_GetSetParamValue(m, sl, true, val+dy)
             else
              if func ~= nil then
                local m = tonumber(t2[3])
                local sl = tonumber(t2[4])
                --msg(func(x, m, sl))
                ENGINE_GetSetParamValue(m,sl, true, F_limit(func(x, m, sl), 0.0000001,1))
              end
            end
          end
        end
      end
    end
  end

----------------------------------------------------------------------- 
  function ENGINE_form_learnstr() local learn_out_temp     
    -- Learn
    if data.learn ~= nil then
      learn_out_temp = '[learn]\n<LEARNSTR\n'
        for i = 1, data.slider_count do
          F_form_learnstr(i)
          if data.learn[i] ~= nil and data.learn[i].outstr ~= nil then
            learn_out_temp = learn_out_temp..i..indent..data.learn[i].outstr..'\n'
          end
        end
      learn_out_temp = learn_out_temp..'ENDLEARNSTR>\n'
     else
      learn_out_temp = ''
    end
    return learn_out_temp
  end
    
-----------------------------------------------------------------------  
  function ENGINE_return_data_to_projextstate2(to_ext_file, set_ext_learn)
    update_gfx_minor = true
    update_gfx = true
    local routing_out_temp,learn_out_temp,learn_out_temp1
    indent =  ' '
    indent2 = '  '
    indent3 = '   '
    indent4 = '    '
    
    if data.project_name == nil then data.project_name = 'Untitled' end
    
    -- from 1.04
      if data.dev_mode == nil then data.dev_mode = 0 end
      if data.expert_mode == nil then data.expert_mode = 0 end
      
    -- MAIN SECTION
    string_ret = '[Global_variables]'..'\n'..
                 'tablet_optimised '..data.tablet_optimised..'\n'..
                 'project_name '..data.project_name..'\n'..
                 'current_map '..data.current_map..'\n'..
                 'slider_mode '..data.slider_mode..'\n'..
                 'slider_count '..data.slider_count..'\n'..
                 'map_count '..data.map_count..'\n'..
                 'fontsize '..data.fontsize..'\n'..
                 'slider_fontsize '..data.slider_fontsize..'\n'..
                 'fontname '..data.fontname..'\n'..
                 'current_window '..data.current_window..'\n'..
                 'run_docked '..data.run_docked..'\n'..
                 'wheel_coeff '..data.wheel_coeff..'\n'..
                 'ctrl_coeff '..data.ctrl_coeff..'\n'..
                 'routing_count '..data.routing_count..'\n'..
                 'current_routing '..data.current_routing..'\n'..
                 'use_learn '..data.use_learn..'\n'..
                 'current_fixedlearn '..data.current_fixedlearn..'\n'..
                 'use_ext_actions '..data.use_ext_actions..'\n'..
                 'window_w '..gfx.w..'\n'..
                 'window_h '..gfx.h..'\n'..
                 'dev_mode '..data.dev_mode..'\n'..
                 'expert_mode '..data.expert_mode..'\n'
                 
    if data.map ~= nil and #data.map > 0 then string_ret = string_ret..'[maps_configuration] \n' end
                 
    -- MAPS/SLIDERS             
    for i = 1, data.map_count do
      if data.map ~= nil and data.map[i] ~= nil then
      
        string_ret = string_ret..'<MAP'..i..' '..'\n'
        if data.map[i]['map_name'] ~= nil then string_ret = string_ret..indent..'map_name '..data.map[i].map_name..'\n' end
        if data.map[i]['track_link'] ~= nil then string_ret = string_ret..indent..'track_link '..data.map[i].track_link..'\n' end
        if data.map[i]['fx_link'] ~= nil then string_ret = string_ret..indent..'fx_link '..data.map[i].fx_link..'\n' end
        if data.map[i]['bypass_learn'] ~= nil then 
          string_ret = string_ret..indent..'bypass_learn '..data.map[i].bypass_learn..'\n' 
         else
          string_ret = string_ret..indent..'bypass_learn 0\n' 
        end
        
       
          for k = 1,data.slider_count do
            if data.map[i][k] ~= nil then
              string_ret = string_ret..indent..'<SL'..k..' '..'\n'
              string_ret = string_ret..indent2..data.map[i][k]['gfx_name']..'\n'
              string_ret = string_ret..indent2..data.map[i][k]['track_guid']..'\n'
              string_ret = string_ret..indent2..data.map[i][k]['fx_guid']..'\n'
              string_ret = string_ret..indent2..data.map[i][k]['paramnumber']..'\n'
              if data.map[i][k]['color'] ~= nil then 
                string_ret = string_ret..indent2..data.map[i][k]['color']..'\n' end
              string_ret = string_ret..indent..'ENDSL>'..'\n'
            end
          end
          
        string_ret = string_ret..'ENDMAP>'..'\n'    
      end  
    end
    
    
    -- ROUTING
      if data.routing ~= nil then
        routing_out_temp = '[routing]\n'
        for m = 1, data.routing_count do
          if data.routing[m] ~= nil then
            routing_out_temp = routing_out_temp..'<R_CONF_'..m..'\n'
            if #data.routing[m] >= 1 then
              for n = 1, #data.routing[m] do
                if data.routing[m][n] ~= nil then
                  routing_out_temp = routing_out_temp..indent2..
                    data.routing[m][n].str..' '..
                    '['..data.routing[m][n].form..'] '..
                    '['..data.routing[m][n].curve..']'..'\n'
                end
              end
            end
            routing_out_temp = routing_out_temp:gsub('[%[]+','['):gsub('[%]]+',']')
            routing_out_temp = routing_out_temp..'ENDR_CONF>\n'
          end
        end
       else
        routing_out_temp = ''
      end
      
    string_ret = string_ret..routing_out_temp  
                   
    learn_out_temp = ENGINE_form_learnstr()
    
    if data.use_learn == 1 and data.last_use_learn ~=0 then -- use global learn
      -- store to ext state
        reaper.SetExtState('MPL_PANEL_MAPPINGS', 'FIXEDLEARN', learn_out_temp, true)
    end
    
    if data.use_learn == 2 then -- use global learn
      string_ret = string_ret..learn_out_temp
    end    
    
    
                
    -- OUT
    if to_ext_file == nil or to_ext_file == false then
      reaper.SetProjExtState(0, 'MPL_PANEL_MAPPINGS', 'MPL_PM_DATA',string_ret)
      extst_len = string_ret:len()
      fdebug('\n'..'RETURN'..'\n'..string_ret)
     else      
      file = io.open(config_path,'w')
      file:write(string_ret)
      file:close()
    end
    
    update_gfx = true
    reaper.MarkProjectDirty(0)
  end
  
-----------------------------------------------------------------------    
  function ENGINE_set_learn()
    if data.use_learn == 1 then
      if data.map[data.current_map] ~= nil and data.map[data.current_map].bypass_learn ~= 1 then
        fdebug('ENGINE_set_learn')
        for i = 1, data.map_count do
          for k = 1, data.slider_count do
            out_value, _, _, _, track, fx_id = ENGINE_GetSetParamValue(i,k, false)
            if out_value >= 0 and out_value <= 1 then
              if i ~= data.current_map then
              -- remove
                ENGINE_GetSetMIDIOSCLearn(track, fx_id, data.map[i][k].paramnumber, -1)
               else
              -- set from table
                if data.learn ~= nil and data.learn[k] ~= nil then
                  ENGINE_GetSetMIDIOSCLearn(track, fx_id, data.map[i][k].paramnumber, 1, data.learn[k].outstr)
                end
              end
            end
          end
        end
      end
    end
  end
  
-----------------------------------------------------------------------    
  function ENGINE_Get_project_name()
    local project_name, project_name0,st1,st2,st
    _, project_name = reaper.EnumProjects(-1, '')
       project_name0 = project_name
       repeat
         st1 = string.find(project_name,'\\') if st1 == nil then st1 = 0 end
         st2 = string.find(project_name,'/') if st2 == nil then st2 = 0 end
         st = math.max(st1,st2)    
         project_name = string.sub(project_name, st+1)
       until st == 0
       project_name = string.sub(project_name, 0, -5)
    return project_name
  end 
  
----------------------------------------------------------------------- 
  function MOUSE_match(b)
    if mouse.mx > b[1] and mouse.mx < b[1]+b[3]
      and mouse.my > b[2] and mouse.my < b[2]+b[4] then
     return true 
    end 
  end 

-----------------------------------------------------------------------
  function MOUSE_get_map_sl()
    local slider = 
      F_limit(math.floor(((mouse.my - control_area_xywh[2]) / control_area_xywh[4])*data.slider_count)+1, 1, 
        data.slider_count,true)  
    local map = 
      F_limit(math.floor(((mouse.mx - control_area_xywh[1]) / control_area_xywh[3])*data.map_count)+1, 1, 
        data.map_count,true)
    return slider, map
  end
   
-----------------------------------------------------------------------    
  function MOUSE_get2() local exists,form,map_temp
    -- collect mouse info
      mouse.mx = gfx.mouse_x
      mouse.my = gfx.mouse_y
      mouse.LMB_state = gfx.mouse_cap&1 == 1 
      mouse.RMB_state = gfx.mouse_cap&2 == 2 
      mouse.MMB_state = gfx.mouse_cap&64 == 64
      mouse.LMB_state_doubleclick = false
      mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
      mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
      mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
      mouse.wheel = gfx.mouse_wheel
      
            
      if mouse.LMB_state and not mouse.last_LMB_state then
        mouse.LMB_state_stamp = time
        if mouse.last_LMB_state_stamp == nil then 
          mouse.last_LMB_state_stamp = mouse.LMB_state_stamp - 10 end
        if mouse.LMB_state_stamp - mouse.last_LMB_state_stamp < d_click_time then
          mouse.LMB_state_doubleclick = true
        end
        if mouse.last_LMB_state_stamp ~= nil then mouse.last_LMB_state_stamp = mouse.LMB_state_stamp end        
        mouse.last_mx = mouse.mx
        mouse.last_my = mouse.my
        update_gfx = true
        update_gfx_minor = true
      end
      
      
      if mouse.last_mx ~= nil and mouse.last_my ~= nil then
        mouse.dx = mouse.mx - mouse.last_mx
        mouse.dy = mouse.my - mouse.last_my
       else
        mouse.dx, mouse.dy = 0,0
      end
      
      -- get whell state
        if mouse.last_wheel ~= nil then 
          if mouse.wheel == mouse.last_wheel then
            mouse.dwheel = 0
           else
            mouse.dwheel = mouse.wheel - mouse.last_wheel
          end
        end
      
      -- on release
        if not mouse.last_LMB_state then  
          mouse.last_object = nil 
          mouse.last_touched_slider = nil
          mouse.last_touched_map = nil
          mouse.last_touched_value = nil
        end
      
    -----------------------
    -----------------------  
      
    -- main window
      if data.current_window == 0 then
        -- project left button
          if MOUSE_match(b_close_xywh) and mouse.LMB_state and not mouse.last_LMB_state 
            then 
            GUI_main_menu() 
            mouse.mx,mouse.my = -100,-100
          end
          
        -- routing shortcut
          if MOUSE_match(b_new_shcut_rout) and mouse.LMB_state and not mouse.last_LMB_state 
            then 
            data.current_window = 2
            ENGINE_return_data_to_projextstate2(false)
          end
          
        -- fixedlearn shortcut
          if MOUSE_match(b_new_shcut_flearn) and mouse.LMB_state and not mouse.last_LMB_state then
            if data.use_learn == 1 or data.use_learn == 2    then 
              data.current_window = 3
              ENGINE_return_data_to_projextstate2(false)
            end
          end          
          
        -- lamp tooltip
          if MOUSE_match(lamp_xywh) then 
            tooltip = F_wrap_text('Red = need to save project with script data. Green = script data saved.', main_xywh[3]/1.5 )
           else 
            tooltip = nil 
          end
          
        -- map menu
          if MOUSE_match(b_2_xywh) and mouse.RMB_state or 
            (data.tablet_optimised == 1 and MOUSE_match(b_2_1_fix_xywh) and mouse.LMB_state and not mouse.last_LMB_state) then 
            GUI_map_menu() 
            mouse.mx,mouse.my = -100,-100
          end 
          
        -- map slider
          if MOUSE_match(b_2_xywh) and mouse.LMB_state and not mouse.last_LMB_state then mouse.last_object = 'map_sl' end
          if mouse.LMB_state and mouse.last_object == 'map_sl' then 
            data.current_map_temp = F_limit( math.ceil(data.map_count * (mouse.mx- b_2_xywh[1])/b_2_xywh[3]) ,  1, data.map_count, true) 
            if data.current_map_temp ~= nil and data.current_map_temp ~= data.current_map then 
              data.current_map = data.current_map_temp 
              data.current_map_temp = nil 
              ENGINE_return_data_to_projextstate2(false)
            end
          end
      end      -- end main     
          
      
    -----------------------
    -----------------------  
               
        if data.current_window ~= 4 then   
        -- sliders/knobs
          -- get
            
              if MOUSE_match(control_area_xywh) and mouse.LMB_state and not mouse.last_LMB_state or 
                MOUSE_match(control_area_xywh) and mouse.RMB_state and not mouse.last_RMB_state or 
                MOUSE_match(control_area_xywh) and mouse.dwheel ~= 0  then
                mouse.last_touched_slider, map_temp = MOUSE_get_map_sl()
                if data.current_window == 0 then mouse.last_touched_map = data.current_map end
                if data.current_window == 2 then mouse.last_touched_map = map_temp         end 
              end
          
                         
          -- left hold abs
            if data.current_window == 0  and data.slider_mode == 0 then
              if mouse.last_touched_slider ~= nil and mouse.LMB_state then 
                if data.current_window == 0 then 
                  local ret = ENGINE_GetSetParamValue(data.current_map, mouse.last_touched_slider, true, 
                    (mouse.mx - control_area_xywh[1])/control_area_xywh[3] ,0.0000001,1) end
                data.bottom_info_slider = mouse.last_touched_slider
                data.bottom_info_map = mouse.last_touched_map
              end              
            end
                                           
          -- if left hold rel sliders
            if data.current_window == 0 and data.slider_mode == 1 
              then
              if mouse.last_touched_slider ~= nil and 
                mouse.LMB_state and 
                not mouse.last_LMB_state then
                mouse.last_touched_value = ENGINE_GetSetParamValue(data.current_map, mouse.last_touched_slider, false)
                data.bottom_info_slider = mouse.last_touched_slider
                data.bottom_info_map = mouse.last_touched_map
              end
              if mouse.last_touched_slider ~= nil and 
                mouse.LMB_state then               
                if mouse.Ctrl_state then
                    ENGINE_GetSetParamValue(data.current_map, mouse.last_touched_slider, true, mouse.last_touched_value + mouse.dx/main_xywh[3]*data.ctrl_coeff)
                   else 
                    ENGINE_GetSetParamValue(data.current_map, mouse.last_touched_slider, true, mouse.last_touched_value + mouse.dx/main_xywh[3])
                end                    
              end
            end    
                        
          --   if left hold rel knobs     
            if data.current_window == 2 then
              if mouse.last_touched_slider ~= nil and 
                mouse.LMB_state and 
                not mouse.last_LMB_state then
                mouse.last_touched_value = ENGINE_GetSetParamValue(mouse.last_touched_map, mouse.last_touched_slider, false)
                data.bottom_info_slider = mouse.last_touched_slider
                data.bottom_info_map = mouse.last_touched_map
              end
              if mouse.last_touched_slider ~= nil and mouse.last_touched_map ~= nil and
                mouse.LMB_state then  
                if not mouse.Ctrl_state and not mouse.Ctrl_state2 then
                    ENGINE_GetSetParamValue(mouse.last_touched_map, mouse.last_touched_slider, true, 
                      F_limit((mouse.last_touched_value - mouse.dy/main_xywh[4]*knob_sens),0.0000001,1))
                end                     
              end
            end    
              
          -- left click tablet
            if data.current_window == 0 and data.tablet_optimised == 1 and
              mouse.LMB_state and not mouse.last_LMB_state then
              
              tablet_control_area_xywh = 
                {control_area_xywh[1]+control_area_xywh[3],
                  mouse.my -1,
                  obj_w2,
                  control_area_xywh[4] / data.slider_count}
              if MOUSE_match(tablet_control_area_xywh) then
                mouse.last_touched_map = data.current_map
                mouse.last_touched_slider = MOUSE_get_map_sl()
                GUI_slider_menu(mouse.last_touched_map, mouse.last_touched_slider)
                mouse.mx, mouse.my = -100,-100
              end
            end
              
          -- right click
            if mouse.last_touched_slider ~= nil and mouse.RMB_state and data.current_window ~= 3
             then 
              if data.current_window == 0 then
                mouse.last_touched_slider = MOUSE_get_map_sl()
                mouse.last_touched_map = data.current_map
              end 
              GUI_slider_menu(mouse.last_touched_map, mouse.last_touched_slider)
              data.bottom_info_slider = mouse.last_touched_slider
              data.bottom_info_map = mouse.last_touched_map
            end
            
          -- wheel
            if mouse.last_touched_slider ~= nil and mouse.dwheel ~= 0 then
              data.bottom_info_slider = mouse.last_touched_slider
              data.bottom_info_map = data.current_map
              local wheel_val = ENGINE_GetSetParamValue(mouse.last_touched_map, mouse.last_touched_slider, false)
              if mouse.dwheel ~= nil then
                ENGINE_GetSetParamValue(mouse.last_touched_map, mouse.last_touched_slider, true, wheel_val + mouse.dwheel * data.wheel_coeff)
              end
            end
          -- alt
            if mouse.last_touched_slider ~= nil and mouse.Alt_state then
              ENGINE_GetSetParamValue(data.current_map, mouse.last_touched_slider, true, 0.5)
            end 
      end -- if not routing setup 
      ------------------------------------------------
      if data.current_window == 4 then
             -- ROUT SETUP get                 
                 if mouse.LMB_state 
                  and not mouse.last_LMB_state then 
                   if MOUSE_match(bigknob1_xywh) then
                     mouse.last_touched_map = last_routing_config_map 
                     mouse.last_touched_slider = last_routing_config_sl
                     mouse.last_object = 'bigkn1'
                   end
                   if MOUSE_match(bigknob2_xywh) then
                     mouse.last_touched_map = last_routing_config_map2
                     mouse.last_touched_slider = last_routing_config_sl2
                     mouse.last_object = 'bigkn2'
                   end                
                  end
                  
              -- get last touched
                if mouse.last_touched_slider ~= nil 
                  and mouse.last_touched_map ~= nil 
                  and mouse.LMB_state 
                  and not mouse.last_LMB_state then
                   mouse.last_touched_value = ENGINE_GetSetParamValue(mouse.last_touched_map, mouse.last_touched_slider, false)
                 end
                 
          -- rel value
            if mouse.last_touched_value ~= nil then
              ENGINE_GetSetParamValue(mouse.last_touched_map, mouse.last_touched_slider, true, 
                mouse.last_touched_value - mouse.dy/100)
            end
      end      
      
          
    -----------------------
    -----------------------  
          
    -- about window
      if data.current_window == 1 then
        -- about close
          if MOUSE_match(b_close_xywh) and mouse.LMB_state and not mouse.last_LMB_state then
            data.current_window = 0
            update_gfx_minor = true
            update_gfx = true
            mouse.mx,mouse.my = -100,-100 
          end
          
        if MOUSE_match(main_xywh) then 
          local active_about_link0 = mouse.my - (mouse.my % gfx.texth )
          local active_about_link_Q = active_about_link0 / gfx.texth
          
          local function F_about_links(id, link)
            if active_about_link_Q == id then
              if mouse.LMB_state and not mouse.last_LMB_state then F_open_URL(link) end
            end
          end
          
          F_about_links(9, 'http://soundcloud.com/mp57')
          F_about_links(10, 'http://pdj.com/michaelpilyavskiy')
          F_about_links(11, 'http://github.com/MichaelPilyavskiy/ReaScripts')
          F_about_links(12, 'http://vk.com/michael_pilyavskiy')
          
          F_about_links(16, 'http://forum.cockos.com/showthread.php?t=170044')
          F_about_links(17, 'http://rmmedia.ru/threads/120507/')
          --F_about_links(18, 'wiki')
                    
          F_about_links(22, 'http://paypal.me/donate2mpl')
          
          if active_about_link_Q >=9 and active_about_link_Q <=12 or
            active_about_link_Q >= 16 and active_about_link_Q <= 17 or 
            active_about_link_Q == 22 then 
             active_about_link = active_about_link0
            else
             active_about_link = -100
          end
        end
        
      end -- end about get
      
    -----------------------
    -----------------------  
    -- routing window
      if data.current_window == 2 then
        -- gfx
          if MOUSE_match(control_area_xywh) then update_gfx_minor = true end
            
        -- get knob under cursor
          if MOUSE_match(control_area_xywh) and not mouse.LMB_state and not mouse.last_LMB_state 
            or MOUSE_match(control_area_xywh) and mouse.Ctrl_LMB_state 
            or MOUSE_match(control_area_xywh) and mouse.Ctrl_state then
            mouse.last_touched_slider, mouse.last_touched_map = MOUSE_get_map_sl()
            data.bottom_info_slider = mouse.last_touched_slider
            data.bottom_info_map = mouse.last_touched_map
          end

        -- doubleclick open first wire
          if MOUSE_match(control_area_xywh) and mouse.LMB_state_doubleclick then
            _, inf_t = F_build_slider_routing_menu(mouse.last_touched_map, mouse.last_touched_slider)
            if inf_t ~= nil and inf_t[1]~= nil and inf_t[1][1] ~= nil then
              rout_id = inf_t[1][1]
              last_routing_config_map = mouse.last_touched_map
              last_routing_config_sl = mouse.last_touched_slider
              data.current_window = 4
              update_gfx = true
              mouse.last_LMB_state_stamp = mouse.LMB_state_stamp
              return
            end
          end        
        
        -- config left slider
          if MOUSE_match(b_2_xywh) and mouse.LMB_state and not mouse.last_LMB_state then mouse.last_object = 'config_sl' end
          if mouse.LMB_state and mouse.last_object == 'config_sl' then 
            data.current_routing_temp = F_limit( math.ceil(data.routing_count * (mouse.mx- b_2_xywh[1])/b_2_xywh[3]) ,  1, data.routing_count, true) 
            if data.current_routing_temp ~= nil and data.current_routing_temp ~= data.current_routing then 
              data.current_routing = data.current_routing_temp 
              ENGINE_return_data_to_projextstate2(false) 
              data.current_routing_temp = nil end
          end       
          
        -- config right button
          if MOUSE_match(b_2_xywh) and mouse.RMB_state 
            or data.tablet_optimised == 1 and MOUSE_match(b_2_1_xywh) and mouse.LMB_state and not mouse.last_LMB_state then 
            GUI_routing_menu() 
            mouse.mx,mouse.my = -100,-100
          end  
                          
        -- routing close
          if MOUSE_match(b_close_xywh) and mouse.LMB_state and not mouse.last_LMB_state then
            data.current_window = 0
            ENGINE_return_data_to_projextstate2(false) 
            mouse.mx,mouse.my = -100,-100 
          end 
          
        -- get
          if mouse.Ctrl_LMB_state and not mouse.last_Ctrl_LMB_state and run_routing_process == nil then
            r_map_out = mouse.last_touched_map
            r_slider_out = mouse.last_touched_slider
            run_routing_process = 1
          end
        
          -- release
            if mouse.last_Ctrl_LMB_state and not mouse.Ctrl_LMB_state then
              r_map_in = mouse.last_touched_map
              r_slider_in = mouse.last_touched_slider  
            
              if data.map[r_map_in] ~= nil and
                data.map[r_map_out] ~= nil and
                data.map[r_map_in][r_slider_in] ~= nil and
                data.map[r_map_out][r_slider_out] ~= nil and
                data.map[r_map_in][r_slider_in].value ~= nil and
                data.map[r_map_out][r_slider_out].value ~= nil and 
                data.map[r_map_in][r_slider_in].value >= 0 and
                data.map[r_map_out][r_slider_out].value >= 0 then --and
                --not(r_map_in == r_map_out and r_slider_in == r_slider_out) then
                
                if r_map_out == r_map_in and r_slider_in == r_slider_out then return end
                --[[msg(r_map_in..'r_map_in')
                msg(r_map_out..'r_map_out')
                msg(r_slider_in..'r_slider_in')
                msg(r_slider_out..'r_slider_out')]]
                
                -- if current routing not exists
                  if data.routing[data.current_routing] == nil then data.routing[data.current_routing] ={} end
                
                -- check for already existing - 2 directions
                  for i = 1, #data.routing[data.current_routing] do
                    if data.routing[data.current_routing][i].str:
                      find(r_map_out..' '..r_slider_out..' '..r_map_in..' '..r_slider_in) 
                     --or data.routing[data.current_routing][i].str:
                     -- find(r_map_in..' '..r_slider_in..' '..r_map_out..' '..r_slider_out..' ') 
                     then
                      exists = i
                      break
                    end
                  end
                
                -- if not exists -> create
                  if exists == nil then  
                    if data.expert_mode == nil or data.expert_mode == 0 then                 
                      table.insert(data.routing[data.current_routing], 
                        {['str'] = r_map_out..' '..r_slider_out..' '..r_map_in..' '..r_slider_in,
                         ['form'] = 'x',
                         ['curve'] = '0 0'})
                     else
                      table.insert(data.routing[data.current_routing], 
                        {['str'] = r_map_out..' '..r_slider_out..' '..r_map_in..' '..r_slider_in,
                         ['form'] = 'y = x',
                         ['curve'] = '0 0'})
                    end
                                           
                    ENGINE_return_data_to_projextstate2(false)
                    ENGINE_dump_functions_to_routing_table()
                  end
                  
                -- if exists -> delete
                  if exists ~= nil then
                    if data.routing[data.current_routing] ~= nil then
                      --msg(exists..'\n')
                      table.remove(data.routing[data.current_routing], exists)
                      ENGINE_return_data_to_projextstate2(false)
                    end
                  end
                
              end -- multiple conditions
            
            exists = nil
            run_routing_process = nil
            r_map_in = nil
            r_map_out = nil
            r_slider_in = nil
            r_slider_out = nil
          end
            
        -- edit mode 
          if mouse.Ctrl_state or mouse.Ctrl_LMB_state then
             data.routing_mode = 1
            else
             data.routing_mode = 0
          end
          
          if data.last_routing_mode ~= data.routing_mode then update_gfx = true end
          
        -- get knob under cursor
          if mouse.last_touched_map1 ~= mouse.last_touched_map then update_gfx = true end
      end --end routing mouse
      
    -----------------------
    -----------------------  
    
    -- fixedlearn window
      if data.current_window == 3 then
        -- close
          if MOUSE_match(b_close_xywh) and mouse.LMB_state and not mouse.last_LMB_state then
            data.current_window = 0
            ENGINE_return_data_to_projextstate2(false)
            mouse.mx,mouse.my = -100,-100 
          end
          
        -- midi osc selector
          if MOUSE_match(b_2_midisetup) and mouse.LMB_state and not mouse.last_LMB_state then
            data.current_fixedlearn = 0
            ENGINE_return_data_to_projextstate2(false)
            update_gfx = true
          end
          if MOUSE_match(b_2_oscsetup) and mouse.LMB_state and not mouse.last_LMB_state then
            data.current_fixedlearn = 1
            ENGINE_return_data_to_projextstate2(false)
            update_gfx = true
          end

        -- context menu          
          if (MOUSE_match(b_2_midisetup) or MOUSE_match(b_2_oscsetup)  )and 
            mouse.RMB_state and not mouse.last_RMB_state then
            GUI_fixedlearn_menu()
            mouse.mx,mouse.my = -100,-100
          end
          
        -- get bottom info
          if MOUSE_match(control_area_xywh)  then
            data.bottom_info_slider = MOUSE_get_map_sl()
            data.bottom_info_map = data.current_map
          end
          
        -- remove        
        if MOUSE_match(control_area_xywh) 
            and data.bottom_info_slider ~= nil 
            and mouse.RMB_state 
            and not mouse.last_RMB_state then
            gfx.x, gfx.y = mouse.mx, mouse.my
            ret_learn = gfx.showmenu('Clear learn') 
            if ret_learn == 1 then
              if data.current_fixedlearn == 0 then 
                data.learn[data.bottom_info_slider].midicc = nil
                data.learn[data.bottom_info_slider].midich = nil
                data.learn[data.bottom_info_slider].flags = nil
                ENGINE_return_data_to_projextstate2(false)
                set_learn = true   
              end
              if data.current_fixedlearn == 1 then 
                data.learn[data.bottom_info_slider].osc = nil
                ENGINE_return_data_to_projextstate2(false)
                set_learn = true   
              end        
            end            
        end
          
        -- set midi learn
          if MOUSE_match(control_area_xywh) 
            and data.bottom_info_slider ~= nil 
            and mouse.LMB_state 
            and not mouse.last_LMB_state 
            and data.current_fixedlearn == 0 then
              local s1
              local s1_t = {}
              _, s1 = reaper.GetUserInputs('MIDI Learn for slider '..data.bottom_info_slider,
                3, 'Channel,CC number,Soft takeover(Y/N)', '')
              for value in s1:gmatch('[^%,]+') do 
                if tonumber(value) ~= nil then value = tonumber(value) end
                table.insert(s1_t, value) 
              end
              if #s1_t >= 2 
                and s1_t[1] ~= nil and s1_t[2] ~= nil
                and s1_t[1] >=1 and s1_t[1] <= 16 
                and s1_t[2] >= 0 and s1_t[2] <=127 then
                  if s1_t[3] == nil then 
                    flags = 0 
                   else
                    if s1_t[3]:lower():match('%a') == 'y' then flags = 2 
                     else flags = 0 end
                  end
                  
                  if data.learn == nil then data.learn = {} end
                  if data.learn[data.bottom_info_slider] == nil then data.learn[data.bottom_info_slider] = {} end
                  data.learn[data.bottom_info_slider].midicc = s1_t[2]
                  data.learn[data.bottom_info_slider].midich = s1_t[1]
                  data.learn[data.bottom_info_slider].flags = flags
                  ENGINE_return_data_to_projextstate2(false)
                  set_learn = true
              end
          end
          
        -- set osc learn
          if MOUSE_match(control_area_xywh) 
            and data.bottom_info_slider ~= nil 
            and mouse.LMB_state 
            and not mouse.last_LMB_state 
            and data.current_fixedlearn == 1 then
              local s1
              _, s1 = reaper.GetUserInputs('OSC Learn for slider '..data.bottom_info_slider,
                1, 'OSC address', '')
              if s1 ~= nil and s1 ~= '' then
                if data.learn == nil then data.learn = {} end
                if data.learn[data.bottom_info_slider] == nil then data.learn[data.bottom_info_slider] = {} end 
                data.learn[data.bottom_info_slider].osc = s1 
                ENGINE_return_data_to_projextstate2(false)
                set_learn = true
              end
          end          
      end
            
    -----------------------
    -----------------------  
    -- routing config window
      if data.current_window == 4 then
        -- close
          if MOUSE_match(b_close_xywh) and mouse.LMB_state and not mouse.last_LMB_state then
            data.current_window = 2 -- ret to routing window
            ENGINE_return_data_to_projextstate2(false)
            mouse.mx,mouse.my = -100,-100 
          end
          
        -- change func
          if MOUSE_match({graph_rect[1],graph_rect[2]+graph_rect[4]+y_offset, 
            graph_rect[3],17}) and mouse.LMB_state and not mouse.last_LMB_state then
            _, form = reaper.GetUserInputs('Change formula', 1, 'Type formula', 
              data.routing[data.current_routing][rout_id].form)
              if form == '' then form = 'x' end
              data.routing[data.current_routing][rout_id].form = form
              ENGINE_return_data_to_projextstate2(false)
              ENGINE_dump_functions_to_routing_table()
          end
          
        -- draw func
          if MOUSE_match(graph_rect) 
            and mouse.LMB_state 
            and not mouse.last_LMB_state  then  mouse.last_object = 'draw_gr' end      
          if MOUSE_match(graph_rect) 
            and mouse.LMB_state 
            and mouse.last_object == 'draw_gr' then
            data.routing[data.current_routing][rout_id].curve = F_GetSet_curve(data.routing[data.current_routing][rout_id].curve)
            ENGINE_return_data_to_projextstate2(false)
            ENGINE_dump_functions_to_routing_table()
          end        
        
        -- presets          
          if MOUSE_match(b_2_fix_xywh) and mouse.LMB_state and not mouse.last_LMB_state 
            or MOUSE_match(b_2_fix_xywh) and mouse.RMB_state and not mouse.last_RMB_state then
            GUI_formula_menu() 
            mouse.mx,mouse.my = -100,-100
          end
      end
          
                
    -- collect mouse for loop
      mouse.last_LMB_state = mouse.LMB_state  
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state 
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_wheel = mouse.wheel
      data.last_routing_mode = data.routing_mode
  end
  
-----------------------------------------------------------------------  
  function DEFINE_global_variables()
    
    data = {}
    
    data.dev_mode = 0
    data.expert_mode = 0
    
    data.map = {}
    data.routing = {}
    data.slider_count = 16
    data.map_count = 8    
    data.current_map = 1
    data.slider_mode = 0 -- absolute/relative
    data.tablet_optimised = 0  
    data.fontname = 'Calibri'
    data.fontsize = 17
    data.slider_fontsize = 18
    data.current_window = 0 -- 0-main 1-about 2-routing 3-MIDIOSC setup 4-routing setup
    data.run_docked = 0
    data.wheel_coeff = 0.0001
    data.ctrl_coeff = 0.01    
    data.routing_mode = 0 -- 0 read -- 1 write
    data.routing_count = 8
    data.current_routing = 1
    data.use_learn = 0 -- 0 not use -- 1 global -- 2 local
    data.current_fixedlearn = 0 -- 0 - midi 1 - osc
    data.use_ext_actions = 0 
    set_learn = true
    
    main_xywh = {0,0,300,600}    
    mouse = {} 
    d_click_time = 0.2
    knob_sens = 8    
    OS = reaper.GetOS()
    config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_config.txt'   
    
    -- GUI variables
      aa = 1 -- aliasing
      gfx.mode = 0
      fontsize = data.fontsize        
      if OS == "OSX32" or OS == "OSX64" then fontsize = fontsize - 5 end   
      button_fontsize = fontsize   -- button
      info_fontsize = fontsize - 2
      
      buttons_back_alpha = 0.4
      button_text_alpha = 0.8
      color_t = {['back'] = '51 51 51',
                       ['back2'] = '51 63 56',
                       ['black'] = '10 2 7',
                       ['green'] = '102 255 102',
                       ['blue'] = '127 204 255',
                       ['white'] = '255 255 255',
                       ['red'] = '204 76 51',
                       ['green_dark'] = '102 153 102'
                       }
                        
  end
     
-----------------------------------------------------------------------
  function MAIN_exit() 
    reaper.atexit()
    gfx.quit() 
    --if data.current_window ==4 then data.current_window = 2 end  
    --ENGINE_return_data_to_projextstate2(false)
  end    
  
-----------------------------------------------------------------------
  function MAIN_defer()
    DEFINE_dynamic_variables2()
    DEFINE_dynamic_variables_ext_state()
    DEFINE_GUI_objects()
    DEFINE_GUI_buffers()
    GUI_DRAW2()
    MOUSE_get2()
    DEFINE_dynamic_variables2_defer_release()
    if char == 27 then MAIN_exit() end  --escape
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end -- space-> transport play   
    if char ~= -1 then reaper.defer(MAIN_defer) else MAIN_exit() end
  end
  
  function MAIN_f_run()
    reaper.SetProjExtState(0, 'MPL_PANEL_MAPPINGS', 'MPL_PM_DATA','')
    DEFINE_dynamic_variables2()
    ENGINE_return_data_to_projextstate2()
    gfx.init("mpl Mapping Panel // "..vrs..'',300, 600,0)
    gfx.ext_retina = 1
    update_gfx = true
    update_gfx_minor = true
    MAIN_defer()   
  end
  
  function MAIN_exist_run()
    extstate_ret = ENGINE_get_params_from_ext_state()
    gfx.init("mpl Mapping Panel // "..vrs, main_xywh[3], main_xywh[4], data.run_docked)
    gfx.ext_retina = 1
    update_gfx = true
    update_gfx_minor = true
    MAIN_defer()
  end
-----------------------------------------------------------------------  
  function MAIN_run2() --local main_ret1,main_ret
    local extstate_s2
    DEFINE_global_variables()
    retval2, extstate_s2 = reaper.GetProjExtState(0, 'MPL_PANEL_MAPPINGS', 'VRS')
    ext_vrs = tonumber(extstate_s2)
    if retval == 0 or ext_vrs == nil then 
      -- create
        reaper.SetProjExtState(0, 'MPL_PANEL_MAPPINGS', 'VRS',vrs)        
        main_ret = reaper.MB('It is first run OR current version is newer than previous.\n'..
                'Config will be erased for current project.','mpl Mapping Panel',1)        
        if main_ret == 1 then MAIN_f_run() end -- if agree to create 
     else
      -- check is current newer
          if ext_vrs < 1.11 then
            -- if current newer
              reaper.SetProjExtState(0, 'MPL_PANEL_MAPPINGS', 'VRS', vrs)  
              main_ret1 = reaper.MB('Current version is newer than previous.\n'..
                'For better compatibility config will be erased for current project.','mpl Mapping Panel',1)
              if main_ret1 == 1 then MAIN_f_run() end
           else
            -- if cuurent == extstate
              MAIN_exist_run()
          end
    end
  end
    
    
  
-----------------------------------------------------------------------    
  reaper.atexit(MAIN_exit)
  MAIN_run2() 
