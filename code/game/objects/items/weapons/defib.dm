//**************************************************************
// Defibrillator
//**************************************************************

/obj/item/weapon/melee/defibrillator
	name = "emergency defibrillator"
	desc = "Used to restore fibrillating patients."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "defib_full"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/surgery_tools.dmi', "right_hand" = 'icons/mob/in-hand/right/surgery_tools.dmi')
	item_state = "defib"
	w_class = W_CLASS_MEDIUM
	force = 5
	throwforce = 5
	origin_tech = Tc_BIOTECH + "=3"
	autoignition_temperature = AUTOIGNITION_PLASTIC

	var/charges = 10
	var/ready = 0
	var/emagged = 0

/obj/item/weapon/melee/defibrillator/New()
	return ..()

/obj/item/weapon/melee/defibrillator/suicide_act(var/mob/living/user)
	to_chat(viewers(user), "<span class='warning'>[user] is putting the live paddles on \his chest! It looks like \he's trying to commit suicide.</span>")
	playsound(src,'sound/items/defib.ogg',50,1)
	return (SUICIDE_ACT_FIRELOSS)

/obj/item/weapon/melee/defibrillator/update_icon()
	icon_state = "defib"
	if(ready)
		icon_state += "paddleout"
	else
		icon_state += "paddlein"
	switch(charges/initial(charges))
		if(0.7 to INFINITY) //Just in case the defib somehow gets more charges than initial
			icon_state += "_full"
		if(0.4 to 0.6)
			icon_state += "_half"
		if(0.01 to 0.3) //Make sure it's really empty dawg
			icon_state += "_low"
		else
			icon_state += "_empty"
	return

/obj/item/weapon/melee/defibrillator/attack_self(mob/user)
	if(charges || ready)
		if(clumsy_check(user) && prob(50) && charges)
			to_chat(user, "<span class='warning'>You touch the paddles together, shorting the device.</span>")
			spark(src, 5)
			playsound(src,'sound/items/defib.ogg',50,1)
			user.Knockdown(5)
			user.Stun(5)
			var/mob/living/carbon/human/H = user
			if(ishuman(user))
				H.apply_damage(20, BURN)
			charges--
			update_icon()
		else
			ready = !ready
			to_chat(user, "<span class='notice'>You turn [src] [ready? "on and take the paddles out" : "off and put the paddles back in"].</span>")
			playsound(src,"sparks",75,1,-1)
			update_icon()
	else
		to_chat(user, "<span class='warning'>[src] is out of charges.</span>")
	add_fingerprint(user)
	return

/obj/item/weapon/melee/defibrillator/update_wield(mob/user)
	..()
	item_state = "fireaxe[wielded ? 1 : 0]"
	force = wielded ? 40 : 10
	if(user)
		user.update_inv_hands()

/obj/item/weapon/melee/defibrillator/attackby(obj/item/weapon/W,mob/user)
	if(istype(W,/obj/item/weapon/card/emag))
		emagged = !src.emagged
		if(emagged)
			to_chat(user, "<span class='warning'>You short out [src]'s safety protocols.</span>")
			overlays += image(icon = icon, icon_state = "defib_emag")
		else
			to_chat(user, "<span class='notice'>You reset [src]'s safety protocols.</span>")
			overlays.len = 0
	else
		. = ..()
	return

/obj/item/weapon/melee/defibrillator/attack(mob/M,mob/user)
	if(!ishuman(M))
		to_chat(user, "<span class='warning'>You can't defibrillate [M]. You don't even know where to put the paddles!</span>")
	else if(!charges)
		to_chat(user, "<span class='warning'>[src] is out of charges.</span>")
	else if(!ready)
		to_chat(user, "<span class='warning'>Take the paddles out first.</span>")
	else
		var/mob/living/carbon/human/target = M
		if(!(target.stat == 2 || target.stat == DEAD))
			if(emagged)
				shockAttack(target,user)
			else
				to_chat(user, "<span class='warning'>[src] buzzes: Vital signs detected.</span>")
		else
			attemptDefib(target,user)
	return

/obj/item/weapon/melee/defibrillator/proc/shockAttack(mob/living/carbon/human/target,mob/user)
	var/damage = rand(30, 60)
	if (!target.electrocute_act(damage, src, def_zone = LIMB_CHEST))
		return
	var/datum/organ/internal/heart/heart = target.get_heart()
	if(heart)
		heart.damage += rand(5,60)
	target.audible_scream() //If we're going this route, it kinda hurts
	spawn() //Logging
		user.attack_log += "\[[time_stamp()]\]<font color='red'> Shocked [target.name] ([target.ckey]) with an emagged [src.name]</font>"
		target.attack_log += "\[[time_stamp()]\]<font color='orange'> Shocked by [user.name] ([user.ckey]) with an emagged [src.name]</font>"
		log_attack("<font color='red'>[user.name] ([user.ckey]) shocked [target.name] ([target.ckey]) with an emagged [src.name]</font>" )
		if(!iscarbon(user))
			target.LAssailant = null
		else
			target.LAssailant = user
			target.assaulted_by(user)
	playsound(src,'sound/items/defib.ogg',50,1)
	charges--
	update_icon()
	return

/obj/item/weapon/melee/defibrillator/proc/attemptDefib(mob/living/carbon/human/target,mob/user)
	user.visible_message("<span class='notice'>[user] starts setting up the paddles on [target]'s chest.</span>", \
	"<span class='notice'>You start setting up the paddles on [target]'s chest</span>")
	if(target.mind && !target.client && target.get_heart() && target.get_organ(LIMB_HEAD) && target.has_brain() && !target.mind.suiciding && target.health+target.getOxyLoss() > config.health_threshold_dead)
		target.ghost_reenter_alert("Someone is about to try to defibrillate your body. Return to it if you want to be resurrected!")
	if(do_after(user,target,30))
		spark(src, 5, FALSE)
		playsound(src,'sound/items/defib.ogg',50,1)
		charges--
		update_icon()
		to_chat(user, "<span class='notice'>You shock [target] with the paddles.</span>")
		var/datum/organ/internal/heart/heart = target.get_heart()
		if(!heart)
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. Subject requires a heart.</span>")
			target.apply_damage(rand(1,5),BURN,LIMB_CHEST)
			return
		var/datum/organ/external/head/head = target.get_organ(LIMB_HEAD)
		if(!head || head.status & ORGAN_DESTROYED)
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. Severe cranial damage detected.</span>")
			return
		if((M_HUSK in target.mutations) && (M_NOCLONE in target.mutations))
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. Irremediable genetic damage detected.</span>")
			return
		if(!target.has_brain())
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. No central nervous system detected.</span>")
			return
		if(target.mind && target.mind.suiciding)
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. Unrecoverable nerve trauma detected.</span>") // They suicided so they fried their brain. Space Magic.
			return
		if(istype(target.wear_suit,/obj/item/clothing/suit/armor) && (target.wear_suit.body_parts_covered & UPPER_TORSO) && prob(95)) //75 ? Let's stay realistic here
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. Please apply on bare skin.</span>")
			target.apply_damage(rand(1,5),BURN,LIMB_CHEST)
			return
		if(istype(target.w_uniform,/obj/item/clothing/under) && (target.w_uniform.body_parts_covered & UPPER_TORSO) && prob(50))
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. Please apply on bare skin.</span>")
			target.apply_damage(rand(1,5),BURN,LIMB_CHEST)
			return
		if(target.mind && !target.client) //Let's call up the ghost! Also, bodies with clients only, thank you.
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. [target.ghost_reenter_alert("Someone has tried to defibrillate your body. Return to it if you want to be resurrected!") ? "Vital signs are too weak, please try again in five seconds" : "No brainwaves detected"].</span>")
			return
		target.apply_damage(-target.getOxyLoss(),OXY)
		target.updatehealth()
		target.visible_message("<span class='danger'>[target]'s body convulses a bit.</span>")
		if(target.health > config.health_threshold_dead)
			target.timeofdeath = 0
			target.visible_message("<span class='notice'>[src] beeps: Defibrillation successful.</span>")

			target.resurrect()

			target.tod = null
			target.stat = target.status_flags & BUDDHAMODE ? CONSCIOUS : UNCONSCIOUS
			target.regenerate_icons()
			target.update_canmove()
			target.flash_eyes(visual = 1)
			target.apply_effect(10, EYE_BLUR) //I'll still put this back in to avoid dumb "pounce back up" behavior
			target.apply_effect(10, PARALYZE)
			target.update_canmove()
			has_been_shade.Remove(target.mind)
			to_chat(target, "<span class='notice'>You suddenly feel a spark and your consciousness returns, dragging you back to the mortal plane.</span>")
		else
			target.visible_message("<span class='warning'>[src] buzzes: Defibrillation failed. Patient's condition does not allow reviving.</span>")
		return

/obj/item/weapon/melee/defibrillator/restock()
	charges = initial(charges)
