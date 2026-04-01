class_name VelocityHandler

static func UpdateVel(body, delta):
	var ind = 0
	var toRemove = -1
	
	for data in body.vels:
		var xFin = data.vel.x * data.xDirect
		var yFin = data.vel.y * data.yDirect
		
		if not data.xOverride:
			body.velocity.x += xFin * (Engine.time_scale / 1.0)
		else:
			body.velocity.x = xFin
			
		if not data.yOverride:
			body.velocity.y += yFin * (Engine.time_scale / 1.0)
		else:
			body.velocity.y = yFin
		
		if data.vel.x > 0.0:
			data.vel.x = clamp(data.vel.x - (data.xDamp * delta), 0.0, data.vel.x)
		if data.vel.y > 0.0:
			data.vel.y = clamp(data.vel.y - (data.yDamp * delta), 0.0, data.vel.y)
		
		#body.vels.set(ind, Force.new(data.vel, data.xDamp, data.yDamp, data.xOverride, data.yOverride, data.xDirect, data.yDirect))
		
		if data.vel.x <= 0.0 and data.vel.y <= 0.0:
			toRemove = ind
		
		ind += 1
	
	#if body.is_in_group("Enemies"):
		#if ind > 0:
			#body.set_collision_mask_value(2, false)
		#else:
			#body.set_collision_mask_value(2, true)
	
	if toRemove != -1:
		body.vels.remove_at(toRemove)
