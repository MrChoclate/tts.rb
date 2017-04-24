SAME, DIFF, ADD, DEL = [0, 1, 2, 3]


def compute_levenshtein_matrix(sentence, sentence2)
  d = Array.new(sentence.length + 1) { Array.new(sentence2.length + 1) }
  for i in 0..sentence.length
      d[i][0] = i
  end
  for j in 0..sentence2.length
      d[0][j] = j
  end

  for i in 1..sentence.length
    for j in 1..sentence2.length
      cost = sentence[i-1] == sentence2[j-1] ? 0 : 1
      d[i][j] = [
        d[i-1][j] + 1,
        d[i][j-1] + 1,
        d[i-1][j-1] + cost
      ].min
    end
  end

  return d
end

def levenshtein(sentence, sentence2)
  d = compute_levenshtein_matrix(sentence, sentence2)

  return d[sentence.length][sentence2.length]
end

def get_levenshtein_ops(sentence, sentence2)
  d = compute_levenshtein_matrix(sentence, sentence2)
  current_value = d[sentence.length][sentence2.length]
  ops = []

  i, j = sentence.length, sentence2.length
  while i != 0 && j != 0 do
    diag = d[i-1][j-1]
    left = d[i][j-1]
    top = d[i-1][j]

    if diag <= left && diag <= top then
      if current_value == diag then
        ops.push(SAME)
      else
        ops.push(DIFF)
      end
      current_value = diag
      i -= 1
      j -= 1
    elsif left <= top then
      current_value = left
      j -= 1
      ops.push(ADD)
    else
      current_value = top
      i -= 1
      ops.push(DEL)
    end
  end

  j.times do
    ops.push(ADD)
  end

  i.times do
    ops.push(DEL)
  end

  return ops.reverse
end
