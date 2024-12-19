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
            [WorkAreaTypes.WEEDER] = true,
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

    if ContractBoost.config.enableHayFromTedderMissions then
        MissionTools.additionalAllowedVehicles.tedderMission = {
            [WorkAreaTypes.FORAGEWAGON] = true,
            [WorkAreaTypes.BALER] = true,
            [WorkAreaTypes.WINDROWER] = true,
        }
    end

    -- allow cultivating when seeding in case you plant the wrong crop
    if not MissionTools.additionalAllowedVehicles.sowMission then
        MissionTools.additionalAllowedVehicles.sowMission = {}
    end
    MissionTools.additionalAllowedVehicles.sowMission[WorkAreaTypes.CULTIVATOR] = true

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
    
        -- if ContractBoost.debug then 
        -- printf('-- ContractBoost:MissionTools :: missionType: %s | workAreaType: %s', missionType, workAreaType)
        -- end

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

-- replace the BaleMission.addBale function with our own function that updates the owner of the bale to the player.
function MissionTools:addBale(superFunc, bale)
    -- call the overwritten function
    superFunc(bale)

    -- exit if not enabled
    if not ContractBoost.config.enableCollectingBalesFromMissions then
        return
    end

    Logging.warning('ContractBoost:::: change owner')

    -- one last check that we have a bale, and change the owner.
    if bale ~= nil then
        if ContractBoost.debug then printf('-- ContractBoost:MissionTools :: addBale changeOwner %s', g_localPlayer.farmId) end
        bale:setOwnerFarmId(g_localPlayer.farmId)
    end
 end

-- replace the BaleMission.finishField function with our own function that doesn't remove the bales.
function MissionTools.finishBaleField(self, superFunc)
    -- call the original method if collecting bales is not enabled
    if not ContractBoost.config.enableCollectingBalesFromMissions then
        superFunc(self)
        return
    end


    -- otherwise call the parent finishField fn bypassing the bale removal
    local parentClass = BaleMission:superClass()
    parentClass.finishField(self)
 end

 -- replace the BaleWrapMission.finishField function with our own function that doesn't remove the bales.
 function MissionTools.finishBaleWrapField(self, superFunc)
    -- call the original method if collecting bales is not enabled
    if not ContractBoost.config.enableCollectingBalesFromMissions then
        superFunc(self)
        return
    end


    -- otherwise call the parent finishField fn bypassing the bale removal
    local parentClass = BaleWrapMission:superClass()
    parentClass.finishField(self)
 end