-- @description Set main input as a modulation for last touched parameter
-- @version 1.0
-- @author MPL
-- @changelog
--  init
  
  ----------------------------------------------------------------
  function main()
     retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
  -- modify chunk
  local modstr =
  '<PROGRAMENV '..paramnumber..[[ 0
  PARAMBASE 0.26
  LFO 0
  LFOWT 1 1
  AUDIOCTL 1
  AUDIOCTLWT 1 -1
  CHAN 1
  STEREO 2
  RMS 300 300
  DBLO -36
  DBHI 0
  X2 0.5
  Y2 0.5
>]]
     
    Data_ModifyMod(conf, data, tracknumber, fxnumber,paramnumber, modstr )
  end
  -----------------------------------------------
  function Data_ModifyMod(conf, data, trid, fx,param, addstr)
      local tr= GetTrack(0,trid-1)
      if not tr then return end
      local retval, minval, maxval = reaper.TrackFX_GetParam( tr, fx, param )
      local retval, tr_chunk = GetTrackStateChunk( tr, '', false )
      local fxGUID_check = TrackFX_GetFXGUID( tr, fx )
      for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
        local fxGUID = fxchunk:match('FXID (.-)\n')
        if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end
        if fxGUID:match(literalize(fxGUID_check):gsub('%s', '')) then
          local fxchunk_mod
          fxchunk_mod = fxchunk:gsub('%<PROGRAMENV '..param..' .-%>', '') -- erase existed assignment
          fxchunk_mod = fxchunk_mod:gsub('WAK', addstr..'\n'..'WAK') -- add string
          tr_chunk = tr_chunk:gsub(literalize(fxchunk), fxchunk_mod)
          local ret = SetTrackStateChunk( tr, tr_chunk, false )
          return
        end
      end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Install it via Reapack (Action: browse packages)', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_LoadVFv2') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then 
      Undo_BeginBlock2( 0 )
      main() 
      Undo_EndBlock2( 0, 'Set main input as a modulation for last touched parameter', -1 )
    end
  end