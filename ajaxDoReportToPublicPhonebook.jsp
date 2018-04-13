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

String sReportPhoneNumber			= nullToString(request.getParameter("reportPhoneNumber"), "");
String sReportPhoneType				= nullToString(request.getParameter("reportPhoneType"), "");
String sReportPhoneOwnerName		= nullToString(request.getParameter("reportPhoneOwnerName"), "");

//登入用戶的資訊
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");
String sLoginUserAuditPhoneNumber	= (String)session.getAttribute("Audit_Phone_Number");

//加盟商不能做
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType) || sLoginUserAccountType.equals("D")){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough + "，或閒置過久遭系統自動登出，請確認資料正確並重新登入!");
	out.print(obj);
	out.flush();
	return;
}

writeLog("info", "Publish to public phonebook, sReportPhoneNumber=" + sReportPhoneNumber + ", sReportPhoneType="  + sReportPhoneType + ", sReportPhoneOwnerName=" + sReportPhoneOwnerName + ", sLoginUserAccountSequence=" + sLoginUserAccountSequence);

if (beEmpty(sReportPhoneNumber) || beEmpty(sReportPhoneType) || ((sReportPhoneType.equals("1") || sReportPhoneType.equals("2")) && (beEmpty(sReportPhoneOwnerName) || sReportPhoneOwnerName.length()>50))){
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
	out.print(obj);
	out.flush();
	return;
}

if (sReportPhoneType.equals("3")) sReportPhoneOwnerName = "行銷電話";
if (sReportPhoneType.equals("4")) sReportPhoneOwnerName = "接起即掛斷";
if (sReportPhoneType.equals("5")) sReportPhoneOwnerName = "詐騙電話";

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
String		sUser				= "System";

//刪除既有資料
sSQL = "DELETE FROM callpro_public_phonebook";
sSQL += " WHERE Phone_Number='" + sReportPhoneNumber + "'";
sSQLList.add(sSQL);

//新增一筆資料
sSQL = "INSERT INTO callpro_public_phonebook (Create_User, Create_Date, Update_User, Update_Date, Phone_Number, Phone_Type, Owner_Name, Creator_Account_Sequence) VALUES (";
sSQL += "'" + sUser + "',";
sSQL += "'" + sDate + "',";
sSQL += "'" + sUser + "',";
sSQL += "'" + sDate + "',";
sSQL += "'" + sReportPhoneNumber + "',";
sSQL += "'" + sReportPhoneType + "',";
sSQL += "'" + sReportPhoneOwnerName + "',";
sSQL += sLoginUserAccountSequence;
sSQL += ")";
sSQLList.add(sSQL);

//writeLog("debug", sSQL);

ht = updateDBData(sSQLList, gcDataSourceName, false);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

