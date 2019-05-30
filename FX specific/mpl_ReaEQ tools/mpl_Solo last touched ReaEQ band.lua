-- @description Solo last touched ReaEQ band
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    # header

  -- NOT reaper NOT gfx
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end

  -----------------------------------------------------------------------------
  function ParseExtState(extstate)
    if not extstate or extstate == '' then return end
    local t = { trGUID= extstate:match('trGUID%s(.-)\n'),
                fxGUID= extstate:match('fxGUID%s(.-)\n'),
                cur_band= tonumber(extstate:match('cur_band%s(.-)\n')),
                bands = {}}
    local bands_str = extstate:match('bands ([%d%s]+)')
    local b = {}
    for pair in bands_str:gmatch('[^%s]+')do b[#b+1] = tonumber(pair) end
    if math.fmod(#b,2) ~= 0 then return end
    for i = 2, #b, 2 do
      t.bands[i/2] = {b_type = b[i-1], b_state = b[i]}
    end
    --if bands_cnt ~= #t.bands then return end
    return t
  end
  -----------------------------------------------------------------------------
  function MPL_SoloReaEqBand(extstate)
    local  retval, tracknumber, fx, paramnumber = GetLastTouchedFX() 
    if not (retval  and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    local num_params = TrackFX_GetNumParams( tr, fx )
    if paramnumber >= num_params -2 then return end
    local bands_cnt =  math.floor((num_params-2)/3)
    local trGUID =GetTrackGUID( tr )
    local fxGUID =TrackFX_GetFXGUID( tr, fx )
          
    -- store data
    if extstate == '' then
      local cur_band  = math.floor(paramnumber/3)+1
      local str_state = ''
      str_state = 'trGUID '..trGUID..'\nfxGUID '..fxGUID..'\ncurband '..cur_band..'\nbands'
      for i = 1, bands_cnt do
        local retval, b_type = TrackFX_GetNamedConfigParm( tr, fx, 'BANDTYPE'..i-1 )
        b_type = tonumber(b_type)
        local retval, b_state = TrackFX_GetNamedConfigParm( tr, fx, 'BANDENABLED'..i-1 )
        str_state = str_state..' '..b_type..' '..b_state
        if i == cur_band then
          --msg(b_type)
          
          TrackFX_SetNamedConfigParm( tr, fx, 'BANDENABLED'..i-1, 1 )
         else
          TrackFX_SetNamedConfigParm( tr, fx, 'BANDENABLED'..i-1, 0 )
        end
      end 
      -- SOLO band
      SetExtState( 'MPL_SOLOEQBAND', 'state', str_state, false )
      
    end
    
    if extstate ~= '' then
      data = ParseExtState(extstate)
      if not data or not data.trGUID or not data.fxGUID then EraseState() return end
      tr_ext =  BR_GetMediaTrackByGUID( 0, data.trGUID )
      if not tr_ext then EraseState() return end
       fx_ext = GetFXByGUID(tr_ext,data.fxGUID )
      if not fx_ext then EraseState() return end
      for i = 1, #data.bands do 
        TrackFX_SetNamedConfigParm( tr_ext, fx_ext, 'BANDTYPE'..i-1, data.bands[i].b_type )
        TrackFX_SetNamedConfigParm( tr_ext, fx_ext, 'BANDENABLED'..i-1, data.bands[i].b_state ) 
      end
      EraseState()
    end
  end
  ----------------------------------------------------------------------------- 
  function EraseState() 
    DeleteExtState( 'MPL_SOLOEQBAND', 'state', true ) 
  end
  ----------------------------------------------------------------------------- 
  function GetFXByGUID(track, FX_GUID)
    if not track then return end
    for i = 1, TrackFX_GetCount( track ) do
      local fxGUID = TrackFX_GetFXGUID( track, i-1 )
      if fxGUID == FX_GUID then return i-1 end
    end
  end
  ---------------------------------------------------
  function CheckReaperVrs(rvrs) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0)
      return
     else
      return true
    end
  end
  ----------------------------------------------------------------------------- 
  --ClearConsole() 
  --EraseState() 
  local ret = CheckReaperVrs(5.81, 5)
  if ret then 
    local extstate = GetExtState( 'MPL_SOLOEQBAND', 'state' )
    MPL_SoloReaEqBand(extstate)
   else
    MB('Script requre REAPER 5.81pre5+','Solo ReaEQ band',0)
  end
  
  
  