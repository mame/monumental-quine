require_relative "load-glyphs"
require_relative "config"

# count max_contour_count and max_point_count
max_contour_count = max_point_count = 0
FONT_CHARS.bytes do |ch|
  contours = $Glyphs[ch]
  max_contour_count = [max_contour_count, contours.size].max
  contours.each do |contour|
    max_point_count = [max_point_count, contour.size].max

    # either condition must be satisfied
    #   * the first point is a control point
    #   * the second point is not a control point
    #
    # so that the second is non-ctrl after interpolation:
    #
    #     ctrl0,     ctrl1, ... ->     ctrl0, interpolated-non-ctrl,     ctrl1, ...
    #     ctrl0, non-ctrl1, ... ->     ctrl0,                        non-ctrl1, ...
    # non-ctrl0, non-ctrl1, ... -> non-ctrl0,                        non-ctrl1, ...
    contour.unshift contour.pop while contour[1].ctrl && !contour[0].ctrl
  end
end

# make a data array (bignum-like in variable base)
ary = []
FONT_CHARS.bytes do |ch|
  contours = $Glyphs[ch]
  ary << [contours.size - 1, max_contour_count]
  contours.each do |contour|
    ary << [contour.size - 3, max_point_count - 2]
    contour.reverse.each do |pt|
      ary << [(pt.ctrl ? 1 : 0), 2]
      ary << [pt.x, Xmax]
      ary << [pt.y, Ymax]
    end
  end
end

# get a bignum
data = 0
ary.reverse.each {|n, max| data = data * max + n }

# transform a bignum to a encoded string
str = []
while data > 0
  str << data % ENCODER_BASE
  data /= ENCODER_BASE
end
str = str.map {|data| (data + ENCODER_ENCODE_OFFSET) % ENCODER_ALIGNMENT + ENCODER_RANGE_A }
str = str.reverse.pack("C*")

# save the result
File.binwrite("font.dat", Marshal.dump([$Glyphs.size, max_contour_count, max_point_count, str]))
