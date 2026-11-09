// MongoDB document model for the NaijaMart product catalogue.
// STATUS: DESIGN ONLY. This script was NOT executed when this portfolio was prepared,
// because no MongoDB server was available. Run it yourself in mongosh and save your own
// screenshots to evidence/ before submitting, and fix anything that does not run.

// Why documents here: products in different categories have different attributes
// (phones have RAM/storage, shoes have sizes). In SQL this needs many nullable columns or an
// EAV table; a document can hold exactly the attributes each product has.

db.products.insertMany([
  {
    _id: 777, name: "Galaxy A15", category: "Phones", price: 185000, stock_qty: 40,
    attributes: { brand: "Samsung", ram_gb: 6, storage_gb: 128, colours: ["black", "blue"] },
    tags: ["android", "smartphone"]
  },
  {
    _id: 42, name: "Running Shoes X", category: "Sports", price: 32000, stock_qty: 120,
    attributes: { brand: "Nova", sizes: [40, 41, 42, 43], material: "mesh" },
    tags: ["shoes", "running"]
  }
]);

// Orders embed their lines (read together, written together). unit_price is a copy at time of sale,
// as in the relational design. Product name is copied too so old orders still read correctly.
db.orders.insertOne({
  _id: 100001, customer_id: 1234, status: "PAID", order_date: new Date(),
  items: [
    { product_id: 777, name: "Galaxy A15", quantity: 1, unit_price: 185000 },
    { product_id: 42,  name: "Running Shoes X", quantity: 2, unit_price: 32000 }
  ],
  payment: { method: "CARD", status: "SUCCESS", amount: 249000 }
});

// Indexes
db.products.createIndex({ category: 1, price: 1 });
db.products.createIndex({ "attributes.brand": 1 });
db.orders.createIndex({ customer_id: 1, order_date: -1 });

// Example queries
db.products.find({ category: "Phones", "attributes.ram_gb": { $gte: 6 } });
db.orders.find({ customer_id: 1234 }).sort({ order_date: -1 });
db.orders.aggregate([
  { $unwind: "$items" },
  { $group: { _id: "$items.product_id", units: { $sum: "$items.quantity" } } },
  { $sort: { units: -1 } }, { $limit: 10 }
]);
