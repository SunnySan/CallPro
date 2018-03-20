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
String sAccountSequence		= nullToString(request.getParameter("accountSequence"), "");

//登入用戶的資訊
String sLoginUserAccountSequence	= (String)session.getAttribute("Account_Sequence");
String sLoginUserAccountType		= (String)session.getAttribute("Account_Type");
String sLoginUserAuditPhoneNumber	= (String)session.getAttribute("Audit_Phone_Number");

if (notEmpty(sLoginUserAuditPhoneNumber)){
	sAccountSequence = sLoginUserAccountSequence;
	sAuditPhoneNumber = sLoginUserAuditPhoneNumber;	//如果登入的是電話主人，只能查自己的紀錄
}

//加盟商不能查
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType) || sLoginUserAccountType.equals("D")){
	obj.put("resultCode", gcResultCodeNoPriviledge);
	obj.put("resultText", gcResultTextNoPriviledge);
	out.print(obj);
	out.flush();
	return;
}

if (beEmpty(sAccountSequence)){
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

sSQL = "SELECT id, DATE_FORMAT(Create_Date,'%y-%m-%d %H:%i'), Account_Name, Send_Instant_Notification";
sSQL += " FROM callpro_account";
sSQL += " WHERE (Account_Type='M' OR Account_Type='U')";
sSQL += " AND Parent_Account_Sequence='" + sAccountSequence + "'";
sSQL += " AND Status='Active'";
sSQL += " ORDER BY id DESC";

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");

	obj.put("recordCount", String.valueOf(s.length));
	String[] fields2 = {"id", "Create_Date", "Account_Name", "Send_Instant_Notification"};
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

