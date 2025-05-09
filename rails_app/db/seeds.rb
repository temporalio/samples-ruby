# Seed some products
Product.insert_all([
  { sku: '1234', name: 'Scooter', price: '150.99' },
  { sku: '2345', name: 'TV', price: '825.49' }
], unique_by: :sku)
