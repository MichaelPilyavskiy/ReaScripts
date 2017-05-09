-- @version 1.01
-- @author MPL
-- @changelog
--   + init
-- @description Assign audio input parameter modulation with last touched parameter
-- @website http://forum.cockos.com/member.php?u=70694

reaper.ClearConsole()
 function msg(s) reaper.ShowConsoleMsg(s) end
 
-------------------------------------------------------------------------------

function toBits(num)
    -- returns a table of bits, least significant first.
    local t={} -- will contain the bits
    while num>0 do
        rest=math.fmod(num,2)
        t[#t+1]=math.floor(rest)
        num=(num-rest)/2
    end
    return t
end  
  -------------------------------------------------------------------------------
  
 function SetParamMod(track, fx_id,  param_id)
  -- set channel count
    reaper.SetMediaTrackInfo_Value( track, 'I_NCHAN', 4 )
  
  --[[ set pin mapping
    local in_pin_L = reaper.TrackFX_GetPinMappings( track, fx_id, 0, 0 )
    local in_pin_L_bin = toBits(in_pin_L)
    in_pin_L_bin[3] = 1
    local in_pin_R = reaper.TrackFX_GetPinMappings( track, fx_id, 0, 1 )
    local in_pin_R_bin = toBits(in_pin_R)
    in_pin_R_bin[4] = 1
    
    for i =1, 4 do
      if not in_pin_R_bin[i] then in_pin_R_bin[i] = 0 end
      if not in_pin_L_bin[i] then in_pin_L_bin[i] = 0 end
    end
    
    local out_pin_L = tonumber( table.concat(in_pin_L_bin,''):reverse() , 2)
    local out_pin_R = tonumber( table.concat(in_pin_R_bin,''):reverse() , 2)
    
    reaper.TrackFX_SetPinMappings( track, fx_id, 0, 0, out_pin_L, 0 )
    reaper.TrackFX_SetPinMappings( track, fx_id, 0, 1, out_pin_R, 0 )]]
  
  if not track then return end
  
  -- split chunk into table
    local _, chunk = reaper.GetTrackStateChunk(track, '')
    local chunk_t = {}
    for line in chunk:gmatch("[^\n]+") do table.insert(chunk_t, line) end

  -- find FX chain  
    local br_count = 0
    local chain_lim_0, chain_lim_1, chain_open
    for i = 1, #chunk_t do
      if  chunk_t[i]:find('<FXCHAIN') then chain_open = true chain_lim_0 = i end
      if chain_open and chunk_t[i]:find('<') then br_count = br_count + 1 end
      if chain_open and chunk_t[i]:find('>') then br_count = br_count - 1 end
      if chain_open and br_count == 0 then chain_open = false chain_lim_1 = i end
    end  
    local FX_chain = table.concat(chunk_t, '\n', chain_lim_0, chain_lim_1 )
    
  -- get raw data of FX 
    local raw_FX = {}
    for raw in FX_chain:gmatch('BYPASS.-WAK %d') do raw_FX[#raw_FX+1] = raw end
    local param = reaper.TrackFX_GetParamNormalized( track, fx_id, param_id )
    
  -- modify chunk
local str_mod = 
'<PROGRAMENV '..param_id..[[ 0
PARAMBASE ]]..param..[[
LFO 0
LFOWT 1 1
AUDIOCTL 1
AUDIOCTLWT 1 -1
CHAN 2
STEREO 1
RMS 300 300
DBLO -24
DBHI 0
X2 0.5
Y2 0.5
>
]]
  
  if not raw_FX[fx_id+1]:find('<PROGRAMENV '..param_id) then 
    raw_FX[fx_id+1] = raw_FX[fx_id+1]:gsub('WAK', str_mod..'WAK')
  end
  
  -- set modified chunk
  local out_chunk =
    table.concat(chunk_t, '\n', 1, chain_lim_0 + 4)..'\n'..
    table.concat(raw_FX, '\n')..'\n'..
    table.concat(chunk_t, '\n', chain_lim_1, #chunk_t)
    
  
  reaper.SetTrackStateChunk(track, out_chunk, false)  
  --msg(out_chunk)
  
 end

------------------------------------------------------------------------------- 
   retval, tracknum, fx_id, param_id = reaper.GetLastTouchedFX()
   track  =  reaper.CSurf_TrackFromID( tracknum, false )
   SetParamMod(track, fx_id, param_id)
