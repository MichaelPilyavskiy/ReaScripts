-- @description Randomize VCVRack wire colors by source module
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    # fix srcdest invertion
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
  dofile(script_path .. "json2lua.lua")-- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
  ---------------------------------------------------------------------
  function RandomizeColorsByModule(t, is_by_output)
    local cnt_modules = #t.modules
    local colors_t = {}
    for i = 1, cnt_modules do colors_t[i] = '#'..GenRandHexCol() end 
    for wire_ID =1, #t.wires do
      if is_by_output then modID = t.wires[wire_ID].inputModuleId else modID = t.wires[wire_ID].outputModuleId end
      t.wires[wire_ID].color = colors_t[modID+1]
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
      local t = json.parse(content)
      RandomizeColorsByModule(t, false)
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
  
  