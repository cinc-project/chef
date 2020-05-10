module ChefUtils
  module Dist
    class Infra
      # When referencing a product directly, as in "Chef Infra"
      PRODUCT = "Cinc Client".freeze

      # The chef-main-wrapper executable name.
      EXEC = "cinc".freeze

      # The client's alias (chef-client)
      CLIENT = "cinc-client".freeze

      # A short name for the product
      SHORT = "cinc".freeze

      # The suffix for Chef's /etc/chef, /var/chef and C:\\Chef directories
      # "cinc" => /etc/cinc, /var/cinc, C:\\cinc
      DIR_SUFFIX = "cinc".freeze

      # The user's configuration directory
      USER_CONF_DIR = ".cinc".freeze

      # chef-shell executable
      SHELL = "cinc-shell".freeze

      # The chef-shell default configuration file
      SHELL_CONF = "cinc_shell.rb".freeze

      # chef-zero executable
      ZERO = "Cinc Zero".freeze

      # Chef-Solo's product name
      SOLO = "Cinc Solo".freeze

      # The chef-zero executable (local mode)
      ZEROEXEC = "cinc-zero".freeze

      # The chef-solo executable (legacy local mode)
      SOLOEXEC = "cinc-solo".freeze
    end
  end
end
