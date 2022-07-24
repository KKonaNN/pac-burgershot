local CurrentWorkObject, InRange, ShowingInteraction, AddedProps = {}, false, false, false
local Framework, PlayerJob, LoggedIn = exports['pepe-core']:GetCoreObject(), {}, false

RegisterNetEvent('Framework:Client:OnPlayerLoaded')
AddEventHandler('Framework:Client:OnPlayerLoaded', function()
    Citizen.SetTimeout(1250, function()
        PlayerJob = Framework.Functions.GetPlayerData().job
        Citizen.Wait(1200)
        LoggedIn = true
    end)
end)

RegisterNetEvent('Framework:Client:OnPlayerUnload')
AddEventHandler('Framework:Client:OnPlayerUnload', function()
	RemoveWorkObjects()
    LoggedIn, AddedProps = false, false
end)

RegisterNetEvent('Framework:Client:OnJobUpdate')
AddEventHandler('Framework:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('Framework:Client:SetDuty')
AddEventHandler('Framework:Client:SetDuty', function()
    PlayerJob = Framework.Functions.GetPlayerData().job
end)

-- Citizen.CreateThread(function()
--     Citizen.SetTimeout(1, function()
--         TriggerEvent("Framework:GetObject", function(obj) Framework = obj end)    
--         PlayerJob = Framework.Functions.GetPlayerData().job
--         Citizen.Wait(1200)
--         LoggedIn = true
--     end)
-- end)

-- Code

-- // Loops \\ --

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(4)
        if LoggedIn then
            local NearAnything = false
            local PlayerCoords = GetEntityCoords(GetPlayerPed(-1))
            if PlayerJob.name == 'burger' and PlayerJob.onduty then
                local Distance = #(PlayerCoords - Config.Intercom['Worker'])
                if Distance < 1.5 then
                    NearAnything = true
                    if not ShowingInteraction then
                        ShowingInteraction = true
                        exports['pepe-ui']:ShowInteraction('Drive Intercom', 'primary')
                        exports.tokovoip_script:addPlayerToRadio(878914, 'Telefoon')
                    end
                end
            end
            local Distance = #(PlayerCoords - Config.Intercom['Customer'])
            if Distance < 3.0 then
                NearAnything = true
                if not ShowingInteraction then
                    ShowingInteraction = true
                    TriggerServerEvent('pepe-burgershot:server:alert:workers')
                    exports['pepe-ui']:ShowInteraction('Drive Intercom', 'primary')
                    exports.tokovoip_script:addPlayerToRadio(878914, 'Telefoon')
                end
            end
            if not NearAnything then
                if ShowingInteraction then
                    ShowingInteraction = false
                    exports['pepe-ui']:HideInteraction()
                    exports.tokovoip_script:removePlayerFromRadio(878914)
                end
                Citizen.Wait(1000)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(4)
        if LoggedIn then
            local PlayerCoords = GetEntityCoords(GetPlayerPed(-1))
            local Distance = GetDistanceBetweenCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, -1193.70, -892.50, 13.99, true)
            InRange = false
            if Distance < 35.0 then
                InRange = true
                if not AddedProps then
                    AddedProps = true
                    SpawnWorkObjects()
                end
            end
            if not InRange then
                CheckDuty()
                if AddedProps then
                    AddedProps = false
                    RemoveWorkObjects()
                end
                Citizen.Wait(1500)
            end
        end
    end
end)

-- // Events \\ --

RegisterNetEvent('pepe-burgershot:client:give:payment')
AddEventHandler('pepe-burgershot:client:give:payment', function()
    local PlayerContext = {['Title'] = 'Paypal ID?', ['Type'] = 'number', ['Logo'] = '<i class="fas fa-sort-numeric-up-alt"></i>'}
    Framework.Functions.OpenInput(PlayerContext, function(PlayerId)
        if PlayerId ~= false then
            TriggerServerEvent('pepe-burgershot:server:give:payment', tonumber(PlayerId))
        end
    end)
end)

RegisterNetEvent('pepe-burgershot:client:call:intercom')
AddEventHandler('pepe-burgershot:client:call:intercom', function()
    if Framework.Functions.GetPlayerData().job.name =='burger' and Framework.Functions.GetPlayerData().job.onduty then
        Framework.Functions.Notify('Er staat iemand bij de drive..', 'info', 10000)
        PlaySoundFrontend( -1, "Beep_Green", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1)
    end
end)

RegisterNetEvent('pepe-burgershot:client:open:payment')
AddEventHandler('pepe-burgershot:client:open:payment', function()
    local MenuItems = {}
    for k, v in pairs(Config.ActivePayments) do
        if Config.ActivePayments[k] ~= nil then
          local NewData = {}
          NewData['Title'] = 'Bestelling: #'..k
          NewData['Desc'] = 'Kosten: €'..v['Price']..' <br>Notitie: '..v['Note']
          NewData['Data'] = {['Event'] = 'pepe-burgershot:server:pay:receipt', ['Type'] = 'Server', ['BillId'] = k, ['Price'] = v['Price'], ['Note'] = v['Note']}
          table.insert(MenuItems, NewData)
        end
    end
    if #MenuItems > 0 then
        local Data = {['Title'] = 'Openstaande Bestellingen', ['MainMenuItems'] = MenuItems}
        Framework.Functions.OpenMenu(Data)
    else
        Framework.Functions.Notify("Er zijn geen actieve bestellingen..", "error")
    end
end)

RegisterNetEvent('pepe-burgershot:client:open:register')
AddEventHandler('pepe-burgershot:client:open:register', function()
  local PrData = {['Title'] = 'Kosten?', ['Type'] = 'number', ['Logo'] = '<i class="fas fa-coins"></i>'}
  local TxData = {['Title'] = 'Bestelling?', ['Type'] = 'text', ['Logo'] = '<i class="fas fa-hamburger"></i>'}
  Framework.Functions.OpenInput(PrData, function(PriceData)
      if PriceData ~= false then
        Citizen.Wait(250)
        Framework.Functions.OpenInput(TxData, function(NoteData)
          if NoteData ~= false then
            TriggerServerEvent('pepe-burgershot:server:add:to:register', PriceData, NoteData)
          end
        end)
      end
  end)
end)

RegisterNetEvent('pepe-burgershot:client:sync:register')
AddEventHandler('pepe-burgershot:client:sync:register', function(RegisterConfig)
    Config.ActivePayments = RegisterConfig
end)

RegisterNetEvent('pepe-burgershot:client:open:box')
AddEventHandler('pepe-burgershot:client:open:box', function(BoxId)
    TriggerServerEvent("pepe-inventory:server:OpenInventory", "stash", 'burgerbox_'..BoxId, {maxweight = 5000, slots = 6})
    TriggerEvent("pepe-inventory:client:SetCurrentStash", 'burgerbox_'..BoxId)
end)

RegisterNetEvent('pepe-burgershot:client:open:cold:storage')
AddEventHandler('pepe-burgershot:client:open:cold:storage', function()
    TriggerServerEvent("pepe-inventory:server:OpenInventory", "stash", "burger_storage", {maxweight = 1000000, slots = 10})
    TriggerEvent("pepe-inventory:client:SetCurrentStash", "burger_storage")
end)

RegisterNetEvent('pepe-burgershot:client:open:hot:storage')
AddEventHandler('pepe-burgershot:client:open:hot:storage', function()
    TriggerServerEvent("pepe-inventory:server:OpenInventory", "stash", "warmtebak", {maxweight = 1000000, slots = 10})
    TriggerEvent("pepe-inventory:client:SetCurrentStash", "warmtebak")
end)

RegisterNetEvent('pepe-burgershot:client:open:tray')
AddEventHandler('pepe-burgershot:client:open:tray', function(Number)
    TriggerServerEvent("pepe-inventory:server:OpenInventory", "stash", "foodtray"..Number, {maxweight = 100000, slots = 3})
    TriggerEvent("pepe-inventory:client:SetCurrentStash", "foodtray"..Number)
end)

RegisterNetEvent('pepe-burgershot:client:create:burger')
AddEventHandler('pepe-burgershot:client:create:burger', function(BurgerType)
    Framework.Functions.TriggerCallback('pepe-burgershot:server:has:burger:items', function(HasBurgerItems)
        if HasBurgerItems then
           MakeBurger(BurgerType)
        else
          Framework.Functions.Notify("Je mist ingredienten om dit broodje te maken..", "error")
        end
    end)
end)

RegisterNetEvent('pepe-burgershot:client:create:drink')
AddEventHandler('pepe-burgershot:client:create:drink', function(DrinkType)
    MakeDrink(DrinkType)
end)

RegisterNetEvent('pepe-burgershot:client:bake:fries')
AddEventHandler('pepe-burgershot:client:bake:fries', function()
    Framework.Functions.TriggerCallback('Framework:HasItem', function(HasItem)
        if HasItem then
           MakeFries()
        else
          Framework.Functions.Notify("Je mist pattatekes..", "error")
        end
    end, 'burger-potato')
end)

RegisterNetEvent('pepe-burgershot:client:bake:meat')
AddEventHandler('pepe-burgershot:client:bake:meat', function()
    Framework.Functions.TriggerCallback('Framework:HasItem', function(HasItem)
        if HasItem then
           MakePatty()
        else
          Framework.Functions.Notify("Je mist vlees..", "error")
        end
    end, 'burger-raw')
end)

-- // Functions \\ --

function MakeBurger(BurgerName)
    Citizen.SetTimeout(750, function()
        
    TriggerEvent('pepe-inventory:client:set:busy', true)
        exports['pepe-assets']:RequestAnimationDict("mini@repair")
        TaskPlayAnim(GetPlayerPed(-1), "mini@repair", "fixing_a_ped" ,3.0, 3.0, -1, 8, 0, false, false, false)
        Framework.Functions.Progressbar("open-brick", "Hamburger Maken..", 7500, false, true, {
            disableMovement = true,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            TriggerServerEvent('pepe-burgershot:server:finish:burger', BurgerName)
            TriggerEvent('pepe-inventory:client:set:busy', false)
            StopAnimTask(GetPlayerPed(-1), "mini@repair", "fixing_a_ped", 1.0)
        end, function()
            TriggerEvent('pepe-inventory:client:set:busy', false)
            Framework.Functions.Notify("Geannuleerd..", "error")
            StopAnimTask(GetPlayerPed(-1), "mini@repair", "fixing_a_ped", 1.0)
        end)
    end)
end

function MakeFries()
    TriggerEvent('pepe-inventory:client:set:busy', true)
    TriggerEvent("pepe-sound:client:play", "baking", 0.7)
    exports['pepe-assets']:RequestAnimationDict("amb@prop_human_bbq@male@base")
    TaskPlayAnim(GetPlayerPed(-1), "amb@prop_human_bbq@male@base", "base" ,3.0, 3.0, -1, 8, 0, false, false, false)
    Framework.Functions.Progressbar("open-brick", "Frietjes Bakken..", 6500, false, true, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {
        model = "prop_cs_fork",
        bone = 28422,
        coords = { x = -0.005, y = 0.00, z = 0.00 },
        rotation = { x = 175.0, y = 160.0, z = 0.0 },
    }, {}, function() -- Done
        TriggerServerEvent('pepe-burgershot:server:finish:fries')
        TriggerEvent('pepe-inventory:client:set:busy', false)
        StopAnimTask(GetPlayerPed(-1), "amb@prop_human_bbq@male@base", "base", 1.0)
    end, function()
        TriggerEvent('pepe-inventory:client:set:busy', false)
        Framework.Functions.Notify("Geannuleerd..", "error")
        StopAnimTask(GetPlayerPed(-1), "amb@prop_human_bbq@male@base", "base", 1.0)
    end)
end

function MakePatty()
    TriggerEvent('pepe-inventory:client:set:busy', true)
    TriggerEvent("pepe-sound:client:play", "baking", 0.7)
    exports['pepe-assets']:RequestAnimationDict("amb@prop_human_bbq@male@base")
    TaskPlayAnim(GetPlayerPed(-1), "amb@prop_human_bbq@male@base", "base" ,3.0, 3.0, -1, 8, 0, false, false, false)
    Framework.Functions.Progressbar("open-brick", "Burger Bakken..", 6500, false, true, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {
        model = "prop_cs_fork",
        bone = 28422,
        coords = { x = -0.005, y = 0.00, z = 0.00},
        rotation = { x = 175.0, y = 160.0, z = 0.0},
    }, {}, function() -- Done
        TriggerServerEvent('pepe-burgershot:server:finish:patty')
        TriggerEvent('pepe-inventory:client:set:busy', false)
        StopAnimTask(GetPlayerPed(-1), "amb@prop_human_bbq@male@base", "base", 1.0)
    end, function()
        TriggerEvent('pepe-inventory:client:set:busy', false)
        Framework.Functions.Notify("Geannuleerd..", "error")
        StopAnimTask(GetPlayerPed(-1), "amb@prop_human_bbq@male@base", "base", 1.0)
    end)
end

function MakeDrink(DrinkName)
    TriggerEvent('pepe-inventory:client:set:busy', false)
    TriggerEvent("pepe-sound:client:play", "pour-drink", 0.4)
    exports['pepe-assets']:RequestAnimationDict("amb@world_human_hang_out_street@female_hold_arm@idle_a")
    TaskPlayAnim(GetPlayerPed(-1), "amb@world_human_hang_out_street@female_hold_arm@idle_a", "idle_a" ,3.0, 3.0, -1, 8, 0, false, false, false)
    Framework.Functions.Progressbar("open-brick", "Drinken Tappen..", 6500, false, true, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        TriggerServerEvent('pepe-burgershot:server:finish:drink', DrinkName)
        TriggerEvent('pepe-inventory:client:set:busy', false)
        StopAnimTask(GetPlayerPed(-1), "amb@world_human_hang_out_street@female_hold_arm@idle_a", "idle_a", 1.0)
    end, function()
        TriggerEvent('pepe-inventory:client:set:busy', false)
        Framework.Functions.Notify("Geannuleerd..", "error")
        StopAnimTask(GetPlayerPed(-1), "amb@world_human_hang_out_street@female_hold_arm@idle_a", "idle_a", 1.0)
    end)
end

function CheckDuty()
    if Framework.Functions.GetPlayerData().job.name =='burger' and Framework.Functions.GetPlayerData().job.onduty then
       TriggerServerEvent('Framework:ToggleDuty')
       Framework.Functions.Notify("Je bent tever van je werk!", "error")
    end
end

function SpawnWorkObjects()
    for k, v in pairs(Config.WorkProps) do
        exports['pepe-assets']:RequestModelHash(v['Prop'])
        WorkObject = CreateObject(GetHashKey(v['Prop']), v["Coords"]["X"], v["Coords"]["Y"], v["Coords"]["Z"], false, true, false)
        SetEntityHeading(WorkObject, v['Coords']['H'])
        if v['PlaceOnGround'] then
        	PlaceObjectOnGroundProperly(WorkObject)
        end
        if not v['ShowItem'] then
        	SetEntityVisible(WorkObject, false)
        end
        FreezeEntityPosition(WorkObject, true)
        SetEntityInvincible(WorkObject, true)
        table.insert(CurrentWorkObject, WorkObject)
    end
end

function RemoveWorkObjects()
    for k, v in pairs(CurrentWorkObject) do
       NetworkRequestControlOfEntity(v)
    	 DeleteEntity(v)
    end
end

function IsInsideBurgershot()
    return InRange
end