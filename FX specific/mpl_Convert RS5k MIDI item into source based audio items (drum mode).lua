-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Convert RS5k MIDI item into source based audio items (drum mode)
-- @changelog
--    # obey pitches / length
--    # obey sample offset
--    # obey sample pan

  local scr_nm = 'Convert RS5k MIDI item into source based audio items (drum mode)'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) ShowConsoleMsg(s) end
  ------------------------------------------------------------------------------
  function ConvertRS5kMIDI2AudioItems(item)
    if not item then return end
    take = GetActiveTake(item)
    if not take or not TakeIsMIDI(take) then return end
    
    local tr= GetMediaItem_Track( item )
    
    -- build pitch map
      p_map = {}
      for fx = 1, TrackFX_GetCount( tr ) do
        local retval, buf = TrackFX_GetParamName( tr, fx-1, 3, '' )
        if retval and buf == 'Note range start' then
          local pitch = math.floor(TrackFX_GetParam( tr, fx-1, 3 )  * 128)
          local pitch_offset = TrackFX_GetParam( tr, fx-1, 15)
          local start_offs = TrackFX_GetParamNormalized(  tr, fx-1, 13 )
          local end_offs = TrackFX_GetParamNormalized(  tr, fx-1, 14 )
          local pan = TrackFX_GetParamNormalized(  tr, fx-1, 1 )
          local retval2, sample_path = reaper.TrackFX_GetNamedConfigParm( tr, fx-1, 'FILE' )
          if retval2 then 
            local src =  PCM_Source_CreateFromFileEx( sample_path, false )
            local srclen = GetMediaSourceLength( src )
            if not src then return end
            p_map[pitch] = {spl = sample_path,
                            src=src,
                            srclen=srclen,
                            pitch_offset=(pitch_offset-0.5)*160,
                            start_offs=start_offs,
                            end_offs=end_offs,
                            pan=pan
                            }
                            
          end
        end
      end
      
    
    
    -- collect data
      local data ={}
      for i = 1,  ({MIDI_CountEvts( take )})[2] do 
        local _, s, m, sppq, eppq, c,p, v =MIDI_GetNote( take, i-1 )
        if m then m = 1 else m = 0 end
        data[#data+1] = {mute = m,
                         pos =  MIDI_GetProjTimeFromPPQPos( take, sppq ),
                         vol = v/127,
                         pitch=p}
      end
      
    -- add audio items
      SetMediaItemInfo_Value( item, 'B_MUTE', 1 ) -- mute MIDI
      for i = 1, #data do
        local new_item = AddMediaItemToTrack( tr )
        local take = AddTakeToMediaItem( new_item )
        local p0 = data[i].pitch
        if p_map[p0] then
          local prate = 2^(p_map[p0].pitch_offset/12) 
          SetMediaItemTake_Source( take, p_map[p0].src )
          
          SetMediaItemInfo_Value( new_item, 'B_MUTE', data[i].mute )
          SetMediaItemInfo_Value( new_item, 'D_VOL', data[i].vol )
          SetMediaItemInfo_Value( new_item, 'D_POSITION', data[i].pos )
          SetMediaItemInfo_Value( new_item, 'D_LENGTH', (p_map[p0].end_offs - p_map[p0].start_offs)  * p_map[p0].srclen/prate   ) 
          SetMediaItemTakeInfo_Value( take, 'D_STARTOFFS', p_map[p0].start_offs   * p_map[p0].srclen) 
          SetMediaItemTakeInfo_Value( take, 'D_PAN', (p_map[p0].pan-0.5)*2) 
          SetMediaItemTakeInfo_Value( take, 'D_PITCH',  p_map[p0].pitch_offset )
          SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE', prate)
           
        end
      end
    
    UpdateArrange()
  end
  ------------------------------------------------------------------------------
  Undo_BeginBlock2( 0 )
  item = GetSelectedMediaItem(0,0)
  ConvertRS5kMIDI2AudioItems(item)
  Undo_EndBlock2( 0, scr_nm, 0 )