local enqueue = ya.sync(function(state, amount)
	local current = cx.active.current
	local count = #current.files
	local cursor = current.cursor

	-- Nothing to scroll.
	if count == 0 then
		state.pending = 0
		return false
	end

	-- Don't queue motion that is already blocked by a boundary.
	if amount < 0 and cursor == 0 then
		if (state.pending or 0) < 0 then
			state.pending = 0
		end
		return false
	end

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
		return 0
	end

	local current = cx.active.current
	local count = #current.files
	local cursor = current.cursor

	if count == 0 then
		state.pending = 0
		state.running = false
		return 0
	end

	-- We've reached the top while upward motion is still queued.
	-- Discard that impossible movement immediately.
	if pending < 0 and cursor == 0 then
		state.pending = 0
		state.running = false
		return 0
	end

	-- Same thing at the bottom.
	if pending > 0 and cursor >= count - 1 then
		state.pending = 0
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

		if not enqueue(amount) then
			return
		end

		while true do
			local step = next_step()

			if step == 0 then
				break
			end

			ya.emit("arrow", { step })
			ya.sleep(1 / 60)
		end
	end,
}
