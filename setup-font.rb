# rename: im, trtable, triangulate, glyphs, bignum, pair, get, ch, num, poly, tau, ctrl0, ctrl1, pt0=ch, pt1, pt2, xmax, ymax, xx, yy, idx

# decode the encoded font data to a bignum
bignum = 0;
%[FONT].bytes do |num|
  bignum = bignum * STATIC[ENCODER_BASE] + (num - STATIC[-ENCODER_DECODE_OFFSET]) % STATIC[ENCODER_ALIGNMENT]
end;

get = ->num{tau=bignum%num;bignum/=num;tau};

# glyph table: glyphs[(ascii code)] = the 3D glyph
glyphs = { 32 => triangulate[[]] };

# decode the bignum to glyphs
STATIC[FONT_RANGE_C - FONT_RANGE_A].upto(STATIC[GlyphCount + FONT_RANGE_C - FONT_RANGE_A - 1]) do |ch|

  glyphs[ch % STATIC[FONT_RANGE_D - FONT_RANGE_A + 1] + STATIC[FONT_RANGE_A]] =

  # get a 3D glyph
  triangulate[
    # decode a 2D glyph
    (0 .. get[STATIC[MaxContourCount]]).map do # a number of contours
      ctrl0 = pt2 = poly = [];
      pt1 = 0;
      (-2 .. get[STATIC[MaxPointCount - 2]]).map do # a number of points in the contour
        [
          ctrl0 = get[2], # is this a control point?
          pt2 = get[STATIC[Xmax]] + get[STATIC[Ymax]] * im + 1 + im
        ]
      end.

      # ctrl0 and pt2 are keeping the last point information
      flat_map do |ctrl1, pt1|
        # interpolate two consective control points
        *, (pt0,) = [
          [pt2, ctrl0], # the original point
          [(pt2 + pt2 = pt1) / 2, 0] # the interpolated point
        ][0..ctrl0 & ctrl0 = ctrl1] # the second point is used only when ctrl0 & ctrl1 is true
      end.

      # ctrl0 and pt0 are keeping the last point information
      map do |pt2, ctrl0|
        pt1 =
          ctrl0 < 1 ? (
            # convert quadratic bezier to a polyline
            (pt1 == 0 ? 8 : 1).upto(8) do |tau|
              poly << pt0 + tau*(pt1-pt0)/4 + tau*tau*(pt2-2*pt1+pt0)/64
            end;
            pt0 = pt2;
            0
          ) : pt2
      end;

      poly
    end
  ]
end
