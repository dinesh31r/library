<!--#include file="includes/db_config.asp"-->
<%
RequireAuth()

If Not IsStaff() Then
    Response.Redirect("books.asp")
    Response.End
End If

Dim errorMessage, conn
errorMessage = ""
Set conn = GetConnection()

' Handle Form Submission (POST)
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim title, isbn, publisher, priceVal, authorId, categoryId, copies
    title = Trim(Request.Form("title"))
    isbn = Trim(Request.Form("isbn"))
    publisher = Trim(Request.Form("publisher"))
    priceVal = SafeFloat(Request.Form("price"), 350.00)
    authorId = SafeInt(Request.Form("author_id"), 0)
    categoryId = SafeInt(Request.Form("category_id"), 0)
    copies = SafeInt(Request.Form("copies"), 1)

    If title = "" Or isbn = "" Then
        errorMessage = "Book Title and ISBN are required fields."
    Else
        Dim insertSql, isAvailable
        If copies > 0 Then isAvailable = 1 Else isAvailable = 0

        insertSql = "INSERT INTO Books (title, isbn, publisher, price, author_id, category_id, copies_available, is_available) VALUES (" & _
                    SQLQuote(title) & ", " & _
                    SQLQuote(isbn) & ", " & _
                    SQLQuote(publisher) & ", " & _
                    priceVal & ", " & _
                    authorId & ", " & _
                    categoryId & ", " & _
                    copies & ", " & _
                    isAvailable & ")"

        On Error Resume Next
        conn.Execute(insertSql)
        If Err.Number <> 0 Then
            errorMessage = "Failed to insert book: " & Err.Description
        Else
            conn.Close
            Set conn = Nothing
            Response.Redirect("books.asp?msg=Book+added+successfully")
            Response.End
        End If
        On Error GoTo 0
    End If
End If

' Fetch Authors and Categories for Select Lists (Active only)
Dim rsAuthors, rsCategories
Set rsAuthors = conn.Execute("SELECT id, name FROM Authors WHERE is_active = 1 ORDER BY name ASC")
Set rsCategories = conn.Execute("SELECT id, name FROM Categories WHERE is_active = 1 ORDER BY name ASC")

RenderHeader "Add New Book"
%>

<div style="max-width: 680px; margin: 20px auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-bottom: 20px;">
        <div>
            <h1 style="font-size:22px; font-weight:800; color:var(--text-primary); margin-bottom:4px;">Add New Book</h1>
            <p style="font-size:13px; color:var(--text-muted); margin:0;">Register a new publication to the library inventory</p>
        </div>
        <a href="books.asp" class="btn btn-secondary btn-sm">&larr; Back to Catalog</a>
    </div>

    <% If errorMessage <> "" Then %>
        <div class="alert alert-danger"><%= CleanText(errorMessage) %></div>
    <% End If %>

    <div class="card">
        <form action="books_add.asp" method="POST">
            <div class="form-group">
                <label for="title">Book Title *</label>
                <input type="text" id="title" name="title" class="form-control" required placeholder="e.g. ಕಾನೂರು ಹೆಗ್ಗಡಿತಿ (Kanooru Heggadithi) or Radar Systems Engineering">
            </div>

            <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap:16px;">
                <div class="form-group">
                    <label for="isbn">ISBN Code *</label>
                    <input type="text" id="isbn" name="isbn" class="form-control" required placeholder="e.g. 978-0123456789">
                </div>
                <div class="form-group">
                    <label for="publisher">Publisher</label>
                    <input type="text" id="publisher" name="publisher" class="form-control" placeholder="e.g. Sapna / BEL Press">
                </div>
                <div class="form-group">
                    <label for="price">Price (&#8377;)</label>
                    <input type="number" step="0.01" id="price" name="price" class="form-control" value="350.00" required>
                </div>
            </div>

            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:16px;">
                <div class="form-group">
                    <label for="author_id">Author</label>
                    <select id="author_id" name="author_id" class="form-control">
                        <option value="0">-- Select Author --</option>
                        <%
                        If Not rsAuthors Is Nothing And rsAuthors.State = 1 Then
                            Do While Not rsAuthors.EOF
                        %>
                            <option value="<%= rsAuthors("id") %>"><%= CleanText(rsAuthors("name") & "") %></option>
                        <%
                                rsAuthors.MoveNext
                            Loop
                        End If
                        %>
                    </select>
                </div>

                <div class="form-group">
                    <label for="category_id">Category</label>
                    <select id="category_id" name="category_id" class="form-control">
                        <option value="0">-- Select Category --</option>
                        <%
                        If Not rsCategories Is Nothing And rsCategories.State = 1 Then
                            Do While Not rsCategories.EOF
                        %>
                            <option value="<%= rsCategories("id") %>"><%= CleanText(rsCategories("name") & "") %></option>
                        <%
                                rsCategories.MoveNext
                            Loop
                        End If
                        %>
                    </select>
                </div>
            </div>

            <div class="form-group">
                <label for="copies">Initial Copies Available</label>
                <input type="number" id="copies" name="copies" class="form-control" value="1" min="0" required>
            </div>

            <div style="margin-top:24px; display:flex; justify-content:flex-end; gap:10px;">
                <a href="books.asp" class="btn btn-secondary">Cancel</a>
                <button type="submit" class="btn btn-primary">Save Publication</button>
            </div>
        </form>
    </div>
</div>

<%
conn.Close
Set conn = Nothing
RenderFooter
%>
