-- @description Reset FX chain pin mapping
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about http://forum.cockos.com/showpost.php?p=2009857&postcount=3
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

  change_name = 0
  
  
  function SplitInstrumentTo34AfterFocusedFX()
    local retval, tracknumber, itemnumber, focusedfx = GetFocusedFX()
    local tr = CSurf_TrackFromID( tracknumber, false )
    if retval~=1 or not tr then return end    
    SetMediaTrackInfo_Value( tr, "I_NCHAN", 4 )
    instrid = TrackFX_GetInstrument( tr ) 
    startid = math.max(instrid,0)
    local str_out = ''
    for i = startid,  TrackFX_GetCount( tr )-1 do
      local retval, fxname = TrackFX_GetFXName( tr, i, '' )
      --if i < focusedfx then -- 1/2 before focused
        TrackFX_SetPinMappings( tr, i, 0, 0, 1, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 1, 2, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 3, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 0, 1, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 1, 2, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 3, 0, 0 )
     --   fxname = fxname:gsub('WET ', '')
        str_out = str_out..'#'..(i+1)..' '..fxname..': go to 1/2 channels\n'  
      --[[ else -- 3/4 after focused
        TrackFX_SetPinMappings( tr, i, 0, 0, 4, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 1, 8, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 0, 3, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 0, 4, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 1, 8, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 2, 0, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 3, 0, 0 )
        fxname = fxname:gsub('WET ', '')
        str_out = str_out..'#'..(i+1)..' '..fxname..': go to 3/4 channels\n'  
        fxname = 'WET '..fxname      
      end
      if change_name == 1 then SetFXName(tr, i, fxname) end
      
      if instrid >= 0 and i == instrid then -- send instrument to both 1/2 3/4
        TrackFX_SetPinMappings( tr, i, 1, 0, 5, 0 )
        TrackFX_SetPinMappings( tr, i, 1, 1, 10, 0 ) 
        str_out = str_out..'#'..(i+1)..' '..fxname..': go to 1-4 channels\n'         
      end]]
    end
    --MB(str_out, '', 0)
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(6,true) then SplitInstrumentTo34AfterFocusedFX() end
  