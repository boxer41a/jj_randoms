note
	description: "[
		A random number generator for normally distributed
		values implemented using the Box-Muller transform.
		Feature `item' gives the same number each time called
		unless the state is advanced with a call to `forth'.

		See:  G. E. P. Box, Mervin E. Muller. "A Note on the
		Generation of Random Normal Deviates." The Annals of
		Mathematical Statistics, 29(2) 610-611 June, 1958.
		https://doi.org/10.1214/aoms/1177706645

		This class uses feature `very_close' from {SAFE_DOUBLE_MATH}
		to compare values to avoid floating point errors...
			or NOT,
		because comparisons are only made during post-conditions,
		of simple features, so may not be necessary and are
		therefor commented out.
		]"
	author: "Jimmy J Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	BOX_MULLER

inherit

	ANY
		redefine
			default_create
		end

inherit {NONE}

--	SAFE_DOUBLE_MATH

	DOUBLE_MATH
		redefine
			default_create
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Initialize for Standard Normal Distribution
			-- (i.e. Mean = 0 and Standard Diviation = 1)
		do
			create uniform
			lower := Min_value
			upper := Max_value
			standard_deviation := 1.0
			generate
		ensure then
			not_dirty: not is_dirty
--			standard_mean: very_close (mean, 0.0)
--			standard_diviation: very_close (standard_deviation, 1.0)
		end

feature -- Access

	item: REAL_64
			-- The random number for the current state
		do
			if is_dirty then
				generate
			end
			if is_using_other_item then
				Result := other_item_imp
			else
				Result := item_imp
			end
--print ("{BOX_MULLER}.item:  Result = " + Result.out + "%N")

--			Result := Result * standard_deviation + mean
		ensure
--			definition: very_close (Result, item_imp) or very_close (Result, other_item_imp)
--			implication: not is_using_other_item implies very_close (Result, item_imp)
--			other_implication: is_using_other_item implies very_close (Result, other_item_imp)
		end

	seed: NATURAL_64
			-- The seed used to initialize the generator
		do
			Result := uniform.seed
		ensure
			definition: seed = uniform.seed
		end

	mean: REAL_64
			-- The mean

	standard_deviation: REAL_64
			-- The standard deviation

	lower: REAL_64
			-- The smallest value returned by `item'

	upper: REAL_64
			-- The largest value returned by `item'

	Min_value: REAL_64 = -1.7976931348623157081452e+308
			-- Minimum value allowed for `item'
			-- Same as {REAL_64}.Min_value

	Max_value: REAL_64 = 1.7976931348623157081452e+308
			-- Maximum value allowed for `item'
			-- Same as {REAL_64}.Max_value

feature -- Element change

	set_seed (a_value: NATURAL_64)
			-- Change the `seed'
		do
			uniform.set_seed (a_value)
			is_dirty := True
		ensure
			value_set: seed = a_value
			is_dirty: is_dirty
		end

	set_mean (a_value: REAL_64)
			-- Change the `mean'
		do
			mean := a_value
			is_dirty := True
		ensure
--			definition: very_close (mean, a_value)
			is_dirty: is_dirty
		end

	set_standard_deviation (a_value: REAL_64)
			-- Change the `standard_devaition'
		require
			value_big_enough: a_value > 0.0
		do
			standard_deviation := a_value
			is_dirty := True
		ensure
--			definition: very_close (standard_deviation, a_value)
			is_dirty: is_dirty
		end

	set_range (a_lower, a_upper: REAL_64)
			-- Constrain `item' to between `a_lower' and `a_upper'
		require
			lower_smaller_than_upper: a_lower < a_upper
		do
			lower := a_lower
			upper := a_upper
			if lower > Min_value or upper < Max_value then
				is_constrained := true
			else
				is_constrained := false
			end
			is_dirty := True
		ensure
			is_dirty: is_dirty
			lower_set: lower = a_lower
			upper_set: upper = a_upper
			implication: (a_lower > Min_value or a_upper < Max_value) implies is_constrained
		end

feature -- Basic operations

	start
			-- Resets the generator to the first value in
			-- the sequence created with `seed'.
			-- Not necessary to call this except for reset
		do
			set_seed (seed)
			generate
		ensure
			not_dirty: not is_dirty
		end

	forth
			-- Change state in order to generate a new number
		do
			if is_using_other_item or else is_dirty then
				generate
				is_using_other_item := False
			else
				is_using_other_item := True
			end
		ensure
			not_dirty: not is_dirty
		end

feature -- Status report

	is_constrained: BOOLEAN
			-- Should the numbers returned by `item' be restricted to
			-- a reduced range (i.e. other than [Min_value, Max_value]?

	is_dirty: BOOLEAN
			-- Has the state changed without the generation
			-- of a new `item'.  Used internally to force
			-- a call to `generate'

feature {NONE} -- Implementation

	uniform: MELG_19937
			-- Uniform random number generator

	is_in_range (a_value: REAL_64): BOOLEAN
			-- If `is_constained', is `a_value' [scaled and shifted]
			-- by the `standard_deviation' and `men' inclusively
			-- between `lower' and `upper'?
		do
			Result := a_value >= lower and a_value <= upper
		ensure
			definition: Result implies a_value >= lower and a_value <= upper
		end

	generate
			-- Calculate a new random number (actuall two)
			-- If `is_constained', perform `calculate' until
			-- producing a number that is in range.
		do
			if is_constrained then
					-- Loop until finding a valid number
				from
				until is_in_range (item_imp) and is_in_range (other_item_imp)
				loop
					calculate
				end
			else
					-- just calculate one
				calculate
			end
			is_dirty := False
		end

	calculate
			-- Perform the caculation, which finds two numbers
			-- from two call to the `uniform_rng'
		local
			u1, u2: REAL_64
			ln_u1: REAL_64
			pi_u2: REAL_64
		do
				-- get two uniformly distributed reals
			from
			until u1 > 0.0
			loop
				u1 := uniform.real_item
				uniform.forth
			end
			u2 := uniform.real_item
			uniform.forth
				-- calculate using natural logrithm
			check
				u1_big_enough: u1 > 0.0
					-- because of loop above & required for ln(x)
			end
			ln_u1 := sqrt (-2.0 * log (u1))
			pi_u2 := 2 * {MATH_CONST}.pi * u2
			item_imp := ln_u1 * cosine (pi_u2)
			other_item_imp := pi_u2 * sine (pi_u2)
				-- Scale and shift by `standard_deviation' and mean
			item_imp := item_imp * standard_deviation + mean
			other_item_imp := other_item_imp * standard_deviation + mean
		end

	item_imp: REAL_64
			-- The first of two number produced by `generate'
			-- Select this one when not `is_using_other_item'

	other_item_imp: REAL_64
			-- The second number found in `generate'
			-- Move to this number in `forth'

	is_using_other_item: BOOLEAN
			-- Flag telling `item' to return `other_item'

invariant

end
