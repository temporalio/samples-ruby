require "json"

module Workflows
  # Ruby JSON module support for Active Model classes.
  module ActiveModelJSONSupport
    extend ActiveSupport::Concern
    include ActiveModel::Serializers::JSON

    included do
      def as_json(*)
        super.merge(::JSON.create_id => self.class.name)
      end

      def to_json(*args)
        as_json.to_json(*args)
      end

      def self.json_create(object)
        object = object.dup
        object.delete(::JSON.create_id)
        new(**object.symbolize_keys)
      end
    end
  end
end
