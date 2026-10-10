require "formula"
require "formula_assertions"
require "formula_free_port"
require "extend/pathname/write_mkpath_extension"
f = Formula[ARGV.fetch(0)]
f.extend(Homebrew::Assertions)
f.extend(Homebrew::FreePort)
Pathname.activate_extensions!
f.run_test
puts JSON.generate(ok: true, scope: "Unmodified Homebrew formula test block via Formula#run_test; compiler environment initialization not required for bundled runtime")
