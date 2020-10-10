# frozen_string_literal: true

module Eneroth
  module ObjectScale
    Sketchup.require "#{PLUGIN_ROOT}/frontend"
    Sketchup.require "#{PLUGIN_ROOT}/transformation"

    # Get scale from selected instances.
    #
    # @return [Float, nil]
    #  `nil` when instances have different scales.
    def self.scale
      scales = selected_instances.map do |instance|
        Transformation.extract_scaling(instance.transformation, instance.definition.bounds)
      end

      # Convert to Length to borrow SU's precision when comparing.
      scales = unique_values(scales) { |a, b| a.to_l == b }

      scales.size == 1 ? scales.first : nil
    end

    # Set scale for selected instances.
    #
    # @param scale [Float]
    def self.scale=(scale)
      selected_instances.each do |instance|
        instance.transformation = Transformation.apply_scaling(instance.transformation, scale)
      end
    end

    # Get instances (groups and components) selected in the model.
    #
    # @return [Array<Sketchup::Group, Sketchup::ComponentInstance>]
    def self.selected_instances
      Sketchup.active_model.selection.select do |entity|
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end
    end

    # Create array of unique objects, using custom comparison for uniqueness.
    #
    # @param array [Array]
    #
    # @yieldparam value1 [Object]
    # @yieldparam value2 [Object]
    # @yieldreturn [Boolean]
    #   Whether `value1` and `value2` are the same.
    #
    # @return [Array]
    def self.unique_values(array)
      new_array = [array.shift]
      array.each do |value|
        match = new_array.find { |other| yield(value, other) }
        new_array << [value] unless match
      end

      new_array
    end

    # Reload extension.
    #
    # @param clear_console [Boolean] Whether console should be cleared.
    # @param undo [Boolean] Whether last oration should be undone.
    #
    # @return [void]
    def self.reload(clear_console = true, undo = false)
      # Hide warnings for already defined constants.
      verbose = $VERBOSE
      $VERBOSE = nil
      Dir.glob(File.join(PLUGIN_ROOT, "**/*.{rb,rbe}")).each { |f| load(f) }
      $VERBOSE = verbose

      # Use a timer to make call to method itself register to console.
      # Otherwise the user cannot use up arrow to repeat command.
      UI.start_timer(0) { SKETCHUP_CONSOLE.clear } if clear_console

      Sketchup.undo if undo

      nil
    end

    unless @loaded
      @loaded = true

      cmd = UI::Command.new(EXTENSION.name) { Frontend.toggle }
      cmd.set_validation_proc { Frontend.command_state }

      UI.menu("Plugins").add_item(cmd)
    end
  end
end
