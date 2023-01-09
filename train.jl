using Printf


include("rnn.jl")
# TODO: Batches, L2-reg,

X_train = loadX("data/examples_train_1.txt")
y_train_ = loady("data/labels_train_1.txt")
y_train = unrolly(y_train_)
X_test = loadX("data/examples_test_1.txt")
k_test = size.(X_test,1)
X_test .= hcat.(X_test, ones.(TYPE, k_test))
k_train = size.(X_train, 1)
X_train .= hcat.(X_train, ones.(TYPE, k_train))
# @show size(X_test[1])
y_test_ = loady("data/labels_test_1.txt")
y_test = unrolly(y_test_)
(n,c) = size(y_train)
t = size(y_test_, 1)

include("rnn.jl")

# sgd
nstate = 5
Waa = randn(nstate, nstate)
Wax = randn(nstate, (96 + 1))
Wya = randn(c, nstate + 1)
a0 = randn(nstate)

BATCH_SIZE = 10
MAX_ITERATIONS = Int(10000/BATCH_SIZE)
STEP_SIZE = 1e-4

for i in 1:MAX_ITERATIONS
	f_mean = 0
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
	global a0 = ga0 - STEP_SIZE * ga0_sum / BATCH_SIZE
	if i % (MAX_ITERATIONS/30) == 0
		correct = 0
		test_err = 0
		yhat = predict(X_test, Waa, Wax, Wya, a0)
		for j in 1:t
			test_err += sum((yhat - y_test).^2)
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
			train_err += sum((yhat - y_train).^2)
			if findmax(yhat[j])[2] - 1 == y_train_[j]
				correct += 1
			end
		end
		train_err /= n
		train_acc = correct / n
		@printf "ITERATION: %d\tTRAIN ACC: %f\tTEST ACC: %f\tTRAIN ERR: %f\tTEST ERR: %f\n" i train_acc test_acc train_err test_err
	end
end

@show Waa
@show Wax
@show Wya
@show a0

