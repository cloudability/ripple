require 'ripple/conflict/basic_resolver'

module Ripple
  module Conflict
    class Resolver
      include Translation

      attr_reader :document, :model_class

      delegate :expected_conflicts, :on_conflict_block, :to => :model_class

      def initialize(robject, model_class)
        @robject = robject
        @model_class = model_class
      end

      def resolve
        basic_resolver.perform
        assert_no_unexpected_conflicts
        document.instance_exec(siblings, basic_resolver.remaining_conflicts, &on_conflict_block)
        document.save!
      end

      def siblings
        @siblings ||= @robject.siblings.map { |s| @model_class.send(:instantiate, s) }
      end

      def document
        # pick a sibling robject to use as the basis of the document to resolve
        # which one doesn't really matter.
        @document ||= @model_class.send(:instantiate, @robject.siblings.first.dup)
      end

      private

      def basic_resolver
        @basic_resolver ||= BasicResolver.new(self)
      end

      def assert_no_unexpected_conflicts
        return unless basic_resolver.unexpected_conflicts.any?

        raise NotImplementedError, t('unexpected_conflicts',
          :conflicts => basic_resolver.unexpected_conflicts.inspect,
          :document  => document.inspect
        )
      end
    end
  end
end

