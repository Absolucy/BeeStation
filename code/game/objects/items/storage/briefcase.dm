/obj/item/storage/briefcase
	name = "briefcase"
	desc = "It's made of AUTHENTIC faux-leather and has a price-tag still attached. Its owner must be a real professional."
	icon = 'icons/obj/storage/case.dmi'
	icon_state = "briefcase"
	lefthand_file = 'icons/mob/inhands/equipment/case_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/case_righthand.dmi'
	flags_1 = CONDUCT_1
	force = 8
	hitsound = "swing_hit"
	throw_speed = 2
	throw_range = 4
	w_class = WEIGHT_CLASS_BULKY
	attack_verb_continuous = list("bashes", "batters", "bludgeons", "thrashes", "whacks")
	attack_verb_simple = list("bash", "batter", "bludgeon", "thrash", "whack")
	resistance_flags = FLAMMABLE
	max_integrity = 150
	var/folder_path = /obj/item/folder //this is the path of the folder that gets spawned in New()

/obj/item/storage/briefcase/Initialize(mapload)
	. = ..()
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL
	atom_storage.max_total_storage = 28

/obj/item/storage/briefcase/PopulateContents()
	new /obj/item/pen(src)
	var/obj/item/folder/folder = new folder_path(src)
	for(var/i in 1 to 6)
		new /obj/item/paper(folder)

/obj/item/storage/briefcase/lawyer
	folder_path = /obj/item/folder/blue

/obj/item/storage/briefcase/lawyer/PopulateContents()
	new /obj/item/stamp/law(src)
	..()

/obj/item/storage/briefcase/sniperbundle
	desc = "Its label reads \"genuine hardened Captain leather\", but suspiciously has no other tags or branding. Smells like L'Air du Temps."
	force = 10

/obj/item/storage/briefcase/sniperbundle/PopulateContents()
	..() // in case you need any paperwork done after your rampage
	new /obj/item/gun/ballistic/sniper_rifle/syndicate(src)
	new /obj/item/clothing/neck/tie/red(src)
	new /obj/item/clothing/under/syndicate/sniper(src)
	new /obj/item/ammo_box/magazine/sniper_rounds/soporific(src)
	new /obj/item/ammo_box/magazine/sniper_rounds/soporific(src)
	new /obj/item/suppressor/specialoffer(src)

