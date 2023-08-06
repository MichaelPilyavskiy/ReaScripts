-- @description Color drums shots by spectral content
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init 

  -- [[debug search filter: NOT function NOT reaper NOT gfx NOT VF]]
  
  local max_slice_length = 0.2
  local min_slice_length = 0.1
  local fftsz = 1024
  local pos_step = fftsz*1/44100
  -- logarithmic splits
  local split1 = 0.16
  local split2 = 0.24
  local split3 = 0.32
  local split4 = 0.49
  local split5 = 0.57
  
  local spls = {}
  local outweight = {}
  -- build log map
  function logspace(start, stop, n, fftsz) return start * (  (stop/start) ^ (n/(fftsz-1))) end 
  local logmap = {} 
  local rangemin = 40 
  local rangemax = 22050
  for i = 1, fftsz-1 do
    initF = rangemin + (rangemax-rangemin) * i/fftsz
    logmap[i] = math.floor(fftsz * logspace(rangemin, rangemax, i, fftsz)/rangemax)--logspaceinv(1, range, initF , fftsz)
  end
  
  --------------------------------------------------------------------- 
  function Main()
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem(0,i-1)
      band_proportion = Main_GetFFTPrint(it)
      ColorTakesBasedOnBandProportion(it, band_proportion)
    end 
  end
   
  --------------------------------------------------------------------- 
  function ColorTakesBasedOnBandProportion(item, b)
      local take = GetActiveTake(item)
      if not ValidatePtr2(0,take,'MediaTake*') then return end 
     
      local set = false
      local drumtype 
      b1 = b[1] b2 = b[2] b3 = b[3] b4 = b[4] b5 = b[5] b6 = b[6]
      if b1 > b2 and b1>b3 and b1>b4 and b1>b5 and b1>b6 then 
        drumtype = 'kick' 
        if b1 - (b2+b3+b4+b5+b6)/5 > 0.3 and b6>b3 and b6>b4 and b6>b5 then drumtype = 'hat' end
      end
      if b2 > b1 and b2>b3 and b2>b4 and b2>b5 and b2>b6 then drumtype = 'snare'  end 
      if b3 > b1 and b3>b2 and b3>b4 and b3>b5 and b3>b6 then drumtype = 'snare_low' end
      if b4 > b1 and b4>b2 and b4>b3 and b4>b5 and b4>b6 then drumtype = 'snare_high' end
      if b5 > b1 and b5>b2 and b5>b3 and b5>b4 and b5>b6 then drumtype = 'tom' end
      if b6 > b1 and b6>b2 and b6>b3 and b6>b4 and b6>b5 then 
        drumtype = 'hat'
        if math.abs((b2+b3+b4+b5)/4 - b6) < 0.2 then drumtype = 'snare' end  
        if math.abs(b6 - (b2+b6)/2) < 0.1 then drumtype = 'snare' end
      end -- aht
     
     --[[
     predominantly bass then it could be colored Red (kick), mostly low mids Yellow (snare), mostly highs Blue (tops)?
     ]]
    if drumtype ~= nil then
      if drumtype == 'kick' then r=1 g = 0 b =0 end
      if drumtype == 'snare' then r=1 g = 1 b =0 end
      if drumtype == 'snare_low' then r=1 g = 0.3 b =0 end
      if drumtype == 'snare_high' then r=1 g = 0.5 b =0 end
      if drumtype == 'tom' then r=0.5 g = 1 b =0.5 end
      if drumtype == 'hat' then r=0 g = 0 b =1 end
      local outcol = ColorToNative(math.floor(r*255),math.floor(g*255),math.floor(b*255))|0x1000000
      SetMediaItemTakeInfo_Value( take, 'I_CUSTOMCOLOR', outcol )
    end
     
     UpdateArrange()
  end
  --------------------------------------------------------------------- 
  function Main_GetFFTPrint(item) 
    -- validate pointers
      if not ValidatePtr2(0,item,'MediaItem*') then return end
      local track =  GetMediaItemTrack( item )
      
      if not ValidatePtr2(0,track,'MediaTrack*') then return end
      local take = GetActiveTake(item)
      if not ValidatePtr2(0,take,'MediaTake*') then return end 
      if TakeIsMIDI(take) then return end
    -- get boundaries
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len =  GetMediaItemInfo_Value( item, 'D_LENGTH' ) 
      local revert_len = false
      local src_len = len
      if len < min_slice_length then 
        revert_len = true
        len = min_slice_length
        SetMediaItemInfo_Value( item, 'D_LENGTH', min_slice_length ) 
      end
      local source = GetMediaItemTake_Source( take )
      local srclen, lengthIsQN = reaper.GetMediaSourceLength( source ) 
      local TSstart = 0--pos
      local TSend = math.min(max_slice_length,len)---math.min(math.min(len, max_slice_length),srclen)
      local SR = VF_GetProjectSampleRate()
      local numchannels = 1
      local FFTwind_sec = 2*fftsz/SR
    
    
    -- take spectrum
      spls = {}
      local accessor = CreateTakeAudioAccessor( take )
      local id = 0 
      local max_magn=-math.huge
      for pos = TSstart, TSend-pos_step, pos_step do
          local posout = pos + pos_step
          local samplebuffer = new_array(fftsz*2)
          GetAudioAccessorSamples( accessor, SR, numchannels, posout, fftsz, samplebuffer )
          id = id + 1 
          samplebuffer.fft_real(fftsz, true)
          local magnbuf = new_array(fftsz)
          for bin = 0, fftsz-2 do 
            local Re = samplebuffer[bin*2+1]
            local Im = samplebuffer[bin*2+ 2]
            local magnitude = math.sqrt(Re^2 + Im^2)
            if bin == 0 then magnitude = 0 end
            magnbuf[bin+1]=magnitude
          end 
          for bin = 1, 2 do magnbuf[bin] = 0 end-- reset niqyst // dc offset and some ultra lows
          spls[id] = magnbuf.table() 
          SpectrumLinearToLog(spls[id])
          SpectrumCompensate(spls[id])
          samplebuffer.clear()
          magnbuf.clear()
        
        
      end
      reaper.DestroyAudioAccessor( accessor )
      
    -- normalize magnitudes
      local magn_max = 0
      local magn_cnt = 0
      for pos =1,#spls do
        for bin=1, #spls[pos] do 
          magn_max = math.max(magn_max, spls[pos][bin]) --math.min(1000,spls[pos][bin] / max_magn)
        end
      end
      for pos =1,#spls do
        for bin=1, #spls[pos] do 
          spls[pos][bin] = spls[pos][bin] / magn_max --math.min(1000,spls[pos][bin] / max_magn)
        end
      end

    -- weight spectrum by shot duration at each bin
      local sz = #spls
      outweight = {}
      local maxbinsum = 0
      for bin = 1, fftsz do
        binsum = 0
        local posweight = 1
        for pos = 1, sz do binsum = binsum + math.abs(spls[pos][bin] )* posweight *(1-(pos/sz)) end
        outweight[bin] = binsum
        maxbinsum = math.max(binsum,maxbinsum)
      end
      for bin = 1, fftsz do outweight[bin] = (outweight[bin] / maxbinsum)^2 end -- normalize
      
      
    -- weight bands
      band_proportion = { 0,0,0,0,0,0 }
      local sz = #outweight
      local b_sum = 0
      for bin = 1, sz do
        b_sum = b_sum + outweight[bin]
        local curratio = bin/sz
        if      curratio < split1                          then band_proportion[1] = band_proportion[1] + outweight[bin] 
         elseif curratio >=split1 and curratio < split2    then band_proportion[2] = band_proportion[2] + outweight[bin] 
         elseif curratio >=split2 and curratio < split3    then band_proportion[3] = band_proportion[3] + outweight[bin] 
         elseif curratio >= split3 and curratio < split4   then band_proportion[4] = band_proportion[4] + outweight[bin] 
         elseif curratio >= split4 and curratio < split5   then band_proportion[5] = band_proportion[5] + outweight[bin] 
         elseif curratio>=split5                           then band_proportion[6] = band_proportion[6] + outweight[bin] 
        end 
      end
      
        
      band_proportion[1] = band_proportion[1] / (sz*(split1))
      band_proportion[2] = band_proportion[2] / (sz*(split2-split1))
      band_proportion[3] = band_proportion[3] / (sz*(split3-split2))
      band_proportion[4] = band_proportion[4] / (sz*(split4-split3))
      band_proportion[5] = band_proportion[5] / (sz*(split5-split4))
      band_proportion[6] = band_proportion[6] / (sz*(1-split5))
      
      local bsum = 0
      for i = 1, #band_proportion do bsum = bsum + band_proportion[i] end
      for i = 1, #band_proportion do band_proportion[i]=band_proportion[i]/bsum end
      
      --UI_test()
      if revert_len == true then  SetMediaItemInfo_Value( item, 'D_LENGTH', src_len )  end

    return band_proportion, signlef_low
  end
  ----------------------------------------------------------------------
  function SpectrumCompensate(t) 
    local sz = #t 
    local mult, curratio
    for i = 1, sz do 
      mult = 0
      curratio = i/sz
      if curratio == 0 then mult = 0
       elseif curratio < split1                        then mult = 0.07 -- sub lows // kick
       elseif curratio >=split1 and curratio < split2    then mult = 0.15 -- lows // kick
       elseif curratio >=split2 and curratio < split3    then mult = 0.2 -- sc = 0.1 mult = sc+(1-sc)*(curratio*2)^2  -- lows // snare
       elseif curratio >= split3 and curratio < split4  then mult = 0.4 -- mid //  toms
       elseif curratio >= split4 and curratio < split5  then mult = 0.5 
       elseif curratio>=split5 then mult = 1 -- highs
      end 
      t[i] = t[i] * mult
    end
  end
  ---------------------------------------------------------------------
    function SpectrumLinearToLog(t) 
      local t_temp=CopyTable(t)
    local sz = #t_temp
    for bin_linear = 1, sz do t[bin_linear] = t_temp[logmap[bin_linear]] or 0 end
    
    -- compensatemidlows
    low_area = math.floor(0.3*sz)
    high_area = math.floor(0.6*sz)
    --[[for bin = 1, low_area do              t[bin] = t[bin] * 0.3 end
    for bin = low_area+1, high_area do    t[bin] = t[bin] * 1 end
    for bin = high_area+1, sz do          t[bin] = t[bin] * 0.8 end]]
    t[1] = 0
    t[#t_temp] = 0
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  function UI_test()
    gfx.init('test',400,1300,0,2300,50)
    gfx.set(1,1,1,1)
    rect_w =math.floor(gfx.w/#spls) 
    rect_h =math.ceil(gfx.h/fftsz)
    gfxh = gfx.h
    
    -- draw spectrum
    for pos =1,#spls do
      x = rect_w * (pos-1)
      y = 0
      w = rect_w-1
      h = rect_h
      a = 0.5
      for bin=2, fftsz do
        if spls[pos][bin] then 
          gfx.a = VF_lim( spls[pos][bin])
          y = gfxh-h*bin
          gfx.rect(x,y,w,h,1)
        end
      end
    end
    
    -- draw bands linear
    check_bin_ratio = math.floor(0.25*fftsz)
    y_line = gfx.h * (1-check_bin_ratio / fftsz)
    gfx.set(1,0.5,0.5,1)
    gfx.line(0,y_line,gfx.w,y_line)
    
    check_bin_ratio = math.floor(0.36*fftsz)
    y_line = gfx.h * (1-check_bin_ratio / fftsz)
    gfx.set(1,0.5,0.2)
    gfx.line(0,y_line,gfx.w,y_line)
    
    check_bin_ratio = math.floor(0.5*fftsz)
    y_line = gfx.h * (1-check_bin_ratio / fftsz)
    gfx.set(1,0.5,1,1)
    gfx.line(0,y_line,gfx.w,y_line)
    
    check_bin_ratio = math.floor(0.77*fftsz)
    y_line = gfx.h * (1-check_bin_ratio / fftsz)
    gfx.set(0.5,0.5,1,1)
    gfx.line(0,y_line,gfx.w,y_line)
    
    check_bin_ratio = math.floor(0.9*fftsz)
    y_line = gfx.h * (1-check_bin_ratio / fftsz)
    gfx.set(0.5,1,0.5,1)
    gfx.line(0,y_line,gfx.w,y_line)
    
    -- draw weight
    rect_h =math.ceil(gfx.h/fftsz)
    for bin=1, fftsz do 
      gfx.set(0,1,1)
      gfx.a = VF_lim( outweight[bin])
      y = gfxh-rect_h*bin
      gfx.rect(gfx.w/2,y,gfx.w/2,rect_h,1)
    end
  end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    Main() 
    Undo_EndBlock2( 0, 'Color drums shots by content', 0xFFFFFFFF )
  end end