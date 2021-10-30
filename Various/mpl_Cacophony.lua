-- @description Cacophony
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Script is designed to play MPL Cacophony. Track is actually 4 tracks diffusing each other on rhythmic, melodic and design levels.
-- @provides
--    mpl_Cacophony_stuff/Michael Pilyavskiy - Cacophony - Track 1.mp3
--    mpl_Cacophony_stuff/Michael Pilyavskiy - Cacophony - Track 2.mp3
--    mpl_Cacophony_stuff/Michael Pilyavskiy - Cacophony - Track 3.mp3
--    mpl_Cacophony_stuff/Michael Pilyavskiy - Cacophony - Track 4.mp3
--    [noindex] mpl_Cacophony_stuff/Michael Pilyavskiy - Cacophony.RPP
-- @changelog
--    # remove master analyzer

-------------------------------------------
function run()
  char = gfx.getchar()
  getdata()
  getdata_onchange()
  defineobj_update()
  handlemouse()
  drawGUI()
  if char >= 0 and char ~= 27 then reaper.defer(run) else   reaper.atexit(gfx.quit) end
end
------------------------------------------------------------------------------------------------------
function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
function WDL_VAL2DB(x, reduce)if not x or x < 0.0000000298023223876953125 then return -150.0 end local v=math.log(x)*8.6858896380650365530225783783321 if v<-150.0 then return -150.0 else  if reduce then  return string.format('%.2f', v) else  return v  end end end
-------------------------------------------
function getdata_onchange()
  data = {}
  data.tracks = {}
  data.com_len = 231
  for i = 1, reaper.CountTracks(0) do
    local tr = reaper.GetTrack(0,i-1)
    local vol = reaper.GetMediaTrackInfo_Value( tr, 'D_VOL' )
    local vol_db = WDL_VAL2DB(vol)
    data.tracks[i] = {ptr = tr, vol = vol, vol_db = vol_db, vol_norm = (math.min(0,vol_db)+ 80)/80}
  end
end
-------------------------------------------
function getdata()
  
end
-------------------------------------------
function drawGUI_drawobj(o)
  gfx.a = 1
  gfx.set(0,0,0)
  gfx.rect(o.x,o.y,o.w,o.h,0)
  if o.val then 
    gfx.a = 1
    gfx.rect(o.x,o.y+o.h*(1-o.val),o.w,o.h*o.val,1) 
  end
  if o.txt then
    gfx.setfont(0)
    gfx.set(0,0,0,1)
    gfx.x,gfx.y = o.x,o.y
    gfx.drawstr(o.txt, 1|4, o.x+o.w,o.y+o.h)
  end
end
-------------------------------------------
function defineobj()
  obj = {}
  local playpos_h = 40
  local playb_w = playpos_h
  local offs = 10
  local tr_w = gfx.w/4
  local trh = gfx.h - playpos_h-offs*2
  local h_but  = gfx.h-trh-offs*3
  local but_w = tr_w-offs*2
  local progr_w = tr_w*3-offs*2
  local progr_x = offs*3 + but_w
  obj.play = {x=offs,
              y = trh + offs*2,
              w = but_w,
              h = h_but,
              txt = 'stop',
              perform_mouse = function()
                reaper.OnStopButton()
              end} 
  obj.playpos = {x=progr_x,
              y = trh + offs*2,
              w = progr_w,
              h = h_but,
              txt = 'play',
              perform_mouse = function()
                
                -- open if not opened
                local retval, projfn = reaper.EnumProjects( -1 )
                if not projfn:lower():match('cacophony') then
                  reaper.Main_OnCommand( 41929, 0 ) -- New project tab (ignore default template)
                  destproject = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Various/mpl_Cacophony_stuff/Michael Pilyavskiy - Cacophony.RPP'
                  reaper.Main_openProject( destproject )
                  return 
                end
                
                local mx = gfx.mouse_x
                local outval_norm = (mx-progr_x)/progr_w
                if  reaper.GetPlayState()&1~=1 then reaper.CSurf_OnPlay() end
                reaper.SetEditCurPos( data.com_len*outval_norm, false, true )
              end}   
              
              
  
  
  for i = 1, 4 do
    local x = tr_w*(i-1)+offs
    local y = offs
    local w = tr_w - 2-offs*2
    obj['tr'..i] = {x=x,
                    y = y,
                    w = w,
                    h = trh,
                    perform_mouse = function()
                      local my = gfx.mouse_y
                      local outval_norm = (trh-my+y)/trh
                      outval_db = outval_norm*80-80
                      outval = WDL_DB2VAL(outval_db)
                      local tr
                      if data.tracks[i] then tr = data.tracks[i].ptr end
                      if tr then reaper.SetMediaTrackInfo_Value( tr, 'D_VOL', outval ) end
                    end}
    
  end
end
-------------------------------------------
function defineobj_update()
  for i = 1, 4 do
    if  data.tracks[i] and obj['tr'..i] then obj['tr'..i].val = data.tracks[i].vol_norm end
  end
end
-------------------------------------------
function drawGUI()
  gfx.a = 0
  gfx.set(1,1,1)
  gfx.rect(0,0,gfx.w, gfx.h)
  for key in pairs(obj) do drawGUI_drawobj(obj[key]) end
  gfx.update()
end
-------------------------------------------
function handlemouse() local state = gfx.mouse_cap&1 == 1 if state then for key in pairs(obj) do  if mousematch(obj[key]) and obj[key].perform_mouse then obj[key].perform_mouse() end end end end
-------------------------------------------
function mousematch(o)
  local x = gfx.mouse_x
  local y = gfx.mouse_y
  return x > o.x and x < o.x+o.w and y > o.y and y < o.y+o.h
 end
-------------------------------------------
gfx.init('MPL - Cacophony', 300, 300,0,100,100)
defineobj()
run()