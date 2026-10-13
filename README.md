# driver_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Platform  Firebase App Id
web       1:3836122260:web:afc04efdb39360cdd19081
android   1:3836122260:android:0004d8df3047d2e3d19081
ios       1:3836122260:ios:5a6632f06fa3c4e8d19081
macos     1:3836122260:ios:5a6632f06fa3c4e8d19081
windows   1:3836122260:web:fa50c2798a95227dd19081


```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SQL Injection Demo</title>
</head>
<body>

    <h1>SQL Injection Demo</h1>

    <!-- Vulnerable example -->
    <h2>1. Unsafe Query</h2>
    <form id="vulnerableForm">
        <input id="vulnerableUsername"
               placeholder="Enter username" required>
        <button type="submit">Show Query</button>
    </form>
    <p id="vulnerableOutput"></p>

    <!-- Secure example -->
    <h2>2. Safe Query</h2>
    <form id="secureForm">
        <input id="secureUsername"
               placeholder="Enter username" required>
        <button type="submit">Show Query</button>
    </form>
    <p id="secureOutput"></p>

    <script>
        // Build unsafe query
        document.getElementById("vulnerableForm")
            .addEventListener("submit", function(event) {
                event.preventDefault();

                const username =
                    document.getElementById("vulnerableUsername").value;

                // Join user input
                const query =
                    "SELECT * FROM users WHERE username = '" +
                    username + "'";

                document.getElementById("vulnerableOutput").textContent =
                    query;
            });

        // Show safe query
        document.getElementById("secureForm")
            .addEventListener("submit", function(event) {
                event.preventDefault();

                const username =
                    document.getElementById("secureUsername").value;

                // Use query parameters
                document.getElementById("secureOutput").textContent =
                    "SELECT * FROM users WHERE username = ? | Input: " +
                    username;
            });
    </script>

    <!-- Database setup instructions:
         Create a database named security_demo.
         Create a users table.
         Add sample user records.
         Use prepared statements in backend code.
         Never concatenate untrusted input into SQL.
    -->

</body>
</html>
```
