require "rake/clean"

CLEAN.include FileList["*.src", "mquine.rb", "mquine2.rb", "mquine.obj", "font.dat", "ocr-table.dat"]

GlyphFiles = FileList["glyphs/*.txt"]

file "font.dat" => ["font.dat.gen.rb", "load-glyphs.rb", *GlyphFiles] do |t|
  ruby "font.dat.gen.rb"
end

rule ".src" => ".rb" do |t|
  ruby "compile.rb", t.source
end
file "setup-font.src"   => ["config.rb", "font.dat"]
file "trianglualte.src" => ["config.rb"]
file "make-obj.src"     => ["config.rb"]
file "mquine.rb"        => ["config.rb"]

file "mquine.rb" => ["mquine.rb.gen.rb", "setup-font.src", "triangulate.src", "make-obj.src"] do
  ruby "mquine.rb.gen.rb"
end

file "mquine.obj" => ["mquine.rb"] do |t|
  ruby "mquine.rb > mquine.obj"
end

file "mquine2.obj" => ["mquine.obj"] do |t|
  ruby "mquine.obj > mquine2.obj"
end

file "ocr-table.dat" => ["ocr-table.dat.gen.rb", "load-glyphs.rb", *GlyphFiles] do |t|
  ruby "ocr-table.dat.gen.rb"
end

file "mquine2.rb" => ["mquine.obj", "ocr.rb", "ocr-table.dat"] do |t|
  ruby "ocr.rb mquine.obj > mquine2.rb"
end

task :default => ["mquine.obj"]

task :test => ["mquine2.obj", "mquine2.rb"] do
  sh "diff", "mquine.obj", "mquine2.obj"
  sh "diff", "mquine.rb", "mquine2.rb"
end
