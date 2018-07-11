-- @description Route FX chain followed by focused FX to 3-4 pair
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about http://forum.cockos.com/showpost.php?p=2009857&postcount=3
-- @changelog
--    + init
--    + set track channels count to 4
--    + route instrument to 1-4 channels
--    + route plugins before focused FX to 1-2 pair
--    + route plugins after focused FX to 3-4 pair
--    + rename plugins after focused FX to 3-4 pair to "WET" (follow original request, can be disabled by change_name=0)
--    + add loser`s 3-band joiner



  change_name = 1
  
  
  function SplitInstrumentTo34AfterFocusedFX()
    local retval, tracknumber, itemnumber, focusedfx = GetFocusedFX()
    local tr = CSurf_TrackFromID( tracknumber, false )
    if retval~=1 or not tr then return end    
    SetMediaTrackInfo_Value( tr, "I_NCHAN", 4 )
    instrid = TrackFX_GetInstrument( tr ) 
    startid = math.max(instrid,0)
    for i = startid,  TrackFX_GetCount( tr )-1 do
      local retval, fxname = TrackFX_GetFXName( tr, i, '' )
      if i < focusedfx then -- 1/2 before focused
        TrackFX_SetPinMappings( tr, i, 0, 0, 1, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 1, 2, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 3, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 0, 1, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 1, 2, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 3, 0, 0 )
        fxname = fxname:gsub('WET ', '')
       else -- 3/4 after focused
        TrackFX_SetPinMappings( tr, i, 0, 0, 4, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 1, 8, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 3, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 0, 4, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 1, 8, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 3, 0, 0 )
        fxname = fxname:gsub('WET ', '')
        fxname = 'WET '..fxname        
      end
      if change_name == 1 then SetFXName(tr, i, fxname) end
      
      if instrid >= 0 and i == instrid then -- send instrument to both 1/2 3/4
        TrackFX_SetPinMappings( tr, i, 1, 0, 5, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 1, 10, 0 )        
      end
      
    end
    
    -- add loser: 3-Band Joiner
      local joinerFXid = TrackFX_AddByName( tr, '3BandJoiner', false, 1 )
        TrackFX_SetPinMappings( tr, joinerFXid, 0, 0, 1, 0 )
        TrackFX_SetPinMappings( tr, joinerFXid, 0, 1, 2, 0 )
        TrackFX_SetPinMappings( tr, joinerFXid, 0, 2, 4, 0 )
        TrackFX_SetPinMappings( tr, joinerFXid, 0, 3, 8, 0 )
        TrackFX_SetPinMappings( tr, joinerFXid, 1, 0, 1, 0 )
        TrackFX_SetPinMappings( tr, joinerFXid, 1, 1, 2, 0 )
        TrackFX_SetPinMappings( tr, joinerFXid, 1, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, joinerFXid, 1, 3, 0, 0 )
  end
-----------------------------------------------------------------------------------------  
    function CheckFunctions(str_func)
      local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
      local f = io.open(SEfunc_path, 'r')
      if f then
        f:close()
        dofile(SEfunc_path)
        
        if not _G[str_func] then 
          reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
         else
          Undo_BeginBlock2( 0 )
          SplitInstrumentTo34AfterFocusedFX()
          Undo_EndBlock( 'Route plugins to 3-4 pair', -1 )
        end        
       else
        MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
      end  
    end
  --------------------------------------------------------------------
  CheckFunctions('SetFXName')     
  