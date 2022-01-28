-- @description Sample focused FX to RS5k
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  -------------------------------------------------------------------  
  function main()
    
    local retval, retvals_csv = reaper.GetUserInputs( 'MPL Sample focused FX', 3, 'note length (sec), lowest note, highest note', '0.5,36,48' )
    if not retval then return end
    local notelen,min_note,max_note = retvals_csv:match('([%d%.]+),([%d%.]+),([%d%.]+)')
    if not (notelen and min_note and max_note) then return end
    notelen,min_note,max_note = tonumber(notelen),tonumber(min_note),tonumber(max_note)
    if not (notelen and min_note and max_note) then return end
    
    --[[local notelen = 0.5
    local min_note = 36
    local max_note = 48]]
    
    local t = cust_GetFocusedFX()
    if not t then return end
    local track = t.tr
    
    Action(40289) -- Item: Unselect (clear selection of) all items
    for i = min_note, max_note do
      local item = CreateNewMIDIItemInProj(track, notelen*i, notelen*(i +1))
      local take = GetActiveTake(item)
      local startppqpos =  MIDI_GetPPQPosFromProjTime( take, notelen*i )
      local endppqpos = MIDI_GetPPQPosFromProjTime( take, notelen*(i +1) )
      MIDI_InsertNote( take, false, false, startppqpos, endppqpos, 0, i, max_note, false )
      SetMediaItemSelected( item, true )
      Action(40209) -- Item: Apply track/take FX to items
      local take = GetActiveTake(item)
      local source =  GetMediaItemTake_Source( take )
      local filenamebuf = reaper.GetMediaSourceFileName( source )
      local fx = TrackFX_AddByName( track, 'ReaSamplOmatic5000', false, -1 )
      TrackFX_SetNamedConfigParm( track, fx, 'FILE'..i, filenamebuf )
      DeleteTrackMediaItem( track, item )
      -- # 3/4 note range 
        TrackFX_SetParam( track, fx, 3, i * 1/128 )
        TrackFX_SetParam( track, fx, 4, i * 1/128 )
    end
  end
  ---------------------------------------------------------------------
  function cust_GetFocusedFX()
    local retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX2()
    if retval&1~=1 then return end
    local tr, trGUID, fxGUID, param, paramname, ret, fxname,paramformat
    tr = CSurf_TrackFromID( tracknumber, false )
    trGUID = GetTrackGUID( tr )
    fxGUID = TrackFX_GetFXGUID( tr, fxnumber )
    retval, buf = reaper.GetTrackName( tr )
    ret, fxname = TrackFX_GetFXName( tr, fxnumber, '' )
    return {tr = tr,
            trnumber=tracknumber,
            trGUID = trGUID,
            fxGUID = fxGUID,
            trname = buf,
            paramnumber=paramnumber,
            paramname=paramname,
            paramformat = paramformat,
            paramval=paramval,
            fxnumber=fxnumber,
            fxname=fxname
            }
  end
  -------------------------------------------------------------------  
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.8) if ret then local ret2 = VF_CheckReaperVrs(5.95,true) if ret2 then
    main()
  end end