FROM mcr.microsoft.com/playwright:v1.39.0-jammy

# 1. Increase network timeouts for npm
# 2. Pin vercel to v33.x (last major version supporting Node 18)
RUN npm config set fetch-retry-mintimeout 20000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm install -g vercel@^33.0.0 serve

# 3. Fix apt backgrounding (& -> &&) to prevent race conditions
RUN apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/*