<%@ Language=VBScript %>
<%
Response.Buffer = True
Response.ContentType = "image/png"
Response.Expires = -1
Response.AddHeader "Cache-Control", "no-cache, no-store, must-revalidate"
Response.AddHeader "Pragma", "no-cache"

Dim fileParam, fileName, filePath, stream
fileParam = LCase(Trim(Request.QueryString("file")))
If fileParam = "full" Or fileParam = "full-logo" Then
    fileName = "bel-full-logo.png"
Else
    fileName = "bel-emblem.png"
End If

filePath = Server.MapPath("assets/images/" & fileName)

On Error Resume Next
Set stream = Server.CreateObject("ADODB.Stream")
stream.Type = 1 ' Binary
stream.Open
stream.LoadFromFile filePath

If Err.Number = 0 Then
    Response.BinaryWrite stream.Read
End If

stream.Close
Set stream = Nothing
On Error GoTo 0
%>
