-- @description Load selected tracks FX chains by name, offline mode
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?p=2137484
-- @changelog
--    + init

  function ReplaceFXChunk(track, content)
    
    local _, chunk = GetTrackStateChunk(track, '')
    -- extract input FX chain
      local rec_chain_chunk = ''
      local rec_chain_cnt = TrackFX_GetRecCount( track )
      if rec_chain_cnt ~= 0 then
        local lastfxGUID = literalize( TrackFX_GetFXGUID( track, 0x1000000 + rec_chain_cnt -1 ))
        rec_chain_chunk = chunk:match('<FXCHAIN_REC.*FXID '..lastfxGUID..'[\r\n]+WAK %d[\r\n]+>') 
      end
    
    local full_chunk = chunk:match('<FXCHAIN.*WAK %d[\r\n]+>')
    if not full_chunk then full_chunk = chunk:match('<FXCHAIN.*>') end
    if rec_chain_cnt ~= 0 then full_chunk = chunk:match('<FXCHAIN.*WAK %d[\r\n]+>[\r\n]+>') end
    
    local out_chunk = chunk:gsub(literalize(full_chunk),
[[    
<FXCHAIN
WNDRECT 100 100 400 400
SHOW 0
LASTSEL 0
DOCKED 0    

]]..
content..'\n'..
rec_chain_chunk..'\n'..'>'  )

    SetTrackStateChunk(track, out_chunk, false) 
    

  end
  ---------------------------------------------------------------------
  function MakeChainOffline(content)
    return content:gsub('BYPASS %d %d %d', 'BYPASS 0 1 0')
  end
  ---------------------------------------------------------------------
  function main()
    -- check are tracks selected
      local cnt_seltr = CountSelectedTracks(0)
      if cnt_seltr == 0 then MB('There aren`t selected tracks', 'Error', 0) return end   
      
    -- ask for input path
      local fsttr = GetSelectedTrack(0,0)
      local ret, fsttr_name = GetTrackName( fsttr )
      local retval, fn = reaper.GetUserFileNameForRead(fsttr_name..'.RfxChain', 'Select FX chain for selected track(s)', 'RfxChain' )
      if not retval then return end 
      local search_path = GetParentFolder(fn)
      
      for i = 1, cnt_seltr do
        local track = GetSelectedTrack(0,i-1)
        local ret, tr_name = GetTrackName( track )
        if tr_name ~= '' then
          local f = io.open(search_path..'/'..tr_name..'.RfxChain')
          if f then
            local content = f:read('a')
            f:close()
            --content = MakeChainOffline(content)
            ReplaceFXChunk(track, content)
          end
        end
      end
      
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end 
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then main() end