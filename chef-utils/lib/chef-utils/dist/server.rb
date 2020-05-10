module ChefUtils
  module Dist
    class Server
      # The name of the server product
      PRODUCT = "Cinc Server".freeze

      # Assumed location of the chef-server configuration directory
      # TODO: This actually sounds like a job for ChefUtils methods
      CONF_DIR = "/etc/cinc-server".freeze
    end
  end
end
