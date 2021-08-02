#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "waiver"

class Chef
  module Compliance
    class WaiverCollection < Array
      def from_file(cookbook, filename)
        self << Waiver.from_file(cookbook, filename)
      end

      def for_inspec
        select(&:enabled?).each_with_object([]) { |waiver, arry| arry << waiver.for_inspec }
      end

      def include_waiver(arg)
        (cookbook_name, waiver_name) = arg.split("::")
        waivers = nil

        if waiver_name.nil?
          waivers = select { |waiver| /^#{cookbook_name}$/.match?(waiver.cookbook_name) }
          if waivers.empty?
            raise "No inspec waivers found in cookbooks matching #{cookbook_name}"
          end
        else
          waivers = select { |waiver| /^#{cookbook_name}$/.match?(waiver.cookbook_name) && /^#{waiver_name}$/.match?(waiver.name) }
          if waivers.empty?
            raise "No inspec waivers matching #{waiver_name} found in cookbooks matching #{cookbook_name}"
          end
        end

        waivers.each(&:enable!)
      end
    end
  end
end
