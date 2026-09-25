<!--#include file="includes/db_config.asp"-->
<%
RequireAuth()

If Not IsStaff() Then
    Response.Redirect("books.asp")
    Response.End
End If

Dim bookId, errorMessage, conn
bookId = SafeInt(Request.QueryString("id"), 0)
errorMessage = ""

If bookId = 0 Then
    Response.Redirect("books.asp")
    Response.End
End If

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
    copies = SafeInt(Request.Form("copies"), 0)

    If title = "" Or isbn = "" Then
        errorMessage = "Book Title and ISBN are required."
    Else
        Dim updateSql, isAvailable
        If copies > 0 Then isAvailable = 1 Else isAvailable = 0

        updateSql = "UPDATE Books SET " & _
                    "title = " & SQLQuote(title) & ", " & _
                    "isbn = " & SQLQuote(isbn) & ", " & _
                    "publisher = " & SQLQuote(publisher) & ", " & _
                    "price = " & priceVal & ", " & _
                    "author_id = " & authorId & ", " & _
                    "category_id = " & categoryId & ", " & _
                    "copies_available = " & copies & ", " & _
                    "is_available = " & isAvailable & " " & _
                    "WHERE id = " & bookId

        On Error Resume Next
        conn.Execute(updateSql)
        If Err.Number <> 0 Then
            errorMessage = "Failed to update book: " & Err.Description
        Else
            conn.Close
            Set conn = Nothing
            Response.Redirect("books.asp?msg=Book+updated+successfully")
            Response.End
        End If
        On Error GoTo 0
    End If
End If

' Fetch Current Book Details
Dim rsBook
Set rsBook = conn.Execute("SELECT * FROM Books WHERE id = " & bookId)

If rsBook.EOF Then
    conn.Close
    Set conn = Nothing
    Response.Redirect("books.asp")
    Response.End
End If

' Fetch Authors and Categories for Select Lists (Active, plus current book values)
Dim rsAuthors, rsCategories, bookAuthorId, bookCatId
bookAuthorId = SafeInt(rsBook("author_id"), 0)
bookCatId = SafeInt(rsBook("category_id"), 0)

Dim sqlAuthors, sqlCats
sqlAuthors = "SELECT id, name, is_active FROM Authors WHERE is_active = 1"
If bookAuthorId > 0 Then sqlAuthors = sqlAuthors & " OR id = " & bookAuthorId
sqlAuthors = sqlAuthors & " ORDER BY name ASC"

sqlCats = "SELECT id, name, is_active FROM Categories WHERE is_active = 1"
If bookCatId > 0 Then sqlCats = sqlCats & " OR id = " & bookCatId
sqlCats = sqlCats & " ORDER BY name ASC"

Set rsAuthors = conn.Execute(sqlAuthors)
Set rsCategories = conn.Execute(sqlCats)

RenderHeader "Edit Book #" & bookId
%>

<div style="max-width: 680px; margin: 20px auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-bottom: 20px;">
        <div>
            <h1 style="font-size:22px; font-weight:800; color:var(--text-primary); margin-bottom:4px;">Edit Publication #<%= bookId %></h1>
            <p style="font-size:13px; color:var(--text-muted); margin:0;">Update book metadata, price, and shelf inventory</p>
        </div>
        <a href="books.asp" class="btn btn-secondary btn-sm">&larr; Cancel</a>
    </div>

    <% If errorMessage <> "" Then %>
        <div class="alert alert-danger"><%= CleanText(errorMessage) %></div>
    <% End If %>

    <div class="card">
        <form action="books_edit.asp?id=<%= bookId %>" method="POST">
            <div class="form-group">
                <label for="title">Book Title *</label>
                <input type="text" id="title" name="title" class="form-control" value="<%= CleanText(rsBook("title") & "") %>" required>
            </div>

            <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap:16px;">
                <div class="form-group">
                    <label for="isbn">ISBN Code *</label>
                    <input type="text" id="isbn" name="isbn" class="form-control" value="<%= CleanText(rsBook("isbn") & "") %>" required>
                </div>
                <div class="form-group">
                    <label for="publisher">Publisher</label>
                    <input type="text" id="publisher" name="publisher" class="form-control" value="<%= CleanText(rsBook("publisher") & "") %>">
                </div>
                <div class="form-group">
                    <label for="price">Price (&#8377;)</label>
                    <input type="number" step="0.01" id="price" name="price" class="form-control" value="<%= SafeFloat(rsBook("price"), 0.00) %>" required>
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
                                Dim selAuthor
                                If CStr(rsAuthors("id")) = CStr(rsBook("author_id")) Then selAuthor = "selected" Else selAuthor = ""
                        %>
                            <option value="<%= rsAuthors("id") %>" <%= selAuthor %>><%= CleanText(rsAuthors("name") & "") %><%= IIf(SafeInt(rsAuthors("is_active"), 1) = 0, " (Disabled)", "") %></option>
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
                                Dim selCat
                                If CStr(rsCategories("id")) = CStr(rsBook("category_id")) Then selCat = "selected" Else selCat = ""
                        %>
                            <option value="<%= rsCategories("id") %>" <%= selCat %>><%= CleanText(rsCategories("name") & "") %><%= IIf(SafeInt(rsCategories("is_active"), 1) = 0, " (Disabled)", "") %></option>
                        <%
                                rsCategories.MoveNext
                            Loop
                        End If
                        %>
                    </select>
                </div>
            </div>

            <div class="form-group">
                <label for="copies">Available Stock Copies</label>
                <input type="number" id="copies" name="copies" class="form-control" value="<%= rsBook("copies_available") %>" min="0" required>
            </div>

            <div style="margin-top:24px; display:flex; justify-content:flex-end; gap:10px;">
                <a href="books.asp" class="btn btn-secondary">Cancel</a>
                <button type="submit" class="btn btn-primary">Save Changes</button>
            </div>
        </form>
    </div>
</div>

<%
rsBook.Close
conn.Close
Set conn = Nothing
RenderFooter
%>
