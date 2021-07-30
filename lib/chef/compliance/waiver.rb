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

require "yaml"

class Chef
  module Compliance
    attr_accessor :enabled
    attr_accessor :cookbook

    class Waiver
      def initialize(data, cookbook)
        @data = data
        @cookbook = cookbook
        @enabled = false
      end

      def enabled?
        !!@enabled
      end

      def enable!
        @enabled = true
      end

      def disable!
        @enabled = false
      end

      def for_inspec; end

      def self.from_hash(hash, cookbook = nil)
        new(hash, cookbook)
      end

      def self.from_yaml(string, cookbook = nil)
        from_hash(YAML.load(string), cookbook)
      end

      def self.from_file(filename, cookbook)
        from_yaml(IO.read(filename), cookbook)
      end
    end
  end
end
