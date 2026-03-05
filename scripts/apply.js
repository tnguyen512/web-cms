const { exec } = require("child_process");
const util = require("util");

// Convert exec to promise-based
const execPromise = util.promisify(exec);

/**
 * Applies the Directus schema changes
 * @returns {Promise<void>}
 */
async function applySchema() {
    console.log("Applying schema changes...");

    try {
        const { stdout, stderr } = await execPromise("npm run import");

        if (stdout) {
            console.log("Output:", stdout);
        }

        if (stderr) {
            console.warn("Warning:", stderr);
        }

        console.log("Schema applied successfully");
    } catch (error) {
        console.error('applySchema error:', error);
        console.error("Error applying schema:", error.message);

        const environment = process.env.NODE_ENV;

        if (environment === "production") {
            // TODO: send error to monitoring-service
            console.error(
                "Production error occurred - should be reported to monitoring service"
            );
        }

        process.exit(1);
    }
}

// Run the schema application
applySchema().catch((error) => {
    console.error("Unhandled error:", error);
    process.exit(1);
});
