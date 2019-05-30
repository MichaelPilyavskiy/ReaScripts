-- @description Split focused ReaEQ to LR routing
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    #header
  
  -- NOT reaper NOT gfx
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  function lit(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end
  -----------------------------------------------------------------------------
  function ModNewReaEQChunk(REQchunk, fxGUID, modGUID, modXY, renamestr, fx, num_params, link_str)
    -- geb new GUID
      local REQchunk_new = REQchunk
      if modGUID then 
        local REQchunk_new = REQchunk:gsub(lit(fxGUID), genGuid('' ))
      end
          
    -- shift screen position
      if modXY then
        local floatpos = REQchunk:match('FLOAT.-\n') 
        if floatpos then
          local xy_shift = 50
          local floatpos_t = {} for num in floatpos:gmatch('[^%s]+') do if tonumber(num) then floatpos_t[#floatpos_t+1] = math.floor(num) end end
          floatpos_t[2] = floatpos_t[2] + xy_shift
          floatpos_t[1] = floatpos_t[1] + xy_shift
          REQchunk_new = REQchunk_new:gsub(floatpos, 'FLOAT '..table.concat(floatpos_t, ' ')..'\n')
        end
      end
      
    -- rename
      if renamestr then
        local edited_line = REQchunk_new:match('VST.-\n')
        if edited_line then
          local t1 = {}
          for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
          local t2 = {}
          local segm
          for i = 1, #t1 do 
            segm = t1[i]
            if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
            if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
          end
          if t2[5] == '""' then 
            t2[5] = '"'..t2[2]:gsub('"', '')..' '..renamestr..'"' 
           else 
            t2[5] = t2[5]:gsub('"','')..' (Side)' 
          end
          REQchunk_new = REQchunk_new:gsub(lit(edited_line), table.concat(t2, ' ')..'\n')
        end
      end
    
    -- add parameter links
      local PM_str = ''
      for param_id = 0,  num_params-3 do
        PM_str = PM_str..
      [[<PROGRAMENV ]]..param_id..[[ 0
        PARAMBASE 0
        LFO 0
        LFOWT 1 1
        AUDIOCTL 0
        AUDIOCTLWT 1 1
        PLINK 1 ]]..link_str..' '..param_id..[[ 0
      >]]..'\n'  
      end
      REQchunk_new = REQchunk_new:gsub('WAK',PM_str..'WAK' )
    
    return REQchunk_new
  end
  
  --[[
]]  
  -----------------------------------------------------------------------------
  function MPL_SplitReaEq()
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX()
    if not (retval ==1 and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    local num_params = TrackFX_GetNumParams( tr, fx )
    
    -- copy/mod chunk
      local fxGUID = TrackFX_GetFXGUID( tr, fx )
      local ret, chunk = GetTrackStateChunk(tr, '', false)
      local REQchunk = chunk:match(lit('<VST "VST: ReaEQ')..'.-'..lit(fxGUID)..'.-WAK %d')
      if not REQchunk then return end
      local link_strFX1 = (fx+1)..':'..1
      local link_strFX2 = (fx+1)..':'..-1
      local REQchunk_old = ModNewReaEQChunk(REQchunk, fxGUID, false,  false,  '(Left)', fx, num_params, link_strFX1) 
      local REQchunk_new = ModNewReaEQChunk(REQchunk, fxGUID, true,   true,   '(Right)', fx, num_params, link_strFX2)
      chunk = chunk:gsub(lit(REQchunk), REQchunk_old..'\n'..REQchunk_new)
      SetTrackStateChunk(tr, chunk , true)
      
    -- set IO pins 
      -- fx 1 in
      TrackFX_SetPinMappings( tr, fx, 0, 0, 1, 0 )
      TrackFX_SetPinMappings( tr, fx, 0, 1, 0, 0 )
      -- fx 1 out
      TrackFX_SetPinMappings( tr, fx, 1, 0, 1, 0 )
      TrackFX_SetPinMappings( tr, fx, 1, 1, 0, 0 )
      -- fx 2 in
      TrackFX_SetPinMappings( tr, fx+1, 0, 0, 0, 0 )
      TrackFX_SetPinMappings( tr, fx+1, 0, 1, 2, 0 )
      -- fx 2 out
      TrackFX_SetPinMappings( tr, fx+1, 1, 0, 0, 0 )
      TrackFX_SetPinMappings( tr, fx+1, 1, 1, 2, 0 )     
      
  end
  ----------------------------------------------------------------------------- 
  MPL_SplitReaEq()