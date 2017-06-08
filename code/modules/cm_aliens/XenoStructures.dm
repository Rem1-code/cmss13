
/*
 * effect/alien
 */
/obj/effect/alien
	name = "alien thing"
	desc = "theres something alien about this"
	icon = 'icons/Xeno/Effects.dmi'
	unacidable = 1
	var/health = 1

/obj/effect/alien/flamer_fire_act()
	health -= 50
	if(health < 0) cdel(src)
/*
 * Resin
 */
/obj/effect/alien/resin
	name = "resin"
	desc = "Looks like some kind of slimy growth."
	icon_state = "Resin1"

	density = 1
	opacity = 1
	anchored = 1
	health = 200
	layer = 2.8
	unacidable = 1

/obj/effect/alien/resin/wall
	name = "resin wall"
	desc = "Weird slime solidified into a wall."
	icon_state = "ResinWall1" //same as resin, but consistency ho!
	layer = 3.1

	New()
		..()
		if(!locate(/obj/effect/alien/weeds) in loc) new /obj/effect/alien/weeds(loc)

/obj/effect/alien/resin/membrane
	name = "resin membrane"
	desc = "Weird slime just translucent enough to let light pass through."
	icon_state = "Resin Membrane"
	opacity = 0
	health = 120
	layer = 3

	New()
		..()
		if(!locate(/obj/effect/alien/weeds) in loc) new /obj/effect/alien/weeds(loc)

/obj/effect/alien/resin/sticky
	name = "sticky resin"
	desc = "Some disgusting sticky slime. Gross!."
	icon_state = "sticky"
	density = 0
	opacity = 0
	health = 150
	layer = 2.9

	Crossed(atom/movable/AM)
		if(ishuman(AM))
			var/mob/living/carbon/human/H = AM
			H.next_move_slowdown += 8

/obj/effect/alien/resin/proc/healthcheck()
	if(health <= 0)
		density = 0
		cdel(src)

/obj/effect/alien/resin/bullet_act(var/obj/item/projectile/Proj)
	health -= Proj.damage
	..()
	healthcheck()
	return 1

/obj/effect/alien/resin/ex_act(severity)
	switch(severity)
		if(1.0)
			health -= 500
		if(2.0)
			health -= (rand(140, 300))
		if(3.0)
			health -= (rand(50, 100))
	healthcheck()
	return

/obj/effect/alien/resin/hitby(AM as mob|obj)
	..()
	if(istype(AM,/mob/living/carbon/Xenomorph))
		return
	visible_message("<span class='danger'>\The [src] was hit by \the [AM].</span>", \
	"<span class='danger'>You hit \the [src].</span>")
	var/tforce = 0
	if(ismob(AM))
		tforce = 10
	else
		tforce = AM:throwforce
	playsound(loc, 'sound/effects/attackblob.ogg', 25, 1)
	health = max(0, health - tforce)
	healthcheck()

/obj/effect/alien/resin/attack_alien(mob/living/carbon/Xenomorph/M)
	if(isXenoLarva(M)) //Larvae can't do shit
		return 0
	M.visible_message("<span class='xenonotice'>\The [M] claws \the [src]!</span>", \
	"<span class='xenonotice'>You claw \the [src].</span>")
	playsound(loc, 'sound/effects/attackblob.ogg', 25, 1)
	health -= (M.melee_damage_upper + 50) //Beef up the damage a bit
	healthcheck()

/obj/effect/alien/resin/attack_animal(mob/living/M as mob)
	M.visible_message("<span class='danger'>[M] tears \the [src]!</span>", \
	"<span class='danger'>You tear \the [name].</span>")
	playsound(loc, 'sound/effects/attackblob.ogg', 25, 1)
	health -= 40
	healthcheck()

/obj/effect/alien/resin/attack_hand()
	usr << "<span class='warning'>You scrape ineffectively at \the [src].</span>"

/obj/effect/alien/resin/attack_paw()
	return attack_hand()

/obj/effect/alien/resin/attackby(obj/item/W as obj, mob/user as mob)
	health = health - W.force
	playsound(loc, 'sound/effects/attackblob.ogg', 25, 1)
	healthcheck()
	return ..(W, user)

/obj/effect/alien/resin/CanPass(atom/movable/mover, turf/target, height = 0, air_group = 0)
	if(air_group)
		return 0
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return !opacity
	return !density

/*
 * Weeds
 */
#define NODERANGE 3

/obj/effect/alien/weeds
	name = "weeds"
	desc = "Weird black weeds..."
	icon_state = "weeds"

	anchored = 1
	density = 0
	layer = 2
	unacidable = 1
	health = 1
	var/obj/effect/alien/weeds/node/linked_node = null
	var/on_fire = 0

	New(pos, node)
		..()
		if(istype(loc, /turf/space))
			cdel(src)
			return
		linked_node = node
		if(icon_state == "weeds")
			icon_state = pick("weeds", "weeds1", "weeds2")
		spawn(rand(150, 200))
			if(src)
				Life()

	Crossed(atom/movable/AM)
		if(ishuman(AM))
			var/mob/living/carbon/human/H = AM
			H.next_move_slowdown += 1

/obj/effect/alien/weeds/proc/Life()
	set background = 1
	var/turf/U = get_turf(src)

	if(istype(U, /turf/space) || isnull(U))
		cdel(src)
		return

	if(!linked_node || (get_dist(linked_node, src) > linked_node.node_range) )
		return

	direction_loop:
		for(var/dirn in cardinal)
			var/turf/T = get_step(src, dirn)

			if(!istype(T) || T.density || locate(/obj/effect/alien/weeds) in T || istype(T.loc, /area/arrival) || istype(T, /turf/space))
				continue

			if(istype(T, /turf/unsimulated/floor/gm/grass) || istype(T, /turf/unsimulated/floor/gm/river) || istype(T, /turf/unsimulated/floor/gm/coast) || T.slayer > 0)
				continue

			for(var/obj/O in T)
				if(O.density)
					continue direction_loop

			new /obj/effect/alien/weeds(T, linked_node)

/obj/effect/alien/weeds/ex_act(severity)
	switch(severity)
		if(1.0)
			cdel(src)
		if(2.0)
			if(prob(70))
				cdel(src)
		if(3.0)
			if(prob(50))
				cdel(src)

/obj/effect/alien/weeds/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(!W || !user || isnull(W))
		return 0

	if(istype(src, /obj/effect/alien/weeds/node)) //The pain is real
		user << "<span class='warning'>You hit \the [src] with \the [W].</span>"
	else
		user << "<span class='warning'>You cut \the [src] away with \the [W].</span>"

	var/damage = W.force / 4.0

	if(istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W

		if(WT.remove_fuel(0, user))
			damage = 15
			playsound(loc, 'sound/items/Welder.ogg', 25, 1)

	health -= damage
	healthcheck()

/obj/effect/alien/weeds/proc/healthcheck()
	if(health <= 0)
		cdel(src)

/obj/effect/alien/weeds/update_icon()
	overlays.Cut()
	if(on_fire)
		overlays += "alien_fire"

/obj/effect/alien/weeds/fire_act()
	on_fire = 1
	if(on_fire)
		update_icon()
		spawn(rand(100,175))
			cdel(src)


/obj/effect/alien/weeds/node
	icon_state = "weednode"
	name = "purple sac"
	desc = "A weird, pulsating node."
	layer = 2.7
	var/node_range = NODERANGE
	var/planter_ckey //ckey of the mob who planted it.
	var/planter_name //nameof the mob who planted it.
	health = 15

	New(loc, mob/living/carbon/Xenomorph/X)
		..(loc, src)
		if(X)
			planter_ckey = X.ckey
			planter_name = X.real_name
		new /obj/effect/alien/weeds(loc)


#undef NODERANGE

/* //It turns out this is cloned in xenoprocs.dm. Wonderful.
 * Acid
 */
/obj/effect/alien/acid
	name = "acid"
	desc = "Bubling corrosive stuff. I wouldn't want to touch it."
	icon_state = "acid"

	density = 0
	opacity = 0
	anchored = 1
	var/ticks = 0
	health = 1

/obj/effect/alien/acid/New(loc, acid_t)
	..(loc)
	world << "acid was SPAWNEDDDs"
	var/strength_t = isturf(acid_t) ? 8:4 // Turf take twice as long to take down.
	tick(acid_t,strength_t)

/obj/effect/alien/acid/proc/tick(atom/acid_t,strength_t)
	set waitfor = 0
	if(!acid_t || !acid_t.loc)
		cdel(src)
		return

	if(++ticks >= strength_t)
		visible_message("<span class='xenodanger'>\The [acid_t] collapses under its own weight into a puddle of goop and undigested debris!</span>")

		if(istype(acid_t, /turf/simulated/wall)) // I hate turf code.
			var/turf/simulated/wall/W = acid_t
			W.dismantle_wall(1)
		else
			if(acid_t.contents) //Hopefully won't auto-delete things inside melted stuff..
				for(var/mob/M in acid_t.contents)
					if(acid_t.loc) M.loc = acid_t.loc
			cdel(acid_t)
		cdel(src)
		return

	switch(strength_t - ticks)
		if(6) visible_message("<span class='xenowarning'>\The [acid_t] is barely holding up against the acid!</span>")
		if(4) visible_message("<span class='xenowarning'>\The [acid_t]\s structure is being melted by the acid!</span>")
		if(2) visible_message("<span class='xenowarning'>\The [acid_t] is struggling to withstand the acid!</span>")
		if(0 to 1) visible_message("<span class='xenowarning'>\The [acid_t] begins to crumble under the acid!</span>")
	sleep(rand(150, 200))
	.()

/obj/effect/alien/acid/flamer_fire_act()
	return //this prevents any acid trickery.

/*
 * Egg
 */
/var/const //for the status var
	BURST = 0
	BURSTING = 1
	GROWING = 2
	GROWN = 3
	DESTROYED = 4

	MIN_GROWTH_TIME = 1800 //time it takes to grow a hugger
	MAX_GROWTH_TIME = 3000

/obj/effect/alien/egg
	desc = "It looks like a weird egg"
	name = "egg"
	icon_state = "Egg Growing"
	density = 0
	anchored = 1

	health = 80
	var/list/egg_triggers = list()
	var/status = GROWING //can be GROWING, GROWN or BURST; all mutually exclusive
	var/on_fire = 0

	New()
		..()
		create_egg_triggers()
		Grow()

	Dispose()
		. = ..()
		delete_egg_triggers()

/obj/effect/alien/egg/ex_act(severity)
	switch(severity)
		if(1.0)
			health -= rand(50, 100)
		if(2.0)
			health -= rand(40, 95)
		if(3.0)
			health -= rand(20, 81)
	healthcheck()

/obj/effect/alien/egg/attack_alien(mob/living/carbon/Xenomorph/M)

	if(!istype(M) || !isXeno(M))
		return attack_hand(M)

	switch(status)
		if(BURST, DESTROYED)
			switch(M.caste)
				if("Queen","Drone","Hivelord")
					M.visible_message("<span class='xenonotice'>\The [M] clears the hatched egg.</span>", \
					"<span class='xenonotice'>You clear the hatched egg.</span>")
					M.storedplasma++
					cdel(src)
		if(GROWING)
			M << "<span class='xenowarning'>The child is not developed yet.</span>"
		if(GROWN)
			if(isXenoLarva(M))
				M << "<span class='xenowarning'>You nudge the egg, but nothing happens.</span>"
				return
			M << "<span class='xenonotice'>You retrieve the child.</span>"
			Burst(0)

/obj/effect/alien/egg/proc/Grow()
	set waitfor = 0
	sleep(rand(MIN_GROWTH_TIME,MAX_GROWTH_TIME))
	if(status == GROWING)
		icon_state = "Egg"
		status = GROWN
		deploy_egg_triggers()

/obj/effect/alien/egg/proc/create_egg_triggers()
	for(var/i=1, i<=8, i++)
		egg_triggers += new /obj/effect/egg_trigger(src, src)

/obj/effect/alien/egg/proc/deploy_egg_triggers()
	var/i = 1
	var/x_coords = list(-1,-1,-1,0,0,1,1,1)
	var/y_coords = list(1,0,-1,1,-1,1,0,-1)
	var/turf/target_turf
	for(var/atom/trigger in egg_triggers)
		var/obj/effect/egg_trigger/ET = trigger
		target_turf = locate(x+x_coords[i],y+y_coords[i], z)
		if(target_turf)
			ET.loc = target_turf
			i++

/obj/effect/alien/egg/proc/delete_egg_triggers()
	for(var/atom/trigger in egg_triggers)
		cdel(trigger)

/obj/effect/alien/egg/proc/Burst(kill = 1) //drops and kills the hugger if any is remaining
	set waitfor = 0
	if(status == GROWN || status == GROWING)
		status = BURSTING
		delete_egg_triggers()
		sleep(3)
		if(loc)
			if(kill) //Make sure it's still there
				status = DESTROYED
				icon_state = "Egg Exploded"
				flick("Egg Exploding", src)
			else
				icon_state = "Egg Opened"
				flick("Egg Opening", src)
				sleep(10)
				if(loc)
					status = BURST
					var/obj/item/clothing/mask/facehugger/child = new(loc)
					child.leap_at_nearest_target()

/obj/effect/alien/egg/bullet_act(var/obj/item/projectile/P)
	..()
	if(P.ammo.flags_ammo_behavior & (AMMO_XENO_ACID|AMMO_XENO_TOX)) return
	health -= P.ammo.damage_type == BURN ? P.damage * 1.3 : P.damage
	healthcheck()
	P.ammo.on_hit_obj(src,P)
	return 1

/obj/effect/alien/egg/update_icon()
	overlays.Cut()
	if(on_fire)
		overlays += "alienegg_fire"

/obj/effect/alien/egg/fire_act()
	on_fire = 1
	if(on_fire)
		update_icon()
		spawn(rand(125, 200))
			cdel(src)

/obj/effect/alien/egg/attackby(obj/item/W, mob/user)
	if(health <= 0)
		return

	if(istype(W,/obj/item/clothing/mask/facehugger))
		var/obj/item/clothing/mask/facehugger/F = W
		if(F.stat != DEAD)
			switch(status)
				if(BURST)
					if(user)
						visible_message("<span class='xenowarning'>[user] slides [F] back into [src].</span>","<span class='xenonotice'>You place the child back in to [src].</span>")
						user.temp_drop_inv_item(F)
					else
						visible_message("<span class='xenowarning'>[F] crawls back into [src]!</span>") //Not sure how, but let's roll with it for now.
					status = GROWN
					icon_state = "Egg"
					cdel(F)
				if(DESTROYED) user << "<span class='xenowarning'>This egg is no longer usable.</span>"
				if(GROWING,GROWN) user << "<span class='xenowarning'>This one is occupied with a child.</span>"
		else user << "<span class='xenowarning'>This child is dead.</span>"
		return

	if(W.attack_verb.len)
		visible_message("<span class='danger'>\The [src] has been [pick(W.attack_verb)] with \the [W][(user ? " by [user]." : ".")]</span>")
	else
		visible_message("<span class='danger'>\The [src] has been attacked with \the [W][(user ? " by [user]." : ".")]</span>")
	var/damage = W.force / 4.0

	if(istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W

		if(WT.remove_fuel(0, user))
			damage = 15
			playsound(src.loc, 'sound/items/Welder.ogg', 25, 1)

	health -= damage
	healthcheck()

/obj/effect/alien/egg/proc/healthcheck()
	if(health <= 0)
		Burst(1)

/obj/effect/alien/egg/HasProximity(atom/movable/AM as mob|obj)
	if(status == GROWN)
		if(!CanHug(AM) || isYautja(AM)) //Predators are too stealthy to trigger eggs to burst. Maybe the huggers are afraid of them.
			return
		Burst(0)

/obj/effect/alien/egg/flamer_fire_act() // gotta kill the egg + hugger
	Burst(1)


//The invisible traps around the egg to tell it there's a mob right next to it.
/obj/effect/egg_trigger
	name = "egg trigger"
	icon = 'icons/effects/effects.dmi'
	anchored = 1
	mouse_opacity = 0
	invisibility = INVISIBILITY_MAXIMUM
	var/obj/effect/alien/egg/linked_egg

	New(loc, obj/effect/alien/egg/source_egg)
		..()
		linked_egg = source_egg


/obj/effect/egg_trigger/Crossed(atom/A)
	if(!linked_egg) //something went very wrong
		cdel(src)
	else if(get_dist(src, linked_egg) != 1 || !isturf(linked_egg.loc)) //something went wrong
		loc = linked_egg
	else if(iscarbon(A))
		var/mob/living/carbon/C = A
		linked_egg.HasProximity(C)


/obj/structure/tunnel
	name = "tunnel"
	desc = "A tunnel entrance. Looks like it was dug by some kind of clawed beast."
	icon = 'icons/Xeno/effects.dmi'
	icon_state = "hole"

	density = 0
	opacity = 0
	anchored = 1
	unacidable = 1

	var/health = 140
	var/obj/structure/tunnel/other = null
	var/id = null //For mapping

	New()
		spawn(5)
			if(id && !other)
				for(var/obj/structure/tunnel/T in world)
					if(T.id == id && T != src && T.other == null) //Found a matching tunnel
						T.other = src
						src.other = T //Link them!
						break

	examine(mob/user)
		if(!isXeno(user))
			return ..()

		if(!other)
			user << "It does not seem to lead anywhere."
		else
			var/area/A = get_area(other)
			user << "It seems to lead to <b>[A.name]</b>."

/obj/structure/tunnel/proc/healthcheck()
	if(health <= 0)
		visible_message("<span class='danger'>The [src] suddenly collapses!</span>")
		if(other && isturf(other.loc))
			visible_message("<span class='danger'>The [other] suddenly collapses!</span>")
			cdel(other)
		cdel(src)

/obj/structure/tunnel/bullet_act(var/obj/item/projectile/Proj)
	return 0

/obj/structure/tunnel/ex_act(severity)
	switch(severity)
		if(1.0)
			health -= 200
		if(2.0)
			health -= 120
		if(3.0)
			if(prob(50))
				health -= 50
			else
				health -= 25
	healthcheck()

/obj/structure/tunnel/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(!isXeno(user))
		return ..()
	attack_alien(user)

/obj/structure/tunnel/attack_alien(mob/living/carbon/Xenomorph/M)
	if(!istype(M) || M.stat)
		return

	//Prevents using tunnels by the queen to bypass the fog.
	if(ticker && ticker.mode && ticker.mode.flags_round_type & MODE_FOG_ACTIVATED)
		if(!living_xeno_queen)
			M << "<span class='xenowarning'>There is no queen. You must choose a queen first.</span>"
			r_FAL
		else if(istype(M, /mob/living/carbon/Xenomorph/Queen))
			M << "<span class='xenowarning'>There is no reason to leave the safety of the caves yet.</span>"
			r_FAL

	var/tunnel_time = 40

	if(M.mob_size == MOB_SIZE_BIG) //Big xenos take WAY longer
		tunnel_time = 120

	if(isXenoLarva(M)) //Larva can zip through near-instantly, they are wormlike after all
		tunnel_time = 5

	if(!other || !isturf(other.loc))
		M << "<span class='warning'>\The [src] doesn't seem to lead anywhere.</span>"
		return
	if(tunnel_time <= 50)
		M.visible_message("<span class='xenonotice'>\The [M] begins crawling down into \the [src].</span>", \
		"<span class='xenonotice'>You begin crawling down into \the [src].</span>")
	else
		M.visible_message("<span class='xenonotice'>[M] begins heaving their huge bulk down into \the [src].</span>", \
		"<span class='xenonotice'>You begin heaving your monstrous bulk into \the [src].</span>")

	if(do_after(M, tunnel_time, FALSE))
		if(other && isturf(other.loc)) //Make sure the end tunnel is still there
			M.loc = other.loc
			M.visible_message("<span class='xenonotice'>\The [M] pops out of \the [src].</span>", \
			"<span class='xenonotice'>You pop out through the other side!</span>")
		else
			M << "<span class='warning'>\The [src] ended unexpectedly, so you return back up.</span>"
	else
		M << "<span class='warning'>Your crawling was interrupted!</span>"


/obj/structure/tunnel/attack_hand()
	usr << "<span class='notice'>No way are you going down there! 2spooky!</span>"

/obj/structure/tunnel/attack_paw()
	return attack_hand()


//COMMENTED BY APOP
/*/obj/item/weapon/handcuffs/xeno
	name = "hardened resin"
	desc = "A thick, nasty resin. You could probably resist out of this."
	breakouttime = 200
	cuff_sound = 'sound/effects/blobattack.ogg'
	icon = 'icons/xeno/effects.dmi'
	icon_state = "sticky2"

	dropped()
		cdel(src)
		return*/

/obj/item/weapon/legcuffs/xeno
	name = "sticky resin"
	desc = "A thick, nasty resin. You could probably resist out of this."
	breakouttime = 100
	icon = 'icons/xeno/effects.dmi'
	icon_state = "sticky2"

/obj/item/weapon/legcuffs/xeno/dropped()
	cdel(src)

/obj/structure/stool/bed/nest/attackby(obj/item/weapon/W as obj, mob/user as mob)
	var/aforce = W.force
	health = max(0, health - aforce)
	playsound(loc, 'sound/effects/attackblob.ogg', 25, 1)
	user.visible_message("<span class='warning'>\The [user] hits \the [src] with \the [W]!</span>", \
	"<span class='warning'>You hit \the [src] with \the [W]!</span>")
	healthcheck()

/obj/structure/stool/bed/nest/proc/healthcheck()
	if(health <= 0)
		density = 0
		cdel(src)

/obj/structure/stool/bed/nest/update_icon()
	overlays.Cut()
	if(on_fire)
		overlays += "alien_fire"

/obj/structure/stool/bed/nest/fire_act()
	on_fire = 1
	if(on_fire)
		update_icon()
		spawn(rand(225, 400))
			cdel(src)

/obj/structure/stool/bed/nest/unbuckle(mob/user as mob)
	if(!buckled_mob)
		return
	resisting = 0
	buckled_mob.pixel_y = 0
	buckled_mob.old_y = 0
	..()

/obj/structure/stool/bed/nest/attack_alien(mob/living/carbon/Xenomorph/M)
	if(isXenoLarva(M)) //Larvae can't do shit
		return
	if(M.a_intent == "hurt")
		M.visible_message("<span class='danger'>\The [M] claws at \the [src]!</span>", \
		"<span class='danger'>You claw at \the [src].</span>")
		playsound(loc, 'sound/effects/attackblob.ogg', 25, 1)
		health -= (M.melee_damage_upper + 25) //Beef up the damage a bit
		healthcheck()
	else
		attack_hand(M)

/obj/structure/stool/bed/nest/attack_animal(mob/living/M as mob)
	M.visible_message("<span class='danger'>\The [M] tears at \the [src]!", \
	"<span class='danger'>You tear at \the [src].")
	playsound(loc, 'sound/effects/attackblob.ogg', 25, 1)
	health -= 40
	healthcheck()

/obj/structure/stool/bed/nest/flamer_fire_act()
	cdel(src)

//Alien blood effects.
/obj/effect/decal/cleanable/blood/xeno
	name = "sizzling blood"
	desc = "It's yellow and acidic. It looks like... <i>blood?</i>"
	icon = 'icons/effects/blood.dmi'
	basecolor = "#dffc00"
	amount = 0

/obj/effect/decal/cleanable/blood/gibs/xeno
	name = "steaming gibs"
	desc = "Gnarly..."
	icon_state = "xgib1"
	random_icon_states = list("xgib1", "xgib2", "xgib3", "xgib4", "xgib5", "xgib6")
	basecolor = "#dffc00"
	amount = 0

/obj/effect/decal/cleanable/blood/gibs/xeno/update_icon()
	color = "#FFFFFF"

/obj/effect/decal/cleanable/blood/gibs/xeno/up
	random_icon_states = list("xgib1", "xgib2", "xgib3", "xgib4", "xgib5", "xgib6","xgibup1","xgibup1","xgibup1")

/obj/effect/decal/cleanable/blood/gibs/xeno/down
	random_icon_states = list("xgib1", "xgib2", "xgib3", "xgib4", "xgib5", "xgib6","xgibdown1","xgibdown1","xgibdown1")

/obj/effect/decal/cleanable/blood/gibs/xeno/body
	random_icon_states = list("xgibhead", "xgibtorso")

/obj/effect/decal/cleanable/blood/gibs/xeno/limb
	random_icon_states = list("xgibleg", "xgibarm")

/obj/effect/decal/cleanable/blood/gibs/xeno/core
	random_icon_states = list("xgibmid1", "xgibmid2", "xgibmid3")

/obj/effect/decal/cleanable/blood/xtracks
	basecolor = "#dffc00"
