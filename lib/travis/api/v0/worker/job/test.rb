module Travis
  module Api
    module V0
      module Worker
        class Job
          class Test < Job
            include Formats

            def data
              {
                'type' => 'test',
                # TODO legacy. remove this once workers respond to a 'job' key
                'build' => job_data,
                'job' => job_data,
                'source' => build_data,
                'repository' => repository_data,
                'config' => job.decrypted_config,
                'queue' => job.queue,
                'uuid' => Travis.uuid,
                'ssh_keys' => ssh_keys,
                'env_vars' => env_vars
              }
            end

            def build_data
              {
                'id' => build.id,
                'number' => build.number
              }
            end

            def job_data
              data = {
                'id' => job.id,
                'number' => job.number,
                'commit' => commit.commit,
                'commit_range' => commit.range,
                'commit_message' => commit.message,
                'branch' => commit.branch,
                'ref' => commit.pull_request? ? commit.ref : nil,
                'state' => job.state.to_s,
                'secure_env_enabled' => build.secure_env_enabled?
              }
              data['tag'] = request.tag_name if include_tag_name?
              data['pull_request'] = commit.pull_request? ? commit.pull_request_number : false
              data
            end

            def repository_data
              {
                'id' => repository.id,
                'slug' => repository.slug,
                'github_id' => repository.github_id,
                'source_url' => repository.source_url,
                'api_url' => repository.api_url,
                'last_build_id' => repository.last_build_id,
                'last_build_number' => repository.last_build_number,
                'last_build_started_at' => format_date(repository.last_build_started_at),
                'last_build_finished_at' => format_date(repository.last_build_finished_at),
                'last_build_duration' => repository.last_build_duration,
                'last_build_state' => repository.last_build_state.to_s,
                'description' => repository.description
              }
            end

            def ssh_keys
              repository.settings.ssh_keys.map do |key|
                key.content.decrypt
              end
            end

            def env_vars
              vars = repository.settings.env_vars.map do |env_var|
                [env_var.name, env_var.value.decrypt]
              end

              Hash[*vars.flatten]
            end

            def include_tag_name?
              Travis.config.include_tag_name_in_worker_payload && request.tag_name.present?
            end
          end
        end
      end
    end
  end
end
