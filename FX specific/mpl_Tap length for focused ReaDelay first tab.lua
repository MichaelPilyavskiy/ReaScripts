-- @description Tap length for focused ReaDelay first tab
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + check is focused FX is readelay
--  + require 2 taps
--  + quantized to project tempo

function main()
    retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX2()
    if retval&1~=1 then return end -- focused fx is a track fx
    if retval&2==2 then return end -- exclude take fx
    if tracknumber ==0 then tr = reaper.GetMasterTrack(0) else tr = reaper.GetTrack(0,tracknumber-1) end
    local lastTS = reaper.GetExtState( 'mplreadelaytap', 'lastTS' )
    if tonumber(lastTS) then lastTS = tonumber(lastTS) else lastTS = os.clock() end -- reset lastTS if not found
    local retval, buf = reaper.TrackFX_GetNamedConfigParm( tr, fxnumber, 'original_name' )
    if not buf:match('ReaDelay') then return end
     
    local TS = os.clock()
    if TS - lastTS < 0 or TS - lastTS > 1 then lastTS = TS end 
    
    local timedif = TS - lastTS
    if timedif ~= 0 then
      bpm = reaper.Master_GetTempo()
      beattime_sec =60/bpm
      div =  beattime_sec / timedif
      divout= math_q(2*div)/2
      out = beattime_sec/divout
      reaper.TrackFX_SetParamNormalized( tr, fxnumber, 3, out/10 ) 
    end
    reaper.SetExtState( 'mplreadelaytap', 'lastTS', TS, false )
  end
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  main()