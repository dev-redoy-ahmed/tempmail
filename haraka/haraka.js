const { spawn } = require('child_process');

const haraka = spawn('/usr/local/bin/haraka', ['-c', '.'], {
  stdio: 'inherit',
  cwd: __dirname
});

haraka.on('exit', (code) => {
  console.log(`Haraka exited with code ${code}`);
});
