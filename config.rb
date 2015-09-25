DIAMETER  = 10   # external diameter (cm)
THICKNESS = 0.12 # thickness (cm)
DEPTH     = 0.07 # carved depth (cm) (negative to emboss)

W = 100          # the number of characters per a line
H = 30           # the number of lines

Xmax = 13        # glyph point-grid width
Ymax = 21        # glyph point-grid height

# use simple glyph characters instead of complex ones
TR_SIMPLE  = "DEILMQTVY"
TR_COMPLEX = "&*38?gj{}"

if File.readable?("font.dat")
  GlyphCount, MaxContourCount, MaxPointCount, Font =
    Marshal.load(File.binread("font.dat"))
end

# FONT_RANGE: this program contains data of glyphs of characters [*FONT_RANGE_A..B, *C..D]
# ENCODER_RANGE: this program encodes the data by using characters [*ENCODER_RANGE_A..B, *C..D]
FONT_RANGE_A, ENCODER_RANGE_A =  37,  37
FONT_RANGE_B, ENCODER_RANGE_B =  63,  63
FONT_RANGE_C, ENCODER_RANGE_C =  91,  94 # 91:`[` 92:`\` 93: `]`
FONT_RANGE_D, ENCODER_RANGE_D = 125, 125

ROUND_FACTOR = 100 # must be a multiple of DIAMETER

UP = 2                  # margin between the upper edge of the column and the top of the first character
                        # (= z-coordinate of the upper edge of the column)
BT = -(Ymax+2)*(H+1)-UP # bottom: z-coordinate of the lower edge of the column


# ---


ENCODER_BASE =
  (ENCODER_RANGE_D - ENCODER_RANGE_C + 1) + (ENCODER_RANGE_B - ENCODER_RANGE_A + 1)
ENCODER_DECODE_OFFSET = ENCODER_RANGE_D - ENCODER_RANGE_A - ENCODER_RANGE_C + 1
ENCODER_ENCODE_OFFSET = ENCODER_RANGE_C - ENCODER_RANGE_A
ENCODER_ALIGNMENT = ENCODER_RANGE_D - ENCODER_RANGE_A + 1

# encode:
#   input: [m0, m1, ...] where 0 <= m < ENCODER_BASE
#   output: [n0, n1, ...] where ENCODER_RANGE_A <= n <= RANGE_B or RANGE_C <= n <= RANGE_D
#   n = (m + ENCODER_ENCODE_OFFSET) % ENCODER_ALIGNMENT + ENCODER_RANGE_A
# decode
#   input: [n0, n1, ...] where ENCODER_RANGE_A <= n <= RANGE_B or RANGE_C <= n <= RANGE_D
#   output: [m0, m1, ...] where 0 <= m < ENCODER_BASE
#   m = (n + ENCODER_DECODE_OFFSET) % ENCODER_ALIGNMENT

FONT_CHARS =
  [*FONT_RANGE_C..FONT_RANGE_D, *FONT_RANGE_A..FONT_RANGE_B].pack("C*").
  tr(TR_COMPLEX, TR_SIMPLE)
