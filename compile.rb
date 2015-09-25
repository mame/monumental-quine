require_relative "config"

# read the original source
src = File.read(ARGV[0])

# mapping long variable names to short ones
var = ?a
renames = {}
if src =~ /^#\s*rename\s*:(.*)/
  $1.split(?,).each do |s|
    word = s.strip
    if s.include?(?=)
      word, parent = word.split(?=)
      word = word.strip
      parent = parent.strip
      renames[word] = renames[parent]
    else
      renames[word] = var
      var = var.succ
    end
  end
end

def out(msg, ary)
  puts "#{ msg }: #{ ary.empty? ? "(none)" : ary * ", " }"
end

# replace do...end with {...}
src = src.gsub(/\bdo\b/, "{")
src = src.gsub(/\bend\b/, "}")

# remove comments
src = src.gsub(/#.*/, "")

# remove all whitespaces
src = src.split.join

# embed static constants
src = src.gsub(/STATIC\[(.*?)\]/) do
  v = eval($1)
  v.is_a?(Float) ? v.round(5) : v
end

# check if single-character variables don't exist in the original source
orphans = src.gsub(/LITERAL\[.*?\]/, "").scan(/\b[a-z]\b+/).uniq.sort
out "orphan single-letter identifiers (may conflict with auto-generated vars)", orphans

# replace long variable names to one-character ones
renames.each do |word, var|
  src = src.gsub(/\b#{ word }\b/) { var }
end

# check if unknown keywords are not used in the original source
remains = src.gsub(/LITERAL\[.*?\]/, "").scan(/\b[a-z][a-z0-9_]+\b/).uniq.sort
known_keywords = %w(
  all arg any begin bytes conj dump each each_slice eval exit flat_map imag
  index keys map max_by pack partition puts real rect reverse rotate round
  size sort_by times tr upto uniq until upcase while
)
out "remaining unknown keywords", (remains - known_keywords)

# remove LITERAL gaurds
src = src.gsub(/LITERAL\[(.*?)\]/, "\\1")

# check if capital letters are not used in the original source
capitals = src.gsub("FONT", "").scan(/[A-Z]/).uniq.sort
out "capital letters",  capitals

# show metrics
puts "var size: #{ renames.values.uniq.size }"
puts "compressed size: #{ src.size }"

# embed FONT data
src = src.gsub(/FONT/) { Font }

# save the compiled source
File.write(File.basename(ARGV[0], ".rb") + ".src", src)
