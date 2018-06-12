-- @description Quantize stretch markers in selected items to zero crossings
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # compensate content move

  -- NOT gfx NOT reaper
  local scr_title = 'Quantize stretch markers in selected items to zero crossings'
  
  local peakrate = 5000 -- peaks quality
  local search_area = 1000 -- search in peaks table entryies (step = src_len / spl_cnt)
  
  
  ---------------------------------------------------------------------
  function GetSMData(take)
    local cnt = GetTakeNumStretchMarkers( take )
    local soffs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    local t = {}
    for i = 1, cnt do 
      local retval, posOut, src_pos = GetTakeStretchMarker( take, i-1 )
      local pow = 8
      t[#t+1] = {pos = posOut, src_pos = math.floor((10^pow)*src_pos) / (10^pow), pos_compensated = posOut + soffs}  
    end
    return t
  end
  ---------------------------------------------------------------------------------------------------------------------
  function GetPeaks(take)
    if not take then    return end
    local src = GetMediaItemTake_Source( take )
      if not src then return end
      local src_len =  GetMediaSourceLength( src )
      local n_spls = math.floor(src_len*peakrate)
      if n_spls < 10 then return end 
      local n_ch = 1
      local want_extra_type = 0--115  -- 's' char
      local buf = new_array(n_spls * n_ch * 3) -- min, max, spectral each chan(but now mono only)
        -------------
      local retval =  PCM_Source_GetPeaks(    src, 
                                        peakrate, 
                                        0,--starttime, 
                                        n_ch,--numchannels, 
                                        n_spls, 
                                        want_extra_type, 
                                        buf )
      local spl_cnt  = (retval & 0xfffff)        -- sample_count
      local peaks = {}
      local peaks2 = {}
      for i=1, spl_cnt do  peaks[#peaks+1] = buf[i]  end
      buf.clear()
      NormalizeT(peaks, 1) 
      local pow = 8
      for i=1, spl_cnt do  peaks2[#peaks2+1] = {val = peaks[i],
                                              pos = math.floor((10^pow)*i * src_len / spl_cnt) / (10^pow)}
      end
      return peaks2, src_len
  end 
  ---------------------------------------------------------------------
  function main()
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem(0,i-1)
      local take = GetActiveTake(it)
      if TakeIsMIDI(take) then return end
      local sm_t = GetSMData(take)
      local peaks_t, src_len = GetPeaks(take)
      ClearConsole()
      for i = #sm_t-1, 1,-1 do
        local src_pos = sm_t[i].src_pos
        for spl = 2, #peaks_t do
          if peaks_t[spl].pos >= src_pos and peaks_t[spl-1].pos < src_pos then
            local loopcnt = lim(spl+search_area, 0,#peaks_t)
            for spl2 =spl , loopcnt  do
              if math.abs(peaks_t[spl2].val) < 0.1 then
                local srcpos_new = peaks_t[spl2].pos
                SetTakeStretchMarker( take, i-1, sm_t[i].pos + ( srcpos_new - sm_t[i].src_pos), srcpos_new )
                break
              end
            end
            break
          end
        end
      end
    end
    UpdateArrange()
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        Undo_BeginBlock()
        main()
        Undo_EndBlock( scr_title, -1 )
      end
      
     else
      MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
--------------------------------------------------------------------
  CheckFunctions('lim')  