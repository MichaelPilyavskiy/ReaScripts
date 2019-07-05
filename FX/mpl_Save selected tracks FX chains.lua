-- @description Save selected tracks FX chains
-- @version 1.06
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?p=2137484
-- @changelog
--    # fix loading ext config
  
  
  
  conf = {}
  ---------------------------------------------------
  function ExtState_Def()  
    return {
            saving_folder = '',
            ES_key = 'MPL_SaveSelTrChains',
            }
  end
  ---------------------------------------------------
  function ExtractFXChunk(track )
    if TrackFX_GetCount( track ) == 0 then return end 
    local _, chunk = GetTrackStateChunk(track, '')
    local lastfxGUID = literalize(TrackFX_GetFXGUID( track, TrackFX_GetCount( track )-1))
    local out_ch = chunk:match('<FXCHAIN(.*FXID '..lastfxGUID..'[\r\n]+WAK %d).*>')
    return out_ch
  end
  ---------------------------------------------------------------------
  function main(conf)
    -- check are tracks selected
      local cnt_seltr = CountSelectedTracks(0)
      if cnt_seltr == 0 then MB('There aren`t selected tracks', 'Error', 0) return end   
      
    -- ask for output path
      local retval, projfn = reaper.EnumProjects( -1, '' )
      local proj_path = GetProjectPath(0,'')..'/'
      local fn_template = 'FX_Chains'
      if projfn == '' then 
        proj_path = GetResourcePath()..'/FXChains/' 
        local ts = os.date():gsub('%:', '-')
        fn_template = 'UntitledProject_'..ts
      end
      local retval0
      if conf.saving_folder and conf.saving_folder:gsub('%s+', '') ~= '' then 
        saving_folder = conf.saving_folder
        retval0 = 1
       else 
        retval0,  saving_folder = JS_Dialog_BrowseForSaveFile('Save selected tracks FX Chains', proj_path, fn_template, ".RfxChain")
      end
      if retval0 ~= 1 then return end
      
    -- extract chunks
      local t = {}
      for i = 1, cnt_seltr do
        local tr = GetSelectedTrack(0,i-1)
        local ch = ExtractFXChunk(tr)
        if ch then  t[#t+1] = {name = ({GetTrackName( tr )})[2]:gsub('[%/%\\%:%*%?%"%<%>%|]+', '_'), chunk = ch} end
      end
      
    -- write files
      if #t ==0 then return end 
      local ret1 = RecursiveCreateDirectory(saving_folder, 1)
      --if ret1 == 0 then MB('Can`t create path', 'Error', 0) return end   
      for i = 1, #t do
        local fname = t[i].name
        --local f = io.open (saving_folder..'/'..fname..'.RfxChain', 'r')
        --[[if f then
          if fname:match('%(v[%d]+%)') then
            local vers = fname:match('.*(%(([%d]+)%))')
            if tonumber(vers) then fname = fname:gsub('%([%d]+%)', '(v'..(tonumber(vers)+1)..')') else fname = fname..' (1)' end
           else
            fname = fname..' (1)'
          end
          f:close()
        end]]
        local f = io.open (saving_folder..'/'..fname..'.RfxChain', 'w')
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
  if ret and ret2 then 
    if JS_Dialog_BrowseForSaveFile then 
      ExtState_Load(conf)
      main(conf) 
     else 
      MB('Missed JS ReaScript API extension', 'Error', 0) 
    end
  end