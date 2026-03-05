const yaml = require("yaml");
const fs = require("fs");
const path = require("path");

// Constants
const SNAPSHOT_DIR = path.join(__dirname, "../snapshot");
const OUTPUT_FILE = path.join(__dirname, "../merged-snapshot.yaml");

/**
 * Merges Directus snapshot files into a single YAML file
 * @typedef {Object} SnapshotOutput
 * @property {number} version - Snapshot version
 * @property {string} directus - Directus version
 * @property {string} vendor - Database vendor
 * @property {Array} collections - Collection configurations
 * @property {Array} fields - Field configurations
 * @property {Array} relations - Relation configurations
 */
const output = {
    version: 1,
    directus: "11.7.2",
    vendor: "postgres",
    collections: [],
    fields: [],
    relations: [],
};

try {
    if (!fs.existsSync(SNAPSHOT_DIR)) {
        throw new Error(`Snapshot directory not found: ${SNAPSHOT_DIR}`);
    }

    console.log("Merging snapshot files...");

    // Read collections
    const collectionsDir = path.join(SNAPSHOT_DIR, "collections");

    if (fs.existsSync(collectionsDir)) {

        fs.readdirSync(collectionsDir).forEach((file) => {
            console.log(`Processing collection: ${file}`);
            const collection = fs.readFileSync(
                path.join(collectionsDir, file),
                "utf8"
            );
            const parsedCollection = yaml.parse(collection);
            output.collections.push(parsedCollection);
        });
    }

    // Read fields
    const fieldsDir = path.join(SNAPSHOT_DIR, "fields");

    if (fs.existsSync(fieldsDir)) {

        fs.readdirSync(fieldsDir).forEach((file) => {
            console.log(`Processing fields: ${file}`);
            const field = fs.readFileSync(path.join(fieldsDir, file), "utf8");
            const parsedFields = yaml.parse(field);
            output.fields = output.fields.concat(parsedFields);
        });
    }

    // Read relations
    const relationsPath = path.join(SNAPSHOT_DIR, "relations.yaml");

    if (!fs.existsSync(relationsPath)) {
        // create an empty relations file if it doesn't exist
        fs.writeFileSync(relationsPath, "");
        console.log(`Created empty relations file: ${relationsPath}`);
    }

    console.log("Processing relations");
    const relations = fs.readFileSync(relationsPath, "utf-8");
    const parsedRelations = yaml.parse(relations);
    output.relations = parsedRelations ?? [];

    // Validate the merged data
    if (!output.collections.length) {
        console.warn("Warning: No collections found");
    }
    if (!output.fields.length) {
        console.warn("Warning: No fields found");
    }

    if (!output.relations.length) {
        console.warn("Warning: No relations found");
    }

    // Write the merged file
    const doc = new yaml.Document();
    doc.contents = output;
    fs.writeFileSync(OUTPUT_FILE, doc.toString());
    console.log(`Successfully merged snapshot to: ${OUTPUT_FILE}`);
} catch (error) {
    console.error("Error merging snapshot:", error);
}
