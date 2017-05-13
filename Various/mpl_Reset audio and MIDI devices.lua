-- @version 1.0
-- @author MPL
-- @description Reset audio and MIDI devices
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init

  
  function main()
    reaper.Audio_Quit()
    reaper.Audio_Init()
  end
  
  reaper.defer(main)
