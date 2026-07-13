# mongo-sampler-dump

Export a sampled JSON dump from a MongoDB database and import it into another MongoDB database.

## What Gets Installed

The machine requirements are listed in [req.txt](req.txt):

- Git
- Node.js LTS and npm
- MongoDB Database Tools, which provides `mongoimport`
- Project npm dependencies from [package.json](package.json)

## Setup On Windows

Run this from the project folder:

```bat
setup_windows.bat
```

The script checks for `git`, `node`, `npm`, and `mongoimport`. If a tool is missing, it tries to install it with `winget`, then runs `npm install`, creates `.env` from `.env.example` if needed, and creates the `dump` folder.

If a newly installed command is not available immediately, close the terminal, open a new one, and run `setup_windows.bat` again.

## Setup On macOS

Run this from the project folder:

```bash
chmod +x setup_mac.sh import_all.sh
./setup_mac.sh
```

The script checks for `git`, `node`, `npm`, and `mongoimport`. If a tool is missing, it installs it with Homebrew, then runs `npm install`, creates `.env` from `.env.example` if needed, and creates the `dump` folder.

Homebrew must already be installed. Install it from <https://brew.sh> if `brew` is not available.

## Configure Environment Variables

After setup, edit `.env` and change these values:

```env
SOURCE_URI=mongodb+srv://user:password@source-cluster.example.mongodb.net
DB_NAME=source_database
SAMPLE_SIZE=500
OUT_DIR=dump
ZIP=false
INCLUDE_SYSTEM=false
TARGET_URI=mongodb+srv://user:password@target-cluster.example.mongodb.net
TARGET_DB=target_database
```

Only `.env` needs to change between machines or databases.

## Export

Run:

```bash
npm run export
```

The export is written to:

```text
dump/<DB_NAME>/
```

Each collection becomes one JSON file.

## Import

Windows:

```bat
import_all.bat dump\YOUR_DB_FOLDER
```

macOS:

```bash
./import_all.sh dump/YOUR_DB_FOLDER
```

If `TARGET_DB` is empty, the import scripts use the dump folder name as the target database name. Imports use `--drop`, so existing target collections with the same names are replaced.

## Full Flow

1. Run the setup script for your OS.
2. Edit `.env`.
3. Run `npm run export`.
4. Run the import script for your OS.

## Useful Commands

```bash
npm run help
npm run export
```
