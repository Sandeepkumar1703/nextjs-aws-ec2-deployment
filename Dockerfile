# ==========================
# Stage 1 - Build
# ==========================
FROM node:20-alpine AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

# Copy package files
COPY app/package*.json ./

# Install dependencies
RUN npm install

# Copy application source
COPY app/ .

# Build the application
RUN npm run build

# ==========================
# Stage 2 - Production
# ==========================
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup -S nodejs && adduser -S nextjs -G nodejs

# Copy built application
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next

# Copy these only if they exist
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.ts ./next.config.ts

USER nextjs

EXPOSE 3000

CMD ["npm", "start"]