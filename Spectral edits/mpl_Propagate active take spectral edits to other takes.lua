-- @description Propagate active take spectral edits to other takes
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
      local FLAGS = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':FLAGS' )--&1=bypassed, &2=solo
      local GATE_THRESH = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':GATE_THRESH' )
      local GATE_FLOOR = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':GATE_FLOOR' )
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
        FLAGS=FLAGS,
        SELECTED=SELECTED, 
        POSITION=POSITION,
        LENGTH=LENGTH, 
        GAIN=GAIN, 
        FADE_IN=FADE_IN,
        FADE_OUT=FADE_OUT,
        FADE_LOW=FADE_LOW,
        FADE_HI=FADE_HI, 
        GATE_THRESH=GATE_THRESH,
        GATE_FLOOR=GATE_FLOOR,
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
        
        SetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..newidx..':POSITION', in_t[x].POSITION)
        SetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..newidx..':LENGTH', in_t[x].LENGTH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GAIN', in_t[x].GAIN )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_IN', in_t[x].FADE_IN )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_OUT', in_t[x].FADE_OUT )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_LOW', in_t[x].FADE_LOW)
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_HI', in_t[x].FADE_HI )
        SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':CHAN', in_t[x].CHAN )
        SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':FLAGS', in_t[x].FLAGS )--&1=bypassed, &2=solo
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GATE_THRESH', in_t[x].GATE_THRESH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GATE_FLOOR', in_t[x].GATE_FLOOR )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':COMP_THRESH', in_t[x].COMP_THRESH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':COMP_RATIO', in_t[x].COMP_RATIO )
        SetMediaItemTakeInfo_Value( take, 'B_SPECEDIT:'..newidx..':SELECTED', in_t[x].SELECTED )
        
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
--------------------------------------------------------------------
  function main() 
    local item = reaper.GetSelectedMediaItem(-1,0)
    if not item then return end
    local activetake = GetActiveTake(item)
    if not (activetake and not TakeIsMIDI(activetake)) then return end
    local in_t = MPL_SpectralEdits_Manipulate(activetake)
    
    for tkid =1, CountTakes (item) do 
      local take = GetTake(item, tkid-1)
      if take ~= activetake then
        MPL_SpectralEdits_Manipulate(take, {clear = true, add_table = in_t})
      end
    end
    UpdateItemInProject(item)
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(7.31,true) then 
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Propagate active take spectral edits to other takes", 0xFFFFFFFF)
  end   