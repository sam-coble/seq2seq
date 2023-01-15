using Printf
const TYPE::DataType = Float32

include("rnn.jl")
# TODO: Batches, L2-reg,

const X_train::Vector{Matrix{TYPE}} = loadX(TYPE, "data/mixed/words_train_1.txt")
const X_test::Vector{Matrix{TYPE}} = loadX(TYPE, "data/mixed/words_test_1.txt")

const n::Int16 = size(X_train, 1)
const t::Int16 = size(X_test, 1)

include("rnn.jl")

## start with prev weights
# include("weights.jl")


## or init randomly
const m::Int32 = 100
const d::Int32 = 28
model::seq2seq{TYPE} = init_seq2seq(TYPE, m, d)

### sgd

const MAX_OUTPUTS::Int32 = 12
const BATCH_SIZE::Int32 = 50
const MAX_ITERATIONS::Int32 = Int32(round(100000/BATCH_SIZE))
const STEP_SIZE::TYPE = 7e-2

@printf "RUNNING WITH STEP_SIZE=%f, BATCH_SIZE=%d, ITERATIONS=%d, m=%d, d=%d\n" STEP_SIZE BATCH_SIZE MAX_ITERATIONS m d
for i::Int32 in 1:MAX_ITERATIONS
	f_sum = 0
	grad_sum::seq2seq_grad{TYPE} = emptyGrad(TYPE, m, d)

	for batch in 1:BATCH_SIZE
		r = rand(1:n)
		(f::TYPE, grad::seq2seq_grad{TYPE}) = bptt(X_train[r], X_train[r], model, MAX_OUTPUTS)
		f_sum += f
		grad_sum = sumGrads(TYPE, grad_sum, grad)
	end
	global model = subGradient(TYPE, model, grad_sum, STEP_SIZE / BATCH_SIZE)

	if i % Int32(round(MAX_ITERATIONS/30)) == 0
		test_err = 0
		yhat = predict(X_test, model)
		for j in 1:t
			test_err += sum((yhat[j] - X_test[j,:]).^2)
		end
		test_err /= t
		yhat = predict(X_train, model)
		train_err = 0
		for j in 1:n
			train_err += sum((yhat[j] - y_train[j,:]).^2)
		end
		train_err /= n
		@printf "ITERATION: %d\tTRAIN ERR: %f\tTEST ERR: %f\n" i  train_err test_err
	end
end

@show model
