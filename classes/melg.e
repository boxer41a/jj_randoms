note
	description: "[
		Root class for the MELG_xxx classes which provide various period
		lengths (e.g. MELG_607, MELG_19937, and others).  The descendent
		classes effect the deferred features (constants) by also inheriting
		from the appropiate constants classes (e.g. MELG_607_CONSTANTS,
		MELG_19937_CONSTANTS, etc), giving the different period lengths.

		This implementation of the MELG algorithm is modeled after the C-code
		developed by Shin Harase and Takamitsu Kimoto, which is available
		at https://github.com/sharase/melg-64.

		This class adapts the code to a more Eiffel-like interface:
		  1) Getting a random number does not advance the state.  Calling
		     `item' multiple times without calling `forth' will return
		     the same value.
		  2) Feature `forth' advances the state by incrementing the index
		     and then calling `twist'.
		  3) Feature `twist' advances the state vector.  Conditionals in
		     this feature distinguishes what the C-code called "case_1",
		     "case_2", "case_3", and "case_4".
		  4) The "tempering" equations that were in the "case_x" methods
		     are in feature `item'.
	]"
	author:    "Jimmy J. Johnson"
	date:      "2/6/22"
	copyright: "Copyright (c) 2021, Jimmy J. Johnson"
	license:   "Eiffel Forum v2 (http://www.eiffel.com/licensing/forum.txt)"

deferred class
	MELG

inherit

	ANY
		redefine
			default_create
		end

feature {NONE} -- Initialization

	default_create
			-- Set up Current.
		do
			create mt.make_filled (Zero, nn)
			initialize (Default_seed)
			set_range (Min_value, Max_value)
			twist
		ensure then
			mt_array_sized_correctly: mt.count = nn
			seed_initialized: seed = Default_seed
			initial_index_set: index = 0
			range_initialized: lower = Min_value and upper = Max_value
		end

	from_seed (a_seed: NATURAL_64)
			-- Create an instance, initializing from `a_seed'
		do
			create mt.make_filled (Zero, nn)
			initialize (a_seed)
			set_range (Min_value, Max_value)
			twist
		ensure
			mt_array_sized_correctly: mt.count = nn
			seed_initialized: seed = a_seed
			initial_index_set: index = 0
			range_initialized: lower = Min_value and upper = Max_value
		end

	from_array (a_array: ARRAY [NATURAL_64])
			-- Create an instance, initializing from `a_array'
		local
			i, j, k: INTEGER_32
		do
			create mt.make_filled (Zero, nn)
			initialize (Array_seed)
			check attached {SPECIAL [NATURAL_64]} a_array.to_c as spec then
					-- c_initialize code converted to Eiffel
				i := 1
				j := 0
				from k := nn.max (a_array.count)
				until k <= 0
				loop
					mt[i] := (mt[i] ⊕ ((mt[i - 1] ⊕ (mt[i - 1] |>> 62)) * 3935559000370003845))
								+ spec[j] + j.as_natural_64
					i := i + 1
					j := j + 1
					if i >= nn then
						mt[0] := mt[nn - 1]
						i := 1
					end
					if j >= a_array.count then
						j := 0
					end
					k := k - 1
				end
				from k := nn - 1
				until k <= 0
				loop
					mt[i] := (mt[i] ⊕ ((mt[i - 1] ⊕ (mt[i - 1] |>> 62)) * 2862933555777941757)) - i.as_natural_64
					i := i+ 1
					if i >= nn then
						mt[0] := mt[nn - 1]
						i := 1
					end
					k := k - 1
				end
				mt[0] := mt[0] | (One |<< 63)
			end
			lung := (lung ⊕ ((mt[NN-1] ⊕ (mt[NN-1] |>> 62)) * 2862933555777941757)) - nn.as_natural_64;
			set_range (Min_value, Max_value)
			twist
		ensure
			mt_array_sized_correctly: mt.count = nn
			seed_initialized: seed = Array_seed
			initial_index_set: index = 0
			range_initialized: lower = Min_value and upper = Max_value
		end

	initialize (a_seed: NATURAL_64)
			-- Reset the generator from `a_seed'.
			-- Not a creation feature.
			-- Called by `default_crate', `from_seed', `from_array',
			-- and `set_seed'.
		local
			i: INTEGER
		do
			seed := a_seed
			mt[0] := seed
			from i := 1
			until i >= nn
			loop
				mt[i] := 6364136223846793005 * (mt[i - 1] ⊕ (mt[i - 1] |>> 62)) + i.as_natural_64
				i := i + 1
			end
			lung := (6364136223846793005 * (mt[nn - 1] ⊕ (mt[nn - 1] |>> 62)) + nn.as_natural_64)
		end

feature -- Access

	item: NATURAL_64
			-- The number generated at the Current state
		local
			i: INTEGER_32
		do
			check
				index_big_enough: index >= 0
				index_small_enough: index < mt.count
					-- because Current keeps its state in order		
			end
			if index < Lag_1_over then
				i := index + Lag_1
			else
				i := index - Lag_1_over
			end
			Result := mt[index] ⊕ (mt[index] |<< Shift_1)
			Result := Result ⊕ (mt[i] & Mask_1)
				-- Constrain the Result if required
			if is_constrained then
				Result := Result \\ (upper - lower + One) + lower
			end
		end

	item_32: NATURAL_32
			-- A random number converted to an {NATURAL_32}
		require
			upper_small_enough: upper <= {NATURAL_32}.max_value.to_natural_32
		do
			Result := item.to_natural_32
		ensure
			result_big_enough: Result >= 0 and Result >= lower.to_natural_32
			result_small_enough: Result <= upper.to_natural_32
		end

	item_16: NATURAL_16
			-- A random number converted to an {NATURAL_16}
		require
			upper_small_enough: upper <= {NATURAL_16}.max_value.to_natural_64
		do
			Result := item.to_natural_16
		ensure
			result_big_enough: Result >= 0 and Result >= lower.to_natural_16
			result_small_enough: Result <= upper.to_natural_16
		end

	item_8: NATURAL_8
			-- A random number converted to an {NATURAL_32}
		require
			upper_small_enough: upper <= {NATURAL_8}.max_value.to_natural_64
		do
			Result := item.to_natural_8
		ensure
			result_big_enough: Result >= 0 and Result >= lower.to_natural_8
			result_small_enough: Result <= upper.to_natural_8
		end

	item_63: NATURAL_64
			-- A random number in the closed interval [0, Max_value - 1]
		do
			Result := item |>> 1
		end

	integer_item: INTEGER_32
			-- A random number converted to an {INTEGER_32}
			-- The result should always be positive.
		require
			upper_small_enough: upper <= {INTEGER_32}.max_value.to_natural_64
		do
			Result := item.to_integer_32
		ensure
			result_big_enough: Result >= 0 and Result >= lower.to_integer_32
			result_small_enough: Result <= upper.to_integer_32
			result_not_negative: Result >= 0
		end

	real_item: REAL_64
			-- A random number in the closed interval [0, 1]
		require
			not_constrained: not is_constrained
		do
			Result := (item |>> 11) * (1.0 / 9007199254740991.0)
		ensure
			result_big_enough: Result >= 0.0
			Result_small_enought: Result <= 1.0
		end

	real_item_semi_open: REAL_64
			-- A random number in the semi-open interval [0, 1)
		require
			not_constrained: not is_constrained
		do
			Result := (item |>> 11) * (1.0 / 9007199254740992.0)
		ensure
			result_big_enough: Result >= 0.0
			Result_small_enought: Result < 1.0
		end

	real_item_open: REAL_64
			-- A random number in the open interval (0, 1)
		require
			not_constrained: not is_constrained
		do
			Result := ((item |>> 12) + 0.5) * (1.0 / 4503599627370496.0)
		ensure
			result_big_enough: Result > 0.0
			Result_small_enought: Result < 1.0
		end

	lower: NATURAL_64
			-- The smallest value returned by `item'.
			-- See `set_range'.

	upper: NATURAL_64
			-- The upper constraint for the possible values of `item'.
			-- See `set_range'.

	seed: NATURAL_64
			-- Value with which to initialize the generator

	Default_seed: NATURAL_64 = 5489
			-- The default value used for the `seed'.

	Array_seed: NATURAL_64 = 19650218
			-- The seed used when initializing from an array

	Min_value: NATURAL_64 = 0
			-- The minimum value allowed for `item'

	Max_value: NATURAL_64 = 18446744073709551615
			-- The maximum value allowed for `item

feature -- Element change

	set_range (a_lower, a_upper: NATURAL_64)
			-- Set `lower' and `upper' such that a call to `item' returns
			-- a number in the closed interval [`lower', `upper'].
		require
			lower_smaller_than_upper: a_lower <= a_upper
		do
			lower := a_lower
			upper := a_upper
			if lower > Min_value or upper < Max_value then
				is_constrained := true
			else
				is_constrained := false
			end
		ensure
			lower_set: lower = a_lower
			upper_set: upper = a_upper
			implication: (a_lower /= 0 or a_upper /= Max_value) implies is_constrained
		end

	set_seed (a_seed: NATURAL_64)
			-- Set the `seed' and reinitialize the generator.
		require
			non_zero: a_seed /= Min_value
		do
			seed := a_seed
			initialize (a_seed)
			twist
		ensure
			seed_assigned: seed = a_seed
		end

feature -- Basic operations

	forth
			-- Advance the state, so next call to `item' returns
			-- a new number.
		do
			index := index + 1
			if index >= mt.count then
				index := 0
			end
			twist
		ensure
			index_advanced: old index < mt.count - 1 implies index = old index + 1
			index_wrapped: old index = nn - 1 implies index = 0
		end

	jump
			-- Advance Current's state equivalent to 2^256 calls to `forth'.
			-- Harase & Kimoto's GitHub page says, "The jump-ahead algorithm
			-- is used [SIC] to obtain disjoint streams in parallel computing."
			-- See https://github.com/sharase/melg-64.
		local
			melg_loc: like Current
			i, j: INTEGER_32
			bits, mask: INTEGER_32
		do
				-- Initialize the local generator, basicly to zero
			melg_loc := Current.deep_twin
			melg_loc.lung := 0
			from i := 0
			until i >= melg_loc.mt.count
			loop
				melg_loc.mt[i] := 0
				i := i + 1
			end
			melg_loc.index := index
				-- Initialation of local complete
			from i := 0
			until i >= jump_chars.count
			loop
				bits := jump_chars[i]
				bits := bits & 0x0f
				mask := 0x08
				from j := 0
				until j >= 4
				loop
					if (bits & mask) /= 0 then
						add (melg_loc)
					end
					forth
					mask := mask |>> 1
					j := j + 1
				end
				i := i + 1
			end
			deep_copy (melg_loc)
		end

feature -- Status report

	is_constrained: BOOLEAN
			-- Should the numbers returned by `item' be restricted to a
			-- reduced range (i.e. other than [0, max_value]?

feature {NONE} -- Implementation

	twist
			-- Advances the state
			-- Takes the place of the four "case_x" methods in the
			-- original C code
			-- Call ONLY ONCE after `index' changes in `forth'
		require
			index_big_enough: index >= 0
			index_small_enough: index < mt.count
		local
			k: INTEGER_32	-- added to index in `lung' equation
			i: INTEGER_32	-- index of "next" state value
			x: NATURAL_64
		do
				-- `k' and `i' distinguish the cases based on `index'
			k := index + 1
			if index < nn - mm then
					-- case_1
				i := index + mm
			elseif index = nn - 1 then
					-- case_4
				i := mm - 1
				k := 0
			else
					-- case_2 and case_3
				i := index + mm - nn
			end
				-- Equations same for all cases given `k' and `i' above
			x := (mt[index] & Upper_mask) | (mt[k] & Lower_mask)
			lung := (x |>> 1) ⊕ Mag_1 [(x & One).to_integer_32] ⊕ mt[i] ⊕ Mat_3_neg (neg_shift, lung)
			mt [index] := x ⊕ Mat_3_pos (pos_shift, lung)
		ensure then
			index_set: index = old index
		end

feature {NONE} -- Implementation

	Zero: NATURAL_64 = 0
			-- Then number zero in the Correct type

	One: NATURAL_64 = 1
			-- The number one in the Correct type

	w: INTEGER_32 = 64
			-- Number of bits in the implementation

	nn: INTEGER_32
			-- Number of elements in the state array
			-- Degreed of recurrence (wiki)
		deferred
		end

	mm: INTEGER_32
			-- Offset bit for middle word, an offset used in the recurrence
			-- relation defining the series, 1 <= mm < nn
		deferred
		end

	p: INTEGER_32
			-- W - R, where R is the seperation point of a word
		deferred
		end

	Upper_mask: NATURAL_64
			-- Mask to get the w - p, high-order bits
		once ("OBJECT")
			Result := 0xffffffffffffffff |<< (w - p)
		end

	Lower_mask: NATURAL_64
			-- Mask to get the low-order bits
		once ("OBJECT")
			Result := Upper_mask.bit_not
		end

	Lag_1: INTEGER_32
			-- Tempering bit-shift value ("elle" on wiki)
		deferred
		end

	Lag_1_over: INTEGER_32
			-- Tempering bit-shift value
		once ("OBJECT")
			Result := nn - Lag_1
		end

	Shift_1: INTEGER_32
			-- Tempering bit-shift value used in `item'
		deferred
		end

	neg_shift: INTEGER_32
			-- Bit-shift value anded with `lung' in `twist'
			-- when calling `mat_3_neg'.
		deferred
		end

	pos_shift: INTEGER_32
			-- Bit-shift value anded with `lung' in `twist'
			-- when calling `mat_3_pos'.
		deferred
		end

	Mask_1: NATURAL_64
			-- Tempering bit-mask ("b" on wiki)
		deferred
		end

	mat_3_neg (a_shift: INTEGER_32; v: NATURAL_64): NATURAL_64
			-- Defined as macro in original C-code
		do
			Result := v ⊕ (v |<< a_shift)
		end

	mat_3_pos (a_shift: INTEGER_32; v: NATURAL_64): NATURAL_64
			-- Defined as macro in original C-code
		do
			Result := v ⊕ (v |>> a_shift)
		end

	matrix_a: NATURAL_64
			-- 2nd value in the twist transformation matrix (see `Mag_1')
		deferred
		end

	Mag_1: SPECIAL [NATURAL_64]
			-- Bit-shift values used in tempering
		once ("OBJECT")
			create Result.make_filled (Min_value, 2)
			Result.put (Matrix_a, 1)
		ensure
			item_one_is_zero: Result.at (0) = 0
			item_two_is_correct: Result.at (1) = Matrix_a
		end

	jump_strings: ARRAY [STRING_8]
			-- Helper feature to ease the creation of `jump_chars'
			-- (See https://github.com/sharase/melg-64)
			-- This should be effected by inheriting from the
			-- appropriate constants class
		deferred
		end

	jump_chars: SPECIAL [NATURAL_8]
			-- Used in the `jump' feature.  Called "jump_strings"
			-- by Harase and Kimoto.
			-- (See https://github.com/sharase/melg-64)
			-- The Result is built from feature `jump_strings' in
			-- the corresponding constants class.
		local
			i, j, k: INTEGER
			r: REAL_64
			c: INTEGER
			s: STRING_8
			js: like jump_strings
		once ("OBJECT")
			r := ((nn * w + p) / 4.0).ceiling_real_64
			check
				c_small_enough: r <= {INTEGER_32}.max_value
				c_big_enough: r >= 0
					-- because of known values of `nn', `w', and `p'
			end
			c := r.truncated_to_integer
			create Result.make_filled (0, c)
				-- Build Result from `jump_string' one char at a time
			js := jump_strings
			from
				i := 1
				k := 0
			until i > js.count
			loop
				s := js[i]
				from j := 1
				until j > s.count
				loop
					Result[k] := char_to_hex (s[j])
					j := j + 1
					k := k + 1
				end
				i := i + 1
			end
		end

	char_to_hex (a_char: CHARACTER_8): NATURAL_8
			-- Convert `a_char' to a hexadecimal value
		require
			valid_character: a_char.is_hexa_digit
		do
			inspect a_char
			when '0' then
				Result := 0
			when '1' then
				Result := 1
			when '2' then
				Result := 2
			when '3' then
				Result := 3
			when '4' then
				Result := 4
			when '5' then
				Result := 5
			when '6' then
				Result := 6
			when '7' then
				Result := 7
			when '8' then
				Result := 8
			when '9' then
				Result := 9
			when 'a', 'A' then
				Result := 10
			when 'b', 'B' then
				Result := 11
			when 'c', 'C' then
				Result := 12
			when 'd', 'D' then
				Result := 13
			when 'e', 'E' then
				Result := 14
			when 'f', 'F' then
				Result := 15
			else
				check
					should_not_happen: False
						-- because of precondition
					end
			end
		ensure
			result_in_range: Result >= 0 and Result <= 15
		end

	add (a_other: like Current)
			-- Updates the state of `a_melg' melding with Current
			-- without changing Current.
			-- Feature `jump' passes a copy of Current to this feature.
			-- (See https://github.com/sharase/melg-64)
		require
			not_current: not (a_other = Current)
		local
			i: INTEGER_32
			n1, n2: INTEGER_32
			diff_1, diff_2: INTEGER_32
		do
			a_other.lung := a_other.lung ⊕ lung
			n1 := a_other.index + 1
			n2 := index + 1
				-- Add the states
			if n1 <= n2 then
				diff_1 := nn - n2 + n1
				diff_2 := n2 - n1
					-- Sub-loop 1
				from i := n1
				until i >= diff_1
				loop
					a_other.mt[i] := a_other.mt[i] ⊕ mt[i + diff_2]
					i := i + 1
				end
					-- Sub-loop 2
				from
				until i >= nn
				loop
					a_other.mt[i] := a_other.mt[i] ⊕ mt[i - diff_1]
					i := i + 1
				end
					-- Sub-loop 3
				from i := 0
				until i >= n1
				loop
					a_other.mt[i] := a_other.mt[i] ⊕ mt[i + diff_2]
					i := i + 1
				end
			else
				diff_1 := nn - n1 + n2
				diff_2 := n1 - n2
					-- Sub-loop 1
				from i := n1
				until i >= nn
				loop
					a_other.mt[i] := a_other.mt[i] ⊕ mt[i - diff_2]
					i := i + 1
				end
					-- Sub-loop 2
				from i := 0
				until i >= diff_2
				loop
					a_other.mt[i] := a_other.mt[i] ⊕ mt[i + diff_1]
					i := i + 1
				end
					-- Sub-loop 3
				from
				until i >= n1
				loop
					a_other.mt[i] := a_other.mt[i] ⊕ mt[i - diff_2]
					i := i + 1
				end
			end
		end

feature {MELG} -- Implementation (state selectively exported for `jump' and `add')

	mt: SPECIAL [NATURAL_64]
			-- The state array

	index: INTEGER_32 assign set_index
			-- Index into the state array, `mt'

	set_index (a_index: INTEGER_32)
			-- Change `index'
		do
			index := a_index
		ensure
			index_assigned: index = a_index
		end

	lung: NATURAL_64 assign set_lung
			-- Extra state variable

	set_lung (a_lung: NATURAL_64)
			-- Change `lung'
			-- Setter feature used by `add' to change the state
		do
			lung := a_lung
		ensure
			lung_assigned: lung = a_lung
		end

	set_mt_item (a_value: NATURAL_64; a_index: INTEGER_32)
			-- Change the value of `a_index'th item of `mt'
			-- Setter feature used by `add' to change the state
		require
			index_big_enough: a_index >= 0
			index_small_enough: a_index < mt.count
		do
			mt[a_index] := a_value
		ensure
			item_assigned: mt[a_index] = a_value
		end

feature {NONE} -- Implementation

	c_initialize (a_special: POINTER; a_count: INTEGER_32; a_seed: NATURAL_64)
			-- Use C to perform the math, because C handles the overflow
			-- in the multiplication of unsigned-long using promotions which
			-- Eiffel does not do.  (Eiffel wraps natural numbers.)
			-- Here is the main equation translated to Eiffel:
			--   mt[i] := f * (mt[i - 1] ⊕ (mt[i - 1] |>> (w - 2))) + i.as_natural_32
			-- The multiplier `f' and the bit-shift amount is hard-coded here.
		external
			"C inline"
		alias
			"{
				EIF_INTEGER_32 N;
				EIF_NATURAL_64 s;
				EIF_NATURAL_64 *mt;

				N = (EIF_INTEGER_32) $a_count;
				s = (EIF_NATURAL_64) $a_seed;
				mt = (EIF_NATURAL_64 *) $a_special;

				mt[0] = s;
				for (int i = 1; i < N; i++) {
					mt[i] = 6364136223846793005ULL * (mt[i-1] ^ (mt[i-1] >> 62)) + i;
				}
			}"
		end

	c_from_array (a_special: POINTER; a_count: INTEGER_32;
					a_init_special: POINTER; a_key_count: INTEGER_32)
			-- Use C to perform the math, because C handles the overflow
			-- in the multiplication of unsigned-long using promotions which
			-- Eiffel does not do.  (Eiffel wraps natural numbers.)
			-- Here are the two main equations translated to Eiffel:
			--   mt[i] := (mt[i] ⊕ ((mt[i - 1] ⊕ (mt[i - 1] |>> (w - 2))) *
			--	           Mult_1)) + a_array [j] + (j).as_natural_32
			--   mt[i] := (mt[i] ⊕ ((mt[i - 1] ⊕ (mt[i - 1] |>> (w - 2))) *
			--             Mult_2)) - i.as_natural_32
			-- The multipliers, `Mult_1' and `Mult_2', and the bit-shift
			-- amount are hard coded here.
		external
			"C inline"
		alias
			"{
				EIF_INTEGER_32 N;
				int i, j, k;
				EIF_INTEGER_32 key_length;
				EIF_NATURAL_64 *mt;
				EIF_NATURAL_64 *init_key;
			
				mt = (EIF_NATURAL_64 *) $a_special;
				init_key = (EIF_NATURAL_64 *) $a_init_special;
				N = (EIF_INTEGER_32) $a_count;
				key_length = (EIF_INTEGER_32) $a_key_count;
				
				i = 1;
				j = 0;
				k = (N > key_length ? N : key_length);
				for (; k; k--) {
					mt[i] = (mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 62)) * 3935559000370003845ULL))
							+ init_key[j] + j;
					i++; j++;
					if (i>=N) { 
						mt[0] = mt[N-1];
						i=1;
					}
					if (j>=key_length) {
						j=0;
					}
				}
				for (k=N-1; k; k--) {
					mt[i] = (mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 62)) * 2862933555777941757ULL)) - i;
					i++;
					if (i>=N) {
						mt[0] = mt[N-1];
						i=1;
					}
			    }
			    	// Assure item 1 is non-zero, preventing non-zero initial array
				mt[0] = (mt[0] | (1ULL << 63));
			}"
		end

invariant

	valid_item: item >= lower and item <= upper

	index_big_enough: index >= 0
	index_small_enough: index < nn

	lower_big_enough: lower >= Min_value
	lower_small_enough: lower <= Max_value

	upper_big_enough: upper >= Min_value
	upper_small_enough: upper <= Max_value

	lower_smaller_than_upper: lower <= upper

	is_constrained_implication: is_constrained implies (lower > Min_value or upper < Max_value)
	reduced_range_implication: (lower > Min_value or upper < Max_value) implies is_constrained

end
