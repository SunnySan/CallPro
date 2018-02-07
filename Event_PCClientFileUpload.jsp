<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>

<%@ page import="org.apache.commons.fileupload.*"%>
<%@ page import="org.apache.commons.fileupload.disk.DiskFileItemFactory"%>
<%@ page import="org.apache.commons.fileupload.servlet.ServletFileUpload"%>
<%@ page import="org.apache.commons.io.FilenameUtils"%>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

/*********************開始做事吧*********************/
JSONObject obj=new JSONObject();

String CLIENT_SECRET_FILE	= application.getRealPath(gcGoogleClientSecretFilePath);
/** Application name. */
String APPLICATION_NAME = "Call-Pro";

String sLineGatewayUrlSendTextPush = gcLineGatewayUrlSendTextPush;

String saveDirectory = application.getRealPath("/upload");

String sSavedFileName = "";
/***********************處理上傳檔案**********************************/
// Check that we have a file upload request
boolean isMultipart = ServletFileUpload.isMultipartContent(request);
//out.println("isMultipart="+isMultipart+"<br>");

// Create a factory for disk-based file items
FileItemFactory factory = new DiskFileItemFactory();

// Create a new file upload handler
ServletFileUpload upload = new ServletFileUpload(factory);

// Parse the request
List /* FileItem */ items = upload.parseRequest(request);

// Process the uploaded items
Iterator iter = items.iterator(); 
while (iter.hasNext()) {
	FileItem item = (FileItem) iter.next();
	
	if (item.isFormField()) {
		// Process a regular form field
		//processFormField(item);
		String name = item.getFieldName();
		String value = item.getString("UTF-8");
		//value = new String(value.getBytes("UTF-8"), "ISO8859-1");
		obj.put(name, value);
		//out.println(name + "=" + value+"<br>");
	} else {	//if (item.isFormField()) {
		// Process a file upload
		//processUploadedFile(item);
		String fieldName = item.getFieldName();
		String fileName = item.getName();
		String contentType = item.getContentType();
		boolean isInMemory = item.isInMemory();
		long sizeInBytes = item.getSize();
		
		obj.put("originalFileName", fileName);
		if (notEmpty(fileName) && sizeInBytes>0) {
			fileName= FilenameUtils.getName(fileName);
			sSavedFileName = fileName;
			obj.put("savedFileName", sSavedFileName);
			File uploadedFile = new File(saveDirectory, sSavedFileName);
			item.write(uploadedFile);
		}	//if (fileName != null && !"".equals(fileName)) {
	}	//if (item.isFormField()) {
}	//while (iter.hasNext()) {

/****************以上是取得上傳資料，以下開始處理資料*********************/

if (notEmpty(sSavedFileName)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	//out.print(obj);
	writeLog("info", "PC Client upload file: " + sSavedFileName);
	out.print(sSavedFileName);
	out.flush();
	return;
}


%>