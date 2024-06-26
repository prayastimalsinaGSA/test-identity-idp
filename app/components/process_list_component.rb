# frozen_string_literal: true

class ProcessListComponent < BaseComponent
  renders_many :items, ->(**kwargs, &block) do
    ProcessListItemComponent.new(heading_level:, **kwargs, &block)
  end

  attr_reader :heading_level, :big, :connected, :tag_options

  def initialize(heading_level: :h2, big: false, connected: false, **tag_options)
    @heading_level = heading_level
    @big = big
    @connected = connected
    @tag_options = tag_options
  end

  def css_class
    classes = ['usa-process-list', *tag_options[:class]]
    classes << 'usa-process-list--big' if big
    classes << 'usa-process-list--connected' if connected
    classes
  end

  class ProcessListItemComponent < BaseComponent
    attr_reader :heading_level, :heading, :heading_id

    def initialize(heading_level:, heading:, heading_id: nil)
      @heading_level = heading_level
      @heading = heading
      @heading_id = heading_id
    end

    def heading_options
      options = { class: 'usa-process-list__heading' }

      options[:id] = heading_id if heading_id.present?
      options
    end
  end
end
