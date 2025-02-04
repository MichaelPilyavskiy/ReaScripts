-- @description Port focused ReaEQ bands to spectral edits on selected items
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
--------------------------------------------------------------------
  function MPL_SpectralEdits_Manipulate(take, data)
    if TakeIsMIDI(take) then return end
    if data and data.clear then -- clear
      local CNT = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:CNT' )
      for x =CNT-1,0,-1 do
        GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:DELETE:'..x ) 
      end
    end
    
    local item = reaper.GetMediaItemTake_Item(take)
    local item_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    
    -- read
    local SE = {} 
    local CNT = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:CNT' )
    local FFT_SIZE = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:FFT_SIZE' ) 
    for x =0, CNT-1 do
      local POSITION = GetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..x..':POSITION' )
      local LENGTH = GetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..x..':LENGTH' )
      local GAIN = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':GAIN' )
      local FADE_IN = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':FADE_IN' )
      local FADE_OUT = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':FADE_OUT' )
      local FADE_LOW = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':FADE_LOW' )
      local FADE_HI = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':FADE_HI' )
      local CHAN = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':CHAN' )
      local BOTFREQ_FREQAGS = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':BOTFREQ_FREQAGS' )--&1=bypassed, &2=solo
      if data and data.set_bypass then 
        if (data.set_bypass == 1 and BOTFREQ_FREQAGS&1==1) or (data.set_bypass == 0 and BOTFREQ_FREQAGS&1~=1) or data.set_bypass == 2  then 
          SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':BOTFREQ_FREQAGS', BOTFREQ_FREQAGS~1 )
        end
      end
      local GATE_THRESH = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':GATE_THRESH' )
      local GATE_BOTFREQ_FREQOOR = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':GATE_BOTFREQ_FREQOOR' )
      local COMP_THRESH = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':COMP_THRESH' )
      local COMP_RATIO = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':COMP_RATIO' )
      local SELECTED = GetMediaItemTakeInfo_Value( take, 'B_SPECEDIT:'..x..':SELECTED' )
      local TOPFREQ_CNT = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':TOPFREQ_CNT' )
      local TOPFREQ = {}
      for y = 0, TOPFREQ_CNT-1 do
        local TOPFREQ_POS = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':TOPFREQ_POS:'..y )
        local TOPFREQ_FREQ = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':TOPFREQ_FREQ:'..y )
        TOPFREQ[y+1] = {
          TOPFREQ_POS = TOPFREQ_POS,
          TOPFREQ_FREQ = TOPFREQ_FREQ,
        }
      end
      local BOTFREQ_CNT = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':BOTFREQ_CNT' )
      local BOTFREQ = {}
      for y = 0, BOTFREQ_CNT-1 do
        local BOTFREQ_POS = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':BOTFREQ_POS:'..y )
        local BOTFREQ_FREQ = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':BOTFREQ_FREQ:'..y )
        BOTFREQ[y+1] = {
          BOTFREQ_POS = BOTFREQ_POS,
          BOTFREQ_FREQ = BOTFREQ_FREQ,
        }
      end 
      SE[x+1] = {
        FFT_SIZE=FFT_SIZE,
        CHAN=CHAN,
        BOTFREQ_FREQAGS=BOTFREQ_FREQAGS,
        SELECTED=SELECTED, 
        POSITION=POSITION,
        LENGTH=LENGTH, 
        GAIN=GAIN, 
        FADE_IN=FADE_IN,
        FADE_OUT=FADE_OUT,
        FADE_LOW=FADE_LOW,
        FADE_HI=FADE_HI, 
        GATE_THRESH=GATE_THRESH,
        GATE_BOTFREQ_FREQOOR=GATE_BOTFREQ_FREQOOR,
        COMP_THRESH=COMP_THRESH,
        COMP_RATIO=COMP_RATIO, 
        TOPFREQ = TOPFREQ,
        BOTFREQ = BOTFREQ,
        
      }
      --I_SPECEDIT:x:TOPFREQ_DEL:y : int * : reading or writing will delete top frequency-point y. there will always be at least one point.
      --I_SPECEDIT:x:BOTFREQ_DEL:y : int * : reading or writing will delete bottom frequency-point y. there will always be at least one point.
    end
    
    
    -- add
    local FFT_SIZE_SET
    if data and data.add_table then -- add table if specified
      local in_t = data.add_table
      local in_sz = #in_t
      for x = 1,in_sz do
        local newidx = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:ADD' )
        if in_t[x].FFT_SIZE~=FFT_SIZE then FFT_SIZE_SET = in_t[x].FFT_SIZE end
        
        SetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..newidx..':POSITION', in_t[x].POSITION or 0)
        SetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..newidx..':LENGTH', in_t[x].LENGTH or item_LENGTH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GAIN', in_t[x].GAIN or 0 )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_IN', in_t[x].FADE_IN or 0 )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_OUT', in_t[x].FADE_OUT or 0  )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_LOW', in_t[x].FADE_LOW or 0 )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_HI', in_t[x].FADE_HI or 0  )
        SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':CHAN', in_t[x].CHAN or -1  )
        SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':FLAGS', in_t[x].FLAGS or 0 )--&1=bypassed, &2=solo
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GATE_THRESH', in_t[x].GATE_THRESH or 0 )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GATE_FLOOR', in_t[x].GATE_FLOOR or 0  )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':COMP_THRESH', in_t[x].COMP_THRESH or 1  )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':COMP_RATIO', in_t[x].COMP_RATIO or 1  )
        SetMediaItemTakeInfo_Value( take, 'B_SPECEDIT:'..newidx..':SELECTED', in_t[x].SELECTED or 0  )
        
        local botsz = #in_t[x].BOTFREQ
        for y = 1,botsz do
          local pos = in_t[x].BOTFREQ[y].BOTFREQ_POS
          local val = in_t[x].BOTFREQ[y].BOTFREQ_FREQ
          GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':BOTFREQ_ADD:'..pos..':'..val )
        end
        
        local topsz = #in_t[x].TOPFREQ
        for y = 1,topsz  do
          local pos = in_t[x].TOPFREQ[y].TOPFREQ_POS
          local val = in_t[x].TOPFREQ[y].TOPFREQ_FREQ
          GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':TOPFREQ_ADD:'..pos..':'..val )
        end 
        GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:SORT' )
      end
    end
    
    if FFT_SIZE_SET then GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:FFT_SIZE',FFT_SIZE_SET ) end -- apply fft sz if different from current
    return SE
  end
  ------------------------------------------------------
  function PortReaEQ() 
    t = {}
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX2()
    if not (retval &1==1 and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    local num_params = TrackFX_GetNumParams( tr, fx )
    local bands = {}
    for param = 1, num_params - 2, 3 do
      local retval, b_enabled = TrackFX_GetNamedConfigParm( tr, fx, 'BANDENABLED'..(-1+(param+2)/3) )
      b_enabled = tonumber(b_enabled)
      if b_enabled == 1 then
        local retval, db_gain  = TrackFX_GetFormattedParamValue( tr, fx, param, '' )
        db_gain = tonumber(db_gain) if not db_gain then db_gain = -150 end 
        local retval, freq = TrackFX_GetFormattedParamValue( tr, fx, param-1,'')
        freq = math.floor(tonumber(freq) ) 
        local retval, N = TrackFX_GetFormattedParamValue( tr, fx, param+1,'') 
        N = tonumber(N) 
        local retval_type, b_type = TrackFX_GetNamedConfigParm( tr, fx, 'BANDTYPE'..(-1+(param+2)/3) )  
        b_type = tonumber(b_type)
        
        -- low shelf / hi pass
        if b_type == 0 or b_type == 4 then t[#t+1] = 
          {
            BOTFREQ = {[1]={
              BOTFREQ_FREQ = freq,
              BOTFREQ_POS = 0
            }}, 
            TOPFREQ = {[1]={
              TOPFREQ_FREQ = 22050,
              TOPFREQ_POS = 0
            }}, 
            GAIN=10^(db_gain/20),
          } 
        end
        
        
        -- high shelf / low pass
        if b_type == 1 or b_type == 3 then t[#t+1] = 
          {  
            BOTFREQ = {[1]={
              BOTFREQ_FREQ = 0,
              BOTFREQ_POS = 0
            }}, 
            TOPFREQ = {[1]={
              TOPFREQ_FREQ = freq,
              TOPFREQ_POS = 0
            }}, 
            GAIN=10^(db_gain/20),
          } 
        end
        
        
        -- band / notch
        if b_type == 8 or b_type == 6 then
          if db_gain < -60 then N = 0.5 end
          local Q = math.sqrt(2^N) / (2^N - 1 ) 
          local BW = freq/Q
          
          t[#t+1] = {
            BOTFREQ = {[1]={
              BOTFREQ_FREQ = freq - BW/2,
              BOTFREQ_POS = 0
            }}, 
            TOPFREQ = {[1]={
              TOPFREQ_FREQ = freq + BW/2,
              TOPFREQ_POS = 0
            }}, 
            GAIN=10^(db_gain/20),
            FADE_LOW = N/4,
            FADE_HI = N/4,
          } 
        end 
        
        
        if b_type == 7 or b_type == 10 then -- band pass / parallel band pass
          if db_gain < -60 then N = 0.5 end
          local Q = math.sqrt(2^N) / (2^N - 1 ) 
          local BW = freq/Q
          
          t[#t+1] = {
            FLAGS = 2,--solo
            BOTFREQ = {[1]={
              BOTFREQ_FREQ = freq - BW/2,
              BOTFREQ_POS = 0
            }}, 
            TOPFREQ = {[1]={
              TOPFREQ_FREQ = freq + BW/2,
              TOPFREQ_POS = 0
            }}, 
            GAIN=10^(db_gain/20),
            FADE_LOW = 0,
            FADE_HI = 0,
          } 

          
        end         
      end
    end
    return t
  end

--------------------------------------------------------------------
  function main() 
    t = PortReaEQ()
    for i =1, CountSelectedMediaItems( -1 ) do
      local item = reaper.GetSelectedMediaItem(-1,i-1)
      local activetake = GetActiveTake(item)
      if not (activetake and not TakeIsMIDI(activetake)) then return end
      
      MPL_SpectralEdits_Manipulate(activetake, {add_table = t})  
      UpdateItemInProject(item)
    end
    
    --UpdateArrange()
    --Main_OnCommand(40441,0)--Peaks: Rebuild peaks for selected items
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(7.31,true) then 
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Port focused ReaEQ bands to spectral edits on selected items", 0xFFFFFFFF)
  end   