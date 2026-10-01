local enqueue = ya.sync(function(state, amount)
	state.pending = (state.pending or 0) + amount

	-- If an animation is already running, just modify its destination.
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
		return 0
	end

	local step = pending > 0 and 1 or -1
	state.pending = pending - step

	return step
end)

return {
	entry = function(_, job)
		local amount = tonumber(job.args[1])

		if not amount or amount == 0 then
			return
		end

		-- Add this motion to the current animation.
		--
		-- Only the first invocation becomes the worker.
		-- Subsequent presses just change `state.pending`.
		if not enqueue(amount) then
			return
		end

		while true do
			local step = next_step()

			if step == 0 then
				break
			end

			-- ya.emit("arrow", {
			-- 	step > 0 and "next" or "prev",
			-- })
			ya.emit("arrow", { step })

			-- 60 cursor updates per second.
			ya.sleep(1 / 60)
		end
	end,
}
