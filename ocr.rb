# cheat ocr for test

require_relative "config"
require "oily_png"
require "cairo"
require "stringio"

V = [nil]
Inner, Outer = [
  10 * ((DIAMETER / 2 - DEPTH) + (DIAMETER / 2 - THICKNESS)) / 2,
  10 * ((DIAMETER / 2 - DEPTH) + (DIAMETER / 2            )) / 2,
].sort

table = Marshal.load(File.binread("ocr-table.dat"))

S = 2

surface = Cairo::ImageSurface.new(W * (Xmax + 2) * S, (H + 1) * (Ymax + 2) * S)
ctx = Cairo::Context.new(surface)
ctx.antialias = :NONE
ctx.line_width = 0.5
ctx.set_source_rgb(1, 1, 1)
ctx.paint
ctx.set_source_rgb(0, 0, 0)
x_offset = W * (Xmax + 2) / 2 * S
x_scale = W * (Xmax + 2) / Math::PI / 2 * S
y_scale = (1.0 / ((Complex::I**(4.0/W)).arg / (Xmax+2)) / DIAMETER) * 1600 / 8000 * S

# parse the obj file
$<.each do |line|
  case line
  when /^v (-?\d+\.\d+) (-?\d+\.\d+) (-?\d+\.\d+)$/
    x, y, z = $1.to_f, $2.to_f, $3.to_f
    d = Math.hypot(x, y)
    if Inner < d && d < Outer
      x = Math.atan2(y, x) * x_scale + x_offset
      y = -z * y_scale - (Ymax + 2) * x / ((Xmax + 2) * W) + (Ymax + 2)
      V << [x, y]
    else
      V << nil
    end
  when /^f/
    vs = $'.split.map {|s| V[s.to_i] }
    if vs.all?
      ctx.move_to(*vs.last)
      vs.each {|v| ctx.line_to(*v) }
      ctx.fill
    end
  end
end

output = StringIO.new("".b)
surface.write_to_png(output)

png = ChunkyPNG::Image.from_blob(output.string)
(H * W).times do |i|
  i += 1
  x = (i + W / 2) % W
  y = (i + W / 2) / W

  # get feature
  a = []
  (Ymax * 2).times do |j|
    (Xmax * 2).times do |i|
      a << (png[x * (Xmax + 2) * 2 + i + 2, y * (Ymax + 2) * 2 + j + 2] > 255 ? 1 : 0)
    end
  end

  # find the nearest neighbor
  ch, a2 = table.min_by do |ch, a2|
    count = 0
    a.zip(a2) {|b, b2| count += 1 if b != b2 }
    count
  end

  print ch.chr
end
puts
