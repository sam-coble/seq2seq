include("misc.jl")

function ha(z)
	return tanh.(z)
end
function dha(z)
	return (sech.(z)).^2
end
function hy(z)
	return tanh.(z)
end
function dhy(z)
	return (sech.(z)).^2
end

mutable struct seq2seq{T<:AbstractFloat}
	a0::Vector{T}
	Waa::Array{T, 2}
	Wax::Array{T, 2}
	ba::T
	Wbb::Array{T, 2}
	Wby::Array{T, 2}
	bb::T
	Wyb::Array{T, 2}
	by::T
end

function init_seq2seq(T, m, d) where T <: AbstractFloat
	return seq2seq{T}(
		randn(T, m), 	# a0
		randn(T, m, m), # Waa
		randn(T, m, d),	# Wax
		randn(T, 1)[1],	# ba
		randn(T, m, m), # Wbb
		randn(T, m, d), # Wby
		randn(T, 1)[1],	# bb
		randn(T, d, m), # Wyb
		randn(T, 1)[1] 	# by
	)

end

# Computes predictions for a set of examples X
function predict(X, Waa, Wax, Wya, a0)
	n = size(X, 1)
	k = size.(X, 1)
	# X .= hcat.(X, ones.(TYPE, k))
	# @show size(X_test[1])
	yhat = Vector{Vector{TYPE}}()
	for xi in X
		a = a0
		(k, d) = size(xi)
		a = a0
		for j in 1:k
			a = ha(Waa * a + Wax * xi[j,:])
		end
		push!(yhat, hy(Wya * vcat(a,1)))
	end
	return yhat
end

# Computes squared error (f) and gradient (g)
# for a single training example (x,y)
function bptt(Waa, Wax, Wya, a0, x, y)
	(k, d) = size(x)
	c = size(y, 1)
	m = size(a0, 1)
	# x = hcat(x, ones(TYPE, k))
	# d += 1

	### Forward propagation
	z = Array{TYPE, 2}(undef, k + 1, m)
	a = Array{TYPE, 2}(undef, k + 1, m)
	z[1,:] = a0
	a[1,:] = z[1,:]
	for l in 1:k
		z[l + 1,:] = Waa * a[l,:] + Wax * x[l,:]
		a[l + 1,:] = ha(z[l+1,:])
	end
	zf = Wya * vcat(a[k+1,:], 1)
	yhat = hy(zf)
	r = yhat - y
	f = 0.5*sum(r.*r) # squared residual error

	### Backpropagation
	dr = r
	err = dr
	gWya = zeros(TYPE, size(Wya))
	for i in 1:c
		for j in 1:(m+1)
			gWya[i,j] = err[i] * dhy(zf[i]) * (j <= m ? a[k+1,j] : 1)
		end
	end
	gWaa = zeros(TYPE, size(Waa))
	gWax = zeros(TYPE, size(Wax))
	backprop = zeros(TYPE, size(a0))
	for i in 1:m
		for j in 1:c
			backprop[i] += Wya[j, i] * dhy(zf[j]) * r[j]
		end
	end
	for l in k:-1:1
		for i in 1:d
			for j in 1:m
				gWax[j,i] += x[l, d] * dha(z[l+1,j]) * backprop[j]
			end
		end
		for i in 1:m
			for j in 1:m
				gWaa[j,i] += a[l, i] * dha(z[l+1,j]) * backprop[j]
			end
		end
		newbackprop = zeros(TYPE, size(backprop))
		for i in 1:m
			for j in 1:m
				newbackprop[i] += Waa[j, i] * dha(z[l+1,j]) * backprop[j]
			end
		end
		backprop = newbackprop
	end
	ga0 = backprop
	return (f, gWaa, gWax, gWya, ga0)
end




