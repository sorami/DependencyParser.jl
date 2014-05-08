using ArgParse
include("Common.jl")


function parse(edge_feats_list, sentences, weights, fpath_out)
	info("Start parsing ...")
	f_out = open(fpath_out, "w")

	for (i, sent) in enumerate(sentences)
		n = length(sent)
		edge_feats = edge_feats_list[i]
		edge_scores = getedgescores(edge_feats, weights, n)
		heads = eisner(edge_scores, n)

		for (j, token) in enumerate(sent)
			token_array = [token.id, 
							token.form, 
							token.lemma, 
							token.cpostag, 
							token.postag, 
							token.feats, 
							heads[j], # predicted head
							token.deprel, 
							"\n"]
			write(f_out, join(token_array, "\t") )
		end
		write(f_out, "\n")
	end
end


function getoptions(args)
	s = ArgParseSettings("Dependency parser in Julia.")
	@add_arg_table s begin
		"input"
			help = "input file"
			arg_type = String
			required = true
		"model"
			help = "model file"
			arg_type = String
			required = true
		"output"
			help = "parsed output file"
			arg_type = String
			required = true
	end
	parsed_args = parse_args(args, s)

	@assert isreadable(parsed_args["input"]) # check if training file readable
	@assert isreadable(parsed_args["model"]) # check if model file readable

	return parsed_args["input"], parsed_args["model"], parsed_args["output"]
end


function main(args)
	info("PARSING")
	const (fpath_in, fpath_model, fpath_out) = getoptions(args)
	info("Input file:\t$fpath_in")
	info("Model file:\t$fpath_model")
	info("Output file:\t$fpath_out")
	info("-------------------")

	const sentences = readconlldata(fpath_in)
	info("-------------------")

	info("Loading model ...")
	const model = open(deserialize, fpath_model)
	info("-------------------")

	const edge_feats_list = createfeatures(sentences, model.featdict)
	info("-------------------")

	parse(edge_feats_list, sentences, model.weights, fpath_out)

	info("... All DONE!")
end

main(ARGS)
