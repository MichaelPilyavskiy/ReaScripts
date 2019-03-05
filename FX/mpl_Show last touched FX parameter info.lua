-- @description Show last touched FX parameter info
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

     
  
retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
if retval then
  tr =  reaper.CSurf_TrackFromID( tracknumber, false )
  retval, fxname = reaper.TrackFX_GetFXName( tr, fxnumber, '' )
  retval, parname = reaper.TrackFX_GetParamName( tr, fxnumber, paramnumber, '' )
  val = reaper.TrackFX_GetParamNormalized( tr, fxnumber, paramnumber)
  retval, valf = reaper.TrackFX_GetFormattedParamValue(  tr, fxnumber, paramnumber,'' )
  retval, trname = reaper.GetTrackName( tr, '' )
  reaper.ClearConsole()
  reaper.ShowConsoleMsg(trname..'\nfx#'..(fxnumber+1)..' - '..fxname..'\nparameter#'..(paramnumber+1)..' - '..parname..'\nvalue: '..val..'\nFormatted value: '..valf)
  
end