// Day 8 / Set 3: MongoDB atomic single-document stock reservation
// Run: mongosh stock_update.js
use('day8_retail_inventory');
db.products.deleteMany({});
db.products.insertMany([
 {_id:101,name:'Monitor',category:'Electronics',stock:12,unit_price:12000},
 {_id:201,name:'Keyboard',category:'Accessories',stock:30,unit_price:1800}
]);

const productId=101;
const requestedQuantity=2;
const result=db.products.updateOne(
 {_id:productId,stock:{$gte:requestedQuantity}},
 {$inc:{stock:-requestedQuantity}}
);
if(result.modifiedCount===1) {
 print('Stock reserved successfully');
} else {
 print('Reservation rejected: product missing or stock is insufficient');
}
db.products.find({_id:productId}).forEach(print);

// $inc is atomic for this one document. A guarded filter prevents stock from becoming negative.
