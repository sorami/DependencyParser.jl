using ArgParse
include("Common.jl")


function training(edge_feats_list, sentences, weights, n_feats)

	function updateweights!(fv_gold, fv_predict)
		for findex in fv_gold
			weights[findex] += 1
		end
		for findex in fv_predict
			weights[findex] -= 1
		end
	end

	n_correct = 0
	n_total = 0
	for (i, sent) in enumerate(sentences)
		n = length(sent)
		edge_feats = edge_feats_list[i]
		edge_scores = getedgescores(edge_feats, weights, n)
		heads = eisner(edge_scores, n)

		for index = 1:n
			h_gold = sent[index].head
			h_predict = heads[index]
			if h_predict != h_gold
				updateweights!(edge_feats[(h_gold, index)], edge_feats[(h_predict, index)])
			else
				n_correct += 1
			end
			n_total += 1
		end
	end

	info("$(n_correct/n_total)")

	weights
end


function serializemodel(fpath, model::Model)
	info("Serialize model to $fpath ...")
	const fout = open(fpath, "w")
	serialize(fout, model)
	close(fout)
end


function getoptions(args)
	s = ArgParseSettings("Dependency parser in Julia.")
	@add_arg_table s begin
		"train"
			help = "training file"
			arg_type = String
			required = true
		"model"
			help = "model file"
			arg_type = String
			required = true
		"--iter"
			help = "number of training iteration"
			arg_type = Int
			default = 2
	end
	parsed_args = parse_args(args, s)

	@assert isreadable(parsed_args["train"]) # check if training file readable
	@assert parsed_args["iter"] > 0 # number of iteration need to be greater than zero

	return parsed_args["train"], parsed_args["model"], parsed_args["iter"]
end


function main(args)
	info("PARSER TRAINING")
	const (fpath_train, fpath_model, n_iteration) = getoptions(args)
	info("Training file:\t$fpath_train")
	info("Model file:\t$fpath_model")
	info("Number of iteration: $n_iteration")
	info("-------------------")

	const sentences = readconlldata(fpath_train)
	info("-------------------")

	const (edge_feats_list, featdict, n_feats) = createfeatures(sentences)
	info("-------------------")

	info("Start training ...")
	weights = zeros(Real, n_feats) # initialize weights
	for n_iter=1:n_iteration
		info("Iteration: $n_iter/$n_iteration")
		weights = training(edge_feats_list, sentences, weights, n_feats)
	end
	info("-------------------")

	serializemodel(fpath_model, Model(weights, featdict))
	info("... All DONE!")
end

main(ARGS)
