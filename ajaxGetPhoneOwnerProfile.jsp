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

String sRowId				= nullToString(request.getParameter("rowId"), "");
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

//只有系統管理者或加盟商可以查詢電話主人資料
/*
if (beEmpty(sLoginUserAccountSequence) || beEmpty(sLoginUserAccountType) || (!sLoginUserAccountType.equals("A") && !sLoginUserAccountType.equals("D"))){
	writeLog("warn", "用戶執行無權限的操作，Account_Sequence= " + sLoginUserAccountSequence + ", Account_Type=" + sLoginUserAccountType);
	obj.put("resultCode", gcResultCodeNoPriviledge);
	obj.put("resultText", gcResultTextNoPriviledge);
	out.print(obj);
	out.flush();
	return;
}
*/

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
int			i					= 0;
int			j					= 0;

String		sWhere				= "";

if (notEmpty(sRowId))				sWhere += " AND A.id=" + sRowId;
if (notEmpty(sAuditPhoneNumber))	sWhere += " AND A.Audit_Phone_Number='" + sAuditPhoneNumber + "'";
if (notEmpty(sAccountSequence))		sWhere += " AND A.Account_Sequence='" + sAccountSequence + "'";

if (sLoginUserAccountType.equals("D")){	//加盟商只能查自己客戶的資料
	sWhere += " AND A.Parent_Account_Sequence=" + sLoginUserAccountSequence;
}

if (notEmpty(sRowId) || notEmpty(sAuditPhoneNumber) || notEmpty(sAccountSequence)){	//若有指定id或門號，則查單一門號的所有資料，若未指定門號，則查所有門號的最基本資料
	//sSQL = "SELECT A.id, DATE_FORMAT(A.Create_Date,'%y-%m-%d %H:%i'), A.Account_Name, A.Bill_Type, A.Line_Channel_Name, A.Audit_Phone_Number, A.Send_Instant_Notification, A.Send_CDR_Notification, DATE_FORMAT(A.Billing_Start_Date,'%y-%m-%d %H:%i'), DATE_FORMAT(A.Expiry_Date,'%y-%m-%d %H:%i'), A.Status, B.Google_User_Name, B.Google_Email, B.Contact_Phone, B.Contact_Address, B.Tax_ID_Number, B.Purchase_Quantity, B.Member_Quantity";
	sSQL = "SELECT A.id, A.Account_Sequence, DATE_FORMAT(A.Create_Date,'%y-%m-%d'), A.Account_Name, A.Bill_Type, A.Line_Channel_Name, A.Audit_Phone_Number, A.Send_Instant_Notification, A.Send_CDR_Notification, DATE_FORMAT(A.Billing_Start_Date,'%y-%m-%d'), DATE_FORMAT(A.Expiry_Date,'%y-%m-%d'), A.Authorization_Code, A.Status, B.Google_User_Name, B.Google_Email, B.Contact_Phone, B.Contact_Address, B.Tax_ID_Number, B.Purchase_Quantity, B.Member_Quantity, A.Account_Type";
}else{
	sSQL = "SELECT A.id, A.Account_Sequence, DATE_FORMAT(A.Create_Date,'%y-%m-%d'), A.Account_Name, A.Bill_Type, A.Line_Channel_Name, A.Audit_Phone_Number, A.Status, A.Account_Type";
}
sSQL += " FROM callpro_account A LEFT JOIN callpro_account_detail B";
sSQL += " ON B.Main_Account_Sequence=A.Account_Sequence";
sSQL += " WHERE (A.Account_Type='O' OR A.Account_Type='T')";
//sSQL += " AND (A.Status<>'Init' AND A.Status<>'Google')";	//還沒完成帳號開通的資料不找出來
sSQL += " AND A.Status<>'Init'";	//還沒帳號開通的資料不找出來
if (notEmpty(sWhere)) sSQL += sWhere;
sSQL += " ORDER BY A.id DESC";
//sSQL += " LIMIT 200";

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");

	obj.put("recordCount", String.valueOf(s.length));
	String[] fields2 = null;
	if (notEmpty(sRowId) || notEmpty(sAuditPhoneNumber) || notEmpty(sAccountSequence)){	//若有指定id或門號，則查單一門號的所有資料，若未指定門號，則查所有門號的最基本資料
		fields2 = new String[]{"id", "Account_Sequence", "Create_Date", "Account_Name", "Bill_Type", "Line_Channel_Name", "Audit_Phone_Number", "Send_Instant_Notification", "Send_CDR_Notification", "Billing_Start_Date", "Expiry_Date", "Authorization_Code", "Status", "Google_User_Name", "Google_Email", "Contact_Phone", "Contact_Address", "Tax_ID_Number", "Purchase_Quantity", "Member_Quantity", "Account_Type"};
	}else{
		fields2 = new String[]{"id", "Account_Sequence", "Create_Date", "Account_Name", "Bill_Type", "Line_Channel_Name", "Audit_Phone_Number", "Status", "Account_Type"};
	}
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

