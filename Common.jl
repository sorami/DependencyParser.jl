require("Feature.jl")
require("Eisner.jl")


immutable Model
	weights::Vector{Real}
	featdict::Dict{String, Int}
end

immutable Word
	id::Int
	form::String
	lemma::String
	cpostag::String
	postag::String
	feats::Array
	head::Int
	deprel::String
end


function readconlldata(fpath)
	info("Reading $fpath ...")
	const file = open(fpath, "r")

	sentences = Array{Word,1}[] # a list of sent
	sent = Word[] # a list of Word
	for line in eachline(file)
		if line != "\n"
			cols = split(line, "\t")
			token = Word(
				int(cols[1]), 			# id
				cols[2], 				# form
				cols[3], 				# lemma
				cols[4], 				# cpostag
				cols[5], 				# postag
				split(cols[6],"|"), 	# feats
				int(cols[7]), 			# head
				cols[8] 				# deprel
			)
			push!(sent, token)
		else
			push!(sentences, sent)
			sent = Word[]
		end
	end
	close(file)

	info("Total number of sentences: $(length(sentences))")
	sentences
end


function getedgescores(edge_feats, weights::Vector{Real}, n::Int)
	# n: number of words in sentence
	# n = sqrt(length(edge_feats)) # total number of edges = n*n
	edge_scores = Dict{(Int, Int), Real}()
	sizehint(edge_scores, n*n) # n*n: number of edges to consider

	for index_head = 0:n
		for index_mod = 1:n
			if index_head != index_mod
				score = 0
				for findex in edge_feats[(index_head, index_mod)]
					score += weights[findex]
				end
			end
			edge_scores[(index_head, index_mod)] = score
		end
	end

	edge_scores
end

