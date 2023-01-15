using Printf

include("rnn.jl")

function train(::Type{T}, MAX_ITERATIONS::Int64, BATCH_SIZE::Int64, STEP_SIZE::T, MAX_OUTPUTS::Int64, m::Int64) where T <: AbstractFloat
	X_train::Vector{Matrix{T}} = loadX(T, "data/mixed/words_train_1.txt")
	X_test::Vector{Matrix{T}} = loadX(T, "data/mixed/words_test_1.txt")

	n::Int64 = size(X_train, 1)
	t::Int64 = size(X_test, 1)

	## start with prev weights
	# include("weights.jl")


	## or init randomly
	# const m::Int64 = 100
	d::Int64 = size(X_train[1], 2)
	model::seq2seq{T} = init_seq2seq(T, m, d, MAX_OUTPUTS)

	### sgd

	# const MAX_OUTPUTS::Int64 = 12
	# const BATCH_SIZE::Int64 = 50
	# const MAX_ITERATIONS::Int64 = Int64(round(100000/BATCH_SIZE))
	# const STEP_SIZE::T = 7e-2

	@printf "RUNNING WITH STEP_SIZE=%f, BATCH_SIZE=%d, ITERATIONS=%d, m=%d, d=%d\n" STEP_SIZE BATCH_SIZE MAX_ITERATIONS m d
	for i::Int64 in 1:MAX_ITERATIONS
		f_sum::T = 0
		grad_sum::seq2seq_grad{T} = emptyGrad(T, m, d)

		for batch in 1:BATCH_SIZE
			r::Int64 = rand(1:n)
			(f::T, grad::seq2seq_grad{T}) = bptt(X_train[r], X_train[r], model)
			f_sum += f
			grad_sum = sumGrads(grad_sum, grad)
		end
		model = subGradient(model, grad_sum, STEP_SIZE / BATCH_SIZE)

		if i % Int64(round(MAX_ITERATIONS/30)) == 0
			test_err::T = 0
			yhat::Vector{Vector{T}} = predict(X_test, model)
			for j in 1:t
				test_err += sum((yhat[j] - X_test[j,:]).^2)
			end
			test_err /= t
			yhat = predict(X_train, model)
			train_err::T = 0
			for j in 1:n
				train_err += sum((yhat[j] - X_train[j,:]).^2)
			end
			train_err /= n
			@printf "ITERATION: %d\tTRAIN ERR: %f\tTEST ERR: %f\n" i  train_err test_err
		end
	end

	@show model
end

train(Float64, 300, 10, 7e-2, 12, 100)