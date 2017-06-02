-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Prepare MIDI input for last touched track
-- @changelog
--    + taken from Export selected items to RS5k instances on selected track (drum mode)

  function MIDI_prepare(tr)
    local tr = reaper.GetLastTouchedTrack()
    if not tr then return end
    local bits_set=tonumber('111111'..'00000',2)
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+bits_set ) -- set input to all MIDI
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
  end
  
  MIDI_prepare()
    