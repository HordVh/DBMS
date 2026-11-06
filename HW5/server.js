//*** set up an HTTP server off port 3000
const express = require("express");
const app = express();
const port = 3000;

//*** set up mysql connections - uses mysql2 AND A POOL
const pool = require('./mysql');


//*** server waits indefinitely for incoming requests
app.listen(port, function () {
    console.log("NodeJS app listening on port " + port);
});


//*** columns the user is allowed to search on
const searchColumns = ["bookid", "title", "author", "category", "price"];

//*** receive get requests at the root path (using async/await)
//*** examples:
//***   http://localhost:3000/?category=Sci-Fi
//***   http://localhost:3000/?author=George Orwell&format=text
app.get("/", async (req, res) => {

    //*** extract the format parameter from the query string (json is the default)
    const format = (req.query.format || "json").toLowerCase();

    //*** extract the search parameter from the query string
    let column = null;
    let value = null;
    for (let i = 0; i < searchColumns.length; i++) {
        if (req.query[searchColumns[i]] !== undefined) {
            column = searchColumns[i];
            value = req.query[column];
            break;
        }
    }

    //*** build the SQL statement
    // Security Best Practice: Use prepared statements with '?'
    let sql_query = "SELECT bookid, title, author, category, price FROM books";
    let params = [];
    if (column !== null) {
        sql_query += " WHERE " + column + " = ?";
        params.push(value);
    }

    try {
        // Await the promise from pool.execute. It returns [rows, fields].
        const [result, fields] = await pool.execute(sql_query, params);

        console.log("Results generated for:", column ? column + " = " + value : "all books");

        //*** if the user asked for text, send back an HTML table
        if (format === "text") {

            //*** start creating the html body for the browser
            let html_body = "<HTML><STYLE>body{font-family:arial}</STYLE>";
            html_body += "<BODY>";
            html_body += "<h3 style=\"color:Tomato\">Book Search Results</h3>";

            if (column !== null) {
                html_body += `<p>Search: ${column} = ${value}</p>`;
            } else {
                html_body += "<p>Search: all books</p>";
            }
            html_body += `<p>${result.length} book(s) found</p>`;

            html_body += "<TABLE BORDER=1>";

            //*** print column headings
            html_body += "<TR>";
            for (let i = 0; i < fields.length; i++) {
                html_body += (`<TH>${fields[i].name.toUpperCase()}</TH>`);
            }
            html_body += "</TR>";

            //*** prints rows of table data
            for (let i = 0; i < result.length; i++) {
                html_body += (`<TR><TD>${result[i].bookid}</TD>` +
                              `<TD>${result[i].title}</TD>` +
                              `<TD>${result[i].author}</TD>` +
                              `<TD>${result[i].category}</TD>` +
                              `<TD>${result[i].price}</TD></TR>`);
            }

            html_body += "</TABLE>";
            html_body += "</BODY></HTML>";

            res.send(html_body); // send query results back to the browser
        }
        //*** otherwise (format=json or no format) send back JSON
        else {
            res.json(result);
        }

    } catch (err) {
        console.error("SQL Error:", err);
        // Catch and handle database errors cleanly
        if (format === "text") {
            res.status(500).send("<html><body><h1>Database Query Error</h1><p>An error occurred while fetching data.</p></body></html>");
        } else {
            res.status(500).json({ error: "Database Query Error", message: "An error occurred while fetching data." });
        }
    }
});