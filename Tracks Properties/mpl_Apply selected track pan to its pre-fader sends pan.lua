-- @description Apply selected track pan to its pre-fader sends pan
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # sligtly cleanup code
--    # use all Undo flags
--    + Apply pan envelope to send pan envelope if any, obey dualpan envelopes

  function main()
    Undo_BeginBlock2( 0 )
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      ApplyPan(tr)
    end
    Undo_EndBlock( 'Apply track pan to pre-fader sends', 0xFFFFFFFF )
  end
  -----------------------------------------------------------------------------------------  
  function EnvExtrractPoints(env, env2)
    local t = {}
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    
    -- single pan env
    if not env2 then
      for ptidx = 1, CountEnvelopePoints( env ) do
        local srct = {GetEnvelopePoint( env, ptidx-1 )}
        t[#t+1] = {time = srct[2], value = srct[3], shape = srct[4], tension = srct[5], selected=srct[6]} 
      end
      return t
    end
    
    -- dual env pan
    for ptidx = 1, CountEnvelopePoints( env ) do
      local srct = {GetEnvelopePoint( env, ptidx-1 )}
      local time = srct[2]
      local L = srct[3]
      local retval, R, dVdS, ddVdS, dddVdS = Envelope_Evaluate( env2, time, SR_spls, 1 )
      local value = math.max(math.min(L+R, 1), -1) 
      t[#t+1] = {time = time, value = value, shape = srct[4], tension = srct[5], selected=srct[6]} 
    end
    for ptidx = 1, CountEnvelopePoints( env2 ) do
      local srct = {GetEnvelopePoint( env2, ptidx-1 )}
      local time = srct[2]
      local R = srct[3]
      local retval, L, dVdS, ddVdS, dddVdS = Envelope_Evaluate( env, time, SR_spls, 1 )
      local value = math.max(math.min(L+R, 1), -1) 
      t[#t+1] = {time = time, value = value, shape = srct[4], tension = srct[5], selected=srct[6]} 
    end
    return t
    
  end
-----------------------------------------------------------------------------------------    
  function ApplyPan(tr)
    local pan, pant
    if GetMediaTrackInfo_Value( tr, 'I_PANMODE') == 6 then     -- dual pan
       local L= GetMediaTrackInfo_Value( tr, 'D_DUALPANL')
       local R= GetMediaTrackInfo_Value( tr, 'D_DUALPANR')
       pan = math.max(math.min(L+R, 1), -1)
       local penvL = GetTrackEnvelopeByChunkName( tr, '<DUALPANENVL2' )
       local penvR = GetTrackEnvelopeByChunkName( tr, '<DUALPANENV2' )
       pant = EnvExtrractPoints(penvL,penvR)
      else
       pan = GetMediaTrackInfo_Value( tr, 'D_PAN' )
       local penv = GetTrackEnvelopeByChunkName( tr, '<PANENV2' ) -- general / = PANENV : preFX pan envelope
       pant = EnvExtrractPoints(penv)
    end
    
    
    -- apply sends pan
    for sendidx =1,  GetTrackNumSends( tr, 0 ) do
      if GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_SENDMODE' ) == 3 then -- if pre fader
        if #pant==0 then
          SetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_PAN', pan )
         else
          -- add send pan envelope
          local P_ENV = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_ENV:<PANENV' )
          if P_ENV then
            DeleteEnvelopePointRange( P_ENV, 0, math.huge ) -- clear
            for i = 1, #pant do
              reaper.InsertEnvelopePoint( P_ENV, pant[i].time, pant[i].value, pant[i].shape, pant[i].tension, pant[i].selected, true )
            end
            Envelope_SortPoints(P_ENV)
          end
        end
      end
    end
    TrackList_AdjustWindows( false )
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.08) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end 
  
  
  