# rename: im, trtable, triangulate, glyphs, bignum, pair, get, str, contour, xx, yy, zz, idx, polygons, tmp, v1, v1z, v2, v2z, v3, v3z, vv, vz, faces=idx, vertices=xx, normals=yy, space=zz, bottom, up, scale

# 3D polygons
polygons = [];

idx = 0;

vv    = im ** STATIC[4.0 / W];        # an argument for one glyph width
scale = STATIC[Xmax + 2] / vv.arg;    # a scale factor
vz    = STATIC[-(Ymax + 2) / W.to_f]; # one glyph height

# a quine
str = 'eval(_=%['+_+'])';

# generate all polygons of column
str.tr(trtable, LITERAL[STATIC[?' + TR_COMPLEX + ?']]).bytes do |tmp|
  # (v1, v1z): xy- and z-coordinates of the left-up vertex of the glyph
  # (v2, v2z): xy- and z-coordinates of the right-bottom vertex of the glyph
  v1z = -vz + v2z = vz *  idx += 1;
  v2  =  vv * v1  = vv ** idx * scale;

  # transform a 3D glyph onto the column wall
  glyphs[tmp].map do |vv|
    polygons << vv.map do |vv, zz|
      xx, yy = vv.rect; # xx: 1..Xmax, yy: 1..Ymax
      [
        (v1 + (v2 - v1) * xx /= STATIC[Xmax + 2]) * zz,
        v1z + vz * xx - yy
      ]
    end
  end;

  # inside walls
  idx < STATIC[W+1] && polygons += [
    # trapezoid for upper gap
    pair[v1,v1z, v2,v2z, *[v2,0]*(idx/STATIC[W]), v2,STATIC[UP], v1,STATIC[UP]],
    # upper cap
    pair[v1,STATIC[UP], v2,STATIC[UP], yy=v2*xx=STATIC[(DIAMETER - THICKNESS * 2) / DIAMETER],STATIC[UP], xx*=v1,STATIC[UP]],
    # inner side
    pair[xx,STATIC[UP], yy,STATIC[UP], yy,bottom=STATIC[BT], xx,bottom],
    # lower cap
    pair[xx,bottom, yy,bottom, v2,bottom, v1,bottom],
    # trapezoid for lower gap
    pair[v1,bottom, v2,bottom, v2,v2z-zz=STATIC[(Ymax + 2) * H], v1,v1z-zz,
     *[v1,bottom+STATIC[UP]]*(1/idx)]
  ];

  # generate a cube
  #idx < 7 && polygons << (0..3).map do
  #  xx, yy, zz = (0..2).map { (1 - 2 * get[2]) * scale / STATIC[DIAMETER] };
  #  [xx + yy * im, zz - STATIC[-BT + 100]]
  #end
end;

# convert polygon data into obj format
vertices = {};
normals = {};
space = ''<<32;
faces = polygons.map do |contour|
  (v1, v1z), (v2, v2z), (v3, v3z) = *contour;
  v1-=v2;
  v2-=v3;
  LITERAL[?f] + space + contour.map do |faces|
    [
      [vertices, LITERAL[:v], *faces],
      [normals, LITERAL[:vn], (v2 * (v1z-v2z) - v1 * (v2z-v3z)) * im, (v1.conj * v2).imag]
    ].map do |vertices, tmp, v1, vz|
      vertices[[tmp, *(v1.rect << vz).map do |v1|
        (v1 * STATIC[ROUND_FACTOR * 5]).round / scale / STATIC[ROUND_FACTOR / DIAMETER]
      end] * space] ||= vertices.size + 1
    end * '//'
  end * space
end;

# output
tmp = ''<<35;
puts(
  LITERAL[%(g%squine')] % space,
  tmp + %{'+(eval(%[} + str + %{]);exit);'},
  vertices.keys,
  normals.keys,
  faces,
  tmp + ?'
)

# note: how to calculate normalized vector (xn, yn, zn) calculation from
# two edges (x1, y1, z1) and (x2, y2, z2).
#
# v1 = x1 + y1 i
# v2 = x2 + y2 i
#
# xn = y1 * z2 - z1 * y2
# yn = z1 * x2 - x1 * z2
# zn = x1 * y2 - y1 * x2
#
#   (v2 * z1 - v1 * z2) * i
# = (x2 + y2i)i * z1 - (x1 + y1i)i * z2
# = y1 * z2 - z1 * y2 + z1 * x2i - x1 * z2i
# = xn + yni
#
#   (v1.conj * v2).imag
# = ((x1 - y1i) * (x2 + y2i)).imag
# = (x1*x2 + x1*y2i - x2*y1i + y1*y2).imag
# = x1*y2 - x2*y1
# = zn
