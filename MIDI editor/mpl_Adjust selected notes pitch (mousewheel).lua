-- @description Adjust selected notes pitch (mousewheel)
-- @version 2.04
-- @author MPL
-- @metapackage
-- @provides
--    [main=midi_editor] . > mpl_Adjust selected notes pitch (mousewheel).lua
--    [main=midi_editor] . > mpl_Adjust selected notes pitch obey keysnap (mousewheel).lua
--    [main=midi_editor] . > mpl_Adjust selected notes pitch by octave (mousewheel).lua
--    [main=midi_editor] . > mpl_Adjust selected notes pitch (mousewheel, inverted).lua
--    [main=midi_editor] . > mpl_Adjust selected notes pitch obey keysnap (mousewheel, inverted).lua
--    [main=midi_editor] . > mpl_Adjust selected notes pitch by octave (mousewheel, inverted).lua
-- @website http://forum.cockos.com/showthread.php?t=188335  
-- @changelog
--    # VF independent

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

  function MoveNotesVertically_Scale(pitch, dir, pat)
    local note = (pitch % 12)
    
    if dir > 0 then 
      for i = note+1, 11 do
        if pat[i] == true then return pitch - (pitch % 12) + i end -- next note match scale
      end
      for i = 0, 11 do
        if pat[i] == true then return pitch - (pitch % 12) + 12 + i end -- next note match scale + 1ocattave
      end
    end
    
    if dir < 0 then 
      for i = note-1, 0, -1 do
        if pat[i] == true then return pitch - (pitch % 12) + i end -- next note match scale
      end
      for i = 11, 0, -1 do
        if pat[i] == true then return pitch - (pitch % 12) - 12 + i end -- next note match scale - 1ocattave
      end
    end
    
    return pitch
  end    
  ----------------------------------------------------------------------      
  function MoveNotesVertically(take, dir, oct_shift, keysnap_pat, inverted)
    local dir_int = 1
    if dir then dir_int = -1 end
    if inverted then dir_int = dir_int * -1 end
    local tableEvents = {}
    local t = 0
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1
    local offset, flags, msg
    local val = 1
    if oct_shift then val = 12 end
    while stringPos < MIDIlen-12 do
      offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
      out_val = msg:byte(2)
      local new_pitch =  msg:byte(2)  - dir_int*val
      if keysnap_pat then 
        new_pitch = MoveNotesVertically_Scale(msg:byte(2), dir_int, keysnap_pat) 
      end
      new_pitch = math.max(0,math.min(new_pitch,127)) -- limi from 0 to 127
      if msg:len() > 1 and ( msg:byte(1)>>4 == 0x9 or msg:byte(1)>>4 == 0x8 ) and flags&1==1 then  out_val = new_pitch end
      t = t + 1
      tableEvents[t] = string.pack("i4Bi4BBB", offset, flags, 3, msg:byte(1), out_val, msg:byte(3) or 0 )
    end
    
    MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    MIDI_Sort(take)
  end
  ----------------------------------------------------------------------
  function GetPattern(root, scale)
    local pat,ex = {}
    local id = 0 
    for num in scale:gmatch('%d') do 
      pat[id] = num+root>0 
      id = id + 1
      if num+root>0 then ex = true end -- check if at least one note in pattern
    end
    if ex then return pat end
  end
  ---------------------------------------------------------------------------------------------------------------------
  function VF_GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end  
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then 
  
    is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    if not is_new_value then return end
    if val == 0 then return end
    
    local midieditor = MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  MIDIEditor_GetTake( midieditor )
    if not take then return end
    
    local filename = ({reaper.get_action_context()})[2]
    local script_title = GetShortSmplName(filename):gsub('%.lua','')
    local oct_shift = script_title:match('octave')~= nil
    local inverted = script_title:match('inverted')~= nil
    local keysnap = script_title:match('keysnap')~= nil
    local keysnap_pat
    if keysnap and MIDIEditor_GetSetting_int( midieditor, 'scale_enabled' )~=0 then 
      local root = MIDIEditor_GetSetting_int( midieditor, 'scale_root' )
      local scale= ({MIDIEditor_GetSetting_str( midieditor, 'scale', '' )})[2]
      local pat  = GetPattern(root, scale)
      if pat then keysnap_pat = pat end
    end
       
    Undo_BeginBlock()  
    MoveNotesVertically(take, val>0, oct_shift, keysnap_pat, inverted)
    Undo_EndBlock('mpl_Adjust selected notes pitch (mousewheel)', 4)  
    
  end 