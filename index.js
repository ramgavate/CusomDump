#!/usr/bin/env node

require('dotenv').config();

const { MongoClient } = require('mongodb');
const path = require('path');
const fs = require('fs/promises');
const fssync = require('fs');
const exportCollection = require('./lib/exportCollection');
const archiver = require('archiver');

// Load from .env
const SOURCE_URI = process.env.SOURCE_URI;
const DB_NAME = process.env.DB_NAME;
const SAMPLE_SIZE = parseInt(process.env.SAMPLE_SIZE || "50");
const OUT_DIR = process.env.OUT_DIR || "dump";
const ZIP = process.env.ZIP === "true";
const INCLUDE_SYSTEM = process.env.INCLUDE_SYSTEM === "true";

if (!SOURCE_URI) {
  console.error("❌ SOURCE_URI missing in .env");
  process.exit(1);
}

if (!DB_NAME) {
  console.error("❌ DB_NAME missing in .env");
  process.exit(1);
}

(async () => {
  console.log("🔌 Connecting to database...");
  
  const client = new MongoClient(SOURCE_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
  });

  await client.connect();
  const db = client.db(DB_NAME);

  console.log("📦 Fetching collections...");
  const collections = await db.listCollections({}, { nameOnly: true }).toArray();

  const collNames = collections
    .map(c => c.name)
    .filter(name => INCLUDE_SYSTEM ? true : !name.startsWith("system."));

  // Create output root
  if (!fssync.existsSync(OUT_DIR)) {
    await fs.mkdir(OUT_DIR, { recursive: true });
  }

  const dbOut = path.join(OUT_DIR, DB_NAME);
  await fs.mkdir(dbOut, { recursive: true });

  console.log(`📁 Exporting into folder: ${dbOut}`);
  console.log(`📑 Sample size per collection: ${SAMPLE_SIZE}`);
  console.log(`📚 Collections found: ${collNames.length}`);

  for (const coll of collNames) {
    console.log(`➡ Exporting: ${coll}`);
    const docs = await exportCollection(db, coll, SAMPLE_SIZE);
    const outPath = path.join(dbOut, `${coll}.json`);
    await fs.writeFile(outPath, JSON.stringify(docs, null, 2), 'utf8');
    console.log(`   ✔ ${docs.length} docs saved → ${outPath}`);
  }

  if (ZIP) {
    console.log("📦 Creating ZIP...");
    const zipFile = path.join(OUT_DIR, `${DB_NAME}-sample.zip`);
    await zipFolder(dbOut, zipFile);
    console.log("   ✔ ZIP created:", zipFile);
  }

  await client.close();
  console.log("🎉 Done! Sample dump complete.");
})();

function zipFolder(sourceDir, outPath) {
  return new Promise((resolve, reject) => {
    const output = fssync.createWriteStream(outPath);
    const archive = archiver("zip", { zlib: { level: 9 } });

    output.on("close", resolve);
    archive.on("error", reject);

    archive.pipe(output);
    archive.directory(sourceDir, false);
    archive.finalize();
  });
}
