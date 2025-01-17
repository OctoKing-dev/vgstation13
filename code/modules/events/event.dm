/datum/event	//NOTE: Times are measured in master controller ticks!
	var/startWhen		= 0	//When in the lifetime to call start().
	var/announceWhen	= 0	//When in the lifetime to call announce().
	var/endWhen			= 0	//When in the lifetime the event should end.
	var/oneShot			= 0	//If true, then the event removes itself from the list of potential events on creation.

	var/activeFor		= 0	//How long the event has existed. You don't need to change this.
	var/last_fired		= 0 //When was the last time an event of this exact type fired?

//Called by event dynamic, returns the percent chance to fire if successful, 0 otherwise.
// Args: list: active_with_role. The number of jobs that have active members. Used as active_with_role["AI"] = number of active.
/datum/event/proc/can_start(var/list/active_with_role)
	return 0

//Called first before processing.
//Allows you to setup your event, such as randomly
//setting the startWhen and or announceWhen variables.
//Only called once.
/datum/event/proc/setup()
	return

//Called when the tick is equal to the startWhen variable.
//Allows you to start before announcing or vice versa.
//Only called once.
/datum/event/proc/start()
	return

//Called when the tick is equal to the announceWhen variable.
//Allows you to announce before starting or vice versa.
//Only called once.
/datum/event/proc/announce()
	return

//Called on or after the tick counter is equal to startWhen.
//You can include code related to your event or add your own
//time stamped events.
//Called more than once.
/datum/event/proc/tick()
	return

//Called on or after the tick is equal or more than endWhen
//You can include code related to the event ending.
//Do not place spawn() in here, instead use tick() to check for
//the activeFor variable.
//For example: if(activeFor == myOwnVariable + 30) doStuff()
//Only called once.
/datum/event/proc/end()
	return



//Do not override this proc, instead use the appropiate procs.
//This proc will handle the calls to the appropiate procs.
/datum/event/proc/process()
	set waitfor = FALSE

	if(activeFor > startWhen && activeFor < endWhen)
		tick()

	if(activeFor == startWhen)
		start()

	if(activeFor == announceWhen)
		announce()

	if(activeFor == endWhen)
		end()

	// Everything is done, let's clean up.
	if(activeFor >= endWhen && activeFor >= announceWhen && activeFor >= startWhen)
		kill()

	activeFor++


//Garbage collects the event by removing it from the global events list,
//which should be the only place it's referenced.
//Called when start(), announce() and end() has all been called.
/datum/event/proc/kill()
	events.Remove(src)


//Adds the event to the global events list, and removes it from the list
//of potential events.
/datum/event/New(var/start_event = TRUE)
	if(start_event)
		setup()
		events.Add(src)
	..()

//Check the time since last fired, if at all.
//Find the percentage of an hour that has passed since then in deciseconds.
//For example, if 55 minutes have passed, 36000-33000 = 3000
//Weight is lowered by this value over 300 deciseconds. As in the above example, 3000/300=10. Reduce weight by 10.
//Almost no event can fire within 25 minutes of its last firing (~50 weight reduction)
/datum/event/proc/recency_weight()
	if(!last_fired)
		return 0
	var/time_until_recharge = (1 HOURS) - (world.time - last_fired)
	return max(0,time_until_recharge / (30 SECONDS))
