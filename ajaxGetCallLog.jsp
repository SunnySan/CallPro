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
String sCallerPhoneNumber	= nullToString(request.getParameter("callerPhoneNumber"), "");
String sDateStart			= nullToString(request.getParameter("dateStart"), "");
String sDateEnd				= nullToString(request.getParameter("dateEnd"), "");
String sAccountSequence		= nullToString(request.getParameter("accountSequence"), "");

//登入用戶的資訊
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");
String sLoginUserAuditPhoneNumber	= (String)session.getAttribute("Audit_Phone_Number");

if (notEmpty(sLoginUserAuditPhoneNumber)){
	sAccountSequence = sLoginUserAccountSequence;
	sAuditPhoneNumber = sLoginUserAuditPhoneNumber;	//如果登入的是電話主人，只能查自己的紀錄
}

//由於用戶從LINE browser無法登入Google，所以允許用戶未登入就查詢某個 sAuditPhoneNumber + sCallerPhoneNumber 的記錄
//if ((beEmpty(sLoginUserAccountSequence) && beEmpty(sAuditPhoneNumber)) || ((beEmpty(sDateStart) || beEmpty(sDateEnd)) && beEmpty(sCallerPhoneNumber))){
//用戶要登入後才能查
if (beEmpty(sLoginUserAccountSequence) || ((beEmpty(sDateStart) || beEmpty(sDateEnd)) && beEmpty(sCallerPhoneNumber))){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough + "，或閒置過久遭系統自動登出，請確認資料正確並重新登入!");
	out.print(obj);
	out.flush();
	return;
}

//加盟商不能查
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType) || sLoginUserAccountType.equals("D")){
	obj.put("resultCode", gcResultCodeNoPriviledge);
	obj.put("resultText", gcResultTextNoPriviledge);
	out.print(obj);
	out.flush();
	return;
}

if (notEmpty(sDateStart))	sDateStart	+= " 00:00:00";	//從開始日期的0點起算
if (notEmpty(sDateEnd))		sDateEnd	+= " 23:59:59";	//算到結束日期的23:59:59

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
int			i					= 0;
int			j					= 0;

String		sWhere				= "";

if (notEmpty(sAccountSequence)) sWhere += " AND Account_Sequence='" + sAccountSequence + "'";
if (notEmpty(sAuditPhoneNumber)) sWhere += " AND Audit_Phone_Number='" + sAuditPhoneNumber + "'";
if (notEmpty(sCallerPhoneNumber)) sWhere += " AND Caller_Phone_Number='" + sCallerPhoneNumber + "'";
if (notEmpty(sDateStart)) sWhere += " AND Record_Time_Start>='" + sDateStart + "'";
if (notEmpty(sDateEnd)) sWhere += " AND Record_Time_Start<='" + sDateEnd + "'";

sSQL = "SELECT id, Audit_Phone_Number, Caller_Phone_Number, Call_Type, Record_Length, Record_Talked_Time, DATE_FORMAT(Record_Time_Start,'%y-%m-%d %H:%i'), Record_File_URL, Caller_Name, Caller_Address, Caller_Company, Caller_Email";
sSQL += " FROM callpro_call_log";
if (notEmpty(sWhere)) sSQL += " WHERE " + sWhere.substring(5);
sSQL += " ORDER BY id DESC";
sSQL += " LIMIT 200";

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");

	obj.put("recordCount", String.valueOf(s.length));
	String[] fields2 = {"id", "Audit_Phone_Number", "Caller_Phone_Number", "Call_Type", "Record_Length", "Record_Talked_Time", "Record_Time_Start", "Record_File_URL", "Caller_Name", "Caller_Address", "Caller_Company", "Caller_Email"};
	List  l1 = new LinkedList();
	Map m1 = null;
	for (i=0;i<s.length;i++){
		m1 = new HashMap();
		for (j=0;j<fields2.length;j++){
			m1.put(fields2[j], nullToString(s[i][j], ""));
		}
		l1.add(m1);
	}
	obj.put("records", l1);
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

