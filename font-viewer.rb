require "cairo"
require "sinatra"
require "sinatra/reloader"
require_relative "load-glyphs"

get "/" do
  content_type "png"
  gen_png(FONT_CHARS, 200, 300, false)
end

get "/favicon.ico" do
  ""
end

get "/:ch" do |ch|
  content_type "png"
  gen_png(ch.to_i.chr, 200, 300, true)
end
