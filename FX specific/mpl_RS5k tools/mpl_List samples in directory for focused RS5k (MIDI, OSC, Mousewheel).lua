-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description List samples in directory for focused RS5k (MIDI, OSC, Mousewheel)
-- @noindex
-- @changelog
--    #header

-- note : mousewheel works only when arrange focused after RS5k focus

  local function wrap(val, min,max) --local min,max 
    if val > max then return min end
    if val < min then return max end
    return val
  end
  
function main(mode, val, res)
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    ret, fn = reaper.TrackFX_GetNamedConfigParm(track, fxnumberOut, "FILE0")
    if not ret then return end
    fn = fn:gsub('\\', '/')
    
    path = fn:reverse():match('[%/]+.*'):reverse():sub(0,-2)
    cur_file =     fn:reverse():match('.-[%/]'):reverse():sub(2)
    -- get files list
      local files = {}
      local i = 0
      repeat
      local file = reaper.EnumerateFiles( path, i )
      if file then
        files[#files+1] = file
      end
      i = i+1
      until file == nil
      
    -- search file list
      local trig_file
      if #files < 2 then return end
      for i = 1, #files do
        if files[i] == cur_file then cur_id = i break end 
      end
      
      if mode == 0 then
        id = math.floor((val/res) * (#files-1)) + 1
       elseif mode==2 then
        local c if val < 0 then c = -1 else c = 1 end
        id = cur_id + c*(val/val)
        
      end
      
      if id then
        out_id = wrap(id, 1, #files)
        if out_id then trig_file = path..'/'..files[out_id] end
      end
      
      if trig_file and fn ~= trig_file then 
        --reaper.Undo_BeginBlock()
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "FILE0", trig_file)
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "DONE", "")
        --reaper.Undo_EndBlock('List samples in directory for focused RS5k', 1)
      end
  end
  
  ---------------------------------------------------
  
  is_new_value,_,_,_,mode,res,val = reaper.get_action_context()
  if is_new_value then main(mode, val, res) end