<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>

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

//登入用戶的資訊
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");

//只有系統管理者可以查詢Error Log
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType) || !sLoginUserAccountType.equals("A")){
	writeLog("warn", "用戶執行無權限的操作，Account_Sequence= " + sLoginUserAccountSequence + ", Account_Type=" + sLoginUserAccountType);
	obj.put("resultCode", gcResultCodeNoPriviledge);
	obj.put("resultText", gcResultTextNoPriviledge);
	out.print(obj);
	out.flush();
	return;
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;
String		sLog				= "";

String saveDirectory = application.getRealPath("/");
if (!saveDirectory.endsWith("/")) saveDirectory = saveDirectory + "/";
String		sShellScriptPath = saveDirectory + "ShellScript/grepErrorFromLogFile.sh";
String		sFilePath = saveDirectory + "errlog.txt";

//writeLog("debug", "sShellScriptPath= " + sShellScriptPath);

try {
	Process p = Runtime.getRuntime().exec(sShellScriptPath);
	p.waitFor();
	//System.out.println("exit code: " + p.exitValue());
	//writeLog("debug", "exit code= " + p.exitValue());
	if (isFileExist(sFilePath)){
		sLog = readFileContent(sFilePath);
		//writeLog("debug", "sLog= " + sLog);
	}
} catch (Exception e) {
	sResultCode = gcResultCodeUnknownError;
	sResultText = e.getMessage();
	//System.out.println(e.getMessage());
}

obj.put("logText", sLog);

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

