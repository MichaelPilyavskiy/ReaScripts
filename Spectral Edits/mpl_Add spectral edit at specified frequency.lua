-- @description Add spectral edit at specified frequency
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # fix non-WAVE sources


  -- NOT gfx NOT reaper
  local scr_title = 'Add spectral edit at specified frequency'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s)  if not s then return end  ShowConsoleMsg(s..'\n') end  
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
    --ClearConsole()
    --msg(out_chunk)
    SetItemStateChunk( item, out_chunk, false )
    UpdateItemInProject( item )
  end
  -------------------------------------------------------
  function AddSE(data, tk_id, SR, item_pos, item_len, loopS, loopE)
    if not data[tk_id+1] then return end
    if not data[tk_id+1].edits then data[tk_id+1].edits = {} end
    
    -- get params
      local ES_str = GetExtState( 'MPL_'..scr_title, 'inputs' )
      local def_str if ES_str == '' then def_str = '12000,1000,-20' else def_str = ES_str end
      local ret, str = GetUserInputs(scr_title, 3, 'Base frequency (Hz),Frequency area (Hz),Gain (dB)',def_str )
      if not ret then return end
      SetExtState( 'MPL_'..scr_title, 'inputs',str , true )
      t = {} for val in str:gmatch('[^%,]+') do if tonumber(val) then t[#t+1] = tonumber(val) end end
      if #t < 3 then return end
      local F_base = t[1]
      local F_Area = t[2]
      local gain_dB = t[3]
      
    -- obey time selection
    local pos, len = 0, item_len
    if loopE - loopS > 0.001 then 
      if loopS >= item_pos and loopS <= item_pos + item_len then pos = loopS- item_pos end
      if loopE >= item_pos and loopE <= item_pos + item_len then 
        len = loopE - loopS 
       else
        len = item_pos + item_len - loopS
      end
    end
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
  Undo_BeginBlock() 
  local loopS, loopE = GetSet_LoopTimeRange2( 0, false, 0, -1, -1, false )
  for i = 1, CountSelectedMediaItems(0) do 
    local item = GetSelectedMediaItem(0,i-1)
    local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local tk = GetActiveTake( item )
    local src =  GetMediaItemTake_Source( tk )
    local SR = GetMediaSourceSampleRate( src )
    local tk_id = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
    ret, data = GetSpectralData(item)    
    AddSE(data, tk_id, SR, item_pos, item_len, loopS, loopE)
    if ret then SetSpectralData(item, data) end
  end
  Undo_EndBlock( scr_title, -1 )
  
  