/* Morgue stuff
 * Contains:
 *		Morgue
 *		Morgue tray
 *		Crematorium
 *		Creamatorium
 *		Crematorium tray
 *		Crematorium button
 */

/*
 * Bodycontainer
 * Parent class for morgue and crematorium
 * For overriding only
 */
GLOBAL_LIST_EMPTY(bodycontainers) //Let them act as spawnpoints for revenants and other ghosties.

/obj/structure/bodycontainer
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "morgue1"
	density = TRUE
	anchored = TRUE
	max_integrity = 400

	var/obj/structure/tray/connected = null
	var/locked = FALSE
	dir = SOUTH
	var/message_cooldown
	var/breakout_time = 600

/obj/structure/bodycontainer/Initialize(mapload)
	. = ..()
	GLOB.bodycontainers += src
	recursive_organ_check(src)

/obj/structure/bodycontainer/Destroy()
	GLOB.bodycontainers -= src
	open()
	if(connected)
		qdel(connected)
		connected = null
	return ..()

/obj/structure/bodycontainer/on_log(login)
	..()
	update_icon()

/obj/structure/bodycontainer/update_icon()
	return

/obj/structure/bodycontainer/relaymove(mob/living/user, direction)
	if(user.stat || !isturf(loc))
		return
	if(locked)
		if(message_cooldown <= world.time)
			message_cooldown = world.time + 50
			to_chat(user, span_warning("[src]'s door won't budge!"))
		return
	open()

/obj/structure/bodycontainer/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/bodycontainer/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(locked)
		to_chat(user, span_danger("It's locked."))
		return
	if(!connected)
		to_chat(user, "That doesn't appear to have a tray.")
		return
	if(connected.loc == src)
		open()
	else
		close()
	add_fingerprint(user)

/obj/structure/bodycontainer/attack_robot(mob/user)
	if(!user.Adjacent(src))
		return
	return attack_hand(user)

/obj/structure/bodycontainer/attackby(obj/P, mob/user, params)
	add_fingerprint(user)
	if(istype(P, /obj/item/pen))
		if(!user.is_literate())
			to_chat(user, span_notice("You scribble illegibly on the side of [src]!"))
			return
		var/t = stripped_input(user, "What would you like the label to be?", "[name]", null)
		if (user.get_active_held_item() != P)
			return
		if(!user.canUseTopic(src, BE_CLOSE))
			return
		if (t)
			name = "[initial(name)]- '[t]'"
		else
			name = initial(name)
	else
		return ..()

/obj/structure/bodycontainer/deconstruct(disassembled = TRUE)
	if (!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/iron (loc, 5)
	recursive_organ_check(src)
	qdel(src)

/obj/structure/bodycontainer/container_resist(mob/living/user)
	if(!locked)
		open()
		return
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message(null, \
		span_notice("You lean on the back of [src] and start pushing the tray open... (this will take about [DisplayTimeText(breakout_time)].)"), \
		span_italics("You hear a metallic creaking from [src]."))
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src )
			return
		user.visible_message(span_warning("[user] successfully broke out of [src]!"), \
			span_notice("You successfully break out of [src]!"))
		open()

/obj/structure/bodycontainer/proc/open()
	recursive_organ_check(src)
	playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)
	playsound(src, 'sound/effects/roll.ogg', 5, 1)
	var/turf/T = get_step(src, dir)
	if(connected)
		connected.setDir(dir)
	for(var/atom/movable/AM in src)
		AM.forceMove(T)
	update_icon()

/obj/structure/bodycontainer/proc/close()
	playsound(src, 'sound/effects/roll.ogg', 5, 1)
	playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
	for(var/atom/movable/AM in connected.loc)
		if(!AM.anchored || AM == connected)
			if(ismob(AM) && !isliving(AM))
				continue
			AM.forceMove(src)
	recursive_organ_check(src)
	update_icon()

/obj/structure/bodycontainer/get_remote_view_fullscreens(mob/user)
	if(user.stat == DEAD || !(user.sight & (SEEOBJS|SEEMOBS)))
		user.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/impaired, 2)
/*
 * Morgue
 */
/obj/structure/bodycontainer/morgue
	name = "morgue"
	desc = "Used to keep bodies in until someone fetches them. Now includes a high-tech alert system."
	icon_state = "morgue1"
	dir = EAST
	var/beeper = TRUE
	var/beep_cooldown = 50
	var/next_beep = 0

/obj/structure/bodycontainer/morgue/Initialize(mapload)
	. = ..()
	connected = new/obj/structure/tray/m_tray(src)
	connected.connected = src

/obj/structure/bodycontainer/morgue/examine(mob/user)
	. = ..()
	. += span_notice("The speaker is [beeper ? "enabled" : "disabled"]. Alt-click to toggle it.")

/obj/structure/bodycontainer/morgue/AltClick(mob/user)
	if(!user.canUseTopic(src, !issilicon(user)))
		return
	beeper = !beeper
	to_chat(user, span_notice("You turn the speaker function [beeper ? "on" : "off"]."))

/obj/structure/bodycontainer/morgue/update_icon()
	if (!connected || connected.loc != src) // Open or tray is gone.
		icon_state = "morgue0"
	else
		if(contents.len == 1)  // Empty
			icon_state = "morgue1"
		else
			icon_state = "morgue2" // Dead, brainded mob.
			var/list/compiled = recursive_mob_check(src, 0, 0) // Search for mobs in all contents.
			if(!length(compiled)) // No mobs?
				icon_state = "morgue3"
				return

			for(var/mob/living/M in compiled)
				var/mob/living/mob_occupant = get_mob_or_brainmob(M)
				if(mob_occupant.client && !mob_occupant.suiciding && !(HAS_TRAIT(mob_occupant, TRAIT_BADDNA)) && !mob_occupant.ishellbound())
					icon_state = "morgue4" // Cloneable
					if(mob_occupant.stat == DEAD && beeper)
						if(world.time > next_beep)
							playsound(src, 'sound/weapons/smg_empty_alarm.ogg', 50, 0) //Clone them you blind fucks
							next_beep = world.time + beep_cooldown
					break


/obj/item/paper/guides/jobs/medical/morgue
	name = "morgue memo"
	default_raw_text = "<font size='2'>Since this station's medbay never seems to fail to be staffed by the mindless monkeys meant for genetics experiments, I'm leaving a reminder here for anyone handling the pile of cadavers the quacks are sure to leave.</font><BR><BR><font size='4'><font color=red>Red lights mean there's a plain ol' dead body inside.</font><BR><BR><font color=orange>Yellow lights mean there's non-body objects inside.</font><BR><font size='2'>Probably stuff pried off a corpse someone grabbed, or if you're lucky it's stashed booze.</font><BR><BR><font color=green>Green lights mean the morgue system detects the body may be able to be cloned.</font></font><BR><font size='2'>I don't know how that works, but keep it away from the kitchen and go yell at the geneticists.</font><BR><BR>- CentCom medical inspector"

/*
 * Crematorium
 */
GLOBAL_LIST_EMPTY(crematoriums)
/obj/structure/bodycontainer/crematorium
	name = "crematorium"
	desc = "A human incinerator. Works well on barbecue nights."
	icon_state = "crema1"
	dir = SOUTH
	var/id = 1

/obj/structure/bodycontainer/crematorium/attack_robot(mob/user) //Borgs can't use crematoriums without help
	to_chat(user, span_warning("[src] is locked against you."))
	return TRUE

/obj/structure/bodycontainer/crematorium/Destroy()
	GLOB.crematoriums.Remove(src)
	return ..()

/obj/structure/bodycontainer/crematorium/New()
	GLOB.crematoriums.Add(src)
	..()

/obj/structure/bodycontainer/crematorium/Initialize(mapload)
	. = ..()
	connected = new /obj/structure/tray/c_tray(src)
	connected.connected = src

/obj/structure/bodycontainer/crematorium/update_icon()
	if(!connected || connected.loc != src)
		icon_state = "crema0"
	else

		if(src.contents.len > 1)
			src.icon_state = "crema2"
		else
			src.icon_state = "crema1"

		if(locked)
			src.icon_state = "crema_active"

	return

/obj/structure/bodycontainer/crematorium/proc/cremate(mob/user)
	if(locked)
		return //don't let you cremate something twice or w/e
	// Make sure we don't delete the actual morgue and its tray
	var/list/conts = GetAllContents() - src - connected

	if(!conts.len)
		audible_message(span_italics("You hear a hollow crackle."))
		return

	else
		audible_message(span_italics("You hear a roar as the crematorium activates."))

		locked = TRUE
		update_icon()

		for(var/obj/O in conts)
			if(O.resistance_flags & INDESTRUCTIBLE)
				O.forceMove(src) // in case an item in container should be spared
				conts -= O

		for(var/mob/living/M in conts)
			if (M.stat != DEAD)
				M.emote("scream")
			if(user)
				log_combat(user, M, "cremated", important = FALSE)
			else
				M.log_message("was cremated", LOG_ATTACK)
			if(user.stat != DEAD)
				user.investigate_log("has died from being cremated.", INVESTIGATE_DEATHS)
			M.death(TRUE)
			if(M) //some animals get automatically deleted on death.
				M.ghostize()
				qdel(M)

		for(var/obj/O in conts) //conts defined above, ignores crematorium and tray
			CHECK_TICK
			log_game("[key_name(user)] has cremated [O.name] ([O.type]) at [AREACOORD(src)].")
			if(user)
				user.log_message("cremated [O.name] ([O.type]) at [AREACOORD(src)]", LOG_ATTACK) //Logged in their attack log for consistency with mobs, see above
			qdel(O)

		if(!locate(/obj/effect/decal/cleanable/ash) in get_step(src, dir))//prevent pile-up
			new/obj/effect/decal/cleanable/ash/crematorium(src)

		sleep(30)

		if(!QDELETED(src))
			locked = FALSE
			update_icon()
			playsound(src.loc, 'sound/machines/ding.ogg', 50, 1) //you horrible people

/obj/structure/bodycontainer/crematorium/creamatorium
	name = "creamatorium"
	desc = "A human incinerator. Works well during ice cream socials."

/obj/structure/bodycontainer/crematorium/creamatorium/cremate(mob/user)
	var/list/icecreams = new()
	for(var/i_scream in GetAllContents(/mob/living))
		var/obj/item/food/icecream/IC = new()
		IC.set_cone_type("waffle")
		IC.add_mob_flavor(i_scream)
		icecreams += IC
	. = ..()
	for(var/obj/IC in icecreams)
		IC.forceMove(src)

/*
 * Generic Tray
 * Parent class for morguetray and crematoriumtray
 * For overriding only
 */
/obj/structure/tray
	icon = 'icons/obj/stationobjs.dmi'
	density = TRUE
	layer = BELOW_OBJ_LAYER
	var/obj/structure/bodycontainer/connected = null
	anchored = TRUE
	pass_flags_self = LETPASSTHROW
	max_integrity = 350

/obj/structure/tray/Destroy()
	if(connected)
		connected.connected = null
		connected.update_icon()
		connected = null
	return ..()

/obj/structure/tray/deconstruct(disassembled = TRUE)
	new /obj/item/stack/sheet/iron (loc, 2)
	qdel(src)

/obj/structure/tray/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/tray/attack_robot(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/structure/tray/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if (src.connected)
		connected.close()
		add_fingerprint(user)
	else
		to_chat(user, span_warning("That's not connected to anything!"))

/obj/structure/tray/attack_robot(mob/user)
	if(!user.Adjacent(src))
		return
	return attack_hand(user)

/obj/structure/tray/attackby(obj/P, mob/user, params)
	if(!istype(P, /obj/item/riding_offhand))
		return ..()

	var/obj/item/riding_offhand/riding_item = P
	var/mob/living/carried_mob = riding_item.rider
	if(carried_mob == user) //Piggyback user.
		return
	user.unbuckle_mob(carried_mob)
	MouseDrop_T(carried_mob, user)

/obj/structure/tray/MouseDrop_T(atom/movable/O as mob|obj, mob/user)
	if(!ismovable(O) || O.anchored || !Adjacent(user) || !user.Adjacent(O) || O.loc == user)
		return
	if(!ismob(O))
		if(!istype(O, /obj/structure/closet/body_bag))
			return
	else
		var/mob/M = O
		if(M.buckled)
			return
	if(!ismob(user) || user.incapacitated())
		return
	if(isliving(user))
		var/mob/living/L = user
		if(L.body_position == LYING_DOWN)
			return
	O.forceMove(src.loc)
	if (user != O)
		visible_message(span_warning("[user] stuffs [O] into [src]."))
	return

/*
 * Crematorium tray
 */
/obj/structure/tray/c_tray
	name = "crematorium tray"
	desc = "Apply body before burning."
	icon_state = "cremat"

/obj/structure/tray/c_tray/attack_silicon(mob/user) //copied behaviour from /obj/structure/bodycontainer/crematorium
	to_chat(user, span_warning("\The [src] is locked against you."))
	return TRUE

/*
 * Morgue tray
 */
/obj/structure/tray/m_tray
	name = "morgue tray"
	desc = "Apply corpse before closing."
	icon_state = "morguet"
	pass_flags_self = PASSTABLE|LETPASSTHROW

/obj/structure/tray/m_tray/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(.)
		return
	if(locate(/obj/structure/table) in get_turf(mover))
		return TRUE
