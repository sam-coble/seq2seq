using Printf


include("rnn.jl")

X = loadX("testX.txt")
y = loady("testy.txt")

include("rnn.jl")

n = size(X, 1)

# sgd
