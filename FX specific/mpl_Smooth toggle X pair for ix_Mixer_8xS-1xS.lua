-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Smooth toggle X pair for ix_Mixer_8xS-1xS
-- @website http://forum.cockos.com/member.php?u=70694
-- @metapackage
-- @provides
--   [main] . > mpl_Smooth toggle 3-4 pair for ix_Mixer_8xS-1xS.lua
--   [main] . > mpl_Smooth toggle 5-6 pair for ix_Mixer_8xS-1xS.lua
--   [main] . > mpl_Smooth toggle 7-8 pair for ix_Mixer_8xS-1xS.lua
--   [main] . > mpl_Smooth toggle 9-10 pair for ix_Mixer_8xS-1xS.lua
  
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  function main(state, channel_pair)
    -- get info
      local tr = GetMasterTrack(0)
      local fx = TrackFX_AddByName( tr, 'Mixer_8xS-1xS', false, 1 )
      if fx < 0 then return end
    
    -- form tables
      t0 = {}
      t = {}
      for param = 1,  8 do
        local fol
        if param == 1 then fol =  -60*state
          elseif param == channel_pair+1 then fol = -60*math.abs(1-state) 
          else fol = -60
        end        
        t0[param] = TrackFX_GetParam( tr, fx, param-1)
        t[param] = fol
      end    
    
    ts0 = os.clock()
    local function run_move()
      ts = os.clock()
      diff = 0
      for param = 1, 8 do
        par_val = TrackFX_GetParam( tr, fx, param-1)
        new_val = par_val + (t[param]-par_val)/7
        t0[param] = new_val
        TrackFX_SetParam( tr, fx, param-1, new_val )
        diff = diff + math.abs(t0[param] - par_val)
      end       
      
      if diff > 0.4 or ts - ts0 > 5 then
        defer(run_move) 
       else
        for param = 1, 8 do
          TrackFX_SetParam( tr, fx, param-1, t[param] )
        end             
      end
    end
    
    run_move()
  end
--------------------------------------------------------------------    
  
  local _,_,sectionID,cmdID = get_action_context()
  local state = GetToggleCommandState( cmdID )
  if state == -1 then state = 1 end
  SetToggleCommandState( sectionID, cmdID, math.abs(1-state) )
  Undo_BeginBlock()
  channel_pair = ({reaper.get_action_context()})[2]:match('[%d]')
  if channel_pair then
    main(  (channel_pair-1)/2  )
   else
    error("could not extract send ID from filename")
  end  
  Undo_EndBlock("Smooth toggle "..(channel_pair*2+1)..'-'..(channel_pair*2+2).." pair for ix_Mixer_8xS-1xS", 0)