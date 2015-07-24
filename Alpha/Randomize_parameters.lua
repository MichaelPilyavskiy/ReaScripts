trackcount = reaper.CountTracks(0)
if trackcount ~= nil then
  for i =1, trackcount do
    track = reaper.GetTrack(0, i-1)
    fx_count = reaper.TrackFX_GetCount(track)
    if fx_count ~= nil then
      for j = 1 , fx_count do
        if reaper.TrackFX_GetOpen(track, j-1) == true then
          par_count = reaper.TrackFX_GetNumParams(track, j-1)
          if par_count ~= nil then
            for k = 1, par_count do
              value, minvalOut, maxvalOut = reaper.TrackFX_GetParam(track, j-1, k-1)
              retval, name = reaper.TrackFX_GetParamName(track, j-1, k-1, "")
              if name ~= "Gain" and
                 name ~= "gain" and
                 name ~= "GAIN" and
                 name ~= "ON" and
                 name ~= "On" and
                 name ~= "on" and
                 name ~= "OFF" and
                 name ~= "Off" and
                 name ~= "off" and
                 string.find(name, "Power") == nil and
                 string.find(name, "POWER") == nil and                 
                 string.find(name, "Input") == nil and
                 string.find(name, "input") == nil and
                 string.find(name, "INPUT") == nil and
                 string.find(name, "Wet") == nil and
                 string.find(name, "wet") == nil and
                 string.find(name, "WET") == nil and
                 string.find(name, "Dry") == nil and
                 string.find(name, "dry") == nil and
                 string.find(name, "DRY") == nil and
                 string.find(name, "Oversampling") == nil and
                 string.find(name, "oice") == nil and
                 string.find(name, "solo") == nil and
                 string.find(name, "Solo") == nil and
                 string.find(name, "Mute") == nil and
                 string.find(name, "mute") == nil and
                 string.find(name, "FEEDBACK") == nil and
                 string.find(name, "eedback") == nil and
                 string.find(name, "ATTACK") == nil and
                 string.find(name, "ttack") == nil and
                 string.find(name, "dest") == nil and
                 string.find(name, "Dest") == nil and
                 string.find(name, "Mix") == nil and
                 string.find(name, "mix") == nil and
                 string.find(name, "olume") == nil 
                 then                 
                 reaper.TrackFX_SetParam(track, j-1, k-1, math.random(0,1))
               end  
            end  
          end
        reaper.TrackFX_SetEnabled(track, j-1, true)  
        break end
      end
    end  
  end
end 
