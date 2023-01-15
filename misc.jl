function loadX(::Type{T}, filename::String)::Vector{Matrix{T}} where T <: AbstractFloat
	X = Vector{Matrix{T}}()
	f = open(filename)
	for line in readlines(f)
		push!(X, str2vec(T, line))
	end
	close(f)
	return X
end

function str2vec(::Type{T}, str::String)::Matrix{T} where T <: AbstractFloat
	ret = Matrix{T}(undef, length(str) + 1, 28)
	i = 1
	for ch in str
		ret[i,:] = chr2vec(T, ch)
		i += 1
	end
	ret[i,:] = begin
		EOS = zeros(T, 28)
		EOS[28] = 1
		EOS
	end
	return ret
end

function chr2vec(::Type{T}, char::Char)::Vector{T} where T <: AbstractFloat
	local ret::Vector{T} = fill(T(-1), 28)
	ret[Int(char) - 96] = T(1)
	return ret
end

function vec2str(vec::Vector{Vector{T}})::String where T <: AbstractFloat
	local str::String = ""
	for i in 1:size(vec, 1)
		max = findmax(vec[i])[2]
		if max <= 26
			str = str * Char(96 + max)
		elseif max == 27
			str = str * "BOS"
		else
			str = str * "EOS"
		end
	end
	return str
end