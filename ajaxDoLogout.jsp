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
String sLoginUserGoogleID			= (String)session.getAttribute("Google_ID");
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");
String sLoginUserAuditPhoneNumber	= (String)session.getAttribute("Audit_Phone_Number");

session.removeAttribute("Google_ID");	//先清除 session 中的用戶資料
session.removeAttribute("Account_Sequence");	//先清除 session 中的用戶資料
session.removeAttribute("Account_Type");	//先清除 session 中的用戶資料
session.removeAttribute("Bill_Type");	//先清除 session 中的用戶資料
session.removeAttribute("Audit_Phone_Number");	//先清除 session 中的用戶資料

writeLog("info", "User logout, Google_ID= " + sLoginUserGoogleID + ", Account_Sequence= " + sLoginUserAccountSequence + ", Account_Type= " + sLoginUserAccountType + ", Audit_Phone_Number= " + sLoginUserAuditPhoneNumber);

String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

