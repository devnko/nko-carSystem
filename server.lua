local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback("nko-carColor", function(source, cb, para)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if xPlayer.PlayerData.money.cash >= para then
        xPlayer.Functions.RemoveMoney('cash', para)
        cb(true)
      else
        cb(false)
      end
end)

RegisterServerEvent("nko-paraIade")
AddEventHandler("nko-paraIade", function(para)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    xPlayer.Functions.AddMoney("cash", para)
end)