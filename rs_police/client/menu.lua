local Menu = exports.vorp_menu:GetMenuData()
local Tele = ConfigMain.Text.Menu.vartrue
local timeinjail = 0
local Playerid = 0
local jailname = ConfigMain.Text.Menu.none

PlayerIDInput = {
    type = "enableinput",
    inputType = "input",
    button = ConfigMain.Text.Input.inputconfirm,
    placeholder = ConfigMain.Text.Input.playerid,
    style = "block",
    attributes = {
        inputHeader = ConfigMain.Text.Input.playerid,
        type = "number",
        pattern = "[0-9]",
        title = ConfigMain.Text.Input.numberonly,
        style = "border-radius: 10px; background-color: ; border:none;"
    }
}

JailTime = {
    type = "enableinput",
    inputType = "input",
    button = ConfigMain.Text.Input.inputconfirm,
    placeholder = ConfigMain.Text.Input.jailamount,
    style = "block",
    attributes = {
        inputHeader = ConfigMain.Text.Input.jailamount,
        type = "number",
        pattern = "[0-9]",
        title = ConfigMain.Text.Input.numberonly,
        style = "border-radius: 10px; background-color: ; border:none;"
    }
}

function OpenPoliceMenu()
    Inmenu = true
    Menu.CloseAll()
    local elements = {
        { label = ConfigMain.Text.Menu.togglebadge,     value = 'star' },
        { label = ConfigMain.Text.Menu.idmenu,          value = 'idmenu' },
        { label = ConfigMain.Text.Menu.cufftoggle,      value = 'cuff' },
        { label = ConfigMain.Text.Menu.escort,          value = 'escort' },
        { label = ConfigMain.Text.Menu.putinoutvehicle, value = 'vehicle' },
        { label = ConfigMain.Text.Menu.jailplayer,      value = 'jail' },
        { label = ConfigMain.Text.Menu.unjailplayer,    value = 'unjail' },
    }
    Menu.Open('default', GetCurrentResourceName(), 'menuapi',
        {
            title    = ConfigMain.Text.Menu.lawmenu,
            align    = 'top-right',
            elements = elements,
        },
        function(data, menu)
            if (data.current.value == 'star') then
                menu.close()
                TriggerServerEvent('rs_police:checkjob')
            elseif (data.current.value == 'cuff') then
                local closestPlayer, closestDistance = GetClosestPlayer()
                if closestPlayer ~= -1 and closestDistance <= 3.0 then
                    HandcuffPlayer()
                else
                    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.handcuff, ConfigMain.Text.Notify.notcloseenough, "menu_textures", "cross", 2000, "COLOR_RED")
                end
            elseif (data.current.value == 'escort') then
                local closestPlayer, closestDistance = GetClosestPlayer()
                if closestPlayer ~= -1 and closestDistance <= 3.0 then
                    TriggerServerEvent('rs_police:drag', GetPlayerServerId(closestPlayer))
                else
                    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.escort, ConfigMain.Text.Notify.notcloseenough, "menu_textures", "cross", 2000, "COLOR_RED")
                end
            elseif (data.current.value == 'vehicle') then
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local closestWagon, distance = GetClosestVehicle(coords)
                if closestWagon ~= -1 and distance <= 5.0 then
                    PutInOutVehicle()
                else
                    TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.wagon, ConfigMain.Text.Notify.notcloseenoughtowagon, "menu_textures", "cross", 2000, "COLOR_RED")
                end
            elseif (data.current.value == 'jail') then
                OpenJailMenu()
            elseif (data.current.value == 'unjail') then
                OpenUnjailMenu()    
            elseif (data.current.value == 'idmenu') then
                OpenIDMenu()
            end
        end,
        function(data, menu)
            Inmenu = false
            menu.close()
        end)
end

function OpenJailMenu()
    Menu.CloseAll()
    local elements = {
        { label = ConfigMain.Text.Menu.playerid .. "<span style='margin-left:10px; color: Red;'>" .. (Playerid) .. '</span>', value = 'id' },
        { label = ConfigMain.Text.Menu.jailamount .. "<span style='margin-left:10px; color: Red;'>" .. (timeinjail) .. '</span>', value = 'time' },
        { label = ConfigMain.Text.Menu.autotele .. (Tele or ""), value = 'auto', desc = ConfigMain.Text.Menu.autoteledesc },
        { label = ConfigMain.Text.Menu.jaillocaiton .. (jailname or ""), value = 'loc' },
        { label = ConfigMain.Text.Menu.jail, value = 'jail', desc = ConfigMain.Text.Menu.jaildesc }
    }

    Menu.Open('default', GetCurrentResourceName(), 'menuapi',
    {
        title    = ConfigMain.Text.Menu.jailmenu,
        align    = 'top-right',
        elements = elements,
        lastmenu = nil
    },
    function(data, menu)
        if data.current.value == 'id' then
            TriggerEvent("vorpinputs:advancedInput", json.encode(PlayerIDInput), function(result)
                local amount = tonumber(result)
                if amount and amount > 0 then
                    Playerid = amount
                    menu.close()
                    OpenJailMenu()
                end
            end)

        elseif data.current.value == 'time' then
            TriggerEvent("vorpinputs:advancedInput", json.encode(JailTime), function(result)
                local amount = tonumber(result)
                if amount and amount > 0 then
                    timeinjail = amount
                    menu.close()
                    OpenJailMenu()
                end
            end)

        elseif data.current.value == 'jail' then
            Wait(500)
            if JailID == nil then JailID = 'sk' end
            TriggerServerEvent('rs_police:JailPlayerServer', tonumber(Playerid), tonumber(timeinjail), JailID)
            menu.close()

        elseif data.current.value == 'auto' then
            Autotele = not Autotele
            Tele = Autotele and ConfigMain.Text.Menu.vartrue or ConfigMain.Text.Menu.varfalse
            menu.close()
            OpenJailMenu()

        elseif data.current.value == 'loc' then
            OpenSubJailMenu()
        end
    end,
    function(data, menu)
        menu.close()
    end)
end

function OpenUnjailMenu()
    Menu.CloseAll()
    local elements = {
        { label = ConfigMain.Text.Menu.playerid .. "<span style='margin-left:10px; color: Red;'>" .. (Playerid) .. '</span>', value = 'id' },
        { label = ConfigMain.Text.Menu.unjail, value = 'unjail', desc = ConfigMain.Text.Menu.unjaildesc }
    }

    Menu.Open('default', GetCurrentResourceName(), 'menuapi',
    {
        title    = ConfigMain.Text.Menu.jailmenu,
        align    = 'top-right',
        elements = elements,
        lastmenu = nil
    },
    function(data, menu)
        if data.current.value == 'id' then
            TriggerEvent("vorpinputs:advancedInput", json.encode(PlayerIDInput), function(result)
                local amount = tonumber(result)
                if amount and amount > 0 then
                    Playerid = amount
                    menu.close()
                    OpenUnjailMenu()
                end
            end)

        elseif data.current.value == 'unjail' then
            if Playerid ~= nil then
                TriggerServerEvent('rs_police:unjailed', Playerid, JailID)
                menu.close()
            else
                TriggerEvent("vorp:TipRight", "Debes ingresar un ID válido", 3000)
            end
        end
    end,
    function(data, menu)
        menu.close()
    end)
end


function OpenSubJailMenu()
    Menu.CloseAll()
    local elements = {
        { label = ConfigMain.Text.Menu.valjail, value = "val" },
        { label = ConfigMain.Text.Menu.bwjail,  value = 'bw' },
        { label = ConfigMain.Text.Menu.sdjail,  value = "sd" },
        { label = ConfigMain.Text.Menu.rhjail,  value = "rh" },
        { label = ConfigMain.Text.Menu.stjail,  value = "st" },
        { label = ConfigMain.Text.Menu.arjail,  value = "ar" },
        { label = ConfigMain.Text.Menu.tujail,  value = "tu" },
        { label = ConfigMain.Text.Menu.anjail,  value = "an" },
        { label = ConfigMain.Text.Menu.sisika,  value = "sk" },
    }
    Menu.Open('default', GetCurrentResourceName(), 'menuapi',
        {
            title    = ConfigMain.Text.Menu.jailmenu,
            align    = 'top-right',
            elements = elements,
            lastmenu = "OpenJailMenu"
        },
        function(data, menu)
            if data.current == "backup" then
                _G[data.trigger]()
            elseif data.current.value then
                jailname = data.current.label
                JailID = data.current.value
                menu.close()
                OpenJailMenu()
            end
        end,
        function(data, menu)
            menu.close()
        end)
end

function CloseMenu()
    Inmenu = false
    Menu.CloseAll()
end

function WeaponMenu()
    Menu.CloseAll()
    local elements = {}

    for i, item in ipairs(ConfigCabinets.WeaponsandAmmo.Weapons) do
        local imgPath = "nui://vorp_inventory/html/img/items/" .. item.weapon .. ".png"
        local labelHTML = "<div style='display:flex;align-items:center;gap:10px;'>"
                        .. "<img src='" .. imgPath .. "' style='width:32px;height:32px;'>"
                        .. "<span>" .. item.label .. "</span></div>"

        table.insert(elements, {
            label = labelHTML,
            value = i,
            desc  = ConfigMain.Text.Menu.gradeRequired .. item.allowedGrade
        })
    end

    Menu.Open('default', GetCurrentResourceName(), 'weapon_menu', {
        title    = ConfigMain.Text.Menu.grabweapons,
        align    = 'top-right',
        elements = elements,
        lastmenu = "CabinetMenu"
    },
    function(data, menu)
        local index = data.current.value
        TriggerServerEvent("rs_police:guncabinet", index)
        CloseMenu()
    end,
    function(data, menu)
        CloseMenu()
    end)
end

function AmmoMenu()
    Menu.CloseAll()
    local elements = {}

    for i, item in ipairs(ConfigCabinets.WeaponsandAmmo.Ammo) do
        local imgPath = "nui://vorp_inventory/html/img/items/" .. item.ammo .. ".png"
        local labelHTML = "<div style='display:flex;align-items:center;gap:10px;'>"
                        .. "<img src='" .. imgPath .. "' style='width:32px;height:32px;'>"
                        .. "<span>" .. item.label .. "</span></div>"

        table.insert(elements, {
            label = labelHTML,
            value = i,
            desc  = ConfigMain.Text.Menu.gradeRequired .. item.allowedGrade
        })
    end

    Menu.Open('default', GetCurrentResourceName(), 'ammo_menu', {
        title    = ConfigMain.Text.Menu.grabammo,
        align    = 'top-right',
        elements = elements,
        lastmenu = "CabinetMenu"
    },
    function(data, menu)
        local index = data.current.value
        TriggerServerEvent("rs_police:addammo", index)
        Inmenu = false
        menu.close()
    end,
    function(data, menu)
        Inmenu = false
        menu.close()
    end)
end

function CabinetMenu()
    Menu.CloseAll()
    local elements = {
        { label = ConfigMain.Text.Menu.grabammo,    value = 'ammo' },
        { label = ConfigMain.Text.Menu.grabweapons, value = 'wep' },
    }

    Menu.Open('default', GetCurrentResourceName(), 'cabinet_menu', {
        title    = ConfigMain.Text.Menu.cabinet,
        align    = 'top-right',
        elements = elements
    },
    function(data, menu)
        if data.current.value == "ammo" then
            AmmoMenu()
        elseif data.current.value == "wep" then
            WeaponMenu()
        end
    end,
    function(data, menu)
        menu.close()
        Inmenu = false
    end)
end

function OpenIDMenu()
    Menu.CloseAll()

    local elements = {
        { label = ConfigMain.Text.Menu.citizenid, value = 'getid' },
    }

    if ConfigMain.CheckHorse then
        table.insert(elements, { label = ConfigMain.Text.Menu.horseowner, value = 'getowner', desc = ConfigMain.Text.Menu.horseownerdesc })
    end

    Menu.Open('default', GetCurrentResourceName(), 'menuapi', {
        title    = ConfigMain.Text.Menu.idmenu,
        align    = 'top-right',
        elements = elements,
        lastmenu = "OpenPoliceMenu"
    },
    function(data, menu)
        if data.current == "backup" then
            _G[data.trigger]()
            
        elseif data.current.value == "getid" then
            local closestPlayer, closestDistance = GetClosestPlayer()
            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('rs_police:GetID', GetPlayerServerId(closestPlayer))
            end
            
        elseif data.current.value == "getowner" then
            local closestPlayer, closestDistance = GetClosestPlayer()
            if closestPlayer ~= -1 and closestDistance <= 5.0 then
                local closestPed = GetPlayerPed(closestPlayer)
                local mount = GetMount(closestPed)
                if mount and mount ~= 0 then
                    TriggerServerEvent('rs_police:getVehicleInfo', GetPlayerServerId(closestPlayer), GetEntityModel(mount))
                end
            else
                local mount = GetMount(PlayerPedId())
                local id = GetPlayerServerId(PlayerId())
                if mount and mount ~= 0 then
                    TriggerServerEvent('rs_police:getVehicleInfo', id, GetEntityModel(mount))
                end
            end
        end
    end, 
    function(data, menu)
        CloseMenu()
    end)
end

RegisterNetEvent("rs_police:OpenWagonMenu")
AddEventHandler("rs_police:OpenWagonMenu", function()
    local town = GetCurentTownName()
    if not town or not ConfigMain.SpawnCoords[town] then
        TriggerEvent("vorp:NotifyLeft", ConfigMain.Text.Notify.wagon, ConfigMain.Text.Notify.nocoords, "menu_textures", "cross", 2000, "COLOR_RED")
        return
    end

    local elements = {}
    for _, data in ipairs(ConfigMain.Wagons) do
        table.insert(elements, {
            label = data.label,
            value = data.wagon,
            desc = string.format("%s%d", ConfigMain.Text.Menu.gradeRequired, data.allowedGrade)
        })
    end

    Menu.Open('default', GetCurrentResourceName(), 'wagon_menu', {
        title   = ConfigMain.Text.Menu.wagonmenutitle,
        subtext = ConfigMain.Text.Menu.wagonmenusub .. town,
        align   = 'top-right',
        elements = elements,
    }, function(data, menu)
        local coords = ConfigMain.SpawnCoords[town]
        TriggerServerEvent('rs_police:RequestSpawnWagon', data.current.value, coords)

        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end)

Citizen.CreateThread(function()
    local showingHireMenu = false

    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearHirePoint = false

        for _, hireCoords in ipairs(ConfigMain.Hire) do
            if #(playerCoords - hireCoords) < 1.5 then
                nearHirePoint = true

                if not showingHireMenu then
                    SendNUIMessage({
                        type = "showHire",
                        text = ConfigMain.Text.hireplayer
                    })
                    showingHireMenu = true
                end

                if IsControlJustReleased(0, 0x760A9C6F) then
                    TriggerServerEvent("rs_police:checkhirejob")
                end
                break
            end
        end

        if not nearHirePoint and showingHireMenu then
            SendNUIMessage({ type = "hideHire" })
            showingHireMenu = false
        end

        Citizen.Wait(nearHirePoint and 0 or 500)
    end
end)

RegisterNetEvent("rs_police:client:openMainMenu")
AddEventHandler("rs_police:client:openMainMenu", function()
    Menu.CloseAll()

    local elements = {
        { label = ConfigMain.Text.Menu.hire, value = "hire" },
        { label = ConfigMain.Text.Menu.fire, value = "fire" }
    }

    Menu.Open("default", GetCurrentResourceName(), "MainMenu", {
        title = ConfigMain.Text.Menu.management,
        subtext = ConfigMain.Text.Menu.sellec,
        align = "top-right",
        elements = elements
    },
    function(data, menu)
        menu.close()
        if data.current.value == "hire" then
            TriggerServerEvent("rs_police:requestJobList")
        elseif data.current.value == "fire" then
            TriggerServerEvent("rs_police:requestFireList")
        end
    end,
    function(data, menu)
        menu.close()
    end)
end)

RegisterNetEvent("rs_police:client:openJobList")
AddEventHandler("rs_police:client:openJobList", function(jobList)
    Menu.CloseAll()

    local menuElements = {}

    for jobName, _ in pairs(ConfigMain.Hirenames) do
        if jobList[jobName] then
            table.insert(menuElements, {
                label = jobName,
                value = jobName,
                desc = ConfigMain.Text.Menu.sellechire,
            })
        end
    end

    Menu.Open("default", GetCurrentResourceName(), "JobList", {
        title = ConfigMain.Text.Menu.sellectohire,
        subtext = ConfigMain.Text.Menu.tohire,
        align = "top-right",
        elements = menuElements
    },
    function(data, menu)
        menu.close()
        TriggerServerEvent("rs_police:requestRankList", data.current.value)
    end,
    function(data, menu)
        menu.close()
        TriggerEvent("rs_police:client:openMainMenu")
    end)
end)

RegisterNetEvent("rs_police:client:openRankList")
AddEventHandler("rs_police:client:openRankList", function(jobName, ranks)
    Menu.CloseAll()

    local elements = {}
    for _, rank in ipairs(ranks) do
        table.insert(elements, {
            label = rank.label,
            value = rank.Grade,
            desc = "Grado: " .. rank.Grade
        })
    end

    Menu.Open("default", GetCurrentResourceName(), "RankList", {
        title = ConfigMain.Text.Menu.rank .. " " .. jobName,
        subtext = ConfigMain.Text.Menu.ranktohire,
        align = "top-right",
        elements = elements
    },
    function(data, menu)
        menu.close()
        local myInput = {
            type = "enableinput",
            inputType = "input",
            button = ConfigMain.Text.Input.inputconfirm,
            placeholder = ConfigMain.Text.Input.playerhireid,
            style = "block",
            attributes = {
                inputHeader = ConfigMain.Text.Input.hireplayer,
                type = "text",
                pattern = "[0-9]+",
                title = ConfigMain.Text.Input.onlynumbers,
                style = "border-radius: 10px; border:none;"
            }
        }

        local result = exports.vorp_inputs:advancedInput(myInput)
        local targetId = tonumber(result)
        if targetId then
            TriggerServerEvent("rs_police:hirePlayer", targetId, jobName, data.current.value)
        end
    end,
    function(data, menu)
        menu.close()
        TriggerEvent("rs_police:client:openJobList", ConfigMain.Hirenames)
    end)
end)

RegisterNetEvent("rs_police:client:openFireList")
AddEventHandler("rs_police:client:openFireList", function(players)
    Menu.CloseAll()

    local elements = {}
    for _, p in ipairs(players) do
        table.insert(elements, {
            label = p.name,
            value = p.id,
            desc = ConfigMain.Text.Menu.job .. " " .. p.job
        })
    end

    Menu.Open("default", GetCurrentResourceName(), "FireList", {
        title = ConfigMain.Text.Menu.firetitle,
        subtext = ConfigMain.Text.Menu.sellectfire,
        align = "top-right",
        elements = elements
    },
    function(data, menu)
        menu.close()
        local myInput = {
            type = "enableinput",
            inputType = "input",
            button = ConfigMain.Text.Input.inputconfirm,
            placeholder = ConfigMain.Text.Input.yesno,
            style = "block",
            attributes = {
                inputHeader = ConfigMain.Text.Input.confirmfire,
                type = "text",
                pattern = "[A-Za-z]+",
                title = ConfigMain.Text.Input.only,
                style = "border-radius: 10px; border:none;"
            }
        }

        local result = exports.vorp_inputs:advancedInput(myInput)
        if result and string.lower(result) == ConfigMain.Text.Input.result then
            TriggerServerEvent("rs_police:firePlayer", data.current.value)
        end
    end,
    function(data, menu)
        menu.close()
        TriggerEvent("rs_police:client:openMainMenu")
    end)
end)

local active_menu = false

CreateThread(function()
    local showingSearch = false

    while true do
        local playerPed = PlayerPedId()
        local closestPlayer, closestDistance = GetClosestPlayer()
        local shouldShow = false
        local targetPed, targetServerId = nil, nil

        if closestPlayer ~= -1 and closestDistance <= 3.0 then
            targetPed = GetPlayerPed(closestPlayer)

            if IsPedCuffed(targetPed) then
                shouldShow = true
                targetServerId = GetPlayerServerId(closestPlayer)
            end
        end

        if shouldShow and not showingSearch then
            SendNUIMessage({
                type = "showSearch",
                text = ConfigMain.Text.searchplayercuff
            })
            showingSearch = true

        elseif (not shouldShow) and showingSearch then
            SendNUIMessage({ type = "hideSearch" })
            showingSearch = false
        end

        if shouldShow and IsControlJustReleased(0, 0x760A9C6F) then
            TriggerServerEvent('rs_police:OpenMenu', {
                enable = true,
                source = targetServerId,
                ped = targetPed
            })
        end

        Citizen.Wait(shouldShow and 0 or 500)
    end
end)

RegisterNetEvent('rs_police:OpenMenu')
AddEventHandler('rs_police:OpenMenu', function(CharacterMoney)
    Menu.CloseAll()

    ClearPedTasksImmediately(PlayerPedId())
    SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true, 0, false, false)
    TaskStartScenarioInPlace(PlayerPedId(), joaat("WORLD_HUMAN_CROUCH_INSPECT"), 0, true, false, false, false)

    active_menu = true

    local elements = {
        {
            label = ConfigMain.Text.Menu.playermoney .. ': ' .. CharacterMoney .. '$',
            value = 'money',
            desc = ConfigMain.Text.Menu.descmoney
        },
        {
            label = ConfigMain.Text.Menu.inventory,
            value = 'inventory',
            desc = ConfigMain.Text.Menu.descinventory
        },
    }

    Menu.Open('default', GetCurrentResourceName(), 'SearchMenu', {
        title = ConfigMain.Text.Menu.menutitle,
        subtext = ConfigMain.Text.Menu.menusubtext,
        align = 'top-right',
        elements = elements,

    }, function(data, menu)
        if not LocalPlayer.state.DataSteal then
            return
        end

        if data.current.value == 'money' then
            local myInput = {
                type = 'enableinput',
                inputType = 'input',
                button = ConfigMain.Text.Input.inputconfirm,
                placeholder = ConfigMain.Text.Input.amountmoney,
                style = 'block',
                attributes = {
                    inputHeader = ConfigMain.Text.Input.money,
                    type = 'text',
                    pattern = '[0-9.]{1,10}',
                    title = 'Wrong value',
                    style = 'border-radius: 10px; background-color: ; border:none;',
                }
            }

            TriggerEvent('vorpinputs:advancedInput', json.encode(myInput), function(result)
                local number = tonumber(result)

                if number and number <= CharacterMoney then
                    TriggerServerEvent('rs_police:StealMoney', LocalPlayer.state.DataSteal.source, number)

                    CharacterMoney = CharacterMoney - number
                    menu.setElement(1, 'label', ConfigMain.Text.Menu.playermoney .. ': ' .. CharacterMoney .. '$')
                    menu.refresh()
                end
            end)
        end

        if data.current.value == 'inventory' then
            TriggerServerEvent('rs_police:ReloadInventory', LocalPlayer.state.DataSteal.source)
            TriggerServerEvent('rs_police:OpenInventory', LocalPlayer.state.DataSteal.source)
        end

    end, function(data, menu)
        TriggerServerEvent('rs_police:Stealing', LocalPlayer.state.DataSteal.source, false)
        LocalPlayer.state:set('DataSteal', nil, true)
        ClearPedTasks(PlayerPedId())
        active_menu = false
        menu.close()
    end)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if LocalPlayer.state.DataSteal then
            LocalPlayer.state:set('DataSteal', nil, true)
        end

        if LocalPlayer.state.Stealing then
            LocalPlayer.state:set('Stealing', nil, true)
        end

        if active_menu then
            Menu.CloseAll()

            if IsPedActiveInScenario(PlayerPedId()) then
                ClearPedTasksImmediately(PlayerPedId())
            end

            TriggerServerEvent('rs_police:CloseInventory')
        end
    end
end)