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
<%@include file="00_LineAPI.jsp"%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

/*********************開始做事吧*********************/
JSONObject obj=new JSONObject();

/************************************呼叫範例*******************************
https://www.call-pro.net/CallPro/Event_PCClientSendInstantNotification.jsp?areacode=02&phonenumber1=26585888&accesscode=123456&callerphone=0988123456&callername=hellokitty&callerdetail=great
************************************呼叫範例*******************************/

String sCurrentVersionNumber = "1.1";
String sCurrentFileList = "project1.zip^http://www.85899.net:8888/project1.zip^\test^project1.exe^1.1|";
sCurrentFileList += "\nproject1.zip^http://www.85899.net:8888/project1.zip^\test1^project2.exe^1.1|";

String sAreaCode			= nullToString(request.getParameter("areacode"), "");		//監控電話的室話區碼
String sPhoneNumber			= nullToString(request.getParameter("phonenumber1"), "");	//監控電話的電話號碼
String sAuthorizationCode	= nullToString(request.getParameter("accesscode"), "");		//授權碼
String sClientVersionNumber = nullToString(request.getParameter("version"), "");		//PC應用程式的版本

if (beEmpty(sAreaCode) || beEmpty(sPhoneNumber) || beEmpty(sAuthorizationCode) || beEmpty(sClientVersionNumber)){
	writeLog("info", "Parameters not enough, areacode= " + sAreaCode + ", phonenumber1= " + sPhoneNumber + ", accesscode= " + sAuthorizationCode + ", version= " + sClientVersionNumber);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

//登入用戶的資訊，系統管理者可以直接發送測試通知
String sLoginUserAccountType = (String)session.getAttribute("Account_Type");

if (!isValidPhoneOwner(sAreaCode, sPhoneNumber, sAuthorizationCode, sLoginUserAccountType)){
	writeLog("error", "Authorization failed, areacode= " + sAreaCode + ", phonenumber1= " + sPhoneNumber + ", accesscode= " + sAuthorizationCode + ", version= " + sClientVersionNumber);
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
	out.print(obj);
	out.flush();
	return;
}

String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String		sResponse			= "";

if (!sClientVersionNumber.equals(sCurrentVersionNumber)) sResponse = sCurrentFileList;
//obj.put("resultCode", sResultCode);
//obj.put("resultText", sResultText);
//out.print(obj);
out.print(sResponse);
out.flush();

%>
