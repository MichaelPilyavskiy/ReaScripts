-- @description Bypass all FX except instruments on selected tracks 
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694 
-- @changelog
--    + init
  

  
  script_title = "Bypass all FX except instruments on selected tracks"
  reaper.Undo_BeginBlock()
  
  counttracks = reaper.CountSelectedTracks(0)
  if counttracks  ~= nil then
    for i = 1, counttracks do
      tr = reaper.GetSelectedTrack(0,i-1)
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
  

  reaper.Undo_EndBlock(script_title, 0)
