const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright');

async function main() {
  const [inputPath, outputPath, modulePath, wasmPath, qualityText] =
    process.argv.slice(2);
  if (!qualityText) {
    throw new Error(
      'Usage: node compress_web_fixture.cjs ' +
        '<input> <output> <index.js> <module.wasm> <quality>',
    );
  }
  const quality = Number.parseInt(qualityText, 10);
  if (!Number.isInteger(quality) || quality < 0 || quality > 100) {
    throw new RangeError(`Invalid JPEG quality: ${qualityText}`);
  }

  const files = {
    '/input.jpeg': {
      type: 'image/jpeg',
      bytes: await fs.readFile(inputPath),
    },
    '/index.js': {
      type: 'text/javascript',
      bytes: await fs.readFile(modulePath),
    },
    '/libcaesium_wasm.wasm': {
      type: 'application/wasm',
      bytes: await fs.readFile(wasmPath),
    },
  };
  const server = http.createServer((request, response) => {
    if (request.url === '/') {
      response.writeHead(200, {'content-type': 'text/html'});
      response.end('<!doctype html><title>compression parity</title>');
      return;
    }
    const file = files[request.url];
    if (!file) {
      response.writeHead(404);
      response.end();
      return;
    }
    response.writeHead(200, {
      'content-type': file.type,
      'content-length': file.bytes.length,
    });
    response.end(file.bytes);
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  const origin = `http://127.0.0.1:${address.port}`;

  const browser = await chromium.launch({
    executablePath: process.env.CHROME_BIN || undefined,
    headless: true,
  });
  try {
    const page = await browser.newPage();
    await page.goto(origin);
    const downloadPromise = page.waitForEvent('download');
    const report = await page.evaluate(async ({origin, quality}) => {
      const module = await import(`${origin}/index.js`);
      await module.initialize(`${origin}/libcaesium_wasm.wasm`);
      const input = new Uint8Array(
        await (await fetch(`${origin}/input.jpeg`)).arrayBuffer(),
      );
      const result = module.compress(input, {
        jpeg: {
          quality,
          chromaSubsampling: 0,
          progressive: true,
          optimize: false,
        },
        png: {
          quality,
          optimizationLevel: 3,
          forceZopfli: false,
          optimize: false,
        },
        webp: {quality, lossless: false},
        tiff: {compression: 2, deflateLevel: 6},
        gif: {quality},
        keepMetadata: false,
        width: 0,
        height: 0,
      });
      if (!result.status) {
        throw new Error(`libcaesium-wasm failed: ${result.errorCode}`);
      }
      const blob = new Blob([result.compressedImage], {type: 'image/jpeg'});
      const anchor = document.createElement('a');
      anchor.href = URL.createObjectURL(blob);
      anchor.download = 'web.jpeg';
      anchor.click();
      return {
        platform: 'web',
        quality,
        version: '0.5.0+libcaesium-0.18.0-wasm',
        inputSize: input.length,
        outputSize: result.size,
      };
    }, {origin, quality});
    const download = await downloadPromise;
    await fs.mkdir(path.dirname(outputPath), {recursive: true});
    await download.saveAs(outputPath);
    const output = await fs.readFile(outputPath);
    report.sha256 = crypto.createHash('sha256').update(output).digest('hex');
    await fs.writeFile(
      `${outputPath}.json`,
      `${JSON.stringify(report, null, 2)}\n`,
    );
  } finally {
    await browser.close();
    await new Promise((resolve) => server.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
