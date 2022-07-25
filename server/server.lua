local Framework = exports['pepe-core']:GetCoreObject()

-- Code

Framework.Functions.CreateCallback('pepe-burgershot:server:has:burger:items', function(source, cb)
    local Count = 0
    local Player = Framework.Functions.GetPlayer(source)
    for k, v in pairs(Config.BurgerItems) do
        local BurgerData = Player.Functions.GetItemByName(v)
        if BurgerData ~= nil then
           Count = Count + 1
        end
    end
    if Count == 3 then
        cb(true)
    else
        cb(false)
    end 
end)

RegisterServerEvent('pepe-burgershot:server:finish:burger')
AddEventHandler('pepe-burgershot:server:finish:burger', function(BurgerName)
    local src = source
    local Player = Framework.Functions.GetPlayer(src)
    if Player.PlayerData.job.name ~= 'burger' then
        return -- Not a burger job player can't finish a burger (: BAN HIM
    end
    for k, v in pairs(Config.BurgerItems) do
        Player.Functions.RemoveItem(v, 1, false, true)
        if v == BurgerName then
            Citizen.SetTimeout(350, function()
                Player.Functions.AddItem(BurgerName, 1, false, false, true)
            end)
        end
    end

end)

function CheckPosition(source)
    local Player = Framework.Functions.GetPlayer(source)
    local x, y, z = Player.Functions.GetCoords()
    local Distance = GetDistanceBetweenCoords(x, y, z, Config.Intercom.Worker.X, Config.Intercom.Worker.Y, Config.Intercom.Worker.Z, true)
    if Distance < 15 then
        return true
    else
        return false
    end
end

RegisterServerEvent('pepe-burgershot:server:finish:fries')
AddEventHandler('pepe-burgershot:server:finish:fries', function()
    local src = source
    local Player = Framework.Functions.GetPlayer(src)
    if Player.PlayerData.job.name ~= 'burger' then
        return -- Not a burger job player can't finish a burger (: BAN HIM
    end
    if CheckPosition(src) == false then
        return -- Not in the right position
    end
    if Player.Functions.RemoveItem('burger-potato', 1) then
        Player.Functions.AddItem('burger-fries', math.random(3, 5))
    end
end)

RegisterServerEvent('pepe-burgershot:server:finish:patty')
AddEventHandler('pepe-burgershot:server:finish:patty', function()
    local src = source
    local Player = Framework.Functions.GetPlayer(src)
    if Player.PlayerData.job.name ~= 'burger' then
        return
    end
    if CheckPosition(src) == false then
        return -- Not in the right position
    end
    if Player.Functions.RemoveItem('burger-raw', 1) then
        Player.Functions.AddItem('burger-meat', 1)
    end
end)

RegisterServerEvent('pepe-burgershot:server:finish:drink')
AddEventHandler('pepe-burgershot:server:finish:drink', function(DrinkName)
    local src = source
    local Player = Framework.Functions.GetPlayer(src)
    if Player.PlayerData.job.name ~= 'burger' then
        return
    end
    if CheckPosition(src) == false then
        return -- Not in the right position
    end
    for k, v in pairs(Config.Drinks) do
        if v == DrinkName then
            Player.Functions.AddItem(DrinkName, 1)
        end
    end
end)

RegisterServerEvent('pepe-burgershot:server:add:to:register')
AddEventHandler('pepe-burgershot:server:add:to:register', function(Price, Note)
    local RandomID = math.random(1111,9999)
    Config.ActivePayments[RandomID] = {['Price'] = Price, ['Note'] = Note}
    TriggerClientEvent('pepe-burgershot:client:sync:register', -1, Config.ActivePayments)
end)

RegisterServerEvent('pepe-burgershot:server:get:bag')
AddEventHandler('pepe-burgershot:server:get:bag', function()
    local RandomID = math.random(1111,99999)
    local Player = Framework.Functions.GetPlayer(source)
    Player.Functions.AddItem('burger-box', 1, false, {boxid = RandomID}, true)
end)

RegisterServerEvent('pepe-burgershot:server:pay:receipt')
AddEventHandler('pepe-burgershot:server:pay:receipt', function(Data)
    local src = source
    local Player = Framework.Functions.GetPlayer(src)
    if Player.Functions.RemoveMoney('cash', Data['Price'], 'burger-shot') then
        if Config.ActivePayments[tonumber(Data['BillId'])] ~= nil then
            Config.ActivePayments[tonumber(Data['BillId'])] = nil
            TriggerEvent('pepe-burgershot:give:receipt:to:workers')
            TriggerClientEvent('pepe-burgershot:client:sync:register', -1, Config.ActivePayments)
        else
            TriggerClientEvent('Framework:Notify', src, 'Error..', 'error')
        end
    else
        TriggerClientEvent('Framework:Notify', src, 'Je hebt niet genoeg contant geld..', 'error')
    end
end)

RegisterServerEvent('pepe-burgershot:give:receipt:to:workers')
AddEventHandler('pepe-burgershot:give:receipt:to:workers', function()
    for k, v in pairs(Framework.Functions.GetPlayers()) do
        local Player = Framework.Functions.GetPlayer(v)
        if Player ~= nil and Player.PlayerData.job.name == 'burger' and Player.PlayerData.job.onduty then
            Player.Functions.AddItem('burger-ticket', 1)
        end
    end
end)

RegisterServerEvent('pepe-burgershot:server:sell:tickets')
AddEventHandler('pepe-burgershot:server:sell:tickets', function()
    local src = source
    local Player = Framework.Functions.GetPlayer(src)
    for k, v in pairs(Player.PlayerData.inventory) do
        if v.name == 'burger-ticket' then
            Player.Functions.RemoveItem('burger-ticket', v.amount)
            Player.Functions.AddMoney('cash', (math.random(60, 100) * v.amount), 'burgershot-payment')
        end
    end
end)

RegisterServerEvent('pepe-burgershot:server:alert:workers')
AddEventHandler('pepe-burgershot:server:alert:workers', function()
    TriggerClientEvent('pepe-burgershot:client:call:intercom', -1)
end)

RegisterServerEvent('pepe-burgershot:server:give:payment')
AddEventHandler('pepe-burgershot:server:give:payment', function(PlayerId)
    local Player = Framework.Functions.GetPlayer(PlayerId)
    if Player ~= nil then
        TriggerClientEvent('pepe-burgershot:client:open:payment', PlayerId)
    else
        TriggerClientEvent('Framework:Notify', source, 'Dit is niet juist..', 'error')
    end
end)

Framework.Commands.Add("setburger", "Neem een burgershot medewerker aan", {{name="id", help="Speler ID"}}, true, function(source, args)
    local Player = Framework.Functions.GetPlayer(source)
    local TargetPlayer = Framework.Functions.GetPlayer(tonumber(args[1]))
    if Player.PlayerData.metadata['ishighcommand'] and Player.PlayerData.job.name == 'burger' then
        if TargetPlayer ~= nil then
            TriggerClientEvent('Framework:Notify', TargetPlayer.PlayerData.source, 'Je bent aangenomen als burgershot medewerker! gefeliciteerd!', 'success')
            TriggerClientEvent('Framework:Notify', Player.PlayerData.source, 'Je hebt '..TargetPlayer.PlayerData.charinfo.firstname..' '..TargetPlayer.PlayerData.charinfo.lastname..' aangenomen als burgershot medewerker!', 'success')
            TargetPlayer.Functions.SetJob('burger')
        end
    end
end)

Framework.Commands.Add("fireburger", "Ontsla een burgershot medewerker", {{name="id", help="Speler ID"}}, true, function(source, args)
    local Player = Framework.Functions.GetPlayer(source)
    local TargetPlayer = Framework.Functions.GetPlayer(tonumber(args[1]))
    if Player.PlayerData.metadata['ishighcommand'] and Player.PlayerData.job.name == 'burger' then
        if TargetPlayer ~= nil and TargetPlayer.PlayerData.job.name == 'burger' then
            TriggerClientEvent('Framework:Notify', TargetPlayer.PlayerData.source, 'Je bent ontslagen!', 'error')
            TriggerClientEvent('Framework:Notify', Player.PlayerData.source, 'Je hebt '..TargetPlayer.PlayerData.charinfo.firstname..' '..TargetPlayer.PlayerData.charinfo.lastname..' ontslagen!', 'success')
            TargetPlayer.Functions.SetJob('unemployed')
        end
    end
end)