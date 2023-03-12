-- @description Export RS5k sample into item on same track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


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
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.57) if ret then local ret2 = VF_CheckReaperVrs(6.77,true) if ret2 then 
    reaper.Undo_BeginBlock()
    main(track)
    reaper.Undo_EndBlock('Export RS5k sample into item on same track', 0xFFFFFFFF)
  end end
