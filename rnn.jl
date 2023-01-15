include("misc.jl")

function ha(T::DataType, z::Vector{T})::Vector{T} where T <: AbstractFloat
	return tanh.(z)
end
function dha(T::DataType, z::Vector{T})::Vector{T} where T <: AbstractFloat
	return (sech.(z)).^2
end
function hb(T::DataType, z::Vector{T})::Vector{T} where T <: AbstractFloat
	return tanh.(z)
end
function dhb(T::DataType, z::Vector{T})::Vector{T} where T <: AbstractFloat
	return (sech.(z)).^2
function hy(T::DataType, z::Vector{T})::Vector{T} where T <: AbstractFloat
	return tanh.(z)
end
function dhy(T::DataType, z::Vector{T})::Vector{T} where T <: AbstractFloat
	return (sech.(z)).^2
end

mutable struct seq2seq{T<:AbstractFloat}
	const m::Int16,
	const d::Int16,
	a0::Vector{T}
	Waa::Matrix{T}
	Wax::Matrix{T}
	ba::Vector{T}
	Wbb::Matrix{T}
	Wby::Matrix{T}
	bb::Vector{T}
	Wyb::Matrix{T}
	by::Vector{T}
end

struct seq2seq_grad{T<:AbstractFloat}
	a0::Vector{T}
	Waa::Matrix{T}
	Wax::Matrix{T}
	ba::Vector{T}
	Wbb::Matrix{T}
	Wby::Matrix{T}
	bb::Vector{T}
	Wyb::Matrix{T}
	by::Vector{T}
end

function init_seq2seq(T::DataType, m::Integer, d::Integer)::seq2seq{T} where T <: AbstractFloat
	return seq2seq{T}(
		m,
		d,
		randn(T, m), 	# a0
		randn(T, m, m), # Waa
		randn(T, m, d),	# Wax
		randn(T, m),	# ba
		randn(T, m, m), # Wbb
		randn(T, m, d), # Wby
		randn(T, m),	# bb
		randn(T, d, m), # Wyb
		randn(T, d) 	# by
	)
end
function emptyGrad(T::DataType, m::Int32, d::Int32)::seq2seq_grad{T} where T <: AbstractFloat
	return seq2seq_grad{T}(
		zeros(T, m),
		zeros(T, m, m),
		zeros(T, m, d),
		zeros(T, m)
		zeros(T, m, m)
		zeros(T, m, d)
		zeros(T, m),
		zeros(T, d, m),
		zeros(T, d)
	)
end

function addGradients(g1::seq2seq_grad{T}, g2::seq2seq_grad{T})::seq2seq_grad{T}
	return seq2seq_grad{T}(
		g1.a0 + g2.a0,
		g1.Waa + g2.Waa,
		g1.Wax + g2.Wax,
		g1.ba + g2.ba,
		g1.Wbb + g2.Wbb,
		g1.Wby + g2.Wby,
		g1.bb + g2.bb,
		g1.Wyb + g2.Wyb,
		g1.by + g2.by
	)
end
function addGradent(model::seq2seq{T}, g::seq2seq_grad{T})::seq2seq{T}
	return seq2seq{T}(
		model.m,
		model.d,
		model.a0 + g.a0,
		model.Waa + g.Waa,
		model.Wax + g.Wax,
		model.ba + g.ba,
		model.Wbb + g.Wbb,
		model.Wby + g.Wby,
		model.bb + g.bb,
		model.Wyb + g.Wyb,
		model.by + g.by
	)
end

function encode(X::Matrix{T}, model::seq2seq{T})::Vector{T} where T <: AbstractFloat
	(k, d) = size(X)
	a = model.a0
	for layer in 1:k
		a = ha( model.Waa * a + model.Wax * X[layer,:] )
	end
	return a
end

function decode(b0::Vector{T}, model::seq2seq{T})::Vector{T} where T <: AbstractFloat
	BOS = zeros(T, model.d)
	BOS[model.d - 1] = 1
	BOS
	y = Vector{T}()
	push!(y, BOS)
	b = b0
	while true
		b = hb( model.Wbb * b + model.Wby * y[lastindex(y)] + model.bb )
		push!(y, hy( model.yb * b + model.by ))
		if findmax(y[lastindex(y)])[2] == model.d
			break
		end
	end
	return y
end

# Computes predictions for a set of examples X
function predict(X::Vector{Matrix{T}}, model::seq2seq{T})::Vector{Vector{T}} where T <: AbstractFloat
	return decode.(encode.(X, model), model)
end

# Computes squared error (f) and gradient (g)
# for a single training example (x,y)
function bptt(x::Vector{T}, y::Vector{T}, model::seq2seq{T}, MAX_OUTPUTS::Int16)::seq2seq_grad{T} where T <: AbstractFloat
	const k = size(x, 1)

	### Forward propagation
	## over encoder
	za = Vector{Vector{T}}(undef, k+1)
	a = Vector{Vector{T}}(undef, k+1)
	za[1] = a0
	a[1] = z[1]
	for l in 1:k
		za[l + 1] = model.Waa * a[l] + model.Wax * x[l] + model.ba
		a[l + 1] = ha(za[l+1])
	end
	zb = Vector{Vector{T}}()
	b = Vector{Vector{T}}()
	zyhat = Vector{Vector{T}}()
	yhat = Vector{Vector{T}}()
	push!(zb, za[k+1])
	push!(b, a[k+1])
	push!(zyhat, begin
		BOS = zeros(T, model.d)
		BOS[model.d - 1] = 1
		BOS
	end)
	push!(yhat, zyhat[1])

	## over decoder
	outputs::Int16 = 0
	while true
		push!(zb, model.Wbb * b[lastindex(b)] + model.by * yhat[lastindex(yhat)] + model.bb)
		push!(b, hb(zb[lastindex(zb)]))
		push!(zyhat, model.Wyb * b[lastindex(b)] + model.by)
		push!(yhat, hy(zyhat[lastindex(zhat)]))
		outputs += 1
		if finxmax(yhat[lastindex(yhat)])[2] == model.d - 1
			break
		else if outputs >= MAX_OUTPUTS
			break
		end
	end


	### calculate error
	const r::Vector{Vector{T}} = Vector{Vector{T}}(undef, size(yhat, 1) - 1)
	const EOS::Vector{T} = begin
		EOS = zeros(T, model.d)
		EOS[model.d] = 1
		EOS
	end
	for i in 1:(size(yhat, 1)-1) # to account for yhat0
		if i > size(y, 1)
			r[i] = yhat[i+1] - EOS
		else
			r[i] = yhat[i+1] - y[i] 
		end
	end
	const f = 0.5*sum(r.*r) # squared residual error


	### Backpropagation
	const gWaa::Matrix{T} = zeros(T, model.m, model.m)
	const gWax::Matrix{T} = zeros(T, model.m, model.d)
	const gba::Vector{T} = zeros(T, model.m)
	const gWbb::Matrix{T} = zeros(T, model.m, model.m)
	const gWby::Matrix{T} = zeros(T, model.m, model.d)
	const gbb::Vector{T} = zeros(T, model.m)
	const gWyb::Matrix{T} = zeros(T, model.d, model.m)
	const gby::Vector{T} = zeros(T, model.d)


	const backprop_y::Vector{T} = zeros(T, model.d)
	backprop_ba::Vector{T} = zeros(T, model.m)

	## over decoder
	for l in (size(yhat, 1) - 1):-1:1
		# backprop_y
		for j in 1:model.d
			for i in 1:model.m
				backprop_y[j] += model.Wby[i, j] * dhb(zb[l + 1][i]) * backprop_ba[i]
			end
			backprop_y[j] += r[l][j]
		end
		# backprop_ba
		const new_backprop_ba::Vector{T} = zeros(T, model.m)
		for j in 1:model.m
			for i in 1:model.m
				new_backprop_ba[j] += model.Wbb[i, j] * dhb(zb[l + 1][i]) * backprop_ba[i]
			end
			for i in 1:model.d
				new_backprop_ba[j] += model.Wyb[i, j] * dhy(zyhat[l + 1][i]) * backprop_y[i]
			end
		end
		backprop_ba = new_backprop_ba

		# gWyb
		for j in 1:model.m
			for i in 1:model.d
				gWyb[i, j] += (r[l][i] + backprop_y[i]) * dhy(zyhat[l + 1][i]) * b[l + 1][j]
			end
		end
		# gby
		for i in 1:model.d
			gby[i] += (r[l][i] + backprop_y[i]) * dhy(zyhat[l + 1][i])
		end

		# gWbb
		for j in 1:model.m
			for i in 1:model.m
				gWbb[i, j] += backprop_ba[i] * dhb(zb[l + 1][i]) * b[l + 1][j]
			end
		end
		# gWby
		for j in 1:model.d
			for i in 1:model.m
				gWby[i, j] += backprop_ba[i] * dhb(zb[l + 1][i] * yhat[l + 1][j])
			end
		end
		# gbb
		for i in 1:model.m
			gbb[i] += backprop_ba[i] * dhb(zb[l + 1][i])
		end
	end


	## over encoder
	for l in (k-1):-1:1
		# gWaa
		for j in 1:model.m
			for i in 1:model.m
				gWaa[i, j] += backprop_ba[i] * dha(za[l + 1][i]) * a[l + 1][j]
			end
		end
		# gWax
		for j in 1:model.d
			for i in 1:model.m
				gWax[i, j] += backprop_ba[i] * dha(za[l + 1][i]) * x[l][j]
			end
		end
		# gba
		for i in 1:model.m
			gba[i] += backprop_ba[i] * dha(za[l + 1][i])
		end
	end

	# leftover backprop is initial state
	const a0 = backprop_ba


	# return error + gradient
	return (f, seq2seq_grad(ga0, gWaa, gWax, gba, gWbb, gWby, gbb, gWyb, gby))
end




