local getNearestPlayer = function()
  local my_pos = GetEntityCoords(cache.ped)
  local players = GetGamePool('CPed')
  local closest = {dist = 9999, id = nil}
  for k,v in pairs(players) do 
    if IsPedAPlayer(v) and v ~= -1 and v ~= cache.ped then 
      local pos = GetEntityCoords(v)
      local dist = #(my_pos - pos)
      if dist < closest.dist then 
        closest.dist = dist
        closest.id = v
      end
    end
  end
  return closest.id, closest.dist
end


local electrocution = {
  idle   = {
    dict = 'missfbi3_electrocute', 
    anim = 'clamp_wait_loop_victim',
  },
  
  action = {
    dict = 'missfbi3_electrocute', 
    anim = 'electrocute_both_loop_victim',
  },
}

local in_chair    = false
local chair_model = Config.chair_model
local chair_pos   = Config.chair_pos


playTortureAnimation = function(_type)
  local anim, dict = electrocution[_type].anim, electrocution[_type].dict
  local player = PlayerPedId()
  while not HasAnimDictLoaded(dict) do   RequestAnimDict(dict); Wait(500); end
  TaskPlayAnim(player, dict, anim, 8.0, 8.0, -1, 3, 0, 0, 0, 0)
end

onReady(function()
  in_chair = Core.SyncCallback('dirk-electrocution:getInChair')
  Core.Objects.Register('electric_chair', {
    Type = 'object',
    Pos  = chair_pos,
    Model = chair_model,
    Radius = 50.0,
  }, function(event, data)
    if event == 'spawn' then 
      Core.Target.AddEntity(data.entity, {
        Local = true, 
        Distance = 1.5,
        Options  = {
          {
            distance = 1.5, 
            label = 'Tether Victim',
            icon  = 'fas fa-chair',
            canInteract = function()
              if in_chair then return false end
              return true
            end,


            action = function()
              local player, dist = getNearestPlayer()
              if player and dist <= 1.5 then 
                local server_id = NetworkGetPlayerIndexFromPed(player)
                local server_id_raw = GetPlayerServerId(server_id)
                TriggerServerEvent('dirk-electrocution:putInChair', server_id_raw)   
              else 
                Core.UI.Notify('No player nearby', 'error')
              end  
            end
          }, 
          {
            distance = 1.5, 
            label = 'Electrocute Victim',
            icon  = 'fas fa-bolt',
            canInteract = function()
              if not in_chair then return false end
              return true
            end,
            action = function()
              if not in_chair then return end
              TriggerServerEvent('dirk-electrocution:electrocuteInChair')
            end
          }, 

          {
            distance = 1.5, 
            label = 'Remove Victim',
            icon  = 'fas fa-user-minus',
            canInteract = function()
              if not in_chair then return false end
              if in_chair == GetPlayerServerId(cache.ped) then return false; end 
              return true
            end,
            action = function()
              if not in_chair then return end
              TriggerServerEvent('dirk-electrocution:removeFromChair')
            end
          }
        } 
      })
    end
  end)
end)


RegisterNetEvent('dirk-electrocution:putInChair', function(player)
  local my_server_id = GetPlayerServerId(PlayerId())
  if player == my_server_id then 
    in_chair = player
    disableControls();
    -- Set In chair 
    FreezeEntityPosition(cache.ped, true)
    SetEntityCoords(cache.ped, chair_pos.x, chair_pos.y, chair_pos.z - 0.55)
    SetEntityHeading(cache.ped, chair_pos.w - 180.0)

    -- Set to Idle Animation 
    playTortureAnimation('idle')
  end

  in_chair = player
end)

local ptfx = {
  dict = "core",
  name = "ent_dst_electrical",
  duration = 5000,
  loops = 100,
}

local playingFx = false
createPlayerModePtfxLoop = function(tgtPedId)
  SetArtificialLightsState(true)
  SetTimeout(5000, function()
    SetArtificialLightsState(false)
  end)
  playingFx = true
  CreateThread(function()
      if tgtPedId <= 0 or tgtPedId == nil then return end
      RequestNamedPtfxAsset(ptfx.dict)
      while not HasNamedPtfxAssetLoaded(ptfx.dict) do Wait(0); end
      local particleTbl = {}
      for i = 0, ptfx.loops do
          UseParticleFxAsset(ptfx.dict)
          -- local partiResult = StartParticleFxLoopedOnEntity(ptfx.name, tgtPedId, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, false, false, false)
          local partiResult = StartParticleFxLoopedAtCoord(ptfx.name, chair_pos.x, chair_pos.y, chair_pos.z, 0.0, 0.0, 0.0, 1.5, false, false, false, false)
          particleTbl[#particleTbl + 1] = partiResult
          Wait(0)
      end
      Wait(ptfx.duration)
      for i = 1, #particleTbl do
        StopParticleFxLooped(particleTbl[i], true)
      end
      playingFx = false
  end)
end

RegisterNetEvent('dirk-electrocution:electrocuteInChair', function()
  local dist_to_chair = #(GetEntityCoords(cache.ped) - chair_pos.xyz)
  local my_server_id = GetPlayerServerId(PlayerId())
  if in_chair == my_server_id then
    if not in_chair then return end
    playTortureAnimation('action')
    local health = GetEntityHealth(cache.ped)
    SetEntityHealth(cache.ped, health - 25)
  end

  if dist_to_chair <= 30.5 then 
    createPlayerModePtfxLoop(in_chair)
  end
end)

RegisterNetEvent('dirk-electrocution:removeFromChair', function()
  local my_server_id = GetPlayerServerId(PlayerId())
  if in_chair == my_server_id  then 
    enableControls()
    FreezeEntityPosition(cache.ped, false)
    SetEntityCoords(cache.ped, chair_pos.x + 1.0, chair_pos.y, chair_pos.z + 1.0)
    ClearPedTasks(cache.ped)
  end
  in_chair = false
end)


local disabled_controls = false
disableControls = function()
  disabled_controls = true
  CreateThread(function()
    while disabled_controls do
      DisableAllControlActions(0)
      DisableAllControlActions(1)
      if IsEntityDead(cache.ped) then 
        enableControls()
        FreezeEntityPosition(false,false)
      end
      Wait(0)
    end
  end)
end

enableControls = function()
  disabled_controls = false
end

