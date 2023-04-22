#!/usr/bin bash
set -e

npm run migration:run
npm run seed:run
npm run start:prod