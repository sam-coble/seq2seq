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

# Computes predictions for a set of examples X
function predict(X, Waa, Wax, Wya, a0)
	n = size(X, 1)
	k = size.(X, 1)
	X .= hcat.(X, ones.(TYPE, k))
	yhat = Vector{Vector{TYPE}}()
	for xi in X
		a = a0
		(k, d) = size(xi)
		a = a0
		for j in 1:k
			a = ha(Waa * a + Wax * xi[j,:])
		end
		push!(yhat, hy(Wy * vcat(a,1)))
	end
	return yhat
end

# Computes squared error (f) and gradient (g)
# for a single training example (x,y)
function bptt(Waa, Wax, Wya, a0, x, y)
	(k, d) = size(x)
	c = size(y, 1)
	m = size(a0, 1)
	x = hcat(x, ones(TYPE, k))
	### Forward propagation
	a = Array{TYPE, 2}(undef, k + 1, m)
	a[1,:] = a0
	for j in 1:k
		a[j + 1,:] = ha(Waa * a[j,:] + Wax * xi[j,:])
	end
	r = hy(Wy * vcat(a,1)) - y
	f = 0.5*sum(r.*r) # squared residual error

	### Backpropagation
	dr = r
	err = dr
	gWya = zeros(TYPE, size(Wya))
	for i in 1:c
		for j in 1:(m+1)
			gWya[i,j] = err[i] * dhy(Wya[i,j]*a) * (j <= m ? a[k+1,j] : 1)
		end
	end
	gWaa = zeros(TYPE, size(Waa))
	gWax = zeros(TYPE, size(Wax))
	ga0 = zeros(TYPE, size(a0))
	return (f, gWaa, gWax, gWya, ga0)
end




