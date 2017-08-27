-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Convert RS5k MIDI item into source based audio items (drum mode)
-- @changelog
--    + init

  local scr_nm = 'Convert RS5k MIDI item into source based audio items (drum mode)'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) ShowConsoleMsg(s) end
  ------------------------------------------------------------------------------
  function ConvertRS5kMIDI2AudioItems(item)
    if not item then return end
    take = GetActiveTake(item)
    if not take or not TakeIsMIDI(take) then return end
    
    local tr= GetMediaItem_Track( item )
    local instr_id = TrackFX_GetInstrument(tr)
    local retval, sample_path = reaper.TrackFX_GetNamedConfigParm( tr, instr_id, 'FILE' )
    if not retval then return end
    
    -- collect data
      local data ={}
      for i = 1,  ({MIDI_CountEvts( take )})[2] do 
        local _, s, m, sppq, eppq, c,p, v =MIDI_GetNote( take, i-1 )
        if m then m = 1 else m = 0 end
        data[#data+1] = {mute = m,
                         pos =  MIDI_GetProjTimeFromPPQPos( take, sppq ),
                         vol = v/127}
      end
      
    -- add audio items
      local src =  PCM_Source_CreateFromFileEx( sample_path, false )
      local srclen = GetMediaSourceLength( src )
      if not src then return end
      SetMediaItemInfo_Value( item, 'B_MUTE', 1 ) -- mute MIDI
      for i = 1, #data do
        local new_item = AddMediaItemToTrack( tr )
        take = AddTakeToMediaItem( new_item )
        SetMediaItemTake_Source( take, src )
        SetMediaItemInfo_Value( new_item, 'B_MUTE', data[i].mute )
        SetMediaItemInfo_Value( new_item, 'D_VOL', data[i].vol )
        SetMediaItemInfo_Value( new_item, 'D_POSITION', data[i].pos )
        SetMediaItemInfo_Value( new_item, 'D_LENGTH', srclen ) 
      end
    
    UpdateArrange()
  end
  ------------------------------------------------------------------------------
  Undo_BeginBlock2( 0 )
  item = GetSelectedMediaItem(0,0)
  ConvertRS5kMIDI2AudioItems(item)
  reaper.Undo_EndBlock2( 0, scr_nm, 0 )