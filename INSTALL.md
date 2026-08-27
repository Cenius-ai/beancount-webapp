# INSTALL.md

## 1. Prerequisites

- **Nim 2.0.8** installed on your system. You can download it from [nim‑lang.org](https://nim-lang.org/install.html).
- **nimble** (included with Nim) must be available in your PATH.

Verify your Nim installation:

```bash
nim --version
```

## 2. Getting the Code

Clone or download the BeanCount project repository to your local machine.

## 3. Building the Project

Compile the application using nimble:

```bash
nimble build -y
```

This command fetches all dependencies declared in `beancount.nimble` and produces a `beancount` binary.

## 4. Environment Variables

Copy the example environment file and edit it to set your own secrets:

```bash
cp .env.example .env
```

Open `.env` and set the required variables:

- `PORT` – the port the server will listen on (default `5000`)
- `SESSION_SECRET` – a random secret key for session encryption

Example:

```
PORT=5000
SESSION_SECRET=a-very-secure-random-string
```

The application will read these variables automatically on startup.

## 5. Database Setup

No manual setup is required. The application uses SQLite and creates the `beancount.db` file in the project root automatically on first run. The database is pre-populated with a demo account (email `cenius@cenius.ai`, password `cenius`) and 10 sample brew entries.

## 6. Running the Application

Start the development server with:

```bash
nimble run
```

The server will start on `http://0.0.0.0:5000` (or the port you configured).

## 7. Production Build

For a release build, compile with:

```bash
nimble build
```

The resulting `beancount` binary can be deployed directly. Set the required environment variables in your production environment.

## 8. Troubleshooting

- **Build fails with dependency errors**  
  Run `nimble build -y` to accept all prompts and let nimble fetch required packages.

- **`nimble` command not found**  
  Ensure Nim is installed correctly and `nimble` is in your PATH.  
  On Unix systems it is usually located at `~/.nimble/bin`.

- **Port already in use**  
  Change the `PORT` value in your `.env` file to an available port.

- **Database errors**  
  Remove `beancount.db` (and `beancount.db-shm`, `beancount.db-wal` if present) and restart the application to recreate the database from scratch.