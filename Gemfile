source "https://rubygems.org"

gem "chef", path: "."

gem "ohai", git: "https://github.com/chef/ohai.git", branch: "18-stable"

# Nwed to file a bug with rest-client. In the meantime, we can use this until they accept the update.
gem "rest-client", git: "https://github.com/chef/rest-client", branch: "jfm/ucrt_update1"

gem "ffi", ">= 1.15.5", "<= 1.18.0"
# CVE-2026-27820 (CVSS 9.8): buffer overflow in Zlib::GzipReader / zstream_buffer_ungets.
# Versions <= 3.0.0, 3.1.0-3.1.1, and 3.2.0-3.2.1 are affected. Fixed in 3.2.3.
gem "zlib", ">= 3.2.3"
# CVE-2026-41316 (CVSS 8.1): ERB @_init deserialization guard bypass via def_method/def_module/def_class.
# Versions <= 6.0.3 are affected. Fixed in 4.0.3.1, 4.0.4.1, 6.0.1.1, and 6.0.4.
gem "erb", ">= 4.0.4.1"
# CVE-2026-85396 (GHSA-47m2-wp7j-p9vc): rubyzip path traversal.
# Versions < 3.4.0 are affected. Fixed in 3.4.0.
gem "rubyzip", ">= 3.4"
# GHSA-qq38-m9mg-xjj5 and six more: addressable URI and template advisories.
# Fixed in 2.9.1; 2.9.2 also fixes 2.9.1's IDNA slowdown.
gem "addressable", ">= 2.9.2"
# GHSA-cx24-f932-rr55: rubyntlm NTLMv2 verification bypass. Fixed in 0.6.6;
# 0.6.6 and 0.6.7 shipped broken, so 0.6.8 is the floor.
gem "rubyntlm", ">= 0.6.8"
# GHSA-vxj5-fg65-x765 and six more: net-ssh host-certificate, ProxyCommand,
# agent-forwarding and DoS advisories. Fixed in 7.3.5 (the first in 7.3.4).
# 7.3.8 completes 7.3.5's ProxyJump fix (GHSA-g2r2-x3p2-5677).
gem "net-ssh", ">= 7.3.8"
# GHSA-5v64-555j-wjxm and three more: rack multipart, Host header and
# Rack::Static advisories. Fixed in 3.2.8.
gem "rack", ">= 3.2.8"
gem "chef-utils", path: File.expand_path("chef-utils", __dir__) if File.exist?(File.expand_path("chef-utils", __dir__))
gem "chef-config", path: File.expand_path("chef-config", __dir__) if File.exist?(File.expand_path("chef-config", __dir__))

# required for FIPS or bundler will pick up default openssl
install_if -> { RUBY_PLATFORM !~ /darwin/ } do
  gem "openssl", "= 3.3.3"
end

if File.exist?(File.expand_path("chef-bin", __dir__))
  # bundling in a git checkout
  gem "chef-bin", path: File.expand_path("chef-bin", __dir__)
else
  # bundling in omnibus
  gem "chef-bin" # rubocop:disable Bundler/DuplicatedGem
end

gem "cheffish", ">= 17"

group(:omnibus_package) do
  gem "appbundler"
  gem "rb-readline"
  gem "chef-vault"

  gem "cinc-auditor-core-bin", ">= 5", "< 6",
    source: "https://rubygems.cinc.sh"

  gem "chef-zero", source: "https://rubygems.cinc.sh"
end

group(:omnibus_package, :pry) do
  # Locked because pry-byebug is broken with 13+.
  # some work is ongoing? https://github.com/deivid-rodriguez/pry-byebug/issues/343
  gem "pry", "0.15.2"
  # byebug does not install on freebsd on ruby 3.0; byebug >= 12 requires ruby >= 3.1
  # which is incompatible with the AIX omnibus toolchain (ruby 3.0.3)
  unless RUBY_PLATFORM.match?(/freebsd|aix/i)
    gem "byebug", "< 13"
    gem "pry-byebug", "< 3.12"
  end
  gem "pry-stack_explorer"
end

# Everything except AIX and Windows
group(:ruby_shadow) do
  install_if -> { RUBY_PLATFORM.match?(/linux|darwin|bsd|solaris/i) } do
    # if ruby-shadow does a release that supports ruby-3.0 this can be removed
    gem "ruby-shadow", git: "https://github.com/chef/ruby-shadow", branch: "lcg/ruby-3.0", platforms: :ruby
  end
end

# deps that cannot be put in the knife gem because they require a compiler and fail on windows nodes
group(:knife_windows_deps) do
  gem "ed25519", "~> 1.2" # ed25519 ssh key support
end

group(:development, :test) do
  gem "rake", ">= 12.3.3"
  gem "rspec"
  gem "webmock"
  gem "crack", "< 1.0.2" # due to https://github.com/jnunemaker/crack/pull/75
  gem "fauxhai-ng" # for chef-utils gem
end

gem "cookstyle", "~> 8.6"

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
#
# But doing eval_gemfile("./Gemfile.local") breaks dependabot, so a
# bit of indirection here
local_gemfile = File.join(__dir__, "Gemfile.local")
eval(File.read(local_gemfile)) if File.exist?(local_gemfile)
