-- @description Notification set - track volume changed
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @about set parameters for MPL notification script
-- @noindex


EXT = {
        CONF_txt1 = 'Volume',
        CONF_txt2 = '#lasttouchedtrack_volume',
        CONF_png = [[C:\test.png]],
        CONF_autoterminatetime = 1, -- seconds, script will close after this time
        CONF_autoterminate_fadetime = 0.5,-- seconds, fade time to make script fully transparent bofore close
      }
      





-------------------------------------------------------------------------------- 
function WildCards_Decode(str)
  if not (str and type(str) == 'string' ) then return str end
  
  --  #lasttouchedtrack_volume
    if str:match('#lasttouchedtrack_volume') then
      local tr = reaper.GetLastTouchedTrack()
      if tr then
        local vol = reaper.GetMediaTrackInfo_Value( tr, 'D_VOL' )
        local voldb = WDL_VAL2DB(vol, true)
        str = str:gsub('#lasttouchedtrack_volume',voldb)
      end
    end
    
  -- return
    return str
end
------------------------------------------------------------------------------------------------------
function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  if not x or x < 0.0000000298023223876953125 then return -150.0 end
  local v=math.log(x)*8.6858896380650365530225783783321
  if v<-150.0 then v=-150.0 end
  return string.format('%.3f', v)..'dB'
end
-------------------------------------------------------------------------------- 
function EXT_save() 
  for key in pairs(EXT) do 
    local outval = WildCards_Decode(EXT[key])
    if outval and (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
      reaper.SetExtState( 'MPL_notification', key, outval, true  ) 
    end 
  end 
end
-------------------------------------------------------------------------------- 
reaper.gmem_attach('mpl_notification_trig' )
reaper.gmem_write(1,1 )
EXT_save() 
