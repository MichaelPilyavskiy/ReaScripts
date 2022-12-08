-- @description Quantize stretch markers in selected items to zero crossings
-- @version 1.10
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Use more precise algorithm, improve performance 
--    + Don`t use various functions


  ---------------------------------------------------------------------
  function MPL_QuantizeSMtoZeroCross(take)
    if not take then return end
    if reaper.TakeIsMIDI(take) then return end
    local source = reaper.GetMediaItemTake_Source( take )
    local SR = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 ))--GetMediaSourceSampleRate( source ) 
    local cnt = reaper.GetTakeNumStretchMarkers( take )
    local soffs = reaper.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    local rate = reaper.GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
    local it = reaper.GetMediaItemTake_Item( take )
    local it_pos = reaper.GetMediaItemInfo_Value(  it, 'D_POSITION' )
    local tr =  reaper.GetMediaItemTrack( it )
    local pr_offs = reaper.GetProjectTimeOffset( 0, false )
     sm_t = {}
    local pow = 8
    for i = 1, cnt do 
      local retval, posOut, src_pos = reaper.GetTakeStretchMarker( take, i-1 )
      
      local pos_proj = it_pos + posOut/rate + pr_offs
      sm_t[#sm_t+1] = {pos = posOut, src_pos = math.floor((10^pow)*src_pos) / (10^pow), pos_proj = pos_proj} 
    end
    
    local bufsz_check = math.floor(SR * (500 / 44100)) -- take approximately 500 samples at 44.1
    local buf_offs_sec =  math.floor(SR * (1 / 44100))/SR -- take approximately 5 samples at 44.1
    local accessor = reaper.CreateTrackAudioAccessor( tr)
    local samplebuffer = reaper.new_array(bufsz_check);
    for i = 1, #sm_t do
      local pos_check = sm_t[i].pos_proj - buf_offs_sec - pr_offs
      reaper.GetAudioAccessorSamples( accessor, SR, 1, pos_check, bufsz_check, samplebuffer )
      for spl = 3,bufsz_check do
        if (samplebuffer[spl] >=0 and samplebuffer[spl-1] <0) or (samplebuffer[spl] <0 and samplebuffer[spl-1] >=0) then
          sm_t[i].pos_ZC  = sm_t[i].src_pos + (spl-2)/ SR
          break
        end
      end
      samplebuffer.clear()
    end
    reaper.DestroyAudioAccessor( accessor )
     
      
    for i = 1,#sm_t do
      local src_pos = sm_t[i].src_pos
      local src_ZC = sm_t[i].pos_ZC
      local diff = sm_t[i].pos_ZC - sm_t[i].src_pos
      reaper.SetTakeStretchMarker( take, i-1, sm_t[i].pos + diff, sm_t[i].src_pos+diff )
    end
    reaper.UpdateItemInProject( it )
  end


    
    ----------------------------------------------------------------------
    reaper.Undo_BeginBlock()
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local it = reaper.GetSelectedMediaItem(0,i-1)
      local take = reaper.GetActiveTake(it)
      MPL_QuantizeSMtoZeroCross(take) 
    end 
    reaper.Undo_EndBlock('Quantize stretch markers to zero crossings' ,0xFFFFFFFF )