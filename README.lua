# nyafi
a cute floating file editing thing!

### installation
`lazy`

```lua
return {
	'periaate/nyafi.nvim',
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		local nyafi = require("nyafi")
		nyafi.config = {} -- your configuration here
	end
}
```

### configuration
`nyafi.nvim` has no default configurations.

nyafi has the following configuration keys.

```lua
config = {
	maps = {
		open = {}, -- keymap(s) to open file
		save = {}, -- keymap(s) to save file
		exit = {}, -- keymap(s) to exit file
	},
	events = {
		pre_open = nil, -- callback(s) ran before opening
		post_open = nil, -- callback(s) ran after opening
		pre_exit = nil, -- callback(s) ran before exiting
		post_exit = nil, -- callback(s) ran after exiting
	},
	filename = nil, -- string|function; function is given the object as an argument.
}
```
