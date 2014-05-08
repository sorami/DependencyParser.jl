# Included in Common.jl

function eisner(edge_scores::Dict{(Int, Int), Real}, n::Int)
 	# n: number of words in sentence

	comp_rh = Dict{(Int, Int), Real}() # Complete span, right head. 	E[s][t][0][0]
	comp_lh = Dict{(Int, Int), Real}() # Complete span, left head. 		E[s][t][1][0]
	incomp_rh = Dict{(Int, Int), Real}() # Incomplete span, right head.	E[s][t][0][1]
	incomp_lh = Dict{(Int, Int), Real}() # Incomplete span, left head.	E[s][t][1][1]
	# TODO: sizehint()

	# backpointers
	bp_comp_rh = Dict{(Int, Int), Int}() 
	bp_comp_lh = Dict{(Int, Int), Int}() 
	bp_incomp_rh = Dict{(Int, Int), Int}() 
	bp_incomp_lh = Dict{(Int, Int), Int}() 



	for i = 0:n
		comp_rh[(i, i)] = 0
		comp_lh[(i, i)] = 0
		incomp_rh[(i, i)] = 0
		incomp_lh[(i, i)] = 0
	end

	for m = 1:n
		for s = 0:n
			t = s + m
			if (t > n) break end

			# E[s][t][0][1]
			tmp = -Inf
			bp = -1
			for q = s:t-1
				# get(edge_scores,(t, s), -Inf): IF edge's from a word to ROOT, then score = -Inf
				x = comp_rh[(q+1, t)] + get(edge_scores,(t, s), -Inf)
				if x > tmp
					tmp = x
					bp = q
				end
			end
			incomp_rh[(s, t)] = tmp
			bp_incomp_rh[(s, t)] = bp

			# E[s][t][1][1]
			tmp = -Inf
			bp = -1
			for q = s:t-1
				x = comp_lh[(s, q)] + comp_rh[(q+1, t)] + edge_scores[(s, t)]
				if x > tmp
					tmp = x
					bp = q
				end
			end
			incomp_lh[(s, t)] = tmp
			bp_incomp_lh[(s, t)] = bp

			# E[s][t][0][0]
			tmp = -Inf
			bp = -1
			for q = s:t-1
				x = comp_rh[(s, q)] + incomp_rh[(q, t)]
				if x > tmp
					tmp = x
					bp = q
				end
			end
			comp_rh[(s, t)] = tmp
			bp_comp_rh[(s, t)] = bp

			# E[s][t][1][0]
			tmp = -Inf
			for q = s+1:t
				x = incomp_lh[(s, q)] + comp_lh[(q, t)]
				if x > tmp
					tmp = x
					bp = q
				end
			end
			comp_lh[(s, t)] = tmp
			bp_comp_lh[(s, t)] = bp
		end
	end


	heads = cell(n)
	function backtrack(s, t, lr, ci)
		# lr: right head = 0, left head = 1
		# ci: comp = 0, incomp = 1
		if lr == 1 && ci == 0 # comp_lh
			if s != t
				q = bp_comp_lh[(s, t)]
				heads[q] = s
				heads[t] = q
				backtrack(s, q, 1, 1)
				backtrack(q, t, 1, 0)
			end
		elseif lr == 0 && ci == 0 # comp_rh
			if s != t
				q = bp_comp_rh[(s, t)]
				heads[q] = t
				heads[s] = q
				backtrack(s, q, 0, 0)
				backtrack(q, t, 0, 1)
			end
		elseif lr == 1 && ci == 1
			if s != t
				q = bp_incomp_lh[(s, t)]
				heads[t] = s
				backtrack(s, q, 1, 0)
				backtrack(q+1, t, 0, 0)
			end
		elseif lr == 0 && ci == 1
			if s != t
				q = bp_incomp_rh[(s, t)]
				heads[s] = t
				backtrack(s, q, 1, 0)
				backtrack(q+1, t, 0, 0)
			end
		end
	end
	backtrack(0, n, 1, 0)

	heads

end