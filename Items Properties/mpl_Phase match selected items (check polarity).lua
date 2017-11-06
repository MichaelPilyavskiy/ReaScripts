-- @description Phase match selected items (check polarity)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init

  -- NOT gfx NOT reaper
  local scr_title = 'Phase match selected items (check polarity)'
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  local function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------
  local function msg(s) if s and s ~= '' then ShowConsoleMsg(s..'\n') end end

  ---------------------------------------------------
  function GetTimeSelection()
    local startOut, endOut = GetSet_LoopTimeRange( false, false, 0, 0, false )
    local buf_time_sec = endOut-startOut
    if buf_time_sec < 0.001 then return end
    buf_time_sec = lim(buf_time_sec, 0.01, 0.05)
    return true, buf_time_sec,startOut
  end
  ---------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end
  ---------------------------------------------------
  function InvPolarity(item, pol)
    local _, chunk = GetItemStateChunk( item, '', false )
    repl = chunk:match('VOLPAN.-[\r\n]')
    local t = {} for num in repl:gmatch('[%p%d]+') do t[#t+1] = num end  
    t[3] = t[3]*pol 
    repl_mod = 'VOLPAN '..table.concat(t, ' ')..'\n'
    out_chunk = chunk:gsub(literalize(repl), repl_mod)
    --msg(out_chunk)
    SetItemStateChunk( item, out_chunk, false )
  end
  ---------------------------------------------------
  function InvertItems(tk_t, offs, buf_time_sec)
    if not offs then return '' end
    str = scr_title..' \n\nLookUp area: '..(math.floor(buf_time_sec*10000)/10000)..'s\n'
    for i in pairs(offs) do
      tk =  GetMediaItemTakeByGUID( 0, tk_t[i].GUID )
      if tk then 
        local item= GetMediaItemTake_Item( tk )
        local it_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
        local pol = offs[i]
        InvPolarity(item,pol)
        local pol_str = 'Normal'
        if pol < 0 then pol_str = 'Inverted' end        
        str = str
          ..tk_t[i].name..'\n   polarity: '..pol_str
          ..'\n'
        UpdateItemInProject( item )
      end
    end
      
    UpdateArrange()
    return str
  end
  ---------------------------------------------------
  function GetTakes(proj_rate,buf_time_sec,n,startOut)
    local takes = {}
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem( 0, i-1 )
      local tk = GetActiveTake(it)
      if not TakeIsMIDI(tk) then
        local par_tr =  GetMediaItemTake_Track( tk )
        local retval, par_tr_name = GetTrackName( par_tr, '' )
        local tk_name = GetTakeName( tk )
        takes[#takes+1] = {offs = GetMediaItemTakeInfo_Value( tk, 'D_STARTOFFS' ),
                           samples = GetSamples(tk,proj_rate,buf_time_sec,n,startOut),
                           GUID = BR_GetMediaItemTakeGUID( tk ),
                           name = par_tr_name..' / '..tk_name
                            }
      end
    end
    return takes
  end
  ---------------------------------------------------
  function CalculatePol(tk_t)
    local pol = {}
    if #tk_t <  2 then return end
    local buf_sz =  #tk_t[1].samples
    
    for key in pairs(tk_t) do
      if tonumber(key) and tonumber(key) ~= 1 then
         diff, diff_inv = 0,0
        for spl = 1, buf_sz do
          diff = diff + tk_t[1].samples[spl] - tk_t[key].samples[spl] 
          diff_inv = diff_inv + tk_t[1].samples[spl] + tk_t[key].samples[spl] 
        end    
        if diff > diff_inv then pol[key] = 1 else pol[key] = -1 end
      end
    end
    return pol
  end
  ---------------------------------------------------
  function GetLowestDiff(t)
    local last_val, min_id
    local min_val = math.huge
    for i = 1, #t do
      local val = t[i]
      if val < min_val then
        min_val = val
        min_id = i 
      end
    end
    return min_id, min_val
  end
  ---------------------------------------------------
  function GetSamples(tk, rate,buf_time_sec,n,startOut)
    local tr = GetMediaItemTake_Track( tk )
    local accessor = CreateTrackAudioAccessor( tr )
    local src = GetMediaItemTake_Source(tk)
    --local numch = GetMediaSourceNumChannels(src)
    local spl_cnt = math.floor(buf_time_sec * rate)
    local buffer = new_array(spl_cnt)--*numch )
    local read_pos = startOut--GetCursorPosition()
    --spl_fft = 256 
    --for i = 1, spl_cnt, spl_fft do
      GetAudioAccessorSamples(
                         accessor,
                         rate,
                         1,--numch,
                         read_pos,
                         spl_cnt, -- numsamplesperchannel
                         buffer) --samplebuffer
                       
                       
    DestroyAudioAccessor( accessor )
    local t = buffer.table()
    t = Smooth(t, 0.9)
    --t = Normalize(t)
    return t
  end
  ---------------------------------------------------------------------------------------------------------------------
  function Normalize(t)
    local m = 0 for i = 1, #t do m = math.max(math.abs(t[i]),m) end
    for i = 1, #t do t[i] = t[i]/m end
    return t
  end  
  ------------------------------------------------------------
  function RemoveFromEnd(t, n)
    for i = #t, 1, -n do table.remove(t, i) end
    return t
  end  
  ------------------------------------------------------------
  function Abs(t)
    for i = 1, #t do t[i] = math.abs(t[i]) end
    return t
  end   
  ------------------------------------------------------------
  function Smooth(t,c)
    for i = 2, #t do t[i]= t[i] - (t[i] - t[i-1])*c   end
    return t
  end
------------------------------------------------------------
  
  function main()
    local ret, buf_time_sec,startOut = GetTimeSelection()
    if not ret then MB('Select time selection as the area for lookup better shift beetween items', scr_title, 0) return end
    local proj_rate = tonumber(format_timestr_pos( 1, '', 4 ) )
    local takes = GetTakes(proj_rate,buf_time_sec,n,startOut)
    if #takes < 2 then MB('Select at least 2 takes', scr_title, 0) return end
    ret = 6--MB('LookUp area: '..(math.floor(1000*buf_time_sec)/1000)..'s. Calculate shifts?', scr_title, 4)
    if ret == 6 then
      --n = 4
      offs,buf_sz = CalculatePol(takes) 
      Undo_BeginBlock2( 0 )
      log = InvertItems(takes, offs,buf_time_sec)
      --ClearConsole()
      --msg(log)
      Undo_EndBlock2( 0, scr_title, -1 )
    end
  end
  
  main()