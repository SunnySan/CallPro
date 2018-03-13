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

<%@ page import="java.math.BigInteger" %>

<%@ page import="java.security.KeyFactory" %>
<%@ page import="java.security.spec.RSAPublicKeySpec" %>
<%@ page import="java.security.Security" %>
<%@ page import="java.security.Signature" %>
<%@ page import="javax.crypto.Cipher" %>
<%@ page import="javax.crypto.SecretKey" %>
<%@ page import="javax.crypto.spec.SecretKeySpec" %>
<%@ page import="java.security.interfaces.RSAPublicKey"%>
<%@ page import="java.security.interfaces.RSAPrivateKey"%>

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
//String sSignatureText = "3e080b5d89327c08ad8ab9f7986b6b383e080b5d89327c08";
String sSignatureText = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e080b5d89327c08ad8ab9f7986b6b383e080b5d89327c08";
//String sSignatureText = "0001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff003e080b5d89327c08ad8ab9f7986b6b383e080b5d89327c08";
String sSignatureHash = "35E593DBFFAEA4267B1CF5B485DC6BD41965BD41754DA1E3F5C0464E860DAAAFEEBAFDE27CCC686A956F225599D9C8047702F71D1D4675576B513E82CED16A04054385FF5E0966DB8D94F86BF11474B2EB32C9051817AB9F008843AB774DA46F74AF9FB789D66540F74EBD0ABF9879E4C8E248A9230640B9FD1745CC24E86496";
String sPublicKeyModulus = "A3765F32293CD98375C45C883A85BC2B8676CA4198E117E88AF24A22971A615711F317E9022D78F3E99911B3F65891E4C2C506CB822627612573AFFBA54A661986D52F46FE1D39669F6B02896F094F28A62FE447D99EEBFEBD3A11B16DB037850C165E1F0C30AA7EB24DACD1B1AF235390C31020819DAF4F4D52342153525457";
String sPublicKeyExponent = "010001";

byte[] encData = doRSAEncryption(hex2Byte(sSignatureHash), sPublicKeyModulus, sPublicKeyExponent, "RSA/ECB/NoPadding", Cipher.ENCRYPT_MODE);
	if (encData==null){
		out.print("encData is null");
	}else{
		out.print(byte2Hex(encData));
		//out.print(encData.toString());
		//out.print(encData.toString());
	}
	
out.flush();

%>

<%!

//將 16 進位碼的字串轉為 byte array
public static byte[] hex2Byte(String hexString) {
        byte[] bytes = new byte[hexString.length() / 2];
        for (int i=0 ; i<bytes.length ; i++)
                bytes[i] = (byte) Integer.parseInt(hexString.substring(2 * i, 2 * i + 2), 16);
        return bytes;
}

    //取得 byte array 每個 byte 的 16 進位碼
    public static String byte2Hex(byte[] b) {
        String result = "";
        for (int i=0 ; i<b.length ; i++)
            result += Integer.toString( ( b[i] & 0xff ) + 0x100, 16).substring( 1 );
        return result;
    }

    public byte[] doRSAEncryption (byte[] data, String sPublicKeyModulus, String sPublicKeyExponent, String algorithm, int mode){
        try {
            BigInteger modulus = new BigInteger(sPublicKeyModulus, 16);
            BigInteger pubExp = new BigInteger(sPublicKeyExponent, 16);
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            RSAPublicKeySpec pubKeySpec = new RSAPublicKeySpec(modulus, pubExp);
            RSAPublicKey key = (RSAPublicKey) keyFactory.generatePublic(pubKeySpec);

            Cipher cipher = Cipher.getInstance(algorithm);

            // Initiate the cipher.
            if (mode == Cipher.ENCRYPT_MODE)
                cipher.init(Cipher.ENCRYPT_MODE, (RSAPublicKey) key);
            else
                cipher.init(Cipher.DECRYPT_MODE, (RSAPrivateKey) key);

            // Encrypt/Decrypt the data.
            return cipher.doFinal(data);
        } catch (Exception e) {
            e.printStackTrace();
				writeLog("error", "Error while do RSA verification: " + e.toString());
        }
        return null;
    }
%>