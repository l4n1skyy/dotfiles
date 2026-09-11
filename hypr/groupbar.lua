local active_border_color = { colors = { "rgba(79818688)", "rgba(cacccc88)" }, angle = 45 }
local inactive_border_color = { colors = { "rgba(59606444)", "rgba(969b9b44)" }, angle = 45 }

hl.config({
	group = {
		groupbar = {
			col = {
				active = active_border_color,
				inactive = inactive_border_color,
			},
		},
	},
})
