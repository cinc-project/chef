#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

require "spec_helper"

describe Chef::Resource::MacosUserDefaults do

  let(:resource) { Chef::Resource::MacosUserDefaults.new("foo") }

  it "has a resource name of :macos_userdefaults" do
    expect(resource.resource_name).to eql(:macos_userdefaults)
  end

  it "has a default action of install" do
    expect(resource.action).to eql([:write])
  end

  [true, "TRUE", "1", "true", "YES", "yes"].each do |val|
    it "coerces value property from #{val} to 1" do
      resource.value val
      expect(resource.value).to eql(1)
    end
  end

  [false, "FALSE", "0", "false", "NO", "no"].each do |val|
    it "coerces value property from #{val} to 0" do
      resource.value val
      expect(resource.value).to eql(0)
    end
  end
end
