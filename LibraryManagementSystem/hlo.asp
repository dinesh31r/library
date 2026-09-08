<%@ Language=VBScript %>
<%
' ====================================================================
' Classic ASP (.asp) Backend Script in VBScript
' ====================================================================
Option Explicit

' 1. Response Setup
Response.Buffer = True
Response.ContentType = "text/html"

' 2. Handle Inputs (QueryString / Form)
Dim action, bookId
action = Request.QueryString("action")
bookId = Request.QueryString("id")

' 3. Session Management (C# HttpContext.Session -> VBScript Session)
Dim currentUser
currentUser = Session("Username")
If IsNull(currentUser) Or currentUser = "" Then
    currentUser = "Guest"
End If

' 4. Database Connection (C# DbContext -> ADODB.Connection)
Dim conn, rs, sql
Set conn = Server.CreateObject("ADODB.Connection")

' Update connection string to your database (SQL Server / MySQL / Access)
conn.Open "Provider=SQLOLEDB;Data Source=localhost;Initial Catalog=LibraryDb;User Id=sa;Password=yourpassword;"

' 5. Backend Logic / Database Query
Dim pageTitle
pageTitle = "Library Management System - Classic ASP"

sql = "SELECT id, title, author, is_available FROM books ORDER BY title ASC"
Set rs = Server.CreateObject("ADODB.Recordset")
rs.Open sql, conn, 1, 1 ' Read-only cursor
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><%= pageTitle %></title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f4f6f9; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 10px; border: 1px solid #ddd; text-align: left; }
        th { background-color: #007bff; color: white; }
        .badge { padding: 4px 8px; border-radius: 4px; color: white; font-size: 12px; }
        .bg-success { background-color: #28a745; }
        .bg-danger { background-color: #dc3545; }
    </style>
</head>
<body>
    <div class="card">
        <h2><%= pageTitle %></h2>
        <p>Logged in as: <strong><%= currentUser %></strong></p>

        <h3>Book Inventory</h3>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Title</th>
                    <th>Author</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <%
                If rs.EOF Then
                %>
                    <tr>
                        <td colspan="4">No books found in database.</td>
                    </tr>
                <%
                Else
                    Do While Not rs.EOF
                %>
                    <tr>
                        <td><%= rs("id") %></td>
                        <td><%= rs("title") %></td>
                        <td><%= rs("author") %></td>
                        <td>
                            <% If CBool(rs("is_available")) Then %>
                                <span class="badge bg-success">Available</span>
                            <% Else %>
                                <span class="badge bg-danger">Borrowed</span>
                            <% End If %>
                        </td>
                    </tr>
                <%
                        rs.MoveNext
                    Loop
                End If
                %>
            </tbody>
        </table>
    </div>
</body>
</html>

<%
' 6. Clean Up Database Objects
rs.Close
conn.Close
Set rs = Nothing
Set conn = Nothing
%>
