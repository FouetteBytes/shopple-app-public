# Environment Configuration for Shopple Chat

## Overview

This application uses environment variables to manage sensitive API keys and secrets for Stream Chat integration.

## Required Environment Variables

The application requires the following environment variables:

- `STREAM_CHAT_API_KEY`: Your Stream Chat API key
- `STREAM_CHAT_API_SECRET`: Your Stream Chat API secret

## Setup Instructions

1. Copy `.env.example` to create your `.env` file:
   ```bash
   cp .env.example .env
   ```

2. Get your Stream Chat credentials:
   - Sign up or log in to [Stream](https://getstream.io/)
   - Create a new app or use an existing one
   - Navigate to the app dashboard
   - Find your API Key and API Secret in the app settings

3. Replace the placeholder values in your `.env` file with your actual credentials:
   ```
   STREAM_CHAT_API_KEY=your_actual_stream_chat_api_key
   STREAM_CHAT_API_SECRET=your_actual_stream_chat_api_secret
   ```

4. After updating environment files, run:
   ```bash
   flutter clean
   flutter pub get
   ```

## Important Notes

- The `.env.example` file is included in the repository as a template
- Your actual `.env` file should NEVER be committed to version control
- The `.gitignore` file excludes `.env` but includes `.env.example`
- Environment variables are loaded automatically when the app starts

## Security

- Keep your Stream Chat credentials secure
- Never share your API secret publicly
- Consider using different apps for development and production environments
