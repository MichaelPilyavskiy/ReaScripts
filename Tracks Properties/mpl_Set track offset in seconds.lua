-- @description Set track offset in seconds
-- @version 1.01
-- @author MPL 
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

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
local retval, retvals_csv = reaper.GetUserInputs( 'Set track offset in seconds)', 1, 'offset (in seconds)', 0 )
if retval and tonumber(retvals_csv) then
  for i = 1, reaper.CountSelectedTracks(0) do
    tr = reaper.GetSelectedTrack(0,i-1)
    reaper.SetMediaTrackInfo_Value( tr, 'I_PLAY_OFFSET_FLAG', 0 )
    reaper.SetMediaTrackInfo_Value( tr, 'D_PLAY_OFFSET', tonumber(retvals_csv) ) 
  end
end
end


  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true)   then 
      Undo_BeginBlock2( 0 )
      main()
      Undo_EndBlock2( 0, 'Set track offset in seconds', -1 )
  end
  