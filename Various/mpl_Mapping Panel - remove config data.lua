--[[
   * ReaScript Name: Remove mpl Mapping Panel config from current project
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  reaper.SetProjExtState(0, 'MPL_PANEL_MAPPINGS', 'MPL_PM_DATA','')
  reaper.SetProjExtState(0, 'MPL_PANEL_MAPPINGS', 'VRS','')
