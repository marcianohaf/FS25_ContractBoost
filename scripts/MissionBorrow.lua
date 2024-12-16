-- MissionBorrow
-- @goal to provide fieldwork items with your mission machiery that needs to be filled
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

MissionBorrow = {}
MissionBorrow.pallets = {
    bigBagPallet_seeds = true,
    bigBagPallet_fertilizer = true,
    herbicideTank = true,
}
MissionBorrow.fillItemsAdded = false

-- 
function MissionBorrow:onSpawnedVehicle(superFunc, vehicle, ...)
    if not ContractBoost.config.enableFieldworkToolFillItems then
        superFunc(self, vehicle, ...)
    end

    if vehicle ~= nil then
        local configNameClean = vehicle[1].configFileNameClean

        if ContractBoost.debug then 
            printf('-- ContractBoost:MissionBorrow :: onSpawnedVehicle %s | isPallet %s', vehicle[1].configFileNameClean, MissionBorrow.pallets[configNameClean] and "yes" or "no")
        end

        if MissionBorrow.pallets[configNameClean] then
            vehicle[1].addWearAmount = function() return true end
            vehicle[1].setOperatingTime = function() return true end
        end

        superFunc(self, vehicle, ...)
    end
end


-- Adds fill items to the mission tools for each type of mission where needed.
function MissionBorrow:addFillItemsToMissionTools()
    if ContractBoost.debug then print('-- ContractBoost:MissionBorrow :: fillMissionTools') end

    if MissionBorrow.fillItemsAdded then
        return
    end

    local fillMissionTypes = {
        "fertilizeMission",
        "herbicideMission",
        "sowMission",
    }

    for _, fillMissionType in pairs(fillMissionTypes) do
        for size, vehicles in pairs(g_missionManager.missionVehicles[fillMissionType]) do
            for v, vehicle in pairs(vehicles) do

                if fillMissionType == 'sowMission' then

                    table.insert(vehicle.vehicles, {
                        filename = 'data/objects/bigBagPallet/seeds/bigBagPallet_seeds.xml'
                    })
                    table.insert(vehicle.vehicles, {
                        filename = 'data/objects/bigBagPallet/seeds/bigBagPallet_seeds.xml'
                    })
                    if size == "large" then
                        table.insert(vehicle.vehicles, {
                            filename = 'data/objects/bigBagPallet/seeds/bigBagPallet_seeds.xml'
                        })
                        table.insert(vehicle.vehicles, {
                            filename = 'data/objects/bigBagPallet/seeds/bigBagPallet_seeds.xml'
                        })
                    end

                elseif fillMissionType == 'fertilizeMission' then

                    table.insert(vehicle.vehicles, {
                        filename = 'data/objects/bigBagPallet/fertilizer/bigBagPallet_fertilizer.xml'
                    })

                    if size ~= "small" then
                        table.insert(vehicle.vehicles, {
                            filename = 'data/objects/bigBagPallet/fertilizer/bigBagPallet_fertilizer.xml'
                        })
                    end

                    if size == "large" then
                        table.insert(vehicle.vehicles, {
                            filename = 'data/objects/bigBagPallet/fertilizer/bigBagPallet_fertilizer.xml'
                        })
                    end

                elseif fillMissionType == 'herbicideMission' then

                    table.insert(vehicle.vehicles, {
                        filename = 'data/objects/pallets/liquidTank/herbicideTank.xml'
                    })

                    if size == "large" then
                        table.insert(vehicle.vehicles, {
                            filename = 'data/objects/pallets/liquidTank/herbicideTank.xml'
                        })
                    end

                end
            end
        end
    end

    -- prevent from being added again
    MissionBorrow.fillItemsAdded = true

    if ContractBoost.debug then print('-- ContractBoost:MissionBorrow :: fillMissionTools complete') end
end