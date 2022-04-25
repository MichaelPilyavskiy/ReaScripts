-- @description Save selected tracks FX chains (no prompt, saved project only)
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + use wildcards (editable inside script)
  
  pat = [[#resourcepath/fxchains/projects/#title OR #filename/#tracknum-#trackname-#datestamp_%d%m%y]]
  
  ---------------------------------------------------
  function ExtractFXChunk(track )
    if TrackFX_GetCount( track ) == 0 then return end 
    local _, chunk = GetTrackStateChunk(track, '')
    local lastfxGUID = literalize(TrackFX_GetFXGUID( track, TrackFX_GetCount( track )-1))
    local out_ch = chunk:match('<FXCHAIN(.*FXID '..lastfxGUID..'[\r\n]+WAK %d).*>')
    return out_ch
  end
  ---------------------------------------------------------------------
  function main(pat)
    -- check are tracks selected
      local cnt_seltr = CountSelectedTracks(0)
      if cnt_seltr == 0 then MB('There aren`t selected tracks', 'Error', 0) return end   
      
    -- get data
      local retval, projfn = reaper.EnumProjects( -1, '' )
      local  proj_path = GetProjectPath(0,'')
      if projfn == '' then return end
      
      local _, title = reaper.GetSetProjectInfo_String( 0, 'PROJECT_TITLE', '', false )
      local resourcepath = reaper.GetResourcePath()
      local ProjectName = reaper.GetProjectName( 0 ):gsub('%.rpp',''):gsub('%.RPP','')
      local datestamp = os.date()
      if pat:match('#datestamp_[%%%d]+') then
        local dspat = pat:match('#datestamp_([%%%a]+)')
        datestamp = os.date(dspat)
      end
      
      
    -- extract chunks
      local t = {}
      for i = 1, cnt_seltr do
        local tr = GetSelectedTrack(0,i-1)
        local ch = ExtractFXChunk(tr)
        if ch then  t[#t+1] = {ptr = tr,
                               name = ({GetTrackName( tr )})[2]:gsub('[%/%\\%:%*%?%"%<%>%|]+', '_'), 
                               chunk = ch,
                               id =  CSurf_TrackToID( tr, false )
                               } 
                              end
      end
      
      
      
    -- write files
      if #t ==0 then return end 
      --if ret1 == 0 then MB('Can`t create path', 'Error', 0) return end   
      for i = 1, #t do 
        local title2 = title if title2 == '' then title2 = ProjectName end
        local outfp =  pat:gsub('#resourcepath',resourcepath)
                          :gsub('#title OR #filename', title2)
                          :gsub('#filename', ProjectName)
                          :gsub('#title', title)
                          :gsub('#tracknum', t[i].id)
                          :gsub('#trackname', t[i].name)
                          :gsub('#datestamp_[%%%a]+', datestamp)
                          ..'.RfxChain'
        local ret1 = RecursiveCreateDirectory(GetParentFolder(outfp), 1)
        local f = io.open (outfp, 'w')
        if f then
          f:write(t[i].chunk)
          f:close()
        end
      end
      
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end 
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then main(pat) end