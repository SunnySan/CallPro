<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

/*********************開始做事吧*********************/

String sGoogleDriveFileId = request.getParameter("fid");	//Google Drive 檔案 ID

String s = "無法取得檔案資訊";
if (sGoogleDriveFileId!=null && sGoogleDriveFileId.length()>5){
	s = "<html><head><script language='JavaScript'>";
	//s += "<!–-\n";
	s += "\n    window.location.replace('";
	s += "https://drive.google.com/file/d/" + sGoogleDriveFileId + "/view";
	s += "');\n";
	//s += "\n-–>";
	s += "</script></head></html>";
}

out.print(s);
out.flush();
return;
%>

