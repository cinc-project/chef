#
# Copyright (c) 2026 Cinc Project
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Run with the embedded Ruby: make Ruby's default json the installed json gem,
# since deleting the default instead breaks require under Bundler.

require "fileutils"
require "rbconfig"

lib = RbConfig::CONFIG["rubylibdir"]
arch = RbConfig::CONFIG["rubyarchdir"]
specs_dir = Gem.default_specifications_dir
native = "{so,bundle}"

newest = Gem::Specification.find_all_by_name("json")
  .reject(&:default_gem?)
  .select { |s| s.base_dir == Gem.default_dir }
  .max_by(&:version)
abort "json: failing the build: no regular json gem in #{Gem.default_dir}" unless newest

gem_lib = File.join(newest.full_gem_path, "lib")
ext_files = Dir.glob("json/ext/*.#{native}", base: newest.extension_dir)
abort "json: failing the build: no built json extensions in #{newest.extension_dir}" if ext_files.empty?

FileUtils.rm_rf([File.join(lib, "json.rb"), File.join(lib, "json"), File.join(arch, "json")])
FileUtils.cp_r([File.join(gem_lib, "json.rb"), File.join(gem_lib, "json")], lib)
FileUtils.rm_f(Dir.glob(File.join(lib, "json", "ext", "**", "*.#{native}")))
FileUtils.mkdir_p(File.join(arch, "json", "ext"))
ext_files.each { |f| FileUtils.cp(File.join(newest.extension_dir, f), File.join(arch, f)) }

# The stub needs the real file list, or rubygems can't map `require "json"`.
spec = Gem::Specification.load(newest.loaded_from)
spec.files = Dir.glob("**/*", base: gem_lib)
  .select { |f| File.file?(File.join(gem_lib, f)) }
  .reject { |f| f.end_with?(".so", ".bundle") } + ext_files
FileUtils.rm_f(Dir.glob(File.join(specs_dir, "json-*.gemspec")))
File.write(File.join(specs_dir, "json-#{newest.version}.gemspec"), spec.to_ruby)
puts "json: Ruby's default json is now #{newest.version}"

env = { "GEM_HOME" => Gem.default_dir, "GEM_PATH" => Gem.default_dir }
checks = {
  "plain require" => ['require "json"; print JSON::VERSION, " ", Gem.loaded_specs["json"]&.version', "#{newest.version} #{newest.version}"],
  "--disable-gems" => ['require "json"; print JSON::VERSION, " ", JSON::Parser', "#{newest.version} JSON::Ext::Parser"],
  "default stubs" => ['print Gem::Specification.default_stubs("json-*.gemspec").map(&:full_name).join(",")', "json-#{newest.version}"],
}
checks.each do |label, (code, want)|
  args = label == "--disable-gems" ? ["--disable-gems", "-e", code] : ["-e", code]
  got = IO.popen([env, RbConfig.ruby, *args], err: %i{child out}, &:read).strip
  abort "json: failing the build: #{label} gave #{got.inspect}, expected #{want.inspect}" unless got == want
  puts "json: #{label}: #{got}"
end
