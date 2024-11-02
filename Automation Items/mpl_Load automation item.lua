-- @description Load automation item
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Load automation item 1.lua
--    [main] . > mpl_Load automation item 2.lua
--    [main] . > mpl_Load automation item 3.lua
--    [main] . > mpl_Load automation item 4.lua
--    [main] . > mpl_Load automation item 5.lua
--    [main] . > mpl_Load automation item 6.lua
--    [main] . > mpl_Load automation item 7.lua
--    [main] . > mpl_Load automation item 8.lua
--    [main] . > mpl_Load automation item 9.lua
--    [main] . > mpl_Load automation item 10.lua
-- @changelog
--    + init

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
  ------------------------------------------------------------------------
  function ParseAI(content)
    local t = {points={}}
    for line in content:gmatch('[^\r\n]+') do
      if line:match('SRCLEN (%d)') then t.SRCLEN = tonumber(line:match('SRCLEN (%d)')) end
      if line:match('PPT') then 
        local posQN,value,shape, tension  = line:match('PPT ([%d%p]+) ([%d%p]+) ([%d%p]+) ([%d%p]+)')
        t.points[#t.points+  1] =  {posQN=tonumber(posQN),value=tonumber(value),shape=tonumber(shape), tension=tonumber(tension)}
      end
    end
    return t
  end
  ------------------------------------------------------------------------
  function main(env, slot) 
    if not env then return end 
    if not slot then return end 
    local fp = reaper.GetResourcePath()..'/AutomationItems/'..slot..'.ReaperAutoItem'
    local f = io.open(fp, 'rb')
    if f then 
      content = f:read('a')
      f:close()
     else
      return
    end
    
    t = ParseAI(content)
    local curpos = reaper.GetCursorPosition()
    local newAI = reaper.InsertAutomationItem( env, -1, curpos, 1 )
    
    reaper.GetSetAutomationItemInfo( env, newAI, 'D_LENGTH', reaper.TimeMap_QNToTime( t.SRCLEN ), true )
    reaper.GetSetAutomationItemInfo( env, newAI, 'D_POOL_QNLEN', t.SRCLEN, true )
    scaling_mode = reaper.GetEnvelopeScalingMode( env )
    for i = 1, #t.points do
      val = reaper.ScaleToEnvelopeMode( scaling_mode, t.points[i].value )
      reaper.InsertEnvelopePointEx( env, newAI, reaper.TimeMap_QNToTime(t.points[i].posQN) + curpos, val, t.points[i].shape, t.points[i].tension, false, true )
    end
    reaper.Envelope_SortPointsEx( env, newAI )
  end
  ------------------------------------------------------------------------
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.68,true) then 
    local slot = ({reaper.get_action_context()})[2]:match('mpl_Load automation item (%d+)')
    Undo_BeginBlock() 
    local env = reaper.GetSelectedEnvelope( -1 )
    main(env, slot)
    Undo_EndBlock('mpl Load automation item', 0xFFFFFFFF)
  end
  
  