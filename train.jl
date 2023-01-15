using Printf


include("rnn.jl")
# TODO: Batches, L2-reg,

X_train = loadX("data/mixed/lang/examples_train_1.txt")
X_test = loadX("data/mixed/lang/examples_test_1.txt")
# bias 
X_train .= hcat.(X_train, ones.(TYPE, size.(X_train, 1)))
X_test .= hcat.(X_test, ones.(TYPE, size.(X_test,1)))

n = size(X_train, 1)
t = size(X_test, 1)

include("rnn.jl")

## start with prev weights
# include("weights.jl")


## or init randomly
(a0, Waa, Wax, ba, Wbb, Wby, bb, Wyb, by) = init_seq2seq(100, 28)

### sgd


BATCH_SIZE = 50
MAX_ITERATIONS = Int(round(100000/BATCH_SIZE))
STEP_SIZE = 7e-2

@printf "RUNNING WITH STEP_SIZE=%f, BATCH_SIZE=%d, ITERATIONS=%d" STEP_SIZE BATCH_SIZE MAX_ITERATIONS
for i in 1:MAX_ITERATIONS
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
	if i % Int(round(MAX_ITERATIONS/30)) == 0
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

@show Waa
@show Wax
@show Wya
@show a0


correct = 0
test_err = 0
yhat = predict(X_test, Waa, Wax, Wya, a0)
for j in 1:t
	global test_err += sum((yhat[j] - y_test[j,:]).^2)
	if findmax(yhat[j])[2] - 1 == y_test_[j]
		global correct += 1
	end
end
test_err /= t
test_acc = correct/t
yhat = predict(X_train, Waa, Wax, Wya, a0)
correct = 0
train_err = 0
for j in 1:n
	global train_err += sum((yhat[j] - y_train[j,:]).^2)
	if findmax(yhat[j])[2] - 1 == y_train_[j]
		global correct += 1
	end
end
train_err /= n
train_acc = correct / n
@printf "TRAIN ACC: %f\tTEST ACC: %f\tTRAIN ERR: %f\tTEST ERR: %f\n" train_acc test_acc train_err test_err


function predictString(str)
	X_new = Vector{Array{TYPE, 2}}()
	push!(X_new, str2vec(str))
	X_new .= hcat.(X_new, ones.(TYPE, size.(X_new, 1)))
	yhat = predict(X_new, Waa, Wax, Wya, a0)
	if yhat[1][1] > yhat[1][2]
		print("PREDICTION IS CODE EXCERPT")
	else
		print("PREDICTION IS TEXT EXCERPT")
	end
end

