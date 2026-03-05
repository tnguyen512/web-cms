const { spawn } = require('child_process');

const fs = require('fs');

const folderPath = './extensions';

const extensions = fs.readdirSync(folderPath);

const commands = [];

for (const extension of extensions) {
    const isDir = fs.statSync(`${folderPath}/${extension}`).isDirectory();

    if (isDir) {
        const command = 'cd ' + folderPath + '/' + extension + ' && npm install && npm run build';

        commands.push({
            cmd: command,
            name: `Build ${extension}`,
        });
    }
}

async function runCommand({ cmd, args, name }) {
    return new Promise((resolve, reject) => {
        const child = spawn(cmd, args, { shell: true });

        console.log(`Running: ${name}`);

        child.on('close', (code) => {
            if (code !== 0) {
                reject(new Error(`${name} failed with exit code ${code}`));
            } else {
                console.log(`Finished: ${name} with exit code ${code}`);
                resolve();
            }
        });

        child.on('error', (err) => {
            reject(new Error(`${name} encountered an error: ${err.message}`));
        });
    });
}

// Main runner
async function main() {
    try {
        console.log('🚀 Starting to build extensions concurrently...');
        await Promise.all(commands.map(runCommand));
        console.log('✅ All commands completed successfully.');
    } catch (err) {
        console.error(`❌ ${err.message}`);
        process.exit(1);
    }
}

main();
