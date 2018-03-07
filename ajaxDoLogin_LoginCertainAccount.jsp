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

String aid	= nullToString(request.getParameter("aid"), "");
String bid	= nullToString(request.getParameter("bid"), "");
String Google_ID	= nullToString(request.getParameter("Google_ID"), "");
String RandomKey	= nullToString(request.getParameter("RandomKey"), "");

if (beEmpty(aid) || beEmpty(bid) || beEmpty(Google_ID) || beEmpty(RandomKey)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

String sRandomKey = (String)session.getAttribute("RandomKey");

if (beEmpty(sRandomKey) || !sRandomKey.equals(RandomKey)){
	obj.put("resultCode", gcResultCodeNoLoginInfoFound);
	obj.put("resultText", gcResultTextNoLoginInfoFound);
	out.print(obj);
	out.flush();
	return;
}

String sGoogleID = (String)session.getAttribute("Google_ID");

if (beEmpty(sGoogleID) || !sGoogleID.equals(Google_ID)){
	obj.put("resultCode", gcResultCodeNoLoginInfoFound);
	obj.put("resultText", gcResultTextNoLoginInfoFound);
	out.print(obj);
	out.flush();
	return;
}

session.removeAttribute("Google_ID");	//先清除 session 中的用戶資料
session.removeAttribute("Account_Sequence");	//先清除 session 中的用戶資料
session.removeAttribute("Account_Type");	//先清除 session 中的用戶資料
session.removeAttribute("Bill_Type");	//先清除 session 中的用戶資料
session.removeAttribute("Audit_Phone_Number");	//先清除 session 中的用戶資料

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

sSQL = "SELECT A.Account_Sequence, A.Account_Name, A.Account_Type, A.Bill_Type, A.Audit_Phone_Number, B.Google_User_Name, B.Google_User_Picture_URL";
sSQL += " FROM callpro_account_detail B, callpro_account A";
sSQL += " WHERE B.id=" + bid;
sSQL += " AND A.id=" + aid;
sSQL += " AND B.Google_ID='" + Google_ID + "'";
sSQL += " AND B.Main_Account_Sequence=A.Account_Sequence";
sSQL += " AND A.Status='Active'";
sSQL += " AND A.Expiry_Date>'" + sDate + "'";

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	//檢查 Status
	s = (String[][])ht.get("Data");

	//更新 callpro_account_detail 中的資料
	sSQL = "UPDATE callpro_account_detail SET ";
	sSQL += "Last_Login_Date='" + sDate + "'";
	sSQL += " WHERE id=" + bid;
	sSQLList.add(sSQL);
	ht = updateDBData(sSQLList, gcDataSourceName, false);	//更新 callpro_account_detail 中的 Google_Refresh_Token
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (!sResultCode.equals(gcResultCodeSuccess)){	//失敗
		writeLog("error", "更新 callpro_account_detail 失敗 (" + sResultCode + "): " + sResultText);
		out.print(obj);
		out.flush();
		return;
	}

	session.setAttribute("Google_ID", Google_ID);	//將登入用戶資料存入 session 中
	session.setAttribute("Account_Sequence", nullToString(s[0][0], ""));	//將登入用戶資料存入 session 中
	session.setAttribute("Account_Type", nullToString(s[0][2], ""));	//將登入用戶資料存入 session 中
	session.setAttribute("Bill_Type", nullToString(s[0][3], ""));	//將登入用戶資料存入 session 中
	session.setAttribute("Audit_Phone_Number", nullToString(s[0][4], ""));	//將登入用戶資料存入 session 中
	writeLog("debug", "用戶登入, Account_Sequence=" + nullToString(s[0][0], ""));
	writeLog("debug", "用戶登入, Account_Type=" + nullToString(s[0][2], ""));
	writeLog("debug", "用戶登入, Bill_Type=" + nullToString(s[0][3], ""));
	writeLog("debug", "用戶登入, Audit_Phone_Number=" + nullToString(s[0][4], ""));
	writeLog("debug", "用戶登入, Google_ID=" + Google_ID);

	obj.put("Account_Sequence", nullToString(s[0][0], ""));
	obj.put("Account_Name", nullToString(s[0][1], ""));
	obj.put("Account_Type", nullToString(s[0][2], ""));
	obj.put("Bill_Type", nullToString(s[0][3], ""));
	obj.put("Audit_Phone_Number", nullToString(s[0][4], ""));
	obj.put("Google_ID", Google_ID);
	obj.put("Google_User_Name", nullToString(s[0][5], ""));
	obj.put("Google_User_Picture_URL", nullToString(s[0][6], ""));

}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料
	obj.put("resultCode", sResultCode);
	obj.put("resultText", "無法取得您的註冊資料，請重新註冊!");
	out.print(obj);
	out.flush();
	return;
}else{
	writeLog("error", "Fail to select callpro_account and callpro_account_detail data (" + sResultCode + "): " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料


//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

