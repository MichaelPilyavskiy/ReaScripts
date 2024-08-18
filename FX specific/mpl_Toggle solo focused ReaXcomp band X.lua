-- @description Toggle solo focused ReaXcomp band X
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--   [main] . > mpl_Toggle solo focused ReaXcomp band 1.lua
--   [main] . > mpl_Toggle solo focused ReaXcomp band 2.lua
--   [main] . > mpl_Toggle solo focused ReaXcomp band 3.lua
--   [main] . > mpl_Toggle solo focused ReaXcomp band 4.lua
--   [main] . > mpl_Toggle solo focused ReaXcomp band 5.lua
--   [main] . > mpl_Toggle solo focused ReaXcomp band 6.lua
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
  
  
  -----------------------------------------------------------------------------
  function MPL_SoloXCompBand(solo_id)
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX() 
    if not (retval  and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local retval, buf = TrackFX_GetFXName( tr, fx, '' )
    if not buf:lower():match('reaxcomp') then return end
    
    local num_params = TrackFX_GetNumParams( tr, fx )
    local bands_cnt =  math.floor((num_params-2)/12)
    
    tbands = {}
    solo_cnt = 0
    for band = 1, bands_cnt do
      local solo_state = math.floor(TrackFX_GetParamNormalized(  tr, fx, (band-1)*12+11 ))
      solo_cnt = solo_cnt + solo_state
      tbands[band] = solo_state
    end
    
    if not tbands[solo_id] then return end -- prevent solo nonexisted band
    
    if tbands[solo_id] == 1 and bands_cnt - solo_cnt >= 1 then 
       for band = 1, bands_cnt do TrackFX_SetParamNormalized(  tr, fx, (band-1)*12+11, 1 ) end
      elseif tbands[solo_id] == 0 or bands_cnt == solo_cnt then
       for band = 1, bands_cnt do TrackFX_SetParamNormalized(  tr, fx, (band-1)*12+11, 0 ) end
       TrackFX_SetParamNormalized(  tr, fx, (solo_id-1)*12+11, 1 )
    end
  end
  
  if VF_CheckReaperVrs(5.95, true) then 
      local band_id = tonumber(({reaper.get_action_context()})[2]:match("band (%d+).lua"))
      MPL_SoloXCompBand(band_id) 
    end