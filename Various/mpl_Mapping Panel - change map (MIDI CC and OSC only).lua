--[[
   * ReaScript Name: mpl_Mapping Panel - change map (MIDI CC and OSC only).lua
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
val_ret=val/resolution
value = tostring(math.floor(val_ret*8)) -- should be taken from data.map_count
reaper.SetExtState("MPL_PANEL_MAPPINGS", "MAP", value, false)
