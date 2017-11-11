-- @description Comb-filtering check selected items
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init
-- @about
--    1. Script works for 2 selected items
--    2. Put edit cursor at transient and shift dub item a bit left.
--    3. Select both items and run script.


  sz = 2^11
  area = 0.05
  show_tooltip = 1
  
  -- NOT gfx NOT reaper
  local scr_title = 'Phase match selected items (comb-filtering check)'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function msg(s)  if not s then return end  ShowConsoleMsg(s..'\n')   end
------------------------------------------  
  function GetBuffer(it, sz, SR, shift)
    local tk = GetActiveTake(it)
    if TakeIsMIDI(tk) then return end
    local read_pos = GetCursorPosition() - shift
    local tr = GetMediaItemTake_Track( tk )
    local accessor = CreateTrackAudioAccessor( tr )
    local src = GetMediaItemTake_Source(tk)
    local numch = 1--GetMediaSourceNumChannels(src)
    local buffer = new_array(sz)--*numch )
    GetAudioAccessorSamples(
                           accessor,
                           SR,
                           1,--numch,
                           read_pos,
                           sz, -- numsamplesperchannel
                           buffer) --samplebuffer
                         
    DestroyAudioAccessor( accessor )
    if inv then for i = 1, sz do buffer[i] = - buffer[i] end end
    return buffer
  end
  ---------------------------------------------------
  function GetFFTSum(b1, b2, sz)
    local b = new_array(sz)
    for i = 1, sz do 
      b[i] = b1[i] + b2[i] 
    end
    b.fft_real(sz, true, 1)
    local t = b.table()
    local s = 0
    for i = 1, #t do s = s + math.abs(t[i]) end
    return  s
  end
  ---------------------------------------------------    
  function CalcOffset(it, area, ref_item_buf ,sz, SR)
    
    -- 1ms brutforce
      local t = {}
      local sum = 0 
      for shift = 0, area, 0.001 do
        local b2 = GetBuffer(it, sz, SR, shift)  
        sum  = GetFFTSum(ref_item_buf, b2, sz)
        t[#t+1] = sum
      end        
      shift_ms = GetMaxValIdx(t)
      if shift_ms < 0 then return end
      if not shift_ms then return end
      --for i = 1, #t do msg(t[i]) end
    -- 1spl brutforce
      local t2 = {}
      local sum2 = 0
      local spl_area = math.floor(SR/1000)*2
      for shift = 1, spl_area  do
        local b2 = GetBuffer(it, sz, SR, (shift_ms-1)/1000 + shift/SR)  
        sum2  = GetFFTSum(ref_item_buf, b2, sz)
        t2[#t2+1] = sum2      
      end
      shift_spl = GetMaxValIdx(t2)
      if not shift_spl then return end
      
    return (shift_ms-1)/1000 + shift_spl/SR
  end
  --------------------------------------------------- 
  function GetMaxValIdx(t) 
    if not t then return end
    local ret_id, max ,last_max= 0 , 0
    for i = 1, #t do
      max = math.max(t[i],max)
      if last_max and last_max < max then ret_id = i end
      last_max = max 
    end
    return ret_id
  end
  ---------------------------------------------------  
  function CombFiltCheck(sz,area) 
    local SR = tonumber(format_timestr_pos( 1, '', 4 ) )
    local ref_item = GetSelectedMediaItem(0,0)
    if not ref_item then return end
    local ref_item_buf = GetBuffer(ref_item, sz, SR, 0)  
    local dub_it = GetSelectedMediaItem(0,1)
    if not dub_it then return end
    
  if show_tooltip == 1 then 
    MB([[1. Script works for 2 selected items
2. Put edit cursor at transient and shift dub item a bit left.
3. Select both items and run script') 

Expected search area: ]]..area..'ms\nFFT size: '..math.floor(sz), scr_title, 0)
  end
      
    local pos = GetMediaItemInfo_Value( dub_it, 'D_POSITION' )
    offs = CalcOffset(dub_it, area, ref_item_buf, sz, SR)
    SetMediaItemInfo_Value( dub_it, 'D_POSITION', pos + offs )
  end
  --------------------------------------------------- 
  
  
  CombFiltCheck(sz,area)