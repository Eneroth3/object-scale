# frozen_string_literal: true

module Eneroth
  module ObjectScale
    # Selection observer wrapper that re-attaches itself to new models.
    class SelectionObserverWrapper
      # Start listenig to selection changes.
      #
      # @yield when selection changes.
      def initialize(&callback)
        @callback = callback

        # Start by removing observers to prevent duplicates.
        remove_observer
        attach_observer
      end

      # Stop listening to selection changes.
      def release
        remove_observer
      end

      # @private
      # @api
      # Sketchup::SelectionObserver
      def onSelectionAdded(_selection, _entity)
        @callback.call
      end

      # @private
      # @api
      # Sketchup::SelectionObserver
      def onSelectionBulkChange(_selection)
        @callback.call
      end

      # @private
      # @api
      # Sketchup::SelectionObserver
      def onSelectionCleared(_selection)
        @callback.call
      end

      # @private
      # @api
      # Sketchup::SelectionObserver
      def onSelectionRemoved(_selection, _entity)
        @callback.call
      end

      # @private
      # @api
      # Sketchup::SelectionObserver
      def onSelectedRemoved(selection, entity)
        # Workaround for misspelled method name.
        onSelectionRemoved(selection, entity)
      end

      # @private
      # @api
      # Sketchup::AppObserver
      def onActivateModel(model)
        model.add_observer(self)
        model.selection.add_observer(self)
      end

      # @private
      # @api
      # Sketchup::AppObserver
      def onNewModel(model)
        model.add_observer(self)
        model.selection.add_observer(self)
      end

      # @private
      # @api
      # Sketchup::AppObserver
      def onOpenModel(model)
        model.add_observer(self)
        model.selection.add_observer(self)
      end

      private

      def remove_observer
        Sketchup.remove_observer(self)
        Sketchup.active_model.remove_observer(self)
        Sketchup.active_model.selection.remove_observer(self)
      end

      def attach_observer
        Sketchup.add_observer(self)
        Sketchup.active_model.add_observer(self)
        Sketchup.active_model.selection.add_observer(self)
      end
    end
  end
end
