require "lookbook/markdown"
require "lookbook/theme"
require "lookbook/store"

module Lookbook
  class Config
    def initialize
      @options = Store.new
      foobar = "bax"
      @options.set({
        project_name: "Lookbook",
        log_level: 2,
        auto_refresh: true,

        components_path: "app/components",
        
        page_controller: "Lookbook::PageController",
        page_route: "pages",
        page_paths: ["test/components/docs"],
        page_options: {},
        markdown_options: Markdown::DEFAULT_OPTIONS,

        preview_paths: [],
        preview_display_params: {},
        preview_options: {},
        preview_srcdoc: false,
        sort_examples: true,

        listen: Rails.env.development?,
        listen_paths: [],
        listen_use_polling: false,

        cable_mount_path: "/lookbook-cable",
        cable_logger: Lookbook.logger,

        runtime_parsing: !Rails.env.production?,
        parser_registry_path: "tmp/storage/.yardoc",

        ui_theme: "indigo",
        ui_theme_overrides: {},

        hooks: {
          after_initialize: [],
          before_exit: [],
          after_change: [],
        },

        experimental_features: false,

        inspector_panels: {
          preview: {
            pane: :main,
            position: 1,
            partial: "lookbook/previews/panels/preview",
            hotkey: "v",
            panel_classes: "overflow-hidden",
            padded: false
          },
          output: {
            pane: :main,
            position: 2,
            partial: "lookbook/previews/panels/output",
            label: "HTML",
            hotkey: "h",
            padded: false
          },
          source: {
            pane: :drawer,
            position: 1,
            partial: "lookbook/previews/panels/source",
            label: "Source",
            hotkey: "s",
            copy: ->(data) { data.examples.map { |e| e.source }.join("\n") },
            padded: false
          },
          notes: {
            pane: :drawer,
            position: 2,
            partial: "lookbook/previews/panels/notes",
            label: "Notes",
            hotkey: "n",
            disabled: ->(data) { data.examples.select { |e| e.notes.present? }.none? },
            padded: false
          },
          params: {
            pane: :drawer,
            position: 3,
            partial: "lookbook/previews/panels/params",
            label: "Params",
            hotkey: "p",
            disabled: ->(data) { data.preview.params.none? },
            padded: false
          }
        },

        inspector_panel_defaults: {
          id: ->(data) { "inspector-panel-#{data.name}" },
          partial: "lookbook/previews/panels/content",
          content: nil,
          label: ->(data) { data.name.titleize },
          pane: :drawer,
          position: ->(data) { data.index_position },
          hotkey: nil,
          disabled: false,
          show: true,
          copy: nil,
          panel_classes: nil,
          locals: {},
          padded: true
        },
      })
    end

    def inspector_panels(&block)
      if block_given?
        yield get(:inspector_panels)
      else
        get(:inspector_panels)
      end
    end

    def define_inspector_panel(name, opts = {})
      inspector_panels[name] = opts
      if opts[:position].present?
        pane = inspector_panels[name].pane.presence || :drawer
        siblings = inspector_panels.select do |key, panel|
          panel.pane == pane && key != name.to_sym
        end
        siblings.each do |key, panel|
          if panel.position >= opts[:position]
            panel.position += 1
          end
        end
      end
    end

    def amend_inspector_panel(name, opts = {})
      if opts == false
        inspector_panels[name] = false
      else
        inspector_panels[name].merge!(opts)
      end
    end

    def remove_inspector_panel(name)
      amend_inspector_panel(name, false)
    end

    def ui_theme=(name)
      name = name.to_s
      if Theme.valid_theme?(name)
        @options[:ui_theme] = name
      else
        Lookbook.logger.warn "'#{name}' is not a valid Lookbook theme. Theme setting not changed."
      end
    end

    def ui_theme_overrides(&block)
      if block_given?
        yield get(:ui_theme_overrides)
      else
        get(:ui_theme_overrides)
      end
    end

    def [](key)
      get(key.to_sym)
    end

    def []=(key, value)
      @options[key.to_sym] = value
    end

    def to_h
      @options.to_h
    end

    def to_json(*a)
      to_h.to_json(*a)
    end
    
    protected

    def get_inspector_panels(panels)
      panels.select! { |key, panel| panel }
      panels
    end

    def get_project_name(name)
      name == false ? nil : name
    end

    def get_components_path(path)
      absolute_path(path)
    end

    def normalize_paths(paths)
      paths.map! { |path| absolute_path(path) }
      paths.select! { |path| Dir.exist?(path) }
      paths
    end

    def absolute_path(path)
      File.absolute_path(path.to_s, Rails.root)
    end

    alias_method :get_page_paths, :normalize_paths
    alias_method :get_preview_paths, :normalize_paths
    alias_method :get_listen_paths, :normalize_paths
    alias_method :get_parser_registry_path, :absolute_path

    def get(name)
      getter_name = "get_#{name}".to_sym
      respond_to?(getter_name, true) ? send(getter_name, @options[name]) : @options[name]
    end

    def set(name, *args)
      @options.send(name, *args)
    end

    def method_missing(name, *args)
      args.any? ? set(name, *args) : get(name)
    end
  end
end