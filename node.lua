gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local font = resource.load_font "Ubuntu-C.ttf"
local json = require "json"

local serial = sys.get_env "SERIAL"
local location = "<waiting>"
local description = "<waiting>"
local dynamic_value = "<no value>"
local dynamic_values = {}   -- extra key/value pairs via "vars"

local res = util.resource_loader{
    "device_details.png";
}

local logo = resource.create_colored_texture(0,0,0,0)
local white = resource.create_colored_texture(1,1,1,1)

-- Only remote control via device node commands now:
--   curl.exe -u ":API_KEY" -d "data=value 123" https://info-beamer.com/api/v1/device/DEVICE_ID/node/root
--   curl.exe -u ":API_KEY" -d "data=vars {\"temp\":22,\"status\":\"OK\"}" https://info-beamer.com/api/v1/device/DEVICE_ID/node/root
util.data_mapper{
    ["device_info"] = function(info)
        local ok, decoded = pcall(json.decode, info)
        if ok and type(decoded) == "table" then
            location = decoded.location or location
            description = decoded.description or description
        end
    end,

    ["value"] = function(raw)
        print("recv value raw:", raw)
        local ok, decoded = pcall(json.decode, raw)
        if ok then
            if type(decoded) == "table" then
                local v = decoded.value or decoded.val or decoded.current or decoded[1]
                dynamic_value = v and tostring(v) or "<no key>"
            else
                dynamic_value = tostring(decoded)
            end
        else
            dynamic_value = raw
        end
        print("dynamic_value now:", dynamic_value)
    end,

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
    font:write(s, s*0.5, "Screen Information", s, 1,1,1,1)
    white:draw(0, s*1.6-2, WIDTH, s*1.6+2, 0.2)
    white:draw(0, s*2.6-2, WIDTH, s*2.6+2, 0.2)

    local w = font:write(s, s*1.75, "Serial: ", s, 1,1,1,1)
    font:write(s+w, s*1.75, serial, s, 1,1,.5,1)
    font:write(s, s*2.75, "Description: "..description, s, 1,1,1,1)
    font:write(s, s*3.75, "Location: "..location, s, 1,1,1,1)
    font:write(s, s*4.75, "Value: "..dynamic_value, s, 1,1,1,1)

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
