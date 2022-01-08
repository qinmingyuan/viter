# frozen_string_literal: true

# Public: Allows to render HTML tags for scripts and styles processed by Vite.

module Vite
  module ApplicationHelper

    def image_vite_tag(name, **options)
      if vite_manifest.exist?
        r = compute_manifest_name(name, type: :image)
        mani = vite_manifest.find(r)
        if mani
          image_tag("/#{mani['assets'][0]}", **options)
        end
      else
        image_tag(name, **options)
      end
    end

    # Public: Resolves the path for the specified Vite asset.
    #
    # Example:
    #   <%= vite_asset_path 'calendar.css' %> # => "/vite/assets/calendar-1016838bab065ae1e122.css"
    def asset_vite_path(name, **options)
      asset_path name, options
    end

    def image_vite_path(name, **options)
      if vite_manifest.exist?
        r = compute_manifest_name(name, type: :image)
        mani = vite_manifest.find(r)
        if mani
          image_path("/#{mani['assets'][0]}", **options)
        end
      else
        image_path(name, options)
      end
    end

    # Public: Renders a <script> tag for the specified Vite entrypoints.
    def javascript_vite_tag(*names, type: 'module', crossorigin: 'anonymous', **options)
      if vite_manifest.exist?
        entries = names.map do |name|
          r = compute_manifest_name(name)
          mani = vite_manifest.find(r)
          if mani
            "/#{mani['file']}"
          end
        end.compact
      else
        entries = names
        options[:host] = RailsVite.instance.config.host
      end

      if entries.blank?
        logger.debug "Names: #{names}"
      else
        javascript_include_tag(*entries, crossorigin: crossorigin, type: type, **options)
      end
    end

    # Public: Renders a <link> tag for the specified Vite entrypoints.
    def stylesheet_vite_tag(*names, **options)
      if vite_manifest.exist?
        entries = names.map do |name|
          r = compute_manifest_name(name)
          mani = vite_manifest.find(r)
          if mani
            csses = []
            csses += mani.fetch('css', []).map(&->(i){ "/#{i}" })
            mani.fetch('imports', []).map(&->(i){
              csses += vite_manifest.find_css(i)
            })
            csses
          end
        end.flatten.compact

        stylesheet_link_tag(*entries, **options)
      end
    end

    def vite_manifest
      RailsVite.instance.manifest
    end

    ASSET_PREFIXES = {
      image: '../assets/'
    }
    def compute_manifest_name(name, type: :javascript, extname: nil)
      r = compute_asset_path(name, type: type)
      r.delete_prefix!('/')
      extname = compute_asset_extname(name, type: type, extname: extname)
      prefix = ASSET_PREFIXES[type] || ''

      "#{prefix}#{r}#{extname}"
    end

    def compute_manifest_path(name, type: , extname: )
      if vite_manifest.exist?
        r = compute_manifest_name(name, type: type, extname: extname)
        mani = vite_manifest.find(r)
        if mani
          "/#{mani['assets'][0]}"
        end
      else
        name
      end
    end

    # Internal: Renders a modulepreload link tag.
    def vite_preload_tag(*sources, crossorigin:, **options)
      sources.map { |source|
        href = path_to_asset(source)
        try(:request).try(:send_early_hints, 'Link' => %(<#{ href }>; rel=modulepreload; as=script; crossorigin=#{ crossorigin }))
        tag.link(rel: 'modulepreload', href: href, as: 'script', crossorigin: crossorigin, **options)
      }.join("\n").html_safe
    end

  end
end
