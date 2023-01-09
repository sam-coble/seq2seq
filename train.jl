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
y_test = loady("data/labels_test_1.txt")
(n,c) = size(y_train)
t = size(y_test, 1)

include("rnn.jl")

# sgd
nstate = 5
Waa = randn(nstate, nstate)
Wax = randn(nstate, (96 + 1))
Wya = randn(c, nstate + 1)
a0 = randn(nstate)

maxIter = 10000
stepSize = 1e-4

for i in 1:maxIter
	r = rand(1:n)
	(f, gWaa, gWax, gWya, ga0) = bptt(Waa, Wax, Wya, a0, X_train[r], y_train[r,:])
	global Waa = Waa - stepSize * gWaa
	global Wax = Wax - stepSize * gWax
	global Wya = Wya - stepSize * gWya
	global a0 = ga0 - stepSize * ga0
	if i % (maxIter/50) == 0
		correct = 0
		yhat = predict(X_test, Waa, Wax, Wya, a0)
		for j in 1:t
			if findmax(yhat[j])[2] - 1 == y_test[j]
				correct += 1
			end
		end
		test_acc = correct/t
		yhat = predict(X_train, Waa, Wax, Wya, a0)
		correct = 0
		for j in 1:n
			if findmax(yhat[j])[2] - 1 == y_train_[j]
				correct += 1
			end
		end
		train_acc = correct / n
		@printf "ITERATION %d TRAIN ACCURACY:\t%f\n" i train_acc
		@printf "ITERATION %d TEST ACCURACY:\t%f\n" i test_acc
		@printf "ITERATION %d TRAINING ERROR:\t%f\n" i f
		@printf "\n"
		@show Waa
		@show Wax
		@show Wya
		@show a0
		@printf "\n\n\n\n"
	end
end

@show Waa
@show Wax
@show Wya
@show a0

