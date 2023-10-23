package routines;
import java.security.MessageDigest;
import javax.xml.bind.DatatypeConverter;

public class MD5_HashFunction{

/**
* Returns a hexadecimal encoded MD5 hash for the input String.
* {Category} Userdefined
* {param} data
* @return
*/
public static String getMD5Hash(String... data) {
StringBuilder sb = new StringBuilder();
for(String str : data){
sb.append(str);
}
String result = null;
try {
MessageDigest digest = MessageDigest.getInstance("MD5");
byte[] hash = digest.digest(sb.toString().getBytes("UTF-8"));
return DatatypeConverter.printHexBinary(hash); // make it printable
} catch (Exception ex) { 
ex.printStackTrace();
}
return result;
}

}
