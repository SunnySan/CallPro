﻿<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
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

String sRowId	= nullToString(request.getParameter("rowId"), "");
String sAccountName	= nullToString(request.getParameter("accountName"), "");
String sContactPhone	= nullToString(request.getParameter("contactPhone"), "");
String sContactAddress	= nullToString(request.getParameter("contactAddress"), "");
String sTaxIDNumber	= nullToString(request.getParameter("taxIDNumber"), "");
String sSendInstantNotification	= nullToString(request.getParameter("sendInstantNotification"), "");
String sSendCDRNotification	= nullToString(request.getParameter("sendCDRNotification"), "");

if (beEmpty(sRowId) || beEmpty(sAccountName)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

//登入用戶的資訊
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");

//只有系統管理者或加盟商可以修改電話主人資料
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType) || (!sLoginUserAccountType.equals("A") && !sLoginUserAccountType.equals("D"))){
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
String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
String		sUser				= "System";
int			i					= 0;
int			j					= 0;

String		sPhoneOwnerAccountSequence	= "";

sSQL = "SELECT Account_Sequence FROM callpro_account WHERE id=" + sRowId;
if (sLoginUserAccountType.equals("D")){	//登入的是加盟商，先看看這個 sRowId 是不是這個加盟商的
	 sSQL += " AND Parent_Account_Sequence=" + sLoginUserAccountSequence;
}

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	sPhoneOwnerAccountSequence = s[0][0];
}else{	//沒資料
	obj.put("resultCode", gcResultCodeNoDataFound);
	obj.put("resultText", gcResultTextNoDataFound);
	out.print(obj);
	out.flush();
	return;
}

sSQL = "UPDATE callpro_account SET ";
if (notEmpty(sSendInstantNotification)){
	if (sSendInstantNotification.equals("Y")){
		sSQL += "Send_Instant_Notification='Y',";
	}else{
		sSQL += "Send_Instant_Notification='N',";
	}
}
if (notEmpty(sSendCDRNotification)){
	if (sSendCDRNotification.equals("Y")){
		sSQL += "Send_CDR_Notification='Y',";
	}else{
		sSQL += "Send_CDR_Notification='N',";
	}
}
sSQL += "Account_Name='" + sAccountName + "'";
sSQL += " WHERE id=" + sRowId;
sSQLList.add(sSQL);

sSQL = "UPDATE callpro_account_detail SET ";
sSQL += "Contact_Phone='" + sContactPhone + "', ";
sSQL += "Contact_Address='" + sContactAddress + "', ";
sSQL += "Tax_ID_Number='" + sTaxIDNumber + "'";
sSQL += " WHERE Main_Account_Sequence=" + sPhoneOwnerAccountSequence;
sSQLList.add(sSQL);

ht = updateDBData(sSQLList, gcDataSourceName, false);
sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

