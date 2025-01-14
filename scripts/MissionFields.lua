-- MissionFields
-- @goal to provide fieldwork items with your mission machiery that needs to be filled
-- @author GMNGjoy
-- @copyright 11/15/2024
-- @contact https://github.com/GMNGjoy/FS25_ContractBoost
-- @license CC0 1.0 Universal

MissionFields = {}
MissionFields.skipHarvestFruitTypes = {}

---Scan all fields on the map at missionStart to see if we need to fix any auto-generated grass fields to actually act like grass fields.
function MissionFields.scanFieldsOnMissionStart()

    if ContractBoost.debug then Logging.info(MOD_NAME..':FIELDS :: scanFieldsOnMissionStart :%s', #g_fieldManager:getFields()) end

    if g_currentMission.contractBoostSettings.enableCustomGrassFieldsForMissions then 
        local grassFruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName('GRASS')
        for idx, field in g_fieldManager:getFields() do
            local fruitTypeIndex = field.fieldState.fruitTypeIndex

            if fruitTypeIndex == grassFruitTypeIndex then
                if not field.grassMissionOnly then
                    if ContractBoost.debug then Logging.info(MOD_NAME..':FIELDS :: force field %s to be grassMissionOnly', field.farmland.id) end

                    -- update the field in memory to have grassMissionOnly
                    field.grassMissionOnly = true

                    -- grass fields shouldn't have weeds, ever.
                    if field.fieldState.weedSate ~= 0 then
                        g_fieldManager:weedField(field)
                    end
                end
            end
        end
    end
end

---Setup the harvest types we don't want based on settings.
function MissionFields:setupSkipHarvestFruitTypes()

    -- start by resetting the object
    self.skipHarvestFruitTypes = {}

    if not g_currentMission.contractBoostSettings.enableHarvestContractPremiumCrops then
        local premiumFruitTypes = g_fruitTypeManager:getFruitTypesByCategoryNames('TOPLIFTINGHARVESTER')
        for _, fruitType in pairs(premiumFruitTypes) do
            self.skipHarvestFruitTypes[fruitType.index] = true
        end
    end

    if not g_currentMission.contractBoostSettings.enableHarvestContractRootCrops then
        local rootCropNames = { "POTATO", "SUGARBEET" }
        for _, fruitName in pairs(rootCropNames) do
            local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(fruitName)
            self.skipHarvestFruitTypes[fruitTypeIndex] = true
        end
    end

    if not g_currentMission.contractBoostSettings.enableHarvestContractSugarcane then
        local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName('SUGARCANE')
        self.skipHarvestFruitTypes[fruitTypeIndex] = true
    end

    if not g_currentMission.contractBoostSettings.enableHarvestContractCotton then
        local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName('COTTON')
        self.skipHarvestFruitTypes[fruitTypeIndex] = true
    end

    if not g_currentMission.contractBoostSettings.enableHarvestContractRootCrops then
        local rootCropNames = { "PEA", "SPINACH", "GREENBEAN" }
        for _, fruitName in pairs(rootCropNames) do
            local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(fruitName)
            self.skipHarvestFruitTypes[fruitTypeIndex] = true
        end
    end

end

---Overwrite the HarvestMission.isAvaiableForField function with ours that checks for harvest types we don't want.
function MissionFields.isHarvestAvailableForField(self, superFunc, field)
    local isAvailable = superFunc(self, field)
    if not isAvailable then
        return false
    end

    if MissionFields.skipHarvestFruitTypes[self.fieldState.fruitTypeIndex] then
        if ContractBoost.debug then Logging.info(MOD_NAME..':FIELDS: skip %s', self.fieldState.fruitTypeIndex, g_fruitTypeManager:getFruitTypeNameByIndex(self.fieldState.fruitTypeIndex)) end
        return false
    end

    -- if ContractBoost.debug then Logging.info(MOD_NAME..':FIELDS: pass %s', self.fieldState.fruitTypeIndex, g_fruitTypeManager:getFruitTypeNameByIndex(self.fieldState.fruitTypeIndex)) end
    return true
end