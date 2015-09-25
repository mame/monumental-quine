# rename: im, trtable, triangulate, tmp, tmp2, pair, convex, hole, holep, holes, p1, p2, p3, poly, polyp=p3, polys, polys2, pt, v2, vertices, ear, idx, update_vertex=poly, bestangle, bestpoly, mergedpoly=holes, depth, inpolys=bestpoly, outpoly, each_rotate, rotated_poly=depth, vertices_orig=bestangle

pair = -> *pair { pair.each_slice(2) };

triangulate = ->inpolys{

# polygon triangulation by ear-clipping algorithm
#
#   inpolys: 2D polygon edge data (a set of polylines) for a 2D glyph
#   outpoly: a set of triangles for a 3D glyph
#
# assumption:
#
# * The input can have multiple polygons.
# * The input can have any number of holes.
# * The input can not have a child polygon in a hole.
# * The format of the input is like: [ [xy0, xy1, ..., xyN], [xy0, xy1, ..., xyN], ...]
# * A position is represented as a complex. (real: x-pos, imag: y-pos)
# * A contour is clockwise.  A hole is counter-clockwise.
# * The format of the output is like: [ [[xy0, z0], [xy1, z1], [xy2, z2]], ...]

# enumerate all rotates
each_rotate = -> tmp do
  tmp.map { tmp = tmp.rotate(1) }
end;

# check the points a, b, and c are convex or not
convex = -> p1,p2,p3 { ((p3-p1) * (p2-p1).conj).arg < 0 };

# triangles consisting of a glyph
outpoly=[];

# DEPTH: distance between center line of column and the bottom of a glyph
depth = STATIC[(DIAMETER - DEPTH * 2) / DIAMETER];

# separate the input to exterior and interiors
polys, holes = inpolys.partition do |poly|
  # area
  tmp = 0;

  each_rotate[poly].map do |p1, p2|
    # add a wall of a carving
    outpoly << pair[p1, depth, p1, 1, p2, 1, p2, depth];

    # calculate the area
    tmp += p1.conj * p2
  end;

  # interior (hole) is counterclockwise if the area is negative
  tmp.arg < 0
end;

# +--------------------+
# |        +--+        |
# |       /    \       |
# |      /  /\  \      |
# |1    /2 /3 \  \     |
# |    /   +--+   \    |
# |   /            \   |
# |  /   +------+   \  |
# | /   /        \   \ |
# |+---+          +---+|
# +--------------------+
pair[
  # 2. faces are carved (depth = DEPTH)
  polys, holes,

  # 1. surrounding area is raised (depth = 1)
  [[0, tmp = STATIC[Ymax + 2] * im, tmp + STATIC[Xmax + 2], STATIC[Xmax + 2]]],
  polys.map(&tmp=:reverse),

  # 3. holes are raised (depth = 1)
  holes.map(&tmp), []
].map do |polys, holes|

  # remove holes
  holes.map do |hole|
    # find the most right vertex of a hole
    each_rotate[hole].max_by{|idx,|idx.real};
  end.

  # rearrange the holes
  sort_by {|holep,| -holep.real }.

  # remove each hole in order by merging a bridge between hole and poly
  map do |hole|
    # holep: the most right vertex in the hole
    holep, = hole;

    # find the best poly
    bestangle = 0;
    polys.map do |poly|
      # find the best vertex in the poly
      each_rotate[poly].map do |rotated_poly|
        polyp, p2, *, p1 = rotated_poly;
        # polyp: the current vertex in the poly
        tmp2 = (holep - polyp).arg**2;

        bestangle < tmp2 &&

        # holep must be in a cone between (poly[idx-2] -- polyp) and (polyp -- poly[idx])
        (tmp = convex[p1, polyp, p2]) ^
        (convex[p1, polyp, holep] ^ tmp | (convex[polyp, p2, holep] ^ tmp)) &&

        # (holep -- polyp) must not cross any other lines
        polys.all? do |poly|
          each_rotate[poly].all? do |p1, p2|
            # (holep -- polyp) and (p1 -- p2) must not intersect
            [holep, polyp, p1, p2].uniq.size < 4 ||
              convex[holep, p1, p2] == convex[polyp, p1, p2] ||
              convex[holep, polyp, p1] == convex[holep, polyp, p2]
          end
        end &&

        # a better vertex is found
        (
          bestangle = tmp2;
          bestpoly = poly;
          mergedpoly = *rotated_poly, polyp, *hole, holep
        )
      end
    end;
    bestpoly[0..-1] = mergedpoly
  end;
  # all holes are removed

  # triangulate each poly
  polys.map do |vertices_orig|
    # vertices[idx] = [pt, prev vertex, next vertex, ear?]
    ear, = vertices = each_rotate[vertices_orig];

    # an auxiliary function to update vertex information
    update_vertex = -> v2 do
      p1,p3,p2=v2;
      p1=p1[2],p2,p3[2];
      v2[3] = convex[*p1] && vertices_orig.all? do |pt|
        # a triangle p1-p2-p3 must not have any vertex inside
        each_rotate[p1].any?{|p1,p2|pt==p1||convex[p1,pt,p2]}
      end
    end;

    # setup vertices as a doubly-linked array
    each_rotate[vertices].map do |p1, p2, p3|
      p2[0,2]=p1,p3;
      update_vertex[p2]
    end;

    # ear-clipping
    (
      vertices[3..-1].map do
        # find any ear
        ear = ear[1] until(ear[3]);

        # remove the ear from the doubly-linked array
        p1, p3 = p2 = ear;
        p3[0], p1[1] = ear;
        update_vertex[p3];
        update_vertex[ear = p1];
        p2
      end << ear
    ).map {|p1,p3,p2| outpoly << pair[p1[2],depth,p2,depth,p3[2],depth] }
  end;

  # distance between center line of column and the face of a glyph
  depth = 1
end;
outpoly

}
