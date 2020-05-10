module ChefUtils
  module Dist
    class Org
      # Main Website address
      WEBSITE = "https://cinc.sh".freeze

      # The downloads site
      DOWNLOADS_URL = "downloads.cinc.sh".freeze

      # The legacy conf folder: C:/opscode/chef. Specifically the "opscode" part
      # DIR_SUFFIX is appended to it in code where relevant
      LEGACY_CONF_DIR = "cincproject".freeze
    end
  end
end
