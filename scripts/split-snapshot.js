const yaml = require("yaml");
const fs = require("fs");
const path = require("path");

// Constants
const SNAPSHOT_DIR = path.join(__dirname, "../snapshot");
const OUTPUT_FILE = path.join(__dirname, "../snapshot.yaml");

/**
 * Splits a Directus snapshot YAML file into separate files by type
 * Creates the following structure:
 * - snapshot/
 *   - collections/
 *   - fields/
 *   - relations.yaml
 */

try {
    // Create directories if they don't exist
    console.log("Setting up directories...");
    if (!fs.existsSync(SNAPSHOT_DIR)) {
        fs.mkdirSync(SNAPSHOT_DIR);
        fs.mkdirSync(path.join(SNAPSHOT_DIR, "collections"));
        fs.mkdirSync(path.join(SNAPSHOT_DIR, "fields"));
        console.log("Created snapshot directory structure");
    }

    if (!fs.existsSync(path.join(SNAPSHOT_DIR, "collections"))) {
        fs.mkdirSync(path.join(SNAPSHOT_DIR, "collections"));
        console.log("Created collections directory");
    }
    if (!fs.existsSync(path.join(SNAPSHOT_DIR, "fields"))) {
        fs.mkdirSync(path.join(SNAPSHOT_DIR, "fields"));
        console.log("Created fields directory");
    }
    if (!fs.existsSync(path.join(SNAPSHOT_DIR, "relations.yaml"))) {
        fs.writeFileSync(path.join(SNAPSHOT_DIR, "relations.yaml"), "");
        console.log("Created relations file");
    }
    

    // Read and parse snapshot file
    console.log(`Reading snapshot file: ${OUTPUT_FILE}`);
    if (!fs.existsSync(OUTPUT_FILE)) {
        throw new Error(`Snapshot file not found: ${OUTPUT_FILE}`);
    }

    const snapShotFile = fs.readFileSync(OUTPUT_FILE, "utf8");
    const parsed = yaml.parse(snapShotFile);

    const { collections, fields, relations } = parsed;

    // Validate parsed data
    if (!collections?.length) {
        console.warn("Warning: No collections found in snapshot");
    }
    if (!fields?.length) {
        console.warn("Warning: No fields found in snapshot");
    }
    if (!relations?.length) {
        console.warn("Warning: No relations found in snapshot");
    }

    // Process collections
    console.log("Processing collections...");
    collections.forEach(function (item) {
        const collectionName = item.collection;
        const collectionPath = path.join(
            SNAPSHOT_DIR,
            "collections",
            `${collectionName}.yaml`
        );

        console.log(`Writing collection: ${collectionName}`);
        fs.writeFileSync(collectionPath, yaml.stringify(item));
    });

    // Process fields
    console.log("Processing fields...");
    const fieldMap = new Map();
    fields.forEach(function (field) {
        if (!fieldMap.has(field.collection)) {
            fieldMap.set(field.collection, [field]);
        } else {
            fieldMap.get(field.collection).push(field);
        }
    });

    fieldMap.forEach(function (value, key) {
        const fieldPath = path.join(SNAPSHOT_DIR, "fields", `${key}.yaml`);
        console.log(`Writing fields for collection: ${key}`);
        fs.writeFileSync(fieldPath, yaml.stringify(value));
    });

    // Process relations
    console.log("Processing relations...");
    const relationsPath = path.join(SNAPSHOT_DIR, "relations.yaml");
    fs.writeFileSync(relationsPath, yaml.stringify(relations));

    console.log("Successfully split snapshot into separate files");
} catch (error) {
    console.error("Error splitting snapshot:", error.message);
    process.exit(1);
}
