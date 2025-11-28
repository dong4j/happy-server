#!/bin/sh
set -e

# Run Prisma migrations
echo "Running Prisma migrations..."
npx prisma migrate deploy

# Start the application
echo "Starting Happy Server..."
exec yarn start

