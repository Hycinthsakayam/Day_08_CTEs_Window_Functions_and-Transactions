// Day 8 / Set 1: MongoDB multi-document funds transfer
// Run on a replica set or sharded cluster: mongosh transaction.js
use('day8_bank_transfer');
db.accounts.deleteMany({});
db.account_transactions.deleteMany({});
db.accounts.insertMany([
 {_id:101,holder:'Aarav',balance:25000,status:'Active'},
 {_id:102,holder:'Diya',balance:12000,status:'Active'},
 {_id:103,holder:'Kabir',balance:5000,status:'Frozen'}
]);

const session=db.getMongo().startSession();
try {
 const bank=session.getDatabase('day8_bank_transfer');
 session.startTransaction();
 const from=bank.accounts.findOne({_id:101,status:'Active'});
 const to=bank.accounts.findOne({_id:102,status:'Active'});
 const amount=2000;
 if (!from || !to) throw new Error('Both accounts must exist and be Active');
 if (from.balance<amount) throw new Error('Insufficient balance');

 const debit=bank.accounts.updateOne(
   {_id:101,status:'Active',balance:{$gte:amount}},
   {$inc:{balance:-amount}}
 );
 if (debit.modifiedCount!==1) throw new Error('Debit failed or balance changed');
 const credit=bank.accounts.updateOne({_id:102,status:'Active'},{$inc:{balance:amount}});
 if (credit.modifiedCount!==1) throw new Error('Credit failed');

 bank.account_transactions.insertMany([
   {account_id:101,related_account_id:102,type:'Transfer Out',amount,created_at:new Date()},
   {account_id:102,related_account_id:101,type:'Transfer In',amount,created_at:new Date()}
 ]);
 session.commitTransaction();
 print('Transfer committed');
} catch (error) {
 if (session.inTransaction()) session.abortTransaction();
 print('Transfer aborted: '+error.message);
} finally {
 session.endSession();
}
db.accounts.find().sort({_id:1}).forEach(print);
