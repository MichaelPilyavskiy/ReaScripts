-- @description Split selected item at waveform fall below zero
-- @version 1.02
-- @author MPL
-- @changelog
--  # use item length as loop end

  function main()
    -- get item
    local it = GetSelectedMediaItem(0,0)
    if not it then return end
    local take = GetActiveTake(it)
    if not take or TakeIsMIDI(take) then return end
    local itpos = GetMediaItemInfo_Value( it, 'D_POSITION'  )
    local itlen = GetMediaItemInfo_Value( it, 'D_LENGTH'  )
    
    -- get samples
    local data = {}
    local src =  GetMediaItemTake_Source( take )
    if not src then src = GetMediaSourceParent( src ) end
    local srclen = GetMediaSourceLength( src ) 
    local id = 0
    local SR_spls =  GetMediaSourceSampleRate( src ) 
    local samplebuffer = new_array(SR_spls);
    local accessor = CreateTakeAudioAccessor( take )
    
    sp_t = {}
    idx = 1
    for pos = 0, itlen do--srclen do
      GetAudioAccessorSamples( accessor, SR_spls, 1, pos, SR_spls, samplebuffer ) 
      for i = 2, SR_spls do 
        if samplebuffer[i] then 
          if samplebuffer[i-1] > 0 and samplebuffer[i] < 0 then 
            sp_t[idx] = itpos + pos+ (i-1)/SR_spls
            idx = idx +1 
          end
        end
      end
      samplebuffer.clear() 
    end
    DestroyAudioAccessor( accessor )
    
    -- get split points
    
    for i = 1, #sp_t do
      it = SplitMediaItem( it, sp_t[i] )
    end
    
    reaper.UpdateArrange()
  end 
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.30) if ret then local ret2 = VF_CheckReaperVrs(5.95,true) if ret2 then
      Undo_BeginBlock2( 0 )
      main() 
      Undo_EndBlock2( 0, 'Split selected items at waveform fall below zero', 4 )
  end end   