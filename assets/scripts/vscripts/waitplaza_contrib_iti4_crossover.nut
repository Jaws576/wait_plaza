///////////////////////////////////////////////
// soda machine

const SODAMACHINE_CLUNK = "ambient/levels/canals/headcrab_canister_open1.wav"
const SODAMACHINE_DRINK = "player/pl_scout_dodge_can_drink.wav"
PrecacheScriptSound(SODAMACHINE_CLUNK)
PrecacheScriptSound(SODAMACHINE_DRINK)

function PlayerDrinkSound() {
	local sound_drink = {
		sound_name = SODAMACHINE_DRINK
		sound_level = 70
		entity = activator
		pitch = 100
		special_dsp = 1
		filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_DEFAULT
	}
	EmitSoundEx(sound_drink)
}

function SodaEffect_Invuln() {
	activator.AddCustomAttribute("dmg taken increased", 0.001, 0)
	//activator.AddCustomAttribute("cancel falling damage", 1, 0)
	EntFireByHandle(activator, "AddContext", "soda_effect:yes")
}

function SodaEffect_Haste() {
	activator.AddCond(Constants.ETFCond.TF_COND_SPEED_BOOST)
	activator.AddCond(Constants.ETFCond.TF_COND_KING_BUFFED)
}

function OnSodaMachineUse(drink_type) {
	local context = activator.GetContext("used_soda_machine")
	if (context == "yes")
		return

	switch (drink_type) {
		case "invuln":
			EntFireByHandle(self, "CallScriptFunction", "SodaEffect_Invuln", 3.5, activator)
			break
		case "haste":
			EntFireByHandle(self, "CallScriptFunction", "SodaEffect_Haste", 3.5, activator)
			break
	}
	EntFireByHandle(activator, "AddContext", "used_soda_machine:yes:5.0")
	
	local sound_machine = {
		sound_name = SODAMACHINE_CLUNK
		sound_level = 70
		entity = caller
		pitch = 100
		special_dsp = 1
		filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_DEFAULT
	}
	EmitSoundEx(sound_machine)
	EntFireByHandle(self, "CallScriptFunction", "PlayerDrinkSound", 2.0, activator)
}

StopListeningToAllGameEvents("hook_playerdeath_soda")
function StripSodaEffects(params) {
	local player = GetPlayerFromUserID(params.userid)
	player.RemoveCustomAttribute("dmg taken increased")
	//player.RemoveCustomAttribute("cancel falling damage")
	
	player.SetModelScale(1, 0)
	
	EntFireByHandle(player, "RemoveContext", "soda_effect")
}
ListenToGameEvent("player_death", StripSodaEffects, "hook_playerdeath_soda")

StopListeningToAllGameEvents("crossroads_spawn_damagefilter")
function SetSodaDamageFilter(params) {
	//printl("SetSodaDamageFilter")
	local player = GetPlayerFromUserID(params.userid)
	EntFireByHandle(player, "SetDamageFilter", "filter_soda")
}
ListenToGameEvent("player_spawn", SetSodaDamageFilter, "crossroads_spawn_damagefilter")

StopListeningToAllGameEvents("crossroads_antigrief")
function KillPlayerStunningNonInvuln(params) {
	//printl("in player stunned")
	local victim = GetPlayerFromUserID(params.victim)
	if (victim.GetContext("soda_effect") == "yes") {
		// would try to remove stun here
		return
	}
	// player doesnt have invuln past this point
	
	if ("stunner" in params) {
		local stunner = GetPlayerFromUserID(params.stunner)
		if (stunner.GetContext("soda_effect") != "yes")
			return
		stunner.RemoveCustomAttribute("dmg taken increased")
		stunner.TakeDamage(99999, 8192, stunner)
	}
}
ListenToGameEvent("player_stunned", KillPlayerStunningNonInvuln, "crossroads_antigrief")
