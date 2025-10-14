-- @version 1.17
-- @author MPL
-- @description Quantize selected MIDI notes ends
-- @website http://forum.cockos.com/member.php?u=70694
-- @provides
-- @provides [main=main,midi_editor] .
-- @changelog
--    # extend note if it end up with zero length

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
    local proj = -1
    local proj_time_st = reaper.MIDI_GetProjTimeFromPPQPos( take, startppqpos )
    beats_st, _, _, tpos_beats_st,denom_st = reaper.TimeMap2_timeToBeats( proj, proj_time_st )
    
    local proj_time = reaper.MIDI_GetProjTimeFromPPQPos( take, endppqpos )
    beats, _, _, tpos_beats,denom = reaper.TimeMap2_timeToBeats( proj, proj_time )
    ME_grid = ME_grid * denom/4
    
    pos_in_beat = tpos_beats%ME_grid 
    nextbeat = tpos_beats + ME_grid - pos_in_beat
    prevbeat = tpos_beats - pos_in_beat
    
    if swing ~= 0 then  
    
      pos_in_beat = tpos_beats%(ME_grid*2) 
      nextbeat = tpos_beats + ME_grid*2 - pos_in_beat
      prevbeat = tpos_beats - pos_in_beat
      swingline = tpos_beats - pos_in_beat + ME_grid+swing*ME_grid/2 
      if tpos_beats>=prevbeat and tpos_beats<=swingline then
        if swingline-tpos_beats < tpos_beats- prevbeat then
          out_beatpos = swingline
         else
          out_beatpos = prevbeat
          out_beatpos2 = swingline
        end
       else 
        if nextbeat-tpos_beats < tpos_beats- swingline then
          out_beatpos = nextbeat
         else
          out_beatpos = swingline
          out_beatpos2 = nextbeat
        end
      end
      
      
     else
      
      -- strength
      if tpos_beats-prevbeat< nextbeat-tpos_beats then
        out_beatpos = prevbeat
        out_beatpos2 = nextbeat
       else
        out_beatpos = nextbeat
      end
      
    end
    
    if out_beatpos - tpos_beats_st < 0.01 then out_beatpos = nextbeat end
    
    
    out_pos = TimeMap2_beatsToTime( 0, out_beatpos)
    out_ppq = MIDI_GetPPQPosFromProjTime( take, out_pos ) 
    if out_ppq<startppqpos then
      if out_beatpos2 then
        out_pos = TimeMap2_beatsToTime( 0, out_beatpos2)
        out_ppq = MIDI_GetPPQPosFromProjTime( take, out_pos ) 
        MIDI_SetNote( take, i-1, true, muted, startppqpos, out_ppq, chan, pitch, vel, true ) 
      end
     else
      MIDI_SetNote( take, i-1, true, muted, startppqpos, out_ppq, chan, pitch, vel, true ) 
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
  