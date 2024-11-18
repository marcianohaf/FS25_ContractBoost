-- MissionBorrow
-- @goal to provide fieldwork items with your mission machiery that needs to be filled
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

MissionBorrow = {}

-- Adds fill items to the mission tools for each type of mission where needed.
function MissionBorrow:addFillItemsToMissionTools()
    if ContractBoost.debug then print('-- ContractBoost:MissionBorrow :: fillMissionTools') end

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
                    if size == "large" then 
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

    if ContractBoost.debug then print('-- ContractBoost:MissionBorrow :: fillMissionTools complete') end
end