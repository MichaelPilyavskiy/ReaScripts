-- @version 1.05
-- @author MPL
-- @description Send selected tracks to track under mouse cursor
-- @changelog
--    # use miltichannel send if source track channel count > 2
--    # force destination channel track count if it is lower than source track channel count
--    # prevent adding already existed send 
--    # fix send mode when MIDI send desabled
-- @website http://forum.cockos.com/showthread.php?t=188335    

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  local script_title = "Send selected tracks to track under mouse cursor"  
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
      local tr = GetSelectedTrack(0,i-1)
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
      local src_tr_ch = GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
      for i = 1, #dest_t do
          local dest_tr =  BR_GetMediaTrackByGUID( 0, dest_t[i] )
          
          -- increase ch up to src track
          local dest_tr_ch = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
          if dest_tr_ch < src_tr_ch then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end
          
          -- check for existing sends
          local is_exist = false
          for i =1,  GetTrackNumSends( src_tr, 0 ) do
            local dest_tr_check = BR_GetMediaTrackSendInfo_Track( src_tr, 0, i-1, 1 )
            if dest_tr_check == dest_tr then is_exist = true break end
          end
          
          if not is_exist then 
            local new_id = CreateTrackSend( src_tr, dest_tr )
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', defsendflag&255)
             
            if dest_tr_ch == 2 then 
              SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',0)
             else
              SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',0|(1024*math.floor(src_tr_ch/2)))
            end
            --SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 0)
          
        end
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