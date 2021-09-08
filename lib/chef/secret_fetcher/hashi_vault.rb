#
# Author:: Marc Paradise (<marc@chef.io>)
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

require_relative "base"
require "aws-sdk-core" # Support for aws instance profile auth
require "vault"
class Chef
  class SecretFetcher
    # == Chef::SecretFetcher::HashiVault
    # A fetcher that fetches a secret from Hashi Vault.
    #
    # Does not yet support fetching with version when a versioned key store is in use.
    # In this initial iteration the only supported authentication is IAM role-based
    #
    # Required config:
    # :auth_method - one of :iam_role, :token.  default: :iam_role
    # :vault_addr - the address of a running Vault instance, eg https://vault.example.com:8200
    #
    # For `:token` auth: `:token` - a Vault token valid for authentication.
    #
    # For `:iam_role`:  `:role_name` - the name of the role in Vault that was created
    # to support authentication via IAM.  See the Vault documentation for details[1].
    # A Terraform example is also available[2]
    #
    #
    # [1] https://www.vaultproject.io/docs/auth/aws#recommended-vault-iam-policy
    # [2] https://registry.terraform.io/modules/hashicorp/vault/aws/latest/examples/vault-iam-auth
    #             an IAM principal ARN bound to it.
    #
    # Optional config
    # :namespace - the namespace under which secrets are kept.  Only supported in with Vault Enterprise
    #
    # @example
    #
    # fetcher = SecretFetcher.for_service(:hashi_vault, { role_name: "testing-role", vault_addr: https://localhost:8200}, run_context )
    # fetcher.fetch("secretkey1")
    #
    # @example
    #
    # fetcher = SecretFetcher.for_service(:hashi_vault, { auth_method: :token, token: "s.1234abcdef", vault_addr: https://localhost:8200}, run_context )
    # fetcher.fetch("secretkey1")
    SUPPORTED_AUTH_TYPES = %i{iam_role token}.freeze
    class HashiVault < Base

      # Validate and authenticate the current session using the configurated auth strategy and parameters
      def validate!
        if config[:vault_addr].nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("You must provide the Vault address in the configuration as :vault_addr")
        end

        Vault.address = config[:vault_addr]
        Vault.namespace = config[:namespace] unless config[:namespace].nil?

        case config[:auth_method]
        when :token
          validate_token_auth!(config[:token])
        when :iam_role, nil
          validate_iam_role_auth!(config[:role_name])
        else
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("Invalid :auth_method provided.  You gave #{config[:auth_method]}, expected one of :#{SUPPORTED_AUTH_TYPES.join(", :")} ")
        end
      end

      # Validates IAM role auth configuration and obtains token via IAM auth
      #
      # @param role_name [String] the name of the Vault role associated with the IAM profile .
      def validate_iam_role_auth!(role_name)
        if role_name.nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("You must provide the authenticating Vault role name in the configuration as :role_name")
        end

        Vault.auth.aws_iam(role_name, Aws::InstanceProfileCredentials.new)
      end

      # Validates that a token is provided and authenticates to Hashi Vault using the provided
      # token.
      # @param token [String] a value Vault token authorized to access the secrets needed. b
      def validate_token_auth!(token)
        if token.nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("You must provide the token in the configuration as :token")
        end

        Vault.auth.token(token)
      end

      # @param identifier [String] Identifier of the secret to be fetched, which should
      # be the full path of that secret, eg 'secret/example'
      # @param _version [String] not used in this implementation
      # @return [Hash] containing key/value pairs stored at the location given in 'identifier'
      def do_fetch(identifier, _version)
        Vault.logical.read(identifier).data
      end
    end
  end
end

