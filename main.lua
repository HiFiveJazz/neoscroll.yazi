local MIN_SPEED = 55       -- rows/sec at start/end
local MAX_SPEED = 150      -- rows/sec while cruising
local EASE_DISTANCE = 18   -- rows over which we ease
local SPEED_SMOOTHING = 0.18

local enqueue = ya.sync(function(state, amount)
	local current = cx.active.current
	local count = #current.files
	local cursor = current.cursor

	if count == 0 then
		state.pending = 0
		return false
	end

	-- Already at the top: discard impossible upward motion.
	if amount < 0 and cursor == 0 then
		if (state.pending or 0) < 0 then
			state.pending = 0
		end
		return false
	end

	-- Already at the bottom: discard impossible downward motion.
	if amount > 0 and cursor >= count - 1 then
		if (state.pending or 0) > 0 then
			state.pending = 0
		end
		return false
	end

	state.pending = (state.pending or 0) + amount

	if state.running then
		return false
	end

	state.running = true
	return true
end)

local next_step = ya.sync(function(state)
	local pending = state.pending or 0

	if pending == 0 then
		state.running = false
		return 0, 0
	end

	local current = cx.active.current
	local count = #current.files
	local cursor = current.cursor

	if count == 0 then
		state.pending = 0
		state.running = false
		return 0, 0
	end

	-- Hit the top while upward movement is still queued.
	if pending < 0 and cursor == 0 then
		state.pending = 0
		state.running = false
		return 0, 0
	end

	-- Hit the bottom while downward movement is still queued.
	if pending > 0 and cursor >= count - 1 then
		state.pending = 0
		state.running = false
		return 0, 0
	end

	local step = pending > 0 and 1 or -1

	state.pending = pending - step

	return step, math.abs(state.pending)
end)

local function smoothstep(t)
	return t * t * (3 - 2 * t)
end

return {
	entry = function(_, job)
		local amount = tonumber(job.args[1])

		if not amount or amount == 0 then
			return
		end

		if not enqueue(amount) then
			return
		end

		local speed = MIN_SPEED
		local last_step = 0

		while true do
			local step, remaining = next_step()

			if step == 0 then
				break
			end

			-- If direction changes, slow down before accelerating
			-- in the opposite direction.
			if last_step ~= 0 and step ~= last_step then
				speed = MIN_SPEED
			end

			last_step = step

			ya.emit("arrow", { step })

			-- More queued movement = higher target speed.
			--
			-- smoothstep gives us:
			-- slow -> fast -> slow
			local t = math.min(remaining / EASE_DISTANCE, 1)
			local eased = smoothstep(t)

			local target_speed =
				MIN_SPEED + (MAX_SPEED - MIN_SPEED) * eased

			-- Gradually approach the target rather than instantly
			-- changing speeds.
			speed =
				speed + (target_speed - speed) * SPEED_SMOOTHING

			ya.sleep(1 / speed)
		end
	end,
}
