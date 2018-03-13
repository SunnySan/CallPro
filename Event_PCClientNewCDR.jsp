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
https://cms.gslssd.com/CallPro/Event_PCClientNewCDR.jsp?areacode=02&phonenumber1=26585888&accesscode=123456&callerphone=0988123456&recordtime=30&recordtimestart=2018-01-23 10:42&call_direction=0&recordfile=ringtone_04.wav&ring_time=10&talked_time=20&callername=John&calleraddr=台北市內湖區成功路四段&callercompany=Call-Pro&calleremail=hello@gmail.com
************************************呼叫範例*******************************/

String CLIENT_SECRET_FILE	= application.getRealPath(gcGoogleClientSecretFilePath);
/** Application name. */
String APPLICATION_NAME = "Call-Pro";

String sLineGatewayUrlSendTextPush = gcLineGatewayUrlSendTextPush;

String saveDirectory = application.getRealPath("/upload");
if (!saveDirectory.endsWith("/")) saveDirectory = saveDirectory + "/";

String sAreaCode			= nullToString(request.getParameter("areacode"), "");			//監控電話的室話區碼
String sPhoneNumber			= nullToString(request.getParameter("phonenumber1"), "");		//監控電話的電話號碼
String sAuthorizationCode	= nullToString(request.getParameter("accesscode"), "");			//授權碼
String sCallerNumber 		= nullToString(request.getParameter("callerphone"), "");		//來電號碼，0966777117  (無來電顯示為0)
String sRecordTime 			= nullToString(request.getParameter("recordtime"), "");			//錄音總長秒數，recordtime = ring_time + talked_time
String sRecordTimeStart 	= nullToString(request.getParameter("recordtimestart"), "");	//錄音開始時間，2018-01-23 10:42
String sType 				= nullToString(request.getParameter("call_direction"), "");		//來電或是撥出，0來電；1撥出
String sSavedFileName 		= nullToString(request.getParameter("recordfile"), "");			//錄音檔名，"2016-03-03_19-34-46_000_0922599500.mp3， (wav或mp3,無錄音檔為0,無錄音檔不會先呼叫錄音檔上傳程式)"
String sRingTime 			= nullToString(request.getParameter("ring_time"), "");			//鈴響秒數
String sTalkedTime 			= nullToString(request.getParameter("talked_time"), "");		//開始通話秒數，0  (如為來電且talked_time=0，則為未接)
String sCallerName 			= nullToString(request.getParameter("callername"), "");			//來電者姓名
String sCallerAddr 			= nullToString(request.getParameter("calleraddr"), "");			//來電者地址
String sCallerCompany 		= nullToString(request.getParameter("callercompany"), "");		//來電者公司
String sCallerEmail 		= nullToString(request.getParameter("calleremail"), "");		//來電者email

if (beEmpty(sAreaCode) || beEmpty(sPhoneNumber) || beEmpty(sAuthorizationCode) || beEmpty(sCallerNumber)){
	writeLog("info", "Parameters not enough, areacode= " + sAreaCode + ", phonenumber1= " + sPhoneNumber + ", accesscode= " + sAuthorizationCode + ", callerphone= " + sCallerNumber);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	//out.print(obj);
	//out.flush();
	return;
}

if (!isValidPhoneOwner(sAreaCode, sPhoneNumber, sAuthorizationCode)){
	writeLog("error", "Authorization failed, areacode= " + sAreaCode + ", phonenumber1= " + sPhoneNumber + ", accesscode= " + sAuthorizationCode + ", callerphone= " + sCallerNumber);
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
	//out.print(obj);
	//out.flush();
	return;
}

String sGoogleCalendarId = "";
String sGoogleDriveFileId = "";
java.lang.Boolean bHasFile = false;
sGoogleCalendarId = getDateTimeNow(gcDateFormatDateDashTime) + "-" + getSequence(gcDataSourceName);
if (notEmpty(sSavedFileName) && sSavedFileName.length()>4 && isFileExist(saveDirectory + sSavedFileName)){
	bHasFile = true;
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();

int			i					= 0;
int			j					= 0;
int			k					= 0;

String		sLineChannelName	= "";
String		sRefreshToken		= "";

//確認門號主人狀態正常且已取得Google帳號
sSQL = "SELECT A.Line_User_ID, A.Line_Channel_Name, B.Google_Refresh_Token";
sSQL += " FROM callpro_account A, callpro_account_detail B";
sSQL += " WHERE A.Audit_Phone_Number='" + sAreaCode + sPhoneNumber + "'";
sSQL += " AND (A.Account_Type='O' OR A.Account_Type='T')";
sSQL += " AND A.Send_Notification='Y'";
sSQL += " AND A.Status='Active'";
sSQL += " AND A.Account_Sequence=B.Main_Account_Sequence";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	if (beEmpty(s[0][0]) || beEmpty(s[0][1]) || beEmpty(s[0][2])){
		obj.put("resultCode", gcResultCodeNoDataFound);
		obj.put("resultText", "無法取得該門號主人Google帳號的Line Channel或Refresh Token，請門號主人至Google移除Call Pro服務後重新註冊");
		//out.print(obj);
		//out.flush();
		return;
	}
	sLineChannelName = s[0][1];
	sRefreshToken = s[0][2];
}else{
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	//out.print(obj);
	//out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料




/****************上傳檔案給Google Drive*********************/

try{
	
    /** Global instance of the JSON factory. */
    JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();

    /** Global instance of the HTTP transport. */
    HttpTransport HTTP_TRANSPORT;
    HTTP_TRANSPORT = GoogleNetHttpTransport.newTrustedTransport();

	GoogleCredential credential = getGoogleCredential(sRefreshToken, CLIENT_SECRET_FILE);
	if (credential==null){	//取得 credential 失敗
		writeLog("error", "無法取得 Google credential");
		obj.put("resultCode", gcResultCodeUnknownError);
		obj.put("resultText", "無法取得 Google credential");
		out.print(obj);
		out.flush();
		return;
	}
	
	if (bHasFile){	//有檔案才上傳
		Drive service = new Drive.Builder(
	            HTTP_TRANSPORT, JSON_FACTORY, credential)
	            .setApplicationName(APPLICATION_NAME)
	            .build();
	
		com.google.api.services.drive.model.File file1 = getExistsFolder(service, gcGoogleDriveFolderName, "");
	
		if (file1==null){
			writeLog("debug", "目錄不存在，建立目錄...");
			com.google.api.services.drive.model.File fileMetadata = new com.google.api.services.drive.model.File();
			fileMetadata.setName(gcGoogleDriveFolderName);
			fileMetadata.setMimeType("application/vnd.google-apps.folder");
			
			file1 = service.files().create(fileMetadata)
			    .setFields("id")
			    .execute();
		}
		String	myFolderId = file1.getId();
		writeLog("debug", "Folder ID: " + myFolderId);
	
	
		com.google.api.services.drive.model.File newFile = insertFile(service, sSavedFileName, "Call-Pro Upload", myFolderId, (sSavedFileName.endsWith("wav")?"audio/wav":"audio/mpeg"), (saveDirectory.endsWith("/")?saveDirectory+sSavedFileName:saveDirectory+"/"+sSavedFileName));
		
		if (newFile!=null && notEmpty(newFile.getId())){
			sGoogleDriveFileId = newFile.getId();
			writeLog("info", "New file ID= " + sGoogleDriveFileId);
			//writeLog("info", "getPermissions()= " + newFile.getPermissions());
		}else{
			writeLog("error", "檔案上傳至Google Drive失敗");
			obj.put("resultCode", gcResultCodeUnknownError);
			obj.put("resultText", "檔案上傳至Google Drive失敗");
			//out.print(obj);
			//out.flush();
			return;
		}
	}	//if (bHasFile){	//有檔案才上傳

	//取得接收LINE通知的人的資料

	String		sRecepientType		= "";

	sRecepientType = "push";

	//準備Push訊息給客戶
	String sMessageBody = "";
	String sPushMessage = "";
	
	sMessageBody = sAreaCode + sPhoneNumber + (sType.equals("0")?"來電自":"撥出電話到") + sCallerNumber;
	if (beEmpty(sCallerName)){
		sMessageBody += "，對方為未建檔";
	}else{
		sMessageBody += "，對方為【" + sCallerName + "】";
	}
	
	//取得Google短網址(錄音檔)
	String sFileURL = "";
	String sShortURL = "";
	if (bHasFile){
		sFileURL = "https://drive.google.com/file/d/" + sGoogleDriveFileId + "/view";
		sShortURL = getShortenURL(HTTP_TRANSPORT, JSON_FACTORY, credential, sFileURL);
	}
	
	//取得Google短網址(Call Log 查詢)
	//String sCallLogURL = gcSystemUri + "SimpleCallLog.html?auditphone=" + sAreaCode + sPhoneNumber + "&callerphone=" + sCallerNumber;
	String sCallLogURL = gcSystemUri + "AdmOwnerCallLog.html?callerPhoneNumber=" + sCallerNumber;
	String sCallLogShortURL = getShortenURL(HTTP_TRANSPORT, JSON_FACTORY, credential, sCallLogURL);

	//sMessageBody += "，通話時間" + sDuration + "秒，聽取通話內容: " + sShortURL;
	if (bHasFile){
		sMessageBody += "，通話時間為" + sTalkedTime + "秒，聽取錄音檔: \n" + (beEmpty(sShortURL)?sFileURL:sShortURL) + "\n，查詢歷史記錄：\n" + (beEmpty(sCallLogShortURL)?sCallLogURL:sCallLogShortURL);
	}else{
		sMessageBody += "，通話時間為" + sTalkedTime + "秒，此通話無錄音檔，查詢歷史記錄：\n" + (beEmpty(sCallLogShortURL)?sCallLogURL:sCallLogShortURL);
	}
	sPushMessage = generateTextMessage(sRecepientType, s, sMessageBody);
	
	//新增 Google 行事曆
	ht = addGoogleCalendarEvent(HTTP_TRANSPORT, JSON_FACTORY, credential, Integer.parseInt(sTalkedTime), sAreaCode + sPhoneNumber + (sType.equals("0")?"來電自":"撥出電話到") + sCallerNumber, sMessageBody );
	
	//Push Line 訊息給客戶
	String	sResponse	= "";
	URL u;
	try
	{
		writeLog("debug", "Send push message to Line: " + sPushMessage);
		
		u = new URL(sLineGatewayUrlSendTextPush + sLineChannelName + "&type=" + sRecepientType);
		HttpURLConnection uc = (HttpURLConnection)u.openConnection();
		uc.setRequestProperty ("Content-Type", "application/json");
		uc.setRequestProperty("contentType", "utf-8");
		uc.setRequestMethod("POST");
		uc.setDoOutput(true);
		uc.setDoInput(true);
	
		byte[] postData = sPushMessage.getBytes("UTF-8");	//避免中文亂碼問題
		OutputStream os = uc.getOutputStream();
		os.write(postData);
		os.close();
	
		InputStream in = uc.getInputStream();
		BufferedReader r = new BufferedReader(new InputStreamReader(in));
		StringBuffer buf = new StringBuffer();
		String line;
		while ((line = r.readLine())!=null) {
			buf.append(line);
		}
		in.close();
		sResponse = buf.toString();	//取得回應值
		if (notEmpty(sResponse)){
			//解析JSON參數
			JSONParser parser = new JSONParser();
			Object objBody = parser.parse(sResponse);
			JSONObject jsonObjectBody = (JSONObject) objBody;
			sResultCode = (String) jsonObjectBody.get("resultCode");
			sResultText = (String) jsonObjectBody.get("resultText");
		}else{
			sResultCode = gcResultCodeUnknownError;
			sResultText = gcResultTextUnknownError;
		}
	}catch (IOException e){
		sResponse = e.toString();
		writeLog("error", "Exception when send message to Line: " + e.toString());
		sResultCode = gcResultCodeUnknownError;
		sResultText = sResponse;
	}
	
	if (sResultCode.equals(gcResultCodeSuccess)){
		writeLog("info", "Successfully send push message to Line!");
	}else{
		writeLog("error", "Failed to send push message to Line: " + sResponse + "\nrequest body=" + sPushMessage);
	}
	
	/*
            // Print the names and IDs for up to 10 files.
    FileList result = service.files().list()
         .setPageSize(10)
         .setFields("nextPageToken, files(id, name)")
         .execute();
    List<com.google.api.services.drive.model.File> files = result.getFiles();
    if (files == null || files.size() == 0) {
		writeLog("info", "No files found.");
    } else {
		writeLog("info", "Files:");
        for (com.google.api.services.drive.model.File file : files) {
			writeLog("info", file.getName() + " - " + file.getId() );
        }
    }
    */
    
    //新增Call Log記錄至database
    insertIntoCallLog(sAreaCode + sPhoneNumber, sCallerNumber, sType, sRecordTime, sTalkedTime, sRecordTimeStart, (beEmpty(sShortURL)?sFileURL:sShortURL), sCallerName, sCallerAddr, sCallerCompany, sCallerEmail);
}catch (Exception e){
	writeLog("error", "Google Drive Error" + e.toString());
	sResultCode = gcResultCodeUnknownError;
	sResultText = "無法取得Google Token，請稍後再試!<br>" + e.toString();
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	//out.print(obj);
	//out.flush();
	return;
}finally{
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
//out.print(obj);
if (bHasFile){
	out.print(sSavedFileName);
}else{
	out.print("ok");
}
out.flush();

%>

<%!

  /**
     * 
     * @param service google drive instance
     * @param title the title (name) of the folder (the one you search for)
     * @param parentId the parent Id of this folder (use root) if the folder is in the main directory of google drive
     * @return google drive file object 
     * @throws IOException
     */
    private com.google.api.services.drive.model.File getExistsFolder(Drive service,String title,String parentId) throws IOException 
    {
        Drive.Files.List request;
        request = service.files().list();
        String query = "";
        if (beEmpty(parentId)){
	        query = "mimeType='application/vnd.google-apps.folder' AND trashed=false AND name='" + title + "'";
	    }else{
	        query = "mimeType='application/vnd.google-apps.folder' AND trashed=false AND name='" + title + "' AND '" + parentId + "' in parents";
    	}
        //Logger.info(TAG + ": isFolderExists(): Query= " + query);
        request = request.setQ(query);
        com.google.api.services.drive.model.FileList files = request.execute();
    //List<com.google.api.services.drive.model.File> files = fileList.getFiles();
        //Logger.info(TAG + ": isFolderExists(): List Size =" + files.getItems().size());
        if (files.getFiles().size() == 0) //if the size is zero, then the folder doesn't exist
            return null;
        else
            //since google drive allows to have multiple folders with the same title (name)
            //we select the first file in the list to return
            return files.getFiles().get(0);
    }


  /**
   * Insert new file.
   *
   * @param service Drive API service instance.
   * @param title Title of the file to insert, including the extension.
   * @param description Description of the file to insert.
   * @param parentId Optional parent folder's ID.
   * @param mimeType MIME type of the file to insert.
   * @param filename Filename of the file to insert.
   * @return Inserted file metadata if successful, {@code null} otherwise.
   */
  private com.google.api.services.drive.model.File insertFile(Drive service, String title, String description,
      String parentId, String mimeType, String filename) {
    // File's metadata.
    com.google.api.services.drive.model.File body = new com.google.api.services.drive.model.File();
    body.setName(title);
    body.setDescription(description);
    body.setMimeType(mimeType);

List<String> list=new ArrayList<String>();
        list.add("102708111980129299028");
body.setPermissionIds(list);

    // Set the parent folder.
    if (parentId != null && parentId.length() > 0) {
      body.setParents(
          //Arrays.asList(new ParentReference().setId(parentId)));
          Arrays.asList(parentId));
    }

    // File's content.
    java.io.File fileContent = new java.io.File(filename);
    FileContent mediaContent = new FileContent(mimeType, fileContent);
    try {
      com.google.api.services.drive.model.File file = service.files().create(body, mediaContent).execute();

      // Uncomment the following line to print the File ID.
      // System.out.println("File ID: " + file.getId());

      return file;
    } catch (IOException e) {
   	writeLog("error", "Upload to Google Drive Error" + e.toString());
      return null;
    }
  }

%>

<%!
	private String generateTextMessage(String sRecepientType, String s[][], String sMessage){	//產生單一文字訊息
		/* 範例
			{"replyToken":"e627c4070a944e808486c9230ec6cf17","messages":[{"template":{"thumbnailImageUrl":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/images\/call-center-2537390_1280.jpg","text":"歡迎您使用電話管家服務\n請點選下方的服務","type":"buttons","title":"親愛的用戶您好!","actions":[{"label":"申請啟用LINE通知功能","type":"uri","uri":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/ApplyLineNotifyEnable.html?lineUserId=Ue913331687d5757ccff454aab90f55cb&lineUserType=user"},{"label":"申請取消LINE通知功能","type":"uri","uri":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/ApplyLineNotifyDisable.html?lineUserId=Ue913331687d5757ccff454aab90f55cb&lineUserType=user"}]},"altText":"選擇服務功能","type":"template"}]}
		*/
		int			i					= 0;
		int			j					= 0;

		JSONObject objPushMessage=new JSONObject();

		if (sRecepientType.equals("push")){
			objPushMessage.put("to", s[0][0]);
		}else{
			List  lMulticast = new LinkedList();
			for (i=0;i<s.length;i++){	//每個i代表一個 row
				lMulticast.add(s[i][0]);
			}
			objPushMessage.put("to", lMulticast);
		}

		List  lMessage = new LinkedList();
		Map mapMessage = null;

		mapMessage = new HashMap();
		mapMessage.put("type", "text");
		mapMessage.put("text", sMessage);
		lMessage.add(mapMessage);
		
		objPushMessage.put("messages", lMessage);	//一次最多可以傳 5 個訊息，這個 function 只傳 1 個訊息
		return objPushMessage.toString();
	}	//private String generateTextMessage(String sRecepientType, String s[][], String sMessage){	//產生單一文字訊息
	
	
	
	//新增Call Log記錄至database
	private void insertIntoCallLog(String sAuditPhoneNumber, String sCallerPhoneNumber, String sCallType, String sRecordLength, String sRecordTalkedTime, String sRecordTimeStart, String sRecordFileURL, String sCallerName, String sCallerAddress, String sCallerCompany, String sCallerEmail){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		List<String> sSQLList			= new ArrayList<String>();
		String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
		String		sUser				= "System";

		sSQL = "INSERT INTO callpro_call_log (Create_User, Create_Date, Update_User, Update_Date, Audit_Phone_Number, Caller_Phone_Number, Call_Type, Record_Length, Record_Talked_Time, Record_Time_Start, Record_File_URL, Caller_Name, Caller_Address, Caller_Company, Caller_Email) VALUES (";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += "'" + sAuditPhoneNumber + "',";
		sSQL += "'" + sCallerPhoneNumber + "',";
		sSQL += "'" + sCallType + "',";
		sSQL += sRecordLength + ",";
		sSQL += sRecordTalkedTime + ",";
		sSQL += "'" + sRecordTimeStart + "',";
		sSQL += "'" + sRecordFileURL + "',";
		sSQL += "'" + sCallerName + "',";
		sSQL += "'" + sCallerAddress + "',";
		sSQL += "'" + sCallerCompany + "',";
		sSQL += "'" + sCallerEmail + "'";
		sSQL += ")";
		sSQLList.add(sSQL);
		ht = updateDBData(sSQLList, gcDataSourceName, false);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		
		if (sResultCode.equals(gcResultCodeSuccess)){	//成功
			writeLog("info", "成功寫入Call_Log");
		}else{
			writeLog("error", "寫入Call_Log失敗：" + sResultText);
		}	//if (sResultCode.equals(gcResultCodeSuccess)){	//成功

	}	//private void insertIntoCallLog(String sAuditPhoneNumber, String sCallerPhoneNumber, String sCallType, String sRecordLength, String sRecordTalkedTime, String sRecordTimeStart, String sRecordFileURL, String sCallerName, String sCallerAddress, String sCallerCompany, String sCallerEmail){

%>