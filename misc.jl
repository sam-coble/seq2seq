function loadX(T::DataType, filename::String)::Vector{Array{T, 2}} where T <: AbstractFloat
	X = Vector{Array{T, 2}}()
	f = open(filename)
	for line in readlines(f)
		push!(X, str2vec(T, line))
	end
	close(f)
	return X
end

function str2vec(T::DataType, str::String)::Array{T, 2} where T <: AbstractFloat
	ret = Array{T, 2}(undef, length(str) + 1, 28)
	i = 1
	for ch in str
		ret[i,:] = chr2vec(T, ch)
		i += 1
	end
	ret[i] = begin
		EOS = zeros(T, 28)
		EOS[28] = 1
		EOS
	end
	return ret
end

function chr2vec(T::DataType, char::Char)::Vector{T} where T <: AbstractFloat
	ret = zeros(T, 28)
	ret[Int(char) - 96] = 1
	return ret
end