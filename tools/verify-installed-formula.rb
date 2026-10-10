require "formula"
require "formulary"
require "keg"
name = ARGV.fetch(0)
loader = Formulary::FromKegLoader.try_new(name)
raise "Missing keg formula" unless loader
f = loader.get_formula(:stable)
raise "Wrong formula loaded" unless f.name == name && f.path.to_s.include?("/.brew/")
puts JSON.generate(ok: true, product: name, scope: "Actual Homebrew FromKegLoader loads embedded formula and bundled private download strategy", formula: f.name, version: f.version.to_s)
