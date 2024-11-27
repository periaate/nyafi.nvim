local M = {}

local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event



M.config = {
	maps = {
		open = {}, -- keymap(s) to open file
		save = {}, -- keymap(s) to save file
		exit = {}, -- keymap(s) to exit file
	},
	events = {
		pre_open = nil, -- callback ran on opening
		post_open = nil, -- callback ran on opening
		pre_exit = nil, -- callback ran on exiting
		post_exit = nil, -- callback ran on exiting
	},
	filename = nil, -- string|function
}

function table_T(tbl, fieldName)
	-- Check if the input is a table
	if type(tbl) ~= "table" then
		return false
	end

	-- Check if the field exists and is true
	return tbl[fieldName] == true
end

local function clear() vim.api.nvim_buf_set_lines(op.buf, 0, -1, false, {}) end

function M.callbacks(this, cbs)
	function call(cb)
		if type(cb) == "function" then cb(this) end
	end

	if type(cbs) == "table" then
		for _, v in ipairs(cbs) do call(v) end
	else
		print("calling cb")
		call(cbs)
	end
end

function all(buf, rhs, arr, bufnr)
	bufnr = bufnr or 0
	if not rhs then return end
	if not arr then return end
	if type(arr) == "string" then
		if buf then
			if not vim.api.nvim_buf_is_valid(bufnr) then return end
			vim.api.nvim_buf_set_keymap(bufnr, 'n', arr, "", { callback = rhs })
		else 
			vim.keymap.set('n', arr, rhs)
		end
	elseif type(arr) == "table" then
		if buf then
			if not vim.api.nvim_buf_is_valid(bufnr) then return end
			for _, v in ipairs(arr) do
				if type(v) == "string" then	vim.api.nvim_buf_set_keymap(bufnr, 'n', v, "", { callback = rhs }) end
			end
		else
			for _, v in ipairs(arr) do
				if type(v) == "string" then	vim.keymap.set('n', v, rhs) end
			end
		end
	end
end


function M.write_binds(this, bufnr)
	bufnr = bufnr or 0

	all(false, function() this:open() end, this.config.maps.open, bufnr)
	all(true, function() this:save() end, this.config.maps.save, bufnr)
	all(true, function() this:exit() end, this.config.maps.exit, bufnr)
end

function M.mount(this)
	this.popup:mount()
	this:write_binds(this.popup.bufnr)
end

function M.unmount(this)
	this.popup:unmount()
end


function once(func) 
	local status = true
	return function()
		if status then
			func()
			status = false
		end
	end
end

function M.get_filename(this, fn)
	if not fn then
		if type(this.config.filename) == "function" then
			fn = this.config.filename()
		elseif type(this.config.filename) == "string" then
			fn = this.config.filename
		end
	end
	return fn
end

function M.open(fn)
	if M.popup then return end
	fn = M:get_filename(fn)
	M.exited = false
	local popup = Popup({
		enter = true,
		focusable = true,
		border = {
			style = "rounded",
		},
		position = "50%",
		size = {
			width = "80%",
			height = "80%",
		},
	})

	M.popup = popup
	M.fn = fn

	M:callbacks(M.config.events.pre_open)
	M:mount()
	M:callbacks(M.config.events.post_open)
	popup:on({ event.BufLeave, event.BufUnload }, once(function() M:exit() end))
	if fn then M:read_file_to_buf(fn) end
end

function M.save(this, fn)
	fn = this:get_filename()
	if not fn then return end
	if not fn then error("no valid filepath given") end
	fn = vim.fn.expand(fn)
	if not this.popup then return end
	this.write_buf_to_file(this.popup.bufnr, fn)
end

function M.exit(this)
	if table_T(this.popup, "mounted") then return end
	if this.exited then return end
	this.exited = true
	this:callbacks(this.config.events.pre_exit)
	this:save()
	this:unmount()
	this:callbacks(this.config.events.post_exit)

	this.fn = ""
	this.popup = nil
end

function M.read_file_to_buf(this, fn)
	vim.api.nvim_command("$read " .. fn)
	-- there is a phantom line. These commands remove it.
	vim.cmd("normal! k") 
	vim.cmd("normal! dd")
end

function M.write_buf_to_file(buf, fn)
	if not vim.api.nvim_buf_is_valid(buf) then return end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local file = io.open(fn, "w")
	for _, line in ipairs(lines) do
		file:write(line .. "\n")
	end
	file:close()
end


function M.setup()
	all(M.config.maps.open)
end

return M
