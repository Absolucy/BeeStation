// Honker

/obj/projectile/bullet/honker
	name = "banana"
	damage = 0
	bleed_force = 0
	paralyze = 60
	movement_type = FLYING
	projectile_piercing = ALL
	nodamage = TRUE
	hitsound = 'sound/items/bikehorn.ogg'
	icon = 'icons/obj/hydroponics/harvest.dmi'
	icon_state = "banana"
	range = 200
	bleed_force = 0

/obj/projectile/bullet/honker/Initialize(mapload)
	. = ..()
	SpinAnimation()

/obj/projectile/bullet/honker/on_hit(mob/target, blocked, pierce_hit)
	. = ..()
	var/mob/M = target
	if(istype(M))
		if(M.can_block_magic())
			return BULLET_ACT_BLOCK

// Mime

/obj/projectile/bullet/mime
	damage = 20

/obj/projectile/bullet/mime/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.silent = max(M.silent, 10)
