-- @description Align item position by SMPTE code on last channel
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use project sample rate instead take sample rate
--    # fix wrong offset for a SMPTE sync pattern


 
  -- NOT gfx NOT reaper
  
  -- config defaults
  DATA2 = {  }
  
  --------------------------------------------------------------------- 
  function DATA2:GetAudioData()
    local reading_len = 0.4 -- sec, approximately 12 frames at 30fps
    
    
    local item = GetSelectedMediaItem(0,0)
    if not item then return end
    local take = GetActiveTake(item)
    if not take or TakeIsMIDI(take ) then return end 
    DATA2.hasvalidtake = true
    
    DATA2.tr_ptr = GetMediaItemTrack( item )
    DATA2.take_src = GetMediaItemTake_Source( take ) 
    DATA2.SR=  VF_GetProjectSampleRate()--GetMediaSourceSampleRate( DATA2.take_src ) 
    
    DATA2.num_ch = GetMediaSourceNumChannels( DATA2.take_src )
    DATA2.tk_srclen = GetMediaSourceLength( DATA2.take_src ) 
    DATA2.item_ptr = item
    DATA2.item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    DATA2.tk_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    
    local accessor = CreateTrackAudioAccessor(DATA2.tr_ptr ) 
    DATA2.pos_read = DATA2.item_pos--DATA2.tk_offs
    local window_spls = math.floor(DATA2.SR*reading_len*DATA2.num_ch)
    local window_spls_perch = math.floor(DATA2.SR*reading_len)
    local samplebuffer = reaper.new_array(window_spls) 
    reaper.GetAudioAccessorSamples( accessor, DATA2.SR, DATA2.num_ch, DATA2.pos_read, window_spls_perch, samplebuffer )
    local t = {}
    local id, val = 0 
    for i = 1, window_spls, DATA2.num_ch do
      id = id + 1
      val = samplebuffer[i + DATA2.num_ch-1]
      if val >= 0 then val = 0 else val = 1 end
      t[id] = {val = val, pos_spls = (i+DATA2.num_ch-1) / DATA2.num_ch}
    end
    samplebuffer.clear( )
    reaper.DestroyAudioAccessor( accessor )
    
    DATA2.audiosrc = t
  end
  ---------------------------------------------------------------------  
  function DATA2:GetBitstreamFromAudio() 
    
    local id = 0
    local trig,pos_spls,cur_value,next_value,rise,fall
    local lastpos = 0
    
    
    -- handle rise above 0
    local t2 = {}
    
    for i = 1, #DATA2.audiosrc-1 do
      cur_value = DATA2.audiosrc[i].val
      next_value = DATA2.audiosrc[i+1].val
      rise = (cur_value <= 0 and next_value > 0)
      fall = (cur_value >0 and next_value <= 0)
      trig = rise or fall
      if trig == true then
        id = id + 1
        pos_spls = DATA2.audiosrc[i].pos_spls 
        t2[id] = { pos_spls = pos_spls,
                    val=cur_value,
                    rise = rise}
      end
    end 
    local sz = #t2 
    
    -- add length of gates
      for i = 1,sz-1 do t2[i].len = t2[i+1].pos_spls - t2[i].pos_spls end
      t2[sz].len = 0
    -- get mid len 
      local mid_len = 0 
      for i = 1,sz do mid_len = mid_len + t2[i].len end
      mid_len = mid_len / sz
    -- handle short/long
      for i = 1,sz-1 do 
        t2[i].long =  t2[i].len > mid_len
        t2[i].len = nil
      end
    -- convert sign
      for i = sz,1,-1 do 
        if t2[i].long == true then 
          t2[i].long = nil
          t2[i].rise = nil
          t2[i].state = false
          t2[i].val = 0
         elseif t2[i].long ~= true and t2[i].rise==true then 
          t2[i].long = nil
          t2[i].rise = nil
          t2[i].state = true 
          t2[i].val = 1
         elseif t2[i].long ~= true and t2[i].rise~=true then  
          table.remove(t2,i)
        end 
      end
      DATA2.bitstreamout = t2
      
  end
  ---------------------------------------------------------------------  
  function DATA2:GetValidMask()
    local t = DATA2.bitstreamout
    local sz = #t
    local valid_mask
    for offs = 1, sz-96 do
      valid_mask = DATA2:IsMaskValid(t,offs-1)
      if valid_mask ==true then
        DATA2.valid_mask_offs = offs
        return 
      end 
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:IsMaskValid(t,i)
      return 
t[i+1].state == false and 
t[i+2].state == false and 
t[i+3].state == true and 
t[i+4].state == true and 
t[i+5].state == true and 
t[i+6].state == true and 
t[i+7].state == true and 
t[i+8].state == true and 
t[i+9].state == true and 
t[i+10].state == true and 
t[i+11].state == true and 
t[i+12].state == true and 
t[i+13].state == true and 
t[i+14].state == true and 
t[i+15].state == false and 
t[i+16].state == true and 

t[i+81].state == false and 
t[i+82].state == false and 
t[i+83].state == true and 
t[i+84].state == true and 
t[i+85].state == true and 
t[i+86].state == true and 
t[i+87].state == true and 
t[i+88].state == true and 
t[i+89].state == true and 
t[i+90].state == true and 
t[i+91].state == true and 
t[i+92].state == true and 
t[i+93].state == true and 
t[i+94].state == true and 
t[i+95].state == false and 
t[i+96].state == true 
  end
  ---------------------------------------------------------------------  
  function DATA2:GetFrame()
    local t = DATA2.bitstreamout
    local offs = DATA2.valid_mask_offs+16
    local smpte_bitmask = ''
    for i = offs, offs+64 do smpte_bitmask = smpte_bitmask..t[i].val end 
    smpte_bitmask = tonumber(smpte_bitmask:reverse(), 2)
    
    local hour =    10 * ((smpte_bitmask >> 56) & 0x03)  + ((smpte_bitmask >> 48) & 0x0f)
    local minute =  10 * ((smpte_bitmask >> 40) & 0x07)  + ((smpte_bitmask >> 32) & 0x0f)
    local second =  10 * ((smpte_bitmask >> 24) & 0x07)  + ((smpte_bitmask >> 16) & 0x0f)
    local frame =   10 * ((smpte_bitmask >>  8) & 0x03)  + ((smpte_bitmask >>  0) & 0x0f)
    DATA2.frame_pos = parse_timestr_pos( hour..':'..minute..':'..second..':'..frame, 5 )
    DATA2.smptesploffs = t[offs].pos_spls
  end
  ---------------------------------------------------------------------  
  function main()  
    ClearConsole()
    DATA2:GetAudioData()
    if not DATA2.hasvalidtake then return end
    if not DATA2.audiosrc then MB('Valid audio source not found', 'SMPTE align', 0) return end
    DATA2:GetBitstreamFromAudio()
    DATA2:GetValidMask()if not DATA2.valid_mask_offs then MB('Valid frame not found', 'SMPTE align', 0) return end 
    DATA2:GetFrame() if not (DATA2.frame_pos and DATA2.smptesploffs) then MB('Valid frame can`t be calculated', 'SMPTE align', 0) return end 
    SetMediaItemInfo_Value( DATA2.item_ptr, 'D_POSITION', DATA2.frame_pos - DATA2.smptesploffs / DATA2.SR  )
    reaper.UpdateArrange()
  end
  
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end