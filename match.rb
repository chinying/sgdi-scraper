
def levenshtein_distance(s, t)
  m = s.length
  n = t.length
  return m if n == 0
  return n if m == 0
  d = Array.new(m+1) {Array.new(n+1)}

  (0..m).each {|i| d[i][0] = i}
  (0..n).each {|j| d[0][j] = j}
  (1..n).each do |j|
    (1..m).each do |i|
      d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                  d[i-1][j-1]       # no operation required
                else
                  [ d[i-1][j]+1,    # deletion
                    d[i][j-1]+1,    # insertion
                    d[i-1][j-1]+1,  # substitution
                  ].min
                end
    end
  end
  d[m][n]
end


if __FILE__ == $0
  file = File.open('./org_to_match.txt', 'r')
  orgs = file.readlines
  file.close

  file = File.open('./output.txt', 'r')
  contents = file.readlines
  crawled_orgs = contents
    .each_slice(2)
    .to_a
  file.close

  dic = {}
  orgs.each do |i|
    cleaned_org = i[0..-2].downcase
    min_so_far = (1 << 31)
    lo = nil
    crawled_orgs.each do |j|
      crawled_org_info = j[1].split(";")
      c_org_name = crawled_org_info[0].downcase
      # normalise the edit distance (is this even the way to do it)
      dist = levenshtein_distance(c_org_name, cleaned_org).to_f / (c_org_name.length + cleaned_org.length)
      if dist < min_so_far
        min_so_far = dist
        lo = [c_org_name, cleaned_org, crawled_org_info[1][0..-2]]
      end
    end

    puts "lo -> #{lo}; dist -> #{min_so_far}"
  end

end

