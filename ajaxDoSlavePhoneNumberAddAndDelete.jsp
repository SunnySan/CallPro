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
String sAction				= nullToString(request.getParameter("action"), "");
String sRowId				= nullToString(request.getParameter("rowId"), "");
String sAccountSequence		= nullToString(request.getParameter("accountSequence"), "");
String sNewPhoneNumber		= nullToString(request.getParameter("newPhoneNumber"), "");

//登入用戶的資訊
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");
String sLoginUserAuditPhoneNumber	= (String)session.getAttribute("Audit_Phone_Number");

if (notEmpty(sLoginUserAuditPhoneNumber)){
	sAccountSequence = sLoginUserAccountSequence;
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

writeLog("info", "Do slave phone number add or delete, sAuditPhoneNumber=" + sAuditPhoneNumber + ", sLoginUserAccountSequence=" + sLoginUserAccountSequence + ", sAction=" + sAction + ", sRowId=" + sRowId);

if (beEmpty(sAccountSequence) || beEmpty(sAction) || beEmpty(sRowId)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

if (sAction.equals("add") && (beEmpty(sNewPhoneNumber) || sNewPhoneNumber.length()>20)){
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
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

String		sWhere				= "";

if (sAction.equals("delete")){	//刪除
	sSQL = "DELETE FROM callpro_account_owner_phones";
}else if (sAction.equals("add")){		//新增
	//找出電話主人的Line_Channel_Name資料
	sSQL = "SELECT Line_Channel_Name, Account_Type, Bill_Type, Audit_Phone_Number, DATE_FORMAT(Expiry_Date, '%Y-%m-%d %H:%i:%s')";
	sSQL += " FROM callpro_account";
	sSQL += " WHERE (Account_Type='O' OR Account_Type='T')";	//電話主人
	sSQL += " AND Bill_Type<>'B'";	//入門版不用建立子門號
	sSQL += " AND Account_Sequence='" + sAccountSequence + "'";
	sSQL += " AND Status='Active'";
	//writeLog("debug", sSQL);
	ht = getDBData(sSQL, gcDataSourceName);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
		s = (String[][])ht.get("Data");
		if (isExpired(s[0][4])){
			obj.put("resultCode", gcResultCodeAccountWasSuspended);
			obj.put("resultText", "您的帳號已過期，無法進行此操作");
			out.print(obj);
			out.flush();
			return;
		}

		sSQL = "INSERT INTO callpro_account_owner_phones (Create_User, Create_Date, Update_User, Update_Date, Main_Account_Sequence, Phone_Number, Phone_Type) VALUES (";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += sAccountSequence + ",";
		sSQL += "'" + sNewPhoneNumber + "',";
		sSQL += "'" + "S" + "'";
		sSQL += ")";
	}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
}else{
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
	out.print(obj);
	out.flush();
	return;
}

if (!sAction.equals("add")){
	sSQL += " WHERE id=" + sRowId;
	sSQL += " AND Main_Account_Sequence='" + sAccountSequence + "'";
}

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

