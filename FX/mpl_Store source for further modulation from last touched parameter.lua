-- @version 1.0
-- @author MPL
-- @changelog
--   + init release
-- @description Store source for further modulation from last touched parameter
-- @website http://forum.cockos.com/member.php?u=70694

function Save()
    _, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    reaper.SetExtState( 'copypaste_plugin_link', 'fxnumber', fxnumber, false )
    reaper.SetExtState( 'copypaste_plugin_link', 'paramnumber', paramnumber, false )
  end
  
  Save()
