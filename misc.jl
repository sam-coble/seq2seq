SEPERATOR = "%%%"

function loadX(T, filename)
	X = Vector{Array{T, 2}}()
	f = open(filename)
	for line in readlines(f)
		push!(X, str2vec(T, line))
	end
	close(f)
	return X
end

function str2vec(T, str)
	ret = Array{T, 2}(undef, length(str) + 1, 28)
	i = 1
	for ch in str
		ret[i,:] = chr2vec(T, ch)
		i += 1
	end
	EOS = zeros(T, 28)
	EOS[28] = 1
	ret[i] = EOS
	return ret
end

function chr2vec(T, char)
	ret = zeros(T, 28)
	ret[Int(char) - 96] = 1
	return ret
end