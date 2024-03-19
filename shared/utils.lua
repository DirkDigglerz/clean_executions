onReady = function(func)
  CreateThread(function()
    while not Core do Wait(500); end
    if not IsDuplicityVersion() then 
      while not Core.Player.Ready() do Wait(500); end
    end
    func()
  end)
end