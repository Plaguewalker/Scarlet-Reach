// Necrite
/obj/effect/proc_holder/spell/targeted/burialrite
	name = "Burial Rites"
	range = 5
	overlay_state = "consecrateburial"
	releasedrain = 30
	recharge_time = 30 SECONDS
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	max_targets = 0
	cast_without_targets = TRUE
	sound = 'sound/magic/churn.ogg'
	associated_skill = /datum/skill/magic/holy
	invocation = "Undermaiden grant thee passage forth and spare the trials of the forgotten."
	invocation_type = "whisper" //can be none, whisper, emote and shout
	miracle = TRUE
	devotion_cost = 5 //very weak spell, you can just make a grave marker with a literal stick

/obj/effect/proc_holder/spell/targeted/burialrite/cast(list/targets, mob/user = usr)
	. = ..()
	var/success = FALSE
	for(var/obj/structure/closet/crate/coffin/coffin in view(1))
		success = pacify_coffin(coffin, user)
		if(success)
			user.visible_message("[user] consecrates [coffin]!", "My funeral rites have been performed on [coffin]!")
			return
	for(var/obj/structure/closet/dirthole/hole in view(1))
		success = pacify_coffin(hole, user)
		if(success)
			user.visible_message("[user] consecrates [hole]!", "My funeral rites have been performed on [hole]!")
			return
	to_chat(user, span_red("I failed to perform the rites."))

/obj/effect/proc_holder/spell/targeted/churn
	name = "Churn Undead"
	range = 4	//Way lower, halved.
	overlay_state = "necra"
	releasedrain = 30
	chargetime = 2 SECONDS
	recharge_time = 60 SECONDS
	max_targets = 0
	cast_without_targets = TRUE
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	sound = 'sound/magic/churn.ogg'
	associated_skill = /datum/skill/magic/holy
	invocation = "The Undermaiden rebukes!"
	invocation_type = "shout" //can be none, whisper, emote and shout
	miracle = TRUE
	devotion_cost = 50

/obj/effect/proc_holder/spell/targeted/churn/cast(list/targets,mob/living/user = usr)
	var/prob2explode = 100
	if(user && user.mind)
		prob2explode = 0
		for(var/i in 1 to user.get_skill_level(/datum/skill/magic/holy))
			prob2explode += 30
	for(var/mob/living/L in targets)
		var/isvampire = FALSE
		var/iszombie = FALSE
		if(L.stat == DEAD)
			continue
		if(L.mind)
			var/datum/antagonist/vampirelord/lesser/V = L.mind.has_antag_datum(/datum/antagonist/vampirelord/lesser)
			if(V)
				if(!V.disguised)
					isvampire = TRUE
			if(L.mind.has_antag_datum(/datum/antagonist/zombie))
				iszombie = TRUE
			if(L.mind.special_role == "Vampire Lord" || L.mind.special_role == "Lich")	//Won't detonate Lich's or VLs but will fling them away.
				user.visible_message(span_warning("[L] overpowers being churned!"), span_userdanger("[L] is too strong, I am churned!"))
				user.Stun(50)
				user.throw_at(get_ranged_target_turf(user, get_dir(user,L), 7), 7, 1, L, spin = FALSE)
				return
		if((L.mob_biotypes & MOB_UNDEAD) || isvampire || iszombie)
			var/vamp_prob = prob2explode
			if(isvampire)
				vamp_prob -= 59
			if(prob(vamp_prob))
				L.visible_message("<span class='warning'>[L] has been churned by Necra's grip!", "<span class='danger'>I've been churned by Necra's grip!")
				explosion(get_turf(L), light_impact_range = 1, flame_range = 1, smoke = FALSE)
				L.Stun(50)
			else
				L.visible_message(span_warning("[L] resists being churned!"), span_userdanger("I resist being churned!"))
	..()
	return TRUE

/obj/effect/proc_holder/spell/invoked/deaths_door
	name = "Death's Door"
	range = 7
	no_early_release = TRUE
	charging_slowdown = 1
	releasedrain = 20
	chargedrain = 0
	overlay_state = "speakwithdead"
	chargetime = 2 SECONDS
	chargedloop = null
	sound = 'sound/misc/deadbell.ogg'
	invocation = "Necra, show me my destination!"
	invocation_type = "shout"
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = TRUE
	recharge_time = 180 SECONDS
	miracle = TRUE
	devotion_cost = 30

/obj/effect/proc_holder/spell/invoked/deaths_door/cast(list/targets, mob/living/user)
	..()
	var/turf/T = get_turf(targets[1])
	if(!isopenturf(T))
		to_chat(user, span_warning("The targeted location is blocked. I cannot open a doorway here."))
		return FALSE
	for (var/obj/structure/underworld_portal/e_portal in user.contents) // checks if the portal exists, and shits them out
		if(istype(e_portal))
			e_portal.dispelled = FALSE //we are recasting after dispelling, its safe to set this as false.
			e_portal.spitout_mob(user, T)
			return TRUE
	if(!locate(/obj/structure/underworld_portal) in T)
		var/obj/structure/underworld_portal/portal = new /obj/structure/underworld_portal(T)
		portal.caster = user
		return TRUE


/obj/structure/underworld_portal
	name = "underworld portal"
	desc = null // see examine
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "shitportal" //get a better sprite for this
	max_integrity = 50
	move_resist = MOVE_FORCE_EXTREMELY_STRONG
	anchored = TRUE
	density = FALSE
	var/mob/living/caster // stores the caster. obviously.
	var/list/trapped = list()// stores the trapped.
	var/time_id
	var/dispelled = FALSE //Safety check

/obj/structure/underworld_portal/examine(mob/living/carbon/user)
	. = ..()
	if(user.mob_biotypes & MOB_UNDEAD)
		. += "A temporary gateway to the underworld. [span_warning("Faintly, you can see clutching fingers in the dark, reaching for you. If you go through, you won't come back.")]"
	else
		. += "A temporary gateway to the underworld. You can hear faint whispers through it. [span_warning("It might be possible to step through.")]"

/obj/structure/underworld_portal/attack_hand(mob/living/carbon/user, list/modifiers)
	..()
	if(user == caster)
		for (var/thing in contents)
			if (istype(thing, /mob/living/carbon))
				caster.contents.Add(src)
				dispelled = TRUE
				user.visible_message(
					span_revenwarning("[user] dispels the doorway with a touch."),
					span_purple("I close the gateway. Opening it again will release whatever is inside.")
					)
				return TRUE
		qdel(src)
		return TRUE
	if(!do_after(user, 2 SECONDS, src))
		return
	gobble_mob(user, caster)
	return TRUE


/obj/structure/underworld_portal/Destroy()
	if(dispelled == FALSE)//Only do this if we DON'T close it ourselves,that means something ELSE -FUNNY- happend.
		visible_message(span_revenwarning("The portal collapses with an angry hiss."))
		if(trapped)
			for(var/mob/living/inportal in trapped)
				spitout_mob(inportal, src.loc)
	..()

/obj/structure/underworld_portal/attack_right(mob/living/carbon/user, list/modifiers)
	..()
	if(user == caster)
		if(trapped)
			for(var/mob/living/inportal in trapped)
				spitout_mob(inportal)
				user.visible_message(
							span_revenwarning("[user] gestures thier hand at the gateway to expel what is within."),
							span_purple("I gesture at the gateway to release whatever is inside.")
							)
			return TRUE

/obj/structure/underworld_portal/MouseDrop_T(atom/movable/O, mob/living/user)
	if(!isliving(O))
		return
	if(!istype(user) || user.incapacitated())
		return
	if(!Adjacent(user) || !user.Adjacent(O))
		return
	if(!do_after_mob(user, O, 5 SECONDS))
		return
	gobble_mob(O)
	user.visible_message(
		span_warning("[user] forces [O] into the portal!")
	)
	return TRUE

/obj/structure/underworld_portal/proc/gobble_mob(mob/living/carbon/user, mob/living/carbon/caster)
	if(user.mob_biotypes & MOB_UNDEAD)
		user.visible_message(
			span_warning("[user] is suddenly grabbed by a massive hand-and pulled through!"),
			span_userdanger("Touching the portal, the Carriageman's hand closes around my own! No! NO!")
			)
		playsound(user, 'sound/misc/deadbell.ogg', 50, TRUE, -2, ignore_walls = TRUE)
		new /obj/effect/gibspawner/generic(get_turf(user))
		qdel(user)
		return TRUE

	user.visible_message(
		span_revenwarning("[user] slips through the portal. Silence follows."),
		span_purple("I touch the doorway. I slip through, and the world is silent and dark. I hear the distant rattle of a passing carriage.")
		)
	trapped += user
	user.forceMove(src)
	ADD_TRAIT(user, TRAIT_BLOODLOSS_IMMUNE, STATUS_EFFECT_TRAIT)
	ADD_TRAIT(user, TRAIT_NOBREATH, STATUS_EFFECT_TRAIT)
	user.add_client_colour(/datum/client_colour/monochrome)
	time_id = addtimer(CALLBACK(src, PROC_REF(spitout_mob), user, null), 5 MINUTES, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE) // 5 mins timer else its spitting you out where the necran is.
	return TRUE

/obj/structure/underworld_portal/proc/spitout_mob(mob/living/carbon/user, turf/T)
	if(!trapped)
		return FALSE
	if(src in user.contents)
		forceMove(T)

	if(dispelled == TRUE)//dispelled at the caster, this is the case of we do not recast out dispelled portal and its been five minutes.
		user.forceMove(caster.loc)
		dispelled = FALSE
	else
		user.forceMove(loc)
	if(time_id)
		deltimer(time_id)
	user.visible_message(
		span_revenwarning("[user] slips out from the whispering portal. Shadow roils off their form like smoke."),
		span_purple("I am pulled from Necra's realm. Air fills my lungs, my heart starts beating- I live.")
		)
	user.remove_client_colour(/datum/client_colour/monochrome)
	REMOVE_TRAIT(user, TRAIT_BLOODLOSS_IMMUNE, STATUS_EFFECT_TRAIT)
	REMOVE_TRAIT(user, TRAIT_NOBREATH, STATUS_EFFECT_TRAIT)
	trapped -= user
	return TRUE

/obj/structure/underworld_portal/container_resist(mob/living/user)
	..()
	if(trapped != user)
		return
	var/resist_prob = user.STASTR * 2.5
	if(!prob(resist_prob))
		return
	spitout_mob(user)


/obj/effect/proc_holder/spell/targeted/soulspeak
	name = "Speak with Soul"
	range = 5
	overlay_state = "speakwithdead"
	releasedrain = 30
	recharge_time = 30 SECONDS
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	max_targets = 0
	cast_without_targets = TRUE
	sound = 'sound/magic/churn.ogg'
	associated_skill = /datum/skill/magic/holy
	invocation = "She-Below brooks thee respite, be heard, wanderer."
	invocation_type = "whisper" //can be none, whisper, emote and shout
	miracle = TRUE
	devotion_cost = 30

/obj/effect/proc_holder/spell/targeted/soulspeak/cast(list/targets,mob/user = usr)
	var/mob/living/carbon/spirit/capturedsoul = null
	var/list/souloptions = list()
	var/list/itemstore = list()
	for(var/mob/living/carbon/spirit/S in GLOB.mob_list)
		if(S.summoned)
			continue
		if(!S.client)
			continue
		souloptions += S.livingname
	var/pickedsoul = input(user, "Which wandering soul shall I commune with?", "Available Souls") as null|anything in souloptions
	if(!pickedsoul)
		to_chat(user, span_warning("I was unable to commune with a soul."))
		return
	for(var/mob/living/carbon/spirit/P in GLOB.mob_list)
		if(P.livingname == pickedsoul)
			to_chat(P, "<font color='blue'>You feel yourself being pulled out of the Underworld.</font>")
			sleep(2 SECONDS)
			if(QDELETED(P) || P.summoned)
				to_chat(user, "<font color='blue'>Your connection to the soul suddenly disappears!</font>")
				return
			capturedsoul = P
			break
	if(capturedsoul)
		for(var/obj/item/I in capturedsoul.held_items) // this is still ass
			capturedsoul.temporarilyRemoveItemFromInventory(I, force = TRUE)
			itemstore += I.type
			qdel(I)
		capturedsoul.loc = user.loc
		capturedsoul.summoned = TRUE
		capturedsoul.beingmoved = TRUE
		capturedsoul.invisibility = INVISIBILITY_OBSERVER
		capturedsoul.status_flags |= GODMODE
		capturedsoul.Stun(61 SECONDS)
		capturedsoul.density = FALSE
		addtimer(CALLBACK(src, PROC_REF(return_soul), user, capturedsoul, itemstore), 60 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(return_soul_warning), user, capturedsoul), 50 SECONDS)
		to_chat(user, "<font color='blue'>I feel a cold chill run down my spine, a ghastly presence has arrived.</font>")
		return ..()

/obj/effect/proc_holder/spell/targeted/soulspeak/proc/return_soul_warning(mob/user, mob/living/carbon/spirit/soul)
	if(!QDELETED(user))
		to_chat(user, span_warning("The soul is being pulled away..."))
	if(!QDELETED(soul))
		to_chat(soul, span_warning("I'm starting to be pulled away..."))

/obj/effect/proc_holder/spell/targeted/soulspeak/proc/return_soul(mob/user, mob/living/carbon/spirit/soul, list/itemstore)
	to_chat(user, "<font color='blue'>The soul returns to the Underworld.</font>")
	if(QDELETED(soul))
		return
	to_chat(soul, "<font color='blue'>You feel yourself being transported back to the Underworld.</font>")
	soul.drop_all_held_items()
	for(var/obj/effect/landmark/underworld/A in shuffle(GLOB.landmarks_list))
		soul.loc = A.loc
		for(var/I in itemstore)
			soul.put_in_hands(new I())
		break
	soul.beingmoved = FALSE
	soul.fully_heal(FALSE)
	soul.invisibility = initial(soul.invisibility)
	soul.status_flags &= ~GODMODE
	soul.density = initial(soul.density)
