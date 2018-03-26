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

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;
String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
String		sUser				= "Cron";

String sYesterday				= getYesterday(gcDateFormatdashYMD);

	//刪除 callpro_account 中，昨天建立的，且狀態是Init的資料，這些資料都是從LINE開帳號後超過5分鐘還沒人輸入註冊碼的
	sSQL = "DELETE FROM callpro_account";
	sSQL += " WHERE Create_Date LIKE '" + sYesterday + "%' AND Status='Init'";
	sSQLList.add(sSQL);
	writeLog("debug", "刪除 callpro_account 中，昨天建立的，且狀態是Init的資料，SQL= " + sSQL);
	ht = updateDBData(sSQLList, gcDataSourceName, false);	//更新 callpro_account_detail 中的 Google_Refresh_Token
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (!sResultCode.equals(gcResultCodeSuccess)){	//失敗
		writeLog("error", "更新 callpro_account 失敗 (" + sResultCode + "): " + sResultText);
		out.print(obj);
		out.flush();
		return;
	}

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

