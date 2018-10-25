-- @version 1.02
-- @author MPL
-- @description Send selected tracks to track under mouse cursor (channel 3-4)
-- @changelog
--    # adjust channels count for destination track if need [rmmedia.ru/threads/118091/page-77#post-2289226]
-- @website http://forum.cockos.com/showthread.php?t=188335    

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  local script_title = "Send selected tracks to track under mouse cursor (channel 3-4)"  
  local defsendvol = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  reaper.get_ini_file() )})[2]
  local defsendflag = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  reaper.get_ini_file() )})[2]
  ---------------------------------------------------------------------
  function GetDestTrGUID()
    local t = {}
    local _, segment = BR_GetMouseCursorContext()
    if segment == "track" then
      local src_track = BR_GetMouseCursorContext_Track()
      t[1] = GetTrackGUID( src_track )      
    end  
    return t   
  end
  ---------------------------------------------------------------------
  function GetSrcTrGUID()
    local t = {}
    for i = 1, CountSelectedTracks(0) do
      tr = GetSelectedTrack(0,i-1)
      t[#t+1] = GetTrackGUID( tr )
    end  
    return t 
  end
  --------------------------------------------------------------------- 
  function Check_t(src_t, dest_t)
    for i = 1, #src_t do
      local chGUID = src_t[i]:gsub('%p', '')
      for i = #dest_t, 1, -1 do
        if dest_t[i]:gsub('%p', '') == chGUID then
          table.remove(dest_t,i)
          break
        end
      end
    end
  end
  ---------------------------------------------------------------------   
  function AddSends(src_t, dest_t)
    for i = 1, #src_t do
      local src_tr =  BR_GetMediaTrackByGUID( 0, src_t[i] )
      for i = 1, #dest_t do
        local dest_tr =  BR_GetMediaTrackByGUID( 0, dest_t[i] )
        local new_id = CreateTrackSend( src_tr, dest_tr )
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', defsendflag)
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 2)
        if GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN'  ) == 2 then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', 4  ) end
      end
    end
  end
  ---------------------------------------------------------------------  
  function main()
    local src_GUID = GetSrcTrGUID()
    local dest_GUID = GetDestTrGUID()    
    Check_t(src_GUID,dest_GUID)
    if #src_GUID < 1 or #dest_GUID < 1 then return end
    AddSends(src_GUID,dest_GUID)
    TrackList_AdjustWindows(false)
  end 
  ---------------------------------------------------------------------    
  Undo_BeginBlock()
  main()
  Undo_EndBlock(script_title, 0) 