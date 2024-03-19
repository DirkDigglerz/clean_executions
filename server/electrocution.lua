local in_chair = false
onReady(function()
  Core.Callback('dirk-electrocution:getInChair', function(src,cb)
    cb(in_chair)
  end)
end)

RegisterNetEvent('dirk-electrocution:putInChair', function(player)
  if in_chair then return end
  in_chair = player
  TriggerClientEvent('dirk-electrocution:putInChair', -1, player)
end)

RegisterNetEvent('dirk-electrocution:electrocuteInChair', function()
  if not in_chair then return end
  TriggerClientEvent('dirk-electrocution:electrocuteInChair', -1)
end)

RegisterNetEvent('dirk-electrocution:removeFromChair', function()
  in_chair = false
  TriggerClientEvent('dirk-electrocution:removeFromChair', -1)
end)

AddEventHandler('onPlayerDropped', function(src, reason)
  if in_chair == src then 
    in_chair = false
    TriggerClientEvent('dirk-electrocution:removeFromChair', -1)
  end
end)