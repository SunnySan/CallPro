<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>

<%@ page import="java.net.*" %>
<%@ page import="java.net.URLDecoder" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.regex.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.io.*" %>
<%@ page import="javax.naming.Context" %>
<%@ page import="javax.naming.InitialContext" %>
<%@ page import="javax.sql.DataSource" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.apache.log4j.Logger" %>
<%@ page import="javax.mail.*"%>
<%@ page import="javax.mail.internet.*"%>
<%@ page import="javax.activation.*"%>

<%@page import="org.json.simple.JSONObject" %>

<%@page import="javax.crypto.Mac" %>
<%@page import="javax.crypto.spec.SecretKeySpec" %>
<%@page import="org.apache.commons.codec.binary.Base64" %>

<%
//Oracle connection
	//Class.forName("oracle.jdbc.driver.OracleDriver");
%>

<%!
//注意：因為有些程式使用jxl.jar執行Excel檔案匯出，而jxl.jar有自己的Boolean，所以這裡的Boolean都宣告為java.lang.Boolean，以免compile失敗

/*********************************************************************************************************************/
//檢查字串是否為空值
public java.lang.Boolean beEmpty(String s) {
	return (s==null || s.length()<1);
}	//public java.lang.Boolean beEmpty(String s) {
/*********************************************************************************************************************/

/*********************************************************************************************************************/
//檢查字串是否不為空值
public java.lang.Boolean notEmpty(String s) {
	return (s!=null && s.length()>0);
}	//public java.lang.Boolean notEmpty(String s) {

/*********************************************************************************************************************/

//若字串為null或空值就改為另一字串(例如""或"&nbsp;")
public String nullToString(String sOld, String sReplace){
	return (beEmpty(sOld)?sReplace:sOld);
}
/*********************************************************************************************************************/

//檢查字串是否為數字格式
public java.lang.Boolean isNumber(String str)  
{  
  try  
  {  
    double d = Double.parseDouble(str);  
  }  
  catch(NumberFormatException nfe)  
  {  
    return false;  
  }  
  return true;  
}

/*********************************************************************************************************************/

/**
	* 數字不足部份補零回傳
	* @param str 字串
	* @param lenSize 字串數字最大長度,不足的部份補零
	* @return 回傳補零後字串數字
*/
public String MakesUpZero(String str, int lenSize) {
	String zero = "0000000000";
	String returnValue = zero;
	
	returnValue = zero + str;
	
	return returnValue.substring(returnValue.length() - lenSize);

}

/*********************************************************************************************************************/

//產生20碼的TxId
public String generateTxId(){
	//以【日期+時間+四位數隨機數】作為送給BSC API的 RequestId，例如【20110816-102153-6221】
	String txtRandom = String.valueOf(Math.round(Math.random()*10000));
	txtRandom = MakesUpZero(txtRandom, 4);	//不足4碼的話，將前面補0
	String txtRequestId = getDateTimeNow(gcDateFormatDateDashTime) + "-" + txtRandom; //將日期時間格式化，加上一個隨機數，作為RequestId，格式是yyyyMMdd-HHmmss-xxxx

	return txtRequestId;
}

/*********************************************************************************************************************/

//產生6碼的隨機數字
public String generateRandomNumber(){
	String txtRandom = String.valueOf(Math.round(Math.random()*1000000));
	txtRandom = MakesUpZero(txtRandom, 6);	//不足4碼的話，將前面補0

	return txtRandom;
}

/*********************************************************************************************************************/
//建立資料庫連線
public Connection DBConnection(String dbName){
	try{
		Context initContext = new InitialContext();
		Context envContext  = (Context)initContext.lookup("java:/comp/env");
		DataSource ds = (DataSource)envContext.lookup(dbName);
		Connection conn = ds.getConnection();
		return conn;
	}catch (Exception e){
		writeLog("error", "DBConnection error: " + e.toString(), "utility");
		return null;
	}       //try{
}       //public Connection DBConnection(String dbName){

/*********************************************************************************************************************/
//關閉資料庫連線及相關的ResultSet、Statement
public  void closeDBConnection(ResultSet rs, Statement stmt, Connection dbconn){
	if(rs != null){
		try{
			rs.close();
		}catch (Exception ignored) {}
	}	//if(rs != null){
	if(stmt != null){
		try{
			stmt.close();
		}catch (Exception ignored) {}
	}	//if(stmt != null){
	if(dbconn != null){
		try{
			dbconn.close();
		}catch (Exception ignored) {}
	}	//if(dbconn != null){
}	//public  void String closeDBConnection(ResultSet rs, Statement stmt, Connection dbconn)

/*********************************************************************************************************************/
//檢查日期格式是否正確
public java.lang.Boolean isDate(String date, String DATE_FORMAT){
	try {
		DateFormat df = new SimpleDateFormat(DATE_FORMAT);
		df.setLenient(false);
		df.parse(date);
		return true;
	} catch (Exception e) {
		return false;
	}
}

/*********************************************************************************************************************/
//取得目前系統時間，並依指定的格式產生字串
public String getDateTimeNow(String sDateFormat){
	/************************************
	sDateFormat:	指定的格式，例如"yyyyMMdd-HHmmss"或"yyyyMMdd"
	*************************************/
	String s;
	SimpleDateFormat nowdate = new java.text.SimpleDateFormat(sDateFormat);
	nowdate.setTimeZone(TimeZone.getTimeZone("GMT+8"));
	s = nowdate.format(new java.util.Date());
	return s;
}	//public String getDateTimeNow(String sDateFormat){

/*********************************************************************************************************************/
//取得昨天日期
public String getYesterday(String sDateFormat){
	/************************************
	sDateFormat:	指定的格式，例如"yyyyMMdd-HHmmss"或"yyyyMMdd"
	*************************************/
	TimeZone.setDefault(TimeZone.getTimeZone("Asia/Taipei"));	//將 Timezone 設為 GMT+8
	java.util.Calendar cal = java.util.Calendar.getInstance();//使用預設時區和語言環境獲得一個日曆。  
	cal.add(java.util.Calendar.DAY_OF_MONTH, -1);//取當前日期的前一天.  
	//cal.add(java.util.Calendar.DAY_OF_MONTH, +1);//取當前日期的後一天.  
	
	//通過格式化輸出日期  
	java.text.SimpleDateFormat format = new java.text.SimpleDateFormat(sDateFormat);
 
	return format.format(cal.getTime());

}	//public String getDateTimeNow(String sDateFormat){

/*********************************************************************************************************************/
//取得七天前日期
public String getWeekAgo(String sDateFormat){
	/************************************
	sDateFormat:	指定的格式，例如"yyyyMMdd-HHmmss"或"yyyyMMdd"
	*************************************/
	TimeZone.setDefault(TimeZone.getTimeZone("Asia/Taipei"));	//將 Timezone 設為 GMT+8
	java.util.Calendar cal = java.util.Calendar.getInstance();//使用預設時區和語言環境獲得一個日曆。  
	cal.add(java.util.Calendar.DAY_OF_MONTH, -7);//取當前日期的前7天.  
	//cal.add(java.util.Calendar.DAY_OF_MONTH, +1);//取當前日期的後一天.  
	
	//通過格式化輸出日期  
	java.text.SimpleDateFormat format = new java.text.SimpleDateFormat(sDateFormat);
 
	return format.format(cal.getTime());

}	//public String getDateTimeNow(String sDateFormat){

/*********************************************************************************************************************/
//取得30天前日期
public String getThirtyDaysAgo(String sDateFormat){
	/************************************
	sDateFormat:	指定的格式，例如"yyyyMMdd-HHmmss"或"yyyyMMdd"
	*************************************/
	TimeZone.setDefault(TimeZone.getTimeZone("Asia/Taipei"));	//將 Timezone 設為 GMT+8
	java.util.Calendar cal = java.util.Calendar.getInstance();//使用預設時區和語言環境獲得一個日曆。  
	cal.add(java.util.Calendar.DAY_OF_MONTH, -30);//取當前日期的前30天.  
	//cal.add(java.util.Calendar.DAY_OF_MONTH, +1);//取當前日期的後一天.  
	
	//通過格式化輸出日期  
	java.text.SimpleDateFormat format = new java.text.SimpleDateFormat(sDateFormat);
 
	return format.format(cal.getTime());

}	//public String getDateTimeNow(String sDateFormat){

/*********************************************************************************************************************/
//取得12個月前日期
public String getTwelveMonthsAgo(String sDateFormat){
	/************************************
	sDateFormat:	指定的格式，例如"yyyyMMdd-HHmmss"或"yyyyMMdd"
	*************************************/
	TimeZone.setDefault(TimeZone.getTimeZone("Asia/Taipei"));	//將 Timezone 設為 GMT+8
	java.util.Calendar cal = java.util.Calendar.getInstance();//使用預設時區和語言環境獲得一個日曆。  
	cal.add(java.util.Calendar.MONTH, -12);//取當前日期的前12個月.  
	
	//通過格式化輸出日期  
	java.text.SimpleDateFormat format = new java.text.SimpleDateFormat(sDateFormat);
 
	return format.format(cal.getTime());

}	//public String getDateTimeNow(String sDateFormat){

/*********************************************************************************************************************/
//判斷某個日期是否已過期
public java.lang.Boolean isExpired(String sExpiryDate){
	if (beEmpty(sExpiryDate)) return false;
	java.lang.Boolean bExpired = true;
	try {
		TimeZone.setDefault(TimeZone.getTimeZone("Asia/Taipei"));	//將 Timezone 設為 GMT+8
		java.util.Calendar cal = java.util.Calendar.getInstance();//使用預設時區和語言環境獲得一個日曆。  
		java.util.Date dateNow = cal.getTime();	//目前時間
		SimpleDateFormat sdf = new SimpleDateFormat(gcDateFormatDashYMDTime);
		java.util.Date dateExpiry = sdf.parse(sExpiryDate);	//過期的時間
		bExpired = dateNow.after(dateExpiry);	//若目前時間超過過期的時間，則回覆true
	} catch (Exception e) {
		e.printStackTrace();
		writeLog("error", "Parsing date exception= " + e.toString());
		return true;
	}
	return bExpired;
}

/*********************************************************************************************************************/

//產生20碼的RequestId
public String generateRequestId(){
	//以【日期+時間+四位數隨機數】作為送給BSC API的 RequestId，例如【20110816-102153-6221】
	java.text.SimpleDateFormat formatter = new java.text.SimpleDateFormat(gcDateFormatDateDashTime);
	java.util.Date currentTime = new java.util.Date();//得到當前系統時間
	String txtRandom = String.valueOf(Math.round(Math.random()*10000));
	txtRandom = MakesUpZero(txtRandom, 4);	//不足4碼的話，將前面補0
	String txtRequestId = formatter.format(currentTime) + "-" + txtRandom; //將日期時間格式化，加上一個隨機數，作為RequestId，格式是yyyyMMdd-HHmmss-xxxx

	return txtRequestId;
}

/*********************************************************************************************************************/
//寫入檔案
public java.lang.Boolean writeToFile(String sFilePath, String content){
	//content是寫入的內容
	java.lang.Boolean bOK = true;
	String s = "";

	if (beEmpty(content)) return false;

	Writer out = null;
	try {
		out = new BufferedWriter(new OutputStreamWriter(
		new FileOutputStream(sFilePath, false), "UTF-8"));	//指定UTF-8
		out.write(content);
		out.close();
	}catch(Exception e){
		s = "Error write to file, filePath=" + sFilePath + "<p>" + e.toString();
		writeLog("error", s);
		bOK = false;
	}

	return bOK;
}	//public java.lang.Boolean writeToFile(String sFilePath, String content){

/*********************************************************************************************************************/
//讀取某個文字檔的內容
public String readFileContent(String sPath){
	//sPath:檔案的路徑及檔名，呼叫此函數前請先以【String fileName=getServletContext().getRealPath("directory/jsp.txt");】取得檔案的徑名，然後以此徑名做為sPath參數送給此函數
	java.io.File file = new java.io.File(sPath);
	FileInputStream fis = null;
	BufferedInputStream bis = null;
	DataInputStream dis = null;
	String content = "";
	try {
		fis = new FileInputStream(file);
		bis = new BufferedInputStream(fis);
		dis = new DataInputStream(bis);
		while (dis.available() != 0) {
			content += dis.readLine() + "\r\n";
		}
		content = new String(content.getBytes("8859_1"),"utf-8");
	} catch (FileNotFoundException e) {
		content = "";
		writeLog("error", "readFileContent error, sPath: " + sPath + ", desc: " + e.toString(), "utility");
	} catch (IOException e) {
		content = "";
		writeLog("error", "readFileContent error, sPath: " + sPath + ", desc: " + e.toString(), "utility");
	}finally{
		if (dis!=null){ try{dis.close();}catch (Exception ignored) {}}
		if (bis!=null){ try{bis.close();}catch (Exception ignored) {}}
		if (fis!=null){ try{fis.close();}catch (Exception ignored) {}}
	}
	return content;
}

/*********************************************************************************************************************/
//刪除某個檔案
public java.lang.Boolean DeleteFile(String sFileName){
	java.lang.Boolean bOK = true;
	if (sFileName==null || sFileName.length()<1)	return false;
	
	java.io.File f = new java.io.File(sFileName);
	if(f.exists()){//檢查是否存在
		writeLog("info", "delete file: " + sFileName, "utility");
		f.delete();//刪除文件
	} 
	return bOK;
}	//public java.lang.Boolean DeleteFile(String sPath, String sFileName){

/*********************************************************************************************************************/
//某個檔案是否存在
public java.lang.Boolean isFileExist(String sFileName){
	java.lang.Boolean bOK = false;
	if (sFileName==null || sFileName.length()<1)	return false;
	
	java.io.File f = new java.io.File(sFileName);
	if(f.exists()){//檔案存在
		bOK = true;
	} 
	return bOK;
}	//public java.lang.Boolean DeleteFile(String sPath, String sFileName){

/*********************************************************************************************************************/
//依照輸入的SQL statement取得ResultSet，並將ResultSet轉換成String Array回覆給呼叫端
public Hashtable getDBData(String sSQL, String dbName){
	//sSQL是SQL statement
	//iColCount是ResultSet中每個row的column數
	
	Hashtable	htResponse		= new Hashtable();	//儲存回覆資料的 hash table
	String		s[][]			= null;
	String		sResultCode		= gcResultCodeSuccess;
	String		sResultText		= gcResultTextSuccess;
	int			i				= 0;
	int			j				= 0;
	int			iRowCount		= 0;
	int			iColCount		= 0;
	
	if ((sSQL==null || sSQL.length()<1)){
		htResponse.put("ResultCode", gcResultCodeParametersValidationError);
		htResponse.put("ResultText", gcResultTextParametersValidationError);
		return htResponse;
	}

	//找出DB中的資料
	Connection	dbconn	= null;	//連接 Oracle DB 的 Connection 物件
	Statement	stmt	= null;	//SQL statement 物件
	ResultSet	rs		= null;	//Resultset 物件
	
	dbconn = DBConnection(dbName);
	if (dbconn==null){	//資料庫連線失敗
		htResponse.put("ResultCode", gcResultCodeDBTimeout);
		htResponse.put("ResultText", gcResultTextDBTimeout);
		return htResponse;
	}	//if (dbconn==null){	//資料庫連線失敗

	try{	//擷取資料
		stmt = dbconn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_READ_ONLY);
		rs = stmt.executeQuery(sSQL);
		if (rs!=null){
			rs.last();
			iRowCount = rs.getRow();
			rs.beforeFirst();
		}
		if (iRowCount>0){	//有資料
			ResultSetMetaData rsm = rs.getMetaData();
			iColCount = rsm.getColumnCount();
			s = new String[iRowCount][iColCount];
			i = 0;
			while (rs != null && rs.next()) { //有資料則顯示
				for (j=0;j<iColCount;j++){	//產生String Array的值
					s[i][j] = rs.getString(j+1);
				}
				i++;
			}	//while(rs.next()){	//有資料則顯示
		}else{	//無資料
			sResultCode = gcResultCodeNoDataFound;
			sResultText = gcResultTextNoDataFound;
		}	//if (iRowCount>0){	//有資料
		     /***********************************************************************************************************/
	}catch(SQLException e){
		sResultCode = gcResultCodeUnknownError;
		sResultText = e.toString();
		writeLog("error", "getDBData error, sSQL: " + sSQL + ", desc: " + e.toString(), "utility");
	}finally{
		//Clean up resources, close the connection.
		closeDBConnection(rs, stmt, dbconn);
	}	//}finally{
	
	htResponse.put("ResultCode", sResultCode);
	htResponse.put("ResultText", sResultText);
	if (iRowCount>0) htResponse.put("Data", s);
	return htResponse;
}	//public String getDBData(String sSQL, int iColCount){

/*********************************************************************************************************************/
//依照輸入的SQL statement對DB執行一個或多個insert, update, delete指令(可指定是否需每個指令自動commit)，並將執行結果回覆給呼叫端
public Hashtable updateDBData(String sSQL, String dbName){	//輸入參數為單一 String 型態
	String[] a = {sSQL};
	return updateDBData(a, dbName, true);
}
public Hashtable updateDBData(List<String> sSQLList, String dbName, java.lang.Boolean bAutoCommit){	//輸入參數為 List 型態
	return updateDBData(sSQLList.toArray(new String[0]), dbName, bAutoCommit);
}
public Hashtable updateDBData(String sSQL[], String dbName, java.lang.Boolean bAutoCommit){			//輸入參數為 String array 型態
	//sSQL[]是SQL statement
	
	Hashtable	htResponse		= new Hashtable();	//儲存回覆資料的 hash table
	String		sResultCode		= gcResultCodeSuccess;
	String		sResultText		= gcResultTextSuccess;
	String		s				= "";
	
	if (sSQL==null || sSQL.length<1){
		htResponse.put("ResultCode", gcResultCodeParametersValidationError);
		htResponse.put("ResultText", gcResultTextParametersValidationError);
		return htResponse;
	}

	//對DB執行SQL指令
	Connection	dbconn	= null;	//連接 Oracle DB 的 Connection 物件
	Statement	stmt	= null;	//SQL statement 物件
	int			i		= 0;	//executeUpdate後回覆的row count數
	int			j		= 0;	//sSQL string array的指標
	
	dbconn = DBConnection(dbName);
	if (dbconn==null){	//資料庫連線失敗
		htResponse.put("ResultCode", gcResultCodeDBTimeout);
		htResponse.put("ResultText", gcResultTextDBTimeout);
		return htResponse;
	}	//if (dbconn==null){	//資料庫連線失敗
	/*
	for(j=0;j<sSQL.length;j++){
		writeLog("debug", "execute sSQL: " + s, "utility");
	}
	*/
	try{	//執行SQL指令
		stmt = dbconn.createStatement();
		if (bAutoCommit==false) dbconn.setAutoCommit(false);
		for(j=0;j<sSQL.length;j++){
			if (notEmpty(sSQL[j])){
				s = s + sSQL[j] + ";";
				stmt.addBatch(sSQL[j]);
			}
        }	//for(j=0;j<=sSQL.length;j++){
        stmt.executeBatch();
        if (bAutoCommit==false) dbconn.commit();
	}catch(SQLException e){
		try{
			if (bAutoCommit==false) dbconn.rollback();
		}catch(SQLException e1){
			writeLog("error", "updateDBData error, rollback fail sSQL: " + s + ", desc: " + e1.toString(), "utility");
		};
		sResultCode = gcResultCodeUnknownError;
		sResultText = e.toString();
		writeLog("error", "updateDBData error, fail sSQL: " + s + ", desc: " + e.toString(), "utility");
	}finally{
		try{
			dbconn.setAutoCommit(true);
		}catch(SQLException e2){
			writeLog("error", "updateDBData error, set AutoCommit=true fail sSQL: " + s + ", desc: " + e2.toString(), "utility");
		}
		//Clean up resources, close the connection.
		closeDBConnection(null, stmt, dbconn);
	}	//}finally{
	
	htResponse.put("ResultCode", sResultCode);
	htResponse.put("ResultText", sResultText);
	return htResponse;
}	//public Hashtable updateDBData(String sSQL[], java.lang.Boolean bAutoCommit){

/*********************************************************************************************************************/
//將金額字串加上千位的逗點
public String toCurrency(String s){
	if (beEmpty(s))		return "";	//字串為空
	if (!isNumeric(s))	return s;	//不是數字，回覆原字串
	
	int i = 0;
	int j = 0;
	int k = 0;
	int l = 0;
	String s2 = "";
	//s = trim(s);
	i = s.length();			//i為字串長度
	if (i<4) return s;		//長度太短，不用加逗點，直接回覆原字串
	j = (int)Math.floor(i/3);	//j為字串長度除以3的商數
	k = i % 3;				//k為字串長度除以3的餘數
	s2 = "";
	if (k>0) s2 = s.substring(0, k);
	for (l=0;l<j;l++){
		s2 = s2 + (s2==""?"":",") + s.substring(k+(l*3), k+(l+1)*3);
	}
	return s2;
}

/*********************************************************************************************************************/
//判斷字串內容是否為數字
public java.lang.Boolean isNumeric(String number) { 
	try {
		Integer.parseInt(number);
		return true;
	}catch (NumberFormatException sqo) {
		return false;
	}
}

/*********************************************************************************************************************/
public void writeLog(String sLevel, String sLog, String sClass){
	if (beEmpty(sClass)) sClass = "NoClass";
	Logger logger = Logger.getLogger(sClass);
	writeToLog(sLevel, sLog, logger);
}
public void writeLog(String sLevel, String sLog){
	Logger logger = Logger.getLogger(this.getClass());
	writeToLog(sLevel, sLog, logger);
}
public void writeToLog(String sLevel, String sLog, Logger logger){
	if (sLevel.equalsIgnoreCase("debug"))	logger.debug(sLog);
	if (sLevel.equalsIgnoreCase("info"))	logger.info(sLog);
	if (sLevel.equalsIgnoreCase("warn"))	logger.warn(sLog);
	if (sLevel.equalsIgnoreCase("error"))	logger.error(sLog);
	if (sLevel.equalsIgnoreCase("fatal"))	logger.fatal(sLog);
	//org.apache.log4j.Layout.DateLayout l = DateLayout();
	//logger.info(l.getTimeZone());
}

/*********************************************************************************************************************/
public String getSequence(String dbName){	//取的新的序號
	Hashtable	ht					= new Hashtable();
	String		sResultCode			= gcResultCodeSuccess;
	String		s[][]				= null;
	String		sSQL				= "";
	String		ss					= "";
	
	sSQL = "SELECT nextval('CallPro')";
	
	ht = getDBData(sSQL, dbName);
	
	sResultCode = ht.get("ResultCode").toString();
	
	if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
		s = (String[][])ht.get("Data");
		ss = s[0][0];
	}

	return ss;
}

/*********************************************************************************************************************/

//發送HTML格式的信件(含附件)
public java.lang.Boolean sendHTMLMail(String sFromEmail, String sFromName, String sToEmail, String sSubject, String sBody){
	return sendHTMLMail(sFromEmail, sFromName, sToEmail, sSubject, sBody, "", "", "", "");
}
public java.lang.Boolean sendHTMLMail(String sFromEmail, String sFromName, String sToEmail, String sSubject, String sBody, String sFiles){
	return sendHTMLMail(sFromEmail, sFromName, sToEmail, sSubject, sBody, sFiles, "", "", "");
}
public java.lang.Boolean sendHTMLMail(String sFromEmail, String sFromName, String sToEmail, String sSubject, String sBody, String sFiles, String sCc){
	return sendHTMLMail(sFromEmail, sFromName, sToEmail, sSubject, sBody, sFiles, sCc, "", "");
}
public java.lang.Boolean sendHTMLMail(String sFromEmail, String sFromName, String sToEmail, String sSubject, String sBody, String sFiles, String sCc, String sBcc, String sLogo){
	/*************************************************************************
		sFromEmail:		寄件者的 email address
		sFromName:		寄件者名稱，若輸入空字串則設為與 sFromEmail 相同值
		sToEmail:		收件人 email address，若有多個收件人則以【;】區隔
		sSubject:		信件主旨
		sBody:			信件內容 HTML，從<html><head>至</body></html>
		sFiles:			附件
		sCc:			CC的 email address，若有多個BCC收件人則以【;】區隔
		sBcc:			BCC的 email address，若有多個BCC收件人則以【;】區隔
		sLogo:			Logo圖檔的路徑檔名
		回覆值:			執行成功回覆 true，失敗時回覆 false
	*************************************************************************/
	java.lang.Boolean	bOK		= true;
	String[]			aTo		= null;
	String[]			aCc	= null;
	String[]			aBcc	= null;
	String[]			aFile	= null;
	int					i		= 0;
	
	String				sSMTPServer			= gcDefaultEmailSMTPServer;
	int					iSMTPServerPort		= gcDefaultEmailSMTPServerPort;
	
	if (beEmpty(sFromEmail) || beEmpty(sFromName) || beEmpty(sToEmail) || beEmpty(sSubject) || beEmpty(sBody)){
		return false;
	}
	
	sToEmail = sToEmail.replace(",", ";");
	aTo = sToEmail.split(";");
	if (aTo.length<1){
		return false;
	}
	
	//CC 收件人
	if (notEmpty(sCc)){
		sCc = sCc.replace(",", ";");
		aCc = sCc.split(";");
	}

	//BCC 收件人
	if (notEmpty(sBcc)){
		sBcc = sBcc.replace(",", ";");
		aBcc = sBcc.split(";");
	}

	//附件
	if (notEmpty(sFiles)){
		aFile = sFiles.split(";");
	}
	
	try{
		try{
			final String				sSMTPServerUserName	= gcDefaultEmailSMTPServerUserName;
			final String				sSMTPServerPassword	= gcDefaultEmailSMTPServerPassword;
			Properties props = new Properties();
			//以下是 Gmail 設定
			props.put("mail.transport.protocol", "smtp");
			props.put("mail.smtp.host", sSMTPServer);
			props.put("mail.smtp.port", iSMTPServerPort);
			props.put("mail.smtp.auth", "true");
			props.put("mail.smtp.starttls.enable", "true");
			props.put("mail.smtp.starttls.required", "true");
			/*
			props.put("mail.smtp.host", sSMTPServer);
			props.put("mail.smtp.auth", "true");
			props.put("mail.smtp.starttls.enable", "true");
			props.put("mail.smtp.port", iSMTPServerPort);
			*/
			/*
			props.put("mail.smtp.host", sSMTPServer);
			//props.put("mail.smtp.auth", "true");	//需要認證則為 true，記得在transport.connect的後兩個參數填入 id、pwd
			*/

			Session s = Session.getInstance(props);
			/*
			Session s = Session.getInstance(props, new javax.mail.Authenticator() {
				protected javax.mail.PasswordAuthentication getPasswordAuthentication() {
					return new javax.mail.PasswordAuthentication(sSMTPServerUserName, sSMTPServerPassword);
				}
			});
			*/
			//s.setDebug(true);	//需要 debug 時再打開
			
			javax.mail.internet.MimeMessage message = new MimeMessage(s);
			
			//設定發信人/收信人/主題/發信時間
			if (beEmpty(sFromName)) sFromName = sFromEmail;
			InternetAddress from = new InternetAddress(sFromEmail, sFromName, "utf-8");
			message.setFrom(from);
			//message.setSender(new InternetAddress(sFromEmail));
			/*
			InternetAddress[] replyAddrs = new InternetAddress[1];
			replyAddrs[0] = new InternetAddress(sFromEmail, sFromName, "utf-8");
			message.setReplyTo(replyAddrs);
			*/
			
			InternetAddress[] mailAddrs = new InternetAddress[aTo.length];
			for (i=0;i<aTo.length;i++){
				 mailAddrs[i] = new InternetAddress(aTo[i].toLowerCase(), aTo[i], "utf-8");	//第一個參數是email，第二個參數是收件人名稱，第三個參數是encoding
			}
			message.setRecipients(javax.mail.Message.RecipientType.TO, mailAddrs);
			
			if (aCc!=null && aCc.length>0){	//CC收件人
				InternetAddress[] mailAddrsCc = new InternetAddress[aCc.length];
				for (i=0;i<aCc.length;i++){
					 mailAddrsCc[i] = new InternetAddress(aCc[i].toLowerCase(), aCc[i], "utf-8");	//第一個參數是email，第二個參數是收件人名稱，第三個參數是encoding
				}
				message.setRecipients(javax.mail.Message.RecipientType.CC, mailAddrsCc);
			}	//if (aCc!=null && aCc.length>0){	//CC收件人

			if (aBcc!=null && aBcc.length>0){	//BCC收件人
				InternetAddress[] mailAddrsBcc = new InternetAddress[aBcc.length];
				for (i=0;i<aBcc.length;i++){
					 mailAddrsBcc[i] = new InternetAddress(aBcc[i].toLowerCase(), aBcc[i], "utf-8");	//第一個參數是email，第二個參數是收件人名稱，第三個參數是encoding
				}
				message.setRecipients(javax.mail.Message.RecipientType.BCC, mailAddrsBcc);
			}	//if (aBcc!=null && aBcc.length>0){	//BCC收件人
			
			message.setSubject(sSubject, "utf-8");
			message.setSentDate(new java.util.Date());
			
			//給消息對像設置內容
			BodyPart mdp = new MimeBodyPart();//新建一個存放信件內容的BodyPart對像
			mdp.setContent(sBody, "text/html;charset=utf-8");//給BodyPart對像設置內容和格式/編碼方式
			Multipart mm = new MimeMultipart();//新建一個MimeMultipart對像用來存放BodyPart對象(事實上可以存放多個)
			mm.addBodyPart(mdp);//將BodyPart加入到MimeMultipart對像中(可以加入多個BodyPart)
			
			//設定附件
			if (aFile!=null && aFile.length>0){	//可能有多個附件
				for (i=0;i<aFile.length;i ++ ){
					mdp = new  MimeBodyPart(); 
					FileDataSource fileds = new  FileDataSource (aFile[i]); 
					mdp.setDataHandler( new  DataHandler(fileds)); 
					mdp.setFileName(fileds.getName()); 
					mm.addBodyPart(mdp); 
				} 
			}	//if (aFile!=null && aFile.length>0){	//可能有多個附件

			// 加入公司logo，放在mai body中 <img src="cid:image"> 指定的位置
			if (notEmpty(sLogo)){
				mdp = new MimeBodyPart();
				FileDataSource fds = new FileDataSource(sLogo);
				mdp.setDataHandler(new DataHandler(fds));
				mdp.setHeader("Content-ID", "<image>");
				mm.addBodyPart(mdp);
			}

			message.setContent(mm);//把mm作為消息對象的內容
			
			message.saveChanges();
			Transport transport = s.getTransport("smtp");
			transport.connect(sSMTPServer, iSMTPServerPort, sSMTPServerUserName, sSMTPServerPassword);	//AWS
			transport.sendMessage(message, message.getAllRecipients());
			transport.close();
		}catch(UnsupportedEncodingException e){
			bOK = false;
		}
	}catch(javax.mail.MessagingException e){
		writeLog("error", "sendHTMLMail 失敗:" + e.toString());
		bOK = false;
	}
	if (!bOK) writeLog("error", "Send Mail 失敗||To=" + sToEmail + "||CC=" + sCc + "||BCC=" + sBcc + "||Subject=" + sSubject);
	return bOK;
}

/*********************************************************************************************************************/
//取得目前時間前一小時的時間，格式為 yyyy-MM-dd HH:00:00，只算到小時
public String getOneHoursAgoTime(){
	String oneHoursAgoTime =  "" ;

	TimeZone.setDefault(TimeZone.getTimeZone("Asia/Taipei"));	//將 Timezone 設為 GMT+8
	java.util.Calendar cal = java.util.Calendar.getInstance();
	cal.add(java.util.Calendar.HOUR_OF_DAY, -1);	//目前的前一小時
	oneHoursAgoTime = new SimpleDateFormat( "yyyy-MM-dd HH" ).format(cal.getTime());//取得時間
	return  oneHoursAgoTime + ":00:00";
}

/*********************************************************************************************************************/
public String getJsonValue(Object obj, String name){
	if (obj==null || name==null) return null;
	String value = "";
	try {
		JSONObject jsonObject = (JSONObject) obj;
		value = (String) jsonObject.get(name);
 
 		/*
		long age = (Long) jsonObject.get("age");
		System.out.println(age);
 
		// loop array
		JSONArray msg = (JSONArray) jsonObject.get("messages");
		Iterator<String> iterator = msg.iterator();
		while (iterator.hasNext()) {
			System.out.println(iterator.next());
		}
		*/
	} catch (Exception e) {
		//e.printStackTrace();
		return null;
	}
	return value;
}

//取得某個Account的設定資料
/*********************************************************************************************************************/
public Hashtable getAccountProfile(String sAccountName, String dbName){
	Hashtable	htResponse		= new Hashtable();	//儲存回覆資料的 hash table
	Hashtable	ht				= new Hashtable();
	String		sSQL			= "";
	String		s[][]			= null;
	String		sResultCode		= gcResultCodeSuccess;
	String		sResultText		= gcResultTextSuccess;
	int			i				= 0;

	sSQL = "SELECT Account_Type, Line_User_ID, Line_Channel_Name, Parent_Account_Name, Status";
	sSQL += " FROM callpro_account";
	sSQL += " WHERE Account_Name='" + sAccountName + "'";

	ht = getDBData(sSQL, dbName);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
		s = (String[][])ht.get("Data");
		i = 0;
		htResponse.put("Account_Type", nullToString(s[0][i], ""));	i++;
		htResponse.put("Line_User_ID", nullToString(s[0][i], ""));	i++;
		htResponse.put("Line_Channel_Name", nullToString(s[0][i], ""));	i++;
		htResponse.put("Parent_Account_Name", nullToString(s[0][i], ""));	i++;
		htResponse.put("Status", nullToString(s[0][i], ""));	i++;
	}else{
		htResponse.put("ResultCode", sResultCode);
		htResponse.put("ResultText", sResultText);
		return htResponse;
	}

	sSQL = "";
	String[] fields = null;
	if (htResponse.get("Account_Type").toString().equals("A")){	//系統管理者
		sSQL = "SELECT Google_ID, Google_User_Name, Google_User_Picture_URL, Google_Email, DATE_FORMAT(Last_Login_Date, '%Y/%m/%d/ %H:%i')";
		sSQL += " FROM callpro_account_admin";
		fields = new String[] {"Google_ID", "Google_User_Name", "Google_User_Picture_URL", "Google_Email", "Last_Login_Date"};
	}

	if (htResponse.get("Account_Type").toString().equals("D")){	//加盟商
		sSQL = "SELECT Google_ID, Google_User_Name, Google_User_Picture_URL, Google_Email, Contact_Phone, Contact_Address, Tax_ID_Number, Purchase_Quantity, Provision_Quantity, DATE_FORMAT(Expiry_Date, '%Y/%m/%d/ %H:%i'), DATE_FORMAT(Last_Login_Date, '%Y/%m/%d/ %H:%i')";
		sSQL += " FROM callpro_account_dealer";
		fields = new String[] {"Google_ID", "Google_User_Name", "Google_User_Picture_URL", "Google_Email", "Contact_Phone", "Contact_Address", "Tax_ID_Number", "Purchase_Quantity", "Provision_Quantity", "Expiry_Date", "Last_Login_Date"};
	}
	
	if (notEmpty(sSQL)){
		sSQL += " WHERE Account_Name='" + sAccountName + "'";
		ht = getDBData(sSQL, dbName);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			s = (String[][])ht.get("Data");
			i = 0;
			htResponse.put("Account_Type", nullToString(s[0][i], ""));	i++;
			htResponse.put("Line_User_ID", nullToString(s[0][i], ""));	i++;
			htResponse.put("Line_Channel_Name", nullToString(s[0][i], ""));	i++;
			htResponse.put("Parent_Account_Name", nullToString(s[0][i], ""));	i++;
			htResponse.put("Status", nullToString(s[0][i], ""));	i++;
		}else{
			htResponse.put("ResultCode", sResultCode);
			htResponse.put("ResultText", sResultText);
			return htResponse;
		}
	}	//if (notEmpty(sSQL)){
	
	htResponse.put("ResultCode", sResultCode);
	htResponse.put("ResultText", sResultText);
	return htResponse;

}	//public Hashtable getAccountProfile(String sAccountName, String dbName){

/*********************************************************************************************************************/
//根據 Line channel 及 Line user ID，取得用戶資料
public Hashtable getAccountProfileByLineId(String sLineChannel, String sLineUserId, String dbName){
	Hashtable	htResponse		= new Hashtable();	//儲存回覆資料的 hash table
	Hashtable	ht				= new Hashtable();
	String		sSQL			= "";
	String		s[][]			= null;
	String		sResultCode		= gcResultCodeSuccess;
	String		sResultText		= gcResultTextSuccess;
	int			i				= 0;

	sSQL = "SELECT A.Account_Sequence, A.Account_Name, A.Account_Type, A.Line_User_ID, A.Line_Channel_Name, A.Parent_Account_Sequence, A.Audit_Phone_Number, A.Status, DATE_FORMAT(B.Expiry_Date, '%Y/%m/%d/ %H:%i')";
	sSQL += " FROM callpro_account A LEFT JOIN callpro_account_detail";
	sSQL += " ON A.Account_Sequence = B.Main_Account_Sequence";
	sSQL += " WHERE A.Line_User_ID='" + sLineUserId + "'";
	sSQL += " AND A.Line_Channel_Name='" + sLineChannel + "'";

	ht = getDBData(sSQL, dbName);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
		s = (String[][])ht.get("Data");
		if (s.length>1){	//資料不應該超過一筆
			htResponse.put("ResultCode", gcResultCodeMoreThanOneAccount);
			htResponse.put("ResultText", gcResultTextMoreThanOneAccount);
			return htResponse;
		}
		i = 0;
		htResponse.put("Account_Sequence", nullToString(s[0][i], ""));	i++;
		htResponse.put("Account_Name", nullToString(s[0][i], ""));	i++;
		htResponse.put("Account_Type", nullToString(s[0][i], ""));	i++;
		htResponse.put("Line_User_ID", nullToString(s[0][i], ""));	i++;
		htResponse.put("Line_Channel_Name", nullToString(s[0][i], ""));	i++;
		htResponse.put("Parent_Account_Sequence", nullToString(s[0][i], ""));	i++;
		htResponse.put("Audit_Phone_Number", nullToString(s[0][i], ""));	i++;
		htResponse.put("Status", nullToString(s[0][i], ""));	i++;
		htResponse.put("Expiry_Date", nullToString(s[0][i], ""));	i++;
	}
	htResponse.put("ResultCode", sResultCode);
	htResponse.put("ResultText", sResultText);
	return htResponse;
}	//public Hashtable getAccountProfileByLineId(String sLineChannel, String sLineUserId, String dbName){

/*********************************************************************************************************************/
//檢查PC送來的電話主人資料是否正常、正確
public java.lang.Boolean isValidPhoneOwner(String sAreaCode, String sPhoneNumber, String sAuthorizationCode, String sLoginUserAccountType) {
	java.lang.Boolean bOK = false;
	Hashtable	ht					= new Hashtable();
	String		sResultCode			= gcResultCodeSuccess;
	String		sResultText			= gcResultTextSuccess;
	
	String		s[][]				= null;
	String		sSQL				= "";

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
		if (!isExpired(s[0][3]) && notEmpty(s[0][5]) && !s[0][5].equals("Suspend") && !s[0][5].equals("Init")){
			bOK = true;
		}
		
		if (beEmpty(s[0][4]) || !sAuthorizationCode.equals(s[0][4])){
			bOK = false;
			//系統管理者可以直接發送測試通知
			if (notEmpty(sLoginUserAccountType) && sLoginUserAccountType.equals("A")) bOK = true;
		}
	}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

	return bOK;
}	//public java.lang.Boolean beEmpty(String s) {

/*********************************************************************************************************************/
//檢查目前(5分鐘內)是否有重複的授權碼在等待用戶輸入
private java.lang.Boolean isDuplicateAuthorizationCode(String sAuthorizationCode){
	Hashtable	ht					= new Hashtable();
	String		sSQL				= "";
	String		s[][]				= null;
	String		sResultCode			= gcResultCodeSuccess;
	String		sResultText			= gcResultTextSuccess;
	String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
	
	sSQL = "SELECT A.Account_Sequence";
	sSQL += " FROM callpro_account A";
	sSQL += " WHERE A.Authorization_Code='" + sAuthorizationCode + "'";
	sSQL += " AND A.Status='Init'";
	sSQL += " AND DATE_ADD( Create_Date , INTERVAL 5 MINUTE )>'" + sDate + "'";
	//writeLog("debug", "SQL= " + sSQL);
	ht = getDBData(sSQL, gcDataSourceName);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
		return true;
	}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料，可能還沒設授權碼或授權碼輸入錯誤
		return false;
	}else{	//有誤
		writeLog("error", "Failed to check duplicate authorization code, SQL= " + sSQL + ", sResultText=" + sResultText);
		return true;
	}
}	//private java.lang.Boolean isDuplicateAuthorizationCode(String sAuthorizationCode){

/*********************************************************************************************************************/
//發送mail給用戶，請用戶重新使用完整登入功能將Google帳號與我們服務綁定
public void sendFullLoginMailToGoogle(String gmailAddress){
	java.lang.Boolean bOK = false;
	String sSubject = "Call-Pro帳號重新驗證通知信";
	String sBody = "";
	String sLink = gcSystemUri + "login_full.html";
	sBody = "親愛的用戶您好，";
	sBody += "<p>感謝您使用Call-Pro服務，我們發現目前無法同步您的Google通訊錄，或無法上傳錄音檔至您的Google雲端硬碟。<br>若是因為您修改過Google帳號的設定，或是您Google帳號註冊的應用程式過多，請點選以下連結重新將Call-Pro服務註冊至您的Google帳號中。";
	sBody += "<p><a href='" + sLink + "'>" + sLink + "</a>";
	sBody += "<p>Call-Pro祝您有美好的一天";
	bOK = sendHTMLMail(gcDefaultEmailFromAddress, gcDefaultEmailFromName, gmailAddress, sSubject, sBody, "", "", "", "");
}	//public void sendFullLoginMailToGoogle(String gmailAddress){

/*********************************************************************************************************************/
//搜尋中華黃頁
public String getCallerNameFromHiPage(String sAPartyNumber){
	String	sResponse	= "";
	URL u;
	int i = 0;
	int j = 0;
	
	try
	{
		writeLog("debug", "get Caller Name From HiPage: " + sAPartyNumber);
		//sAPartyNumber = "0226270927";
		u = new URL("https://www.iyp.com.tw/phone.php?phone=" + sAPartyNumber);
		HttpURLConnection uc = (HttpURLConnection)u.openConnection();
		//uc.setRequestProperty ("Content-Type", "text/plain");
		//uc.setRequestProperty("contentType", "utf-8");
		uc.setRequestMethod("GET");
		//add request header
		uc.setRequestProperty("User-Agent", "Mozilla/5.0");
		//uc.setDoOutput(false);
		//uc.setDoInput(true);
	
		InputStream in = uc.getInputStream();
		BufferedReader r = new BufferedReader(new InputStreamReader(in));
		StringBuffer buf = new StringBuffer();
		String line;
		while ((line = r.readLine())!=null) {
			buf.append(line);
		}
		in.close();
		sResponse = buf.toString();	//取得回應值
		//writeLog("debug", "Response from HiPage: " + sResponse);
		if (notEmpty(sResponse)){
			i = sResponse.indexOf("<ol class=\"general\">");
			j = sResponse.indexOf("</ol>");
			if (i>0 && j>0 && j>i){
				sResponse = sResponse.substring(i+20, j);
				i = sResponse.indexOf("target=\"_blank\">");
				j = sResponse.indexOf("</a>");
				if (i>0 && j>0 && j>i){
					//writeLog("debug", "i= " + String.valueOf(i));
					//writeLog("debug", "j= " + String.valueOf(j));
					//writeLog("debug", "sResponse= " + sResponse.substring(i+16, j));
					sResponse = sResponse.substring(i+16, j);
				}else{
					sResponse = "";
				}
			}else{
				sResponse = "";
			}
		}else{
			sResponse = "";
		}
	}catch (Exception e){
		sResponse = "";
		writeLog("error", "Exception when get data from HiPage: " + e.toString());
	}

	if (beEmpty(sResponse)) sResponse = getCallerNameFromMyPublicPhonebook(sAPartyNumber);
	return sResponse;
}

/*********************************************************************************************************************/
//搜尋我們自己的社群電話簿
public String getCallerNameFromMyPublicPhonebook(String sAPartyNumber){
	String		sResponse			= "";
	Hashtable	ht					= new Hashtable();
	String		sSQL				= "";
	String		s[][]				= null;
	String		sResultCode			= gcResultCodeSuccess;
	String		sResultText			= gcResultTextSuccess;
	
	if (beEmpty(sAPartyNumber)) return "";
	sSQL = "SELECT Owner_Name";
	sSQL += " FROM callpro_public_phonebook";
	sSQL += " WHERE Phone_Number='" + sAPartyNumber + "'";
	//writeLog("debug", "SQL= " + sSQL);
	ht = getDBData(sSQL, gcDataSourceName);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
		s = (String[][])ht.get("Data");
		sResponse = nullToString(s[0][0], "");
	}

	return sResponse;
}

/*********************************************************************************************************************/
//讓單引號等字元可以寫入MySQL DB中，用法為escape(String)
private static final HashMap<String,String> sqlTokens;
private static java.util.regex.Pattern sqlTokenPattern;

static
{           
    //MySQL escape sequences: http://dev.mysql.com/doc/refman/5.1/en/string-syntax.html
    String[][] search_regex_replacement = new String[][]
    {
            {   "\u0000"    ,       "\\x00"     ,       "\\\\0"     },
            {   "'"         ,       "'"         ,       "\\\\'"     },
            {   "\""        ,       "\""        ,       "\\\\\""    },
            {   "\b"        ,       "\\x08"     ,       "\\\\b"     },
            {   "\n"        ,       "\\n"       ,       "\\\\n"     },
            {   "\r"        ,       "\\r"       ,       "\\\\r"     },
            {   "\t"        ,       "\\t"       ,       "\\\\t"     },
            {   "\u001A"    ,       "\\x1A"     ,       "\\\\Z"     },
            {   "\\"        ,       "\\\\"      ,       "\\\\\\\\"  }
    };

    sqlTokens = new HashMap<String,String>();
    String patternStr = "";
    for (String[] srr : search_regex_replacement)
    {
        sqlTokens.put(srr[0], srr[2]);
        patternStr += (patternStr.isEmpty() ? "" : "|") + srr[1];            
    }
    sqlTokenPattern = java.util.regex.Pattern.compile('(' + patternStr + ')');
}


public static String escape(String s)
{
    Matcher matcher = sqlTokenPattern.matcher(s);
    StringBuffer sb = new StringBuffer();
    while(matcher.find())
    {
        matcher.appendReplacement(sb, sqlTokens.get(matcher.group(1)));
    }
    matcher.appendTail(sb);
    return sb.toString();
}

/*********************************************************************************************************************/


%>