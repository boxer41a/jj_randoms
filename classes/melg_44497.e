note
	description: "[
		A {MELG} Random Number generator with a period of 2^44497
	]"
	author:    "Jimmy J. Johnson"
	date:      "2/6/22"
	copyright: "Copyright (c) 2021, Jimmy J. Johnson"
	license:   "Eiffel Forum v2 (http://www.eiffel.com/licensing/forum.txt)"

class
	MELG_44497

inherit

	MELG

	MELG_44497_CONSTANTS
		undefine
			default_create
		end

create
	default_create,
	from_seed,
	from_array

end
