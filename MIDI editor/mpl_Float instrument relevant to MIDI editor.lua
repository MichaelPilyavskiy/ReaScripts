-- @version 1.2
-- @author MPL
-- @description Float instrument relevant to MIDI editor
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # fix send instrument lookup (http://github.com/MichaelPilyavskiy/ReaScripts/issues/4)


--[[
    1.2 23.02.2017
      # fix send instrument lookup (http://github.com/MichaelPilyavskiy/ReaScripts/issues/4)
    1.1 22.02.2017
      + Search instruments in send destination tracks
]]

function check_instr(track)
  vsti_id = reaper.TrackFX_GetInstrument(track)
  if vsti_id and vsti_id >= 0 then 
    reaper.TrackFX_Show(track, vsti_id, 3) -- float
    return true
  end
end

function main()
  local act_editor = reaper.MIDIEditor_GetActive()
  if not act_editor then return end
  local take = reaper.MIDIEditor_GetTake(act_editor)
  if not take then return end
  local take_track = reaper.GetMediaItemTake_Track(take)
  
  -- search vsti on parent track
    ret1 = check_instr(take_track )
    if ret1 then return end
    
  -- search vsti on tree
    take_track2 = take_track
    repeat
      parent_track = reaper.GetParentTrack(take_track2)
      if parent_track ~= nil then
        ret2 = check_instr(parent_track )
        if ret2 then return end
        take_track2 = parent_track
      end
    until parent_track == nil    
    
  -- search sends
    cnt_sends = reaper.GetTrackNumSends( take_track, 0)
    for sendidx = 1,  cnt_sends do
      dest_tr = reaper.BR_GetMediaTrackSendInfo_Track( take_track, 0, sendidx-1, 1 )
      ret3 = check_instr(dest_tr )
      if ret3 then return  end
    end
  
end

script_title = 'Float instrument relevant to MIDI Editor'
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock(script_title, 1)
