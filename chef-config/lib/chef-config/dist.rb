module ChefConfig
  class Dist
    # The chef executable name.
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

    # The legacy conf folder: C:/opscode/chef. Specifically the "opscode" part
    # DIR_SUFFIX is appended to it in code where relevant
    LEGACY_CONF_DIR = "cincproject".freeze

    # Enable forcing Chef EULA
    ENFORCE_LICENSE = false

    # The servers's alias (chef-server)
    SERVER = "cinc-server".freeze

    # The server's configuration utility
    SERVER_CTL = "cinc-server-ctl".freeze
  end
end
