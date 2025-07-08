'use strict';

const path = require('path');
const Haraka = require('haraka');

const server = new Haraka();
server.loadModules();
server.listen();
