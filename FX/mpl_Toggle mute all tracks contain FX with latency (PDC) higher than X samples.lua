-- @description Toggle mute all tracks contain FX with latency (PDC) higher than X samples
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Toggle mute all tracks contain FX with latency (PDC) higher than 256 samples.lua
--    [main] . > mpl_Toggle mute all tracks contain FX with latency (PDC) higher than 512 samples.lua
--    [main] . > mpl_Toggle mute all tracks contain FX with latency (PDC) higher than 1024 samples.lua
--    [main] . > mpl_Toggle mute all tracks contain FX with latency (PDC) higher than 2048 samples.lua
--    [main] . > mpl_Toggle mute all tracks contain FX with latency (PDC) higher than 4096 samples.lua
--    [main] . > mpl_Toggle mute all tracks contain FX with latency (PDC) higher than 8192 samples.lua
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

  --NOT gfx NOT reaper
  --------------------------------------------------------------------
  function main(spl_thrshld)
     state =  GetExtState( 'MPLPDCTOGGLETR', 'STATE' )
    if not state or state == '' or tonumber(state)==0 then 
      
      -- bypass 
      local str = ''
      for tr_id = 1, CountTracks(0) do
        local track = GetTrack(0,tr_id-1)
        for fx_id = 1,  TrackFX_GetCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, fx_id-1, 'pdc' )
          if retval and tonumber(buf) and tonumber(buf) > spl_thrshld then 
            
            local is_mute =  GetMediaTrackInfo_Value( track, 'B_MUTE' )
            str = str..'\n'.. GetTrackGUID( track )..' '..is_mute
            SetMediaTrackInfo_Value( track, 'B_MUTE',1 )
            
            goto nexttrack
          end 
        end
        ::nexttrack::
      end
      SetExtState( 'MPLPDCTOGGLETR', 'STATE', 1, true )
      SetProjExtState( 0, 'MPLPDCTOGGLETR', 'TRGUIDS', str )
      
     else
      
      local ret, str = GetProjExtState( 0, 'MPLPDCTOGGLETR', 'TRGUIDS' )
       t = {}
      for line in str:gmatch('[^\r\n]+') do local GUID, mute = line:match('({.*}) (%d)') t[GUID] = tonumber(mute) end      
      
      for tr_id = 1, CountTracks(0) do
        local track = GetTrack(0,tr_id-1)
        local GUID = GetTrackGUID( track )
        if t[GUID] then SetMediaTrackInfo_Value( track, 'B_MUTE', t[GUID]) end
      end     
      SetExtState( 'MPLPDCTOGGLETR', 'STATE', 0, true )
    end
  end 
-------------------------------------------------------------------- 
  local cnt_spls = ({reaper.get_action_context()})[2]:match('([%d]+) samples')
  if not (cnt_spls and tonumber(cnt_spls)) then cnt_spls = 256 else cnt_spls = tonumber(cnt_spls) end 
  if VF_CheckReaperVrs(5.95, true)then  main(cnt_spls) end