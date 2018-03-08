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

String sDateType	= nullToString(request.getParameter("dateType"), "");	//統計類型，day=過去30天每日統計、month=過去12個月每月統計

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

String sDateStart = "";
String sDateEnd = "";

if (beEmpty(sDateType) || !sDateType.equals("month")) sDateType = "day";

if (sDateType.equals("day")){
	sDateStart	+= getThirtyDaysAgo(gcDateFormatSlashYMD);
}else{
	sDateStart	+= getTwelveMonthsAgo(gcDateFormatSlashYM) + "/01 00:00:00";	//從當月1日的0點起算
}
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

List  l1 = new LinkedList();
Map m1 = null;

if (notEmpty(sLoginUserAuditPhoneNumber)) sWhere += " AND callpro_call_log.Audit_Phone_Number='" + sLoginUserAuditPhoneNumber + "'";

/************************************全部資料************************************/
if (sDateType.equals("day")){
	sSQL = "SELECT DATE_FORMAT(all_date.each_date,'%Y-%m-%d'), COUNT(callpro_call_log.id), SUM(callpro_call_log.Record_Talked_Time)";
	sSQL += " FROM";
	sSQL += " (SELECT ADDDATE(y.first, x.d - 1) AS each_date";
	sSQL += " FROM";
	sSQL += "     (SELECT 1 AS d UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL";
	sSQL += "     SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL";
	sSQL += "     SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL";
	sSQL += "     SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL";
	//sSQL += "     SELECT 29 UNION ALL SELECT 30 UNION ALL SELECT 31) x,";
	sSQL += "     SELECT 29 UNION ALL SELECT 30) x,";
	sSQL += "     (SELECT DATE('" + sDateStart + "') AS FIRST, DATE('" + sDateEnd + "') AS last) y";
	sSQL += " WHERE x.d <= y.last) AS all_date LEFT JOIN callpro_call_log";
	sSQL += " ON DATE(callpro_call_log.Record_Time_Start)=all_date.each_date";
	if (notEmpty(sWhere)) sSQL += " AND " + sWhere.substring(5);
	sSQL += " GROUP BY all_date.each_date";
}else{
	sSQL = "SELECT YEAR(all_month.each_month), MONTH(all_month.each_month), COUNT(callpro_call_log.id), SUM(callpro_call_log.Record_Talked_Time)";
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
	sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -1 MONTH)) AS all_month LEFT JOIN callpro_call_log";
	sSQL += " ON YEAR(callpro_call_log.Record_Time_Start)=YEAR(all_month.each_month) AND MONTH(callpro_call_log.Record_Time_Start)=MONTH(all_month.each_month)";
	if (notEmpty(sWhere)) sSQL += " AND " + sWhere.substring(5);
	sSQL += " GROUP BY YEAR(all_month.each_month), MONTH(all_month.each_month)";
}

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s1 = (String[][])ht.get("Data");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************撥入資料************************************/
if (sDateType.equals("day")){
	sSQL = "SELECT all_date.each_date, COUNT(callpro_call_log.id), SUM(callpro_call_log.Record_Talked_Time)";
	sSQL += " FROM";
	sSQL += " (SELECT ADDDATE(y.first, x.d - 1) AS each_date";
	sSQL += " FROM";
	sSQL += "     (SELECT 1 AS d UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL";
	sSQL += "     SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL";
	sSQL += "     SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL";
	sSQL += "     SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL";
	//sSQL += "     SELECT 29 UNION ALL SELECT 30 UNION ALL SELECT 31) x,";
	sSQL += "     SELECT 29 UNION ALL SELECT 30) x,";
	sSQL += "     (SELECT DATE('" + sDateStart + "') AS FIRST, DATE('" + sDateEnd + "') AS last) y";
	sSQL += " WHERE x.d <= y.last) AS all_date LEFT JOIN callpro_call_log";
	sSQL += " ON DATE(callpro_call_log.Record_Time_Start)=all_date.each_date";
	if (notEmpty(sWhere)) sSQL += " AND " + sWhere.substring(5);
	sSQL += " AND callpro_call_log.Call_Type='0'";	//撥入
	sSQL += " GROUP BY all_date.each_date";
}else{
	sSQL = "SELECT YEAR(all_month.each_month), MONTH(all_month.each_month), COUNT(callpro_call_log.id), SUM(callpro_call_log.Record_Talked_Time)";
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
	sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -1 MONTH)) AS all_month LEFT JOIN callpro_call_log";
	sSQL += " ON YEAR(callpro_call_log.Record_Time_Start)=YEAR(all_month.each_month) AND MONTH(callpro_call_log.Record_Time_Start)=MONTH(all_month.each_month)";
	if (notEmpty(sWhere)) sSQL += " AND " + sWhere.substring(5);
	sSQL += " AND callpro_call_log.Call_Type='0'";	//撥入
	sSQL += " GROUP BY YEAR(all_month.each_month), MONTH(all_month.each_month)";
}

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s2 = (String[][])ht.get("Data");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/************************************撥出資料************************************/
if (sDateType.equals("day")){
	sSQL = "SELECT all_date.each_date, COUNT(callpro_call_log.id), SUM(callpro_call_log.Record_Talked_Time)";
	sSQL += " FROM";
	sSQL += " (SELECT ADDDATE(y.first, x.d - 1) AS each_date";
	sSQL += " FROM";
	sSQL += "     (SELECT 1 AS d UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL";
	sSQL += "     SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL";
	sSQL += "     SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL";
	sSQL += "     SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL";
	//sSQL += "     SELECT 29 UNION ALL SELECT 30 UNION ALL SELECT 31) x,";
	sSQL += "     SELECT 29 UNION ALL SELECT 30) x,";
	sSQL += "     (SELECT DATE('" + sDateStart + "') AS FIRST, DATE('" + sDateEnd + "') AS last) y";
	sSQL += " WHERE x.d <= y.last) AS all_date LEFT JOIN callpro_call_log";
	sSQL += " ON DATE(callpro_call_log.Record_Time_Start)=all_date.each_date";
	if (notEmpty(sWhere)) sSQL += " AND " + sWhere.substring(5);
	sSQL += " AND callpro_call_log.Call_Type='1'";	//撥出
	sSQL += " GROUP BY all_date.each_date";
}else{
	sSQL = "SELECT YEAR(all_month.each_month), MONTH(all_month.each_month), COUNT(callpro_call_log.id), SUM(callpro_call_log.Record_Talked_Time)";
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
	sSQL += " UNION SELECT DATE_ADD('" + sDateEnd + "', INTERVAL -1 MONTH)) AS all_month LEFT JOIN callpro_call_log";
	sSQL += " ON YEAR(callpro_call_log.Record_Time_Start)=YEAR(all_month.each_month) AND MONTH(callpro_call_log.Record_Time_Start)=MONTH(all_month.each_month)";
	if (notEmpty(sWhere)) sSQL += " AND " + sWhere.substring(5);
	sSQL += " AND callpro_call_log.Call_Type='1'";	//撥出
	sSQL += " GROUP BY YEAR(all_month.each_month), MONTH(all_month.each_month)";
}

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s3 = (String[][])ht.get("Data");
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

if (s1!=null && s2!=null && s3!=null && s1.length==s2.length && s1.length==s3.length){
	obj.put("recordCount", String.valueOf(s1.length));
	l1 = new LinkedList();
	m1 = null;
	for (i=0;i<s1.length;i++){
		m1 = new HashMap();
		if (sDateType.equals("day")){
			m1.put("date", nullToString(s1[i][0], ""));
			m1.put("allCount", nullToString(s1[i][1], "0"));
			m1.put("allMinute", nullToString(s1[i][2], "0"));
			m1.put("inCount", nullToString(s2[i][1], "0"));
			m1.put("inMinute", nullToString(s2[i][2], "0"));
			m1.put("outCount", nullToString(s3[i][1], "0"));
			m1.put("outMinute", nullToString(s3[i][2], "0"));
		}else{
			m1.put("date", nullToString(s1[i][0], "") + "-" + MakesUpZero(nullToString(s1[i][1], ""), 2));
			m1.put("allCount", nullToString(s1[i][2], "0"));
			m1.put("allMinute", nullToString(s1[i][3], "0"));
			m1.put("inCount", nullToString(s2[i][2], "0"));
			m1.put("inMinute", nullToString(s2[i][3], "0"));
			m1.put("outCount", nullToString(s3[i][2], "0"));
			m1.put("outMinute", nullToString(s3[i][3], "0"));
		}
		l1.add(m1);
	}
	obj.put("countData", l1);
	sResultCode = gcResultCodeSuccess;
	sResultText = gcResultTextSuccess;
}else{
	sResultCode = gcResultCodeUnknownError;
	sResultText = gcResultTextUnknownError;
}





//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

