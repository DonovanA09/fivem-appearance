-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
ESX = exports["es_extended"]:getSharedObject()
local shops, savedOutfits = {}, {}

-- ESX Events
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    closeMenu()
end)

-- Appearance Events

RegisterNetEvent('fivem-appearance:skinCommand')
AddEventHandler('fivem-appearance:skinCommand', function()
	local config = {
		ped = true,
		headBlend = true,
		faceFeatures = true,
		headOverlays = true,
		components = true,
		props = true
	}
	exports['fivem-appearance']:startPlayerCustomization(function (appearance)
		if (appearance) then
			TriggerServerEvent('fivem-appearance:save', appearance)
			ESX.SetPlayerData('ped', PlayerPedId())
		else
			ESX.SetPlayerData('ped', PlayerPedId())
		end
	end, config)
end)

RegisterNetEvent('fivem-appearance:setOutfit')
AddEventHandler('fivem-appearance:setOutfit', function(data)
    -- Logic to set an outfit
    local pedModel = data.ped
    local pedComponents = data.components
    local pedProps = data.props
    local playerPed = PlayerPedId()
    local currentPedModel = GetEntityModel(playerPed)
    if currentPedModel ~= pedModel then
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Citizen.Wait(0)
        end
        SetPlayerModel(PlayerId(), pedModel)
        SetModelAsNoLongerNeeded(pedModel)
        playerPed = PlayerPedId()
        exports['fivem-appearance']:setPedComponents(playerPed, pedComponents)
        exports['fivem-appearance']:setPedProps(playerPed, pedProps)
        local appearance = exports['fivem-appearance']:getPedAppearance(playerPed)
        TriggerServerEvent('fivem-appearance:save', appearance)
        ESX.SetPlayerData('ped', playerPed)
        TriggerEvent('skinchanger:loadSkin', appearance)
        TriggerEvent('esx:showNotification', 'You have changed your appearance')
    else
        exports['fivem-appearance']:setPedComponents(playerPed, pedComponents)
        exports['fivem-appearance']:setPedProps(playerPed, pedProps)
        local appearance = exports['fivem-appearance']:getPedAppearance(playerPed)
        TriggerServerEvent('fivem-appearance:save', appearance)
        ESX.SetPlayerData('ped', playerPed)
        TriggerEvent('skinchanger:loadSkin', appearance)
        TriggerEvent('esx:showNotification', 'You have changed your appearance')
    end
end)

RegisterNetEvent('fivem-appearance:saveOutfit')
AddEventHandler('fivem-appearance:saveOutfit', function()
    local pedModel = GetEntityModel(PlayerPedId())
    local pedComponents = exports['fivem-appearance']:getPedComponents(PlayerPedId())
    local pedProps = exports['fivem-appearance']:getPedProps(PlayerPedId())
    ESX.UI.Menu.Open(
        'dialog',
        GetCurrentResourceName(),
        'save_outfit_menu',
        {
            title = 'Save Outfit',
        },
        function(data, menu)
            local outfitName = data.value
            if outfitName and outfitName ~= '' then
                TriggerServerEvent('fivem-appearance:saveOutfit', outfitName, pedModel, pedComponents, pedProps)
                menu.close()
                TriggerEvent('esx:showNotification', 'Outfit saved: ' .. outfitName)
            else
                TriggerEvent('esx:showNotification', 'Invalid outfit name')
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end)

RegisterNetEvent('fivem-appearance:browseOutfits')
AddEventHandler('fivem-appearance:browseOutfits', function()
    ESX.TriggerServerCallback('fivem-appearance:getOutfits', function(outfits)
        local elements = {}
        if outfits then
            for i = 1, #outfits do
                table.insert(elements, {
                    label = outfits[i].name,
                    value = outfits[i].id
                })
            end
        end

        ESX.UI.Menu.Open(
            'default',
            GetCurrentResourceName(),
            'browse_outfits_menu',
            {
                title = 'My Outfits',
                align = 'top-left',
                elements = elements
            },
            function(data, menu)
                local outfitId = data.current.value
                ESX.TriggerServerCallback('fivem-appearance:getOutfit', function(outfit)
                    if outfit then
                        TriggerEvent('fivem-appearance:setOutfit', outfit)
                    end
                end, outfitId)
            end,
            function(data, menu)
                menu.close()
            end
        )
    end)
end)

RegisterNetEvent('fivem-appearance:deleteOutfitMenu')
AddEventHandler('fivem-appearance:deleteOutfitMenu', function()
    ESX.TriggerServerCallback('fivem-appearance:getOutfits', function(outfits)
        local elements = {}
        if outfits then
            for i = 1, #outfits do
                table.insert(elements, {
                    label = outfits[i].name,
                    value = outfits[i].id
                })
            end
        end

        ESX.UI.Menu.Open(
            'default',
            GetCurrentResourceName(),
            'delete_outfit_menu',
            {
                title = 'Delete Outfit',
                align = 'top-left',
                elements = elements
            },
            function(data, menu)
                local outfitId = data.current.value
                ESX.UI.Menu.Open(
                    'default',
                    GetCurrentResourceName(),
                    'confirm_delete_outfit_menu',
                    {
                        title = 'Are you sure?',
                        align = 'top-left',
                        elements = {
                            { label = 'Yes', value = 'yes' },
                            { label = 'No', value = 'no' }
                        }
                    },
                    function(confirmData, confirmMenu)
                        if confirmData.current.value == 'yes' then
                            TriggerServerEvent('fivem-appearance:deleteOutfit', outfitId)
                            TriggerEvent('esx:showNotification', 'You have deleted the outfit')
                        end
                        confirmMenu.close()
                    end,
                    function(confirmData, confirmMenu)
                        confirmMenu.close()
                    end
                )
            end,
            function(data, menu)
                menu.close()
            end
        )
    end)
end)

AddEventHandler('fivem-appearance:clothingMenu', function(price)
    ESX.UI.Menu.CloseAll()
    openShop('clothing_menu', price)
end)

RegisterNetEvent('fivem-appearance:clothingShop', function(price)
    local elements = {
        {
            label = Strings.change_clothing_title,
            value = 'change_clothing',
        },
        {
            label = Strings.browse_outfits_title,
            value = 'browse_outfits',
        },
        {
            label = Strings.save_outfit_title,
            value = 'save_outfit',
        },
        {
            label = Strings.delete_outfit_title,
            value = 'delete_outfit',
        }
    }
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'clothing_menu',
    {
        title = Strings.clothing_shop_title,
        align = 'top-left',
        elements = elements
    },
    function(data, menu)
        if data.current.value == 'change_clothing' then
            TriggerEvent('fivem-appearance:clothingMenu', price)
        elseif data.current.value == 'browse_outfits' then
            TriggerEvent('fivem-appearance:browseOutfits')
        elseif data.current.value == 'save_outfit' then
            TriggerEvent('fivem-appearance:saveOutfit')
        elseif data.current.value == 'delete_outfit' then
            TriggerEvent('fivem-appearance:deleteOutfitMenu')
        end
    end,
    function(data, menu)
        menu.close()
    end)
end)


CreateThread(function()
    for i=1, #Config.ClothingShops do
        if Config.ClothingShops[i].blip.enabled then
            createBlip(Config.ClothingShops[i].coords, Config.ClothingShops[i].blip.sprite, Config.ClothingShops[i].blip.color, Config.ClothingShops[i].blip.string, Config.ClothingShops[i].blip.scale)
        end
    end
    for i=1, #Config.BarberShops do
        if Config.BarberShops[i].blip.enabled then
            createBlip(Config.BarberShops[i].coords, Config.BarberShops[i].blip.sprite, Config.BarberShops[i].blip.color, Config.BarberShops[i].blip.string, Config.BarberShops[i].blip.scale)
        end
    end
    for i=1, #Config.TattooShops do
        if Config.TattooShops[i].blip.enabled then
            createBlip(Config.TattooShops[i].coords, Config.TattooShops[i].blip.sprite, Config.TattooShops[i].blip.color, Config.TattooShops[i].blip.string, Config.TattooShops[i].blip.scale)
        end
    end
end)

CreateThread(function()
    shops = consolidateShops()
    textUI = {}
    while true do
        local sleep = 2000
        if #shops > 0 then
            local coords = GetEntityCoords(cache.ped)
            for k,v in pairs(shops) do
                local dist = #(coords - v.coords)
                if dist < (v.distance + 1) then
                    if not textUI[k] then
                        ESX.ShowHelpNotification(showTextUI(v.store))
                        textUI[k] = true
                    end
                    sleep = 0
                    if IsControlJustReleased(0, 38) then
                        openShop(v.store, v.price)
                    end
                elseif dist > v.distance and textUI[k] then
                    textUI[k] = nil
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand('propfix', function()
    for k, v in pairs(GetGamePool('CObject')) do
        if IsEntityAttachedToEntity(PlayerPedId(), v) then
            SetEntityAsMissionEntity(v, true, true)
            DeleteObject(v)
            DeleteEntity(v)
        end
    end
end)

RegisterCommand('fixpj', function()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(appearance)
        exports['fivem-appearance']:setPlayerAppearance(appearance)
    end)
end)

--cd_multicharacter compatibility
RegisterNetEvent('skinchanger:loadSkin2')
AddEventHandler('skinchanger:loadSkin2', function(ped, skin)
    if not skin.model then skin.model = 'mp_m_freemode_01' end
    	exports['fivem-appearance']:setPedAppearance(ped, skin)
    if cb ~= nil then
        cb()
    end
end)

-- esx_skin/skinchanger compatibility(The best I/we can)
AddEventHandler('skinchanger:getSkin', function(cb)
    while not ESX.PlayerLoaded do
        Wait(1000)
    end
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(appearance)
        cb(appearance)
    end)
end)

RegisterNetEvent('skinchanger:loadSkin')
AddEventHandler('skinchanger:loadSkin', function(skin, cb)
	if not skin.model then skin.model = 'mp_m_freemode_01' end
	exports['fivem-appearance']:setPlayerAppearance(skin)
	if cb ~= nil then
		cb()
	end
end)

AddEventHandler('skinchanger:loadDefaultModel', function(loadMale, cb)
    if loadMale then
        TriggerEvent('skinchanger:loadSkin',Config.DefaultSkin)
    else
        local skin = Config.DefaultSkin
        skin.model = 'mp_f_freemode_01'
        TriggerEvent('skinchanger:loadSkin',skin)
    end
end)

RegisterNetEvent('skinchanger:loadClothes')
AddEventHandler('skinchanger:loadClothes', function(skin, clothes)
    local playerPed = PlayerPedId()
    local outfit = convertClothes(clothes)
    exports['fivem-appearance']:setPedComponents(playerPed, outfit.Components)
    exports['fivem-appearance']:setPedProps(playerPed, outfit.Props)
end)

RegisterNetEvent('esx_skin:openSaveableMenu')
AddEventHandler('esx_skin:openSaveableMenu', function(submitCb, cancelCb)
	local config = {
		ped = true,
		headBlend = true,
		faceFeatures = true,
		headOverlays = true,
		components = true,
		props = true
	}
	exports['fivem-appearance']:startPlayerCustomization(function (appearance)
		if (appearance) then
			TriggerServerEvent('fivem-appearance:save', appearance)
			ESX.SetPlayerData('ped', PlayerPedId())
			if submitCb then submitCb() end
		else
			if cancelCb then cancelCb() end
			ESX.SetPlayerData('ped', PlayerPedId())
		end
	end, config)
end)