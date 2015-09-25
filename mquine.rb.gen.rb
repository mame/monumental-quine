require_relative "config"

# global var:
#   _ = quine seed
#   a = Complex::I
#   b = tr table
#   c = triangulate
#   d = glyphs
#   e = bignum (font + cube)
#   f = each_slice(2)

raise if TR_COMPLEX.tr("&-}", "%-|").tr('x%-|','%-'<<125) != TR_COMPLEX

src = <<END
eval(_ = %[
  b='#{ TR_SIMPLE }';
  eval(
    (%[
      a=(-1)**0.5;
      #{ File.read("triangulate.src") };
      #{ File.read("setup-font.src") };
      #{ File.read("make-obj.src").sub(TR_COMPLEX) { "]+b+%[" } };
    ]).tr(b,'#{ TR_COMPLEX.tr("&-}", "%-|") }'.tr('x%-|','%-'<<125))
  );''
])
END

src = src.tr(TR_COMPLEX, TR_SIMPLE)

src = src.split.join unless ENV["NOCOMP"]

puts "size: #{ src.size }"

copyright = "  Monumental Quine (c) 2015 Yusuke Endoh -- tested with ruby 2.2.1 -- built on 2015/04/01 "
padding = [W * H - src.size, 0].max
if padding >= copyright.size
  s = ""
  if (padding - copyright.size) % 2 == 1
    s << " "
    padding -= 1
  end
  n = (padding - copyright.size) / 2
  src[-3, 0] = s + ?[ * n + copyright + ?] * n
end

File.write("mquine.rb", src + "\n")
