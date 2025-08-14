gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local font = resource.load_font "Ubuntu-C.ttf"
local json = require "json"

local serial = sys.get_env "SERIAL"
local location = "<please wait>"
local description = "<please wait>"
local dynamic_value = "<loading>" -- value shown on screen from value.json

local res = util.resource_loader{
    "device_details.png";
}

local logo = resource.create_colored_texture(0,0,0,0)
local white = resource.create_colored_texture(1,1,1,1)

util.file_watch("config.json", function(raw)
    local config = json.decode(raw)
    logo = resource.load_image(config.logo.asset_name)
end)

-- Watch a separate JSON file (value.json) whose contents are updated via API/file upload.
-- Expected format example: {"value": 42}
-- Any change to the file will be picked up automatically.
util.file_watch("value.json", function(raw)
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == "table" then
        -- Try common keys or fallbacks
        local v = data.value or data.val or data.current or data[1]
        if v == nil then
            dynamic_value = "<no key>"
        else
            dynamic_value = tostring(v)
        end
    else
        dynamic_value = "<json error>"
    end
end)

util.data_mapper{
    ["device_info"] = function(info)
        info = json.decode(info)
        location = info.location
        description = info.description
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
    if res.device_details then
        res.device_details:draw(s, s*5, s*5.5, s*9.5)
    end
    util.draw_correct(logo, WIDTH-s*5.5, s*5, WIDTH-s, s*9.5)
end

function node.render()
    gl.clear(0,0,0,1)
    draw_info()
end
