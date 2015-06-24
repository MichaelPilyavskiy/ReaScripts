-- mpl swing quantize items

snap_direction = 0
swing = 25
n_offset = 4 -- offset for text in gui

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

grid = reaper.BR_GetNextGridDivision(0)
grid_beats = reaper.TimeMap2_timeToBeats(0, grid)  
grid_beats_r = round(grid_beats, 4)

function store_items_positions() local item, item_pos
  items_guid_t ={}
  positions_t = {}
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items > 0 then 
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1)
      guid = reaper.BR_GetMediaItemGUID(item)
      item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      table.insert(items_guid_t, i, guid)
      table.insert(positions_t, i, item_pos)
    end
  end    
end

store_items_positions() 
 
function quantize()  
  if #items_guid_t > 0 then 
    for i = 1, #items_guid_t, 1 do   
     
      temp_guid = items_guid_t[i]
      item = reaper.BR_GetMediaItemByGUID(0, temp_guid)                 
      item_pos = positions_t[i]      
      item_pos_beats, measures = reaper.TimeMap2_timeToBeats(0, item_pos)
      item_pos_beats_r = round(item_pos_beats, 4)      
      prev_grid_div = reaper.BR_GetPrevGridDivision(item_pos)
      prev_grid_div_beats = reaper.TimeMap2_timeToBeats(0, prev_grid_div)
      prev_grid_div_beats_r = round(prev_grid_div_beats, 4)             
      posiontprecent = item_pos_beats_r / grid_beats_r % 1      
      
      -- snap items --
            
      if posiontprecent == 0 then -- if item on grid set item pos as prev grid pos
        prev_grid_div_beats_r = item_pos_beats_r
      end       
      
      if snap_direction == 1 then -- 1: to closest grid 
        if posiontprecent < 0.5 then
          item_pos_beats_r = prev_grid_div_beats_r
         else 
          item_pos_beats_r = prev_grid_div_beats_r + grid_beats_r
        end
       else --  0: to previous grid
        if posiontprecent < 0.5 then
         item_pos_beats_r = prev_grid_div_beats_r
        else 
         item_pos_beats_r = prev_grid_div_beats_r  
        end
      end
      
      new_pos = reaper.TimeMap2_beatsToTime(0, item_pos_beats_r, measures)
      reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)      
      
      -- swing --
      
      item_pos_beats2, measures = reaper.TimeMap2_timeToBeats(0, new_pos)
      item_pos_beats_r2 = round(item_pos_beats2, 4)
      
      div_remainder2 = (item_pos_beats_r2 / grid_beats_r) % 2       
      
      if div_remainder2 == 1.0 then -- swing            
        new_pos2_beats = item_pos_beats_r2 + (grid_beats_r - (grid_beats_r*0.001)) * swing/100
        new_pos2 = reaper.TimeMap2_beatsToTime(0, new_pos2_beats, measures)
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos2)
      end     
      
    end -- for count_sel_items
  end  -- count_sel_items > 0
end -- func


-------------------  GUI  ---------------------------
-----------------------------------------------------

function draw_rect()
  gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 1
  w_rect = main_w - x_offset * 2
  h_rect = main_h - y_offset * 2 - 10
  gfx.roundrect(x_offset,y_offset,w_rect,h_rect,0.1, true)
end 

function draw_grid()
  x_offset_grid = main_w / 10
  y_offset_grid = y_offset
  w_grid = main_w - x_offset * 2
  h_grid = h_rect
  for i = 1, 16, 1 do       
    div_i = i % 4
    div_i2 = i % 2    
    if div_i == 1 then h_div = 1.2
      else
      if div_i2 == 1 then 
       h_div = 1.8      
       else 
       h_div = 3 
      end
     end  
    gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 1   
    gfx.line(x_offset_grid, y_offset_grid + h_grid, x_offset_grid, y_offset_grid + h_grid - h_grid / h_div, 0.9)
    x_offset_grid = x_offset_grid + w_grid / 16
  end 
end

function draw_percent()
 gfx.setfont(1,"Arial", 16, b)
 gfx.x = x_offset + 5
 gfx.y = y_offset + n_offset
 measurestr0 = gfx.measurestr("Swing:  ")
 gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 1
 gfx.drawstr("Swing: ")
 gfx.x = x_offset + measurestr0
 gfx.y = y_offset + n_offset
 num = tostring(swing)
 gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 1
 gfx.drawstr(num.."%")  
 end  

function draw_fill()  
  col = swing/100
  col2 = math.abs(col - 100)/100
  gfx.r, gfx.g, gfx.b, gfx.a = col, col2, 0, 0.5
  gfx.rect(x_offset+1, y_offset +1,w_grid*swing/100-1,h_grid-1)
end
  
function draw_snap_dir()
   gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 1  
  gfx.y = y_offset + h_rect + n_offset  
  gfx.x = x_offset
  gfx.drawstr("Snap direction: ")   
  measurestr1 = gfx.measurestr("Snap direction: ")
  if snap_direction == 0 then
    gfx.a = 1     
    gfx.x = x_offset + measurestr1
    gfx.drawstr(" to previous grid")
    
    gfx.a = 0.4 
    measurestr2 = gfx.measurestr(" to previous grid")    
    gfx.x = x_offset + measurestr1 + measurestr2
    gfx.drawstr(" / to closest grid")
    
   else
    gfx.a = 0.4 
    gfx.x = x_offset + measurestr1
    gfx.drawstr(" to previous grid / ")
    
    gfx.a = 1 
    measurestr3 = gfx.measurestr(" to previous grid / ")    
    gfx.x = x_offset + measurestr1 + measurestr3
    gfx.drawstr("to closest grid")
    
  end  
end
   
function draw_exit()
  gfx.r, gfx.g, gfx.b, gfx.a = 1, 0, 0, 1
  measurestr4 = gfx.measurestr("Save before exit")  
  gfx.x = x_offset + w_rect - measurestr4
  gfx.drawstr("Save before exit")
end

   
function open_gui()  
  gfx.init("", main_w, main_h)  
  draw_rect() 
  draw_grid()  
  draw_percent() 
  draw_fill() 
  draw_snap_dir()
  draw_exit()  
end  
 
function snapdir_set()
    
  measurestr1 = gfx.measurestr("Snap direction: ")
  measurestr2 = gfx.measurestr(" to previous grid")
  measurestr3 = gfx.measurestr(" to previous grid / ")    
  if LB_DOWN == 1 and mx > x_offset + measurestr1
    and mx < x_offset + measurestr1 + measurestr2
    and my > y_offset + h_rect + 4 
    and my < y_offset + h_rect + 20 then     
      snap_direction = 0 
  end
  if LB_DOWN == 1 and mx > x_offset + measurestr1 + measurestr3
    and mx < x_offset + measurestr1 + measurestr2 + measurestr3
    and my > y_offset + h_rect + 4 
    and my < y_offset + h_rect + 20 then     
      snap_direction = 1 
  end
  
end

------------------  Main  ---------------------------
-----------------------------------------------------
cond = 1
function mainloop() 
 if cond == 1 then    
  gfx.x = 0
  gfx.y = 0
  main_w = 500
  main_h = 80
  
  x_offset = main_w / 10
  y_offset = 12
  
  open_gui()
  
  mx, my = gfx.mouse_x, gfx.mouse_y -- position
  LB_DOWN = gfx.mouse_cap&1 -- state of left button              
     
  measurestr1 = gfx.measurestr("Snap direction: to previous grid")
  snapdir_set()    
    
    if LB_DOWN == 1 
      and mx > x_offset 
      and mx < x_offset + w_rect 
      and my > y_offset 
      and my < y_offset + h_rect then 
       swing = math.floor((mx - x_offset) / w_rect * 100)      
       quantize()            
    end
    
    if LB_DOWN == 1 and mx > x_offset + w_rect - measurestr4
      and mx < x_offset + w_rect
      and my > y_offset + h_rect + 4 
      and my < y_offset + h_rect + 20 then     
      cond = 0
      reaper.atexit()
    end               
  gfx.update()
  reaper.defer(mainloop)
 end 
end
  
end

mainloop()
