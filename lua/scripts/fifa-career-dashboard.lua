require 'imports/career_mode/helpers'
require 'imports/other/helpers'
local json = require("imports/external/json")

function GetUserSeniorTeamPlayerIDs()
    local result = {}
    local user_teamid = GetUserTeamID()
    Log(string.format("User Team ID: %d", user_teamid))

    -- From this table should be the quickest I guess
    local career_playercontract_table = LE.db:GetTable("career_playercontract")
    local current_record = career_playercontract_table:GetFirstRecord()
    local c = 1
    while current_record > 0 do
        local teamid = career_playercontract_table:GetRecordFieldValue(current_record, "teamid")
        if teamid == user_teamid then
            local playerid = career_playercontract_table:GetRecordFieldValue(current_record, "playerid")
            result[playerid] = true
            Log(string.format("%d: %d", c, playerid))
            c = c + 1
        end
        current_record = career_playercontract_table:GetNextValidRecord()
    end

    return result
end

function sendTeamPlayerAttr()
    local bIsInCM = IsInCM()
    if not bIsInCM then return end

    -- local saveUID = GetSaveUID()
    local currentdate = GetCurrentDate()
    local dateStr = string.format("%d-%d-%d", currentdate.year, currentdate.month, currentdate.day)
    Log(string.format("Current Date: %s", dateStr))

    local user_team_playerids = GetUserSeniorTeamPlayerIDs()
    local players_count = table_count(user_team_playerids)
    local updated_players = 0

    -- Get Players Table
    local players_table = LE.db:GetTable("players")
    local current_record = players_table:GetFirstRecord()

    local playerid = 0
    while current_record > 0 do
        playerid = players_table:GetRecordFieldValue(current_record, "playerid")
        if user_team_playerids[playerid] then
            local overallrating = players_table:GetRecordFieldValue(current_record, "overallrating")
            local potential = players_table:GetRecordFieldValue(current_record, "potential")
             Log(string.format("PlayerID: %d, OverallRating: %d, Potential: %d", playerid, overallrating, potential))

            -- POST to API
            local url = "http://localhost:8888/api/v1/player/" .. playerid
            local dataStr = string.format("currentDate=%s&overallrating=%d&potential=%d", dateStr, overallrating, potential)
            local command = string.format('curl %s -X POST -d "%s"', url, dataStr)
            -- example: curl http://localhost:8888/api/v1/player/1 -X POST -d "currentDate=2021-10-10&overallrating=80&potential=90"
            Log(command)
            local res = os.execute(command)
            Log(res)

            updated_players = updated_players + 1
        end

        if (updated_players == players_count) then
            return
        end
        current_record = players_table:GetNextValidRecord()
    end
end

function OnEvent(events_manager, event_id, event)
   if (
       event_id == ENUM_CM_EVENT_MSG_WEEK_PASSED
   ) then
       sendTeamPlayerAttr()
   end
end

-- sendTeamPlayerAttr()
AddEventHandler("post__CareerModeEvent", OnEvent)

