-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Set RS5k sample start offset based on sample peak
-- @noindex
-- @changelog
--    + init


function main()
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    ret, fn = reaper.TrackFX_GetNamedConfigParm(track, fxnumberOut, "FILE0")
    if not ret then return end
    
    local data = {}
    
    local wind = 0.002
    local bsz = 2
    local buf = new_array(bsz)
    local pcmsrc = PCM_Source_CreateFromFile( fn )
    local peakrate =  GetMediaSourceSampleRate( pcmsrc )
    local numchannels = 1
    local numsamplesperchannel = 1
    local want_extra_type = 0
    local srclen, lengthIsQN = GetMediaSourceLength( pcmsrc )
    for starttime = 0, srclen, wind do
      PCM_Source_GetPeaks( pcmsrc, peakrate, starttime, numchannels, numsamplesperchannel, want_extra_type, buf )
      data[#data+1] = buf[1]
    end
    PCM_Source_Destroy( pcmsrc )
    
    local max_val = 0
    for i = 1, #data do data[i] = math.abs(data[i]) max_val = math.max(max_val, data[i]) end
    for i = 1, #data do data[i] = data[i]/max_val end -- normalize
    
    -- manage to get peak
      local peaktime_normal = 0
      for i = 1, #data do if data[i] == 1 then peaktime_normal = i*wind / srclen break end end
      
    
    if peaktime_normal ~= 0 then reaper.TrackFX_SetParamNormalized( track, fxnumberOut, 13, peaktime_normal ) end
  end

  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.0) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then Undo_BeginBlock() main() Undo_EndBlock('Set RS5k sample start offset based on sample peak', 1) end end