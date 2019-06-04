module ChefUtils
  # This class is not fully implemented, depending on it is not recommended!
  module Dist
    class Apply
      # The chef-apply product name
      PRODUCT = "Cinc Apply".freeze

      # The chef-apply binary
      EXEC = "cinc-apply".freeze
    end

    class Automate
      # name of the automate product
      PRODUCT = "Cinc Dashboard".freeze
    end

    class Infra
      # When referencing a product directly, like Chef (Now Chef Infra)
      PRODUCT = "Cinc Client".freeze

      # A short designation for the product, used in Windows event logs
      # and some nomenclature.
      SHORT = "cinc".freeze

      # The client's alias (chef-client)
      CLIENT = "cinc-client".freeze

      # The chef executable, as in `chef gem install` or `chef generate cookbook`
      EXEC = "cinc".freeze

      # The chef-shell executable
      SHELL = "cinc-shell".freeze

      # Configuration related constants
      # The chef-shell configuration file
      SHELL_CONF = "cinc_shell.rb".freeze

      # The user's configuration directory
      USER_CONF_DIR = ".cinc".freeze

      # The suffix for Chef's /etc/chef, /var/chef and C:\\Chef directories
      # "chef" => /etc/cinc, /var/cinc, C:\\cinc
      DIR_SUFFIX = "cinc".freeze
    end

    class Org
      # product Website address
      WEBSITE = "https://cinc.sh".freeze

      # The downloads site
      DOWNLOADS_URL = "downloads.cinc.sh".freeze

      # The legacy conf folder: C:/opscode/chef. Specifically the "opscode" part
      # DIR_SUFFIX is appended to it in code where relevant
      LEGACY_CONF_DIR = "cincproject".freeze

      # Enable forcing Chef EULA
      ENFORCE_LICENSE = false

      # product patents page
      PATENTS = "https://www.chef.io/patents".freeze

      # knife documentation page
      KNIFE_DOCS = "https://docs.chef.io/workstation/knife/".freeze
    end

    class Server
      # The name of the server product
      PRODUCT = "Cinc Server".freeze

      # The server's configuration directory
      CONF_DIR = "/etc/cinc-server".freeze

      # The servers's alias (chef-server)
      SERVER = "cinc-server".freeze

      # The server's configuration utility
      SERVER_CTL = "cinc-server-ctl".freeze
    end

    class Solo
      # Chef-Solo's product name
      PRODUCT = "Cinc Solo".freeze

      # The chef-solo executable (legacy local mode)
      EXEC = "cinc-solo".freeze
    end

    class Zero
      # chef-zero executable
      PRODUCT = "Cinc Zero".freeze

      # The chef-zero executable (local mode)
      EXEC = "cinc-zero".freeze
    end
  end
end
