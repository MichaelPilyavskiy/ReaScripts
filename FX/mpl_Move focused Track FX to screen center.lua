-- @description Move focused Track FX to screen center
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # improve fix chunk modification
  
-------------------------------------------------
  function main()
    local track
    local retval, tracknumber, itemnumber, fxnumber = GetFocusedFX()
    if retval ~= 1 then return end 
    if tracknumber == 0 then tr = GetMasterTrack( 0 ) else tr = GetTrack(0, tracknumber -1 ) end
    if not tr then return end
    Data_ModifyFloat(tracknumber,fxnumber)
  end
  -----------------------------------------------
  function Data_ModifyFloat(trid,fx)
    local tr= GetTrack(0,trid-1)
    if not tr then return end
    local retval, tr_chunk = GetTrackStateChunk( tr, '', false )
    local fxGUID_check = TrackFX_GetFXGUID( tr, fx )
    for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
      local fxGUID = fxchunk:match('FXID (.-)\n')
      if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end

      if fxGUID:match(literalize(fxGUID_check):gsub('%s', '')) then
        local fxchunk_param_line = fxchunk:match('(FLOAT .-)\n')
        if not fxchunk_param_line then fxchunk_param_line = fxchunk:match('(FLOATPOS .-)\n') end
         temp_t = {}
        for num in fxchunk_param_line:gmatch('[^%s]+') do temp_t [#temp_t+1] = tonumber(num) end --table.remove(temp_t,0)
        local _, _, scr_w, scr_h = reaper.my_getViewport(0,0,0,0,0,0,0,0, true)
        temp_t[1] = math.ceil((scr_w - temp_t[3]) /2)
        temp_t[2] = math.ceil((scr_h - temp_t[4]) /2)
        local outstr = 'FLOAT '..table.concat(temp_t, ' ')
          
        fxchunk_mod = fxchunk:gsub(fxchunk_param_line, outstr..'\n')
                  
        tr_chunk = tr_chunk:gsub(literalize(fxchunk), fxchunk_mod)
        SetTrackStateChunk( tr, tr_chunk, false )
        return
      end
    end
  end  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
 --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end
  end
  
