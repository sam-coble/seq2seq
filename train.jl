using Printf
const TYPE::DataType = Float32

include("rnn.jl")
# TODO: Batches, L2-reg,

const X_train::Vector{Matrix{TYPE}} = loadX(TYPE, "data/mixed/lang/examples_train_1.txt")
const X_test::Vector{Matrix{TYPE}} = loadX(TYPE, "data/mixed/lang/examples_test_1.txt")

const n::Int16 = size(X_train, 1)
const t::Int16 = size(X_test, 1)

include("rnn.jl")

## start with prev weights
# include("weights.jl")


## or init randomly
model::seq2seq{TYPE} = init_seq2seq(TYPE, 100, 28)

### sgd


const BATCH_SIZE::Int32 = 50
const MAX_ITERATIONS::Int32 = Int32(round(100000/BATCH_SIZE))
const STEP_SIZE::TYPE = 7e-2

@printf "RUNNING WITH STEP_SIZE=%f, BATCH_SIZE=%d, ITERATIONS=%d" STEP_SIZE BATCH_SIZE MAX_ITERATIONS
for i::Int32 in 1:MAX_ITERATIONS
	f_sum = 0
	gWaa_sum = zeros(TYPE, size(Waa))
	gWax_sum = zeros(TYPE, size(Wax))
	gWya_sum = zeros(TYPE, size(Wya))
	ga0_sum = zeros(TYPE, size(a0))

	for batch in 1:BATCH_SIZE
		r = rand(1:n)
		(f, gWaa, gWax, gWya, ga0) = bptt(Waa, Wax, Wya, a0, X_train[r], y_train[r,:])
		f_sum += f
		gWaa_sum += gWaa
		gWax_sum += gWax
		gWya_sum += gWya
		ga0_sum += ga0
	end
	# r = rand(1:n)
	# (f, gWaa, gWax, gWya, ga0) = bptt(Waa, Wax, Wya, a0, X_train[r], y_train[r,:])
	global Waa = Waa - STEP_SIZE * gWaa_sum / BATCH_SIZE
	global Wax = Wax - STEP_SIZE * gWax_sum / BATCH_SIZE
	global Wya = Wya - STEP_SIZE * gWya_sum / BATCH_SIZE
	global a0 = a0 - STEP_SIZE * ga0_sum / BATCH_SIZE
	if i % Int32(round(MAX_ITERATIONS/30)) == 0
		correct = 0
		test_err = 0
		yhat = predict(X_test, Waa, Wax, Wya, a0)
		for j in 1:t
			test_err += sum((yhat[j] - y_test[j,:]).^2)
			if findmax(yhat[j])[2] - 1 == y_test_[j]
				correct += 1
			end
		end
		test_err /= t
		test_acc = correct/t
		yhat = predict(X_train, Waa, Wax, Wya, a0)
		correct = 0
		train_err = 0
		for j in 1:n
			train_err += sum((yhat[j] - y_train[j,:]).^2)
			if findmax(yhat[j])[2] - 1 == y_train_[j]
				correct += 1
			end
		end
		train_err /= n
		train_acc = correct / n
		@printf "ITERATION: %d\tTRAIN ACC: %f\tTEST ACC: %f\tTRAIN ERR: %f\tTEST ERR: %f\n" i train_acc test_acc train_err test_err
	end
end

@show model
