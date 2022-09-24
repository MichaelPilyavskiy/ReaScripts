-- @description Zoom horizontally, change grid relatively, preserve grid visibility and snap state  (mousewheel) 
-- @version 2.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    - disable snap at 1/256
--    # fix grid conditions
 
  DATA = {  reduceviewratio = 0.7, -- horizontal
            inc = 0.5 ,-- init progress increment 
            inc_current = 0}
  
  
  ------------------------------------------------------------------
  function msg(s) reaper.ShowConsoleMsg(s..'\n') end
  ------------------------------------------------------------------
  function SmoothZoom_GetDirection()
    local mouse_scroll  = ({reaper.get_action_context()})[7]
    if mouse_scroll > 0 then return 1 else return -1 end
  end 
  ------------------------------------------------------------------
  function Applyzoom_gridmap()
    --DATA.beats_cnt =  ({reaper.TimeMap2_timeToBeats( 0, DATA.arr_end_time )})[4] - ({reaper.TimeMap2_timeToBeats( 0, DATA.arr_start_time )})[4]
    --reaper.SetProjectGrid( 0, 160/math.floor(DATA.beats_cnt ))
    DATA.arr_zoom = reaper.GetHZoomLevel() -- pixels/second
    DATA.zoom_gridmap = {0.38, -- no snap / no grid 
              5, -- 2
              16,--1
              22.84,
              48.84, -- 1/4
              117.86,
              351.95,-- 1/16
              1050.92, -- 1/32
              3200, -- 1/64
              5000, -- 1/128
              7000, -- 1/256
              9000} -- no snap / no grid
    grid_t = {}
    for i = 2, -(#DATA.zoom_gridmap-3), -1 do grid_t[#grid_t+1] = 2^i end
   
    
    for i = 1, #DATA.zoom_gridmap-1 do
      if DATA.arr_zoom > DATA.zoom_gridmap[i] and DATA.arr_zoom <= DATA.zoom_gridmap[i+1] then
        local grid_div_out = grid_t[i]
        if DATA.is_triplet then grid_div_out = grid_div_out /3 end
        local retval, division, swingmode, swingamt = reaper.GetSetProjectGrid( 0, true, grid_div_out, DATA.swingmode, DATA.swingamt ) 
        --msg(grid_div_out)
        break
      end
    end
    
    DATA.arr_zoom = reaper.GetHZoomLevel()   
    if DATA.arr_zoom < DATA.zoom_gridmap[2] or DATA.arr_zoom > DATA.zoom_gridmap[#DATA.zoom_gridmap] then 
      --reaper.Main_OnCommand(40753,0) -- disable snap
     else
      --reaper.Main_OnCommand(40754,0) -- enable snap
    end
    if DATA.gridlinestate == 0 then reaper.Main_OnCommand(40145,0)  end-- restore toggle grid lines
    
  end
  ------------------------------------------------------------------
  function run_progress()
    --run_progress_cnt = run_progress_cnt + 1
    --ignore_skipframes = true
    
    --if run_progress_cnt%2 == 0 or ignore_skipframes then 
      -- progress stuff
        --if not DATA.zoom_progress then DATA.zoom_progress = 0 end -- init progress
        DATA.zoom_progress = 1
        --[[DATA.inc_current = math.max(0.02, 0.3*(1-DATA.zoom_progress)) -- handle smooth braking
        DATA.zoom_progress = DATA.zoom_progress + DATA.inc_current -- increment progress 
        if DATA.zoom_progress>1 then return end -- stop on reaching 1]]
      
      -- actually zoom arrange horizontally
        reaper.GetSet_ArrangeView2( 0, true, 0, 0, 
          DATA.arr_start_time - DATA.mousecoeff_st * (DATA.arr_boundaryshift*DATA.zoom_progress*DATA.dir), 
          DATA.arr_end_time   + DATA.mousecoeff_end * (DATA.arr_boundaryshift*DATA.zoom_progress*DATA.dir)
        )
        
      -- handle grid stuff
        Applyzoom_gridmap()
    --end
    
    --reaper.defer(run_progress) 
    
  end
  ------------------------------------------------------------------
  function main()
    DATA.dir = SmoothZoom_GetDirection()  
    
    -- arrange horizontal time data
      DATA.arr_start_time, DATA.arr_end_time = reaper.GetSet_ArrangeView2( 0, false, 0, 0, 0, 0 )
      DATA.arr_length_src = DATA.arr_end_time - DATA.arr_start_time
      DATA.arr_length_dest = DATA.arr_length_src * DATA.reduceviewratio
      DATA.arr_boundaryshift = (DATA.arr_length_dest - DATA.arr_length_src ) /2
      
    -- handle zoom around mouse pointer
      local x,y = reaper.GetMousePosition()
      DATA.mouse_pos = reaper.GetSet_ArrangeView2(0, false, x, x+1)
      DATA.mousecoeff_st = (DATA.mouse_pos - DATA.arr_start_time) / DATA.arr_length_src
      DATA.mousecoeff_end = (DATA.arr_end_time - DATA.mouse_pos) / DATA.arr_length_src
    
    -- grid lines state
      DATA.gridlinestate = reaper.GetToggleCommandState( 40145 )
      DATA.grid_flags, DATA.division, DATA.swingmode, DATA.swingamt = reaper.GetSetProjectGrid( 0, false, 0, 0, 0 )
      DATA.is_triplet = (1/DATA.division) % 3 == 0 
      
    --run_progress_cnt = 0
    run_progress()
    
  end
  ------------------------------------------------------------------------------------
  main()