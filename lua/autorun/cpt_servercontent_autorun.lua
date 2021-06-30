CreateConVar("sv_movementspeed",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Enables realistic movement speed")
CreateConVar("sv_movementspeed_walk",100,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_run",190,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_climb",30,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_jump",150,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_staminamax",500,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_staminadrain",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_staminadraintime",0.25,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_staminaregen",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_staminaregentime",0.5,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_movementspeed_staminaregendelay",15,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Movement Variable")
CreateConVar("sv_newspawns",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Enables custom spawn points on certain maps")
CreateConVar("sv_realisticvoice",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE,FCVAR_NOTIFY},"Enables realistic player speech distance")

game.AddParticles("particles/cpt_flamethrower.pcf")

player_manager.AddValidModel("Kotone Shiomi","models/persona_nk/minako/minako_p3.mdl")
player_manager.AddValidHands("Kotone Shiomi","models/player/dewobedil/persona/rise_kujikawa/c_arms/winter_p.mdl",0,"00000000")

if SERVER then
	resource.AddWorkshop("2159297560")
end

hook.Add("PlayerCanHearPlayersVoice","SVStuff_SetPlayerVoiceRange",function(listener,talker)
	if GetConVarNumber("sv_realisticvoice") == 0 then return true end
	if (listener:IsAdmin() or listener:IsSuperAdmin()) && (talker:IsAdmin() or talker:IsSuperAdmin()) then
		return true
	end
	if listener:GetPos():Distance(talker:GetPos()) > 1000 then -- Needs to be within 50 meters to be able to hear
		return false
	else
		return true
	end
end)

if SERVER then
	hook.Add("Think","SVStuff_Think",function()
		if GetConVarNumber("sv_movementspeed") == 1 then
			local wSpeed = GetConVarNumber("sv_movementspeed_walk")
			local rSpeed = GetConVarNumber("sv_movementspeed_run")
			local jPower = GetConVarNumber("sv_movementspeed_jump")
			local cSpeed = GetConVarNumber("sv_movementspeed_climb")
			local staminaMax = GetConVarNumber("sv_movementspeed_staminamax")
			local staminaDrain = GetConVarNumber("sv_movementspeed_staminadrain")
			local staminaDrainT = GetConVarNumber("sv_movementspeed_staminadraintime")
			local staminaRegen = GetConVarNumber("sv_movementspeed_staminaregen")
			local staminaRegenT = GetConVarNumber("sv_movementspeed_staminaregentime")
			local staminaRegenDelay = GetConVarNumber("sv_movementspeed_staminaregendelay")
			 for _,ply in pairs(player.GetAll()) do
				if ply:Health() <= 20 then
					wSpeed = wSpeed -(wSpeed *0.419)
					-- rSpeed = wSpeed
					rSpeed = rSpeed -(rSpeed *0.385)
					jPower = jPower -(jPower *0.45)
					cSpeed = cSpeed -(cSpeed *0.8)
				end
				local isRunning = (ply:KeyDown(IN_SPEED) && ply:Alive())
				if isRunning then
					if CurTime() > ply.SV_NextStaminaDrainT then
						ply.SV_Stamina = math.Clamp(ply.SV_Stamina -staminaDrain,0,staminaMax)
						ply.SV_NextStaminaDrainT = CurTime() +staminaDrainT
					end
					ply.SV_NextStaminaRegenDelayT = CurTime() +staminaRegenDelay
				else
					if CurTime() > ply.SV_NextStaminaRegenT && CurTime() > ply.SV_NextStaminaRegenDelayT then
						local mT = ply:GetMoveType()
						if (mT == MOVETYPE_WALK or mT == MOVETYPE_LADDER) && ply:GetVelocity():Length() <= 0 then
							staminaRegen = staminaRegen *2
							staminaRegenT = staminaRegenT *0.5
						end
						ply.SV_Stamina = math.Clamp(ply.SV_Stamina +staminaRegen,0,staminaMax)
						ply.SV_NextStaminaRegenT = CurTime() +staminaRegenT
					end
				end
				local halfStamina = staminaMax *0.5
				if ply.SV_Stamina <= halfStamina then
					ply.SV_StaminaVoice:Play()
					local pitch = 100 +(100 -(100 *(ply.SV_Stamina /halfStamina)))
					ply.SV_StaminaVoice:ChangePitch(pitch)
					ply.SV_StaminaVoice:ChangeVolume(1 -(ply.SV_Stamina /halfStamina))
				else
					ply.SV_StaminaVoice:Stop()
				end
				if ply.SV_Stamina <= staminaMax *0.15 then
					wSpeed = wSpeed -(wSpeed *0.3)
					rSpeed = rSpeed -(rSpeed *0.45)
					jPower = jPower -(jPower *0.6)
					cSpeed = cSpeed -(cSpeed *0.5)
				end
				-- ply:ChatPrint("Stamina - " .. ply.SV_Stamina)
				ply:SetWalkSpeed(math.Clamp(wSpeed,1,wSpeed))
				ply:SetRunSpeed(math.Clamp(rSpeed,1,rSpeed))
				ply:SetJumpPower(math.Clamp(jPower,1,jPower))
				ply:SetLadderClimbSpeed(math.Clamp(cSpeed,1,cSpeed))
			end
		end
	end)

	hook.Add("PlayerDeath","SVStuff_PlayerDeath",function(ply)
		if ply.SV_StaminaVoice then
			ply.SV_StaminaVoice:Stop()
		end
	end)

	hook.Add("PlayerInitialSpawn","SVStuff_PlayerInitialSpawn",function(ply)
		timer.Simple(0.1,function()
			ply:SetArmor(150)

			ply.SV_Stamina = GetConVarNumber("sv_movementspeed_staminamax")
			ply.SV_NextStaminaDrainT = CurTime()
			ply.SV_NextStaminaRegenT = CurTime()
			ply.SV_NextStaminaRegenDelayT = CurTime()

			ply.SV_StaminaVoice = CreateSound(ply,"player/breathe1.wav")
			ply.SV_StaminaVoice:SetSoundLevel(70)
			ply.SV_StaminaVoice:ChangeVolume(0)
		end)
	end)

	hook.Add("PlayerSpawn","SVStuff_PlayerSpawn",function(ply)
		timer.Simple(0.1,function()
			ply:SetArmor(150)
			-- ply:StripWeapons()
			-- ply:Give("weapon_fists")

			ply.SV_Stamina = GetConVarNumber("sv_movementspeed_staminamax")
			ply.SV_NextStaminaDrainT = CurTime()
			ply.SV_NextStaminaRegenT = CurTime()
			ply.SV_NextStaminaRegenDelayT = CurTime()

			ply.SV_StaminaVoice = CreateSound(ply,"player/breathe1.wav")
			ply.SV_StaminaVoice:SetSoundLevel(70)
			ply.SV_StaminaVoice:ChangeVolume(0)
		end)

		if GetConVarNumber("sv_newspawns") == 0 then
			return true
		end

		local function GetNeedle(tb)
			return tb[math.random(1,#tb)]
		end

		if game.GetMap() == "gm_atomic" then
			local tb_spawns = {
				[1] = Vector(-8838.501953,-1877.733032,-12253.894531),
				[2] = Vector(-9856.744141,-2452.219971,-12259.383789),
				[3] = Vector(-7988.878906,-2630.843750,-12257.968750)
			}
			ply:SetPos(GetNeedle(tb_spawns))
		elseif game.GetMap() == "rp_eve_atomic" then
			local tb_spawns = {
				[1] = Vector(4233.028320,-11393.541016,-11898.149414),
				[2] = Vector(3747.280762,-12280.607422,-11897.968750),
				[2] = Vector(3706.919189,-11074.775391,-11896.901367),
				[2] = Vector(1810.606445,-11866.365234,-11887.768555),
				[2] = Vector(2036.859619,-11831.431641,-11887.768555),
				[2] = Vector(6237.832031,-11507.856445,-11824.96875),
			}
			ply:SetPos(GetNeedle(tb_spawns))
		elseif game.GetMap() == "gm_nuclear_winter_v2" then
			local tb_spawns = {
				[1] = Vector(-1121.436523,-3792.415039,-13763.013672),
				[2] = Vector(-6950.273926,-7959.828125,-13708.968750),
				[3] = Vector(-2892.562500,943.685608,-13266.369141),
				[4] = Vector(-12493.905273,2850.126709,-13766.369141),
				[5] = Vector(-11943.241211,-7125.512207,-13766.268555),
				[6] = Vector(-10538.704102,-11708.960938,-13644.968750),
				[7] = Vector(8728.959961,-12423.459961,-13766.369141),
				[8] = Vector(4257.935547,1410.394043,-13375.968750),
			}
			ply:SetPos(GetNeedle(tb_spawns))
		elseif game.GetMap() == "desertdiner" then
			local tb_spawns = {
				[1] = Vector(-1217.619141,5404.813477,139),
				[2] = Vector(-1476.452515,5410.621094,139),
				[3] = Vector(-1725.927734,5414.823242,139),
				[4] = Vector(-1981.624634,5416.550293,139),
			}
			ply:SetPos(GetNeedle(tb_spawns))
		elseif game.GetMap() == "gm_boreas" then
			local tb_spawns = {
				[1] = Vector(-8819.687500,-15486.244141,-10496.659180),
				[2] = Vector(-8696.804688,-15480.103516,-10496.72168),
				[3] = Vector(-8910.791992,-15490.794922,-10496.72753),
				[4] = Vector(-9020.353516,-15501.905273,-10496.91406),
			}
			ply:SetPos(GetNeedle(tb_spawns))
			ply:SetAngles(Angle(0,94,0))
		elseif game.GetMap() == "v_h01" then
			local tb_spawns = {
				[1] = Vector(2342.586182,1.549212,448.031250),
			}
			ply:SetPos(GetNeedle(tb_spawns))
		elseif game.GetMap() == "zs_mall_v2" then
			-- for _,v in ipairs(ents.GetAll()) do -- Crashes
				-- if (v:GetClass() == "npc_maker") then
					-- v:Remove()
				-- end
			-- end
		elseif game.GetMap() == "gm_site19" then
			local tb_spawns = {
				[1] = Vector(-1865.967651,1966.947266,128.031250),
				[2] = Vector(-1847.048096,1618.584595,128.031250),
				[3] = Vector(-1736.233765,1969.569580,128.031250),
				[4] = Vector(-1716.670410,1617.182007,128.031250),
				[5] = Vector(-1611.080811,1949.321777,128.031250),
				[6] = Vector(-1586.643677,1613.107666,128.031250),
				[7] = Vector(-1612.911377,1951.349854,128.031250),
				[8] = Vector(-1843.785645,1625.763916,128.031250),
				[9] = Vector(-825.649109,13.598735,224.031250),
				[10] = Vector(-320.933990,860.103577,0.031250),
				[11] = Vector(2692.071533,4.769185,0.031250),
				[12] = Vector(-825.649109,13.598735,224.031250),
				[13] = Vector(1160.489990,526.396362,0.031250),
				[14] = Vector(-674.742554,2958.544922,18.150749),
				[15] = Vector(1487.773193,2911.925781,64.031250),
			}
			ply:SetPos(GetNeedle(tb_spawns))
		end
	end)
end