# USAGE.md

## Starting the Server

From the project root, run:

```bash
nimble run
```

The server binds to `0.0.0.0` on the port specified by the `PORT` environment variable (default `5000`).

## Accessing the Application

Open a web browser and navigate to `http://localhost:5000` (replace `localhost` with your server’s IP if running remotely).

## Demo Account

On first startup, the database is seeded with a demo user:

- **Email:** `cenius@cenius.ai`
- **Password:** `cenius`

The login page displays a hint reminding you of these credentials.

## Available Pages

Once logged in, you can access the following pages:

1. **Brew Log List**  
   View all recorded brews for the logged-in user. The seed data includes 10 sample entries.

2. **New Brew Form**  
   Create a new brew entry by selecting:
   - Brewing method
   - Grind size
   - Rating

3. **Bean Inventory**  
   Manage your coffee bean stock.

Navigation is handled through server-rendered links on each page.

## Interacting with the Application

The application uses traditional HTML forms and redirects. Simply click through the pages, fill out forms, and submit them. No external API client is required.