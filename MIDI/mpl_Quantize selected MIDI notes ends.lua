-- @version 1.13
-- @author MPL
-- @description Quantize selected MIDI notes ends
-- @website http://forum.cockos.com/member.php?u=70694
-- @provides
-- @provides [main=main,midi_editor] .
-- @changelog
--    # add support for multiple MIDI editor takes

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
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) if ret then local ret2 = VF_CheckReaperVrs(5.32,true) if ret2 then 
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
  end end
  