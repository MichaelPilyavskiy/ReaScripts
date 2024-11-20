-- @description Toggle "Reference" track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
    ---------------------------------------------------
  function main() 
    -- get track by name
    for i = 1, CountTracks(-1) do
      local tr = GetTrack(-1,i-1)
      local ret, trname = reaper.GetTrackName(tr)
      if trname:lower():match('reference') then
        local solo = reaper.GetMediaTrackInfo_Value(tr, 'I_SOLO') 
        if solo > 0 then 
          SetMediaTrackInfo_Value(tr, 'I_SOLO', 0) 
          SetMediaTrackInfo_Value(tr, 'B_MUTE', 1) 
         else
          SetMediaTrackInfo_Value(tr, 'I_SOLO', 2) 
          SetMediaTrackInfo_Value(tr, 'B_MUTE', 0) 
        end
        break
      end
    end
  
  
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6,true) then 
    defer(main)
  end 