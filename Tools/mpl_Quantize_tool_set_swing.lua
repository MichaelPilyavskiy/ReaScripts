-- set strenght value for mpl Quantize tool
 
is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
val_ret=val/127
value = tostring(val_ret)
reaper.SetExtState("mplQT_settings", "Swing", value, true)
