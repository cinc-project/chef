module ChefUtils
  module Dist
    class Workstation
      # The Workstation's product name
      PRODUCT = "Cinc Workstation".freeze

      # The old ChefDK product name
      DK = "CincDK".freeze

      # The suffix for workstation's eponymous folders, like /opt/workstation
      DIR_SUFFIX = "cinc-workstation".freeze

      # The suffix for ChefDK's eponymous folders, like /opt/chef-dk
      LEGACY_DIR_SUFFIX = "cinc-dk".freeze
    end
  end
end
