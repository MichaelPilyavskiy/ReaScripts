-- @description Tap length for focused ReaDelay first tab
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init 

function main()
    retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX2()
    if retval&1~=1 then return end -- focused fx is a track fx
    if retval&2==2 then return end -- exclude take fx
    if tracknumber ==0 then tr = reaper.GetMasterTrack(0) else tr = reaper.GetTrack(0,tracknumber-1) end
    local lastTS = reaper.GetExtState( 'mplreadelaytap', 'lastTS' )
    if tonumber(lastTS) then lastTS = tonumber(lastTS) else lastTS = os.clock() end -- reset lastTS if not found
    
    local TS = os.clock()
    if TS - lastTS < 0 or TS - lastTS > 1 then lastTS = TS end
    
    
    local timedif = TS - lastTS
    if timedif ~= 0 then
      local tapcnt = reaper.GetExtState( 'mplreadelaytap', 'tapcnt' )
      if not tonumber(tapcnt) then tapcnt = 0 else tapcnt = tonumber(tapcnt)+1 end
      reaper.SetExtState( 'mplreadelaytap', 'tapcnt', tapcnt, false )
      reaper.SetExtState( 'mplreadelaytap', 'tap'..tapcnt, timedif, false )
      local t = {}
      for i = 1, tapcnt do
        local tapsec = reaper.GetExtState( 'mplreadelaytap', 'tap'..i )
        if  tonumber(tapsec) then t[i] = tonumber(tapsec) end
      end
      
      -- calc rms 
        if #t ~= 1 then
           rms = 0
          local ist = 2
          local laststeps = 10
          if #t > laststeps then ist = #t - laststeps end
          for i = ist, #t do rms = rms + t[i] end
          if #t-ist > 0 then
            rms = rms / (#t-ist)
            if rms ~= 0 then  reaper.TrackFX_SetParamNormalized( tr, fxnumber, 3,rms/10 ) end
          end
        end
     else
      reaper.SetExtState( 'mplreadelaytap', 'tapcnt', 0, false )
    end 
    reaper.SetExtState( 'mplreadelaytap', 'lastTS', TS, false )
  end
  
  main()