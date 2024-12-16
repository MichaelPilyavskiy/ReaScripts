-- @description Set selected items timestretch, pitchshift modes
-- @version 1.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--   [main] . > mpl_Set selected items takes pitch shift mode to Dirac LE.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to elastique 2.2.8 efficient.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to elastique 2.2.8 pro.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to elastique 2.2.8 soloist.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to elastique 3.3.0 efficient.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to elastique 3.3.0 pro.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to elastique 3.3.0 soloist.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to project default.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to ReaReaRea.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to Rrreeeaaa.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to Rubber Band.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to Simple windowed.lua
--   [main] . > mpl_Set selected items takes pitch shift mode to SoundTouch.lua
--   [main] . > mpl_Set selected items stretch marker fade size to 2.5ms.lua
--   [main] . > mpl_Set selected items stretch marker fade size to 5ms.lua
--   [main] . > mpl_Set selected items stretch marker fade size to 10ms.lua
--   [main] . > mpl_Set selected items stretch marker fade size to 15ms.lua
--   [main] . > mpl_Set selected items time stretch mode to default.lua
--   [main] . > mpl_Set selected items time stretch mode to Balanced.lua
--   [main] . > mpl_Set selected items time stretch mode to Tonal.lua
--   [main] . > mpl_Set selected items time stretch mode to Transient.lua
--   [main] . > mpl_Set selected items time stretch mode to No pre echo reduction.lua      
-- @changelog
--    # backward compatibility for 3.3.3

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

------------------------------------------------------------------------------
  function main(params)
    if not params then return end
  
    for i = 1, CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem(0,i-1) 
      for takeidx = 1,  CountTakes( item ) do
        local take =  GetTake( item, takeidx-1 )
        if ValidatePtr2( 0, take, 'MediaItem_Take*' ) then 
          if params.mode_pitchshift and params.pitchshift and params.pitchshift_reset~= true then SetMediaItemTakeInfo_Value( take, 'I_PITCHMODE',params.pitchshift<<16  ) end
          if params.pitchshift_reset== true then SetMediaItemTakeInfo_Value( take, 'I_PITCHMODE',-1 ) end
          
          if params.mode_smfadesz == true and params.smfadesz then SetMediaItemTakeInfo_Value( take, 'F_STRETCHFADESIZE',params.smfadesz/1000 ) end
          if params.mode_timestretch == true and params.timestretch then SetMediaItemTakeInfo_Value( take, 'I_STRETCHFLAGS',params.timestretch ) end
        end
      end
    end
    
    
    reaper.UpdateArrange()
  end
  ------------------------------------------------------------------------------
  function parse_srcipt_name(scr_name)
    params = {}
    params.mode_pitchshift = scr_name:match('pitch shift mode')~= nil 
    params.mode_smfadesz = scr_name:match('stretch marker fade size')~= nil 
    params.mode_timestretch = scr_name:match('time stretch mode')~= nil
    -- check if pshift mode is supported
    if params.mode_pitchshift == true then 
      if scr_name:match('Dirac LE')~= nil then params.pitchshift_name = 'Dirac LE' end 
      if scr_name:match('elastique 2.2.8 efficient')~= nil then params.pitchshift_name = 'elastique 2.2.8 efficient' end 
      if scr_name:match('elastique 2.2.8 pro')~= nil then params.pitchshift_name = 'elastique 2.2.8 pro' end 
      if scr_name:match('elastique 2.2.8 soloist')~= nil then params.pitchshift_name = 'elastique 2.2.8 soloist' end 
      if scr_name:match('elastique 3.3.0 efficient')~= nil then params.pitchshift_name = 'elastique 3.3.0 efficient' end 
      if scr_name:match('elastique 3.3.0 pro')~= nil then params.pitchshift_name = 'elastique 3.3.0 pro' end 
      if scr_name:match('elastique 3.3.0 soloist')~= nil then params.pitchshift_name = 'elastique 3.3.0 soloist' end 
      if scr_name:match('ReaReaRea')~= nil then params.pitchshift_name = 'ReaReaRea' end 
      if scr_name:match('Rrreeeaaa')~= nil then params.pitchshift_name = 'Rrreeeaaa' end 
      if scr_name:match('Rubber Band')~= nil then params.pitchshift_name = 'Rubber Band' end 
      if scr_name:match('Simple windowed')~= nil then params.pitchshift_name = 'Simple windowed' end 
      if scr_name:match('SoundTouch')~= nil then params.pitchshift_name = 'SoundTouch' end 
      if scr_name:match('project default')~= nil then params.pitchshift_reset = true end 
      if params.pitchshift_name and params.pitchshift_reset~= true then 
        local supported 
        for mode=0,32 do
          local retval, str = reaper.EnumPitchShiftModes( mode )
          if retval and str then  
            str = str:gsub('%.','')
            str = str:lower():gsub('é','e')-- ignore non unicode str
            local pitchshift_name = params.pitchshift_name:lower():gsub('é','e')-- ignore non unicode str 
            pitchshift_name = pitchshift_name:gsub('%.','') 
            if str:match(pitchshift_name) 
              or str:match(pitchshift_name:gsub(330,333)) -- fix for backward compatibility
             then 
              supported = true 
              params.pitchshift =mode 
              break 
            end
          end
        end
      end
    end
    
    -- stretch markers fade sz
    if params.mode_smfadesz == true then
      if scr_name:match('%s[%d%.]+ms')~= nil then 
        local smfadesz = scr_name:match('%s([%d%.]+)ms')
        if smfadesz and tonumber(smfadesz) then params.smfadesz = tonumber(smfadesz) end 
      end
    end
    
    -- time stretch
    if params.mode_timestretch == true then
      if scr_name:match('default')~= nil then params.timestretch = 0 end 
      if scr_name:match('Balanced')~= nil then params.timestretch = 1 end 
      if scr_name:match('Tonal')~= nil then params.timestretch = 2 end 
      if scr_name:match('Transient')~= nil then params.timestretch = 4 end 
      if scr_name:match('No pre echo reduction')~= nil then params.timestretch = 5 end 
    end
    
    
    return params
  end
  ---------------------------------------------------------------------------------------------------------------------
  function VF_GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end 
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(7.19,true) then  
    local scr_name = ({reaper.get_action_context()})[2]
    scr_name = VF_GetShortSmplName(scr_name)
    local params = parse_srcipt_name(scr_name) 
    reaper.Undo_BeginBlock()
    main(params)
    reaper.Undo_EndBlock('Set selected items timestretch, pitchshift modes', 0xFFFFFFFF)
  end  