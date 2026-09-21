-- Minimal JSON encode/decode for the demo protocol.
local json = {}

local encode_value

local escape_map = {
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
}

local function encode_string(s)
    return '"' .. tostring(s):gsub('[%z\1-\31\\"]', function(c)
        return escape_map[c] or string.format("\\u%04x", string.byte(c))
    end) .. '"'
end

local function is_array(t)
    local count, maxn = 0, 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
            return false
        end
        if k > maxn then
            maxn = k
        end
        count = count + 1
    end
    return maxn == count
end

encode_value = function(v)
    local tv = type(v)
    if v == nil then
        return "null"
    elseif tv == "boolean" then
        return v and "true" or "false"
    elseif tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then
            return "null"
        end
        return string.format("%.0f", v) == tostring(v) and tostring(v) or tostring(v)
    elseif tv == "string" then
        return encode_string(v)
    elseif tv == "table" then
        if is_array(v) then
            local parts = {}
            for i = 1, #v do
                parts[i] = encode_value(v[i])
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local parts = {}
        for k, val in pairs(v) do
            if type(k) == "string" then
                parts[#parts + 1] = encode_string(k) .. ":" .. encode_value(val)
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    error("json.encode cannot encode " .. tv)
end

function json.encode(v)
    return encode_value(v)
end

local ptr, src, slen

local function peek()
    return src:sub(ptr, ptr)
end

local function skip_ws()
    while ptr <= slen do
        local c = src:sub(ptr, ptr)
        if c == " " or c == "\t" or c == "\n" or c == "\r" then
            ptr = ptr + 1
        else
            break
        end
    end
end

local parse_value

local function parse_string()
    ptr = ptr + 1
    local buf = {}
    while ptr <= slen do
        local c = src:sub(ptr, ptr)
        if c == '"' then
            ptr = ptr + 1
            return table.concat(buf)
        elseif c == "\\" then
            local n = src:sub(ptr + 1, ptr + 1)
            local map = {
                n = "\n", r = "\r", t = "\t",
                ['"'] = '"', ["\\"] = "\\", ["/"] = "/",
                b = "\b", f = "\f",
            }
            if n == "u" then
                local hex = src:sub(ptr + 2, ptr + 5)
                local code = tonumber(hex, 16) or 0
                buf[#buf + 1] = utf8.char(code)
                ptr = ptr + 6
            else
                buf[#buf + 1] = map[n] or n
                ptr = ptr + 2
            end
        else
            buf[#buf + 1] = c
            ptr = ptr + 1
        end
    end
    error("unterminated string")
end

local function parse_number()
    local s, e = src:find("-?%d+%.?%d*[eE]?[%+%-]?%d*", ptr)
    if not s or s ~= ptr then
        error("bad number at " .. ptr)
    end
    local n = tonumber(src:sub(s, e))
    ptr = e + 1
    return n
end

local function parse_array()
    ptr = ptr + 1
    skip_ws()
    local arr = {}
    if peek() == "]" then
        ptr = ptr + 1
        return arr
    end
    while true do
        arr[#arr + 1] = parse_value()
        skip_ws()
        local c = peek()
        if c == "]" then
            ptr = ptr + 1
            return arr
        elseif c == "," then
            ptr = ptr + 1
            skip_ws()
        else
            error("expected , or ] in array")
        end
    end
end

local function parse_object()
    ptr = ptr + 1
    skip_ws()
    local obj = {}
    if peek() == "}" then
        ptr = ptr + 1
        return obj
    end
    while true do
        skip_ws()
        if peek() ~= '"' then
            error("expected string key")
        end
        local key = parse_string()
        skip_ws()
        if peek() ~= ":" then
            error("expected :")
        end
        ptr = ptr + 1
        obj[key] = parse_value()
        skip_ws()
        local c = peek()
        if c == "}" then
            ptr = ptr + 1
            return obj
        elseif c == "," then
            ptr = ptr + 1
        else
            error("expected , or } in object")
        end
    end
end

parse_value = function()
    skip_ws()
    local c = peek()
    if c == '"' then
        return parse_string()
    elseif c == "{" then
        return parse_object()
    elseif c == "[" then
        return parse_array()
    elseif c == "t" and src:sub(ptr, ptr + 3) == "true" then
        ptr = ptr + 4
        return true
    elseif c == "f" and src:sub(ptr, ptr + 4) == "false" then
        ptr = ptr + 5
        return false
    elseif c == "n" and src:sub(ptr, ptr + 3) == "null" then
        ptr = ptr + 4
        return nil
    elseif c == "-" or c:match("%d") then
        return parse_number()
    end
    error("unexpected char at " .. ptr .. ": " .. tostring(c))
end

function json.decode(s)
    src = s
    slen = #s
    ptr = 1
    local v = parse_value()
    skip_ws()
    return v
end

return json
