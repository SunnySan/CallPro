<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>

<%@page import="javax.servlet.ServletException" %>
<%@page import="javax.servlet.http.HttpServlet" %>
<%@page import="javax.servlet.http.HttpServletRequest" %>
<%@page import="javax.servlet.http.HttpServletResponse" %>
<%@page import="java.io.PrintWriter" %>
<%@page import="java.io.IOException" %>
<%@page import="java.util.Enumeration" %>
<%@page import="javax.servlet.annotation.WebServlet" %>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>
<%@include file="00_ClientContact.jsp"%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

/*********************開始做事吧*********************/
JSONObject obj=new JSONObject();

String s = getQueryString(request);
//writeLog("debug", "request= " + s);

//out.print("2,2,2,0");
//out.print("queryString=" + s);

s = nullToString(request.getParameter("contactall"), "");
out.print("queryString=" + s);
writeLog("debug", "queryString" + s);

ClientUsers clientUsers = new ClientUsers(s);
ClientUser[] aUsers = clientUsers.getUsers();
PhoneNumbers mobilePhoneNumbers = null;
PhoneNumbers homePhoneNumbers = null;
PhoneNumbers workPhoneNumbers = null;
String[] aMobilePhone = null;
String[] aHomePhone = null;
String[] aWorkPhone = null;
int j = 0;
int k = 0;
for (int i=0;i<aUsers.length;i++){
	writeLog("debug", "name" + String.valueOf(i) + "= " + aUsers[i].getName());
	j = aUsers[i].getMobilePhoneNumbers().getPhoneNumberCount();
	writeLog("debug", "MobilePhoneNumber count=" + String.valueOf(j));
	if (j>0){
		aMobilePhone = aUsers[i].getMobilePhoneNumbers().getPhoneNumberList();
		for (k=0;k<j;k++){
			writeLog("debug", "MobilePhone" + String.valueOf(k) + "= " + aMobilePhone[k]);
		}
	}

	j = aUsers[i].getHomePhoneNumbers().getPhoneNumberCount();
	writeLog("debug", "HomePhoneNumber count=" + String.valueOf(j));
	if (j>0){
		aHomePhone = aUsers[i].getHomePhoneNumbers().getPhoneNumberList();
		for (k=0;k<j;k++){
			writeLog("debug", "HomePhone" + String.valueOf(k) + "= " + aHomePhone[k]);
		}
	}

	j = aUsers[i].getWorkPhoneNumbers().getPhoneNumberCount();
	writeLog("debug", "WorkPhoneNumber count=" + String.valueOf(j));
	if (j>0){
		aWorkPhone = aUsers[i].getWorkPhoneNumbers().getPhoneNumberList();
		for (k=0;k<j;k++){
			writeLog("debug", "WorkPhone" + String.valueOf(k) + "= " + aWorkPhone[k]);
		}
	}
}

writeLog("debug", "clientUsers.toString()=" + clientUsers.toString());

out.flush();

%>

<%!
private String getQueryString(HttpServletRequest request){
 try{
    boolean first = true;
    StringBuffer strbuf = new StringBuffer("");
    Enumeration emParams = request.getParameterNames();

    do {
      if (!emParams.hasMoreElements()) {
        break;
      }
      String sParam = (String) emParams.nextElement();
      String[] sValues = request.getParameterValues(sParam);
      String sValue = "";
      for (int i = 0; i < sValues.length; i++) {
        sValue = sValues[i];
        if (sValue != null && sValue.trim().length() != 0
            && first == true) {
          first = false;
          strbuf.append(sParam).append("=").append(
              URLEncoder.encode(sValue, "utf8"));
        }
        else if (sValue != null && sValue.trim().length() != 0
                 && first == false) {
          strbuf.append("&").append(sParam).append("=").append(
              URLEncoder.encode(sValue, "utf8"));
        }
      }
    }
    while (true);

    return strbuf.toString();
}catch(Exception e){
   writeLog("error", "error= " + e.toString());
}
return "";
  }
%>