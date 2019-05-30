-- @description Port focused ReaEQ bands to spectral edits on selected items
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    # header

  -- NOT reaper NOT gfx
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  function MPL_PortReaEQtoSpectralPeaks()
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX()
    if not (retval ==1 and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    local num_params = TrackFX_GetNumParams( tr, fx )
    local bands = {}
    for param = 1, num_params - 2, 3 do
      local retval, db_gain  = TrackFX_GetFormattedParamValue( tr, fx, param, '' )
      local retval, freq = TrackFX_GetFormattedParamValue( tr, fx, param-1,'')
      local retval, N = TrackFX_GetFormattedParamValue( tr, fx, param+1,'')
      local retval_type, b_type = TrackFX_GetNamedConfigParm( tr, fx, 'BANDTYPE'..(-1+(param+2)/3) )
      local retval, b_enabled = TrackFX_GetNamedConfigParm( tr, fx, 'BANDENABLED'..(-1+(param+2)/3) )      
      freq = math.floor(tonumber(freq) )
      db_gain = tonumber(db_gain) if not db_gain then db_gain = -150 end
      N = tonumber(N)
      if N < 2 and math.abs(db_gain) > 1 then 
        if (not retval_type) or 
          (retval_type and 
          (tonumber(b_type) == 8  or tonumber(b_type) == 9 or tonumber(b_type) == 2)
          and tonumber(b_enabled) == 1) then
          local Q = math.sqrt(2^N) / (2^N - 1 )
          bands[#bands+1]  = {  F = freq,
                                G = db_gain,
                                Q = math.floor(freq/Q)}
        end
      end
    end
    
      MPL_SetSpectralPeak(bands)
  end  
  -----------------------------------------------------------------------------
  function ParseDbVol(out_str_toparse)
    if not out_str_toparse or not out_str_toparse:match('%d') then return 0 end
    if out_str_toparse:find('1.#JdB') then return 0 end
    out_str_toparse = out_str_toparse:lower():gsub('db', '')
    local out_val = tonumber(out_str_toparse) 
    if not out_val then return 0 end
    out_val = lim(out_val, -150, 12)
    out_val = WDL_DB2VAL(out_val)
    return out_val
  end
  -----------------------------------------------------------------------------
  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end
  function WDL_VAL2DB(x, reduce)
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else 
      if reduce then 
        return string.format('%.2f', v)
       else 
        return v 
      end
    end
  end
  -----------------------------------------------------------------------------
   function lim(val, min,max) --local min,max 
     if not min or not max then min, max = 0,1 end 
     return math.max(min,  math.min(val, max) ) 
   end
  -------------------------------------------------------
  function GetSpectralData(item)
    if not item then return end
    local chunk = ({GetItemStateChunk( item, '', false )})[2]
    -- parse chunk
    local tk_cnt = 0
    local SE ={}
    for line in chunk:gmatch('[^\r\n]+') do 
    
      if line:match('<SOURCE') then 
        tk_cnt =  tk_cnt +1 
        SE[tk_cnt]= {}
      end 
        
      if line:match('SPECTRAL_CONFIG') then
        local sz = line:match('SPECTRAL_CONFIG ([%d]+)')
        if sz then sz = tonumber(sz) end
        SE[tk_cnt].FFT_sz = sz
      end
            
      if line:match('SPECTRAL_EDIT') then  
        if not SE[tk_cnt].edits then SE[tk_cnt].edits = {} end
        local tnum = {} 
        for num in line:gmatch('[^%s]+') do if tonumber(num) then tnum[#tnum+1] = tonumber(num) end end
        SE[tk_cnt].edits [#SE[tk_cnt].edits+1] =       {pos = tnum[1],
                       len = tnum[2],
                       gain = tnum[3],
                       fadeinout_horiz = tnum[4], -- knobleft/2 + knobright/2
                       fadeinout_vert = tnum[5], -- knoblower/2 + knobupper/2
                       freq_low = tnum[6],
                       freq_high = tnum[7],
                       chan = tnum[8], -- -1 all 0 L 1 R
                       bypass = tnum[9], -- bypass&1 solo&2
                       gate_threshold = tnum[10],
                       gate_floor = tnum[11],
                       compress_threshold = tnum[12],
                       compress_ratio = tnum[13],
                       unknown1 = tnum[14],
                       unknown2 = tnum[15],
                       fadeinout_horiz2 = tnum[16],  -- knobright - knobleft
                       fadeinout_vert2 = tnum[17]} -- knobupper - knoblower
      end
                       
    end
    return true, SE
  end
  ---------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end
  -------------------------------------------------------
  function SetSpectralData(item, data)
    if not item then return end
    local chunk = ({GetItemStateChunk( item, '', false )})[2]
    chunk = chunk:gsub('SPECTRAL_CONFIG.-\n', '')
    chunk = chunk:gsub('SPECTRAL_EDIT.-\n', '')
    --msg(chunk)
    local open
    local t = {} 
    for line in chunk:gmatch('[^\r\n]+') do t[#t+1] = line end
    local tk_cnt = 0 
    for i = 1, #t do
      if t[i]:match('<SOURCE') then 
        tk_cnt = tk_cnt + 1 
        open = true 
      end
      if open and t[i]:match('>') then
      
        local add_str = ''
        
        if data[tk_cnt] 
          and data[tk_cnt].edits 
          and GetTake( item, tk_cnt-1 )
          and not TakeIsMIDI(GetTake( item, tk_cnt-1 ))
          then
          for edit_id in pairs(data[tk_cnt].edits) do
            if not data[tk_cnt].FFT_sz then data[tk_cnt].FFT_sz = 1024 end
            add_str = add_str..'SPECTRAL_EDIT '
              ..data[tk_cnt].edits[edit_id].pos..' '
              ..data[tk_cnt].edits[edit_id].len..' '
              ..data[tk_cnt].edits[edit_id].gain..' '
              ..data[tk_cnt].edits[edit_id].fadeinout_horiz..' '
              ..data[tk_cnt].edits[edit_id].fadeinout_vert..' '
              ..data[tk_cnt].edits[edit_id].freq_low..' '
              ..data[tk_cnt].edits[edit_id].freq_high..' '
              ..data[tk_cnt].edits[edit_id].chan..' '
              ..data[tk_cnt].edits[edit_id].bypass..' '
              ..data[tk_cnt].edits[edit_id].gate_threshold..' '
              ..data[tk_cnt].edits[edit_id].gate_floor..' '
              ..data[tk_cnt].edits[edit_id].compress_threshold..' '
              ..data[tk_cnt].edits[edit_id].compress_ratio..' '
              ..data[tk_cnt].edits[edit_id].unknown1..' '
              ..data[tk_cnt].edits[edit_id].unknown2..' '
              ..data[tk_cnt].edits[edit_id].fadeinout_horiz2..' '
              ..data[tk_cnt].edits[edit_id].fadeinout_vert2..' '
              ..'\n'
          add_str = add_str..'SPECTRAL_CONFIG '..data[tk_cnt].FFT_sz ..'\n'
          end        
        end
        
        t[i] = t[i]..'\n'..add_str
        open = false
      end
    end   
    local out_chunk = table.concat(t, '\n')
    SetItemStateChunk( item, out_chunk, false )
    UpdateItemInProject( item )
  end
  -------------------------------------------------------
  function AddSE(data, tk_id, SR, item_pos, item_len, loopS, loopE, F_base, F_Area, gain_dB, take_offs, take_prate)
    if not data[tk_id+1] then return end
    if not data[tk_id+1].edits then data[tk_id+1].edits = {} end
      
    -- obey time selection
    local pos, len = 0, item_len
    if loopE - loopS > 0.001 then 
      pos = math.max(loopS - item_pos, 0)
      len = loopE - pos - item_pos
     else
      pos = 0
      len = item_len
    end
    pos = pos* take_prate + take_offs 
    len = len * take_prate
    if len <= 0 then return end
    local freq_L = math.max(0, F_base-F_Area)
    local freq_H = math.min(SR, F_base+F_Area)
    data[tk_id+1].edits [ #data[tk_id+1].edits + 1] = 
      {pos = pos,
       len = len,
       gain = 10^(gain_dB/20),
       fadeinout_horiz = 0,
       fadeinout_vert = 0,
       freq_low = freq_L,
       freq_high = freq_H,
       chan = -1, -- -1 all 0 L 1 R
       bypass = 0, -- bypass&1 solo&2
       gate_threshold = 0,
       gate_floor = 0,
       compress_threshold = 1,
       compress_ratio = 1,
       unknown1 = 0,
       unknown2 = 0,
       fadeinout_horiz2 = 0, 
       fadeinout_vert2 = 0}
  end
  -------------------------------------------------------
  function MPL_SetSpectralPeak(bands)
    local loopS, loopE = GetSet_LoopTimeRange2( 0, false, 0, -1, -1, false )
    for i = 1, CountSelectedMediaItems(0) do 
      local item = GetSelectedMediaItem(0,i-1)
      local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local tk = GetActiveTake( item )
      local src =  GetMediaItemTake_Source( tk )
      local SR = GetMediaSourceSampleRate( src )
      local tk_id = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
      local take_offs = GetMediaItemTakeInfo_Value( tk , 'D_STARTOFFS' )
      local take_prate = GetMediaItemTakeInfo_Value( tk , 'D_PLAYRATE' )
      
      local ret, data = GetSpectralData(item) 
      for i = 1, #bands do  
        local f_area = 100
        if bands[i].F < 1000 then 
          f_area = 50
         elseif bands[i].F >= 1000 and bands[i].F < 5000 then 
          f_area = 200
         elseif bands[i].F >= 5000 and bands[i].F < 10000 then 
          f_area = 500
         elseif bands[i].F >= 10000 then 
          f_area = 1000
        end
        AddSE(data, tk_id, SR, item_pos, item_len, loopS, loopE, 
              bands[i].F, 
              f_area,--bands[i].Q, 
              bands[i].G, 
              take_offs, take_prate)
      end
      if ret then SetSpectralData(item, data) end
    end
  end
  
  Undo_BeginBlock()
  MPL_PortReaEQtoSpectralPeaks()
  Undo_EndBlock( 'Port focused ReaEQ bands to spectral edits', 0 )