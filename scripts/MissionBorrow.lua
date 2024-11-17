-- MissionBorrow
-- @goal to provide fieldwork items with your mission machiery that needs to be filled
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

MissionBorrow = {}
MissionBorrow.config = {}
MissionBorrow.debug = false

function MissionBorrow:init()
    if MissionBorrow.debug then print('-- MissionBorrow :: init.') end

    -- load the config from xml
    source(g_currentModDirectory.."scripts/xmlConfigLoader.lua")
    MissionBorrow.config = XmlConfigLoader.init()
    MissionBorrow.debug = MissionBorrow.config.debugMode
    
    g_missionManager.loadMapData = Utils.appendedFunction(MissionManager.loadMapData, MissionBorrow.loadMapData)

    print('-- ContractBoost:MissionBorrow :: loaded.')
end

function MissionBorrow:loadMapData()
    if MissionBorrow.debug then print('-- MissionBorrow :: loadMapData') end

    if MissionBorrow.config.enableFieldworkToolFillItems then 
        MissionBorrow:fillMissionTools()
    end
   
    if MissionBorrow.debug then print('-- MissionBorrow :: loadMapData complete') end
end

function MissionBorrow:fillMissionTools()
    if MissionBorrow.debug then print('-- MissionBorrow :: fillMissionTools') end

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

    if MissionBorrow.debug then print('-- MissionBalance :: fillMissionTools complete') end
end

MissionBorrow:init()