-- @description Propagate item spectral edits to other items in group
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
    if data and data.clear == true then -- clear
      local CNT = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:CNT' )
      for x =CNT-1,0,-1 do GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:DELETE:'..x ) end
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
      local BOTFREQ_CNT = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':BOTFREQ_CNT' )
      local TOPFREQ = {}
      for y = 0, TOPFREQ_CNT-1 do
        local TOPFREQ_POS = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':TOPFREQ_POS:'..y )
        local TOPFREQ_FREQ = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':TOPFREQ_FREQ:'..y )
        TOPFREQ[y+1] = {
          TOPFREQ_POS = TOPFREQ_POS,
          TOPFREQ_FREQ = TOPFREQ_FREQ,
        }
      end
      
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
        TOPFREQ_CNT = TOPFREQ_CNT,
        BOTFREQ_CNT = BOTFREQ_CNT,
        
        
      }
    end
    
    
    
    -- add
    local function addpt(take, newidx, y, pos, val, w) -- a bit of tweaking by Justin: "The biggest issue is that there is never allowed to be an empty top/bottom list, so the script will have to do a little bit of tweaking to remove the first point after adding the new point:"
      local idx = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':'..w..'FREQ_ADD:'..pos..':'..math.floor(val) )
      if y == 1 then
        if idx == 0 then idx = 1 else idx = 0 end
        GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':'..w..'FREQ_DEL:'..idx)
      end
    end
    
    
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
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_LOW', in_t[x].FADE_LOW)
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_HI', in_t[x].FADE_HI )
        SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':CHAN', in_t[x].CHAN )
        SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':FLAGS', in_t[x].FLAGS )--&1=bypassed, &2=solo
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GATE_THRESH', in_t[x].GATE_THRESH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GATE_FLOOR', in_t[x].GATE_FLOOR )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':COMP_THRESH', in_t[x].COMP_THRESH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':COMP_RATIO', in_t[x].COMP_RATIO )
        SetMediaItemTakeInfo_Value( take, 'B_SPECEDIT:'..newidx..':SELECTED', in_t[x].SELECTED )
        
                     
        local botsz = in_t[x].BOTFREQ_CNT
        for y = 1,botsz do
          local pos = in_t[x].BOTFREQ[y].BOTFREQ_POS
          local val = in_t[x].BOTFREQ[y].BOTFREQ_FREQ
          --GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':BOTFREQ_ADD:'..pos..':'..math.floor(val) )
          addpt(take, newidx, y, pos, val, "BOT")
        end
        
        local topsz = in_t[x].TOPFREQ_CNT
        for y = 1,topsz  do
          local pos = in_t[x].TOPFREQ[y].TOPFREQ_POS
          local val = in_t[x].TOPFREQ[y].TOPFREQ_FREQ
          --GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':TOPFREQ_ADD:'..pos..':'..math.floor(val) )
          addpt(take, newidx, y, pos, val, "TOP")
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
    in_t = MPL_SpectralEdits_Manipulate(activetake)
    local I_GROUPID_par = GetMediaItemInfo_Value( item, "I_GROUPID" )
    if I_GROUPID_par == 0 then return end
    
     
    
    for itemidx =1, CountMediaItems( -1) do 
      local item_child = GetMediaItem( -1, itemidx-1 )
      local I_GROUPID = GetMediaItemInfo_Value( item_child, "I_GROUPID" )
      if I_GROUPID == I_GROUPID_par and item_child ~= item then
        local take = GetActiveTake(item_child) 
        MPL_SpectralEdits_Manipulate(take, {clear = true, add_table = in_t})
      end
    end
    UpdateItemInProject(item)
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(7.31,true) then 
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Propagate item spectral edits to other items in group", 0xFFFFFFFF)
    reaper.UpdateArrange()
  end   