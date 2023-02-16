source "https://rubygems.org"

# 1.15+ is required for M1 mac builds
gem "ffi", ">=1.15"

# Nwed to file a bug with rest-client. In the meantime, we can use this until they accept the update.
gem "rest-client", git: "https://github.com/chef/rest-client", branch: "jfm/ucrt_update1"

# Note we do not use the gemspec DSL which restricts to the
# gemspec for the current platform and filters out other platforms
# during a bundle lock operation. We actually want dependencies from
# both of our gemspecs. Also note this this mimics gemspec behavior
# of bundler versions prior to 1.12.0 (https://github.com/bundler/bundler/commit/193a14fe5e0d56294c7b370a0e59f93b2c216eed)
gem "chef", path: "."

gem "ohai", git: "https://github.com/chef/ohai.git", branch: "16-stable"

gem "chef-utils", path: File.expand_path("chef-utils", __dir__) if File.exist?(File.expand_path("chef-utils", __dir__))
gem "chef-config", path: File.expand_path("chef-config", __dir__) if File.exist?(File.expand_path("chef-config", __dir__))

# gems below are added here for Chef-16 compat. Their modern versions don't support Ruby 2.6
gem "semverse", "= 3.0.0"
gem "train-core", "= 3.2"

if File.exist?(File.expand_path("chef-bin", __dir__))
  # bundling in a git checkout
  gem "chef-bin", path: File.expand_path("chef-bin", __dir__)
else
  # bundling in omnibus
  gem "chef-bin" # rubocop:disable Bundler/DuplicatedGem
end

# gem "cheffish", ">= 14"
gem "cheffish", "= 16.0.26"

gem "chef-telemetry", ">=1.0.8" # 1.0.8 removes the http dep

group(:omnibus_package) do
  gem "appbundler"
  gem "rb-readline"
  gem "inspec-core", "~> 4.24",
    source: "https://packagecloud.io/cinc-project/stable"
  gem "cinc-auditor-core-bin", "~> 4.24", # need to provide the binaries for inspec
    source: "https://packagecloud.io/cinc-project/stable"
  gem "chef-vault"
  gem "chef-zero", source: "https://packagecloud.io/cinc-project/stable"
end

group(:omnibus_package, :pry) do
  # Locked because pry-byebug is broken with 13+
  # some work is ongoing? https://github.com/deivid-rodriguez/pry-byebug/issues/343
  gem "pry", "= 0.13.0"
  # byebug does not install on freebsd on ruby 3.0
  # This is the last version compatible for ruby2.6, which is used at linting step
  gem "pry-byebug", "~> 3.9.0" unless RUBY_PLATFORM =~ /freebsd/i
  gem "pry-stack_explorer"
end

# Everything except AIX
group(:ruby_prof) do
  # ruby-prof 1.3.0 does not compile on our centos6 builders/kitchen testers
  gem "ruby-prof", "< 1.3.0"
end

# Everything except AIX and Windows
group(:ruby_shadow) do
  gem "ruby-shadow", platforms: :ruby
end

group(:development, :test) do
  gem "rake"
  gem "rspec"
  gem "webmock"
  gem "fauxhai-ng" # for chef-utils gem
end

group(:chefstyle) do
  gem "chefstyle", "= 1.5.9"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile("./Gemfile.local") if File.exist?("./Gemfile.local")

# These lines added for Windows development only.
# For FFI to call into PowerShell we need the binaries and assemblies located
# in the Ruby bindir.
# The Powershell DLL source lives here: https://github.com/chef/chef-powershell-shim
# Every merge into that repo triggers a Habitat build and promotion. Running
# the rake :update_chef_exec_dll task in this (chef/chef) repo will pull down
# the built packages and copy the binaries to distro/ruby_bin_folder.
#
# We copy (and overwrite) these files every time "bundle <exec|install>" is
# executed, just in case they have changed.
if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
  instance_eval do
    ruby_exe_dir = RbConfig::CONFIG["bindir"]
    assemblies = Dir.glob(File.expand_path("distro/ruby_bin_folder/#{ENV["PROCESSOR_ARCHITECTURE"]}", __dir__) + "**/*")
    FileUtils.cp_r assemblies, ruby_exe_dir, verbose: false unless ENV["_BUNDLER_WINDOWS_DLLS_COPIED"]
    ENV["_BUNDLER_WINDOWS_DLLS_COPIED"] = "1"
  end
end
