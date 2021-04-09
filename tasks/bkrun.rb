require "yaml"

namespace :bkrun do
  def create_tasks_from_expeditor_verification_pipeline
    spec = YAML.load_file(".expeditor/verify.pipeline.yml")
    spec["steps"].each do |step|

      if step.class == Hash && image = step.dig("expeditor", "executor", "docker", "image")
        image = image.split("/")[1]
        #os, rubyversion = image.split(":")
        test_group, component_name = nil
        step["commands"].each do |cmd|
          test_group ||= if cmd == "rake spec"
                         "spec"
                       elsif cmd =~ /rake spec:(.*)/
                         $1
                       else
                         nil
                       end
          component_name ||= cmd =~ /cd (.*)/ ? $1 :  nil
        end


        # We'll skip anything we can't find either a test group or comp onent name for.
        # This primarily affects windows integration/functional - they're not yet available here
        # (and when they are available, they must be run from a windows host)
        name = test_group || component_name
        next if name.nil?

        desc "Run via docker: #{step["label"].gsub(":ruby:", "ruby")}" #  ruby #{rubyversion} #{name} tests on #{os}"

        task "#{name}-#{image.gsub(":", "-")}" do
          docker_cfg = step["expeditor"]["executor"]["docker"]
          flags = ""
          if docker_cfg["privileged"]
            flags << " --privileged "
          end

          if docker_cfg["environment"]
            flags << "-e #{docker_cfg["environment"].join(",")}"
          end
          sh "docker run #{flags} --volume $(pwd):/workdir --workdir /workdir rubydistros/#{image} #{flags} sh -e -c '#{step["commands"].join(" && ")}'"
        end
      end
    end
  end
  create_tasks_from_expeditor_verification_pipeline
end

