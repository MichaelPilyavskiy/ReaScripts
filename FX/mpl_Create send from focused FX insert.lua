-- @description Create send from focused FX insert
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # respect send parameters
--   # forum link

  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  
  local defsendvol = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  get_ini_file() )})[2]
  local defsendflag = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  get_ini_file() )})[2]
    
  function msg(s)  ShowConsoleMsg(s..'\n') end
  function main()
    local ret, tracknumberOut, _, fxnumberOut = GetFocusedFX()
    if not ret or tracknumberOut < 1 or fxnumberOut < 0 then return end
    
    -- get src info
      local track = CSurf_TrackFromID( tracknumberOut, false )
      local _, chunk = GetTrackStateChunk(track, '')
      local fx_GUID = TrackFX_GetFXGUID( track, fxnumberOut )
      local matchGUID = fx_GUID:sub(0,9)
      local insert_chunk = 'BYPASS'..chunk:match('BYPASS(.-)'..matchGUID)..fx_GUID..'\nWAK 0'
      local _, fxname = TrackFX_GetFXName( track, fxnumberOut, '' )
    
    -- add new track
    InsertTrackAtIndex( tracknumberOut+1, true )
    local new_tr = GetTrack(0, tracknumberOut)
    local new_chunk = ({GetTrackStateChunk(new_tr , '')})[2]:sub(0,-3)..[[<FXCHAIN
SHOW 0
LASTSEL 0
DOCKED 0]]..'\n'..insert_chunk..'\n>\n>'
    local ret = SetTrackStateChunk(new_tr , new_chunk, false)
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', 'AUX '..fxname:match('[%:](.*)'):sub(2), 1 )
    
    -- remove old inssert fx
    if ret then SNM_MoveOrRemoveTrackFX( track, fxnumberOut, 0 ) end
    new_id = CreateTrackSend( track, new_tr )
    SetTrackSendInfo_Value( track, 0, new_id, 'D_VOL', defsendvol)
    SetTrackSendInfo_Value( track, 0, new_id, 'I_SENDMODE', defsendflag)
  end
  
  Undo_BeginBlock()
  main()
  Undo_EndBlock('Create send from focused FX insert', 0)