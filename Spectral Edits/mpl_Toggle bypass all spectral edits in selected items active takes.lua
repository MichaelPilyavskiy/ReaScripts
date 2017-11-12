-- @description Toggle bypass all spectral edits in selected items active takes
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # fix non-WAVE sources


  -- NOT gfx NOT reaper
  local scr_title = 'Toggle bypass all spectral edits in selected items active takes'
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
          end
          add_str = add_str..'SPECTRAL_CONFIG '..data[tk_cnt].FFT_sz  ..'\n'         
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
  function BypassSEstate(data, tk_id)
    if  data[tk_id+1] and data[tk_id+1].edits then
      for se_id  =1 , #data[tk_id+1].edits do
        if data[tk_id+1].edits[se_id].bypass == 0 then data[tk_id+1].edits[se_id].bypass = 1 
          elseif data[tk_id+1].edits[se_id].bypass == 1 then data[tk_id+1].edits[se_id].bypass = 0 
        end
      end
    end
  end
  -------------------------------------------------------
  Undo_BeginBlock() 
  for i = 1, CountSelectedMediaItems(0) do 
    local item = GetSelectedMediaItem(0,i-1)
    local tk = GetActiveTake( item )
    local tk_id = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
    local ret, data = GetSpectralData(item)    
    BypassSEstate(data, tk_id)
    if ret then SetSpectralData(item, data) end
  end
  Undo_EndBlock( scr_title, -1 )
  
  