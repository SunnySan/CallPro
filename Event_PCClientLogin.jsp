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
<%@include file="00_GoogleAPI.jsp"%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

/*********************開始做事吧*********************/
JSONObject obj=new JSONObject();

/************************************呼叫範例*******************************
https://cms.gslssd.com/CallPro/Event_PCClientLogin.jsp?areacode=02&phonenumber1=26585888&accesscode=123456
************************************呼叫範例*******************************/

String sAreaCode			= nullToString(request.getParameter("areacode"), "");		//監控電話的室話區碼
String sPhoneNumber			= nullToString(request.getParameter("phonenumber1"), "");	//監控電話的電話號碼
String sAuthorizationCode	= nullToString(request.getParameter("accesscode"), "");		//授權碼

String sAuthorizationStatus	= "0";	//區碼電話授權碼狀態－0電話沒紀錄；1電話正確授權碼錯誤；2電話正確授權碼正確
String sAccountStatus		= "0";	//帳號類型－0入門；1進階google帳號未綁定；2進階google帳號已綁定
String sStatus				= "0";	//帳號狀態－0停用；1入門功能正常；2進階功能正常

if (beEmpty(sAreaCode) || beEmpty(sPhoneNumber) || beEmpty(sAuthorizationCode)){
	out.print(sAuthorizationStatus + "," + sAccountStatus + "," + sStatus);
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

int			i					= 0;
int			j					= 0;

//找電話主人的資料
sSQL = "SELECT Account_Type, Bill_Type, Audit_Phone_Number, DATE_FORMAT(Expiry_Date, '%Y-%m-%d %H:%i:%s'), Authorization_Code, Status";
sSQL += " FROM callpro_account";
sSQL += " WHERE (Account_Type='O' OR Account_Type='T')";	//電話主人
sSQL += " AND Audit_Phone_Number='" + sAreaCode + sPhoneNumber + "'";

ht = getDBData(sSQL, gcDataSourceName);
sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	if (isExpired(s[0][3]) || (beEmpty(s[0][5]) || s[0][5].equals("Suspend") || s[0][5].equals("Init"))){
		sStatus = "0";	//帳號狀態－0停用；1入門功能正常；2進階功能正常
	}else{
		if (notEmpty(s[0][1]) && s[0][1].equals("A")){
			sStatus = "2";	//帳號狀態－0停用；1入門功能正常；2進階功能正常
		}else{
			sStatus = "1";	//帳號狀態－0停用；1入門功能正常；2進階功能正常
		}
	}
	
	if (notEmpty(s[0][4]) && sAuthorizationCode.equals(s[0][4])){
		sAuthorizationStatus	= "2";	//區碼電話授權碼狀態－0電話沒紀錄；1電話正確授權碼錯誤；2電話正確授權碼正確
	}else{
		sAuthorizationStatus	= "1";	//區碼電話授權碼狀態－0電話沒紀錄；1電話正確授權碼錯誤；2電話正確授權碼正確
	}
	
	if (notEmpty(s[0][5])){
		if (s[0][5].indexOf("Google")>-1){
			sAccountStatus		= "1";	//帳號類型－0入門；1進階google帳號未綁定；2進階google帳號已綁定
		}else{
			sAccountStatus		= "2";	//帳號類型－0入門；1進階google帳號未綁定；2進階google帳號已綁定
		}
	}
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

out.print(sAuthorizationStatus + "," + sAccountStatus + "," + sStatus);
out.flush();
return;

%>