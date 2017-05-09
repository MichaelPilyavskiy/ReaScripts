-- @version 1.0
-- @author MPL
-- @changelog
--   + init release
-- @description Create modulation link on same track from stored buffer
-- @website http://forum.cockos.com/member.php?u=70694

function Load()
    src_fx = tonumber( reaper.GetExtState( 'copypaste_plugin_link', 'fxnumber')  )
    src_param = tonumber(  reaper.GetExtState( 'copypaste_plugin_link', 'paramnumber') ) 
    _, dest_tr, dest_fx, dest_param = reaper.GetLastTouchedFX()
    dest_tr = reaper.CSurf_TrackFromID( dest_tr, false )
    
  insert_chunk = 
[[
<PROGRAMENV ]]..dest_param..[[ 0
PARAMBASE 0
LFO 0
LFOWT 1 1
AUDIOCTL 0
AUDIOCTLWT 1 1
PLINK 1 ]]..src_fx..[[:-1  ]]..src_param..[[ 0
>
]]
  
  local _, chunk = reaper.GetTrackStateChunk(  dest_tr, '', false )
  dest_fxGUID = reaper.TrackFX_GetFXGUID( dest_tr, dest_fx):gsub('-','')
  local t= {} for line in chunk:gmatch('[^\n\r]+') do t[#t+1] = line end
  for i = 1, #t do  local line = t[i]  if line:gsub('-',''):match(dest_fxGUID) then fxguid_chunkpos = i break end end
  if fxguid_chunkpos then table.insert(t, fxguid_chunkpos+1, insert_chunk) end
  local out_chunk = table.concat(t, '\n')
  reaper.SetTrackStateChunk(  dest_tr, out_chunk, true )
  reaper.ClearConsole()
  --reaper.ShowConsoleMsg(out_chunk)
  end
  
  
  Load()
