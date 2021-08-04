-- @description mpl_QuantizeTool change knob1 (MIDI, OSC, mousewheel)
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @noindex

reaper.gmem_attach('MPLQT')
reaper.gmem_write(0,1)
  function main()
    local _,_,_,_,_,resolution,val = reaper.get_action_context()
    if resolution < 0 or val < 0 then return end
    reaper.gmem_write(1,(val/resolution))
  end
  
  reaper.defer(main)
