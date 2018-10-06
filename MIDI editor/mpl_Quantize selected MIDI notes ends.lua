-- @version 1.11
-- @author MPL
-- @description Quantize selected MIDI notes ends
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # improve/handle math around closest MIDI Editor grid
--    + prevent less than 2 PPQ length notes

  function main() 
    reaper.Undo_BeginBlock()
    local ME = reaper.MIDIEditor_GetActive()
    if not ME then return end
    local take = reaper.MIDIEditor_GetTake(ME)
    if not take or not TakeIsMIDI(take) then return end
    local ME_grid, swing = reaper.MIDI_GetGrid( take )
     
    local parent_item = reaper.GetMediaItemTake_Item( take )
    local itpos = GetMediaItemInfo_Value( parent_item, 'D_POSITION' ) 

    
    local _, notecnt = reaper.MIDI_CountEvts( take )
    for i = 1, notecnt do
      local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )
      if selected then
      
        local proj_time = reaper.MIDI_GetProjTimeFromPPQPos( take, endppqpos )
        local beats, _, _, tpos_beats = reaper.TimeMap2_timeToBeats( proj, proj_time )
        local out_pos, out_ppq, out_beatpos
        
        if swing == 0 then             
          if (beats % ME_grid) < (ME_grid/2) then out_beatpos = tpos_beats - (beats % ME_grid) else out_beatpos = tpos_beats - (beats % ME_grid) + ME_grid end
          out_pos = TimeMap2_beatsToTime( 0, out_beatpos)
          out_ppq = MIDI_GetPPQPosFromProjTime( take, out_pos )
         else
          local midval = 0.5 + 0.25*swing
          local checkval = 0.5 * (beats % (ME_grid*2)) / ME_grid
          if checkval < midval then 
            -- before swing grid
            if checkval < 0.5*midval then 
              out_beatpos = tpos_beats - (beats % ME_grid)  
             else 
              if swing < 0 then 
                out_beatpos = tpos_beats - (beats % ME_grid) + ME_grid*midval*2
               else
                out_beatpos = tpos_beats - (beats % ME_grid) + ME_grid*swing/2
                if checkval % midval < 0.5 then out_beatpos = out_beatpos + ME_grid end
              end
            end
                      
           else 
           
            -- after swing grid
            if checkval < midval + 0.5*  (1-midval)  then 
              out_beatpos = tpos_beats - (beats % ME_grid) + ME_grid * 0.5 * swing
             else 
              out_beatpos = tpos_beats - (beats % ME_grid) + ME_grid
            end            
           
          end
          out_pos = TimeMap2_beatsToTime( 0, out_beatpos)
          out_ppq = MIDI_GetPPQPosFromProjTime( take, out_pos )          
        end  

        if out_ppq and out_ppq - startppqpos > 10 then MIDI_SetNote( take, i-1, true, muted, startppqpos, out_ppq, chan, pitch, vel, true ) end
      end
    end
               

    MIDI_Sort( take )
    Undo_EndBlock('Quantize selected MIDI notes ends', 0)  
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        return true
      end
      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
  ---------------------------------------------------
  function CheckReaperVrs(rvrs) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0)
      return
     else
      return true
    end
  end
--------------------------------------------------------------------  
  local ret = CheckFunctions('Action') 
  local ret2 = CheckReaperVrs(5.32)    
  if ret and ret2 then main() end
  