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

String sAuditPhoneNumber	= nullToString(request.getParameter("auditPhoneNumber"), "");
String sAction	= nullToString(request.getParameter("action"), "");
String sRowId	= nullToString(request.getParameter("rowId"), "");

//登入用戶的資訊
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");
String sLoginUserAuditPhoneNumber	= (String)session.getAttribute("Audit_Phone_Number");

if (notEmpty(sLoginUserAuditPhoneNumber)){
	sAuditPhoneNumber = sLoginUserAuditPhoneNumber;	//如果登入的是電話主人，只能查自己的紀錄
}

//加盟商不能做
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType) || sLoginUserAccountType.equals("D")){
	obj.put("resultCode", gcResultCodeNoPriviledge);
	obj.put("resultText", gcResultTextNoPriviledge);
	out.print(obj);
	out.flush();
	return;
}

writeLog("info", "Do member suspend or delete, sAuditPhoneNumber=" + sAuditPhoneNumber + ", sLoginUserAccountSequence=" + sLoginUserAccountSequence + ", sAction=" + sAction + ", sRowId=" + sRowId);

if (beEmpty(sAuditPhoneNumber) || beEmpty(sAction) || beEmpty(sRowId)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
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
int			i					= 0;
int			j					= 0;

String		sWhere				= "";

if (sAction.equals("delete")){	//刪除
	sSQL = "DELETE FROM callpro_account";
}else if (sAction.equals("suspend")){	//停用
	sSQL = "UPDATE callpro_account SET Send_Notification='N'";
}else if (sAction.equals("revert")){	//復用
	sSQL = "UPDATE callpro_account SET Send_Notification='Y'";
}else{
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
	out.print(obj);
	out.flush();
	return;
}
sSQL += " WHERE id=" + sRowId;
sSQL += " AND Account_Type='M'";
sSQL += " AND Account_Type='M'";
if (sLoginUserAccountType.equals("O") || sLoginUserAccountType.equals("T")){
	sSQL += " AND Parent_Account_Sequence='" + sLoginUserAccountSequence + "'";
}else{
	sSQL += " AND Audit_Phone_Number='" + sAuditPhoneNumber + "'";
}
sSQL += " AND Status='Active'";
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

