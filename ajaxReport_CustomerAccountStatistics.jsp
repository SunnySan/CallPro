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
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");
String sLoginUserAuditPhoneNumber	= (String)session.getAttribute("Audit_Phone_Number");

//用戶未登入或 session timeout
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType)){
	obj.put("resultCode", gcResultCodeNoLoginInfoFound);
	obj.put("resultText", gcResultTextNoLoginInfoFound);
	out.print(obj);
	out.flush();
	return;
}

//只有系統管理者和加盟商可以取得這些資料
if (!(sLoginUserAccountType.equals("A") || sLoginUserAccountType.equals("D"))){
	obj.put("resultCode", gcResultCodeNoPriviledge);
	obj.put("resultText", gcResultTextNoPriviledge);
	out.print(obj);
	out.flush();
	return;
}

String sDateEnd = "";

sDateEnd = getDateTimeNow(gcDateFormatSlashYMD);

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String		s1[][]				= null;
String		s2[][]				= null;
String		s3[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
int			i					= 0;
int			j					= 0;

String		sWhere				= "";
String		sTotalCount			= "錯誤";	//所有正式版用戶
String		sAdvanceCount		= "錯誤";	//正式進階版用戶
String		sBasicCount			= "錯誤";	//正式入門版用戶
String		sTestCount			= "錯誤";	//試用版用戶

List  l1 = new LinkedList();
Map m1 = null;

/************************************所有正式版用戶************************************/
sSQL = "SELECT COUNT(id)";
sSQL += " FROM callpro_account";
sSQL += " WHERE Account_Type='O'";
sSQL += " AND (Status='Active' OR Status='Suspend')";
if (sLoginUserAccountType.equals("D")) sSQL += " AND Parent_Account_Sequence=" + sLoginUserAccountSequence;

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	sTotalCount = nullToString(s1[0][0], "0");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************正式進階版用戶************************************/
sSQL = "SELECT COUNT(id)";
sSQL += " FROM callpro_account";
sSQL += " WHERE Account_Type='O'";
sSQL += " AND (Status='Active' OR Status='Suspend')";
if (sLoginUserAccountType.equals("D")) sSQL += " AND Parent_Account_Sequence=" + sLoginUserAccountSequence;
sSQL += " AND Bill_Type='A'";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	sAdvanceCount = nullToString(s1[0][0], "0");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************正式入門版用戶************************************/
sSQL = "SELECT COUNT(id)";
sSQL += " FROM callpro_account";
sSQL += " WHERE Account_Type='O'";
sSQL += " AND (Status='Active' OR Status='Suspend')";
if (sLoginUserAccountType.equals("D")) sSQL += " AND Parent_Account_Sequence=" + sLoginUserAccountSequence;
sSQL += " AND Bill_Type='B'";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	sBasicCount = nullToString(s1[0][0], "0");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************試用版用戶************************************/
sSQL = "SELECT COUNT(id)";
sSQL += " FROM callpro_account";
sSQL += " WHERE Account_Type='T'";
sSQL += " AND (Status='Active' OR Status='Suspend')";
if (sLoginUserAccountType.equals("D")) sSQL += " AND Parent_Account_Sequence=" + sLoginUserAccountSequence;

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	sTestCount = nullToString(s1[0][0], "0");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料


/************************************過去12個月，每月開通的客戶數量************************************/
sSQL = "SELECT YEAR(all_month.each_month), MONTH(all_month.each_month), COUNT(callpro_account.id)";
sSQL += " FROM";
sSQL += " (SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -12 MONTH) AS each_month";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -11 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -10 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -9 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -8 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -7 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -6 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -5 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -4 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -3 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -2 MONTH)";
sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -1 MONTH)) AS all_month LEFT JOIN callpro_account";
sSQL += " ON YEAR(callpro_account.Billing_Start_Date)=YEAR(all_month.each_month) AND MONTH(callpro_account.Billing_Start_Date)=MONTH(all_month.each_month)";
sSQL += " AND callpro_account.Account_Type='O'";
sSQL += " AND (callpro_account.Status='Active' OR callpro_account.Status='Suspend')";
if (sLoginUserAccountType.equals("D")) sSQL += " AND callpro_account.Parent_Account_Sequence=" + sLoginUserAccountSequence;
sSQL += " GROUP BY YEAR(all_month.each_month), MONTH(all_month.each_month)";

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	obj.put("recordCount", String.valueOf(s1.length));
	l1 = new LinkedList();
	m1 = null;
	for (i=0;i<s1.length;i++){
		m1 = new HashMap();
		m1.put("date", nullToString(s1[i][0], "") + "-" + MakesUpZero(nullToString(s1[i][1], ""), 2));
		m1.put("allCount", nullToString(s1[i][2], "0"));
		l1.add(m1);
	}
	obj.put("countData", l1);
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

obj.put("totalCustomerCount", sTotalCount);
obj.put("advanceCustomerCount", sAdvanceCount);
obj.put("basicCustomerCount", sBasicCount);
obj.put("testCustomerCount", sTestCount);

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

