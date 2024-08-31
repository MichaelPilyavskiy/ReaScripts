-- @description Normalize selected items takes loudness to XdB
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
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
    ---------------------------------------------------
  function main(loudtype, loudvalue)
    Undo_BeginBlock2( 0 )
    for i = 1, CountSelectedMediaItems(0) do
      local it =  reaper.GetSelectedMediaItem( 0, i-1)
      mpl_norm_ApplyLUFSNormalize(it,loudtype, loudvalue)
    end
  end
  ----------------------------------------------------------------------
  function mpl_norm_ApplyLUFSNormalize(it,loudtype, loudvalue) 
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
  if VF_CheckReaperVrs(6.44,true) then 
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
  end
  
  
  