using Printf


include("rnn.jl")


X_train = loadX("data/examples_train_1.txt")
y_train = unrolly(loady("data/labels_train_1.txt"))
X_test = loadX("data/examples_test_1.txt")
y_test = loady("data/labels_test_1.txt")
(n,c) = size(y_train)
t = size(y_test, 1)

include("rnn.jl")

# sgd
nstate = 5
Waa = randn(nstate, nstate)
Wax = randn(nstate, (96 + 1))
Wya = randn(c, nstate + 1)
a0 = zeros(nstate)

maxIter = 10000
stepSize = 1e-4

for i in 1:maxIter
	r = rand(1:n)
	(f, gWaa, gWax, gWya, ga0) = bptt(Waa, Wax, Wya, a0, X_train[r], y_train[r,:])
	global Waa = Waa - stepSize * gWaa
	global Wax = Wax - stepSize * gWax
	global Wya = Wya - stepSize * gWya
	global a0 = ga0 - stepSize * ga0
	if i % (maxIter/20) == 0
		correct = 0
		yhat = predict(X_test, Waa, Wax, Wya, a0)
		for j in 1:t
			if findmax(yhat[j,:])[1] == y_test[j]
				correct += 1
			end
		end
		@printf "ITERATION %d TEST ACCURACY:\t%d\n" i (correct/t)
		@printf "ITERATION %d ERROR:\t%d\n" i f
	end
end

