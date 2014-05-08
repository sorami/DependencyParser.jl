# Included in Common.jl


# for parsing
function createfeatures(sentences, featdict)

	function createedgefeat(head::Word, mod::Word)
		# Feature Template
		p_word = 	"p-word=$(head.form)"
		p_pos = 	"p-pos=$(head.postag)"
		c_word = 	"c-word=$(mod.form)"
		c_pos = 	"c-pos=$(mod.postag)"

		feature_template = [
			# Basic Features
			join([p_word, p_pos, c_word, c_pos], " "), 
			join([p_pos, c_word, c_pos], " "), 
			join([p_word, c_word, c_pos], " "), 
			join([p_word, p_pos, c_pos], " "), 
			join([p_word, p_pos, c_word], " "), 
			join([p_word, c_word], " "), 
			join([p_pos, c_pos], " "),
			join([p_word, p_pos], " "),
			join([c_word, p_pos], " "),
			p_word, 
			p_pos,
			c_word, 
			c_pos
		]

		# one-hot features
		# simply keep a list of feat indices, instead of k/v pairs
		fv = Int[]
		for feat in feature_template
			if haskey(featdict, feat)
				push!(fv, featdict[feat])
			end
		end

		return fv
	end

	root = Word(
			0, 			# id
			"<ROOT>", 	# form
			"<ROOT>", 	# lemma
			"ROOT", 	# cpostag
			"ROOT", 	# postag
			[], 		# feats
			-1, 		# head
			"ROOT" 		# deprel
		)

	edge_feats_list = Dict{(Int,Int), Vector{Int}}[] # a list of `edge_feats` (set of feature vectors per sentence)

	info("Create features and vectorize sentences ...")
	for sent in sentences
		n = length(sent)
		# edge_feats[(index_head, index_mod)] = "a list of feat indices"
		edge_feats = Dict{(Int,Int), Vector{Int}}() 
		sizehint(edge_feats, n*n)

		# edges from ROOT
		for index_mod = 1:n
			edge_feats[(0, index_mod)] = createedgefeat(root, sent[index_mod])
		end

		# all other edges
		for index_head = 1:n
			for index_mod = 1:n
				if index_head != index_mod # no self-loop edge
					edge_feats[(index_head, index_mod)] = createedgefeat(sent[index_head], sent[index_mod])
				end
			end
		end

		push!(edge_feats_list, edge_feats)
	end

	return edge_feats_list
end



# for training
function createfeatures(sentences)
	
	function getfeatindex!(feat::String)
		if haskey(featdict, feat)
			return featdict[feat]
		else
			n_feats += 1
			featdict[feat] = n_feats
			return n_feats
		end
	end

	function createedgefeat!(head::Word, mod::Word)
		# Feature Template
		p_word = 	"p-word=$(head.form)"
		p_pos = 	"p-pos=$(head.postag)"
		c_word = 	"c-word=$(mod.form)"
		c_pos = 	"c-pos=$(mod.postag)"

		feature_template = [
			# Basic Features
			join([p_word, p_pos, c_word, c_pos], " "), 
			join([p_pos, c_word, c_pos], " "), 
			join([p_word, c_word, c_pos], " "), 
			join([p_word, p_pos, c_pos], " "), 
			join([p_word, p_pos, c_word], " "), 
			join([p_word, c_word], " "), 
			join([p_pos, c_pos], " "),
			join([p_word, p_pos], " "),
			join([c_word, p_pos], " "),
			p_word, 
			p_pos,
			c_word, 
			c_pos
		]

		# one-hot features
		# simply keep a list of feat indices, instead of k/v pairs
		fv = Int[]
		for feat in feature_template
			index = getfeatindex!(feat)
			push!(fv, index)
		end

		return fv
	end

	root = Word(
			0, 			# id
			"<ROOT>", 	# form
			"<ROOT>", 	# lemma
			"ROOT", 	# cpostag
			"ROOT", 	# postag
			[], 		# feats
			-1, 		# head
			"ROOT" 		# deprel
		)

	featdict = Dict{String, Int}() # feature index dictionary
	n_feats = 0 # number of features
	edge_feats_list = Dict{(Int,Int), Vector{Int}}[] # a list of `edge_feats` (set of feature vectors per sentence)

	info("Create features and vectorize sentences ...")
	for sent in sentences
		n = length(sent)
		# edge_feats[(index_head, index_mod)] = "a list of feat indices"
		edge_feats = Dict{(Int,Int), Vector{Int}}() 
		sizehint(edge_feats, n*n)

		# edges from ROOT
		for index_mod = 1:n
			edge_feats[(0, index_mod)] = createedgefeat!(root, sent[index_mod])
		end

		# all other edges
		for index_head = 1:n
			for index_mod = 1:n
				if index_head != index_mod # no self-loop edge
					edge_feats[(index_head, index_mod)] = createedgefeat!(sent[index_head], sent[index_mod])
				end
			end
		end

		push!(edge_feats_list, edge_feats)
	end
	info("Total number of features: $n_feats")

	return edge_feats_list, featdict, n_feats
end
