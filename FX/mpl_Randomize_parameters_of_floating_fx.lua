script_title = "Randomize parameters of floating fx"

function string_find(name, name_cust)
  name_lc = string.lower(name)
  name_cust_lc = string.lower(name_cust)
  name_cust_len = string.len(name_cust)
  if name_cust_len <= 4 then
    name_cust_lc_sub1 = name_cust_lc
    name_cust_lc_sub2 = name_cust_lc
   else
    name_cust_len1 = name_cust_len-1
    name_cust_lc_sub1 = string.sub(name_cust, 2)
    name_cust_lc_sub2 = string.sub(name_cust, 1, name_cust_len1)
  end
  
 if string.find(name_lc, name_cust_lc) ~= nil or
    string.find(name, name_cust_lc_sub1) ~= nil or
    string.find(name, name_cust_lc_sub2) ~= nil 
  then
    return true 
   else 
    return false 
 end
end


function Store_params()  
  par_t = {}
  trackcount = reaper.CountTracks(0)
  if trackcount ~= nil then
  for i =1, trackcount do
    track = reaper.GetTrack(0, i-1)
    fx_count = reaper.TrackFX_GetCount(track)
    if fx_count ~= nil then
      for j = 1 , fx_count do
        if reaper.TrackFX_GetOpen(track, j-1) == true then
          par_count = reaper.TrackFX_GetNumParams(track, j-1)
          if par_count ~= nil then
            for k = 1, par_count do
              value, minvalOut, maxvalOut = reaper.TrackFX_GetParam(track, j-1, k-1)
              retval, name = reaper.TrackFX_GetParamName(track, j-1, k-1, "")
              par_sub_t = {i, j, k, value,minvalOut, maxvalOut,name}
              table.insert(par_t, par_sub_t)              
            end  
          end
        reaper.TrackFX_SetEnabled(track, j-1, true)  
        break end
      end
    end  
  end
 end 
end

--------------------------------------------
--------------------------------------------

function set_param(mult0, offset0)
 if par_t ~= nil then
  for i = 1, #par_t do
    temp_t = par_t[i]
    fx_id, par_id, value, minvalOut, maxvalOut, par_name = temp_t[2], temp_t[3], temp_t[4],temp_t[5], temp_t[6], temp_t[7]
    track = reaper.GetTrack(0, temp_t[1]-1)
    if track ~= nil and fx_id~= nil and par_id~= nil and
      string_find(par_name, "gain") == false and
      string_find(par_name, "vol") == false and
      string_find(par_name, "on") == false and
      string_find(par_name, "off") == false and
      string_find(par_name, "wet") == false and
      string_find(par_name, "dry") == false and
      string_find(par_name, "oversampling") == false and
      string_find(par_name, "aliasing") == false and
      string_find(par_name, "input") == false and
      string_find(par_name, "power") == false and
      string_find(par_name, "solo") == false and
      string_find(par_name, "mute") == false and
      string_find(par_name, "feedback") == false and
      string_find(par_name, "attack") == false and
      string_find(par_name, "decay") == false and
      string_find(par_name, "sustain") == false and
      string_find(par_name, "release") == false and
      string_find(par_name, "active") == false 
      
      then
      value_out = value*mult0 + offset0      
      reaper.TrackFX_SetParam(track, fx_id-1, par_id-1, value_out) --math.random(0,1))
    end
  end
 end
end


--------------------------------------------
--------------------------------------------
 

function get_mouse(rect_t,value_ret)   
  if LB_DOWN == 1 -- mouse on swing
    and mx > rect_t[1]
    and mx < rect_t[1]+rect_t[3]
    and my > rect_t[2]
    and my < rect_t[2]+rect_t[4] then
     value_ret = math.ceil(((mx-rect_t[1]) / rect_t[3])*10000) / 10000
     state = true
   else
     state = false  
  end  
  return value_ret, state
end  
        

-------------------------------------------- 
------------------ GUI ---------------------
--------------------------------------------  

function str_draw(str1, rect1)
  gfx.a = 1
  str1_len = gfx.measurestr(str1)
  gfx.x, gfx.y = rect1[1]+(rect1[3]-str1_len)/2, rect1[2] + 6
  gfx.setfont(1, "Arial", 18, b)
  gfx.drawstr(str1)
  gfx.x, gfx.y = 0, 0
  gfx.a = 0.2
  gfx.roundrect(rect1[1], rect1[2], rect1[3], rect1[4], 0.1, true)
  gfx.a = 0.2
  gfx.rect(rect1[1], rect1[2], rect1[3], rect1[4], true)
end

offset = 0
mult = 0
main_w = 450
main_h = 90
rect1 = {30, 10, 230, 30}
rect2 = {30, 50, 230, 30}
rect3 = {280, 10, 150, 30}
rect4 = {280, 50, 150, 30}
gfx.init("mpl Randomize Parameters", main_w, main_h) 

--------------------------------------------
--------------------------------------------
--------------------------------------------

function run()  
  mx, my = gfx.mouse_x, gfx.mouse_y  
  LB_DOWN = gfx.mouse_cap&1 
  
  offset, offset_b = get_mouse(rect1, offset)  
  if offset_b == true then set_param(mult, offset) end
  
  mult, mult_b = get_mouse(rect2, mult)
  if mult_b == true then set_param(mult, offset) end
   
  isset_val, isset = get_mouse(rect3)
  if isset == true then  Store_params()  end
  
  isrest_val, isrest = get_mouse(rect4)
  if isrest == true then  set_param(1, 0)  end
  
  --- buttons ---
  
  if offset == nil then offset = 0 end
  str_draw("Offset "..offset,rect1)  
  
  if mult == nil then  mult = 0 end 
  str_draw("Multiply "..mult,rect2)
  
  if par_t == nil then par_table_size = 0 else par_table_size = #par_t end
  str_draw("Get parameters ("..par_table_size..")",rect3)
  
  str_draw("Restore",rect4) 
   
  ----------------
   
  gfx.update()
  if gfx.getchar() ~= -1 then reaper.defer(run) else gfx.quit() end
end

parameters_t0 = {}
parameters_t = {}

run()
reaper.atexit(gfx.quit) 
