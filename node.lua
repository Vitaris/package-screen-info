gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local font = resource.load_font "Ubuntu-C.ttf"
local json = require "json"

local serial = sys.get_env "SERIAL"
local location = "<please wait>"
local description = "<please wait>"
local dynamic_value = "<loading>" -- value shown on screen from value.json
local dynamic_values = {}         -- optional map of extra values (updated via "vars" command)

local res = util.resource_loader{
    "device_details.png";
}

local logo = resource.create_colored_texture(0,0,0,0)
local white = resource.create_colored_texture(1,1,1,1)
local watched_value_asset -- currently watched JSON asset filename

-- util.file_watch("config.json", function(raw)
--     local config = json.decode(raw)
--     if config.logo and config.logo.asset_name then
--         logo = resource.load_image(config.logo.asset_name)
--     end
--     -- Set up / switch JSON asset watcher if option provided
--     if config.value_json and config.value_json.asset_name then
--         local asset = config.value_json.asset_name
--         if asset ~= watched_value_asset then
--             watched_value_asset = asset
--             util.file_watch(asset, function(raw_json)
--                 local ok, data = pcall(json.decode, raw_json)
--                 if ok and type(data) == "table" then
--                     local v = data.value or data.val or data.current or data[1]
--                     dynamic_value = v and tostring(v) or "<no key>"
--                 else
--                     dynamic_value = "<json error>"
--                 end
--             end)
--         end
--     end
-- end)

-- Watch a separate JSON file (value.json) whose contents are updated via API/file upload.
-- Expected format example: {"value": 42}
-- Any change to the file will be picked up automatically.
-- Legacy direct file watcher for bundled default file (kept if no asset option chosen)
-- util.file_watch("value.json", function(raw)
--     if watched_value_asset then return end -- asset option overrides
--     local ok, data = pcall(json.decode, raw)
--     if ok and type(data) == "table" then
--         local v = data.value or data.val or data.current or data[1]
--         dynamic_value = v and tostring(v) or "<no key>"
--     else
--         dynamic_value = "<json error>"
--     end
-- end)

util.data_mapper{
    ["device_info"] = function(info)
        info = json.decode(info)
        location = info.location
        description = info.description
    end,
    -- Update dynamic_value directly via API using the device node command:
    -- POST /api/v1/device/<device_id>/node/root with form field
    --   data=value {"value":123}
    -- or data=value 123
    ["value"] = function(raw)
        -- Try JSON first
        local ok, decoded = pcall(json.decode, raw)
        if ok then
            if type(decoded) == "table" then
                local v = decoded.value or decoded.val or decoded.current or decoded[1]
                if v ~= nil then
                    dynamic_value = tostring(v)
                else
                    dynamic_value = "<no key>"
                end
            else
                -- decoded is a number/string/bool
                dynamic_value = tostring(decoded)
            end
        else
            -- Fallback: treat raw string as the value itself
            dynamic_value = raw
        end
    end,
    -- Batch update: send JSON object with arbitrary scalar keys
    -- curl -u ":API_KEY" -d 'data=vars {"temp":21,"humidity":55}' https://info-beamer.com/api/v1/device/DEVICE_ID/node/root
    ["vars"] = function(raw)
        local ok, obj = pcall(json.decode, raw)
        if ok and type(obj) == "table" then
            for k,v in pairs(obj) do
                if type(v) ~= "table" then
                    dynamic_values[k] = tostring(v)
                end
            end
        end
    end
}

local function draw_info()
    local s = HEIGHT/10
    font:write(s, s*0.5, "Screen Information4", s, 1,1,1,1)
    white:draw(0, s*1.6-2, WIDTH, s*1.6+2, 0.2)
    white:draw(0, s*2.6-2, WIDTH, s*2.6+2, 0.2)
    local w = font:write(s, s*1.75, "Serial: ", s, 1,1,1,1)
    font:write(s+w, s*1.75, serial, s, 1,1,.5,1)
    font:write(s, s*2.75, "Description: "..description, s, 1,1,1,1)
    font:write(s, s*3.75, "Location: "..location, s, 1,1,1,1)
    font:write(s, s*4.75, "Value: "..dynamic_value, s, 1,1,1,1)
    -- Render additional vars (if any) below
    local line = 5.75
    for k,v in pairs(dynamic_values) do
        font:write(s, s*line, k..": "..v, s, 1,1,1,1)
        line = line + 1
        if s*line > HEIGHT - s then break end
    end
    util.draw_correct(logo, WIDTH-s*5.5, s*5, WIDTH-s, s*9.5)
end

function node.render()
    gl.clear(0,0,0,1)
    draw_info()
end
