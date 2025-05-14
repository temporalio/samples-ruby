
require_relative "active_model_json_support"

module Workflows
  # Models accepted/returned from the shopping cart workflow.
  module Models
    class ShoppingCart
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModelJSONSupport

      # @!attribute amount
      #   @return [Array<ShoppingCartEntry>]
      attribute :entries, default: -> { [] }
      attribute :complete, :boolean, default: false
    end

    class ShoppingCartEntry
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModelJSONSupport

      attribute :id, :integer
      # @!attribute product
      #   @return [DatabaseProduct]
      attribute :product
      attribute :quantity, :integer
    end

    class DatabaseProduct
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModelJSONSupport

      attribute :id, :integer
      attribute :sku, :string
      attribute :name, :string
      attribute :price, :decimal

      def self.from_record(product)
        new(product.attributes.slice("id", "sku", "name", "price"))
      end
    end

    class CompletedOrder
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModelJSONSupport

      attribute :id, :string
      # @!attribute cart
      #   @return [ShoppingCart]
      attribute :cart
      attribute :payment_id, :string
      attribute :payment_capture_id, :string
    end
  end
end
