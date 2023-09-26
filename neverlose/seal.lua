---@diagnostic disable: undefined-global, lowercase-global

_DEBUG = true


local raw_hwnd                                           = utils.opcode_scan("engine.dll",
	"8B 0D ? ? ? ? 85 C9 74 16 8B 01 8B") or error("Invalid signature #1")
local raw_insn_jmp_ecx                                   = utils.opcode_scan("gameoverlayrenderer.dll", "FF E1") or
	error("Invalid signature #2")
local raw_FlashWindow                                    = utils.opcode_scan("gameoverlayrenderer.dll",
	"55 8B EC 83 EC 14 8B 45 0C F7") or error("Invalid signature #3")
local raw_GetForegroundWindow                            = utils.opcode_scan("gameoverlayrenderer.dll",
	"FF 15 ? ? ? ? 3B C6 74") or error("Invalid signature #4")

local hwnd_ptr                                           = ((ffi.cast("uintptr_t***", ffi.cast("uintptr_t", raw_hwnd) + 2)[0])[0] + 2)
local FlashWindow                                        = ffi.cast("int(__stdcall*)(uintptr_t, int)", raw_FlashWindow)
local insn_jmp_ecx                                       = ffi.cast("int(__thiscall*)(uintptr_t)", raw_insn_jmp_ecx)
local GetForegroundWindow                                = (ffi.cast("uintptr_t**", ffi.cast("uintptr_t", raw_GetForegroundWindow) + 2)[0])
	[0]

local font1                                              = render.load_font("verdana", 16, "ao")
local font2                                              = render.load_font("verdana", vector(10, 10, 1), "ad")

local ui                                                 = require 'neverlose/pui'
local smoothy                                            = require 'neverlose/smoothy'
local animations                                         = require 'neverlose/animations'
local gradient                                           = require 'neverlose/gradient'

local hitgroup_str                                       = {
	[0] = "generic",
	"head",
	"chest",
	"stomach",
	"left arm",
	"right arm",
	"left leg",
	"right leg",
	"neck",
	"generic",
	"gear"
}

local nl_ragebot                                         = ui.find("Aimbot", "Ragebot", "Main", "Enabled")
local nl_fakelag                                         = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled")
local nl_desync                                          = ui.find("Aimbot", "Anti Aim", "Angles", "Enabled")
local nl_scope                                           = ui.find("Visuals", "World", "Main", "Override Zoom",
	"Scope Overlay")
local nl_autostrafe                                      = ui.find("Miscellaneous", "Main", "Movement", "Air Strafe")
local nl_leg                                             = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement")

local last_realtime                                      = 0
local last_queue_string                                  = ""
local alpha, offset, length, velocityalpha, velocitymenu = smoothy.new(0), smoothy.new(0), smoothy.new(0), smoothy.new(0),
	smoothy.new(0)
local pos, w                                             = render.screen_size() * .5, 1
local indicator_pos                                      = render.screen_size() / 2

local SEAL, NOTIFICATION, INDICATORS                     = {}, {}, {}

SEAL.UI                                                  = {
	username = common.get_username(),
	lastupdate = "1.08.2023",
	build = "debug"
}

NOTIFICATION.TYPE                                        = {
	"Round Start",
	"Match Found",
}

INDICATORS.LIST                                          = {
	"🎯 Desync Sides",
	"🐌 Velocity Warning"
}



local info = ui.create("🌊 Main", "🍂 info", 1)
local main = ui.create("🌊 Main", "🍂 main", 1)
local visuals = ui.create("🌊 Main", "🍂 visuals", 2)
local misc = ui.create("🌊 Main", "🍂 misc", 2)

local menu = {

	info = {
		username = ui.label(info, ""),
		lastupdate = ui.label(info, "")
	},

	main = {
		roll = ui.switch(main, "👻 Extended Angles", false, nil),
		jumpfix = ui.switch(main, "🐰 Jumpscout Fix", false, nil),
		legbreaker = ui.switch(main, "😎 Leg Breaker", false, nil),
	},

	misc = {
		autodisconnect = ui.switch(misc, "🚪 Auto Disconnect", false, nil, function(gear)
			return {
				autodisconnect_delay = gear:slider("Delay", 1, 10, 7, 0.1, "s")
			}
		end),
		antiafk = ui.switch(misc, "😴 Anti AFK", false, nil),
		warmupdisabler = ui.switch(misc, "🔥 Warmup Disabler", false, nil),
		fpsboost = ui.switch(misc, "📈 FPS Boost", false, nil),
		flashnotification = ui.selectable(misc, "📢 Flash Notifications", NOTIFICATION.TYPE, 0),
	},

	visuals = {
		viewmodel = ui.switch(visuals, "🤚 Viewmodel Changer", false, nil, function(gear)
			return {
				viewmodel_fov = gear:slider("FOV", 60, 120, cvar.viewmodel_fov:int()),
				viewmodel_x = gear:slider("X", -35, 35, cvar.viewmodel_offset_x:float()),
				viewmodel_y = gear:slider("Y", -35, 35, cvar.viewmodel_offset_y:float()),
				viewmodel_z = gear:slider("Z", -35, 35, cvar.viewmodel_offset_z:float()),
			}
		end),
		aspectratio = ui.switch(visuals, "📺 Aspect Ratio", false, nil, function(gear)
			return {
				aspectratio_value = gear:slider("Aspect Ratio", 0, 50, cvar.r_aspectratio:float(), 0.1),
			}
		end),
		logs = ui.switch(visuals, "📜 Logs", false, nil, function(gear)
			return {
				log_color = gear:color_picker("Log Color", color(60, 240, 213)),
			}
		end),
		indicators = ui.switch(visuals, "🧪 Indicators", false, nil, function(gear)
			return {
				indicator_list = gear:listable("Indicator List", INDICATORS.LIST)
			}
		end),
		scopelines = ui.switch(visuals, "🦋 Scope Lines", false, nil, function(gear)
			return {
				scope_invert = gear:switch("Color", false, "Enable to invert colors", color(255, 155)),
				scope_offset = gear:slider("Offset", 0, 50, 10),
				scope_length = gear:slider("Length", 0, 200, 50),
			}
		end),
	},

}


local function sidebar()
	local sidebar_text = gradient.text_animate("seal " .. SEAL.UI.build, 1, {
		ui.get_style()["Link Active"],
		color(187, 196, 255)
	})

	ui.sidebar(sidebar_text:get_animated_text(), "\f<leaf>")

	sidebar_text:animate()
end



local function get_csgo_hwnd()
	return hwnd_ptr[0]
end

local function get_foreground_hwnd()
	return insn_jmp_ecx(GetForegroundWindow)
end

local function notfiy_user()
	local csgo_hwnd = get_csgo_hwnd()
	if get_foreground_hwnd ~= csgo_hwnd then
		FlashWindow(csgo_hwnd, 1)
		return true
	end
	return false
end


local function legbreaker()
	if menu.main.legbreaker:get() then
		p = math.random(1, 2)
		if p == 1 then
			nl_leg:set("sliding")
		elseif p == 2 then
			nl_leg:set("walking")
		end
	end
end


local function antiafk()
	if menu.misc.antiafk:get() then
		utils.console_exec("+left;+right")
	else
		utils.console_exec("-left;-right")
	end
end

local function warmupdisabler()
	local me = entity.get_local_player()

	if me == nil then
		return
	end

	if menu.misc.warmupdisabler:get() and entity.get_game_rules()['m_bWarmupPeriod'] then
		nl_desync:set(false)
		nl_fakelag:set(false)
		nl_ragebot:set(false)
	else
		nl_desync:set(true)
		nl_fakelag:set(true)
		nl_ragebot:set(true)
	end
end


local function jumpfix()
	local me = entity.get_local_player()

	if me == nil then return end

	local vel = math.sqrt(me["m_vecVelocity[0]"] ^ 2 + me["m_vecVelocity[1]"] ^ 2)

	if menu.main.jumpfix:get() then
		if vel > 5 then
			nl_autostrafe:set(true)
		else
			nl_autostrafe:set(false)
		end
	end
end

local function velocitywarning()
	local player = entity.get_local_player()

	if player == nil or not player:is_alive() then return end

	local vel = ui.get_alpha() > 0 and player.m_flVelocityModifier == 1 and 1 - ui.get_alpha() / 2 or
		player:is_alive() and player.m_flVelocityModifier or 1

	local menu_a = velocitymenu(.05, menu.visuals.indicators.indicator_list:get(2))
	local alpha = velocityalpha(.05, ((ui.get_alpha() > 0 and 150 or vel ~= 1 and 255) or 0)) * menu_a

	if menu_a < 0.1 then
		return
	end

	if menu.visuals.indicators:get() and menu.visuals.indicators.indicator_list:get(2) then
		render.text(1, vector(indicator_pos.x, indicator_pos.y - 250), color(255, 255, 255, alpha), "c",
			tostring("🐌 slowed down: %s%%"):format(math.floor(100 - vel * 100)))
	end
end

local function indicator()
	local me = entity.get_local_player()
	local state = menu.visuals.indicators.indicator_list:get(1) and me ~= nil and me:is_alive()

	local ragebot_target = entity.get_threat(false)
	if ragebot_target == nil then
		ragebot_target = "nil"
	else
		ragebot_target = ragebot_target:get_name()
	end

	if not state then return end

	local indicator_pos_anim = animations.new("first indicator pose", indicator_pos.y):update(animations.types.LERP,
		me.m_bIsScoped and indicator_pos.y + 25 or indicator_pos.y)

	if menu.visuals.indicators:get() and menu.visuals.indicators.indicator_list:get(1) then
		render.text(font1, vector(indicator_pos.x, indicator_pos_anim - .5), color(255, 255, 255), "c",
			rage.antiaim:inverter() and "❮			" or "			❯")
	end
end


local function scopelines()
	nl_scope:override(menu.visuals.scopelines:get() and "Remove All" or nil)

	local me = entity.get_local_player()
	local state = menu.visuals.scopelines:get() and me ~= nil and me:is_alive() and me.m_bIsScoped

	alpha(.05, state)
	offset(.05, menu.visuals.scopelines.scope_offset:get() * alpha.value)
	length(.05, menu.visuals.scopelines.scope_length:get() * alpha.value)

	if not state and alpha.value == 0 then
		return
	end

	local color = menu.visuals.scopelines.scope_invert.color.value
	local one, two = color:alpha_modulate(menu.visuals.scopelines.scope_invert:get() and 0 or (color.a * alpha.value)),
		color:alpha_modulate(menu.visuals.scopelines.scope_invert:get() and (color.a * alpha.value) or 0)

	render.gradient(vector(pos.x - offset.value + w, pos.y), vector(pos.x - offset.value - length.value + w, pos.y + w),
		one, two, one, two)
	render.gradient(vector(pos.x + offset.value, pos.y), vector(pos.x + offset.value + length.value, pos.y + w), one, two,
		one, two)
	render.gradient(vector(pos.x, pos.y + offset.value), vector(pos.x + w, pos.y + offset.value + length.value), one, one,
		two, two)
	render.gradient(vector(pos.x, pos.y - offset.value + w), vector(pos.x + w, pos.y - offset.value - length.value + w),
		one, one, two, two)
end


local function viewmodel()
	local fov = menu.visuals.viewmodel.viewmodel_fov:get()
	local v_x = menu.visuals.viewmodel.viewmodel_x:get()
	local v_y = menu.visuals.viewmodel.viewmodel_y:get()
	local v_z = menu.visuals.viewmodel.viewmodel_z:get()

	if menu.visuals.viewmodel:get() then
		cvar.viewmodel_fov:int(fov, true)
		cvar.viewmodel_offset_x:float(v_x, true)
		cvar.viewmodel_offset_y:float(v_y, true)
		cvar.viewmodel_offset_z:float(v_z, true)
	else
		cvar.viewmodel_fov:int(60, true)
		cvar.viewmodel_offset_x:float(0, true)
		cvar.viewmodel_offset_y:float(0, true)
		cvar.viewmodel_offset_z:float(0, true)
	end
end


local function aspectratio()
	if menu.visuals.aspectratio:get() then
		cvar.r_aspectratio:float(menu.visuals.aspectratio.aspectratio_value:get() / 10, true)
	else
		cvar.r_aspectratio:float(0, true)
	end
end


local function roll(cmd)
	local me = entity.get_local_player()
	if me == nil then return end
	local weapon = me:get_player_weapon()
	if weapon == nil then return end
	local weapon_name = weapon:get_weapon_info().weapon_name
	if weapon_name == nil then return end

	if menu.main.roll:get() then
		if weapon_name == "weapon_hegrenade" or weapon_name == "weapon_smokegrenade" or weapon_name == "weapon_incgrenade" or weapon_name == "weapon_molotov" then return end -- fuck roll when holding nades :D

		if me.m_MoveType == 9 then return end
		if me.m_MoveType == 8 then return end

		cmd.view_angles.z = (rage.antiaim:inverter() and -45 or 45)
	end
end


local hitlogs = {}

local function aimack(shot)
	local log_color = menu.visuals.logs.log_color:get():to_hex()
	shot.spread = shot.spread ~= nil and shot.spread or 0.1
	if not menu.visuals.logs:get() then return end
	if shot.state == nil then
		text = ("\aFFFFFFHit \a" .. log_color:sub(1, 6) .. "%s \aFFFFFFin the \a" .. log_color:sub(1, 6) .. "%s\aFFFFFF for \a" .. log_color:sub(1, 6) .. "%d\affffff(%d) \aFFFFFFdamage (hc: %s%% · bt: %st)")
			:format(
				tostring(shot.target:get_name()), hitgroup_str[shot.hitgroup], shot.damage, shot.wanted_damage,
				shot.hitchance, shot.backtrack
			)

		text_event = ("\affffffffHit \a" .. log_color .. "%s \affffffffin the \a" .. log_color .. "%s\affffffff for \a" .. log_color .. "%d\affffffff(%d) \affffffffdamage (hc: %s%% · bt: %st)")
			:format(
				tostring(shot.target:get_name()), hitgroup_str[shot.hitgroup], shot.damage, shot.wanted_damage,
				shot.hitchance, shot.backtrack
			)

		print_raw(text)

		table.insert(hitlogs, { text = text_event, time = globals.realtime })
	else
		text = ("\affffffMissed \afa5050%s \aFFFFFFin the \afa5050%s\aFFFFFF due to \afa5050%s\aFFFFFF (hc: %s%% · bt: %st)")
			:format(
				tostring(shot.target:get_name()), hitgroup_str[shot.wanted_hitgroup], shot.state, shot.hitchance,
				shot.backtrack
			)

		text_event = ("\affffffffMissed \afa5050ff%s \affffffffin the \afa5050ff%s\aFFFFFFFF due to \afa5050ff%s\aFFFFFFFF (hc: %s%% · bt: %st)")
			:format(
				tostring(shot.target:get_name()), hitgroup_str[shot.wanted_hitgroup], shot.state, shot.hitchance,
				shot.backtrack
			)

		print_raw(text)
		table.insert(hitlogs, { text = text_event, time = globals.realtime })
	end
end

local function on_screen_render()
	local y = render.screen_size().y / 2
	local me = entity.get_local_player()

	if me == nil then return end

	for i, hitlog in ipairs(hitlogs) do
		render.text(font2, vector(indicator_pos.x, y + 50), color(255, 255, 255), "c", hitlog.text)
		y = y + 15
		if hitlog.time + 5 < globals.realtime or #hitlogs > 5 then
			table.remove(hitlogs, i)
		end
	end
end


events.aim_ack:set(function(shot)
	aimack(shot)
end)

events.render:set(function()
	sidebar()
	scopelines()
	viewmodel()
	aspectratio()
	indicator()
	warmupdisabler()
	jumpfix()
	antiafk()
	on_screen_render()
	velocitywarning()
	legbreaker()

	if not menu.misc.flashnotification:get() == "Match Found" then
		return
	end

	local realtime = globals.realtime

	if realtime >= last_realtime then
		local queue_string = panorama.loadstring("return PartyListAPI.GetPartySessionSetting('game/mmqueue')")()

		if last_queue_string ~= "reserved" and queue_string == "reserved" then
			notfiy_user()
		end

		last_queue_string = queue_string
		last_realtime = realtime + 1
	end

	menu.info.username:name("🦑 Username, \v" .. SEAL.UI.username)
	menu.info.lastupdate:name("📅 Last Update: \v" .. SEAL.UI.lastupdate)
end)

events.round_start:set(function()
	if not menu.misc.flashnotification:get() == "Round Start" then
		return
	end

	notfiy_user()
end)

events.createmove:set(function(cmd)
	roll(cmd)
end)

events.cs_win_panel_match:set(function()
	if menu.misc.autodisconnect:get() then
		utils.execute_after(tonumber(menu.misc.autodisconnect.autodisconnect_delay:get()), function()
			utils.console_exec("disconnect;-forward;-back;-duck;-moveleft;-moveright;-speed;-jump");
		end)
	end
end)

events.shutdown:set(function()
	cvar.viewmodel_fov:int(60, true)
	cvar.viewmodel_offset_x:float(0, true)
	cvar.viewmodel_offset_y:float(0, true)
	cvar.viewmodel_offset_z:float(0, true)
	cvar.r_aspectratio:float(0, true)
end)

ui.setup(menu)
