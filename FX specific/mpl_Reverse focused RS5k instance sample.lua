-- @description Reverse focused RS5k instance sample (render reversed and use as new source)
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

  local script_title = 'Reverse focused RS5k instance sample'
  --------------------------------------------------------------------- 
  function CheckFocusedRS5K()
    local retval, tracknumber, itemnumber, fxnumber = GetFocusedFX()
    if retval ~= 1 then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    if tracknumber ==0 then tr = GetMasterTrack(0) end
    if not tr then return end
    local retval1, buf = reaper.TrackFX_GetFXName( tr, fxnumber,'' )
    if not retval1 then return end
    local retval2, buf1 = reaper.TrackFX_GetParamName(  tr, fxnumber, 3, '' )
    if not retval2 or buf1~='Note range start' then return end
    return true, tr, fxnumber
  end
  ---------------------------------------------------------------------  
  function main()
    
    --get rs5k
      local ret, tr, fxnumber =  CheckFocusedRS5K()
      if not ret then return end
    -- get file
      local retval, file = reaper.TrackFX_GetNamedConfigParm( tr, fxnumber, 'FILE0' )
      if not (retval and file~= '' ) then return end
    -- insert media as new item
      SelectAllMediaItems( 0, false )
      reaper.InsertMedia( file, 1 )
    -- create inversed take
      Action(41051)--Item properties: Toggle take reverse
      Action(40362)--Item: Glue items, ignoring time selection
    -- get src name
      local item = GetSelectedMediaItem( 0, 0 )
      local take = GetActiveTake(item)
      local src = GetMediaItemTake_Source( take )
      local  filenamebuf = GetMediaSourceFileName( src, '' )
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'FILE0', filenamebuf )
      TrackFX_Show(  tr, fxnumber, 2 )
      TrackFX_Show(  tr, fxnumber, 3 )
      
      tr_par = GetMediaItem_Track( item )
      DeleteTrack( tr_par )
  end
   ------------------------------------------------------------------------------------------------------
   function Action(s, sectionID, ME )  
     if sectionID == 32060 and ME then 
       MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
      else
       Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
     end
   end  
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then 
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock(script_title, 1)
  end  