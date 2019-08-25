-- @description Show and arm envelopes linked to learn for selected tracks
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix name

  function literalize(str) return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  function ArmEnvLearn(tr)    
    if not tr then return end    
    local GUID = {}
    for fx = 1,  reaper.TrackFX_GetCount( tr) do GUID[#GUID+1]= reaper.TrackFX_GetFXGUID( tr, fx-1 ) end
    local _, chunk = reaper.GetTrackStateChunk(tr, '', true)
    for line in chunk:gmatch('BYPASS.-WAK') do
      if line:match('PARMLEARN') then 
        for GUID_id = 1, #GUID do
          if line:match(literalize(GUID[GUID_id])) then            
            for parid_line in line:gmatch('PARMLEARN %d+') do
              local parid = parid_line:match('%d+')
              if parid and tonumber(parid) then 
                local fxenv = reaper.GetFXEnvelope( tr, GUID_id-1, tonumber(parid), true )
                local BR_env = reaper.BR_EnvAlloc( fxenv, false )
                local _, _, _, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties( BR_env )
                reaper.BR_EnvSetProperties( BR_env, true, true, true, inLane, laneHeight, defaultShape, faderScaling )
                reaper.BR_EnvFree( BR_env, true )
              end
            end            
            break
          end
        end
      end
    end    
    reaper.TrackList_AdjustWindows( false )
  end
  ---------------------------------   
  
  for i = 1, reaper.CountSelectedTracks(0) do
    local tr= reaper.GetSelectedTrack(0,i-1) 
    ArmEnvLearn(tr)
  end