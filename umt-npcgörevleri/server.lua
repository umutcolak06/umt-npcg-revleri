local QBCore = nil
local ESX = nil

local FrameworkBackend = 'standalone'
local InventoryBackend = 'none'
local ActiveMissions = {}
local PendingGroupMissions = {}
local buildMission

math.randomseed(os.time())

local function chooseRandom(list)
    if not list or #list == 0 then
        return nil
    end
    return list[math.random(1, #list)]
end

local function debugLog(msg)
    if Config.Debug then
        print(('[umt-meslekler] %s'):format(msg))
    end
end

local function detectFramework()
    local preferred = (Config.Framework or 'auto'):lower()
    if preferred ~= 'auto' then
        FrameworkBackend = preferred
    elseif GetResourceState('qb-core') == 'started' then
        FrameworkBackend = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        FrameworkBackend = 'esx'
    else
        FrameworkBackend = 'standalone'
    end

    if FrameworkBackend == 'qb' and GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif FrameworkBackend == 'esx' and GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
    end
end

local function detectInventory()
    local preferred = (Config.InventoryBackend or 'auto'):lower()
    if preferred ~= 'auto' then
        InventoryBackend = preferred
        return
    end

    if GetResourceState('ox_inventory') == 'started' then
        InventoryBackend = 'ox'
    elseif GetResourceState('qb-inventory') == 'started' then
        InventoryBackend = 'qb'
    elseif FrameworkBackend == 'esx' then
        InventoryBackend = 'esx'
    else
        InventoryBackend = 'none'
    end
end

local function getPlayer(src)
    if FrameworkBackend == 'qb' and QBCore and QBCore.Functions then
        return QBCore.Functions.GetPlayer(src)
    end

    if FrameworkBackend == 'esx' and ESX and ESX.GetPlayerFromId then
        return ESX.GetPlayerFromId(src)
    end

    return { source = src }
end

local function getPlayerJob(player)
    if not player then
        return { name = nil, onduty = true }
    end

    if FrameworkBackend == 'qb' then
        local job = player.PlayerData and player.PlayerData.job or nil
        return {
            name = job and job.name or nil,
            onduty = job and (job.onduty == true) or false,
        }
    end

    if FrameworkBackend == 'esx' then
        local job = player.getJob and player.getJob() or nil
        local onduty = true
        if job and job.onduty ~= nil then
            onduty = job.onduty == true
        end
        return {
            name = job and job.name or nil,
            onduty = onduty,
        }
    end

    return {
        name = nil,
        onduty = true,
    }
end

local function addMoneyReward(src, player, account, amount)
    if amount <= 0 then
        return false
    end

    if FrameworkBackend == 'qb' and player and player.Functions and player.Functions.AddMoney then
        local qbAccount = account or 'cash'
        player.Functions.AddMoney(qbAccount, amount, 'meslek-npc-gorev-odulu')
        return true
    end

    if FrameworkBackend == 'esx' and player then
        local esxAccount = account or 'money'
        if esxAccount == 'cash' then
            esxAccount = 'money'
        end

        if player.addAccountMoney then
            player.addAccountMoney(esxAccount, amount)
            return true
        end

        if esxAccount == 'money' and player.addMoney then
            player.addMoney(amount)
            return true
        end
    end

    return false
end

local function addItemReward(src, player, item, count)
    if not item or count <= 0 then
        return false
    end

    if InventoryBackend == 'ox' and GetResourceState('ox_inventory') == 'started' then
        local ok = exports.ox_inventory:AddItem(src, item, count)
        return ok ~= false
    end

    if InventoryBackend == 'qb' and FrameworkBackend == 'qb' and player and player.Functions and player.Functions.AddItem then
        player.Functions.AddItem(item, count, false, nil, 'meslek-npc-gorev-odulu')
        return true
    end

    if InventoryBackend == 'esx' and player and player.addInventoryItem then
        player.addInventoryItem(item, count)
        return true
    end

    return false
end

local function hasPermission(src, jobCfg)
    if not jobCfg.RequiredAce then
        return true
    end
    return IsPlayerAceAllowed(src, jobCfg.RequiredAce)
end

local function resolveJobConfigName(jobName)
    if not jobName then
        return nil
    end

    local jobs = Config.Jobs or {}
    if jobs[jobName] then
        return jobName
    end

    local aliases = Config.JobAliases and Config.JobAliases[jobName] or nil
    if type(aliases) == 'string' then
        aliases = { aliases }
    end

    if type(aliases) == 'table' then
        for i = 1, #aliases do
            local aliasName = aliases[i]
            if jobs[aliasName] then
                return aliasName
            end
        end
    end

    return nil
end

local function findSharedGroupByJob(jobName)
    local resolvedJobName = resolveJobConfigName(jobName)
    if not resolvedJobName then
        return nil
    end

    local groups = Config.SharedMissionGroups or {}
    for i = 1, #groups do
        local group = groups[i]
        local jobs = group.Jobs or {}
        for j = 1, #jobs do
            local listedJob = jobs[j]
            local listedResolved = resolveJobConfigName(listedJob) or listedJob
            if listedResolved == resolvedJobName then
                return group
            end
        end
    end
    return nil
end

local function isJobInList(jobName, jobs)
    local resolvedInput = resolveJobConfigName(jobName) or jobName
    for i = 1, #jobs do
        local listed = jobs[i]
        local resolvedListed = resolveJobConfigName(listed) or listed
        if listed == jobName or resolvedListed == resolvedInput then
            return true
        end
    end
    return false
end

local function canJobCompleteMission(jobName, mission)
    if mission.allowedJobs and #mission.allowedJobs > 0 then
        return isJobInList(jobName, mission.allowedJobs)
    end
    return mission.jobName == jobName
end

local function getOnlineSourcesWithJobs(jobs, requireDuty)
    local sources = {}
    local all = GetPlayers()
    for i = 1, #all do
        local src = tonumber(all[i])
        if src then
            local p = getPlayer(src)
            local j = getPlayerJob(p)
            local dutyAllowed = (not requireDuty) or (j and j.onduty == true)
            if j and j.name and dutyAllowed and isJobInList(j.name, jobs) then
                sources[#sources + 1] = src
            end
        end
    end
    return sources
end

local function getPendingGroupMission(groupId)
    local pending = PendingGroupMissions[groupId]
    if not pending then
        return nil
    end

    if os.time() >= (pending.expiresAt or 0) then
        PendingGroupMissions[groupId] = nil
        return nil
    end

    return pending
end

local function buildReward(jobCfg)
    local rewardCfg = jobCfg.Reward or {}
    local rewardType = rewardCfg.type or Config.Reward.DefaultType or 'money'

    if rewardType == 'item' then
        local minCount = rewardCfg.minCount or 1
        local maxCount = rewardCfg.maxCount or minCount
        return {
            type = 'item',
            item = rewardCfg.item,
            count = math.random(minCount, maxCount),
        }
    end

    local minAmount = rewardCfg.min or 100
    local maxAmount = rewardCfg.max or minAmount
    return {
        type = 'money',
        account = rewardCfg.account or Config.Reward.DefaultAccount or 'cash',
        amount = math.random(minAmount, maxAmount),
    }
end

buildMission = function(src, jobName, jobCfg)
    local missionId = ('%s-%s-%s'):format(src, jobName, math.random(111111, 999999))
    local missionType = jobCfg.Type or jobName

    local mission = {
        id = missionId,
        src = src,
        jobName = jobName,
        missionType = missionType,
        reward = buildReward(jobCfg),
        createdAt = os.time(),
        state = 'active'
    }

    if missionType == 'doctor' then
        local coords = chooseRandom(jobCfg.Locations)
        if not coords then
            return nil
        end

        local bodyParts = (jobCfg.DoctorDialogue and jobCfg.DoctorDialogue.BodyParts) or { 'Bacagim' }
        local incidents = (jobCfg.DoctorDialogue and jobCfg.DoctorDialogue.Incidents) or { 'yaralandim' }
        local names = (jobCfg.DoctorDialogue and jobCfg.DoctorDialogue.Names) or { 'Vatandas' }
        local symptoms = (jobCfg.DoctorDialogue and jobCfg.DoctorDialogue.Symptoms) or { 'kendimi kotu hissediyorum' }
        local severityLevels = (jobCfg.DoctorDialogue and jobCfg.DoctorDialogue.Severity) or { 'orta' }
        local bodyPart = chooseRandom(bodyParts) or 'Bacagim'
        local incident = chooseRandom(incidents) or 'yaralandim'
        local patientName = chooseRandom(names) or 'Vatandas'
        local symptom = chooseRandom(symptoms) or 'kendimi kotu hissediyorum'
        local severity = chooseRandom(severityLevels) or 'orta'
        local age = math.random(20, 58)

        mission.clientData = {
            id = missionId,
            type = missionType,
            jobName = jobName,
            jobLabel = jobCfg.Label,
            coords = { x = coords.x, y = coords.y, z = coords.z, w = coords.w },
            patientInfo = {
                name = patientName,
                age = age,
                bodyPart = bodyPart,
                incident = incident,
                symptom = symptom,
                severity = severity,
            }
        }
    elseif missionType == 'police' then
        local coords = chooseRandom(jobCfg.Locations)
        local subtype = chooseRandom(jobCfg.Types)
        if not coords or not subtype then
            return nil
        end

        local pd = jobCfg.PoliceDialogue or {}
        local suspectName = chooseRandom(pd.SuspectNames or { 'Unknown' }) or 'Unknown'
        local callerName = chooseRandom(pd.CallerNames or { 'Caller' }) or 'Caller'
        local witnessLine = chooseRandom(pd.WitnessLines or { 'Supheli son olarak burada goruldu.' }) or 'Supheli son olarak burada goruldu.'
        local suspectLine = chooseRandom(pd.SuspectLines or { 'Beni yakalayamazsiniz.' }) or 'Beni yakalayamazsiniz.'

        local message = 'Supheli sokakta dolasiyor.'
        if subtype == 'stolen_vehicle' then
            message = 'Ihbar: Arac hirsizligi suphelisi kaciyor.'
        elseif subtype == 'murder_suspect' then
            message = 'Ihbar: Cinayet suphelisi olay yerinden kaciyor.'
        end

        mission.clientData = {
            id = missionId,
            type = missionType,
            jobName = jobName,
            jobLabel = jobCfg.Label,
            subtype = subtype,
            message = message,
            coords = { x = coords.x, y = coords.y, z = coords.z, w = coords.w },
            dispatchInfo = {
                callerName = callerName,
                witnessLine = witnessLine,
                suspectName = suspectName,
                suspectLine = suspectLine,
            }
        }
    elseif missionType == 'food' then
        local delivery = chooseRandom(jobCfg.Dropoffs)
        if not delivery then
            return nil
        end

        local fd = jobCfg.FoodDialogue or {}
        local customerName = chooseRandom(fd.CustomerNames or { 'Customer' }) or 'Customer'
        local orderLine = chooseRandom(fd.Orders or { '1x Siparis' }) or '1x Siparis'
        local pickupLine = chooseRandom(fd.PickupLines or { 'Siparis hazir.' }) or 'Siparis hazir.'
        local deliveryLine = chooseRandom(fd.DeliveryLines or { 'Tesekkurler.' }) or 'Tesekkurler.'

        mission.clientData = {
            id = missionId,
            type = missionType,
            jobName = jobName,
            jobLabel = jobCfg.Label,
            delivery = { x = delivery.x, y = delivery.y, z = delivery.z },
            foodInfo = {
                customerName = customerName,
                orderLine = orderLine,
                pickupLine = pickupLine,
                deliveryLine = deliveryLine,
            }
        }
    elseif missionType == 'mechanic' then
        local spawn = chooseRandom(jobCfg.SpawnLocations)
        local vehicleModel = chooseRandom(jobCfg.Vehicles)
        if not spawn or not vehicleModel then
            return nil
        end

        local md = jobCfg.MechanicDialogue or {}
        local ownerName = chooseRandom(md.OwnerNames or { 'Driver' }) or 'Driver'
        local issueLine = chooseRandom(md.Issues or { 'arac arizalandi' }) or 'arac arizalandi'
        local urgencyLine = chooseRandom(md.Urgency or { 'acil yardim gerekiyor' }) or 'acil yardim gerekiyor'
        local thanksLine = chooseRandom(md.Thanks or { 'tesekkur ederim usta' }) or 'tesekkur ederim usta'

        mission.clientData = {
            id = missionId,
            type = missionType,
            jobName = jobName,
            jobLabel = jobCfg.Label,
            coords = { x = spawn.x, y = spawn.y, z = spawn.z, w = spawn.w },
            vehicleModel = vehicleModel,
            mechanicInfo = {
                ownerName = ownerName,
                issueLine = issueLine,
                urgencyLine = urgencyLine,
                thanksLine = thanksLine,
            }
        }
    else
        return nil
    end

    return mission
end

CreateThread(function()
    Wait(500)
    detectFramework()
    detectInventory()
    debugLog(('Framework: %s | Inventory: %s'):format(FrameworkBackend, InventoryBackend))
end)

RegisterNetEvent('umt_meslekler:server:RequestMission', function(jobName)
    local src = source
    local player = getPlayer(src)
    if not player then
        return
    end

    local resolvedJobName = resolveJobConfigName(jobName)
    local jobCfg = resolvedJobName and Config.Jobs[resolvedJobName] or nil
    if not jobCfg then
        TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'Bu meslek icin gorev tanimli degil.')
        return
    end

    if ActiveMissions[src] then
        TriggerClientEvent('umt_meslekler:client:MissionDenied', src, Config.Locale.mission_active)
        return
    end

    if FrameworkBackend ~= 'standalone' then
        local pJob = getPlayerJob(player)
        local playerResolvedJob = resolveJobConfigName(pJob.name)
        if playerResolvedJob ~= resolvedJobName then
            TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'Meslegin degisti, gorev verilemedi.')
            return
        end

        if Config.RequireDuty and not pJob.onduty then
            TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'On duty olmadan gorev alamazsin.')
            return
        end
    end

    if not hasPermission(src, jobCfg) then
        TriggerClientEvent('umt_meslekler:client:MissionDenied', src, Config.Locale.no_permission)
        return
    end

    local sharedGroup = findSharedGroupByJob(resolvedJobName)
    if sharedGroup then
        local pending = getPendingGroupMission(sharedGroup.Id)
        local createdNow = false
        if not pending then
            local newMission = buildMission(src, resolvedJobName, jobCfg)
            if not newMission then
                TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'Ortak gorev olusturulamadi, config kontrol et.')
                return
            end
            newMission.groupId = sharedGroup.Id
            newMission.allowedJobs = sharedGroup.Jobs or {}
            newMission.shared = true

            pending = {
                mission = newMission,
                expiresAt = os.time() + (sharedGroup.OfferDurationSeconds or 45),
            }
            PendingGroupMissions[sharedGroup.Id] = pending
            createdNow = true
        end

        local offerPayload = {
            id = pending.mission.id,
            jobLabel = sharedGroup.Label or pending.mission.clientData.jobLabel or sharedGroup.Id,
            type = pending.mission.clientData.type,
        }
        if createdNow then
            local targets = getOnlineSourcesWithJobs(sharedGroup.Jobs or {}, Config.RequireDuty)
            for i = 1, #targets do
                TriggerClientEvent('umt_meslekler:client:MissionOffered', targets[i], offerPayload, pending.expiresAt)
            end
        else
            TriggerClientEvent('umt_meslekler:client:MissionOffered', src, offerPayload, pending.expiresAt)
        end
        return
    end

    local mission = buildMission(src, resolvedJobName, jobCfg)
    if not mission then
        TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'Gorev olusturulamadi, config kontrol et.')
        return
    end

    ActiveMissions[src] = mission
    TriggerClientEvent('umt_meslekler:client:MissionAssigned', src, mission.clientData)
end)

RegisterNetEvent('umt_meslekler:server:AcceptOfferedMission', function(offerId)
    local src = source
    local player = getPlayer(src)
    if not player then
        return
    end

    if ActiveMissions[src] then
        TriggerClientEvent('umt_meslekler:client:MissionDenied', src, Config.Locale.mission_active)
        return
    end

    local playerJob = getPlayerJob(player)
    local playerResolvedJob = resolveJobConfigName(playerJob.name)
    if not playerResolvedJob then
        TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'Bu meslek icin gorev tanimli degil.')
        return
    end
    local groups = Config.SharedMissionGroups or {}

    for i = 1, #groups do
        local group = groups[i]
        local pending = getPendingGroupMission(group.Id)
        if pending and pending.mission and pending.mission.id == offerId then
            if pending.claimedBy then
                TriggerClientEvent('umt_meslekler:client:MissionOfferClosed', src, 'taken')
                return
            end

            if not isJobInList(playerResolvedJob, group.Jobs or {}) then
                TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'Bu gorevi kabul edemezsin.')
                return
            end

            if Config.RequireDuty and not playerJob.onduty then
                TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'On duty olmadan gorev alamazsin.')
                return
            end

            local jobCfg = Config.Jobs[playerResolvedJob]
            if not hasPermission(src, jobCfg or {}) then
                TriggerClientEvent('umt_meslekler:client:MissionDenied', src, Config.Locale.no_permission)
                return
            end

            pending.claimedBy = src
            local mission = buildMission(src, playerResolvedJob, jobCfg)
            if not mission then
                pending.claimedBy = nil
                TriggerClientEvent('umt_meslekler:client:MissionDenied', src, 'Gorev olusturulamadi, config kontrol et.')
                return
            end
            mission.id = offerId
            mission.groupId = group.Id
            mission.allowedJobs = group.Jobs or {}
            mission.shared = true

            ActiveMissions[src] = mission
            PendingGroupMissions[group.Id] = nil

            local targets = getOnlineSourcesWithJobs(group.Jobs or {}, false)
            for t = 1, #targets do
                local targetSrc = targets[t]
                if targetSrc == src then
                    TriggerClientEvent('umt_meslekler:client:MissionOfferClosed', targetSrc, 'accepted')
                    TriggerClientEvent('umt_meslekler:client:MissionAssigned', targetSrc, mission.clientData)
                else
                    TriggerClientEvent('umt_meslekler:client:MissionOfferClosed', targetSrc, 'taken')
                end
            end
            return
        end
    end

    TriggerClientEvent('umt_meslekler:client:MissionOfferClosed', src, 'expired')
end)

RegisterNetEvent('umt_meslekler:server:CompleteMission', function(missionId)
    local src = source
    local player = getPlayer(src)
    local mission = ActiveMissions[src]
    if not player or not mission then
        return
    end

    if mission.id ~= missionId then
        return
    end

    if FrameworkBackend ~= 'standalone' then
        local pJob = getPlayerJob(player)
        local resolvedJobName = resolveJobConfigName(pJob.name) or (pJob.name or '')
        if not canJobCompleteMission(resolvedJobName, mission) then
            ActiveMissions[src] = nil
            return
        end
    end

    local reward = mission.reward or {}
    local success = false

    if reward.type == 'item' then
        success = addItemReward(src, player, reward.item, reward.count or 1)
    else
        success = addMoneyReward(src, player, reward.account, reward.amount or 0)
    end

    if not success then
        debugLog(('Reward failed for src %s'):format(src))
    end

    ActiveMissions[src] = nil
    TriggerClientEvent('umt_meslekler:client:MissionRewarded', src, reward)
end)

AddEventHandler('playerDropped', function()
    ActiveMissions[source] = nil
end)
