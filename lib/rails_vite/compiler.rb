require 'open3'
require 'digest/sha1'

module RailsVite
  class RailsVite::Compiler

    # Additional environment variables that the compiler is being run with
    # RailsVite::Compiler.env['FRONTEND_API_KEY'] = 'your_secret_key'
    cattr_accessor(:env) { {} }

    delegate :config, :logger, to: :rails_vite
    attr_reader :rails_vite

    def initialize(rails_vite)
      @rails_vite = rails_vite
    end

    def compile
      if true #stale?
        run_vite.tap do |success|
          #record_compilation_digest
        end
      else
        true
      end
    end

    # Returns true if all the compiled packs are up to date with the underlying asset files.
    def fresh?
      last_compilation_digest&.== watched_files_digest
    end

    # Returns true if the compiled packs are out of date with the underlying asset files.
    def stale?
      !fresh?
    end

    private
    def last_compilation_digest
      compilation_digest_path.read if compilation_digest_path.exist? && config.public_manifest_path.exist?
    rescue Errno::ENOENT, Errno::ENOTDIR
    end

    def watched_files_digest
      warn "Webpacker::Compiler.watched_paths has been deprecated. Set additional_paths in rails_vite.yml instead." unless watched_paths.empty?
      Dir.chdir File.expand_path(config.root_path) do
        files = Dir[*default_watched_paths, *watched_paths].reject { |f| File.directory?(f) }
        file_ids = files.sort.map { |f| "#{File.basename(f)}/#{Digest::SHA1.file(f).hexdigest}" }
        Digest::SHA1.hexdigest(file_ids.join("/"))
      end
    end

    def record_compilation_digest
      config.cache_path.mkpath
      compilation_digest_path.write(watched_files_digest)
    end

    def ruby_runner
      bin_webpack_path = config.root_path.join('bin/vite')
      first_line = File.readlines(bin_webpack_path).first.chomp
      /ruby/.match?(first_line) ? RbConfig.ruby : ''
    end

    def run_vite
      logger.info 'RailsVite Compiling...'

      stdout, stderr, status = Open3.capture3(
        vite_env,
        "#{ruby_runner} ./bin/vite build",
        chdir: File.expand_path(config.root_path)
      )

      if status.success?
        logger.info "Compiled all packs in #{config.root_path}"
        logger.error "#{stderr}" unless stderr.empty?
        logger.info stdout
      else
        non_empty_streams = [stdout, stderr].delete_if(&:empty?)
        logger.error "Compilation failed:\n#{non_empty_streams.join("\n\n")}"
      end

      status.success?
    end

    def default_watched_paths
      [
        *config.additional_paths,
        "#{config.source_path}/**/*",
        'yarn.lock',
        'package.json',
        'config/vite/**/*'
      ].freeze
    end

    def compilation_digest_path
      config.cache_path.join("last-compilation-digest-#{rails_vite.env}")
    end

    def vite_env
      return env unless defined?(ActionController::Base)

      env.merge(
        'VITER_ASSET_HOST' => ENV.fetch('VITER_ASSET_HOST', ActionController::Base.helpers.compute_asset_host),
        'VITER_RELATIVE_URL_ROOT' => ENV.fetch('VITER_RELATIVE_URL_ROOT', ActionController::Base.relative_url_root),
        'VITER_CONFIG' => rails_vite.config_path.to_s
      )
    end

  end
end
