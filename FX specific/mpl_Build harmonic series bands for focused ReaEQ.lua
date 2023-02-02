-- @description Build harmonic series bands for focused ReaEQ
-- @version 1.07
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # overhaul, code cleanup
--    # using native API for parameter linking
--    # remove all parameters except setting base frequency
--    # change type to band
--    + Improve BW link offset / scale
  
  
  
  -- NOT reaper NOT gfx
  -----------------------------------------------------------------------------
  function MPL_BuildEQReduce(freq)
    if not freq then return end
    
    -- handle reaEQ
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX()
    if not (retval ==1 and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    
    -- init params
      TrackFX_SetParamNormalized( tr, fx, 0, F2ReaEQVal(freq)) -- F
      TrackFX_SetParamNormalized( tr, fx, 1, 0.25) -- G
      TrackFX_SetParamNormalized( tr, fx, 2, .01) -- Q
      
    -- cnt bands
      local bands_cnt=0
      for band_id = 0, 50 do
        local ret,str = TrackFX_GetNamedConfigParm( tr, fx, 'BANDTYPE'..band_id )
        if not ret then break end
        bands_cnt = bands_cnt + 1
      end
    -- set bands  
      for band_id = 1, bands_cnt do
        -- freq
        local Fid = band_id*3 + 0
        TrackFX_SetParamNormalized( tr, fx, Fid, F2ReaEQVal(freq * (band_id+1) )) 
        -- G
        local Gid = band_id*3 + 1
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Gid..'.mod.active', 1 )
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Gid..'.plink.active', 1 )
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Gid..'.plink.effect', fx )
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Gid..'.plink.param', 1 )
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Gid..'.plink.scale', 1- ( band_id / bands_cnt) )
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Gid..'.mod.baseline', 0.25* ( band_id / bands_cnt) )
        -- Q
        local Qid = band_id*3 + 2
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Qid..'.mod.active', 1 )
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Qid..'.plink.active', 1 )
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Qid..'.plink.effect', fx )
        TrackFX_SetNamedConfigParm( tr, fx, 'param.'..Qid..'.plink.param', 2 )
      end
  end
  ----------------------------------------------------------------------------- 
  function ReaEQVal2F(x) 
    local curve = (math.exp(math.log(401)*x) - 1) * 0.0025
    local freq = (24000 - 20) * curve + 20
    return freq
  end
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ----------------------------------------------------------------------------- 
  function ParseDbVol(out_str_toparse)
    if not out_str_toparse or not out_str_toparse:match('%d') then return 0 end
    if out_str_toparse:find('1.#JdB') then return 0 end
    out_str_toparse = out_str_toparse:lower():gsub('db', '')
    local out_val = tonumber(out_str_toparse)
    if not out_val then return end
    out_val = lim(out_val, -150, 12)
    out_val = WDL_DB2VAL(out_val)
    if out_val <= 1 then out_val = out_val / 2 else out_val = 0.5 + out_val / 8 end
    return out_val
  end
  ----------------------------------------------------------------------------- 
  function F2ReaEQVal(F) 
    local curve =  (F - 20) / (24000 - 20)
    local x = (math.log((curve +0.0025) / 0.0025,math.exp(1) ))/math.log(401)
    return x
  end 
  ----------------------------------------------------------------------
  function main()
    local retval, freq = GetUserInputs('Build harmonic bands', 1, 'Base frequency (Hz)', 50)
    if retval and freq ~= '' then 
      freq = freq:match('[%d%p]+')
      if not freq then return end
      freq = tonumber(freq)
      if not freq then return end
      MPL_BuildEQReduce(freq)
    end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.15) if ret then local ret2 = VF_CheckReaperVrs(6.37,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Build harmonic series bands for focused ReaEQ', 0xFFFFFFFF )
  end end
  