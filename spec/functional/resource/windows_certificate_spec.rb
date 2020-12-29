# Author: Nimesh Patni (nimesh.patni@msystechnologies.com)
# Copyright:: Copyright (c) Chef Software Inc.
# License: Apache License, Version 2.0
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
require "chef/mixin/powershell_exec"
require "chef/resource/windows_certificate"

module WindowsCertificateHelper
  include Chef::Mixin::PowershellExec

  def create_store
    path = "Cert:\\LocalMachine\\" + store
    command = <<~EOC
      New-Item -Path #{path}
    EOC
    powershell_exec(command)
  end

  def delete_store
    path = "Cert:\\LocalMachine\\" + store
    command = <<~EOC
      Remove-Item -Path #{path} -Recurse
    EOC
    powershell_exec(command)
  end

  def certificate_count
    path = "Cert:\\LocalMachine\\" + store
    # Seems weird that we have to call dir twice right?
    # The powershell pki module cache the last dir in module session state
    # Issuing dir with a different arg (-Force) seems to refresh that state.
    command = <<~EOC
      dir #{path} -Force | Out-Null
      (dir #{path} | measure).Count
    EOC
    powershell_exec(command).result.to_i
  end
end

describe Chef::Resource::WindowsCertificate, :windows_only do
  include WindowsCertificateHelper

  let(:stdout) { StringIO.new }
  let(:password) { "P@ssw0rd!" }
  let(:store) { "Chef-Functional-Test" }
  let(:certificate_path) { File.expand_path(File.join(CHEF_SPEC_DATA, "windows_certificates")) }
  let(:cer_path) { File.join(certificate_path, "test.cer") }
  let(:base64_path) { File.join(certificate_path, "base64_test.cer") }
  let(:pem_path) { File.join(certificate_path, "test.pem") }
  let(:p7b_path) { File.join(certificate_path, "test.p7b") }
  let(:pfx_path) { File.join(certificate_path, "test.pfx") }
  let(:out_path) { File.join(certificate_path, "testout.pem") }
  let(:tests_thumbprint) { "e45a4a7ff731e143cf20b8bfb9c7c4edd5238bb3" }
  let(:other_cer_path) { File.join(certificate_path, "othertest.cer") }
  let(:others_thumbprint) { "6eae1deefaf59daf1a97c9ceeff39c98b3da38cb" }
  let(:p7b_thumbprint) { "f867e25b928061318ed2c36ca517681774b06260" }
  let(:p7b_nested_thumbprint) { "dc395eae6be5b69951b8b6e1090cfc33df30d2cd" }

  let(:resource) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    Chef::Resource::WindowsCertificate.new("ChefFunctionalTest", run_context).tap do |r|
      r.store_name = store
    end
  end

  before do
    # Bypass validation of the store name so we can use a fake test store.
    allow_any_instance_of(Chef::Mixin::ParamsValidate)
      .to receive(:_pv_equal_to)
      .with({store_name: store}, :store_name, anything)
      .and_return(true)

    create_store

    allow(Chef::Log).to receive(:info) do |msg|
      stdout.puts(msg)
    end
  end

  after { delete_store }

  it "starts with no certificates" do
    expect(certificate_count).to eq(0)
  end

  it "can add a certificate idempotently" do
    resource.source = cer_path
    resource.run_action(:create)

    expect(certificate_count).to eq(1)
    expect(resource).to be_updated_by_last_action

    # Adding the cert again should have no effect
    resource.run_action(:create)
    expect(certificate_count).to eq(1)
    expect(resource).not_to be_updated_by_last_action

    # Adding the cert again with a different format should have no effect
    resource.source = pem_path
    resource.run_action(:create)
    expect(certificate_count).to eq(1)
    expect(resource).not_to be_updated_by_last_action

    # Adding another cert should work correctly
    resource.source = other_cer_path
    resource.run_action(:create)

    expect(certificate_count).to eq(2)
    expect(resource).to be_updated_by_last_action
  end

  it "can add a base64 encoded certificate idempotently" do
    resource.source = base64_path
    resource.run_action(:create)

    expect(certificate_count).to eq(1)

    resource.run_action(:create)
    expect(certificate_count).to eq(1)
    expect(resource).not_to be_updated_by_last_action
  end

  it "can add a PEM certificate idempotently" do
    resource.source = pem_path
    resource.run_action(:create)

    expect(certificate_count).to eq(1)

    resource.run_action(:create)

    expect(certificate_count).to eq(1)
    expect(resource).not_to be_updated_by_last_action
  end

  it "can add a P7B certificate idempotently" do
    resource.source = p7b_path
    resource.run_action(:create)

    # A P7B cert includes nested certs (?)
    expect(certificate_count).to eq(3)

    resource.run_action(:create)

    expect(resource).not_to be_updated_by_last_action
    expect(certificate_count).to eq(3)
  end

  it "can add a PFX certificate idempotently with a valid password" do
    resource.source = pfx_path
    resource.pfx_password = password
    resource.run_action(:create)

    expect(certificate_count).to eq(1)

    resource.run_action(:create)
    expect(certificate_count).to eq(1)
    expect(resource).not_to be_updated_by_last_action
  end

  it "raises an error when adding a PFX certificate with an invalid password" do
    resource.source = pfx_path
    resource.pfx_password = "Invalid password"

    expect { resource.run_action(:create) }.to raise_error(OpenSSL::PKCS12::PKCS12Error)
  end

=begin
    allow(Chef::Log).to receive(:info) do |msg|
=end

  describe "action: verify" do
    context "When a certificate is not present" do
      before do
        resource.source = tests_thumbprint
        resource.run_action(:verify)
      end
      it "Initial check if certificate is not present" do
        expect(certificate_count).to eq(0)
      end
      it "Displays correct message" do
        expect(stdout.string.strip).to eq("Certificate not found")
      end
      it "Does not converge while verifying" do
        expect(resource).not_to be_updated_by_last_action
      end
    end

    context "When a certificate is present" do
      before do
        resource.source = cer_path
        resource.run_action(:create)
      end

      context "For a valid thumbprint" do
        before do
          resource.source = tests_thumbprint
          resource.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(certificate_count).to eq(1)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate is valid")
        end
        it "Does not converge while verifying" do
          expect(resource).not_to be_updated_by_last_action
        end
      end

      context "For an invalid thumbprint" do
        before do
          resource.source = others_thumbprint
          resource.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(certificate_count).to eq(1)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate not found")
        end
        it "Does not converge while verifying" do
          expect(resource).not_to be_updated_by_last_action
        end
      end
    end

    context "When multiple certificates are present" do
      before do
        resource.source = p7b_path
        resource.run_action(:create)
      end

      context "With main certificate's thumbprint" do
        before do
          resource.source = p7b_thumbprint
          resource.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(certificate_count).to eq(3)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate is valid")
        end
        it "Does not converge while verifying" do
          expect(resource).not_to be_updated_by_last_action
        end
      end

      context "With nested certificate's thumbprint" do
        before do
          resource.source = p7b_nested_thumbprint
          resource.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(certificate_count).to eq(3)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate is valid")
        end
        it "Does not converge while verifying" do
          expect(resource).not_to be_updated_by_last_action
        end
      end

      context "For an invalid thumbprint" do
        before do
          resource.source = others_thumbprint
          resource.run_action(:verify)
        end
        it "Initial check if certificate is present" do
          expect(certificate_count).to eq(3)
        end
        it "Displays correct message" do
          expect(stdout.string.strip).to eq("Certificate not found")
        end
        it "Does not converge while verifying" do
          expect(resource).not_to be_updated_by_last_action
        end
      end
    end
  end

  describe "action: fetch" do
    context "When a certificate is not present" do
      before do
        resource.source = tests_thumbprint
        resource.run_action(:fetch)
      end
      it "Initial check if certificate is not present" do
        expect(certificate_count).to eq(0)
      end
      it "Does not show any content" do
        expect(stdout.string.strip).to be_empty
      end
      it "Does not converge while fetching" do
        expect(resource).not_to be_updated_by_last_action
      end
    end

    context "When a certificate is present" do
      before do
        resource.source = cer_path
        resource.run_action(:create)
      end

      after do
        if File.exist?(out_path)
          File.delete(out_path)
        end
      end

      context "For a valid thumbprint" do
        before do
          resource.source = tests_thumbprint
          resource.cert_path = out_path
          resource.run_action(:fetch)
        end
        it "Initial check if certificate is present" do
          expect(certificate_count).to eq(1)
        end
        it "Stores Certificate content at given path" do
          expect(File.exist?(out_path)).to be_truthy
        end
        it "Does not converge while fetching" do
          expect(resource).not_to be_updated_by_last_action
        end
      end

      context "For an invalid thumbprint" do
        before do
          resource.source = others_thumbprint
          resource.cert_path = out_path
          resource.run_action(:fetch)
        end
        it "Initial check if certificate is present" do
          expect(certificate_count).to eq(1)
        end
        it "Does not show any content" do
          expect(stdout.string.strip).to be_empty
        end
        it "Does not store certificate content at given path" do
          expect(File.exist?(out_path)).to be_falsy
        end
        it "Does not converge while fetching" do
          expect(resource).not_to be_updated_by_last_action
        end
      end
    end
  end

  describe "action: delete" do
    context "When a certificate is not present" do
      before do
        resource.source = tests_thumbprint
        resource.run_action(:delete)
      end
      it "Initial check if certificate is not present" do
        expect(certificate_count).to eq(0)
      end
      it "Does not delete any certificate" do
        expect(stdout.string.strip).to be_empty
      end
    end

    context "When a certificate is present" do
      before do
        resource.source = cer_path
        resource.run_action(:create)
      end
      before { resource.source = tests_thumbprint }
      it "Initial check if certificate is present" do
        expect(certificate_count).to eq(1)
      end
      it "Deletes the certificate" do
        resource.run_action(:delete)
        expect(certificate_count).to eq(0)
      end
      it "Converges while deleting" do
        resource.run_action(:delete)
        expect(resource).to be_updated_by_last_action
      end
      it "Idempotent: Does not converge while deleting again" do
        resource.run_action(:delete)
        resource.run_action(:delete)
        expect(certificate_count).to eq(0)
        expect(resource).not_to be_updated_by_last_action
      end
      it "Deletes the valid certificate" do
        # Add another certificate"
        resource.source = other_cer_path
        resource.run_action(:create)
        expect(certificate_count).to eq(2)

        # Delete previously added certificate
        resource.source = tests_thumbprint
        resource.run_action(:delete)
        expect(certificate_count).to eq(1)

        # Verify another certificate still exists
        resource.source = others_thumbprint
        resource.run_action(:verify)
        expect(stdout.string.strip).to eq("Certificate is valid")
      end
    end
  end
end
