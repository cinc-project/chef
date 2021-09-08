#
# Author:: Marc Paradise <marc@chef.io>
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

require_relative "../../spec_helper"
require "chef/secret_fetcher/hashi_vault"

describe Chef::SecretFetcher::HashiVault do
  let(:node) { {} }
  let(:run_context) { double("run_context", node: node) }

  context "when validating provided HashiVault configuration" do
    it "raises ConfigurationInvalid when the :auth_method is not valid" do
      fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :invalid, vault_addr: "https://vault.example.com" }, run_context)
      expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid, /:auth_method/)
    end

    it "raises ConfigurationInvalid when the vault_addr is not provided" do
      fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :iam_role, role_name: "example-role" }, run_context)
      expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
    end

    context "and using auth_method: :iam_role" do
      it "raises ConfigurationInvalid when the role_name is not provided" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :iam_role, vault_addr: "vault.example.com" }, run_context)
        expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      end

      it "obtains a token via AWS IAM auth to allow the gem to do its own validations when all required config is provided" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :iam_role, vault_addr: "vault.example.com", role_name: "example-role" }, run_context)
        allow(Aws::InstanceProfileCredentials).to receive(:new).and_return instance_double(Aws::InstanceProfileCredentials)
        auth_double = instance_double(Vault::Authenticate)
        expect(auth_double).to receive(:aws_iam)
        allow(Vault).to receive(:auth).and_return(auth_double)
        fetcher.validate!
      end
    end

    context "and using auth_method: :token" do
      it "raises ConfigurationInvalid when no token is provided" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :token, vault_addr: "vault.example.com" }, run_context)
        expect { fetcher.validate! }.to raise_error(Chef::Exceptions::Secret::ConfigurationInvalid)
      end

      it "authenticates using the token during validation when all configuration is correct" do
        fetcher = Chef::SecretFetcher::HashiVault.new( { auth_method: :token, token: "t.1234abcd", vault_addr: "vault.example.com" }, run_context)
        auth = instance_double(Vault::Authenticate)
        auth_double = instance_double(Vault::Authenticate)
        expect(auth_double).to receive(:token)
        allow(Vault).to receive(:auth).and_return(auth_double)
        fetcher.validate!
      end
    end
  end
end

