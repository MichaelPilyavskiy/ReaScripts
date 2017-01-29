-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description SendFader - set volume (MIDI OSC only)
-- @changelog
--    + init

_,_,_,_,_,resolution,val = reaper.get_action_context()
local val_ret=val/resolution
reaper.SetExtState( 'mpl SendFader', 'EXT_vol', val_ret, false )
