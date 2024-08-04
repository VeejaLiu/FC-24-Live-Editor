require 'imports/career_mode/helpers'
require 'imports/other/helpers'
local json = require("imports/external/json")

local attributeNameList = {
    "birthdate",
    "overallrating",
    "potential",
    "nationality",
    "height",
    "weight",
    "preferredfoot",
    "preferredposition1",
    "preferredposition2",
    "preferredposition3",
    "preferredposition4",
    "skillmoves",
    "weakfootabilitytypecode",
    "attackingworkrate",
    "defensiveworkrate",
    -- pace
    "acceleration",
    "sprintspeed",
    -- attacking
    "positioning",
    "finishing",
    "shotpower",
    "longshots",
    "volleys",
    "penalties",
    -- passing
    "vision",
    "crossing",
    "freekickaccuracy",
    "shortpassing",
    "longpassing",
    "curve",
    -- dribbling
    "agility",
    "balance",
    "reactions",
    "ballcontrol",
    "dribbling",
    "composure",
    -- defending
    "interceptions",
    "headingaccuracy",
    "defensiveawareness",
    "standingtackle",
    "slidingtackle",
    -- physical
    "jumping",
    "stamina",
    "strength",
    "aggression"
}

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

function postPlayers(jsonStr)
    -- POST to API
    local url = "http://localhost:8888/api/v1/player/bulk"
    -- 转义 jsonStr
    -- 保存到文件
    local file = io.open("players.json", "w")
    file:write(jsonStr)
    file:close()

    jsonStr = string.gsub(jsonStr, '"', '\\"')
    local command = 'curl -X POST -H "Content-Type: application/json"'
    -- 从文件读取
    command = command .. ' -d "@players.json"'
    --command = command .. ' -d "' .. jsonStr .. '"'
    command = command .. ' ' .. url
    Log('Command: ' .. command)
    os.execute(command)
end

function sendTeamPlayerAttr()
    local bIsInCM = IsInCM()
    if not bIsInCM then
        return
    end

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

    local jsonStr = ""
    jsonStr = jsonStr .. "["
    -- now is [

    local playerid = 0
    while current_record > 0 do
        playerid = players_table:GetRecordFieldValue(current_record, "playerid")
        if user_team_playerids[playerid] then
            local playername = GetPlayerName(playerid)
            Log(string.format("Player Name: %s", playername))

            local currentPlayerJsonStr = ""

            currentPlayerJsonStr = currentPlayerJsonStr .. "{"
            -- now currentPlayerJsonStr is '{'

            -- add playerid
            currentPlayerJsonStr = currentPlayerJsonStr .. string.format('"playerid": %d', playerid)
            -- now currentPlayerJsonStr is {"playerid": playerid

            -- add playername
            currentPlayerJsonStr = currentPlayerJsonStr .. string.format(', "playername": "%s"', playername)
            -- now currentPlayerJsonStr is {"playerid": playerid, "playername": "playername"
            -- add current date
            currentPlayerJsonStr = currentPlayerJsonStr .. string.format(', "date": "%s"', dateStr)
            -- now currentPlayerJsonStr is {"playerid": playerid, "date": "dateStr"

            -- get all attributes
            for i, attrName in ipairs(attributeNameList) do
                local attrValue = players_table:GetRecordFieldValue(current_record, attrName)
                currentPlayerJsonStr = currentPlayerJsonStr .. string.format(', "%s": "%s"', attrName, attrValue)
                -- now currentPlayerJsonStr is {"playerid": playerid, "date": "dateStr", "attrName": "attrValue"
            end

            currentPlayerJsonStr = currentPlayerJsonStr .. "}"
            -- now currentPlayerJsonStr is {"playerid": playerid, "date": "dateStr", "attrName": "attrValue"}

            updated_players = updated_players + 1
            jsonStr = jsonStr .. currentPlayerJsonStr
            -- now jsonStr is [{"playerid": playerid, "date": "dateStr", "attrName": "attrValue"}
            if (updated_players < players_count) then
                jsonStr = jsonStr .. ","
                -- now is [{...},
            end
        end
        if (updated_players == players_count) then
            jsonStr = jsonStr .. "]"
            -- now jsonStr is [{...}, ..., {...}]
            postPlayers(jsonStr)
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

sendTeamPlayerAttr()
-- AddEventHandler("post__CareerModeEvent", OnEvent)

