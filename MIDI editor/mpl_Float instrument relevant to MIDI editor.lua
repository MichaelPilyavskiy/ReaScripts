-- @version 1.03
-- @author MPL
-- @description Float instrument relevant to MIDI editor
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # use Various_function


--[[
    1.2 23.02.2017
      # fix send instrument lookup (http://github.com/MichaelPilyavskiy/ReaScripts/issues/4)
    1.1 22.02.2017
      + Search instruments in send destination tracks
]]

local scr_title = 'Float instrument relevant to MIDI Editor'

function main()
  local act_editor = reaper.MIDIEditor_GetActive()
  if not act_editor then return end
  local take = reaper.MIDIEditor_GetTake(act_editor)
  if not take then return end
  local take_track = reaper.GetMediaItemTake_Track(take)
  
  -- search vsti on parent track
    local ret1 = FloatInstrument(take_track )
    if ret1 then return end
    
  ApplyFunctionToTrackInTree(take_track, FloatInstrument)
end
---------------------------------------------------------------------
  function CheckFunctions(str_func)
    SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        Undo_BeginBlock()
        main()
        Undo_EndBlock( scr_title, -1 )
      end
      
     else
      MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
--------------------------------------------------------------------
  CheckFunctions('FloatInstrument')
