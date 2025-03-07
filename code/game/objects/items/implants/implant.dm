/**
 * Parent class for all implants
 */
/obj/item/implant
	name = "implant"
	icon = 'icons/obj/implants.dmi'
	icon_state = "generic" //Shows up as the action button icon
	item_flags = ABSTRACT | DROPDEL
	actions_types = list(/datum/action/item_action/hands_free/activate)
	// This gives the user an action button that allows them to activate the implant.
	// If the implant needs no action button, then null this out.
	// Or, if you want to add a unique action button, then replace this.
	var/mob/living/imp_in = null
	var/implant_color = "b"
	var/allow_multiple = FALSE
	var/uses = -1


/obj/item/implant/proc/trigger(emote, mob/living/carbon/source)
	return

/obj/item/implant/proc/on_death(emote, mob/living/carbon/source)
	return

/obj/item/implant/proc/activate()
	SEND_SIGNAL(src, COMSIG_IMPLANT_ACTIVATED)

/obj/item/implant/ui_action_click()
	activate("action_button")

/obj/item/implant/item_action_slot_check(slot, mob/user)
	return user == imp_in



/obj/item/implant/proc/can_be_implanted_in(mob/living/target) // for human-only and other special requirements
	return TRUE

/mob/living/proc/can_be_implanted()
	return TRUE

/mob/living/silicon/can_be_implanted()
	return FALSE

/mob/living/simple_animal/can_be_implanted()
	return healable //Applies to robots and most non-organics, exceptions can override.

/obj/item/implant/proc/on_implanted(mob/user)

//What does the implant do upon injection?
//return 1 if the implant injects
//return 0 if there is no room for implant / it fails
/obj/item/implant/proc/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	if(SEND_SIGNAL(src, COMSIG_IMPLANT_IMPLANTING, args) & COMPONENT_STOP_IMPLANTING)
		return
	LAZYINITLIST(target.implants)
	if(!force && (!target.can_be_implanted() || !can_be_implanted_in(target)))
		return FALSE
	for(var/X in target.implants)
		var/obj/item/implant/imp_e = X
		var/flags = SEND_SIGNAL(imp_e, COMSIG_IMPLANT_OTHER, args, src)
		if(flags & COMPONENT_DELETE_NEW_IMPLANT)
			UNSETEMPTY(target.implants)
			qdel(src)
			return TRUE
		if(flags & COMPONENT_DELETE_OLD_IMPLANT)
			qdel(imp_e)
			continue
		if(flags & COMPONENT_STOP_IMPLANTING)
			UNSETEMPTY(target.implants)
			return FALSE

		if(istype(imp_e, type))
			if(!allow_multiple)
				if(imp_e.uses < initial(imp_e.uses)*2)
					if(uses == -1)
						imp_e.uses = -1
					else
						imp_e.uses = min(imp_e.uses + uses, initial(imp_e.uses)*2)
					qdel(src)
					return TRUE
				else
					return FALSE

	forceMove(target)
	imp_in = target
	target.implants += src
	for(var/datum/action/implant_action as anything in actions)
		implant_action.Grant(target)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.sec_hud_set_implants()

	on_implanted(target)

	if(user)
		log_combat(user, target, "implanted", "\a [name]", important = FALSE)

	SEND_SIGNAL(src, COMSIG_IMPLANT_IMPLANTED, target, user, silent, force)
	return TRUE

/obj/item/implant/proc/transfer_implant(mob/living/user, mob/living/target)
	if(SEND_SIGNAL(src, COMSIG_IMPLANT_IMPLANTING, args) & COMPONENT_STOP_IMPLANTING)
		return
	LAZYINITLIST(target.implants)
	if(!force && (!target.can_be_implanted() || !can_be_implanted_in(target)))
		return FALSE
	forceMove(target)
	user.implants -= src
	imp_in = target
	target.implants += src
	for(var/datum/action/implant_action as anything in actions)
		implant_action.Grant(target)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.sec_hud_set_implants()
	on_implanted(target)
	SEND_SIGNAL(src, COMSIG_IMPLANT_IMPLANTED, target, user, TRUE, FALSE)
	return TRUE

/obj/item/implant/proc/removed(mob/living/source, silent = FALSE, special = 0)
	moveToNullspace()
	imp_in = null
	source.implants -= src
	for(var/datum/action/implant_action as anything in actions)
		implant_action.Remove(source)
	if(ishuman(source))
		var/mob/living/carbon/human/H = source
		H.sec_hud_set_implants()

	SEND_SIGNAL(src, COMSIG_IMPLANT_REMOVED, source, silent, special)
	return TRUE

/obj/item/implant/Destroy()
	if(imp_in)
		removed(imp_in)
	return ..()

/obj/item/implant/proc/get_data()
	return "No information available"

/obj/item/implant/dropped(mob/user)
	. = TRUE
	..()
