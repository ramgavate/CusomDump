#!/usr/bin/env node

/**
 * mongo-sampler-dump
 *
 * Usage examples:
 *  - Export:
 *      SOURCE_URI="mongodb+srv://user:pass@cluster.mongodb.net" node index.js
 *  - Export with specific DB and sample size:
 *      SOURCE_URI="..." DB_NAME="fml" SAMPLE_SIZE=50 node index.js
 *  - Export and zip:
 *      SOURCE_URI="..." DB_NAME="fml" SAMPLE_SIZE=50 ZIP=true node index.js
 *
 * The script will produce: ./dump/<dbname>/<collection>.json (jsonArray)
 */

const { MongoClient } = require('mongodb');
const path = require('path');
const fs = require('fs/promises');
const fssync = require('fs');
const exportCollection = require('./lib/exportCollection');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');
const archiver = require('archiver');

const argv = yargs(hideBin(process.argv))
  .option('uri', { type: 'string', alias: 'u', description: 'Source MongoDB URI (env: SOURCE_URI)' })
  .option('db', { type: 'string', alias: 'd', description: 'Database name to export (env: DB_NAME)' })
  .option('sample', { type: 'number', alias: 's', description: 'Sample size per collection (env: SAMPLE_SIZE)', default: 50 })
  .option('out', { type: 'string', alias: 'o', description: 'Output folder (default dump)', default: 'dump' })
  .option('zip', { type: 'boolean', description: 'Zip the dump folder at the end', default: false })
  .option('includeSystem', { type: 'boolean', description: 'Include system.* collections', default: false })
  .help()
  .argv;

const SOURCE_URI = argv.uri || process.env.SOURCE_URI;
const DB_NAME = argv.db || process.env.DB_NAME;
const SAMPLE_SIZE = parseInt(process.env.SAMPLE_SIZE || argv.sample, 10) || 50;
const OUT_DIR = argv.out || process.env.OUT_DIR || 'dump';
const ZIP = (process.env.ZIP === 'true') || argv.zip;
const INCLUDE_SYSTEM = argv.includeSystem || (process.env.INCLUDE_SYSTEM === 'true');

if (!SOURCE_URI) {
  console.error('ERROR: Source URI is required. Provide via --uri or env SOURCE_URI');
  process.exit(2);
}

(async () => {
  const client = new MongoClient(SOURCE_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
  });

  try {
    console.log('Connecting to source DB...');
    await client.connect();

    // if DB name not provided, attempt to read from URI; if still not found, require DB name
    let dbName = DB_NAME;
    if (!dbName) {
      // try to parse from uri (mongodb+srv://user:pass@host/<dbname>)
      try {
        const parsed = new URL(SOURCE_URI.replace('mongodb+srv://', 'http://'));
        const pathname = parsed.pathname || '';
        if (pathname && pathname !== '/') dbName = pathname.replace(/^\//, '');
      } catch (err) {
        // ignore
      }
    }

    if (!dbName) {
      console.error('ERROR: DB name not provided. Use --db or set DB_NAME env var.');
      await client.close();
      process.exit(2);
    }

    const db = client.db(dbName);

    console.log(`Listing collections for DB: ${dbName} ...`);
    const collections = await db.listCollections({}, { nameOnly: true }).toArray();
    const collNames = collections
      .map(c => c.name)
      .filter(name => INCLUDE_SYSTEM ? true : !name.startsWith('system.'));

    if (!fssync.existsSync(OUT_DIR)) {
      await fs.mkdir(OUT_DIR, { recursive: true });
    }
    const dbOutDir = path.join(OUT_DIR, dbName);
    await fs.mkdir(dbOutDir, { recursive: true });

    console.log(`Found collections: ${collNames.join(', ')}`);
    for (const collName of collNames) {
      console.log(`Sampling collection ${collName} -> up to ${SAMPLE_SIZE} documents`);
      try {
        const docs = await exportCollection(db, collName, SAMPLE_SIZE);
        const outPath = path.join(dbOutDir, `${collName}.json`);
        // write as json array that mongoimport understands
        await fs.writeFile(outPath, JSON.stringify(docs, null, 2), 'utf8');
        console.log(`Wrote ${docs.length} docs to ${outPath}`);
      } catch (err) {
        console.error(`Failed collection ${collName}:`, err);
      }
    }

    if (ZIP) {
      const zipName = `${dbName}-sample-dump.zip`;
      const zipPath = path.join(OUT_DIR, zipName);
      console.log(`Zipping ${dbOutDir} -> ${zipPath}`);
      await zipFolder(dbOutDir, zipPath);
      console.log('Zip created:', zipPath);
    }

    console.log('Export finished.');
    await client.close();
    process.exit(0);
  } catch (err) {
    console.error('Fatal error:', err);
    await client.close();
    process.exit(1);
  }
})();

// helper to zip
function zipFolder(sourceDir, outPath) {
  return new Promise((resolve, reject) => {
    const output = fssync.createWriteStream(outPath);
    const archive = archiver('zip', { zlib: { level: 9 }});
    output.on('close', () => resolve());
    archive.on('error', err => reject(err));
    archive.pipe(output);
    archive.directory(sourceDir, false);
    archive.finalize();
  });
}
