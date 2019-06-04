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
  end
end
