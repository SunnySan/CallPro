<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>

<%@page import="com.google.api.client.auth.oauth2.Credential" %>
<%@page import="com.google.api.client.extensions.java6.auth.oauth2.AuthorizationCodeInstalledApp" %>
<%@page import="com.google.api.client.extensions.jetty.auth.oauth2.LocalServerReceiver" %>
<%@page import="com.google.api.client.extensions.java6.auth.oauth2.AbstractPromptReceiver" %>

<%@page import="com.google.api.client.auth.oauth2.StoredCredential" %>
<%@page import="com.google.api.client.googleapis.auth.oauth2.*" %>
<%@page import="com.google.api.client.http.javanet.NetHttpTransport" %>
<%@page import="com.google.api.client.http.FileContent" %>
<%@page import="com.google.api.client.googleapis.javanet.GoogleNetHttpTransport" %>

<%@page import="com.google.api.client.http.HttpTransport" %>

<%@page import="com.google.api.client.json.jackson2.JacksonFactory" %>
<%@page import="com.google.api.client.json.JsonFactory" %>
<%@page import="com.google.api.client.util.store.FileDataStoreFactory" %>

<%@page import="com.google.api.services.drive.DriveScopes" %>
<%@page import="com.google.api.services.drive.model.*" %>
<%@page import="com.google.api.services.drive.Drive" %>

<%@page import="com.google.api.services.people.v1.PeopleService" %>
<%@page import="com.google.api.services.people.v1.model.ListConnectionsResponse" %>
<%@page import="com.google.api.services.people.v1.model.Person" %>
<%@page import="com.google.api.services.people.v1.model.PhoneNumber" %>
<%@page import="com.google.api.services.people.v1.model.Name" %>

<%@page import="com.google.api.services.urlshortener.Urlshortener" %>
<%@page import="com.google.api.services.urlshortener.model.Url" %>

<%@page import="com.google.api.client.util.DateTime" %>
<%@page import="com.google.api.services.calendar.CalendarScopes" %>
<%@page import="com.google.api.services.calendar.model.*" %>

<%@page import="java.io.File" %>
<%@page import="java.io.IOException" %>
<%@page import="java.io.InputStreamReader" %>
<%@page import="java.io.Reader" %>
<%@page import="java.util.List" %>
<%@page import="java.util.Arrays" %>

<%!
//注意：因為有些程式使用jxl.jar執行Excel檔案匯出，而jxl.jar有自己的Boolean，所以這裡的Boolean都宣告為java.lang.Boolean，以免compile失敗

/*********************************************************************************************************************/
//經由 refresh token 取得 GoogleCredential
public GoogleCredential getGoogleCredential(String sRefreshToken, String sClientSecretFile){
	Hashtable			ht					= new Hashtable();
	String				sResultCode			= gcResultCodeSuccess;
	String				sResultText			= gcResultTextSuccess;
	String 				sAccessToken		= "";
	GoogleCredential	credential			= null;

	try{
		GoogleClientSecrets clientSecrets = GoogleClientSecrets.load( JacksonFactory.getDefaultInstance(), new FileReader(sClientSecretFile));
		ht = doRefreshGoogleToken(sRefreshToken, clientSecrets.getDetails().getClientId(), clientSecrets.getDetails().getClientSecret());
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		
		if (!sResultCode.equals(gcResultCodeSuccess)){	//取得新的Access Token失敗
			writeLog("error", "無法 Refresh Google Access Token");
			return null;
		}else{
			sAccessToken = ht.get("AccessToken").toString();
		}
	
		credential = new GoogleCredential().setAccessToken(sAccessToken);
	}catch (Exception e){
		return null;
	}

	return credential;
}	//public GoogleCredential getGoogleCredential(String sRefreshToken, String sClientSecretFile){

/*********************************************************************************************************************/
//更新 Google API 的 Access Token
public Hashtable doRefreshGoogleToken(String refreshToken, String clientId, String clientSecret){
	Hashtable	htResponse		= new Hashtable();	//儲存回覆資料的 hash table
	String		sResultCode			= gcResultCodeSuccess;
	String		sResultText			= gcResultTextSuccess;

	String	line;
	String	sResponse	= "";
	String	sAccessToken = "";
	JSONParser parser = new JSONParser();
	
	writeLog("debug", "Trying to get new Google access token...");
	sResponse = "";

	try{
		String encodedUrl = "grant_type=" + URLEncoder.encode("refresh_token", "UTF-8");
		encodedUrl += "&refresh_token=" + URLEncoder.encode(refreshToken, "UTF-8");
		encodedUrl += "&client_id=" + URLEncoder.encode(clientId, "UTF-8");
		encodedUrl += "&client_secret=" + URLEncoder.encode(clientSecret, "UTF-8");
		
		byte[] postData = encodedUrl.getBytes( "UTF-8" );
		int postDataLength = postData.length;
	
		URL u;
		u = new URL(gcGoogleUrlForGettingAccessToken);
		HttpURLConnection uc = (HttpURLConnection)u.openConnection();
		uc.setRequestProperty( "Content-Length", Integer.toString( postDataLength ));
		uc.setRequestProperty ("Content-Type", "application/x-www-form-urlencoded");
		uc.setRequestProperty("contentType", "utf-8");
		uc.setRequestMethod("POST");
		uc.setDoOutput(true);
		uc.setDoInput(true);
	
		/*
		final BufferedWriter bfw = new BufferedWriter(new OutputStreamWriter(uc.getOutputStream()));
		bfw.write(encodedUrl.toString());
		bfw.flush();
		bfw.close();        
		*/
		DataOutputStream wr = new DataOutputStream(uc.getOutputStream());
		wr.writeBytes(encodedUrl);
		wr.flush();
		wr.close();
	
		InputStream in = uc.getInputStream();
		BufferedReader r = new BufferedReader(new InputStreamReader(in));
		StringBuffer buf = new StringBuffer();
		line = "";
		while ((line = r.readLine())!=null) {
			buf.append(line);
		}
		in.close();
		sResponse = buf.toString();	//取得回應值
	}catch (IOException e){ 
		sResponse = "";
		sResultCode	= gcResultCodeUnknownError;
		sResultText	= e.toString();
		writeLog("error", "Exception when Getting new Google access token: " + e.toString());
		htResponse.put("ResultCode", sResultCode);
		htResponse.put("ResultText", sResultText);
		return htResponse;
	}

	if (beEmpty(sResponse)){
		sResultCode	= gcResultCodeUnknownError;
		sResultText	= "Google回覆空白資料";
		writeLog("error", "Error when Getting new Google access token: " + sResultText);
		htResponse.put("ResultCode", sResultCode);
		htResponse.put("ResultText", sResultText);
		return htResponse;
	}else{
		writeLog("debug", "Google response after getting new Google access token: " + sResponse);
	}
	
	//取得 Google 回傳的資料了，解析 Access Token
	try {
		Object objBody = parser.parse(sResponse);
		JSONObject jsonObjectBody = (JSONObject) objBody;
		sAccessToken = (String) jsonObjectBody.get("access_token");
		if (beEmpty(sAccessToken)){
			sResultCode	= gcResultCodeUnknownError;
			sResultText	= "無法取得Google的Token資料";
			writeLog("error", "Google response didn't contain access token...");
			htResponse.put("ResultCode", sResultCode);
			htResponse.put("ResultText", sResultText);
			return htResponse;
		}else{
			writeLog("debug", "Got Access Token=" + sAccessToken);
			htResponse.put("AccessToken", sAccessToken);
		}
	} catch (Exception e) {
		writeLog("error", "Parse Access Token failed exception: " + e.toString());
		sResultCode	= gcResultCodeUnknownError;
		sResultText	= "無法取得Google的Token資料:" + e.toString();
		htResponse.put("ResultCode", sResultCode);
		htResponse.put("ResultText", sResultText);
		return htResponse;
	}

	htResponse.put("ResultCode", sResultCode);
	htResponse.put("ResultText", sResultText);
	return htResponse;

}	//public String doRefreshGoogleToken(String refreshToken, String clientId, String clientSecret){

/*********************************************************************************************************************/
//搜尋聯絡人(使用Google People API client library)
public Hashtable searchGoogleContact(HttpTransport httpTransport, JsonFactory jsonFactory, GoogleCredential credential, String sNumberToBeCompared ) {
	Hashtable	htResponse			= new Hashtable();	//儲存回覆資料的 hash table
	String		sResultCode			= gcResultCodeNoDataFound;
	String		sResultText			= gcResultTextNoDataFound;
	int			i					= 0;

	if (beEmpty(sNumberToBeCompared)){
		htResponse.put("ResultCode", gcResultCodeParametersNotEnough);
		htResponse.put("ResultText", gcResultTextParametersNotEnough);
		return htResponse;
	}
	//只比對最後 6 碼
	if (sNumberToBeCompared.length()>6) sNumberToBeCompared = sNumberToBeCompared.substring(sNumberToBeCompared.length()-6);
	try{
		PeopleService peopleService = new PeopleService.Builder(httpTransport, jsonFactory, credential).build();
        // Request 10 connections.
        //https://developers.google.com/resources/api-libraries/documentation/people/v1/java/latest/
        ListConnectionsResponse response = peopleService.people().connections()
                .list("people/me")
                .setPageSize(2000)
                .setPersonFields("names,phoneNumbers")
                .execute();
                //.setPersonFields("names,phoneNumbers,emailAddresses")

        // Print display name of connections if available.
        List<Person> connections = response.getConnections();
        String sPhoneNumber = "";
        if (connections != null && connections.size() > 0) {
            for (Person person : connections) {
                List<Name> names = person.getNames();
                List<PhoneNumber> phoneNumbers = person.getPhoneNumbers();
                if (names != null && names.size() > 0) {
	                if (phoneNumbers != null && phoneNumbers.size() > 0) {
	                	for (i=0;i<phoneNumbers.size();i++){
	                		sPhoneNumber = person.getPhoneNumbers().get(i).getValue();
		                	if (sPhoneNumber.endsWith(sNumberToBeCompared)){
								htResponse.put("ResultCode", gcResultCodeSuccess);
								htResponse.put("ResultText", gcResultTextSuccess);
								htResponse.put("ContactName", person.getNames().get(0).getDisplayName());
								return htResponse;
							}
	                	}
	                }
            	}
            	/*
                if (names != null && names.size() > 0) {
                	writeLog("debug", "Name: " + person.getNames().get(0).getDisplayName());
                	writeLog("debug", "PhoneNumbe: " + sPhoneNumber);
                    //System.out.println("Name: " + person.getNames().get(0).getDisplayName());
                } else {
                	writeLog("debug", "No names available for connection.");
                    //System.out.println("No names available for connection.");
                }
                */
            }	//for (Person person : connections) 
        } else {
           	writeLog("debug", "No connections found.");
            //System.out.println("No connections found.");
        }	//if (connections != null && connections.size() > 0) 

	} catch (Exception e) {
		writeLog("error", "Search Google contact error: " + e.toString());
		sResultCode	= gcResultCodeUnknownError;
		sResultText	= "無法取得Google聯絡人的資料:" + e.toString();
		htResponse.put("ResultCode", sResultCode);
		htResponse.put("ResultText", sResultText);
		return htResponse;
	}

	htResponse.put("ResultCode", sResultCode);
	htResponse.put("ResultText", sResultText);
	return htResponse;
}	//public java.lang.Boolean beEmpty(String s) {

/*********************************************************************************************************************/
//搜尋聯絡人(使用Google Contact API REST request)
public Hashtable searchGoogleContactWithGoogleContactApi(String sAccessToken, String sNumberToBeCompared ) {
	Hashtable	htResponse			= new Hashtable();	//儲存回覆資料的 hash table
	String		sResultCode			= gcResultCodeNoDataFound;
	String		sResultText			= gcResultTextNoDataFound;
	int			i					= 0;
	int			j					= 0;
	int			k					= 0;
	String		sResponse			= "";
	JSONParser	parser				= new JSONParser();
	URL u;

	if (beEmpty(sAccessToken) || beEmpty(sNumberToBeCompared)){
		htResponse.put("ResultCode", gcResultCodeParametersNotEnough);
		htResponse.put("ResultText", gcResultTextParametersNotEnough);
		return htResponse;
	}
	//只比對最後 6 碼
	if (sNumberToBeCompared.length()>6) sNumberToBeCompared = sNumberToBeCompared.substring(sNumberToBeCompared.length()-6);

	try{
		writeLog("debug", "Contact query for phone number= " + sNumberToBeCompared);
		//如果要回傳聯絡人所有欄位，就將thin改為full
		u = new URL("https://www.google.com/m8/feeds/contacts/default/thin?q=" + sNumberToBeCompared + "&access_token=" + sAccessToken + "&alt=json&v=3.0");
		//u = new URL("https://www.google.com/m8/feeds/contacts/default/thin?access_token=" + sAccessToken + "&alt=json&v=3.0");
		HttpURLConnection uc = (HttpURLConnection)u.openConnection();
		uc.setRequestProperty("contentType", "utf-8");
		uc.setRequestMethod("GET");
		uc.setDoInput(true);
	
		InputStream in = uc.getInputStream();
		BufferedReader r = new BufferedReader(new InputStreamReader(in));
		StringBuffer buf = new StringBuffer();
		String line;
		while ((line = r.readLine())!=null) {
			buf.append(line);
		}
		in.close();
		sResponse = buf.toString();	//取得回應值
		//writeLog("debug", "Google Contact API response: " + sResponse);
	}catch (IOException e){
		writeLog("error", "Search Google contact error: " + e.toString());
		sResultCode	= gcResultCodeUnknownError;
		sResultText	= "無法取得Google聯絡人的資料:" + e.toString();
		htResponse.put("ResultCode", sResultCode);
		htResponse.put("ResultText", sResultText);
		return htResponse;
	}

	//這是 sResponse 的範例
	/*
	{"version":"1.0","encoding":"UTF-8","feed":{"xmlns":"http://www.w3.org/2005/Atom","xmlns$openSearch":"http://a9.com/-/spec/opensearchrss/1.0/","xmlns$batch":"http://schemas.google.com/gdata/batch","xmlns$gd":"http://schemas.google.com/g/2005","xmlns$gContact":"http://schemas.google.com/contact/2008","id":{"$t":"diegosun888@gmail.com"},"updated":{"$t":"2017-11-06T09:39:03.365Z"},"category":[{"scheme":"http://schemas.google.com/g/2005#kind","term":"http://schemas.google.com/contact/2008#contact"}],"title":{"type":"text","$t":"Diego Diego's Contacts"},"link":[{"rel":"alternate","type":"text/html","href":"http://www.google.com/"},{"rel":"http://schemas.google.com/g/2005#feed","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin"},{"rel":"http://schemas.google.com/g/2005#post","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin"},{"rel":"http://schemas.google.com/g/2005#batch","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/batch"},{"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin?alt\u003djson\u0026q\u003dRichard\u0026max-results\u003d25"}],"author":[{"name":{"$t":"Diego Diego"},"email":{"$t":"diegosun888@gmail.com"}}],"generator":{"version":"1.0","uri":"http://www.google.com/m8/feeds","$t":"Contacts"},"openSearch$totalResults":{"$t":"4"},"openSearch$startIndex":{"$t":"1"},"openSearch$itemsPerPage":{"$t":"25"},"entry":[{"id":{"$t":"http://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/base/bb16ae809d756b9"},"updated":{"$t":"2017-11-02T03:09:33.791Z"},"category":[{"scheme":"http://schemas.google.com/g/2005#kind","term":"http://schemas.google.com/contact/2008#contact"}],"title":{"type":"text","$t":"孫芳武手機"},"link":[{"rel":"http://schemas.google.com/contacts/2008/rel#edit-photo","type":"image/*","href":"https://www.google.com/m8/feeds/photos/media/diegosun888%40gmail.com/bb16ae809d756b9/1B2M2Y8AsgTpgAmY7PhCfg"},{"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/bb16ae809d756b9"},{"rel":"edit","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/bb16ae809d756b9/1509592173791002"}],"gd$phoneNumber":[{"rel":"http://schemas.google.com/g/2005#other","uri":"tel:+886-986-123-101","$t":"986123101"}]},{"id":{"$t":"http://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/base/23a815ab8db3b6f9"},"updated":{"$t":"2017-10-30T10:35:07.019Z"},"category":[{"scheme":"http://schemas.google.com/g/2005#kind","term":"http://schemas.google.com/contact/2008#contact"}],"title":{"type":"text","$t":""},"link":[{"rel":"http://schemas.google.com/contacts/2008/rel#edit-photo","type":"image/*","href":"https://www.google.com/m8/feeds/photos/media/diegosun888%40gmail.com/23a815ab8db3b6f9/1B2M2Y8AsgTpgAmY7PhCfg"},{"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/23a815ab8db3b6f9"},{"rel":"edit","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/23a815ab8db3b6f9/1509359707019004"}],"gd$email":[{"rel":"http://schemas.google.com/g/2005#other","address":"sunny561228@gmail.com"}]},{"id":{"$t":"http://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/base/40a483cf0d840ec7"},"updated":{"$t":"2017-11-02T03:42:36.673Z"},"category":[{"scheme":"http://schemas.google.com/g/2005#kind","term":"http://schemas.google.com/contact/2008#contact"}],"title":{"type":"text","$t":"孫芳武email"},"link":[{"rel":"http://schemas.google.com/contacts/2008/rel#edit-photo","type":"image/*","href":"https://www.google.com/m8/feeds/photos/media/diegosun888%40gmail.com/40a483cf0d840ec7/upWou2ha1HTMglFbi80EQA"},{"rel":"http://schemas.google.com/contacts/2008/rel#photo","type":"image/*","href":"https://www.google.com/m8/feeds/photos/media/diegosun888%40gmail.com/40a483cf0d840ec7"},{"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/40a483cf0d840ec7"},{"rel":"edit","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/40a483cf0d840ec7/1509594156673001"}],"gd$email":[{"rel":"http://schemas.google.com/g/2005#other","address":"sunny561227@gmail.com"}]},{"id":{"$t":"http://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/base/658c93d38bf5e73f"},"updated":{"$t":"2017-10-30T15:20:39.134Z"},"category":[{"scheme":"http://schemas.google.com/g/2005#kind","term":"http://schemas.google.com/contact/2008#contact"}],"title":{"type":"text","$t":""},"link":[{"rel":"http://schemas.google.com/contacts/2008/rel#edit-photo","type":"image/*","href":"https://www.google.com/m8/feeds/photos/media/diegosun888%40gmail.com/658c93d38bf5e73f/upWou2ha1HTMglFbi80EQA"},{"rel":"http://schemas.google.com/contacts/2008/rel#photo","type":"image/*","href":"https://www.google.com/m8/feeds/photos/media/diegosun888%40gmail.com/658c93d38bf5e73f"},{"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/658c93d38bf5e73f"},{"rel":"edit","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/diegosun888%40gmail.com/thin/658c93d38bf5e73f/1509376839134001"}],"gd$email":[{"rel":"http://schemas.google.com/g/2005#other","address":"sunny561227@gmail.com"}]}]}}
	*/

	//取得 Google 回傳的資料了，解析電話號碼
	try {
		Object objBody = parser.parse(sResponse);
		JSONObject jsonObjectBody = (JSONObject) objBody;
		JSONObject jsonObjectFeed = (JSONObject) jsonObjectBody.get("feed");
		JSONArray jsonEntries = (JSONArray) jsonObjectFeed.get("entry");

		JSONObject jsonObjectEntry = null;
		JSONArray jsonPhoneNumbers = null;
		JSONObject jsonObjectPhoneNumber = null;
		String sPhoneNumber = null;
		JSONObject jsonObjectTitle = null;
		String sTitle = null;

		//writeLog("debug", "jsonEntries: " + jsonEntries.toString());
		for (i=0; i<jsonEntries.size(); i++) {	//把每個人的電話號碼找出來比對
			jsonObjectEntry = (JSONObject) jsonEntries.get(i);
			jsonPhoneNumbers = (JSONArray) jsonObjectEntry.get("gd$phoneNumber");
			if (jsonPhoneNumbers!=null){	//這人有電話號碼
				for (j=0; j<jsonPhoneNumbers.size(); j++) {	//把每個電話號碼找出來比對
					jsonObjectPhoneNumber = (JSONObject) jsonPhoneNumbers.get(i);
					sPhoneNumber = (String) jsonObjectPhoneNumber.get("$t");
					if (notEmpty(sPhoneNumber) && sPhoneNumber.endsWith(sNumberToBeCompared)){	//找到了
						jsonObjectTitle = (JSONObject) jsonObjectEntry.get("title");
						sTitle = (String) jsonObjectTitle.get("$t");
						if (notEmpty(sTitle)){	//找到聯絡人姓名
							writeLog("debug", "Found contact: " + sTitle + ", phone number= " + sPhoneNumber);
							htResponse.put("ResultCode", gcResultCodeSuccess);
							htResponse.put("ResultText", gcResultTextSuccess);
							htResponse.put("ContactName", sTitle);
							return htResponse;
						}	//if (notEmpty(sTitle)){	//找到聯絡人姓名
					}	//if (notEmpty(sPhoneNumber) && sPhoneNumber.endsWith(sNumberToBeCompared)){	//找到了
				}	//for (i=0; i<jsonEntries.size(); i++) {	//把每個人的電話號碼找出來比對
				//writeLog("debug", "jsonEntries(" + String.valueOf(i) + "): " + jsonPhoneNumbers.toString());
			}	//if (jsonPhoneNumbers!=null){	//這人有電話號碼
		}	//for (i=0; i<jsonEntries.size(); i++) {	//把每個人的電話號碼找出來比對
		writeLog("debug", "找不到符合的聯絡人...");
	} catch (Exception e) {
		writeLog("error", "比對Google聯絡人的電話號碼失敗: " + e.toString());
		sResultCode	= gcResultCodeUnknownError;
		sResultText	= "比對Google聯絡人的電話號碼失敗:" + e.toString();
		htResponse.put("ResultCode", sResultCode);
		htResponse.put("ResultText", sResultText);
		return htResponse;
	}

	htResponse.put("ResultCode", sResultCode);
	htResponse.put("ResultText", sResultText);
	return htResponse;
}	//public java.lang.Boolean beEmpty(String s) {

/*********************************************************************************************************************/
//取得Google短網址
//https://developers.google.com/api-client-library/java/apis/urlshortener/v1
public String getShortenURL(HttpTransport httpTransport, JsonFactory jsonFactory, GoogleCredential credential, String sLongURL){
	String	sResponse		= "";
	String	sPostMessage	= "{\"longUrl\": \"" + sLongURL + "\"}";
	String	sShortURL		= "";
	
	try{
		Urlshortener shortener = new Urlshortener.Builder(httpTransport, jsonFactory, credential).build();
		Url toInsert = new Url().setLongUrl(sLongURL);
		toInsert = shortener.url().insert(toInsert).execute();
		sShortURL = toInsert.getId();
		writeLog("debug", "Got short URL: " + sShortURL);
	} catch (Exception e) {
		sResponse = e.toString();
		writeLog("error", "Google Shorten URL exception: " + sResponse);
		sShortURL = sLongURL;
	}

	return sShortURL;
}	//function String getShortenURL(String sLongURL){

/*********************************************************************************************************************/
//新增Google Calendar Event
public Hashtable addGoogleCalendarEvent(HttpTransport httpTransport, JsonFactory jsonFactory, GoogleCredential credential, int iDuration, String sSummary, String sDescription ) {
	String		APPLICATION_NAME	= "Call-Pro";
	Hashtable	htResponse			= new Hashtable();	//儲存回覆資料的 hash table
	String		sResultCode			= gcResultCodeSuccess;
	String		sResultText			= gcResultTextSuccess;
	int			i					= 0;

	try{
		com.google.api.services.calendar.Calendar service = new com.google.api.services.calendar.Calendar.Builder(
															httpTransport, jsonFactory, credential)
															.setApplicationName(APPLICATION_NAME)
															.build();
		/*
		com.google.api.services.calendar.model.EventAttachment eventAttachment = new com.google.api.services.calendar.model.EventAttachment();
		eventAttachment.setFileUrl(sAttachmentURL);
		eventAttachment.setMimeType("audio/mpeg");
		eventAttachment.setTitle(sSavedFileName);
	
		java.util.List<EventAttachment> attachments = new ArrayList<EventAttachment>();
		attachments.add(eventAttachment);
		*/
		
		com.google.api.services.calendar.model.Event event = new com.google.api.services.calendar.model.Event();
		//event.setAttachments(attachments);	//加不進去，算了，檔案連結放在sDescription中
		event.setDescription(sDescription);
		//event.setEndTimeUnspecified(true);	//經測試一定要指定End Time才可以
		EventDateTime startDateTime = new EventDateTime();
		//從目前的時間往前減少通話時間的秒數，作為日曆事件的起始時間
		startDateTime.setDateTime(new DateTime(System.currentTimeMillis()-iDuration*1000)).setTimeZone("Asia/Taipei");
		event.setStart(startDateTime);
		DateTime endDateTime = new DateTime(System.currentTimeMillis());
		EventDateTime end = new EventDateTime().setDateTime(endDateTime).setTimeZone("Asia/Taipei");
        event.setEnd(end);
            
		event.setSummary(sSummary);
	
		com.google.api.services.calendar.model.Event eResult = service.events().insert("primary", event).execute();
		writeLog("info", "Insert Google Calendar successfully, event link=" + eResult.getHtmlLink() + ", summary(title)= " + sSummary + ", datatime=" + startDateTime.getDateTime().toString());
		htResponse.put("EventURL", eResult.getHtmlLink());
	} catch (Exception e) {
		writeLog("error", "Insert Google Calendar error: " + e.toString());
		sResultCode	= gcResultCodeUnknownError;
		sResultText	= "無法新增Google行事曆資料:" + e.toString();
		htResponse.put("ResultCode", sResultCode);
		htResponse.put("ResultText", sResultText);
		return htResponse;
	}

	htResponse.put("ResultCode", sResultCode);
	htResponse.put("ResultText", sResultText);
	return htResponse;
}	//public java.lang.Boolean beEmpty(String s) {

/*********************************************************************************************************************/

%>