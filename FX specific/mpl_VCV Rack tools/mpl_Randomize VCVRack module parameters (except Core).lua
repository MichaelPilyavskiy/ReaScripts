-- @description Randomize VCVRack module parameters (except Core)
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    # fix file ask
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
  dofile(script_path .. "json2lua.lua")-- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
  ---------------------------------------------------------------------
  function RandomizeParams(t)
    for moduleID =1, #t.modules do
      for param_ID =1, #t.modules[moduleID].params do
        if not t.modules[moduleID].plugin:match('Core') then  
          t.modules[moduleID].params[param_ID].value = math.random()--*2-1
        end
      end
    end
  end
  ---------------------------------------------------------------------
  function GenRandHexCol()
    local col_int = ColorToNative(  math.floor(255*math.random()), 
                              math.floor(255*math.random()), 
                              math.floor(255*math.random()))
    local random_col = string.format('%.06x', col_int)--math.floor(math.random()*16777215))
    return random_col
  end
  ---------------------------------------------------------------------
  function main()
    -- get file
      local retval, fp = GetUserFileNameForRead('', 'Randomize VCVRack wire colors', 'vcv' )
      if not retval then return end 
      local f,content = io.open(fp, 'r')
      if not f then return else 
        content = f:read('a')
        f:close()
      end
    
    -- modify
       t = json.parse(content)
      RandomizeParams(t)
      local setstr = json.stringify(t)
    
    -- get filename without extension
      local fp0 = fp:sub(-6)
      local out_fp
      if fp0:lower():match('vcv') then out_fp = fp:gsub('%.vcv', ''):gsub('%.VCV', '')..'-MOD.vcv' end
      
    -- write modded file back
      if out_fp then
        f = io.open(out_fp, 'w')
        if f then 
          f:write(setstr)
          f:close()
        end
      end
  end

  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end 
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then main() end
  
  
