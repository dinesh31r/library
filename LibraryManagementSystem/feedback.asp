<!--#include file="includes/db_config.asp"-->
<%
' Require Authentication & Check Permission
RequireAuth()
If Not HasPermission("feedback") Then
    Response.Redirect("dashboard.asp?msg=Access+Denied:+Feedback+feature+disabled+for+your+account")
    Response.End
End If

Dim conn, errorMessage, successMessage
errorMessage = ""
successMessage = ""
Set conn = GetConnection()

Dim selectedBookId
selectedBookId = SafeInt(Request.QueryString("book_id"), 0)

' Handle Form Submission (POST)
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim feedbackType, bookIdVal, rating, comment, currentUserId
    feedbackType = Trim(Request.Form("feedback_type"))
    bookIdVal = SafeInt(Request.Form("book_id"), 0)
    rating = SafeInt(Request.Form("rating"), 5)
    comment = Trim(Request.Form("comment"))
    currentUserId = SafeInt(Session("UserId"), 0)

    If feedbackType <> "book" Then
        feedbackType = "website"
        bookIdVal = 0
    End If

    If rating < 1 Or rating > 5 Then rating = 5

    ' Server-Side 150 Words Limit Validation
    Dim wordList, wordCount
    wordCount = 0
    If comment <> "" Then
        ' Normalize spaces and split
        Dim tempComment
        tempComment = Replace(comment, vbCrLf, " ")
        tempComment = Replace(tempComment, vbTab, " ")
        wordList = Split(tempComment, " ")
        
        Dim i, w
        For i = 0 To UBound(wordList)
            w = Trim(wordList(i))
            If w <> "" Then wordCount = wordCount + 1
        Next
    End If

    If comment = "" Then
        errorMessage = "Feedback comment cannot be empty."
    ElseIf wordCount > 150 Then
        errorMessage = "Validation Error: Your review exceeds the 150-word limit (" & wordCount & " words submitted). Please shorten your feedback."
    Else
        On Error Resume Next
        Dim sqlInsert
        If bookIdVal > 0 And feedbackType = "book" Then
            sqlInsert = "INSERT INTO Feedbacks (user_id, book_id, feedback_type, rating, comment) VALUES (" & _
                        currentUserId & ", " & bookIdVal & ", 'book', " & rating & ", " & SQLQuote(comment) & ")"
        Else
            sqlInsert = "INSERT INTO Feedbacks (user_id, book_id, feedback_type, rating, comment) VALUES (" & _
                        currentUserId & ", NULL, 'website', " & rating & ", " & SQLQuote(comment) & ")"
        End If
        
        conn.Execute(sqlInsert)
        
        If Err.Number <> 0 Then
            errorMessage = "Database error saving feedback: " & Err.Description
        Else
            successMessage = "Thank you! Your feedback/review has been submitted successfully."
            comment = ""
        End If
        On Error GoTo 0
    End If
End If

' Fetch Books for Selection Dropdown
Dim rsBooks
Set rsBooks = conn.Execute("SELECT id, title FROM Books ORDER BY title ASC")

' Fetch Recent Feedbacks & Reviews
Dim rsFeedbacks
Set rsFeedbacks = conn.Execute("SELECT f.id, f.feedback_type, f.rating, f.comment, f.created_at, u.username, b.title AS book_title " & _
                               "FROM Feedbacks f " & _
                               "LEFT JOIN Users u ON f.user_id = u.id " & _
                               "LEFT JOIN Books b ON f.book_id = b.id " & _
                               "ORDER BY f.id DESC LIMIT 20")

RenderHeader "Feedback & Reviews"
%>

<!-- Header -->
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; margin-bottom: 22px;">
    <div>
        <h1 style="font-size:22px; font-weight:800; color:var(--text-primary); margin-bottom:4px;">Community Feedback &amp; Book Reviews</h1>
        <p style="font-size:13px; color:var(--text-muted); margin:0;">Share your thoughts on the portal or publish reviews on library literature</p>
    </div>
</div>

<% If errorMessage <> "" Then %>
    <div class="alert alert-danger"><%= CleanText(errorMessage) %></div>
<% End If %>

<% If successMessage <> "" Then %>
    <div class="alert alert-info"><%= CleanText(successMessage) %></div>
<% End If %>

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 24px;">
    <!-- Left Column: Submit Review / Feedback Form -->
    <div class="card" style="align-self:start;">
        <div class="card-header">
            <h2 class="card-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" /></svg>
                Post Review or Feedback
            </h2>
        </div>

        <form action="feedback.asp" method="POST" id="feedbackForm" onsubmit="return validateWordCount();">
            <div class="form-group">
                <label for="feedback_type">Feedback Scope</label>
                <select id="feedback_type" name="feedback_type" class="form-control" onchange="toggleBookDropdown();">
                    <option value="website" <%= IIf(selectedBookId = 0, "selected", "") %>>General System Feedback</option>
                    <option value="book" <%= IIf(selectedBookId > 0, "selected", "") %>>Book Review</option>
                </select>
            </div>

            <div class="form-group" id="bookSelectGroup" style="<%= IIf(selectedBookId > 0, "", "display:none;") %>">
                <label for="book_id">Select Catalog Book</label>
                <select id="book_id" name="book_id" class="form-control">
                    <option value="0">-- Select Book from Catalog --</option>
                    <%
                    If Not (rsBooks Is Nothing Or rsBooks.State = 0) Then
                        Do While Not rsBooks.EOF
                    %>
                        <option value="<%= rsBooks("id") %>" <%= IIf(rsBooks("id") = selectedBookId, "selected", "") %>>
                            <%= CleanText(rsBooks("title") & "") %>
                        </option>
                    <%
                            rsBooks.MoveNext
                        Loop
                        rsBooks.MoveFirst
                    End If
                    %>
                </select>
            </div>

            <div class="form-group">
                <label for="rating">Rating Score</label>
                <select id="rating" name="rating" class="form-control">
                    <option value="5" selected>★★★★★ (5 Stars - Excellent)</option>
                    <option value="4">★★★★☆ (4 Stars - Very Good)</option>
                    <option value="3">★★★☆☆ (3 Stars - Good)</option>
                    <option value="2">★★☆☆☆ (2 Stars - Fair)</option>
                    <option value="1">★☆☆☆☆ (1 Star - Needs Improvement)</option>
                </select>
            </div>

            <div class="form-group">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
                    <label for="comment" style="margin:0;">Comments &amp; Review (Max 150 Words) *</label>
                    <span id="wordCounter" style="font-size:12px; font-weight:700; color:var(--text-muted);">0 / 150 words</span>
                </div>
                <textarea id="comment" name="comment" class="form-control" rows="5" placeholder="Share your experience or honest book critique..." oninput="updateWordCount();" required></textarea>
                <div id="wordWarning" style="color:var(--danger); font-size:12px; margin-top:6px; display:none; font-weight:600;">
                    ⚠️ Word limit exceeded! Please shorten your review to 150 words or fewer.
                </div>
            </div>

            <button type="submit" id="submitBtn" class="btn btn-primary" style="width:100%; padding:11px;">
                Submit Review
            </button>
        </form>
    </div>

    <!-- Right Column: Recent Feedbacks Stream -->
    <div class="card" style="padding:0; overflow:hidden;">
        <div style="padding:18px 22px; border-bottom:1px solid var(--border-subtle);">
            <h2 class="card-title" style="margin:0;">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>
                Community Reviews Stream
            </h2>
        </div>

        <div style="max-height: 520px; overflow-y: auto; padding: 18px 22px;">
            <%
            If rsFeedbacks Is Nothing Or rsFeedbacks.State = 0 Or rsFeedbacks.EOF Then
            %>
                <p style="text-align:center; color:var(--text-muted); padding:32px 0;">No reviews submitted yet.</p>
            <%
            Else
                Do While Not rsFeedbacks.EOF
                    Dim stars, rVal
                    rVal = SafeInt(rsFeedbacks("rating"), 5)
                    stars = String(rVal, "★")
            %>
                <div style="border-bottom:1px solid var(--border-subtle); padding-bottom:16px; margin-bottom:16px;">
                    <div style="display:flex; justify-content:space-between; align-items:center;">
                        <strong style="color:var(--text-primary);"><%= CleanText(rsFeedbacks("username") & "") %></strong>
                        <span style="font-size:13px; color:#eab308; font-weight:700;"><%= stars %></span>
                    </div>
                    <div style="display:flex; gap:8px; align-items:center; margin:4px 0 8px 0;">
                        <% If rsFeedbacks("feedback_type") = "book" And Not IsNull(rsFeedbacks("book_title")) Then %>
                            <span class="badge badge-success" style="font-size:11px;">Book Review: <%= CleanText(rsFeedbacks("book_title") & "") %></span>
                        <% Else %>
                            <span class="badge badge-warning" style="font-size:11px;">System Feedback</span>
                        <% End If %>
                        <span style="font-size:11px; color:var(--text-muted);"><%= FormatDateTime(rsFeedbacks("created_at"), 2) %></span>
                    </div>
                    <p style="margin:0; color:var(--text-secondary); font-size:13.5px; line-height:1.5;">
                        <%= CleanText(rsFeedbacks("comment") & "") %>
                    </p>
                </div>
            <%
                    rsFeedbacks.MoveNext
                Loop
                rsFeedbacks.Close
            End If
            
            conn.Close
            Set conn = Nothing
            %>
        </div>
    </div>
</div>

<script>
function toggleBookDropdown() {
    var typeSelect = document.getElementById('feedback_type');
    var bookGroup = document.getElementById('bookSelectGroup');
    if (typeSelect.value === 'book') {
        bookGroup.style.display = 'block';
    } else {
        bookGroup.style.display = 'none';
    }
}

function getWordCount(text) {
    var trimmed = text.trim();
    if (trimmed === '') return 0;
    return trimmed.split(/\s+/).length;
}

function updateWordCount() {
    var textarea = document.getElementById('comment');
    var counter = document.getElementById('wordCounter');
    var warning = document.getElementById('wordWarning');
    var submitBtn = document.getElementById('submitBtn');
    
    var count = getWordCount(textarea.value);
    counter.innerText = count + ' / 150 words';
    
    if (count > 150) {
        counter.style.color = 'var(--danger)';
        warning.style.display = 'block';
        submitBtn.disabled = true;
    } else {
        counter.style.color = 'var(--text-muted)';
        warning.style.display = 'none';
        submitBtn.disabled = false;
    }
}

function validateWordCount() {
    var textarea = document.getElementById('comment');
    var count = getWordCount(textarea.value);
    if (count > 150) {
        if (window.Toast) {
            window.Toast.show('Your review exceeds 150 words. Please shorten before submitting.', 'error');
        } else {
            alert('Your review exceeds 150 words.');
        }
        return false;
    }
    return true;
}
</script>

<% RenderFooter %>
