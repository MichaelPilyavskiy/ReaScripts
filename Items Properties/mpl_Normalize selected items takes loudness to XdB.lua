-- @description Normalize selected items takes loudness to XdB
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
-- @metapackage
-- @provides
--   [main] . > mpl_Normalize selected items takes RMS to -3dB.lua
--   [main] . > mpl_Normalize selected items takes RMS to -10dB.lua
--   [main] . > mpl_Normalize selected items takes RMS to -14dB.lua
--   [main] . > mpl_Normalize selected items takes RMS to -18dB.lua
--   [main] . > mpl_Normalize selected items takes LUFS to -7dB.lua
--   [main] . > mpl_Normalize selected items takes LUFS to -11dB.lua
--   [main] . > mpl_Normalize selected items takes LUFS to -14dB.lua
--   [main] . > mpl_Normalize selected items takes LUFS to -18dB.lua
--   [main] . > mpl_Normalize selected items takes LUFS to -23dB.lua

  function main(loudtype, loudvalue)
    Undo_BeginBlock2( 0 )
    for i = 1, CountSelectedMediaItems(0) do
      local it =  reaper.GetSelectedMediaItem( 0, i-1)
      ApplyLUFSNormalize(it,loudtype, loudvalue)
    end
  end
  ----------------------------------------------------------------------
  function ApplyLUFSNormalize(it,loudtype, loudvalue)
    if not (loudtype and loudvalue) then return end
    local take = GetActiveTake(it)
    if not take then return end
    local src = GetMediaItemTake_Source( take )
    if not src then return end
     value = CalculateNormalization( src, 
                                    loudtype, 
                                    loudvalue, 
                                    0,--normalizeStart, 
                                    0)--normalizeEnd )
    SetMediaItemTakeInfo_Value( take, 'D_VOL',value )
    UpdateItemInProject( it )
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.08) if ret then local ret2 = VF_CheckReaperVrs(6.44,true) if ret2 then 
    local scr_name = ({reaper.get_action_context()})[2]
    local loudtype, loudvalue
    local loudtypestr, loudvaluestr = scr_name:match('Normalize selected items takes ([%a]+) to ([%d%a%p]+)dB%.lua')
    if not (loudtypestr and loudvaluestr) then return end
    if loudtypestr:match('LUFS') then loudtype = 0 
     elseif loudtypestr:match('RMS') then loudtype = 1  
    end 
    if tonumber(loudvaluestr) then loudvalue = tonumber(loudvaluestr) end 
    Undo_BeginBlock2( 0 )
    main(loudtype, loudvalue)
    Undo_EndBlock( 'Normalize items takes '..loudtypestr..' to '..loudvaluestr..'dB', 0xFFFFFFFF )
  end end 
  
  
  