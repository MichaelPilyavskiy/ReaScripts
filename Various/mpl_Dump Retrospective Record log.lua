-- @description Dump Retrospective Record log
-- @version 2.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Dump recent MIDI messages log. 
-- @metapackage
-- @provides
--    [main] . > mpl_Dump Retrospective Record log.lua
--    [main] . > mpl_Dump Retrospective Record log (notes only).lua
--    [main] . > mpl_Dump Retrospective Record log (only data at playing).lua
--    [main] . > mpl_Dump Retrospective Record log (only data at stop).lua
--    [main] . > mpl_Dump Retrospective Record log (everything recorded from last REAPER start).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last 5 minutes).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last 5 minutes, ignore loop).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last 10 minutes).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last 30 minutes).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last hour, obey stored data break).lua
--    [main] . > mpl_Dump Retrospective Record log (clean buffer only).lua
-- @changelog 
--    + add mpl_Dump Retrospective Record log (everything from last 5 minutes, ignore loop)
--    + Put all the functions into the dcript body

  ---------------------------------------------------------------------------------
  function MPL_DumpRetrospectiveLog_CollectEvents(settings) -- collect raw data
    local t = {}
    local idx = 0
    local evt_id = 0
    while true do
      local retval, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(idx)
      if retval == 0 then break end -- stop if return null sequence
      idx = idx + 1 
      if (devIdx & 0x10000) == 0 or devIdx == 0x1003e then -- should works without this after REAPER6.39rc2, so thats just in case
        local isNoteOn = rawmsg:byte(1)>>4 == 0x9
        local isNoteOff = rawmsg:byte(1)>>4 == 0x8
        if settings.notes_only==0 or (settings.notes_only&1==1 and (isNoteOn or isNoteOff) ) then
          evt_id = evt_id + 1 
          t[evt_id] = {retval=retval, rawmsg=rawmsg, tsval=tsval, devIdx=devIdx, projPos=projPos, projLoopCnt=projLoopCnt}
        end
      end
    end 
    -- reverse table
      local rev_t = {}
      local rev_t_id = 0
      for i=#t, 1, -1 do rev_t_id = rev_t_id + 1 rev_t[rev_t_id] = t[i] end
      
    return rev_t
  end
  ---------------------------------------------------------------------------------
  function MPL_DumpRetrospectiveLog_CalculateEventsTiming(t, SR) -- add POST_projtimesec, a) time in seconds after edit cursor position b) playposition while playing
    local editcurpos = GetCursorPositionEx( 0 )
    for i = 1, #t do
      if t[i].projPos>=0 then
        t[i].POST_projtimesec = t[i].projPos -- event was catched while playing
        t[i].POST_atplaystate = true -- event was catched while playing
       else
        t[i].POST_projtimesec = t[i].tsval / SR -- event was catched while stopped
        t[i].POST_atplaystate = false
      end
    end
  end
  ---------------------------------------------------------------------------------  
  function MPL_DumpRetrospectiveLog_DumpToTake(item, t, mode, settings)
    
    -- define item/take boundaries
      local first_evt_pos = 60*60*24*7*365 -- year
      local last_evt_pos = 0 
      for i=1, #t do
        local evt = t[i]
        first_evt_pos = math.min( first_evt_pos, evt.POST_projtimesec)
        last_evt_pos = math.max( last_evt_pos, evt.POST_projtimesec)
      end 
      --local item =  GetMediaItemTake_Item( take )
      SetMediaItemInfo_Value( item, 'D_POSITION',first_evt_pos )
      SetMediaItemInfo_Value( item, 'D_LENGTH',last_evt_pos-first_evt_pos )
      SetMediaItemInfo_Value( item, 'B_UISEL',1 )
      local tr= GetMediaItemTrack( item )
      local ret, tr_name = GetTrackName( tr )
      
    -- extract loop takes
      local loop_cnt_t = {}
      for i=1, #t do
        local evt = t[i]
        if settings.obey_loops&1==1 then
          if not loop_cnt_t[evt.projLoopCnt] then loop_cnt_t[evt.projLoopCnt] = {} end
          loop_cnt_t[evt.projLoopCnt][#loop_cnt_t[evt.projLoopCnt]+1] = CopyTable(t[i])
         else
          if not loop_cnt_t[1] then loop_cnt_t[1] = {} end
          loop_cnt_t[1][#loop_cnt_t[1]+1] = CopyTable(t[i])
        end
      end
      
    -- add data to take(s)
      local tk_id = 0
      for key in pairs(loop_cnt_t) do
        tk_id = tk_id + 1
        local take = GetTake( item, tk_id-1)
        
        if not  ValidatePtr2( 0, take, 'MediaItem_Take*' )  then  
          local new_item = CreateNewMIDIItemInProj( tr, first_evt_pos, last_evt_pos )
          local new_take = GetActiveTake(new_item)
          local new_src = reaper.GetMediaItemTake_Source( new_take )
          
          AddTakeToMediaItem( item )
          take = GetTake(item, tk_id-1)
          SetMediaItemTake_Source( take, new_src )
          DeleteTrackMediaItem( tr, new_item )
        end
        
        local midistr = ''
        local ppq_cur_last    
        for i=1, #loop_cnt_t[key] do
          local evt = loop_cnt_t[key][i]
          local ppq_evt = math.floor(MIDI_GetPPQPosFromProjTime( take, evt.POST_projtimesec ))
          ppq_cur = ppq_evt
          if not ppq_cur_last then ppq_cur_last = ppq_cur end
          local str_per_msg = string.pack("i4BI4BBB", ppq_cur - ppq_cur_last, 0, 3, evt.rawmsg:byte(1), evt.rawmsg:byte(2), evt.rawmsg:byte(3))
          ppq_cur_last = ppq_cur
          midistr = midistr..str_per_msg
        end
        MIDI_SetAllEvts(take, midistr)
        MIDI_Sort(take) 
      end
    UpdateItemInProject( item )
    
    -- show message
    local showmsg = GetExtState( 'MPL_DRL', 'showmsg' ) 
    if showmsg == '' then  showmsg = 1 SetExtState( 'MPL_DRL', 'showmsg', showmsg, true ) end
    if showmsg == 1 then 
      MB('Take with recorded data '..mode..' added sucessfully at \nTrack: '..tr_name..'\nPosition: '..first_evt_pos..'s'..'\nLength: '..last_evt_pos-first_evt_pos..'s', 'MPL Dump Retrospective log', 0)
    end
  end
  ---------------------------------------------------------------------------------
  function MPL_DumpRetrospectiveLog_SplitTable(t)
    local t1_atplay = {}
    local t2_atstop = {}
    -- split at playing/stop events
    for i = 1, #t do 
      if t[i].POST_atplaystate == true then
        t1_atplay[#t1_atplay+1] = t[i]
       else
        t2_atstop[#t2_atstop+1] = t[i]
      end
    end 
    return t1_atplay, t2_atstop
  end
  ---------------------------------------------------------------------------------
  function MPL_DumpRetrospectiveLog_CreateItem()
    -- Create item at first selected track or new one if no track selected 
      local track = GetSelectedTrack(0,0)
      if not track then 
        InsertTrackAtIndex(  CountTracks( 0 ), 1 )
        track = GetTrack(0,CountTracks( 0 )-1)
      end  
    -- Add item
      local itempos = GetCursorPosition()
      local pos = pos or 0
      local end_pos = end_pos or (pos + 1)
      local item =  CreateNewMIDIItemInProj( track,  0,  1)
      --local take =  GetActiveTake( item )
      return item
  end

  -------------------------------------------
  function MPL_DumpRetrospectiveLog_NormalizerTableAtStop(t, editcurpos) -- shift timing to a positiove scope based on first event
    local shift = 0 
    for i = 1, #t do
      if i == 1 then shift = t[i].POST_projtimesec end
      t[i].POST_projtimesec = t[i].POST_projtimesec + editcurpos - shift
    end
  end
  -------------------------------------------
  function MPL_DumpRetrospectiveLog(settings)
  
    -- get data
      local SR = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
      local editcurpos = GetCursorPositionEx( 0 )
      local midi_t = MPL_DumpRetrospectiveLog_CollectEvents(settings)
      MPL_DumpRetrospectiveLog_CalculateEventsTiming(midi_t, SR)
      t1_atplay, t2_atstop = MPL_DumpRetrospectiveLog_SplitTable(midi_t)
      
    -- not dump, just add break
      if settings.dump_evts&16==16 then
        SetExtState( 'MPL_DRL', 'ATPLAY_POS', #t1_atplay+1, false )
        SetExtState( 'MPL_DRL', 'ATSTOP_POS', #t2_atstop+1, false )
        return
      end
      
    -- dump evts at playing
      if settings.dump_evts&1==1 and #t1_atplay>=2 then
        -- handle ignore_stored_break
          local pos_start = GetExtState( 'MPL_DRL', 'ATPLAY_POS' ) 
          if pos_start == '' then pos_start = 1 else pos_start = tonumber(pos_start) end
          if settings.ignore_stored_break&1==1 then 
            pos_start = 1 
           else
            SetExtState( 'MPL_DRL', 'ATPLAY_POS', #t1_atplay+1, false )
          end
          for i = pos_start -1, 0, -1 do if t1_atplay[i] then table.remove(t1_atplay,i) end end
        -- handle time_limit
          if settings.time_limit> 0 then -- filter by time stamp
            for i = #t1_atplay, 1, -1 do  if math.abs(t1_atplay[i].tsval/SR) > settings.time_limit then table.remove(t1_atplay,i) end  end 
          end
          
        if #t1_atplay>=2 then
          -- create take
            local item = MPL_DumpRetrospectiveLog_CreateItem()
          -- dump events
            MPL_DumpRetrospectiveLog_DumpToTake(item, t1_atplay, 'while playing', settings) 
        end
      end
      
    -- dump evts at playing
      if settings.dump_evts&2==2 and #t2_atstop>=2 then
        -- handle ignore_stored_break
          local pos_start = GetExtState( 'MPL_DRL', 'ATSTOP_POS' ) 
          if pos_start == '' then pos_start = 1 else pos_start = tonumber(pos_start) end
          if settings.ignore_stored_break&1==1 then 
            pos_start = 1  
           else
            SetExtState( 'MPL_DRL', 'ATSTOP_POS', #t2_atstop+1, false )
          end
          for i = pos_start -1, 0, -1 do if t2_atstop[i] then table.remove(t2_atstop,i) end end
        -- handle time_limit
          if settings.time_limit> 0 then -- filter by time stamp
            for i = #t2_atstop, 1, -1 do  if math.abs(t2_atstop[i].tsval/SR) > settings.time_limit then table.remove(t2_atstop,i) end  end 
          end
        if #t2_atstop>=2 then
          -- shift events
            MPL_DumpRetrospectiveLog_NormalizerTableAtStop(t2_atstop, editcurpos) -- shift timing to a positiove scope based on first event
          -- create take
            local item = MPL_DumpRetrospectiveLog_CreateItem()
          -- dump events
            MPL_DumpRetrospectiveLog_DumpToTake(item, t2_atstop, 'while stopped', settings)
        end
      end      
       
  end
  ---------------------------------------------------------------------  
  function MPL_DumpRetrospectiveLog_Parsing_filename(script_title) 
    --[[local settings = {
                        ['dump_evts'] = 3, -- &1 put take into selected track (create new if not exists), boundaries is [first_event...last_event], &2 put take into selected track (create new if not exists), boundaries is [edit_cursor...length_beetween_last_and_first_event]
                        ['ignore_stored_break'] = 3, -- &1 ignore break at playing, &2 ignore break at playing  
                        ['time_limit'] = 20, -- filter in seconds by timestamp
                        ['obey_loops'] = 1, -- collect loops into takes
                        ['notes_only'] = 0, -- collect loops into takes
                      } ]]
    local versions ={
                      { str='mpl_Dump Retrospective Record log',
                        t = { ['dump_evts'] = 3,
                              ['ignore_stored_break'] = 0,
                              ['time_limit'] = -1,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 0,
                            }
                      },                       
                      
                      { str='mpl_Dump Retrospective Record log (notes only)',
                        t = { ['dump_evts'] = 3,
                              ['ignore_stored_break'] = 0,
                              ['time_limit'] = -1,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 1, 
                            }
                      },            
                      
                      { str='mpl_Dump Retrospective Record log (only data at playing)',
                        t = { ['dump_evts'] = 1,
                              ['ignore_stored_break'] = 0,
                              ['time_limit'] = -1,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 0,
                            }
                      },
                      { str='mpl_Dump Retrospective Record log (only data at stop)',
                        t = { ['dump_evts'] = 2,
                              ['ignore_stored_break'] = 0,
                              ['time_limit'] = -1,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 0,
                            }
                      },                      
                      { str='mpl_Dump Retrospective Record log (everything recorded from last REAPER start)',
                        t = { ['dump_evts'] = 3,
                              ['ignore_stored_break'] = 3,
                              ['time_limit'] = -1,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 0,
                            }
                      },   
                      { str='mpl_Dump Retrospective Record log (everything from last 5 minutes)',
                        t = { ['dump_evts'] = 3,
                              ['ignore_stored_break'] = 3,
                              ['time_limit'] = 300,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 0,
                            }
                      }, 
                      { str='mpl_Dump Retrospective Record log (everything from last 5 minutes, ignore loop)',
                        t = { ['dump_evts'] = 3,
                              ['ignore_stored_break'] = 3,
                              ['time_limit'] = 300,
                              ['obey_loops'] = 0,
                              ['notes_only'] = 0,
                            }
                      },                       
                      { str='mpl_Dump Retrospective Record log (everything from last 10 minutes)',
                        t = { ['dump_evts'] = 3,
                              ['ignore_stored_break'] = 3,
                              ['time_limit'] = 600,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 0,
                            }
                      },  
                      { str='mpl_Dump Retrospective Record log (everything from last 30 minutes)',
                        t = { ['dump_evts'] = 3,
                              ['ignore_stored_break'] = 3,
                              ['time_limit'] = 1800,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 0,
                            }
                      }, 
                      { str='mpl_Dump Retrospective Record log (everything from last hour, obey stored data break)',
                        t = { ['dump_evts'] = 3,
                              ['ignore_stored_break'] = 0,
                              ['time_limit'] = 3600,
                              ['obey_loops'] = 1,
                              ['notes_only'] = 0,
                            }
                      }, 
                      { str='mpl_Dump Retrospective Record log (clean buffer only)',
                        t = { ['dump_evts'] = 16,
                              ['ignore_stored_break'] = 0,
                              ['time_limit'] = -1,
                              ['obey_loops'] = 0,
                              ['notes_only'] = 0,
                            }
                      },                       
                      
                    }
    for i = 1, #versions do if script_title==versions[i].str then return versions[i].t end end
  end                    
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.67) if ret then local ret2 = VF_CheckReaperVrs(6.39,true) if ret2 then 
    local filename = ({reaper.get_action_context()})[2]
    local script_title = GetShortSmplName(filename):gsub('%.lua','')
    local settings = MPL_DumpRetrospectiveLog_Parsing_filename(script_title)
    if settings then 
      Undo_BeginBlock2( 0 )
      MPL_DumpRetrospectiveLog(settings) 
      Undo_EndBlock2( 0, 'MPL_DumpRetrospectiveLog', 0)
    end
  end end
