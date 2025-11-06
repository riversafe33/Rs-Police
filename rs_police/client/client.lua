local IsHandcuffed = false
local display = false
local badgeactive = false
local Jailed = false
local Serviced = false
local Autotele = true
local playerJob
local JailID
local jaillocation
local searchid
local JailEntranceCoords = nil
local Takenmoney = nil
local Search = nil
local InWagon = nil
local spawn_wagon = nil
local Jail_time = 0
local Jail_maxDistance = ConfigJail.EscapeConfig.EscapeDistance
local Jail_penalty = ConfigJail.EscapeConfig.EscapePenaltyTime
local dragStatus = {}
dragStatus.isDragged = false

Citizen.CreateThread(function()
    local showingCabinet = false

    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearCabinet = false

        for _, cabinetCoords in ipairs(ConfigCabinets.Guncabinets) do
            if #(playerCoords - vector3(cabinetCoords.x, cabinetCoords.y, cabinetCoords.z)) < 1.5 then
                nearCabinet = true

                if not showingCabinet then
                    SendNUIMessage({
                        type = "showCabinet",
                        text = ConfigMain.Text.cabinetnui
                    })
                    showingCabinet = true
                end

                if IsControlJustReleased(0, 0x760A9C6F) then
                    TriggerServerEvent("rs_police:checkcabinetjob")
                end
                break
            end
        end

        if not nearCabinet and showingCabinet then
            SendNUIMessage({ type = "hideCabinet" })
            showingCabinet = false
        end

        Citizen.Wait(nearCabinet and 0 or 500)
    end
end)

CreateThread(function()
    while true do
        Wait(5)
        if InWagon then
            SetRelationshipBetweenGroups(1, `PLAYER`, `PLAYER`)
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('rs_police:PlayerInWagon')
AddEventHandler('rs_police:PlayerInWagon', function()
    local ped = PlayerPedId()

    if not IsPedCuffed(ped) then
        return
    end

    local coords = GetEntityCoords(ped)
    local closestWagon = GetClosestVehicle(coords)

    if DoesEntityExist(ped) and DoesEntityExist(closestWagon) then
        if not IsPedInVehicle(ped, closestWagon, false) then
            local rearSeats = {1, 2, 3, 4, 5, 6}
            for i = 1, #rearSeats do
                if IsVehicleSeatFree(closestWagon, rearSeats[i]) then
                    SetPedIntoVehicle(ped, closestWagon, rearSeats[i])
                    InWagon = true
                    break
                end
            end
        else
            TaskLeaveVehicle(ped, closestWagon, 16)
            Wait(5000)
            InWagon = false
        end
    end
end)


RegisterNetEvent('rs_police:StartSearch', function()
    local closestPlayer, closestDistance = GetClosestPlayer()

    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        local targetPed = GetPlayerPed(closestPlayer)

        if IsPedCuffed(targetPed) then
            local searchid = GetPlayerServerId(closestPlayer)
            TriggerServerEvent("rs_police:ReloadInventory", searchid)
            TriggerServerEvent('rs_police:OpenInventory', searchid)
        end
    end
end)


RegisterNetEvent("rs_police:PlayerJob")
AddEventHandler("rs_police:PlayerJob", function(Job)
    playerJob = Job
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)

        if LocalPlayer.state.IsInSession then
            TriggerServerEvent("rs_police:check_jail")
            TriggerServerEvent("rs_police:gooffdutyonstart")
            break
        end
    end
end)

Badge = nil
Badgex, Badgey, Badgez = 0.17, -0.19, -0.25
BadgeCoords = nil
MaleboneIndex = 458
FemaleboneIndex = 500
Rotationz = 30.0

local function GetBadgeModel(jobName, grade)
    for _, badgeData in pairs(ConfigMain.Badges) do
        if badgeData.jobName == jobName then
            for _, gradeData in pairs(badgeData.grades) do
                if grade >= gradeData.min and grade <= gradeData.max then
                    return gradeData.model
                end
            end
        end
    end
    return nil
end

RegisterNetEvent("rs_police:badgeon")
AddEventHandler("rs_police:badgeon", function(playerjob, jobgrade)
    Wait(60)
    local ped = PlayerPedId()

    if not badgeactive then
        badgeactive = true
        Wait(5)

        local badgeModel = GetBadgeModel(playerjob, jobgrade)

        if badgeModel then
            local hash = GetHashKey(badgeModel)
            RequestModel(hash)
            while not HasModelLoaded(hash) do
                Wait(5)
            end

            Badge = CreateObject(hash, Badgex, Badgey, Badgez + 0.2, true, true, false, false)

            if IsPedMale(ped) then
                AttachEntityToEntity(Badge, ped, MaleboneIndex, Badgex, Badgey, Badgez, -12.5, 0.0, Rotationz, false, true, false, true, 1, true)
            else
                AttachEntityToEntity(Badge, ped, FemaleboneIndex, Badgex, Badgey, Badgez, -12.5, 0.0, Rotationz, false, true, false, true, 1, true)
            end

            BadgeCoords = GetEntityCoords(Badge)
            TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.titlebadge, ConfigMain.Text.Notify.badgeon, "generic_textures", "tick", 2000, "COLOR_GREEN")
        end
    else
        DeleteObject(Badge)
        badgeactive = false
        TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.titlebadge, ConfigMain.Text.Notify.badgeoff, "generic_textures", "tick", 2000, "COLOR_GREEN")
    end
end)

RegisterNetEvent("rs_police:goonduty")
AddEventHandler("rs_police:goonduty", function()
    TriggerServerEvent('rs_police:goondutysv', GetPlayers())
end)

RegisterCommand(ConfigMain.ondutycommand, function()
    TriggerEvent('rs_police:goonduty')
end)

RegisterCommand(ConfigMain.adjustbadgecommand, function()
    local ped = PlayerPedId()

    if not badgeactive or not Badge then
        return
    end

    if display then
        display = false
        SendNUIMessage({ action = "hidepanel" })
        return
    end

    display = true

    SendNUIMessage({
        action = "showpanel",
        title = ConfigMain.ControlsPanel.title,
        controls = ConfigMain.ControlsPanel.controls
    })

    Citizen.CreateThread(function()
        local lastX, lastY, lastZ = nil, nil, nil
        local lastRotZ = nil

        while display and badgeactive do
            Wait(0)

            for _, keyCode in pairs(ConfigMain.Keys) do
                DisableControlAction(0, keyCode, true)
            end

            if IsDisabledControlJustPressed(0, ConfigMain.Keys.finistadjust) then
                display = false
                SendNUIMessage({ action = "hidepanel" })
                break
            end

            if IsDisabledControlJustPressed(0, ConfigMain.Keys.up) then Badgez = Badgez + 0.01 end
            if IsDisabledControlJustPressed(0, ConfigMain.Keys.down) then Badgez = Badgez - 0.01 end
            if IsDisabledControlJustPressed(0, ConfigMain.Keys.left) then Badgex = Badgex + 0.01 end
            if IsDisabledControlJustPressed(0, ConfigMain.Keys.right) then Badgex = Badgex - 0.01 end
            if IsDisabledControlJustPressed(0, ConfigMain.Keys.int) then Badgey = Badgey + 0.01 end
            if IsDisabledControlJustPressed(0, ConfigMain.Keys.out) then Badgey = Badgey - 0.01 end
            if IsDisabledControlJustPressed(0, ConfigMain.Keys.rotateleft) then Rotationz = Rotationz + 2.0 end
            if IsDisabledControlJustPressed(0, ConfigMain.Keys.rotateright) then Rotationz = Rotationz - 2.0 end

            if Badgex ~= lastX or Badgey ~= lastY or Badgez ~= lastZ or Rotationz ~= lastRotZ then
                local boneIndex = IsPedMale(ped) and MaleboneIndex or FemaleboneIndex
                AttachEntityToEntity(Badge, ped, boneIndex, Badgex, Badgey, Badgez, -15.0, 0.0, Rotationz, true, true, false, true, 1, true)
                lastX, lastY, lastZ = Badgex, Badgey, Badgez
                lastRotZ = Rotationz
            end
        end
    end)
end, false)

RegisterNetEvent("rs_police:gooffduty")
AddEventHandler("rs_police:gooffduty", function()
    TriggerServerEvent("rs_police:gooffdutysv")
end)

RegisterCommand(ConfigMain.offdutycommand, function()
    TriggerEvent('rs_police:gooffduty')
end)

RegisterCommand(ConfigMain.openpolicemenu, function()
    if not IsEntityDead(PlayerPedId()) then
        TriggerServerEvent("CheckPoliceMenuPermission")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if ConfigMain.EnableKeyPoliceMenu then
            if IsControlJustReleased(0, ConfigMain.PoliceMenuKey) then
                if not IsEntityDead(PlayerPedId()) then
                    TriggerServerEvent("CheckPoliceMenuPermission")
                end
            end
        end
    end
end)

RegisterNetEvent("OpenPoliceMenuClient")
AddEventHandler("OpenPoliceMenuClient", function()
    OpenPoliceMenu()
end)

CreateThread(function()
    while true do
        Citizen.Wait(5)
        if IsHandcuffed then
            DisableControlAction(0, 0xB2F377E8, true)
            DisableControlAction(0, 0xC1989F95, true)
            DisableControlAction(0, 0x07CE1E61, true)
            DisableControlAction(0, 0xF84FA74F, true)
            DisableControlAction(0, 0xCEE12B50, true)
            DisableControlAction(0, 0x8FFC75D6, true)
            DisableControlAction(0, 0xD9D0E1C0, true)
            DisableControlAction(0, 0xF3830D8E, true)
            DisableControlAction(0, 0x80F28E95, true)
            DisableControlAction(0, 0xDB096B85, true)
            DisableControlAction(0, 0xE30CD707, true)
        elseif IsHandcuffed and IsPedDeadOrDying(PlayerPedId()) then
            ClearPedSecondaryTask(PlayerPedId())
            SetEnableHandcuffs(PlayerPedId(), false)
            DisablePlayerFiring(PlayerPedId(), false)
            SetPedCanPlayGestureAnims(PlayerPedId(), true)
            Wait(500)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    local wasDragged
    while true do
        Citizen.Wait(5)
        local playerPed = PlayerPedId()
        if IsHandcuffed and dragStatus.isDragged then
            local targetPed = GetPlayerPed(GetPlayerFromServerId(dragStatus.CopId))
            if DoesEntityExist(targetPed) and IsPedOnFoot(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                if not wasDragged then
                    AttachEntityToEntity(playerPed, targetPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    wasDragged = true
                else
                    Citizen.Wait(1000)
                end
            else
                wasDragged = false
                dragStatus.isDragged = false
                DetachEntity(playerPed, true, false)
            end
        elseif wasDragged then
            wasDragged = false
            DetachEntity(playerPed, true, false)
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('rs_police:drag')
AddEventHandler('rs_police:drag', function(copId)
    if IsHandcuffed then
        dragStatus.isDragged = not dragStatus.isDragged
        dragStatus.CopId = copId
    end
end)

RegisterNetEvent("rs_police:JailPlayer")
AddEventHandler('rs_police:JailPlayer', function(time, Location)
    local ped = PlayerPedId()
    local time_minutes = math.floor(time / 60)

    local JailAlias = {
        sk = "sisika", bw = "blackwater", st = "strawberry", val = "valentine",
        ar = "armadillo", tu = "tumbleweed", rh = "rhodes", sd = "stdenis", an = "annesburg"
    }

    JailID = JailAlias[Location] or Location
    Serviced = false
    EscapeActive = false

    local jailData = ConfigJail.Jails[JailID]
    if jailData then
        JailEntranceCoords = vector3(jailData.entrance.x, jailData.entrance.y, jailData.entrance.z)
    end

    Jail_time = time
    Jailed = true

    if Autotele and JailEntranceCoords then
        DoScreenFadeOut(1000)
        Wait(4000)
        SetEntityCoords(ped, JailEntranceCoords.x, JailEntranceCoords.y, JailEntranceCoords.z)
        DoScreenFadeIn(1000)
        EscapeActive = true
    end
    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.prison, ConfigMain.Text.Notify.jailed .. time_minutes .. ConfigMain.Text.Notify.minutes, "generic_textures", "tick", 2000, "COLOR_GREEN")
    TriggerEvent("rs_police:wear_prison", ped)
end)

RegisterNetEvent("rs_police:wear_prison")
AddEventHandler("rs_police:wear_prison", function()
    local ped = PlayerPedId()
    local components = {
        0x9925C067, 0x485EE834, 0x18729F39, 0x3107499B, 0x3C1A74CD, 0x3F1F01E5,
        0x3F7F3587, 0x49C89D9B, 0x4A73515C, 0x514ADCEA, 0x5FC29285, 0x79D7DF96,
        0x7A96FACA, 0x877A2CF7, 0x9B2C8B89, 0xA6D134C6, 0xE06D30CE, 0x662AC34,
        0xAF14310B, 0x72E6EF74, 0xEABE0032, 0x2026C46D
    }

    for _, comp in ipairs(components) do
        Citizen.InvokeNative(0xDF631E4BCE1B1FC4, ped, comp, true, true, true)
    end

    if IsPedMale(ped) then
        Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, 0x5BA76CCF, true, true, true)
        Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, 0x216612F0, true, true, true)
        Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, 0x1CCEE58D, true, true, true)
    else
        Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, 0x6AB27695, true, true, true)
        Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, 0x75BC0CF5, true, true, true)
        Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, 0x14683CDF, true, true, true)
    end

end)

RegisterNetEvent("rs_police:UnjailPlayer")
AddEventHandler("rs_police:UnjailPlayer", function(jaillocation)
    local ped = PlayerPedId()
    local player = PlayerId()

    local JailAlias = {
        sk = "sisika", bw = "blackwater", st = "strawberry", val = "valentine",
        ar = "armadillo", tu = "tumbleweed", rh = "rhodes", sd = "stdenis", an = "annesburg"
    }

    JailID = JailAlias[jaillocation] or jaillocation

    ExecuteCommand('rc')
    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.prison, ConfigMain.Text.Notify.leave, "generic_textures", "tick", 2000, "COLOR_GREEN")
    Jailed = false
    Jail_time = 0

    if Autotele then
        local jailData = ConfigJail.Jails[JailID]
        if jailData and jailData.exit then
            SetEntityCoords(ped, jailData.exit.x, jailData.exit.y, jailData.exit.z)
        end
    end

    SetPlayerInvincible(player, false)
    SendNUIMessage({ type = "hideJailTime" })
end)

CreateThread(function()
    while true do
        Wait(1000)

        if Jailed then
            local ped = PlayerPedId()
            local player = PlayerId()

            if Jail_time > 0 then
                Jail_time = Jail_time - 1
                SendNUIMessage({
                    type = "updateJailTime",
                    time = Jail_time,
                    text = ConfigMain.Text.jailTimerLabel
                })
            else
                local server_id = GetPlayerServerId(player)
                TriggerServerEvent("rs_police:finishedjail", server_id)
                SendNUIMessage({ type = "hideJailTime" })
                Jailed = false
                JailEntranceCoords = nil
                EscapeActive = false
                SetPlayerInvincible(player, false)
            end

            if ConfigJail.EscapeConfig.EnableEscapePenalty and JailEntranceCoords and EscapeActive then
                local playerPos = GetEntityCoords(ped)
                local dist = #(playerPos - JailEntranceCoords)

                if dist > Jail_maxDistance then
                    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.prison, ConfigMain.Text.Notify.leaveprison, "generic_textures", "tick", 2000, "COLOR_GREEN")
                    SetEntityCoords(ped, JailEntranceCoords.x, JailEntranceCoords.y, JailEntranceCoords.z)
                    Jail_time = Jail_time + Jail_penalty
                    TriggerServerEvent("rs_police:updatejailtime", Jail_time)
                end
            end
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    local doingchore = false
    local currentChore = nil
    local choreBlip = nil
    local showingTask = false

    local function AssignRandomChore()
        local chores = ConfigJail.jailchores
        currentChore = chores[math.random(#chores)]

        if choreBlip then RemoveBlip(choreBlip) end
        choreBlip = N_0x554d9d53f696d002(1664425300, currentChore.x, currentChore.y, currentChore.z)
        SetBlipSprite(choreBlip, 28148096, 1)
        Citizen.InvokeNative(0x9CB1A1623062F402, choreBlip, ConfigMain.Text.jailchoreblip)
    end

    while true do
        Wait(5)
        if Jailed then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            if not currentChore then AssignRandomChore() end

            local dist = #(coords - vector3(currentChore.x, currentChore.y, currentChore.z))
            if dist < 5 then
                if not showingTask then
                    SendNUIMessage({
                        type = 'showTask',
                        text = ConfigMain.Text.taskMessage
                    })
                    showingTask = true
                end

                if IsControlJustReleased(0, 0x760A9C6F) and not doingchore then
                    doingchore = true
                    SendNUIMessage({ type = 'hideTask' })
                    showingTask = false

                    TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_BROOM_WORKING'), 20000, true, false, false, false)
                    Wait(20000)

                    ClearPedTasksImmediately(ped)
                    ClearPedSecondaryTask(ped)
                    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)

                    local broom = GetClosestObjectOfType(GetEntityCoords(ped), 2.0, GetHashKey("prop_broom"), false, false, false)
                    if broom ~= 0 then
                        local netId = NetworkGetNetworkIdFromEntity(broom)
                        TriggerServerEvent("rs_police:deleteBroom", netId)
                    end

                    TriggerServerEvent("rs_police:clearChoreProp", GetPlayerServerId(PlayerId()))

                    Jail_time = Jail_time - (currentChore.timeReduction or 10)
                    if Jail_time < 0 then Jail_time = 0 end

                    TriggerServerEvent("rs_police:updatejailtime", Jail_time)

                    AssignRandomChore()
                    Wait(1000)
                    doingchore = false
                end
            else
                if showingTask then
                    SendNUIMessage({ type = 'hideTask' })
                    showingTask = false
                end
            end
        else
            if choreBlip then
                RemoveBlip(choreBlip)
                choreBlip = nil
                currentChore = nil
            end

            if showingTask then
                SendNUIMessage({ type = 'hideTask' })
                showingTask = false
            end

            Wait(500)
        end
    end
end)

RegisterNetEvent("rs_police:tryHandcuff")
AddEventHandler("rs_police:tryHandcuff", function()
    local closestPlayer, closestDistance = GetClosestPlayer()
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        HandcuffPlayer(closestPlayer)
    else
        TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.handcuff, ConfigMain.Text.Notify.notcloseenough, "menu_textures", "cross", 2000, "COLOR_RED")
    end
end)

RegisterNetEvent('rs_police:handcuffed', function()
    local playerPed = PlayerPedId()
    if not IsHandcuffed then
        IsHandcuffed = true
        SetEnableHandcuffs(playerPed, true)
        Citizen.InvokeNative(0x7981037A96E7D174, playerPed)
        DisablePlayerFiring(playerPed, true)
        SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
        SetPedCanPlayGestureAnims(playerPed, false)
    else
        IsHandcuffed = false
        ClearPedSecondaryTask(playerPed)
        SetEnableHandcuffs(playerPed, false)
        Citizen.InvokeNative(0x67406F2C8F87FC4F, playerPed)
        DisablePlayerFiring(playerPed, false)
        SetPedCanPlayGestureAnims(playerPed, true)
    end
end)

local commisaryBlip = nil
local blipCoords = ConfigJail.Jails.sisika.Commisary.coords

local function CreateCommisaryBlip()
    if commisaryBlip == nil then
        commisaryBlip = N_0x554d9d53f696d002(1664425300, blipCoords.x, blipCoords.y, blipCoords.z)
        SetBlipSprite(commisaryBlip, 28148096, 1)
        SetBlipScale(commisaryBlip, 0.5)
        Citizen.InvokeNative(0x9CB1A1623062F402, commisaryBlip, "Comisary")
    end
end

local function RemoveCommisaryBlip()
    if commisaryBlip ~= nil then
        RemoveBlip(commisaryBlip)
        commisaryBlip = nil
    end
end

CreateThread(function()
    if ConfigJail.Jails.sisika.Commisary.enable then
        local showingComisary = false

        while true do
            Wait(5)
            local pl = GetEntityCoords(PlayerPedId())
            local dist = GetDistanceBetweenCoords(pl.x, pl.y, pl.z, blipCoords.x, blipCoords.y, blipCoords.z, true)

            if Jailed then
                CreateCommisaryBlip()

                if dist < 5 then
                    if not showingComisary then
                        SendNUIMessage({
                            type = 'showComisary',
                            text = ConfigMain.Text.comisaryMessage
                        })
                        showingComisary = true
                    end

                    if IsControlJustReleased(0, 0x760A9C6F) then
                        TriggerServerEvent('rs_police:CommisaryAddItem')
                    end
                else
                    if showingComisary then
                        SendNUIMessage({ type = 'hideComisary' })
                        showingComisary = false
                    end

                    if dist > 200 then
                        Wait(2000)
                    end
                end
            else
                if showingComisary then
                    SendNUIMessage({ type = 'hideComisary' })
                    showingComisary = false
                end

                RemoveCommisaryBlip()
                Wait(1000)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)
        if Jailed then
            TriggerServerEvent("rs_police:updatejailtime", Jail_time)
        end
    end
end)

local spawn_wagon = nil

function GetCurentTownName()
    local pedCoords = GetEntityCoords(PlayerPedId())
    local town_hash = Citizen.InvokeNative(0x43AD8FC02B429D33, pedCoords, 1)

    local townNames = {
        [GetHashKey("Annesburg")] = "Annesburg",
        [GetHashKey("Armadillo")] = "Armadillo",
        [GetHashKey("Blackwater")] = "Blackwater",
        [GetHashKey("Rhodes")] = "Rhodes",
        [GetHashKey("StDenis")] = "Saint Denis",
        [GetHashKey("Strawberry")] = "Strawberry",
        [GetHashKey("Tumbleweed")] = "Tumbleweed",
        [GetHashKey("valentine")] = "Valentine"
    }

    return townNames[town_hash]
end

RegisterNetEvent('rs_police:spawnWagon')
AddEventHandler('rs_police:spawnWagon', function(wagonModel, coords)
    if DoesEntityExist(spawn_wagon) then
        DeleteVehicle(spawn_wagon)
        spawn_wagon = nil
    end

    RequestModel(GetHashKey(wagonModel))
    while not HasModelLoaded(GetHashKey(wagonModel)) do
        Citizen.Wait(10)
    end

    local wagon = CreateVehicle(GetHashKey(wagonModel), coords.x, coords.y, coords.z, coords.h, true, false)
    SetEntityAsMissionEntity(wagon, true, true)

    local netId = NetworkGetNetworkIdFromEntity(wagon)
    SetNetworkIdExistsOnAllMachines(netId, true)

    SetModelAsNoLongerNeeded(GetHashKey(wagonModel))
    spawn_wagon = wagon
end)

function GetClosestWagon(radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestWagon = nil
    local closestDist = radius

    local vehicles = GetGamePool("CVehicle")
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local model = GetEntityModel(veh)
            for _, wagon in ipairs(ConfigMain.Wagons) do
                if model == GetHashKey(wagon.wagon) then
                    local dist = #(playerCoords - GetEntityCoords(veh))
                    if dist < closestDist then
                        closestDist = dist
                        closestWagon = veh
                    end
                end
            end
        end
    end

    if closestWagon then
        return NetworkGetNetworkIdFromEntity(closestWagon)
    end
    return nil
end

RegisterNetEvent("rs_police:deleteWagon")
AddEventHandler("rs_police:deleteWagon", function()
    local wagonNetId = GetClosestWagon(5.0)
    if wagonNetId then
        TriggerServerEvent("rs_police:DeleteWagonServer", wagonNetId)
    else
        TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.wagon, ConfigMain.Text.Notify.notwagon, "menu_textures", "cross", 2000, "COLOR_RED")
    end
end)

RegisterNetEvent("rs_police:DeleteWagonGlobal")
AddEventHandler("rs_police:DeleteWagonGlobal", function(wagonNetId)
    if NetworkDoesNetworkIdExist(wagonNetId) then
        local wagon = NetToVeh(wagonNetId)
        if DoesEntityExist(wagon) then
            DeleteVehicle(wagon)
        end
    end
end)

Citizen.CreateThread(function()
    local showingWagon = false

    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearStation = false

        for _, stationCoords in ipairs(ConfigMain.Stations) do
            if #(playerCoords - stationCoords) < 1.5 then
                nearStation = true

                if not showingWagon then
                    SendNUIMessage({
                        type = "showWagon",
                        text = ConfigMain.Text.wagonMessage
                    })
                    showingWagon = true
                end

                if IsControlJustReleased(0, 0x760A9C6F) then
                    TriggerServerEvent("rs_police:CheckJob")
                end
                break
            end
        end

        if not nearStation and showingWagon then
            SendNUIMessage({ type = "hideWagon" })
            showingWagon = false
        end

        Citizen.Wait(nearStation and 0 or 500)
    end
end)

RegisterNetEvent("rs_police:JobAccepted")
AddEventHandler("rs_police:JobAccepted", function()
    TriggerEvent("rs_police:OpenWagonMenu")
end)

RegisterNetEvent("rs_police:JobDenied")
AddEventHandler("rs_police:JobDenied", function()
    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.job, ConfigMain.Text.Notify.notjob, "menu_textures", "cross", 2000, "COLOR_RED")
end)

RegisterNetEvent("rs_police:JobCabinetAccepted")
AddEventHandler("rs_police:JobCabinetAccepted", function()
    CabinetMenu()
end)

RegisterNetEvent("rs_police:JobCabinetDenied")
AddEventHandler("rs_police:JobCabinetDenied", function()
    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.job, ConfigMain.Text.Notify.notjob, "menu_textures", "cross", 2000, "COLOR_RED")
end)

RegisterNetEvent("rs_police:JobHireAccepted")
AddEventHandler("rs_police:JobHireAccepted", function()
    TriggerServerEvent("rs_police:openMainMenu")
end)

RegisterNetEvent("rs_police:JobHireDenied")
AddEventHandler("rs_police:JobHireDenied", function()
    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.job, ConfigMain.Text.Notify.notjob, "menu_textures", "cross", 2000, "COLOR_RED")
end)

local showingStorage = false
local currentStorageKey = nil

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearStorage = false

        for key, data in pairs(ConfigMain.Storage) do
            local distance = #(playerCoords - data.Coords)
            if distance < 1.5 then
                nearStorage = true

                if not showingStorage then
                    SendNUIMessage({
                        type = "showStorage",
                        text = ConfigMain.Text.storage
                    })
                    showingStorage = true
                end

                currentStorageKey = key

                if IsControlJustReleased(0, 0x760A9C6F) then
                    if not isPlayerNearby() then
                        TriggerServerEvent("rs_police:checkstoragejob", currentStorageKey)
                    else
                        TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.storage, ConfigMain.Text.Notify.playernearby, "menu_textures", "cross", 2000, "COLOR_RED")
                    end
                end
                break
            end
        end

        if not nearStorage and showingStorage then
            SendNUIMessage({ type = "hideStorage" })
            showingStorage = false
        end

        Citizen.Wait(nearStorage and 0 or 500)
    end
end)

RegisterNetEvent("rs_police:JobStorageAccepted")
AddEventHandler("rs_police:JobStorageAccepted", function(key)
    TriggerServerEvent("rs_police:Server:OpenStorage", key)
end)

RegisterNetEvent("rs_police:JobStorageDenied")
AddEventHandler("rs_police:JobStorageDenied", function(key)
    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.storage, ConfigMain.Text.Notify.notaccess, "menu_textures", "cross", 3000, "COLOR_RED")
end)

function isPlayerNearby()
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            if #(coords - targetCoords) < 2.0 then
                return true
            end
        end
    end
    return false
end

CreateThread(function()
    if ConfigMain.ShowBlip then 
        for i = 1, #ConfigMain.PoliceStationblip do 
            local zone = ConfigMain.PoliceStationblip[i]
            if zone.blips and type(zone.blips) == "number" then
                local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, zone.coords.x, zone.coords.y, zone.coords.z) 
                SetBlipSprite(blip, zone.blips, 1)
                SetBlipScale(blip, 0.8)
                Citizen.InvokeNative(0x9CB1A1623062F402, blip, zone.blipsName)
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveBlip(blip)
        RemoveBlip(choreBlip)
        RemoveCommisaryBlip()
    end
end)
