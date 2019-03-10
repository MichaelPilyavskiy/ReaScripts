-- @description Dump RetrospectiveRecord tracker log to selected track
-- @version 1.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Dump MIDI messages log from RetrospectiveRecord_tracker JSFX as new item on selected track placed at edit cursor
-- @changelog
--    - drop support for old plugin with no sync option
--    + create new item around edit cursor, build proper take offset
--    + use play cursor if dumping while playing


     

  --NOT gfx NOT reaper
  ---------------------------------------------------------
  function CollectData()
    gmem_attach('mpl_RetrospectiveRecord') 
    local max_buf = 3500000
    local cnt_entries = reaper.gmem_read(0)
    local t = {}
    local ts_cur0
    for i = 1, cnt_entries do
      local midimsg = reaper.gmem_read(i)
      local msg1 = midimsg & 0xFF
      local msg2 = (midimsg >> 8) & 0xFF
      local msg3 = (midimsg >> 16) & 0xFF
      local ts_cur = gmem_read(i+max_buf)
      if not ts_cur0 then ts_cur0 = ts_cur end
      t[i] = {midimsg=midimsg,
              msg1 =msg1,
              msg2=msg2,  
              msg3=msg3,
              ts = ts_cur-ts_cur0}
    end
    
    return t, gmem_read(8000000)==1, gmem_read(8000001)
  end 
  ---------------------------------------------------------
  function AddDataToTrack(data, sync_support, playpos)
    if not data or #data < 1 then return end 
    if not sync_support then MB('Please update mpl_Retrospective Record JSFX', 'Error', 0) return end 
    local tr = GetSelectedTrack(0,0)
    if not tr then MB('Select track','Dump RetrospectiveRecord tracker log',0) return end
    
    ---------
    local curpos = GetCursorPositionEx( 0 )
    if GetPlayStateEx( 0 )&1==1 then curpos =  GetPlayPosition2Ex( 0 ) end
    local it_len0 = data[#data].ts
    local it = CreateNewMIDIItemInProj( tr, curpos, it_len0 ) 
    SetMediaItemInfo_Value( it, 'B_LOOPSRC', 0 )
    local take 
    if it then take = GetActiveTake(it) end
    if not take then return end 
    ---------
    local proj_offs =  GetProjectTimeOffset( 0, false )
    if playpos < 0 then
      SetMediaItemInfo_Value( it, 'D_POSITION' , curpos)
      SetMediaItemInfo_Value( it, 'D_LENGTH' , it_len0)
     else
      playpos = playpos - proj_offs
      if playpos >= curpos then
        SetMediaItemInfo_Value( it, 'D_LENGTH' , playpos  - curpos)
        SetMediaItemTakeInfo_Value( take, 'D_STARTOFFS',  curpos + it_len0 - playpos  )
       else
        SetMediaItemInfo_Value( it, 'D_POSITION' , playpos - it_len0)
        SetMediaItemInfo_Value( it, 'D_LENGTH' , curpos - playpos + it_len0)
      end
    end
    
    
    ---------
    local s_pack = string.pack
    local MIDIstr= ''
    local lastPPQ
    local flags = 0
    for i = 1, #data do 
      local PPQ = MIDI_GetPPQPosFromProjTime( take, curpos + data[i].ts )
      if not lastPPQ then lastPPQ = PPQ end
      local offs = math.floor(PPQ - lastPPQ)
      lastPPQ = PPQ
      MIDIstr = MIDIstr..s_pack("i4BI4BBB", offs, flags, 3, data[i].msg1, data[i].msg2, data[i].msg3)
    end
    MIDIstr = MIDIstr..s_pack("i4BI4BBB", 0, flags, 3, 0xB, 123, 0)
    ---------
    MIDI_SetAllEvts(take, MIDIstr)
    return true
  end
  
 
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.966,true)    
  if ret and ret2 then 
    local midi_t, sync_support, playpos = CollectData()
    local ret = AddDataToTrack(midi_t,sync_support, playpos)
    if ret then gmem_write(0,0) end-- clear buffer
  end