require "cairo"
require "oily_png"
require_relative "load-glyphs"

table = {}

FONT_CHARS.bytes do |ch|
  blob = gen_png(ch.chr, Xmax * 2, Ymax * 2, false)
  png = ChunkyPNG::Image.from_blob(blob)
  a = []
  (Ymax * 2).times do |y|
    (Xmax * 2).times do |x|
      a << (png[x, y] > 255 ? 1 : 0)
    end
  end
  table[ch] = a
end
table[32] = [1] * table.first.last.size
File.binwrite("ocr-table.dat", Marshal.dump(table))
