SEPERATOR = "%%%"

function loadX(filename)
	X = Vector{Array{Float32, 2}}()
	f = open(filename)
	s = ""
	for line in readlines(f)
		if line == SEPERATOR
			push!(X, str2vec(s))
			s = ""
		else
			s = s * line * '\n'
		end
	end
	push!(X, str2vec(s))
	close(f)
	return X
end

function loady(filename)
	y = Vector{Float32}()
	f = open(filename)
	for line in readlines(f)
		push!(y, Int(line[begin]) - 48)
	end
	close(f)
	return y
end

function str2vec(str)
	ret = Array{Float32, 2}(undef, 96, length(str))
	i = 1
	for ch in str
		ret[:,i] = chr2vec(ch)
		i += 1
	end
	return ret
end

function chr2vec(char)
	ret = zeros(Float32, 96)
	if char == '\n'
		ret[96] = 1
	else
		ret[Int(char) - 31] = 1
	end
	return ret
end

	