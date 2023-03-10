using Printf
using JLD2

include("rnn.jl")

function train(::Type{T}, MAX_ITERATIONS::Int64, BATCH_SIZE::Int64, STEP_SIZE::T, MAX_OUTPUTS::Int64, m::Int64, infile::String, outfile::String) where T <: AbstractFloat
	# local X_train::Vector{Matrix{T}} = loadX(T, "data/mixed/words_train_1.txt")
	# local X_test::Vector{Matrix{T}} = loadX(T, "data/mixed/words_test_1.txt")
	local X_train::Vector{Matrix{T}} = loadX(T, "data/letters.txt")
	local X_test::Vector{Matrix{T}} = X_train

	local n::Int64 = size(X_train, 1)
	local t::Int64 = size(X_test, 1)

	
	local d::Int64 = size(X_train[1], 2)
	local model::seq2seq{T}
	if (infile == "") ## start with prev weights
		model = init_seq2seq(T, m, d, MAX_OUTPUTS)
	else ## or init randomly
		model = load_object(infile)
	end
	

	### sgd

	# const MAX_OUTPUTS::Int64 = 12
	# const BATCH_SIZE::Int64 = 50
	# const MAX_ITERATIONS::Int64 = Int64(round(100000/BATCH_SIZE))
	# const STEP_SIZE::T = 7e-2

	@printf "RUNNING WITH STEP_SIZE=%f, BATCH_SIZE=%d, ITERATIONS=%d, m=%d, d=%d\n" STEP_SIZE BATCH_SIZE MAX_ITERATIONS m d
	for i::Int64 in 1:MAX_ITERATIONS
		if i % Int64(round(MAX_ITERATIONS/2)) == 1
			# @printf "CALCULATING ERROR:\n"
			local test_err::T = 0
			local yhat::Vector{Vector{Vector{T}}} = predict(X_test, model)
			for j in 1:t
				test_err += calculateResidualError(yhat[j], X_test[j])[1]
			end
			test_err /= t
			yhat = predict(X_train, model)
			local train_err::T = 0
			for j in 1:n
				train_err += calculateResidualError(yhat[j], X_train[j])[1]
			end
			train_err /= n
			@printf "ITERATION: %d\tTRAIN ERR: %f\tTEST ERR: %f\n" (i-1)  train_err test_err
		end
		local f_sum::T = 0
		local grad_sum::seq2seq_grad{T} = emptyGrad(T, m, d)

		Threads.@threads for r in 1:n
		# Threads.@threads for batch in 1:BATCH_SIZE
			# local r::Int64 = rand(1:n)
			(f::T, grad::seq2seq_grad{T}) = bptt(X_train[r], X_train[r], model)
			f_sum += f
			grad_sum = sumGrads(grad_sum, grad)
		end
		model = subGradient(model, grad_sum, STEP_SIZE / n)
		# model = subGradient(model, grad_sum, STEP_SIZE / BATCH_SIZE)
	end
	# @show model
	if outfile != ""
		save_object(outfile, model)
	end
	# return model
end
function predictStr(str, model)
	return vec2str(predict([str2vec(Float64, str)], model)[1])
end

# train(Float64, 120000, 8, 7e-2, 6, 5, "", "letter_model.jld2")