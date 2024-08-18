-- @description Export RS5k sample into item on same track
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


function main()
    local ret, tracknumberOut, _, fx = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    local ret1, scrpath = TrackFX_GetNamedConfigParm(track, fx, "FILE0",1)
    if not ret1 then return end
    
    -- get data
    local retval, vol = reaper.TrackFX_GetFormattedParamValue( track, fx, 0 ) 
    local pan = TrackFX_GetParamNormalized( track, fx, 1 )
    local notest = TrackFX_GetParamNormalized( track, fx, 13 )
    local noteend = TrackFX_GetParamNormalized( track, fx, 14 )
    local pitch = TrackFX_GetParamNormalized( track, fx, 15 )
    --[[local attack = TrackFX_GetParamNormalized( track, fx, 9 )
    local release = TrackFX_GetParamNormalized( track, fx, 10)
    local decay = TrackFX_GetParamNormalized( track, fx, 24)
    local sustain = TrackFX_GetParamNormalized( track, fx, 25)]]
    
    -- add item/take
    local it = AddMediaItemToTrack( track )
    local tk = AddTakeToMediaItem( it )
    local pcm =  PCM_Source_CreateFromFile( scrpath )
    SetMediaItemTake_Source( tk, pcm )
    local srclen, lengthIsQN = reaper.GetMediaSourceLength( pcm )
    local editcurpos = GetCursorPosition()
    SetMediaItemInfo_Value( it, 'D_POSITION', editcurpos )
    
    -- set item properties
    SetMediaItemInfo_Value( it, 'D_LENGTH', srclen*(noteend-notest))
    SetMediaItemTakeInfo_Value( tk, 'D_STARTOFFS',notest*srclen)
    SetMediaItemTakeInfo_Value( tk, 'D_PAN', pan*2-1)
    SetMediaItemTakeInfo_Value( tk, 'D_PITCH', pitch*160-80)
    
    reaper.UpdateItemInProject( it )
  end
  ---------------------------------------------------   
  if VF_CheckReaperVrs(6.77,true)then 
    reaper.Undo_BeginBlock()
    main(track)
    reaper.Undo_EndBlock('Export RS5k sample into item on same track', 0xFFFFFFFF)
  end 
