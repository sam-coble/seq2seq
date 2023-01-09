using Printf


include("rnn.jl")

c = 2

X = loadX("testX.txt")
n = size(X, 1)
y_ = loady("testy.txt")
y = zeros(n, c)
for i in 1:n
	y[i,y_[i]] = 1
end
include("rnn.jl")

# sgd
nstate = 5
Waa = randn(nstate, nstate)
Wax = randn(nstate, (96 + 1))
Wya = randn(c, nstate)
a0 = zeros(nstate)

maxIter = 10000
stepSize = 1e-4

acc = Vector{TYPE}()
for t in 1:maxIter
	i = rand(1:n)
	(f, gWaa, gWax, gWya, ga0) = bptt(Waa, Wax, Wya, a0, X[i], y[i])
	global Waa = Waa - stepSize * gWaa
	global Wax = Wax - stepSize * gWax
	global Wya = Wya - stepSize * gWya
	global a0 = ga0 - stepSize * ga0
	if t % 1000 == 0
		push!(acc, f)
	end
end

print(acc)