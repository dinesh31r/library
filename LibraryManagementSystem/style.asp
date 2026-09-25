<%@ Language=VBScript %>
<%
Response.Buffer = True
Response.ContentType = "text/css"
Response.Charset = "UTF-8"
Response.Expires = -1
Response.AddHeader "Cache-Control", "no-cache, no-store, must-revalidate"
Response.AddHeader "Pragma", "no-cache"

Dim fso, f, filePath
filePath = Server.MapPath("assets/css/modern.css")
Set fso = Server.CreateObject("Scripting.FileSystemObject")
If fso.FileExists(filePath) Then
    Set f = fso.OpenTextFile(filePath, 1)
    Response.Write f.ReadAll
    f.Close
    Set f = Nothing
End If
Set fso = Nothing
%>
