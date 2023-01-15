include("misc.jl")

function ha(z::T) where T <: AbstractFloat
	return tanh(z)
end
function dha(z::T) where T <: AbstractFloat
	return (sech(z))^2
end
function hb(z::T) where T <: AbstractFloat
	return tanh(z)
end
function dhb(z::T) where T <: AbstractFloat
	return (sech(z))^2
end
function hy(z::T) where T <: AbstractFloat
	return tanh(z)
end
function dhy(z::T) where T <: AbstractFloat
	return (sech(z))^2
end


mutable struct seq2seq{T<:AbstractFloat}
	const m::Int32
	const d::Int32
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

function init_seq2seq(::Type{T}, m::Int32, d::Int32)::seq2seq{T} where T <: AbstractFloat
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
function emptyGrad(::Type{T}, m::Int32, d::Int32)::seq2seq_grad{T} where T <: AbstractFloat
	return seq2seq_grad{T}(
		zeros(T, m),
		zeros(T, m, m),
		zeros(T, m, d),
		zeros(T, m),
		zeros(T, m, m),
		zeros(T, m, d),
		zeros(T, m),
		zeros(T, d, m),
		zeros(T, d)
	)
end

function sumGrads(::Type{T}, g1::seq2seq_grad{T}, g2::seq2seq_grad{T})::seq2seq_grad{T} where T <: AbstractFloat
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
function subGradient(::Type{T}, model::seq2seq{T}, g::seq2seq_grad{T}, stepSize::T)::seq2seq{T} where T <: AbstractFloat
	return seq2seq{T}(
		model.m,
		model.d,
		model.a0 + g.a0 * stepSize,
		model.Waa + g.Waa * stepSize,
		model.Wax + g.Wax * stepSize,
		model.ba + g.ba * stepSize,
		model.Wbb + g.Wbb * stepSize,
		model.Wby + g.Wby * stepSize,
		model.bb + g.bb * stepSize,
		model.Wyb + g.Wyb * stepSize,
		model.by + g.by * stepSize
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
function bptt(x::Matrix{T}, y::Matrix{T}, model::seq2seq{T}, MAX_OUTPUTS::Int32)::Tuple{T, seq2seq_grad{T}} where T <: AbstractFloat
	local k::Int32 = size(x, 1)

	### Forward propagation
	## over encoder
	za = Vector{Vector{T}}(undef, k+1)
	a = Vector{Vector{T}}(undef, k+1)
	za[1] = model.a0
	a[1] = za[1]
	for l in 1:k
		za[l + 1] = model.Waa * a[l] + model.Wax * x[l,:] + model.ba
		a[l + 1] = ha.(za[l+1])
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
	outputs::Int32 = 0
	while true
		push!(zb, model.Wbb * b[lastindex(b)] + model.Wby * yhat[lastindex(yhat)] + model.bb)
		push!(b, hb.(zb[lastindex(zb)]))
		push!(zyhat, model.Wyb * b[lastindex(b)] + model.by)
		push!(yhat, hy.(zyhat[lastindex(zyhat)]))
		outputs += 1
		if findmax(yhat[lastindex(yhat)])[2] == model.d - 1
			break
		elseif outputs >= MAX_OUTPUTS
			break
		end
	end


	### calculate error
	local r::Vector{Vector{T}} = Vector{Vector{T}}(undef, size(yhat, 1) - 1)
	local EOS::Vector{T} = begin
		EOS = zeros(T, model.d)
		EOS[model.d] = 1
		EOS
	end
	for i in 1:(size(yhat, 1)-1) # to account for yhat0
		if i > size(y, 1)
			r[i] = yhat[i+1] - EOS
		else
			r[i] = yhat[i+1] - y[i,:] 
		end
	end

	# squared residual error
	f::T = 0
	for i in 1:size(r, 1)
		f += 0.5 * sum(r[i].*r[i])
	end


	### Backpropagation
	local gWaa::Matrix{T} = zeros(T, model.m, model.m)
	local gWax::Matrix{T} = zeros(T, model.m, model.d)
	local gba::Vector{T} = zeros(T, model.m)
	local gWbb::Matrix{T} = zeros(T, model.m, model.m)
	local gWby::Matrix{T} = zeros(T, model.m, model.d)
	local gbb::Vector{T} = zeros(T, model.m)
	local gWyb::Matrix{T} = zeros(T, model.d, model.m)
	local gby::Vector{T} = zeros(T, model.d)


	local backprop_y::Vector{T} = zeros(T, model.d)
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
		local new_backprop_ba::Vector{T} = zeros(T, model.m)
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
				gWax[i, j] += backprop_ba[i] * dha(za[l + 1][i]) * x[l,j]
			end
		end
		# gba
		for i in 1:model.m
			gba[i] += backprop_ba[i] * dha(za[l + 1][i])
		end
	end

	# leftover backprop is initial state
	local ga0 = backprop_ba


	# return error + gradient
	return (f, seq2seq_grad{T}(ga0, gWaa, gWax, gba, gWbb, gWby, gbb, gWyb, gby))
end




