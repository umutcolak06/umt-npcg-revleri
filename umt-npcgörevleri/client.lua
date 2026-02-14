local QBCore = nil
local ESX = nil

local FrameworkBackend = 'standalone'
local TargetBackend = 'none'
local NotifyBackend = 'native'
local ProgressBackend = 'native'
local KeysBackend = 'none'

local PlayerData = { job = { name = nil, onduty = true } }
local CurrentMission = nil
local NextMissionAt = 0
local PendingMissionOffer = nil

local FallbackWarningShown = false

local function debugLog(msg)
    if Config.Debug then
        print(('[umt-meslekler] %s'):format(msg))
    end
end

local function chooseRandom(list)
    if not list or #list == 0 then
        return nil
    end
    return list[math.random(1, #list)]
end

local function getLocationLabelFromCoords(coords)
    if not coords then
        return 'Bilinmeyen konum'
    end

    local streetHash = 0
    local crossingHash = 0
    streetHash, crossingHash = GetStreetNameAtCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)

    local streetName = ''
    local crossingName = ''
    if streetHash and streetHash ~= 0 then
        streetName = GetStreetNameFromHashKey(streetHash) or ''
    end
    if crossingHash and crossingHash ~= 0 then
        crossingName = GetStreetNameFromHashKey(crossingHash) or ''
    end

    local zoneCode = GetNameOfZone(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    local zoneLabel = GetLabelText(zoneCode)
    if not zoneLabel or zoneLabel == 'NULL' then
        zoneLabel = zoneCode or ''
    end

    local road = streetName
    if crossingName ~= '' then
        road = ('%s / %s'):format(streetName, crossingName)
    end

    if road ~= '' and zoneLabel ~= '' then
        return ('%s, %s'):format(road, zoneLabel)
    end
    if road ~= '' then
        return road
    end
    if zoneLabel ~= '' then
        return zoneLabel
    end
    return 'Bilinmeyen konum'
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

local function detectTargetBackend()
    local function isBackendReady(backend)
        if backend == 'ox_target' then
            return GetResourceState('ox_target') == 'started'
        end
        if backend == 'qb-target' then
            return GetResourceState('qb-target') == 'started'
        end
        if backend == 'qtarget' then
            return GetResourceState('qtarget') == 'started'
        end
        return false
    end

    local preferred = (Config.TargetBackend or 'auto'):lower()
    if preferred ~= 'auto' then
        if isBackendReady(preferred) then
            TargetBackend = preferred
        else
            TargetBackend = 'none'
        end
    elseif isBackendReady('ox_target') then
        TargetBackend = 'ox_target'
    elseif isBackendReady('qb-target') then
        TargetBackend = 'qb-target'
    elseif isBackendReady('qtarget') then
        TargetBackend = 'qtarget'
    else
        TargetBackend = 'none'
    end
end

local function detectNotifyBackend()
    local preferred = (Config.NotifyBackend or 'auto'):lower()
    if preferred ~= 'auto' then
        NotifyBackend = preferred
        return
    end

    if FrameworkBackend == 'qb' then
        NotifyBackend = 'qb'
    elseif FrameworkBackend == 'esx' then
        NotifyBackend = 'esx'
    elseif GetResourceState('ox_lib') == 'started' then
        NotifyBackend = 'ox'
    else
        NotifyBackend = 'native'
    end
end

local function detectProgressBackend()
    local preferred = (Config.ProgressBackend or 'auto'):lower()
    if preferred ~= 'auto' then
        ProgressBackend = preferred
        return
    end

    if FrameworkBackend == 'qb' then
        ProgressBackend = 'qb'
    elseif GetResourceState('ox_lib') == 'started' then
        ProgressBackend = 'ox'
    else
        ProgressBackend = 'native'
    end
end

local function detectKeysBackend()
    if not Config.VehicleKeys or Config.VehicleKeys.Enabled == false then
        KeysBackend = 'none'
        return
    end

    local preferred = (Config.VehicleKeys.Backend or 'auto'):lower()
    if preferred ~= 'auto' then
        KeysBackend = preferred
        return
    end

    if GetResourceState('qb-vehiclekeys') == 'started' then
        KeysBackend = 'qb'
    elseif GetResourceState('qs-vehiclekeys') == 'started' then
        KeysBackend = 'qs'
    elseif Config.VehicleKeys.CustomEvent and Config.VehicleKeys.CustomEvent ~= '' then
        KeysBackend = 'custom'
    else
        KeysBackend = 'none'
    end
end

local function notify(msg, msgType)
    local nType = msgType or 'primary'

    if NotifyBackend == 'qb' and QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(msg, nType)
        return
    end

    if NotifyBackend == 'esx' and ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
        return
    end

    if NotifyBackend == 'ox' and lib and lib.notify then
        local oxType = nType
        if oxType == 'primary' then
            oxType = 'inform'
        end
        lib.notify({ description = msg, type = oxType })
        return
    end

    BeginTextCommandPrint('STRING')
    AddTextComponentString(msg)
    EndTextCommandPrint(3500, 1)
end

local function playProgress(label, duration)
    if ProgressBackend == 'qb' and QBCore and QBCore.Functions and QBCore.Functions.Progressbar then
        local state = nil
        QBCore.Functions.Progressbar('umt_meslek_progress', label, duration, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableCombat = true,
        }, {}, {}, {}, function()
            state = true
        end, function()
            state = false
        end)

        while state == nil do
            Wait(100)
        end
        return state == true
    end

    if ProgressBackend == 'ox' and lib and lib.progressBar then
        return lib.progressBar({
            duration = duration,
            label = label,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
            }
        }) == true
    end

    Wait(duration)
    return true
end

local function normalizeJob(job)
    if not job then
        return { name = nil, onduty = true }
    end

    local onduty = true
    if job.onduty ~= nil then
        onduty = job.onduty == true
    elseif job.onDuty ~= nil then
        onduty = job.onDuty == true
    end

    return {
        name = job.name,
        onduty = onduty,
    }
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

local function refreshPlayerData()
    if FrameworkBackend == 'qb' and QBCore and QBCore.Functions then
        local pd = QBCore.Functions.GetPlayerData()
        if pd and pd.job then
            PlayerData.job = normalizeJob(pd.job)
        end
    elseif FrameworkBackend == 'esx' and ESX and ESX.GetPlayerData then
        local pd = ESX.GetPlayerData()
        if pd and pd.job then
            PlayerData.job = normalizeJob(pd.job)
        end
    end
end

local function getCurrentJobName()
    local rawName = PlayerData.job and PlayerData.job.name or nil
    return resolveJobConfigName(rawName)
end

local function ensurePlayerData()
    if FrameworkBackend == 'standalone' then
        return
    end

    if not PlayerData.job or not PlayerData.job.name then
        refreshPlayerData()
    end
end

local function setNextMission(jobName)
    local resolvedJobName = resolveJobConfigName(jobName)
    local jobCfg = resolvedJobName and Config.Jobs[resolvedJobName] or nil
    if not jobCfg then
        NextMissionAt = 0
        return
    end

    local intervals = jobCfg.IntervalMinutes or { 5, 10 }
    local minMinutes = intervals[1] or 5
    local maxMinutes = intervals[2] or minMinutes
    local randomMinutes = math.random(minMinutes, maxMinutes)
    NextMissionAt = GetGameTimer() + (randomMinutes * 60 * 1000)
end
    
local function clearPendingOffer()
    PendingMissionOffer = nil
end

local function hasValidPendingOffer()
    if not PendingMissionOffer then
        return false
    end
    if GetGameTimer() >= (PendingMissionOffer.expiresAtGame or 0) then
        clearPendingOffer()
        notify(Config.Locale.mission_offer_expired, 'error')
        return false
    end
    return true
end

local function isJobAllowedForMission()
    local jobName = getCurrentJobName()
    if not jobName or not Config.Jobs[jobName] then
        return false
    end
    if not Config.RequireDuty then
        return true
    end
    return PlayerData.job.onduty == true
end

local function makeBlip(coords, sprite, color, name)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.9)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, color)
    return blip
end

local function loadModel(model)
    local modelHash = type(model) == 'number' and model or joaat(model)
    if not IsModelValid(modelHash) then
        return nil
    end

    RequestModel(modelHash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) do
        Wait(10)
        if GetGameTimer() > timeout then
            return nil
        end
    end
    return modelHash
end

local function trim(text)
    if not text then
        return ''
    end
    return (text:gsub('^%s*(.-)%s*$', '%1'))
end

local function giveMissionVehicleKeys(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    if not Config.VehicleKeys or Config.VehicleKeys.Enabled == false then
        return
    end

    local plate = trim(GetVehicleNumberPlateText(vehicle))

    if KeysBackend == 'qb' then
        local ev = Config.VehicleKeys.QbEvent or 'vehiclekeys:client:SetOwner'
        TriggerEvent(ev, plate)
        notify(Config.Locale.mechanic_key_given, 'success')
        return
    end

    if KeysBackend == 'qs' then
        local ev = Config.VehicleKeys.QsEvent or 'qs-vehiclekeys:client:AddKeys'
        TriggerEvent(ev, plate)
        notify(Config.Locale.mechanic_key_given, 'success')
        return
    end

    if KeysBackend == 'custom' and Config.VehicleKeys.CustomEvent and Config.VehicleKeys.CustomEvent ~= '' then
        TriggerEvent(Config.VehicleKeys.CustomEvent, vehicle, plate)
        notify(Config.Locale.mechanic_key_given, 'success')
        return
    end

    debugLog('Vehicle keys backend not found or disabled.')
end

local function addTargetEntity(entity, options, distance)
    local targetDistance = distance or 2.0

    if TargetBackend == 'none' then
        if not FallbackWarningShown then
            notify(Config.Locale.target_missing, 'error')
            FallbackWarningShown = true
        end
        return nil
    end

    if TargetBackend == 'qb-target' or TargetBackend == 'qtarget' then
        exports[TargetBackend]:AddTargetEntity(entity, {
            options = options,
            distance = targetDistance
        })

        local labels = {}
        for i = 1, #options do
            labels[#labels + 1] = options[i].label
        end

        return {
            backend = TargetBackend,
            labels = labels
        }
    end

    if TargetBackend == 'ox_target' then
        local names = {}
        local oxOptions = {}

        for i = 1, #options do
            local opt = options[i]
            local optionName = ('lm_%s_%s_%s'):format(entity, i, math.random(1000, 9999))
            names[#names + 1] = optionName
            oxOptions[#oxOptions + 1] = {
                name = optionName,
                label = opt.label,
                icon = opt.icon,
                distance = targetDistance,
                canInteract = function(ent, dist, coords)
                    if not opt.canInteract then
                        return true
                    end
                    return opt.canInteract(ent, dist, coords)
                end,
                onSelect = function(data)
                    opt.action(data)
                end
            }
        end

        exports.ox_target:addLocalEntity(entity, oxOptions)
        return {
            backend = 'ox_target',
            names = names,
        }
    end
    return nil
end

local function removeTargetEntity(entity, handle)
    if not handle then
        return
    end

    if handle.backend == 'qb-target' or handle.backend == 'qtarget' then
        pcall(function()
            exports[handle.backend]:RemoveTargetEntity(entity, handle.labels or {})
        end)
        return
    end

    if handle.backend == 'ox_target' then
        pcall(function()
            exports.ox_target:removeLocalEntity(entity, handle.names or {})
        end)
        return
    end
end

local function cleanupMission()
    if not CurrentMission then
        return
    end

    if CurrentMission.blip and DoesBlipExist(CurrentMission.blip) then
        RemoveBlip(CurrentMission.blip)
    end

    if CurrentMission.ped and DoesEntityExist(CurrentMission.ped) then
        removeTargetEntity(CurrentMission.ped, CurrentMission.pedTargetHandle)
        DeleteEntity(CurrentMission.ped)
    end

    if CurrentMission.vehicle and DoesEntityExist(CurrentMission.vehicle) then
        removeTargetEntity(CurrentMission.vehicle, CurrentMission.vehicleTargetHandle)
        DeleteEntity(CurrentMission.vehicle)
    end

    if CurrentMission.dispatcher and DoesEntityExist(CurrentMission.dispatcher) then
        removeTargetEntity(CurrentMission.dispatcher, CurrentMission.dispatcherTargetHandle)
        DeleteEntity(CurrentMission.dispatcher)
    end

    if CurrentMission.deliveryPed and DoesEntityExist(CurrentMission.deliveryPed) then
        removeTargetEntity(CurrentMission.deliveryPed, CurrentMission.deliveryPedTargetHandle)
        DeleteEntity(CurrentMission.deliveryPed)
    end

    CurrentMission = nil
end

local function completeMission()
    if not CurrentMission then
        return
    end

    local missionPed = CurrentMission.ped
    local missionPedHandle = CurrentMission.pedTargetHandle
    local missionVehicle = CurrentMission.vehicle
    local missionVehicleHandle = CurrentMission.vehicleTargetHandle
    local missionType = CurrentMission.type

    if missionPed and DoesEntityExist(missionPed) then
        removeTargetEntity(missionPed, missionPedHandle)
        CurrentMission.ped = nil
        CurrentMission.pedTargetHandle = nil

        SetTimeout((Config.DespawnSeconds or 5) * 1000, function()
            if DoesEntityExist(missionPed) then
                DeleteEntity(missionPed)
            end
        end)
    end

    if missionType == 'mechanic' and missionVehicle and DoesEntityExist(missionVehicle) then
        removeTargetEntity(missionVehicle, missionVehicleHandle)
        CurrentMission.vehicle = nil
        CurrentMission.vehicleTargetHandle = nil

        SetTimeout((Config.DespawnSeconds or 5) * 1000, function()
            if DoesEntityExist(missionVehicle) then
                DeleteEntity(missionVehicle)
            end
        end)
    end

    TriggerServerEvent('umt_meslekler:server:CompleteMission', CurrentMission.id)
    cleanupMission()
    setNextMission(getCurrentJobName())
end

local function sendDispatch(title, message, coords)
    if not Config.Dispatch.Enabled then
        return
    end

    TriggerEvent(Config.Dispatch.ClientEvent, {
        title = title,
        message = message,
        coords = coords
    })
end

local function playDoctorConversation(jobCfg, missionData)
    local dlg = (jobCfg and jobCfg.DoctorDialogue) or {}
    local patientInfo = missionData.patientInfo or {}
    local where = getLocationLabelFromCoords(vector3(missionData.coords.x, missionData.coords.y, missionData.coords.z))
    local patientName = patientInfo.name or 'Vatandas'
    local age = patientInfo.age or 30
    local bodyPart = patientInfo.bodyPart or 'Bacagim'
    local incident = patientInfo.incident or 'yaralandim'
    local symptom = patientInfo.symptom or 'kendimi kotu hissediyorum'
    local severity = patientInfo.severity or 'orta'

    local openingTemplate = chooseRandom(dlg.Openings) or 'Doktor, ben %s. Yardim et.'
    local anxiety = chooseRandom(dlg.Anxiety) or 'Lutfen beni kurtar.'
    local doctorReply = chooseRandom(dlg.DoctorReplies) or 'Sakin ol, tedaviye basliyorum.'
    local closing = chooseRandom(dlg.Closings) or 'Tesekkur ederim doktor.'
    local opening = openingTemplate:format(patientName)

    notify(opening, 'primary')
    Wait(850)
    notify(Config.Locale.doctor_patient_info:format(patientName, age, bodyPart, incident, where), 'primary')
    Wait(850)
    notify(Config.Locale.doctor_symptom_info:format(severity, symptom), 'primary')
    Wait(850)
    notify(anxiety, 'primary')
    Wait(700)
    notify(('Doktor: %s'):format(doctorReply), 'success')

    return closing
end

local function startDoctorMission(missionData)
    local jobCfg = Config.Jobs[missionData.jobName]
    if not jobCfg then
        return
    end
    if not missionData.coords then
        notify('Doktor gorevi config hatasi: koordinat eksik.', 'error')
        return
    end

    local model = loadModel(chooseRandom(jobCfg.PedModels))
    if not model then
        notify('NPC modeli yuklenemedi.', 'error')
        return
    end

    local ped = CreatePed(4, model, missionData.coords.x, missionData.coords.y, missionData.coords.z - 1.0, missionData.coords.w, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_SUNBATHE_BACK', 0, true)

    local pedTargetHandle = addTargetEntity(ped, {
        {
            label = Config.Locale.doctor_target,
            icon = 'fas fa-kit-medical',
            action = function()
                local closingLine = playDoctorConversation(jobCfg, missionData)
                local ok = playProgress('Tedavi uygulaniyor...', 7000)
                if ok then
                    notify(closingLine, 'success')
                    completeMission()
                else
                    notify(Config.Locale.mission_cancel, 'error')
                end
            end
        }
    }, 2.0)

    CurrentMission = {
        id = missionData.id,
        jobName = missionData.jobName,
        type = 'doctor',
        ped = ped,
        pedTargetHandle = pedTargetHandle,
        coords = vector3(missionData.coords.x, missionData.coords.y, missionData.coords.z),
        blip = makeBlip(vector3(missionData.coords.x, missionData.coords.y, missionData.coords.z), 153, 2, 'Yarali Vatandas'),
    }

    sendDispatch('EMS Cagri', 'Sehirde yarali vatandas var.', missionData.coords)
end

local function startPoliceMission(missionData)
    local jobCfg = Config.Jobs[missionData.jobName]
    if not jobCfg then
        return
    end
    if not missionData.coords then
        notify('Polis gorevi config hatasi: koordinat eksik.', 'error')
        return
    end
    local dispatchInfo = missionData.dispatchInfo or {}

    local pedModel = loadModel(chooseRandom(jobCfg.PedModels))
    if not pedModel then
        notify('Supheli modeli yuklenemedi.', 'error')
        return
    end

    local ped = CreatePed(4, pedModel, missionData.coords.x, missionData.coords.y, missionData.coords.z, missionData.coords.w, true, true)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedCanRagdoll(ped, true)

    local vehicle = nil
    local behaviorState = 'active'
    local hasBeenSearched = false

    local function setAsSurrendered()
        if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then
            return
        end

        if IsPedInAnyVehicle(ped, false) then
            local pedVeh = GetVehiclePedIsIn(ped, false)
            TaskLeaveVehicle(ped, pedVeh, 256)
            SetTimeout(1300, function()
                if DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
                    ClearPedTasks(ped)
                    TaskHandsUp(ped, -1, PlayerPedId(), -1, true)
                end
            end)
        else
            ClearPedTasks(ped)
            TaskHandsUp(ped, -1, PlayerPedId(), -1, true)
        end

        behaviorState = 'surrendered'
        notify(Config.Locale.police_surrendered, 'success')
    end

    local function runOnFoot()
        if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then
            return
        end

        if IsPedInAnyVehicle(ped, false) then
            local pedVeh = GetVehiclePedIsIn(ped, false)
            TaskLeaveVehicle(ped, pedVeh, 256)
            SetTimeout(1200, function()
                if DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
                    TaskSmartFleePed(ped, PlayerPedId(), 180.0, -1, false, false)
                end
            end)
        else
            TaskSmartFleePed(ped, PlayerPedId(), 180.0, -1, false, false)
        end

        behaviorState = 'fleeing'
        notify(Config.Locale.police_fleeing, 'error')
    end

    local function attackOfficer()
        if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then
            return
        end

        if IsPedInAnyVehicle(ped, false) then
            local pedVeh = GetVehiclePedIsIn(ped, false)
            TaskLeaveVehicle(ped, pedVeh, 256)
            SetTimeout(1200, function()
                if DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
                    GiveWeaponToPed(ped, joaat('WEAPON_KNIFE'), 1, false, true)
                    TaskCombatPed(ped, PlayerPedId(), 0, 16)
                end
            end)
        else
            GiveWeaponToPed(ped, joaat('WEAPON_KNIFE'), 1, false, true)
            TaskCombatPed(ped, PlayerPedId(), 0, 16)
        end

        behaviorState = 'aggressive'
        notify(Config.Locale.police_attack, 'error')
    end

    if missionData.subtype == 'stolen_vehicle' then
        local vehModel = loadModel(chooseRandom(jobCfg.Vehicles))
        if vehModel then
            vehicle = CreateVehicle(vehModel, missionData.coords.x + 2.0, missionData.coords.y + 2.0, missionData.coords.z, missionData.coords.w, true, false)
            SetVehicleEngineOn(vehicle, true, true, false)
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
            TaskVehicleDriveWander(ped, vehicle, 28.0, 786603)
        end
    elseif missionData.subtype == 'murder_suspect' then
        GiveWeaponToPed(ped, joaat('WEAPON_KNIFE'), 1, false, true)
        TaskWanderStandard(ped, 10.0, 10)
    else
        TaskWanderStandard(ped, 10.0, 10)
    end

    local pedTargetHandle = addTargetEntity(ped, {
        {
            label = Config.Locale.police_cuff,
            icon = 'fas fa-handcuffs',
            canInteract = function(entity)
                return not IsPedDeadOrDying(entity, true) and not IsPedInAnyVehicle(entity, false)
            end,
            action = function()
                if IsPedInAnyVehicle(ped, false) then
                    notify(Config.Locale.police_exit_vehicle_first, 'error')
                    return
                end
                local ok = playProgress('Kelepce takiliyor...', 5000)
                if ok then
                    ClearPedTasksImmediately(ped)
                    TaskHandsUp(ped, -1, PlayerPedId(), -1, true)
                    FreezeEntityPosition(ped, true)
                    behaviorState = 'detained'
                    notify(Config.Locale.police_detained, 'success')
                else
                    notify(Config.Locale.mission_cancel, 'error')
                end
            end
        },
        {
            label = Config.Locale.police_warn,
            icon = 'fas fa-bullhorn',
            canInteract = function(entity)
                return not IsPedDeadOrDying(entity, true) and behaviorState ~= 'detained'
            end,
            action = function()
                if dispatchInfo.suspectLine then
                    notify(Config.Locale.police_suspect_quote:format(dispatchInfo.suspectLine), 'primary')
                end
                local ok = playProgress('Supheliye uyari veriliyor...', 3500)
                if not ok then
                    notify(Config.Locale.mission_cancel, 'error')
                    return
                end

                if behaviorState == 'surrendered' or behaviorState == 'detained' then
                    notify(Config.Locale.police_already_stopped, 'primary')
                    return
                end

                local roll = math.random(1, 100)
                if missionData.subtype == 'stolen_vehicle' then
                    if roll <= 70 then
                        behaviorState = 'fleeing'
                        if vehicle and DoesEntityExist(vehicle) and IsPedInVehicle(ped, vehicle, false) then
                            TaskVehicleDriveWander(ped, vehicle, 48.0, 786603)
                            notify(Config.Locale.police_fleeing_vehicle, 'error')
                        else
                            runOnFoot()
                        end
                    elseif roll <= 90 then
                        runOnFoot()
                    else
                        setAsSurrendered()
                    end
                elseif missionData.subtype == 'murder_suspect' then
                    if roll <= 40 then
                        attackOfficer()
                    elseif roll <= 75 then
                        runOnFoot()
                    else
                        setAsSurrendered()
                    end
                else
                    if roll <= 55 then
                        runOnFoot()
                    elseif roll <= 70 then
                        attackOfficer()
                    else
                        setAsSurrendered()
                    end
                end
            end
        },
        {
            label = Config.Locale.police_search,
            icon = 'fas fa-magnifying-glass',
            canInteract = function(entity)
                if IsPedDeadOrDying(entity, true) then
                    return false
                end
                return behaviorState == 'detained' and not hasBeenSearched
            end,
            action = function()
                if behaviorState ~= 'detained' then
                    notify(Config.Locale.police_search_need_detain, 'error')
                    return
                end
                local ok = playProgress(Config.Locale.police_search_progress, 4500)
                if not ok then
                    notify(Config.Locale.mission_cancel, 'error')
                    return
                end

                hasBeenSearched = true
                notify(Config.Locale.police_search_done, 'success')
            end
        },
        {
            label = Config.Locale.police_send_jail,
            icon = 'fas fa-building-shield',
            canInteract = function(entity)
                if IsPedDeadOrDying(entity, true) then
                    return false
                end
                return behaviorState == 'detained'
            end,
            action = function()
                if behaviorState ~= 'detained' then
                    notify(Config.Locale.police_search_need_detain, 'error')
                    return
                end
                if not hasBeenSearched then
                    notify(Config.Locale.police_search_first, 'error')
                    return
                end

                local ok = playProgress(Config.Locale.police_jail_progress, 4500)
                if not ok then
                    notify(Config.Locale.mission_cancel, 'error')
                    return
                end

                local pp = Config.PolicePunishment or {}
                if pp.TriggerEvents and pp.JailEvent and pp.JailEvent ~= '' then
                    TriggerEvent(pp.JailEvent, {
                        minutes = pp.JailMinutes or 20,
                        missionId = missionData.id,
                        suspectName = dispatchInfo.suspectName,
                        subtype = missionData.subtype,
                    })
                end

                notify(Config.Locale.police_jail_done, 'success')
                completeMission()
            end
        },
        {
            label = Config.Locale.police_send_community,
            icon = 'fas fa-people-carry-box',
            canInteract = function(entity)
                if IsPedDeadOrDying(entity, true) then
                    return false
                end
                return behaviorState == 'detained'
            end,
            action = function()
                if behaviorState ~= 'detained' then
                    notify(Config.Locale.police_search_need_detain, 'error')
                    return
                end
                if not hasBeenSearched then
                    notify(Config.Locale.police_search_first, 'error')
                    return
                end

                local ok = playProgress(Config.Locale.police_community_progress, 4500)
                if not ok then
                    notify(Config.Locale.mission_cancel, 'error')
                    return
                end

                local pp = Config.PolicePunishment or {}
                if pp.TriggerEvents and pp.CommunityEvent and pp.CommunityEvent ~= '' then
                    TriggerEvent(pp.CommunityEvent, {
                        minutes = pp.CommunityMinutes or 30,
                        missionId = missionData.id,
                        suspectName = dispatchInfo.suspectName,
                        subtype = missionData.subtype,
                    })
                end

                notify(Config.Locale.police_community_done, 'success')
                completeMission()
            end
        },
        {
            label = Config.Locale.police_neutralize,
            icon = 'fas fa-skull',
            canInteract = function(entity)
                return IsPedDeadOrDying(entity, true)
            end,
            action = function()
                if not IsPedDeadOrDying(ped, true) then
                    notify(Config.Locale.police_dead_required, 'error')
                    return
                end
                completeMission()
            end
        }
    }, 2.0)

    local blip = AddBlipForEntity(ped)
    SetBlipSprite(blip, 60)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.9)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Polis Ihbari')
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)

    CurrentMission = {
        id = missionData.id,
        jobName = missionData.jobName,
        type = 'police',
        subtype = missionData.subtype,
        ped = ped,
        vehicle = vehicle,
        pedTargetHandle = pedTargetHandle,
        blip = blip,
    }

    if dispatchInfo.callerName and dispatchInfo.witnessLine then
        notify(Config.Locale.police_dispatch_info:format(dispatchInfo.callerName, dispatchInfo.witnessLine), 'primary')
    end
    if dispatchInfo.suspectName then
        notify(Config.Locale.police_suspect_info:format(dispatchInfo.suspectName, missionData.message or 'Ihbar aktif'), 'error')
    end

    CreateThread(function()
        while CurrentMission and CurrentMission.type == 'police' and CurrentMission.id == missionData.id do
            Wait(1200)
            if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then
                return
            end

            local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped))
            if behaviorState == 'active' and dist < 14.0 then
                if math.random(1, 100) <= 18 then
                    runOnFoot()
                end
            end

            if behaviorState == 'fleeing' and dist > 180.0 then
                notify(Config.Locale.police_lost_suspect, 'error')
                cleanupMission()
                setNextMission(getCurrentJobName())
                return
            end
        end
    end)

    sendDispatch('Polis Ihbari', missionData.message, missionData.coords)
end

local function startFoodMission(missionData)
    local jobCfg = Config.Jobs[missionData.jobName]
    if not jobCfg then
        return
    end
    local foodInfo = missionData.foodInfo or {}
    if not jobCfg.Dispatcher then
        notify('Food gorevi config hatasi: Dispatcher eksik.', 'error')
        return
    end
    if not missionData.delivery then
        notify('Food gorevi config hatasi: delivery koordinati eksik.', 'error')
        return
    end

    local dispatcherModel = loadModel(jobCfg.DispatcherModel or 's_m_m_linecook')
    if not dispatcherModel then
        notify('Gorev NPC yuklenemedi.', 'error')
        return
    end

    local dispatcher = CreatePed(4, dispatcherModel, jobCfg.Dispatcher.x, jobCfg.Dispatcher.y, jobCfg.Dispatcher.z - 1.0, jobCfg.Dispatcher.w, true, true)
    SetEntityInvincible(dispatcher, true)
    FreezeEntityPosition(dispatcher, true)
    SetBlockingOfNonTemporaryEvents(dispatcher, true)
    TaskStartScenarioInPlace(dispatcher, 'WORLD_HUMAN_CLIPBOARD', 0, true)

    local deliveryCoords = vector3(missionData.delivery.x, missionData.delivery.y, missionData.delivery.z)
    local pickupCoords = vector3(jobCfg.Dispatcher.x, jobCfg.Dispatcher.y, jobCfg.Dispatcher.z)

    local dispatcherTargetHandle = addTargetEntity(dispatcher, {
        {
            label = Config.Locale.food_talk,
            icon = 'fas fa-burger',
            action = function()
                if not CurrentMission or CurrentMission.stage ~= 'pickup' then
                    return
                end

                if foodInfo.pickupLine then
                    notify(Config.Locale.food_pickup_info:format(foodInfo.pickupLine), 'primary')
                end
                if foodInfo.orderLine and foodInfo.customerName then
                    notify(Config.Locale.food_order_info:format(foodInfo.orderLine, foodInfo.customerName), 'primary')
                end

                local ok = playProgress(Config.Locale.food_collect, 4500)
                if not ok then
                    notify(Config.Locale.mission_cancel, 'error')
                    return
                end

                if CurrentMission.blip and DoesBlipExist(CurrentMission.blip) then
                    RemoveBlip(CurrentMission.blip)
                end

                local bikeModel = loadModel(jobCfg.DeliveryVehicle)
                if bikeModel then
                    local spawnPos = vector4(jobCfg.Dispatcher.x + 1.5, jobCfg.Dispatcher.y - 1.5, jobCfg.Dispatcher.z, jobCfg.Dispatcher.w)
                    CurrentMission.vehicle = CreateVehicle(bikeModel, spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w, true, false)
                    SetVehicleEngineOn(CurrentMission.vehicle, true, true, false)
                end

                CurrentMission.stage = 'deliver'
                CurrentMission.blip = makeBlip(deliveryCoords, 1, 5, 'Teslimat')

                local customerModel = loadModel('a_m_y_business_03')
                if customerModel then
                    local deliveryPed = CreatePed(4, customerModel, deliveryCoords.x, deliveryCoords.y, deliveryCoords.z - 1.0, 0.0, true, true)
                    SetEntityInvincible(deliveryPed, true)
                    FreezeEntityPosition(deliveryPed, true)
                    SetBlockingOfNonTemporaryEvents(deliveryPed, true)
                    TaskStartScenarioInPlace(deliveryPed, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)

                    local dropoffLabel = jobCfg.DropoffText or '[Teslim Et]'
                    local deliveryPedHandle = addTargetEntity(deliveryPed, {
                        {
                            label = dropoffLabel,
                            icon = 'fas fa-box',
                            action = function()
                                if not CurrentMission or CurrentMission.stage ~= 'deliver' then
                                    return
                                end
                                local delivered = playProgress(Config.Locale.food_deliver, 3500)
                                if not delivered then
                                    notify(Config.Locale.mission_cancel, 'error')
                                    return
                                end
                                if CurrentMission.customerName and CurrentMission.deliveryLine then
                                    notify(Config.Locale.food_delivery_thanks:format(CurrentMission.customerName, CurrentMission.deliveryLine), 'success')
                                end
                                completeMission()
                            end
                        }
                    }, 2.0)

                    CurrentMission.deliveryPed = deliveryPed
                    CurrentMission.deliveryPedTargetHandle = deliveryPedHandle
                else
                    notify('Teslimat NPC modeli yuklenemedi. Gorev iptal edildi.', 'error')
                    cleanupMission()
                    setNextMission(getCurrentJobName())
                    return
                end

                notify('Teslimat noktasinda musteriyi target ile secip siparisi ver.', 'success')
            end
        }
    }, 2.0)

    CurrentMission = {
        id = missionData.id,
        jobName = missionData.jobName,
        type = 'food',
        stage = 'pickup',
        dispatcher = dispatcher,
        dispatcherTargetHandle = dispatcherTargetHandle,
        pickupCoords = pickupCoords,
        deliveryCoords = deliveryCoords,
        blip = makeBlip(pickupCoords, 267, 47, 'Siparis Hazirlama'),
        customerName = foodInfo.customerName,
        deliveryLine = foodInfo.deliveryLine,
    }

    sendDispatch('Restoran Siparisi', 'Yeni siparis geldi.', jobCfg.Dispatcher)
end

local function startMechanicMission(missionData)
    local jobCfg = Config.Jobs[missionData.jobName]
    if not jobCfg then
        return
    end
    if not missionData.coords then
        notify('Mechanic gorevi config hatasi: koordinat eksik.', 'error')
        return
    end
    local mechInfo = missionData.mechanicInfo or {}

    local vehModel = loadModel(missionData.vehicleModel)
    if not vehModel then
        notify('Gorev araci yuklenemedi.', 'error')
        return
    end

    local vehicle = CreateVehicle(vehModel, missionData.coords.x, missionData.coords.y, missionData.coords.z, missionData.coords.w, true, false)
    SetVehicleEngineOn(vehicle, false, true, false)
    SetVehicleEngineHealth(vehicle, 180.0)
    SetVehicleBodyHealth(vehicle, 350.0)
    SetVehiclePetrolTankHealth(vehicle, 300.0)
    SetVehicleUndriveable(vehicle, true)
    SetVehicleDirtLevel(vehicle, 15.0)

    local vehicleTargetHandle = addTargetEntity(vehicle, {
        {
            label = Config.Locale.mechanic_target,
            icon = 'fas fa-screwdriver-wrench',
            action = function()
                local ok = playProgress(Config.Locale.mechanic_progress, 8500)
                if not ok then
                    notify(Config.Locale.mission_cancel, 'error')
                    return
                end

                SetVehicleFixed(vehicle)
                SetVehicleEngineHealth(vehicle, 1000.0)
                SetVehicleBodyHealth(vehicle, 1000.0)
                SetVehiclePetrolTankHealth(vehicle, 1000.0)
                SetVehicleUndriveable(vehicle, false)
                if mechInfo.ownerName and mechInfo.thanksLine then
                    notify(Config.Locale.mechanic_thanks:format(mechInfo.ownerName, mechInfo.thanksLine), 'success')
                end
                completeMission()
            end
        }
    }, 3.0)

    giveMissionVehicleKeys(vehicle)

    CurrentMission = {
        id = missionData.id,
        jobName = missionData.jobName,
        type = 'mechanic',
        vehicle = vehicle,
        vehicleTargetHandle = vehicleTargetHandle,
        blip = makeBlip(vector3(missionData.coords.x, missionData.coords.y, missionData.coords.z), 446, 46, 'Ariza Araci'),
    }

    if mechInfo.issueLine and mechInfo.ownerName then
        notify(Config.Locale.mechanic_owner_info:format(mechInfo.ownerName, mechInfo.issueLine), 'primary')
    end
    if mechInfo.urgencyLine then
        notify(Config.Locale.mechanic_urgency_info:format(mechInfo.urgencyLine), 'error')
    end

    sendDispatch('Mekanik Cagrisi', 'Arizali arac tamir bekliyor.', missionData.coords)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    refreshPlayerData()
    setNextMission(getCurrentJobName())
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = normalizeJob(job)
    cleanupMission()
    setNextMission(job.name)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    if PlayerData.job then
        PlayerData.job.onduty = onDuty == true
    end
end)

RegisterNetEvent('esx:playerLoaded', function()
    refreshPlayerData()
    setNextMission(getCurrentJobName())
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = normalizeJob(job)
    cleanupMission()
    setNextMission(job.name)
end)

RegisterNetEvent('umt_meslekler:client:MissionOffered', function(offerData, expiresAtUnix)
    if TargetBackend == 'none' then
        return
    end

    if CurrentMission then
        return
    end

    local secondsLeft = math.max(1, (expiresAtUnix or os.time()) - os.time())
    PendingMissionOffer = {
        id = offerData.id,
        jobLabel = offerData.jobLabel or 'Ortak Gorev',
        expiresAtGame = GetGameTimer() + (secondsLeft * 1000),
    }

    notify(Config.Locale.mission_offer:format(PendingMissionOffer.jobLabel), 'primary')
end)

RegisterNetEvent('umt_meslekler:client:MissionOfferClosed', function(reason)
    if not PendingMissionOffer then
        return
    end

    clearPendingOffer()
    if reason == 'taken' then
        notify(Config.Locale.mission_offer_taken, 'error')
    elseif reason == 'accepted' then
        notify(Config.Locale.mission_offer_accepted, 'success')
    else
        notify(Config.Locale.mission_offer_expired, 'error')
    end
end)

RegisterNetEvent('umt_meslekler:client:MissionAssigned', function(missionData)
    clearPendingOffer()
    if CurrentMission then
        notify(Config.Locale.mission_active, 'error')
        return
    end

    if missionData.type == 'doctor' then
        startDoctorMission(missionData)
    elseif missionData.type == 'police' then
        startPoliceMission(missionData)
    elseif missionData.type == 'food' then
        startFoodMission(missionData)
    elseif missionData.type == 'mechanic' then
        startMechanicMission(missionData)
    end

    if missionData.jobLabel then
        notify(Config.Locale.mission_assigned:format(missionData.jobLabel), 'success')
    end
end)

RegisterCommand('iskabul', function()
    if TargetBackend == 'none' then
        notify(Config.Locale.target_missing, 'error')
        return
    end

    if not hasValidPendingOffer() then
        notify(Config.Locale.mission_no_offer, 'error')
        return
    end
    TriggerServerEvent('umt_meslekler:server:AcceptOfferedMission', PendingMissionOffer.id)
end, false)

RegisterNetEvent('umt_meslekler:client:MissionDenied', function(reason)
    notify(reason or Config.Locale.no_permission, 'error')
    setNextMission(getCurrentJobName())
end)

RegisterNetEvent('umt_meslekler:client:MissionRewarded', function(rewardData)
    if type(rewardData) ~= 'table' then
        notify(Config.Locale.mission_done:format(tostring(rewardData or 0)), 'success')
        return
    end

    if rewardData.type == 'item' then
        notify(Config.Locale.mission_done_item:format(rewardData.count or 1, rewardData.item or 'item'), 'success')
        return
    end

    notify(Config.Locale.mission_done:format(tostring(rewardData.amount or 0)), 'success')
end)

CreateThread(function()
    Wait(1000)
    detectFramework()
    detectTargetBackend()
    detectNotifyBackend()
    detectProgressBackend()
    detectKeysBackend()

    refreshPlayerData()
    setNextMission(getCurrentJobName())

    debugLog(Config.Locale.backend_detect:format(FrameworkBackend, TargetBackend, Config.InventoryBackend or 'auto', KeysBackend))
    if TargetBackend == 'none' then
        notify(Config.Locale.target_missing, 'error')
        FallbackWarningShown = true
    end

    while true do
        local now = GetGameTimer()
        local sleepMs = 5000

        if PendingMissionOffer then
            local msLeft = (PendingMissionOffer.expiresAtGame or 0) - now
            if msLeft <= 0 then
                hasValidPendingOffer()
            elseif msLeft < sleepMs then
                sleepMs = math.max(500, msLeft)
            end
        end

        if CurrentMission then
            sleepMs = 10000
        elseif TargetBackend == 'none' then
            sleepMs = 15000
        elseif NextMissionAt <= 0 then
            sleepMs = 10000
        else
            local untilMission = NextMissionAt - now
            if untilMission > 10000 then
                sleepMs = 10000
            elseif untilMission > 1000 then
                sleepMs = 1000
            else
                sleepMs = 500
            end
        end

        if TargetBackend ~= 'none' and isJobAllowedForMission() and not CurrentMission and NextMissionAt > 0 and now >= NextMissionAt then
            ensurePlayerData()
            local jobName = getCurrentJobName()
            if jobName then
                TriggerServerEvent('umt_meslekler:server:RequestMission', jobName)
                NextMissionAt = GetGameTimer() + 60000
            end
        end

        Wait(sleepMs)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    cleanupMission()
end)
