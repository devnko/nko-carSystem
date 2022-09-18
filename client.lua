-- Araç İttirme
QBCore = exports['qb-core']:GetCoreObject()
local coreLoaded = false
Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
        Citizen.Wait(200)
    end
    coreLoaded = true
end)

local First = vector3(0.0, 0.0, 0.0)
local Second = vector3(5.0, 5.0, 5.0)

local cVehicle = nil
local Dimensions = nil
local cDistance =  nil
local cVehicleCoords = nil
local IsInFront =  nil
local Hold = 0

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) and coreLoaded then
            local closestVehicle, Distance = QBCore.Functions.GetClosestVehicle()
            if Distance < 4.5 then
                cVehicle = closestVehicle
                cVehicleCoords = GetEntityCoords(cVehicle)
                Dimensions = GetModelDimensions(GetEntityModel(cVehicle), First, Second)
                cDistance = Distance
                if GetDistanceBetweenCoords(cVehicleCoords + GetEntityForwardVector(cVehicle), GetEntityCoords(ped), true) > GetDistanceBetweenCoords(cVehicleCoords + GetEntityForwardVector(cVehicle) * -1, GetEntityCoords(ped), true) then
                    IsInFront = false
                else
                    IsInFront = true
                end
            else
                cVehicle = nil
                Dimensions = nil
                cDistance =  nil
                cVehicleCoords = nil
                IsInFront =  nil
                Hold = 0
            end
        end
        Citizen.Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do 
        local time = 1000
        if cVehicle then
            local ped = PlayerPedId()
            time = 1

            if IsControlPressed(0, 21) and not IsPedJumping(Ped) and IsVehicleSeatFree(cVehicle, -1) and not IsEntityAttachedToEntity(Ped, cVehicle) and IsControlPressed(0, 38) then
                Citizen.Wait(100)
                Hold = Hold + 1
            else
                Hold = 0
            end

            if Hold >= 5 then
                if IsControlPressed(0, 21) and not IsPedJumping(ped) and IsVehicleSeatFree(cVehicle, -1) and not IsEntityAttachedToEntity(ped, cVehicle) and IsControlPressed(0, 38) then
                    NetworkRequestControlOfEntity(cVehicle)
                    local coords = GetEntityCoords(ped)
                    if IsInFront then    
                        AttachEntityToEntity(PlayerPedId(), cVehicle, GetPedBoneIndex(6286), 0.0, Dimensions.y * -1 + 0.1 , Dimensions.z + 1.0, 0.0, 0.0, 180.0, 0.0, false, false, true, false, true)
                    else
                        AttachEntityToEntity(PlayerPedId(), cVehicle, GetPedBoneIndex(6286), 0.0, Dimensions.y - 0.3, Dimensions.z  + 1.0, 0.0, 0.0, 0.0, 0.0, false, false, true, false, true)
                    end

                    QBCore.Shared.RequestAnimDict('missfinale_c2ig_11', function() -- animasyon oynatma
                        TaskPlayAnim(PlayerPedId(), 'missfinale_c2ig_11', 'pushcar_offcliff_m',  2.0, -8.0, -1, 35, 0, 0, 0, 0)
                    end)

                    local currentVehicle = cVehicle
                    while true do
                        Citizen.Wait(5)
                        if IsDisabledControlPressed(0, 34) then
                            TaskVehicleTempAction(PlayerPedId(), currentVehicle, 11, 1000)
                        end

                        if IsDisabledControlPressed(0, 9) then
                            TaskVehicleTempAction(PlayerPedId(), currentVehicle, 10, 1000)
                        end

                        if IsInFront then
                            SetVehicleForwardSpeed(currentVehicle, -1.0)
                        else
                            SetVehicleForwardSpeed(currentVehicle, 1.0)
                        end

                        if not IsDisabledControlPressed(0, 21) then
                            DetachEntity(ped, false, false)
                            StopAnimTask(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0)
                            ClearPedTasks(ped)
                            FreezeEntityPosition(ped, false)
                            break
                        end
                    end
                end
            end
        end
        Citizen.Wait(time)
    end
end)

-- Yakın Olduğun Koltuğa Binme
Settings = {
    KeepEngineOn = true, ---Keeps The engine on after leaving the vehicle if the engine is on,
    NPCCheck = true --- Adds NPC Check to the code(Checks if there is any ped inside vehicle or not)
}

CreateThread(function()
    local dist, index,ped
    while true do
        if IsControlJustPressed(0, 75) then
            ped = PlayerPedId()
            if IsPedInAnyVehicle(ped) then
                if Settings.KeepEngineOn then
                    local veh = GetVehiclePedIsIn(ped)
                    if GetIsVehicleEngineRunning(veh) then
                        TaskLeaveVehicle(ped, veh, 0)
                        Wait(1000)
                        SetVehicleEngineOn(veh, true, true, true)
                    end
                end
            else
                local veh = GetVehiclePedIsTryingToEnter(ped)
                if veh ~= 0 then
                    if CanSit(veh) then
                        local coords = GetEntityCoords(ped)
                        if #(coords - GetEntityCoords(veh)) <= 3.5 then
                            ClearPedTasks(ped)
                            ClearPedSecondaryTask(ped)
                            for i = 0, GetNumberOfVehicleDoors(veh), 1 do
                                local coord = GetEntryPositionOfDoor(veh, i)
                                if (IsVehicleSeatFree(veh, i - 1) and
                                    GetVehicleDoorLockStatus(veh) ~= 2) then
                                    if dist == nil then
                                        dist = #(coords - coord)
                                        index = i
                                    end
                                    if #(coords - coord) < dist then
                                        dist = #(coords - coord)
                                        index = i
                                    end
                                end
                            end
                            if index then
                                TaskEnterVehicle(ped, veh, 10000, index - 1,1.0, 1, 0)
                            end
                            index, dist = nil, nil
                        end
                    end
                end
            end
        end
        Wait(1)
    end
end)

CanSit = function(veh)
    if not Settings.NPCCheck then 
        return true 
    end
    for i = -1, 15 do
        if IsEntityAPed(GetPedInVehicleSeat(veh, i)) then return false end
    end
    return true
end

-- Toprakta Lastik Kayma
local OnDebug = false
local GripAmount = 5.8000001907349 -- Max amount = 9.8000001907349 | Default = 5.8000001907349 (Grip amount when on drift)


Citizen.CreateThread(function()
	while true do
		local veh = GetVehiclePedIsIn(PlayerPedId())

		if veh == 0 then -- Player isnt in a vehicle
			Citizen.Wait(500)

		else -- Player is in a vehicle

			local material_id = GetVehicleWheelSurfaceMaterial(veh, 1)
			local wheel_type = GetVehicleWheelType(veh)

			if wheel_type == 3 or wheel_type == 4 or wheel_type == 6 then -- If have Off-road/Suv's/Motorcycles wheel grip its equal
			else
				if material_id == 4 or material_id == 1 or material_id == 3 then -- All road (sandy/los santos/paleto bay)
					-- On road
					SetVehicleGravityAmount(veh, 9.8000001907349)
					if OnDebug then
						text = "You are on the road"
					end
				else
					-- Off road
					if GripAmount >= 9.8000001907349 then
						GripAmount = 5.8000001907349
					end

					SetVehicleGravityAmount(veh, GripAmount)
					if OnDebug then
						text = "You aren't on the road"
					end
				end
			end

			if OnDebug then
				Drawtext()
				Citizen.Wait(1)
			else
				Citizen.Wait(200)
			end
		end
	end
end)

function Drawtext()
	SetTextScale(0.7, 0.7)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(1)
    SetTextColour(255, 255, 255, 215)

	AddTextComponentString(text)
    DrawText(0.5, 0.9)
end

-- Vehicles to enable/disable air control
local vehicleClassDisableControl = {
    [0] = true,     --compacts
    [1] = true,     --sedans
    [2] = true,     --SUV's
    [3] = true,     --coupes
    [4] = true,     --muscle
    [5] = true,     --sport classic
    [6] = true,     --sport
    [7] = true,     --super
    [8] = false,    --motorcycle
    [9] = true,     --offroad
    [10] = true,    --industrial
    [11] = true,    --utility
    [12] = true,    --vans
    [13] = false,   --bicycles
    [14] = false,   --boats
    [15] = false,   --helicopter
    [16] = false,   --plane
    [17] = true,    --service
    [18] = true,    --emergency
    [19] = false    --military
}

-- Main thread
Citizen.CreateThread(function()
    while true do
        -- Loop forever and update every frame
        Citizen.Wait(0)

        -- Get player, vehicle and vehicle class
        local player = GetPlayerPed(-1)
        local vehicle = GetVehiclePedIsIn(player, false)
        local vehicleClass = GetVehicleClass(vehicle)

        -- Disable control if player is in the driver seat and vehicle class matches array
        if ((GetPedInVehicleSeat(vehicle, -1) == player) and vehicleClassDisableControl[vehicleClass]) then
            -- Check if vehicle is in the air and disable L/R and UP/DN controls
            if IsEntityInAir(vehicle) then
                DisableControlAction(2, 59)
                DisableControlAction(2, 60)
            end
        end
    end
end)

-- Araç Rengi Değiştirme

local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
}

local kordinat = { -- 3 Farklı kordinatın parasını ayrı olarak ayarlıyabilirsiniz 
    {x = 519.9004, y = 168.6675, z = 99.663, para = 750, npc = {x = 515.0723, y = 167.9203, z = 98.368, h = 274.39}}, -- 519.9004, 168.6675, 99.663
    {x = 151.5323, y = -3080.26, z = 6.2840, para = 750, npc = {x = 154.2611, y = -3082.70, z = 4.8963, h = 97.78}}, 
    {x = 146.9751, y = 320.9965, z = 112.33, para = 750, npc = {x = 150.5802, y = 322.7590, z = 111.33, h = 107.78}}, 
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k,v in pairs(kordinat) do
            
            local plyCoords = GetEntityCoords(PlayerPedId(), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.x, v.y, v.z)
            if IsPedInAnyVehicle(PlayerPedId(), true) then
                if dist <= 5 then
                    DrawText3Ds(v.x, v.y, v.z -0.5, "[~r~E~w~] - Aracı Boyat ~g~$~g~"..v.para)
                    if IsControlJustPressed(0, Keys['E']) then
                        QBCore.Functions.TriggerCallback("nko-carColor", function(cb)
                            if cb then 
                                local dispatchoran = math.random(0, 100)
                                if dispatchoran >= 70 then  -- %kaç oranla bildirim gitmesini istiyorsanız 70'i değiştiriniz
                                    local ra1der_ped = PlayerPedId()
                                    --TriggerServerEvent('m3:dispatch:notify', 'İllegal Modifiye Yapılıyor!', '', '', GetEntityCoords(ra1der_ped)) -- Farklı dispatch kullanıyorsanız kendinize göre düzenleyiniz.
                                end
                                exports['progressbar']:Progress({
                                    name = "nko-randomcolor",
                                    duration = Config.Sure,
                                    label = "Araç Boyanıyor!",
                                    useWhileDead = false,
                                    canCancel = true,
                                    controlDisables = {
                                        disableMovement = true,
                                        disableCarMovement = true,
                                        disableMouse = false,
                                        disableCombat = true,
                                    },
                                }, function(cancelled)
                                    if not cancelled then
                                    end
                                end) 
                                for r = 1, Config.RSure do 
                                    Wait(1) 
                                    if IsControlJustPressed(0, 178) then
                                            TriggerServerEvent("nko-paraIade", v.para)-- iptal edildiğinde aldığı parayı verir
                                            exports["Venice-Notification"]:Notify("İşlem İptal Edlidi", 5000, "error")
                                            --exports['codem-notification']:SendAlert('error', 'İşlem İptal Edlidi')
                                            return
                                    elseif r == Config.Sure then 
                                    end
                                end
                                exports["Venice-Notification"]:Notify("Araç Başarıyla Boyandı", 5000, "success")
                                --exports['codem-notification']:SendAlert('success', 'Araç Başarıyla Boyandı!')
                                local sans = math.random(1,100)
                                local ped = PlayerPedId()
                                local vehicle = GetVehiclePedIsIn(ped, false)
                                
                                if sans >= 0 and sans <= 100 then
                                    SetVehicleColours(vehicle, sans)
                                end
                            elseif not cb then 
                                exports["Venice-Notification"]:Notify("Yeterli Paran Yok", 5000, "error")
                                --exports['codem-notification']:SendAlert('error', 'Yeterli Paran Yok!')
                            end
                        end, v.para)
                    end
                end
            end
        end
    end
end)

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x,y,z)
    if onScreen then
        local factor = #text / 370
        SetTextScale(0.27, 0.27)
        SetTextFont(10)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        DrawRect(_x, _y + 0.0120, 0.006 + factor, 0.024, 0, 0, 0, 155)
    end
end
  
Citizen.CreateThread(function()
	RequestModel(Config.npcHash)
		while not HasModelLoaded(Config.npcHash) do
			Wait(1)
		end
        for k,v in pairs(kordinat) do  
            meth_dealer_seller = CreatePed(1, Config.NPCHash, v.npc.x, v.npc.y, v.npc.z, v.npc.h, false, true)
            SetBlockingOfNonTemporaryEvents(meth_dealer_seller, true)
            SetPedDiesWhenInjured(meth_dealer_seller, false)
            SetPedCanPlayAmbientAnims(meth_dealer_seller, true)
            SetPedCanRagdollFromPlayerImpact(meth_dealer_seller, false)
            SetEntityInvincible(meth_dealer_seller, true)
            FreezeEntityPosition(meth_dealer_seller, true)
            TaskStartScenarioInPlace(meth_dealer_seller, "WORLD_HUMAN_SMOKING", 0, true);
        end
end)