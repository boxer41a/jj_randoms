note
	description: "[
		Produces normally distributed random numbers using
		the ziggurat algorithm. 
		See https://en.wikipedia.org/wiki/Ziggurat_algorithm
		]"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	JJ_NORMAL

inherit

	ANY
		redefine
			default_create
		end

feature {NONE} -- Initialization

	default_create
			-- Initialize an instance
		do
			create uniform
			create region_x_imp
		ensure then
			is_dirty: is_dirty
			standard_mean: mean = {like mean}.one
		end

feature -- Access

	item: REAL
			-- The number generated from the Current state
		do
			if is_dirty then
				item_imp := generated
			end
			Result := generated
		end

	seed: like normal.seed
			-- The seed value used to start the generator
		do
			Result := uniform.seed
		ensure
			definition: Result = normal.seed
		end

	mean: REAL_64
			-- The desired mean of the function

	standard_deviation: REAL_64
			-- The desired standard deviation of the function

feature -- Element change

	set_seed (a_value: like normal.seed)
			-- Change the `seed'
		do
			uniform.set_seed (a_value)
		end

	set_mean (a_value: like mean): like x_value
			-- Change the `mean'
		do
			mean := a_value
			set_dirty
		end

	set_deviation (a_value: like standard_deviation)
			-- Change the `standard_deviation'
		do
			standard_deviation := a_value
			set_dirty
		end

feature -- Basic operations

	start
			-- Reset the random generator
		do
			uniform.start (seed)
			set_dirty
		end

	forth
			-- Advance the state so the next call to `item' returns
			-- a new number
		do
			uniform.forth
			set_dirty
		end

feature -- Status report

	is_dirty: BOOLEAN
			-- Has a paramenter been changed or `forth' called
			-- since last computation?
		do
			Result := not attached item_imp
		end

feature -- Status setting

	set_dirty
			-- Ensure the next call to `item' recomputes a value
		do
			item_imp := Void
		ensure
			correct_value: is_dirty
			definition: not attached item_imp
		end

feature {NONE} -- Implementation

	generated: REAL_64
			-- One random number generated
		require
			not_already_generated: is_dirty
		do

		end

	region_count: INTEGER = 256
			-- The number of regions (i.e. rectangles in original
			-- Ziggurat algorithm) into which to divide the function.

	region_index: INTEGER
			-- The y coordinate (i.e. the top edge) of the
			-- region from which a to draw a sample point

	x_value (a_index: like region_index): REAL
			-- The x coordinate (i.e. the right edge) of the
			-- region `a_y' from which to draw a sample point.
			-- The values are memoized [or precomputed?] and
			-- stored in `x_values_imp'
		do
			if x_values_imp.has (a_y) then
				Result := x_values_imp [a_y]
			else
				Result := computed_x (a_y)
				region_x_imp.extend (Result, a_y)
			end
		end

	y_value (a_index: like region_index): REAL
			-- The y coordinate (i.e. the top edge) of the
			-- region `a_index' from which to draw a sample point.
			-- The values are memoized [or precomputed?] and
			-- stored in `y_values_imp'
		require
			index_big_enough: a_index >= 0
			index_small_enough: a_index <= region_count
		do
			if y_values_imp.has (a_index) then
				Result := y_values_imp [a_index]
			else
				Result := computed_y (a_index)
				y_values_imp.extend (Result, a_index)
			end
		end

	sqrt_2_pi: REAL_64
			-- sqare root of 2 * Pi
		once
			Result := sqrt (2 * {MATH_CONST}.Pi_2)
		end

	value (a_x: like x_value): REAL_64
			-- The result of computing f(x) at `a_x' for the
			-- Normal Distribution: Mean = `u' and standard Deviation = `a'
			--   f(x) := e^(-(x^2 - u) / (2 * a)^2) / (a * sqrt (2 * Pi))
			-- Standard Normal: `u' = 0 & `a' = 1
			--   f(x) := e^(x^2 / 2) / (sqrt (2 * Pi)
		do
			 Result := exp (x^2 / 2) / sqrt_2_pi
		end

	computed_x (a_index: REAL_64): REAL_64
			-- The calculated value of an x coordinate
			-- given `a_index' to the region
		do
			check
				fix_me: false then
			end
		end

	x_values_imp: HASH_TABLE [INTEGER_32, REAL_64]
			-- Memoization of the `x_value' values
			-- indexed by the y coordinate `region_index'

	y_values_imp: HASH_TABLE [INTEGER_32, REAL_64]
			-- Memoization of the `region_y' values indexed
			-- by the y coordinate `region_index'

feature {NONE} -- Implementation

	normal: MELG
			-- The uniform random number generator used
			-- by the algorithm

	item_imp: detachable like item
			-- Implementation of `item' to prevent multiple calls
			-- to generate a new number if nothing in the state
			-- has changed

end
