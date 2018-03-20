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

String sAccountSequence	= nullToString(request.getParameter("accountSequence"), "");
String sAction	= nullToString(request.getParameter("action"), "");

//登入用戶的資訊
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");
String sLoginUserAuditPhoneNumber	= (String)session.getAttribute("Audit_Phone_Number");

//只有系統管理者能執行此作業
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType) || !sLoginUserAccountType.equals("A")){
	obj.put("resultCode", gcResultCodeNoPriviledge);
	obj.put("resultText", gcResultTextNoPriviledge);
	out.print(obj);
	out.flush();
	return;
}

writeLog("info", "Do phone owner suspend or delete, sLoginUserAccountSequence=" + sLoginUserAccountSequence + ", sAction=" + sAction + ", sAccountSequence=" + sAccountSequence);

if (beEmpty(sAccountSequence) || beEmpty(sAction)){
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
	//sSQL = "DELETE FROM callpro_account";
	sSQL = "UPDATE callpro_account SET Status='Delete'";	//先不刪除加盟商，只將狀態改為Delete，以免電話主人帳號找不到Parent_Account_Sequence
}else if (sAction.equals("suspend")){	//停用
	sSQL = "UPDATE callpro_account SET Status='Suspend'";
}else if (sAction.equals("revert")){	//復用
	sSQL = "UPDATE callpro_account SET Status='Active'";
}else{
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
	out.print(obj);
	out.flush();
	return;
}
sSQL += " WHERE Account_Sequence=" + sAccountSequence;
sSQL += " AND (Account_Type='O' OR Account_Type='T')";
sSQLList.add(sSQL);

if (sAction.equals("delete")){	//刪除，將通話記錄移到 callpro_call_log_deleted 去
	sSQL = "INSERT INTO callpro_call_log_deleted (Create_User, Create_Date, Update_User, Update_Date, Account_Sequence, Audit_Phone_Number, Caller_Phone_Number, Call_Type, Record_Length, Record_Talked_Time, Record_Time_Start, Record_File_URL, Caller_Name, Caller_Address, Caller_Company, Caller_Email)";
	sSQL += " SELECT Create_User, Create_Date, Update_User, Update_Date, Account_Sequence, Audit_Phone_Number, Caller_Phone_Number, Call_Type, Record_Length, Record_Talked_Time, Record_Time_Start, Record_File_URL, Caller_Name, Caller_Address, Caller_Company, Caller_Email";
	sSQL += " FROM callpro_call_log";
	sSQL += " WHERE Account_Sequence=" + sAccountSequence;
	sSQLList.add(sSQL);

	sSQL = " DELETE FROM callpro_call_log";
	sSQL += " WHERE Account_Sequence=" + sAccountSequence;
	sSQLList.add(sSQL);
}
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

