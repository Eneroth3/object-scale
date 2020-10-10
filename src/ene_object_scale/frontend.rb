# frozen_string_literal: true

module Eneroth
  module ObjectScale
    Sketchup.require "#{PLUGIN_ROOT}/vendor/scale"
    Sketchup.require "#{PLUGIN_ROOT}/selection_observer_wrapper"

    module Frontend
      # Message for invalid selection.
      INVALID_SEL = "No groups or components selected"

      # Name of operation.
      OP_NAME = "Scale Objects"

      # Show dialog.
      def self.show
        if visible?
          @dialog.bring_to_front
        else
          create_dialog unless @dialog
          @dialog.set_file("#{PLUGIN_ROOT}/dialog.html")
          attach_callbacks
          @dialog.show
        end
        @observer = SelectionObserverWrapper.new { on_selection_change }
      end

      # Hide dialog.
      def self.hide
        @dialog.close
      end

      # Check whether dialog is visible.
      #
      # @return [Boolean]
      def self.visible?
        @dialog && @dialog.visible?
      end

      # Toggle visibility of dialog.
      def self.toggle
        visible? ? hide : show
      end

      # Get SketchUp UI command state for dialog visibility state.
      #
      # @return [MF_CHECKED, MF_UNCHECKED]
      def self.command_state
        visible? ? MF_CHECKED : MF_UNCHECKED
      end

      # @api
      # Expected to be called when the selection changes.
      def self.on_selection_change
        scale = ObjectScale.scale
        # Format scale, e.g. 0.01149425287356322 to 1:87.
        scale = Scale.new(scale) if scale
        @dialog.execute_script("updateFields('#{scale}');")

        return unless ObjectScale.selected_instances.empty?

        @dialog.execute_script("displayMessage(#{INVALID_SEL.inspect});")
      end

      # Private

      def self.attach_callbacks
        @dialog.add_action_callback("ready") { on_selection_change }
        @dialog.add_action_callback("onChange") do |_, scale|
          on_change(scale)
        end
        @dialog.set_on_closed { @observer.release }
      end
      private_class_method :attach_callbacks

      def self.create_dialog
        @dialog = UI::HtmlDialog.new(
          dialog_title:    EXTENSION.name,
          preferences_key: name, # Full module name
          resizable:       false,
          width:           230,
          height:          140,
          left:            200,
          top:             100
        )
      end
      private_class_method :create_dialog

      def self.on_change(scale)
        scale = Scale.new(scale)
        if scale.valid?
          @scale = scale
          @dialog.execute_script("markAsValid(scaleField);")
        else
          @dialog.execute_script("markAsInvalid(scaleField);")
          return
        end

        Sketchup.active_model.start_operation(OP_NAME, true)
        ObjectScale.scale = scale.factor
        Sketchup.active_model.commit_operation
      end
      private_class_method :on_change
    end
  end
end
