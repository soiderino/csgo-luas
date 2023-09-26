---@diagnostic disable: undefined-global, deprecated, lowercase-global


-- @soiderino: fuck ffi.
ffi.cdef([[

    typedef void* (__cdecl* tCreateInterface)(const char* name, int* returnCode);

    void* GetProcAddress(void* hModule, const char* lpProcName);
    void* GetModuleHandleA(const char* lpModuleName);
]])

function mem.CreateInterface(module, interface)
    return ffi.cast('tCreateInterface', ffi.C.GetProcAddress(ffi.C.GetModuleHandleA(module), 'CreateInterface'))(interface, ffi.new('int*'))
end


-- @soiderino: Filesystem Library.
local filesystem = {} filesystem.__index = filesystem filesystem.char_buffer = ffi.typeof("char[?]")
filesystem.table = ffi.cast(ffi.typeof("void***"), mem.CreateInterface("filesystem_stdio.dll", "VBaseFileSystem011"))
filesystem.v_funcs = {
    fileRead = ffi.cast(ffi.typeof("int(__thiscall*)(void*, void*, int, void*)"), filesystem.table[0][0]),
    fileOpen = ffi.cast(ffi.typeof("void*(__thiscall*)(void*, const char*, const char*, const char*)"), filesystem.table[0][2]),
    fileClose = ffi.cast(ffi.typeof("void*(__thiscall*)(void*, void*)"), filesystem.table[0][3]),
    fileSize = ffi.cast(ffi.typeof("unsigned int(__thiscall*)(void*, void*)"), filesystem.table[0][7]),
}
function filesystem.readFile(path)
    local handle = filesystem.v_funcs.fileOpen(filesystem.table, path, "r", "MOD")
    if (handle == nil) then return end

    local filesize = filesystem.v_funcs.fileSize(filesystem.table, handle)
    if (filesize == nil or filesize < 0) then return end

    local buffer = filesystem.char_buffer(filesize + 1)
    if (buffer == nil) then return end

    if (not filesystem.v_funcs.fileRead(filesystem.table, buffer, filesize, handle)) then return end

    filesystem.v_funcs.fileClose(filesystem.table, handle)

    return ffi.string(buffer, filesize)
end






local RUBY, CHEAT, LIB = {}, {}, {}

RUBY.UI = {
    screen_x = draw.GetScreenSize(x),
    screen_y = draw.GetScreenSize(y),
    indicators = draw.GetScreenSize() / 2
}

RUBY.FONTS = {
    verdana = draw.CreateFont("Verdana", 12, 1200),
    verdana_bold = draw.CreateFont("Verdana Bold", 12, 300)
}

RUBY.ROLL_MODES = {
    "static",
    "jump abuser"
}

RUBY.WARMUP_LIST = {
    "rbot.master",
    "misc.fakelag.enable",
    "misc.fakelatency.enable",
    "misc.strafe.enable"
}

RUBY.SPECTATOR_LIST = {}

CHEAT.VARS = {
    aw_name = cheat.GetUserName()
}

-- GUI
RUBY.GUI = gui.XML(
	[[
		<Window var="menu" name="Ruby" width="370" height="420">
			<Tab var="antiaim" name="antiaim"></Tab>
			<Tab var="visuals" name="visuals"></Tab>
			<Tab var="misc" name="misc"></Tab>
		</Window>
	]]
)


-- References
local RUBY_GLOBAL = RUBY.GUI:Reference("Ruby") RUBY_GLOBAL:SetPosY(RUBY.UI.screen_y / 3.5) RUBY_GLOBAL:SetPosX(RUBY.UI.screen_x / 6)

local RUBY_ANTIAIM_TAB = RUBY.GUI:Reference('antiaim')
local RUBY_VISUALS_TAB = RUBY.GUI:Reference('visuals')
local RUBY_MISC_TAB = RUBY.GUI:Reference('misc')



-- ANTI-AIM
local RUBY_ANTIAIM_GROUP = gui.Groupbox(RUBY_ANTIAIM_TAB, "Anti-Aim") RUBY_ANTIAIM_GROUP:SetPosX(16)
local RUBY_INVERTER_KEY = gui.Checkbox(RUBY_ANTIAIM_GROUP, "ruby.inverter", "Desync Inverter", false)
RUBY_INVERTER_KEY:SetDescription("Switch the desync side")

local RUBY_ROLL_GROUP = gui.Groupbox(RUBY_ANTIAIM_TAB, "Extended Angles") RUBY_ROLL_GROUP:SetPosX(16)
local RUBY_ROLL_BOX = gui.Checkbox(RUBY_ANTIAIM_GROUP, "ruby.roll.box", "Extended Angles", false)
local RUBY_ROLL_SLIDER = gui.Slider(RUBY_ROLL_GROUP, "ruby.roll", "Yaw", 0, -50, 50)
local RUBY_ROLL_MODE = gui.Combobox(RUBY_ROLL_GROUP, "ruby.roll.mode", "Mode", unpack(RUBY.ROLL_MODES))


-- VISUALS
local RUBY_VISUALS_GROUP = gui.Groupbox(RUBY_VISUALS_TAB, "Visuals") RUBY_VISUALS_GROUP:SetPosX(16)
local RUBY_VIEWMODEL_GROUP = gui.Groupbox(RUBY_VISUALS_TAB, "Screen") RUBY_VIEWMODEL_GROUP:SetPosX(16)

local RUBY_WATERMARK = gui.Checkbox(RUBY_VISUALS_GROUP, "ruby.watermark", "Watermark", false)
local RUBY_WATERMARK_COLOR = gui.ColorPicker(RUBY_WATERMARK, "color", "Watermark Color", 255, 255, 255, 255)

local RUBY_VIEWMODEL_X = gui.Slider(RUBY_VIEWMODEL_GROUP, "ruby.viewmodel.x", "Viewmodel X", 1, -20, 20)
local RUBY_VIEWMODEL_Y = gui.Slider(RUBY_VIEWMODEL_GROUP, "ruby.viewmodel.y", "Viewmodel Y", 1, -20, 20)
local RUBY_VIEWMODEL_Z = gui.Slider(RUBY_VIEWMODEL_GROUP, "ruby.viewmodel.z", "Viewmodel Z", -1, -20, 20)
local RUBY_ASPECTRATIO = gui.Slider(RUBY_VIEWMODEL_GROUP, "ruby.aspectratio", "Aspect Ratio", 0, 0, 10, 0.1)


-- MISC
local RUBY_MISC_GROUP = gui.Groupbox(RUBY_MISC_TAB, "Misc") RUBY_MISC_GROUP:SetPosX(16)

local RUBY_WARMUP = gui.Checkbox(RUBY_MISC_GROUP, "ruby.warmup", "Disable on Warmup", false)
local RUBY_AUTODISCONNECT = gui.Checkbox(RUBY_MISC_GROUP, "ruby.autodisconnect", "Auto Disconnect", false)
local RUBY_ANTIAFK = gui.Checkbox(RUBY_MISC_GROUP, "ruby.antiafk", "Anti AFK", false)
local RUBY_JUMPSCOUT = gui.Checkbox(RUBY_MISC_GROUP, "ruby.jumpscout", "Jump Scout", false)



RUBY.MENU = function ()
    if gui.Reference('menu'):IsActive() then
		RUBY.GUI:SetInvisible(false)
	else
		RUBY.GUI:SetInvisible(true)
	end
end

RUBY.INVERTER = function ()
    if not RUBY_INVERTER_KEY:GetValue() then
        gui.SetValue("rbot.antiaim.base", "0 Desync")
		gui.SetValue("rbot.antiaim.base.rotation", 58)
    else
        gui.SetValue("rbot.antiaim.base.rotation", -58)
    end
end

RUBY.VIEWMODEL = function () -- @soiderino: gucci optimization 🤣
    local viewmodelX = RUBY_VIEWMODEL_X:GetValue()
    local viewmodelY = RUBY_VIEWMODEL_Y:GetValue()
    local viewmodelZ = RUBY_VIEWMODEL_Z:GetValue()

    client.SetConVar("viewmodel_offset_x", viewmodelX, true)
    client.SetConVar("viewmodel_offset_y", viewmodelY, true)
    client.SetConVar("viewmodel_offset_z", viewmodelZ, true)
end

RUBY.ASPECTRATIO = function ()
    local aspectRatio = RUBY_ASPECTRATIO:GetValue() / 10
    client.SetConVar("r_aspectratio", aspectRatio, true)
end

RUBY.ROLL = function (cmd)

    gui.SetValue("rbot.antiaim.advanced.roll", "Off") -- @soiderino: disables aimware roll, it's shit

    if RUBY_ROLL_BOX:GetValue() == true then
        RUBY_ROLL_GROUP:SetInvisible(false)
        gui.SetValue("misc.antiuntrusted", false)
    else
        RUBY_ROLL_GROUP:SetInvisible(true)
        gui.SetValue("misc.antiuntrusted", true)
    end

    local desyncValue = gui.GetValue("rbot.antiaim.base.rotation")
    local me = entities.GetLocalPlayer()

    if not me then
        return
    end

    local roll = RUBY_ROLL_SLIDER:GetValue()

    local flags = me:GetPropInt("m_fFlags")
    local duck = me:GetPropFloat("m_flDuckAmount")

    if RUBY_ROLL_BOX:GetValue() then
        if RUBY_ROLL_MODE:GetValue() == 0 then
            if desyncValue == 58 then
                cmd.viewangles = EulerAngles(cmd.viewangles.x, cmd.viewangles.y, -roll)
            elseif desyncValue == -58 then
                cmd.viewangles = EulerAngles(cmd.viewangles.x, cmd.viewangles.y, roll)
            end
        elseif RUBY_ROLL_MODE:GetValue() == 1 then
            if flags == 262 and duck > 0.8 then
                cmd.viewangles = EulerAngles(cmd.viewangles.x, cmd.viewangles.y, math.random(-roll, roll))
            elseif duck > 0.8 then
                cmd.viewangles = EulerAngles(cmd.viewangles.x, cmd.viewangles.y, roll)
            end
        end
    end
end

RUBY.JUMPSCOUT = function ()
    local me = entities.GetLocalPlayer()
    if not me then return end

    local vel = math.sqrt(me:GetPropFloat("localdata", "m_vecVelocity[0]") ^ 2 + me:GetPropFloat("localdata", "m_vecVelocity[1]") ^ 2)

    if RUBY_JUMPSCOUT:GetValue() then
        if vel > 5 then
            gui.SetValue("misc.strafe.air", true)
        else
            gui.SetValue("misc.strafe.air", false)
        end
    end
end

RUBY.WARMUP = function ()
    local game_rules = entities.GetGameRules()
    local warmup = game_rules:GetPropBool("cs_gamerules_data", "m_bWarmupPeriod")
    local valve_server = game_rules:GetPropBool("cs_gamerules_data", "m_bIsValveDS")
    local me = entities.GetLocalPlayer()

    if not me then return end

    for _, v in pairs(RUBY.WARMUP_LIST) do
        if RUBY_WARMUP:GetValue() and warmup and valve_server then
            gui.SetValue(v, false)
        else
            gui.SetValue(v, true)
        end
    end
end


RUBY.AUTODISCONNECT = function (event)
    if not RUBY_AUTODISCONNECT:GetValue() then return end

	if event:GetName() == "cs_win_panel_match" then
        -- @soiderino: added movement fix 🔮
		client.Command("disconnect;-forward;-back;-duck;-moveleft;-moveright;-speed;-jump", true)
	end
end

RUBY.ANTIAFK = function ()
    if RUBY_ANTIAFK:GetValue() then
        client.Command("+left; +right", true)
    else
        client.Command("-left; -right", true)
    end
end


RUBY.WATERMARK = function ()
    if not RUBY_WATERMARK:GetValue() then
        return
    end

    draw.SetFont(RUBY.FONTS.verdana_bold)

    local getServer = engine.GetServerIP()

    getServer = getServer == nil and "disconnected" or (getServer == 'loopback' and 'local' or getServer:find("^=%[A") and "valve")

    local server = ""

    if entities.GetLocalPlayer() ~= nil then
		server = " / " .. getServer
	end

    local temp = draw.GetTextSize(CHEAT.VARS.aw_name .. server)

    local r, g, b, a = gui.GetValue("menu.visuals.ruby.watermark.color")

    draw.Color(r, g, b, a-180)
	draw.RoundedRectFill(RUBY.UI.screen_x-70-temp, 20, RUBY.UI.screen_x-25, 42, 0)
	draw.Color(r,g,b,a)
	draw.FilledRect(RUBY.UI.screen_x-70-temp, 18, RUBY.UI.screen_x-25, 20)
    draw.ShadowRect(RUBY.UI.screen_x-70-temp, 18, RUBY.UI.screen_x-25, 20, 5)
	draw.Color(255, 255, 255)
	draw.TextShadow(RUBY.UI.screen_x-66-temp, 27, "ruby / " .. CHEAT.VARS.aw_name .. server)
end


-- Callbacks
callbacks.Register('Draw', function ()
    RUBY.MENU()
    RUBY.WATERMARK()
    RUBY.INVERTER()
    RUBY.VIEWMODEL()
    RUBY.ASPECTRATIO()
    RUBY.ANTIAFK()
    RUBY.JUMPSCOUT()
    RUBY.WARMUP()
end)

callbacks.Register("CreateMove", function (cmd)
    RUBY.ROLL(cmd)
end)

callbacks.Register("FireGameEvent", function (event)
    RUBY.AUTODISCONNECT(event)
end)


callbacks.Register("Unload", function ()
    client.SetConVar("viewmodel_offset_x", 1, true)
    client.SetConVar("viewmodel_offset_y", 1, true)
    client.SetConVar("viewmodel_offset_z", -1, true)
    client.SetConVar("r_aspectratio", 0, true)
end)


-- Allow Listener's
client.AllowListener("cs_win_panel_match")


panorama.RunScript(
	[[LoadoutAPI.IsLoadoutAllowed = () => {return true;} ;]]
)
