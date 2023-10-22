-- @description Snap selected tracks volume faders (background)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init 

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  local DATA = {UPD={}}
  --------------------------------------------------------------------------
  function quantize(v, step) local  mult = v/step  return v*math.ceil(mult) end
  --------------------------------------------------------------------------
  function PerformSnap()
    --if not ValidatePtr(tr, 'MediaTrack*') then return end
    
    for i=1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      local vol = GetMediaTrackInfo_Value( tr, 'D_VOL' )
      local db = WDL_VAL2DB(vol)
      
      -- quantize
      local out_db = db
      if db>0 then out_db = math_q(db, 0.1)  end
      if db>-2 and db<0 then out_db = math_q(db, 0.1)  end
      if db>-6 and db<=-2 then out_db = math_q(db, 0.2)  end
      if db>-12 and db<=-6 then out_db = math_q(db, 0.5)  end
      if db>-24 and db<=-12 then out_db = math_q(db, 1)  end
      if db<-24 then out_db = math_q(db, 2)  end
      SetMediaTrackInfo_Value( tr, 'D_VOL',WDL_DB2VAL(out_db) )
    end
  end
  ----------------------------------------------------------------------------------------------------------
  function math_q(num, step)  
    if not step then if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
    if step then  return math_q(num/step)*step end
  end
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else return v end
  end
  --------------------------------------------------------------------------
  function handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 )
    if (DATA.UPD.lastSCC and DATA.UPD.lastSCC~=SCC ) then DATA.UPD.onprojstatechange = true end
    DATA.UPD.lastSCC = SCC
    
    local editcurpos =  GetCursorPosition() 
    if (DATA.UPD.last_editcurpos and DATA.UPD.last_editcurpos~=editcurpos ) then DATA.UPD.onprojstatechange = true end
    DATA.UPD.last_editcurpos=editcurpos 
    
    local reaproj = tostring(EnumProjects( -1 ))
    DATA.UPD.reaproj = reaproj
    if DATA.UPD.last_reaproj and DATA.UPD.last_reaproj ~= DATA.UPD.reaproj then DATA.UPD.onprojtabchange = true end
    DATA.UPD.last_reaproj = reaproj
  end
  --------------------------------------------------------------------------
  function run()
    handleProjUpdates()
    if DATA.UPD.onprojtabchange == true or DATA.UPD.onprojstatechange == true then PerformSnap() end
    defer(run)
  end
  
  run()
  reaper.atexit()