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

//只有系統管理者可以取得這些資料
if (!sLoginUserAccountType.equals("A")){
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
String		sTotalCount			= "錯誤";	//所有加盟商數量
String		sActiveCount		= "錯誤";	//Active加盟商數量
String		sSuspendCount			= "錯誤";	//Suspend加盟商數量
String		sDeleteCount			= "錯誤";	//已刪除加盟商數量

List  l1 = new LinkedList();
Map m1 = null;

/************************************所有加盟商數量************************************/
sSQL = "SELECT COUNT(id)";
sSQL += " FROM callpro_account";
sSQL += " WHERE Account_Type='D'";
sSQL += " AND (Status='Active' OR Status='Suspend' OR Status='Delete')";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	sTotalCount = nullToString(s1[0][0], "0");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************Active加盟商數量************************************/
sSQL = "SELECT COUNT(id)";
sSQL += " FROM callpro_account";
sSQL += " WHERE Account_Type='D'";
sSQL += " AND Status='Active'";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	sActiveCount = nullToString(s1[0][0], "0");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************Suspend加盟商數量************************************/
sSQL = "SELECT COUNT(id)";
sSQL += " FROM callpro_account";
sSQL += " WHERE Account_Type='D'";
sSQL += " AND Status='Suspend'";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	sSuspendCount = nullToString(s1[0][0], "0");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************已刪除加盟商數量************************************/
sSQL = "SELECT COUNT(id)";
sSQL += " FROM callpro_account";
sSQL += " WHERE Account_Type='D'";
sSQL += " AND Status='Delete'";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	sDeleteCount = nullToString(s1[0][0], "0");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料


/************************************各加盟商開通客戶數統計************************************/
sSQL = "SELECT A.Account_Name, B.Provision_Quantity";
sSQL += " FROM callpro_account A, callpro_account_detail B";
sSQL += " WHERE A.Account_Type='D'";
sSQL += " AND B.Main_Account_Sequence=A.Account_Sequence";
sSQL += " ORDER BY B.Provision_Quantity DESC";

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	//obj.put("recordCount", String.valueOf(s1.length));
	l1 = new LinkedList();
	m1 = null;
	for (i=0;i<s1.length;i++){
		m1 = new HashMap();
		m1.put("name", nullToString(s1[i][0], "0"));
		m1.put("allCount", nullToString(s1[i][1], "0"));
		l1.add(m1);
	}
	obj.put("countData", l1);
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************各加盟商購買電話盒數量統計************************************/
sSQL = "SELECT A.Account_Name, B.Purchase_Quantity";
sSQL += " FROM callpro_account A, callpro_account_detail B";
sSQL += " WHERE A.Account_Type='D'";
sSQL += " AND B.Main_Account_Sequence=A.Account_Sequence";
sSQL += " ORDER BY B.Purchase_Quantity DESC";

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
	//obj.put("recordCount", String.valueOf(s1.length));
	l1 = new LinkedList();
	m1 = null;
	for (i=0;i<s1.length;i++){
		m1 = new HashMap();
		m1.put("name", nullToString(s1[i][0], "0"));
		m1.put("allCount", nullToString(s1[i][1], "0"));
		l1.add(m1);
	}
	obj.put("boxCountData", l1);
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

obj.put("totalDealerCount", sTotalCount);
obj.put("activeDealerCount", sActiveCount);
obj.put("suspendDealerCount", sSuspendCount);
obj.put("deleteDealerCount", sDeleteCount);

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

