-- @description Generate random VCV patch from Fundamental modules
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    + init
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
  dofile(script_path .. "json2lua.lua")-- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
  ---------------------------------------------------------------------
  function GenerateNew(t)
    -- Init with Core audio
    t = { version="0.6.2c",
          wires = {},
          modules = {
                      {model = 'AudioInterface',
                       plugin= 'Core',
                       version = '0.6.2c',
                       data = {
                                audio = { driver=6,
                                          deviceName = '',--Speakers (6- USB Audio Device)',
                                          offset = 0,
                                          maxChannels = 8,
                                          sampleRate = 44100,
                                          blockSize = 4096
                                        },
                                pos = {1, 0}
                              }
                      }
                    }
    
        }
    local vco_cnt = 20
    AddVCO(t,vco_cnt)
    AddWires(t,vco_cnt)
    return t
  end
  ---------------------------------------------------------------------
  function AddVCO(t,vco_cnt)
    local x0 = 15
    local x = x0
    local y = 0
    local w = 15
    local names= {'VCO',
                  'VCF',
                  'LFO',
                  'Delay',
                  'VCO2',
                  --'SEQ3',
                  'ADSR',
                  'Unity',
                  
                  'SequentialSwitch1'}
    for i = 1, vco_cnt do
      t.modules[#t.modules+1] = { plugin="Fundamental",
                                  version="0.6.2",
                                  model=names[math.min(#names,1+math.floor(math.random()*#names))],
                                  pos = {x,y},
                                  params = {}
                                  }
      t.modules[#t.modules].params = {}
      for iparam =1, 30 do
        r = math.random()*2-1
        if iparam-1 == 2 then r = math.random()*90-45 end
        t.modules[#t.modules].params[iparam] = {paramId=iparam-1 ,
                                                value = r}
      end
      x = x + w
      if i % 8 == 0 then x = x0 y = y +1 end                                  
    end
  end
  ---------------------------------------------------------------------
  function AddWires(t,vco_cnt) 
    for wireID = 1, 100 do
      outputModuleId = math.floor(math.random()*(vco_cnt-1))+1
      --inputModuleId= math.floor(math.random()*(vco_cnt-1))+1
      inputModuleId= math.floor(math.random()*(vco_cnt))
      if inputModuleId ~= outputModuleId then
        local src_id = math.floor(math.random()*5)
        local dest_id = math.floor(math.random()*5)
        local ret = CheckDestId(t,inputModuleId, dest_id, outputModuleId, src_id)
        if ret then t.wires[#t.wires+1] = {color = '#'..GenRandHexCol(),
                              outputModuleId = outputModuleId,
                              outputId = src_id,
                              inputModuleId = inputModuleId,
                              inputId = dest_id
                              }
        end
      end
    end
  end
  ---------------------------------------------------------------------
  function CheckDestId(t, inputModuleId, dest_id, outputModuleId, outputId)
    for i = 1, #t.wires do
      if (t.wires[i].inputModuleId == inputModuleId and t.wires[i].inputId == dest_id) then return false 
      end
    end
    return true
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
      --fp = [[C:\Users\mpl\Desktop/1.vcv]]
       retval0,  fp = JS_Dialog_BrowseForSaveFile('Generate random VCV patch from Fundamental modules', '', '', ".vcv")
      if retval0 ~= 1 then return end 
      if not fp:match('%.vcv') then fp = fp..'.vcv' end
      --[[local f,content = io.open(fp, 'r')
      if not f then return else 
        content = f:read('a')
        f:close()
      end]]
    
    -- modify
      --t = json.parse(content)
      t =GenerateNew()
      local setstr = json.stringify(t)
    
    -- get filename without extension
      local fp0 = fp
      local out_fp
      if fp0:lower():match('vcv') then out_fp = fp:gsub('%.vcv', ''):gsub('%.VCV', '')..'-MOD.vcv' end
      
      --do return end
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
  if ret and ret2 then 
    if JS_Dialog_BrowseForSaveFile then main() else MB('Missed JS ReaScript API extension', 'Error', 0) end
  end
  
  