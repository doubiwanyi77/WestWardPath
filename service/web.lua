local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"

local web_root = skynet.getenv("web_root") or "./www"
local port = tonumber(skynet.getenv("http_port")) or 8080

--扩展名
local mime = {
    html = "text/html;charset = utf-8",
    css = "text/css; charset = utf-8",
    js = "application/javascript; charset = utf-8",
    jpg = "image/jpeg",
    jpeg = "image/jpeg",
    png = "image/png",
    webp = "image/webp",
    gif = "image/gif",
}

local function read_file(path)
    local f = io.open(path,"rb")
    if not f then
        return nil
    end
    local body = f:read("*a")
    f:close()
    return body
end

---将url路径专程www下的文件路径
---@param url_path any
---@return string
local function safe_path(url_path)
    if url_path == "/" or url_path == "" then
        return web_root .. "/index.html"
    end
    if url_path:find("..",1,true) then
        return nil
    end
    return web_root .. url_path
end

---取扩展名，用于查mime
---@param path any
---@return string
local function get_ext(path)
    return path:match("%.([%w]+)$") or ""
end

local function handle(fd)
    socket.start(fd)

    local read = sockethelper.readfunc(fd)
    local write = sockethelper.writefunc(fd)

    ---解析请求
    local code,url,method,header,body = httpd.read_request(read,8192) --8192(字节)为头部大小上限

    --以下为错误情况
    if not code then
        socket.close(fd)
        return
    end
    if code ~= 200 then
        httpd.write_response(write,code)
        socket.close(fd)
        return
    end

    local path = urllib.parse(url)
    local file_path = safe_path(path)

    if not file_path then
        httpd.write_response(write,403,"forbidden")
        socket.close(fd)
        return
    end

    local content = read_file(file_path)
    if not content then
        httpd.write_response(write,404,"not found")
        socket.close(fd)
        return
    end

    local header_out = {
        ["content-type"] = mime[get_ext(file_path)] or "application/octet-stream",
        ["cache-control"] = "no-cache",
    }
    httpd.write_response(write,200,content,header_out)
    socket.close(fd)
end

skynet.start(function ()
    local listen = socket.listen("0.0.0.0",port)
    skynet.error("HTTP网页监听:"..port)

    socket.start(listen,function (fd,addr)
        skynet.fork(handle,fd)
    end)
end)