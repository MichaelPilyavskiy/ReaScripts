-- @version 1.15
-- @author MPL
-- @description Quantize selected MIDI notes ends
-- @website http://forum.cockos.com/member.php?u=70694
-- @provides
-- @provides [main=main,midi_editor] .
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  ----------------------------------------------------------------------
  function Quantize_selected_MIDI_notes_ends_sub(take,i,itpos,muted,startppqpos, endppqpos,ME_grid,swing)
    
    local proj_time = reaper.MIDI_GetProjTimeFromPPQPos( take, endppqpos )
    local beats, _, _, tpos_beats = reaper.TimeMap2_timeToBeats( proj, proj_time )
    local out_pos, out_ppq, out_beatpos
    
    local ME_grid_s = TimeMap2_beatsToTime( 0, ME_grid)
    local ME_grid_ppq = MIDI_GetPPQPosFromProjTime( take, ME_grid_s+itpos )
    
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
    
      
    if out_ppq and out_pos then
      
      if out_ppq - startppqpos < ME_grid_ppq then
        out_pos = TimeMap2_beatsToTime( 0, out_beatpos+ME_grid)
        out_ppq = MIDI_GetPPQPosFromProjTime( take, out_pos )   
      end
      
      if out_ppq - startppqpos > ME_grid_ppq then 
        MIDI_SetNote( take, i-1, true, muted, startppqpos, out_ppq, chan, pitch, vel, true ) 
      end
    end
  end
  ----------------------------------------------------------------------  
  function Quantize_selected_MIDI_notes_ends(take) 
    if not take or not TakeIsMIDI(take) then return end
    local ME_grid, swing = reaper.MIDI_GetGrid( take )
     
    local parent_item = reaper.GetMediaItemTake_Item( take )
    local itpos = GetMediaItemInfo_Value( parent_item, 'D_POSITION' ) 

    
    local _, notecnt = reaper.MIDI_CountEvts( take )
    for i = 1, notecnt do
      local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )
      if selected then
          Quantize_selected_MIDI_notes_ends_sub(take,i,itpos,muted,startppqpos, endppqpos,ME_grid,swing)
      end
    end 

    MIDI_Sort( take )
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.32,true) then 
    Undo_BeginBlock()
    local ME = reaper.MIDIEditor_GetActive()
    if ME then
      --take = reaper.MIDIEditor_GetTake(ME)
      for takeindex = 1, 100000 do
        local take = MIDIEditor_EnumTakes( ME, takeindex-1, true) 
        if not take then break end
        Quantize_selected_MIDI_notes_ends(take) 
      end
     else
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item) 
        if take then 
          Quantize_selected_MIDI_notes_ends(take) 
        end
      end
    end
    Undo_EndBlock('Quantize selected MIDI notes ends', 0xFFFFFFFF)  
  end 
  