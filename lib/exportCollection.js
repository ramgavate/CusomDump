/**
 * exportCollection(db, collectionName, sampleSize)
 * Returns an array of documents (with ObjectId and other BSON types converted to plain JSON serializable forms).
 */

const { ObjectId } = require('mongodb');

function bsonToPlain(doc) {
  // Simple transformation: convert ObjectId to { "$oid": "..." } optionally.
  // mongoimport accepts plain JSON with ObjectId as {"$oid":"..."} or with string _id.
  // We'll convert ObjectId to {"$oid": "..."} to preserve types.
  if (doc === null || typeof doc !== 'object') return doc;
  if (Array.isArray(doc)) return doc.map(bsonToPlain);

  const out = {};
  for (const [k, v] of Object.entries(doc)) {
    if (v && typeof v === 'object' && typeof v.equals === 'function' && v._bsontype === 'ObjectID') {
      out[k] = { $oid: v.toHexString() };
    } else if (v && v._bsontype === 'Decimal128') {
      out[k] = { $numberDecimal: v.toString() };
    } else if (v && v._bsontype === 'Long') {
      out[k] = { $numberLong: v.toString() };
    } else if (v && v._bsontype === 'Date') {
      out[k] = { $date: v.toISOString() };
    } else if (Array.isArray(v)) {
      out[k] = v.map(bsonToPlain);
    } else if (v && typeof v === 'object') {
      out[k] = bsonToPlain(v);
    } else {
      out[k] = v;
    }
  }
  return out;
}

module.exports = async function exportCollection(db, collectionName, sampleSize = 50) {
  // If sampleSize is more than collection size, aggregation will return all docs available.
  const coll = db.collection(collectionName);

  // Use aggregation $sample for randomness
  const pipeline = [
    { $sample: { size: sampleSize } }
  ];

  const cursor = coll.aggregate(pipeline, { allowDiskUse: false });
  const docs = [];
  for await (const doc of cursor) {
    // convert doc to JSON-serializable format preserving common BSON types for mongoimport
    docs.push(bsonToPlain(doc));
  }
  return docs;
};
