-- @description Create send from selected tracks (custom)
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    + init by custom request

--[[
Логика действий
X 1. Создать 1 трек сенд (FX-трек) от выбранного 1 либо нескольких треков (В случае если выбрано несколько треков,  тоже создавать 1 FX-трек с стендами от всех выбранных)
X 2. Создавать рядом справа от выбранного трека, если было выбрано несколько треков то справа от последнего выбранного из них.
>>1 3. Если выбранный трек или несколько треков находится в папке, то FX-трек создавать в тоже папке вместе с выбранным треком или треками
X 4. Если выбранный трек папка, то вся логика такая же только fx-трек(и) создавать слева от папки и задавать имя «Bus Fx 1, Bus Fx 2 и т.д.»
X 5. Если выбран трек(и) «A» то от него создавать, если трек(и) «B» то от него создавать, если выбран снова трек(и) «А» от которого(их) уже создавался fx 1 трек, то продолжать создавать Fx 2, fx 3… и т.д.
X 6. Задавать фокус на новый созданный трек 
Внешний вид
X 1.  Задавать цвет «0x8d46cc»
задать иконку «fx.png» вроде стандартная 
X 2. Фейдер громкости -inf 
X 3. В Трек окне Layout трека сделать (C-DPI-translated to 200% C)
X 4. В микшер окне Layout задать ( Track layout 200%_B)
]]
  ----------------------------------------------------------------------
  function main()
    if reaper.CountSelectedTracks(0) == 1 then
      VF2_CreateFXTrack(reaper.GetSelectedTrack( 0,0 ))
     elseif reaper.CountSelectedTracks(0) > 1 then
      local seltr_ptrs = {}
      for i = 1, reaper.CountSelectedTracks(0) do 
        local tr = reaper.GetSelectedTrack( 0, i-1 )
        seltr_ptrs[#seltr_ptrs+1]=tr
        if i == reaper.CountSelectedTracks(0) then VF2_CreateFXTrack(tr, seltr_ptrs) end
      end 
    end
  end
  
   
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.66) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    reaper.Undo_BeginBlock2( 0 )
    main()
    reaper.Undo_EndBlock2( 0, 'Create send from selected tracks (custom)', -1 )
  end end