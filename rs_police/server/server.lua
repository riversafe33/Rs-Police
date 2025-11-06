local VorpInv = {}
VorpInv = exports.vorp_inventory:vorp_inventoryApi()
local VORPcore = exports.vorp_core:GetCore()

RegisterNetEvent("rs_police:deleteBroom")
AddEventHandler("rs_police:deleteBroom", function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

RegisterServerEvent("rs_police:goondutysv")
AddEventHandler("rs_police:goondutysv", function(ptable)
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local job = player.job
    local grade = player.jobGrade

    local jobIndex = nil
    for i, v in ipairs(OffDutyJobs) do
        if v == job then
            jobIndex = i
            break
        end
    end

    if jobIndex then
        player.setJob(ConfigMain.allowedJobs[jobIndex], grade)
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.service, ConfigMain.Text.Notify.goonduty, "generic_textures", "tick", 4000, "COLOR_GREEN")
    else
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.service, ConfigMain.Text.Notify.onduty, "generic_textures", "tick", 4000, "COLOR_YELLOW")
    end
end)

RegisterServerEvent('rs_police:checkjob')
AddEventHandler('rs_police:checkjob', function()
    local _source = source
    local User = VORPcore.getUser(_source)
    local Character = User.getUsedCharacter
    local job = Character.job
    local jobgrade = Character.jobGrade
    TriggerClientEvent('rs_police:badgeon', _source, job, jobgrade)
end)

RegisterServerEvent("rs_police:gooffdutysv")
AddEventHandler("rs_police:gooffdutysv", function()
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local job = player.job
    local grade = player.jobGrade
    local allowed = false

    for k, v in pairs(ConfigMain.allowedJobs) do
        if v == job then
            allowed = true
            break
        end
    end

    if allowed then
        player.setJob('off' .. job, grade)
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.service, ConfigMain.Text.Notify.gooffduty, "generic_textures", "tick", 4000, "COLOR_GREEN")
    else
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.service, ConfigMain.Text.Notify.alredygooffduty, "generic_textures", "tick", 4000, "COLOR_YELLOW")
    end
end)

RegisterServerEvent("rs_police:gooffdutyonstart")
AddEventHandler("rs_police:gooffdutyonstart", function()
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local job = player.job
    local grade = player.jobGrade
    local allowed = false

    for k, v in pairs(ConfigMain.allowedJobs) do
        if v == job then
            allowed = true
            break
        end
    end

    if allowed then
        player.setJob('off' .. job, grade)
    end
end)

RegisterServerEvent('rs_police:JailPlayerServer')
AddEventHandler('rs_police:JailPlayerServer', function(player, amount, loc)
    local _source = source

    if not player or player == 0 then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.id, ConfigMain.Text.Notify.idinvalid, "menu_textures", "cross", 3000, "COLOR_RED")
        return
    end

    local targetUser = VORPcore.getUser(player)
    local sourceUser = VORPcore.getUser(_source)

    if not targetUser or not targetUser.getUsedCharacter then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.id, ConfigMain.Text.Notify.idincorret, "menu_textures", "cross", 3000, "COLOR_RED")
        return
    end

    local target = targetUser.getUsedCharacter
    local user = sourceUser.getUsedCharacter
    local username = user.firstname .. ' ' .. user.lastname
    local Job = user.job
    local targetname = target.firstname .. ' ' .. target.lastname
    local steam_id = target.identifier
    local Character = target.charIdentifier

    local amountInSeconds = amount * 60

    exports.oxmysql:execute("SELECT * FROM jail WHERE characterid = @characterid", {
        ["@characterid"] = Character
    }, function(result)
        if result[1] then
            VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.prison, ConfigMain.Text.Notify.inprison, "menu_textures", "cross", 3000, "COLOR_RED")
            return
        end

        exports.oxmysql:execute(
            "INSERT INTO jail (identifier, characterid, name, time_s, jaillocation) VALUES (@identifier, @characterid, @name, @time, @jaillocation)",
            {
                ["@identifier"] = steam_id,
                ["@characterid"] = Character,
                ["@name"] = targetname,
                ["@time"] = amountInSeconds,
                ["@jaillocation"] = loc
            },
            function()
                TriggerClientEvent("rs_police:JailPlayer", player, amountInSeconds, loc)
            end
        )
    end)
end)

RegisterServerEvent("rs_police:finishedjail")
AddEventHandler("rs_police:finishedjail", function(target_id)
    local target = VORPcore.getUser(target_id).getUsedCharacter
    local steam_id = target.identifier
    local Character = target.charIdentifier

    exports.oxmysql:execute("SELECT * FROM `jail` WHERE characterid = @characterid", {
        ["@characterid"] = Character
    }, function(result)
        if result[1] then
            local loc = result[1]["jaillocation"]
            TriggerClientEvent("rs_police:UnjailPlayer", target_id, loc)
        end
    end)

    exports.oxmysql:execute("DELETE FROM jail WHERE identifier = @identifier AND characterid = @characterid", {
        ["@identifier"] = steam_id,
        ["@characterid"] = Character
    })
end)

RegisterServerEvent("rs_police:unjailed")
AddEventHandler("rs_police:unjailed", function(target_id, loc)
    local _source = source

    if not target_id or target_id == 0 then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.id, ConfigMain.Text.Notify.idinvalid, "menu_textures", "cross", 3000, "COLOR_RED")
        return
    end

    local targetUser = VORPcore.getUser(target_id)
    local user = VORPcore.getUser(_source).getUsedCharacter

    if not targetUser or not targetUser.getUsedCharacter then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.id, ConfigMain.Text.Notify.idincorret, "menu_textures", "cross", 3000, "COLOR_RED")
        return
    end

    local target = targetUser.getUsedCharacter
    local username = user.firstname .. ' ' .. user.lastname
    local Job = user.job
    local targetname = target.firstname .. ' ' .. target.lastname
    local steam_id = target.identifier
    local Character = target.charIdentifier

    exports.oxmysql:execute("SELECT * FROM `jail` WHERE characterid = @characterid", {
        ["@characterid"] = Character
    }, function(result)
        if result[1] then
            local jailLoc = result[1]["jaillocation"]
            TriggerClientEvent("rs_police:UnjailPlayer", target_id, jailLoc)

            exports.oxmysql:execute("DELETE FROM jail WHERE identifier = @identifier AND characterid = @characterid", {
                ["@identifier"] = steam_id,
                ["@characterid"] = Character
            })

        else
            VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.prison, ConfigMain.Text.Notify.noprison, "menu_textures", "cross", 3000, "COLOR_RED")
        end
    end)
end)

RegisterServerEvent('rs_police:GetID')
AddEventHandler('rs_police:GetID', function(player)
    local _source = tonumber(source)

    local User = VORPcore.getUser(player)
    local Target = User.getUsedCharacter

    VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.idcheck, ConfigMain.Text.Notify.name .. Target.firstname .. ' ' .. Target.lastname .. "             " .. ConfigMain.Text.Notify.jobok .. Target.job, "toasts_mp_generic", "toast_mp_customer_service", 8000, "COLOR_WHITE")
end)

RegisterServerEvent('rs_police:getVehicleInfo')
AddEventHandler('rs_police:getVehicleInfo', function(player, mount)
    local _source = tonumber(source)

    local User = VORPcore.getUser(player)
    local Character = User.getUsedCharacter
    local charID = Character.charIdentifier

    local sqlTable = ConfigMain.SQLTable
    local columns = {}

    if sqlTable == "sirevlc_horses_v3" then
        columns.charid = "CHARID"
        columns.model = "MODEL"
        columns.name = "NAME"
    elseif sqlTable == "sirevlc_horses" then
        columns.charid = "charid"
        columns.model = "model"
        columns.name = "name"    
    elseif sqlTable == "rsd_horses" then
        columns.charid = "charid"
        columns.model = "model"
        columns.name = "name"
    elseif sqlTable == "stables" then
        columns.charid = "charidentifier"
        columns.model = "modelname"
        columns.name = "name"  
    elseif sqlTable == "player_horses" then
        columns.charid = "charid"
        columns.model = "model"
        columns.name = "name"      
    end

    exports.oxmysql:execute("SELECT * FROM `" .. sqlTable .. "` WHERE " .. columns.charid .. "=@identifier",
        { identifier = charID },
        function(result)
            local found = false
            if result[1] then
                for i, v in pairs(result) do
                    local modelHash = GetHashKey(v[columns.model])

                    if modelHash == mount then
                        found = true
                        VORPcore.NotifyLeft(_source,
                            ConfigMain.Text.Notify.idcheck,
                            ConfigMain.Text.Notify.name .. Character.firstname .. ' ' .. Character.lastname .. ConfigMain.Text.Notify.horse .. (v[columns.name]), "toasts_mp_generic", "toast_mp_customer_service", 8000, "COLOR_WHITE")
                        break
                    end
                end
            end

            if not found then
                VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.idcheck, ConfigMain.Text.Notify.notowned, "toasts_mp_generic", "toast_mp_customer_service", 8000, "COLOR_WHITE")
            end
        end)
end)

RegisterServerEvent('rs_police:handcuff', function(player)
    TriggerClientEvent('rs_police:handcuffed', player)
end)

RegisterServerEvent('rs_police:drag')
AddEventHandler('rs_police:drag', function(target)
    local _source = source
    local user = VORPcore.getUser(_source).getUsedCharacter
    for i, v in pairs(ConfigMain.allowedJobs) do
        if user.job == v then
            TriggerClientEvent('rs_police:drag', target, _source)
        end
    end
end)

RegisterServerEvent("rs_police:check_jail")
AddEventHandler("rs_police:check_jail", function()
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end

    local CharInfo = User.getUsedCharacter
    if not CharInfo then return end

    local steam_id = CharInfo.identifier
    local character_id = CharInfo.charIdentifier

    local query = "SELECT * FROM jail WHERE identifier = @identifier AND characterid = @characterid"
    local params = {
        ["@identifier"] = steam_id,
        ["@characterid"] = character_id
    }

    exports.oxmysql:execute(query, params, function(result)
        if not result or not result[1] then return end

        local jailData = result[1]
        local time = tonumber(jailData.time_s)
        local jailLocation = jailData.jaillocation

        local updateQuery = "UPDATE jail SET time_s = @time WHERE identifier = @identifier AND characterid = @characterid"
        local updateParams = {
            ["@time"] = time,
            ["@identifier"] = steam_id,
            ["@characterid"] = character_id
        }

        exports.oxmysql:execute(updateQuery, updateParams)

        TriggerClientEvent("rs_police:JailPlayer", _source, time, jailLocation)
        TriggerClientEvent("rs_police:wear_prison", _source)
    end)
end)

RegisterNetEvent("rs_police:updatejailtime")
AddEventHandler("rs_police:updatejailtime", function(currentTime)
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User or not User.getUsedCharacter then return end
    local CharInfo = User.getUsedCharacter
    local steam_id = CharInfo.identifier
    local Character = CharInfo.charIdentifier

    currentTime = tonumber(currentTime) or 0

    exports.oxmysql:execute("SELECT * FROM jail WHERE identifier = @identifier AND characterid = @characterid",
        { ["@identifier"] = steam_id, ["@characterid"] = Character }, function(result)
            if result[1] then
                exports.oxmysql:execute("UPDATE jail SET time_s = @time WHERE identifier = @identifier AND characterid = @characterid",
                    { ["@time"] = currentTime, ["@identifier"] = steam_id, ["@characterid"] = Character })
            else
                exports.oxmysql:execute(
                    "INSERT INTO jail (identifier, characterid, time_s) VALUES (@identifier, @characterid, @time)",
                    { ["@identifier"] = steam_id, ["@characterid"] = Character, ["@time"] = currentTime }
                )
            end
        end)
end)

RegisterServerEvent("rs_police:guncabinet")
AddEventHandler("rs_police:guncabinet", function(index)
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local grade = player.jobGrade

    local item = ConfigCabinets.WeaponsandAmmo.Weapons[index]
    if not item then
        return
    end

    local label = item.label

    if grade >= item.allowedGrade then
        exports.vorp_inventory:canCarryWeapons(_source, 1, function(canCarry)
            if canCarry then
                VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.armory, ConfigMain.Text.Notify.collect .. label, "generic_textures", "tick", 4000, "COLOR_GREEN")
                VorpInv.createWeapon(_source, item.weapon, {}, {})
            else
                VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.armory, ConfigMain.Text.Notify.fullweapons, "menu_textures", "cross", 4000, "COLOR_RED")
            end
        end, item.weapon)
    else
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.grade, ConfigMain.Text.Notify.nograde, "menu_textures", "cross", 4000, "COLOR_RED")
    end
end)

RegisterServerEvent("rs_police:addammo")
AddEventHandler("rs_police:addammo", function(index)
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local grade = player.jobGrade

    local item = ConfigCabinets.WeaponsandAmmo.Ammo[index]
    if not item then return end

    if grade < item.allowedGrade then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.grade, ConfigMain.Text.Notify.nograde, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    local amount = item.amount or 1
    local canCarryItems = true

    exports.vorp_inventory:canCarryItem(_source, item.ammo, amount, function(canCarry)
        if not canCarry then
            canCarryItems = false
        end
    end)

    Wait(100)

    if not canCarryItems then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.armory, ConfigMain.Text.Notify.fullitems, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    VorpInv.addItem(_source, item.ammo, amount)
    VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.armory, ConfigMain.Text.Notify.collect .. item.label, "generic_textures", "tick", 4000, "COLOR_GREEN")
end)

function CheckTable(tbl, val)
    if not tbl then return false end
    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end

function getTime()
    return os.time(os.date("!*t"))
end

Citizen.CreateThread(function()
    Wait(200)
    VorpInv.RegisterUsableItem("handcuffs", function(data)
        local _source = data.source
        local Character = VORPcore.getUser(_source).getUsedCharacter
        local job = Character.job
        VorpInv.CloseInv(_source)

        if not ConfigMain.jobRequired or hasJob(job) then
            TriggerClientEvent("rs_police:tryHandcuff", _source)
        else
            VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.handcuff, ConfigMain.Text.Notify.nojob, "menu_textures", "cross", 3000, "COLOR_RED")
        end
    end)
end)

function hasJob(job)
    for _, allowedJob in ipairs(ConfigMain.allowedJobs) do
        if job == allowedJob then
            return true
        end
    end
    return false
end

function CheckTable(table, element)
    for k, v in pairs(table) do
        if v == element then
            return true
        end
    end
    return false
end

RegisterServerEvent('rs_police:PlayerJob')
AddEventHandler('rs_police:PlayerJob', function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local CharacterJob = Character.job
    TriggerClientEvent('rs_police:PlayerJob', _source, CharacterJob)
end)

RegisterServerEvent("rs_police:GetPlayerWagonID")
AddEventHandler("rs_police:GetPlayerWagonID", function(player)
    if player ~= nil then
        TriggerClientEvent('rs_police:PlayerInWagon', player)
    end
end)

local playersTakenFood = {}

RegisterServerEvent('rs_police:CommisaryAddItem', function()
    local _source = source
    local commisary = ConfigJail.Jails.sisika.Commisary

    if playersTakenFood[_source] then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.canteen, ConfigMain.Text.Notify.succes, "menu_textures", "cross", 3000, "COLOR_RED")
        return
    end

    for _, item in ipairs(commisary.Items) do
        VorpInv.addItem(_source, item.name, item.amount)
    end

    playersTakenFood[_source] = true

    local msg = ConfigMain.Text.Notify.collect1
    for i, item in ipairs(commisary.Items) do
        msg = msg .. item.amount .. "x " .. item.label
        if i < #commisary.Items then
            msg = msg .. ", "
        end
    end

    TriggerClientEvent('vorp:NotifyLeft', _source, ConfigMain.Text.Notify.canteen, msg, "generic_textures", "tick", 4000, "COLOR_GREEN")
end)

RegisterServerEvent("rs_police:PlayerReleased")
AddEventHandler("rs_police:PlayerReleased", function()
    local _source = source
    playersTakenFood[_source] = nil
end)

AddEventHandler("playerDropped", function()
    local _source = source
    playersTakenFood[_source] = nil
end)

local function HasAllowedJob(job)
    for _, allowedJob in ipairs(ConfigMain.allowedJobs) do
        if job == allowedJob then
            return true
        end
    end
    return false
end

RegisterServerEvent("rs_police:CheckJob")
AddEventHandler("rs_police:CheckJob", function()
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local job = player.job

    if ConfigMain.jobRequired and not HasAllowedJob(job) then
        TriggerClientEvent("rs_police:JobDenied", _source)
    else
        TriggerClientEvent("rs_police:JobAccepted", _source)
    end
end)

RegisterServerEvent("rs_police:checkcabinetjob")
AddEventHandler("rs_police:checkcabinetjob", function()
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local job = player.job

    if ConfigMain.jobRequired and not HasAllowedJob(job) then
        TriggerClientEvent("rs_police:JobCabinetDenied", _source)
    else
        TriggerClientEvent("rs_police:JobCabinetAccepted", _source)
    end
end)

RegisterServerEvent("rs_police:checkhirejob")
AddEventHandler("rs_police:checkhirejob", function()
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local job = player.job

    if ConfigMain.jobRequired and not HasAllowedJob(job) then
        TriggerClientEvent("rs_police:JobHireDenied", _source)
    else
        TriggerClientEvent("rs_police:JobHireAccepted", _source)
    end
end)

RegisterServerEvent("rs_police:RequestSpawnWagon")
AddEventHandler("rs_police:RequestSpawnWagon", function(wagonModel, coords)
    local _source = source
    local player = VORPcore.getUser(_source).getUsedCharacter
    local job = player.job
    local grade = player.jobGrade

    local requiredGrade = nil
    for _, data in ipairs(ConfigMain.Wagons) do
        if data.wagon == wagonModel then
            requiredGrade = data.allowedGrade
            break
        end
    end

    if requiredGrade and grade < requiredGrade then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.wagon, ConfigMain.Text.Notify.nograde, "menu_textures", "cross", 3000, "COLOR_RED")
        return
    end

    TriggerClientEvent("rs_police:spawnWagon", _source, wagonModel, coords)
    VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.wagon, ConfigMain.Text.Notify.wagonok, "generic_textures", "tick", 4000, "COLOR_GREEN")
end)


RegisterServerEvent("rs_police:DeleteWagonServer")
AddEventHandler("rs_police:DeleteWagonServer", function(wagonNetId)
    TriggerClientEvent("rs_police:DeleteWagonGlobal", -1, wagonNetId)
end)

RegisterCommand(ConfigMain.delwagoncommand, function(source)
    local _source = source
    TriggerClientEvent("rs_police:deleteWagon", _source)
end, false)

local Inv = exports.vorp_inventory

local function registerStorage(prefix, name, limit)
    local isInvRegstered <const> = Inv:isCustomInventoryRegistered(prefix)
    if not isInvRegstered then
        local data <const> = {
            id = prefix,
            name = name,
            limit = limit,
            acceptWeapons = true,
            shared = true,
            ignoreItemStackLimit = true,
            whitelistItems = false,
            UsePermissions = false,
            UseBlackList = false,
            whitelistWeapons = false,

        }
        Inv:registerInventory(data)
    end
end

RegisterNetEvent("rs_police:Server:OpenStorage", function(key)
    local _source <const> = source
    local user <const> = VORPcore.getUser(_source)
    if not user then return end

    local prefix = "police_storage_" .. key
    local storageData = ConfigMain.Storage[key]
    if not storageData then return end

    local storageName <const> = storageData.Name
    local storageLimit <const> = storageData.Limit

    registerStorage(prefix, storageName, storageLimit)
    Inv:openInventory(_source, prefix)
end)

RegisterServerEvent("rs_police:checkstoragejob")
AddEventHandler("rs_police:checkstoragejob", function(key)
    local _source = source
    if not key then return end

    local player = VORPcore.getUser(_source)
    if not player then return end

    local character = player.getUsedCharacter
    local job = character.job
    local grade = character.jobGrade

    local storageData = ConfigMain.Storage[key]
    if not storageData then return end

    local requiredGrade = storageData.MinGrade

    if requiredGrade == false then
        if HasAllowedJob(job) then
            TriggerClientEvent("rs_police:JobStorageAccepted", _source, key)
        else
            TriggerClientEvent("rs_police:JobStorageDenied", _source, key)
        end
        return
    end

    if HasAllowedJob(job) and tonumber(grade) and tonumber(requiredGrade) and tonumber(grade) >= tonumber(requiredGrade) then
        TriggerClientEvent("rs_police:JobStorageAccepted", _source, key)
    else
        TriggerClientEvent("rs_police:JobStorageDenied", _source, key)
    end
end)

RegisterServerEvent("CheckPoliceMenuPermission")
AddEventHandler("CheckPoliceMenuPermission", function()
    local _source = source
    local User = VORPcore.getUser(_source)
    if not User then return end

    local character = User.getUsedCharacter
    if not character then return end

    local characterJob = character.job
    local characterGroup = character.group

    if characterGroup == "admin" then
        TriggerClientEvent("OpenPoliceMenuClient", _source)
        return
    end

    if ConfigMain.jobRequired and not HasAllowedJob(characterJob) then
        VORPcore.NotifyLeft(_source, ConfigMain.Text.Notify.job, ConfigMain.Text.Notify.notjoborservice, "menu_textures", "cross", 3000, "COLOR_RED")
        return
    end
    
    TriggerClientEvent("OpenPoliceMenuClient", _source)
end)


RegisterServerEvent("rs_police:openMainMenu")
AddEventHandler("rs_police:openMainMenu", function()
    TriggerClientEvent("rs_police:client:openMainMenu", source)
end)

RegisterServerEvent("rs_police:requestJobList")
AddEventHandler("rs_police:requestJobList", function()
    TriggerClientEvent("rs_police:client:openJobList", source, ConfigMain.Hirenames)
end)

RegisterServerEvent("rs_police:requestRankList")
AddEventHandler("rs_police:requestRankList", function(jobName)
    local ranks = ConfigMain.Hirenames[jobName]
    if ranks then
        TriggerClientEvent("rs_police:client:openRankList", source, jobName, ranks)
    end
end)

RegisterServerEvent("rs_police:hirePlayer")
AddEventHandler("rs_police:hirePlayer", function(targetId, jobName, grade)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end

    local char = user.getUsedCharacter
    if not char then return end

    local playerJob = char.job
    local playerGrade = char.jobGrade
    local jobRanks = ConfigMain.Hirenames[playerJob]

    local canHire = false
    if jobRanks then
        for _, rank in ipairs(jobRanks) do
            if rank.Grade == playerGrade and rank.canHire then
                canHire = true
                break
            end
        end
    end

    if not canHire then
        VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.permisdenied, ConfigMain.Text.Notify.nograde, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    local targetUser = VORPcore.getUser(targetId)
    if not targetUser then
        VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.error, ConfigMain.Text.Notify.playernot, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    local targetChar = targetUser.getUsedCharacter
    if not targetChar then
        VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.error, ConfigMain.Text.Notify.playernotcharge, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    local rankData = nil
    if ConfigMain.Hirenames[jobName] then
        for _, rank in ipairs(ConfigMain.Hirenames[jobName]) do
            if rank.Grade == grade then
                rankData = rank
                break
            end
        end
    end

    if not rankData then
        VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.error, ConfigMain.Text.Notify.invalidrank, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    targetChar.setJob(jobName, grade)
    targetChar.setJobGrade(grade)
    targetChar.setJobLabel(rankData.label)

    exports.oxmysql:execute("UPDATE characters SET job = ?, jobgrade = ?, jobLabel = ? WHERE charidentifier = ?", {
        jobName, grade, rankData.label, targetChar.charIdentifier
    })

    VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.contracted, ConfigMain.Text.Notify.youhire .. " " .. targetChar.firstname .. " " .. targetChar.lastname .. ConfigMain.Text.Notify.how .. " " .. rankData.label, "generic_textures", "tick", 4000, "COLOR_GREEN")
    VORPcore.NotifyLeft(targetId, ConfigMain.Text.Notify.newjob, ConfigMain.Text.Notify.youhirehow .. " " .. rankData.label, "generic_textures", "tick", 4000, "COLOR_GREEN")
end)

RegisterServerEvent("rs_police:firePlayer")
AddEventHandler("rs_police:firePlayer", function(targetId)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end

    local char = user.getUsedCharacter
    if not char then return end

    local playerJob = char.job
    local playerGrade = char.jobGrade
    local jobRanks = ConfigMain.Hirenames[playerJob]

    local canFire = false
    if jobRanks then
        for _, rank in ipairs(jobRanks) do
            if rank.Grade == playerGrade and rank.canFire then
                canFire = true
                break
            end
        end
    end

    if not canFire then
        VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.permisdenied, ConfigMain.Text.Notify.nograde, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    local targetUser = VORPcore.getUser(targetId)
    if not targetUser then
        VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.error, ConfigMain.Text.Notify.playernot, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    local targetChar = targetUser.getUsedCharacter
    if not targetChar then
        VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.error, ConfigMain.Text.Notify.playernotcharge, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    targetChar.setJob("unemployed", 0)
    targetChar.setJobGrade(0)
    targetChar.setJobLabel("Unemployed")

    exports.oxmysql:execute("UPDATE characters SET job = ?, jobgrade = ?, jobLabel = ? WHERE charidentifier = ?", {
        "unemployed", 0, "Unemployed", targetChar.charIdentifier
    })

    VORPcore.NotifyLeft(src, ConfigMain.Text.Notify.dismissed, ConfigMain.Text.Notify.youfire .. " " .. targetChar.firstname .. " " .. targetChar.lastname, "menu_textures", "cross", 4000, "COLOR_RED")
    VORPcore.NotifyLeft(targetId, ConfigMain.Text.Notify.dismissed, ConfigMain.Text.Notify.fire, "menu_textures", "cross", 4000, "COLOR_RED")
end)

RegisterServerEvent("rs_police:requestFireList")
AddEventHandler("rs_police:requestFireList", function()
    local src = source
    local players = {}

    for _, playerId in ipairs(GetPlayers()) do
        local targetUser = VORPcore.getUser(tonumber(playerId))
        if targetUser then
            local targetChar = targetUser.getUsedCharacter
            if targetChar then
                local job = targetChar.job
                if ConfigMain.Hirenames[job] then
                    table.insert(players, {
                        id = tonumber(playerId),
                        name = targetChar.firstname .. " " .. targetChar.lastname,
                        job = job
                    })
                end
            end
        end
    end

    TriggerClientEvent("rs_police:client:openFireList", src, players)
end)

RegisterServerEvent('rs_police:OpenMenu')
AddEventHandler('rs_police:OpenMenu', function(data)
    local _source = source

    Player(_source).state:set('DataSteal', data, true)

    exports.vorp_inventory:closeInventory(data.source)

    Player(data.source).state:set('Stealing', true, true)
    local Character = VORPcore.getUser(data.source).getUsedCharacter
    TriggerClientEvent('rs_police:OpenMenu', _source, Character.money)
end)

RegisterServerEvent('rs_police:Stealing')
AddEventHandler('rs_police:Stealing', function(steal_source, enable)
    Player(steal_source).state:set('Stealing', enable, true)
end)

RegisterServerEvent('rs_police:StealMoney')
AddEventHandler('rs_police:StealMoney', function(steal_source, amount)
    local _source = source
    local StealCharacter = VORPcore.getUser(steal_source).getUsedCharacter

    StealCharacter.removeCurrency(0, amount)

    local Character = VORPcore.getUser(_source).getUsedCharacter
    Character.addCurrency(0, amount)

    VORPcore.NotifyAvanced(_source, ConfigMain.Text.Notify.stealmoney .. ' ' .. amount .. "$", "menu_textures", "log_gang_bag", "COLOR_PURE_WHITE", 2000)

end)

RegisterServerEvent('rs_police:ReloadInventory')
AddEventHandler('rs_police:ReloadInventory', function(steal_source, player_source)
    local _source = player_source or source

    local inventory = {}

    exports.vorp_inventory:getUserInventoryItems(tonumber(steal_source), function(getInventory)
        for _, v in pairs(getInventory) do
            table.insert(inventory, v)
        end
    end)

    exports.vorp_inventory:getUserInventoryWeapons(tonumber(steal_source), function(getUserWeapons)
        for _, v in pairs(getUserWeapons) do
            v.count = 1
            v.limit = 1
            v.type = 'item_weapon'
            table.insert(inventory, v)
        end
    end)

    TriggerClientEvent('vorp_inventory:ReloadstealInventory', _source, json.encode({
        itemList = inventory,
        action = 'setSecondInventoryItems',
    }))
end)

RegisterServerEvent('rs_police:OpenInventory')
AddEventHandler('rs_police:OpenInventory', function(steal_source)
    local _source = source
    local Character = VORPcore.getUser(steal_source).getUsedCharacter

    TriggerClientEvent('vorp_inventory:OpenstealInventory', _source, ConfigMain.Text.Menu.menutitle, Character.charIdentifier)
end)

RegisterServerEvent('syn_search:MoveTosteal')
AddEventHandler('syn_search:MoveTosteal', function(obj)
    local _source = source

    local steal_source = Player(_source).state.DataSteal and Player(_source).state.DataSteal.source

    if not steal_source then
        return
    end

    local decode_obj = json.decode(obj)
    decode_obj.number = tonumber(decode_obj.number)

    if decode_obj.type == 'item_standard' and decode_obj.number > 0 and decode_obj.number <= tonumber(decode_obj.item.count) then
        local canCarrys = exports.vorp_inventory:canCarryItems(steal_source, decode_obj.number)
        local canCarry = exports.vorp_inventory:canCarryItem(steal_source, decode_obj.item.name, decode_obj.number)
        if canCarrys and canCarry then
            exports.vorp_inventory:subItem(_source, decode_obj.item.name, decode_obj.number, decode_obj.item.metadata)
            exports.vorp_inventory:addItem(steal_source, decode_obj.item.name, decode_obj.number, decode_obj.item.metadata)
            Wait(100)
            TriggerEvent('rs_police:ReloadInventory', steal_source, _source)
        else
            VORPcore.NotifyObjective(_source, ConfigMain.Text.Notify.notstealcarryitems, 4000)
        end

    elseif decode_obj.type == 'item_weapon' then
        local canCarry = exports.vorp_inventory:canCarryWeapons(steal_source, 1, nil, decode_obj.item.name)
        if canCarry then
            exports.vorp_inventory:giveWeapon(steal_source, decode_obj.item.id, _source)
            Wait(100)
            TriggerEvent('rs_police:ReloadInventory', steal_source, _source)
        else
            VORPcore.NotifyObjective(_source, ConfigMain.Text.Notify.notstealcarryweapon, 4000)
        end
    end
end)

RegisterServerEvent('syn_search:TakeFromsteal')
AddEventHandler('syn_search:TakeFromsteal', function(obj)
    local _source = source

    local steal_source = Player(_source).state.DataSteal and Player(_source).state.DataSteal.source

    if not steal_source then
        return
    end

    local decode_obj = json.decode(obj)
    decode_obj.number = tonumber(decode_obj.number)

    if decode_obj.type == 'item_standard' and decode_obj.number > 0 and decode_obj.number <= tonumber(decode_obj.item.count) then

        local canCarrys = exports.vorp_inventory:canCarryItems(_source, decode_obj.number)
        local canCarry = exports.vorp_inventory:canCarryItem(_source, decode_obj.item.name, decode_obj.number)
        if canCarrys and canCarry then
            exports.vorp_inventory:subItem(steal_source, decode_obj.item.name, decode_obj.number, decode_obj.item.metadata)
            exports.vorp_inventory:addItem(_source, decode_obj.item.name, decode_obj.number, decode_obj.item.metadata)
            Wait(100)
            TriggerEvent('rs_police:ReloadInventory', steal_source, _source)
        else
            VORPcore.NotifyObjective(_source, ConfigMain.Text.Menu.notcarryitems, 4000)
        end

    elseif decode_obj.type == 'item_weapon' then
        
        local canCarry = exports.vorp_inventory:canCarryWeapons(_source, 1, nil, decode_obj.item.name)
        if canCarry then
            exports.vorp_inventory:giveWeapon(_source, decode_obj.item.id, steal_source)
            Wait(100)
            TriggerEvent('rs_police:ReloadInventory', steal_source, _source)
        else
            VORPcore.NotifyObjective(_source, ConfigMain.Text.Menu.notcarryweapons, 4000)
        end
    end
end)

RegisterServerEvent('rs_police:CloseInventory')
AddEventHandler('rs_police:CloseInventory', function()
    local _source = source
    exports.vorp_inventory:closeInventory(_source)
end)

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key, value in pairs(ConfigMain.Storage) do
        local prefix = "police_storage_" .. key
        registerStorage(prefix, value.Name, value.Limit)
    end
end)
