require "cairo"
require "stringio"
require_relative "config"

Point = Struct.new(:x, :y, :ctrl)
class Point
  def inspect
    "#{ !ctrl ? ?[ : ?( }#{ x },#{ y }#{ ctrl ? ?) : ?] }"
  end
end

$Glyphs = {}

# load glyphs/*.txt
#
# glyphs/*.txt format:
#   the first line: point ranges
#   the lines below: point map (capital letters are non-control points)
def reload_glyphs
  $Glyphs.clear
  Dir.glob("glyphs/*.txt").each do |file|
    open(file) do |f|
      ranges = f.gets.chomp.downcase.scan(/(\w+)-(\w+)/)
      points = {}
      Ymax.times do |y|
        f.gets.scan(/..?/).each_with_index do |ch, x|
          ch = ch.strip
          points[ch.downcase] = Point[x, y, ch.upcase != ch] if ch != ?.
        end
      end
      $Glyphs[File.basename(file).to_i] = ranges.map do |a, b|
        aa = []
        until a == b || aa.size == 30
          aa << a
          a = a.succ
        end
        aa << b
      end.map do |contour|
        contour.map {|point_id| points[point_id] }
      end
    end
  end
end
reload_glyphs

# determine if poly is counter-clockwise or not
def ccw?(poly)
  s = 0
  [*poly, poly[0]].map {|pt| Complex(pt.x, pt.y) }.each_cons(2) do |p1, p2|
    s += (p2 * p1.conj).imag
  end
  s > 0
end

# get a png blob for str
def gen_png(str, w, h, viewer)
  reload_glyphs

  surface = Cairo::ImageSurface.new(w * str.size, h)
  ctx = Cairo::Context.new(surface)
  ctx.antialias = :NONE
  ctx.line_width = 0
  ctx.set_source_rgb(1, 1, 1)
  ctx.paint
  if viewer
    ctx.set_source_rgb(0.9, 0.9, 0.9)
    ctx.translate(30, 30)
    ctx.select_font_face("Inconsolata")
    ctx.font_size = 300
    e = ctx.text_extents([*33..60].pack("C*"))
    ctx.save do
      ctx.translate(0, -e.y_bearing)
      ctx.show_text(str.tr(TR_COMPLEX, TR_SIMPLE))
    end
    ctx.scale(e.height / 20, e.height / 20)
    ctx.line_width = 0.1
  else
    ctx.scale(w / Xmax, h / Ymax)
  end

  str.tr(TR_COMPLEX, TR_SIMPLE).bytes do |ch|
    $Glyphs[ch].each do |contour|
      # quadratic beziers -> polyline
      polyline = []
      [*contour, contour.first].each_cons(2) do |p0, p1|
        polyline << p0

        # interpolation
        polyline << Point[(p0.x + p1.x) / 2r, (p0.y + p1.y) / 2r, false] if p0.ctrl && p1.ctrl
      end

      # the last point must not be a control point
      polyline.rotate!(1) while polyline.last.ctrl

      # draw
      p0 = polyline.last
      ctx.move_to(p0.x, p0.y)
      p1 = nil
      polyline.each do |p2|
        if p2.ctrl
          p1 = p2
        else
          p1 = p2 unless p1
          # draw a quadratic bezier by using a cubic bezier function
          ctx.curve_to(
            2.0 / 3.0 * p1.x + 1.0 / 3.0 * p0.x,
            2.0 / 3.0 * p1.y + 1.0 / 3.0 * p0.y,
            2.0 / 3.0 * p1.x + 1.0 / 3.0 * p2.x,
            2.0 / 3.0 * p1.y + 1.0 / 3.0 * p2.y,
            p2.x, p2.y
          )
          p0, p1 = p2, nil
        end
      end
      ctx.close_path

      if viewer
        # draw outline
        ctx.set_source_rgb(0, 0, 0)
        ctx.stroke
      else
        # paint
        if ccw?(polyline)
          # hole is counter-clockwise
          ctx.set_source_rgb(0, 0, 0)
        else
          ctx.set_source_rgb(1, 1, 1)
        end
        ctx.fill
      end
    end

    if viewer
      ctx.set_source_rgb(0, 0, 0)
      ctx.rectangle(0, 0, Xmax - 1, Ymax - 1)
      ctx.stroke
    end
    ctx.translate(Xmax - 1, 0)
  end

  # return png blob
  output = StringIO.new("".b)
  surface.write_to_png(output)
  output.string
end
