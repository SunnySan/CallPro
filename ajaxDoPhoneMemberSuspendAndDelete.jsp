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
String sAccountSequence		= nullToString(request.getParameter("accountSequence"), "");
String sNewMemberName		= nullToString(request.getParameter("newMemberName"), "");

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

writeLog("info", "Do member suspend or delete, sAuditPhoneNumber=" + sAuditPhoneNumber + ", sLoginUserAccountSequence=" + sLoginUserAccountSequence + ", sAction=" + sAction + ", sRowId=" + sRowId);

if (beEmpty(sAccountSequence) || beEmpty(sAction) || beEmpty(sRowId)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

if ((sAction.equals("rename") || sAction.equals("add")) && (beEmpty(sNewMemberName) || sNewMemberName.length()>20)){
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

String		sSequence			= "";
String		sAuthorizationCode	= "";

if (sAction.equals("delete")){	//刪除
	sSQL = "DELETE FROM callpro_account";
}else if (sAction.equals("suspend")){	//停用
	sSQL = "UPDATE callpro_account SET Send_Instant_Notification='N'";
}else if (sAction.equals("revert")){	//復用
	sSQL = "UPDATE callpro_account SET Send_Instant_Notification='Y'";
}else if (sAction.equals("rename")){	//更名
	sSQL = "UPDATE callpro_account SET Account_Name='" + sNewMemberName + "'";
}else if (sAction.equals("add")){		//新增
	//找出電話主人的Line_Channel_Name資料
	sSQL = "SELECT Line_Channel_Name, Account_Type, Bill_Type, Audit_Phone_Number, DATE_FORMAT(Expiry_Date, '%Y-%m-%d %H:%i:%s')";
	sSQL += " FROM callpro_account";
	sSQL += " WHERE (Account_Type='O' OR Account_Type='T')";	//電話主人
	sSQL += " AND Bill_Type<>'B'";	//入門版不用建立子帳號
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
		//電話主人建立子帳號
		sSequence = getSequence(gcDataSourceName);	//取得新的Account_Sequence序號
		sAuthorizationCode = generateRandomNumber();
		if (isDuplicateAuthorizationCode(sAuthorizationCode)){
			obj.put("resultCode", gcResultCodeUnknownError);
			obj.put("resultText", "目前系統中有相同的授權碼待用戶註冊帳號，請稍後再試一次!");
			out.print(obj);
			out.flush();
			return;
		}
		sSQL = "INSERT INTO callpro_account (Create_User, Create_Date, Update_User, Update_Date, Account_Sequence, Account_Name, Account_Type, Bill_Type, Line_User_ID, Line_Channel_Name, Parent_Account_Sequence, Audit_Phone_Number, Expiry_Date, Authorization_Code, Status) VALUES (";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += sSequence + ",";
		sSQL += "'" + sNewMemberName + "',";
		sSQL += "'" + (s[0][1].equals("O")?"M":"U") + "',";
		sSQL += "'" + (s[0][2]==null?"":s[0][2]) + "',";
		sSQL += "'" + "" + "',";
		sSQL += "'" + s[0][0] + "',";	//子帳號的Line_Channel_Name應和電話主人相同
		sSQL += "'" + sAccountSequence + "',";
		sSQL += "'" + (s[0][3]==null?"":s[0][3]) + "',";
		sSQL += "'" + (s[0][4]==null?"":s[0][4]) + "',";
		sSQL += "'" + sAuthorizationCode + "',";
		sSQL += "'" + "Init" + "'";
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
	sSQL += " AND (Account_Type='M' OR Account_Type='U')";
	sSQL += " AND Parent_Account_Sequence='" + sAccountSequence + "'";
	//sSQL += " AND Status='Active'";
}

sSQLList.add(sSQL);

//writeLog("debug", sSQL);

ht = updateDBData(sSQLList, gcDataSourceName, false);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
obj.put("Authorization_Code", sAuthorizationCode);
out.print(obj);
out.flush();

%>

