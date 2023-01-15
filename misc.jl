SEPERATOR = "%%%"
TYPE = Float32

function loadX(filename)
	X = Vector{Array{TYPE, 2}}()
	f = open(filename)
	for line in readlines(f)
		push!(X, str2vec(line))
	end
	push!(X, str2vec(s))
	close(f)
	return X
end

function str2vec(str)
	ret = Array{TYPE, 2}(undef, length(str) + 1, 28)
	i = 1
	for ch in str
		ret[i,:] = chr2vec(ch)
		i += 1
	end
	EOS = zeros(TYPE, 28)
	EOS[28] = 1
	ret[i] = EOS
	return ret
end

function chr2vec(char)
	ret = zeros(TYPE, 28)
	ret[Int(char) - 96] = 1
	return ret
end