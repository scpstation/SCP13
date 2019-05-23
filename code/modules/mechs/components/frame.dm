/obj/item/frame_holder
	matter = list(MATERIAL_STEEL = 175000, MATERIAL_PLASTIC = 50000, MATERIAL_OSMIUM = 30000)

/obj/item/frame_holder/New(var/newloc)
	new /obj/structure/heavy_vehicle_frame(newloc)
	qdel(src)

/obj/structure/heavy_vehicle_frame
	name = "exosuit frame"
	desc = "The frame for an exosuit, apparently."
	icon = 'icons/mecha/mech_parts.dmi'
	icon_state = "backbone"
	density = 1
	pixel_x = -8

	// Holders for the final product.
	var/obj/item/mech_component/manipulators/arms
	var/obj/item/mech_component/propulsion/legs
	var/obj/item/mech_component/sensors/head
	var/obj/item/mech_component/chassis/body
	var/is_wired = 0
	var/is_reinforced = 0
	var/set_name

/obj/structure/heavy_vehicle_frame/proc/set_colour(var/new_colour)
	var/painted_component = FALSE
	for(var/obj/item/mech_component/comp in list(body, arms, legs, head))
		if(comp.set_colour(new_colour))
			painted_component = TRUE
	if(painted_component)
		queue_icon_update()

/obj/structure/heavy_vehicle_frame/Destroy()
	QDEL_NULL(arms)
	QDEL_NULL(legs)
	QDEL_NULL(head)
	QDEL_NULL(body)
	. = ..()

/obj/structure/heavy_vehicle_frame/examine()
	. = ..()
	if(.)
		if(!arms)
			to_chat(usr, SPAN_WARNING("It is missing manipulators."))
		if(!legs)
			to_chat(usr, SPAN_WARNING("It is missing propulsion."))
		if(!head)
			to_chat(usr, SPAN_WARNING("It is missing sensors."))
		if(!body)
			to_chat(usr, SPAN_WARNING("It is missing a chassis."))
		if(is_wired == 1)
			to_chat(usr, SPAN_WARNING("It has not had its wiring adjusted."))
		else if(!is_wired)
			to_chat(usr, SPAN_WARNING("It has not yet been wired."))
		if(is_reinforced == 1)
			to_chat(usr, SPAN_WARNING("It has not had its internal reinforcement secured."))
		else if(is_reinforced == 2)
			to_chat(usr, SPAN_WARNING("It has not had its internal reinforcement welded in."))
		else if(!is_reinforced)
			to_chat(usr, SPAN_WARNING("It does not have any internal reinforcement."))

/obj/structure/heavy_vehicle_frame/on_update_icon()
	var/list/new_overlays = get_mech_images(list(legs, head, body, arms), layer)
	if(body)
		if(legs)
			anchored = TRUE
		else
			anchored = FALSE
		density = TRUE
		overlays += get_mech_image(null, "[body.icon_state]_cockpit", body.icon, body.color)
		if(body.pilot_coverage < 100 || body.transparent_cabin)
			new_overlays += get_mech_image(null, "[body.icon_state]_open_overlay", body.icon, body.color)
	else
		density = FALSE
	overlays = new_overlays
	if(density != opacity)
		set_opacity(density)

/obj/structure/heavy_vehicle_frame/New()
	..()
	set_dir(SOUTH)
	update_icon()

/obj/structure/heavy_vehicle_frame/set_dir()
	..(SOUTH)

/obj/structure/heavy_vehicle_frame/attackby(var/obj/item/thing, var/mob/user)

	// Removing components.
	if(isCrowbar(thing))
		if(is_reinforced == 1)
			if(!do_after(user, 5 * user.skill_delay_mult(SKILL_DEVICES)) || !material)
				return
			user.visible_message(SPAN_NOTICE("\The [user] crowbars the reinforcement off \the [src]."))
			material.place_sheet(src.loc, 10)
			material = null
			return
		var/obj/item/component
		if(arms)
			component = arms
			arms = null
		else if(body)
			component = body
			body = null
		else if(legs)
			component = legs
			legs = null
		else if(head)
			component = head
			head = null
		else
			to_chat(user, SPAN_WARNING("There are no components to remove."))
			return

		if(!do_after(user, 40 * user.skill_delay_mult(SKILL_DEVICES)) || component.loc != src)
			return
		user.visible_message(SPAN_NOTICE("\The [user] crowbars \the [component] off \the [src]."))
		component.forceMove(get_turf(src))
		user.put_in_hands(component)
		playsound(user.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		update_icon()
		return

	// Final construction step.
	else if(isScrewdriver(thing))

		// Check for basic components.
		if(!(arms && legs && head && body))
			to_chat(user,  SPAN_WARNING("There are still parts missing from \the [src]."))
			return

		// Check for wiring.
		if(is_wired < 2)
			if(is_wired == 1)
				to_chat(user, SPAN_WARNING("\The [src]'s wiring has not been adjusted!"))
			else
				to_chat(user, SPAN_WARNING("\The [src] is not wired!"))
			return

		// Check for basing metal internal plating.
		if(is_reinforced < 3)
			if(is_reinforced == 1)
				to_chat(user, SPAN_WARNING("\The [src]'s internal reinforcement has not been secured!"))
			else if(is_reinforced == 2)
				to_chat(user, SPAN_WARNING("\The [src]'s internal reinforcement has not been welded down!"))
			else
				to_chat(user, SPAN_WARNING("\The [src] has no internal reinforcement!"))
			return

		visible_message(SPAN_NOTICE("\The [user] begins tightening screws, flipping connectors and finishing off \the [src]."))
		if(!do_after(user, 50 * user.skill_delay_mult(SKILL_DEVICES)))
			return

		// We're all done. Finalize the exosuit and pass the frame to the new system.
		var/mob/living/exosuit/M = new(get_turf(src), src)
		visible_message(SPAN_NOTICE("\The [user] finishes off \the [M]."))
		playsound(user.loc, 'sound/items/Screwdriver.ogg', 100, 1)

		arms = null
		legs = null
		head = null
		body = null
		qdel(src)

		return

	// Installing wiring.
	else if(isCoil(thing))

		if(is_wired)
			to_chat(user, SPAN_WARNING("\The [src] has already been wired."))
			return

		var/obj/item/stack/cable_coil/CC = thing
		if(CC.get_amount() < 10)
			to_chat(user, SPAN_WARNING("You need at least ten units of cable to complete the exosuit."))
			return

		user.visible_message("\The [user] begins wiring \the [src]...")

		if(!do_after(user, 30 * user.skill_delay_mult(SKILL_ELECTRICAL)))
			return

		if(!CC || !user || !src || CC.amount < 10 || is_wired)
			return

		CC.use(10)
		user.visible_message("\The [user] installs wiring in \the [src].")
		playsound(user.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		is_wired = 1
	// Securing wiring.
	else if(isWirecutter(thing))
		if(!is_wired)
			to_chat(user, "There is no wiring in \the [src] to neaten.")
			return

		user.visible_message("\The [user] begins adjusting the wiring inside \the [src]...")
		var/last_wiring_state = is_wired
		if(!do_after(user, 30 * user.skill_delay_mult(SKILL_ELECTRICAL)) || last_wiring_state != is_wired)
			return

		visible_message("\The [user] [(is_wired == 2) ? "snips some of" : "neatens"] the wiring in \the [src].")
		playsound(user.loc, 'sound/items/Wirecutter.ogg', 100, 1)
		is_wired = (is_wired == 2) ? 1 : 2
	// Installing metal.
	else if(istype(thing, /obj/item/stack/material))
		var/obj/item/stack/material/M = thing
		if(M.material)
			if(is_reinforced)
				to_chat(user, SPAN_WARNING("There is already a material reinforcement installed in \the [src]."))
				return
			if(M.amount < 10)
				to_chat(user, SPAN_WARNING("You need at least ten sheets to reinforce \the [src]."))
				return

			visible_message("\The [user] begins layering the interior of the \the [src] with \the [M].")

			if(!do_after(user, 30 * user.skill_delay_mult(SKILL_DEVICES)) || is_reinforced)
				return

			visible_message("\The [user] reinforces \the [src] with \the [M].")
			playsound(user.loc, 'sound/items/Deconstruct.ogg', 50, 1)
			material = M.material
			is_reinforced = 1
			M.use(10)
		else
			return ..()
	// Securing metal.
	else if(isWrench(thing))
		if(!is_reinforced)
			to_chat(user, SPAN_WARNING("There is no metal to secure inside \the [src]."))
			return
		if(is_reinforced == 3)
			to_chat(user, SPAN_WARNING("\The [src]'s internal reinforcment has been welded in."))
			return

		var/last_reinforced_state = is_reinforced
		visible_message("\The [user] begins adjusting the metal reinforcement inside \the [src].")
		if(!do_after(user, 30 * user.skill_delay_mult(SKILL_DEVICES)) || last_reinforced_state != is_reinforced)
			return

		visible_message("\The [user] [(is_reinforced == 2) ? "unsecures" : "secures"] the metal reinforcement inside \the [src].")
		playsound(user.loc, 'sound/items/Ratchet.ogg', 100, 1)
		is_reinforced = (is_reinforced == 2) ? 1 : 2
	// Welding metal.
	else if(isWelder(thing))
		var/obj/item/weapon/weldingtool/WT = thing
		if(!is_reinforced)
			to_chat(user, SPAN_WARNING("There is no metal to secure inside \the [src]."))
			return
		if(is_reinforced == 1)
			to_chat(user, SPAN_WARNING("The reinforcement inside \the [src] has not been secured."))
			return
		if(!WT.isOn())
			to_chat(user, SPAN_WARNING("Turn \the [WT] on, first."))
			return
		if(WT.remove_fuel(1, user))

			var/last_reinforced_state = is_reinforced
			visible_message("\The [user] begins welding the metal reinforcement inside \the [src].")
			if(!do_after(user, 30 * user.skill_delay_mult(SKILL_DEVICES)) || last_reinforced_state != is_reinforced)
				return

			visible_message("\The [user] [(is_reinforced == 3) ? "unwelds the reinforcement from" : "welds the reinforcement into"] \the [src].")
			is_reinforced = (is_reinforced == 3) ? 2 : 3
			playsound(user.loc, 'sound/items/Welder.ogg', 50, 1)
		else
			to_chat(user, SPAN_WARNING("Not enough fuel!"))
			return
	// Installing basic components.
	else if(istype(thing,/obj/item/mech_component/manipulators))
		if(arms)
			to_chat(user, SPAN_WARNING("\The [src] already has manipulators installed."))
			return
		if(install_component(thing, user)) 
			arms = thing
	else if(istype(thing,/obj/item/mech_component/propulsion))
		if(legs)
			to_chat(user, SPAN_WARNING("\The [src] already has a propulsion system installed."))
			return
		if(install_component(thing, user)) 
			legs = thing
	else if(istype(thing,/obj/item/mech_component/sensors))
		if(head)
			to_chat(user, SPAN_WARNING("\The [src] already has a sensor array installed."))
			return
		if(install_component(thing, user)) 
			head = thing
	else if(istype(thing,/obj/item/mech_component/chassis))
		if(body)
			to_chat(user, SPAN_WARNING("\The [src] already has an outer chassis installed."))
			return
		if(install_component(thing, user)) 
			body = thing
	else
		return ..()
	update_icon()
	return

/obj/structure/heavy_vehicle_frame/proc/install_component(var/obj/item/thing, var/mob/user)
	var/obj/item/mech_component/MC = thing
	if(istype(MC) && !MC.ready_to_install())
		to_chat(user, SPAN_WARNING("\The [MC] [MC.gender == PLURAL ? "are" : "is"] not ready to install."))
		return 0
	if(user)
		visible_message(SPAN_NOTICE("\The [user] begins installing \the [thing] into \the [src]."))
		if(!do_after(user, 30 * user.skill_delay_mult(SKILL_ELECTRICAL)) || user.get_active_hand() != thing)
			return
		user.drop_from_inventory(thing)
	thing.forceMove(src)
	visible_message(SPAN_NOTICE("\The [user] installs \the [thing] into \the [src]."))
	playsound(user.loc, 'sound/machines/click.ogg', 50, 1)
	return 1