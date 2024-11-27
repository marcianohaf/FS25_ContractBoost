-- ContractBoost:MissionTools
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

WorkAreaTypes = {
    BALER = 1,
    COMBINECHOPPER = 2,
    COMBINESWATH = 3,
    CULTIVATOR = 4,
    CUTTER = 5,
    HAULMDROP = 6,
    FORAGEWAGON = 7,
    FRUITPREPARER = 8,
    MULCHER = 9,
    MOWER = 10,
    PLOW = 11,
    PLOWSHARE = 12,
    RIDGEFORMER = 13,
    RIDGEMARKER = 14,
    ROLLER = 15,
    SALTSPREADER = 16,
    SOWINGMACHINE = 17,
    SPRAYER = 18,
    STONEPICKER = 19,
    STUMPCUTTER = 20,
    TEDDER = 21,
    WEEDER = 22,
    WINDROWER = 23,
    DEFAULT = 24,
    AUXILIARY = 25,
}

MissionTools = {}
MissionTools.additionalAllowedVehicles = {}

-- Determine which additional allowed vehicles will be allowed based on user settings.
function MissionTools:setupAdditionalAllowedVehicles()

    if ContractBoost.config.enableStrawFromHarvestMissions then
        MissionTools.additionalAllowedVehicles.harvestMission = {
            [WorkAreaTypes.FORAGEWAGON] = true,
            [WorkAreaTypes.BALER] = true,
            [WorkAreaTypes.WINDROWER] = true,
        }
    end

    if ContractBoost.config.enableSwathingForHarvestMissions then
        if not MissionTools.additionalAllowedVehicles.harvestMission then
            MissionTools.additionalAllowedVehicles.harvestMission = {}
        end
        MissionTools.additionalAllowedVehicles.harvestMission[WorkAreaTypes.MOWER] = true
    end

    if ContractBoost.config.enableGrassFromMowingMissions then
        MissionTools.additionalAllowedVehicles.mowMission = {
            [WorkAreaTypes.COMBINECHOPPER] = true,
            [WorkAreaTypes.CUTTER] = true,
            [WorkAreaTypes.FORAGEWAGON] = true,
            [WorkAreaTypes.BALER] = true,
            [WorkAreaTypes.FORAGEWAGON] = true,
            [WorkAreaTypes.WINDROWER] = true,
        }
    end

    if ContractBoost.config.enableStonePickingFromMissions then
        MissionTools.additionalAllowedVehicles.plowMission = {
            [WorkAreaTypes.STONEPICKER] = true,
        }
        MissionTools.additionalAllowedVehicles.cultivateMission = {
            [WorkAreaTypes.STONEPICKER] = true,
        }
        MissionTools.additionalAllowedVehicles.sowMission = {
            [WorkAreaTypes.STONEPICKER] = true,
        }
    end

    -- baleMission = {},
    -- baleWrapMission = {},
    -- hoeMission = {},
    -- weedMission = {},
    -- herbicideMission ={},
    -- fertilizeMission ={},
    -- tedderMission = {},
    -- stonePickMission = {},
    -- deadwoodMission = {},
    -- treeTransportMission = {},
    -- destructibleRockMission = {},
end

-- replace the getIsMissionWorkAllowed with our own function that also checks the additional tools
function MissionTools:getIsMissionWorkAllowed(superFunc, farmId, x, z, workAreaType)
    local mission = self:getMissionAtWorldPosition(x, z)
    if mission ~= nil and mission.type ~= nil and mission.farmId == farmId then
        local missionType = mission.type.name
    
        -- if ContractBoost.debug then printf('-- ContractBoost:MissionTools :: missionType: %s | workAreaType: %s', missionType, workAreaType) end

        local additionalWorkAreaTypes = MissionTools.additionalAllowedVehicles[missionType] or {}
        
        -- if ContractBoost.debug then
        --     print('-- ContractBoost:MissionTools :: additionalAllowedVehicles')
        --     DebugUtil.printTableRecursively(additionalWorkAreaTypes)
        -- end

        if (
            workAreaType == nil
            or mission.workAreaTypes[workAreaType]
            or additionalWorkAreaTypes[workAreaType]
        ) then
            return true
        end
    end

    return false
end