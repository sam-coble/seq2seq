SEPERATOR = "%%%"
TYPE = Float32
TYPE_Y = Int8

function loadX(filename)
	X = Vector{Array{TYPE, 2}}()
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
	y = Vector{TYPE_Y}()
	f = open(filename)
	for line in readlines(f)
		push!(y, Int(line[begin]) - 48)
	end
	close(f)
	return y
end
function unrolly(y_)
	n = size(y_, 1)
	y = fill(-1, (n, maximum(y_)+1))
	for i in 1:n
		y[i,y_[i] + 1] = 1
	end
	return y
end

function str2vec(str)
	ret = Array{TYPE, 2}(undef, length(str), 96)
	i = 1
	for ch in str
		ret[i,:] = chr2vec(ch)
		i += 1
	end
	return ret
end

function chr2vec(char)
	ret = zeros(TYPE, 96)
	if char == '\n'
		ret[96] = 1
	else
		ret[Int(char) - 31] = 1
	end
	return ret
end

	