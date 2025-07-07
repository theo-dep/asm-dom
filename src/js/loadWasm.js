function asciiToBinary(str) {
  if (typeof atob === 'function') {
    // this works in the browser
    return atob(str)
  } else {
    // this works in node
    return Buffer.from(str, 'base64').toString('binary');
  }
}

const wasmBuffer = process.env.WASM_BUFFER;
var binaryString = asciiToBinary(wasmBuffer);
var bytes = new Uint8Array(binaryString.length);
for (var i = 0; i < binaryString.length; i++) {
  bytes[i] = binaryString.charCodeAt(i);
}

const wasmBinary = new Uint8Array(bytes.buffer);
const wasmGlueCode = require(wasmPath + '/asm-dom.js');

export default (config) => {
  config.wasmBinary = wasmBinary;
  return Promise.resolve(wasmGlueCode);
};
