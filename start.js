#!/usr/bin/env node

const { spawn } = require('child_process');

function runCommand(command, args) {
  return new Promise((resolve, reject) => {
    console.log(`Executing: ${command} ${args.join(' ')}`);
    const proc = spawn(command, args, {
      stdio: 'inherit',
      env: process.env
    });
    
    proc.on('error', (err) => {
      console.error(`Error executing ${command}:`, err);
      reject(err);
    });
    
    proc.on('exit', (code) => {
      console.log(`${command} exited with code ${code}`);
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Command failed with code ${code}`));
      }
    });
  });
}

async function start() {
  console.log('=== Starting CMS Service ===');
  console.log('NODE_ENV:', process.env.NODE_ENV);
  console.log('DB_HOST:', process.env.DB_HOST);
  
  // Always run bootstrap to ensure database is initialized
  console.log('\n=== Step 1: Running Bootstrap ===');
  try {
    await runCommand('npx', ['directus', 'bootstrap']);
    console.log('✓ Bootstrap completed successfully');
  } catch (error) {
    console.log('⚠ Bootstrap error (may be already initialized):', error.message);
  }
  
  // Import schema if snapshot exists
  console.log('\n=== Step 2: Importing Schema ===');
  try {
    await runCommand('npm', ['run', 'import']);
    console.log('✓ Schema import completed successfully');
  } catch (error) {
    console.log('⚠ Schema import error (may be already applied):', error.message);
  }
  
  // Start Directus
  console.log('\n=== Step 3: Starting Directus ===');
  const directus = spawn('npx', ['directus', 'start'], {
    stdio: 'inherit',
    env: process.env
  });
  
  directus.on('error', (error) => {
    console.error('✗ Failed to start Directus:', error);
    process.exit(1);
  });
  
  directus.on('exit', (code) => {
    console.log(`Directus exited with code ${code}`);
    process.exit(code);
  });
}

start().catch((error) => {
  console.error('✗ Startup failed:', error);
  process.exit(1);
});
