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
    class Waiver
      attr_accessor :enabled
      attr_accessor :cookbook_name
      attr_accessor :path

      def initialize(data, path, cookbook_name)
        @data = data
        @cookbook_name = cookbook_name
        @path = path
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

      def for_inspec
        path
      end

      def self.from_hash(hash, path, cookbook_name = nil)
        new(hash, path, cookbook_name)
      end

      def self.from_yaml(string, path, cookbook_name = nil)
        from_hash(YAML.load(string), path, cookbook_name)
      end

      def self.from_file(filename, cookbook_name = nil)
        from_yaml(IO.read(filename), filename, cookbook_name)
      end
    end
  end
end
