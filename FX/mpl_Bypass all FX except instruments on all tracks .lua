--[[
   * ReaScript Name:Bypass all FX except instruments on all tracks 
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.1
  ]]
  
  -- changelog
  -- 14.01.2014 1.1 fixed wron getinstr id
  
  script_title = "Bypass all FX except instruments on all tracks"
  reaper.Undo_BeginBlock()
  
  counttracks = reaper.CountTracks(0)
  if counttracks  ~= nil then
    for i = 1, counttracks do
      tr = reaper.GetTrack(0,i-1)
      if tr ~= nil then
      
        fxcount = reaper.TrackFX_GetCount(tr)
        if fxcount ~= nil then
          for j = 1, fxcount do
            if j == reaper.TrackFX_GetInstrument(tr)+1 then
              reaper.TrackFX_SetEnabled(tr, j-1, true)
               else
              reaper.TrackFX_SetEnabled(tr, j-1, false)
            end
          end
        end  
              
      end
    end
  end
  
  tr= reaper.GetMasterTrack(0)
  
        fxcount = reaper.TrackFX_GetCount(tr)
        if fxcount ~= nil then
          for j = 1, fxcount do
            if j == reaper.TrackFX_GetInstrument(tr)+1 then
              reaper.TrackFX_SetEnabled(tr, j-1, true)
               else
              reaper.TrackFX_SetEnabled(tr, j-1, false)
            end
          end
        end  
            
  reaper.Undo_EndBlock(script_title, 0)
